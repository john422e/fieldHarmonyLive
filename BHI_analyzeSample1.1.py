# STEREO CAPABLE

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
wavFile1 = "temp1.wav"
wavFile2 = "temp2.wav"
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

    print("ANALYZING AUDIO SAMPLE 1")
    wave1 = thinkdsp.read_wave(wavFile1)
    wave1.apodize()
    spectrum1 = wave1.make_spectrum()
    peaks1 = spectrum1.peaks()
    print("ANALYZING AUDIO SAMPLE 2")
    wave2= thinkdsp.read_wave(wavFile2)
    wave2.apodize()
    spectrum2 = wave2.make_spectrum()
    peaks2 = spectrum2.peaks()

    # now filter and limit
    # get a range around each freq
    min = 1 - params['hz boundary']
    max = 1 + params['hz boundary']

    # LEFT
    filteredPeaks1 = []
    while( len(filteredPeaks1) < totalPeaks):
        #print("LENGTH:", len(filteredPeaks1))
    # stop once length is met

        for freqTuple in peaks1:
            if len(filteredPeaks1) >= totalPeaks: break
            freq = freqTuple[1] # this is the new potential freq
            #print(freq)
            # filter for high and low pass (range)

            if freq > params['high pass'] and freq < params['low pass']:
                #print("FREQ IN RANGE", freq)
                if len(filteredPeaks1) == 0:
                    print("FIRST FREQ")
                    filteredPeaks1.append(freqTuple)
                else:
                    # now test each freq already in filteredPeaks1 to see if it's in this range
                    unique = True
                    for subFreqTuple in filteredPeaks1:
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
                        freqs = [round(pair[1]) for pair in filteredPeaks1]
                        print(freqs)
                        filteredPeaks1.append(freqTuple)

    # RIGHT
    filteredPeaks2 = []
    while( len(filteredPeaks2) < totalPeaks):
        #print("LENGTH:", len(filteredPeaks2))
    # stop once length is met

        for freqTuple in peaks2:
            if len(filteredPeaks2) >= totalPeaks: break
            freq = freqTuple[1] # this is the new potential freq
            #print(freq)
            # filter for high and low pass (range)

            if freq > params['high pass'] and freq < params['low pass']:
                #print("FREQ IN RANGE", freq)
                if len(filteredPeaks2) == 0:
                    print("FIRST FREQ")
                    filteredPeaks2.append(freqTuple)
                else:
                    # now test each freq already in filteredPeaks1 to see if it's in this range
                    unique = True
                    for subFreqTuple in filteredPeaks2:
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
                        freqs = [round(pair[1]) for pair in filteredPeaks2]
                        print(freqs)
                        filteredPeaks2.append(freqTuple)


    # send freqs to client
    print("SENDING")
    sendData(sendAddress, [filteredPeaks1, filteredPeaks2])

def sendData(address, data):
    # data is 2d array [ [amps, freqs], [amps, freqs] ]
    # TAG: ,dddddddddddddddd
    #',ii[iiii]'
    # round it
    #print("CLEANING")
    cleaned = []
    for l in data:
        c = []
        # go through each list and put everything into one list of [amp, freq, amp, freq...]
        for i, t in enumerate(l):
            print(i, t)
            amp = float(round(t[0], 2))
            freq = round(t[1], 2)
            c.append(amp)
            c.append(freq)
        cleaned.append(c)

    print("SENDING:", address, cleaned)
    tag = ','

    for l in cleaned:
        print(l)
        t = '[' + ('d' * len(l))
        t += ']'
        tag += t

    print("TAG:", tag)

    msg = oscbuildparse.OSCMessage(address, tag, cleaned)
    oscel.osc_send(msg, "SENDER CLIENT")
    print("SENT:", address, cleaned)

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
