#!/usr/bin/env python3
"""
Email the finished digest to yourself over SMTP (SSL).

Usage:  python3 send_email.py <digest.md> [date]

Reads SMTP_HOST / SMTP_PORT / SMTP_USER / SMTP_PASS / DIGEST_TO from the env
(loaded from .env by digest.sh). Sends the Markdown as a plain-text body.

For Gmail: create an App Password (Google Account > Security > App passwords)
and put it in SMTP_PASS with the spaces removed.
"""
import os, sys, smtplib, ssl
from email.message import EmailMessage

path = sys.argv[1]
date = sys.argv[2] if len(sys.argv) > 2 else ""

body = open(path, encoding="utf-8").read()

host = os.environ["SMTP_HOST"]
port = int(os.environ.get("SMTP_PORT", "465"))
user = os.environ["SMTP_USER"]
pw = os.environ["SMTP_PASS"]
to = os.environ.get("DIGEST_TO", user)

msg = EmailMessage()
subject = f"HCM AI Digest \u2014 {date}".strip(" \u2014")
msg["Subject"] = subject
msg["From"] = user
msg["To"] = to
msg.set_content(body)

ctx = ssl.create_default_context()
with smtplib.SMTP_SSL(host, port, context=ctx) as s:
    s.login(user, pw)
    s.send_message(msg)

print(f"sent: {subject} -> {to}")
