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
capture program drop subjobgr9;
program define subjobgr9, rclass ;

version 9.2;
syntax varlist(min=1)[, HSize(varname) PLINE(varname) LAN(string) XRNAMES(string)  AGGRegate(string) PCEXP(varname) IPSCH(varname)  FPSCH(varname) WAPPR(int 1) MIN(real 0) MAX(real 100) OGR(string)  SCEN(string) NSCEN(int 1) TYPETR(int 1) GTARG(varname) DGRA(int 1) ];
*set trace on;

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

qui replace `tot_imp'=max(`tot_imp', -`pcexp');

if (`wappr'==2) {;
tempvar tot_imp;
qui gen `tot_imp' =( 1 / `price_def' -  1 )*`pcexp' ;
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

tempvar poor0;
qui gen `poor0' = `pcexp'  < `pline';

qui sum `poor0'  [aw=`_fw'];
local hc=`r(mean)' ; 






tempvar trans;
local pas = (`max'-`min') / 100;
qui gen `trans' = (_n-1)*`pas' in 1/101;




tempvar res;
qui gen `res' = .;

tempvar indicator;

                   qui     gen `indicator' = 1;
if ("`gtarg'"~="") qui replace `indicator' = `gtarg';
                  
local  check = 1;
forvalues i=1/101 {;
cap drop  `net_in' ;
cap drop  `poor' ;
tempvar   net_in poor;
if `typetr' == 1 qui gen `net_in' = `pcexp' +`tot_imp' +(`i'-1)*`pas'*`indicator'          ;
if `typetr' == 2 qui gen `net_in' = `pcexp' +`tot_imp' +(`i'-1)*`pas'/`hsize'*`indicator'  ;
                 qui gen `poor' = ( `net_in'  < `pline') ;

qui sum `poor' [aw=`_fw'] , meanonly;
qui replace `res' = r(mean) in `i';

if `r(mean)' > `hc' & `check' ==1 {;
local x1 `trans'[`i'];
local y1 `res'[`i'];
};

if `r(mean)' <= `hc' & `check' ==1 {;
local x2 `trans'[`i'];
local y2 `res'[`i'];
local check=0;
local transp = `x1'+((`x2'-`x1')/(`y2'-`y1'))*(`hc'-`y1');
};

};


/*****************************/
local transpa =0;
qui sum `pline' ;
local mina = 0;
local maxa = `r(max)' ;
local mmm =  `r(max)' ;
local base = 0;
 * set trace on;
local ca = 0;


local niter=0;
local i=1 ;
forvalues i=1/10 {;
local  check = 1;
local  check2 = 1;
local pas`i' = (`maxa'-`mina') / 10;
local j=1 ;
while `j'<101   & `check2'!=0 {;
local ca = `ca'+ 1;
cap drop  `net_in' ;
cap drop  `poor' ;
tempvar   net_in poor;
if `typetr' == 1 qui gen `net_in' = `pcexp' +`tot_imp' +(`base'+(`j'-1)*`pas`i'')*`indicator'          ;
if `typetr' == 2 qui gen `net_in' = `pcexp' +`tot_imp' +(`base'+(`j'-1)*`pas`i'')/`hsize'*`indicator'  ;
                 qui gen `poor' = ( `net_in'  < `pline') ;
qui sum `poor' [aw=`_fw'] , meanonly;
local  resa = r(mean);
if `r(mean)' > `hc' & `check' ==1 {;
local x1 = (`base'+(`j'-1)*`pas`i'');
local y1=`resa';
local mina = `x1';
local base = `mina';
};
if `r(mean)' <= `hc' & `check' ==1 {;
local x2 = (`base'+(`j'-1)*`pas`i'');
local y2 = `resa';
local check=0;
local check2=0;
local maxa = `x2' ;
local   `check' = `check'+1;
local transpa = `x1'+((`x2'-`x1')/(`y2'-`y1'))*(`hc'-`y1');
};
local aa = (`base'+(`j'-1)*`pas`i'') ;
local j= `j'+ 1 ;
local niter=`niter' + 1 ;
};
};

/*****************************/


if "`lan'"=="en" {;
if `typetr' == 1 local xtit = "Level of individual transfer";
if `typetr' == 2 local xtit = "Level of household transfer";
};

if "`lan'"=="fr" {;
if `typetr' == 1 local xtit = "Niveau de transfert par individu";
if `typetr' == 2 local xtit = "Niveau de transfert par ménage";
};



tempvar any;
qui gen `any' = .;
gropt 9 `lan' ;
local mtitle `r(gtitle)' ;
if (`nscen'>1) local mtitle `mtitle' : Scenario `scen';

if (`transpa' <=`max') {;
local rtransp = round(`transpa',0.001);
local rhc     = round(floor(`hc'*10000000)/100000,0.001);
local graddi0 yline(`rhc'    , lcolor(blue) lpattern(dash)) xline(`transpa', lcolor(red) lpattern(dash)) ;
local graddi1 || (line `any' `any' in 1/1,  lcolor(blue) lpattern(dash) ) ;
local graddi1 `graddi1' ||(line `any' `any' in 1/1,  lcolor(red) lpattern(dash) ) ;
local graddi1 `graddi1', legend(order( 2 "Initial level of poverty headcount ratio (`rhc')" 3 "Required transfer to offset the change in poverty (`rtransp')")) ;
};
if (`transpa' >`max') {;
local rtransp = floor(`transpa'*1000)/1000;
 local nota "The equivalent transfer to offset the change in headcount = `rtransp'";
};

qui replace `res'  = `res' *100 ;

if (`dgra' == 1) {;
twoway
(
line `res'  `trans' in 1/101 , 
title(`mtitle')  
xtitle(`xtit')
ytitle(`r(gytitle)'  in (%)) 
`r(gstyle)' 
`ogr'
`graddi0'
note(`nota')
)
`graddi1'

;
};


return scalar  trans = `transpa';

cap drop impacto;
tempvar impacto;
if `typetr' == 1 qui gen `impacto' = `transpa'*`indicator'          ;
if `typetr' == 2 qui gen `impacto' = (`transpa'/`hsize')*`indicator'  ;


tempvar _fw1;
gen  `_fw1' = `_fw'*`indicator' ;
qui sum `impacto'  [aw=`_fw'];
qui sum `impacto'  [aw=`_fw'];
return scalar  ctrans =`r(mean)' ; 
return scalar  ttrans =`r(sum)'; 



end;







