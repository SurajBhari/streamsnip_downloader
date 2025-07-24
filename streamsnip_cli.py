#!/usr/bin/env python3
"""
StreamSnip Downloader CLI (Python)
Requirements: git, python3, pip-installable packages (yt-dlp, requests, colorama)
Uses yt_dlp download_ranges to fetch only clip segment.
"""
import os
import sys
import subprocess
from colorama import Fore, Style
import requests
from yt_dlp import YoutubeDL, utils as ytd_utils

# Configuration
REPO_URL = 'https://github.com/surajbhari/streamsnip_downloader.git'
API_TEMPLATE = 'https://streamsnip.com/extension/clips/{}'

# Helper to run commands
def run_cmd(cmd, cwd=".", capture=False):
    result = subprocess.run(cmd, shell=True, cwd=cwd,
                            stdout=subprocess.PIPE if capture else None,
                            stderr=subprocess.PIPE if capture else None,
                            text=True)
    return result.stdout.strip() if capture else None

# Ensure repo directory exists and update from remote
# if "--no-update" not in sys.argv:
if "--no-update" not in sys.argv:
    print(Fore.GREEN + '[INFO]' + Style.RESET_ALL + ' Initializing Git repo and fetching latest code...')
    run_cmd('git init')
    run_cmd(f'git remote remove origin')
    run_cmd(f'git remote add origin {REPO_URL}')
    run_cmd('git fetch origin')
    run_cmd('git reset --hard origin/main')
    run_cmd("clear")
    run_cmd('cls')
    print(Fore.GREEN + '[DONE] Repo initialized and updated.' + Style.RESET_ALL)
else:
    print(Fore.YELLOW + '[WARN] Skipping repo update as --no-update flag is set.' + Style.RESET_ALL)

# Download and store using ranges
def download_and_store(video_url, clip, extra=0.0, fmt=None):
    start = int(clip['clip_time'] + -extra)
    delay = clip.get('delay') or -60
    # compute end based on delay
    end = int(start + (-delay) + extra*2)  # double the extra to account for both ends
    desc = clip['message'].replace(' ', '_')
    cid = clip['id']
    sid = clip['stream_id']
    ext = fmt or 'mp4'
    file_name = f"{desc}_{cid}_{sid}_{start}_{end}.{ext}"
    output_dir = os.path.join('clips', sid)
    os.makedirs(output_dir, exist_ok=True)
    outtmpl = os.path.join(output_dir, file_name)
    if os.path.exists(outtmpl):
        print(Fore.YELLOW + f'[SKIP] {file_name} exists.' + Style.RESET_ALL)
        return
    print(Fore.YELLOW + f'[DOWNLOAD] {file_name} start={start} end={end}' + Style.RESET_ALL)
    params = {
        "download_ranges": ytd_utils.download_range_func([], [[int(start), int(end)]]),
        "match_filter": ytd_utils.match_filter_func("!is_live & live_status!=is_upcoming & availability=public"),
        "no_warnings": False,
        "outtmpl": outtmpl,
        "overwrites": False,
        "quiet": False,
    }

    if fmt:
        params["postprocessors"] = [{
            "key": "FFmpegVideoConvertor",
            "preferedformat": fmt
        }]
        params["final_ext"] = fmt

    with YoutubeDL(params) as ydl:
        try:
            ydl.download([video_url])
        except Exception as e:
            print(Fore.RED + f'[ERROR] Download failed: {e}' + Style.RESET_ALL)

# Main loop
def main():
    while True:
        vid = input(Fore.BLUE + 'Enter YouTube URL (or q to quit): ' + Style.RESET_ALL).strip()
        if vid.lower() == 'q':
            break
        sid = vid.split('v=')[-1].split('&')[0]
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
        while True:
            sel = input('Select clip numbers (comma-separated, e.g. 1,3-5) or * for all: ').strip()
            if sel == '*':
                indices = list(range(1, len(clips) + 1))
                break
            else:
                indices = []
                outer_break = False
                for part in sel.split(','):
                    part = part.strip()
                    if '-' in part:
                        a, b = part.split('-')
                        indices.extend(range(int(a), int(b) + 1))
                        outer_break = True
                    else:
                        try:
                            indices.append(int(part))
                            outer_break = True
                        except ValueError:
                            print(Fore.RED + f"[ERROR] Invalid selection: {part}" + Style.RESET_ALL)
                            continue
                if outer_break:
                    break
        indices = sorted(set(indices))
        print(Fore.BLUE + f'Selected clips: {", ".join(map(str, indices))}' + Style.RESET_ALL)
        if not indices:
            print(Fore.RED + '[ERROR] No valid clips selected.' + Style.RESET_ALL)
            continue
        
        adj = input('Adjust delay? (y/N): ').strip().lower()
        extra = float(input('Seconds to adjust: ')) if adj == 'y' else 0.0
        fmt = input('Enter format extension (mp4, mkv) or leave blank: ').strip() or None
        for idx in indices:
            if 1 <= idx <= len(clips):
                download_and_store(vid, clips[idx - 1], extra, fmt)
            else:
                print(Fore.RED + f"[WARN] Clip number {idx} is out of range." + Style.RESET_ALL)
        print(Fore.GREEN + '[DONE] Clips saved under clips\\' + sid + Style.RESET_ALL)

if __name__ == '__main__':
    main()
