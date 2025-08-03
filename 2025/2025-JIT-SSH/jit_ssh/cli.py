"""
cli.py

This script provides a command-line interface to manage:
- User registration with MFA secret
- MFA token verification
- Logging access requests (tickets)
- Generating JIT SSH ephemeral keys and certs

Author: Richard Chamberlain
"""

import argparse
from user_auth_manager import UserAuthManager
from password_manager import PasswordManager
from mfa_manager import MFA
from ticket_logger import TicketLogger
from ssh_ca import generate_and_sign  # Assumes you already created this function
import getpass
import os

def register_user(args):
    mfa_secret = args.secret
    if not mfa_secret:
        print("❌ You must provide a valid base32 MFA secret using --secret")
        return
    auth = UserAuthManager()
    auth.register_user(args.username, mfa_secret, show_password=args.show_password)

def generate_mfa(args):
    mfa = MFA(args.username)
    print(f"🔐 Secret: {mfa.get_secret()}")
    print(f"🔗 URI: {mfa.get_uri()}")
    mfa.generate_qr_code()

def create_ticket_and_key(args):
    auth = UserAuthManager()
    logger = TicketLogger()

    password = getpass.getpass("🔑 Password: ")
    token = input("📲 MFA token: ")

    if not auth.authenticate_user(args.username, password, token):
        print("❌ Authentication failed. Cannot proceed.")
        return

    logger.log_ticket(args.username, args.reason)
    print("📝 Ticket logged.")

    generate_and_sign(args.username, validity="15m")


def main():
    parser = argparse.ArgumentParser(description="JIT SSH CLI Tool")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Register user
    register = subparsers.add_parser("register", help="Register a new user")
    register.add_argument("username")
    register.add_argument("--secret", help="User's TOTP secret (base32)", required=True)
    register.add_argument("--show-password", action="store_true")
    register.set_defaults(func=register_user)

    # Generate MFA QR code
    mfa = subparsers.add_parser("generate-mfa", help="Generate MFA QR code")
    mfa.add_argument("username")
    mfa.set_defaults(func=generate_mfa)

    # Log a ticket and generate a JIT SSH key
    ticket = subparsers.add_parser("jit-access", help="Log ticket and generate JIT SSH cert")
    ticket.add_argument("username")
    ticket.add_argument("reason", help="Reason for access")
    ticket.set_defaults(func=create_ticket_and_key)

    args = parser.parse_args()
    args.func(args)

if __name__ == "__main__":
    main()
