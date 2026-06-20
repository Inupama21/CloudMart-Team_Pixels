"""
CloudMart User Service — PostgreSQL Store Adapter (AWS RDS)

This module implements the PostgresUserStore class that connects to
an AWS RDS PostgreSQL instance. It is loaded lazily by app.py when
DB_BACKEND=postgres is set.

Required environment variables:
    DB_HOST      — RDS endpoint (e.g., cloudmart-db.xxxx.us-east-1.rds.amazonaws.com)
    DB_PORT      — PostgreSQL port (default: 5432)
    DB_NAME      — Database name (e.g., cloudmart)
    DB_USER      — Database user (e.g., cloudmart)
    DB_PASSWORD  — Database password (from K8s Secret / Secrets Manager)
    DB_SSLMODE   — SSL mode (default: require)

Alternatively, set DATABASE_URL as a single connection string.

Author: Member 4 — Backend Services & Data Layer
"""

import os
import psycopg2
import psycopg2.pool


class PostgresUserStore:
    """
    PostgreSQL adapter for AWS RDS.

    Uses psycopg2 with ThreadedConnectionPool for Gunicorn compatibility.
    Auto-creates the users table on startup and seeds initial data if empty.
    """

    def __init__(self, seed_users=None, logger=None):
        """
        Args:
            seed_users: List of seed user dicts to insert if table is empty.
            logger:     Logger instance from the main app.
        """
        import logging
        self.logger = logger or logging.getLogger("postgres-user-store")
        self._seed_users = seed_users or []

        # Support both individual env vars and a single DATABASE_URL
        database_url = os.environ.get("DATABASE_URL")
        if database_url:
            self.pool = psycopg2.pool.ThreadedConnectionPool(
                minconn=2, maxconn=10, dsn=database_url
            )
        else:
            self.pool = psycopg2.pool.ThreadedConnectionPool(
                minconn=2,
                maxconn=10,
                host=os.environ["DB_HOST"],
                port=int(os.environ.get("DB_PORT", "5432")),
                dbname=os.environ["DB_NAME"],
                user=os.environ["DB_USER"],
                password=os.environ["DB_PASSWORD"],
                sslmode=os.environ.get("DB_SSLMODE", "require"),
            )

        self.logger.info("Connected to PostgreSQL (RDS)")
        self._ensure_table()
        self._seed_if_empty()

    # ------------------------------------------------------------------
    # Connection helpers
    # ------------------------------------------------------------------

    def _get_conn(self):
        return self.pool.getconn()

    def _put_conn(self, conn):
        self.pool.putconn(conn)

    # ------------------------------------------------------------------
    # Schema & seeding
    # ------------------------------------------------------------------

    def _ensure_table(self):
        """Create the users table if it does not exist (idempotent)."""
        conn = self._get_conn()
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS users (
                        id            VARCHAR(64)  PRIMARY KEY,
                        email         VARCHAR(255) UNIQUE NOT NULL,
                        name          VARCHAR(255) NOT NULL,
                        "passwordHash" TEXT        NOT NULL,
                        role          VARCHAR(32)  NOT NULL DEFAULT 'customer',
                        address       TEXT         DEFAULT '',
                        "createdAt"   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
                        "updatedAt"   TIMESTAMPTZ
                    );
                    CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
                """)
            conn.commit()
            self.logger.info("PostgreSQL: users table ensured")
        finally:
            self._put_conn(conn)

    def _seed_if_empty(self):
        """Insert seed users only if the table is empty."""
        conn = self._get_conn()
        try:
            with conn.cursor() as cur:
                cur.execute("SELECT COUNT(*) FROM users")
                count = cur.fetchone()[0]
                if count == 0 and self._seed_users:
                    for u in self._seed_users:
                        cur.execute(
                            """INSERT INTO users
                               (id, email, name, "passwordHash", role, address, "createdAt")
                               VALUES (%s, %s, %s, %s, %s, %s, %s)
                               ON CONFLICT (id) DO NOTHING""",
                            (
                                u["id"], u["email"], u["name"],
                                u["passwordHash"], u["role"],
                                u["address"], u["createdAt"],
                            ),
                        )
                    conn.commit()
                    self.logger.info(
                        f"PostgreSQL: seeded {len(self._seed_users)} users"
                    )
                else:
                    self.logger.info(
                        f"PostgreSQL: {count} users already exist, skipping seed"
                    )
        finally:
            self._put_conn(conn)

    # ------------------------------------------------------------------
    # Row conversion
    # ------------------------------------------------------------------

    _COLUMNS = (
        "id", "email", "name", '"passwordHash"',
        "role", "address", '"createdAt"', '"updatedAt"',
    )
    _COLUMN_KEYS = (
        "id", "email", "name", "passwordHash",
        "role", "address", "createdAt", "updatedAt",
    )

    def _row_to_dict(self, row):
        """Convert a DB row tuple to a dict matching the in-memory format."""
        d = dict(zip(self._COLUMN_KEYS, row))
        # Convert datetime objects to ISO strings
        for key in ("createdAt", "updatedAt"):
            val = d.get(key)
            if val is not None and hasattr(val, "isoformat"):
                d[key] = val.isoformat().replace("+00:00", "Z")
        return d

    # ------------------------------------------------------------------
    # CRUD operations (same interface as InMemoryUserStore)
    # ------------------------------------------------------------------

    def find_by_email(self, email):
        conn = self._get_conn()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    f'SELECT {", ".join(self._COLUMNS)} FROM users WHERE email = %s',
                    (email,),
                )
                row = cur.fetchone()
                return self._row_to_dict(row) if row else None
        finally:
            self._put_conn(conn)

    def find_by_id(self, user_id):
        conn = self._get_conn()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    f'SELECT {", ".join(self._COLUMNS)} FROM users WHERE id = %s',
                    (user_id,),
                )
                row = cur.fetchone()
                return self._row_to_dict(row) if row else None
        finally:
            self._put_conn(conn)

    def create(self, user_data):
        conn = self._get_conn()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """INSERT INTO users
                       (id, email, name, "passwordHash", role, address, "createdAt")
                       VALUES (%s, %s, %s, %s, %s, %s, %s)""",
                    (
                        user_data["id"], user_data["email"], user_data["name"],
                        user_data["passwordHash"], user_data["role"],
                        user_data.get("address", ""), user_data["createdAt"],
                    ),
                )
            conn.commit()
            return user_data
        finally:
            self._put_conn(conn)

    def update(self, user_id, data):
        conn = self._get_conn()
        try:
            # Build dynamic SET clause for provided fields only
            allowed = {"name", "address", "email"}
            updates = {k: v for k, v in data.items() if k in allowed}
            if not updates:
                return self.find_by_id(user_id)

            set_parts = []
            values = []
            for k, v in updates.items():
                set_parts.append(f"{k} = %s")
                values.append(v)
            set_parts.append('"updatedAt" = NOW()')
            values.append(user_id)

            with conn.cursor() as cur:
                cur.execute(
                    f'UPDATE users SET {", ".join(set_parts)} WHERE id = %s',
                    values,
                )
            conn.commit()
            return self.find_by_id(user_id)
        finally:
            self._put_conn(conn)

    def list_all(self):
        conn = self._get_conn()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    f'SELECT {", ".join(self._COLUMNS)} FROM users '
                    f'ORDER BY "createdAt" DESC'
                )
                rows = cur.fetchall()
                return [self._row_to_dict(row) for row in rows]
        finally:
            self._put_conn(conn)
