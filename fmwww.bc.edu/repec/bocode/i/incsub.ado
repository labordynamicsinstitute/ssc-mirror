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
capture program drop incsub;
program define incsub, rclass ;
version 9.2;
syntax varlist(min=1 max=1)[ ,   IPSCH(string) hsize(varname)];

local n    =  `.`ipsch'.nblock'; 
local bun  =  `.`ipsch'.bun'; 
local n1 = `n' - 1;
if r(N)<`n' qui set obs `n';
tempvar q p1 sub1 s rev ran;
qui gen `q' = .;
qui gen `p1' = .;
qui gen `sub1' = .;
qui gen `rev' = .;
qui gen `ran' = .;

qui count;

forvalues i = 1/`n' {;
qui replace `q'    = `.`ipsch'.blk[`i'].max'       in `i' ;
qui replace `p1'   = `.`ipsch'.blk[`i'].price'     in `i' ;
qui replace `sub1' = `.`ipsch'.blk[`i'].subside'   in `i' ;
};

//list `q' `p1' `sub1' in 1/`n';


forvalues i = 1/`n' {;
local sb`i' = `sub1'[`i']/`p1'[`i'];
};


local se1=`q'[1]*`p1'[1];
local basev1=0;
forvalues i = 2/`n' {;
local j  = `i'-1;
local se`i' = `se`j'' + (`q'[`i']-`q'[`i'-1])*`p1'[`i'];
};


local ex1= `q'[1]*`p1'[1];
forvalues i = 2/`n' {;
local ex`i'= (`q'[`i']-`q'[`i'-1])*`p1'[`i'];
};

tempvar bexp;
if `bun'==1 qui gen `bexp' = `1'*`hsize';
if `bun'==2 qui gen `bexp' = `1';

tempvar class ;
qui gen `class' = 1;
if `n1' > 1 {;
forvalues i = 2/`n1' {;
local j=`i'-1;
 qui replace `class' = `i'  if (`bexp'>`se`j'' & `bexp'<=`se`i'') ;
};

};

if `n' >= 2 qui replace `class' = `n'         if (`bexp'>`se`n1'')  ;

tempvar svar ;
qui gen `svar' = 0 ;


qui replace `svar' = `bexp'*`sb1'                                                      if `class'==1; 
forvalues i = 2/`n' {;
local k = `i'-1;
forvalues j = 1/`k' {;
qui replace `svar' = `svar' + `ex`j''*`sb`j''							              if `class'==`i'; 
};
qui replace `svar' = `svar' + (`bexp'-`se`k'')*`sb`i''                                if `class'==`i'; 
};

 
cap drop __esub;

if `bun'==1   qui gen  __esub=`svar' / `hsize';
if `bun'==2   qui gen  __esub=`svar';
end;
