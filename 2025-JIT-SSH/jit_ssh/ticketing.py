import sqlite3
import os
from datetime import datetime

DB_PATH = "./db/tickets.sqlite"


def initialize_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS tickets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user TEXT NOT NULL,
            reason TEXT NOT NULL,
            timestamp TEXT NOT NULL
        )
    ''')
    conn.commit()
    conn.close()


def log_ticket(user, reason):
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    timestamp = datetime.utcnow().isoformat() + "Z"
    c.execute(
        'INSERT INTO tickets (user, reason, timestamp) VALUES (?, ?, ?)',
        (user, reason, timestamp)
    )
    conn.commit()
    conn.close()


def list_tickets():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('SELECT id, user, reason, timestamp FROM tickets ORDER BY id DESC')
    rows = c.fetchall()
    conn.close()
    return rows


# If you want to run this directly for testing
if __name__ == "__main__":
    initialize_db()
    log_ticket("richard", "Example ticket for SSH JIT access testing")
    for ticket in list_tickets():
        print(ticket)
