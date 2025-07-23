import pyotp
import qrcode



def generate_qr_code(uri):
    """
    Generate and display a QR code for the provided URI.
    """
    print(uri)
    qr = qrcode.make(uri)
    qr.show()  # This opens the image in the default image viewer
    # Optionally, save the QR code as an image file
    qr.save("mfa_qr_code.png")


def generate_mfa_secret():
    """
    Generates a new TOTP secret for MFA.
    """
    return pyotp.random_base32()


def get_mfa_uri(username, secret, issuer="JIT-SSH-Access"):
    """
    Returns the provisioning URI for a QR code for Google Authenticator.
    This can be turned into a QR code using tools like qrencode.
    """
    totp = pyotp.TOTP(secret)
    return totp.provisioning_uri(name=username, issuer_name=issuer)


def verify_mfa_token(secret, token):
    """
    Verifies the given TOTP token against the secret.
    """
    totp = pyotp.TOTP(secret)
    return totp.verify(token)


# For testing
if __name__ == "__main__":
    username = "richard"
    secret = generate_mfa_secret()
    uri = get_mfa_uri(username, secret)

    print(f"Secret (store this securely!): {secret}")
    print(f"Google Authenticator URI:\n{uri}\n")
    
    print("Use this URI with a QR Code generator (e.g., qrencode) or enter the secret manually.")
    input_token = input("Enter current TOTP token: ")
    if verify_mfa_token(secret, input_token):
        print("MFA verification successful.")