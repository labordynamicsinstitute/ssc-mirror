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
capture program drop subjobgr6;
program define subjobgr6, rclass ;
version 9.2;
syntax varlist(min=1)[ ,  HSize(varname) PCEXP(varname) VIPSCH(varname)  VFPSCH(varname)  INF(real 0) APPR(int 1) MIN(real -1) MAX(real 0) AGGRegate(string) XRNAMES(string) LAN(string) SCEN(string) NSCEN(int 1) OGR(string) ];

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
local fpsch  =  ""+`vfpsch'[`z'];
local nva   =  ""+`1'[`z'];



local issub =  `.`ipsch'.issub';
local n1    =  `.`ipsch'.nblock'; 
local bun  =  `.`ipsch'.bun'; 
local n2    =  `.`fpsch'.nblock'; 
local nn    = `n1'+`n2';

if `n1' > 1 local lq1 = `.`ipsch'.blk[`n1'-1].max'; 
if `n2' > 1 local lq2 = `.`fpsch'.blk[`n2'-1].max'; 

if `n1' == 1 local lq1 = `.`ipsch'.blk[`n1'].max'; 
if `n2' == 1 local lq2 = `.`fpsch'.blk[`n2'].max'; 

local mq = max(`lq1',`lq2')*100;
qui count;
local nn1 = `nn'-1;
local nn2 = `nn'-2;
if r(N)<`nn' qui set obs `nn';
tempvar q p1 p2 s sub1 sub2;
qui gen `q' = .;
qui gen `p1' = .;
qui gen `p2' = .;
qui gen `s' = .;
qui gen `sub1' = .;
qui gen `sub2' = .;

forvalues i = 1/`n1' {;
if `i'!=`n1' qui replace `q'  = `.`ipsch'.blk[`i'].max'       in `i' ;
if `i'==`n1' qui replace `q'  = `mq'                          in `i' ;
             qui replace `p1' = `.`ipsch'.blk[`i'].price'     in `i' ;
             qui replace `s' = 1                              in `i' ;
             qui replace `sub1' = `.`ipsch'.blk[`i'].subside'  in `i' ;
};


forvalues i = 1/`n2' {;
local j=`i'+`n1';
if `i'!=`n2' qui replace `q'  = `.`fpsch'.blk[`i'].max'   in `j' ;
if `i'==`n2' qui replace `q'  = `mq'                      in `j' ;
             qui replace `p2'   = `.`fpsch'.blk[`i'].price' in `j';
             qui replace `s'  = 2                         in `j' ;
             qui replace `sub2' = `.`fpsch'.blk[`i'].subside'  in `j' ;
};


preserve;
tempvar pp1 pp2 ss1 ss2;
qui keep in 1/`nn';
qui by `q', sort : egen  `pp1' = mean(`p1');
qui by `q', sort : egen  `pp2' = mean(`p2') ;
qui by `q', sort : egen  `ss1' = mean(`sub1') ;
qui by `q', sort : egen  `ss2' = mean(`sub2') ;


cap drop __q;
qui gen __q=`q';
collapse (mean) `pp1' `pp2' `ss1' `ss2', by(__q);

qui count;
local nn = `r(N)';

forvalues i=1/`nn' {;
local q`i' = __q[`i'];
local p1`i'  = `pp1'[`i'];
local sub1`i' = `ss1'[`i'];
local p2`i'  = `pp2'[`i'];
local sub2`i' = `ss2'[`i'];
};

restore; 

cap drop `q' `p1' `p2' `sub1' `sub2';
tempvar q p1 p2 sub1 sub2;
qui gen `q' = .;
qui gen `p1' = .;
qui gen `p2' = .;
qui gen `sub1' = .;
qui gen `sub2' = .;

forvalues i=1/`nn' {;

qui replace `q'  = `q`i''  in `i';
qui replace `p1' = `p1`i'' in `i';
qui replace `p2' = `p2`i'' in `i';
qui replace `sub1' = `sub1`i'' in `i';
qui replace `sub2' = `sub2`i'' in `i';
};




local nn1=`nn'-1;
local nn2=`nn'-2;

qui sort `q'  in 1/`nn';



forvalues i = 1/`nn' {;
local i1=`i'-1;
if   (`p1'[`i']==. ) {;
local h1=`i';
while `p1'[`h1']==. & `h1' <=`nn' {;
local h1 =`h1'+1 ;
};
qui replace `p1'=`p1'[`h1'] in `i';
qui replace `sub1'=`sub1'[`h1'] in `i';
local h1=`h1'-1;
};
};


forvalues i = 1/`nn' {;
if   (`p2'[`i']==. ) {;
local h2=`i';
while `p2'[`h2']==. & `h2' <=`nn' {;
local h2 =`h2'+1 ;
};
qui replace `p2'  =  `p2'[`h2'] in `i';
qui replace `sub2'=`sub2'[`h2'] in `i';
local h2=`h2'-1;
};
};






forvalues i = 1/`nn' {;
local dp`i' = (`p2'[`i']/`p1'[`i']-1) ;
local sb`i' = `sub1'[`i']/`p1'[`i']; // add valorem subsidy

};



local se1=`q'[1]*`p1'[1];
forvalues i = 2/`nn' {;
local j  = `i'-1;
local se`i' = `se`j'' + (`q'[`i']-`q'[`i'-1])*`p1'[`i'];
};



local ex1= `q'[1]*`p1'[1];
forvalues i = 2/`nn' {;
local ex`i'= (`q'[`i']-`q'[`i'-1])*`p1'[`i'];
};


cap drop `bexp_`z'';
tempvar bexp_`z';
if `bun'==1  qui gen `bexp_`z'' = `nva'*`hsize';
if `bun'==2  qui gen `bexp_`z'' = `nva';
tempvar class ;
qui gen `class' = 1;
if `nn1' > 1 {;
forvalues i = 2/`nn1' {;
local j=`i'-1;
 qui replace `class' = `i'  if (`bexp_`z''>`se`j'' & `bexp_`z''<=`se`i'') ;
};
};
if `nn1'>=1 qui replace `class' = `nn'         if (`bexp_`z''>`se`nn1'')  ;


local ex1= `q'[1]*`p1'[1];
forvalues i = 2/`nn' {;
local ex`i'= (`q'[`i']-`q'[`i'-1])*`p1'[`i'];
};


forvalues v=1/101 {;



local pos = (`v'-1)*`step';
qui replace `perc' = `min'+`pos' in `v';

local elas = `min'+`pos';

forvalues i = 1/`nn' {;
local dp`i' = (`p2'[`i']/`p1'[`i']-1) ;
local sb`i' = `sub1'[`i']/`p1'[`i']; // add valorem subsidy;
};



cap drop _svar_`nva';
qui gen _svar_`nva' = 0 ;


if (`issub'==0) {;

if (`appr' == 1) {;
qui replace _svar_`nva'  = `bexp_`z''*`dp1'*(1+`elas')                                                  if `class'==1; 
forvalues i = 2/`nn' {;
local k = `i'-1;
forvalues j = 1/`k' {;
qui replace _svar_`nva'  = _svar_`nva'  + `ex`j''*`dp`j''*(1+`elas')                                      if `class'==`i'; 
};
qui replace _svar_`nva'  = _svar_`nva'  + (`bexp_`z''-`se`k'')*`dp`i''*(1+`elas')                             if `class'==`i'; 
};
};

if (`appr' == 2) {;
qui replace _svar_`nva'  = `bexp_`z''*`dp1'*(1+`elas'*(1+`dp1'))                                                     if `class'==1; 
forvalues i = 2/`nn' {;
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
forvalues i = 2/`nn' {;
local k = `i'-1;
forvalues j = 1/`k' {;
qui replace _svar_`nva'  = _svar_`nva'  + `ex`j''*`dp`j''*(`elas'*(`sb`j''-`dp`j'')-1)                                    if `class'==`i'; 
};
qui replace _svar_`nva'  = _svar_`nva'  + (`bexp_`z''-`se`k'')*`dp`i''*(`elas'*(`sb`i''-`dp`i'')-1)                              if `class'==`i'; 
};

};


if (`appr'==2 ) {;
qui replace _svar_`nva'  = `bexp_`z''*  ( (`sb1'-`dp1')*(1+`elas'*`dp1')- `sb1'  )                                         if `class'==1; 
forvalues i = 2/`nn' {;
local k = `i'-1;
forvalues j = 1/`k' {;
qui replace _svar_`nva'  = _svar_`nva'  + `ex`j''*  ( (`sb`j''-`dp`j'')*(1+`elas'*`dp`j'')*(1+`dp`j'')- `sb`j''  )       if `class'==`i'; 
};
qui replace _svar_`nva'  = _svar_`nva'  + (`bexp_`z''-`se`k'')*( (`sb`i''-`dp`i'')*(1+`elas'*`dp`i'')*(1+`dp`i'')- `sb`i''  )        if `class'==`i'; 
};
};

};

if `bun'==1 qui replace  _svar_`nva'= _svar_`nva'/`hsize';
qui sum  _svar_`nva' [aw=`fw'];
qui replace `est_`z'' = -`r(sum)'/(1+`inf'/100) in `v';
cap drop _svar_`nva';
}; 


 
};

aggrvar `ylist' , xrnames(`xrnames') aggregate(`aggregate');
local slist = r(slist);
local flist = r(flist);
local nl = `r(nl)'; 


gropt 6 `lan' ;
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








