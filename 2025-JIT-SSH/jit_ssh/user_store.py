# user_store.py

"""
Handles loading and saving user data to a YAML file.
"""

import os
import yaml


class UserStore:
    def __init__(self, user_file="./db/users.yaml"):
        self.user_file = user_file
        os.makedirs(os.path.dirname(self.user_file), exist_ok=True)
        self.users = self._load()

    def _load(self):
        if not os.path.exists(self.user_file):
            return {}
        with open(self.user_file, "r") as f:
            data = yaml.safe_load(f) or {}
            return data.get("users", {})

    def _save(self):
        with open(self.user_file, "w") as f:
            yaml.safe_dump({"users": self.users}, f)

    def get(self, username):
        return self.users.get(username)

    def add(self, username, user_data):
        self.users[username] = user_data
        self._save()

    def exists(self, username):
        return username in self.users

    def all_usernames(self):
        return list(self.users.keys())
