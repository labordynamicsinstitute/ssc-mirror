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
capture program drop imsref;
program define imsref, rclass sortpreserve;
version 9.2;
syntax varlist(min=2 max=2)[ ,  HSize(varname) HGroup(varname) IPSCH(string) FPSCH(string) ELAS(varname) INF(real 0) RESULT(string) DSTE(int 0)  DGRA(int 0) NAME(string) dec(int 3) 
];
local ll =20;
qui svyset ;
tokenize `varlist';
qui drop if `1'==. ; 
qui drop if `2'==. ;
tempvar ela;
qui gen `ela' = 0;
if ("`elas'" ~= "" ) qui replace `ela' = `elas';

if ("`result'"~="per") qui sort `1' , stable;;
tempvar pc_inc;
if ("`hsize'"~="")      gen      `pc_inc' = `1' / `hsize';
if ("`result'"=="per")  qui sort `pc_inc' , stable;;
local hweight=""; 
cap qui svy: total `1'; 
local hweight=`"`e(wvar)'"';
cap ereturn clear;
tempvar fw;
qui gen `fw'=1;
if ("`hsize'"~="" & "`result'"=="per")         qui replace `fw' = `hsize';
if ("`hweight'"~="")                           qui replace `fw'=`fw'*`hweight';


tempvar perc;
qui     gen `perc' =  sum(`fw');
qui replace `perc' = `perc'/`perc'[_N];

tempvar dec10;
gen `dec10' = . ;
local pas = 1/10;
local step1=0;
local step2=`pas';
forvalues i=1/10{;
qui replace `dec10'=`i' if ((`perc'>`step1') & (`perc'<=`step2'));
local step1=`step2';
local step2=`step1'+`pas';
local po = `i';
};
qui replace `dec10'=10 if `perc'>=1.0;

qui count;
qui replace `dec10'=10 in `r(N)';


local n1  =  `.`ipsch'.nblock'; 
local n2  =  `.`fpsch'.nblock'; 
local nn = `n1'+`n2';

if `n1' > 1 local lq1 = `.`ipsch'.blk[`n1'-1].max'; 
if `n2' > 1 local lq2 = `.`fpsch'.blk[`n2'-1].max'; 

if `n1' == 1 local lq1 = `.`ipsch'.blk[`n1'].max'; 
if `n2' == 1 local lq2 = `.`fpsch'.blk[`n2'].max'; 

local mq = max(`lq1',`lq2')*100;
qui count;
local nn1 = `nn'-1;
local nn2 = `nn'-2;
if r(N)<`nn' qui set obs `nn';
tempvar q p1 p2 s sub1 sub2;
qui gen `q' = .;
qui gen `p1' = .;
qui gen `p2' = .;
qui gen `s' = .;
qui gen `sub1' = .;
qui gen `sub2' = .;

forvalues i = 1/`n1' {;
if `i'!=`n1' qui replace `q'  = `.`ipsch'.blk[`i'].max'       in `i' ;
if `i'==`n1' qui replace `q'  = `mq'                          in `i' ;
             qui replace `p1' = `.`ipsch'.blk[`i'].price'     in `i' ;
             qui replace `s' = 1                              in `i' ;
             qui replace `sub1' = `.`ipsch'.blk[`i'].subside'  in `i' ;
};


forvalues i = 1/`n2' {;
local j=`i'+`n1';
if `i'!=`n2' qui replace `q'  = `.`fpsch'.blk[`i'].max'   in `j' ;
if `i'==`n2' qui replace `q'  = `mq'                      in `j' ;
             qui replace `p2'   = `.`fpsch'.blk[`i'].price' in `j';
             qui replace `s'  = 2                         in `j' ;
             qui replace `sub2' = `.`fpsch'.blk[`i'].subside'  in `j' ;
};





preserve;
tempvar pp1 pp2 ss1 ss2;
qui keep in 1/`nn';
qui by `q', sort : egen  `pp1' = mean(`p1');
qui by `q', sort : egen  `pp2' = mean(`p2') ;
qui by `q', sort : egen  `ss1' = mean(`sub1') ;
qui by `q', sort : egen  `ss2' = mean(`sub2') ;


cap drop __q;
qui gen __q=`q';
collapse (mean) `pp1' `pp2' `ss1' `ss2', by(__q);

qui count;
local nn = `r(N)';

forvalues i=1/`nn' {;
local q`i' = __q[`i'];
local p1`i'  = `pp1'[`i'];
local sub1`i' = `ss1'[`i'];
local p2`i'  = `pp2'[`i'];
local sub2`i' = `ss2'[`i'];
};

restore; 

cap drop `q' `p1' `p2' `sub1' `sub2';
tempvar q p1 p2 sub1 sub2;
qui gen `q' = .;
qui gen `p1' = .;
qui gen `p2' = .;
qui gen `sub1' = .;
qui gen `sub2' = .;

forvalues i=1/`nn' {;

qui replace `q'  = `q`i''  in `i';
qui replace `p1' = `p1`i'' in `i';
qui replace `p2' = `p2`i'' in `i';
qui replace `sub1' = `sub1`i'' in `i';
qui replace `sub2' = `sub2`i'' in `i';
};




local nn1=`nn'-1;
local nn2=`nn'-2;

qui sort `q'  in 1/`nn';



forvalues i = 1/`nn' {;
local i1=`i'-1;
if   (`p1'[`i']==. ) {;
local h1=`i';
while `p1'[`h1']==. & `h1' <=`nn' {;
local h1 =`h1'+1 ;
};
qui replace `p1'=`p1'[`h1'] in `i';
qui replace `sub1'=`sub1'[`h1'] in `i';
local h1=`h1'-1;
};
};


forvalues i = 1/`nn' {;
if   (`p2'[`i']==. ) {;
local h2=`i';
while `p2'[`h2']==. & `h2' <=`nn' {;
local h2 =`h2'+1 ;
};
qui replace `p2'  =  `p2'[`h2'] in `i';
qui replace `sub2'=`sub2'[`h2'] in `i';
local h2=`h2'-1;
};
};






forvalues i = 1/`nn' {;
local dp`i' = (`p2'[`i']/`p1'[`i']-1) ;
local sb`i' = `sub1'[`i']/`p1'[`i']; // add valorem subsidy

};



local se1=`q'[1]*`p1'[1];
local basev1=0;
forvalues i = 2/`nn' {;
local j  = `i'-1;
local se`i' = `se`j'' + (`q'[`i']-`q'[`i'-1])*`p1'[`i'];
};



local ex1= `q'[1]*`p1'[1];
forvalues i = 2/`nn' {;
local ex`i'= (`q'[`i']-`q'[`i'-1])*`p1'[`i'];
};




tempvar class ;
qui gen `class' = 1;

if `nn1' > 1 {;
forvalues i = 2/`nn1' {;
local j=`i'-1;
 qui replace `class' = `i'  if (`2'>`se`j'' & `2'<=`se`i'') ;
};


};
if `nn1'>=1 qui replace `class' = `nn'         if (`2'>`se`nn1'')  ;


tab `class';
tempvar svar ;
qui gen `svar' = 0 ;





qui replace `svar' = `2'*`dp1'*(`ela'*(`sb1'-`dp1')-1)                                                       if `class'==1; 

forvalues i = 2/`nn' {;
local k = `i'-1;
forvalues j = 1/`k' {;
qui replace `svar' = `svar' + `ex`j''*`dp`j''*(`ela'*(`sb`j''-`dp`j'')-1)                                    if `class'==`i'; 
};
qui replace `svar' = `svar' + (`2'-`se`k'')*`dp`i''*(`ela'*(`sb`i''-`dp`i'')-1)                              if `class'==`i'; 
};







qui replace `svar' = -`svar' /(1+`inf'/100); 


if ("`name'" ~= "") {;
cap drop `name';
qui gen `name' =  `svar';
};


/* estimating the results by considering the household or the indidual units */

tempvar ww it dww ;
qui gen  `ww' = `1';
qui gen  `it' = `2';
qui gen `dww' = `svar';




tempvar num denum;
qui gen `num' = `dww';
qui gen `denum' = 1;

if ("`result'" == "per") {;
qui replace  `ww' = `1' / `hsize' ;
qui replace  `it' = `2' / `hsize' ;
qui replace `dww' = `svar' / `hsize' ;

qui replace `num' = `hsize'*`dww';
qui replace `denum' = `hsize';
};

/* set trace on; */


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
};
                    local length = 10;
if ("`hgroup'"!="") local length = $indica;
local length1 = `length'+1;

qui count;
if (`r(N)' < `length1')  qui set obs `length1' ;

tempvar Group est1 est2 est3  sest1 sest2 sest3 ;
qui gen `Group' ="";
qui gen `est1' = 0;
qui gen `est2' = 0;
qui gen `est3' = 100;
qui gen `sest1' = 0;
qui gen `sest2' = 0;
qui gen `sest3' = 0;


qui svy: total `num'   ;
matrix aa1 = e(b);
qui replace `est1' = el(aa1,1,1) in `length1';
matrix saa1 = e(V);
qui replace `sest1' = el(saa1,1,1)^0.5 in `length1';

qui svy: ratio `num'/`denum'   ;
matrix bb1 = e(b);
qui replace `est2' = el(bb1,1,1) in `length1';

matrix sbb1 = e(V);
qui replace `sest2' = el(sbb1,1,1)^0.5 in `length1';

qui replace `sest3' = 0                in `length1';


tempvar gro;
if ("`hgroup'"=="") qui gen `gro' = `dec10';
if ("`hgroup'"!="") qui gen `gro' = `hgroup'; 

qui svy: total `num' , over(`dec10')  ;
matrix aa = e(b);
matrix saa = e(V);


qui svy: ratio `num'/`denum' , over(`gro')  ;
matrix bb  = e(b);
matrix sbb = e(V);






qui replace `Group' = "Population" in `length1';

tempvar snum;
forvalues i=1/`length' {;
cap drop `snum';
qui gen `snum' = `num'*(`gro'==`i')*100;
qui svy: ratio `snum'/`num'   ;
cap drop matric acc;
matrix acc = e(b);
cap drop matrix sacc;
matrix sacc = e(V);
local es`i'  = el(acc,1,1);
local ses`i' = el(sacc,1,1)^0.5;
};


forvalues i=1/`length' {;
qui replace `est1'       = el(aa,1,`i')              in `i';
qui replace `est2'       = el(bb,1,`i')              in `i';
qui replace `est3'       = `es`i''   			     in `i';


qui replace `sest1'       = el(saa,`i',`i')^0.5              in `i';
qui replace `sest2'       = el(sbb,`i',`i')^0.5              in `i';
qui replace `sest3'       = `ses`i''    					 in `i';


if ("`hgroup'"=="")  {;
qui replace `Group' = "Decile `i'"   in `i';
};
if ("`hgroup'"!="")  {;
local kk = gn1[`i'];
if ( "`grlab`kk''" == "") local grlab`kk' = "Group_`kk'";
qui replace `Group' = "`kk': `grlab`kk''" in `i';
local ll=max(`ll',length("`kk': `grlab`kk''"));
};
};



local stit1 = "Deciles";
if ("`hgroup'"!="") local stit1 = "Population groups";


	tempname table;
	.`table'  = ._tab.new, col(4);
	.`table'.width |20|20 20 20 |;
	.`table'.strcolor . . yellow .  ;
	.`table'.numcolor yellow yellow . yellow ;
	.`table'.numfmt %16.0g  %16.`dec'f  %16.`dec'f %16.2f  ;
	                                         local unit = "household";
	 if ("`hsize'"!="" &  "`result'"=="per") local unit = "per capita";
	di _n as text "{col 4} Change in `unit' expenditures on `2'";
       if ("`hsize'"!="" &  "`result'"=="per")   di as text     "{col 5}Household size  :  `hsize'";
       if ("`hweight'"!="") di as text     "{col 5}Sampling weight :  `hweight'";
     
	.`table'.sep, top;
	if ("`result'"=="hh" | "`result'"=="") {;
		.`table'.titles "`stit1'" "Total change in"      " Average change "  "Proporion of  the   " ;
	    .`table'.titles "  " "revenue by groups"     "                 "   "change (in %)" ;
	};
	
  if ("`result'"=="per") {;
		.`table'.titles "`stit1'" "Total change in"      " Average change "  "Proporion of  the   " ;
	    .`table'.titles "  "       "revenue by"     "                 "   "change (in %)" ;
	};
	.`table'.sep, mid;
	
	forvalues i=1/`length'{;
                                       .`table'.numcolor white yellow yellow yellow    ;
             
			                           .`table'.row `Group'[`i'] `est1'[`i']  `est2'[`i'] `est3'[`i']; 
			                           
		     if (`dste'==1 )    {; 
				                   .`table'.numcolor white green   green  green  ;
			                       .`table'.row " "    `sest1'[`i']  `sest2'[`i'] `sest3'[`i']  ;       
                };
				
				};
   .`table'.sep, mid;
.`table'.numcolor white yellow yellow yellow;
.`table'.row `Group'[`length1'] `est1'[`length1']  `est2'[`length1'] `est3'[`length1']   ;

if (`dste'==1){;
.`table'.numcolor white green   green  green   ;
.`table'.row  " "    `sest1'[`length1']  `sest2'[`length1'] `sest3'[`length1']  ;   
};


.`table'.sep,bot;




if (`dgra'==1 )    {; 
tempvar group;
if ("`hgroup'"=="") qui gen `group' = _n in 1/`length';
if ("`hgroup'"!="") qui gen `group' =  gn1 in 1/`length'; 

	                                         local unitan = "household";
     if ("`hsize'"!="" &  "`result'"=="per") local unitan = "individual";
forvalues i=1/`length' {;
local aa = ""+`Group'[`i'];
label define _lgr  `i' "`aa'" , modify ;
};
lab val `group' _lgr;
preserve;
tempname gr1 gr2 gr3;
qui keep in 1/`length';
qui graph hbar (asis)    `est1', over(`group')
title(Total change in expenditures, size(medlarge) )  name(`gr1') nodraw;
qui graph hbar (asis)    `est2', over(`group')
title(Average change in expenditures, size(medlarge))  name(`gr2') nodraw;
qui graph hbar (asis)    `est3', over(`group')
title(Proporion of  change (in %),size(medlarge))  name(`gr3') nodraw;
graph combine  `gr1' `gr2' `gr3', cols(2) title(Impact on expenditures at `unitan' level); 
restore;
};

end;

/*

set more off;
/*set trace on;*/
set tracedepth 2;
pschsetn psch1,
nblock(6)
mxb1(160)
mxb2(300)
mxb3(500)
mxb4(750)
mxb5(1000)
tr1(0.033)  
tr2(0.072)  
tr3(0.086)  
tr4(0.114)  
tr5(0.135)  
tr6(0.174)  

sub1(0.066)  
sub2(0.144)  
sub3(0.192)  
sub4(0.228)  
sub5(0.270)  
sub6(0.348)  

;

pschsetn psch2, nblock(7) 
mxb1(160) 
mxb2(300) 
mxb3(400) 
mxb4(500) 
mxb5(700) 
mxb6(1000) 
tr1(0.034) 
tr2(0.0762) 
tr3(0.0906) 
tr4(0.0924) 
tr5(0.1385) 
tr6(0.1714) 
tr7(0.1814)
;

cap drop max_block2
cap drop tarrif2
input max_block2 tarrif2
160	0.0363
300	0.0792
400	0.0946
500	0.1254
700 0.1485
1000 0.174
100000 0.174
end

#delimit ;
pschdes psch1;


pschdes psch2;
cap drop elas;
g elas=-0.3;
*set trace on;
set tracedepth 1;
imsref all_exp elec, hsize(hhsize) elas(elas) name(lmp_exp_elc) ipsch(psch1) fpsch(psch2) ;

cap drop elas;
g elas=-0.6;
*set trace on;
set tracedepth 1;
imsref all_exp elec, hsize(hhsize) elas(elas) name(lmp_exp_elc) ipsch(psch1) fpsch(psch2) ;


*/
