# Bot to collect channel view statistics
make api.json with required attributes, set your channel name in main - collect the stats
# Telegram bot on Powershell which allows to download multiple photos at once
- /start_session - creates temp session for the current chat to store file list
- /complete_session - downloads all files stored in session into ./photo folder and resets session for the current chat
<br>
To send file - just forward message with photo to the bot after /start_session is called and before /complete_session is called. Telegram desktop allows 100 messages forward max - but it's better than one anyway)
<br>
Bot token is taken from environment variable: $Env:bulk_file_bot_token = "your_token here"

з.ы. Vote for (original issue) https://github.com/telegramdesktop/tdesktop/issues/1382