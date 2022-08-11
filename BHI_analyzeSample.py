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


    #print(peaks[:totalPeaks])
    #return peaks


    #for i in range(totalPeaks):
        #sys.stdout.write(str(peaks[i])+ "\n")
        #print(peaks[i])

    # send freqs to client
    sendData(sendAddress, peaks[:totalPeaks])
    #sendData(sendAddress, 300.0)

def sendData(address, data):
    # FOR TESTING
    # round it
    print("CLEANING")
    cleaned = []
    for t in data:
        print(t)
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









def get_peak_frequencies(spectrum, params, with_amps=False, rounding_decimal=2):
    """
    rounding_decimal = decimal point that freq will be rounded to. 2 = 2 decimal points
    """
    # get first x peaks frequencies
    peaks = spectrum.peaks()#[:total_peaks]
    # amp=peaks[0] freq=peaks[1]
    freqs = []
    for i in peaks:
        freq = round(i[1], rounding_decimal)
        # filters out freqs below min_threshold
        if freq <= params['low pass'] and freq >= params['high pass'] and freq != 0:
            if with_amps:
                # append tuplet [amp, freq], but round freq
                freqs.append((i[0], freq)) # appends tuplet
            else:
                freqs.append(float(round(Decimal(freq), rounding_decimal)))
        if len(freqs) >= params['total peaks']:
            break
    return freqs # with_amp returns list of amp, freq tuplets; else returns freq list

def thin_freqs(freqs, with_amps=False):
    # filter out freqs within hz_boundary percentage (.5 percent is good - pitch JND)
    if with_amps:
        unique_freqs = [freqs[0][1]]
        unique_freq_pairs = []
    else:
        unique_freqs = [freqs[0]]
    for freq_item in freqs:
        if with_amps:
            freq = freq_item[1]
        else:
            freq = freq_item
        unique = True
        #rounded_freq = round(freq) why was i rounding this?
        # get a range around each freq
        hz_boundary = 0.005
        min = 1 - params['hz boundary']
        max = 1 + params['hz boundary']
        # now test each freq already in unique_freqs to see if it's in this range
        for i in unique_freqs:
            if i >= (freq * min) and i <= (freq * max):
                unique = False
        if unique == True:
            unique_freqs.append(freq)
            if with_amps:
                unique_freq_pairs.append(freq_item)
    if with_amps:
        return unique_freq_pairs
    else:
        return unique_freqs
