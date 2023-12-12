******************************************************************************
/*
* Guide to comparing entries using cfout and readreplace
	By Ryan Knight
	v0.2 on March 9, 2010
	
	To be used in conjunction with the "Guide to Comparing the First and Second Entries"
	
	The data is fake, generated using Excel.
*/

* Load the first entry
use "firstEntry.dta" 

* compare to the second entry
cfout region-no_good_at_all using "secondEntry.dta" , id(uniqueid)

* Make replacements using corrected data
readreplace using "correctedValues.csv", id(uniqueid)

