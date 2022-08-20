/*
sensorSender.ck
for SH@UCIrvine, June 2, 2022 - john eagle
*/

// run this if python3 still open (debugging)
Std.system("pkill python3");
1::second => now;

// -----------------------------------------------------------------------------
// GLOBALS
// -----------------------------------------------------------------------------
1 => int running;
"d3.py" => string sensorProgram; // d2 for simulation, d3 for realz
//"d2.py" => string sensorProgram; // d2 for simulation, d3 for realz
// -----------------------------------------------------------------------------
// OSC
// -----------------------------------------------------------------------------

// local address
"127.0.0.1" => string localIP;

// ports
5000 => int OUT_PORT;
10000 => int IN_PORT;

OscOut out;
OscIn in;
OscMsg msg;

out.dest(localIP, OUT_PORT);
"/setPing" => string pingAddress;
"/shutdown" => string shutdownAddress;

IN_PORT => in.port;
in.listenAll(); // start listener

// -----------------------------------------------------------------------------
// FUNCTIONS
// -----------------------------------------------------------------------------

fun void sensorInit() {
    // turns sensor program on
    <<< "sensorSender.ck TURNING SENSOR ON" >>>;
    me.dir() + sensorProgram => string targetFile; // file in same directory
    "python3 " + targetFile + " &" => string command;
    Std.system(command);
}

fun void setPinging(int pingState) {
    // set pingState to 0 or 1, let python deal with interval
    <<< "sensorSender.ck PINGING:", pingState >>>;
    out.dest(localIP, OUT_PORT);
    out.start(pingAddress);
    pingState => out.add; // 0 or 1 for state
    out.send();
}

fun void sensorShutdown() {
    // send shutdown message so sensor program can properly shutdown
    <<< "sensorSender.ck SHUTTING DOWN SENSOR" >>>;
    out.dest(localIP, OUT_PORT);
    out.start(shutdownAddress);
    out.send();
    1::second => now;
}

fun void rebootSensor() {
    // reboot in the case of an error
    // kill python processes first
    <<< "sensorSender.ck HARD REBOOT SENSOR" >>>;
    Std.system("pkill python3");
    1::second => now;
    // now start up sensor program again
    me.dir() + "../python/" + sensorProgram => string targetFile;
    "python3 " + targetFile + " &" => string command;
    Std.system(command);
}

fun void endProgram() {
    <<< "sensorSender.ck END PROGRAM" >>>;
    // ends loop and stops program
    // shutds down sensor program
    sensorShutdown();
    0 => running;
}

fun void oscListener() {
    <<< "sensorSender.ck SENSOR CTL LISTENING ON PORT", IN_PORT >>>;
    while( true ) {
        in => now; // wait for a message
        while( in.recv(msg)) {
            // addresses coming through are either /sensorOn, /sensorOff,
            // or /distance followed by a float arg
            //<<< "sensorSender.ck", msg.address >>>;
            
            // sensor on
            if( msg.address == "/sensorInit") sensorInit();
            
            // sensor off
            if( msg.address == "/sensorShutdown") sensorShutdown();
            
            // hard reboot (emergencies only)
            if( msg.address == "/rebootSensor" ) rebootSensor();
            
            // shutdown sensor and chuck
            if( msg.address == "/endProgram") endProgram();
            
            // start pinging sensor program
            if( msg.address == "/sensorOn") setPinging(1);
            
            // stop pinging sensor program
            if( msg.address == "/sensorOff") setPinging(0);
            
            // distance data
            //if( msg.address == "/distance") <<< "sensorSender.ck", msg.getFloat(1) >>>; // uncomment this only for testing
        }
    }
}

spork ~ oscListener();

while( running ) {
    1::second => now;
}

<<< "sensorSender.ck stopping" >>>;
