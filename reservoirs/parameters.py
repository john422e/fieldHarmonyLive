"""
parameters.py
saves settings for analysis program
author: john eagle
last update: 2.10.20
"""


# DEFAULTS
params = {
# file handling
'project folder': None, # top directory
# file input
'audio path': '../audio/trimmed/', # Set audio path to audio directory
'filename': None, # Set filename to specific audio file
'filepath': None, # autoset from audio path + filepath
# file output
# AUDIO
'peaks': None,
'harmonies': None,
'analyses': None, #"analyses/",
'depth': None, # for particular analysis params
'directory': None, # Set the top directory for all file output, deprecated?
'region': None, # autoset
'subregion': None,
'ly directory': None,
# time sequence params, set all to None if not using
'offset thresh': None, # for gaps or offsets in time sequence
'offset unit': None, # the offset unit type (minute, second, or microsecond)
'offset inc': 0, # the offset value (negative for subtracting)
# basic analysis params
'framerate': 48000,
'sample duration': 10,
'playback duration': 10, # If not None, will set duration of .wav files created, else it is equal to 'sample duration'
'start time': 0,
'high pass': 100,
'low pass': 10000,
'hz boundary': 0.5, # 5% .005, # 0.5%
'clear harmonics': [2],#[1, 2, 4, 8, 16], # harmonics of frequency to filter for
'total peaks': 0,
# harmonic analysis params
'denominator limit': 128, # resolution
'prime limit': 13, # limit prime depth
'limit range': True, # whether to limit range or not
'max ratio int': 32, # what to limit it to
'max range multiplier': 3, # what to limit it to
'ratio min count': 1, # number of tones in group, deprecated?
# count - deprecated?
'analysis count': 0
}
