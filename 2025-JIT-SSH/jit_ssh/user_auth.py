import bcrypt
import pyotp
import yaml
import os
import secrets
import string
import base64


USERS_FILE = "./db/users.yaml"


def load_users():
    if not os.path.exists(USERS_FILE):
        return {"users": {}}
    with open(USERS_FILE, "r") as f:
        data = yaml.safe_load(f)
        if not data or "users" not in data:
            return {"users": {}}
        return data

def save_users(users):
    with open(USERS_FILE, "w") as f:
        yaml.safe_dump(users, f)


def hash_password(password):
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def verify_password(password, hashed):
    return bcrypt.checkpw(password.encode(), hashed.encode())


def generate_strong_password(length=12):
    alphabet = string.ascii_letters + string.digits + string.punctuation
    while True:
        password = ''.join(secrets.choice(alphabet) for _ in range(length))
        if (any(c.islower() for c in password) and
            any(c.isupper() for c in password) and
            any(c.isdigit() for c in password) and
            any(c in string.punctuation for c in password)):
            return password


def is_valid_base32(secret):
    try:
        base64.b32decode(secret, casefold=True)
        return True
    except Exception:
        return False


def register_user(username, mfa_secret, show_password=False):
    users_data = load_users()
    users = users_data.get("users", {})

    if username in users:
        print(f"❌ User '{username}' already exists.")
        return

    if not is_valid_base32(mfa_secret):
        print("❌ Provided MFA secret is not valid base32.")
        return

    password = generate_strong_password()
    password_hash = hash_password(password)

    users[username] = {
        "password_hash": password_hash,
        "mfa_secret": mfa_secret
    }

    save_users({"users": users})

    print(f"✅ User '{username}' registered successfully.")
    if show_password:
        print(f"🔐 Temporary password: {password}")
    else:
        print("🔐 Password generated and stored securely. Use '--show-password' to display.")

def authenticate_user(username, password, token):
    users_data = load_users()
    users = users_data.get("users", {})

    user = users.get(username)
    if not user:
        print("❌ Invalid username.")
        return False

    if not verify_password(password, user["password_hash"]):
        print("❌ Invalid password.")
        return False

    if not pyotp.TOTP(user["mfa_secret"]).verify(token):
        print("❌ Invalid MFA token.")
        return False

    print(f"✅ User '{username}' authenticated successfully.")
    return True