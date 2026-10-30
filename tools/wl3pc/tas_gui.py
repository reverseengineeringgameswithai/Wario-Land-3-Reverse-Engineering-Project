"""TAS editor window for the emulator oracle: live screen, piano roll, RAM watch.

Run with `make tas NAME=...`. A development tool only (ADR-0001): it runs the
identified ROM through the oracle and saves movies as oracle recordings in
local/recordings/. Keys are listed in the window and in
docs/02-research/emulator-oracle.md.
"""

from __future__ import annotations

import json
import os
import re
import tempfile
import time
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, simpledialog, ttk
from typing import Any

import numpy as np

from . import oracle
from .provenance import canonical_json
from .tas import TasSession

COLUMNS = (("up", "U"), ("down", "D"), ("left", "L"), ("right", "R"),
           ("a", "A"), ("b", "B"), ("start", "S"), ("select", "s"))
GAME_KEYS = {"Up": "up", "Down": "down", "Left": "left", "Right": "right", "x": "a", "X": "a",
             "z": "b", "Z": "b", "Return": "start", "BackSpace": "select"}
SPEEDS = (("6%", 1 / 16), ("12%", 1 / 8), ("25%", 1 / 4), ("50%", 1 / 2), ("100%", 1.0),
          ("200%", 2.0), ("400%", 4.0), ("Max", 0.0))
WATCH = ("wWarioXPos", "wWarioYPos", "wWarioState", "wDirection", "wWalkVelIndex", "wJumpVelIndex",
         "wJumpVelTable", "wTransformation", "wTransformationProgress", "wPowerUpLevel", "wKeyAndTreasureFlags",
         "wNumCoins", "wNumCollectedTreasures", "wCameraSCX", "wCameraSCY", "wState", "wSubState", "wLevel",
         "wRoom", "wLevelRoomID", "wGlobalCounter", "wJoypadDown")
ROW_H, FRAME_W, CELL_W, ROWS = 16, 64, 24, 26
RELEASE_GRACE = 0.03  # seconds
KEY_MAP = "Game Boy keys:  arrows = D-pad    X = A    Z = B    Enter = Start    Backspace = Select"
MODE_COLOURS = {True: "#cc0000", False: "#3465a4"}  # recording, read-only
WATCH_ROWS = 14
EXTRA_ROWS = 600  # empty rows shown past the end of the movie
HELP = ("Game: arrows, X=A, Z=B, Enter=Start, Backspace=Select (used while recording)\n"
        "Space/Pause play/pause   . or F frame advance   , or Shift+R frame back   Home/End first/last\n"
        "Hold Tab fast-forward   - / = slower / faster   Ctrl+R or Q record (off = read-only playback)\n"
        "Ctrl+S save   Ctrl+Z undo   Insert/Delete frame   M marker   [ / ] previous/next marker   Esc quit\n"
        "Shift+click frame numbers to select   Ctrl+C copy   Ctrl+V paste over   Ctrl+Shift+V paste-insert\n"
        "Ctrl+T save state here   Ctrl+B branch: new movie from this frame   Ctrl+E export battery save\n"
        "Piano roll: click frame number to seek; click/drag a cell to set or clear a button")
NAME_RE = re.compile(r"^[A-Za-z0-9_-]{1,64}$")
COLOURS = {"current": "#3465a4", "green": "#dcf0d5", "lag": "#f5c6c1", "beyond": "#eeeeec",
           "selected": "#c5d4ea", "marker": "#edd400",
           "plain": "#ffffff", "cell": "#2e3436", "cell_text": "#ffffff", "faint": "#babdb6", "grid": "#d3d7cf"}


def _write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    with os.fdopen(fd, "wb") as handle:
        handle.write(data)
    os.replace(temp, path)


class TasEditor:
    def __init__(self, rom: bytes, session: TasSession, path: Path, scale: int) -> None:
        self.rom, self.session, self.path, self.scale = rom, session, path, scale
        # A new, empty movie behaves like an emulator: running and recording, so keys move Wario at once.
        # An existing movie opens paused and read-only, so it is replayed rather than overwritten.
        fresh = not session.inputs
        self.playing, self.recording = fresh, fresh
        self.releases: dict[str, float] = {}  # game button -> time its key was released
        self.speed = 1.0
        self.budget, self.last = 0.0, time.perf_counter()
        self.top = 0
        self.keys: set[str] = set()
        self.paint: tuple[str, bool] | None = None
        self.restore_to: int | None = None
        self.selection: tuple[int, int] | None = None
        self.clipboard: list[frozenset[str]] = []
        self.lag_total, self.lag_checked = 0, 0.0
        self.message: tuple[str, float] = ("", 0.0)

        self.root = tk.Tk()
        self.root.protocol("WM_DELETE_WINDOW", self.quit)
        left = ttk.Frame(self.root, padding=6)
        left.grid(row=0, column=0, sticky="n")
        right = ttk.Frame(self.root, padding=6)
        right.grid(row=0, column=1, sticky="ns")

        self.photo = tk.PhotoImage(width=160 * scale, height=144 * scale)
        top = ttk.Frame(left)
        top.grid(row=0, column=0, columnspan=7)
        # Mode banner and a screen border in the mode's colour: red while recording, blue while read-only.
        self.mode_label = tk.Label(top, font=("TkDefaultFont", 12, "bold"), fg="white", cursor="hand2", pady=4)
        self.mode_label.pack(fill="x")
        self.mode_label.bind("<Button-1>", lambda _event: self.toggle_record())
        self.border = tk.Frame(top, padx=4, pady=4)
        self.border.pack()
        screen = tk.Canvas(self.border, width=160 * scale, height=144 * scale, bg="black", highlightthickness=0)
        screen.create_image(0, 0, image=self.photo, anchor="nw")
        screen.pack()
        tk.Label(top, text=KEY_MAP, font=("TkDefaultFont", 10, "bold")).pack(fill="x", pady=(2, 0))
        buttons = (("|<", lambda: self.goto(0)), ("< Frame", self.frame_back), ("Play", self.toggle_play),
                   ("Frame >", self.frame_advance), ("Mode", self.toggle_record), ("Save", self.save))
        extra = ttk.Frame(left)
        extra.grid(row=5, column=0, columnspan=7, sticky="w", pady=(6, 0))
        for text, command in (("Save state", self.on_save_state), ("Branch…", self.branch),
                              ("Export save", self.on_export_save)):
            ttk.Button(extra, text=text, command=command, takefocus=False).pack(side="left", padx=(0, 4))
        self.play_button = None
        self.record_button = None
        for column, (text, command) in enumerate(buttons):
            button = ttk.Button(left, text=text, command=command, width=16 if text == "Mode" else 8,
                                takefocus=False)
            button.grid(row=1, column=column, pady=4)
            if text == "Play":
                self.play_button = button
            if text == "Mode":
                self.record_button = button
        self.speed_box = ttk.Combobox(left, values=[label for label, _ in SPEEDS], width=5, state="readonly")
        self.speed_box.set("100%")
        self.speed_box.bind("<<ComboboxSelected>>", self.set_speed)
        self.speed_box.grid(row=1, column=6)
        goto_row = ttk.Frame(left)
        goto_row.grid(row=2, column=0, columnspan=7, sticky="w")
        ttk.Label(goto_row, text="Go to frame:").pack(side="left")
        self.goto_entry = ttk.Entry(goto_row, width=8)
        self.goto_entry.pack(side="left", padx=4)
        self.goto_entry.bind("<Return>", self.goto_typed)
        # Keep the window's shortcuts (".", ",", space) out of the entry while typing a frame number.
        self.goto_entry.bindtags((str(self.goto_entry), "TEntry", "all"))
        self.status = ttk.Label(left, font=("TkFixedFont", 10))
        self.status.grid(row=3, column=0, columnspan=7, sticky="w", pady=(4, 0))
        ttk.Label(left, text=HELP, foreground="#555753", justify="left").grid(row=4, column=0, columnspan=7,
                                                                              sticky="w", pady=(6, 0))

        width = FRAME_W + CELL_W * len(COLUMNS)
        header = tk.Canvas(right, width=width, height=ROW_H, bg="#e9e9e9", highlightthickness=0)
        header.create_text(4, ROW_H // 2, text="frame", anchor="w", font=("TkSmallCaptionFont",))
        for i, (_, label) in enumerate(COLUMNS):
            header.create_text(FRAME_W + i * CELL_W + CELL_W // 2, ROW_H // 2, text=label)
        header.grid(row=0, column=0, sticky="w")
        self.roll = tk.Canvas(right, width=width, height=ROWS * ROW_H, bg="white", highlightthickness=0)
        self.roll.grid(row=1, column=0)
        self.scroll = ttk.Scrollbar(right, orient="vertical", command=self.yview)
        self.scroll.grid(row=1, column=1, sticky="ns")
        self.watch = ttk.Treeview(right, columns=("value", "hex"), height=WATCH_ROWS, selectmode="none")
        self.watch.heading("#0", text="RAM watch")
        self.watch.heading("value", text="value")
        self.watch.heading("hex", text="hex")
        self.watch.column("#0", width=150)
        self.watch.column("value", width=70, anchor="e")
        self.watch.column("hex", width=70, anchor="e")
        for name in WATCH:
            self.watch.insert("", "end", iid=name, text=name, values=("", ""))
        self.watch.grid(row=2, column=0, pady=(8, 0), sticky="we")
        watch_scroll = ttk.Scrollbar(right, orient="vertical", command=self.watch.yview)
        watch_scroll.grid(row=2, column=1, sticky="ns", pady=(8, 0))
        self.watch.configure(yscrollcommand=watch_scroll.set)

        self.roll.bind("<Button-1>", self.press)
        self.roll.bind("<B1-Motion>", self.drag)
        self.roll.bind("<ButtonRelease-1>", self.release)
        for sequence in ("<Button-4>", "<Button-5>", "<MouseWheel>"):
            self.roll.bind(sequence, self.wheel)
        self.root.bind("<KeyPress>", self.key_down)
        self.root.bind("<KeyRelease>", self.key_up)
        # Tab fast-forwards while held; "break" keeps Tk from moving keyboard focus with it.
        self.fast_forward = False
        self.root.bind("<KeyPress-Tab>", lambda _event: (setattr(self, "fast_forward", True), "break")[1])
        self.root.bind("<KeyRelease-Tab>", lambda _event: (setattr(self, "fast_forward", False), "break")[1])
        for sequence, handler in (("<space>", self.toggle_play), ("<period>", self.frame_advance),
                                  ("<comma>", self.frame_back), ("<Home>", lambda: self.goto(0)),
                                  ("<End>", lambda: self.goto(len(self.session.inputs))),
                                  ("<Control-r>", self.toggle_record), ("<Control-s>", self.save),
                                  ("<Control-z>", self.undo), ("<Insert>", self.insert_frame),
                                  ("<Control-t>", self.on_save_state), ("<Control-b>", self.branch),
                                  ("<Control-e>", self.on_export_save),
                                  ("<minus>", lambda: self.step_speed(-1)), ("<equal>", lambda: self.step_speed(1)),
                                  ("<plus>", lambda: self.step_speed(1)),
                                  # BizHawk-style aliases
                                  ("<f>", self.frame_advance), ("<R>", self.frame_back), ("<q>", self.toggle_record),
                                  ("<Pause>", self.toggle_play),
                                  ("<m>", self.toggle_marker), ("<bracketleft>", lambda: self.jump_marker(-1)),
                                  ("<bracketright>", lambda: self.jump_marker(1)),
                                  ("<Control-c>", self.copy), ("<Control-v>", lambda: self.paste(False)),
                                  ("<Control-V>", lambda: self.paste(True)),
                                  ("<Delete>", self.delete_frame), ("<Escape>", self.quit)):
            self.root.bind(sequence, lambda _event, h=handler: (h(), "break")[1])
        self.refresh()
        # Come to the front when opened (briefly topmost; window managers may still refuse focus).
        self.root.lift()
        self.root.attributes("-topmost", True)
        self.root.after(800, lambda: self.root.attributes("-topmost", False))
        self.root.focus_force()
        self.root.after(4, self.loop)

    # --- transport ---------------------------------------------------------------

    def live(self) -> frozenset[str]:
        """Buttons held now. A release only counts after RELEASE_GRACE, because X11 key repeat sends a
        release and a press together; without the grace a held key could drop out for one frame."""
        now = time.perf_counter()
        for button, released in list(self.releases.items()):
            if now - released >= RELEASE_GRACE:
                self.keys.discard(button)
                del self.releases[button]
        return frozenset(self.keys)

    def toggle_play(self) -> None:
        self.playing = not self.playing
        self.budget, self.last = 0.0, time.perf_counter()
        self.refresh()

    def toggle_record(self) -> None:
        self.recording = not self.recording
        self.refresh()

    def set_speed(self, _event: Any = None) -> None:
        self.speed = dict(SPEEDS)[self.speed_box.get()]
        self.root.focus_set()

    def step_speed(self, direction: int) -> None:
        labels = [label for label, _ in SPEEDS]
        index = max(0, min(len(labels) - 1, labels.index(self.speed_box.get()) + direction))
        self.speed_box.set(labels[index])
        self.set_speed()
        self.refresh(follow=False)

    def frame_advance(self) -> None:
        self.playing = False
        self.session.advance(self.live() if self.recording else None)
        self.refresh()

    def frame_back(self) -> None:
        self.playing = False
        self.goto(self.session.frame - 1)

    def goto(self, frame: int) -> None:
        self.session.seek(max(0, frame))
        self.refresh()

    def goto_typed(self, _event: Any) -> None:
        text = self.goto_entry.get().strip()
        if text.isdigit():
            self.goto(int(text))
        self.root.focus_set()

    def loop(self) -> None:
        now = time.perf_counter()
        if self.playing:
            if self.speed == 0 or self.fast_forward:
                frames = 1
                deadline = now + 0.012
                while time.perf_counter() < deadline:
                    self.session.advance(self.live() if self.recording else None, render=False)
                    frames += 1
                self.session.advance(self.live() if self.recording else None)
            else:
                self.budget = min(self.budget + (now - self.last) * oracle.LCD_HZ * self.speed, 8)
                frames = int(self.budget)
                self.budget -= frames
                for index in range(frames):
                    self.session.advance(self.live() if self.recording else None, render=index == frames - 1)
            if frames:
                self.refresh()
        self.last = now
        self.root.after(4, self.loop)

    # --- editing -----------------------------------------------------------------

    def frame_at(self, y: int) -> int:
        return self.top + max(0, y) // ROW_H

    def press(self, event: tk.Event) -> None:
        frame = self.frame_at(event.y)
        if event.x < FRAME_W:
            self.playing = False
            if getattr(event, "state", 0) & 0x1:  # Shift: select from the current frame to this one
                self.selection = (min(frame, self.session.frame), max(frame, self.session.frame))
                self.refresh(follow=False)
                return
            self.selection = None
            self.goto(frame)
            return
        column = (event.x - FRAME_W) // CELL_W
        if not 0 <= column < len(COLUMNS):
            return
        self.playing = False
        self.restore_to = self.session.frame
        self.session.remember()
        self.paint = (COLUMNS[column][0], self.session.toggle(frame, COLUMNS[column][0]))
        self.refresh(follow=False)

    def drag(self, event: tk.Event) -> None:
        if self.paint is None:
            return
        button, pressed = self.paint
        frame = self.frame_at(event.y)
        held = self.session.input_at(frame)
        if (button in held) != pressed:
            self.session.set_input(frame, held | {button} if pressed else held - {button})
            self.refresh(follow=False)

    def release(self, _event: tk.Event) -> None:
        self.paint = None
        if self.restore_to is not None and self.session.frame != self.restore_to:
            self.session.seek(self.restore_to)  # auto-restore the position an edit rewound from
            self.refresh(follow=False)
        self.restore_to = None

    def undo(self) -> None:
        current = self.session.frame
        if self.session.undo():
            self.session.seek(current)
            self.refresh()

    def toggle_marker(self) -> None:
        frame = self.session.frame
        self.session.remember()
        if frame in self.session.markers:
            self.session.set_marker(frame, None)
        else:
            label = simpledialog.askstring("Marker", f"Label for frame {frame} (may be empty):", parent=self.root)
            if label is None:
                return
            self.session.set_marker(frame, label.strip())
        self.refresh(follow=False)

    def jump_marker(self, direction: int) -> None:
        frame = self.session.frame
        candidates = sorted(f for f in self.session.markers if (f > frame if direction > 0 else f < frame))
        if candidates:
            self.goto(candidates[0] if direction > 0 else candidates[-1])

    def copy(self) -> None:
        first, last = self.selection or (self.session.frame, self.session.frame)
        self.clipboard = self.session.copy(first, last)
        self.flash(f"copied {len(self.clipboard)} frame(s)")

    def paste(self, insert: bool) -> None:
        if not self.clipboard:
            return
        self.playing = False
        self.session.remember()
        frame = self.session.frame
        if insert:
            self.session.insert(frame, inputs=self.clipboard)
        else:
            self.session.paste(frame, self.clipboard)
        self.flash(f"{'inserted' if insert else 'pasted'} {len(self.clipboard)} frame(s) at {frame}")
        self.refresh(follow=False)

    def flash(self, message: str) -> None:
        self.message = (message, time.perf_counter() + 3)
        self.refresh(follow=False)

    def insert_frame(self) -> None:
        self.session.remember()
        self.session.insert(self.session.frame)
        self.refresh()

    def delete_frame(self) -> None:
        self.session.remember()
        self.session.delete(self.session.frame)
        self.refresh()

    def key_down(self, event: tk.Event) -> None:
        if event.keysym in GAME_KEYS and self.root.focus_get() is not self.goto_entry:
            button = GAME_KEYS[event.keysym]
            self.releases.pop(button, None)
            if button not in self.keys:
                self.keys.add(button)
                if not self.recording:
                    self.flash("read-only playback: press Q or Ctrl+R to record your keys")
                elif not self.playing:
                    self.flash("paused: Space plays, . advances one frame with the keys you hold")

    def key_up(self, event: tk.Event) -> None:
        if event.keysym in GAME_KEYS:
            self.releases[GAME_KEYS[event.keysym]] = time.perf_counter()

    # --- piano roll ----------------------------------------------------------------

    def total_rows(self) -> int:
        return max(len(self.session.inputs), self.session.frame) + EXTRA_ROWS

    def yview(self, *args: str) -> None:
        total = self.total_rows()
        if args[0] == "moveto":
            self.top = int(float(args[1]) * total)
        elif args[0] == "scroll":
            self.top += int(args[1]) * (ROWS - 2 if args[2] == "pages" else 1)
        self.top = max(0, min(self.top, total - ROWS))
        self.draw_roll()

    def wheel(self, event: tk.Event) -> None:
        step = -3 if getattr(event, "num", 0) == 4 or getattr(event, "delta", 0) > 0 else 3
        self.yview("scroll", str(step), "units")

    def draw_roll(self) -> None:
        roll, session = self.roll, self.session
        roll.delete("all")
        known = session.known_until()
        width = FRAME_W + CELL_W * len(COLUMNS)
        for row in range(ROWS):
            frame, y = self.top + row, row * ROW_H
            lag = session.lag(frame)
            selected = self.selection is not None and self.selection[0] <= frame <= self.selection[1]
            if frame == session.frame:
                fill = COLOURS["current"]
            elif selected:
                fill = COLOURS["selected"]
            elif frame >= len(session.inputs):
                fill = COLOURS["beyond"]
            elif lag:
                fill = COLOURS["lag"]
            elif frame < known:
                fill = COLOURS["green"]
            else:
                fill = COLOURS["plain"]
            roll.create_rectangle(0, y, width, y + ROW_H, fill=fill, outline=COLOURS["grid"])
            text_colour = "#ffffff" if frame == session.frame else "#2e3436"
            if frame in session.markers:
                roll.create_rectangle(0, y, 4, y + ROW_H, fill=COLOURS["marker"], outline="")
                label = session.markers[frame]
                text = f"{frame} {label[:3]}" if label else f"{frame} *"
            else:
                text = str(frame)
            roll.create_text(6, y + ROW_H // 2, text=text, anchor="w", fill=text_colour, font=("TkFixedFont", 9))
            held = session.input_at(frame)
            for i, (button, label) in enumerate(COLUMNS):
                x = FRAME_W + i * CELL_W
                if button in held:
                    roll.create_rectangle(x + 2, y + 2, x + CELL_W - 2, y + ROW_H - 2, fill=COLOURS["cell"], outline="")
                    roll.create_text(x + CELL_W // 2, y + ROW_H // 2, text=label, fill=COLOURS["cell_text"],
                                     font=("TkFixedFont", 9, "bold"))
                else:
                    roll.create_text(x + CELL_W // 2, y + ROW_H // 2, text=label, fill=COLOURS["faint"],
                                     font=("TkFixedFont", 9))
        total = self.total_rows()
        self.scroll.set(self.top / total, (self.top + ROWS) / total)

    # --- display -------------------------------------------------------------------

    def refresh(self, follow: bool = True) -> None:
        """Redraw everything; with `follow`, scroll the piano roll to keep the current frame in view."""
        session = self.session
        if follow and not self.top <= session.frame < self.top + ROWS - 3:
            self.top = max(0, session.frame - ROWS // 3)
        pixels = np.asarray(session.screen())[:, :, :3]
        if self.scale > 1:
            pixels = pixels.repeat(self.scale, axis=0).repeat(self.scale, axis=1)
        height, width = pixels.shape[:2]
        self.photo.configure(data=f"P6 {width} {height} 255\n".encode() + np.ascontiguousarray(pixels).tobytes(),
                             format="ppm")
        ram = session.ram()
        for name in WATCH:
            hex_text = f"{ram[name]:04x}" if oracle.SAMPLE_SIZES[name] == 2 else f"{ram[name]:02x}"
            if name == "wKeyAndTreasureFlags":  # GREY/RED/GREEN/BLUE keys in bits 0-3, treasures in bits 4-7
                hex_text = f"{ram[name]:08b}"
            self.watch.item(name, values=(oracle.sample_value(name, ram[name]), hex_text))  # BCD counters in decimal
        now = time.perf_counter()
        if now - self.lag_checked > 0.5 or not self.playing:
            self.lag_total = sum(1 for f in range(len(session.inputs)) if session.lag(f))
            self.lag_checked = now
        self.status.configure(text=(
            f"frame {session.frame} / {len(session.inputs)}   {'PLAYING' if self.playing else 'paused'}"
            f"{'   ● RECORDING' if self.recording else ''}   lag {self.lag_total}"
            f"{'   unsaved' if session.dirty else ''}   speed {'FAST' if self.fast_forward else self.speed_box.get()}"
            f"\nstart: {oracle.describe_start(session.start)}"
            f"{'   marker: ' + session.markers[session.frame] if session.markers.get(session.frame) else ''}"
            f"{'   ' + self.message[0] if self.message[1] > now else ''}"))
        self.play_button.configure(text="Pause" if self.playing else "Play")
        self.record_button.configure(text="Mode: RECORDING" if self.recording else "Mode: READ-ONLY")
        colour = MODE_COLOURS[self.recording]
        self.mode_label.configure(bg=colour, text=(
            "● RECORDING: your keys go into the movie (Q or click to switch)" if self.recording
            else "READ-ONLY playback: keys are ignored (Q or click here to record)"))
        self.border.configure(bg=colour)
        self.root.title(f"WL3PC TAS editor: {self.path.name}{' *' if session.dirty else ''}")
        self.draw_roll()

    # --- files ---------------------------------------------------------------------

    def save(self) -> bool:
        self.playing = False
        try:
            recording = self.session.to_recording()
        except oracle.OracleError as error:
            messagebox.showerror("Not saved", str(error))
            return False
        _write(self.path, canonical_json(recording))
        self.session.dirty = False
        self.refresh()
        return True

    def settle_unsaved(self) -> bool:
        """Ask to save a changed movie; False if the user cancels."""
        if not self.session.dirty:
            return True
        answer = messagebox.askyesnocancel("Unsaved movie", f"Save {self.path.name} first?")
        return answer is not None and (not answer or self.save())

    def quit(self) -> None:
        if self.settle_unsaved():
            self.root.destroy()

    # --- states, branches, battery saves ----------------------------------------------

    def on_save_state(self) -> None:
        self.playing = False
        start = self.session.save_state_here(self.path.stem.removesuffix(".recording"))
        messagebox.showinfo("State saved", f"Frame {self.session.frame} saved as state {start['sha256'][:12]}…\n"
                            f"Start a movie from it with:\nmake tas NAME=new-movie STATE={start['sha256']}")

    def on_export_save(self) -> None:
        self.playing = False
        digest = self.session.export_save()
        messagebox.showinfo("Battery save exported",
                            f"Cartridge RAM at frame {self.session.frame} is save {digest[:12]}…\n"
                            f"{oracle.store_path('save', digest)}\n"
                            f"Start a movie from power-on with it:\nmake tas NAME=new-movie SAVE={oracle.store_path('save', digest)}")

    def branch(self, name: str | None = None) -> bool:
        """Start a new movie from the current frame (saved as a state) and switch to it."""
        self.playing = False
        if name is None:
            name = simpledialog.askstring("Branch", "Name of the new movie (letters, digits, - and _):",
                                          parent=self.root)
            if name is None:
                return False
        target = self.path.parent / f"{name}.recording.json"
        if not NAME_RE.match(name) or target.exists():
            messagebox.showerror("Branch", f"{name!r} is not a valid new movie name, or it already exists")
            return False
        if not self.settle_unsaved():
            return False
        start = self.session.save_state_here(self.path.name.removesuffix(".recording.json"))
        session = TasSession(self.rom, start)
        self.session.close()
        self.session, self.path = session, target  # an empty branch has nothing to save until frames are added
        self.recording = True
        self.refresh()
        return True

    def run(self) -> None:
        self.root.mainloop()


def open_session(rom: bytes, path: Path, start: dict[str, Any] | None) -> TasSession:
    """The movie at `path`, or a new empty one from `start`."""
    if path.exists():
        recording = json.loads(path.read_text(encoding="utf-8"))
        oracle.check_document(recording, "recording")
        oracle.check_rom(rom, recording["rom_sha256"])
        return TasSession(rom, recording["start"], TasSession.inputs_from(recording),
                          markers=TasSession.markers_from(recording))
    if start is None:
        raise oracle.OracleError(f"{path} does not exist and no start was given")
    return TasSession(rom, start)


def run_editor(rom: bytes, path: Path, start: dict[str, Any] | None, scale: int = 3) -> None:
    editor = TasEditor(rom, open_session(rom, path, start), path, scale)
    try:
        editor.run()
    finally:
        editor.session.close()


def selftest(rom: bytes, path: Path, screenshot: Path | None, scale: int = 3) -> str:
    """Drive the real window through its main actions (development check of the editor itself)."""
    import subprocess

    session = TasSession(rom, oracle.route_start("ootw-day1-start"))
    editor = TasEditor(rom, session, path, scale)
    root, timings = editor.root, []
    original_refresh = editor.refresh

    def timed_refresh(follow: bool = True) -> None:
        began = time.perf_counter()
        original_refresh(follow)
        timings.append(time.perf_counter() - began)

    editor.refresh = timed_refresh
    if not (editor.playing and editor.recording):
        raise oracle.OracleError("a new movie should open running and recording")
    editor.playing = False
    # X11 key repeat sends a release and a press together: the button must stay held through it.
    right = type("Event", (), {"keysym": "Right"})()
    editor.key_down(right)
    editor.key_up(right)
    editor.key_down(right)
    held_through_repeat = editor.live() == frozenset({"right"})
    editor.key_up(right)
    time.sleep(RELEASE_GRACE + 0.02)
    if not held_through_repeat or editor.live():
        raise oracle.OracleError("key repeat handling is wrong")
    editor.keys = {"right"}
    editor.toggle_play()
    deadline = time.perf_counter() + 1.5
    while time.perf_counter() < deadline:
        root.update()
    editor.toggle_play()
    played = session.frame
    editor.keys = {"right", "a"}
    for _ in range(12):
        editor.frame_advance()
    editor.keys = set()
    editor.recording = False
    editor.goto(20)
    event = type("Event", (), {"x": FRAME_W + 5 * CELL_W + 4, "y": 4 * ROW_H + 2})()
    editor.press(event)                      # set B on the frame in row 4 ...
    for row in (5, 6, 7):
        event.y = row * ROW_H + 2
        editor.drag(event)                   # ... and paint it down three more rows
    editor.release(event)
    painted = [f for f in range(len(session.inputs)) if "b" in session.input_at(f)]
    # Shift+click selects frames 5-15, copy, paste over frame 60, and mark frame 20.
    editor.goto(5)
    shift_click = type("Event", (), {"x": 4, "y": (15 - editor.top) * ROW_H + 2, "state": 0x1})()
    editor.press(shift_click)
    editor.copy()
    copied = list(editor.clipboard)
    editor.goto(60)
    editor.paste(False)
    if editor.selection != (5, 15) or session.copy(60, 70) != copied:
        raise oracle.OracleError("selection, copy, or paste did not work")
    session.set_marker(20, "selftest marker")
    editor.goto(0)
    editor.jump_marker(1)
    if session.frame != 20:
        raise oracle.OracleError("jumping to the next marker failed")
    editor.goto(len(session.inputs))
    root.update()
    if not editor.save():
        raise oracle.OracleError("save failed")
    saved = json.loads(path.read_text(encoding="utf-8"))
    if saved.get("markers") != [{"tick": 20, "label": "selftest marker"}]:
        raise oracle.OracleError("the marker was not saved")
    replayed = oracle.replay(rom, saved)
    # Branch a new movie from the last frame, record into it, save, and replay it from its state.
    branch_name = path.name.removesuffix(".recording.json") + "-branch"
    branch_path = path.parent / f"{branch_name}.recording.json"
    if branch_path.exists():
        branch_path.unlink()
    if not editor.branch(branch_name):
        raise oracle.OracleError("branch failed")
    if not editor.recording or editor.playing:
        raise oracle.OracleError("a branch should open paused and recording")
    editor.keys = {"left"}
    for _ in range(30):
        editor.frame_advance()
    editor.keys = set()
    editor.recording = False
    exported = editor.session.export_save()
    if not editor.save():
        raise oracle.OracleError("saving the branch failed")
    branch_replay = oracle.replay(rom, json.loads(branch_path.read_text(encoding="utf-8")))
    if screenshot is not None:
        root.update()
        subprocess.run(["import", "-window", str(root.winfo_id()), str(screenshot)], check=True)
    root.destroy()
    editor.session.close()
    return (f"played {played} frames in 1.5 s while recording, recorded 12 more by frame advance, painted B on "
            f"frames {painted}, copied frames 5-15 over 60-70 and marked frame 20, saved {replayed['ticks']} ticks "
            f"and replayed {replayed['checkpoints']} checkpoints; "
            f"branched '{branch_name}' from frame {replayed['ticks']}, recorded 30 frames, replayed it from its state "
            f"({branch_replay['checkpoints']} checkpoints), exported save {exported[:8]}; "
            f"refresh {1000 * sum(timings) / len(timings):.1f} ms average, {1000 * max(timings):.1f} ms worst")
