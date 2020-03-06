#!/usr/bin/python
import sys, os, json, subprocess

IMAGE_DURATION = 5

# If you get an error, install the libav-tools package for the avprobe program:
# apt-get install libav-tools
def video_duration(fname):
    # return float(subprocess.Popen([
    #     "avprobe", "-show_format_entry", "duration", fname
    # ], stdout=subprocess.PIPE, stderr=file('/dev/null', 'wb')).stdout.read())
    return IMAGE_DURATION
assets = []
for fname in os.listdir('.'):
    if fname in (
        'empty.png', 'package-header.jpg', 'package.png',
        'screenshot.jpg', 'screenshot-1.jpg', 'blank.png'
    ):
        continue
    if fname.endswith('.jpg') or fname.endswith('.png'):
        assets.append((fname, "image", IMAGE_DURATION))
    if fname.endswith('.mp4'):
        assets.append((fname, "video", video_duration(fname)))
assets.sort()

target = 'config.json'
if len(sys.argv) > 1:
    target = sys.argv[1]

with file(target, 'wb') as f:
    f.write(json.dumps(dict(
        playlist = [dict(
            duration = duration,
            file = dict(
                asset_name = fname,
                type = type,
            )
        ) for fname, type, duration in assets],
        switch_time = 0,
        kenburns = False,
        synced = False,
        rotation = 0,
        audio = True,
    )))

print("config.json created (%d assets). start info-beamer now" % len(assets))
