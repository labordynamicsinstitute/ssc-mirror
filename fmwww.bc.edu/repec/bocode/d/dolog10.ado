#delim ;
program define dolog10;
version 10.0;
*
 Execute a do-file `1', outputting to `1'.log,
 with the option of passing parameters.
 Adapted from an example called dofile, given in net course 151,
 and installed at the KCL site by Jonathan Sterne.
*! Author: Roger Newson
*! Date: 10 January 2008
*;
 capture log close;
 log using `"`1'.log"', replace;
 display "Log file `1'.log opened on $S_DATE at $S_TIME";
 capture noisily do `0';
 local retcod = _rc;
 display "Log file `1'.log completed on $S_DATE at $S_TIME";
 log close;
 exit `retcod';
end;
