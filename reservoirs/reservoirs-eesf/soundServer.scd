(
// sets and starts server and builds arrays for ~micBusses, ~micSynths, and ~sines
var numInputs=~numSources, numOutputs=~numSources;

s.quit;
o = Server.default.options;
o.numOutputBusChannels = 4;
o.numOutputBusChannels;
o.sampleRate_(48000);

// use this for testing
//o.inDevice_("BlackHole 64ch");
//o.outDevice_("BlackHole 64ch");

// use this for performance with evo 16
o.inDevice_("Audient EVO16");
o.outDevice_("Audient EVO16");

ServerOptions.devices;

~fourChannels = True; // set to True if using house l/r and stage l/r; false for just two channels

s.waitForBoot( { // boot server
	// ADD SYNTHS TO SERVER
	s.freeAll;
	// Mic Synth for input only
	SynthDef.new( \micIn, {
		arg in=0, inputGain=1.0, out=0;
		var sig;
		sig = SoundIn.ar(in, inputGain);
		out = Out.ar(out, sig);
	}).add;


	/*
	// TESTING THIS DEF
	SynthDef.new( \micOut, {
		arg in=0, inputGain=0.2, out=0; // set the gain here
		var sig;
		sig = SoundIn.ar(in, inputGain);
		out = Out.ar(out, sig);
	}).add;
	//
	*/



	SynthDef.new(\sinBank8, {
		|out, gate| // arg out=0, gate;
		var size=~numSines, env, sig, freqs, amps, phases;

		freqs = Array.fill(size, { 440 } );
		amps = Array.fill(size, { 1/size } );
		phases = Array.fill(size, { arg i; i.mod(2pi) } );
		// amp env
		env = EnvGen.kr(Env.asr( 0.5, 1.0, \release.kr(0.1) ), gate );

		// signal
		sig = DynKlang.ar( `[ \freqs.kr(freqs).lag(0.01), \amps.kr(amps), \phases.kr(phases) ] );
		sig = sig * env;
		if( ~fourChannels == True ) { ~output = [out, out+2] } { ~output = out };
		Out.ar(~output, sig);
	}).add;

	s.sync;
	// allocate bus and instance of mic synth and sine synth
	~micBusses = Array.fill(numInputs, {Bus.audio(s, 1)});
	~micSynths = Array.fill(numInputs, { arg i; Synth.new(\micIn, [\in, i, \out, ~micBusses[i]])}); // after testing change 0 to i for diff input channels
	//~micOuts = Array.fill(numOutputs, { arg i; Synth.new(\micOut, [\in, i, \out, i])}); // sends only to 1 and 2
	~sines = Array.fill(numOutputs, { arg i; Synth.new(\sinBank8, [\out, i])});
	~micBusses.do( { arg bus; bus.scope});
});
)

s.meter;
s.quit;
