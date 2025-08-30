!/usr/bin/env python3

import os
import signal
import time

def disable_signals():
    # Ignore Ctrl+C (SIGINT) and Ctrl+Z (SIGTSTP)
    #signal.signal(signal.SIGINT, signal.SIG_IGN)
    #signal.signal(signal.SIGTSTP, signal.SIG_IGN)
    pass

def clear_screen():
    os.system('clear')

def main():
    disable_signals()
    clear_screen()

    print("🔐 Welcome to the Test CLI App")
    print("==============================")
    print("1. Check system time")
    print("2. Display logged-in user")
    print("3. Simulate processing task")
    print("4. Exit")
    print("==============================")

    while True:
        try:
            choice = input("Select an option [1-4]: ").strip()
        except EOFError:
            print("\n❌ Ctrl+D detected. Exiting securely.")
            time.sleep(1)
            break

        if choice == "1":
            print("🕒 Current system time:", time.strftime("%Y-%m-%d %H:%M:%S"))
        elif choice == "2":
            print("👤 You are logged in as:", os.getenv("USER", "Unknown"))
        elif choice == "3":
            print("⌛ Simulating task...")
            time.sleep(2)
            print("✅ Task completed.")
        elif choice == "4":
            print("👋 Exiting. Goodbye.")
            time.sleep(1)
            break
        else:
            print("❌ Invalid option. Try again.")

if __name__ == "__main__":
    main()
