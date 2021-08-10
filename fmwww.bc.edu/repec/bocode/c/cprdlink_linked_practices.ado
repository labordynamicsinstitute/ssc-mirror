#delim ;
prog def cprdlink_linked_practices;
version 13.0;
*
 Create dataset with 1 obs per linked practice.
  Add-on packages required:
 keyby
*!Author: Roger Newson
*!Date: 13 June 2016
*;

syntax using [ , CLEAR noKEY ];
/*
 clear specifies that any existing dataset in memory will be cleared.
 nokey specifies that the new dataset will not be keyed by patid.
*/

*
 Input data
*;
import delimited `using', varnames(1) delim(tab) `clear';
cap lab var pracid "CPRD GOLD Practice ID";
desc, fu;

*
 Key dataset if requested
*;
if "`key'"!="nokey" {;
  keyby pracid, fast;
};

*
 Describe dataset
*;
desc, fu;
char list;

end;
