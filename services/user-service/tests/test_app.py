import unittest
from app import app

class UserServiceTestCase(unittest.TestCase):

    def setUp(self):
        self.client = app.test_client()
        self.client.testing = True

    def test_health(self):
        response = self.client.get('/health')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json['status'], 'healthy')

    def test_login_success(self):
        response = self.client.post(
            '/auth/login',
            json={
                'email': 'alice@cloudmart.example',
                'password': 'password123'
            }
        )

        self.assertEqual(response.status_code, 200)
        self.assertIn('token', response.json)

    def test_login_invalid_password(self):
        response = self.client.post(
            '/auth/login',
            json={
                'email': 'alice@cloudmart.example',
                'password': 'wrong-password'
            }
        )

        self.assertEqual(response.status_code, 401)

    def test_register_user(self):
        response = self.client.post(
            '/auth/register',
            json={
                'email': 'newuser@test.com',
                'password': 'password123',
                'name': 'New User'
            }
        )

        self.assertEqual(response.status_code, 201)
        self.assertIn('token', response.json)

    def test_verify_without_token(self):
        response = self.client.get('/auth/verify')

        self.assertEqual(response.status_code, 401)

if __name__ == '__main__':
    unittest.main()