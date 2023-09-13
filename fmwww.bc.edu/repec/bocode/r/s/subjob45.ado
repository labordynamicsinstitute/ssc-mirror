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
capture program drop subjob45;
program define subjob45, eclass;
version 9.2;
syntax varlist(min=1)[, HSize(varname) HGroup(varname) LAN(string) XRNAMES(string)  AGGRegate(string) PCEXP(varname) IPSCH(varname)  FPSCH(varname) elas(varname) wappr(int 1) UNIT(varname)];

tokenize `varlist';
_nargs    `varlist';

forvalues i=1/$indica {;
tempvar Variable EST`i';
qui gen `EST`i''=0;
local tipsch = ""+`ipsch'[`i'];
local tfpsch = ""+`fpsch'[`i'];
local telas   = `elas'[`i'];
if (`wappr'==1)  imqsub ``i''          , ipsch(`tipsch') fpsch(`tfpsch') hsize(`hsize') elas(`telas');
if (`wappr'==2)  imqsub_cob_doug ``i'' , ipsch(`tipsch') fpsch(`tfpsch') hsize(`hsize') ;
tempvar imqsub_``i'' ;
qui gen  `imqsub_``i''' = __imqsub;
local nlist `nlist' `imqsub_``i''' ;
cap drop __imqsub;
};
 
aggrvar `nlist' , xrnames(`xrnames') aggregate(`aggregate');

local slist = r(slist);
local flist = r(flist);
local drlist = r(drlist);
subjobstat `flist',   hs(`hsize') hgroup(`hgroup') lan(`lan')   xrnames(`slist')  stat(exp_pc) unit(`unit');
cap drop `drlist';
tempname mat45 ;
matrix `mat45'= e(est);
local rowsize = rowsof(`mat45');
local colsize = colsof(`mat45') - 1 ;
matrix `mat45' = `mat45'[1..`rowsize', 1..`colsize'];
ereturn matrix est = `mat45';

end;



