// run one of the ~sections blocks, then run the ~fills block
(
// 15 minutes -- do this one
// python3 form_functions.py 50 3.5 1.1
// python3 form_functions.py 50 3.5 0.98
~sections = [0.05, 0.05, 0.06, 0.06, 0.06, 0.06, 0.06, 0.07, 0.06, 0.07, 0.06, 0.07, 0.07, 0.06, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.08, 0.07, 0.07, 0.08, 0.07, 0.07, 0.08, 0.07, 0.07, 0.08, 0.07, 0.08, 0.07, 0.08, 0.07, 0.08, 0.07, 0.08, 0.08, 0.07, 0.08, 0.08, 0.07, 0.08, 0.08, 0.07, 0.07, 0.07, 0.08, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.08, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.06, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.06, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.06, 0.07, 0.07, 0.07];
)
~sections.size;

(
// calculate fills
~fills = Array.fill(~sections.size, { arg i; (i+1)/~sections.size});
~fills = ~fills.normalize(0.999, 1.0);


// set source cound (# of mics)
~numSources = 2; // 3 or 6 (2 each?)

// set number of sine tones (must match number in python analysis server)
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

// check duration based on ~sections
l = 0;
~sections.do( {
	arg dur, i;
	var sec;
	sec = dur * 60;
	l = l + (sec*2);
});
~seconds = l;
~minutes = ~seconds/60;
);

~sections.size;
~seconds;
~minutes;