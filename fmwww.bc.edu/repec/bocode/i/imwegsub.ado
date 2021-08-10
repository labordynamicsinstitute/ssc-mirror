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
capture program drop imwegsub;
program define imwegsub, sortpreserve;
version 9.2;
syntax varlist(min=1 max=1)[ ,   IPSCH(string) FPSCH(string) HSIZE(varname) pcexp(varname)];

tokenize `varlist';
tempvar q0 q1;

imq0sub `1' , ipsch(`ipsch') hsize(`hsize');
gen `q0' =__imq0sub;
cap drop __imq0sub;

imq0sub `1' , ipsch(`fpsch') hsize(`hsize');
gen `q1' =__imq0sub;
cap drop  __imq0sub;

tempvar share;
gen `share'=`1' /`pcexp';
/*
sum `share';
tempvar dp;
gen `dp' = `q0'/`q1';

sum `dp';
*/
tempvar wegvar;
gen `wegvar' =( 1 / ((`q0'/`q1')^`share') -  1 )*`pcexp' ;
qui replace `wegvar' = 0 if `q0' == 0 ;

cap drop __imwegsub;
qui gen  __imwegsub=`wegvar';
end;
