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


#delimit;
capture program drop subjob46b;
program define subjob46b, eclass;
version 9.2;
syntax varlist(min=1)[, HSize(varname) HGroup(varname) LAN(string) XRNAMES(string)  AGGRegate(string) PCEXP(varname) IPSCH(varname)  FPSCH(varname) inf(real 0) elas(varname) appr(real 1) ];

tokenize `varlist';
_nargs    `varlist';
tempvar tot_imp;
gen `tot_imp' = 0;
forvalues i=1/$indica {;
tempvar Variable EST`i';
qui gen `EST`i''=0;
local tipsch = ""+`ipsch'[`i'];
local tfpsch = ""+`fpsch'[`i'];
local telas   = `elas'[`i'];
imrsub ``i'' , ipsch(`tipsch') fpsch(`tfpsch') elas(`telas') inf(`inf') hsize(`hsize') appr(`appr');
tempvar imrsub_``i'' ;
qui gen  `imrsub_``i''' = __imrsub;
local nlist `nlist' `imrsub_``i''' ;
qui replace `tot_imp' = `tot_imp' + `imrsub_``i''';
cap drop __imrsub;

};
cap drop __imp_rev;
gen  __imp_rev = `tot_imp';
 
aggrvar `nlist' , xrnames(`xrnames') aggregate(`aggregate');

local slist = r(slist);
local flist = r(flist);
local drlist = r(drlist);
subjobstat `flist',   hs(`hsize') hgroup(`hgroup') lan(`lan')   xrnames(`slist')  stat(exp_pc) ;
cap drop `drlist';
tempname mat46 ;
matrix `mat46'= e(est);
ereturn matrix est2 = `mat46';

end;



