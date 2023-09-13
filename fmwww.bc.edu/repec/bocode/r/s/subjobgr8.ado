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
capture program drop subjobgr8;
program define subjobgr8, rclass ;

version 9.2;
syntax varlist(min=1)[, HSize(varname) HGroup(varname) LAN(string) XRNAMES(string)  AGGRegate(string) PCEXP(varname) IPSCH(varname)  FPSCH(varname) WAPPR(int 1) MIN(real 0) MAX(real 100) OGR(string)  SCEN(string) NSCEN(int 1) TYPETR(int 1) GTARG(varname)   ];
/*
set trace on;
set tracedepth 1;
*/
preserve;
capture {;
local lvgroup:value label `hgroup';
if ("`lvgroup'"!="") {;
uselabel `lvgroup' , clear;
qui count;
forvalues i=1/`r(N)' {;
local tem=value[`i'];
local grlab`tem' = label[`i'];
};
};
};
restore;

preserve;
qui tabulate `hgroup', matrow(grn);
restore;

preserve;
svmat int grn ;
global india=r(r);




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
				
tempvar imwsub_`tname' ;
qui gen  `imwsub_`tname'' = __imwsub;
local nlist `nlist' `imwsub_``i''' ;
cap drop __imwsub;
cap drop __tdef;
qui replace `tot_imp' = `tot_imp' + `imwsub_`tname'';
};


if (`wappr'==2) {;
tempvar tot_imp;
qui gen `tot_imp' =( 1 / `price_def' -  1 )*`pcexp' ;
};



/*
imean `tot_imp' , hs(`hsize') hg(`hgroup');
*/

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

forvalues k = 1/$india {;
local kk = grn1[`k'];
qui sum `tot_imp' [aw=`_fw']  if `hgroup'==`kk', meanonly;
local mu`k' = r(mean);
local label`k'  : label (`hgroup') `kk';
if ( "`grlab`kk''" == "") local label`k'  = "Group_`kk'";
};





tempvar trans;
local pas = (`max'-`min') / 100;
qui gen `trans' = (_n-1)*`pas' in 1/101;

forvalues k = 1/$india {;
local kk = grn1[`k'];
local label`k'  : label (`hgroup') `kk';
if ( "`grlab`kk''" == "") local label`k'  = "Group_`kk'";
tempvar net_imp_`k' ;
qui gen `net_imp_`k'' =. ;
};

tempvar indicator;
qui gen `indicator' = 1;
if ("`gtarg'"~="") replace `indicator' = `gtarg';

forvalues i=1/101 {;
cap drop `net_imp';
tempvar   net_imp ;
if `typetr' == 1 qui gen `net_imp' = `tot_imp' +(`i'-1)*`pas'*`indicator'          ;
if `typetr' == 2 qui gen `net_imp' = `tot_imp' +(`i'-1)*`pas'/`hsize'*`indicator'  ;

forvalues k = 1/$india {;

local kk = grn1[`k'];
qui sum `net_imp' [aw=`_fw']  if `hgroup'==`kk', meanonly;
qui replace `net_imp_`k'' = r(mean) in `i';
};

};

forvalues k = 1/$india {;
local yvar `yvar' `net_imp_`k'' ;
};



if "`lan'"=="en" {;
if `typetr' == 1 local xtit = "Level of individual transfer";
if `typetr' == 2 local xtit = "Level of household transfer";
};

if "`lan'"=="fr" {;
if `typetr' == 1 local xtit = "Niveau de transfert par individu";
if `typetr' == 2 local xtit = "Niveau de transfert par ménage";
};


gropt 8 `lan' ;
local mtitle `r(gtitle)' ;
if (`nscen'>1) local mtitle `mtitle' : Scenario `scen';
line `yvar'  `trans' in 1/101 , 
legend(
label(1 `label1')
label(2 `label2')
label(3 `label3')
label(4 `label4')
label(5 `label5')
label(6 `label6')
label(7 `label7')
label(8 `label8')
label(9 `label9')
label(10 `label10')
label(11 `label11')
label(12 `label12')
label(13 `label13')
label(14 `label14')
label(15 `label15')
label(16 `label16')
)
title(`mtitle')  
xtitle(`xtit')
ytitle(`r(gytitle)') 
`r(gstyle)' 
`ogr'
;

end;








