"""
ticket_logger.py

This module defines a class `TicketLogger` that logs user access tickets
to an SQLite database for auditing or JIT access tracking.

Each ticket contains:
- a unique ID
- the username
- the reason for access
- a UTC timestamp

Author: Richard Chamberlain
"""

import sqlite3
import os
from datetime import datetime


class TicketLogger:
    """
    Handles logging and retrieval of access tickets to/from an SQLite database.
    """

    def __init__(self, db_path="./db/tickets.sqlite"):
        """
        Initialize the TicketLogger and ensure the database and table exist.

        Args:
            db_path (str): Path to the SQLite database file.
        """
        self.db_path = db_path
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        self._initialize_db()

    def _initialize_db(self):
        """
        Create the tickets table if it doesn't already exist.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS tickets (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user TEXT NOT NULL,
                    reason TEXT NOT NULL,
                    timestamp TEXT NOT NULL
                )
            ''')
            conn.commit()

    def log_ticket(self, user, reason):
        """
        Log a ticket with a reason for access and the current UTC timestamp.

        Args:
            user (str): Username requesting access.
            reason (str): Description of why access is needed.
        """
        timestamp = datetime.utcnow().isoformat() + "Z"
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(
                'INSERT INTO tickets (user, reason, timestamp) VALUES (?, ?, ?)',
                (user, reason, timestamp)
            )
            conn.commit()

    def list_tickets(self):
        """
        Retrieve all tickets in reverse chronological order.

        Returns:
            list of tuple: Each tuple contains (id, user, reason, timestamp)
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(
                'SELECT id, user, reason, timestamp FROM tickets ORDER BY id DESC'
            )
            return cursor.fetchall()


# -------------------------
# 🔧 Example CLI usage
# -------------------------
if __name__ == "__main__":
    logger = TicketLogger()

    # Log an example access request
    logger.log_ticket("richard", "Example ticket for SSH JIT access testing")

    # Print all logged tickets
    for ticket in logger.list_tickets():
        print(ticket)
