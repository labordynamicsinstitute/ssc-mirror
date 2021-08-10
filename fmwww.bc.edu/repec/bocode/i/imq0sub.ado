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
capture program drop imq0sub;
program define imq0sub, sortpreserve;
version 9.2;
syntax varlist(min=1 max=1)[ ,   IPSCH(string) HSIZE(varname) ];

tokenize `varlist';






/*************************/

cap drop `qvar' ;
tempname qvar;
qui gen `qvar' =0;

local nblock  =  `.`ipsch'.nblock'; 
local bun     =  `.`ipsch'.bun'; 

cap drop `bexp';
tempvar bexp;
if `bun'==1 qui gen `bexp' = `1'*`hsize';
if `bun'==2 qui gen `bexp' = `1';


local n1= `nblock' - 1; 
forvalues i = 1/`n1' {;
local mxb`i'   = `.`ipsch'.blk[`i'].max';
local tr`i'    = `.`ipsch'.blk[`i'].price';
};
local tr`nblock'   =  `.`ipsch'.blk[`nblock'].price';


local ex0=0;
local mxb0=0;
forvalues i=1/`nblock' {;
local j = `i' - 1;
local ex`i' = `ex`j''+ ( `mxb`i'' - `mxb`j'' ) *`tr`i'' ;
qui replace `qvar' = (((`bexp'-`ex`j'')/`tr`i'')+(`mxb`j''))*(`bexp'<=`ex`i'')*(`bexp'>`ex`j'') if (`bexp'<=`ex`i'') & (`bexp'>`ex`j'') & `bexp'!=.  ;
if `i' == `nblock'  {;
qui replace `qvar' = (((`bexp'-`ex`j'')/`tr`i'')+(`mxb`j''))*(`bexp'>`ex`j'') if (`bexp'>`ex`j'') & `bexp'!=.  ;
};
};

if `bun'==1  qui replace `qvar' = `qvar'/ `hsize' ;


cap drop __imq0sub;
qui gen  __imq0sub=`qvar';
end;
