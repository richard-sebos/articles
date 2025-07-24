"""
password_manager.py

This module provides password-related functionality:
- Secure hashing using bcrypt
- Password verification
- Strong password generation with complexity rules

Designed for reuse in any user or access control system.

Author: Richard Chamberlain
"""

import bcrypt
import secrets
import string


class PasswordManager:
    """
    Handles password generation, hashing, and verification.
    """

    def __init__(self, min_length=12):
        self.min_length = min_length

    def generate_strong_password(self):
        """
        Generate a strong, random password with letters, digits, and punctuation.

        Returns:
            str: A secure password.
        """
        chars = string.ascii_letters + string.digits + string.punctuation
        while True:
            password = ''.join(secrets.choice(chars) for _ in range(self.min_length))
            if (any(c.islower() for c in password) and
                any(c.isupper() for c in password) and
                any(c.isdigit() for c in password) and
                any(c in string.punctuation for c in password)):
                return password

    def hash_password(self, password):
        """
        Hash a plain text password using bcrypt.

        Args:
            password (str): The password to hash.

        Returns:
            str: The hashed password.
        """
        return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

    def verify_password(self, password, hashed):
        """
        Verify a plain password against its bcrypt hash.

        Args:
            password (str): User-entered password.
            hashed (str): Stored hash.

        Returns:
            bool: True if match, False otherwise.
        """
        return bcrypt.checkpw(password.encode(), hashed.encode())
