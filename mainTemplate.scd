/*
a template for live intonation pieces.
runs with python server analyzeSampleTemplate.py with Allen Downey's thinkdsp modules.
it's essentially just a pitch tracker for now without further spectral processing.
--john eagle, august 2022

TO RUN: add code blocks 1-3, then run analyzeSampleTemplate.py from terminal, then run code block 5
*/

// 1. DEFINE FUNCTIONS
(
~makeLocalHost = {
	arg hostname = "127.0.0.1", port=10000;
	var host;
	host = NetAddr.new( hostname, port);
	host;
};
)

// 2. SET UP SOUND STUFF
(
s.waitForBoot( { // boot server
	// ADD SYNTHS TO SERVER

	// Mic Synth for input only
	SynthDef.new( \micIn, {
		arg in=0, inputGain=1.0, out=0;
		var sig;
		sig = SoundIn.ar(in, inputGain);
		out = Out.ar(out, sig);
	}).add;

	// sine bank synth
	SynthDef.new(\sinBank8, {
		arg iphase=0, width=0.5, pulse=0;
		var size=8, env, sig, freqs, amps, phases, time=0.05;
		freqs = Array.fill(size, { 440 } );
		amps = Array.fill(size, { 1/size } );
		phases = Array.fill(size, { arg i; i.mod(2pi) } );
		// amp env
		env = EnvGen.kr( Env.asr(0.01, 1.0, 0.01), \gate.kr(0));
		// signal
		sig = DynKlang.ar( `[ \freqs.kr(freqs), \amps.kr(amps), \phases.kr(phases) ] );
		// EQ
		//sig = BLowShelf.ar(sig, 100, 1.0, 3);
		//sig = BHiShelf.ar(sig, 200, rs: 0.5, db: -2);
		//sig = BHiShelf.ar(sig, 300, rs: 0.1, db: -2);
		//sig = BHiShelf.ar(sig, 400, rs: 0.1, db: -1);
		//sig = BHiShelf.ar(sig, 600, rs: 0.2, db: -3);

		sig = Pan2.ar(sig, \pan.kr(0), \amp.kr(0.1)) * env;
		Out.ar(\out.kr(0), sig);
	}).add;

	s.sync;
	// allocate bus and instance of mic synth and sine synth
	~micBus = Bus.audio(s, 1);
	~micIn = Synth.new(\micIn, [\out, ~micBus]);
	~micBus.scope;
	~sines = Synth.new(\sinBank8);
});
)

// 3. SET UP OSC STUFF
(
OSCdef.freeAll;
OSCdef.new(
	\recvFreqs,
	// function to be evaluated upon receiving qualifying OSC message
	{
		arg msg, time, addr, port; // these are the messages passed on
		var rawRcvd, amps, freqs;
		[msg, time, addr, port].postln; // action to be executed
		msg.removeAt(0);
		// make separate lists for amp vals and freq vals
		~amps = Array.new(msg.size/2);
		~freqs = Array.new(msg.size/2);
		// separate msg into the two lists
		msg.do( {
			arg val, i;
			[val, i].postln;
			if( i % 2 == 0, { ~amps.add(val) }, { ~freqs.add(val) });
		});
		~amps = ~amps.normalizeSum();

		["RECEIVED", msg.size].postln;
		~amps.postln;
		~freqs.postln;
		//~amps.sum.postln;
	},
	'/freqs',
	recvPort: 10001
);
)

~freqs;
~amps;

// 4. START PYTHON SERVER IN TERMINAL

// 5. START PROGRAM
(
// MAIN
var cwd, tempWav, sampleDur=2.0, recBufTime=1.0, pingBufTime=1.0, cycleRemainder, cycleDur=10, totalCycles=10, totalFreqs=8;


// set up local host
~localHost = ~localHost.free;
~localHost = ~makeLocalHost.();

cwd = PathName.new(thisProcess.nowExecutingPath).parentPath;
tempWav = cwd ++ "temp.wav";
r = Recorder(s);
r.recHeaderFormat_('wav');
r.recSampleFormat_("int16");

// for display
t = TempoClock.new();

// MAIN LOOP, DETERMINED BY totalCycles
Task{
	totalCycles.do{
		var freqs;
		// 1. START RECORDING
		r.record(tempWav, ~micBus, numChannels:1); // record for sampleDur seconds
		sampleDur.do{ format("RECORDING, TIME:\t\t\t\t %", t.beats).postln; 1.wait};
		// 2. STOP RECORDING
		r.stopRecording;
		recBufTime.do{ format("STOPPED RECORDING, TIME:\t\t %", t.beats).postln; 1.wait};
		// 3. PING PYTHON PROGRAM FOR FREQS
		~localHost.sendMsg('/ping');
		//freqs.postln;
		pingBufTime.do{ format("GETTING SAMPLE FREQS, TIME:\t\t %", t.beats).postln; 1.wait}; // is this necessary?
		// 4. UPDATE SYNTH
		~sines.set(\freqs, ~freqs);
		~sets.set(\amps, ~amps);
		~sines.set(\gate, 1);

		cycleRemainder = cycleDur - sampleDur - recBufTime - pingBufTime;
		cycleRemainder.do{ format("UPDATING SYNTH, TIME:\t\t\t %", t.beats).postln; 1.wait};

	};
	// shutdown python server when finished
	~localHost.sendMsg('/shutdown');
	// kill synth
	~sines.set(\gate, 0);
}.start;
)
