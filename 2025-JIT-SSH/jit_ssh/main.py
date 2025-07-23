import argparse
from user_auth import authenticate_user
from ticketing import initialize_db, log_ticket
from ssh_ca import generate_and_sign
import getpass

def login_and_request_access(username):
    password = getpass.getpass("🔑 Enter password: ")
    token = input("📲 Enter 6-digit TOTP code: ")

    if not authenticate_user(username, password, token):
        print("❌ Access denied.")
        return

    reason = input("📝 What is the reason for this access? ")
    log_ticket(username, reason)
    generate_and_sign(username, validity="15m")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="JIT SSH Access Tool")
    subparsers = parser.add_subparsers(dest="command", required=True)

    login_parser = subparsers.add_parser("login")
    login_parser.add_argument("username")

    args = parser.parse_args()

    initialize_db()

    if args.command == "login":
        login_and_request_access(args.username)