# SSH Auth Key Rotation

- How often when setting up a new server have you setup SSH auth key and continued to use that key.
- Weeks, months, year?
- SSH auth keys give us that false sense of security.
- It's true that also long as the private key is secure your fine. 
- Just like password, SSH keys should expire and need to be changed
- Do SSH auth key expired?

Table of Contents

## How Keys work
- On you local system, you create a private and public key pair
- You keep the private key stored securely stored on you local system
- the public key is added to the `authorized_keys` file and used to validate the private key when turing to log on

## Do SSH Key Expire
- SSH does not directly allow for keys to expire.
- It's just not build in to the process.
- You can use CA certificates to build keys that expire and I will be create an article on that in the future
- So how do we exipre keys without CA certificates?

## AuthorizedKeys Directive
- The sshd_config files a AuthorizedKeys directives to setup how auth keys are retrieved.
- `AuthorizedKeysFile none` is used to disable looking in the user's .ssh directory
- the `AuthorizedKeysCommand` specifies the file to user to retrieve the keys

```bash
## bypass nornal lookup of auth keys
AuthorizedKeysFile none

## Uses the below script to retrieve auth key
AuthorizedKeysCommand /usr/local/bin/ssh-key-expiry-check

```
- To successfully login in the script needs to return a validate SSH Auth Key

## What does the script do
- the Bash script reads a json file that has
  - system user for the key
  - a list of public keys for that user
  - an expiry date for each key

```json
{
  "richard": [
    {
      "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICn4EzI2g9gqlWCw6V1jvysZiO5tKLn/zbUalRWJRL3o sebos@dockOnWall.sebostechnology.local",
      "expires": "2025-08-01"
    }
  ]
}
```
- the script reads parse the json full for this users and looks for auth keys that are not expired.
- it returns them to the sshd server to validate them with the SSH private key provided by the logging running on the client

```bash
# Get the username passed as the first argument from sshd
USER="$1"

# Path to the JSON file containing public keys and expiration dates
KEYS_FILE="/etc/ssh/user_keys.json"

# Use jq to:
# 1. Access the list of keys for the specified user.
# 2. For each key, parse the "expires" field (YYYY-MM-DD) into a timestamp.
# 3. Compare the timestamp with the current time (`now`) and keep only keys
#    that have not yet expired.
# 4. Output the "key" field (the SSH public key) for each valid entry.
jq -r --arg user "$USER" '
  .[$user][] |
  select((.expires | strptime("%Y-%m-%d") | mktime) >= now) |
  .key
' "$KEYS_FILE"
```
- if there is a key that matched the private key, the uses is allowed to log in.
- when the keys are expired, the login is blocked
```bash
ssh rockey
Received disconnect from UNKNOWN port 65535:2: Too many authentication failures
Disconnected from UNKNOWN port 65535

```

## Do the key really expire?
- not really, this is more of artifical expire
- if you change the date in the json file or set the sshd_config back to the default, the keys will still work
- so why use these, 
    - If you have existing key and you want to add expiration
    - You have a small set up servers/keys
    - It can easily be removed without affecting the ssh auth keys
> Note: Before adding this, make sure you have another to login onto the system, else you could log youself out

- If you wanted a more secure method of expiring keys, I would suggest looking in to CA cert which have a hard expiry date and use the normal SSH configuration.
