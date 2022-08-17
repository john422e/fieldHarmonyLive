"""
accepts 3 optional command line arguments for:
numSections: number of sections to divide time of piece into
duration: total duration of piece
power: determines the slope (linear, exp, log)
"""

import sys

def normalize(a_list):
    normalized_list = []
    for val in a_list:
        n = (val - min(a_list)) / (max(a_list) - min(a_list))
        normalized_list.append(n)
    return normalized_list

def makeSections(numSections=10, duration=10, power=1):
    """
    return a list of section start times (and final end time)
    function can be linear (power=1) or exponential (power>1) or logarithmic (power<1)
    """
    sections = [i**power for i in range(numSections+1)]
    sections = normalize(sections)
    sections = [round(i * duration, 2) for i in sections]

    return sections

def getDurations(sectionsList, show=False):
    """
    prints/returns the duration for each section in a list of times
    """
    durations = []
    for i, time in enumerate(sectionsList):
        if i > 0:
            duration = round(sectionsList[i] - sectionsList[i-1], 2)
            durations.append(duration)
            if show:
                seconds = duration % 1
                minutes = int(duration - seconds)
                displayTime = f"{minutes}:{round(60*seconds)}"
                print(f"Time {sectionsList[i-1]} to {sectionsList[i]}: {displayTime}")
    return durations


# MAIN

if __name__ == "__main__":

    if len(sys.argv) > 1:
        try:
            numSections = int(sys.argv[1])
            duration = float(sys.argv[2])
            power = float(sys.argv[3])
        except:
            print("Must provide 3 arguments (int, float, float) for numSections, duration, power")
            print("Or omit for defaults of 10, 10.0, 1.0")

    else:
        print("Using defaults of 10, 10.0, 1.0 for numSections, duration, power")
        numSections = 10
        duration = 10.0
        power = 1.0


    sections = makeSections(numSections, duration, power=power)
    #15 10 0.5
    durations = getDurations(sections, show=False)
    sys.stdout.write(str(durations) + "\n")
