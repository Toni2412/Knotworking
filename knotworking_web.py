#!/usr/bin/env python3
# ---------------------------------------------------------------
# Knotworking - Website zum An/Aus-Schalten
# Kleiner Flask-Server, der eine simple Seite mit An/Aus-Knopf
# ausliefert und OSC-Befehle an SuperCollider schickt.
#
# Erreichbar unter:
#   - im AP-Modus:  http://192.168.4.1:5000
#   - im Hotspot:   http://<pi-ip>:5000  (zum Testen)
# ---------------------------------------------------------------

from flask import Flask, render_template_string, redirect, url_for
from pythonosc.udp_client import SimpleUDPClient

app = Flask(__name__)

# OSC-Ziel: SuperCollider auf diesem Pi
osc = SimpleUDPClient("127.0.0.1", 57120)

# Aktueller Zustand (True = laeuft, False = aus)
state = {"on": True}

# ---------- Die Webseite (schlicht) ----------
PAGE = """
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Knotworking</title>
    <style>
        body {
            font-family: -apple-system, system-ui, sans-serif;
            background: #1a1a1a;
            color: #eee;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
            text-align: center;
        }
        h1 { font-weight: 300; letter-spacing: 2px; margin-bottom: 40px; }
        .status { font-size: 1.2em; margin-bottom: 30px; opacity: 0.7; }
        .btn {
            display: inline-block;
            padding: 30px 60px;
            font-size: 1.5em;
            border: none;
            border-radius: 16px;
            cursor: pointer;
            text-decoration: none;
            color: #fff;
            transition: opacity 0.2s;
        }
        .btn:active { opacity: 0.6; }
        .on  { background: #2d7a4a; }
        .off { background: #a83232; }
    </style>
</head>
<body>
    <h1>KNOTWORKING</h1>
    <div class="status">
        Status: {{ "AN" if on else "AUS" }}
    </div>
    {% if on %}
        <a href="/off" class="btn off">Installation ausschalten</a>
    {% else %}
        <a href="/on" class="btn on">Installation einschalten</a>
    {% endif %}
</body>
</html>
"""

@app.route("/")
def index():
    return render_template_string(PAGE, on=state["on"])

@app.route("/on")
def turn_on():
    osc.send_message("/mute", [0])   # 0 = an
    state["on"] = True
    return redirect(url_for("index"))

@app.route("/off")
def turn_off():
    osc.send_message("/mute", [1])   # 1 = aus
    state["on"] = False
    return redirect(url_for("index"))

if __name__ == "__main__":
    # host="0.0.0.0" -> von anderen Geraeten im Netz erreichbar (nicht nur localhost)
    # port=5000 -> Standard-Flask-Port
    app.run(host="0.0.0.0", port=5000)
