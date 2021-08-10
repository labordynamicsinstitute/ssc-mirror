#delim ;
program define dolog15;
version 15.0;
*
 Execute a do-file `1', outputting to `1'.log,
 with the option of passing parameters.
 Adapted from an example called dofile, given in net course 151,
 and installed at the KCL site by Jonathan Sterne.
*! Author: Roger Newson
*! Date: 06 June 2017
*;
 capture log close;
 log using `"`1'.log"', replace;
 display "Log file `1'.log opened on `c(current_date)' at `c(current_time)'";
 capture noisily do `0';
 local retcod = _rc;
 display "Log file `1'.log completed on `c(current_date)' at `c(current_time)'";
 log close;
 exit `retcod';
end;
