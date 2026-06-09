import unittest
from app import app

class ProductServiceTestCase(unittest.TestCase):

    def setUp(self):
        self.client = app.test_client()
        self.client.testing = True

    def test_health(self):
        response = self.client.get('/health')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json['status'], 'healthy')

    def test_get_products(self):
        response = self.client.get('/products')

        self.assertEqual(response.status_code, 200)
        self.assertGreater(response.json['count'], 0)

    def test_get_product_by_id(self):
        response = self.client.get('/products/prod-001')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json['id'], 'prod-001')

    def test_get_product_not_found(self):
        response = self.client.get('/products/invalid-product')

        self.assertEqual(response.status_code, 404)

    def test_create_product(self):
        response = self.client.post(
            '/products',
            json={
                'name': 'Test Product',
                'price': 99.99
            }
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.json['name'], 'Test Product')

if __name__ == '__main__':
    unittest.main()