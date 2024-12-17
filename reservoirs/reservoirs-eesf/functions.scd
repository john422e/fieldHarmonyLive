// FUNCTIONS FOR reservoirs_main.scd
(
// MAKE SINGLE HOST
~makeHost = {
	arg hostname = "127.0.0.1", port=10000;
	var host;
	host = NetAddr.new( hostname, port);
	host;
};
// MAKE HOST ARRAY
~makeHosts = {
	arg hostnames, port=10000;
	var hosts;
	hosts = Array.fill( hostnames.size, { arg i; NetAddr.new( hostnames[i], port)});
	hosts;
};

// exits remote chuck server
~shutdownRemoteServer = {
	arg hosts;
	hosts.do( {
		arg host;
		host.sendMsg( '/endProgram');
	});
};

~getNoteAndCentsFromHz = {
	arg freq;
	var name, cents;
	name = (freq*2).cpsname; // octave off?
	cents = freq.cpsname.cents.round(0.01);
	[name, cents];
};

~updatePitchDisplay = {
	arg host, name, cents;
	host.sendMsg(\pitchClass, name);
	host.sendMsg(\cents, cents);
};
)
