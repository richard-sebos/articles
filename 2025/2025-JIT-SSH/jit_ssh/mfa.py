"""
mfa_manager.py

This module provides a reusable class for handling Time-based One-Time Password (TOTP)
Multi-Factor Authentication (MFA) using `pyotp` and `qrcode`.

Features:
- Generate a secure TOTP secret
- Create a provisioning URI for Google Authenticator
- Generate and show/save a QR code for easy setup
- Verify user-provided TOTP tokens
- Designed for CLI or automation workflows (MacBook/Linux compatible)

Author: Richard Chamberlain
"""

import pyotp
import qrcode


class MFA:
    """
    MFA - A class to manage TOTP-based Multi-Factor Authentication.

    Attributes:
        username (str): The username or label for the MFA identity.
        issuer (str): The name of the service or organization (e.g., "JIT-SSH-Access").
        secret (str): The base32 TOTP secret used to generate and verify tokens.
    """

    def __init__(self, username, secret=None, issuer="JIT-SSH-Access"):
        """
        Initialize the MFA class with a username and optional secret.

        Args:
            username (str): The identity label shown in the authenticator app.
            secret (str, optional): An existing base32 secret. If not provided, a new one will be generated.
            issuer (str): The name of the service/issuer displayed in the MFA app.
        """
        self.username = username
        self.issuer = issuer
        self.secret = secret or self.generate_secret()
        self.totp = pyotp.TOTP(self.secret)

    def generate_secret(self):
        """
        Generate a new base32 TOTP secret.

        Returns:
            str: A randomly generated TOTP secret.
        """
        return pyotp.random_base32()

    def get_uri(self):
        """
        Generate the provisioning URI for use with Google Authenticator apps.

        Returns:
            str: A URI that can be encoded into a QR code or used manually.
        """
        return self.totp.provisioning_uri(name=self.username, issuer_name=self.issuer)

    def generate_qr_code(self, filename="mfa_qr_code.png", show=True):
        """
        Generate a QR code from the provisioning URI.

        Args:
            filename (str): Filename to save the QR code image.
            show (bool): Whether to open the image after generation.

        Notes:
            The QR code image is useful for scanning into apps like Google Authenticator.
        """
        uri = self.get_uri()
        print(f"Provisioning URI for {self.username}:\n{uri}\n")

        qr = qrcode.make(uri)
        qr.save(filename)

        if show:
            qr.show()  # Opens in default image viewer

    def verify_token(self, token):
        """
        Verify the user-provided TOTP token against the stored secret.

        Args:
            token (str): The 6-digit code from the user's authenticator app.

        Returns:
            bool: True if valid, False otherwise.
        """
        return self.totp.verify(token)

    def get_secret(self):
        """
        Return the TOTP secret.

        Returns:
            str: The base32 secret string.
        """
        return self.secret


# -------------------------
# 🔧 Example CLI test usage
# -------------------------
if __name__ == "__main__":
    # Example for a user named 'richard'
    user = MFA("richard")

    # Show the secret so it can be saved or manually entered
    print(f"🔐 Secret (store securely): {user.get_secret()}")

    # Show the URI and generate the QR code
    print(f"🔗 URI: {user.get_uri()}")
    user.generate_qr_code()

    # Ask user to enter token and verify
    token = input("🔑 Enter current token from your Authenticator app: ")
    if user.verify_token(token):
        print("✅ MFA verification successful.")
    else:
        print("❌ MFA verification failed.")
