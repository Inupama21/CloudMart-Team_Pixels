"""
CloudMart Product Service — DynamoDB Store Adapter

This module implements the DynamoDBStore class that connects to
an AWS DynamoDB table. It is loaded lazily by app.py when
STORE_BACKEND=dynamodb is set.

Required environment variables:
    DYNAMODB_TABLE — Table name (e.g., cloudmart-products)
    AWS_REGION     — AWS Region (default: us-east-1)

Credentials come from workload identity (IRSA on EKS) or local AWS config.

Author: Member 4 — Backend Services & Data Layer
"""

import os
import uuid
from datetime import datetime


class DynamoDBStore:
    """
    AWS DynamoDB adapter for product-service.
    """

    def __init__(self, seed_products=None, logger=None):
        import boto3
        from decimal import Decimal
        import logging

        self.logger = logger or logging.getLogger("dynamodb-store")
        self._seed_products = seed_products or []
        self._Decimal = Decimal

        region = os.environ.get("AWS_REGION", "us-east-1")
        dynamodb = boto3.resource("dynamodb", region_name=region)
        table_name = os.environ.get("DYNAMODB_TABLE", "cloudmart-products")
        self.table = dynamodb.Table(table_name)

        self.logger.info(f"Connected to DynamoDB table: {table_name} (region: {region})")
        self._seed_if_empty()

    def _to_dynamodb(self, item):
        """Convert Python floats to Decimal for DynamoDB."""
        result = {}
        for k, v in item.items():
            if isinstance(v, float):
                result[k] = self._Decimal(str(v))
            elif isinstance(v, int) and not isinstance(v, bool):
                result[k] = self._Decimal(str(v))
            else:
                result[k] = v
        return result

    def _from_dynamodb(self, item):
        """Convert DynamoDB Decimals back to Python float/int."""
        if item is None:
            return None
        result = {}
        for k, v in item.items():
            if isinstance(v, self._Decimal):
                # If it's a whole number, convert to int; else float
                if v % 1 == 0:
                    result[k] = int(v)
                else:
                    result[k] = float(v)
            else:
                result[k] = v
        return result

    def _seed_if_empty(self):
        """Insert seed products only if the table is empty."""
        try:
            response = self.table.scan(Limit=1)
            if response.get("Count", 0) == 0 and self._seed_products:
                with self.table.batch_writer() as batch:
                    for p in self._seed_products:
                        batch.put_item(Item=self._to_dynamodb(p))
                self.logger.info(f"DynamoDB: seeded {len(self._seed_products)} products")
            else:
                self.logger.info("DynamoDB: products already exist, skipping seed")
        except Exception as e:
            self.logger.error(f"DynamoDB seed error: {e}")

    def get_all(self, category=None, search=None):
        from boto3.dynamodb.conditions import Attr

        scan_kwargs = {}
        filter_expr = None

        if category:
            filter_expr = Attr("category").eq(category)
        if search:
            q = search.lower()
            search_expr = Attr("name").contains(q) | Attr("description").contains(q)
            filter_expr = (filter_expr & search_expr) if filter_expr else search_expr

        if filter_expr:
            scan_kwargs["FilterExpression"] = filter_expr

        items = []
        # Handle pagination for large tables
        while True:
            response = self.table.scan(**scan_kwargs)
            items.extend(response.get("Items", []))
            if "LastEvaluatedKey" not in response:
                break
            scan_kwargs["ExclusiveStartKey"] = response["LastEvaluatedKey"]

        return [self._from_dynamodb(item) for item in items]

    def get_by_id(self, product_id):
        response = self.table.get_item(Key={"id": product_id})
        item = response.get("Item")
        return self._from_dynamodb(item) if item else None

    def create(self, data):
        product_id = f"prod-{uuid.uuid4().hex[:6]}"
        product = {
            "id": product_id,
            "name": data["name"],
            "description": data.get("description", ""),
            "price": float(data["price"]),
            "category": data.get("category", "general"),
            "stock": int(data.get("stock", 0)),
            "imageUrl": data.get("imageUrl", ""),
            "createdAt": datetime.utcnow().isoformat() + "Z",
        }
        self.table.put_item(Item=self._to_dynamodb(product))
        return product

    def update(self, product_id, data):
        # Check if product exists first
        existing = self.get_by_id(product_id)
        if not existing:
            return None

        update_parts = []
        expr_values = {}
        expr_names = {}
        idx = 0

        for key in ["name", "description", "price", "category", "stock", "imageUrl"]:
            if key in data:
                placeholder = f":val{idx}"
                name_placeholder = f"#attr{idx}"
                update_parts.append(f"{name_placeholder} = {placeholder}")
                val = data[key]
                if isinstance(val, float):
                    val = self._Decimal(str(val))
                elif isinstance(val, int) and not isinstance(val, bool):
                    val = self._Decimal(str(val))
                expr_values[placeholder] = val
                expr_names[name_placeholder] = key
                idx += 1

        # Always set updatedAt
        update_parts.append("#updatedAt = :updatedAt")
        expr_values[":updatedAt"] = datetime.utcnow().isoformat() + "Z"
        expr_names["#updatedAt"] = "updatedAt"

        self.table.update_item(
            Key={"id": product_id},
            UpdateExpression="SET " + ", ".join(update_parts),
            ExpressionAttributeValues=expr_values,
            ExpressionAttributeNames=expr_names,
        )

        return self.get_by_id(product_id)

    def delete(self, product_id):
        existing = self.get_by_id(product_id)
        if not existing:
            return False
        self.table.delete_item(Key={"id": product_id})
        return True

    def check_stock(self, product_id, quantity):
        product = self.get_by_id(product_id)
        if not product:
            return False
        return product["stock"] >= quantity

    def decrement_stock(self, product_id, quantity):
        """Atomically decrement stock using ConditionExpression to prevent overselling."""
        try:
            self.table.update_item(
                Key={"id": product_id},
                UpdateExpression="SET stock = stock - :qty",
                ConditionExpression="stock >= :qty",
                ExpressionAttributeValues={":qty": self._Decimal(str(quantity))},
            )
            return True
        except self.table.meta.client.exceptions.ConditionalCheckFailedException:
            return False
