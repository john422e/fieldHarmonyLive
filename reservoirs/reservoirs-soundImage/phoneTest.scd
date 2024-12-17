/*PORTS:
to/from local host: 9998/9999
to pis: 10000 (on/off), 10001 (control messages: /freq, /gain, /distance)
TO PHONES: 10002
FROM PHONES: 10003
*/
(
OSCdef.freeAll;

// set up local host
//~localHost = ~localHost.free;
//~localHost = ~makeHost.(port: 9998);

//~phoneHostnames = ["Johns-iPhone.local", "Emily.local"];
~phoneHostnames = ["127.0.0.1"];//, "Johns-iPhone.local"];
//~phoneHostnames = ["127.0.0.1", "Emily.local"]; // do this one for performance
try { ~phones = ~makeHosts.(~phoneHostnames, 10002) } { "PHONES NOT ONLINE".postln};
//~phones = ~makeHost.("Johns-iPhone.local", 10002);
//~phoneHostnames.size;
)

~phones;


// this updates the time
(
~phones.do( {
	arg phone;
	try { phone.sendMsg("/nowTime", format("%:%", (6000/60).asInteger, (6000%60).asInteger)) } { "PHONE OFFLINE".postln };
});
)


// this turns light on (when recording ON)
(
~phones.do( {
	arg phone;
	try { phone.sendMsg("/recordingLight", "1") } { "MESSAGE ERROR".postln };
});
)

// this turns light off (when recording OFF)
(
~phones.do( {
	arg phone;
	try { phone.sendMsg("/recordingLight", "0") } { "MESSAGE ERROR".postln };
});
)

// make a button to start the whole thing (save a new version of touchOSC patch)