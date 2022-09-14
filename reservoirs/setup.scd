(
// define ~numSources and get durations from form_functions.py

var p, l, cwd, pyFile, numSections=200, duration=10, power=1.0;  // ADJUST VARS HERE FOR FORM
//var p, l, cwd, pyFile, numSections=10, duration=1, power=0.6; // for testing

cwd = PathName.new(thisProcess.nowExecutingPath).parentPath;
pyFile = cwd ++ "form_functions.py";
p = Pipe.argv(["python3", pyFile, numSections.asString, duration.asString, power.asString], "r");
~sections = p.getLine;
p.close;

~sections = ~sections.interpret;

// manually run form_functions.py for numSections values greater than 170 (pipe issue?)
~sections = [0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04, 0.04, 0.05, 0.04, 0.04, 0.04];

~fills = Array.fill(~sections.size, { arg i; (i+1)/~sections.size});
~fills = ~fills.normalize(0.999, 1.0);

~numSources = 2; // 3 or 6 (2 each?)
~numSines = 4;
~currentData = Array.fill(~numSources, {
	[
		Array.fill(~numSines, { 1.0/~numSines }),
		Array.fill(~numSines, { rrand(100.0, 200.0)})
	]
});


["SECTIONS:", ~sections].postln;
["FILLS:", ~fills].postln;
["NUM MIC SOURCES:", ~numSources].postln;


)

