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
capture program drop subjob42;
program define subjob42, eclass;
version 9.2;
syntax varlist(min=1)[, HSize(varname) HGroup(varname) LAN(string) XRNAMES(string)  AGGRegate(string) PCEXP(varname) IPSCH(varname)  FPSCH(varname) WAPPR(int 1) GVIMP(int 0)];

tokenize `varlist';
_nargs    `varlist';

tempvar price_def;
qui gen `price_def' =1;
tempvar tot_imp;
gen `tot_imp' = 0;
forvalues i=1/$indica {;

tempvar Variable EST`i';
qui gen `EST`i''=0;
local tipsch = ""+`ipsch'[`i'];
local tfpsch = ""+`fpsch'[`i'];

if (`wappr'==1) {;
imwsub ``i'' , ipsch(`tipsch') fpsch(`tfpsch') hsize(`hsize');
};

if (`wappr'==2) {;
                  imwsub_cob_doug ``i'' , ipsch(`tipsch') fpsch(`tfpsch') hsize(`hsize') pcexp(`pcexp');
				  qui replace `price_def' = `price_def' * __tdef;
				};
				
tempvar imwsub_``i'' ;
qui gen  `imwsub_``i''' = __imwsub;
local nlist `nlist' `imwsub_``i''' ;
cap drop __imwsub;
cap drop __tdef;
qui replace `tot_imp' = `tot_imp' + `imwsub_``i''';

};


if (`wappr'==2) {;
tempvar tot_imp;
qui gen `tot_imp' =( 1 / `price_def' -  1 )*`pcexp' ;
subjobstat `tot_imp',   hs(`hsize') hgroup(`hgroup') lan(`lan')   xrnames(total)  stat(exp_pc) ;
tempname mat42tot ;
matrix `mat42tot'= e(est); 
};

if (`gvimp'==1) {;
cap drop _imp_on_well;
qui gen _imp_on_well = `tot_imp' ;
};


aggrvar `nlist' , xrnames(`xrnames') aggregate(`aggregate');
local slist = r(slist);
local flist = r(flist);
local drlist = r(drlist);
subjobstat `flist',   hs(`hsize') hgroup(`hgroup') lan(`lan')   xrnames(`slist')  stat(exp_pc);
cap drop `drlist';
tempname mat42 ;
matrix `mat42'= e(est);
if (`wappr'==2) {;
local rowsize = rowsof(`mat42');
local colsize = colsof(`mat42');
forvalues i=1/`rowsize' {;
 matrix `mat42'[ `i',`colsize'] = el(`mat42tot',`i',1);
};
};
ereturn matrix est = `mat42';
cap drop  __imp_well; 
qui gen __imp_well = `tot_imp' ;
end;






