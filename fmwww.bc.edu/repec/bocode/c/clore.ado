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


capture program drop lore2;
program define lore2, rclass;
version 9.2;
args www yyy rank type min max gr ng;
quietly {;
preserve;
if ("`gr'" ~="") qui keep if (`gr'==gn1[`ng']);
if ("`rank'" == "-1") sort `yyy';
if ("`rank'" ~= "-1") sort `rank';
cap drop if `yyy'>=.;
cap drop if `www'>=.;
if (_N<101) qui set obs 101;
cap drop _ww;
cap drop _wy;
cap drop _lp;
if ("`type'"=="abs") {;
qui sum `yyy' [aw=`www'];
qui replace `yyy' = `yyy' - `r(mean)';
};
gen _ww = sum(`www');
gen _wy = sum(`www'*`yyy');
local suma = _wy[_N];
cap drop _pc;
qui sum _ww;
gen _pc=_ww/r(max);
if ("`type'"~="gen" | "`type'"~="abs")  qui sum `yyy' [aw=`www'];
if ("`type'"=="gen" | "`type'"=="abs")  qui sum `www';
local suma = `suma'/`r(sum)';
gen _lp=_wy/r(sum);
cap drop _finlp;
gen _finlp=0;
local i = 1;
local step=(`max'-`min')/100;
local i = 1;
forvalues j=0/100 {;
local pcf=`min'+`j' *`step';
local av=`j'+1;
while (`pcf' > _pc[`i']) {;
local i=`i'+1;
};
local ar=`i'-1;
if (`i'> 1) local lpi=_lp[`ar']+((_lp[`i']-_lp[`ar'])/(_pc[`i']-_pc[`ar']))*(`pcf'-_pc[`ar']);
if (`i'==1) local lpi=0+((_lp[`i'])/(_pc[`i']))*(`pcf');
qui replace _finlp=`lpi' in `av';
};
qui keep in 1/101;
set matsize 101;
cap matrix drop _xx;
mkmat _finlp, matrix (_xx);
restore;
};
end;

capture program drop clore;
program define clore, rclass;
version 9.2;
syntax varlist(min=1)[, HWeight(varname) HSize(varname) HGroup(varname)
 RANK(varname) MIN(real 0) MAX(real 1) type(string) DIF(string)
 LRES(int 0)  SRES(string) DGRA(int 1) SGRA(string) EGRA(string) POP(string) *];

if (`min' < 0) {;
 di as err "min should be >=0"; exit;
};
if (`max' > 1) {;
 di as err "max should be <=1"; exit;
};

if (`max' <= `min') {;
 di as err "max should be greater than min"; exit;
};
if ("`dif'"=="no") local dif="";

_get_gropts , graphopts(`options') ;
	local options `"`s(graphopts)'"';
	
if ("`hgroup'"!="") {;
preserve;
capture {;
local lvgroup:value label `hgroup';
if ("`lvgroup'"!="") {;
uselabel `lvgroup' , replace;
qui count;
forvalues i=1/`r(N)' {;
local tem=value[`i'];
local grlab`tem' = label[`i'];
};
};
};
restore;
preserve;
qui tabulate `hgroup', matrow(gn);
svmat int gn;
global indica=r(r);
tokenize `varlist';
};
if ("`hgroup'"=="") {;
tokenize `varlist';
_nargs    `varlist';
preserve;
};


qui svyset ;
if ( "`r(settings)'"==", clear") qui svyset _n, vce(linearized);
local hweight=""; 
cap qui svy: total `1'; 
local hweight=`"`e(wvar)'"';
cap ereturn clear; 


local l45=$indica+1;
local _cory  = "";
local label = "";
if ("`dif'"=="" & "`type'"~="gen" & "`type'"~="abs") local legline =  "45° line";
local cl=1;
if ("`rank'"!=""){;
forvalues k = 1/$indica {;
 local cl = `cl'*("``k''"!="`rank'");
};
};
if (($indica==1|"`hgroup'"~="") & "`rank'"=="`1'") local cl=2;
quietly{; 

local tit1="Lorenz"; 
local tit2="L"; 
local tit3="";
local tit4="";
if ("`rank'"!="" & `cl'!=2) {;
local tit1="Concentration";
local tit2="C";
if (`cl'==0 & "`hgroup'"=="" )  local tit1="Lorenz and Concentration";
};
if ("`type'"=="gen") {;
local tit3="Generalised ";
local tit4="G";
};
if ("`type'"=="abs") {;
local tit4="A";
local tit3="Absolute ";
};
if ("`dif'"=="c1") {;
local tit0="Difference Between ";
};
local tit_s="";
if ($indica>1) local tit_s="s";
local ftitle = "`tit0'`tit3'"+"`tit1' Curve`tit_s'";
local ytitle = "`tit4'`tit2'(p)";
if (`cl'==0 & "`hgroup'"=="") local ytitle = "`tit4'L(p) & `tit4'C(p)";
if (("`dif'"=="ds") & ("`type'"~="gen") & ("`type'"~="abs")  & ("`group'"=="") ) {;
local ftitle = "Deficit share curve`tit_s'";
local ytitle = "p - `tit4'`tit2'(p)";
if (`cl'==0 & "`hgroup'"=="" )  local ytitle = "p - `tit4'L(p) & p - `tit4'C(p) ";
};
if ("`dif'"=="c1")        local ytitle ="Difference";
if ("`ctitle'"  ~="")     local ftitle ="`ctitle'";
tempvar fw;
gen `fw'=1;
if ("`hsize'"   ~="")     replace `fw'=`fw'*`hsize';
if ("`hweight'" ~="")     replace `fw'=`fw'*`hweight';
local xtitle = "Percentiles (p)";
if ("`cytitle'"  ~="") local ytitle ="`cytitle'";
if ("`cxtitle'"  ~="") local xtitle ="`cxtitle'";

qui count;
if (r(N)<101) set obs 101;

if ("`dif'"=="" & "`type'"~="gen" & "`type'"~="abs" ) local _cory = "`_cory'" + " _corx";

if ("`hgroup'"!="") {;
if ("`rank'"=="") local rank = -1;
if ("`type'"=="") local type = "no";
if ("`min'"=="")  local min  = 0;
if ("`max'"=="")  local max  = 1;
lore2 `fw' `1' `rank' `type' `min' `max' ;
svmat float _xx;
cap matrix drop _xx;
rename _xx1 _corypop;
if ("`dif'"~="c1" & "`pop'" != "no") {;
local _cory  = "`_cory'" + " _corypop";
local legendp = "Population";
};
if ("`dif'"=="c1") {;
gen _dct=_cory;
replace _corypop=0;
local _cory  = "`_cory'" + " _corypop";
};
if ("`dif'"=="ds") local legendp = "Population";
};



forvalues k = 1/$indica {;
local _cory  = "`_cory'" + " _cory`k'";
local f=`k';
if ("`dif'"=="c1" & "`hgroup'"=="")  local f =`k'-1;
if ("`rank'"=="") local rank = -1;
if ("`type'"=="") local type = "no";
if ("`min'"=="")  local min  = 0;
if ("`max'"=="")  local max  = 1;
if ("`hgroup'"=="") {;
local label`f'  =  "``k''";

local titd="L";
if ("``k''"=="`rank'" & "`rank'"!="-1" ) local titd="L";
if ("``k''"!="`rank'" & "`rank'"!="-1")  local titd="C";
local titd1="L";
if ("`1'"=="`rank'" & "`rank'"!="-1") local titd1="L";
if ("`1'"!="`rank'" & "`rank'"!="-1") local titd1="C";

if (("`dif'"=="ds") & ("`type'"~="gen") & ("`type'"~="abs")  & ("`group'"=="")) local comt="p-";
if ("`dif'"=="c1") local comt="-`tit4'`titd1'_`1'";
if (`cl'==0 ) local adtit="`comt'`tit4'`titd'(p):";
local label`f'  ="`adtit' ``k''";

if ("`dif'"=="c1")  local adtit="`comt'";
if ("`dif'"=="c1")  local label`f'  = "`tit4'`titd'_``k'' `adtit'";
lore2 `fw' ``k'' `rank' `type' `min' `max' ;

};
if ("`hgroup'"!="") {;
local kk = gn1[`k'];
local k1 = gn1[1];
local label`f'  : label (`hgroup') `kk';
local labelg1   : label (`hgroup') `k1';
if ( "`label1'"   == "")   local labelg1    = "Group: `k1'";
if ( "`label`f''" == "")   local label`f'   = "Group: `kk'";
local titd="L";
if ("`1'"!="`rank'" & "`rank'"!="-1") local titd="C";
if ("`dif'"=="c1") {;
local adtit="`tit4'`titd'_`label`f'' - `tit4'`titd'_Population";
local label`f'  ="`adtit'";
};
lore2 `fw' `1' `rank' `type' `min' `max' `hgroup' `k';
};
svmat float _xx;
cap matrix drop _xx;
rename _xx1 _cory`k';
};
local m5=(`max'-`min')/5;
local step=(`max'-`min')/100;
gen _corx = `min'+(_n-1)*`step';
qui keep in 1/101;
if (("`dif'"=="ds") & ("`type'"~="gen") & ("`type'"~="abs") ) {;
foreach var of varlist _cory* {;
if ("`dif'"=="ds")  qui replace `var' =  _corx - `var';
};
};
 }; // end of quietly 

 
if ("`dif'"=="c1" ) {;
if ("`hgroup'"=="")  {;
gen _dct=_cory1;
};
forvalues k = 1/$indica {;
qui replace _cory`k'=_cory`k'-_dct;
};
local legline  ="Null horizontal line";
};

local legend legend(nodraw);
if ("`legline'" ~="")  local lg1="label(1 `legline') ";
                       local j=1;
if ("`legline'" ~="")  local j=2;
if ("`legendp'" ~="" )  local lg`j'="label(`j' `legendp') ";



local j=0; 
if ("`legline'" ~="" | "`legendp'"~="") local j=1; 
if ("`legline'" ~="" & "`legendp'"~="" ) local j=2;

forvalues i=1/$indica {;
local k=`j'+`i';
local lg`k'="label(`k' `label`i'') ";
};
	
if( `lres' == 1) {;
set more off;
list _corx _cory*;
};
quietly {;
if (`dgra'!=0) {; 
line `_cory'  _corx, 
legend(
`lg1'  `lg2'  `lg3' `lg4' 
`lg5'  `lg6'  `lg7' `lg8' 
`lg9'  `lg10'  `lg11' `lg12'
)
title(`ftitle')
ytitle(`ytitle')
xtitle(`xtitle') 
xscale(range(`min' `max'))
xlabel(`min'(`m5')`max', labsize(small))
ylabel(, labsize(small))
plotregion(margin(zero))
legend(size(small))
`options'		
;
};
cap matrix drop _xx;
if( "`sres'" ~= "") {;
keep _corx _cory*;
save `"`sres'"', replace;
};

if( "`sgra'" ~= "") {;
graph save `"`sgra'"', replace;
};

if( "`egra'" ~= "") {;
graph export `"`egra'"', replace;
};


restore;
}; // end of quietly
end;
