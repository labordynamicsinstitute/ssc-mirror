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


#delimit;
capture program drop subjobgr1;
program define subjobgr1, eclass;
version 9.2;
syntax varlist(min=1)[, HSize(varname) HGroup(varname) LAN(string) XRNAMES(string) AGGRegate(string) PCEXP(varname) MIN(real 0) MAX(real 1000) OGR(string)  *];
aggrvar `varlist' , xrnames(`xrnames') aggregate(`aggregate');
local  slist = r(slist);
local  flist = r(flist);
local drlist = r(drlist);


tokenize `flist';
_nargs   `flist';

forvalues i=1/$indica {;
tempvar s_`i';
gen `s_`i''  = ``i'' / `pcexp';
local glist `glist' `s_`i'' ;
};



local glegend legend(order( ;
if ("`slist'"~="") {;
local xrna  "`slist'";
local xrna : subinstr local xrna " " ",", all ;
local xrna : subinstr local xrna "|" " ", all ;
local count : word count `xrna';
tokenize "`xrna'";
forvalues i = 1/`count' {;
	local `i': subinstr local `i' "," " ", all ;
	local glegend `"`glegend' `i' "``i''""';
	
};

};

local glegend `"`glegend' ))"';



gropt 1 `lan' ;
curvnpe `glist', xvar(`pcexp') hsize(`hsize') 
title(`r(gtitle)')  
xtitle(`r(gxtitle)')
ytitle(`r(gytitle)') 
`glegend'
`r(gstyle)' 
min(`min')
max(`max')
`ogr'

  ;
  
 
cap drop `glist';

end;


