/*
for live fieldHarmony pieces, August 2022 - john eagle
*/

1 => int running;
"serverMaster.ck" => string fn;

me.dir() => string dir;

// OSC
OscIn in;
OscMsg msg;
9999 => int port;
port => in.port;
in.listenAll();

int sensorState;
int sensorID;

int synthState;
int synthID;

int newState;

fun void oscListener() {
    <<< fn, "LISTENING ON PORT:", port >>>;
    while( true ) {
        in => now; // wait for message
        while( in.recv(msg) ) {
            
            // SENSOR PROGRAM
            if( msg.address == "/sensorState" ) {
                msg.getInt(0) => newState; // msg is 0 or 1
                if( newState != sensorState) { // only set it and act if it's a change
                    newState => sensorState;
                    if( sensorState == 1 ) {
                        // add sensorSender.ck to server and assign it an ID
                        Machine.add(dir + "sensorSender.ck") => sensorID;
                        <<< "ADDING SENSOR SENDER", sensorID >>>;
                    }
                    if( sensorState == 0 ) {
                        // remove sensorSender.ck from server
                        Machine.remove(sensorID);
                        <<< "REMOVING SENSOR SENDER", sensorID >>>;
                    }
                }
            }
            
            // STD SYNTH
            if( msg.address == "/synthState" ) {
                msg.getInt(0) => newState; // msg is 0 or 1
                if( newState != synthState ) { // only set it and act if it's a change
                    newState => ternaryState;
                    if( ternaryState == 1 ) {
                        // add stdSynth.ck to server and assign it an ID
                        Machine.add(dir + "stdSynth.ck") => synthID;
                        <<< "ADDING STD SYNTH", synthID >>>;
                    }
                    if( ternaryState == 0 ) {
                        // remove stdSynth.ck from server
                        Machine.remove(synthID);
                        <<< "REMOVING STD SYNTH", synthID >>>;
                    }
                }
            }
            
            if( msg.address == "/endProgram" ) 0 => running;
        }
    }
}


// MAIN
spork ~ oscListener();

while( running ) {
    1::second => now;
}

<<< fn, "stopping" >>>;