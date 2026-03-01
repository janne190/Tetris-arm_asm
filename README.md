# Tetris - ARM Assembly

Tetris implementation written in ARMv7 Assembly, running in a [Unicorn Engine](https://www.unicorn-engine.org/) emulator with a Python driver.

[![Tetris Demo](https://i.ytimg.com/vi/cNctX6qrSyM/hqdefault.jpg)](https://www.youtube.com/watch?v=cNctX6qrSyM)
---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Requirements](#requirements)
- [Installation and Running](#installation-and-running)
- [Controls](#controls)
- [Memory Map](#memory-map)
- [File Structure](#file-structure)

---

## Overview

The goal of the project is to implement a fully functional Tetris game purely in ARMv7 assembly. The game is run within an ARM emulator launched by a Python script, emulating a simple retro console environment with a VRAM display buffer and memory-mapped I/O.

The game board is a classic **10 x 20** grid. All seven standard tetrominos (I, J, L, O, S, T, Z) are defined.

---

## Architecture

```
,-----------------------------------------.
|           tetris_runner.py              |
|  (Python + Unicorn Engine driver)       |
|                                         |
|  +----------+   +------------------+    |
|  |  Input   |   | Display render   |    |
|  |  (Win32  |   | (ANSI terminal)  |    |
|  |  VK API) |   +------------------+    |
|  +----+-----+            ^              |
|       | MMIO write       | VRAM read    |
|  +----v------------------+----------+   |
|  |      Unicorn ARM emulator        |   |
|  |  +---------------------------+   |   |
|  |  |        main.s             |   |   |
|  |  |   (ARMv7 Assembly game)   |   |   |
|  |  +---------------------------+   |   |
|  +----------------------------------+   |
`-----------------------------------------'
```

### Memory and I/O Model

| Region | Address | Description |
|--------|---------|-------------|
| Code (ROM) | `0x10000` | ARM machine code binary |
| RAM | `0x20000` | Stack frame, game state, tetromino data |
| Game State | `0x20100` | Game state variables |
| Matrix | `0x20200` | Game board (10 x 20 bytes) |
| Tetromino Definitions | `0x20300` | 7 pieces x 4 bytes (row bitmask) |
| VRAM | `0x30000` | Display buffer (40 x 20 chars) |
| MMIO | `0x40000` | Keypad state |
| RNG Port | `0x40004` | Random number (Python writes) |
| VSYNC Port | `0x40008` | ARM writes `1` when frame is ready |

### Game State Variables (RAM `0x20100`)

| Offset | Description |
|--------|-------------|
| `+0x100` | Initialization flag |
| `+0x104` | Current piece: X-coordinate |
| `+0x108` | Current piece: Y-coordinate |
| `+0x10C` | Current piece type (0-6) |
| `+0x110` | Score |
| `+0x114` | Gravity counter |
| `+0x118` | Game over flag |
| `+0x11C` | High Score |
| `+0x120` | Current Level |
| `+0x124` | Lines Cleared |

---

## Features

- [x] All 7 standard tetrominos (I, J, L, O, S, T, Z)
- [x] 10 x 20 game board
- [x] Piece falling (gravity)
- [x] Moving left and right
- [x] Fast dropping (soft drop)
- [x] Full line detection and clearing
- [x] Shifting lines down after clearing
- [x] Collision detection (walls, floor, locked pieces)
- [x] Scoring (100 points per cleared line)
- [x] Score display (4-digit, max 9999)
- [x] Game over detection and "GAME OVER" text
- [x] VSYNC mechanism for smooth rendering
- [x] Text-based terminal display (ANSI control sequences)
- [x] Piece rotation
- [x] Next piece preview
- [x] Restart game without restarting the program
- [x] Level progression (game speeds up as score increases)
- [x] High score tracking
- [x] Game background colors / ASCII art

---

## Requirements

- **Windows** (input loop uses Win32 `GetAsyncKeyState` API)
- **Python 3.8+**
- **unicorn** Python library

```bash
pip install unicorn
```

> The Python package `unicorn` includes the pre-compiled Unicorn Engine library, no separate C libraries are needed.

---

## Installation and Running

1. Clone or download the repository:
   ```bash
   git clone https://github.com/janne190/Tetris-arm_asm.git
   cd Tetris-arm_asm
   ```

2. Install the dependency:
   ```bash
   pip install unicorn
   ```

3. Start the game:
   ```bash
   python tetris_runner.py
   ```

> The driver script reads the compiled ARM binary from `tetris_binary.hex`.
> A separate compiler (e.g., `arm-none-eabi-as`) is not needed to run the game.
> `main.s` is the source code file from which the binary is generated.

---

## Controls

| Key | Action |
|-----|--------|
| `A` or Left Arrow | Move piece left |
| `D` or Right Arrow | Move piece right |
| `S` or Down Arrow | Soft drop |
| `W` or Up Arrow | Rotate piece clockwise |
| `SPACE` | Restart game |
| `Q` | Quit game |

---

## File Structure

```
Tetris-arm_asm/
+-- main.s              # Game source code in ARMv7 Assembly
+-- tetris_runner.py    # Python driver (Unicorn Engine + terminal display)
+-- tetris_binary.hex   # Compiled game binary as an ASCII hex string
+-- README.md           # This file
```

---

## License

This project is released without a specific license. All rights reserved.
