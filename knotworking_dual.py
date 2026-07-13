#!/usr/bin/env python3
# ---------------------------------------------------------------
# Knotworking: TWO ESPs -> Serial -> OSC -> SuperCollider
#
# Reads piezo hits from two ESPs (Harfe + Netz) over stable
# by-path device paths, so the assignment never swaps on reboot.
# ---------------------------------------------------------------

from pythonosc.udp_client import SimpleUDPClient
import serial
import time

# --- OSC target: SuperCollider (sclang) on this Pi ---
client = SimpleUDPClient("127.0.0.1", 57120)

# ================================================================
#  ESP ASSIGNMENT  --  the important part
# ----------------------------------------------------------------
#  These stable paths are tied to the PHYSICAL USB socket,
#  not to the ttyUSB number, so they survive reboots.
#
#  If Harfe and Netz come out swapped, just swap these two paths.
# ================================================================
HARFE_PORT = "/dev/serial/by-path/platform-xhci-hcd.0-usb-0:2:1.0-port0"  # oben
NETZ_PORT  = "/dev/serial/by-path/platform-xhci-hcd.1-usb-0:2:1.0-port0"  # unten

BAUD = 115200

# --- Trigger settings (per ESP, 6 piezos each) ---
THRESHOLDS = [100, 100, 100, 100, 100, 100]
GLOBAL_BREAK = 0.4          # seconds between any two triggers (global)
last_global_trigger = 0

# ================================================================
#  SOUND MAPPING
#  Harfe piezos 0-5  and  Netz piezos 0-5
#  Adjust the OSC messages to taste later.
# ================================================================
def harfe_sound(i, signal):
    if   i == 0: client.send_message("/tone", 440)
    elif i == 1: client.send_message("/bass", 1)
    elif i == 2: client.send_message("/pad", 1)
    elif i == 3: client.send_message("/tone", 660)
    elif i == 4: client.send_message("/noise", 1)
    elif i == 5: client.send_message("/kick", 1)
    print(f"HARFE piezo {i} -> Sound! (Signal: {signal})")

def netz_sound(i, signal):
    if   i == 0: client.send_message("/tone", 220)
    elif i == 1: client.send_message("/tone", 330)
    elif i == 2: client.send_message("/pad", 1)
    elif i == 3: client.send_message("/bass", 1)
    elif i == 4: client.send_message("/kick", 1)
    elif i == 5: client.send_message("/noise", 1)
    print(f"NETZ  piezo {i} -> Sound! (Signal: {signal})")


def open_port(path, name):
    """Open a serial port, with a clear message if it fails."""
    try:
        s = serial.Serial(path, BAUD, timeout=0.01)
        print(f"[OK] {name} verbunden: {path}")
        return s
    except Exception as e:
        print(f"[FEHLER] {name} konnte nicht geoeffnet werden: {e}")
        return None


def read_esp(ser, thresholds, sound_fn):
    """Read one line from an ESP and trigger sounds. Returns True if a sound fired."""
    global last_global_trigger
    if ser is None:
        return False

    line = ser.readline().decode('utf-8', errors='ignore').strip()
    if not line or ',' not in line:
        return False

    try:
        vals = [int(v) for v in line.split(',')]
    except ValueError:
        return False

    now = time.time()
    if (now - last_global_trigger) < GLOBAL_BREAK:
        return False

    for i in range(len(vals)):
        if i < len(thresholds) and vals[i] > thresholds[i]:
            sound_fn(i, vals[i])
            last_global_trigger = now
            return True
    return False


# --- Open both ESPs ---
harfe = open_port(HARFE_PORT, "HARFE (oben)")
netz  = open_port(NETZ_PORT,  "NETZ  (unten)")

if harfe is None and netz is None:
    print("Kein ESP gefunden - Abbruch.")
    raise SystemExit(1)

print("\nKnotworking laeuft! Klopf ans Netz oder die Harfe. Strg-C zum Stoppen.\n")

try:
    while True:
        # Read both ESPs each loop; whichever has data triggers.
        read_esp(harfe, THRESHOLDS, harfe_sound)
        read_esp(netz,  THRESHOLDS, netz_sound)

except KeyboardInterrupt:
    print("\nGestoppt.")
finally:
    if harfe: harfe.close()
    if netz:  netz.close()
