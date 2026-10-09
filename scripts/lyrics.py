#!/usr/bin/env python3
"""Fetch timecoded lyrics for the current song, with smart fallback and a bounded disk cache."""
import hashlib, json, os, re, sys, time, urllib.parse, urllib.request
from pathlib import Path

def clean_track_title(title: str) -> str:
    t = re.sub(r'\(feat\.[^)]*\)', '', title, flags=re.I)
    t = re.sub(r'\[feat\.[^\]]*\]', '', t, flags=re.I)
    t = re.sub(r'-\s*(remastered|remix|bonus track|single version|edit).*$', '', t, flags=re.I)
    return t.strip()

def query_lrclib(params: dict) -> dict:
    query = urllib.parse.urlencode({k: v for k, v in params.items() if v is not None})
    request = urllib.request.Request(
        'https://lrclib.net/api/get?' + query,
        headers={'User-Agent': 'Modesty/1.0 (Quickshell desktop lyrics)'}
    )
    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            return json.loads(response.read(2_000_000))
    except Exception:
        return None

def fetch(track: dict) -> dict:
    key = hashlib.sha256(json.dumps(track, sort_keys=True).encode()).hexdigest()
    cache = Path(os.environ.get('XDG_CACHE_HOME', Path.home() / '.cache')) / 'modesty' / 'lyrics'
    cache.mkdir(parents=True, exist_ok=True)
    path = cache / (key + '.json')

    if path.exists():
        try:
            cached = json.loads(path.read_text())
            has_lyrics = len(cached.get('lines', [])) > 0
            max_age = 7 * 86400 if has_lyrics else 300
            if time.time() - path.stat().st_mtime < max_age:
                return cached
        except Exception:
            pass

    title = track.get('title', '').strip()
    artist = track.get('artist', '').strip()
    duration = round(track.get('duration', 0))

    data = None
    if duration > 0:
        data = query_lrclib({'track_name': title, 'artist_name': artist, 'duration': duration})

    if not data or not data.get('syncedLyrics'):
        data = query_lrclib({'track_name': title, 'artist_name': artist})

    cleaned = clean_track_title(title)
    if (not data or not data.get('syncedLyrics')) and cleaned != title:
        data = query_lrclib({'track_name': cleaned, 'artist_name': artist})

    lines = []
    instrumental = False
    if data:
        instrumental = bool(data.get('instrumental'))
        for line in (data.get('syncedLyrics') or '').splitlines():
            match = re.match(r'\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)', line)
            if match:
                lines.append({'time': int(match[1]) * 60 + float(match[2]), 'text': match[3]})

    result = {'lines': lines, 'instrumental': instrumental}

    temp = path.with_suffix('.tmp')
    temp.write_text(json.dumps(result))
    temp.replace(path)

    for old in sorted(cache.glob('*.json'), key=lambda p: p.stat().st_mtime, reverse=True)[100:]:
        old.unlink(missing_ok=True)

    return result

if __name__ == '__main__':
    track = json.loads(sys.argv[1])
    key = sys.argv[2] if len(sys.argv) > 2 else ''
    print(json.dumps(dict(fetch(track), key=key)), flush=True)
