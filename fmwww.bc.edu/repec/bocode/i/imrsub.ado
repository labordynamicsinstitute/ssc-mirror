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
capture program drop imrsub;
program define imrsub, sortpreserve;
version 9.2;
syntax varlist(min=1 max=1)[ ,   IPSCH(string) FPSCH(string) HSIZE(varname) APPR(int 1) ELAS(real 0) INF(real 0) ];

tokenize `varlist';


local issub = `.`ipsch'.issub'; 
local n1  =  `.`ipsch'.nblock'; 
local bun1  =  `.`ipsch'.bun'; 
local n2  =  `.`fpsch'.nblock'; 
local bun2  =  `.`fpsch'.bun'; 
local nn = `n1'+`n2';

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
local basev1=0;
forvalues i = 2/`nn' {;
local j  = `i'-1;
local se`i' = `se`j'' + (`q'[`i']-`q'[`i'-1])*`p1'[`i'];
};



local ex1= `q'[1]*`p1'[1];
forvalues i = 2/`nn' {;
local ex`i'= (`q'[`i']-`q'[`i'-1])*`p1'[`i'];
};


cap drop `bexp';
tempvar bexp;
if `bun1'==1 qui gen `bexp' = `1'*`hsize';
if `bun1'==2 qui gen `bexp' = `1';


tempvar class ;
qui gen `class' = 1;
if `nn1' > 1 {;
forvalues i = 2/`nn1' {;
local j=`i'-1;
 qui replace `class' = `i'  if (`bexp'>`se`j'' & `bexp'<=`se`i'') ;
};
};
if `nn1'>=1 qui replace `class' = `nn'         if (`bexp'>`se`nn1'')  ;


tempvar svar ;
qui gen `svar' = 0 ;



if (`issub'==0) {;

if (`appr' == 1) {;
qui replace `svar' = `bexp'*`dp1'*(1+`elas')                                                  if `class'==1; 
forvalues i = 2/`nn' {;
local k = `i'-1;
forvalues j = 1/`k' {;
qui replace `svar' = `svar' + `ex`j''*`dp`j''*(1+`elas')                                       if `class'==`i'; 
};
qui replace `svar' = `svar' + (`bexp'-`se`k'')*`dp`i''*(1+`elas')                             if `class'==`i'; 
};
};

if (`appr' == 2) {;
qui replace `svar' = `bexp'*`dp1'*(1+`elas'*(1+`dp1'))                                                   if `class'==1; 
forvalues i = 2/`nn' {;
local k = `i'-1;
forvalues j = 1/`k' {;
qui replace `svar' = `svar' + `ex`j''*`dp`j''*(1+`elas'*(1+`dp`j''))                                       if `class'==`i'; 
};
qui replace `svar' = `svar' + (`bexp'-`se`k'')*`dp`i''*(1+`elas'*(1+`dp`i''))                             if `class'==`i'; 
};
};

qui replace `svar' = - `svar';
};



if (`issub'==1) {;
if (`appr'==1) {;
qui replace `svar' = `bexp'*`dp1' + max(`elas'*`bexp'*`dp1' , -`bexp')*(`dp1'-`sb1')                                                               if `class'==1; 
forvalues i = 2/`nn' {;
local k = `i'-1;
forvalues j = 1/`k' {;
qui replace `svar' = `svar' +  `ex`j''*`dp`j'' + max(`elas'*`ex`j''*`dp`j'' , -`ex`j'')*(`dp`j''-`sb`j'')                                          if `class'==`i'; 
};
qui replace `svar' = `svar' + (`bexp'-`se`k'')*`dp`i'' + max(`elas'*(`bexp'-`se`k'')*`dp`i'' , -(`bexp'-`se`k''))*(`dp`i''-`sb`i'')                if `class'==`i'; 
};
};


if (`appr'==2 ) {;
qui replace `svar' = `bexp'*  ( (`sb1'-`dp1')*(1+`elas'*`dp1')- `sb1'  )                                             if `class'==1; 
forvalues i = 2/`nn' {;
local k = `i'-1;
forvalues j = 1/`k' {;
qui replace `svar' = `svar' + `ex`j''*  ( (`sb`j''-`dp`j'')*(1+`elas'*`dp`j'')*(1+`dp`j'')- `sb`j''  )                if `class'==`i'; 
};
qui replace `svar' = `svar' + (`bexp'-`se`k'')*( (`sb`i''-`dp`i'')*(1+`elas'*`dp`i'')*(1+`dp`i'')- `sb`i''  )        if `class'==`i'; 
};
};

};

if `bun1'==1 qui replace  `svar'= `svar'/`hsize';


qui replace `svar' = -`svar' /(1+`inf'/100.0000000000); 

cap drop __imrsub;
qui gen __imrsub=`svar';
end;
