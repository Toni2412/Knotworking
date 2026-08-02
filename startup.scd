// ================================================================
//  KNOTWORKING - Autostart-Skript fuer SuperCollider (robust)
//  Wird beim Booten automatisch von sclang abgearbeitet.
//
//  Nutzt eine Routine mit s.sync, damit JEDER Schritt wirklich
//  abgeschlossen ist, bevor der naechste kommt:
//    booten -> warten -> Soundscape_2 laden -> warten
//           -> Soundscape_addition laden -> fertig
// ================================================================

s.options.numInputBusChannels = 0;

s.waitForBoot({
    // Wir laufen hier schon in einer Routine (waitForBoot),
    // deshalb ist s.sync erlaubt und laesst uns sauber warten.

    // --- Lautstaerke (spaeter fuer die Ausstellung anpassen) ---
    // s.volume.volume = 6;

    s.sync;  // sicherstellen, dass der Server wirklich bereit ist

    // Erste Datei laden und warten, bis ihre SynthDefs/Handler da sind
    load("/home/knotworking/Knotworking/Soundscape_2.scd");
    s.sync;
    1.wait;  // eine Sekunde Puffer, damit alles registriert ist

    // Zweite Datei laden
    load("/home/knotworking/Knotworking/Soundscape_addition.scd");
    s.sync;
    1.wait;

    "=== KNOTWORKING AUTOSTART FERTIG ===".postln;
});
