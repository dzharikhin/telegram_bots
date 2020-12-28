import json
from datetime import datetime

import pytz
from telethon import TelegramClient
from telethon.tl.types import PeerChannel, Dialog, DocumentAttributeAudio

with open('api.json') as f:
    api = json.load(f)
    client = TelegramClient('app_session', api['id'], api['hash'])


async def find_chat(channel_name: str) -> Dialog:
    async for dialog in client.iter_dialogs():
        if dialog.is_channel and dialog.entity.username == channel_name.lstrip('@'):
            return dialog


async def main(channel_name, start_date):
    target_channel = await find_chat(channel_name)
    channel_entity = await client.get_entity(PeerChannel(target_channel.id))
    async for message in client.iter_messages(channel_entity, reverse=True):
        if message.date >= start_date and message.audio:
            tag = [f'{attr.performer} - {attr.title}' for attr in message.audio.attributes if isinstance(attr, DocumentAttributeAudio)][0]
            if 'None' in tag:
                tag = message.text.strip('\n')
            print(f'{tag}\t{message.views}\t{message.date}\t{message.id}')

if __name__ == '__main__':
    with client:
        client.loop.run_until_complete(main('mychannel', datetime(2019, 12, 1).astimezone(pytz.utc)))
