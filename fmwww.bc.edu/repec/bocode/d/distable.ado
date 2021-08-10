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


#delim ;
cap program drop fractwo;
program define fractwo, rclass;
syntax anything, [ nlist(string) clen(int 16)];
quietly {;
local k = 1;
mac shift;
while "``k''" ~= "" {; 
local k = `k'+1;
};
};
tokenize `nlist';
local part2 = "";
local tmp = length("`1'");
local pos=1;
while (`tmp'<`clen' & `pos'<=`k')  {;
local tt = length("``pos''");
local tmp = `tmp' + `tt' ;
local part1 = "`part1'"+" ``pos''";
local pos=`pos'+1;

};

if (`pos'<=`k' & `k'!=1) {;
forvalues i=`pos'/`k' {;
local part2 = "`part2'"+" ``i''";
};
};
return local part1  "`part1'" ;
return local part2  "`part2'" ;
end;



cap program drop distable;
program define distable;
version 9.2;
syntax namelist(min=1 max=1) [, MATRIX(string) DEC(int 3) DEC1(string) DEC2(string) DEC3(string) DEC4(string) DEC5(string) DEC6(string) FCLEN(int 16) CLEN(int 16) ATIT(string) HEAD1(string) HEAD2(string) dsmidl(int 0) ];
tempname table;
tokenize `namelist';	
local ncol = colsof(`1');
local nrow = rowsof(`1');
local ncol1 = `ncol'+1;	
.`table'  = ._tab.new, col(`ncol1');


forvalues i = 1/`nrow' {;
tempname TEMPORARY;
matrix `TEMPORARY'=`1'[`i'..`i',1..1];
local rnam`i': rownames `TEMPORARY';
local tt = length("`rnam`i''");
local fclen = max(`tt',`fclen');
};

local line3 .`table'.strcolor  yellow ;

local line5   ;
forvalues i = 1/`ncol' {;
local line3 `line3' yellow;
};	

local line5   ".`table'";
local line5 `line5'.titles;
local line55   ".`table'";
local line55 `line55'.titles;
local temp = "`atit' ";
local line5  `"`line5'  "`temp'" "' ;
local temp = "";
local line55  `"`line55'  "`temp'" "' ;
tempname mymat;
local ll=10;
forvalues i = 1/`ncol' {;
tokenize `namelist';
tempname TEMPORARY;
matrix `TEMPORARY'=`1'[1..1,`i'..`i'];
local cnam`i': colnames `TEMPORARY';
local rnam`i': rownames `TEMPORARY';
fractwo 16, nlist(`cnam`i'');
local line5  `"`line5'   "`r(part1)'" "' ;
local line55 `"`line55'  "`r(part2)'" "' ;
local l1= length("`r(part1)'");
local l2= length("`r(part2)'");
local hd2=`hd2'+`l2';
local clen`i' = max(16,max(`l1',`l2'));
};
local line4  .`table'.numfmt %-`fclen'.0g  ;
local line44 .`table'.strfmt %-16s  ;
forvalues i = 1/`ncol' {;
if "`dec`i''" ~="" local decef=`dec`i'';
if "`dec`i''" =="" local decef=`dec';
local line4 `line4' %16.`decef'f;
local line44 `line44' %-16s;
};

local line2 .`table'.width  | `fclen';
local line2 `line2' |;
forvalues i = 1/`ncol' {;
local line2 `line2'  `clen`i'' |;
};	


tokenize `namelist' ;
`line2'; 
`line3'; 
`line4'; 
`line44'; 	
if ("`head1'" ~= "" ) di _n as text "{col 4} `head1'";
if ("`head2'" ~= "" ) di _n as text "{col 4} `head2'";
.`table'.sep, top;
`line5'; 
if (`hd2'!=0) `line55'; 
.`table'.sep, mid;
forvalues i = 1/`nrow' {;
tempname TEMPORARY;
matrix `TEMPORARY'=`1'[`i'..`i',1..1];
local rnam`i': rownames `TEMPORARY';
local line6 .`table'.row "`rnam`i''" ;
if (`i'== 2 & `dsmidl' == 1) .`table'.sep, mid;
forvalues j = 1/`ncol' {;
local line6 `line6' el(`1',`i',`j');
};
if (`i'==`nrow') .`table'.sep, mid;
`line6'; 
};
.`table'.sep,bot;
 end;
 

