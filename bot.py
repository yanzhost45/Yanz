"""
Simple Telegram bot (long-polling) - single-file implementation
Features:
- Responds to /start and /help
- /ping -> replies "Pong"
- Echoes any non-command message
- Only accepts commands from OWNER_ID for admin-only actions (example)

How to run:
1. Install Python 3.
2. Save this file as bot.py
3. (Optional) Install requirements: pip install requests
4. Run: python3 bot.py

Set TOKEN and OWNER_ID below.
"""

import time
import requests
import sys

# --- CONFIG ---
TOKEN = "7974171410:AAHLbyCDz70jpe_T3dVnDbq9IGtekVKBedU"  # ganti jika perlu
OWNER_ID = 7986943327
POLL_INTERVAL = 1.0  # detik

API = f"https://api.telegram.org/bot{TOKEN}"

def get_updates(offset=None, timeout=20):
    params = {"timeout": timeout}
    if offset:
        params["offset"] = offset
    r = requests.get(API + "/getUpdates", params=params)
    r.raise_for_status()
    return r.json().get("result", [])

def send_message(chat_id, text, reply_to=None):
    params = {"chat_id": chat_id, "text": text}
    if reply_to:
        params["reply_to_message_id"] = reply_to
    requests.post(API + "/sendMessage", data=params)

def handle_update(update):
    # update -> dict
    if "message" not in update:
        return
    msg = update["message"]
    chat_id = msg["chat"]["id"]
    text = msg.get("text", "")
    from_id = msg["from"]["id"]

    # simple commands
    if text.startswith("/"):
        cmd = text.split()[0].lower()
        if cmd == "/start":
            send_message(chat_id, "Hai! aku bot simpel. Ketik /help untuk daftar perintah.")
            return
        if cmd == "/help":
            help_text = (
                "Perintah yang tersedia:\n"
                "/start - Sambutan\n"
                "/help - Tampilkan bantuan\n"
                "/ping - Cek respons bot\n"
                "Bisa juga kirim pesan biasa untuk di-echo."
            )
            send_message(chat_id, help_text)
            return
        if cmd == "/ping":
            send_message(chat_id, "Pong")
            return
        # contoh perintah admin
        if cmd == "/say" and from_id == OWNER_ID:
            # format: /say pesan...
            body = text.partition(" ")[2]
            if body:
                send_message(chat_id, body)
            else:
                send_message(chat_id, "Gunakan: /say teks yang ingin dikirim")
            return
        # unknown command
        send_message(chat_id, "Perintah tidak dikenal. Ketik /help.")
        return

    # non-command: echo
    if text:
        # contoh: jangan echo jika pesan terlalu panjang
        if len(text) > 1000:
            send_message(chat_id, "Pesan terlalu panjang untuk di-echo.")
        else:
            send_message(chat_id, f"Echo: {text}")


def main():
    print("Bot starting...")
    offset = None
    try:
        while True:
            try:
                updates = get_updates(offset=offset)
                for upd in updates:
                    offset = upd["update_id"] + 1
                    try:
                        handle_update(upd)
                    except Exception as e:
                        # jika terjadi error pada update tertentu, kirim ke owner
                        try:
                            send_message(OWNER_ID, f"Error handling update {upd.get('update_id')}: {e}")
                        except Exception:
                            pass
                time.sleep(POLL_INTERVAL)
            except requests.exceptions.RequestException as e:
                print("Network error:", e)
                time.sleep(5)
    except KeyboardInterrupt:
        print("Bot stopped by user")
        sys.exit(0)

if __name__ == '__main__':
    main()
