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

cap program drop trex2;  
program define trex2, rclass ;    
version 9.2;         
syntax varlist (min=2 max=2) [, HSize(string) HWeight(varname) HGroup(varname)   GNumber(int -1) dste(int 0)];
preserve;
tokenize `varlist';
                     qui drop if `1'>=. ;
if ("`hsize'"!="")   qui drop if `hsize'>=.;
if ("`hweight'"!="") qui drop if `hweight'>=.;
if ("`hweight'"=="") {;
tempvar hweight;
qui gen `hweight'=1;
};
tempvar  hs;
tempvar  hs;
qui gen `hs'=1;
tempvar  hsp;
qui gen `hsp'=1;
if ("`hsize'" != "") qui replace `hs'=`hsize';
if ("`hsize'" != "") qui replace `hsp'=`hsize';
tempvar _in;
if ("`hgroup'" != "")  qui gen    `_in' = (`hgroup' == `gnumber');
if ("`hgroup'" != "")  qui replace `hs' = `hs' * `_in';


tempvar vec_a vec_b vec_c;
qui gen   `vec_a' = `hs'*`1';
qui gen   `vec_b' = `hs'*`2';    
qui gen   `vec_c' = `hs';    
           
qui svy: ratio `vec_a'/`vec_b';
cap drop matrix _aa;
matrix _aa=e(b);
local est  =  el(_aa,1,1);
matrix _vv=e(V);
local std= el(_vv,1,1)^0.5;  

if (`dste'==0) {;
qui sum `vec_a' [aw=`hweight'] ,  meanonly; local m1=r(mean);
qui sum `vec_b' [aw=`hweight'] ,   meanonly; local m2=r(mean);
qui sum `hs'    [aw=`hweight'] ,      meanonly; local m3=r(mean);
qui sum `hsp'   [aw=`hweight'] ,     meanonly; local m4=r(mean);   
return scalar est1  = `m1'/`m3';
return scalar est2  = `m2'/`m3';
return scalar est3  = `m3'/`m4'*100;
};

if (`dste'==1) {;
              
qui  svy: ratio `vec_a'/`hs';
cap drop matrix _aa;
matrix _aa=e(b);
local est  =  el(_aa,1,1);
matrix _vv=e(V);
local ste= el(_vv,1,1)^0.5;  
return scalar est1  = `est';
return scalar ste1  = `ste';

qui  svy: ratio `vec_b'/`hs';
cap drop matrix _aa;
matrix _aa=e(b);
local est  =  el(_aa,1,1);
matrix _vv=e(V);
local ste= el(_vv,1,1)^0.5;  
return scalar est2  = `est';
return scalar ste2  = `ste';

qui  svy: ratio `hs'/`hsp';
cap drop matrix _aa;
matrix _aa=e(b);
local est  =  el(_aa,1,1);
matrix _vv=e(V);
local ste= el(_vv,1,1)^0.5;  
return scalar est3  = `est'*100;
return scalar ste3  = `ste'*100;

};

end;     









  

#delimit ;
capture program drop trexqua;
program define trexqua, rclass;
version 9.2;
syntax varlist(min=2)[ ,  
HSize(varname)
HGroup(varname)
PSCH(string)
RESULT(string)
 DSTE(int 0)  DGRA(int 0) NAME(string) dec(int 3)
];

if ("`psch'"=="") {;
        di in r "The schedule price must be indicated: option psch(...).";
	  exit 198;
exit;
};

local ll = 20;

qui svyset ;
tokenize `varlist';
if ( "`r(settings)'"==", clear") qui svyset _n, vce(linearized);
global indicag=0;
local hweight=""; 
cap qui svy: total `1'; 
local hweight=`"`e(wvar)'"';
cap ereturn clear; 
if "`name'" == "" local name = "_quantity";
if ("`result'"=="") local result = "hh";
cap drop `name';
qui gen `name' = . ;
tempvar key;
qui gen `key' = .;
local mxb0 = 0;
local ex0  = 0;





local nblock  =  `.`psch'.nblock'; 
local n1= `nblock' - 1; 
forvalues i = 1/`n1' {;
local mxb`i'   = `.`psch'.blk[`i'].max';
local tr`i'    = `.`psch'.blk[`i'].price';

};

local tr`nblock'   =  `.`psch'.blk[`nblock'].price';


local ex0=0;
local mxb0=0;
forvalues i=1/`nblock' {;
local j = `i' - 1;
local ex`i' = `ex`j''+ ( `mxb`i'' - `mxb`j'' ) *`tr`i'' ;
qui replace `name' = (((`1'-`ex`j'')/`tr`i'')+(`mxb`j''))*(`1'<=`ex`i'')*(`1'>`ex`j'') if (`1'<=`ex`i'') & (`1'>`ex`j'') & `1'!=.  ;
qui replace `key' = `i'  if (`1'<=`ex`i'') & (`1'>`ex`j'') & `1'!=.  ;
if `i' == `nblock'  {;
qui replace `name' = (((`1'-`ex`j'')/`tr`i'')+(`mxb`j''))*(`1'>`ex`j'') if (`1'>`ex`j'') & `1'!=.  ;
qui replace `key' = `i'  if  (`1'>`ex`j'') & `1'!=.  ;
};

};

//set trace on;

tempvar Variable eme1 eme2 epr  ;
tempvar Variable seme1 seme2 sepr  ;
qui gen `Variable'="";

qui gen `eme1'=0;
qui gen `eme2'=0;
qui gen `epr'=0;

qui gen `seme1'=0;
qui gen `seme2'=0;
qui gen `sepr'=0;

tempvar hsz v1 v2;
qui gen `hsz' = 1;
qui gen `v1' = `1';
qui gen `v2' = `name';

 if ("`result'"=="per") {;
 qui replace `hsz' =  `hsize';
 qui replace `v1' =  `v1'/`hsize';
 qui replace `v2' =  `v2'/`hsize';
 };



local k1=(`nblock'+1);
local pos = 1;

if ("`hgroup'"=="") {;
forvalues i=1/`nblock' {;
local j= `i'-1;
qui replace `Variable' = " `mxb`j'' - `mxb`i'' " in `pos';
if `i'==`nblock' qui replace `Variable' = " `mxb`j'' and more " in `pos';
trex2 `v1' `v2' , hweight(`hweight')   hsize(`hsz') hgroup(`key') gnumber(`i') dste(`dste');
qui replace `eme1' = r(est1) in `pos'  ;
qui replace `eme2' = r(est2) in `pos'  ;
qui replace `epr' =  r(est3) in `pos'  ;
if (`dste'==1) {;
qui replace `seme1' = r(ste1) in `pos'  ;
qui replace `seme2' = r(ste2) in `pos'  ;
qui replace `sepr' =  r(ste3) in `pos'  ;
};
local pos = `pos'+ 1;
};

};

if ("`hgroup'"!="") {;

preserve;
capture {;
local lvgroup:value label `hgroup';
if ("`lvgroup'"!="") {;
uselabel `lvgroup' , clear;
qui count;
forvalues i=1/`r(N)' {;
local tem=value[`i'];
local grlab`tem' = label[`i'];
};
};
};
restore;
cap drop gn1;
qui tabulate `hgroup', matrow(gn);
svmat int gn;
global indica=r(r);


forvalues i=1/$indica {;

local kk = gn1[`i'];
if ( "`grlab`kk''" == "") local grlab`kk' = "Group_`kk'";
qui replace `Variable' = "`kk': `grlab`kk''" in `pos';
local ll=max(`ll',length("`kk': `grlab`kk''"));
trex2 `v1' `v2' , hweight(`hweight')   hsize(`hsz') hgroup(`hgroup') gnumber(`kk') dste(`dste');
qui replace `eme1' = r(est1) in `pos'  ;
qui replace `eme2' = r(est2) in `pos'  ;
qui replace `epr' =  r(est3) in `pos'  ;
if (`dste'==1) {;
qui replace `seme1' = r(ste1) in `pos'  ;
qui replace `seme2' = r(ste2) in `pos'  ;
qui replace `sepr' =  r(ste3) in `pos'  ;
};
local pos = `pos'+ 1;
};

};


trex2 `v1' `v2' ,  hweight(`hweight') hsize(`hsz')  dste(`dste');
qui replace `Variable' = " All  " in `pos';
qui replace `eme1' = r(est1) in `pos'  ;
qui replace `eme2' = r(est2) in `pos'  ;
qui replace `epr' =  r(est3) in `pos'  ;
if (`dste'==1) {;
qui replace `seme1' = r(ste1) in `pos'  ;
qui replace `seme2' = r(ste2) in `pos'  ;
qui replace `sepr' =  r(ste3) in `pos'  ;
local pos = `pos'+ 1;
};

                    local length = `nblock';
if ("`hgroup'"!="") local length = $indica;
local length1 = `length'+1;


	tempname table;
	.`table'  = ._tab.new, col(4);
	.`table'.width |20|20 20 20|;
	.`table'.strcolor . . yellow .  ;
	.`table'.numcolor yellow yellow . yellow;
	.`table'.numfmt %16.0g  %16.`dec'f  %16.`dec'f %16.`dec'f ;
	di _n as text "{col 4} Price schedule and household consumption";
       if ("`hsize'"!="" &  "`result'"=="per")   di as text     "{col 5}Household size  :  `hsize'";
       if ("`hweight'"!="") di as text     "{col 5}Sampling weight :  `hweight'";
	   if ("`hgroup'"!="")  di as text     "{col 5}Group variable  :  `hgroup'";
     
	.`table'.sep, top;
	if ("`result'"=="hh" | "`result'"=="") {;
	.`table'.titles "Population groups" "Average household"   "Average consumed "  "  Proporion of     " ;
	.`table'.titles "                 " "  expenditures   "   "    quantities     "  "households (in %) " ;
	};
	
  if ("`result'"=="per") {;
	.`table'.titles "Population groups   " "Average per capita"   " Average per capita  "  "  Proporion of     " ;
	.`table'.titles "                    " "  expenditures   "    "consumed quantities"  "  population (in %)" ;
	};
	.`table'.sep, mid;
	
	forvalues i=1/`length'{;
                                       .`table'.numcolor white yellow yellow yellow  ;
             
			                           .`table'.row `Variable'[`i'] `eme1'[`i']  `eme2'[`i'] `epr'[`i'] ; 
			                           
		     if (`dste'==1 )    {; 
				                   .`table'.numcolor white green   green  green ;
			                       .`table'.row " "    `seme1'[`i']  `seme2'[`i'] `sepr'[`i'] ;        
                };
				};
.`table'.sep, mid;
.`table'.numcolor white yellow yellow yellow;
.`table'.row `Variable'[`length1'] `eme1'[`length1']  `eme2'[`length1'] `epr'[`length1'] ;
if (`dste'==1){;
.`table'.numcolor white green   green  green ;
.`table'.row  " "   `seme1'[`length1']  `seme2'[`length1'] `sepr'[`length1'] ;
};


.`table'.sep,bot;

if "`result'"=="hh"    local tita = "households (in %)";
if "`result'"=="per"   local tita = "population (in %)";
if "`result'"=="hh"    local titd = "household";
if "`result'"=="per"   local titd = "per capita";

if (`dgra'==1 )    {; 
tempvar group;
if ("`hgroup'"=="") qui gen `group' = _n in 1/`length';
if ("`hgroup'"!="") qui gen `group' =  gn1 in 1/`length'; 
forvalues i=1/`length' {;
local aa = ""+`Variable'[`i'];
label define _lgr  `i' "`aa'" , modify ;
};
lab val `group' _lgr;
preserve;
tempname gr1 gr2 gr3;
qui keep in 1/`length';
qui graph hbar (asis)    `epr', over(`group')
title(Proportion of `tita', size(medlarge) )  name(`gr1') nodraw;
qui graph hbar (asis)    `eme1', over(`group')
title(Average `titd' expenditures, size(medlarge))  name(`gr2') nodraw;
qui graph hbar (asis)    `eme2', over(`group')
title(Average `titd' consumed quantities,size(medlarge))  name(`gr3') nodraw;
graph combine  `gr1' `gr2' `gr3', cols(2); 
restore;
};

end;



