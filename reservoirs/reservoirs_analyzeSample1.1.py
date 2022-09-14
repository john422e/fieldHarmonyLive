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
rcvPort = 9998
sendPort = 9999
pingAddress = "/ping"
shutdownAddress = "/shutdown"
sendAddress = "/freqs"

# DEFAULTS
numWavs = 2 # 3
wavFiles = ["temp" + str(i) + ".wav" for i in range(numWavs)]
totalPeaks = 4 #8

masterPeaks = []


params['total peaks'] = totalPeaks*2 # allow larger size because we'll thin them
params['high pass'] = 100
params['low pass'] = 1500
params['hz boundary'] = 0.05

# FUNCTIONS
def shutdown():
    global running
    print(fn, "SHUTTING DOWN SAMPLE ANALYSIS SERVER")
    running = False

def analyzeSample(chan):
    global totalPeaks
    global wavFile

    print("ADDRESS", chan)

    wavFile = "temp" + str(chan) + ".wav"
    #print(wavFile)

    #masterPeaks = []
    # get a range around each freq
    min = 1 - params['hz boundary']
    max = 1 + params['hz boundary']

    print("ANALYZING", wavFile)
    wave = thinkdsp.read_wave(wavFile)
    #print("HERE")
    #wave.apodize()
    spectrum = wave.make_spectrum()
    peaks = spectrum.peaks()

    #print("HERE")


    # now filter and limit
    filteredPeaks = []
    while( len(filteredPeaks) < totalPeaks):
        #print("LENGTH:", len(filteredPeaks1))
    # stop once length is met

        for freqTuple in peaks:
            if len(filteredPeaks) >= totalPeaks: break
            freq = freqTuple[1] # this is the new potential freq
            #print(freq)
            # filter for high and low pass (range)

            if freq > params['high pass'] and freq < params['low pass']:
                #print("FREQ IN RANGE", freq)
                if len(filteredPeaks) == 0:
                    #print("FIRST FREQ")
                    filteredPeaks.append(freqTuple)
                else:
                    # now test each freq already in filteredPeaks1 to see if it's in this range
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
                        #print(f"adding {freq} to list")
                        freqs = [round(pair[1]) for pair in filteredPeaks]
                        #print(freqs)
                        filteredPeaks.append(freqTuple)

    #masterPeaks.append(filteredPeaks)

    # send freqs to client
    print("SENDING 106", filteredPeaks)
    #sendData(sendAddress, chan, masterPeaks)
    sendData(sendAddress, chan, filteredPeaks)

def sendData(address, chan, data):
    # data is 2d array [ [amps, freqs], [amps, freqs] ]
    # TAG: ,dddddddddddddddd
    #',ii[iiii]'
    # round it
    #print("CLEANING")
    cleaned = []
    for tuple in data:
        for item in tuple:
            cleaned.append(round(item, 2))
        """
        c = []
        # go through each list and put everything into one list of [amp, freq, amp, freq...]
        for i, t in enumerate(l):
            print(i, t)
            amp = float(round(t[0], 2))
            freq = round(t[1], 2)
            c.append(amp)
            c.append(freq)
        cleaned.append(c)
        """

    print("SENDING 131 :", address, cleaned)
    tag = ',i[' + ('d' * len(cleaned)) + ']'

    """
    for l in cleaned:
        print(l)
        t = '[' + ('d' * len(l))
        t += ']'
        tag += t
    """

    print("TAG:", tag)

    sendData = [chan, cleaned]

    msg = oscbuildparse.OSCMessage(address, tag, sendData)
    oscel.osc_send(msg, "SENDER CLIENT")
    print("SENT:", address, sendData)

# MAIN
if __name__ == "__main__":
    # start osc
    oscel.osc_startup()
    # setup server
    oscel.osc_udp_server(localIP, rcvPort, "SAMPLE ANALYSIS SERVER")
    # assign functions
    print("HERE 149")
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
