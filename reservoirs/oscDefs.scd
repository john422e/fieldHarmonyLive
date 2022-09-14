
(
/*PORTS:
to/from local host: 9998/9999
to pis: 10000 (on/off), 10001 (control messages: /freq, /gain, /distance)
*/

OSCdef.freeAll;

// set up local host
~localHost = ~localHost.free;
~localHost = ~makeHost.(port: 9998);

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
)