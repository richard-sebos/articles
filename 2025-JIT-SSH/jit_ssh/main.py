from user_auth import register_user, authenticate_user

# Register user
register_user("richard", "your_password_here")

# Authenticate user
authenticate_user("richard", "your_password_here", "123456")  # 123456 = TOTP token from your app
