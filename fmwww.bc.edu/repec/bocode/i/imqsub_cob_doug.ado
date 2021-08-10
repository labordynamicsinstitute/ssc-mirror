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
capture program drop imqsub_cob_doug;
program define imqsub_cob_doug, sortpreserve rclass;
version 9.2;
syntax varlist(min=1 max=1)[ ,   IPSCH(string) FPSCH(string) HSIZE(varname) ];

tokenize `varlist';
tempvar q0 q1;

imq0sub `1' , ipsch(`ipsch') hsize(`hsize');
qui gen `q0' =__imq0sub;
qui replace `q0' =0 if `q0'==. ;
qui cap drop __imq0sub;

imq0sub `1' , ipsch(`fpsch') hsize(`hsize');
qui gen `q1' =__imq0sub;
qui replace `q1' =0 if `q1'==. ;
cap drop  __imq0sub;

qui cap drop __imqsub ;
qui gen  __imqsub = `q1' - `q0' ;
end;
