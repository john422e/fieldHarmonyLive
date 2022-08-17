# std imports
import sys
# osc imports
import osc4py3.as_eventloop as oscel
from osc4py3 import oscmethod as osm
from osc4py3 import oscbuildparse
# local imports
import thinkdsp
from parameters import params

# GLOBALS
fn = sys.argv[0]
running = True
localIP = "127.0.0.1"
rcvPort = 10000
sendPort = 10001
pingAddress = "/ping"
shutdownAddress = "/shutdown"
sendAddress = "/freqs"

# DEFAULTS
wavFile = "temp.wav"
totalPeaks = 8

params['total peaks'] = totalPeaks*2 # allow larger size because we'll thin them
params['high pass'] = 100
params['low pass'] = 5000

# FUNCTIONS
def shutdown():
    global running
    print(fn, "SHUTTING DOWN SAMPLE ANALYSIS SERVER")
    running = False

def analyzeSample():
    global totalPeaks
    global wavFile

    print("ANALYZING AUDIO SAMPLE")
    wave = thinkdsp.read_wave(wavFile)
    wave.apodize()
    spectrum = wave.make_spectrum()
    peaks = spectrum.peaks()

    # now filter and limit
    # get a range around each freq
    min = 1 - params['hz boundary']
    max = 1 + params['hz boundary']

    filteredPeaks = []
    while( len(filteredPeaks) < totalPeaks):
        #print("LENGTH:", len(filteredPeaks))
    # stop once length is met

        for freqTuple in peaks:
            freq = freqTuple[1] # this is the new potential freq
            #print(freq)
            # filter for high and low pass (range)

            if freq > params['high pass'] and freq < params['low pass']:
                #print("FREQ IN RANGE", freq)
                #filteredPeaks.append(freqTuple)
                if len(filteredPeaks) == 0:
                    print("FIRST FREQ")
                    filteredPeaks.append(freqTuple)
                else:
                    # now test each freq already in filteredPeaks to see if it's in this range
                    unique = True
                    for subFreqTuple in filteredPeaks:
                        checkFreq = subFreqTuple[1]
                        #print(f"checking {freq} against {checkFreq}")
                        for harm in params['clear harmonics']:
                            # eliminate freqs within range of louder freqs and their harmonics
                            if freq >= (checkFreq*harm*min) and freq <= (checkFreq*harm*max):
                            #if checkFreq >= (freq*harm*min) and checkFreq <= (freq*harm*max):
                                unique = False
                                #print("NOT UNIQUE")
                                break

                    if unique == True:
                        print(f"adding {freq} to list")
                        freqs = [round(pair[1]) for pair in filteredPeaks]
                        print(freqs)
                        filteredPeaks.append(freqTuple)


    #print(len(filteredPeaks), filteredPeaks[:totalPeaks])
    #return peaks

    # send freqs to client
    sendData(sendAddress, filteredPeaks[:totalPeaks])

def sendData(address, data):
    # FOR TESTING
    # round it
    #print("CLEANING")
    cleaned = []
    for t in data:
        #print(t)
        amp = float(round(t[0], 2))
        freq = round(t[1], 2)
        cleaned.append(amp)
        cleaned.append(freq)

    print("SENDING:", address, cleaned)
    tag = 'd' * len(cleaned)
    tag = ',' + tag
    print("TAG:", tag)

    msg = oscbuildparse.OSCMessage(address, tag, cleaned)
    oscel.osc_send(msg, "SENDER CLIENT")
    #print("SENT:", address, cleaned)

# MAIN
if __name__ == "__main__":
    # start osc
    oscel.osc_startup()
    # setup server
    oscel.osc_udp_server(localIP, rcvPort, "SAMPLE ANALYSIS SERVER")
    # assign functions
    oscel.osc_method(pingAddress, analyzeSample)
    oscel.osc_method(shutdownAddress, shutdown)

    # client setup
    oscel.osc_udp_client(localIP, sendPort, "SENDER CLIENT")

    print("SERVING ON PORT", rcvPort)
    # serve until shutdown
    while running:
        oscel.osc_process()

    print(fn, "EXITING")
    oscel.osc_terminate()
