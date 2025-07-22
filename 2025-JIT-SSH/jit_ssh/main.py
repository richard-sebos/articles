from user_auth import register_user, authenticate_user
from ticketing import initialize_db, log_ticket, list_tickets
from ssh_ca import generate_and_sign

register_user("richard", "your_password_here")
# Authenticate user
authenticate_user("richard", "your_password_here", "123456")  # 123456 = TOTP token from your app


initialize_db()

log_ticket("richard", "Performing maintenance on DB server")
generate_and_sign("richard", validity="15m")

tickets = list_tickets()
for ticket in tickets:
    print(ticket)# Register user
