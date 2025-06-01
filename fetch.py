from telethon import TelegramClient
import os

api_id = int(os.getenv('TELEGRAM_API_ID'))
api_hash = os.getenv('TELEGRAM_API_HASH')
session = os.getenv('TELEGRAM_SESSION')
channel = os.getenv('TARGET_CHANNEL')
keywords = [k.strip().lower() for k in os.getenv('KEYWORDS').split(',')]

client = TelegramClient(session, api_id, api_hash)

async def main():
    await client.start()
    async for message in client.iter_messages(channel, limit=10):
        if message.text:
            lower_text = message.text.lower()
            if any(k in lower_text for k in keywords):
                print(f"{message.id}|{message.text.replace(chr(10), ' ')}")
                break

with client:
    client.loop.run_until_complete(main())
