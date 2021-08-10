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
capture program drop imwsub_cob_doug;
program define imwsub_cob_doug, sortpreserve rclass;
version 9.2;
syntax varlist(min=1 max=1)[ ,   IPSCH(string) FPSCH(string) HSIZE(varname)  PCEXP(varname)];

tokenize `varlist';
tempvar p0 p1;

imq0sub `1' , ipsch(`ipsch') hsize(`hsize');
qui gen `p0' =`1'/__imq0sub;
qui cap drop __imq0sub;

imq0sub `1' , ipsch(`fpsch') hsize(`hsize');
qui gen `p1' =`1'/__imq0sub;
cap drop  __imq0sub;



tempvar ishare;
qui gen `ishare'= `1'/`pcexp';
qui cap drop __tdef;
qui gen  __tdef = (`p1'/`p0')^`ishare';
qui replace __tdef = 1 if __tdef ==.; 

qui cap drop __imwsub ;
qui gen __imwsub =( 1 / __tdef -  1 )*`pcexp' ;
end;
