#!/usr/bin/env python3
# ---------------------------------------------------------------
# Knotworking: Piezo -> Serial -> OSC -> SuperCollider
# Reads piezo hits from the ESP and triggers SuperCollider sounds.
# ---------------------------------------------------------------

from pythonosc.udp_client import SimpleUDPClient
import serial
import time

# --- OSC: where SuperCollider (sclang) is listening ---
# sclang listens on 57120 by default, on the same Pi (localhost).
client = SimpleUDPClient("127.0.0.1", 57120)

# --- Serial: the ESP port on the Pi ---
PORT = '/dev/ttyUSB0'
BAUD = 115200

# --- Trigger settings ---
THRESHOLDS = [100, 100, 100, 100, 100, 100, 100]  # one per sensor
GLOBAL_BREAK = 0.4          # seconds: min gap between any two triggers
last_global_trigger = 0

# Open the serial port
try:
    ser = serial.Serial(PORT, BAUD, timeout=0.01)
except Exception as e:
    print(f"Konnte {PORT} nicht öffnen: {e}")
    print("Port pruefen mit: ls /dev/ttyUSB* /dev/ttyACM*")
    raise SystemExit(1)

print("Knotworking laeuft! Klopf ans Netz. Strg-C zum Stoppen.\n")

try:
    while True:
        line = ser.readline().decode('utf-8', errors='ignore').strip()

        if line and ',' in line:
            try:
                vals = [int(v) for v in line.split(',')]
                now = time.time()

                # global debounce: don't fire too often
                if (now - last_global_trigger) < GLOBAL_BREAK:
                    continue

                for i in range(len(vals)):
                    if i < len(THRESHOLDS) and vals[i] > THRESHOLDS[i]:

                        # --- your sensor -> sound mapping ---
                        if i == 0:
                            client.send_message("/tone", 440)
                        elif i == 1:
                            client.send_message("/bass", 1)
                        elif i == 2:
                            client.send_message("/pad", 1)
                        elif i == 3:
                            client.send_message("/tone", 660)
                        elif i == 4:
                            client.send_message("/noise", 1)
                        elif i == 5:
                            client.send_message("/kick", 1)
                        elif i == 6:
                            client.send_message("/tone", 220)

                        print(f"PIEZO {i} -> Sound! (Signal: {vals[i]})")

                        last_global_trigger = now
                        break  # one sound per reading

            except (ValueError, IndexError):
                continue

except KeyboardInterrupt:
    print("\nGestoppt.")
finally:
    ser.close()
