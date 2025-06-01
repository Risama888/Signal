from telethon import TelegramClient

# Ganti dengan API ID dan API Hash dari my.telegram.org

api_id = '25492239'
api_hash = 'c44ecddaf2c2d192bc4abee556cfc107'

# Nama session yang akan disimpan
session_name = 'my_session'

# Membuat instance TelegramClient
client = TelegramClient(session_name, api_id, api_hash)

async def main():
    # Mulai koneksi dan login
    await client.start()
    print("Session berhasil dibuat dan tersimpan.")
    # Anda bisa menambahkan kode lain di sini sesuai kebutuhan

# Menjalankan program secara asynchronous
with client:
    client.loop.run_until_complete(main())

# Setelah sesi dibuat, file session akan tersimpan secara otomatis dengan nama sesuai session_name
