#delim ;
program define dotex;
version 14.0;
*
 Execute a do-file `1', outputting to `1'.tex,
 written in the SJ LaTeX version of TeX,
 with the option of passing parameters.
 Adapted from dolog (which creates text log files).
*! Author: Roger Newson
*! Date: 08 April 2014
*;
 capture log close;
 tempfile tmplog;
 qui log using `"`tmplog'"', smcl replace;
 display "Temporary log file opened on `c(current_date)' at `c(current_time)'";
 capture noisily do `0';
 local retcod = _rc;
 display "Temporary log file completed on `c(current_date)' at `c(current_time)'";
 qui log close;
 * Copy temporary file to TeX file *;
 log texman `"`tmplog'"' `"`1'.tex"',replace; 
 exit `retcod';
end;
