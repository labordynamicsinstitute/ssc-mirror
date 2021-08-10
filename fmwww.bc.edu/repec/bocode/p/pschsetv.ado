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
capture program drop pschsetv ;
program define pschsetv , rclass;
version 9.2;
syntax namelist (min=1 max=1) [,   NBLOCK(int 1) MXB(varname)  TR(varname) SUB(varname)   * ];

tokenize `namelist';
cap classutil drop .`1';	
if ("`sub'"=="") local issub=0;
if ("`sub'"~="") local issub=1;
cap classutil drop .`1';  
      
.`1' = .pschedule.new `nblock' `issub';

local min1  = 0;
local max1  = `mxb'[1];

forvalues i=2/`nblock' {;
local j = `i' - 1;
local min`i'  = `mxb'[`j'] ;
local max`i'  = `mxb'[`i'] ;
if `i' == `nblock' local max`i'  = 10000*`mxb'[`j'] ;
};


forvalues i=1/`nblock' {;
cap classutil drop .block`i';
.block`i' = .block.new  `min`i'' `max`i'' `tr'[`i'] `sub'[`i'];
.`1'.blk[`i'] = .block`i';
};

end;

