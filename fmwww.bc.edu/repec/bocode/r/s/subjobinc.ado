*! version 2.10 06June2014 M. Araar Abdelkrim & M. Paolo verme
/*************************************************************************/
/* SUBSIM: Subsidy Simulation Stata Toolkit  (Version 2.1)               */
/*************************************************************************/
/* Conceived by Dr. Araar Abdelkrim[1] and Dr. Paolo Verme[2]            */
/* World Bank Group (2012-2014)		                                 */
/* 									 */
/* [1] email : aabd@ecn.ulaval.ca                                        */
/* [1] Phone : 1 418 656 7507                                            */
/*									 */
/* [2] email : pverme@worldbank.org                                      */
/*************************************************************************/



#delimit ;


capture program drop subjobinc;
program define subjobinc, eclass;
version 9.2;
syntax varlist(min=1)[, 
HSize(varname) HGroup(varname)  
PCEXP(varname)
IPSCH(varname)
XRNAMES(string) LAN(string) STAT(string)];



tokenize `varlist';
_nargs    `varlist';


forvalues i=1/$indica {;
tempvar Variable EST`i';
qui gen `EST`i''=0;
local tipsch = ""+`ipsch'[`i'];
incsub ``i'' , ipsch(`tipsch');
cap drop __sub_``i'';
qui gen  __sub_``i'' = __esub;
cap drop __esub;
};


end;




