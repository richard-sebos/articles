"""
user_auth_manager.py

This module defines the UserAuthManager class, which handles user registration
and authentication using secure password hashing (bcrypt) and TOTP-based MFA (pyotp).
It is designed to support a zero-trust model by requiring short-lived, validated credentials.

Dependencies:
- PasswordManager: Handles password hashing and generation
- UserStore: Handles persistent user storage in YAML format
- pyotp: Verifies TOTP-based tokens

Author: Richard Chamberlain
"""

import base64
import pyotp
from password_manager import PasswordManager
from user_store import UserStore


class UserAuthManager:
    """
    Manages user registration and authentication with password and TOTP-based MFA.

    This class is the core of the authentication system and delegates:
    - Password logic to PasswordManager
    - Data persistence to UserStore

    Typical Usage:
        auth = UserAuthManager()
        auth.register_user("alice", "JBSWY3DPEHPK3PXP", show_password=True)
        auth.authenticate_user("alice", "securepass123", "123456")
    """

    def __init__(self, user_file="./db/users.yaml"):
        """
        Initialize the UserAuthManager.

        Args:
            user_file (str): Path to the user YAML file used by UserStore.
        """
        self.store = UserStore(user_file)
        self.password_manager = PasswordManager()

    def _is_valid_base32(self, secret):
        """
        Validate that a string is base32-encoded, suitable for TOTP.

        Args:
            secret (str): The TOTP secret to validate.

        Returns:
            bool: True if valid base32, False otherwise.
        """
        try:
            base64.b32decode(secret, casefold=True)
            return True
        except Exception:
            return False

    def register_user(self, username, mfa_secret, show_password=False):
        """
        Register a new user with a secure password and existing TOTP secret.

        Args:
            username (str): The user's login name.
            mfa_secret (str): A valid base32 TOTP secret already added to their authenticator app.
            show_password (bool): If True, print the generated password for the user to see.

        Notes:
            - Will not overwrite existing users.
            - Passwords are securely hashed and stored.
        """
        if self.store.exists(username):
            print(f"❌ User '{username}' already exists.")
            return

        if not self._is_valid_base32(mfa_secret):
            print("❌ Invalid TOTP secret. Must be base32.")
            return

        # Generate and hash a secure password
        password = self.password_manager.generate_strong_password()
        password_hash = self.password_manager.hash_password(password)

        # Store the user data
        self.store.add(username, {
            "password_hash": password_hash,
            "mfa_secret": mfa_secret
        })

        print(f"✅ User '{username}' registered.")
        if show_password:
            print(f"🔐 Temporary password: {password}")
        else:
            print("🔐 Password stored securely. Use '--show-password' to display it.")

    def authenticate_user(self, username, password, token):
        """
        Authenticate a user by verifying both password and TOTP token.

        Args:
            username (str): The username.
            password (str): The plain-text password entered by the user.
            token (str): The 6-digit MFA token from their authenticator app.

        Returns:
            bool: True if all credentials are valid, False otherwise.
        """
        user = self.store.get(username)
        if not user:
            print("❌ Invalid username.")
            return False

        if not self.password_manager.verify_password(password, user["password_hash"]):
            print("❌ Invalid password.")
            return False

        if not pyotp.TOTP(user["mfa_secret"]).verify(token):
            print("❌ Invalid MFA token.")
            return False

        print(f"✅ User '{username}' authenticated.")
        return True

    def list_users(self):
        """
        Get a list of all registered usernames.

        Returns:
            list: List of usernames as strings.
        """
        return self.store.all_usernames()
