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
capture program drop subjobgr10;
program define subjobgr10, rclass ;

version 9.2;
syntax varlist(min=1)[, HSize(varname) PLINE(varname) LAN(string) XRNAMES(string)  AGGRegate(string) PCEXP(varname) IPSCH(varname)  FPSCH(varname)  inf(real 0) elas(varname) appr(real 1) MIN(real 0) MAX(real 100) OGR(string)  SCEN(string) NSCEN(int 1) TYPETR(int 1) GTARG(varname) ];
*set trace on;


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
};


qui svyset ;
if ( "`r(settings)'"==", clear") qui svyset _n, vce(linearized);
local hweight=""; 
cap qui svy: total `1'; 
local hweight=`"`e(wvar)'"';
cap ereturn clear; 

tempvar _ths _fw;
qui gen `_ths'=1;
if ( "`hsize'"!="") qui replace `_ths'=`hsize';
qui gen `_fw'=`_ths';
if (`"`hweight'"'~="") qui replace `_fw'=`_fw'*`hweight';

tempvar trans;
local pas = (`max'-`min') / 100;
qui gen `trans' = (_n-1)*`pas' in 1/101;




tempvar res;
qui gen `res' = .;

tempvar indicator;
qui gen `indicator' = 1;
if ("`gtarg'"~="") replace `indicator' = `gtarg';

forvalues i=1/101 {;
cap drop  `net_rev' ;
tempvar   net_rev poor;
if `typetr' == 1 qui gen `net_rev' = `tot_imp' -(`i'-1)*`pas'*`indicator'          ;
if `typetr' == 2 qui gen `net_rev' = `tot_imp' -(`i'-1)*`pas'/`hsize'*`indicator'  ;


qui sum `net_rev' [aw=`_fw'];
qui replace `res' = r(sum) in `i';
};

if "`lan'"=="en" {;
if `typetr' == 1 local xtit = "Level of individual transfer";
if `typetr' == 2 local xtit = "Level of household transfer";
};

if "`lan'"=="fr" {;
if `typetr' == 1 local xtit = "Niveau de transfert par individu";
if `typetr' == 2 local xtit = "Niveau de transfert par ménage";
};

gropt 10 `lan' ;
local mtitle `r(gtitle)' ;
if (`nscen'>1) local mtitle `mtitle' : Scenario `scen';
line `res'  `trans' in 1/101 , 
title(`mtitle')  
xtitle(`xtit')
ytitle(`r(gytitle)') 
`r(gstyle)' 
`ogr'
;

end;








