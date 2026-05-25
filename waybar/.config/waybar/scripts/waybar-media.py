#!/usr/bin/env python3
"""Waybar media module — pactl + Spotify MPRIS dbus.

Detects audio-playing apps via PulseAudio sink-inputs. Spotify takes priority
over browser/YouTube. Runs as a daemon: pactl/dbus state is refreshed once a
second, JSON is emitted faster so long titles can scroll as a marquee.
"""
import json
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from typing import Optional

POLL_SEC = 1.0
TICK_SEC = 0.35
MAX_VISIBLE = 30

ICON_PLAY = "\U000f0408"   # 󰐊
ICON_PAUSE = "\U000f03e4"  # 󰏤
ICON_IDLE = "\U000f075b"   # 󰝛

BROWSER_BINS = ("brave", "chromium", "chrome", "firefox", "librewolf", "vivaldi")
SINK_INDEX_FILE = "/tmp/waybar-media-sink"

ENV = {**os.environ, "LANG": "C", "LC_ALL": "C"}


def run(cmd, timeout=2):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, env=ENV)
        return r.stdout
    except Exception:
        return ""


@dataclass
class SinkInput:
    index: int
    state: str
    volume_pct: int
    app_name: str
    app_binary: str
    media_name: str


def parse_sink_inputs():
    out = run(["pactl", "list", "sink-inputs"])
    if not out:
        return []
    blocks = re.split(r"^Sink Input #", out, flags=re.M)
    inputs = []
    for block in blocks[1:]:
        m = re.match(r"(\d+)", block)
        if not m:
            continue

        def prop(name):
            pm = re.search(rf'{re.escape(name)} = "(.*?)"', block)
            return pm.group(1) if pm else ""

        state_m = re.search(r"State:\s*(\S+)", block)
        vol_m = re.search(r"Volume:.*?(\d+)%", block)
        inputs.append(SinkInput(
            index=int(m.group(1)),
            state=state_m.group(1) if state_m else "",
            volume_pct=int(vol_m.group(1)) if vol_m else 0,
            app_name=prop("application.name"),
            app_binary=prop("application.process.binary"),
            media_name=prop("media.name"),
        ))
    return inputs


def is_spotify(s: SinkInput) -> bool:
    return "spotify" in s.app_name.lower() or "spotify" in s.app_binary.lower()


def is_browser(s: SinkInput) -> bool:
    b = s.app_binary.lower()
    return any(name in b for name in BROWSER_BINS)


def _unescape(s: str) -> str:
    return s.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


def spotify_metadata():
    """Returns (title, artist, playback_status). Empty strings on failure."""
    out = run([
        "gdbus", "call", "--session",
        "--dest", "org.mpris.MediaPlayer2.spotify",
        "--object-path", "/org/mpris/MediaPlayer2",
        "--method", "org.freedesktop.DBus.Properties.GetAll",
        "org.mpris.MediaPlayer2.Player",
    ])
    if not out:
        return "", "", ""
    title_m = re.search(r"'xesam:title':\s*<'((?:\\.|[^'\\])*)'>", out)
    artist_m = re.search(r"'xesam:artist':\s*<\[\s*'((?:\\.|[^'\\])*)'", out)
    status_m = re.search(r"'PlaybackStatus':\s*<'((?:\\.|[^'\\])*)'>", out)
    return (
        _unescape(title_m.group(1)) if title_m else "",
        _unescape(artist_m.group(1)) if artist_m else "",
        status_m.group(1) if status_m else "",
    )


def clean_browser_title(name: str) -> str:
    name = re.sub(r"\s*[-—]\s*(YouTube Music|YouTube)(\s*[-—].*)?$", "", name, flags=re.I)
    return name.strip() or "Audio"


@dataclass
class State:
    source: str = "none"
    sink_index: Optional[int] = None
    raw_text: str = ""
    app_label: str = ""
    playing: bool = False
    volume_pct: int = 0


def gather_state() -> State:
    sinks = parse_sink_inputs()

    spotify_sinks = [s for s in sinks if is_spotify(s)]
    if spotify_sinks:
        si = next((s for s in spotify_sinks if s.state == "RUNNING"), spotify_sinks[0])
        title, artist, status = spotify_metadata()
        raw = " - ".join(x for x in (title, artist) if x) or si.media_name or "Spotify"
        playing = (status == "Playing") if status else (si.state == "RUNNING")
        return State(
            source="spotify", sink_index=si.index, raw_text=raw,
            app_label="Spotify", playing=playing, volume_pct=si.volume_pct,
        )

    browser_sinks = [s for s in sinks if is_browser(s)]
    if browser_sinks:
        si = next((s for s in browser_sinks if s.state == "RUNNING"), browser_sinks[0])
        raw = clean_browser_title(si.media_name or si.app_name)
        return State(
            source="youtube", sink_index=si.index, raw_text=raw,
            app_label=si.app_binary or si.app_name or "Browser",
            playing=(si.state == "RUNNING"), volume_pct=si.volume_pct,
        )

    return State()


def marquee(text: str, width: int, pos: int) -> str:
    if len(text) <= width:
        return text
    cycle = text + "   "
    pos = pos % len(cycle)
    return (cycle + cycle)[pos : pos + width]


def write_sink_index(idx: Optional[int]):
    try:
        with open(SINK_INDEX_FILE, "w") as f:
            f.write("" if idx is None else str(idx))
    except OSError:
        pass


def emit(state: State, pos: int):
    if state.source == "none":
        payload = {"text": ICON_IDLE, "tooltip": "Nothing playing", "class": "none", "alt": "idle"}
    else:
        icon = ICON_PLAY if state.playing else ICON_PAUSE
        visible = marquee(state.raw_text, MAX_VISIBLE, pos)
        tooltip = "\n".join([
            state.raw_text or state.app_label,
            f"Source: {state.app_label}",
            f"Volume: {state.volume_pct}%",
        ])
        payload = {
            "text": f"{icon}  {visible}",
            "tooltip": tooltip,
            "class": state.source,
            "alt": state.source,
        }
    print(json.dumps(payload, ensure_ascii=False), flush=True)


def main():
    state = gather_state()
    write_sink_index(state.sink_index)
    last_poll = time.monotonic()
    last_raw = state.raw_text
    pos = 0
    while True:
        now = time.monotonic()
        if now - last_poll >= POLL_SEC:
            new_state = gather_state()
            if new_state.raw_text != last_raw:
                pos = 0
                last_raw = new_state.raw_text
            state = new_state
            write_sink_index(state.sink_index)
            last_poll = now
        emit(state, pos)
        pos += 1
        time.sleep(TICK_SEC)


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        sys.exit(0)
