- With GUI interfaces and web applications being around for decades now, it some times hard to believe we still have apps running in SSH shells.
- It they still exist today, and if now setup right could provide users with access to the commandline
- So additional steps need to be taked to stop the user from getting access.
- Good news is, it not hard to do and can be added quickly

## What is  SSH Application Shell
- SSH Application Shell are applications that run from the Linux terminal and an easy way from end users to access them is from SSH term
- Putty and other SSH clients are a convent way to run them.
- they make for light weight app
- It does provide a way to setup access to the app that is indepentant of the users home drive setup adding a layer of security built in
- Extra steps are needed to secure these apps to end users can not break out and get to a command prompt

## Setup the App
- A simple Python script will be used for the app.
- The needs to be self-contained and it is added to /opt/test_app/app_entrypoint.py
- As part of the app, a function is called to disable critical control characters Ctrl+C (SIGINT) and Ctrl+Z (SIGTSTP)

```python
def disable_signals():
    # Ignore Ctrl+C (SIGINT) and Ctrl+Z (SIGTSTP)
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    signal.signal(signal.SIGTSTP, signal.SIG_IGN)

```
- See full code [here]()
- This stop the user from drop into a shell terminal
- Because the app waits for input from the user, special code was enter into to stop Ctrl+D (EOF).
```python
    while True:
        try:
            choice = input("Select an option [1-4]: ").strip()
        except EOFError:
            print("\n❌ Ctrl+D detected. Exiting securely.")
            time.sleep(1)
            break
```
- If the user enter Ctrl+D, the app exists and the users exit from terminal session

## SSH Setup for the App
- When setting up the app, it is common for the app to be called from:
  - User home folder, through .bashrc or other user step files
  - through SSH login in the SSHD setup
- In this article we will focus on the latter
- App users were addedd to a app_group Linux group.
- The SSH option `Match group` was used confined those users at login

```bash
Match Group app_group
    ForceCommand /opt/test_app/app_entrypoint.py
    PermitTTY yes
    AllowTcpForwarding no
    X11Forwarding no
```
- when the user logins in SSH confineds the by
  - force the seesion to run `/opt/test_app/app_entrypoint.py`
  - `PermitTTY` yes allows for interactive apps that read user input
  - and stop the user from using these session from forward to other servers.

## So what have we done
- We setup SSH to the users is forced into run the app using groups and SSH
- Admin and system users still can log in as normal
- We stop the user from breaking out of the app
- The app can still access other parts of the Linux filesystem and can run OS command within the app, which is outside the scope here.
- What is left to do

## What about using console?
- If the end user using ssh client to connect to the server, we have them confined
- but the account is still open for console and `su-l` access.
- to terminal the sesssions, the below were added to the `.bashrc` file
```bash
if [ -z "$SSH_CONNECTION" ]; then
  echo "🚫 Direct login is not allowed."
  exit 1
fi
```
- It check for non-SSH logins and exits from the system

- So does adding these protects mean we don't trust our end user?
- Yes, we do trust them.
- In most cases, the end users do not have the access or intent to cause harm to the system if it is setup proporely
- If a threat actor were to break or get access to one of these accounts, we want to make it hard from them to get access.
- Security needs to be added in layers and beyond what files or apps a users needs, does the user need terminal access too.
