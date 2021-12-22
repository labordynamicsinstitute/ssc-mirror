#delim ;
version 13.1;
*
 Create dataset patient with 1 obs per patient
*;

* Folder containing input text files *;
global CPRDDATA "../cprddata";

* Create and save patient dataset *;
cprd_patient using $CPRDDATA/Data/patient.txt, clear dofile(xyzlookuplabs.do);
cprd_patientobs using ./dta/practice, accept;
save ./dta/patient, replace;

exit;
