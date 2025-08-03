import os
import subprocess

KEYS_DIR = "./keys/temp_keys/"
CA_PRIVATE_KEY = "./ca/ca_user_key"  # Path to your CA's private key


def ensure_keys_dir():
    os.makedirs(KEYS_DIR, exist_ok=True)


def generate_keypair(username):
    ensure_keys_dir()
    key_path = os.path.join(KEYS_DIR, f"{username}_ed25519")
    if os.path.exists(key_path):
        os.remove(key_path)
        os.remove(f"{key_path}.pub")

    subprocess.run([
        "ssh-keygen", "-t", "ed25519",
        "-f", key_path,
        "-N", ""
    ], check=True)

    return key_path, f"{key_path}.pub"


def sign_public_key(pubkey_file, username, validity="15m"):
    # This uses OpenSSH CA to sign the public key with a short TTL
    subprocess.run([
        "ssh-keygen", "-s", CA_PRIVATE_KEY,
        "-I", f"{username}-jit",
        "-n", username,
        "-V", f"+{validity}",
        pubkey_file
    ], check=True)


def generate_and_sign(username, validity="15m"):
    key_file, pubkey_file = generate_keypair(username)
    sign_public_key(pubkey_file, username, validity)
    cert_file = f"{key_file}-cert.pub"

    print(f"\nJIT SSH Credentials for {username}:")
    print(f"Private Key: {key_file}")
    print(f"Public Key: {pubkey_file}")
    print(f"Certificate: {cert_file}")
    print(f"\nConnect with:")
    print(f"ssh -i {key_file} -o CertificateFile={cert_file} user@your-server\n")

    return key_file, cert_file


# For testing if run directly
if __name__ == "__main__":
    generate_and_sign("richard")
