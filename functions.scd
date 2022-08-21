// FUNCTIONS FOR BHI_main.scd
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

// start python sensor program
~sensorInit = {
	arg hostsMaster, hostsParams;
	var delayTime = 1.0;
	Task {
		// 1. add sensorSender.ck to remote server
		hostsMaster.do( {
			arg host;
			host.sendMsg( '/sensorState', 1);
		});
		// delay
		(delayTime + 1).wait; // allow extra time for sensorSender startup
		// 2. initiate sensors (to sensor program)
		hostsParams.do( {
			arg host;
			host.sendMsg( '/sensorInit');
		});
	}.start;
};

// exit python sensor program
~sensorShutdown = {
	arg hostsMaster, hostsParams;
	var delayTime = 1.0;
	Task {
		// 1. shutdown sensors (to sensor program)
		hostsParams.do( {
		arg host;
		host.sendMsg( '/sensorShutdown');
		});

		// delay
		delayTime.wait;

		// 2. remove sensorSender.ck to remote server
		hostsMaster.do( {
			arg host;
			host.sendMsg( '/sensorState', 0);
		});
	}.start;
};

// start sensors pinging
~pingSensors = {
	arg hostsParams;
	hostsParams.do( {
		arg host;
		host.sendMsg( '/sensorOn');
	});
};

// stop sensors pinging
~unpingSensors = {
	arg hostsParams;
	hostsParams.do( {
		arg host;
		host.sendMsg( '/sensorOff');
	});
};

// turn synth on/off
~stdSynthSwitch = {
	arg hostsMaster, address="/synthState", state = 1;
	hostsMaster.do( {
		arg host;
		//"------------SETTING STD SYNTH".postln;
		//state.postln;
		host.sendMsg(address, state);
	});
};

// set synth params
~setSensorOffset = {
	arg hostsParams, address="/distOffset", vals = Array.fill(hostsParams.size, 10.0);
	hostsParams.do( {
		arg host, i;
		host.sendMsg(address, vals[i]);
	});
};

~setSensorRange = {
	arg hostsParams, address="/sensorRange", val=5.0;
	hostsParams.do( {
		arg host;
		[address, val].postln;
		host.sendMsg(address, val);
	});
};

~setStdSynth = {
	arg hostsParams, address, val1=0, val2=0;
	hostsParams.do( {
		arg host;
		host.sendMsg(address, val1, val2);
	});
};

// exits remote chuck server
~shutdownRemoteServer = {
	arg hosts;
	hosts.do( {
		arg host;
		host.sendMsg( '/endProgram');
	});
};
)