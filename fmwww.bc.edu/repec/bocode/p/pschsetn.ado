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
capture program drop pschsetn ;
program define pschsetn , rclass;
version 9.2;
syntax namelist (min=1 max=1) [,   
NBLOCK(int 1)
MXB1(real 100)  MXB2(real 200) MXB3(real 300) MXB4(real 400) MXB5(real 500) 
MXB6(real 600)  MXB7(real 700) MXB8(real 800) MXB9(real 900) MXB10(real 1000)
TR1(real 1)     TR2(real 1)  TR3(real 1)  TR4(real 1)  TR5(real 1)  
TR6(real 1)     TR7(real 1)  TR8(real 1)  TR9(real 1)  TR10(real 1) 
SUB1(real 0)     SUB2(real 0)  SUB3(real 0)  SUB4(real 0)  SUB5(real 0)  
SUB6(real 0)     SUB7(real 0)  SUB8(real 0)  SUB9(real 0)  SUB10(real 0)
];


tokenize `namelist';
if ("`sub1'"=="0") local issub=0;
if ("`sub1'"~="0") local issub=1;
cap classutil drop .`1';	
.`1' = .pschedule.new `nblock' `issub';


local min1  = 0;
local max1  = `mxb1';

forvalues i=2/`nblock' {;
local j = `i' - 1;
local min`i'  = `mxb`j'' ;
local max`i'  = `mxb`i'' ;
if `i' == `nblock' local max`i'  = 10000*`mxb`j'' ;
};


forvalues i=1/`nblock' {;
cap classutil drop .block`i';
.block`i' = .block.new  `min`i'' `max`i'' `tr`i'' `sub`i'';
.`1'.blk[`i'] = .block`i';
};

end;




