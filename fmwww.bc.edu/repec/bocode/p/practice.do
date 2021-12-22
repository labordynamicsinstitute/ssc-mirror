#delim ;
version 13.1;
*
 Create dataset practice with 1 obs per practice
*;

* Folder containing input text files *;
global CPRDDATA "../cprddata";

* Create and save practice dataset *;
cprd_practice using $CPRDDATA/Data/practice.txt, clear dofile(xyzlookuplabs.do); 
save ./dta/practice, replace;

exit;
