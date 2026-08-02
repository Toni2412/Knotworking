// ================================================================
//  KNOTWORKING - Autostart-Skript fuer SuperCollider
//  Wird beim Booten automatisch von sclang abgearbeitet.
//  Ersetzt das manuelle Tippen von:
//    s.boot; -> warten -> load(Soundscape_2) -> load(Soundscape_addition)
// ================================================================

// Audio-Konfiguration (wie in Soundscape_2 - kein Mikrofon-Input noetig)
s.options.numInputBusChannels = 0;

// Server booten UND warten bis er wirklich bereit ist,
// DANN erst die Soundscapes laden (das ist dein "auf server ready warten").
s.waitForBoot({

    // --- Lautstaerke (spaeter fuer die Ausstellung anpassen) ---
    // Zeile einkommentieren und Wert setzen, wenn noetig:
    // s.volume.volume = 6;

    // --- Deine Klaenge laden ---
    load("/home/knotworking/Knotworking/Soundscape_2.scd");
    load("/home/knotworking/Knotworking/Soundscape_addition.scd");

    "=== KNOTWORKING AUTOSTART FERTIG ===".postln;
});
