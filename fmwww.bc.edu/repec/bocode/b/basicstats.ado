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

capture program drop basicstats;
program define  basicstats, rclass;
version 9.2;
syntax varlist  [, HSize(varname) HGroup(varname)  STAT(string) DENOM(varname)];
preserve;

tokenize `varlist';

tempvar _hs;

gen `_hs'=`hsize';

local hweight=""; 
cap qui svy: total `1'; 
local hweight=`"`e(wvar)'"';
cap ereturn clear; 

tempvar _num _denum _fw _w;

if "`stat'" == "" local stat = "exp_tt";
qui gen `_fw'=`_hs';
if (`"`hweight'"'~="") qui replace `_fw'=`_fw'*`hweight';

qui gen `_w'=1;
if (`"`hweight'"'~="") qui replace `_w'=`hweight';

if "`stat'" == "exp_tt" {;
forvalues i=1/$indig {;
tempvar _fwg;
local kk = gn1[`i'];
qui gen `_fwg'=`_fw'*(`hgroup'==`kk');
qui sum `1' [aw=`_fwg'];
return scalar est`i' =  r(sum);
};
qui sum  `1'  [aw=`_fw'] ;
local pe = $indig+1;
return scalar est`pe' =  r(sum);
};

if "`stat'" == "exp_pc" {;

forvalues i=1/$indig {;
tempvar _fwg;
local kk = gn1[`i'];
qui gen `_fwg'=`_fw'*(`hgroup'==`kk');
qui sum `1' [aw=`_fwg'];
return scalar est`i' =  r(mean);
};
qui sum  `1'  [aw=`_fw'] ;
local pe = $indig+1;
return scalar est`pe' =  r(mean);
};

if "`stat'" == "exp_hh" {;
tempvar var;
qui gen `var' = `1'*`_hs';
forvalues i=1/$indig {;
local kk = gn1[`i'];
tempvar _wg;
qui gen `_wg'=`_w'*(`hgroup'==`kk');
qui sum `var' [aw=`_wg'];
return scalar est`i' =  r(mean);
};
qui sum  `var'  [aw=`_w'] ;
local pe = $indig+1;
return scalar est`pe' =  r(mean);
};

if "`stat'" == "share_tot_pro" | "`stat'" == "share_tot_exp" {;


forvalues i=1/$indig {;
tempvar _fwg;
local kk = gn1[`i'];
qui gen `_fwg'=`_fw'*(`hgroup'==`kk');
qui sum `1'     [aw=`_fwg'];  local st1= r(sum);
qui sum `denom' [aw=`_fwg' ]; local st2= r(sum);
return scalar est`i' =  `st1' / `st2' *100;
local pe = $indig+1;
qui sum `1'     [aw=`_fw'];  local st1= r(sum);
qui sum `denom' [aw=`_fw' ]; local st2= r(sum);
return scalar est`pe' =  `st1' / `st2' *100;
};
};



restore;

end;
