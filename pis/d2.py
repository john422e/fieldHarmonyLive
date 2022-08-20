from osc4py3.as_eventloop import *
from osc4py3 import oscmethod as osm
from osc4py3 import oscbuildparse
from random import randrange
import time

# GLOBALS
running = True
localIP = "127.0.0.1"
sendPort = 10001
rcvPort = 5000
pingAddress = "/setPing"
shutdownAddress = "/shutdown"

dummyDistance = 0
step = 1


pingInterval = 0.25 # in seconds
pingState = 0

def setPing(newPingState):
    global pingState
    # sets ping state to 0 or 1
    print("d2.py PING STATE:", newPingState)
    pingState = newPingState

def sendDistance():
    # sends distance to proper synthNum
    dummyDistance = randrange(0.0, 300.0)
    #dummyDistance = 10.0
    dummyDistance = float(dummyDistance)
    # build message
    #print("d2.py distance:", dummyDistance)
    msg = oscbuildparse.OSCMessage("/distance", None, [dummyDistance])
    osc_send(msg, "SENDER CLIENT")

def shutdown():
    global running
    print("d2.py SHUTTING SENSOR DOWN")
    running = False

# start the system
osc_startup()

# SERVER-----------------------------------------------
# make server channels to receive packets
osc_udp_server(localIP, rcvPort, "SENSOR PING SERVER")
# assign functions
osc_method(pingAddress, setPing)
osc_method(shutdownAddress, shutdown)
print("d2.py SERVING ON PORT", rcvPort)

# CLIENT-----------------------------------------------
osc_udp_client(localIP, sendPort, "SENDER CLIENT")

# loop and listen
while running:
    osc_process()
    # only fetch distance and send when pingState == 1
    if pingState == 1:
        sendDistance()
    time.sleep(pingInterval)

print("d2.py EXITING")
# properly close the system
osc_terminate()
