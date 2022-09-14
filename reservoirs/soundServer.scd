(
// sets and starts server and builds arrays for ~micBusses, ~micSynths, and ~sines
var numInputs=~numSources, numOutputs=~numSources;

s.quit;
o = Server.default.options;
//o.numOutputBusChannels = 3;
o.numOutputBusChannels;
o.sampleRate_(48000);
//o.inDevice_("Scarlett 18i20 USB");
o.inDevice_("Scarlett 2i2 USB");
//o.inDevice_("Soundflower (2ch)");
//o.outDevice_("External Headphones");
o.outDevice_("Soundflower (2ch)");
//o.outDevice_("Scarlett 18i20 USB");


//ServerOptions.devices;
//Server.default.options.inDevice_("H5"); // stereo input
//Server.default.options.inDevice_("Scarlett 18i20 USB");
//Server.default.options.inDevice_(1);
//Server.default.options.inDevice_("MacBook Pro Microphone"); // mono input
//Server.default.options.outDevice_("External Headphones");
//Server.default.options.outDevice_("USB Audio CODEC");
//Server.default.options.outDevice_(0);
//Server.default.options.outDevice_("Soundflower (2ch)");
//Server.default.options.outDevice_("Scarlett 2i2 USB");


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

	// sine bank synth
	SynthDef.new(\sinBank8, {
		arg out=0, gate;
		var size=~numSines, env, sig, freqs, amps, phases;

		freqs = Array.fill(size, { 440 } );
		amps = Array.fill(size, { 1/size } );
		phases = Array.fill(size, { arg i; i.mod(2pi) } );
		// amp env
		env = EnvGen.kr(Env.asr( 0.01, 1.0, \release.kr(1.0) ), gate );

		// signal
		sig = DynKlang.ar( `[ \freqs.kr(freqs).lag(0.01), \amps.kr(amps), \phases.kr(phases) ] );
		sig = sig * env;
		Out.ar(out, sig);
	}).add;

	s.sync;
	// allocate bus and instance of mic synth and sine synth
	~micBusses = Array.fill(numInputs, {Bus.audio(s, 1)});
	~micSynths = Array.fill(numInputs, { arg i; Synth.new(\micIn, [\in, i, \out, ~micBusses[i]])}); // after testing change 0 to i for diff input channels

	~sines = Array.fill(numOutputs, { arg i; Synth.new(\sinBank8, [\out, i])});
	~micBusses.do( { arg bus; bus.scope});
});
)

s.meter;