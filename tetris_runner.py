"""
ARM Retro Console v2.0 - Tetris Runner (VSYNC Edition)
Suorittaa ARM-assemblylla kirjoitetun pelin Unicorn-emulaattorissa.
Ohjaus: W/A/S/D tai Nuolinäppäimet. Q lopettaa.
"""
import sys
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

CODE_ADDR  = 0x10000
DATA_ADDR  = 0x20000
VRAM_ADDR  = 0x30000
IO_ADDR    = 0x40000

# UUSI PORTTI: Kun ARM kirjoittaa tänne 1, tiedämme että "Frame" on valmis piirrettäväksi!
VSYNC_PORT = IO_ADDR + 8

CONSOLE_WIDTH  = 40
CONSOLE_HEIGHT = 20

# AGENTIN UUSIN HEX (Kopioi tämä aina kun Cline tekee uuden):
TETRIS_BINARY = (
    "00d008e302d040e3008000e3038040e3009000e3029040e3000199e5000050e34b00001a0100a0e3000189e5030c89e20010a0e30010c0e50f10a0e30110c0e50010a0e30210c0e50310c0e5c10f89e20210a0e30010c0e50110c0e50710a0e30210c0e50010a0e30310c0e5c20f89e20410a0e30010c0e50110c0e50710a0e30210c0e50010a0e30310c0e5c30f89e26610a0e30010c0e50110c0e50010a0e30210c0e50310c0e5310e89e20310a0e30010c0e50610a0e30110c0e50010a0e30210c0e50310c0e5c50f89e20210a0e30010c0e50710a0e30110c0e50210a0e30210c0e50010a0e30310c0e5c60f89e20610a0e30010c0e50310a0e30110c0e50010a0e30210c0e50310c0e50000a0e3040189e5080189e50c0189e5100189e5140189e5180189e50300a0e3040189e50000a0e3080189e5020c89e20010a0e3c820a0e30110c0e4012052e2fcffff1a4b0000eb180199e5010050e34100000a140199e5010080e2140189e5000000e3040040e3004090e5020014e30200000a6400a0e3140189e5030000ea140199e514c000e30c0050e1150000ba0000a0e3140189e50c0199e5041199e5082199e5012082e2460000eb000050e30300001a080199e5010080e2080189e5080000ea0c0199e5041199e5082199e50130a0e36b0000eb960000eb250000ebd00000ebd7ffffea000000e3040040e3004090e5040014e30900000a0c0199e5041199e5011041e2082199e52d0000eb000050e30200001a040199e5010040e2040189e5080014e30900000a0c0199e5041199e5011081e2082199e5210000eb000050e30200001a040199e5010080e2040189e5b30000ebbaffffeab10000eb630100eb080000e3040040e30110a0e3001080e5f8ffffeaf0402de9040000e3040040e3000090e50710a0e36f0100eb0c0189e50300a0e3040189e50000a0e3080189e50c0199e5041199e5082199e5040000eb000050e30100000a0100a0e3180189e5f080bde8f04d2de90040a0e10150a0e10260a0e10470a0e10771a0e1097087e0037c87e20040a0e30400d7e7000050e31c00000a0080a0e308c0a0e30c0010e11400000a041086e0082085e0130051e3190000aa000051e30e0000ba000052e3150000ba0a0052e3130000aa01a0a0e18aa1a0e101b0a0e18bb0a0e10b308ae0023083e0093083e0023c83e20030d3e5000053e30800001aacc0a0e1018088e2040058e3e4ffffba014084e2040054e3dcffffba0000a0e3f08dbde80100a0e3f08dbde8f0402de90040a0e10150a0e10260a0e10370a0e10401a0e1090080e0030c80e20040a0e30410d0e7000051e31b00000a0030a0e308c0a0e30c0011e11300000a042086e003b085e0000052e30f0000ba140052e30d0000aa00005be30b0000ba0a005be3090000aa04202de502a0a0e18221a0e18aa0a0e10a2082e00b2082e0092082e0022c82e20070c2e504209de4acc0a0e1013083e2040053e3e5ffffba014084e2040054e3ddffffbaf080bde8f04d2de91340a0e304a0a0e18aa1a0e104b0a0e18bb0a0e10b508ae0095085e0025c85e20060a0e30070a0e30700d5e7000050e30000000a016086e2017087e20a0057e3f8ffffba0a0056e32400001a100199e5640080e2100189e50460a0e1000056e3160000da06a0a0e18aa1a0e106b0a0e18bb0a0e10b508ae0095085e0025c85e201c046e20ca0a0e18aa1a0e10cb0a0e18bb0a0e10b708ae0097087e0027c87e20000a0e30010d7e70010c5e7010080e20a0050e3faffffba016046e2e6ffffea020c89e20010a0e30020a0e30210c0e7012082e20a0052e3fbffffbac8ffffea014054e2c6ffffaaf08dbde8f04c2de92000a0e30810a0e1322ea0e30100c1e4012052e2fcffff1a0040a0e37c50a0e30460a0e18662a0e10470a0e18771a0e1071086e0010088e00e0080e20050c0e5010088e0190080e20050c0e5014084e2140054e3f1ffffba0040a0e30050a0e304a0a0e18aa1a0e104b0a0e18bb0a0e10b008ae0050080e0090080e0020c80e20000d0e5000050e30900000a04a0a0e18aa2a0e104b0a0e18bb1a0e10b008ae0050080e00f0080e2080080e02310a0e30010c0e5015085e20a0055e3e7ffffba014084e2140054e3e3ffffba0800a0e1020c80e2010c80e2080040e20f0080e22d10a0e30010c0e50110c0e50210c0e50310c0e50410c0e50510c0e50610c0e50710c0e50810c0e50910c0e50c0199e5041199e5082199e52330a0e33c0000eb100199e50810a0e16e2000e3021081e00020a0e3fa0f50e3020000bafa0f40e2012082e2faffffea0020c1e50020a0e3640050e3020000ba640040e2012082e2faffffea302082e20120c1e50020a0e30a0050e3020000ba0a0040e2012082e2faffffea302082e20220c1e5300080e20300c1e50000d1e5300080e20000c1e5180199e5010050e31400001a0800a0e1a01000e3010080e04710a0e30010c0e54110a0e30110c0e54d10a0e30210c0e54510a0e30310c0e52010a0e30410c0e54f10a0e30510c0e55610a0e30610c0e54510a0e30710c0e55210a0e30810c0e5080000e3040040e30110a0e3001080e5f08cbde8f0402de90040a0e10150a0e10260a0e10370a0e10401a0e1090080e0030c80e20040a0e30410d0e7000051e31c00000a0030a0e30320a0e3032042e001c0a0e31cc2a0e10c0011e11200000a042086e0000052e30f0000ba140052e30d0000aa03c085e000005ce30a0000ba0a005ce3080000aa04102de58212a0e18221a0e1021081e00c1081e00f1081e2081081e00070c1e504109de4013083e2040053e3e3ffffba014084e2040054e3dcffffbaf080bde8f0402de90800a0e1a01000e3010080e04710a0e30010c0e54110a0e30110c0e54d10a0e30210c0e54510a0e30310c0e52010a0e30410c0e54f10a0e30510c0e55610a0e30610c0e54510a0e30710c0e55210a0e30810c0e5f080bde8070000e2070050e30000001a0600a0e31eff2fe1"
)

def init_emulator():
    mu = Uc(UC_ARCH_ARM, UC_MODE_ARM)
    mu.mem_map(CODE_ADDR, 0x10000)
    mu.mem_map(DATA_ADDR, 0x10000)
    mu.mem_map(VRAM_ADDR, 0x1000)
    mu.mem_map(IO_ADDR, 0x1000)

    binary = binascii.unhexlify(TETRIS_BINARY)
    mu.mem_write(CODE_ADDR, binary)

    # LISÄÄ TÄMÄ KOUKKU-FUNKTIO:
    def hook_mem_write(uc, access, address, size, value, user_data):
        if address == VSYNC_PORT and value == 1:
            # Kun ARM kirjoittaa 1 VSYNC-porttiin, PYSÄYTÄ emulaattorin suoritus välittömästi!
            uc.emu_stop()

    # Rekisteröidään koukku valvomaan muistiin kirjoittamista (UC_HOOK_MEM_WRITE)
    mu.hook_add(UC_HOOK_MEM_WRITE, hook_mem_write)

    return mu, len(binary)

def render_vram(mu):
    vram = mu.mem_read(VRAM_ADDR, CONSOLE_WIDTH * CONSOLE_HEIGHT)
    parts = ["\033[H"]
    parts.append("+" + "-" * CONSOLE_WIDTH + "+\n")
    for row in range(CONSOLE_HEIGHT):
        row_chars = []
        for col in range(CONSOLE_WIDTH):
            b = vram[row * CONSOLE_WIDTH + col]
            row_chars.append(chr(b) if 32 <= b <= 126 else ' ')
        parts.append("|" + "".join(row_chars) + "|\n")
    parts.append("+" + "-" * CONSOLE_WIDTH + "+\n")
    parts.append("Ohjaus: W/A/S/D tai Nuolet. Q = Lopeta.   ")
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
        mu.mem_write(IO_ADDR, struct.pack("<I", buttons))
        time.sleep(0.01)

def run_game():
    mu, code_len = init_emulator()
    mu.mem_write(DATA_ADDR, bytes(0x10000))
    mu.mem_write(VRAM_ADDR, bytes(0x1000))
    mu.mem_write(IO_ADDR, bytes(0x1000))

    # Tyhjennetään terminaali ja piilotetaan kursori
    sys.stdout.write("\033[2J\033[H\033[?25l")
    sys.stdout.flush()

    running = [True]
    input_t = threading.Thread(target=input_thread_func, args=(mu, running), daemon=True)
    input_t.start()

    try:
        while running[0]:
            # RNG:n päivitys
            mu.mem_write(IO_ADDR + 4, struct.pack("<I", random.randint(0, 0xFFFFFFFF)))
            
            # VSYNC:in nollaus ENNEN ajoa
            mu.mem_write(VSYNC_PORT, b'\x00\x00\x00\x00')

            # TÄMÄ ON KRIITTINEN MUUTOS: timeout=0 tarkoittaa että ajetaan 
            # kunnes koukku (hook) pysäyttää sen emu_stop():lla.
            mu.emu_start(CODE_ADDR, CODE_ADDR + code_len, timeout=0)

            # Kun tullaan tähän, ARM on juuri sanonut "Frame valmis" koukun kautta.
            render_vram(mu)

            # Pelin nopeuden säätö (esim 60fps = 1/60 = n. 0.016s)
            time.sleep(0.05)  # Säädä tätä jos peli on liian nopea tai hidas

    except UcError as e:
        print(f"\nEmulaattorivirhe: {e}")
    except KeyboardInterrupt:
        pass

    sys.stdout.write("\033[?25h")
    sys.stdout.flush()
    print("\nPeli päättyi.")

if __name__ == "__main__":
    run_game()
