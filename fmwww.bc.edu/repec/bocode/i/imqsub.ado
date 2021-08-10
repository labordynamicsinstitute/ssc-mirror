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
capture program drop imqsub;
program define imqsub, sortpreserve;
version 9.2;
syntax varlist(min=1 max=1)[ ,   IPSCH(string) FPSCH(string) HSIZE(varname) ELAS(real 0)];

tokenize `varlist';


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
tempvar q p1 p2 s;
qui gen `q' = .;
qui gen `p1' = .;
qui gen `p2' = .;
qui gen `s' = .;

forvalues i = 1/`n1' {;
if `i'!=`n1' qui replace `q'  = `.`ipsch'.blk[`i'].max'    in `i' ;
if `i'==`n1' qui replace `q'  = `mq'                   in `i' ;
             qui replace `p1' = `.`ipsch'.blk[`i'].price'  in `i' ;
             qui replace `s' = 1                       in `i' ;
};


forvalues i = 1/`n2' {;
local j=`i'+`n1';
if `i'!=`n2' qui replace `q'  = `.`fpsch'.blk[`i'].max'   in `j' ;
if `i'==`n2' qui replace `q'  = `mq'                  in `j' ;
             qui replace `p2' = `.`fpsch'.blk[`i'].price' in `j';
             qui replace `s'  = 2                     in `j' ;
};




preserve;
tempvar pp1 pp2;
qui keep in 1/`nn';
quietly {;
by `q', sort : egen  `pp1' = mean(`p1');
by `q', sort : egen  `pp2' = mean(`p2') ;
};

cap drop __q;
qui gen __q=`q';
collapse (mean) `pp1' `pp2', by(__q);

qui count;
local nn = `r(N)';

forvalues i=1/`nn' {;
local q`i' = __q[`i'];
local p1`i' = `pp1'[`i'];
local p2`i' = `pp2'[`i'];
};

restore; 

cap drop `q' `p1' `p2';
tempvar q p1 p2;
qui gen `q' = .;
qui gen `p1' = .;
qui gen `p2' = .;

forvalues i=1/`nn' {;

qui replace `q'  = `q`i''  in `i';
qui replace `p1' = `p1`i'' in `i';
qui replace `p2' = `p2`i'' in `i';
};




local nn1=`nn'-1;
local nn2=`nn'-2;

sort `q'  in 1/`nn';



*list `q' `p1' `p2' in 1/`nn' ;


forvalues i = 1/`nn' {;
local i1=`i'-1;
if   (`p1'[`i']==. ) {;
local h1=`i';
while `p1'[`h1']==. & `h1' <=`nn' {;
local h1 =`h1'+1 ;
};
qui replace `p1'=`p1'[`h1'] in `i';
local h1=`h1'-1;
};
};


forvalues i = 1/`nn' {;
if   (`p2'[`i']==. ) {;
local h2=`i';
while `p2'[`h2']==. & `h2' <=`nn' {;
local h2 =`h2'+1 ;
};
qui replace `p2'=`p2'[`h2'] in `i';
local h2=`h2'-1;
};
};


*list `q' `p1' `p2' in 1/`nn';


local se1=`q'[1]*`p1'[1];
local basev1=0;
forvalues i = 2/`nn' {;
local j  = `i'-1;
local j1 = `i'-2;
local se`i' = `se`j'' + (`q'[`i']-`q'[`i'-1])*`p1'[`i'];
if `i'== 2 local base`i'=  - (`q'[`j']  -       0)*(`p2'[`j']-`p1'[`j']);
if `i'!= 2 local base`i'=  - (`q'[`j']-`q'[`j'-1])*(`p2'[`j']-`p1'[`j']);
local basev`i'=`basev`j''+`base`i'';
};


local baseq1=0;
local sq1=`q'[1];
forvalues i = 2/`nn' {;
local j  = `i'-1;
local sq`i' = `sq`j'' + (`q'[`i']-`q'[`i'-1]);
if `i'== 2 local base`i'=   (`q'[`j']  -       0)*(`elas'*(`p2'[`j']/`p1'[`j']-1));
if `i'!= 2 local base`i'=   (`q'[`j']-`q'[`j'-1])*(`elas'*(`p2'[`j']/`p1'[`j']-1));
local baseq`i'=`baseq`j''+`base`i'';
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
if `nn1'>=1 qui replace `class' = `nn'                              if (`bexp'>`se`nn1'')  ;


tempvar hhq ;
qui gen `hhq' = 0 ;
qui replace `hhq' = `bexp'/`p1'[1]                                  if `class'==1; 
if `nn1' > 1 {;
forvalues i = 2/`nn1' {;
local j=`i'-1;
 qui replace `hhq' = `sq`j'' +   (`bexp'-`se`j'')/`p1'[`i']         if (`class'==`i') ;
};
};
if `nn1'>=1 qui replace  `hhq' = `sq`nn1'' + (`bexp'-`se`nn1'')/`p1'[`nn']                if (`class' == `nn')  ;



tempvar qvar ;
qui gen `qvar' = 0 ;
qui replace `qvar' = (`hhq')*(`elas'*(`p2'[1]/`p1'[1]-1))                                 if `class'==1; 
if `nn1' > 1 {;
forvalues i = 2/`nn1' {;
local j=`i'-1;
 qui replace `qvar' = `baseq`i'' + (`hhq'-`sq`j'')*(`elas'*(`p2'[`i']/`p1'[`i']-1))           if (`class'==`i') ;
};
};
if `nn1'>=1 qui replace  `qvar' = `baseq`nn'' + (`hhq'-`sq`nn1'')*(`elas'*(`p2'[`nn']/`p1'[`nn']-1))         if (`class' == `nn' )  ;


qui replace `qvar' = max(-`hhq', `qvar') ;

if `bun1'==1 qui replace `qvar' = `qvar'/ `hsize' ;


cap drop __imqsub;
qui gen  __imqsub=`qvar';
end;
