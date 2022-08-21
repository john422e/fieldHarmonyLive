
# osc imports
from osc4py3.as_eventloop import *
from osc4py3 import oscmethod as osm
from osc4py3 import oscbuildparse

# std imports
from random import randrange
import time
from datetime import datetime, timedelta

# pi import
import RPi.GPIO as GPIO

# GLOBALS
fn = "d3.py"
running = True
localIP = "127.0.0.1"
sendPort = 10001
rcvPort = 5000
pingAddress = "/setPing"
shutdownAddress = "/shutdown"

dummyDistance = 0
step = 1

TRIG = 23
ECHO = 24

pingInterval = 0.25 # in seconds
pingState = 0

def setPing(newPingState):
    global pingState
    # sets ping state to 0 or 1
    print(fn, "PING STATE:", newPingState)
    pingState = newPingState

def ultrasonic_init():
    # initialize ultrasonic
    GPIO.setmode(GPIO.BCM)

    GPIO.setup(TRIG, GPIO.OUT)
    GPIO.setup(ECHO, GPIO.IN)

    GPIO.output(TRIG, False)
    time.sleep(2)

def get_reading():
    # does a ping or something
    GPIO.output(TRIG, True)
    time.sleep(0.00001)
    GPIO.output(TRIG, False)

    break_loop = False
    timeout = datetime.now() + timedelta(seconds=1)

    pulse_end = 0
    pulse_start = 0

    # finds the time measurements?
    while GPIO.input(ECHO)==0:
        pulse_start = time.time()
        # if timeout > datetime.now():
        #    break;

    timeout = datetime.now() + timedelta(seconds=1)
    while GPIO.input(ECHO)==1:
        pulse_end = time.time()
        # if timeout > datetime.now():
        #     break;

    # some calculations to convert to centimeters
    pulse_duration = pulse_end - pulse_start
    distance = pulse_duration * 17150
    return round(distance, 2)

def sendDistance():
    # sends distance to proper synthNum
    reading = get_reading()
    # build message
    #print("d2.py distance:", dummyDistance)
    msg = oscbuildparse.OSCMessage("/distance", None, [reading])
    osc_send(msg, "SENDER CLIENT")

def shutdown():
    global running
    print(fn, "SHUTTING SENSOR DOWN")
    running = False


# MAIN
if __name__ == "__main__":

    # startup sensors
    ultrasonic_init()

    # start the system
    osc_startup()

    # SERVER-----------------------------------------------
    # make server channels to receive packets
    osc_udp_server(localIP, rcvPort, "SENSOR PING SERVER")
    # assign functions
    osc_method(pingAddress, setPing)
    osc_method(shutdownAddress, shutdown)
    print(fn, "SERVING ON PORT", rcvPort)

    # CLIENT-----------------------------------------------
    osc_udp_client(localIP, sendPort, "SENDER CLIENT")

    # loop and listen
    while running:
        osc_process()
        # only fetch distance and send when pingState == 1
        if pingState == 1:
            sendDistance()
        time.sleep(pingInterval)

    print(fn, "EXITING")
    # properly close the system
    GPIO.cleanup()
    osc_terminate()
