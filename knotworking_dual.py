#!/usr/bin/env python3
# ---------------------------------------------------------------
# Knotworking: TWO ESPs -> Serial -> OSC -> SuperCollider
# Mit Velocity: die Signalstaerke steuert die Lautstaerke (amp).
#
# Harfe (oben)  -> /harfe <freq> <amp>   (angeschlagener Klang)
# Netz  (unten) -> /netz  <freq> <amp>   (tiefer Drone/Bass)
#
# 7 Piezos pro ESP (GPIO 36,39,34,35,32,33,25 am ESP).
# ---------------------------------------------------------------

from pythonosc.udp_client import SimpleUDPClient
import serial
import time

# --- OSC target: SuperCollider (sclang) auf diesem Pi ---
client = SimpleUDPClient("127.0.0.1", 57120)

# ================================================================
#  ESP-ZUORDNUNG (stabile by-path Pfade, tauschen nie)
#  Harfe = hcd.0 (oben),  Netz = hcd.1 (unten)
# ================================================================
HARFE_PORT = "/dev/serial/by-path/platform-xhci-hcd.0-usb-0:2:1.0-port0"  # oben
NETZ_PORT  = "/dev/serial/by-path/platform-xhci-hcd.1-usb-0:2:1.0-port0"  # unten

BAUD = 115200

# --- Trigger settings (7 piezos pro ESP) ---
THRESHOLDS = [100, 100, 100, 100, 100, 100, 100]
GLOBAL_BREAK = 0.4          # Sekunden zwischen zwei Ausloesungen (global)
last_global_trigger = 0

# ================================================================
#  VELOCITY: Signalstaerke -> Lautstaerke (wie im pygame-Code)
#  Signal 100..1000  ->  amp 0.1..1.0
# ================================================================
def signal_to_amp(signal):
    strength = max(100, min(signal, 1000))
    amp = 0.1 + ((strength - 100) / 900) * 0.9
    return round(amp, 3)

# ================================================================
#  FREQUENZEN
#  Harfe: deine 7 Pentatonik-Werte
#  Netz:  tiefere, ergaenzende Toene (Bass-Bereich)
# ================================================================
HARFE_FREQS = [261.63, 196.00, 293.66, 329.63, 392.00, 440.00, 220.00]
NETZ_FREQS  = [ 65.41,  55.00,  73.42,  82.41,  98.00, 110.00,  49.00]  # ~2 Oktaven tiefer

def harfe_sound(i, signal):
    amp = signal_to_amp(signal)
    freq = HARFE_FREQS[i] if i < len(HARFE_FREQS) else 440
    client.send_message("/harfe", [freq, amp])
    print(f"HARFE piezo {i} -> {freq}Hz  amp {amp}  (Signal {signal})")

def netz_sound(i, signal):
    amp = signal_to_amp(signal)
    freq = NETZ_FREQS[i] if i < len(NETZ_FREQS) else 110
    client.send_message("/netz", [freq, amp])
    print(f"NETZ  piezo {i} -> {freq}Hz  amp {amp}  (Signal {signal})")


def open_port(path, name):
    try:
        s = serial.Serial(path, BAUD, timeout=0.01)
        print(f"[OK] {name} verbunden: {path}")
        return s
    except Exception as e:
        print(f"[FEHLER] {name} konnte nicht geoeffnet werden: {e}")
        return None


def read_esp(ser, sound_fn):
    global last_global_trigger
    if ser is None:
        return
    line = ser.readline().decode('utf-8', errors='ignore').strip()
    if not line or ',' not in line:
        return
    try:
        vals = [int(v) for v in line.split(',')]
    except ValueError:
        return
    now = time.time()
    if (now - last_global_trigger) < GLOBAL_BREAK:
        return
    for i in range(len(vals)):
        if i < len(THRESHOLDS) and vals[i] > THRESHOLDS[i]:
            sound_fn(i, vals[i])
            last_global_trigger = now
            return


# --- Beide ESPs oeffnen ---
harfe = open_port(HARFE_PORT, "HARFE (oben)")
netz  = open_port(NETZ_PORT,  "NETZ  (unten)")

if harfe is None and netz is None:
    print("Kein ESP gefunden - Abbruch.")
    raise SystemExit(1)

print("\nKnotworking laeuft! Klopf an Harfe oder Netz. Strg-C zum Stoppen.\n")

try:
    while True:
        read_esp(harfe, harfe_sound)
        read_esp(netz,  netz_sound)
except KeyboardInterrupt:
    print("\nGestoppt.")
finally:
    if harfe: harfe.close()
    if netz:  netz.close()
