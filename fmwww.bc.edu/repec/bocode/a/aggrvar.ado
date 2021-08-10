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
capture program drop aggrvar;
program define aggrvar, rclass;
version 9.2;
syntax varlist(min=1)[,  XRNAMES(string) AGGRegate(string)];

if "`aggregate'"== ""{;
local flist `varlist' ;
local slist `xrnames' ;
};

if "`aggregate'"~= ""{;
tokenize  `varlist' ;
_nargs    `varlist' ;
forvalues i=1/$indica {;
local nvar`i' = "``i''";
local ldrop`i'=0;
};
local cnam;

if ("`aggregate'"~="") {;
local xrna1  "`aggregate'";
local xrna1 : subinstr local xrna1 " " ",", all ;
local xrna1 : subinstr local xrna1 "|" " ", all ;
local count1 : word count `xrna1';
tokenize "`xrna1'";
forvalues i = 1/`count1' {;
	tokenize "`xrna1'";
	local `i': subinstr local `i' "," " ", all ;	
	if ("``i''"~="") {;
	local xrna2  "``i''";	
	local xrna2 : subinstr local xrna2 " " ",", all ;
	local xrna2 : subinstr local xrna2 ":" " ", all ;
	local count2 : word count `xrna2';
	tokenize "`xrna2'";
	forvalues j = 1/`count2' {;
	local `j': subinstr local `j' "," " ", all ;
	if (`j' == 1) local varggr`i' = "``j''";
	if (`j' == 2) local narggr`i' = "``j''";
	};
};	
};
};


forvalues i = 1/`count1' {;
cap drop __nevar`i';
qui gen __nevar`i' = 0;
local drlist `drlist' __nevar`i';
tokenize `varggr`i'';
nargs `varggr`i'';
forvalues j = 1/`r(narg)' {;
qui replace  __nevar`i' =   __nevar`i'+ `nvar``j''';
local ldrop``j''=1;
};
local finlist = "`finlist'"+"  __nevar`i'" ;
local dlist `dlist' `varggr`i'' ;
};

tokenize `varlist';
local flist "";
forvalues i=1/$indica {;
if  `ldrop`i'' != 1 local flist `flist' ``i'' ;
};
forvalues i=1/`count1' {;
local flist `flist'  __nevar`i' ;
};

local cnam;
if ("`xrnames'"~="") {;
local xrna  "`xrnames'";
local xrna : subinstr local xrna " " ",", all ;
local xrna : subinstr local xrna "|" " ", all ;
local count : word count `xrna';
tokenize "`xrna'";
forvalues i = 1/`count' {;
local cnam`i': subinstr local `i' "," " ", all ;
};
};

local slist = "";
forvalues i=1/`count' {;
if (`i' == 1 & `ldrop`i'' != 1) local tmp2 =   ""+"`cnam`i''";
if (`i' != 1 & `ldrop`i'' != 1) local tmp2 = " |"+"`cnam`i''";
if ("`cnam`i'"~="" & `ldrop`i'' != 1) {;
local slist `slist' `tmp2';
};
};

forvalues i=1/`count1' {;
local slist `slist' | `narggr`i'' ;
};
};

return local slist =  "`slist'";
return local flist =  "`flist'";
return local drlist = "`drlist'";
nargs `flist' ;
return scalar nl = `r(narg)' ;
end;
