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
capture program drop subjob25;
program define subjob25, eclass;
version 9.2;
syntax varlist(min=1)[, HSize(varname) HGroup(varname) LAN(string) XRNAMES(string)  AGGRegate(string) PCEXP(varname) IPSCH(varname)  FPSCH(varname) elas(varname) UNIT(varname)];

tokenize `varlist';
_nargs    `varlist';


forvalues i=1/$indica {;
tempvar Variable EST`i';
qui gen `EST`i''=0;
local tipsch = ""+`ipsch'[`i'];
imq0sub ``i'' , ipsch(`tipsch') hsize(`hsize');
tempvar imq0sub_``i'' ;
qui gen  `imq0sub_``i''' = __imq0sub;
local nlist `nlist' `imq0sub_``i''' ;
cap drop __imq0sub;
};
 
aggrvar `nlist' , xrnames(`xrnames') aggregate(`aggregate');

local slist = r(slist);
local flist = r(flist);
local drlist = r(drlist);

subjobstat `flist',   hs(`hsize') hgroup(`hgroup') lan(`lan')   xrnames(`slist')  stat(exp_pc) unit(`unit') ;
cap drop `drlist';
tempname mat25 ;
matrix `mat25'= e(est);
local rowsize = rowsof(`mat25');
local colsize = colsof(`mat25') - 1 ;
matrix `mat25' = `mat25'[1..`rowsize', 1..`colsize'];
ereturn matrix est = `mat25';

end;



