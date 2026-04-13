# Security

- **Never commit** `.env`, `gateway-data/.env`, or Alpaca/Telegram/Gemini keys.
- **Rotate** any API key or password that appeared in chat, logs, or tickets.
- Prefer **SSH keys** over passwords; lock SSH to key-only and firewall (UFW) **22** to your IP if possible.
- **Caddy** obtains public TLS certs automatically; keep **80/443** reachable from the internet for HTTP-01.
- Hermes: use **`TELEGRAM_ALLOWED_USERS`**; do not expose the bot token.
