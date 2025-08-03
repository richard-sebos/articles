import pyotp
import time

# Use your known good secret
secret = "IWIIXKTYX7USSTACUGXHAXE4NIWP2UAT"  # Replace with your secret

totp = pyotp.TOTP(secret)

# Show expected token (for the current time window)
expected_token = totp.now()
print(f"Expected TOTP token (right now): {expected_token}")

# Print token window start and end timestamps
print(f"Time now (epoch): {int(time.time())}")
print(f"Token valid from {totp.interval * (int(time.time()) // totp.interval)} to {totp.interval * (int(time.time()) // totp.interval + 1)}")

# Ask user to input token from their app
user_token = input("🔐 Enter the 6-digit token from your Authenticator app: ")

# Validate token
if totp.verify(user_token):
    print("✅ Token is valid!")
else:
    print("❌ Token is invalid. Make sure clocks are synced.")
