import bcrypt
import pyotp
import yaml
import os


USERS_FILE = "./db/users.yaml"


def load_users():
    if not os.path.exists(USERS_FILE):
        return {"users": {}}
    with open(USERS_FILE, "r") as f:
        return yaml.safe_load(f)


def save_users(users):
    with open(USERS_FILE, "w") as f:
        yaml.safe_dump(users, f)


def hash_password(password):
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def verify_password(password, hashed):
    return bcrypt.checkpw(password.encode(), hashed.encode())


def verify_mfa(secret, token):
    totp = pyotp.TOTP(secret)
    return totp.verify(token)


def register_user(username, password):
    users_data = load_users()
    users = users_data.get("users", {})

    if username in users:
        print(f"User '{username}' already exists.")
        return

    hashed = hash_password(password)
    secret = pyotp.random_base32()

    users[username] = {
        "password_hash": hashed,
        "mfa_secret": secret
    }

    save_users({"users": users})

    print(f"User '{username}' registered successfully.")
    print(f"TOTP Secret for {username} (add to Google Authenticator): {secret}")


def authenticate_user(username, password, token):
    users_data = load_users()
    users = users_data.get("users", {})

    user = users.get(username)
    if not user:
        print("Invalid username.")
        return False

    if not verify_password(password, user["password_hash"]):
        print("Invalid password.")
        return False

    if not verify_mfa(user["mfa_secret"], token):
        print("Invalid MFA token.")
        return False

    print(f"User '{username}' authenticated successfully.")
    return True
