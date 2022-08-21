/*
a template for live intonation pieces.
runs with python server analyzeSample.py with Allen Downey's thinkdsp modules.
it's essentially just a pitch tracker for now without further spectral processing.
--john eagle, august 2022

TO RUN: add code blocks 1-4, then run analyzeSample.py from terminal (5), serverMaster.ck from terminal on each pi (6), then run code block 7
*/

// 1. LOAD FUNCTIONS (functions.scd)


// 2. GET DURATIONS FROM PYTHON SCRIPT form_functions.py
(
var p, l, cwd, pyFile, numSections=20, duration=10, power=0.6;  // ADJUST VARS HERE FOR FORM
//var p, l, cwd, pyFile, numSections=10, duration=1, power=0.6; // for testing

cwd = PathName.new(thisProcess.nowExecutingPath).parentPath;
pyFile = cwd ++ "form_functions.py";
p = Pipe.argv(["python3", pyFile, numSections.asString, duration.asString, power.asString], "r");
~sections = p.getLine;
p.close;
~sections = ~sections.interpret;
~fills = Array.fill(~sections.size, { arg i; (i+1)/~sections.size});
~fills = ~fills.normalize(0.5, 1.0);
)



// 3. SET UP SOUND STUFF
s.quit;
(

ServerOptions.devices;
Server.default.options.inDevice_("H5"); // stereo input
//Server.default.options.inDevice_("MacBook Pro Microphone"); // mono input
//Server.default.options.outDevice_("External Headphones");
Server.default.options.outDevice_("Scarlett 2i2 USB");
Server.default.options.sampleRate_(48000);

s.waitForBoot( { // boot server
	// ADD SYNTHS TO SERVER
	s.freeAll;
	// Mic Synth for input only
	SynthDef.new( \micIn, {
		arg in1=0, in2=0, inputGain=1.0, out1=0, out2=0;
		var sig, out;
		sig = SoundIn.ar([in1, in2], inputGain);
		//sig = Mix.new(sig);
		out = Out.ar([out1, out2], sig);
	}).add;

	// sine bank synth
	SynthDef.new(\sinBank8, {
		arg iphase=0, width=0.5, pulse=0, out=0;
		var size=8, env, sig, freqs, amps, phases;

		freqs = Array.fill(size, { 440 } );
		amps = Array.fill(size, { 1/size } );
		phases = Array.fill(size, { arg i; i.mod(2pi) } );
		// amp env
		env = EnvGen.kr( Env.new(
			[0, 1.0, 1.0, 0], // levels
			[\attack.kr(0.1), \sus.kr(1.0), \release.kr(5.0)], // times
			[5, 0, -5] // curves
		), \gate.tr(0)
		);

		// signal
		sig = DynKlang.ar( `[ \freqs.kr(freqs), \amps.kr(amps), \phases.kr(phases) ] );
		// EQ
		//sig = BLowShelf.ar(sig, 100, 1.0, 3);
		//sig = BHiShelf.ar(sig, 200, rs: 0.5, db: -2);
		//sig = BHiShelf.ar(sig, 300, rs: 0.1, db: -2);
		//sig = BHiShelf.ar(sig, 400, rs: 0.1, db: -1);
		//sig = BHiShelf.ar(sig, 600, rs: 0.2, db: -3);

		sig = Pan2.ar(sig, \pan.kr(0), \amp.kr(0.1)) * env;
		Out.ar(out, sig);
	}).add;

	s.sync;
	// allocate bus and instance of mic synth and sine synth
	~micBus1 = Bus.audio(s, 1);
	~micBus2 = Bus.audio(s, 1);
	~micIn = Synth.new(\micIn, [\in1, 0, \in2, 1, \out1, ~micBus1, \out2, ~micBus2]); //stereo input
	//~micIn = Synth.new(\micIn, [\in1, 0, \in2, 0, \out1, ~micBus1, \out2, ~micBus2]); // mono input
	~micBus1.scope;
	~micBus2.scope;
	~sines1 = Synth.new(\sinBank8, [\out, 0]);
	~sines2 = Synth.new(\sinBank8, [\out, 1]);
});
)

// 4. SET UP OSC STUFF
(
/*PORTS:
to/from local host: 9998/9999
to pis: 10000 (on/off), 10001 (control messages: /freq, /gain, /distance)
*/

OSCdef.freeAll;

// set up local host
~localHost = ~localHost.free;
~localHost = ~makeHost.(port: 9998);

~hostnames = ["pione.local", "pitwo.local"];
~hostsMaster = ~makeHosts.(~hostnames, 10000); // for adding/removing synths from remote servers
~hostsParams = ~makeHosts.(~hostnames, 10001); // for setting params on remote synths

// ----------------------------------------------------------------------------
// set up pi hosts
~piHosts = [~makeHost.(hostname: "pione.local", port: 10002)]; // just one for now


OSCdef.new(
	\recvFreqs,
	// function to be evaluated upon receiving qualifying OSC message
	{
		arg msg, time, addr, port; // these are the messages passed on
		var cleaned, midpoint, l1, l2;
		[msg, time, addr, port].postln; // action to be executed
		msg.removeAt(0); // get rid of tag beginning
		["RCVD:", msg].postln;
		// clean list of strings
		cleaned = msg.select( { arg i; i.isNumber });
		// cut list in two
		midpoint = (cleaned.size/2).asInteger;
		l1 = cleaned[..(midpoint-1)];
		l2 = cleaned[midpoint..cleaned.size];
		// now we have 2 lists of [amp, freq, amp, freq...]
		// make separate lists for amp vals and freq vals\

		// L1
		~amps1 = Array.new(l1.size/2);
		~freqs1 = Array.new(l1.size/2);
		l1.do( {
			arg val, i;
			[val, i].postln;
			if( i % 2 == 0, { ~amps1.add(val) }, { ~freqs1.add(val) });
		});
		~amps1 = ~amps1.normalizeSum();
		//~amps1 = Array.fill(8, {1.0/8});

		// L2
		~amps2 = Array.new(l2.size/2);
		~freqs2 = Array.new(l2.size/2);
		l2.do( {
			arg val, i;
			[val, i].postln;
			if( i % 2 == 0, { ~amps2.add(val) }, { ~freqs2.add(val) });
		});
		~amps2 = ~amps2.normalizeSum();
		//~amps2 = Array.fill(8, {1.0/8});

		//~amps1.sum.postln;
	},
	'/freqs',
	recvPort: 9999
);
)


// 5. START PYTHON SERVER IN TERMINAL BHY_analyzeSample.py

// 6. START PI SERVERS IN TERMINAL serverMaster.ck








// 7. START UP PIs: sensorSender.ck and stdSynth.ck
(
// start up sensor programs
~sensorInit.(~hostsMaster, ~hostsParams);  // TO RESET SENSOR DO THIS AND ~pingSensors block
)

(
// start up synth programs
~stdSynthSwitch.(~hostsMaster);
);

(
// initiate synth settings and start pinging
~pingSensors.(~hostsParams);
~setSensorOffset.(~hostsParams, vals: [12.0, 4.0]);
~setSensorRange.(~hostsParams, val: 5.0);
)

(
~setStdSynth.(~hostsParams, "/stdSynthState", 0, 1); // turn on chan 1

~setStdSynth.(~hostsParams, "/synthFreq1", 0, 440.0);
~setStdSynth.(~hostsParams, "/synthFreq2", 0, 330.0);
)

// SHUT IT DOWN
(
~unpingSensors.(~hostsParams);
~stdSynthSwitch.(~hostsMaster, state: 0);
~sensorShutdown.(~hostsMaster, ~hostsParams);
)
~shutdownRemoteServer.(~hostsMaster);









// 8. START PROGRAM
(
// MAIN
var cwd, tempWav1, tempWav2, r1, r2, sampleDur=2.0, recBufTime=1.0, pingBufTime=1.0, cycleRemainder, totalFreqs=8;




// ----------------------------------------------------------------------------

cwd = PathName.new(thisProcess.nowExecutingPath).parentPath;
tempWav1 = cwd ++ "temp1.wav";
tempWav2 = cwd ++ "temp2.wav";
r1 = Recorder(s);
r1.recHeaderFormat_('wav');
r1.recSampleFormat_("int16");
r2 = Recorder(s);
r2.recHeaderFormat_('wav');
r2.recSampleFormat_("int16");
// for display
t = TempoClock.new();

// MAIN LOOP, DETERMINED BY totalCycles
x = Task{
	~sections.do{
		arg dur, i;
		var nextSection, freqs, fillPct, attack, sus, release, cycleDur, minutes, seconds;

		cycleDur = dur * 60;
		nextSection = t.beats + cycleDur;

		format("LENGTH OF SECTION: % seconds", cycleDur).postln;
		// 1. START RECORDING
		r1.record(tempWav1, ~micBus1, numChannels:1); // record for sampleDur seconds
		r2.record(tempWav2, ~micBus2, numChannels:1); // record second channel
		1.do{ format("RECORDING, TIME:\t\t\t\t % minutes, % seconds", (t.beats/60).asInteger, (t.beats%60).asInteger).postln; sampleDur.wait};
		// 2. STOP RECORDING
		r1.stopRecording;
		r2.stopRecording;
		recBufTime.do{ format("STOPPED RECORDING, TIME:\t\t % minutes, % seconds", (t.beats/60).asInteger, (t.beats%60).asInteger).postln; 1.wait};
		// 3. PING PYTHON PROGRAM FOR FREQS
		~localHost.sendMsg('/ping');
		//freqs.postln;
		pingBufTime.do{ format("GETTING SAMPLE FREQS, TIME:\t\t % minutes, % seconds", (t.beats/60).asInteger, (t.beats%60).asInteger).postln; 1.wait}; // is this necessary?
		// 4. UPDATE LOCAL SYNTH
		~sines1.set(\freqs, ~freqs1);
		~sines1.set(\amps, ~amps1);
		~sines2.set(\freqs, ~freqs2);
		~sines2.set(\amps, ~amps2);
		// calculate envelope based on length of cycle

		// calculate remaining time left in cycle
		cycleRemainder = cycleDur - sampleDur - recBufTime - pingBufTime;

		// determine envelope based on ~fills value (determined at top), value 0.5 - 1.0
		fillPct = ~fills[i];
		sus = cycleRemainder * fillPct;
		release = (cycleRemainder - sus) * 0.8;

		//if( cycleDur > 50.0, {fillPct = 0.5}, {fillPct = 0.9});
		//if( fillPct < 1.0, {release = 10.0}, {release=0.1});


		format( "sus %, release %, cycleDur %", sus, release, cycleDur).postln;
		~sines1.set(\sus, sus);
		~sines1.set(\release, release);
		~sines1.set(\gate, 1);
		~sines2.set(\sus, sus);
		~sines2.set(\release, release);
		~sines2.set(\gate, 1);

		// at this point, sampleDur (2) + recBufTime (1) + pingBufTime (1) seconds have passed

		// ----------------------------------------------------------------------------
		// NOW UPDATE PIS
		// pi 1, freqs 1 and 2
		~hostsParams[0].sendMsg('/synthFreq1', 0, ~freqs1.takeAt(rand(~freqs1.size)));
		~hostsParams[0].sendMsg('/synthFreq2', 0, ~freqs1.takeAt(rand(~freqs1.size)));
		// pi 2, freqs 1 and 2
		~hostsParams[1].sendMsg('/synthFreq1', 0, ~freqs2.takeAt(rand(~freqs2.size)));
		~hostsParams[1].sendMsg('/synthFreq2', 0, ~freqs2.takeAt(rand(~freqs2.size)));






		cycleRemainder.do{ format("TUNING TIME, TIME:\t %:% , NEXT CHANGE: %:%", (t.beats/60).asInteger, (t.beats%60).asInteger, (nextSection/60).asInteger, (nextSection%60).asInteger).postln; 1.wait};

	};
	// shutdown python server when finished
	~localHost.sendMsg('/shutdown');
	// kill synth
	~sines1.set(\gate, 0);
	~sines2.set(\gate, 0);
}.start;
)
a = [1, 2, 3, 4, 5];
c = a.choose;
b = a.takeAt(rand(a.size));
a;
// USE THIS FOR STOPPING
x.stop;
s.quit;


s.scope;
s.freqscope;

~freqs1;
~freqs2;