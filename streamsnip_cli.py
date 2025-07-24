#!/usr/bin/env python3
import os
import sys
import threading
import requests
from colorama import Fore, Style
from yt_dlp import YoutubeDL, utils as ytd_utils
from urllib import parse
from concurrent.futures import ThreadPoolExecutor, as_completed

# ----------------- CONFIG -------------------
API_TEMPLATE = 'https://streamsnip.com/extension/clips/{}'
MAX_WORKERS = 5
progress_data = {}
progress_lock = threading.Lock()
stop_progress = threading.Event()

# ----------------- PROGRESS HOOKS -------------------
def make_progress_hook(index):
    def hook(d):
        if d['status'] == 'downloading':
            total = d.get('total_bytes') or d.get('total_bytes_estimate') or 1
            downloaded = d.get('downloaded_bytes', 0)
            eta = d.get('eta', 0)
            speed = d.get('speed', 0)
            string = f"{downloaded/total*100:.2f}% (ETA: {eta:.2f}s Speed: {speed/1024:.2f} KB/s)"
            with progress_lock:
                progress_data[index] = string
        elif d['status'] == 'finished':
            with progress_lock:
                progress_data[index] = "100%"
    return hook

def progress_updater(total):
    while not stop_progress.is_set():
        with progress_lock:
            lines = [f"Downloading {i+1}/{total} .... {progress_data.get(i, '0%')}" for i in range(total)]
            output = "\n".join(lines)
        sys.stdout.write("\033[H\033[J")  # clear screen
        sys.stdout.write(output + "\n")
        sys.stdout.flush()
        stop_progress.wait(0.2)

# ----------------- DOWNLOAD FUNCTION -------------------
def download_clip(index, video_url, clip, extra, fmt):
    start = int(clip['clip_time'] - extra)
    delay = clip.get('delay') or -60
    end = int(start + (-delay) + extra * 2)
    desc = clip['message'].replace(' ', '_')
    cid = clip['id']
    sid = clip['stream_id']
    ext = fmt or 'mp4'
    file_name = f"{desc}_{cid}_{sid}_{start}_{end}.{ext}"
    output_dir = os.path.join('clips', sid)
    os.makedirs(output_dir, exist_ok=True)
    outtmpl = os.path.join(output_dir, file_name)

    if os.path.exists(outtmpl):
        with progress_lock:
            progress_data[index] = "Already exists"
        return

    params = {
        "download_ranges": ytd_utils.download_range_func([], [[start, end]]),
        "outtmpl": outtmpl,
        "quiet": True,
        "progress_hooks": [make_progress_hook(index)]
    }
    if fmt:
        params["postprocessors"] = [{
            "key": "FFmpegVideoConvertor",
            "preferedformat": fmt
        }]
        params["final_ext"] = fmt

    with YoutubeDL(params) as ydl:
        ydl.download([video_url])

# ----------------- URL HELPERS -------------------
def get_video_id(video_link):
    x = parse.urlparse(video_link)
    if x.path == "/watch":
        return x.query.replace("v=", "").split("&")[0]
    if "/live/" in x.path:
        return x.path.replace("/live/", "")
    if "youtu.be" in x.netloc:
        return x.path.replace("/", "")
    return x.path

# ----------------- MAIN -------------------
def main():
    while True:
        vid = input(Fore.BLUE + 'Enter YouTube URL (or q to quit): ' + Style.RESET_ALL).strip()
        if vid.lower() == 'q':
            break
        sid = get_video_id(vid)
        resp = requests.get(API_TEMPLATE.format(sid))
        clips = resp.json() or []
        if not clips:
            print(Fore.RED + '[ERROR] No clips found.' + Style.RESET_ALL)
            continue

        print(Fore.BLUE + f'Available clips for {sid}:' + Style.RESET_ALL)
        for i, clip in enumerate(clips, 1):
            st = clip['clip_time']
            en = st + (-clip['delay'])
            print(f"{i}) {clip['message']} [ID:{clip['id']}] start={st:.2f} end={en:.2f}")

        sel = input('Select clip numbers (comma-separated, e.g. 1,3-5) or * for all: ').strip()
        if sel == '*':
            indices = list(range(1, len(clips) + 1))
        else:
            indices = []
            for part in sel.split(','):
                if '-' in part:
                    a, b = part.split('-')
                    indices.extend(range(int(a), int(b) + 1))
                else:
                    indices.append(int(part))
        indices = sorted(set(indices))
        if not indices:
            print(Fore.RED + '[ERROR] No valid clips selected.' + Style.RESET_ALL)
            continue

        adj = input('Adjust delay? (y/N): ').strip().lower()
        extra = float(input('Seconds to adjust: ')) if adj == 'y' else 0.0
        fmt = input('Enter format extension (mp4, mkv) or leave blank: ').strip() or None

        # Launch progress updater
        total = len(indices)
        t = threading.Thread(target=progress_updater, args=(total,))
        t.start()

        # Launch threaded downloads
        futures = []
        with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
            for idx, clip_index in enumerate(indices):
                futures.append(executor.submit(download_clip, idx, vid, clips[clip_index - 1], extra, fmt))
            for f in as_completed(futures):
                f.result()

        stop_progress.set()
        t.join()

        print(Fore.GREEN + f'[DONE] Clips saved under clips/{sid}' + Style.RESET_ALL)

if __name__ == '__main__':
    main()
