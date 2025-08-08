#delim ;
program define kmsenspec_p;
version 16.0;
/*
 Predict program for kmsenspec
 (warning the user that predict should not be used
 after kmsenspec)
*! Author: Roger Newson
*! Date: 03 March 2020
*/

syntax [newvarlist] [,*];

disp as error
 "predict should not be used after kmsenspec";
error 498;

end;
