(
/*PORTS:
to/from local host: 9998/9999
TO PHONES: 10002
FROM PHONES: 10003
*/

OSCdef.freeAll;

// set up local host
~localHost = ~localHost.free;
~localHost = ~makeHost.(port: 9998);

// set up local host
//~localHost = ~localHost.free;
//~localHost = ~makeHost.(port: 9998);

~phoneHostnames = ["Johns-iPhone.local", "Emily.local"]; // use this for performance, make sure john is channel 1 spkr/mic
//~phoneHostnames = ["Emily.local", "Johns-iPhone.local"];
//~phoneHostnames = ["127.0.0.1", "Johns-iPhone.local"]; // use this for testing
//~phoneHostnames = ["127.0.0.1", "Emily.local"]; //
try { ~phones = ~makeHosts.(~phoneHostnames, 10002) } { "PHONES NOT ONLINE".postln};
//~phones = ~makeHost.("Johns-iPhone.local", 10002);
//~phoneHostnames.size;

// ----------------------------------------------------------------------------
//OSCFunc.trace(false);
OSCdef.new(
	\recvFreqs,
	// function to be evaluated upon receiving qualifying OSC message
	{
		arg msg, time, addr, port; // these are the messages passed on
		var chan, data, numLists, cleaned, amps, freqs, rcvLists;
		//[msg, time, addr, port].postln; // action to be executed
		msg.removeAt(0); // get rid of tag beginning
		//["RCVD:", msg].postln;

		//msg.postln;

		chan = msg[0];

		msg.removeAt(0);

		//msg.postln;



		// clean list of strings
		cleaned = msg.select( { arg i; i.isNumber }); // makes one long list
		//"CLEANED".postln;
		//cleaned.postln;
		//cleaned.size.postln;

		amps = Array.new(~numSines);
		freqs = Array.new(~numSines);
		//format("NUM SINES: %", ~numSines).postln;
		cleaned.do( {
			// split out amps and freqs into separate lists
			arg val, i;
			if( i % 2 == 0, { amps.add(val) }, { freqs.add(val) });
		});
		amps = amps.normalizeSum();
		//["SUMMED", amps.sum].postln;

		//format("NUM SINES: %", ~numSines).postln;
		//format("NUM FREQS: %", freqs.size).postln;

		// add it to the master list
		//~currentData[i] = [amps, freqs];
		//["PARSED", i, amps, freqs].postln;

		~currentData[chan] = [amps, freqs];
		format("UPDATED CHAN % : % %", chan, amps, freqs).postln;


	},
	'/freqs',
	recvPort: 9999
);

// functions for sending osc messages
~updateTime = {
	~phones.do( {
		arg phone;
		try { phone.sendMsg("/nowTime", format("%:%", (t.beats/60).asInteger, (t.beats%60).asInteger)) } { "PHONE OFFLINE".postln };
	});
};
)