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
capture program drop subjobgr4;
program define subjobgr4, rclass ;
version 9.2;
syntax varlist(min=1)[ ,  HSize(varname) PCEXP(varname) VIPSCH(varname) MIN(real 0) MAX(real 100) PLINE(varname) AGGRegate(string) XRNAMES(string) LAN(string) OGR(string) *];


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
tokenize `varlist';
_nargs    `varlist';

qui svyset ;
if ( "`r(settings)'"==", clear") qui svyset _n, vce(linearized); 
local hweight=""; 
cap qui svy: total `1'; 
local hweight=`"`e(wvar)'"';
cap ereturn clear;
tempvar fw;
qui gen `fw'=1;
if ("`hsize'"~="" )                            qui replace `fw' = `hsize';
if ("`hweight'"~="")                           qui replace `fw'=`fw'*`hweight';

tempvar p2;
qui sum `wvar'; 
tempvar hy ga1;
qui gen `hy' = `pcexp' ;
qui gen `ga1' = 0;
qui replace `ga1' = (`pline'>`hy');
qui sum `ga1' [aweight= `fw'];
local fgt0 = r(mean)*100;


local step=(`max'-`min')/100;

cap drop `tlist';
forvalues g=1/`nit' {;
local nva   =  ""+`1'[`g'];
local tlist `tlist' `nva';
local ttlist `ttlist' _wvar_`nva';
};



tokenize `varlist';

forvalues r=1/`nl' {;
tempvar est_`r';
qui gen `est_`r'' = .;
local ylist `ylist' `est_`r'';
};

tempvar perc;
tempvar rev ran;
qui gen `perc'=. ;



qui count;
if r(N)<101 qui set obs 101;
forvalues v=1/101 {;
local pos = (`v'-1)*`step';
qui replace `perc' = `min'+`pos' in `v';

/****************/
cap drop `rev'; qui gen `rev' = .;
cap drop `ran'; qui gen `ran' = .;

forvalues z=1/`nit' {;
local nva   =  ""+`1'[`z'];
cap drop `q_`z'' ;
cap drop `p1_`z'';

tempvar q_`z' p1_`z' ;
local ipsch = ""+`vipsch'[`z'];
local nva   =  ""+`1'[`z'];

local n_`z'  =  `.`ipsch'.nblock'; 
local bun_`z'  =  `.`ipsch'.bun'; 
local n1_`z' = `n_`z'' - 1;
if r(N)<101 qui set obs 101;


cap drop `q_`z''; 
qui gen `q_`z'' = .;
cap drop `p1_`z''; 
qui gen `p1_`z'' = .;



qui count;
if r(N)<`n_`z'' qui set obs `n_`z'';
forvalues i = 1/`n_`z'' {;
qui replace `q_`z''    = `.`ipsch'.blk[`i'].max'       in `i' ;
qui replace `p1_`z''   = `.`ipsch'.blk[`i'].price'     in `i' ;
};

local se1_`z'=`q_`z''[1]*`p1_`z''[1];
forvalues i = 2/`n_`z'' {;
local j  = `i'-1;
local se`i'_`z' = `se`j'_`z'' + (`q_`z''[`i']-`q_`z''[`i'-1])*`p1_`z''[`i'];
};
cap drop `class_`z'';
cap drop `bexp_`z'';
tempvar class_`z'  bexp_`z';
qui gen `class_`z'' = 1;

cap drop `bexp_`z'';
tempvar bexp_`z';

if `bun_`z''==1  qui gen `bexp_`z'' = `nva'*`hsize';
if `bun_`z''==2  qui gen `bexp_`z'' = `nva';

if `n1_`z'' > 1 {;
forvalues i = 2/`n1_`z'' {;
local j=`i'-1;
 qui replace `class_`z'' = `i'  if (`bexp_`z''>`se`j'_`z'' & `bexp_`z''<=`se`i'_`z'') ;
};
};

if `n1_`z''>=1 qui replace `class_`z'' = `n_`z''         if (`bexp_`z''>`se`n1_`z''_`z'')  ;




/********************/





local nva   =  ""+`1'[`z'];

local basev1_`z'=0;
forvalues i = 2/`n_`z'' {;
local j  = `i'-1;
local j1 = `i'-2;
if `i'== 2 local base`i'_`z'=  - (`q_`z''[`j']  -           0)*(`p1_`z''[`j']*`pos'/100) ;
if `i'!= 2 local base`i'_`z'=  - (`q_`z''[`j']-`q_`z''[`j'-1])*(`p1_`z''[`j']*`pos'/100) ;
local basev`i'_`z'=`basev`j'_`z''+`base`i'_`z'';
};




cap drop `rev'; qui gen `rev' = .;
cap drop `ran'; qui gen `ran' = .;


cap drop _wvar_`nva';
qui gen _wvar_`nva' = 0 ;
qui replace _wvar_`nva' = -`bexp_`z''*(`pos'/100)                                                                  if `class_`z''==1; 
forvalues i = 2/`n_`z'' {;
local k = `i'-1;
forvalues j = 1/`k' {;
qui replace _wvar_`nva' = `basev`i''     - (`bexp_`z''-`se`j'_`z''     )*(`pos'/100)                               if (`class_`z''==`i');
};

qui replace _wvar_`nva' = `basev`n_`z''_`z'' - (`bexp_`z''-`se`n1_`z''_`z'')*(`pos'/100)                           if `class_`z''==`n_`z''; 

};

if `bun_`z''==1  qui replace _wvar_`nva' = _wvar_`nva' / `hsize';

}; 





// end big
*set trace on;

aggrvar `ttlist' , xrnames(`xrnames') aggregate(`aggregate');
local slist = r(slist);
local flist = r(flist);
local nl = `r(nl)'; 


tokenize `flist';
forvalues o=1/`nl' {;
cap drop `hy';
qui gen `hy' = `pcexp' + ``o''; 
cap drop `ga1';
gen `ga1' = 0;
qui replace `ga1' = (`pline'>`hy');
qui sum `ga1' [aweight= `fw'];
local res = r(mean)*100-`fgt0';
qui replace `est_`o'' = `res' in `v' ;
};

tokenize `varlist';

};



gropt 4 `lan' ;
line `ylist' `perc' in 1/101 ,
`glegend'
title(`r(gtitle)')  
xtitle(`r(gxtitle)')
ytitle(`r(gytitle)') 
`glegend'
`r(gstyle)' 
`ogr'
;

end;



