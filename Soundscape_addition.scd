// ================================================================
//  KNOTWORKING - Erweiterung fuer Harfe + Netz
//  Mit load("...Soundscape_addition.scd"); laden.
// ================================================================
(
// ---------- HARFE: der angeschlagene, organische Ton ----------
SynthDef(\harfe, { |freq = 440, amp = 0.5|
    var fundamental, overtones, strike, env, sig;

    fundamental = SinOsc.ar(freq) * 1.0;

    overtones =
        (SinOsc.ar(freq * 2.102) * 0.4) +
        (SinOsc.ar(freq * 3.505) * 0.2) +
        (SinOsc.ar(freq * 5.201) * 0.1);

    strike = WhiteNoise.ar(0.2) * EnvGen.ar(Env.perc(0.001, 0.02));

    env = EnvGen.ar(
        Env.perc(0.001, 3.0, curve: -4),
        doneAction: 2
    );

    sig = (fundamental + overtones + strike) * env * amp;
    sig = sig ! 2;
    Out.ar(0, sig);
}).add;

// ---------- NETZ: tiefer, tragender Drone/Bass ----------
SynthDef(\netz, { |freq = 110, amp = 0.5|
    var sub, body, env, sig;

    sub  = SinOsc.ar(freq / 2) * 0.5;
    body = SinOsc.ar(freq) * 0.6 + (Saw.ar(freq) * 0.15);

    env = EnvGen.ar(
        Env.perc(0.02, 4.5, curve: -3),
        doneAction: 2
    );

    sig = (sub + body) * env * amp;
    sig = LPF.ar(sig, 800);
    sig = sig ! 2;
    Out.ar(0, sig);
}).add;

// ---------- OSC-HANDLER ----------
OSCdef(\harfeTrig, { |msg|
    Synth(\harfe, [\freq, msg[1], \amp, msg[2]]);
}, "/harfe");

OSCdef(\netzTrig, { |msg|
    Synth(\netz, [\freq, msg[1], \amp, msg[2]]);
}, "/netz");

"=== HARFE + NETZ bereit ===".postln;
)
