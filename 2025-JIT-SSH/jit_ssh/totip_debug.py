import pyotp
import time
from datetime import datetime
import zoneinfo  # Available in Python 3.9+

# Your base32 TOTP secret
secret = "IWIIXKTYX7USSTACUGXHAXE4NIWP2UAT"  # Replace with your actual TOTP secret

# Set your timezone: Saskatchewan (no DST)
regina_tz = zoneinfo.ZoneInfo("Canada/Saskatchewan")

# Create TOTP object
totp = pyotp.TOTP(secret)

# Get current time details
unix_time = int(time.time())
local_time = datetime.now(regina_tz).strftime("%Y-%m-%d %H:%M:%S")

print(f"🔍 Unix time now: {unix_time}")
print(f"🕰️  Local time (Regina, SK): {local_time}")
print(f"🧮 TOTP interval: {totp.interval} seconds")

# Show the expected token
print(f"🔐 TOTP token from Python: {totp.now()}")

# Ask for user token to verify
user_token = input("🔑 Enter the token from your app: ")
if totp.verify(user_token):
    print("✅ Token is valid!")
else:
    print("❌ Invalid token. Check time sync or secret.")
