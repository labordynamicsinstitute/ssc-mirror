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
capture program drop subjobgr5;
program define subjobgr5, rclass ;
version 9.2;
syntax varlist(min=1)[ ,  HSize(varname) PCEXP(varname) VIPSCH(varname)  IELAS(varname) INF(real 0) APPR(int 1) MIN(real 0) MAX(real 100) AGGRegate(string) XRNAMES(string) LAN(string) SCEN(string) NSCEN(int 1) OGR(string) ];

preserve;

local vlist;
local slist;
tokenize `varlist' ;
qui drop if `1'=="";
//sort `1';
qui count;
local nit=`r(N)';
forvalues i=1/`r(N)' {;
local tmp = ""+`1'[`i'];
if ("`1'"~="") {;
local vlist `vlist' `tmp';
};
};



qui aggrvar `vlist' , xrnames(`xrnames') aggregate(`aggregate');
local  slist = r(slist);
local nl = `r(nl)'; 


local glegend legend(order( ;
if ("`slist'"~="") {;
local xrna  "`slist'";
local xrna : subinstr local xrna " " ",", all ;
local xrna : subinstr local xrna "|" " ", all ;
local count : word count `xrna';
tokenize "`xrna'";
forvalues a = 1/`count' {;
	local `a': subinstr local `a' "," " ", all ;
	local glegend `"`glegend' `a' "``a''""';
	
};

};
local glegend `"`glegend' ))"';

restore;

preserve;
tokenize `varlist' ;
qui svyset ;
if ( "`r(settings)'"==", clear") qui svyset _n, vce(linearized); 
local hweight=""; 
cap qui svy: total `pcexp'; 
local hweight=`"`e(wvar)'"';
cap ereturn clear;
tempvar fw;
qui gen `fw'=1;
if ("`hsize'"~="" )         qui replace `fw' = `hsize';
if ("`hweight'"~="")                           qui replace `fw'=`fw'*`hweight';



local step=(`max'-`min')/100;


tempvar perc;
qui gen `perc'=. ;
tempvar q p1 p2 sub1 sub2 s rev ran;

forvalues z=1/`nit' {;

tempvar est_`z';
qui gen `est_`z'' = .;
local ylist `ylist' `est_`z'';

local ipsch  =  ""+`vipsch'[`z'];
local elas   =  `ielas'[`z']; if "`elas'"=="" local elas=0;
local nva   =  ""+`1'[`z'];
local issub = `.`ipsch'.issub'; 
local n     =  `.`ipsch'.nblock'; 
local bun     =  `.`ipsch'.bun'; 
local n1    = `n' - 1;

cap drop `q' ; qui gen `q' = .;
cap drop `p1' ; qui gen `p1' = .;
cap drop `p2' ; qui gen `p2' = .;
cap drop `sub1' ; qui gen `sub1' = .;
forvalues i = 1/`n' {;
qui replace `q'    = `.`ipsch'.blk[`i'].max'     in `i' ;
qui replace `p1'   = `.`ipsch'.blk[`i'].price'   in `i' ;
qui replace `sub1' = `.`ipsch'.blk[`i'].subside'   in `i' ;
};




local se1=`q'[1]*`p1'[1];
forvalues i = 2/`n' {;
local j  = `i'-1;
local se`i' = `se`j'' + (`q'[`i']-`q'[`i'-1])*`p1'[`i'];
};






tempvar svar ;
qui gen `svar' = 0 ;

cap drop `class';
cap drop `bexp_`z'';
tempvar bexp_`z';
if `bun'==1  qui gen `bexp_`z'' = `nva'*`hsize';
if `bun'==2  qui gen `bexp_`z'' = `nva';

tempvar class ;
qui gen `class' = 1;
if `n1' > 1 {;
forvalues i = 2/`n1' {;
local j=`i'-1;
 qui replace `class' = `i'  if (`bexp_`z''>`se`j'' & `bexp_`z''<=`se`i'') ;
};
};
if `n1'>=1 qui replace `class' = `n'         if (`bexp_`z''>`se`n1'')  ;



local ex1= `q'[1]*`p1'[1];
forvalues i = 2/`n' {;
local ex`i'= (`q'[`i']-`q'[`i'-1])*`p1'[`i'];
};



forvalues v=1/101 {;



local pos = (`v'-1)*`step';
qui replace `perc' = `min'+`pos' in `v';

cap drop p2; 
qui replace `p2' = `p1'*(1+`pos'/100);




forvalues i = 1/`n' {;
local dp`i' = (`p2'[`i']/`p1'[`i']-1) ;
local sb`i' = `sub1'[`i']/`p1'[`i']; // add valorem subsidy;
};



cap drop _svar_`nva';
qui gen _svar_`nva' = 0 ;
cap drop _sub_`nva';
qui gen _sub_`nva' = 0 ;


qui replace _sub_`nva'  = `bexp_`z''*`sb1'                                      if `class'==1; 

forvalues i = 2/`n' {;
local k = `i'-1;
forvalues j = 1/`k' {;
qui replace _sub_`nva'  = _sub_`nva'  + `ex`j''*`sb`j''                         if `class'==`i'; 
};
qui replace _sub_`nva'  = _sub_`nva'  + (`bexp_`z''-`se`k'')*`sb`i''            if `class'==`i'; 
};

qui replace _sub_`nva'  = - _sub_`nva' ;

if (`issub'==0) {;

if (`appr' == 1) {;
qui replace _svar_`nva'  = `bexp_`z''*`dp1'*(1+`elas')                                                  if `class'==1; 
forvalues i = 2/`n' {;
local k = `i'-1;
forvalues j = 1/`k' {;
qui replace _svar_`nva'  = _svar_`nva'  + `ex`j''*`dp`j''*(1+`elas')                                      if `class'==`i'; 
};
qui replace _svar_`nva'  = _svar_`nva'  + (`bexp_`z''-`se`k'')*`dp`i''*(1+`elas')                             if `class'==`i'; 
};
};

if (`appr' == 2) {;
qui replace _svar_`nva'  = `bexp_`z''*`dp1'*(1+`elas'*(1+`dp1'))                                                     if `class'==1; 
forvalues i = 2/`n' {;
local k = `i'-1;
forvalues j = 1/`k' {;
qui replace _svar_`nva'  = _svar_`nva'  + `ex`j''*`dp`j''*(1+`elas'*(1+`dp`j''))                                       if `class'==`i'; 
};
qui replace _svar_`nva'  = _svar_`nva'  + (`bexp_`z''-`se`k'')*`dp`i''*(1+`elas'*(1+`dp`i''))                             if `class'==`i'; 
};
};

qui replace _svar_`nva'  = - _svar_`nva' ;
};



if (`issub'==1) {;

if (`appr'==1) {;
qui replace _svar_`nva'  = `bexp_`z''*`dp1'*(`elas'*(`sb1'-`dp1')-1)                                                       if `class'==1; 
forvalues i = 2/`n' {;
local k = `i'-1;
forvalues j = 1/`k' {;
qui replace _svar_`nva'  = _svar_`nva'  + `ex`j''*`dp`j''*(`elas'*(`sb`j''-`dp`j'')-1)                                    if `class'==`i'; 
};
qui replace _svar_`nva'  = _svar_`nva'  + (`bexp_`z''-`se`k'')*`dp`i''*(`elas'*(`sb`i''-`dp`i'')-1)                              if `class'==`i'; 
};

};


if (`appr'==2 ) {;
qui replace _svar_`nva'  = `bexp_`z''*  ( (`sb1'-`dp1')*(1+`elas'*`dp1')- `sb1'  )                                         if `class'==1; 
forvalues i = 2/`n' {;
local k = `i'-1;
forvalues j = 1/`k' {;
qui replace _svar_`nva'  = _svar_`nva'  + `ex`j''*  ( (`sb`j''-`dp`j'')*(1+`elas'*`dp`j'')*(1+`dp`j'')- `sb`j''  )       if `class'==`i'; 
};
qui replace _svar_`nva'  = _svar_`nva'  + (`bexp_`z''-`se`k'')*( (`sb`i''-`dp`i'')*(1+`elas'*`dp`i'')*(1+`dp`i'')- `sb`i''  )        if `class'==`i'; 
};
};

};

if (`issub'==1) qui replace _svar_`nva' = max(_svar_`nva', _sub_`nva');

if `bun'==1    qui replace  _svar_`nva'= _svar_`nva'/`hsize';


qui sum  _svar_`nva' [aw=`fw'];


qui replace `est_`z'' = -`r(sum)'/(1+`inf'/100) in `v';
cap drop _svar_`nva';
}; 


 
};

aggrvar `ylist' , xrnames(`xrnames') aggregate(`aggregate');
local slist = r(slist);
local flist = r(flist);
local nl = `r(nl)'; 

gropt 5 `lan' ;
local mtitle `r(gtitle)';
if (`nscen'>1) local mtitle `mtitle' : Scenario `scen';
line `flist' `perc' in 1/101 ,
`glegend'
title(`mtitle')  
xtitle(`r(gxtitle)')
ytitle(`r(gytitle)') 
`glegend'
`r(gstyle)' 
`ogr'
;
end;








