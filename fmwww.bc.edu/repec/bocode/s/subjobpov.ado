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



 
/*

stat:
exp_tt  : Total expenditures
exp_pc  : Expenditures per capita
exp_hh  : Expenditures per household

con_tt  : Total consumption
con_pc  : Consumption per capita
con_hh  : Consumption per household

*/



#delimit ;



capture program drop basicpov;
program define basicpov, rclass;
syntax varlist(min=1 max=1) [, HSize(varname)  PLINE(varname)  PCEXP(varname) ALpha(real 0) ];
preserve; 
tokenize `varlist';
tempvar we ga0 ga10 ga1 hy;
gen `hy' = `1';


local hweight=""; 
cap qui svy: total `1'; 
local hweight=`"`e(wvar)'"';
cap ereturn clear; 
qui gen `we'=1;
if ("`hweight'"~="")    qui replace `we'=`we'*`hweight';


if "`stat'" == "" local stat = "exp_tt";

gen `ga0' = 0;
gen `ga10' = 0;
gen `ga1' = 0;


if (`alpha'==0) qui replace `ga0' = `hsize'*(`pline'>`pcexp');
if (`alpha'~=0) qui replace `ga0' = `hsize'*((`pline'-`pcexp')/`pline')^`alpha' if (`pline'>`pcexp');



if (`alpha'==0) qui replace `ga1' = `hsize'*(`pline'>`hy');
if (`alpha'~=0) qui replace `ga1' = `hsize'*((`pline'-`hy')/`pline')^`alpha' if (`pline'>`hy');



qui replace `ga10' = `ga1'-`ga0';


qui sum `hsize' [aweight= `we'];
local denom = r(mean);

qui sum `ga1' [aweight= `we'];
local fgt1 = r(mean)/`denom';



qui svydes;
local fr=`r(N_units)'-`r(N_strata)';

qui svy: ratio `ga10' / `hsize';
cap drop matrix _aa;
matrix _aa=e(b);
local est10 = el(_aa,1,1);
cap drop matrix _vv;
matrix _vv=e(V);
local ste10 = el(_vv,1,1)^0.5;



return scalar fgt1 = `fgt1'*100;


return scalar est10 = `est10'*100;


return scalar ste10 = `ste10'*100;



local tval = `est10'/`ste10';
local pval = 1-2*(normal(abs(`tval'))-0.5);
if `ste10'==0 local pval = 0; 
return scalar pval10 = `pval';



end;



capture program drop subjobpov;
program define subjobpov, eclass;
version 9.2;
syntax varlist(min=1)[, 
HSize(varname)  
PCEXP(varname)
XRNAMES(string) 
LAN(string) 
STAT(string)
ALPHA(real 0)
pline(varname)
];




preserve;

tokenize `varlist';
_nargs    `varlist';
local indica2 = $indica+2;

tempvar total;
qui gen `total'=0;
tempvar Variable EST1 EST11 EST111 EST1111  ;
qui gen `EST1'=0;
qui gen `EST11'=0;
qui gen `EST111'=0;
qui gen `EST1111'=0;



forvalues i=1/$indica {;
qui replace `total'=`total'+``i'';
};






tempvar Variable ;
qui gen `Variable'="";

tempvar _ths;
qui gen  `_ths'=1;
if ( "`hsize'"!="") qui replace `_ths'=`hsize';

cap svy: total;
if ( "`r(settings)'"==", clear") qui svyset _n, vce(linearized);




basicpov `pcexp' ,  hsize(`_ths') pline(`pline') alpha(`alpha') pcexp(`pcexp');
qui replace `Variable' = "Pre-reform" in 1;
qui replace `EST1'=  `r(fgt1)'  in 	1;
qui replace `EST11'=  . in 	1;
qui replace `EST111'=  .  in 	1;
qui replace `EST1111'=  .  in 	1;


forvalues k = 1/$indica {;
local j = `k' +1;
tempvar sliving;
qui gen `sliving' = `pcexp'+``k'';
basicpov `sliving' ,  hsize(`_ths') pline(`pline')  alpha(`alpha') pcexp(`pcexp');

qui replace `EST1'=  `r(fgt1)'  in `j';
qui replace `EST11'=  `r(est10)'  in 	`j';
qui replace `EST111'=  `r(ste10)'  in 	`j';
qui replace `EST1111'=  `r(pval10)'  in 	`j';

};

tempvar sliving;
qui gen `sliving' = `pcexp'+`total';
basicpov `sliving' ,  hsize(`_ths') pline(`pline')  alpha(`alpha') pcexp(`pcexp');
qui replace `EST1'=  `r(fgt1)'  in `indica2';
qui replace `EST11'=  `r(est10)'  in `indica2';
qui replace `EST111'=  `r(ste10)'  in 	`indica2';
qui replace `EST1111'=  `r(pval10)'  in 	`indica2';
qui replace `Variable' = "Post-reform" in `indica2';








/****TO DISPLAY RESULTS*****/

local cnam = "";

if ("`lan'"~="fr")  local cnam `"`cnam' "Poverty level""';
if ("`lan'"~="fr")  local cnam `"`cnam' "The change in poverty ""';
if ("`lan'"~="fr")  local cnam `"`cnam' "Standard error""';
if ("`lan'"~="fr")  local cnam `"`cnam' "P-Value""';



					 


if ("`lan'"=="fr")  local cnam `"`cnam' "Niveau de pauvreté""';
if ("`lan'"=="fr")  local cnam `"`cnam' "Le changement dans la pauvreté""';
if ("`lan'"=="fr")  local cnam `"`cnam' "Erreur type""';
if ("`lan'"=="fr")  local cnam `"`cnam' "P-Value""';





local lng = (`indica2');
qui keep in 1/`lng';

local dste=0;



tempname zz;
qui mkmat   `EST1'  `EST11'  `EST111' `EST1111'  ,   matrix(`zz');



local rnam;
local rnam `"`rnam' "Pre reform""';
if ("`xrnames'"~="") {;
local xrna  "`xrnames'";
local xrna : subinstr local xrna " " ",", all ;
local xrna : subinstr local xrna "|" " ", all ;
local count : word count `xrna';
tokenize "`xrna'";
forvalues i = 1/`count' {;
	local `i': subinstr local `i' "," " ", all ;
	    local tmp = substr("``i''",1,30);
	    local rnam `"`rnam' "`tmp'""';
	
};
};

local rnam `"`rnam' "Post reform""';



matrix rownames `zz' = `rnam' ;
matrix colnames `zz' = `cnam' ;


cap matrix drop _vv _aa gn;

ereturn matrix est = `zz';

restore;

end;



