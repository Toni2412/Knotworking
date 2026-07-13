// ================================================================
//  KNOTWORKING - Erweiterung fuer Harfe + Netz
//  An das Ende von Soundscape_2.scd anhaengen (VOR dem letzten
//  schliessenden Teil, der "=== READY ===" druckt - siehe Hinweis).
//
//  Baut den organischen "angeschlagenen" Klang aus dem pygame-Code
//  in SuperCollider nach:
//    - Grundton
//    - inharmonische Obertoene (2.102x, 3.505x, 5.201x)
//    - kurzer Strike-Noise am Anfang
//    - langer exponentieller Ausklang
//  Velocity (0.0-1.0) steuert die Lautstaerke.
// ================================================================

(
// ---------- HARFE: der angeschlagene, organische Ton ----------
SynthDef(\harfe, { |freq = 440, amp = 0.5, gate = 1|
    var fundamental, overtones, strike, env, sig;

    // 1. Grundton
    fundamental = SinOsc.ar(freq) * 1.0;

    // 2. Inharmonische Obertoene (wie im pygame-Code)
    overtones =
        (SinOsc.ar(freq * 2.102) * 0.4) +
        (SinOsc.ar(freq * 3.505) * 0.2) +
        (SinOsc.ar(freq * 5.201) * 0.1);

    // 3. Strike-Noise (kurzer Impuls am Anfang, ~20ms)
    strike = WhiteNoise.ar(0.2) * EnvGen.ar(Env.perc(0.001, 0.02));

    // 4. Langer exponentieller Ausklang (Env.perc mit langem release)
    env = EnvGen.ar(
        Env.perc(0.001, 3.0, curve: -4),  // schneller Anschlag, 3s Ausklang
        doneAction: 2                      // Synth danach freigeben
    );

    sig = (fundamental + overtones + strike) * env * amp;
    sig = sig ! 2;  // stereo
    Out.ar(0, sig);
}).add;

// ---------- NETZ: tiefer, tragender Drone/Bass ----------
// Ergaenzt die Harfe mit einem warmen, laenger stehenden Bassklang.
SynthDef(\netz, { |freq = 110, amp = 0.5|
    var sub, body, env, sig;

    // Tiefer Grundton + eine Oktave drunter (Sub)
    sub  = SinOsc.ar(freq / 2) * 0.5;
    body = SinOsc.ar(freq) * 0.6 + (Saw.ar(freq) * 0.15);

    // Weicher, laengerer Ausklang (tragender als die Harfe)
    env = EnvGen.ar(
        Env.perc(0.02, 4.5, curve: -3),
        doneAction: 2
    );

    sig = (sub + body) * env * amp;
    sig = LPF.ar(sig, 800);   // Tiefpass: warm, gedaempft
    sig = sig ! 2;
    Out.ar(0, sig);
}).add;
)

// ================================================================
//  OSC-HANDLER  -  reagieren auf die Nachrichten vom Python
//  Format:  "/harfe", <freq>, <amp>    und   "/netz", <freq>, <amp>
// ================================================================
(
// Harfe: erwartet Frequenz und Amplitude (Velocity)
OSCdef(\harfeTrig, { |msg|
    var freq = msg[1];
    var amp  = msg[2];
    Synth(\harfe, [\freq, freq, \amp, amp]);
}, "/harfe");

// Netz: erwartet Frequenz und Amplitude (Velocity)
OSCdef(\netzTrig, { |msg|
    var freq = msg[1];
    var amp  = msg[2];
    Synth(\netz, [\freq, freq, \amp, amp]);
}, "/netz");

"=== HARFE + NETZ bereit ===".postln;
)
