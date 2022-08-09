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

def showDurations(sectionsList):
    """
    prints/returns the duration for each section in a list of times
    """
    for i, time in enumerate(sectionsList):
        if i > 0:
            duration = round(sectionsList[i] - sectionsList[i-1], 2)
            seconds = duration % 1
            minutes = int(duration - seconds)
            displayTime = f"{minutes}:{round(60*seconds)}"
            print(f"Time {sectionsList[i-1]} to {sectionsList[i]}: {displayTime}")

sections = makeSections(15, 10, power=0.5)

print(sections)

showDurations(sections)
