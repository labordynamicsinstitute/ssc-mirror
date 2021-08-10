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
capture program drop _nlargs;
program define _nlargs, rclass;
version 9.2;
syntax namelist  [, ];
quietly {;
tokenize `namelist';
local k = 1;
mac shift;
while "``k''" ~= "" {; 
local k = `k'+1;
};
};
global indica=`k';
end;



#delim ;


#delimit ;
capture program drop pschdes ;
program define pschdes , rclass;
version 9.2;
syntax namelist  [,  DGRA(int 0) SGRA(string) EGRA(string) *];



_get_gropts , graphopts(`options') ;
	local options `"`s(graphopts)'"';
preserve;
tokenize `namelist';
_nlargs `namelist';


forvalues t=1/$indica {;
local  nblock =  `.``t''.nblock' ;
qui count;
if r(N)<`nblock' qui set obs `nblock';
tempvar Variable tarif  subside;
qui gen `Variable'="";
qui gen `tarif' = 0;
qui gen `subside' = 0;
local pos = 1;
local mxb0 = 0;
forvalues i=1/`nblock' {;
local j= `i'-1;
local mxb`i' = `.``t''.blk[`i'].max' ;
qui replace `Variable' = " `mxb`j'' - `mxb`i'' " in `pos';
if `i'==`nblock' qui replace `Variable' = " `mxb`j'' and more " in `pos';
qui replace `tarif'   = `.``t''.blk[`i'].price' in `pos'  ;
qui replace `subside' = `.``t''.blk[`i'].subside' in `pos'  ;
local pos = `pos'+ 1;
};

	tempname table;
	.`table'  = ._tab.new, col(3);
	.`table'.width |30|20 20 |;
	.`table'.strcolor . . . ;
	.`table'.numcolor yellow yellow yellow  ;
	.`table'.numfmt %16.0g  %16.6f  %16.6f;
	 di _n as text "{col 4} Description of the price schedule:  ``t''";
    .`table'.sep, top;
    .`table'.titles "Block     " "Tariff      "  "Subside      "  ;
	.`table'.sep, mid;
	forvalues i=1/`nblock'{;
                                       .`table'.numcolor white yellow   yellow  ;
			                           .`table'.row `Variable'[`i'] `tarif'[`i'] `subside'[`i']   ; 
			                          
				           };
.`table'.sep,bot;

};

if (`dgra'==1) {;
local tmp=0;
local ttmp=0;

forvalues t=1/$indica {;
local  nblock =  `.``t''.nblock' ;
qui count;
if r(N)<`nblock' qui set obs `nblock';
tempvar Variable tarif maxbl ;
qui gen `Variable'="";
qui gen `tarif' = 0;
qui gen `maxbl' = 0;
local pos = 1;
local mxb0 = 0;
forvalues i=1/`nblock' {;
local j= `i'-1;
local mxb`i' = `.``t''.blk[`i'].max' ;
qui replace `Variable' = " `mxb`j'' - `mxb`i'' " in `pos';
if `i'==`nblock' qui replace `Variable' = " `mxb`j'' and more " in `pos';

qui replace `tarif' = `.``t''.blk[`i'].price' in `pos'  ;
qui replace `maxbl' = `.``t''.blk[`i'].max' in `pos'  ;
if `i'==`nblock' local tmp`t'  = (`.``t''.blk[`j'].max')*1.2 ;
if `i'==`nblock' local ttmp`t' = (`.``t''.blk[`i'].price') ;
if `i'==`nblock' qui replace `maxbl' = `tmp`t'' in `pos';
local pos = `pos'+ 1;

if `i'==`nblock' local tmp  = max(`tmp',`tmp`t'');
if `i'==`nblock' local ttmp = max(`ttmp',`ttmp`t'');
};





tempvar x`t' y`t';

qui gen `x`t'' = .;
qui gen `y`t'' = .;

qui replace `y`t'' = `maxbl'[1] in 1;
local pos  = 1;
local pos2 = 2;
local minobs = 2*`nblock';
qui count; if `r(N)'<`minobs' qui set obs `minobs';


forvalues i=1/`nblock' {;
qui replace `y`t'' = `tarif'[`i'] in `pos';
qui replace `x`t'' = `maxbl'[`i'] in `pos2';

local pos = `pos'  + 1;
local pos2 = `pos2'+ 1;
qui replace `y`t'' = `tarif'[`i'] in `pos';
if `i'!=`nblock' qui replace `x`t'' = `maxbl'[`i'] in `pos2';
local pos  = `pos'+ 1;
local pos2 = `pos2'+ 1;
};

qui replace `x`t'' = 0 in 1;


local cmd `cmd' line `y`t'' `x`t'' in 1/`minobs' || ;
local ps`t' = `pos2'-2; 
};

local ttmp = round(`ttmp'*1.2,0.01);

local tpas= `ttmp'/5;


local lgd legend(order( ;
forvalues t=1/$indica {;
 qui replace `x`t'' = `tmp' in `ps`t'';
 local aa `"`t' "``t''" "';
local lgd `lgd' `aa' ;
 
};


local lgd `lgd' )) ;

twoway  `cmd' , `lgd' 
plotregion(margin(zero))
graphregion(margin(medlarge))
title(Price schedules)
xtitle(Quantity)
ytitle(Tariff)
ylabel(0(`tpas')`ttmp')

`options'
;

if( "`sgra'" ~= "") {;
graph save `"`sgra'"', replace;
};

if( "`egra'" ~= "") {;
graph export `"`egra'"', replace;
};

};
end;


