from django.test import TestCase
from django.urls import reverse
from django.contrib.auth.models import User

class SimpleTestCase(TestCase):
    def test_basic_setup(self):
        """Test that Django is properly configured"""
        self.assertTrue(True)
    
    def test_database_connection(self):
        """Test SQLite database connection"""
        from django.db import connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            self.assertEqual(result[0], 1)


class BlogViewsTestCase(TestCase):
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            username='testuser',
            password='testpass123'
        )

    def test_public_view_accessible(self):
        """Test that public view is accessible"""
        response = self.client.get(reverse('public'))
        self.assertEqual(response.status_code, 200)

    def test_login_view_accessible(self):
        """Test that login view is accessible"""
        response = self.client.get(reverse('login'))
        self.assertEqual(response.status_code, 200)

    def test_private_view_requires_login(self):
        """Test that private view requires login"""
        response = self.client.get(reverse('protected'))
        self.assertEqual(response.status_code, 302)  # Redirect to login

    def test_private_view_accessible_when_logged_in(self):
        """Test that private view is accessible when logged in"""
        self.client.login(username='testuser', password='testpass123')
        response = self.client.get(reverse('protected'))
        self.assertEqual(response.status_code, 200)
