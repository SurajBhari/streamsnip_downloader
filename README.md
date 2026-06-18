# StreamSnip Downloader

![Python](https://img.shields.io/badge/Python-3670A0?style=flat&logo=python&logoColor=ffdd54)
![yt-dlp](https://img.shields.io/badge/yt--dlp-FF0000?style=flat&logo=youtube&logoColor=white)
![FFmpeg](https://img.shields.io/badge/FFmpeg-007808?style=flat&logo=ffmpeg&logoColor=white)
![CLI](https://img.shields.io/badge/CLI-tool-4EAA25?style=flat&logo=gnu-bash&logoColor=white)

A command-line tool that downloads [StreamSnip](https://streamsnip.com) clips as **real video files**.

StreamSnip itself only stores clip *metadata* (timestamps, messages) — not the video. This CLI takes that metadata for a given stream, then uses [`yt-dlp`](https://github.com/yt-dlp/yt-dlp) to pull only the exact second ranges of each clip straight from YouTube and saves them locally. Nothing but the lightweight clip metadata comes from StreamSnip; the video bytes come from YouTube.

## Features

- Fetches every clip for a stream from the StreamSnip API.
- Select clips individually (`1,3-5`) or grab them all (`*`).
- Parallel downloads with a live multi-clip progress display.
- Optional per-clip start/end padding to fine-tune the cut.
- Choose a specific video format/resolution, or take the best automatically.
- Optional `force_keyframes_at_cuts` for frame-accurate trimming.
- Self-updating: pulls the latest version from this repo on launch (skip with `--no-update`).

## Requirements

- **Python 3**, **git**, and **FFmpeg** (FFmpeg is required by yt-dlp to trim and merge segments).
- Python packages: `yt-dlp`, `requests`, `colorama`.

The install scripts below set all of this up for you.

## Install & run

**Windows** — run `install_windows.bat` (installs Python/git/FFmpeg via Chocolatey if missing, then launches the CLI).

**Linux (Debian/Ubuntu)** — `bash install_unix.sh`

**macOS** — `bash install_mac.sh`

Or, if you already have the requirements:

```bash
pip install --upgrade yt-dlp requests colorama
python streamsnip_cli.py
```

## Usage

```text
Enter YouTube URL (or q to quit): https://youtube.com/watch?v=<stream_id>
```

The tool lists the available clips, you pick which ones, optionally adjust padding/format, and the segments are saved to:

```text
clips/<stream_id>/<message>_<clip_id>_<stream_id>_<start>_<end>.<ext>
```

Pass `--no-update` to skip the auto-update step.

## Related

- [streamsnip](https://github.com/SurajBhari/streamsnip) — project home & Nightbot setup.
- [streamsnip_extension](https://github.com/SurajBhari/streamsnip_extension) — clip markers on the YouTube scrubber.
