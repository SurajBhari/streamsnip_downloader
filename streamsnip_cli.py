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
        progress_data[index] = d['status']
        return hook
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
def download_clip(index, video_url, clip, extra, fmt, force_cuts_at_keyframes):
    start = int(clip['clip_time'] - extra)
    delay = clip.get('delay') or -60
    end = int(start + (-delay) + extra * 2)
    desc = clip['message'].replace(' ', '_')
    cid = clip['id']
    sid = clip['stream_id']
    
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
        params["format"] = fmt + "+bestaudio"
    if force_cuts_at_keyframes:
        params["force_keyframes_at_cuts"] = True

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

def time_to_hms(seconds: int):
    hour = int(seconds / 3600)
    minute = int(seconds / 60) % 60
    second = int(seconds) % 60
    if hour < 10:
        hour = f"0{hour}"
    if minute < 10:
        minute = f"0{minute}"
    if second < 10:
        second = f"0{second}"
    if int(hour):
        hour_minute_second = f"{hour}:{minute}:{second}"
    else:
        hour_minute_second = f"{minute}:{second}"
    return hour_minute_second


def get_available_format(stream_id):
    video_url = f"https://youtube.com/watch?v={stream_id}"
    # Fetch available formats using yt_dlp
    params = {
        "quiet": True,
        "no_warnings": True,
        "noprogress": True,
    }

    with YoutubeDL(params) as ydl:
        try:
            info = ydl.extract_info(video_url, download=False)
            formats = info.get("formats", [])
            available_formats = [
                {
                    "format_id": f["format_id"],
                    "ext": f["ext"],
                    "format_note": f.get("format_note", "Unknown"),
                    "resolution": f.get("resolution", "Unknown"),
                    "filesize": f.get("filesize", "Unknown"),
                    "quality": f.get("quality", "Unknown"),
                }
                for f in formats
            ]

            # Save to JSON
            os.makedirs("clips", exist_ok=True)

            return available_formats[::-1][:5] # Reverse to show best formats first

        except ytd_utils.DownloadError as e:
            print(f"Download error: {e}")
            return "Failed to fetch video information", 500
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
            st = int(clip['clip_time'])
            dl = clip.get('delay') or -60
            en = int(st + (-dl) )
            print(f"{i}) {clip['message']} [ID:{clip['id']}] start={time_to_hms(st)} end={time_to_hms(en)}")

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
        last_clip = clips[-1]
        extra = 0
        while True:
            start = int(last_clip['clip_time'] - extra)
            delay = last_clip.get('delay') or -60
            end = int(start + (-delay) + extra * 2)

            print("Last clip details:")
            print(f"  Message    : {last_clip['message']}")
            print(f"  Start Time : {time_to_hms(start)}")
            print(f"  End Time   : {time_to_hms(end)}")
            adj = input('Adjust delay? (y/N): ').strip().lower()
            if adj != 'y':
                break
            try:
                extra_extra = int(input('Enter extra seconds to add to start and end (default 0): ').strip() or 0)
            except ValueError:
                print(Fore.RED + '[ERROR] Invalid number.' + Style.RESET_ALL)
                continue

            extra += extra_extra
        print(Fore.YELLOW + f'Extra seconds added: {extra}' + Style.RESET_ALL)
        available_formats = get_available_format(sid)
        fmt = input('Do You want custom format ? (y/N)').strip().lower() == 'y'
        if fmt:
            print(Fore.BLUE + 'Available formats:' + Style.RESET_ALL)
            for f in available_formats:
                print(f"Format ID: {f['format_id']}, Extension: {f['ext']}, Note: {f['format_note']}, Resolution: {f['resolution']}, Filesize: {f['filesize']}, Quality: {f['quality']}")
            fmt_id = input('Enter format ID (or leave blank for best): ').strip() or available_formats[0]['format_id']
            if fmt_id not in [f['format_id'] for f in available_formats]:
                print(Fore.RED + '[ERROR] Invalid format ID.' + Style.RESET_ALL)
                continue
        
        force_cuts_at_keyframes = input('Force cuts at keyframes? (will remove blank space from starting but may take longer time) (y/N): ').strip().lower() == 'y'
        # Launch progress updater
        total = len(indices)
        t = threading.Thread(target=progress_updater, args=(total,))
        t.start()

        # Launch threaded downloads
        futures = []
        with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
            for idx, clip_index in enumerate(indices):
                futures.append(executor.submit(download_clip, idx, vid, clips[clip_index - 1], extra, fmt_id, force_cuts_at_keyframes))
            for f in as_completed(futures):
                f.result()

        stop_progress.set()
        t.join()

        print(Fore.GREEN + f'[DONE] Clips saved under clips/{sid}' + Style.RESET_ALL)
        if input("Open Folder? (y/N): ").strip().lower() == 'y':
            os.startfile(os.path.join('clips', sid))

if __name__ == '__main__':
    main()
