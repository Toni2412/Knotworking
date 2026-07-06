// ============================================================================
//  SOUNDSCAPE_2.scd  —  ALL SOUNDS IN ONE FILE
//  ----------------------------------------------------------------------------
//  Merged from: tunes.scd  +  altj_soundscape_2.scd  +  indie_soundscape.scd
//  (altj_soundscape.scd was left out — it was fully contained in the _2 version.)
//
//  Three sound sets live here, each with its own OSC address prefix so they
//  never clash:
//
//    1. TUNES   — 7 simple one-shot sounds. Addresses:  /kick  /bass  /tone
//                 /pad  /sparkle  /noise  /subdrop
//                 (these go straight to the speakers)
//
//    2. ALT-J   — folk-tronica voices in A minor pentatonic. Addresses start
//                 with  /altj/...   Message format: [ value, intensity, pan ]
//
//    3. INDIE   — big indie palette in C major pentatonic. Addresses start
//                 with  /ind/...    Message format: [ value, intensity, pan ]
//
//  All three run through one shared reverb + master limiter (speaker-safe).
//
//  ----------------------------------------------------------------------------
//  HOW TO RUN (just like tunes.scd):
//    STEP 1: Double-click the ( on the line below to select the whole block,
//            then press Cmd + Enter. Wait for the "=== READY ===" message in
//            the post window (bottom pane). That message = everything loaded.
//    STEP 2: Drive it from Python (port 57120), or use the local test lines
//            at the very bottom of this file to hear voices by hand first.
//
//  STOP ALL SOUND: Cmd + .   (Command + period)
//  If you changed audio device / get boot errors:  s.reboot;   then re-run.
// ============================================================================


// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// >>>  STEP 1 — RUN THIS ONE BIG BLOCK ONCE.  (double-click the ( below)
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
(
// No audio INPUT needed (triggers come over OSC). Turning input off also
// avoids the Bluetooth-mic sample-rate clash that can stop the server booting.
s.options.numInputBusChannels = 0;

s.waitForBoot({

    // ---- clean slate so re-running this block never stacks or half-loads ----
    s.freeAll;         // stop any synths/beds left from a previous run
    s.initTree;        // REBUILD the default group (fixes "Group 1 not found")
    s.sync;            // wait until that's really done before we make our groups
    OSCdef.freeAll;    // remove all old OSC handlers

    // ====================================================================
    //  SHARED INFRASTRUCTURE  (buses, groups, reverb, master) — one set
    // ====================================================================
    ~rbus   = Bus.audio(s, 2);          // reverb send bus
    ~mbus   = Bus.audio(s, 2);          // main mix bus
    ~srcGrp = Group.new(s);             // all voices live here
    ~fxGrp  = Group.after(~srcGrp);     // reverb runs after the voices
    ~mstGrp = Group.after(~fxGrp);      // master limiter runs last

    // ---- two note-sets, one per soundscape ------------------------------
    // alt-J: A minor pentatonic (root A2)
    ~altjNotes = (0..3).collect({ |o|
        [0, 3, 5, 7, 10, 12].collect({ |d| (45 + d + (o * 12)).midicps })
    }).flatten;
    ~pickAltj = { |val| ~altjNotes[(val.clip(0, 1) * (~altjNotes.size - 1)).round.asInteger] };

    // indie: C major pentatonic (root C3)
    ~indNotes = (0..3).collect({ |o|
        [0, 2, 4, 7, 9, 12].collect({ |d| (48 + d + (o * 12)).midicps })
    }).flatten;
    ~pickIndie = { |val| ~indNotes[(val.clip(0, 1) * (~indNotes.size - 1)).round.asInteger] };


    // ====================================================================
    //  SET 1 — TUNES  (simple one-shot functions; go straight to speakers)
    //  Call by hand with ~playKick.(); etc. or trigger via /kick, /bass, ...
    // ====================================================================

    ~playKick = {
        { var env, pitch, sound;
            env   = EnvGen.kr(Env.perc(0.001, 0.5), doneAction: 2);
            pitch = XLine.kr(90, 40, 0.08);
            sound = SinOsc.ar(pitch, 0, 0.6) * env;
            sound ! 2
        }.play;
    };

    ~playBass = {
        { var env, sound;
            env   = EnvGen.kr(Env.perc(0.01, 1.6), doneAction: 2);
            sound = Saw.ar(55, 0.18) + SinOsc.ar(55, 0, 0.15);
            sound = LPF.ar(sound, 300) * env;
            sound ! 2
        }.play;
    };

    ~playTone = { |freq = 440|
        { var env, sound;
            env   = EnvGen.kr(Env.perc(0.01, 1.2), doneAction: 2);
            sound = Pulse.ar(freq, 0.45, 0.12) + SinOsc.ar(freq * 2, 0, 0.04);
            sound = LPF.ar(sound, 1800) * env;
            sound ! 2
        }.play;
    };

    ~playPad = {
        { var env, sound;
            env   = EnvGen.kr(Env.linen(0.5, 4, 2), doneAction: 2);
            sound = Saw.ar(220, 0.06) + Saw.ar(330, 0.05) + SinOsc.ar(440, 0, 0.04);
            sound = LPF.ar(sound, 1200) * env;
            FreeVerb.ar(sound ! 2, 0.4, 0.8, 0.3)
        }.play;
    };

    ~playSparkle = {
        { var env, sound;
            env   = EnvGen.kr(Env.perc(0.01, 2.5), doneAction: 2);
            sound = (SinOsc.ar(1200, 0, 0.05) + SinOsc.ar(1800, 0, 0.03)) * env;
            FreeVerb.ar(sound ! 2, 0.5, 0.9, 0.5)
        }.play;
    };

    ~playNoise = {
        { var env, sound;
            env   = EnvGen.kr(Env.perc(0.02, 3), doneAction: 2);
            sound = PinkNoise.ar(0.12);
            sound = BPF.ar(sound, XLine.kr(300, 3000, 2), 0.2) * env;
            FreeVerb.ar(sound ! 2, 0.35, 0.8, 0.4)
        }.play;
    };

    ~playSubDrop = {
        { var env, freq, sound;
            env   = EnvGen.kr(Env.perc(0.01, 3), doneAction: 2);
            freq  = XLine.kr(60, 28, 2.5);
            sound = SinOsc.ar(freq, 0, 0.35) * env;
            sound ! 2
        }.play;
    };


    // ====================================================================
    //  SET 2 — ALT-J  SynthDefs  (\alt...)
    // ====================================================================

    SynthDef(\altPluck, { |freq=220, amp=0.3, pan=0, decay=2.5, coef=0.2, out=0, rvb=0|
        var exc, sig;
        exc = WhiteNoise.ar(0.5) * EnvGen.kr(Env.perc(0.001, 0.05));
        sig = Pluck.ar(exc, Impulse.kr(0), 0.05, freq.reciprocal, decay, coef);
        sig = LPF.ar(sig, 4500);
        sig = sig * EnvGen.kr(Env.linen(0.001, decay, 0.5, 1), doneAction: 2);
        sig = Pan2.ar(sig * amp, pan);
        Out.ar(out, sig * 0.7); Out.ar(rvb, sig * 0.4);
    }).add;

    SynthDef(\altBell, { |freq=440, amp=0.3, pan=0, decay=3, out=0, rvb=0|
        var idx, sig, env;
        idx = LFNoise1.kr(0.5).range(2, 5) * EnvGen.kr(Env.perc(0.001, decay));
        sig = PMOsc.ar(freq, freq * 2.01, idx);
        env = EnvGen.kr(Env.perc(0.001, decay, amp, -4), doneAction: 2);
        sig = Pan2.ar(sig * env, pan);
        Out.ar(out, sig * 0.5); Out.ar(rvb, sig * 0.5);
    }).add;

    SynthDef(\altChoir, { |freq=220, amp=0.2, pan=0, dur=6, out=0, rvb=0|
        var vib, src, vowel, sig, env;
        vib   = SinOsc.kr(LFNoise1.kr(0.3).range(3, 5), 0, freq * 0.01);
        src   = Mix(Saw.ar((freq * [1, 1.005, 0.995]) + vib));
        vowel = BPF.ar(src, [700, 1220, 2600], 0.12).sum;
        sig   = (vowel * 0.4) + (src * 0.1);
        env   = EnvGen.kr(Env.linen(dur * 0.4, dur * 0.2, dur * 0.4, amp), doneAction: 2);
        sig   = LPF.ar(sig, 3500) * env;
        sig   = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.7); Out.ar(rvb, sig * 0.6);
    }).add;

    SynthDef(\altBass, { |freq=55, amp=0.5, decay=1.5, out=0|
        var sig;
        sig = SinOsc.ar(freq) + (SinOsc.ar(freq * 2) * 0.2);
        sig = (sig * 1.5).tanh;
        sig = LPF.ar(sig, 300);
        sig = sig * EnvGen.kr(Env.perc(0.01, decay, amp, -3), doneAction: 2);
        Out.ar(out, (sig ! 2) * 0.6);
    }).add;

    SynthDef(\altDrone, { |freq=110, amp=0.06, bright=800, out=0, rvb=0|
        var sig;
        sig = Mix(Saw.ar(freq * [0.99, 1.0, 1.005, 1.012])) * 0.25;
        sig = sig + (SinOsc.ar(freq * 0.5) * 0.3);
        sig = LPF.ar(sig, bright + LFNoise1.kr(0.1).range(-200, 400));
        sig = sig * Lag.kr(amp, 2);
        sig = Pan2.ar(sig, LFNoise1.kr(0.1));
        Out.ar(out, sig * 0.5); Out.ar(rvb, sig * 0.5);
    }).add;

    SynthDef(\altSitar, { |freq=330, amp=0.3, pan=0, decay=3, bend=0, out=0, rvb=0|
        var bendEnv = EnvGen.kr(Env([(bend.neg).midiratio, 1], [0.12], \sin));
        var f = freq * bendEnv;
        var pluckEnv = EnvGen.kr(Env.perc(0.002, 0.6));
        var harm = Blip.ar(f, 18) * pluckEnv;
        var ring = CombL.ar(harm, 0.05, f.reciprocal.clip(0.0002, 0.05), decay);
        var body = (harm * 0.5) + ring;
        var buzz = (body * 2.5).tanh;
        var symp = Ringz.ar(buzz * 0.04, freq * [2, 3.01, 4.02], decay * 0.4).sum;
        var sig  = LPF.ar(buzz + symp, 6500);
        sig = sig * EnvGen.kr(Env.linen(0.002, decay, 0.5, 1), doneAction: 2) * amp;
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.5); Out.ar(rvb, sig * 0.5);
    }).add;

    SynthDef(\altTabla, { |freq=220, amp=0.5, pan=0, decay=0.4, bend=0, out=0, rvb=0|
        var f     = freq * EnvGen.kr(Env([1 + bend, 1], [0.08], \exp));
        var click = LPF.ar(WhiteNoise.ar(1), 4000) * EnvGen.kr(Env.perc(0.0005, 0.015));
        var body  = SinOsc.ar(f) + (SinOsc.ar(f * 2.4) * 0.4) + (SinOsc.ar(f * 3.8) * 0.2);
        var ring  = Ringz.ar(click, f, decay);
        var sig   = (body * EnvGen.kr(Env.perc(0.001, decay, 1, -4))) + (ring * 0.5) + (click * 0.6);
        sig = sig * EnvGen.kr(Env.linen(0.0005, decay, 0.05), doneAction: 2) * amp;
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.5); Out.ar(rvb, sig * 0.3);
    }).add;

    SynthDef(\altHorn, { |freq=220, amp=0.3, pan=0, dur=4, out=0, rvb=0|
        var env    = EnvGen.kr(Env([0, amp, amp, 0], [dur*0.5, dur*0.2, dur*0.3], [3, 0, -3]), doneAction: 2);
        var bright = EnvGen.kr(Env([0, 1, 0.6], [dur*0.5, dur*0.5]));
        var sig    = Mix(VarSaw.ar(freq * [1, 1.003], 0, LFNoise1.kr(0.5).range(0.3, 0.7)));
        sig = sig + (Pulse.ar(freq * 0.5, 0.4) * 0.3);
        sig = MoogFF.ar(sig, (freq * 3) + (bright * 2500), 2);
        sig = (sig * 1.5).tanh * env;
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.4); Out.ar(rvb, sig * 0.5);
    }).add;

    SynthDef(\altTanpura, { |freq=110, amp=0.0, rate=2.2, out=0, rvb=0|
        var trig = Impulse.kr(rate);
        var f    = freq * Demand.kr(trig, 0, Dseq([1.5, 1, 1, 2], inf));
        var exc  = PinkNoise.ar(0.4) * EnvGen.kr(Env.perc(0.005, (rate.reciprocal) * 1.6), trig);
        var str  = Pluck.ar(exc, trig, 0.05, f.reciprocal.clip(0.0002, 0.05), 2.5, 0.4);
        var buzz = (str * 2).tanh + str;
        var symp = Ringz.ar(buzz * 0.03, freq * [2, 3, 4], 1.2).sum;
        var sig  = LPF.ar(buzz + symp, 4000) * Lag.kr(amp, 3);
        sig = Pan2.ar(sig, 0);
        Out.ar(out, sig * 0.5); Out.ar(rvb, sig * 0.6);
    }).add;


    // ====================================================================
    //  SET 3 — INDIE  SynthDefs  (\ind...)
    // ====================================================================

    SynthDef(\indJangle, { |freq=330, amp=0.3, pan=0, decay=1.5, out=0, rvb=0|
        var sig = Mix(Pulse.ar(freq * [1, 2.001], [0.3, 0.5], [0.6, 0.3]));
        sig = sig + Mix(Saw.ar(freq * [1.002, 0.998], 0.3));
        sig = LPF.ar(sig, 4500);
        sig = sig + DelayC.ar(sig, 0.03, SinOsc.kr(0.6, 0, 0.004, 0.012));
        sig = sig * EnvGen.kr(Env.perc(0.005, decay, 1, -3), doneAction: 2) * amp;
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.4); Out.ar(rvb, sig * 0.4);
    }).add;

    SynthDef(\indMute, { |freq=165, amp=0.4, pan=0, decay=0.18, out=0, rvb=0|
        var pick = HPF.ar(WhiteNoise.ar(1), 2000) * EnvGen.kr(Env.perc(0.001, 0.01));
        var sig  = Mix(Saw.ar(freq * [1, 1.005])) + pick;
        sig = LPF.ar(sig, 1800);
        sig = sig * EnvGen.kr(Env.perc(0.002, decay, 1, -6), doneAction: 2) * amp;
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.5); Out.ar(rvb, sig * 0.15);
    }).add;

    SynthDef(\indAcoustic, { |freq=220, amp=0.35, pan=0, decay=3, out=0, rvb=0|
        var trig = Impulse.kr(0);
        var exc  = PinkNoise.ar(0.7) * EnvGen.kr(Env.perc(0.001, 0.04));
        var sig  = Mix([1, 1.25, 1.5].collect({ |r, i|
            DelayN.ar(Pluck.ar(exc, trig, 0.05, (freq * r).reciprocal, decay, 0.3), 0.1, i * 0.025)
        }));
        sig = LPF.ar(sig, 5000);
        sig = sig * EnvGen.kr(Env.linen(0.001, decay, 0.5), doneAction: 2) * amp;
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.4); Out.ar(rvb, sig * 0.4);
    }).add;

    SynthDef(\indSurf, { |freq=330, amp=0.3, pan=0, decay=2, trem=6, out=0, rvb=0|
        var sig = LPF.ar(Mix(Saw.ar(freq * [1, 1.004])), 3000);
        sig = sig * SinOsc.kr(trem, 0, 0.4, 0.6);
        sig = sig * EnvGen.kr(Env.perc(0.01, decay, 1, -3), doneAction: 2) * amp;
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.4); Out.ar(rvb, sig * 0.6);
    }).add;

    SynthDef(\indEPiano, { |freq=220, amp=0.4, pan=0, decay=2.5, out=0, rvb=0|
        var tine = SinOsc.ar(freq * 4) * EnvGen.kr(Env.perc(0.001, 0.4)) * 0.3;
        var body = SinOsc.ar(freq) + (SinOsc.ar(freq * 2) * 0.2);
        var sig  = body + PMOsc.ar(freq, freq * 2, tine * 3);
        sig = LPF.ar(sig, 4000);
        sig = sig * EnvGen.kr(Env.perc(0.005, decay, 1, -4), doneAction: 2) * amp;
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.4); Out.ar(rvb, sig * 0.3);
    }).add;

    SynthDef(\indOrgan, { |freq=220, amp=0.3, pan=0, dur=1.5, out=0, rvb=0|
        var vib = SinOsc.kr(5.5, 0, 0.006, 1);
        var sig = Mix(SinOsc.ar(freq * [1, 2, 3, 4] * vib, 0, [1, 0.6, 0.4, 0.25]));
        sig = (sig * 0.6).tanh;
        sig = sig * EnvGen.kr(Env.linen(0.02, dur, 0.1, amp), doneAction: 2);
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.35); Out.ar(rvb, sig * 0.3);
    }).add;

    SynthDef(\indPad, { |freq=220, amp=0.25, pan=0, dur=6, out=0, rvb=0|
        var sig = Mix(Saw.ar(freq * [0.99, 1, 1.007, 1.012]));
        sig = LPF.ar(sig, SinOsc.kr(0.1).range(700, 2500));
        sig = sig * EnvGen.kr(Env.linen(dur * 0.4, dur * 0.3, dur * 0.4, amp), doneAction: 2);
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.3); Out.ar(rvb, sig * 0.5);
    }).add;

    SynthDef(\indArp, { |freq=440, amp=0.3, pan=0, decay=0.4, out=0, rvb=0|
        var fenv = EnvGen.kr(Env.perc(0.001, decay));
        var sig  = RLPF.ar(Mix(Saw.ar(freq * [1, 1.005])), (freq * 2) + (fenv * 3000), 0.4);
        sig = sig * EnvGen.kr(Env.perc(0.003, decay, 1, -4), doneAction: 2) * amp;
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.4); Out.ar(rvb, sig * 0.3);
    }).add;

    SynthDef(\indGlock, { |freq=880, amp=0.3, pan=0, decay=1.5, out=0, rvb=0|
        var sig = SinOsc.ar(freq) + (SinOsc.ar(freq * 5.4) * 0.4) + (SinOsc.ar(freq * 8.9) * 0.2);
        sig = sig * EnvGen.kr(Env.perc(0.001, decay, amp, -6), doneAction: 2);
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.3); Out.ar(rvb, sig * 0.5);
    }).add;

    SynthDef(\indMello, { |freq=220, amp=0.3, pan=0, dur=4, out=0, rvb=0|
        var wob = SinOsc.kr(LFNoise1.kr(0.3).range(4, 6), 0, 0.004, 1);
        var sig = LPF.ar(Mix(Saw.ar(freq * [1, 1.003, 0.997] * wob)), 2600);
        sig = sig * LFNoise2.kr(8).range(0.85, 1);
        sig = sig * EnvGen.kr(Env.linen(0.15, dur, 0.4, amp), doneAction: 2);
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.35); Out.ar(rvb, sig * 0.5);
    }).add;

    SynthDef(\indBass, { |freq=82, amp=0.5, pan=0, decay=0.8, out=0, rvb=0|
        var sig = Saw.ar(freq) + (SinOsc.ar(freq) * 0.6);
        sig = LPF.ar(sig, (freq * 6) + 200);
        sig = sig * EnvGen.kr(Env.perc(0.005, decay, 1, -3), doneAction: 2) * amp;
        Out.ar(out, (sig ! 2) * 0.5);
    }).add;

    SynthDef(\indSynBass, { |freq=55, amp=0.5, pan=0, decay=0.6, out=0, rvb=0|
        var fenv = EnvGen.kr(Env.perc(0.001, decay * 0.6));
        var sig  = MoogFF.ar(Mix(Saw.ar(freq * [1, 1.003])), (freq * 2) + (fenv * 1500), 2.5);
        sig = (sig * 1.3).tanh;
        sig = sig * EnvGen.kr(Env.perc(0.005, decay, 1, -3), doneAction: 2) * amp;
        Out.ar(out, (sig ! 2) * 0.5);
    }).add;

    SynthDef(\indKick, { |amp=0.6, pan=0, tune=55, out=0, rvb=0|
        var fenv  = EnvGen.kr(Env([tune * 3, tune], [0.06], \exp));
        var click = LPF.ar(WhiteNoise.ar(1), 3000) * EnvGen.kr(Env.perc(0.0005, 0.01)) * 0.3;
        var sig   = (SinOsc.ar(fenv) + click) * EnvGen.kr(Env.perc(0.001, 0.35, 1, -5), doneAction: 2) * amp;
        sig = (sig * 1.3).tanh;
        Out.ar(out, (sig ! 2) * 0.6);
    }).add;

    SynthDef(\indSnare, { |amp=0.5, pan=0, tune=220, decay=0.22, out=0, rvb=0|
        var nenv = EnvGen.kr(Env.perc(0.001, decay, 1, -3));
        var tenv = EnvGen.kr(Env.perc(0.001, 0.1, 1, -4));
        var sig  = (HPF.ar(WhiteNoise.ar(1), 1500) * nenv) + ((SinOsc.ar(tune) + SinOsc.ar(tune * 1.59)) * tenv * 0.5);
        sig = sig * amp * EnvGen.kr(Env.linen(0.0005, decay, 0.06), doneAction: 2);
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.5); Out.ar(rvb, sig * 0.45);
    }).add;

    SynthDef(\indHat, { |amp=0.3, pan=0, decay=0.06, out=0, rvb=0|
        var sig = HPF.ar(WhiteNoise.ar(1), 7000);
        sig = sig * EnvGen.kr(Env.perc(0.001, decay, 1, -8), doneAction: 2) * amp;
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.4); Out.ar(rvb, sig * 0.1);
    }).add;

    SynthDef(\indTom, { |amp=0.5, pan=0, tune=160, decay=0.4, out=0, rvb=0|
        var fenv = EnvGen.kr(Env([tune * 1.5, tune], [0.08], \exp));
        var sig  = SinOsc.ar(fenv) + (PinkNoise.ar(0.2) * EnvGen.kr(Env.perc(0.001, 0.02)));
        sig = sig * EnvGen.kr(Env.perc(0.001, decay, 1, -4), doneAction: 2) * amp;
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.5); Out.ar(rvb, sig * 0.3);
    }).add;

    SynthDef(\indShaker, { |amp=0.3, pan=0, decay=0.12, out=0, rvb=0|
        var sig = BPF.ar(WhiteNoise.ar(1), 6000, 0.6);
        sig = sig * EnvGen.kr(Env([0, 1, 0.2, 0], [0.01, 0.02, decay]), doneAction: 2) * amp * 3;
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.4); Out.ar(rvb, sig * 0.15);
    }).add;

    SynthDef(\indClap, { |amp=0.4, pan=0, out=0, rvb=0|
        var env = EnvGen.kr(Env([0, 1, 0.3, 1, 0.2, 1, 0], [0.005, 0.01, 0.005, 0.01, 0.005, 0.08]), doneAction: 2);
        var sig = BPF.ar(WhiteNoise.ar(1), 1400, 0.7) * env * amp * 2;
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.4); Out.ar(rvb, sig * 0.4);
    }).add;

    SynthDef(\indWhistle, { |freq=660, amp=0.25, pan=0, dur=1, out=0, rvb=0|
        var vib = SinOsc.kr(5, 0, freq * 0.01);
        var sig = SinOsc.ar(freq + vib) + (SinOsc.ar((freq + vib) * 2) * 0.05);
        sig = sig + (HPF.ar(WhiteNoise.ar(1), 3000) * 0.02);
        sig = sig * EnvGen.kr(Env.linen(0.06, dur, 0.2, amp), doneAction: 2);
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.4); Out.ar(rvb, sig * 0.4);
    }).add;

    SynthDef(\indWash, { |freq=220, amp=0.25, pan=0, dur=8, out=0, rvb=0|
        var sig = Mix(Saw.ar(freq * [1, 1.01, 0.99, 2.003])) + (PinkNoise.ar(0.5) * 0.3);
        sig = BPF.ar(sig, SinOsc.kr(0.07).range(500, 3000), 0.5);
        sig = sig * EnvGen.kr(Env.linen(dur * 0.45, dur * 0.1, dur * 0.45, amp), doneAction: 2);
        sig = sig + (CombC.ar(sig, 0.3, 0.25, 3) * 0.3);
        sig = Pan2.ar(sig, pan);
        Out.ar(out, sig * 0.3); Out.ar(rvb, sig * 0.6);
    }).add;

    SynthDef(\indCrackle, { |amp=0.0, out=0|
        var sig = (Dust2.ar(180) * 0.5) + (Dust2.ar(30) * 1.0) + HPF.ar(PinkNoise.ar(0.06), 1500);
        sig = sig * Lag.kr(amp, 2);
        Out.ar(out, sig ! 2 * 0.5);
    }).add;


    // ====================================================================
    //  SHARED REVERB + MASTER LIMITER  (one pair for everything)
    // ====================================================================
    SynthDef(\fxVerb, { |in=0, out=0, mix=0.5, room=0.9, damp=0.4|
        var sig = In.ar(in, 2);
        sig = FreeVerb2.ar(sig[0], sig[1], 1.0, room, damp);
        Out.ar(out, sig * mix);
    }).add;

    SynthDef(\fxMaster, { |in=0, out=0, amp=1|
        Out.ar(out, Limiter.ar(In.ar(in, 2), 0.95, 0.01) * amp);
    }).add;

    s.sync;   // wait until every SynthDef is on the server


    // ---- start the always-on infrastructure & beds ---------------------
    Synth(\fxVerb,   [\in, ~rbus, \out, ~mbus, \mix, 0.5, \room, 0.9, \damp, 0.4], ~fxGrp);
    Synth(\fxMaster, [\in, ~mbus, \out, 0, \amp, 1], ~mstGrp);

    ~drone   = Synth(\altDrone,   [\freq, ~altjNotes[0], \amp, 0, \out, ~mbus, \rvb, ~rbus], ~srcGrp);
    ~tanpura = Synth(\altTanpura, [\freq, ~altjNotes[0], \amp, 0,    \out, ~mbus, \rvb, ~rbus], ~srcGrp);
    ~crackle = Synth(\indCrackle, [\amp, 0, \out, ~mbus], ~srcGrp);


    // ====================================================================
    //  OSC HANDLERS  ("doorbells")
    //  Every handler key is prefixed (tun_/altj_/ind_) so none overwrite
    //  each other. The ADDRESSES are what Python sends to.
    // ====================================================================

    // ---- SET 1: TUNES  (bare addresses, straight to speakers) ----------
    OSCdef(\tun_kick,    {         ~playKick.();      }, "/kick");
    OSCdef(\tun_bass,    {         ~playBass.();      }, "/bass");
    OSCdef(\tun_tone,    { |msg|   ~playTone.(msg[1] ? 440); }, "/tone");
    OSCdef(\tun_pad,     {         ~playPad.();       }, "/pad");
    OSCdef(\tun_sparkle, {         ~playSparkle.();   }, "/sparkle");
    OSCdef(\tun_noise,   {         ~playNoise.();     }, "/noise");
    OSCdef(\tun_subdrop, {         ~playSubDrop.();   }, "/subdrop");

    // ---- SET 2: ALT-J  ( [value, intensity, pan] ) ---------------------
    OSCdef(\altj_pluck, { |msg|
        var val = msg[1], inten = (msg[2] ? 0.6), pan = (msg[3] ? 0);
        Synth(\altPluck, [\freq, ~pickAltj.(val) * [0.999, 1.001].choose,
            \amp, inten.linlin(0, 1, 0.05, 0.4), \decay, inten.linlin(0, 1, 1.5, 4),
            \pan, pan, \out, ~mbus, \rvb, ~rbus], ~srcGrp);
    }, '/altj/pluck');

    OSCdef(\altj_bell, { |msg|
        var val = msg[1], inten = (msg[2] ? 0.6), pan = (msg[3] ? 0);
        Synth(\altBell, [\freq, ~pickAltj.(val) * 2,
            \amp, inten.linlin(0, 1, 0.04, 0.32), \decay, inten.linlin(0, 1, 2, 5),
            \pan, pan, \out, ~mbus, \rvb, ~rbus], ~srcGrp);
    }, '/altj/bell');

    OSCdef(\altj_choir, { |msg|
        var val = msg[1], inten = (msg[2] ? 0.5), pan = (msg[3] ? 0);
        Synth(\altChoir, [\freq, ~pickAltj.(val),
            \amp, inten.linlin(0, 1, 0.06, 0.28), \dur, inten.linlin(0, 1, 4, 9),
            \pan, pan, \out, ~mbus, \rvb, ~rbus], ~srcGrp);
    }, '/altj/choir');

    OSCdef(\altj_bass, { |msg|
        var val = msg[1], inten = (msg[2] ? 0.6);
        Synth(\altBass, [\freq, ~pickAltj.(val * 0.4),
            \amp, inten.linlin(0, 1, 0.2, 0.6), \decay, inten.linlin(0, 1, 1, 2.5),
            \out, ~mbus], ~srcGrp);
    }, '/altj/bass');

    OSCdef(\altj_drone, { |msg|      // room-energy bed level (0 = quiet)
        var inten = (msg[1] ? 0.1);
        ~drone.set(\amp, inten.linlin(0, 1, 0.04, 0.22), \bright, inten.linlin(0, 1, 500, 2200));
    }, '/altj/drone');

    OSCdef(\altj_sitar, { |msg|      // 4th arg = bend (semitones)
        var val = msg[1], inten = (msg[2] ? 0.6), pan = (msg[3] ? 0), bend = (msg[4] ? 0);
        Synth(\altSitar, [\freq, ~pickAltj.(val) * 2,
            \amp, inten.linlin(0, 1, 0.05, 0.4), \decay, inten.linlin(0, 1, 2, 4.5),
            \bend, bend, \pan, pan, \out, ~mbus, \rvb, ~rbus], ~srcGrp);
    }, '/altj/sitar');

    OSCdef(\altj_tabla, { |msg|      // 4th arg = bend (semitones)
        var val = msg[1], inten = (msg[2] ? 0.6), pan = (msg[3] ? 0), bend = (msg[4] ? 0);
        Synth(\altTabla, [\freq, ~pickAltj.(val * 0.5),
            \amp, inten.linlin(0, 1, 0.15, 0.6), \decay, inten.linlin(0, 1, 0.25, 0.6),
            \bend, bend, \pan, pan, \out, ~mbus, \rvb, ~rbus], ~srcGrp);
    }, '/altj/tabla');

    OSCdef(\altj_horn, { |msg|
        var val = msg[1], inten = (msg[2] ? 0.6), pan = (msg[3] ? 0);
        Synth(\altHorn, [\freq, ~pickAltj.(val),
            \amp, inten.linlin(0, 1, 0.1, 0.35), \dur, inten.linlin(0, 1, 3, 6),
            \pan, pan, \out, ~mbus, \rvb, ~rbus], ~srcGrp);
    }, '/altj/horn');

    OSCdef(\altj_tanpura, { |msg|    // continuous drone level (0 = off)
        var inten = (msg[1] ? 0.12);
        ~tanpura.set(\amp, inten.linlin(0, 1, 0.05, 0.3));
    }, '/altj/tanpura');

    // ---- SET 3: INDIE  ( [value, intensity, pan] ) ---------------------
    // Helper for the melodic voices (they all share the same shape).
    ~indVoice = { |name, synth, octave = 1|
        OSCdef(("ind_" ++ name).asSymbol, { |msg|
            var val = msg[1], inten = (msg[2] ? 0.6), pan = (msg[3] ? 0);
            Synth(synth, [\freq, ~pickIndie.(val) * octave,
                \amp, inten.linlin(0, 1, 0.05, 0.45),
                \pan, pan, \out, ~mbus, \rvb, ~rbus], ~srcGrp);
        }, ("/ind/" ++ name).asSymbol);
    };

    ~indVoice.("jangle",   \indJangle,   1);
    ~indVoice.("mute",     \indMute,     0.5);
    ~indVoice.("acoustic", \indAcoustic, 1);
    ~indVoice.("surf",     \indSurf,     1);
    ~indVoice.("epiano",   \indEPiano,   1);
    ~indVoice.("organ",    \indOrgan,    1);
    ~indVoice.("pad",      \indPad,      0.5);
    ~indVoice.("arp",      \indArp,      2);
    ~indVoice.("glock",    \indGlock,    2);
    ~indVoice.("mello",    \indMello,    0.5);
    ~indVoice.("bass",     \indBass,     0.25);
    ~indVoice.("synbass",  \indSynBass,  0.25);
    ~indVoice.("whistle",  \indWhistle,  2);
    ~indVoice.("wash",     \indWash,     0.5);

    // indie drums: 1st number TUNES the drum (hat/shaker/clap ignore it)
    OSCdef(\ind_kick, { |msg|
        Synth(\indKick, [\tune, (msg[1] ? 0.3).linexp(0, 1, 40, 75),
            \amp, (msg[2] ? 0.7).linlin(0, 1, 0.3, 0.9), \pan, (msg[3] ? 0), \out, ~mbus], ~srcGrp);
    }, '/ind/kick');

    OSCdef(\ind_snare, { |msg|
        Synth(\indSnare, [\tune, (msg[1] ? 0.4).linexp(0, 1, 170, 260),
            \amp, (msg[2] ? 0.6).linlin(0, 1, 0.2, 0.7), \pan, (msg[3] ? 0), \out, ~mbus, \rvb, ~rbus], ~srcGrp);
    }, '/ind/snare');

    OSCdef(\ind_tom, { |msg|
        Synth(\indTom, [\tune, (msg[1] ? 0.4).linexp(0, 1, 90, 240),
            \amp, (msg[2] ? 0.6).linlin(0, 1, 0.2, 0.7), \pan, (msg[3] ? 0), \out, ~mbus, \rvb, ~rbus], ~srcGrp);
    }, '/ind/tom');

    OSCdef(\ind_hat, { |msg|
        Synth(\indHat, [\amp, (msg[2] ? 0.5).linlin(0, 1, 0.1, 0.4), \pan, (msg[3] ? 0), \out, ~mbus, \rvb, ~rbus], ~srcGrp);
    }, '/ind/hat');

    OSCdef(\ind_shaker, { |msg|
        Synth(\indShaker, [\amp, (msg[2] ? 0.5).linlin(0, 1, 0.1, 0.4), \pan, (msg[3] ? 0), \out, ~mbus, \rvb, ~rbus], ~srcGrp);
    }, '/ind/shaker');

    OSCdef(\ind_clap, { |msg|
        Synth(\indClap, [\amp, (msg[2] ? 0.6).linlin(0, 1, 0.2, 0.5), \pan, (msg[3] ? 0), \out, ~mbus, \rvb, ~rbus], ~srcGrp);
    }, '/ind/clap');

    OSCdef(\ind_crackle, { |msg|     // vinyl-crackle bed level (0 = off)
        ~crackle.set(\amp, (msg[1] ? 0.1).linlin(0, 1, 0.05, 0.4));
    }, '/ind/crackle');


    // ---- confirmation: if you see this, EVERYTHING is loaded -----------
    s.sync;
    "".postln;
    "=== READY ===".postln;
    ("Loaded: 7 tunes + 9 alt-J voices + 21 indie voices").postln;
    ("Listening for OSC on port " ++ NetAddr.langPort ++ " (send from Python here).").postln;
    ("Handlers registered: " ++ OSCdef.all.size).postln;
});
)
// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// <<<  END OF ENGINE BLOCK.
// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


/* ============================================================================
   STEP 2 — LOCAL TEST TRIGGERS  (engine running? select ONE line, Cmd+Enter)
   ============================================================================

// --- TUNES (no arguments needed) ---
NetAddr.localAddr.sendMsg("/kick");
NetAddr.localAddr.sendMsg("/bass");
NetAddr.localAddr.sendMsg("/tone", 440);
NetAddr.localAddr.sendMsg("/pad");
NetAddr.localAddr.sendMsg("/sparkle");
NetAddr.localAddr.sendMsg("/noise");
NetAddr.localAddr.sendMsg("/subdrop");

// --- ALT-J  ( value 0..1, intensity 0..1, pan -1..1 ) ---
NetAddr.localAddr.sendMsg("/altj/pluck", 0.3, 0.7, -0.4);
NetAddr.localAddr.sendMsg("/altj/bell",  0.8, 0.6,  0.4);
NetAddr.localAddr.sendMsg("/altj/choir", 0.5, 0.5,  0.0);
NetAddr.localAddr.sendMsg("/altj/bass",  0.2, 0.8);
NetAddr.localAddr.sendMsg("/altj/sitar", 0.6, 0.7,  0.0, 2);   // 4th = bend
NetAddr.localAddr.sendMsg("/altj/tabla", 0.3, 0.8, -0.2, 4);
NetAddr.localAddr.sendMsg("/altj/horn",  0.4, 0.8,  0.0);
NetAddr.localAddr.sendMsg("/altj/drone", 0.6);                 // bed (0 = quiet)
NetAddr.localAddr.sendMsg("/altj/tanpura", 0.5);               // bed (0 = off)

// --- INDIE  ( value 0..1, intensity 0..1, pan -1..1 ) ---
NetAddr.localAddr.sendMsg("/ind/jangle",   0.5, 0.7,  0.0);
NetAddr.localAddr.sendMsg("/ind/epiano",   0.5, 0.6,  0.0);
NetAddr.localAddr.sendMsg("/ind/glock",    0.6, 0.6,  0.2);
NetAddr.localAddr.sendMsg("/ind/arp",      0.7, 0.6,  0.3);
NetAddr.localAddr.sendMsg("/ind/pad",      0.4, 0.5,  0.0);
NetAddr.localAddr.sendMsg("/ind/kick",     0.3, 0.9);          // 1st num tunes drum
NetAddr.localAddr.sendMsg("/ind/snare",    0.4, 0.7);
NetAddr.localAddr.sendMsg("/ind/hat",      0.0, 0.6);
NetAddr.localAddr.sendMsg("/ind/crackle",  0.4);               // bed (0 = off)
// (also available: /ind/mute /ind/acoustic /ind/surf /ind/organ /ind/mello
//  /ind/bass /ind/synbass /ind/whistle /ind/wash /ind/tom /ind/shaker /ind/clap)

============================================================================ */


/* ============================================================================
   PYTHON SIDE   (pip install python-osc)
   ============================================================================
from pythonosc.udp_client import SimpleUDPClient
client = SimpleUDPClient("127.0.0.1", 57120)

# TUNES — no args needed:
client.send_message("/kick", [])
client.send_message("/tone", [440])

# ALT-J and INDIE voices — [value, intensity, pan]:
client.send_message("/altj/pluck", [0.3, 0.7, -0.4])
client.send_message("/ind/glock",  [0.6, 0.6,  0.2])

# drums on the indie kit — [tune, intensity, pan]:
client.send_message("/ind/kick",   [0.3, 0.9])

# always-on beds (0 = off/quiet):
client.send_message("/altj/drone",   [0.6])
client.send_message("/altj/tanpura", [0.5])
client.send_message("/ind/crackle",  [0.4])
============================================================================ */
