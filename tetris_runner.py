"""
ARM Retro Console v2.0 - Tetris Runner (VSYNC Edition)
Runs an ARM assembly game inside the Unicorn emulator.
Controls: W/A/S/D or Arrow keys. Q to quit.
"""
import sys
import os
import time
import ctypes
import binascii
import threading
import struct
import random
from unicorn import *
from unicorn.arm_const import *

_GetAsyncKeyState = ctypes.windll.user32.GetAsyncKeyState
def _key_held(vk): return bool(_GetAsyncKeyState(vk) & 0x8000)

VK_UP, VK_DOWN   = 0x26, 0x28
VK_LEFT, VK_RIGHT = 0x25, 0x27
VK_W,  VK_S      = 0x57, 0x53
VK_A,  VK_D      = 0x41, 0x44
VK_Q             = 0x51
VK_SPACE = 0x20

CODE_ADDR  = 0x10000
DATA_ADDR  = 0x20000
VRAM_ADDR  = 0x30000
IO_ADDR    = 0x40000

# VSYNC port: when ARM writes 1 here, we know a frame is ready to render.
VSYNC_PORT = IO_ADDR + 8

CONSOLE_WIDTH  = 40
CONSOLE_HEIGHT = 20

# Binary is read from a separate file -- update tetris_binary.hex when the assembly code changes
_HEX_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tetris_binary.hex")
with open(_HEX_FILE) as _f:
    TETRIS_BINARY = _f.read().strip()
def init_emulator():
    mu = Uc(UC_ARCH_ARM, UC_MODE_ARM)
    mu.mem_map(CODE_ADDR, 0x10000)
    mu.mem_map(DATA_ADDR, 0x10000)
    mu.mem_map(VRAM_ADDR, 0x2000)   # 8 KB: VRAM 0x30000-0x307FF + CRAM 0x30800-0x30FFF
    mu.mem_map(IO_ADDR, 0x1000)

    binary = binascii.unhexlify(TETRIS_BINARY)
    mu.mem_write(CODE_ADDR, binary)

    # Memory write hook: stop emulation when ARM signals VSYNC
    def hook_mem_write(uc, access, address, size, value, user_data):
        if address == VSYNC_PORT and value == 1:
            # ARM wrote 1 to VSYNC port -- frame is done, stop emulator
            uc.emu_stop()

    mu.hook_add(UC_HOOK_MEM_WRITE, hook_mem_write)

    return mu, len(binary)

def render_vram(mu):
    # Read character data (VRAM) and color data (CRAM)
    vram = mu.mem_read(VRAM_ADDR, CONSOLE_WIDTH * CONSOLE_HEIGHT)
    cram = mu.mem_read(VRAM_ADDR + 0x800, CONSOLE_WIDTH * CONSOLE_HEIGHT)

    # ANSI color codes (indices 0-7)
    ANSI_COLORS = [
        "\033[0m",   # 0: White (default)
        "\033[31m",  # 1: Red    (Z-piece)
        "\033[32m",  # 2: Green  (S-piece)
        "\033[33m",  # 3: Yellow (O-piece)
        "\033[34m",  # 4: Blue   (J-piece)
        "\033[35m",  # 5: Magenta (T-piece)
        "\033[36m",  # 6: Cyan   (I-piece)
        "\033[90m"   # 7: Dark grey (walls / empty)
    ]
    RESET_COLOR = "\033[0m"

    parts = ["\033[H"]
    parts.append("+" + "-" * CONSOLE_WIDTH + "+\n")

    for row in range(CONSOLE_HEIGHT):
        row_chars = []
        for col in range(CONSOLE_WIDTH):
            idx = row * CONSOLE_WIDTH + col
            b = vram[idx]
            color_idx = cram[idx] & 7  # Clamp color index to 0-7

            char = chr(b) if 32 <= b <= 126 else ' '
            color_code = ANSI_COLORS[color_idx]

            row_chars.append(f"{color_code}{char}")

        parts.append("|" + "".join(row_chars) + f"{RESET_COLOR}|\n")

    parts.append("+" + "-" * CONSOLE_WIDTH + "+\n")
    parts.append("Controls: W/A/S/D/Arrows. SPACE=Restart. Q=Quit.   ")
    sys.stdout.write("".join(parts))
    sys.stdout.flush()

def input_thread_func(mu, running):
    while running[0]:
        if _key_held(VK_Q):
            running[0] = False
        buttons = 0
        if _key_held(VK_UP)    or _key_held(VK_W): buttons |= 1
        if _key_held(VK_DOWN)  or _key_held(VK_S): buttons |= 2
        if _key_held(VK_LEFT)  or _key_held(VK_A): buttons |= 4
        if _key_held(VK_RIGHT) or _key_held(VK_D): buttons |= 8
        if _key_held(VK_SPACE):                    buttons |= 16  # restart
        mu.mem_write(IO_ADDR, struct.pack("<I", buttons))
        time.sleep(0.01)

def run_game():
    mu, code_len = init_emulator()
    mu.mem_write(DATA_ADDR, bytes(0x10000))
    mu.mem_write(VRAM_ADDR, bytes(0x1000))
    mu.mem_write(IO_ADDR, bytes(0x1000))

    # Clear terminal and hide cursor
    sys.stdout.write("\033[2J\033[H\033[?25l")
    sys.stdout.flush()

    running = [True]
    input_t = threading.Thread(target=input_thread_func, args=(mu, running), daemon=True)
    input_t.start()

    try:
        while running[0]:
            # Update RNG
            mu.mem_write(IO_ADDR + 4, struct.pack("<I", random.randint(0, 0xFFFFFFFF)))

            # Reset VSYNC before running
            mu.mem_write(VSYNC_PORT, b'\x00\x00\x00\x00')

            # timeout=0 means run until the hook calls emu_stop() on VSYNC
            mu.emu_start(CODE_ADDR, CODE_ADDR + code_len, timeout=0)

            # ARM has signalled "frame ready" -- render it
            render_vram(mu)

            # Frame rate limiter (~20 fps); reduce for faster gameplay
            time.sleep(0.05)

    except UcError as e:
        print(f"\nEmulator error: {e}")
    except KeyboardInterrupt:
        pass

    sys.stdout.write("\033[?25h")
    sys.stdout.flush()
    print("\nGame over. Goodbye!")

if __name__ == "__main__":
    run_game()
