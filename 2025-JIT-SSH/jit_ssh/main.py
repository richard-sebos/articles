from user_auth import register_user, authenticate_user
from ticketing import initialize_db, log_ticket, list_tickets
from ssh_ca import generate_and_sign
from mfa import generate_mfa_secret, get_mfa_uri

secret = generate_mfa_secret()
print(f"Secret: {secret}")
print(get_mfa_uri("richard", secret))
qrencode -o richard.png "otpauth://totp/JIT-SSH-Access:richard?secret=SECRET&issuer=JIT-SSH-Access"

register_user("richard", "your_password_here")
# Authenticate user
authenticate_user("richard", "your_password_here", "123456")  # 123456 = TOTP token from your app


secret = generate_mfa_secret()
print(f"Secret: {secret}")
print(get_mfa_uri("richard", secret))


initialize_db()

log_ticket("richard", "Performing maintenance on DB server")
generate_and_sign("richard", validity="15m")

tickets = list_tickets()
for ticket in tickets:
    print(ticket)# Register user
