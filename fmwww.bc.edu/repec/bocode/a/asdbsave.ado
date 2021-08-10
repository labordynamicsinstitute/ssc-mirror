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




capture program drop wfpsdb;
program define wfpsdb;
version 9.2;
syntax anything  [ ,  INISave(string) NAMEPS(string) ITEM(string) PER(string) mxb(varname) tr(varname) sub(varname) ];
  tokenize `inisave' ,  parse(".");
  local dof = trim("`1'");
  local fname "`dof'-`nameps'.pco" ;
   cap file close mefile;
   cap erase  "`fname'" ;
   tempfile  mefile;
   file open mefile   using "`fname'", write append;
   tokenize `namelist';
   file write mefile `".pschset_`per'_`item'_dlg.main.cb_ini.setvalue    `.pschset_`per'_`item'_dlg.main.cb_ini.value'"'          _n;
   file write mefile `".pschset_`per'_`item'_dlg.main.cb_bracs.setvalue  `.pschset_`per'_`item'_dlg.main.cb_bracs.value'"'        _n;
   file write mefile `".pschset_`per'_`item'_dlg.main.ed_bracs.setvalue  `.pschset_`per'_`item'_dlg.main.ed_bracs.value'"'        _n;
   file write mefile `".pschset_`per'_`item'_dlg.main.cb_bun.setvalue    `.pschset_`per'_`item'_dlg.main.cb_bun.value'"'           _n;
   
   if "`.pschset_`per'_`item'_dlg.main.cb_bracs.value'"!=""  local nblock1 =  `.pschset_`per'_`item'_dlg.main.cb_bracs.value' ;
   if "`.pschset_`per'_`item'_dlg.main.ed_bracs.value'"!=""  local nblock2 =  `.pschset_`per'_`item'_dlg.main.ed_bracs.value' ;
   if "`.pschset_`per'_`item'_dlg.main.cb_ini.value'" == "1" local nblk = `nblock1' ;
   if "`.pschset_`per'_`item'_dlg.main.cb_ini.value'" == "2" local nblk = `nblock2' ;
   
 forvalues i=1/`nblk' {;
 file write mefile `".pschset_`per'_`item'_dlg.main.en_mxb`i'.setvalue    "`.pschset_`per'_`item'_dlg.main.en_mxb`i'.value'""'  _n;  
 file write mefile `".pschset_`per'_`item'_dlg.main.en_tarif`i'.setvalue  "`.pschset_`per'_`item'_dlg.main.en_tarif`i'.value'""'  _n; 
 file write mefile `".pschset_`per'_`item'_dlg.main.en_sub`i'.setvalue    "`.pschset_`per'_`item'_dlg.main.en_sub`i'.value'""'  _n; 
  };
  
 file write mefile `".pschset_`per'_`item'_dlg.main.var_mxb.setvalue     "`.pschset_`per'_`item'_dlg.main.var_mxb.value'""'  _n; 
 file write mefile `".pschset_`per'_`item'_dlg.main.var_tr.setvalue      "`.pschset_`per'_`item'_dlg.main.var_tr.value'""'   _n; 
 file write mefile `".pschset_`per'_`item'_dlg.main.var_sub.setvalue     "`.pschset_`per'_`item'_dlg.main.var_sub.value'""'  _n; 
file close mefile;
end;





capture program drop asdbsave;
program define asdbsave, rclass sortpreserve;
version 9.2;
syntax varlist(min=1 max=1)[ ,   
HSize(varname) 
PLINE(varname)

ITNAMES(varname)
SNAMES(varname)
IPSCH(varname)
UNIT(varname)

FPSCH1(varname)
ELAS1(varname)

FPSCH2(varname)
ELAS2(varname)

FPSCH3(varname)
ELAS3(varname)


OINF(int 1)

INF1(real 0) 
INF2(real 0) 
INF3(real 0)

NSCEN(int 1) 
HGroup(varname) 
NITEMS(int 1)

XFIL(string)
LAN(string)
AGGRegate(string)
appr(int 1)  
wappr(int 1)
INISave(string) 
TJOBS(string) 
SUMMARY(string)
GJOBS(string) 

CNAME(string)
YSVY(string)
YSIM(string)
LCUR(string)
TYPETR(int 1)
GTARG(varname)
FOLGR(string)
GVIMP(int 0) 

OPR1(string) OPR2(string)  OPR3(string)  OPR4(string) OPR5(string)  
OPR6(string) OPR7(string)  OPR8(string)  OPR9(string) OPR10(string)

OPGR1(string)   
OPGR2(string)   
OPGR3(string)   
OPGR4(string)   
OPGR5(string)  
OPGR6(string)   
OPGR7(string)   
OPGR8(string)   
OPGR9(string)  
OPGR10(string)  


];


tokenize "`inisave'" ,  parse(".");
local inisave = "`1'";
    

local mylist min max ogr;
forvalues i=1/10 {;
if ("`opgr`i''"~="") {;
extend_opt_graph test , `opgr`i'' ;
foreach name of local mylist {;
local `name'`i' = r(`name');
if  "``name'`i''"=="." local `name'`i' = "" ;
};
};
};
   tokenize `varlist';
   cap file close myfile;
   tempfile  myfile;
   cap erase "`inisave'.prj" ;
   file open myfile   using "`inisave'.prj", write replace ;
   file write myfile `".asubsim_dlg.main.vn_pcexp.setvalue "`1'""' _n;
   file write myfile `".asubsim_dlg.main.vn_hhs.setvalue "`hsize'""' _n;
   file write myfile `".asubsim_dlg.main.vn_pl1.setvalue "`pline'""' _n;
   file write myfile `".asubsim_dlg.main.cb_wmet.setvalue "`wappr'""' _n;
   
   if ("`inisave'"~="")  file write myfile `".asubsim_dlg.main.dbsamex.setvalue "`inisave'""' _n;
   if ("`cname'"~="")    file write myfile `".asubsim_dlg.main.ed_cname.setvalue "`cname'""' _n;
   if ("`ysvy'"~="")     file write myfile `".asubsim_dlg.main.ed_ysvy.setvalue "`ysvy'""' _n;
   if ("`ysim'"~="")     file write myfile `".asubsim_dlg.main.ed_ysim.setvalue "`ysim'""' _n;
   if ("`lcur'"~="")     file write myfile `".asubsim_dlg.main.ed_lcur.setvalue "`lcur'""' _n;
   if ("`typetr'"~="")   file write myfile `".asubsim_dlg.main.cb_tr.setvalue "`typetr'""' _n;
   if ("`gtarg'"~="")  {;
                         file write myfile `".asubsim_dlg.main.cb_trg.setvalue "gr""' _n;
						 file write myfile `".asubsim_dlg.main.var_trg.setvalue "`gtarg'""' _n;
					   };
	/* if (`gvimp'==1)     file write myfile `".asubsim_dlg.main.chk_gvimp.settrue "' _n; : find how to set the value of checkbox latter */
   
   if ("`folgr'"~="")  {;
   file write myfile `".asubsim_dlg.gr_options.ck_folgr.seton"' _n;
   file write myfile `".asubsim_dlg.gr_options.ed_folgr.setvalue "`folgr'""' _n;
   };
   
   file write myfile `".asubsim_dlg.main.vn_hhg.setvalue "`hgroup'""' _n;
   
   if ("`aggregate'"~="") {;
   file write myfile `".asubsim_dlg.tb_options.ck_order.seton"' _n;
   file write myfile `".asubsim_dlg.tb_options.ed_aggr.setvalue "`aggregate'""' _n;
   };
   
   
   if ("`tjobs'"~="") {;
   file write myfile `".asubsim_dlg.tb_options.ck_tables.seton"' _n;
   file write myfile `".asubsim_dlg.tb_options.ed_tab.setvalue "`tjobs'""' _n;
   };
   
   if ("`gjobs'"~="") {;
   file write myfile `".asubsim_dlg.gr_options.ck_graphs.seton"' _n;
   file write myfile `".asubsim_dlg.gr_options.ed_gra.setvalue "`gjobs'""' _n;
   };
   
   if ("`xfil'"~="") {;
   file write myfile `".asubsim_dlg.tb_options.ck_excel.seton"' _n;
   file write myfile `".asubsim_dlg.tb_options.fnamex.setvalue "`xfil'""' _n;
   };
   if ("`lan'" == "fr") file write myfile `".asubsim_dlg.tb_options.cb_lan.setvalue fr "' _n;
   
   forvalues i=1/10 {;
   if ("`min`i''"~="")  file write myfile `".asubsim_dlg.gr_options.en_min`i'.setvalue "`min`i''""' _n;
   if ("`max`i''"~="")  file write myfile `".asubsim_dlg.gr_options.en_max`i'.setvalue "`max`i''""' _n;
   if ("`ogr`i''"~="")  file write myfile `".asubsim_dlg.gr_options.en_opt`i'.setvalue `"`ogr`i''"' "' _n;
   };
   
   file write myfile `".asubsim_dlg.items_info.en_inf1.setvalue "`inf1'""' _n;
   file close myfile;  
   
  
  
  
  
  
  
if (`oinf'==1) {;


local mylist sn qu it ip su fp el ps;
forvalues i=1/`nitems' {;
extend_opt_price test , `opr`i'' ;
foreach name of local mylist {;
local `name'`i'  `r(`name')';
if  "``name'`i''"=="." local `name'`i' = "" ;
};
};

forvalues i=1/`nitems' {;
if "`su`i''"==""      local su`i' = 0 ;
if "`el`i''"==""      local el`i' = 0 ;
if ("`sn`i''" == "" ) local sn`i' = "`it`i''" ;

if ("`ps`i''" == "2") {;
 local ipp`i' = "i_psch`i'" ;
};

};


 
   cap file close myfile;
   tempfile  myfile;
   file open myfile   using "`inisave'.prj", write append;
   file write myfile `".asubsim_dlg.items_info.cb_items.setvalue  `nitems'"'  _n;
   file write myfile `".asubsim_dlg.items_info.ed_items.setvalue  `nitems'"'  _n;
		forvalues i=1/`nitems' {;
		 file write myfile `".asubsim_dlg.items_info.en_sn`i'.setvalue  "`sn`i''""'  _n;  
		file write myfile `".asubsim_dlg.items_info.en_qu`i'.setvalue  "`qu`i''""'  _n; 
		file write myfile `".asubsim_dlg.items_info.vn_item`i'.setvalue  "`it`i''""'  _n;   
		file write myfile `".asubsim_dlg.items_info.cb_ps`i'.setvalue  `ps`i''"'  _n;  
		file write myfile `".asubsim_dlg.items_info.en_pr`i'.setvalue  "`ip`i''""'  _n; 
		file write myfile `".asubsim_dlg.items_info.en_su`i'.setvalue  "`su`i''""'  _n; 
		file write myfile `".asubsim_dlg.items_info.en_fp`i'.setvalue  "`fp`i''""'  _n; 
		file write myfile `".asubsim_dlg.items_info.en_elas`i'.setvalue  "`el`i''""'  _n; 
		};


forvalues i=1/`nitems' {;
 local fpp`i' = "f_psch`i'" ;
if ("`ps`i''" == "2") {;
local tcmd  pschset `ipp`i'' , ;
local n  =  `.`ipp`i''.nblock' ; 
local bun  =  `.`ipp`i''.bun' ; 
local tcmd `tcmd' nblock(`n') bun(`bun') ;
local n1=`n'-1;
forvalues j = 1/`n1' {;
local tcmd `tcmd' mxb`j'(`.`ipp`i''.blk[`j'].max')  sub`j'(`.`ipp`i''.blk[`j'].subside') tr`j'(`.`ipp`i''.blk[`j'].price') ;
};
local tcmd `tcmd' sub`n'(`.`ipp`i''.blk[`n'].subside')  tr`n'(`.`ipp`i''.blk[`n'].price') ;
file write myfile `"`tcmd'"'  _n;

classutil dir pschset_i_`i'_dlg ;
if ("`ps`i''" == "2" & "`r(list)'"==".pschset_i_`i'_dlg") wfpsdb anything , inisave(`inisave') nameps(`ipp`i'') per(i) item(`i');
if ("`ps`i''" == "2") file write myfile `".asubsim_dlg.items_info.bu_pr`i'.setlabel "`ipp`i''""'  _n; 
};
if ("`ps`i''" == "2") {;
local tcmd  pschset `fpp`i'' , ;
local n    =  `.`fpp`i''.nblock'; 
local bun  =  `.`fpp`i''.bun'; 
local tcmd `tcmd' nblock(`n') bun(`bun');
local n1=`n'-1;
forvalues j = 1/`n1' {;
local tcmd `tcmd' mxb`j'(`.`fpp`i''.blk[`j'].max')  sub`j'(`.`fpp`i''.blk[`j'].subside') tr`j'(`.`fpp`i''.blk[`j'].price') ;
};
local tcmd `tcmd' sub`n'(`.`fpp`i''.blk[`n'].subside')  tr`n'(`.`fpp`i''.blk[`n'].price') ;
file write myfile `"`tcmd'"'  _n;

classutil dir pschset_f_`i'_dlg ;
if ("`ps`i''" == "2" & "`r(list)'"==".pschset_f_`i'_dlg") wfpsdb anything , inisave(`inisave') nameps(`fpp`i'')  per(f) item(`i');
if ("`ps`i''" == "2") file write myfile `".asubsim_dlg.items_info.bu_fr`i'.setlabel "`fpp`i''""'  _n; 
};
};

local nfile = "$S_FN" ;
/* file write myfile `"cap use `nfile' , replace"'  _n; */
file close myfile;
};



if (`oinf'==2 ) {;
   cap file close myfile;
   tempfile  myfile;
   file open myfile   using "`inisave'.prj", write append;

forvalues i=1/`nitems' {;
local ip`i' = ""+`ipsch'[`i'] ;
local tcmd  pschset `ip`i'' , ;
local n  =  `.`ip`i''.nblock'; 
local bun  =  `.`ip`i''.bun'; 
local tcmd `tcmd' nblock(`n') bun(`bun')  ;
local n1=`n'-1;
forvalues j = 1/`n1' {;
local tcmd `tcmd' mxb`j'(`.`ip`i''.blk[`j'].max')  sub`j'(`.`ip`i''.blk[`j'].subside') tr`j'(`.`ip`i''.blk[`j'].price') ;
};
local tcmd `tcmd' sub`n'(`.`ip`i''.blk[`n'].subside')  tr`n'(`.`ip`i''.blk[`n'].price') ;
file write myfile `"`tcmd'"'  _n;

forvalues s=1/`nscen' {;
local fp`i' = ""+`fpsch`s''[`i'] ;
local tcmd  pschset `fp`i'' , ;
local n    =  `.`fp`i''.nblock'; 
local bun  =  `.`fp`i''.bun'; 
local tcmd `tcmd' nblock(`n') bun(`bun')  ;
local n1=`n'-1;
forvalues j = 1/`n1' {;
local tcmd `tcmd' mxb`j'(`.`fp`i''.blk[`j'].max')  sub`j'(`.`fp`i''.blk[`j'].subside') tr`j'(`.`fp`i''.blk[`j'].price') ;
};
local tcmd `tcmd' sub`n'(`.`fp`i''.blk[`n'].subside')  tr`n'(`.`fp`i''.blk[`n'].price') ;
file write myfile `"`tcmd'"'  _n;

};

};

 file write myfile `".asubsim_dlg.items_info.cb_items.setvalue  `nitems'"'  _n;
 file write myfile `".asubsim_dlg.items_info.ed_items.setvalue  `nitems'"'  _n;
 
 file write myfile `".asubsim_dlg.items_info.cb_ini.setvalue `oinf'""' _n;
 file write myfile `".asubsim_dlg.items_info.var_sn.setvalue "`snames'""' _n;
 file write myfile `".asubsim_dlg.items_info.var_item.setvalue "`itnames'""' _n;
 file write myfile `".asubsim_dlg.items_info.var_ip.setvalue "`ipsch'""' _n;
 file write myfile `".asubsim_dlg.items_info.var_unit.setvalue "`unit'""' _n;
 
 file write myfile `".asubsim_dlg.items_info.cb_nscen.setvalue  `nscen'"'  _n;

 forvalues s = 1/`nscen' {;
  file write myfile `".asubsim_dlg.items_info.vn_fpsch`s'.setvalue "`fpsch`s''""' _n;
  file write myfile `".asubsim_dlg.items_info.vn_elas`s'.setvalue "`elas`s''""' _n;
  file write myfile `".asubsim_dlg.items_info.en_inf`s'.setvalue "`inf`s''""' _n;
 };

 local nfile = "$S_FN" ;
 /* file write myfile `"cap use `nfile' , replace"'  _n; */
 file close myfile;
};






end;

