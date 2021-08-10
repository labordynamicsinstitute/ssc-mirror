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
syntax namelist (min=1 max=1) [,   NBLOCK(int 1) BUN(int 1) MXB(varname)  TR(varname) SUB(varname)  NUMBER(int 1) PER(string)  * ];

tokenize `namelist';
cap classutil drop .`1';	
if ("`sub'"=="") local issub=0;
if ("`sub'"~="") local issub=1;
if ("`bun'"~="1")  local bun=2;
cap classutil drop .`1';  
      
.`1' = .pschedule.new `nblock' `issub' `bun';

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
if  ("`sub'"=="")  local sb = 0 ;
if  ("`sub'"~="")  local sb=`sub'[`i'];
.block`i' = .block.new  `min`i'' `max`i'' `tr'[`i'] `sb';
.`1'.blk[`i'] = .block`i';
};

end;


#delimit ;
capture program drop pschset ;
program define pschset , rclass;
version 9.2;
syntax namelist (min=1 max=1) [,   
NBLOCK(int 1)
BUN(int 1)
MXB1(real 100)  MXB2(real 200) MXB3(real 300) MXB4(real 400) MXB5(real 500) 
MXB6(real 600)  MXB7(real 700) MXB8(real 800) MXB9(real 900) MXB10(real 1000)
TR1(real 1)     TR2(real 1)  TR3(real 1)  TR4(real 1)  TR5(real 1)  
TR6(real 1)     TR7(real 1)  TR8(real 1)  TR9(real 1)  TR10(real 1) 
SUB1(real 0)     SUB2(real 0)  SUB3(real 0)  SUB4(real 0)  SUB5(real 0)  
SUB6(real 0)     SUB7(real 0)  SUB8(real 0)  SUB9(real 0)  SUB10(real 0)
MXB(varname)  TR(varname) SUB(varname) OINF(int 1)
ITEM(int 1) PER(string) PRNAME(string)
INISAVE(string)
];


if (`oinf'==1) {;
tokenize `namelist';
if ("`sub1'"=="0") local issub=0;
if ("`sub1'"~="0") local issub=1;
if ("`bun'"~="1")  local bun=2;

cap classutil drop .`1';	
.`1' = .pschedule.new `nblock' `issub' `bun';


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
.block`i' = .block.new  `min`i'' `max`i'' `tr`i'' `sub`i'' ;
.`1'.blk[`i'] = .block`i';
};
};
if (`oinf'==2) {;
pschsetv `namelist' , nblock(`nblock') mxb(`mxb') tr(`tr') sub(`sub') bun(`bun');
};

capture {;
if ("`item'"~="") {;
if ("`per'"=="i") .asubsim_dlg.items_info.bu_pr`item'.setlabel "`1'";
if ("`per'"=="f") .asubsim_dlg.items_info.bu_fr`item'.setlabel "`1'";
};
};


/***********/

/***********/


if ("`inisave'" ~="") {;
   if ("`per'"=="") {;
   cap file close myfile;
   tempfile  myfile;
    tokenize `inisave' ,  parse(".");
    local dof = trim("`1'");
	cap erase  "`dof'.psc" ;
   file open myfile   using "`dof'.psc", write append;
   tokenize `namelist';
   file write myfile `".pschset_dlg.main.dbsamex.setvalue "`inisave'"'   _n;
   file write myfile `".pschset_dlg.main.ed_vname.setvalue  `1'"'            _n;
   file write myfile `".pschset_dlg.main.cb_ini.setvalue  `oinf'"'           _n;
   file write myfile `".pschset_dlg.main.cb_bracs.setvalue  `nblock'"'           _n;
   file write myfile `".pschset_dlg.main.ed_bracs.setvalue  `nblock'"'           _n;
   file write myfile `".pschset_dlg.main.cb_bun.setvalue  `bun'"'           _n;
   
 forvalues i=1/`nblock' {;
 file write myfile `".pschset_dlg.main.en_mxb`i'.setvalue     "`mxb`i''""'  _n;  
 file write myfile `".pschset_dlg.main.en_tarif`i'.setvalue   "`tr`i''""'  _n;  
 file write myfile `".pschset_dlg.main.en_sub`i'.setvalue     "`sub`i''""'  _n;  
  };

 file write myfile `".pschset_dlg.main.var_mxb.setvalue     "`mxb'""'  _n; 
 file write myfile `".pschset_dlg.main.var_tr.setvalue      "`tr'""'   _n; 
 file write myfile `".pschset_dlg.main.var_sub.setvalue     "`sub'""'  _n; 

file close myfile;
};

};

end;




