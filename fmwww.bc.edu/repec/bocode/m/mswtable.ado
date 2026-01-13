*! version 16.34   12Dec2025   
*! John Casterline
capture program drop mswtable
program define mswtable, rclass
version 16

set adosize 60

#d ;

local INPUT `"`0'"';

syntax , COLWidth(string)
         [ mat(string)
           mat1(string) mat2(string) mat3(string) mat4(string) mat5(string) mat6(string) mat7(string)
           est(string) 
           est1(string) est2(string) est3(string) est4(string) est5(string) est6(string) est7(string)
           est_stat(string) 
           est_stat1(string) est_stat2(string) est_stat3(string) est_stat4(string)
           est_stat5(string) est_stat6(string) est_stat7(string)
           est_star  est_star(string)   est_se  est_se(string)   est_no(string) 
           est_vars(string)
           est_vars1(string) est_vars2(string) est_vars3(string) est_vars4(string)
           est_vars5(string) est_vars6(string) est_vars7(string) 
           add_cols(string) add_means(string)  add_mat(string)  add_excel(string)
           title(string asis) SUBTitle(string asis)  
           title1(string asis) title2(string asis)
           note1(string) note2(string) note3(string) note4(string) note5(string)
           note6(string) note7(string) note8(string) note9(string)
           font(passthru)
           tline(string) bline(string)   firstX lastX   extra_place
           DECimals(string)  
           dec1(string) dec2(string) dec3(string) dec4(string) dec5(string) dec6(string) dec7(string)
           ct_set(string)
           ct(string)
           cst_set(string)  cst_set1(string) cst_set11(string)
           cst1(string asis) cst2(string asis) cst3(string asis) cst4(string asis)
           cst5(string asis) cst6(string asis) cst7(string asis) cst8(string asis)
           cst9(string asis) cst10(string asis)
           cst11(string asis) cst12(string asis) cst13(string asis) cst14(string asis) cst15(string asis)
           rt_set(string)
           rt(string)
           rt1(string) rt2(string) rt3(string) rt4(string) rt5(string) rt6(string) rt7(string)
           rst_set(string)  
           rst1(string asis)  rst2(string asis)  rst3(string asis)  rst4(string asis)  rst5(string asis)
           rst6(string asis)  rst7(string asis)  rst8(string asis)  rst9(string asis)  rst10(string asis)
           rst11(string asis)  rst12(string asis)  rst13(string asis)  rst14(string asis)  rst15(string asis)
           rst16(string asis)  rst17(string asis)  rst18(string asis)  rst19(string asis)
           rst21(string asis)  rst22(string asis)  rst23(string asis)  rst24(string asis)  rst25(string asis)
           rst26(string asis)  rst27(string asis)  rst28(string asis)  rst29(string asis)
           rst31(string asis)  rst32(string asis)  rst33(string asis)  rst34(string asis)  rst35(string asis)
           rst36(string asis)  rst37(string asis)  rst38(string asis)  rst39(string asis)
           rst41(string asis)  rst42(string asis)  rst43(string asis)  rst44(string asis)  rst45(string asis)
           rst46(string asis)  rst47(string asis)  rst48(string asis)  rst49(string asis)
           rst51(string asis)  rst52(string asis)  rst53(string asis)  rst54(string asis)  rst55(string asis)
           rst56(string asis)  rst57(string asis)  rst58(string asis)  rst59(string asis)
           rst61(string asis)  rst62(string asis)  rst63(string asis)  rst64(string asis)  rst65(string asis)
           rst66(string asis)  rst67(string asis)  rst68(string asis)  rst69(string asis)
           rst71(string asis)  rst72(string asis)  rst73(string asis)  rst74(string asis)  rst75(string asis)
           rst76(string asis)  rst77(string asis)  rst78(string asis)  rst79(string asis)
           pt_set(string)
           pt1(string) pt2(string) pt3(string) pt4(string) pt5(string) pt6(string) pt7(string)
           pline  pspace(string)  
           extra1(string) extra2(string) extra3(string) extra4(string) extra5(string)
           extra6(string) extra7(string) extra8(string) extra9(string) 
           extra11(string) extra12(string) extra13(string) extra14(string)
           extra15(string) extra16(string) extra17(string) extra18(string)
           extra21(string) extra22(string) extra23(string) extra24(string)
           extra25(string) extra26(string) extra27(string) extra28(string)
           extra31(string) extra32(string) extra33(string) extra34(string)
           extra35(string) extra36(string) extra37(string) extra38(string)
           extra41(string) extra42(string) extra43(string) extra44(string)
           extra45(string) extra46(string) extra47(string) extra48(string)
           extra51(string) extra52(string) extra53(string) extra54(string)
           extra55(string) extra56(string) extra57(string) extra58(string)
           extra61(string) extra62(string) extra63(string) extra64(string)
           extra65(string) extra66(string) extra67(string) extra68(string)
           extra71(string) extra72(string) extra73(string) extra74(string)
           extra75(string) extra76(string) extra77(string) extra78(string)
           slim
           tabname(string)  
           OUTFile(string) ];  

#d cr

*  n = 249 options  (max allowed = 256)
*
*  di 1+1+7+1+7+1+7+5+4+2+2+9+1+5+1+7+1+1+3+15+1+1+7+1+19+(6*9)+1+7+2+9+(7*9)+1+1+1


if "`mat'"~="" & "`mat1'"~=""     {
   noi di _n(1) _col(3) in y  "ERROR:  mat or mat1 can be specified but not both"  _n(1) " "
   exit
}

if "`est'"~="" & "`est1'"~=""     {
   noi di _n(1) _col(3) in y  "ERROR:  est or est1 can be specified but not both"  _n(1) " "
   exit
}

if "`est'"~=""  &  "`mat'"~=""    {
   noi di _n(1) _col(3) in y  "ERROR:  either mat or est but not both"  _n(1) " "
   exit
}

if "`est1'"~=""  &  "`mat1'"~=""  {
   noi di _n(1) _col(3) in y  "ERROR:  either mat1 or est1 but not both"  _n(1) " "
   exit
}

if ("`est'"=="" & "`est1'"=="") & ("`est_stat'"~="" | "`est_star'"~="" |      ///
    "`est_se'"~="" | "`add_means'"~="" | "`add_mat'"~="")     {
   noi di _n(1) _col(3) in y  "ERROR:  est option requested but not est"   _n(1) " "
   exit
}

if ("`mat'"~="" | "`mat1'"~="") & "`add_means'"~=""  {
   noi di _n(1) _col(3) in y  "ERROR:  cannot specify add_means with mat input"  _n(1) " "
   exit
}

if ("`mat'"~="" | "`mat1'"~="") & "`add_mat'"~=""  {
   noi di _n(1) _col(3) in y  "ERROR:  cannot specify add_mat with mat input"  _n(1) " "
   exit
}

if "`add_means'"~=""  &  "`add_mat'"~=""  {
   noi di _n(1) _col(3) in y  "ERROR:  cannot specify BOTH add_means and add_mat"  _n(1) " "
   exit
}




******************************************************************************************
******************************************************************************************


**# reconciling single-panel and multi-panel
*  ***********************************************************
*
*  ****  RECONCILING SINGLE-PANEL AND MULTI-PANEL SYNTAX  ****
*
*  ***********************************************************


local n_p = 0
forvalues p = 1/7           {
   if "`mat`p''" ~= ""      {
      local n_mat = `n_mat' + 1
      local n_p   = `n_p'   + 1
   }
}
forvalues p = 1/7           {
   if "`est`p''" ~= ""      {
      local n_est = `n_est' + 1
      local n_p   = `n_p'   + 1
   }
}

if "`mat'" ~= ""            {
   local mat1 "`mat'"
   local n_p = 1
   macro drop _mat
}

if "`est'" ~= ""            {
   local est1 "`est'"
   local n_p = 1
   macro drop _est
}

if "`est_stat'" ~= ""       {
   local est_stat1 "`est_stat'"
   macro drop _est_stat
   forvalues p = 2/7        {
      if "`est`p''"~="" & "`est_stat`p''"==""  {
         local est_stat`p' "`est_stat1'"
      }
   }
}

if "`est_vars'" ~= ""       {
   local est_vars1 "`est_vars'"
   macro drop _est_vars
   forvalues p = 2/7        {
      if "`est`p''"~=""     {
         local est_vars`p' "`est_vars1'"
      }
   }
}

if "`rt'" ~= ""             {
   forvalues p = 1/`n_p'    {
      if "`rt`p''"==""      {
         local rt`p' "`rt'"
      }
   }
   macro drop _rt
}

if `"`rst1'"' ~= ""                  {
   if `n_p'==1                       {
      forvalues r = 15(-1)1          {
         if `"`rst`r''"' ~= ""       {
            local rst1`r' `"`rst`r''"'  
            capture macro drop _rst`r'
         }
      }
   }
   if `n_p' > 1                      {
      forvalues p = 1/`n_p'          {
         forvalues r = 9(-1)1        {
            if `"`rst`r''"' ~= ""    {
               local rst`p'`r' `"`rst`r''"'  
            }
         }
      }
      forvalues r = 1/9              {
         capture macro drop _rst`r'
      }
   }
}


******************************************************************************************
******************************************************************************************


*  *********************************
*
*  ****  SOME INITIAL SETTINGS  ****
*
*  *********************************



if "`tabname'" == ""  {
   local tabname "DdMmTtZz"
}


**# fonts
*  fonts

local FONT "Cambria"
local t_fsize  "12.5"    //  title
local s_fsize  "12"      //  sub-title
local l_fsize  "12"      //  column labels, row labels
local b_fsize  "11.5"    //  body of table
local st_fsize "11"      //  statistics 
local ex_fsize "11"      //  extra information
local se_fsize "10.5"    //  se, z, p
local ci_fsize "10.0"    //  confidence intervals
local a_fsize  "10.5"    //  asterisks
local n_fsize  "10.5"    //  notes
if `"`font'"' ~= ""  {                     //  font is reset
   local FONT1 = regexr(`"`font'"',"font","")
   tokenize `"`FONT1'"', parse(" ,)")
   local FONT2 "`1'"                       //  new name of font
   mac shift
   local k = 1
   while "`1'" ~= ""   {
      if "`1'"~="," & "`1'"~=")"   {
         local font`k' "`1'"
         local ++k
      }
      mac shift
   }
   if "`font1'" ~= ""  {         //  resetting sizes of fonts
      local t_fsize  "`font1'"             //  title
      local s_fsize  "`font2'"             //  sub-title
      local l_fsize  "`font3'"             //  column labels, row labels
      local b_fsize  "`font4'"             //  body of table
      local n_fsize  "`font5'"             //  notes
      local b_fsizeX = real("`b_fsize'")
      local st_fsize = `b_fsizeX' - 0.5    //  statistics
      local ex_fsize = `b_fsizeX' - 0.5    //  extra information
      local se_fsize = `b_fsizeX' - 1.0    //  se, z, p
      local ci_fsize = `b_fsizeX' - 1.5    //  confidence intervals
      local a_fsize  = `b_fsizeX' - 1.5    //  asterisks
   }
   tokenize `"`FONT2'"', parse("(")
   local FONT "`2'"
}
local font "`FONT'"

local inflate = 1.00
if "`font'"=="Arial"        {
   local inflate = 1.10
}
if "`font'"=="LM Roman 12"  {
   local inflate = 1.30
}
**# line heights
local bf016 = `b_fsize'*(2/12)
local bf025 = `b_fsize'*(3/12)
local bf033 = `b_fsize'*(4/12)
local bf044 = `b_fsize'*(5/12)
local bf050 = `b_fsize'*(6/12)
local bf058 = `b_fsize'*(7/12)
local bf067 = `b_fsize'*(8/12)
local bf075 = `b_fsize'*(9/12)
local bf083 = `b_fsize'*(10/12)
local bf092 = `b_fsize'*(11/12)
local bf100 = `b_fsize'*(12/12)
local bf108 = `b_fsize'*(13/12)*`inflate'
local bf117 = `b_fsize'*(14/12)*`inflate'
local bf125 = `b_fsize'*(15/12)*`inflate'
local bf133 = `b_fsize'*(16/12)*`inflate'
local bf150 = `b_fsize'*(18/12)*`inflate'
local bf167 = `b_fsize'*(20/12)*`inflate'
local bf200 = `b_fsize'*(24/12)*`inflate'
local bf260 = `b_fsize'*(31/12)*`inflate'
local bf275 = `b_fsize'*(33/12)*`inflate'
local bf300 = `b_fsize'*(36/12)*`inflate'
local bf410 = `b_fsize'*(49/12)*`inflate'
local bf425 = `b_fsize'*(51/12)*`inflate'
local bf540 = `b_fsize'*(65/12)*`inflate'
local bf550 = `b_fsize'*(66/12)*`inflate'


local lineT "single"
if "`tline'"=="double"  {
   local lineT "double,,0.25pt"
}
if "`tline'"=="bold"  {
   local lineT "single,,1.5pt"
}

local lineB "single"
if "`bline'"=="double"  {
   local lineB "double,,0.25pt"
}
if "`bline'"=="bold"  {
   local lineB "single,,1.5pt"
}



**# statistic names
*  statistic names

#delimit ;
local sttitles
`"N        "N observations"
  N_g      "N groups"
  N_clust  "N clusters"
  bic      BIC
  aic      AIC
  r2       R-squared
  r2_a     "Adjusted R-squared"
  r2_w     "R-squared within"
  rho      Rho
  F        "F statistic"
  chi2     Chi-squared
  ll       "Log likelihood" "';
#delimit cr



**# rt_set, ct_set, cst_set, pt_set, rst_set

*  rt_set

local rt_format ""
local rt_just "left"
if "`rt_set'" ~= ""                  {
   tokenize "`rt_set'", parse(" ,")
   while "`1'" ~= ""                 {
      if "`1'" == "bold"             {
         local rt_format "bold"
      }
      if "`1'" == "underline"        {
         local rt_format "underline"
      }
      if "`1'"=="italic" | "`1'"=="italics"  {
         local rt_format "italic"
      }
      if "`1'" == "left"             {
         local rt_just "left"
      }
      if "`1'" == "center"           {
         local rt_just "center"
      }
      if "`1'" == "intercept_right"  {
         local INT_RIGHT "yes"
      }
      if "`1'" == "total_right"      {
         local TOT_RIGHT "yes"
      }
      mac shift
   }
}



*  ct_set

local ct_format ""
local ct_just "right"
if "`ct_set'" ~= ""            {
   tokenize "`ct_set'", parse(" ,")
   while "`1'" ~= ""           {
      if "`1'" == "bold"       {
         local ct_format "bold"
      }
      if "`1'" == "underline"  {
         local ct_format "underline"
      }
      if "`1'"=="italic" | "`1'"=="italics"  {
         local ct_format "italic"
      }
      if "`1'" == "left"       {
         local ct_just "left"
      }
      if "`1'" == "center"     {
         local ct_just "center"
      }
      mac shift
   }
}



*  cst_set

if "`cst_set1'" == ""     {
   local cst_set1 "`cst_set'"
}
if "`cst_set11'" == ""    {
   local cst_set11 "`cst_set'"
}
local cst_format1 "underline"
local cst_just1 "center"
if "`cst_set1'" ~= ""        {
   tokenize "`cst_set1'", parse(" ,")
   while "`1'" ~= ""         {
      if "`1'"=="bold"       {
         local cst_format1 "bold"
      }
      if "`1'"=="italic" | "`1'"=="italics"  {
         local cst_format1 "italic"
      }
      if "`1'"=="none"       {
         local cst_format1 ""
      }
      if "`1'" == "left"     {
         local cst_just1 "left"
      }
      if "`1'" == "right"    {
         local cst_just1 "right"
      }
      mac shift
   }
}
local cst_format11 "underline"
local cst_just11 "center"
if "`cst_set11'" ~= ""       {
   tokenize "`cst_set11'", parse(" ,")
   while "`1'" ~= ""         {
      if "`1'"=="bold"       {
         local cst_format11 "bold"
      }
      if "`1'"=="italic" | "`1'"=="italics"  {
         local cst_format11 "italic"
      }
      if "`1'"=="none"       {
         local cst_format11 ""
      }
      if "`1'" == "left"     {
         local cst_just11 "left"
      }
      if "`1'" == "right"    {
         local cst_just11 "right"
      }
      mac shift
   }
}



*  pt_set

local pt_format "underline"
local pt_just   "left"
local SPACES_PT ""
if "`pt_set'" ~= ""             {
   tokenize "`pt_set'", parse(" ,()")
   while "`1'" ~= ""            {
      if "`1'" == "underline"   {
         local underline_yes "yes"
      }
      if "`1'" == "bold"        {
         local bold_yes "yes"
      }
      if "`1'"=="italic" | "`1'"=="italics"  {
         local italic_yes "yes"
      }
      mac shift
   }
   if "`underline_yes'"=="yes" & "`bold_yes'"=="yes"   {
      local pt_format "underline bold"
   }
   if "`underline_yes'"=="yes" & "`italic_yes'"=="yes" {
      local pt_format "underline italic"
   }
   if "`underline_yes'"=="" & "`bold_yes'"=="yes"      {
      local pt_format "bold"
   }
   if "`underline_yes'"=="" & "`italic_yes'"=="yes"    {
      local pt_format "italic"
   }
   if "`italic_yes'"=="yes" & "`bold_yes'"=="yes"      {
      local pt_format "italic bold"
   }
   tokenize "`pt_set'", parse(" ,()")
   while "`1'" ~= ""            {
      if "`1'" == "none"        {
         local pt_format ""
      }
      if "`1'" == "center"      {
         local pt_just "center"
      }
      if "`1'" == "right"       {
         local pt_just "right"
      }
      if "`1'" == "indent"      {
         local SPACES_PT "   "
      }
      if real("`1'")>0 & real("`1'")<=8   {
         local SPACES_PT ""
         forvalues n = 1/8                {
            if `n'<=real("`1'")           {
               local SPACES_PT " `SPACES_PT'"
            }
         }
      }
      mac shift
   }
}



*  rst_set

local rst_format ""
local rst_indent ""
local SPACES_RST ""
if "`rst_set'" ~= ""                      {
   tokenize "`rst_set'", parse(" ,()")
   while "`1'" ~= ""                      {
      if "`1'" == "bold"                  {
        local rst_format "bold"
      }
      if "`1'" == "underline"             {
         local rst_format "underline"
      }
      if "`1'"=="italic" | "`1'"=="italics"  {
         local rst_format "italic"
      }
      if "`1'" == "indent"                {
         local rst_indent "indent"
         local SPACES_RST "   "
      }
      if real("`1'")>0 & real("`1'")<=8   {
         local SPACES_RST ""
         forvalues n = 1/8                {
            if `n'<=real("`1'")           {
               local SPACES_RST " `SPACES_RST'"
            }
         }
      }
      mac shift
   }
}



**# default settings:  add_cols, est_se, est_star, title/subtitle
*  add_cols

local extra_width = 0
if "`add_cols'"~=""       {
   tokenize "`add_cols'", parse("!")
   local s = 0
   local N_ADDCOLS = 0
   while "`1'" ~= ""      {
      if "`1'" ~= "!"     {
         local ++s
         local ++N_ADDCOLS
         local ADDCOLS`s' "`1'"
      }
      mac shift
   }
   local extra_width = 0
   forvalues s = 1/`N_ADDCOLS'   {
      tokenize "`ADDCOLS`s''", parse(" ,")
      local ac_start`s' = `1'
      local ac_width`s' "`2'"
      if "`3'" ~= ""             {
         local ac_width`s' = "`3'"
      }
      local extra_width = `extra_width' + `ac_width`s''
   }
}



*  est_se  and  est_star - settings for default (i.e. no "string")

tokenize `"`INPUT'"', parse(" ,")
while `"`1'"' ~= ""          {
   if `"`1'"' == "est_se"    {
      local est_se "XX"
   }
   if `"`1'"' == "est_star"  {
      local est_star "XX"
   }
   mac shift
}



*  title & subtitle

if `"`title'"' ~= ""              {
   if "`title1'"~="" | "`title2'"~=""             {
      noi di _n(2) _col(3) in y  `"ERROR:  "title" and "title1/title2" cannot both be specified"'   _n(1) " "
      exit  
   }
   local title_just   "center"
   local title_format ""
   tokenize `"`title'"', parse(" ,")
   local TITLE "`1'"
   mac shift
   while "`1'" ~= ""              {
      if "`1'" == "left"       {
         local title_just "left"
      }
      if "`1'" == "right"      {
         local title_just "right"
      }
      if "`1'" == "bold"       {
         local title_format "bold"
      }
      if "`1'" == "underline"  {
         local title_format "underline"
      }
      if "`1'" == "italic"     {
         local title_format "italic"
      }
      mac shift
   }
}
if `"`title1'"'~="" | `"`title2'"'~=""            {
   if "`title'" ~= ""                             {
      noi di _n(2) _col(3) in y  `"ERROR:  "title1/title2" and "title" cannot both be specified"'   _n(1) " "
      exit  
   }
   local title1_width "0.8"
   forvalues t = 1/2                              {
      if `"`title`t''"' ~= ""                     {          
         local title`t'_just   "left"
         local title`t'_format ""
         tokenize `"`title`t''"', parse(" ,")
         local TITLE`t' "`1'"
         mac shift
         while "`1'" ~= ""                        {
            if "`1'" == "center"                  {
               local title`t'_just "center"
            }
            if "`1'" == "right"                   {
               local title`t'_just "right"
            }
            if "`1'" == "bold"                    {
               local title`t'_format "bold"
            }
            if "`1'" == "underline"               {
               local title`t'_format "underline"
            }
            if "`1'" == "italic"                  {
               local title`t'_format "italic"
            }
            if `t'==1                             {
               if real("`1'")>0 & real("`1'")<=8  {
                  local title1_width = `1'
               }
            }
            mac shift
         }
      }
   }
}
if `"`subtitle'"' ~= ""             {
   local sub_just   "center"
   local sub_format ""
   tokenize `"`subtitle'"', parse(" ,")
   local SUB "`1'"
   mac shift
   while "`1'" ~= ""           {
      if "`1'" == "left"    {
         local sub_just "left"
      }
      if "`1'" == "right"   {
         local sub_just "right"
      }
      if "`1'" == "bold"    {
         local sub_format "bold"
      }
      if "`1'" == "underline"   {
         local sub_format "underline"
      }
      if "`1'" == "italic"   {
         local sub_format "italic"
      }
      mac shift
   }
}



* PUTDOCX table:  a few preliminaries

if "`outfile'" ~= ""  {
   local OPT "replace"
   tokenize "`outfile'", parse(" ,")
   local OUTF "`1'"
   mac shift
   while "`1'" ~= ""  {
      if "`1'" == "append"     {
         local OPT "append(pagebreak stylesrc(file))"
      } 
      if "`1'" == "landscape"  {
         local landscape "landscape"
      }
      mac shift
   }
}




quietly  {


******************************************************************************************
******************************************************************************************

**# add_excel

*  **********************************
*
*  ****  PROCESSING ADD_EXCEL  ****
*
*  **********************************


local EXC_SIDE "left"
local n_colE = 0

if `"`add_excel'"' ~= ""         {

   local k = 0
   tokenize `"`add_excel'"', parse(" ,")
   local EXC_SIDE = cond("`1'"=="left" | "`1'"=="right","`1'","left")
   while "`1'" ~= ""             {
      if "`1'"~="left" & "`1'"~="right" & "`1'" ~= ","   {
         local EXC_FILE "`1'"
      }
      mac shift
   }

   preserve

   import excel using "`EXC_FILE'", clear
   desc, varlist
   local EXC_VARS "`r(varlist)'"
   count
   local NUM = `r(N)'
   
   foreach a of local EXC_VARS   {
      local ++n_colE
      local EXC_type`a' : type `a'
      local EXC_TYPE`a' = substr("`EXC_type`a''",1,3)
      forvalues n = 1/`NUM'      {
         local exc`a'`n' = `a'[`n']
      }
   }

   restore

}




*  **********************************
*
*  ****  PROCESSING MAT and EST  ****
*
*  **********************************


local n_mat   = 0
local n_est   = 0
local n_pstat = 0
local n_p     = 0
local n_rt    = 0
forvalues p = 1/7           {
   if "`mat`p''" ~= ""      {    //  repeat above counts (for clarity)
      local n_mat = `n_mat' + 1
      local n_p   = `n_p'   + 1
   }
}
forvalues p = 1/7           {
   if "`est`p''" ~= ""      {    //  repeat above counts (for clarity)
      local n_est = `n_est' + 1
      local n_p   = `n_p'   + 1
   }
   if "`est_stat`p''" ~= "" {
      local n_pstat = `n_pstat' + 1
   }
   if "`rt`p''"  ~= ""      {
      local n_rt  = `n_rt' + 1
   }
}



if "`mat1'" ~= ""  {
   if "`rt1'"~="" & `n_rt'<`n_mat' & `n_rt'>0         {
      noi di _n(2) _col(3) in y  "ERROR:  must have rt for each mat"   _n(1) " "
      exit  
   }
}
if "`est1'" ~= ""       {
   if "`rt1'"~="" & `n_rt'<`n_est' & `n_rt'>0         {
      noi di _n(2) _col(3) in y  "ERROR:  must have rt for each est"   _n(1) " "
      exit  
   }
   if (`n_est'~=`n_pstat') & "`est_stat1'"~=""  {
      noi di _n(2) _col(3) in y  "ERROR:  must have equal numbers of est# and est_stat#"   _n(1) " "
      exit  
   }
}



**# mat processing
*
*  ****  PROCESSING MAT  ****
*

if "`mat1'" ~= ""  {

   local n_colD : colsof `mat1'
   local n_colM = 0                  //  means/matrix - always zero with matrix input
   local n_rowD = 0
   local n_rowS = 0                  //  statistics - always zero with matrix input
   matrix XxYyZz = `mat1'
   forvalues p = 1/`n_mat'   {
      if "`mat`p''" ~= ""    {
         local n_rowD`p' : rowsof `mat`p''
         local n_rowD = `n_rowD' + `n_rowD`p''
         local n_rowS`p' = 0        //  statistics - always zero with matrix input
         if `p' > 1          {
            matrix XxYyZz = XxYyZz \ `mat`p''
         }
      }
   }
   forvalues p = 1/`n_mat'      {          //  if ct or rt are NOT specified
      if `p'==1 & "`ct'" == ""  {
         local ct " "
         local COLNAME : colnames `mat`p'', quoted
         tokenize `"`COLNAME'"'
         while "`1'" ~= ""      {
            local ct "`ct' `1' !"
            mac shift
         }
      } 
      if "`rt`p''" == ""        {
         local rt`p' " "
         local ROWNAME : rownames `mat`p'', quoted
         tokenize `"`ROWNAME'"'
         while "`1'" ~= ""      {
            local rt`p' "`rt`p'' `1' !"
            mac shift
         }
      } 
   }

}
local mat "XxYyZz"



**# est processing
*
*  ****  PROCESSING EST  ****
*

if "`est1'" ~= ""  {

   forvalues p = 1/`n_est'         {
      local eqs`p' " "
      tokenize "`est`p''", parse(", ")
      local k = 1
      while "`1'" ~= ""            {
         if "`1'" ~= ","           {
            local eq`p'`k' "`1'"
            local eqs`p' "`eqs`p'' `eq`p'`k''"
            local ++k
         }
         mac shift
      }
   } 

   forvalues p = 1/`n_est'         {
      local stats`p' " "
      if "`est_stat`p''" ~= ""     {
         tokenize "`est_stat`p''", parse("!")
         local s = 0
         local N_STAT = 0
         while "`1'" ~= ""         {
            if "`1'" ~= "!"        {
               local ++s
               local ++N_STAT
               local STAT`s' "`1'"
            }
            mac shift
         }
         local k = 1
         forvalues s = 1/`N_STAT'  {
            tokenize "`STAT`s''", parse(" ,")
            local stats`p' "`stats`p'' `1'"
            local decS`p'`k' "`2'"
            if "`3'" ~= ""  {
               local decS`p'`k' "`3'"
            }
            local ++k
         }
      }            
   }

   local num_es = 3
   local pv1 = 0.05
   local pv2 = 0.01
   local pv3 = 0.001
   if "`est_star'" ~= ""     {
      local num_es = 3
      local pv1 = 0.05
      local pv2 = 0.01
      local pv3 = 0.001
      tokenize "`est_star'", parse(" ,()")
      if real("`1'")>=.00001 & real("`1'")<=.99      {
         local num_es = 0
         local pv1 ""
         local pv2 ""
         local pv3 ""
         local k = 0
      }
      while "`1'" ~= ""      {
         if real("`1'")>=.00001 & real("`1'")<=.99   {
            local ++num_es
            local ++k
            local pv`k' "`1'"
         }
         mac shift
      }    
   }


**# est:  est_se processing
   local ci_p = .025
   if `"`est_se'"' ~= ""     {
      tokenize `"`est_se'"', parse("!")
      local k = 1
      while `"`1'"' ~= ""    {
         if `"`1'"' ~= "!"   {
            local est_seX`k' = subinstr(`"`1'"',","," ",5)
            local ++k
         }
         mac shift
      }
      local hit1 = 0
      tokenize `"`est_seX1'"', parse(" ()")
      while `"`1'"' ~= ""    {
         if "`1'"=="beside"  {
            local est_se2 `"`est_seX1'"'
            local hit1 = 1
         }
         mac shift
      }
      tokenize `"`est_seX1'"'
      local j = 1
      while `"`1'"' ~= ""    {
         local X`j' "`1'"
         local ++j
         mac shift
      }
      forvalues i = 1/`j'    {
         tokenize `X`i'', parse("(")
         if "`1'"=="beside"  {
            local est_se2 `"`est_seX1'"'
            local beside_lab "`3'"
            local hit1 = 1
         }
      } 
      local hit2 = 9
      if `"`est_seX2'"' ~= ""                    {
         local hit2 = 0
         tokenize `"`est_seX2'"', parse(" ()")
         while `"`1'"' ~= ""                     {
            if "`1'"=="beside"                   {
               if `hit1'==1                      {
                  noi di _n(2) _col(3) in y  `"ERROR:  est_se "beside" specified twice"'   _n(1) " "
                  exit
               }
               local est_se2 "`est_seX2'"
               local hit2 = 1
            }

            mac shift
         }
         tokenize `"`est_seX2'"'
         local j = 1
         while `"`1'"' ~= ""         {
            local X`j' "`1'"
            local ++j
            mac shift
         }
         forvalues i = 1/`j'         {
            tokenize `X`i'', parse("(")
            if "`1'"=="beside"       {
               if `hit1'==1                      {
                  noi di _n(2) _col(3) in y  `"ERROR:  est_se "beside" specified twice"'   _n(1) " "
                  exit
               }
               local est_se2 "`est_seX2'"
               local beside_lab "`3'"
               local hit2 = 1
            }
         } 
      }
      if `hit1'==0 & `hit2'==0       {
         noi di _n(2) _col(3) in y  `"ERROR:  est_se "below" specified twice"'   _n(1) " "
         exit
      }
      if `hit1'==0 | `hit2'==0       {
         if `hit1'==0                {
            local est_se1 "`est_seX1'"
         }
         if `hit2'==0                {
            local est_se1 "`est_seX2'"
         } 
      }

      forvalues k = 1/2              {
         if `"`est_se`k''"' ~= ""    {
            if `k'==2 & "`est_star'"~=""  {
               noi di _n(2) _col(3) in y  `"ERROR:  est_star and se/z/p/ci "beside" are incompatible"'   _n(1) " "
               exit
            }  
            local PAREN`k'    "no"
            local STPC`k'     "se"
            local CI_SEP "comma"
            tokenize `"`est_se`k''"', parse(" ()")
            while "`1'" ~= ""  {
               if "`1'" == "paren"   {
                  local PAREN`k' "paren"
               } 
               if "`1'" == "bracket" {
                  local PAREN`k' "bracket"
               }  
               if "`1'" == "z"       {
                  local STPC`k' "z"
               }
               if "`1'" == "p"       {
                  local STPC`k' "p"
               } 
               if "`1'" == "ci"      {
                  local STPC`k' "ci"
               }
               if real("`1'")>=.0001 & real("`1'")<.40   {     //  next three assume "ci" specified just once
                  local ci_p = `1'/2
               }
               if real("`1'")>5 & real("`1'")<30         {
                  local ci_fsize "`1'"    
               }
               if "`1'" == "dash"    {
                  local CI_SEP "dash"
               }  
               if real("`1'")>=.40 & real("`1'")<2       {
                  local beside_width "`1'"    
               }
               if real("`1'")>=2 & real("`1'")<=5        {
                  local beside_spaces "`1'"    
               }
               mac shift
            }
         }
      }
   }


   forvalues p = 1/`n_est'               {
      qui estimates table `eqs`p''
      matrix xX_eQ`p' = r(coef)          //  for labeling, retrieve coefficient vector
      if `p'==1 & "`ct'" == ""     {     //  if ct NOT specified
         local ct " "
         local COLNAMES : colnames xX_eQ`p', quoted
         tokenize `"`COLNAMES'"'
         while "`1'" ~= ""         {
            local ct "`ct' `1' !"
            mac shift
         }
      } 
      if "`rt`p''" == ""           {      //  if rt NOT specified
         local rt`p' " "
         local ROWNAMES : rownames xX_eQ`p', quoted
         local ROWNAMESX = subinstr("`ROWNAMES'","_cons","intercept",1)
         tokenize `"`ROWNAMESX'"'
         while "`1'" ~= ""         {
            local rt`p' "`rt`p'' `1' !"
            mac shift
         }
      }
      capture matrix drop xX_eQ`p' 
   }

*  matrix xX_`p'_*:  matrices:  coefficients, standard errors, z-statistics, p-values
*     obtained from r(table) 

**# est:  matrices:  coeff, se, z, p
   forvalues p = 1/`n_est'         {

      tokenize `eqs`p'', parse(" ")
      local k = 1
      while "`1'" ~= ""            {
         qui estimates restore `1'
         qui estimates replay
         matrix xXqQ`k' = r(table)
         capture local DF`p'`k' = r(table)["df",1]
         if _rc~=0  | (`DF`p'`k''==.) {
            local DF`p'`k' = e(N) - (e(df_m) + 1)     //  df
         }
         local ++k
         mac shift
      }
      local K = `k' - 1
     
      forvalues k = 1/`K'              {
         matrix xX_`p'`k'_b  = xXqQ`k'["b",1...]               //  coefficients
         matrix xX_`p'`k'_se = xXqQ`k'["se",1...]              //  standard errors
         capture matrix xX_`p'`k'_z  = xXqQ`k'["z",1...]       //  z statistics
         if _rc~=0    {
            capture matrix xX_`p'`k'_z  = xXqQ`k'["t",1...]    //  t statistics
         }
         matrix xX_`p'`k'_p      = xXqQ`k'["pvalue",1...]      //  p values
         matrix drop xXqQ`k'
         local ++k
      }
      local item "b se z p"
      foreach i of local item      {
         forvalues k = 1/`K'       {
            matrix colnames xX_`p'`k'_`i' = _:
            local allvars : colnames xX_`p'`k'_`i'
            local allvars = subinstr("`allvars'","b.",".",30)
            local allvars = subinstr("`allvars'","bn.",".",30)
            local allvars = subinstr("`allvars'","bo.",".",30)
            matrix colnames xX_`p'`k'_`i' = `allvars'
         }           
         matrix xX_`p'_`i' = xX_`p'1_`i'                       //  matrices fixed 
         forvalues k = 2/`K'       {
            matrix rowjoinbyname xX_`p'_`i' = xX_`p'_`i' xX_`p'`k'_`i'
         }
         forvalues k = 1/`K'       {
            matrix drop xX_`p'`k'_`i'
         }
      }

      if "`est_vars`p''" ~= ""            {
         local allvars : colnames xX_`p'_b
         local allvarsX " "
         foreach v of local allvars       {      //  strip factor notation
            tokenize "`v'", parse(".")
            if "`3'"==""                  {
               local allvarsX "`allvarsX' `1'"
            }
            if "`3'"~=""                  {
               local allvarsX "`allvarsX' `3'"
            }
         }
         tokenize "`allvarsX'", parse(" ")
         local j = 1
         while "`1'" ~= ""                {      //  locals for all vars
            local av`j' "`1'"
            local ++j
            mac shift
         }
         local AJ = `j' - 1
         local keepvars "`est_vars`p''"  
         local keepvarsX = subinstr("`keepvars'","i."," ",30)      //  strip factor notation
         tokenize "`keepvarsX'", parse(", ")
         local j = 1
         while "`1'" ~= ""                {      //  locals for keep vars
            if "`1'"~=","                 {
               local kv`j' "`1'"
               local ++j
            }
            mac shift
         }
         local KJ = `j' - 1
         forvalues j = 1/`AJ'             {
            local C`j' = 0
            forvalues v = 1/`KJ'          {
               if "`kv`v''"=="`av`j''"    {
                  local C`j' = 1                 //  columns to keep 
               }
            }
         }
         foreach i of local item          {      //  single-column matrices - keep vars
            local kc = 0
            forvalues j = 1/`AJ'          {
               if `C`j''== 1              {
                  local ++kc
                  matrix cCcC_`i'_`kc' = xX_`p'_`i'[1...,`j']
               }
            }
         }
         local KC = `kc'
         foreach i of local item          {      //  join columns for keep vars
            matrix gGgGgG = cCcC_`i'_1
            matrix drop cCcC_`i'_1
            forvalues kc = 2/`KC'         {
               matrix gGgGgG = gGgGgG,cCcC_`i'_`kc'
               matrix drop cCcC_`i'_`kc'
            }
            matrix xX_`p'_`i' = gGgGgG           //  matrices fixed, reduced
            matrix drop gGgGgG
         }
      }

   }


**# est:  matrices final:  coeff, se, z, p, ci
*  matrix xX_C#:    coefficients
*  matrix xX_SE#:   standard errors
*  matrix xX_ZV#:   z-statistics
*  matrix xX_PV#:   p-values

   forvalues p = 1/`n_est'   {
      matrix xX_C`p'  = xX_`p'_b'
      matrix xX_SE`p' = xX_`p'_se'
      matrix xX_ZV`p' = xX_`p'_z'
      matrix xX_PV`p' = xX_`p'_p'
      if `p' == 1            {
         local n_colD : colsof xX_C`p'
      }
      local n_rowD`p' : rowsof xX_C`p'
      matrix drop xX_`p'_b  xX_`p'_se  xX_`p'_z  xX_`p'_p
   }


*  matrices pvx#:  vector of p-values ( "1" "2" "3" according to p-value thresholds; miss = -99 )
*  matrices ci_l#: vector of confidence interval lower value  [computed: se,DF,p] 
*  matrices ci_u#: vector of confidence interval upper value  [computed: se,DF,p] 

   forvalues p = 1/`n_est'             {
      forvalues c = 1/`n_colD'         {
         matrix pvx`p'`c'  = J(`n_rowD`p'',1,0)
         matrix ci_l`p'`c' = J(`n_rowD`p'',1,0)
         matrix ci_u`p'`c' = J(`n_rowD`p'',1,0)
         forvalues r = 1/`n_rowD`p''   {
            scalar coef_`r'_`c' = xX_C`p'[`r',`c']
            scalar se_`r'_`c'   = xX_SE`p'[`r',`c']
            scalar pv_`r'_`c'   = xX_PV`p'[`r',`c']
            tempvar pvx_`r'_`c'
            gen `pvx_`r'_`c'' = -99
            forvalues PVX = 1/`num_es'  {
               replace `pvx_`r'_`c'' = `PVX'  if (pv_`r'_`c'<=`pv`PVX'')
            }
            scalar ci_l_`r'_`c' = coef_`r'_`c' - (invttail(`DF`p'`c'',`ci_p')*se_`r'_`c')
            scalar ci_u_`r'_`c' = coef_`r'_`c' + (invttail(`DF`p'`c'',`ci_p')*se_`r'_`c')
            matrix ci_l`p'`c'[`r',1] = ci_l_`r'_`c'
            matrix ci_u`p'`c'[`r',1] = ci_u_`r'_`c'
            sum `pvx_`r'_`c'', meanonly
            matrix pvx`p'`c'[`r',1]  = `r(mean)'
            scalar drop coef_`r'_`c'  se_`r'_`c'  pv_`r'_`c'
            scalar drop ci_l_`r'_`c' ci_u_`r'_`c'
            capture macro drop _pvx_`r'_`c'
         }
      }
   }


*  matrix xX_PVX#:  p-values  ( "1" "2" "3" according to p-value thresholds; miss = -99 )
*  matrix xX_CI#:   confidence interval bounds - lower and upper

   forvalues p = 1/`n_est'      {

      local PVX "pvx`p'1"
      forvalues c = 2/`n_colD'  {
         local PVX "`PVX',pvx`p'`c'"
      }
      matrix xX_PVX`p' = `PVX'

      local CI "ci_l`p'1,ci_u`p'1"
      forvalues c = 2/`n_colD'  {
         local CI "`CI',ci_l`p'`c',ci_u`p'`c'"
      }
      matrix xX_CI`p' = `CI'

   }


*  define matrices for standard errors (or t-statistic or p-value or confidence-interval):

   forvalues k = 1/2                {
      if `"`est_se`k''"' ~= ""      {
         forvalues p = 1/`n_est'    {
            if "`STPC`k''" == "se"  {
               matrix xX_STPC`k'`p' = xX_SE`p'
            }
            if "`STPC`k''" == "z"   {
               matrix xX_STPC`k'`p' = xX_ZV`p' 
            }
            if "`STPC`k''" == "p"   {
               matrix xX_STPC`k'`p' = xX_PV`p'
            }
            if "`STPC`k''" == "ci"  {
               matrix xX_STPC`k'`p' = xX_CI`p'
            }
         }
      }
   }


*  matrices STAT#:  statistics (N, r-squared, BIC, etc.) 

   forvalues p = 1/`n_est'     {
      local n_rowS`p' = 0
   }
   if "`est_stat1'"~=""    {
      forvalues p = 1/`n_est'  {
         qui estimates table `eqs`p'', stat(`stats`p'')
         matrix STAT`p' = r(stats)
         local n_rowS`p'  : rowsof STAT`p'      //  # stat rows in each panel
         local STnameX`p' : rownames STAT`p'    //  stat names in each panel
         local STnameZ `" "'
         foreach s of local STnameX`p'  {
            local STITLE "`s'"
            tokenize `"`sttitles'"'
            while `"`1'"'~=""           {
               if "`s'"==`"`1'"'        {
                  local STITLE `"`2'"'
                  continue, break
               }
               mac shift 2
            }
            local STnameZ `" `STnameZ' `"`STITLE'"' "'
         }
         matrix rownames STAT`p' = `STnameZ'
     }
   }




**# est:  add_means 
*  **********************************
*
*  ****  ADD_MEANS OPTION  ****
*
*  **********************************

   local ADD_SIDE "left"
   local n_colM = 0

   if "`add_means'" ~= ""          {
      local k = 0
      tokenize "`add_means'", parse(" ,")
      local ADD_SIDE = cond("`1'"=="left" | "`1'"=="right","`1'","left")
      while "`1'" ~= ""            {
         if "`1'"~="left" & "`1'"~="right" & "`1'" ~= ","   {
            local ++k
            estimates restore `1'
            qui margins, atmeans          //  or, could employ estat summarize
            matrix xX_MEANS`k' = r(at)'
            local n_colM = 1
         }
         mac shift
      }
      if `k' ~= `n_p'              {
         noi di _n(2) _col(3) in y  "ERROR:  add_means - number of equation names unequal to number of panels"   _n(1) " "
         exit  
      }
   }  




**# est:  add_mat
*  **************************
*
*  ****  ADD_MAT OPTION  ****
*
*  **************************

   if "`add_mat'" ~= ""          {
      local k = 0
      tokenize "`add_mat'", parse(" ,")
      local ADD_SIDE = cond("`1'"=="left" | "`1'"=="right","`1'","left")
      while "`1'" ~= ""          {
         if "`1'"~="left" & "`1'"~="right" & "`1'" ~= ","   {
            local ++k
            matrix xX_MAT`k' = `1'
            local n_rowM`k' : rowsof xX_MAT`k'
            local n_colM`k' : colsof xX_MAT`k'
         }
         mac shift
      }
      if `k' ~= `n_p'            {
         noi di _n(2) _col(3) in y  "ERROR:  add_mat - number of matrix names unequal to number of panels"   _n(1) " "
         exit  
      }
      forvalues p = 1/`n_p'      { 
         forvalues P = 1/`n_p'   {
            if `n_colM`p'' ~= `n_colM`P''  {
               noi di _n(2) _col(3) in y  "ERROR:  add_mat - number of matrix columns must be the same in all panels"
               noi di _n(1) " "
               exit
            }
         }
      }
      local n_colM = `n_colM1'
   }  




**# matrix for putdocx table
*  **********************************************
*
*  ****  CONSTRUCT MATRIX FOR PUTDOCX TABLE  ****
*
*  **********************************************

*  matrix for input to putdocx table:
*      xX_C    if no statistics have been requested
*      xX_CM   if no statistics, but means or matrix have been requested
*      xX_CZ   if statistics have been requested [ xX_CZ = xX_C + STAT ]
*      xX_CZM  if statistics and means/matrix have been requested  [ xX_CZM = xX_CM + STAT ] 

   matrix xX_C = xX_C1
   forvalues p = 2/`n_est'      {
      matrix xX_C = xX_C \ xX_C`p'
   }
   local mat "xX_C"
   if "`est_stat1'" ~= ""       {
      matrix xX_CZ1 = xX_C1 \ STAT1
      matrix xX_CZ = xX_CZ1
      forvalues p = 2/`n_est'   { 
         matrix xX_CZ`p' = xX_C`p' \ STAT`p'
         matrix xX_CZ = xX_CZ \ xX_CZ`p'
      }
      local mat "xX_CZ"
   } 
   if "`add_means'"~="" & "`est_stat1'"==""   {
      if "`ADD_SIDE'" == "left"               {
         matrix coljoinbyname xX_CM1 = xX_MEANS1 xX_C1
         matrix xX_CM = xX_CM1
         forvalues p = 2/`n_est'              {
            matrix coljoinbyname xX_CM`p' = xX_MEANS`p' xX_C`p'
            matrix xX_CM = xX_CM \ xX_CM`p'
         }
      }
      if "`ADD_SIDE'" == "right"              {
         matrix coljoinbyname xX_CM1 = xX_C1 xX_MEANS1
         matrix xX_CM = xX_CM1
         forvalues p = 2/`n_est'              {
            matrix coljoinbyname xX_CM`p' = xX_C`p' xX_MEANS`p'
            matrix xX_CM = xX_CM \ xX_CM`p'
         }
      }
      local mat "xX_CM"
   }
   if "`add_means'"~="" & "`est_stat1'"~=""   {
      if "`ADD_SIDE'" == "left"               {
         matrix coljoinbyname xX_CZM1 = xX_MEANS1 xX_CZ1
         matrix xX_CZM = xX_CZM1
         forvalues p = 2/`n_est'              {
            matrix coljoinbyname xX_CZM`p' = xX_MEANS`p' xX_CZ`p'
            matrix xX_CZM = xX_CZM \ xX_CZM`p'
         }
      }
      if "`ADD_SIDE'" == "right"              {
         matrix coljoinbyname xX_CZM1 = xX_CZ1 xX_MEANS1
         matrix xX_CZM = xX_CZM1
         forvalues p = 2/`n_est'              {
            matrix coljoinbyname xX_CZM`p' = xX_CZ`p' xX_MEANS`p'
            matrix xX_CZM = xX_CZM \ xX_CZM`p'
         }
      }
      local mat "xX_CZM"
   }
   if "`add_mat'"~=""                         {     //  truncate rows if exceeds rows in xX_C matrix 
      forvalues p = 1/`n_est'                 {
         matrix xX_M`p' = xX_MAT`p'
         if `n_rowM`p'' > `n_rowD`p''         {
            matrix xX_M`p' = xX_MAT`p'[1..`n_rowD`p'', 1..`n_colM`p'']
         }
      }      
   }
   if "`add_mat'"~="" & "`est_stat1'"==""     {
      local n_colCM = `n_colD' + `n_colM1'
      local leftX  = `n_colM1' + 1
      local rightX = `n_colD'  + 1
      forvalues p = 1/`n_est'                 {     
         matrix xX_CM`p' = J(`n_rowD`p'',`n_colCM',.)   //  create empty matrix
         if "`ADD_SIDE'" == "left"            {
            matrix xX_CM`p'[1,1] = xX_M`p'
            matrix xX_CM`p'[1,`leftX'] = xX_C`p'
         }
         if "`ADD_SIDE'" == "right"           {
            matrix xX_CM`p'[1,1] = xX_C`p'
            matrix xX_CM`p'[1,`rightX'] = xX_M`p'
         }
      }
      matrix xX_CM = xX_CM1
      forvalues p = 2/`n_est'                 {
         matrix xX_CM = xX_CM \ xX_CM`p'
      }
      local mat "xX_CM"
   }
   if "`add_mat'"~="" & "`est_stat1'"~=""     {
      local n_colCM = `n_colD' + `n_colM1'
      local leftX  = `n_colM1' + 1
      local rightX = `n_colD'  + 1
      forvalues p = 1/`n_est'                 {     
         local n_rowDS`p' = `n_rowD`p'' + `n_rowS`p''
         matrix xX_CZM`p' = J(`n_rowDS`p'',`n_colCM',.)   //  create empty matrix
         if "`ADD_SIDE'" == "left"            {
            matrix xX_CZM`p'[1,1] = xX_M`p'
            matrix xX_CZM`p'[1,`leftX'] = xX_CZ`p'
         }
         if "`ADD_SIDE'" == "right"           {
            matrix xX_CZM`p'[1,1] = xX_CZ`p'
            matrix xX_CZM`p'[1,`rightX'] = xX_M`p'
         }
      }
      matrix xX_CZM = xX_CZM1
      forvalues p = 2/`n_est'                 {
         matrix xX_CZM = xX_CZM \ xX_CZM`p'
      }
      local mat "xX_CZM"
   }
  
  
}     //  end processing est  



**# add_excel - finishing
*  **************************
*
*  ****  ADD_EXCEL - FINISHING
*
*  ***************************

if `"`add_excel'"' ~= ""         {
   local n_rows : rowsof `mat'
   matrix xX_EXC = J(`n_rows',`n_colE',.)
   if "`EXC_SIDE'" == "left"     {
      matrix `mat' = xX_EXC,`mat'
   }
   if "`EXC_SIDE'" == "right"    {
      matrix `mat' = `mat',xX_EXC
   }
}



**# est:  est_no
*  *************************
*
*  ****  EST_NO OPTION  ****
*
*  *************************

*  identify "no" columns (accounting for extra means/matrix/excel columns)

   forvalues c = 1/`n_colD'        { 
      local est_no`c' "yes"
   }
   if "`est_no'" ~= ""             {
      tokenize "`est_no'", parse(" ,")
      while "`1'" ~= ""            {
         forvalues c = 1/`n_colD'  {
            if "`1'" == "`c'"      {
               if ("`EXC_SIDE'"=="left" & `n_colE'>0) & ("`ADD_SIDE'"=="right" | `n_colM'==0)  { 
                  local d = `c' + `n_colE'
                  local est_no`d' "no"
               }
               if ("`ADD_SIDE'"=="left" & `n_colM'>0) & ("`EXC_SIDE'"=="right" | `n_colE'==0)  { 
                  local d = `c' + `n_colM'
                  local est_no`d' "no"
               }
               if ("`EXC_SIDE'"=="left" & `n_colE'>0) & ("`ADD_SIDE'"=="left" & `n_colM'>0)    { 
                  local d = `c' + `n_colE' + `n_colM'
                  local est_no`d' "no"
               }
               if "`ADD_SIDE'"=="right" & ("`EXC_SIDE'"=="right" | `n_colE'==0)  { 
                  local d = `c' 
                  local est_no`d' "no"
               }
               if "`EXC_SIDE'"=="right" & ("`ADD_SIDE'"=="right" | `n_colM'==0)  { 
                  local d = `c' 
                  local est_no`d' "no"
               }
               if `n_colE'==0 & `n_colM'==0  {
                  local d = `c'
                  local est_no`d' "no"
               }
            }
         }
         mac shift
      }
   }   



*  **************************
*
*  ****  INPUT CLEAN UP  ****
*
*  **************************


if "`est1'" ~= ""  {
   forvalues p = 1/`n_est'  {
      capture matrix drop xX_eQ`p'
      capture matrix drop STAT`p'
      capture matrix drop V`p'
   }
   forvalues c = 1/`n_colD'      {
      capture matrix drop coef`c'
      capture matrix drop var`c'
      forvalues p = 1/`n_est'    {
         capture matrix drop se`p'`c'
         capture matrix drop tv`p'`c'
         capture matrix drop pv`p'`c'
         capture matrix drop pvx`p'`c'
         capture matrix drop ci_l`p'`c'
         capture matrix drop ci_u`p'`c'
      }
   }
}




******************************************************************************************
******************************************************************************************


**# initialize rows and columns
*  ********************************
*
*  **** INITIALIZE DIMENSIONS  ****
*
*  ********************************


*  Guide to rows and columns
*
*     n_rowD   number data rows (coefficients or matrix elements):        all panels
*     n_rowS   number statistics rows (N, r-squared, BIC, etc):           all panels
*
*     n_colD   number of data columns (equations or matrix elements), excluding means/matrices
*     n_colM   number of means/matrix columns
*     n_colE   number of excel columns
*     n_colT   number of data/means/matrix/excel columns
*     n_colTX  number of columns:  row title + data/means/matrix/excel columns
*
*     col_DF   first data column (accounting for row title column = 1)
*     col_DL   last data column (accounting for extra columns: row title, stars, se)
*     col_MF   first means/matrix column (accounting for row title column = 1)
*     col_ML   last means/matrix column (accounting for row title column = 1) 
*     col_EF   first excel column (accounting for row title column = 1)
*     col_EL   last excel column (accounting for row title column = 1) 
*     col_F    first data/means/matrix/excel column (accounting for row title column = 1)
*     col_L    last data/means/matrix/excel column (accounting for row title column = 1)
*
*     row_SP   column spanning title row
*     row_C    column title row
*
*     row_F    first data row                                       first row, first panel
*     row_L    last data/coeff row:                                 last row, last panel
*     row_LS   last data/coeff/stat row:                            after all panels
*     row_LSE  last data/coeff/stat/extra row:                      after all panels
*     row_N    first row of notes                                   after all panels
*
*     n_rowD#  number data rows (coefficients or matrix elements):  panel-specific
*     n_rowS#  number statistics rows (N, r-squared, BIC, etc):     panel-specific
*
*     row_F#   first data row:                                      panel-specific
*     row_L#   last data/coeff row:                                 panel-specific
*     row_LS#  last data/coeff/stat row:                            panel-specific
*
*     note:  panel-specific are absolute -- based on row_F, not renumbered panel-by-panel



*  ****************
*
*  ****  ROWS  ****
*
*  ****************


*  Guide to rows
*
*     n_rowD   number data rows (coefficients or matrix elements):        all panels
*     n_rowS   number statistics rows (N, r-squared, BIC, etc):           all panels
*
*     row_SP   column spanning title row
*     row_C    column title row
*
*     row_F    first data row                                       first row, first panel
*     row_L    last data/coeff row:                                 last row, last panel
*     row_LS   last data/coeff/stat row:                            after all panels
*     row_LSE  last data/coeff/stat/extra row:                      after all panels
*     row_N    first row of notes                                   after all panels
*
*     n_rowD#  number data rows (coefficients or matrix elements):  panel-specific
*     n_rowS#  number statistics rows (N, r-squared, BIC, etc):     panel-specific
*
*     row_F#   first data row:                                      panel-specific
*     row_L#   last data/coeff row:                                 panel-specific
*     row_LS#  last data/coeff/stat row:                            panel-specific
*
*     note:  panel-specific are absolute -- based on row_F, not renumbered panel-by-panel


local row_C  = 1                             //  column title row
local row_F  = 2                             //  first data/coeff row 

forvalues p = 1/`n_p'      {                 //  panel-specific first and last data row
   if `p' == 1   {
      local n_rowD   = `n_rowD1'             //  # data/coeff rows all panels
      local n_rowS   = `n_rowS1'             //  # stat rows all panels
      local row_F1   = `row_F'
      local row_L1   = `row_F'  + (`n_rowD1' - 1)
      local row_LS1  = `row_L1' + `n_rowS1'  //  last data/coeff/stat row, panel 1 (stat rows added in)
      local row_L    = `row_L1'              //  last data/coeff row (after all panels)
      local row_LS   = `row_LS1'             //  last data/coeff/stat row (after all panels)
      local row_LSE  = `row_LS1'             //  last data/coeff/stat/extra row (after all panels)
   }
   if `p' > 1    {
      local n_rowD     = `n_rowD' + `n_rowD`p''       //  # data/coeff rows all panels
      local n_rowS     = `n_rowS' + `n_rowS`p''       //  # stat rows all panels
      local q = `p' - 1
      local row_F`p'   = `row_F`q''  + `n_rowD`q'' + `n_rowS`q''    
      local row_L`p'   = `row_LS`q'' + `n_rowD`p''    //  last data/coeff row, panel_specific
      local row_LS`p'  = `row_L`p''  + `n_rowS`p''    //  last data/coeff/stat row, panel-specific (stat rows added ub)
      local row_L      = `row_L`p''                   //  last data/coeff row (after all panels)
      local row_LS     = `row_LS`p''                  //  last data/coeff/stat row (after all panels)
      local row_LSE    = `row_LS`p''                  //  last data/coeff/stat/extra row (after all panels)
   }
}



*  *******************
*
*  ****  COLUMNS  ****
*
*  *******************


local n_colT  = `n_colD' + `n_colM' + `n_colE'
local n_colTX = `n_colT' + 1


*  taking account of means/matrix columns  AND  excel columns

local col_MF = 0
local col_ML = 0
local col_EF = 0
local col_EL = 0

if `n_colM'==0 | "`ADD_SIDE'"=="right"           {    //  add NOT on left (right or missing)
   if `n_colE'==0                                {    //  excel missing
      local col_DF = 1 + 1 
      local col_DL = `col_DF' + (`n_colD' - 1)
      if "`est_star'"~="" | `"`est_se2'"'~=""    {
         local col_DL = `col_DF' + ((2*`n_colD') - 1)
      }
      if "`add_means'"~="" | "`add_mat'"~=""     {
         local col_MF = `col_DL' + 1
         local col_ML = `col_MF' + (`n_colM' - 1)
      }
   }
   if `n_colE'>0 & "`EXC_SIDE'" == "right"       {    //  excel on right
      local col_DF  = 1 + 1 
      local col_DL  = `col_DF'  + (`n_colD' - 1)
      local col_DLX = `col_DF'  + (`n_colD' - 1)      //  for use when inputting excel cell values
      local col_EFX = `col_DL'  + 1                
      if "`est_star'"~="" | `"`est_se2'"'~=""    {
         local col_DL = `col_DF' + ((2*`n_colD') - 1)
      }
      local col_EF = `col_DL' + 1
      local col_EL = `col_EF' + (`n_colE' - 1)
      if "`add_means'"~="" | "`add_mat'"~=""     {
         local col_MF  = `col_DL'  + 1
         local col_ML  = `col_MF'  + (`n_colM' - 1)
         local col_EF  = `col_ML'  + 1
         local col_EL  = `col_EF'  + (`n_colE' - 1)
         local col_EFX = `col_DLX' + `n_colM' + 1
      }
   }
   if `n_colE'>0 & "`EXC_SIDE'" == "left"        {    //  excel on left
      local col_DF = 1 + `n_colE' + 1 
      local col_DL = `col_DF' + (`n_colD' - 1)
      if "`est_star'"~="" | `"`est_se2'"'~=""    {
         local col_DL = `col_DF' + ((2*`n_colD') - 1)
      }
      local col_EF = 1 + 1
      local col_EL = `col_EF' + (`n_colE' - 1)
      if "`add_means'"~="" | "`add_mat'"~=""     {
         local col_MF = `col_DL' + 1
         local col_ML = `col_MF' + (`n_colM' - 1)
      }
   }
}

if `n_colM'>0 & "`ADD_SIDE'"=="left"             {    //  add on left
   if `n_colE'==0                                {    //  excel missing
      local col_DF = 1 + `n_colM' + 1
      local col_DL = `col_DF' + (`n_colD' - 1)
      if "`est_star'"~="" | `"`est_se2'"'~=""    {
         local col_DL = `col_DF' + ((2*`n_colD') - 1)
      }
      local col_MF = 1 + 1
      local col_ML = `col_MF' + (`n_colM' - 1)
   }
   if "`EXC_SIDE'" == "right"                    {    //  excel on right
      local col_DF  = 1 + `n_colM' + 1
      local col_DL  = `col_DF'  + (`n_colD' - 1)
      local col_EFX = `col_DL'  + 1                   //  for use when inputting excel cell values
      if "`est_star'"~="" | `"`est_se2'"'~=""    {
         local col_DL = `col_DF' + ((2*`n_colD') - 1)
      }
      local col_MF = 1 + 1
      local col_ML = `col_MF' + (`n_colM' - 1)
      local col_EF = `col_DL' + 1
      local col_EL = `col_EF' + (`n_colE' - 1)
   }
   if `n_colE'>0 & "`EXC_SIDE'" == "left"        {    //  excel on left
      local col_DF = 1 + `n_colE' + `n_colM' + 1 
      local col_DL = `col_DF' + (`n_colD' - 1)
      if "`est_star'"~="" | `"`est_se2'"'~=""    {
         local col_DL = `col_DF' + ((2*`n_colD') - 1)
      }
      local col_EF = 1 + 1
      local col_EL = `col_EF' + (`n_colE' - 1)
      local col_MF = `col_EL' + 1
      local col_ML = `col_MF' + (`n_colM' - 1)
   }
}
if "`col_EFX'" == ""            {
   local col_EFX = `col_EF'
}

local col_F = 2

local col_L = cond(`col_DL'>`col_ML',`col_DL',`col_ML')
local col_L = cond(`col_EL'>`col_L',`col_EL',`col_L')




******************************************************************************************
******************************************************************************************


**# formatting columns
*  ******************************
*
*  ****  FORMATTING COLUMNS  ****
*
*  ******************************


*  Guide to columns  (reprise)
*
*     n_colD   number of data columns (equations or matrix elements), excluding means/matrices
*     n_colM   number of means/matrix columns
*     n_colE   number of excel columns
*     n_colT   number of data/means/matrix/excel columns
*     n_colTX  number of columns:  row title + data/means/matrix/excel columns
*
*     col_DF   first data column (accounting for row title column = 1)
*     col_DL   last data column (accounting for extra columns: row title, stars, se)
*     col_MF   first means/matrix column (accounting for row title column = 1)
*     col_ML   last means/matrix column (accounting for row title column = 1) 
*     col_EF   first excel column (accounting for row title column = 1)
*     col_EL   last excel column (accounting for row title column = 1) 
*     col_F    first data/means/matrix/excel column (accounting for row title column = 1)
*     col_L    last data/means/matrix/excel column (accounting for row title column = 1)
*


*  width of columns  ( allowing extra columns for est_star and est_se "beside" )
*                    ( takes into account columns of means/matrices )
*                    ( accommodate replicating values )

tokenize "`colwidth'", parse(" ,")
local C = 1
while "`1'"~=""              {
   local CWX`C' "`1'"
   local ++C
   mac shift
}

*  replicating values
local C = `C' - 1
local COLWIDTH " "
forvalues c = 1/`C'          {
   tokenize "`CWX`c''", parse("*")
   local hit`c' = 0
   while "`1'"~=""           {
      if "`1'"=="*"          {
         local hit`c' = 1    
      }
      mac shift
   }
   if `hit`c''==0            {
      if "`CWX`c''" ~= ","   {
         if `c'<`C'          {
            local CWZ`c' "`CWX`c'',"
         }
         if `c'==`C'          {
            local CWZ`c' "`CWX`c''"
         }
      } 
   }     
   if `hit`c''==1            {
      tokenize "`CWX`c''", parse("*")
      local CWZ`c' "`3',"
      forvalues r = 2/20     {
         if `1'>`r'          {
            local CWZ`c' "`CWZ`c''`3',"
         }
         if `1'==`r'         {
            if `c'<`C'       {
               local CWZ`c' "`CWZ`c''`3',"
            }
            if `c'==`C'      {
               local CWZ`c' "`CWZ`c''`3'"
            }
         }
         if `1'<`r'          {
            continue, break
         }
      }
   }  
   local COLWIDTH "`COLWIDTH'`CWZ`c''"
}
local colwidth "`COLWIDTH'"

tokenize "`colwidth'", parse(" ,")
local c = 1
while "`1'"~=""              {
   if "`1'" ~= ","           {
      local CW`c' "`1'" 
      local ++c
   }
   mac shift
}
local cw1 "1"                      //  1 inch default
local CWX "1"                      //  1 inch default
forvalues c = 1/`n_colTX'    {
   if "`CW`c''" ~= ""        {     
      local cw`c' "`CW`c''" 
      local CWX "`CW`c''"
   }
   if "`CW`c''" == ""        {     //  extend last value
      local cw`c' "`CWX'"
   }
}   
                       
if "`est_star'"=="" & `"`est_se2'"'==""   {
   forvalues c = 1/`n_colTX'     {
      local colwidth`c' "1in"
      if "`cw`c''" ~= ""         {
         local colwidth`c' "`cw`c''in"
      }
   }
}
 
if "`est_star'" ~= ""            {
   local cwmin = `cw2'
   forvalues c = 3/`n_colTX'     {
      if `cw`c'' < `cwmin'       {
         local cwmin = `cw`c''
      }
   }
   if `cwmin' < 0.10             {
      local cwmin = 0.10
   }
   local colwidth1 "`cw1'in"
   local k = `col_DF'
   forvalues c = `col_DF'(2)`col_DL'    {
      local d = `c' + 1
      local colwidth`c' "1in"
      if "`cw`k''" ~= ""         {
         local colwidth`c' "`cw`k''in"    
         local cwst`d' = 0.4*`cwmin'
         local colwidth`d' "`cwst`d''in"
      }
      local ++k
   }
   if `n_colM' > 0                     {
      local k = 2
      if "`ADD_SIDE'"=="right" & "`EXC_SIDE'"=="right"                 {
         local k = `n_colD' + 2
      }
      if "`ADD_SIDE'"=="right" & ("`EXC_SIDE'"=="left" & `n_colE'>0)   {
         local k = `n_colD' + `n_colE' + 2
      }
      if "`ADD_SIDE'"=="left" & ("`EXC_SIDE'"=="left" & `n_colE'>0)    {
         local k = `n_colE' + 2
      }
      forvalues c = `col_MF'/`col_ML'  {
         local colwidth`c' "1in"
         if "`cw`k''" ~= ""            {
            local colwidth`c' "`cw`k''in"
         }
         local ++k
      }
   } 
   if `n_colE' > 0                            {
      local k = 2
      if "`EXC_SIDE'"=="right" & `n_colM'>0   {
         local k = `n_colD' + `n_colM' + 2
      }
      forvalues c = `col_EF'/`col_EL'         {
         local colwidth`c' "1in"
         if "`cw`k''" ~= ""                   {
            local colwidth`c' "`cw`k''in"
         }
         local ++k
      }
   } 
}

if `"`est_se2'"' ~= ""                  {
   local colwidth1 "`cw1'in"
   local k = `col_DF'
   forvalues c = `col_DF'(2)`col_DL'    {
      local colwidth`c' "1in"
      if "`cw`k''" ~= ""         {
         local colwidth`c' "`cw`k''in"    
      }
      local ++k
   }
   local col_DFX = `col_DF' + 1
   local k = `col_DF'
   forvalues c = `col_DFX'(2)`col_DL'  {
      local colwidth`c' "0.9in"
      if "`STPC2'" ~= "ci"             {
         if "`cw`k''" ~= ""            {
            local cwX = 0.75*`cw`k''
            local colwidth`c' "`cwX'in"
            if "`beside_width'"~= ""   {
               local colwidth`c' "`beside_width'in"
            }     
         }
      }
      if "`STPC2'" == "ci"             {
         if "`cw`k''" ~= ""            {
            local cwX = 1.4*`cw`k''
            local colwidth`c' "`cwX'in"     
         }
      }
      local ++k
   }
   if `n_colM' > 0                     {
      local k = 2
      if "`ADD_SIDE'"=="right" & "`EXC_SIDE'"=="right"                 {
         local k = `n_colD' + 2
      }
      if "`ADD_SIDE'"=="right" & ("`EXC_SIDE'"=="left" & `n_colE'>0)   {
         local k = `n_colD' + `n_colE' + 2
      }
      if "`ADD_SIDE'"=="left" & ("`EXC_SIDE'"=="left" & `n_colE'>0)    {
         local k = `n_colE' + 2
      }
      forvalues c = `col_MF'/`col_ML'  {
         local colwidth`c' "1in"
         if "`cw`k''" ~= ""            {
            local colwidth`c' "`cw`k''in"
         }
         local ++k
      }
   } 
   if `n_colE' > 0                            {
      local k = 2
      if "`EXC_SIDE'"=="right" & `n_colM'>0   {
         local k = `n_colD' + `n_colM' + 2
      }
      forvalues c = `col_EF'/`col_EL'         {
         local colwidth`c' "1in"
         if "`cw`k''" ~= ""                   {
            local colwidth`c' "`cw`k''in"
         }
         local ++k
      }
   } 
}



* total width of table

local WIDTH = 0
forvalues c = 1/`col_L'                              {
   if "`colwidth`c''"~="" & "`colwidth`c''"~="."     {
      local W  = subinstr("`colwidth`c''","in","",1)
      local WIDTH = `WIDTH' + real("`W'")
   }
}
if "`add_cols'" ~= ""  {
   local WIDTH = `WIDTH' + `extra_width'
}


*  Guide to rows and columns  (reprise)
*
*     n_rowD   number data rows (coefficients or matrix elements):        all panels
*     n_rowS   number statistics rows (N, r-squared, BIC, etc):           all panels
*
*     n_colD   number of data columns (equations or matrix elements), excluding means/matrices
*     n_colM   number of means/matrix columns
*     n_colE   number of excel columns
*     n_colT   number of data/means/matrix/excel columns
*     n_colTX  number of columns:  row title + data/means/matrix/excel columns
*
*     col_DF   first data column (accounting for row title column = 1)
*     col_DL   last data column (accounting for extra columns: row title, stars, se)
*     col_MF   first means/matrix column (accounting for row title column = 1)
*     col_ML   last means/matrix column (accounting for row title column = 1) 
*     col_EF   first excel column (accounting for row title column = 1)
*     col_EL   last excel column (accounting for row title column = 1) 
*     col_F    first data/means/matrix/excel column (accounting for row title column = 1)
*     col_L    last data/means/matrix/excel column (accounting for row title column = 1)
*
*     row_SP   column spanning title row
*     row_C    column title row
*
*     row_F    first data row                                       first row, first panel
*     row_L    last data/coeff row:                                 last row, last panel
*     row_LS   last data/coeff/stat row:                            after all panels
*     row_LSE  last data/coeff/stat/extra row:                      after all panels
*     row_N    first row of notes                                   after all panels
*
*     n_rowD#  number data rows (coefficients or matrix elements):  panel-specific
*     n_rowS#  number statistics rows (N, r-squared, BIC, etc):     panel-specific
*
*     row_F#   first data row:                                      panel-specific
*     row_L#   last data/coeff row:                                 panel-specific
*     row_LS#  last data/coeff/stat row:                            panel-specific
*
*     note:  panel-specific are absolute -- based on row_F, not renumbered panel-by-panel


**# number of decimals
*  ******************************
*
*  ****  NUMBER OF DECIMALS  ****
*
*  ******************************

*  format of data columns: number of decimals
*     ( allowing extra columns for est_star and est_se "beside" )
*     ( attending to column-wise vs. row-wise )
*     ( accommodate replicating values )
*  default = %10.1fc


if "`dec1'" == ""               {
   if "`decimals'" ~= ""        {
      forvalues p = 1/`n_p'     {
         local DECIMAL`p' "`decimals'"
      }
   }
}
if "`dec1'" ~= ""               {
   forvalues p = 1/`n_p'        {
      if "`dec`p''"~=""         {
        local DECIMAL`p' "`dec`p''"
      }
      if "`dec`p''"==""         {
         noi di _n(1) _col(3) in y  "ERROR:  dec`p' not specified"   _n(1) " "
         exit 
      }
   }
}


*  replicating values
forvalues p = 1/`n_p'                  {
   tokenize "`DECIMAL`p''", parse(" ,")
   local C = 1
   while "`1'"~=""                     {
      local SDX`C' "`1'"
      local ++C
      mac shift
   }
   local C = `C' - 1
   local DEC " "
   forvalues c = 1/`C'                 {
      tokenize "`SDX`c''", parse("*")
      local hit`c' = 0
      while "`1'"~=""                  {
         if "`1'"=="*"                 {
            local hit`c' = 1    
         }
         mac shift
      }
      if `hit`c''==0                   {
         if "`SDX`c''" ~= ","          {
            if `c'<`C'                 {
               local SDZ`c' "`SDX`c'',"
            }
            if `c'==`C'                {
               local SDZ`c' "`SDX`c''"
            }
         } 
      }     
      if `hit`c''==1                   {
         tokenize "`SDX`c''", parse("*")
         local SDZ`c' "`3',"
         forvalues r = 2/20            {
            if `1'>`r'                 {
               local SDZ`c' "`SDZ`c''`3',"
            }
            if `1'==`r'                {
               if `c'<`C'              {
                  local SDZ`c' "`SDZ`c''`3',"
               }
               if `c'==`C'             {
                  local SDZ`c' "`SDZ`c''`3'"
               }
            }
            if `1'<`r'                 {
               continue, break
            }
         }
      }  
      local DEC "`DEC'`SDZ`c''"
   }
   local dec`p' "`DEC'"
}

local WISE "cols"
if "`dec1'" ~= ""                      {
   tokenize "`dec1'", parse(" ,")
   if "`1'"=="rows" | "`1'"=="row" | "`1'"=="Rows" | "`1'"=="Row"   {
      local WISE "rows"
   }
}
forvalues p = 1/`n_p'                  {
   if "`dec`p''" ~= ""                 {
      tokenize "`dec`p''", parse(" ,")
      if "`1'"=="rows" | "`1'"=="row" | "`1'"=="Rows" | "`1'"=="Row"   {
         mac shift
      }
      if "`1'"=="cols" | "`1'"=="col" | "`1'"=="Cols" | "`1'"=="Col"   {
         mac shift
      }
      local k = 1
      while "`1'"~=""                  {
         if "`1'" ~= ","               {
            local nf`p'`k' "`1'"
            local NF "`nf`p'`k''"
            local D = `1' + 1                 //  set additional decimals (if any) for standard error
            local sef`p'`k' "`D'"
            local ++k
         }
         mac shift
      }
      if "`WISE'" == "cols"            {
         forvalues j = `k'/`n_colT'    {      //  extend through all data columns
            local nf`p'`j' "`NF'"
            local sef`p'`j' "`D'"
         }
      }  
      if "`WISE'" == "rows"            {
         forvalues j = `k'/`n_rowD`p'' {      //  extend through all data rows
            local nf`p'`j' "`NF'"
            local sef`p'`j' "`D'"
         }
      }
   }      
}

if "`WISE'" == "cols"                           {
   forvalues p = 1/`n_p'                        {
      local k = 1
      forvalues c = 1/`n_colT'                  {
         forvalues r = 1/`n_rowD`p''            {
            local nform`p'`r'`c' "nformat(%10.1fc)"
            local ciform`p'`r'`c' "%10.1fc"
            local seform`p'`r'`c' "%8.2f"
            local zform`p'`r'`c'  "%3.2f"
            local pform`p'`r'`c'  "%4.3f"
            if "`dec`p''" ~= ""                 {
               if "`nf`p'`k''" ~= ""            {
                  local NFORM "%10.`nf`p'`k''fc"
               }
               local nform`p'`r'`c' "nformat(`NFORM')"
               local ciform`p'`r'`c' "`NFORM'"
               if "`sef`p'`k''" ~= ""           {
                  local seform`p'`r'`c' "%10.`sef`p'`k''fc"
               }
            }
         }
         local ++k
      }
   } 
} 

if "`WISE'" == "rows"                           {
   forvalues p = 1/`n_p'                        {
      forvalues c = 1/`n_colT'                  {
         local k = 1
         forvalues r = 1/`n_rowD`p''            {
            local nform`p'`r'`c' "nformat(%10.1fc)"
            local ciform`p'`r'`c' "%10.1fc"
            local seform`p'`r'`c' "%8.2f"
            local zform`p'`r'`c'  "%3.2f"
            local pform`p'`r'`c'  "%4.3f"
            if "`dec`p''" ~= ""                 {
               if "`nf`p'`k''" ~= ""            {
                  local NFORM "%10.`nf`p'`k''fc"
               }
               local nform`p'`r'`c' "nformat(`NFORM')"
               local ciform`p'`r'`c' "`NFORM'"
               if "`sef`p'`k''" ~= ""           {
                  local seform`p'`r'`c' "%10.`sef`p'`k''fc"
               }
            }
            local ++k
         }
      }
   } 
} 

if "`WISE'" == "cols"                           {
   if `col_EF' > 0                              {
      local c = `col_EF'
      foreach a in A B                          {
         if "`EXC_TYPE`a''"=="str"              {
            local nform`c' ""
         }
         local ++c
      }
   }
}



******************************************************************************************
******************************************************************************************


**# start table
*  ************************
*
*  **** PUTDOCX TABLE  ****
*
*  ************************



*  start document

capture putdocx clear

putdocx begin, font(`font', `b_fsize') `landscape'



*  main command

local LAYOUT "autofitwindow"
if "`TITLE1'"~="" | "`TITLE2'"~=""  {
   local MEMTABLE "memtable"
   local LAYOUT "autofitcontents"
}
local cellmargL "cellmargin(left, 0.04in)"
local cellmargR "cellmargin(right, 0.05in)"
local cellmargB "cellmargin(bottom, 0.01in)"

#d ;
putdocx table `tabname' = mat(`mat'),
   `MEMTABLE'
   layout(`LAYOUT') 
   rownames colnames 
   width(`WIDTH'in)
   `cellmargL' `cellmargR' `cellmargB'
   border(all, nil);
#d cr



*  Guide to rows and columns  (reprise)
*
*     n_rowD   number data rows (coefficients or matrix elements):        all panels
*     n_rowS   number statistics rows (N, r-squared, BIC, etc):           all panels
*
*     n_colD   number of data columns (equations or matrix elements), excluding means/matrices
*     n_colM   number of means/matrix columns
*     n_colE   number of excel columns
*     n_colT   number of data/means/matrix/excel columns
*     n_colTX  number of columns:  row title + data/means/matrix/excel columns
*
*     col_DF   first data column (accounting for row title column = 1)
*     col_DL   last data column (accounting for extra columns: row title, stars, se)
*     col_MF   first means/matrix column (accounting for row title column = 1)
*     col_ML   last means/matrix column (accounting for row title column = 1) 
*     col_EF   first excel column (accounting for row title column = 1)
*     col_EL   last excel column (accounting for row title column = 1) 
*     col_F    first data/means/matrix/excel column (accounting for row title column = 1)
*     col_L    last data/means/matrix/excel column (accounting for row title column = 1)
*
*     row_SP   column spanning title row
*     row_C    column title row
*
*     row_F    first data row                                       first row, first panel
*     row_L    last data/coeff row:                                 last row, last panel
*     row_LS   last data/coeff/stat row:                            after all panels
*     row_LSE  last data/coeff/stat/extra row:                      after all panels
*     row_N    first row of notes                                   after all panels
*
*     n_rowD#  number data rows (coefficients or matrix elements):  panel-specific
*     n_rowS#  number statistics rows (N, r-squared, BIC, etc):     panel-specific
*
*     row_F#   first data row:                                      panel-specific
*     row_L#   last data/coeff row:                                 panel-specific
*     row_LS#  last data/coeff/stat row:                            panel-specific
*
*     note:  panel-specific are absolute -- based on row_F, not renumbered panel-by-panel


*  replacing missing values with " "

local ROWS = `n_rowD' + `n_rowS'
tempvar VVV
qui gen `VVV' = .
local r = `row_F'
forvalues RR = 1/`ROWS'         {
   local c = 2
   forvalues CC = 1/`n_colT'    {
      qui replace `VVV' = `mat'[`RR',`CC']
      sum `VVV', meanonly
      if "`r(mean)'" == ""      {
         putdocx table `tabname'(`r',`c') = (" "), font(`font',`b_fsize')
      }
      if "`r(mean)'" == "-99"   {
         putdocx table `tabname'(`r',`c') = (" "), font(`font',`b_fsize')
      }
      local ++c
   }
   local ++r
}
capture drop `VVV'



*  filling in excel columns

local ROWS = `n_rowD' + `n_rowS'
local c = `col_EFX'
foreach a of local EXC_VARS     {
   local r = `row_F'
   forvalues n = 1/`ROWS'       {
      if "`exc`a'`n''"=="" | "`exc`a'`n''"=="."  {
         putdocx table `tabname'(`r',`c') = (" "), font(`font',`b_fsize')
      }
      if "`exc`a'`n''"~="" & "`exc`a'`n''"~="."  {
         putdocx table `tabname'(`r',`c') = ("`exc`a'`n''"), font(`font',`b_fsize')
      }
      local ++r
   }
   local ++c
} 



*  column titles and data cells: horizontal right align, vertical bottom align

putdocx table `tabname'(`row_C'/`row_LS',2/`n_colTX'), halign(right) valign(bottom)



**# column titles
*  column titles
*  (syntax assumes four lines maximum, separated by slashes)

if "`ct'" ~= ""         {
   tokenize "`ct'", parse("!")
   local k = 0
   local CT = 0
   while "`1'" ~= ""    {
      if "`1'" == "!"   {
         if `k' == 0   { 
            local ++k
            local ctitle`k' " "
         }
         local CT = `CT' + 1
         if `CT' >= 2   {
            local ++k
            local ctitle`k' " "
         }
      }
      if "`1'" ~= "!"  {
         local CT = 0
         local ++k
         local ctitle`k' "`1'"
      }
      mac shift
   }
}

local ctitleht "single"
forvalues c = 1/`n_colTX'                {
   if "`ctitle`c''" ~= ""                {
      tokenize "`ctitle`c''", parse("\")
      if "`3'"==""                       {
         putdocx table `tabname'(`row_C',`c') = ("`1'"), font(`font', `l_fsize') `ct_format'
      }
      if "`3'"~="" & "`5'"==""           {
         if "`ctitleht'"~="triple"  &  "`ctitleht'"~="quad"      {
            local ctitleht "double" 
         }
         if "`ct_format'"~="underline"   {
            putdocx table `tabname'(`row_C',`c') = ("`1'"), font(`font', `l_fsize') `ct_format' linebreak(1)
         }
         if "`ct_format'"=="underline"   {
            putdocx table `tabname'(`row_C',`c') = ("`1'"), font(`font', `l_fsize') linebreak(1)
         }
         putdocx table `tabname'(`row_C',`c') = ("`3'"), font(`font', `l_fsize') `ct_format' append
      }
      if "`5'"~="" & "`7'"==""           {
         if "`ctitleht'"~="quad"         {
            local ctitleht "triple" 
         }
         if "`ct_format'"~="underline"   {
            putdocx table `tabname'(`row_C',`c') = ("`1'"), font(`font', `l_fsize') `ct_format' linebreak(1)
            putdocx table `tabname'(`row_C',`c') = ("`3'"), font(`font', `l_fsize') `ct_format' append linebreak(1)
         }
         if "`ct_format'"=="underline"   {
            putdocx table `tabname'(`row_C',`c') = ("`1'"), font(`font', `l_fsize') linebreak(1)
            putdocx table `tabname'(`row_C',`c') = ("`3'"), font(`font', `l_fsize') append linebreak(1)
         }
         putdocx table `tabname'(`row_C',`c') = ("`5'"), font(`font', `l_fsize') `ct_format' append
      }
      if "`7'"~=""                       {
         local ctitleht "quad"         
         if "`ct_format'"~="underline"   {
            putdocx table `tabname'(`row_C',`c') = ("`1'"), font(`font', `l_fsize') `ct_format' linebreak(1)
            putdocx table `tabname'(`row_C',`c') = ("`3'"), font(`font', `l_fsize') `ct_format' append linebreak(1)
            putdocx table `tabname'(`row_C',`c') = ("`5'"), font(`font', `l_fsize') `ct_format' append linebreak(1)
         }
         if "`ct_format'"=="underline"   {
            putdocx table `tabname'(`row_C',`c') = ("`1'"), font(`font', `l_fsize') linebreak(1)
            putdocx table `tabname'(`row_C',`c') = ("`3'"), font(`font', `l_fsize') append linebreak(1)
            putdocx table `tabname'(`row_C',`c') = ("`5'"), font(`font', `l_fsize') append linebreak(1)
         }
         putdocx table `tabname'(`row_C',`c') = ("`7'"), font(`font', `l_fsize') `ct_format' append
      }
      if `c'==1  {
         putdocx table `tabname'(`row_C',`c'), halign(left)
      }
      if `c'>1   {
         putdocx table `tabname'(`row_C',`c'), halign(`ct_just')
      }
   }
}



*  height of column titles row (depends on number of lines)

if "`ctitleht'" == "single"     {
   local htR = `bf167'
   if `"`cst1'"' ~= ""          {
      local htR = round(`bf150')
   }
}
if "`ctitleht'" == "double"     {
   local htR = round(`bf275')
   if `"`cst1'"' ~= ""          {
      local htR = round(`bf260')
   }
}
if "`ctitleht'" == "triple"     {
   local htR = round(`bf425')
   if `"`cst1'"' ~= ""          {
      local htR = round(`bf410')
   }
}
if "`ctitleht'" == "quad"       {
   local htR = round(`bf550')
   if `"`cst1'"' ~= ""          {
      local htR = round(`bf540')
   }
}

putdocx table `tabname'(`row_C',.), height(`htR'pt, exact) valign(bottom)



**# row titles
*  row titles:  default alignments:  horizontal left, vertical bottom

putdocx table `tabname'(`row_C'/`row_LS',1), halign(left) valign(bottom)



*  row titles
*  (syntax assumes two lines maximum, separated by slashes)

forvalues p = 1/`n_p'      {
   if "`rt`p''" ~= ""  {
      local k = 0
      local RT = 0
      tokenize "`rt`p''", parse("!")
      while "`1'" ~= ""   {
         if "`1'" == "!"  {
            if `k' == 0   { 
               local ++k
               local rtitle`p'`k' " "
            }
            local RT = `RT' + 1
            if `RT' >= 2  {
               local ++k
               local rtitle`p'`k' " "
            }
         }
         if "`1'" ~= "!"  {
            local RT = 0
            local ++k
            local rtitle`p'`k' "`1'"
         }
         mac shift
      }
      if "`rst_indent'"=="indent"               {
         local K = `k'
         forvalues k = 1/`K'                    {
            forvalues j = 1/12                  {
               if `"`rst`p'`j''"' ~= ""         {
                  local RST ""
                  tokenize `"`rst`p'`j''"', parse(" ,")
                  while "`1'" ~= ""             {
                     if "`1'" ~= ","            {
                        local RST "`RST'`1',"
                     }
                     mac shift
                  }
                  tokenize `"`RST'"', parse(",")
                  if `k'>=`3' & `k'<(`3'+`5')   {
                     local indent`p'`k' "yes"
                  }
               }
            }
         }
      }
   }

   local row_RA = `row_L`p'' + 1
   local r = 1
   forvalues R = `row_F`p''/`row_LS`p''   {
      if "`rtitle`p'`r''" ~= ""  {
         tokenize "`rtitle`p'`r''", parse("\")
         if "`3'" == ""                   {
            putdocx table `tabname'(`R',1) = ("`SPACES_PT'`1'"), `rt_format' font(`font', `l_fsize') 
            if "`indent`p'`r''" == "yes"  {
               putdocx table `tabname'(`R',1) = ("`SPACES_PT'`SPACES_RST'`1'"), `rt_format' font(`font', `l_fsize') 
            }
            putdocx table `tabname'(`R',1), halign(`rt_just') valign(bottom)
            local X = strtrim("`1'")
            if "`INT_RIGHT'" == "yes" & `R'==`row_L`p''     {
               if "`X'"=="_cons" | "`X'"=="constant" | "`X'"=="Constant" |    ///
                  "`X'"=="intercept" | "`X'"=="Intercept"   {
                  putdocx table `tabname'(`R',.), height(`bf150'pt, exact) valign(center)
                  local row_RA = `row_L`p''
               }
            }
            if "`TOT_RIGHT'"=="yes" & `R'==`row_L`p''       {
               if "`X'"=="Total" | "`X'"=="total"           {
                  putdocx table `tabname'(`R',.), height(`bf150'pt, exact) valign(center)
                  local row_RA = `row_L`p''
               }
            }
         }
         if "`3'" ~= ""                   {
            putdocx table `tabname'(`R',1) = ("`SPACES_PT'`1'"), `rt_format' font(`font', `l_fsize') linebreak(1) 
            putdocx table `tabname'(`R',1) = ("`SPACES_PT`3'"), `rt_format' font(`font', `l_fsize') append 
            if "`indent`p'`r''" == "yes"  {
               putdocx table `tabname'(`R',1) = ("`SPACES_PT'`SPACES_RST'`1'"),   ///
                  `rt_format' font(`font', `l_fsize') linebreak(1) 
               putdocx table `tabname'(`R',1) = ("`SPACES_PT'`SPACES_RST'`3'"),   ///
                  `rt_format' font(`font', `l_fsize') append 
            }
            putdocx table `tabname'(`R',.), height(`bf200'pt, exact)
            putdocx table `tabname'(`R',1), halign(`rt_just') valign(bottom)
         }
      }
      local ++r
   }
   forvalues R = `row_F`p''/`row_LS`p''   {        //  right-align "Intercept" / "Total" and beyond
      if `R' >= `row_RA'  {
         putdocx table `tabname'(`R',1), halign(right)
      }
   }  
}


*  note:  row-spanning titles are below, after: insertion of columns and filling of columns
*                                        OR     insertion of rows and filling of rows
*                                       AND     deletion of columns



*  Guide to rows and columns  (reprise)
*
*     n_rowD   number data rows (coefficients or matrix elements):        all panels
*     n_rowS   number statistics rows (N, r-squared, BIC, etc):           all panels
*
*     n_colD   number of data columns (equations or matrix elements), excluding means/matrices
*     n_colM   number of means/matrix columns
*     n_colE   number of excel columns
*     n_colT   number of data/means/matrix/excel columns
*     n_colTX  number of columns:  row title + data/means/matrix/excel columns
*
*     col_DF   first data column (accounting for row title column = 1)
*     col_DL   last data column (accounting for extra columns: row title, stars, se)
*     col_MF   first means/matrix column (accounting for row title column = 1)
*     col_ML   last means/matrix column (accounting for row title column = 1) 
*     col_EF   first excel column (accounting for row title column = 1)
*     col_EL   last excel column (accounting for row title column = 1) 
*     col_F    first data/means/matrix/excel column (accounting for row title column = 1)
*     col_L    last data/means/matrix/excel column (accounting for row title column = 1)
*
*     row_SP   column spanning title row
*     row_C    column title row
*
*     row_F    first data row                                       first row, first panel
*     row_L    last data/coeff row:                                 last row, last panel
*     row_LS   last data/coeff/stat row:                            after all panels
*     row_LSE  last data/coeff/stat/extra row:                      after all panels
*     row_N    first row of notes                                   after all panels
*
*     n_rowD#  number data rows (coefficients or matrix elements):  panel-specific
*     n_rowS#  number statistics rows (N, r-squared, BIC, etc):     panel-specific
*
*     row_F#   first data row:                                      panel-specific
*     row_L#   last data/coeff row:                                 panel-specific
*     row_LS#  last data/coeff/stat row:                            panel-specific
*
*     note:  panel-specific are absolute -- based on row_F, not renumbered panel-by-panel



*  width of columns

if "`est_star'"=="" & `"`est_se2'"'==""  {
   forvalues c = 1/`col_L'   {
      putdocx table `tabname'(.,`c'), width(`colwidth`c'')
   }
}



**# format data cells
*  format data cells:  numeric format, row height  
*  (note:  statistics formatting corrected later)

forvalues p = 1/`n_p'                       {                 
   local C = 1
   forvalues c = `col_F'/`col_L'            {
      local R = 1
      forvalues r = `row_F`p''/`row_L`p''   {
         local NF "`nform`p'`R'`C''"
         scalar X = el(`mat',`R',`C')
         if X < 10000                       {
            local NF = subinstr("`nform`p'`R'`C''","fc","f",1)
         }
         putdocx table `tabname'(`r',`c'), `NF' font(`font',`b_fsize')
         local ++R
         capture scalar drop X
      }
      local ++C
   }
}

forvalues r = `row_F'/`row_LS'              {
   putdocx table `tabname'(`r',.), height(`bf125'pt, exact)
   if "`est_star'"~="" | `"`est_se2'"'~=""  {
      putdocx table `tabname'(`r',.), height(`bf133'pt, exact)
   }
}



**# est_star / est_se "beside": insert columns
*  est_star or est_se "beside":  insert columns, set width

if "`est_star'"~="" | `"`est_se2'"'~=""     {
   local c = `col_DF'
   forvalues CC = 1/`n_colD'                {
      putdocx table `tabname'(.,`c'), addcols(1, after)          
      local c = `c' + 2
   }
   forvalues c = 1/`col_L'                  {
      putdocx table `tabname'(.,`c'), width(`colwidth`c'') border(all,nil) 
   }
}



**# est_star
*  setting the asterisks in column to right of coefficients 

if "`est_star'" ~= ""               {
   tempvar AST
   qui gen `AST' = .
   forvalues p = 1/`n_p'            {
      local r = `row_F`p''
      forvalues RR = 1/`n_rowD`p''  {
         local c = `col_DF' + 1
         forvalues CC = 1/`n_colD'  {
            qui replace `AST' = xX_PVX`p'[`RR',`CC']
            sum `AST', meanonly
            if "`r(mean)'" == "-99" {
               putdocx table `tabname'(`r',`c') = (" "), font(`font', `a_fsize')
            }
            if "`r(mean)'" == "1"   {
               putdocx table `tabname'(`r',`c') = ("*"), font(`font', `a_fsize')
            }
            if "`r(mean)'" == "2"   {
               putdocx table `tabname'(`r',`c') = ("**"), font(`font', `a_fsize')
            }
            if "`r(mean)'" == "3"   {
               putdocx table `tabname'(`r',`c') = ("***"), font(`font', `a_fsize')
            }
            putdocx table `tabname'(`r',`c'), halign(left) valign(center)
            if "`est_se1'" ~= ""    {
               putdocx table `tabname'(`r',`c'), halign(left) valign(bottom)
            }
            local c = `c' + 2
         }
         local ++r
      }
   }
   capture drop `AST'
}



**# se, z, p:  beside
*  standard errors or z_statistics or p-values in column to right of coefficients:  add values, format 
*  adjust vertical alignment to center (to achieve visual alignment despite different font sizes)

local SPACES_BE ""
if "`PAREN2'"=="no" & "`beside_spaces'"=="" {
   local SPACES_BE " "
}
if "`beside_spaces'" ~= ""                  {
   forvalues j = 1/`beside_spaces'          {
      local SPACES_BE " `SPACES_BE'"
   }
}

if `"`est_se2'"'~="" & "`STPC2'"~="ci"      {
   tempvar xX_STPC
   qui gen `xX_STPC' = .
   forvalues p = 1/`n_p'                    {
      local r = `row_F`p''
      forvalues R = 1/`n_rowD`p''           {
         local c = `col_DF' + 1
         local CX = 1
         local fs = `col_DF' - 1
         local fe = `fs' + (`n_colD' - 1)
         forvalues C = `fs'/`fe'            {
            local b = `c' - 1
            qui replace `xX_STPC' = xX_STPC2`p'[`R',`CX']
            sum `xX_STPC', meanonly
            if "`r(mean)'" ~= ""            {
               local stpc : display ``STPC2'form`p'`R'`C'' `r(mean)'
               local stpc = strtrim("`stpc'")
               if "`PAREN2'" == "no"        {
                  putdocx table `tabname'(`r',`c') = ("`SPACES_BE'`stpc'"), font(`font', `se_fsize')
               }
               if "`PAREN2'" == "paren"     {
                  putdocx table `tabname'(`r',`c') = ("`SPACES_BE'(`stpc')"), font(`font', `se_fsize')
               }
               if "`PAREN2'" == "bracket"   {
                  putdocx table `tabname'(`r',`c') = ("`SPACES_BE'[`stpc']"), font(`font', `se_fsize')
               }
               putdocx table `tabname'(`r',`c'), halign(left) valign(center)
               putdocx table `tabname'(`r',`b'), valign(center)
            }
            local c = `c' + 2
            local ++CX
         }
         putdocx table `tabname'(`r',1), valign(center)
         local ++r
      }
   }
   if "`beside_lab'" ~= ""                  {
      local CF = `col_DF' + 1
      forvalues c = `CF'(2)`col_DL'         {
         putdocx table `tabname'(`row_C',`c') = ("`SPACES_BE'`beside_lab'"), font(`font', `se_fsize')
         putdocx table `tabname'(`row_C',`c'), halign(left) valign(bottom)
      }
   }
   capture drop `xX_STPC'
}



**# ci:  beside
*  confidence intervals in column to right of coefficients:  add values, format 
*  three indexings:  location in ci matrix [R,CX,CZ]; decimals local macro [R,C]; 
*                    location in table [r,c] 
*  adjust vertical alignment to center (for visual alignment despite different font sizes)

if `"`est_se2'"'~="" & "`STPC2'"=="ci"      {
   local n_colCI = 2*`n_colD'
   tempvar xX_STPC_L xX_STPC_U
   qui gen `xX_STPC_L' = .
   qui gen `xX_STPC_U' = .
   forvalues p = 1/`n_p'                    {
      local r = `row_F`p''
      forvalues R = 1/`n_rowD`p''           {
         local c = `col_DF' + 1
         local CX = 1
         local fs = `col_DF' - 1
         local fe = `fs' + (`n_colD' - 1)
         forvalues C = `fs'/`fe'            {
            local b = `c' - 1
            local CZ = `CX' + 1
            qui replace `xX_STPC_L' = xX_STPC2`p'[`R',`CX']
            qui replace `xX_STPC_U' = xX_STPC2`p'[`R',`CZ']
            sum `xX_STPC_L', meanonly
            if "`r(mean)'" ~= ""            {
               local stpc_l : display ``STPC2'form`p'`R'`C'' `r(mean)'
               local stpc_l = strtrim("`stpc_l'")
               sum `xX_STPC_U', meanonly
               local stpc_u : display ``STPC2'form`p'`R'`C'' `r(mean)'
               local stpc_u = strtrim("`stpc_u'")
               if "`PAREN2'" == "no"        {
                  if "`CI_SEP'" == "comma"  {
                     putdocx table `tabname'(`r',`c') = ("`SPACES_BE'`stpc_l', `stpc_u'"),      ///
                             font(`font', `ci_fsize')
                  }
                  if "`CI_SEP'" == "dash"   {
                     putdocx table `tabname'(`r',`c') = ("`SPACES_BE'`stpc_l' - `stpc_u'"),     ///
                             font(`font', `ci_fsize')
                  }
               }
               if "`PAREN2'" == "paren"     {
                  if "`CI_SEP'" == "comma"  {
                     putdocx table `tabname'(`r',`c') = ("`SPACES_BE'(`stpc_l', `stpc_u')"),     ///
                             font(`font', `ci_fsize')
                  }
                  if "`CI_SEP'" == "dash"   {
                     putdocx table `tabname'(`r',`c') = ("`SPACES_BE'(`stpc_l' - `stpc_u')"),    ///
                             font(`font', `ci_fsize')
                  }
               }
               if "`PAREN2'" == "bracket"   {
                  if "`CI_SEP'" == "comma"  {
                     putdocx table `tabname'(`r',`c') = ("`SPACES_BE'[`stpc_l', `stpc_u']"),     ///
                             font(`font', `ci_fsize')
                  }
                  if "`CI_SEP'" == "dash"   {
                     putdocx table `tabname'(`r',`c') = ("`SPACES_BE'[`stpc_l' - `stpc_u']"),    ///
                             font(`font', `ci_fsize')
                  }
               }
               putdocx table `tabname'(`r',`c'), halign(left) valign(center)
               putdocx table `tabname'(`r',`b'), valign(center)
            }
            local c = `c' + 2
            local CX = `CX' + 2
         }
         putdocx table `tabname'(`r',1), valign(center)
         local ++R
         local ++r
      }
   }
   if "`beside_lab'" ~= ""                  {
      local CF = `col_DF' + 1
      forvalues c = `CF'(2)`col_DL'         {
         putdocx table `tabname'(`row_C',`c') = ("`SPACES_BE'`beside_lab'"), font(`font', `se_fsize')
         putdocx table `tabname'(`row_C',`c'), halign(left) valign(bottom)
      }
   }
   capture drop `xX_STPC_L' `xX_STPC_U'
}



**# se, z, p, ci:  below
*  standard errors or z_statistics or p-values in row below coefficients:  add rows, add values, format
*  OR
*  confidence interval in row below coefficients:  add rows, add values, format
*     with three indexings:  location in ci matrix [R,C,CX]; decimals local macro [R,C]; 
*                            location in table [r,c] 
*  est_no cells are set to " "

if "`est_se1'" ~= ""        {

   forvalues p = 1/`n_p'    {
      local r = `row_F`p''
      local n_extra = 0
      forvalues R = `row_F`p''/`row_L`p''  {
         putdocx table `tabname'(`r',.), addrows(1, after) 
         putdocx table `tabname'(`r',.), height(`bf117'pt, exact)
         local rx = `r' + 1
         putdocx table `tabname'(`rx',.), height(`bf133'pt, exact)
         local r = `r' + 2
         local ++n_extra
      }
      local row_L`p'     = `row_L`p''   + `n_extra'
      local row_LS`p'    = `row_LS`p''  + `n_extra'
      local row_LSE`p'   = `row_LSE`p'' + `n_extra'
      local q = `p' + 1
      if `p' < `n_p'    {
         local row_F`q'   = `row_F`q''   + `n_extra'
         local row_L`q'   = `row_L`q''   + `n_extra'
         local row_LS`q'  = `row_LS`q''  + `n_extra'
      }
      local row_L   = `row_L'   + `n_extra'
      local row_LS  = `row_LS'  + `n_extra' 
      local row_LSE = `row_LSE' + `n_extra'

      if "`STPC1'" ~= "ci"                    {
         tempvar xX_STPC
         qui gen `xX_STPC' = .
         local r = `row_F`p'' + 1
         forvalues R = 1/`n_rowD`p''          {
            local c = `col_DF'
            local CX = 1
            local k = cond("`ADD_SIDE'"=="left",1 + `n_colM',1)
            local fs = `col_DF' - 1
            local fe = `fs' + (`n_colD' - 1)
            forvalues C = `fs'/`fe'           {
               qui replace `xX_STPC' = xX_STPC1`p'[`R',`CX']
               sum `xX_STPC', meanonly
               if "`r(mean)'" ~= ""           {
                  local stpc : display ``STPC1'form`p'`R'`C'' `r(mean)'
                  local stpc = strtrim("`stpc'")
                  if "`PAREN1'" == "no"       {
                     putdocx table `tabname'(`r',`c') = ("`stpc'"), font(`font', `se_fsize')
                  }
                  if "`PAREN1'" == "paren"    {
                     putdocx table `tabname'(`r',`c') = ("(`stpc')"), font(`font', `se_fsize')
                  }
                  if "`PAREN1'" == "bracket"  {
                     putdocx table `tabname'(`r',`c') = ("[`stpc']"), font(`font', `se_fsize')
                  }
                  if "`est_no'"~="" & "`est_no`k''"=="no"   {
                     putdocx table `tabname'(`r',`c') = (" ")
                  }
                  putdocx table `tabname'(`r',`c'), halign(right) valign(top)
               }
               if "`est_star'"=="" & `"`est_se2'"'==""  {
                  local c = `c' + 1
               }
               if "`est_star'"~="" | `"`est_se2'"'~=""  {
                  local c = `c' + 2
               }
               local ++CX
               local ++k
            }
            local r = `r' + 2
         }
         capture drop `xX_STPC'
      } 

      if "`STPC1'" == "ci"                      {
         tempvar xX_STPC_L xX_STPC_U
         qui gen `xX_STPC_L' = .
         qui gen `xX_STPC_U' = .
         local r = `row_F`p'' + 1
         forvalues R = 1/`n_rowD`p''            {
            local c = `col_DF'
            local CX = 1
            local k = cond("`ADD_SIDE'"=="left",1 + `n_colM',1)
            local fs = `col_DF' - 1
            local fe = `fs' + (`n_colD' - 1)
            forvalues C = `fs'/`fe'             {
               local CZ = `CX' + 1
               qui replace `xX_STPC_L' = xX_STPC1`p'[`R',`CX']
               qui replace `xX_STPC_U' = xX_STPC1`p'[`R',`CZ']
               sum `xX_STPC_L', meanonly
               if "`r(mean)'" ~= ""             {
                  local stpc_l : display ``STPC1'form`p'`R'`C'' `r(mean)'
                  local stpc_l = strtrim("`stpc_l'")
                  sum `xX_STPC_U', meanonly
                  local stpc_u : display ``STPC1'form`p'`R'`C'' `r(mean)'
                  local stpc_u = strtrim("`stpc_u'")
                  if "`PAREN1'" == "no"         {
                     if "`CI_SEP'" == "comma"   {
                        putdocx table `tabname'(`r',`c') = ("`stpc_l', `stpc_u'"),     ///
                                font(`font', `ci_fsize')
                     }
                     if "`CI_SEP'" == "dash"    {
                        putdocx table `tabname'(`r',`c') = ("`stpc_l' - `stpc_u'"),    ///
                                font(`font', `ci_fsize')
                     }
                  }
                  if "`PAREN1'" == "paren"      {
                     if "`CI_SEP'" == "comma"   {
                        putdocx table `tabname'(`r',`c') = ("(`stpc_l', `stpc_u')"),     ///
                                font(`font', `ci_fsize')
                     }
                     if "`CI_SEP'" == "dash"    {
                        putdocx table `tabname'(`r',`c') = ("(`stpc_l' - `stpc_u')"),    ///
                                font(`font', `ci_fsize')
                     }
                  }
                  if "`PAREN1'" == "bracket"    {
                     if "`CI_SEP'" == "comma"   {
                        putdocx table `tabname'(`r',`c') = ("[`stpc_l', `stpc_u']"),     ///
                                font(`font', `ci_fsize')
                     }
                     if "`CI_SEP'" == "dash"    {
                        putdocx table `tabname'(`r',`c') = ("[`stpc_l' - `stpc_u']"),    ///
                                font(`font', `ci_fsize')
                     }
                  }
                  if "`est_no'" ~= "" & "`est_no`k''"=="no"   {
                     putdocx table `tabname'(`r',`c') = (" ")
                  }
                  putdocx table `tabname'(`r',`c'), halign(right) valign(top)
               }
               local CX = `CX' + 2
               if "`est_star'"=="" & `"`est_se2'"'==""  {
                  local c = `c' + 1
               }
               if "`est_star'"~="" | `"`est_se2'"'~=""  {
                  local c = `c' + 2
               }
               local ++k
            }
            local ++R
            local r = `r' + 2
         }
         capture drop `xX_STPC_L' `xX_STPC_U'
      } 
   }
}



**# firstX / lastX additional lines
*  linespaces:  add line between  (i)  first and next row ("firstX")
*                                 (ii) last and previous row ("lastX")

if "`slim'" == ""             {
   if "`firstX'" ~= ""        {
      forvalues p = 1/`n_p'   {
         local row_FX = cond("`est_se1'"~="",`row_F`p''+1,`row_F`p'')     
         putdocx table `tabname'(`row_FX',.), addrows(1, after)
         local row_F_1 = `row_FX' + 1           //  after first row:  additional row
         putdocx table `tabname'(`row_F_1',.), height(`bf033'pt, exact)
         local row_L   = `row_L'  + 1             //  last data/coeff row
         local row_LS  = `row_LS' + 1             //  last data/coeff/stat row
         local row_LSE = `row_LSE' + 1            //  last data/coeff/stat/extra row
         local row_L`p'   = `row_L`p''  + 1       //  last data/coeff row:        panel-specific
         local row_LS`p'  = `row_LS`p'' + 1       //  last data/coeff/stat row:   panel-specific 
         local Q = `p' + 1
         forvalues q = `Q'/`n_p'   {
            local row_F`q'   = `row_F`q''  + 1    //  first data/coeff row, subsequent panels
            local row_L`q'   = `row_L`q''  + 1    //  last data/coeff row, subsequent panels
            local row_LS`q'  = `row_LS`q'' + 1    //  last data/coeff/stat row, subsequent panels 
         }
      }
   }
   if "`lastX'" ~= ""         {
      forvalues p = 1/`n_p'   {
         local row_LX = cond("`est_se1'"~="",`row_L`p''-1,`row_L`p'')
         putdocx table `tabname'(`row_LX',.), addrows(1, before)
         putdocx table `tabname'(`row_LX',.), height(`bf033'pt, exact)
         local row_L   = `row_L'  + 1             //  last data/coeff row
         local row_LS  = `row_LS' + 1             //  last data/coeff/stat row
         local row_LSE = `row_LSE' + 1            //  last data/coeff/stat/extra row
         local row_L`p'   = `row_L`p''  + 1       //  last data/coeff row:        panel-specific
         local row_LS`p'  = `row_LS`p'' + 1       //  last data/coeff/stat row:   panel-specific 
         local Q = `p' + 1
         forvalues q = `Q'/`n_p'   {
            local row_F`q'   = `row_F`q''  + 1    //  first data/coeff row, subsequent panels
            local row_L`q'   = `row_L`q''  + 1    //  last data/coeff row, subsequent panels
            local row_LS`q'  = `row_LS`q'' + 1    //  last data/coeff/stat row, subsequent panels 
         }
      }
   }
}
 


*  Guide to rows and columns  (reprise)
*
*     n_rowD   number data rows (coefficients or matrix elements):        all panels
*     n_rowS   number statistics rows (N, r-squared, BIC, etc):           all panels
*
*     n_colD   number of data columns (equations or matrix elements), excluding means/matrices
*     n_colM   number of means/matrix columns
*     n_colE   number of excel columns
*     n_colT   number of data/means/matrix/excel columns
*     n_colTX  number of columns:  row title + data/means/matrix/excel columns
*
*     col_DF   first data column (accounting for row title column = 1)
*     col_DL   last data column (accounting for extra columns: row title, stars, se)
*     col_MF   first means/matrix column (accounting for row title column = 1)
*     col_ML   last means/matrix column (accounting for row title column = 1) 
*     col_EF   first excel column (accounting for row title column = 1)
*     col_EL   last excel column (accounting for row title column = 1) 
*     col_F    first data/means/matrix/excel column (accounting for row title column = 1)
*     col_L    last data/means/matrix/excel column (accounting for row title column = 1)
*
*     row_SP   column spanning title row
*     row_C    column title row
*
*     row_F    first data row                                       first row, first panel
*     row_L    last data/coeff row:                                 last row, last panel
*     row_LS   last data/coeff/stat row:                            after all panels
*     row_LSE  last data/coeff/stat/extra row:                      after all panels
*     row_N    first row of notes                                   after all panels
*
*     n_rowD#  number data rows (coefficients or matrix elements):  panel-specific
*     n_rowS#  number statistics rows (N, r-squared, BIC, etc):     panel-specific
*
*     row_F#   first data row:                                      panel-specific
*     row_L#   last data/coeff row:                                 panel-specific
*     row_LS#  last data/coeff/stat row:                            panel-specific
*
*     note:  panel-specific are absolute -- based on row_F, not renumbered panel-by-panel



**# statistics rows
*  if there are statistics:  format data cells (include right align row titles, vertical center align)
*  linespace:  add one before first stat row in each panel (unless slim requested)

if "`est_stat1'"~=""       {
   forvalues p = 1/`n_p'   {
      local row_FS`p' = `row_L`p'' + 1
      local k = `row_FS`p''
      forvalues c = 1/`n_rowS`p''  {
         putdocx table `tabname'(`k',.), nformat(%8.`decS`p'`c''fc) halign(right) valign(center)
         putdocx table `tabname'(`k',.), font(`font', `st_fsize') height(`bf100'pt, exact)
         putdocx table `tabname'(`k',1), halign(right) valign(center)
         local ++k
      }
      if "`slim'" == ""           {
         putdocx table `tabname'(`row_FS`p'',.), addrows(1, before)   //  before first stat row:  add row
         if "`lastX'" == ""       {
            putdocx table `tabname'(`row_FS`p'',.), height(`bf067'pt, exact)
            if "`est_se1'" ~= ""  {
               putdocx table `tabname'(`row_FS`p'',.), height(`bf067'pt, exact)
            }
            if ("`extra1'"=="" & "`extra`p'1'"=="")  &  (`n_p'>1 & "`pspace'"=="small")  {
               putdocx table `tabname'(`row_ZZZ_1',.), height(`bf058'pt, exact)
            }
         }
         if "`lastX'"~="" | ("`extra1'"~="" | "`extra`p'1'"~="")    {
            putdocx table `tabname'(`row_FS`p'',.), height(`bf058'pt, exact)
            if "`est_se1'" ~= ""  {
               putdocx table `tabname'(`row_FS`p'',.), height(`bf067'pt, exact)
            }
         }
         local row_L      = `row_L'      + 1         //  last data/coeff row
         local row_LS     = `row_LS'     + 1         //  last data/coeff/stat row
         local row_LSE    = `row_LSE'    + 1         //  last data/coeff/stat/extra row
         local row_LS`p'  = `row_LS`p''  + 1         //  last data/coeff/stat row: panel `p'
         local q = `p' + 1
         forvalues PP = `q'/`n_p'   {
            local row_F`PP'   = `row_F`PP''   + 1    //  first data/coeff row, subsequent panels
            local row_L`PP'   = `row_L`PP''   + 1    //  last data/coeff row, subsequent panels
            local row_LS`PP'  = `row_LS`PP''  + 1    //  last data/coeff/stat row, subsequent panels
         }
      }
   }
}  



**# extra information rows
*  extra information rows
*  one set below all panels and multiple panels
*  linespace:  add one after last data/stat row (unless slim requested) 

if "`extra1'"~="" & `n_p'>1        {
   local n_extra = 0
   forvalues x = 1/9   {
      if "`extra`x''" ~= ""        {
         local ++n_extra
         tokenize "`extra`x''", parse("!")
         local k  = 0
         local EX = 0
         while "`1'" ~= ""         {
            if "`1'" == "!"        {
               if `k' == 0   { 
                  local ++k
                  local ex`x'_`k' " "
               }
               local EX = `EX' + 1
               if `EX' >= 2        {
                  local ++k
                  local ex`x'_`k' " "
               }
            }
            if "`1'" ~= "!"        {
               local EX = 0
               local ++k
               local ex`x'_`k' "`1'"
            }
            mac shift
         }
      } 
   }
   if `k' > `n_colTX'              {
      noi di _n(1) _col(3) in y  "ERROR:  too many elements in one or more extra rows"
      noi di _n(1) " "
      exit
   }
   if "`slim'" == ""               {
      putdocx table `tabname'(`row_LS',.), addrows(1, after)
      local row_LS_1  = `row_LS' + 1
      if "`est_stat1'"~="" & "`extra_place'"==""  {
         putdocx table `tabname'(`row_LS_1',.), height(`bf100'pt, exact)  
      }
      if "`est_stat1'"=="" | "`extra_place'"~=""  {
         putdocx table `tabname'(`row_LS_1',.), height(`bf092'pt, exact)  
      }
      local row_LSE = `row_LSE' + 1
   }
   if "`slim'" ~= ""               {
      local row_LS_1 = `row_LS'
   }      
   putdocx table `tabname'(`row_LS_1',.), addrows(`n_extra', after)
   forvalues r = 1/`n_extra'  {
      local extra_empty "yes"
      local R = `row_LS_1' + `r'
      if "`est_star'"=="" & `"`est_se2'"'==""        {
         forvalues c = 1/`n_colTX'                   {
            local C = `c'
            if "`ex`r'_`c''"~=""                     {
               putdocx table `tabname'(`R',`C') = ("`ex`r'_`c''"), font(`font', `ex_fsize')
               if "`ex`p'`r'_`c''" ~= " "            {
                  local extra_empty "no" 
               }
            }
            if "`ex`r'_`c''" == " "                  {
               putdocx table `tabname'(`R',`C') = (" "), font(`font', `ex_fsize')  
            }
            putdocx table `tabname'(`R',`C'), halign(right) 
         }
      }
      if "`est_star'"~="" | `"`est_se2'"'~=""        {
         local k = 1
         local m = 1
         forvalues c = 1/`n_colTX'                   {
            if `c' <= `col_DF'                       {
               local C = `c'
               if "`ex`r'_`c''"~=""                  {
                  putdocx table `tabname'(`R',`C') = ("`ex`r'_`c''"), font(`font', `ex_fsize')
                  if "`ex`p'`r'_`c''"~=" "           {
                     local extra_empty "no" 
                  }
               }
               if "`ex`r'_`c''" == " "               {
                  putdocx table `tabname'(`R',`C') = (" "), font(`font', `ex_fsize')  
               } 
               putdocx table `tabname'(`R',`C'), halign(right) 
            }
            if `c'>`col_DF' & `c'<=(`col_DF' + (`n_colD' - 1))    {
               local C = `col_DF' + (2*`k')
               if "`ex`r'_`c''"~=""                  {
                  putdocx table `tabname'(`R',`C') = ("`ex`r'_`c''"), font(`font', `ex_fsize')
                  if "`ex`p'`r'_`c''"~=" "           {
                     local extra_empty "no" 
                  }
               }
               if "`ex`r'_`c''" == " "               {
                  putdocx table `tabname'(`R',`C') = (" "), font(`font', `ex_fsize')  
               }
               putdocx table `tabname'(`R',`C'), halign(right) 
               local ++k
            }
            if `c' > (`col_DF' + (`n_colD' - 1))     {
               local C = `col_DL' + `m'
               if "`ex`r'_`c''"~=""                  {
                  putdocx table `tabname'(`R',`C') = ("`ex`r'_`c''"), font(`font', `ex_fsize') 
                  if "`ex`p'`r'_`c''"~=" "           {
                     local extra_empty "no" 
                  }
               }
               if "`ex`r'_`c''" == " "               {
                  putdocx table `tabname'(`R',`C') = (" "), font(`font', `ex_fsize')  
               }
               putdocx table `tabname'(`R',`C'), halign(right) 
               local ++m
            }
         }
      }
      putdocx table `tabname'(`R',.), height(`bf100'pt, exact)
      if "`extra_empty'"=="yes"    {
         putdocx table `tabname'(`R',.), height(`bf033'pt, exact)
      }
   }
   local row_LSE  = `row_LSE'  + `n_extra'     //  last data/coeff/stat/extra row 
}  



*  extra information rows
*  one set per panel

if ("`extra1'"~="" & `n_p'==1) |                                             ///
   ("`extra11'"~="" | "`extra21'"~="" | "`extra31'"~="" | "`extra41'"~="" |  ///
    "`extra51'"~="" | "`extra61'"~="" | "`extra71'"~="")      {
   if "`extra1'"~="" & `n_p'==1        {
      forvalues x = 1/9                {
         local extra1`x' = "`extra`x''"
      }
   }
   forvalues p = 1/`n_p'               {
      if "`extra`p'1'" ~= ""           {
         local n_extra = 0
         forvalues x = 1/9  {
             if "`extra`p'`x''" ~= ""  {
               local ++n_extra
               tokenize "`extra`p'`x''", parse("!")
               local k  = 0
               local EX = 0
               while "`1'" ~= ""       {
                  if "`1'" == "!"      {
                     if `k' == 0       { 
                        local ++k
                        local ex`p'`x'_`k' " "
                     }
                     local EX = `EX' + 1
                     if `EX' >= 2      {
                        local ++k
                        local ex`p'`x'_`k' " "
                     }
                  }
                  if "`1'" ~= "!"      {
                     local EX = 0
                     local ++k
                     local ex`p'`x'_`k' "`1'"
                  }
                  mac shift
               }
            }
         }
         if `k' > `n_colTX'            {
            noi di _n(1) _col(3) in y  "ERROR:  too many elements in one or more extra rows"
            noi di _n(1) " "
            exit
         }
         local ZZZ = cond("`extra_place'"=="","LS","L")
         local row_ZZZ_1 = cond("`slim'"=="",`row_`ZZZ'`p''+1,`row_`ZZZ'`p'')
         if "`slim'" == ""                        {
            putdocx table `tabname'(`row_`ZZZ'`p'',.), addrows(1, after)
            putdocx table `tabname'(`row_ZZZ_1',.), height(`bf058'pt, exact)
            if "`est_stat`p''"==""                {
               putdocx table `tabname'(`row_ZZZ_1',.), height(`bf067'pt, exact)
               if `n_p'>1 & "`pspace'"=="small"   {
                  putdocx table `tabname'(`row_ZZZ_1',.), height(`bf050'pt, exact)
               }
            }
         }
         putdocx table `tabname'(`row_ZZZ_1',.), addrows(`n_extra', after)
         forvalues r = 1/`n_extra'                      {
            local extra_empty "yes"
            local R = `row_ZZZ_1' + `r'
            if "`est_star'"=="" & `"`est_se2'"'==""     {
               forvalues c = 1/`n_colTX'                {
                  local C = `c'
                  if "`ex`p'`r'_`c''"~=""               {
                     putdocx table `tabname'(`R',`C') = ("`ex`p'`r'_`c''"), font(`font', `ex_fsize')
                     if "`ex`p'`r'_`c''"~=" "           {
                        local extra_empty "no" 
                     }
                  }
                  if "`ex`p'`r'_`c''" == " "            {
                     putdocx table `tabname'(`R',`C') = (" "), font(`font', `ex_fsize')  
                  }
                  putdocx table `tabname'(`R',`C'), halign(right)
               }
            }
            if "`est_star'"~="" | `"`est_se2'"'~=""     {
               local k = 1
               local m = 1
               forvalues c = 1/`n_colTX'                {
                  if `c' <= `col_DF'                    {
                     local C = `c'
                     if "`ex`p'`r'_`c''"~=""            {
                        putdocx table `tabname'(`R',`C') = ("`ex`p'`r'_`c''"), font(`font', `ex_fsize') 
                        if "`ex`p'`r'_`c''"~=" "        {
                           local extra_empty "no" 
                        }
                     }
                     if "`ex`p'`r'_`c''" == " "         {
                        putdocx table `tabname'(`R',`C') = (" "), font(`font', `ex_fsize')  
                     } 
                     putdocx table `tabname'(`R',`C'), halign(right)
                  }
                  if `c'>`col_DF' & `c'<=(`col_DF' + (`n_colD' - 1))    {
                     local C = `col_DF' + (2*`k')
                     if "`ex`p'`r'_`c''"~=""            {
                        putdocx table `tabname'(`R',`C') = ("`ex`p'`r'_`c''"), font(`font', `ex_fsize')
                        if "`ex`p'`r'_`c''"~=" "        {
                           local extra_empty "no" 
                        }
                     }
                     if "`ex`p'`r'_`c''" == " "         {
                        putdocx table `tabname'(`R',`C') = (" "), font(`font', `ex_fsize')  
                     }
                     putdocx table `tabname'(`R',`C'), halign(right) 
                     local ++k
                  }
                  if `c' > (`col_DF' + (`n_colD' - 1))  {
                     local C = `col_DL' + `m'
                     if "`ex`p'`r'_`c''"~=""            {
                        putdocx table `tabname'(`R',`C') = ("`ex`p'`r'_`c''"), font(`font', `ex_fsize')
                        if "`ex`p'`r'_`c''"~=" "        {
                           local extra_empty "no" 
                        }
                     }
                     if "`ex`p'`r'_`c''" == " "         {
                        putdocx table `tabname'(`R',`C') = (" "), font(`font', `ex_fsize')  
                     }
                     putdocx table `tabname'(`R',`C'), halign(right) 
                     local ++m
                  }
               }
            }
            putdocx table `tabname'(`R',.), font(`font', `ex_fsize') height(`bf100'pt, exact)
            if "`extra_empty'"=="yes"   {
               putdocx table `tabname'(`R',.), font(`font', `ex_fsize') height(`bf033'pt, exact)
            }
         }
         local n_ext   = cond("`slim'"~="",`n_extra',`n_extra' + 1)
         local row_LS  = `row_LS'   + `n_ext'           //  last data/coeff/stat row
         local row_LSE = `row_LSE'  + `n_ext'           //  last data/coeff/stat/extra row
         local q = `p' + 1
         forvalues PP = `q'/`n_p'   {
            local row_F`PP'  = `row_F`PP''  + `n_ext'   //  first data/coeff row, subsequent panels
            local row_L`PP'  = `row_L`PP''  + `n_ext'   //  last data/coeff row, subsequent panels
            local row_LS`PP' = `row_LS`PP'' + `n_ext'   //  last data/coeff/stat row, subsequent panels
         }
      }
   }
} 



**# column deletion
*  ***************************
*
*  ****  COLUMN DELETION  ****
*
*  ***************************


*  Guide to rows and columns  (reprise)
*
*     n_rowD   number data rows (coefficients or matrix elements):        all panels
*     n_rowS   number statistics rows (N, r-squared, BIC, etc):           all panels
*
*     n_colD   number of data columns (equations or matrix elements), excluding means/matrices
*     n_colM   number of means/matrix columns
*     n_colE   number of excel columns
*     n_colT   number of data/means/matrix/excel columns
*     n_colTX  number of columns:  row title + data/means/matrix/excel columns
*
*     col_DF   first data column (accounting for row title column = 1)
*     col_DL   last data column (accounting for extra columns: row title, stars, se)
*     col_MF   first means/matrix column (accounting for row title column = 1)
*     col_ML   last means/matrix column (accounting for row title column = 1) 
*     col_EF   first excel column (accounting for row title column = 1)
*     col_EL   last excel column (accounting for row title column = 1) 
*     col_F    first data/means/matrix/excel column (accounting for row title column = 1)
*     col_L    last data/means/matrix/excel column (accounting for row title column = 1)
*
*     row_SP   column spanning title row
*     row_C    column title row
*
*     row_F    first data row                                       first row, first panel
*     row_L    last data/coeff row:                                 last row, last panel
*     row_LS   last data/coeff/stat row:                            after all panels
*     row_LSE  last data/coeff/stat/extra row:                      after all panels
*     row_N    first row of notes                                   after all panels
*
*     n_rowD#  number data rows (coefficients or matrix elements):  panel-specific
*     n_rowS#  number statistics rows (N, r-squared, BIC, etc):     panel-specific
*
*     row_F#   first data row:                                      panel-specific
*     row_L#   last data/coeff row:                                 panel-specific
*     row_LS#  last data/coeff/stat row:                            panel-specific
*
*     note:  panel-specific are absolute -- based on row_F, not renumbered panel-by-panel


*  deleting est_star and est_se columns    (must precede panel titles, notes, column-spanning titles)
*
*  1.  defining starting and ending columns, prior to column deletion
*      (this is defined for all columns, whether or not est_star / beside apply)
*      (defined in terms of data columns, i.e. excluding row-title column)

local DB   "/"
local PLUS ""
if "`est_star'"~="" | `"`est_se2'"'~=""     {
   local DB   "(2)"
   local PLUS "+ 1"
}

local k = 1
if `n_colE'==0 & `n_colM'==0                {   //  neither excel or add
   forvalues c = `col_DF'`DB'`col_DL'       {
      local start`k' = `c'
      local end`k' = `c' `PLUS'
      local ++k
   }
   local lastD = `k' - 1
}

if `n_colE'>0  &  `n_colM'==0               {   //  excel but no add
   if "`EXC_SIDE'"=="left"                  {
      forvalues c = `col_EF'/`col_EL'       {
         local start`k' = `c' 
         local end`k' = `c'
         local ++k
      }
      forvalues c = `col_DF'`DB'`col_DL'    {
         local start`k' = `c'
         local end`k' = `c' `PLUS'
         local ++k
      }
      local lastD = `k' - 1
   }
   if "`EXC_SIDE'"=="right"                 {
      forvalues c = `col_DF'`DB'`col_DL'    {
         local start`k' = `c'
         local end`k' = `c' `PLUS'
         local ++k
      }
      local lastD = `k' - 1
      forvalues c = `col_EF'/`col_EL'       {
         local start`k' = `c'
         local end`k' = `c'
         local ++k
      }
   }
}

if `n_colE'==0  &  `n_colM'>0               {   //  add but no excel
   if "`ADD_SIDE'"=="left"                  {
      forvalues c = `col_MF'/`col_ML'       {
         local start`k' = `c'
         local end`k' = `c'
         local ++k
      }
      forvalues c = `col_DF'`DB'`col_DL'    {
         local start`k' = `c'
         local end`k' = `c' `PLUS'
         local ++k
      }
      local lastD = `k' - 1
   }
   if "`ADD_SIDE'"=="right"                 {
      forvalues c = `col_DF'`DB'`col_DL'    {
         local start`k' = `c'
         local end`k' = `c' `PLUS'
         local ++k
      }
      local lastD = `k' - 1
      forvalues c = `col_MF'/`col_ML'       {
         local start`k' = `c'
         local end`k' = `c'
         local ++k
      }
   }
}

if `n_colE'>0  &  `n_colM'>0                {   //  both excel and add
   if "`EXC_SIDE'"=="left"                  {
      forvalues c = `col_EF'/`col_EL'       {
         local start`k' = `c'
         local end`k' = `c'
         local ++k
      }
      if "`ADD_SIDE'"=="left"               {
         forvalues c = `col_MF'/`col_ML'    {
            local start`k' = `c'
            local end`k' = `c'
            local ++k
         }
         forvalues c = `col_DF'`DB'`col_DL' {
            local start`k' = `c'
            local end`k' = `c' `PLUS'
            local ++k
         }
         local lastD = `k' - 1
      }
      if "`ADD_SIDE'"=="right"              {
         forvalues c = `col_DF'`DB'`col_DL' {
            local start`k' = `c'
            local end`k' = `c' `PLUS'
            local ++k
         }
         local lastD = `k' - 1
         forvalues c = `col_MF'/`col_ML'    {
            local start`k' = `c'
            local end`k' = `c'
            local ++k
         }
      }
   }
   if "`EXC_SIDE'"=="right"                 {
      if "`ADD_SIDE'"=="left"               {
         forvalues c = `col_MF'/`col_ML'    {
            local start`k' = `c'
            local end`k' = `c'
            local ++k
         }
         forvalues c = `col_DF'`DB'`col_DL' {
            local start`k' = `c'
            local end`k' = `c' `PLUS'
            local ++k
         }
         local lastD = `k' - 1
      }
      if "`ADD_SIDE'"=="right"              {
         forvalues c = `col_DF'`DB'`col_DL' {
            local start`k' = `c'
            local end`k' = `c' `PLUS'
            local ++k
         }
         local lastD = `k' - 1
         forvalues c = `col_MF'/`col_ML'    {
            local start`k' = `c'
            local end`k' = `c'
            local ++k
         }
      }
      forvalues c = `col_EF'/`col_EL'       {
         local start`k' = `c'
         local end`k' = `c'
         local ++k
      }
   }
}



*  2.  column deletion 
*      

if "`est_star'"~="" | `"`est_se2'"'~=""    {
   local highK = `k' - 1
   if "`est_no'" ~= ""                     {
      local k = `lastD'
      forvalues c = `col_DL'(-2)`col_DF'   {      
         if "`est_no`k''" == "no"          {
            putdocx table `tabname'(.,`c'), drop
            local end`k' = `end`k'' - 1
            local K = `k' + 1        
            forvalues p = `K'/`highK'      { 
               local start`p' = `start`p'' - 1
               local end`p'   = `end`p'' - 1
            }
         }
         local k = `k' - 1
      }
   }
}




**# insert blank columns
*  ****************************************
*
*  ****  INSERTION OF BLANK COLUMN(S)  ****
*
*  ****************************************

if "`add_cols'" ~= ""  {
   forvalues a = `N_ADDCOLS'(-1)1    {
      putdocx table `tabname'(.,`start`ac_start`a'''), addcols(1, before)
      putdocx table `tabname'(.,`start`ac_start`a'''), width(`ac_width`a'') border(all,nil)
      local col_L   = `col_L' + 1
      local n_colTX = `n_colTX' + 1
      local COL = `ac_start`a''
      forvalues p = `COL'/`n_colT'   {
         local start`p' = `start`p'' + 1
         local end`p'   = `end`p'' + 1
      }
   }
}


*  linespace:  add one between last data/coeff/stat/extra row and bottom line
*  horizontal line:  below last data/coeff/stat/extra
*  linespace:  add one between bottom line and notes, if there are notes

if "`slim'" ~= ""        {
   putdocx table `tabname'(`row_LSE',.), border(bottom, `lineB')
}

if "`slim'" == ""        {
   putdocx table `tabname'(`row_LSE',.), addrows(1, after)        //  after last data/coeff/stat/extra row:  add row
   local row_LSE = `row_LSE' + 1 
   putdocx table `tabname'(`row_LSE',.), height(`bf044'pt, exact) border(bottom, `lineB')
   if ("`est_stat1'"~="")  |          ///
      ("`extra1'"~="")     |          ///
      ("`extra11'"~="" | "`extra21'"~="" | "`extra31'"~="" | "`extra41'"~="" | "`extra51'"~="")   {
      putdocx table `tabname'(`row_LSE',.), height(`bf050'pt, exact) border(bottom, `lineB')
   }
   if "`note1'" ~= ""    {
      local HT "bf092"
      if `n_rowD1'<=8  {
         local HT "bf083"
      }
      putdocx table `tabname'(`row_LSE',.), addrows(1, after)          //  after bottom line:  add row if there are notes
      local row_LSE = `row_LSE' + 1  
      putdocx table `tabname'(`row_LSE',.), height(``HT''pt, exact)   //  row before notes
   }
}



******************************************************************************************
******************************************************************************************


*  Guide to rows and columns  (reprise)
*
*     n_rowD   number data rows (coefficients or matrix elements):        all panels
*     n_rowS   number statistics rows (N, r-squared, BIC, etc):           all panels
*
*     n_colD   number of data columns (equations or matrix elements), excluding means/matrices
*     n_colM   number of means/matrix columns
*     n_colE   number of excel columns
*     n_colT   number of data/means/matrix/excel columns
*     n_colTX  number of columns:  row title + data/means/matrix/excel columns
*
*     col_DF   first data column (accounting for row title column = 1)
*     col_DL   last data column (accounting for extra columns: row title, stars, se)
*     col_MF   first means/matrix column (accounting for row title column = 1)
*     col_ML   last means/matrix column (accounting for row title column = 1) 
*     col_EF   first excel column (accounting for row title column = 1)
*     col_EL   last excel column (accounting for row title column = 1) 
*     col_F    first data/means/matrix/excel column (accounting for row title column = 1)
*     col_L    last data/means/matrix/excel column (accounting for row title column = 1)
*
*     row_SP   column spanning title row
*     row_C    column title row
*
*     row_F    first data row                                       first row, first panel
*     row_L    last data/coeff row:                                 last row, last panel
*     row_LS   last data/coeff/stat row:                            after all panels
*     row_LSE  last data/coeff/stat/extra row:                      after all panels
*     row_N    first row of notes                                   after all panels
*
*     n_rowD#  number data rows (coefficients or matrix elements):  panel-specific
*     n_rowS#  number statistics rows (N, r-squared, BIC, etc):     panel-specific
*
*     row_F#   first data row:                                      panel-specific
*     row_L#   last data/coeff row:                                 panel-specific
*     row_LS#  last data/coeff/stat row:                            panel-specific
*
*     note:  panel-specific are absolute -- based on row_F, not renumbered panel-by-panel




**# row-spanning titles
*  ********************************
*
*  ****  FINISHING TOUCHES, I  ****
*
*        row spanning titles
*
*  ********************************


*  row spanning titles (maximum twelve per panel)
*  (syntax assumes three values in each rst#, separated by comma or space)
*  (assumes within-panel numbering)
*  (must occur after:  insertion of columns and filling of columns
*                  OR  insertion of rows and filling of rows)
*                 AND  deletion of columns (because rst span all columns ("colspan"))
*  
 
if `"`rst11'"' ~= "" |  `"`rst21'"' ~= "" |  `"`rst31'"' ~= "" |  `"`rst41'"' ~= "" |   ///
   `"`rst51'"' ~= "" |  `"`rst61'"' ~= "" |  `"`rst71'"' ~= ""     {

   forvalues p = 1/`n_p'                 {
      local max = cond(`p'==1,15,9)
      local RST_MAX = 0
      forvalues r = 1/`max'              {
         if `"`rst`p'`r''"' ~= ""        {
            local ++RST_MAX
            local RST ""
            tokenize `"`rst`p'`r''"', parse(" ,")
            while "`1'" ~= ""            {
               if "`1'" ~= ","           {
                  local RST "`RST'`1',"
               }
               mac shift
            }
            tokenize `"`RST'"', parse(",")
            local lab_rst`r' "`1'"
            if "`est_se1'"==""           {
               local row_rst_first`r' = `3' + (`row_F`p'' - 1) 
               local row_rst_last`r'  = `row_rst_first`r'' + (`5' - 1)
               local alignV "bottom"
            }
            if "`est_se1'"~=""           {
               local row_rst_first`r' = `3' + (`3'-1) + (`row_F`p'' - 1) 
               local row_rst_last`r'  = `row_rst_first`r'' + ((`5'*2) - 1)
               local alignV "center"
            }
            local q = `r' - 1
            if `r'>1                     {
               if `row_rst_first`r'' == (`row_rst_last`q'') + 1    {
                  local row_rst_next`q' "yes"
               }
            }
            if "`firstX'"~=""            {
               local ++row_rst_first`r'
               local ++row_rst_last`r'
            }
         }
      }
      local HT  "bf125"
      local HTX "bf033"
      local HTZ "bf016"
      if "`est_se1'"~=""                 {
         local HT  "bf150"
         local HTX "bf016"
         local HTZ "bf025"
      }
      local ADD = 0
      forvalues r = 1/`RST_MAX'          {
         local extra = 0
         if "`row_rst_first`r''" ~= ""   {                    //  insert row title 
            putdocx table `tabname'(`row_rst_first`r'',.), addrows(1, before)
            putdocx table `tabname'(`row_rst_first`r'',1), colspan(`col_L')
            putdocx table `tabname'(`row_rst_first`r'',.), height(``HT''pt, exact) valign(`alignV')
            putdocx table `tabname'(`row_rst_first`r'',1) = ("`SPACES_PT'`lab_rst`r''"),     ///
               font(`font', `l_fsize') `rst_format' halign(left)
            local ++row_rst_last`r'
            local ++ADD
            local ++extra
            if "`slim'"=="" & `row_rst_first`r''~=2 {         //  insert empty row before row title
               putdocx table `tabname'(`row_rst_first`r'',.), addrows(1, before)
               putdocx table `tabname'(`row_rst_first`r'',.), height(``HTX''pt, exact) valign(`alignV')
               local ++row_rst_first`r'
               local ++row_rst_last`r'
               local ++ADD
               local ++extra
            }
            if "`slim'"=="" & "`row_rst_next`r''"~="yes"   {  //  insert empty row after block of row-title rows
                if "`lastX'"=="" |   ///
                  ("`lastX'"~="" & (`row_rst_last`r'' + 2)~=(`row_L`p'' + `extra'))   { 
                   putdocx table `tabname'(`row_rst_last`r'',.), addrows(1, after)
                   local row_rst_LAST`r' = `row_rst_last`r'' + 1
                   putdocx table `tabname'(`row_rst_LAST`r'',1), colspan(`col_L')
                   putdocx table `tabname'(`row_rst_LAST`r'',.), height(``HTZ''pt, exact) valign(center)
                   local ++ADD
                   local ++extra
               }
            }
            if `r' < `RST_MAX'           {
               local s = `r' + 1
               local row_rst_first`s' = `row_rst_first`s'' + `ADD'
               local row_rst_last`s'  = `row_rst_last`s''  + `ADD'
            }
         }
         local row_L      = `row_L'   + `extra'      //  last data/coeff row
         local row_LS     = `row_LS'  + `extra'      //  last data/coeff/stat row
         local row_LSE    = `row_LSE' + `extra'      //  last data/coeff/stat/extra row
         local row_L`p'   = `row_L`p''  + `extra'    //  last data/coeff row, panel-specific
         local row_LS`p'  = `row_LS`p'' + `extra'    //  last data/coeff/stat row, panel-specific
      }
      local Q = `p' + 1
      forvalues q = `Q'/`n_p'      {
         local row_F`q'   = `row_F`q''  + `ADD'      //  first data/coeff row, subsequent panels
         local row_L`q'   = `row_L`q''  + `ADD'      //  last data/coeff row, subsequent panels 
         local row_LS`q'  = `row_LS`q'' + `ADD'      //  last data/coeff/stat row, subsequent panels
      }
   }

}



**# panel titles
*  *********************************
*
*  ****  FINISHING TOUCHES, II  ****
*
*        panel titles
*
*  *********************************


*  panel titles:  insert row
*                 add title

forvalues p = 1/`n_p'      {

   local HTPT "bf150"             //  height of panel title row
   if "`pspace'"=="large"  {
      local HTPT "bf167"
   }

   if `p' == 1  {
      if "`pt1'" ~= ""  {
         local X = 1
         if "`slim'" == ""      {
            putdocx table `tabname'(`row_F`p'',.), addrows(1,before) border(top, nil)
            putdocx table `tabname'(`row_F`p'',.), height(`bf033'pt, exact)
            local ++X
         }
         putdocx table `tabname'(`row_F`p'',.), addrows(1,before)
         putdocx table `tabname'(`row_F`p'',1), colspan(`col_L')
         tokenize "`pt`p''", parse("\")
         if "`3'" == ""        {
            putdocx table `tabname'(`row_F`p'',.), height(``HTPT''pt, exact)
            putdocx table `tabname'(`row_F`p'',1) = ("`1'"),                      ///
                    font(`font', `l_fsize') `pt_format' halign(`pt_just') valign(center)   
         }
         if "`3'" ~= ""        {
            local pt_formatX = cond(strltrim("`pt_format'")~="underline","`pt_format'","")
            putdocx table `tabname'(`row_F`p'',.), height(`bf300'pt, exact)
            putdocx table `tabname'(`row_F`p'',1) = ("`1'"), append linebreak(1)  ///
                    font(`font', `l_fsize')  `pt_formatX'  halign(`pt_just') valign(center)   
            putdocx table `tabname'(`row_F`p'',1) = ("`3'"),                      ///
                    font(`font', `l_fsize')  `pt_format'  halign(`pt_just') valign(center) append
         }
         local row_F   = `row_F'  + `X'                //  first data/coeff row
         local row_L   = `row_L'  + `X'                //  last data/coeff row
         local row_LS  = `row_LS' + `X'                //  last data/coeff/stat row
         local row_LSE = `row_LSE' + `X'               //  last data/coeff/stat/extra row
         forvalues PP = `p'/`n_p'   {
            local row_F`PP'   = `row_F`PP''   + `X'    //  first data/coeff row:           panel-specific
            local row_L`PP'   = `row_L`PP''   + `X'    //  last data/coeff row:            panel-specific
            local row_LS`PP'  = `row_LS`PP''  + `X'    //  last data/coeff/stat row:       panel-specific
         }
      }
   }

   if `p' > 1                     {

*  guide:   HTPT   row: panel title
*           HTP    row: pline
*           HTPX   row: pline, under "large"/"small" and under est_stat/extra
*           HT2    row: preceding panel - break between panels
*           HT0    HT2: smaller version, no pline and "below"
*           HT1    HT2: medium version, no pline and est_stat+extra
*           HT3    HT2: larger version, est_stat+extra

      local q = `p' - 1
      if "`pline'" == ""          {     //   NO PLINE:  setting HT3, HT2, HT1, HT0
         local HT3  "bf092"
         local HT2  "bf083"            
         if "`lastX'"~=""         {
            local HT2 "bf075"
         }
         local HT1 "bf075"
         local HT0 "bf067"
         if "`pspace'"=="large"   {
            local HT2 "bf108"
            if "`lastX'"~=""      {
               local HT2 "bf100"
            }
            local HT1 "bf092"
            local HT0 "bf092"
         }
         if "`pspace'"=="small"   {
            local HT3  "bf067"
            local HT2  "bf058"
            if "`lastX'"~=""      {
               local HT2 "bf050"
            }
            local HT1 "bf050"
            local HT0 "bf044"
         }
         if "`est_se1'"~=""       {
            local HT2 "`HT0'"
         }
         if "`pt`p''"~=""         {
            if "`est_stat'"=="" & "`est_stat`q''"=="" & "`extra`q'1'"==""     {
               local HT2 "`HT1'"
            }
            if ("`est_stat'"~="" | "`est_stat`q''"~="") & "`extra`q'1'"~=""   {
               local HT2 "`HT3'"
            }
         }
      }
      if "`pline'" ~= ""          {     //   PLINE:  setting HT3, HT2, HTP, HTPX
         local HT3 "bf117"
         local HT2 "bf108"            
         if "`lastX'"~=""         {
            local HT2 "bf108"
         }
         local HTP  "bf050" 
         local HTPX "bf058"
         if "`pspace'"=="large"   {
            local HT3 "bf133"
            local HT2 "bf133"
            if "`lastX'"~=""      {
               local HT2 "bf117"
            }
            local HTP  "bf058"
            local HTPX "bf067"
         }
         if "`pspace'"=="small"   {
            local HT3 "bf092"
            local HT2 "bf092"
            if "`lastX'"~=""      {
               local HT2 "bf083"
            }
            local HTP  "bf033"
            local HTPX "bf044"
         }
         if ("`est_stat'"~="" | "`est_stat`q''"~="") & "`extra`q'1'"~=""   {
            local HT2 "`HT3'"
            if "`pt`p''"==""      {
               local HTP "`HTPX'"
            }
         }
         if ("`est_stat'"~="" | "`est_stat`q''"~="") | "`extra`q'1'"~=""   {
            if "`pt`p''"==""      {
               local HTP "`HTPX'"
            }
         }
      }

      local X = 1
      if "`slim'" == ""      {
         if "`pline'" ~= ""  {
            putdocx table `tabname'(`row_F`p'',.), addrows(1,before) height(``HTP''pt, exact)
            putdocx table `tabname'(`row_F`p'',.), border(top,,,0.25pt)
            local X = 2
         }
         putdocx table `tabname'(`row_F`p'',.), addrows(1,before) border(top, nil)
         putdocx table `tabname'(`row_F`p'',.), height(``HT2''pt, exact)
      }
      if "`slim'" ~= ""      {
         local X = 0
         if "`pline'" ~= ""  {
            putdocx table `tabname'(`row_F`p'',.), border(top,,,0.25pt) 
         }
      }      
      local row_L   = `row_L'   + `X'               //  last data/coeff row
      local row_LS  = `row_LS'  + `X'               //  last data/coeff/stat row
      local row_LSE = `row_LSE' + `X'               //  last data/coeff/stat/extra row
      forvalues PP  = `p'/`n_p'   {
         local row_F`PP'   = `row_F`PP''  + `X'     //  first data/coeff row:            panel-specific
         local row_L`PP'   = `row_L`PP''  + `X'     //  last data/coeff row:             panel-specific
         local row_LS`PP'  = `row_LS`PP'' + `X'     //  last data/coeff/stat row:        panel-specific
      }
      if "`pt`p''" ~= ""  {
         putdocx table `tabname'(`row_F`p'',.), addrows(1,before)  border(bottom, nil)
         putdocx table `tabname'(`row_F`p'',1), colspan(`col_L')
         tokenize "`pt`p''", parse("\")
         if "`3'" == ""        {
            putdocx table `tabname'(`row_F`p'',.), height(``HTPT''pt, exact)
            putdocx table `tabname'(`row_F`p'',1) = ("`1'"),                      ///
                    font(`font', `l_fsize') `pt_format' halign(`pt_just') valign(center)   
         }
         if "`3'" ~= ""        {
            local pt_formatX = cond(strltrim("`pt_format'")~="underline","`pt_format'","")
            putdocx table `tabname'(`row_F`p'',.), height(`bf300'pt, exact)
            putdocx table `tabname'(`row_F`p'',1) = ("`1'"), append linebreak(1)  ///
                    font(`font', `l_fsize')  `pt_formatX'  halign(`pt_just') valign(center)   
            putdocx table `tabname'(`row_F`p'',1) = ("`3'"),                      ///
                    font(`font', `l_fsize')  `pt_format'  halign(`pt_just') valign(center) append
         }
         local row_L   = `row_L'   + 1              //  last data/coeff row
         local row_LS  = `row_LS'  + 1              //  last data/coeff/stat row
         local row_LSE = `row_LSE' + 1              //  last data/coeff/stat/extra row            
         forvalues PP = `p'/`n_p'   {
            local row_F`PP'   = `row_F`PP''   + 1   //  first data/coeff row:            panel-specific
            local row_L`PP'   = `row_L`PP''   + 1   //  last data/coeff row:             panel-specific
            local row_LS`PP'  = `row_LS`PP''  + 1   //  last data/coeff/stat row:        panel-specific
         }
      }
   }
}

local row_N = `row_LSE'     //  first row of notes section



*  **********************************
*
*  ****  FINISHING TOUCHES, III  ****
*
*        notes
*        column-spanning titles
*
*  **********************************


**# notes
*  notes

if "`note1'" ~= ""           {
   forvalues n = 1/9         {
      local k = `n' + 1
      local HT1 = round(`n_fsize'*1.0)
      local HT2 = round(`n_fsize'*0.5)
      if "`note`n''" ~= ""   {
         if "`slim'" == ""   { 
            putdocx table `tabname'(`row_N',.), addrows(1, after)
            local row_N = `row_N' + 1
            putdocx table `tabname'(`row_N',1), colspan(`col_L')
            putdocx table `tabname'(`row_N',1) = ("`note`n''"), font(`font', `n_fsize')   
            putdocx table `tabname'(`row_N',1), halign(left) valign(center) 
            putdocx table `tabname'(`row_N',.), height(`HT1'pt, atleast)
            if ("`note`n''"=="" | "`note`n''"==" ") & ("`note`k''"~="" | "`note`k''"~=" ")  {
               putdocx table `tabname'(`row_N',.), height(`HT2'pt, exact)
            }
            if "`note`n''"~=" "  &  ("`note`k''"~=""  &  "`note`k''"~=" ")  {
               putdocx table `tabname'(`row_N',.), addrows(1,after)
               local row_N = `row_N' + 1
               putdocx table `tabname'(`row_N',.), height(1pt, exact) 
            }
         }
         if "`slim'"~="" & "`note`n''"~=" "  { 
            putdocx table `tabname'(`row_N',.), addrows(1, after)
            local row_N = `row_N' + 1
            putdocx table `tabname'(`row_N',1), colspan(`col_L')
            putdocx table `tabname'(`row_N',1) = ("`note`n''"), font(`font', `n_fsize')   
            putdocx table `tabname'(`row_N',1), halign(left) valign(center) 
            putdocx table `tabname'(`row_N',.), height(`HT1'pt, atleast)
         }
      }
   }
}



**# column-spanning titles
*  column spanning titles:  add row for spanning titles
*

if `"`cst11'"' ~= ""    {

   if `"`cst1'"' == ""  {
      noi di _n(2) _col(3) in y  "ERROR:  cannot have cst1# without cst# - higher-level presumes lower-level"
      noi di _n(1) " "
      exit
   }

   putdocx table `tabname'(`row_C',.), addrows(1, before)
   local row_SP = `row_C'
   local row_C  = `row_C'  + 1      //  column title row
         


*  second-level column spanning titles (maximum five)
*
*  relies on starting and ending columns, calculated above
*  (syntax assumes three values in each cst#, separated by comma or space)
*  (syntax allows for two lines maximum per piece of text, separated by slashes)
  
   forvalues s = 5(-1)1        {
      if `"`cst1`s''"'~=""     {
         local CST ""
         tokenize `"`cst1`s''"', parse(" ,")
         while "`1'" ~= ""     {
            if "`1'" ~= ","    {
               local CST "`CST'`1',"
            }
            mac shift
         }
         tokenize `"`CST'"', parse(",")
         local cststart = `3'
         local cstend   = `3' + (`5' - 1)
         local cstwidth = (`end`cstend'' - `start`cststart'') + 1
         tokenize "`1'",  parse("\")
         if "`3'"==""                         { 
            putdocx table `tabname'(`row_SP',`start`cststart''), colspan(`cstwidth') 
            putdocx table `tabname'(`row_SP',`start`cststart'') = ("`1'"),       ///
               font(`font', `l_fsize') `cst_format11'  halign(`cst_just11') valign(bottom)  
         }
         if "`3'"~=""                         {
            local cstitleht "double" 
            putdocx table `tabname'(`row_SP',`start`cststart''), colspan(`cstwidth') 
            if "`cst_format11'"~="underline"  {
               putdocx table `tabname'(`row_SP',`start`cststart'') = ("`1'"),    ///
                  font(`font', `l_fsize') `cst_format11'  halign(`cst_just11') valign(bottom) append linebreak(1)  
            }
            if "`cst_format11'"=="underline"  {
               putdocx table `tabname'(`row_SP',`start`cststart'') = ("`1'"),    ///
                  font(`font', `l_fsize') halign(`cst_just11') valign(bottom) append linebreak(1)  
            }
            putdocx table `tabname'(`row_SP',`start`cststart'') = ("`3'"),       ///
               font(`font', `l_fsize') `cst_format11'  halign(`cst_just11') valign(bottom) append 
         }
      }
   }
   local htR = `bf167'
   if "`cstitleht'" == "double"  {
      local htR = `bf275'
   }
   putdocx table `tabname'(`row_SP',.), height(`htR'pt, exact) border(top, `lineT') 

}


*  first-level column spanning titles

if `"`cst1'"' ~= ""  {

   putdocx table `tabname'(`row_C',.), addrows(1, before)
   local row_SP = `row_C'
   local row_C  = `row_C'  + 1      //  column title row

   local cstitleht "single"    


*  first-level column spanning titles (maximum ten)
*
*  relies on starting and ending columns, calculated above
*  (syntax assumes three values in each cst#, separated by comma or space)
*  (syntax allows for three lines maximum per piece of text, separated by slashes)
  
   forvalues s = 10(-1)1  {
      if `"`cst`s''"' ~= ""   {
         local CST ""
         tokenize `"`cst`s''"', parse(" ,")
         while "`1'" ~= ""    {
            if "`1'" ~= ","   {
               local CST "`CST'`1',"
            }
            mac shift
         }
         tokenize `"`CST'"', parse(",")
         local cststart = `3'
         local cstend   = `3' + (`5' - 1)
         local cstwidth = (`end`cstend'' - `start`cststart'') + 1
         tokenize "`1'",  parse("\")
         if "`3'"==""                    { 
            putdocx table `tabname'(`row_SP',`start`cststart''), colspan(`cstwidth') 
            putdocx table `tabname'(`row_SP',`start`cststart'') = ("`1'"),       ///
               font(`font', `l_fsize') `cst_format1'  halign(`cst_just1') valign(bottom)  
         }
         if "`3'"~="" & "`5'"==""             {
            if "`cstitleht'"~="triple"        {
               local cstitleht "double" 
            }
            putdocx table `tabname'(`row_SP',`start`cststart''), colspan(`cstwidth') 
            if "`cst_format1'"~="underline"   {
               putdocx table `tabname'(`row_SP',`start`cststart'') = ("`1'"),    ///
                  font(`font', `l_fsize') `cst_format1'  halign(`cst_just1') valign(bottom) append linebreak(1)  
            }
            if "`cst_format1'"=="underline"   {
               putdocx table `tabname'(`row_SP',`start`cststart'') = ("`1'"),    ///
                  font(`font', `l_fsize') halign(`cst_just1') valign(bottom) append linebreak(1)
            }  
            putdocx table `tabname'(`row_SP',`start`cststart'') = ("`3'"),       ///
               font(`font', `l_fsize') `cst_format1'  halign(`cst_just1') valign(bottom) append 
         }
         if "`5'"~=""                    {
            local cstitleht "triple" 
            putdocx table `tabname'(`row_SP',`start`cststart''), colspan(`cstwidth') 
            if "`cst_format1'"~="underline"  {
               putdocx table `tabname'(`row_SP',`start`cststart'') = ("`1'"),    ///
                  font(`font', `l_fsize') `cst_format1'  halign(`cst_just1') valign(bottom) append linebreak(1)  
               putdocx table `tabname'(`row_SP',`start`cststart'') = ("`3'"),       ///
                  font(`font', `l_fsize') `cst_format1'  halign(`cst_just1') valign(bottom) append linebreak(1)
            }
            if "`cst_format1'"=="underline"  {
               putdocx table `tabname'(`row_SP',`start`cststart'') = ("`1'"),    ///
                  font(`font', `l_fsize') halign(`cst_just1') valign(bottom) append linebreak(1)  
               putdocx table `tabname'(`row_SP',`start`cststart'') = ("`3'"),       ///
                  font(`font', `l_fsize') halign(`cst_just1') valign(bottom) append linebreak(1)
            }
            putdocx table `tabname'(`row_SP',`start`cststart'') = ("`5'"),       ///
               font(`font', `l_fsize') `cst_format1'  halign(`cst_just1') valign(bottom) append 
         }
      }
   }
   local htR = `bf167'
   if "`cstitleht'" == "double"  {
      local htR = `bf275'
   }
   if "`cstitleht'" == "triple"  {
      local htR = `bf425'
   }
   if `"`cst11'"' == ""          {
      putdocx table `tabname'(`row_SP',.), height(`htR'pt, exact) border(top, `lineT') 
   }

}



*  no column spanning titles:  horizontal line on top of column titles row

if `"`cst1'"' == ""  {
   putdocx table `tabname'(`row_C',.), border(top, `lineT')
}



*  linespaces:  add two between column titles and first data row
*  horizontal line:  between column titles and first data row

if "`slim'" == ""     {
   putdocx table `tabname'(`row_C',.), addrows(2, after)
   local row_C_1 = `row_C' + 1           //  after column title row:  1st add row
   local row_C_2 = `row_C' + 2           //  after column title row:  2nd add row
   putdocx table `tabname'(`row_C_1',.), height(`bf025'pt, exact) border(bottom)
   putdocx table `tabname'(`row_C_2',.), height(`bf058'pt, exact)
   if "`pt1'"~="" & "`pspace'"~="small"   {
      putdocx table `tabname'(`row_C_2',.), height(`bf075'pt, exact)
   }
   if "`pt1'"~="" & "`pspace'"=="small"   {
      putdocx table `tabname'(`row_C_2',.), height(`bf067'pt, exact)
   }
}
if "`slim'" ~= ""     {
   putdocx table `tabname'(`row_C',.), border(bottom)
}



*  *********************************
*
*  ****  FINISHING TOUCHES, IV  ****
*
*        title and subtitle
*
*  *********************************


**# title and subtitle
*  title and subtitle (insert linespaces for separation - between and after)

if "`TITLE'"~="" | "`TITLE1'"~="" | "`TITLE2'"~=""   {

   if "`TITLE'" ~= ""  {
      local TABNAME "tabname"
      local subcol "1"
      putdocx table `tabname'(1,.), addrows(1,before)
      putdocx table `tabname'(1,1), colspan(`col_L')
      tokenize "`TITLE'", parse("\")
      if "`5'"~=""              {
         putdocx table `tabname'(1,1) = ("`1'"), font(`font', `t_fsize')  ///
                 `title_format' halign(`title_just') valign(center) append linebreak(1)
         putdocx table `tabname'(1,1) = ("`3'"), font(`font', `t_fsize')  ///
                 `title_format' halign(`title_just') valign(center) append linebreak(1)
         putdocx table `tabname'(1,1) = ("`5'"), font(`font', `t_fsize')  ///
                 `title_format' halign(`title_just') valign(center) append
      }
      if "`5'"=="" & "`3'"~=""  {
         putdocx table `tabname'(1,1) = ("`1'"), font(`font', `t_fsize')  ///
                 `title_format' halign(`title_just') valign(center) append linebreak(1)
         putdocx table `tabname'(1,1) = ("`3'"), font(`font', `t_fsize')  ///
                 `title_format' halign(`title_just') valign(center) append
      }
      if "`3'"==""              {
         putdocx table `tabname'(1,1) = ("`1'"), font(`font', `t_fsize') `title_format'  
         putdocx table `tabname'(1,1), halign(`title_just') valign(center) 
      }
   }

   if "`TITLE1'"~="" | "`TITLE2'"~=""  {
      local TABNAME "tabnameX"
      local subcol "2"
      tempname tabnameX
      putdocx table `tabnameX' = (1,2),            ///
              layout(autofitwindow)                ///
              width(`WIDTH'in)                     ///
              `cellmargL' `cellmargR' `cellmargB'  ///
              border(all,nil) 
      local title2_width = `WIDTH' - `title1_width'
      putdocx table `tabnameX'(.,1), width(`title1_width')
      putdocx table `tabnameX'(.,2), width(`title2_width')

      forvalues t = 1/2                {
         if "`TITLE`t''" ~= ""         {
            tokenize "`TITLE`t''", parse("\")
            if "`5'"~=""               {
               putdocx table `tabnameX'(1,`t') = ("`1'"), font(`font', `t_fsize')  ///
                       `title`t'_format' halign(`title`t'_just') valign(top) append linebreak(1)
               putdocx table `tabnameX'(1,`t') = ("`3'"), font(`font', `t_fsize')  ///
                       `title`t'_format' halign(`title`t'_just') valign(top) append linebreak(1)
               putdocx table `tabnameX'(1,`t') = ("`5'"), font(`font', `t_fsize')  ///
                       `title`t'_format' halign(`title`t'_just') valign(top) append
            }
            if "`5'"=="" & "`3'"~=""   {
               putdocx table `tabnameX'(1,`t') = ("`1'"), font(`font', `t_fsize')  ///
                       `title`t'_format' halign(`title`t'_just') valign(top) append linebreak(1)
               putdocx table `tabnameX'(1,`t') = ("`3'"), font(`font', `t_fsize')  ///
                       `title`t'_format' halign(`title`t'_just') valign(top) append
            }
            if "`3'"==""               {
               putdocx table `tabnameX'(1,`t') = ("`1'"), font(`font', `t_fsize') `title`t'_format'  
               putdocx table `tabnameX'(1,`t'), halign(`title`t'_just') valign(top) 
            }
         }
      }
   }

   if "`slim'" == ""         {
      if "`SUB'" ~= ""       {
         putdocx table ``TABNAME''(1,.), addrows(1,after)
         putdocx table ``TABNAME''(2,.), height(`bf016'pt, exact) 
         putdocx table ``TABNAME''(2,.), addrows(1, after)
         putdocx table ``TABNAME''(3,.), height(`bf125'pt)
         putdocx table ``TABNAME''(2,1), colspan(`col_L')
         if "`TITLE'"~=""  {
            putdocx table ``TABNAME''(3,1), colspan(`col_L')
         }
         local subrow "3"
      }
      if "`SUB'" == ""       {
         putdocx table ``TABNAME''(1,.), addrows(1, after)
         putdocx table ``TABNAME''(2,.), height(`bf092'pt, exact) 
         putdocx table ``TABNAME''(2,1), colspan(`col_L')
      }
   }
   if "`slim'" ~= ""         {
      if "`SUB'" ~= ""       {
         putdocx table ``TABNAME''(1,.), addrows(1,after)
         putdocx table ``TABNAME''(2,.), height(`bf125'pt)
         local subrow "2"
      }
   }

   if "`SUB'" ~= ""              {
      tokenize "`SUB'", parse("\")
      if "`5'"~=""               {
         putdocx table ``TABNAME''(`subrow',`subcol') = ("`1'"), font(`font', `s_fsize')     ///
                 `sub_format' halign(`sub_just') valign(center) append linebreak(1)
         putdocx table ``TABNAME''(`subrow',`subcol') = ("`3'"), font(`font', `s_fsize')     ///
                 `sub_format' halign(`sub_just') valign(center) append linebreak(1)
         putdocx table ``TABNAME''(`subrow',`subcol') = ("`5'"), font(`font', `s_fsize')     ///
                 `sub_format' halign(`sub_just') valign(center) append
      }
      if "`5'"=="" & "`3'"~=""  {
         putdocx table ``TABNAME''(`subrow',`subcol') = ("`1'"), font(`font', `s_fsize')     ///
                 `sub_format' halign(`sub_just') valign(center) append linebreak(1)
         putdocx table ``TABNAME''(`subrow',`subcol') = ("`3'"), font(`font', `s_fsize')     ///
                 `sub_format' halign(`sub_just') valign(center) append
      }
      if "`3'"==""              {
         putdocx table ``TABNAME''(`subrow',`subcol') = ("`1'"), font(`font', `s_fsize') `sub_format'  
         putdocx table ``TABNAME''(`subrow',`subcol'), halign(`sub_just') valign(center) 
      }
      if "`slim'" == ""         {
         putdocx table ``TABNAME''(3,.), addrows(1, after)
         putdocx table ``TABNAME''(4,.), height(`bf083'pt, exact) 
         putdocx table ``TABNAME''(4,1), colspan(`col_L')
      }
   }

   if "`TITLE1'"~="" | "`TITLE2'"~=""  {
      if "`SUB'" == ""      {
         if "`slim'" ~= ""  {
            putdocx table `tabnameX'(1,.), addrows(1, after)
            local ROW_TAB "2"
         }
         if "`slim'" == ""  {
            putdocx table `tabnameX'(2,.), addrows(1, after)
            local ROW_TAB "3"
         }
      }
      if "`SUB'" ~= ""      {
         if "`slim'" ~= ""  {
            putdocx table `tabnameX'(2,.), addrows(1, after)
            local ROW_TAB "3"
         }
         if "`slim'" == ""  {
            putdocx table `tabnameX'(4,.), addrows(1, after)
            local ROW_TAB "5"
         }
      }
      putdocx table `tabnameX'(`ROW_TAB',1), colspan(`col_L') 
      putdocx table `tabnameX'(`ROW_TAB',1) = table(`tabname')
   }

}



******************************************************************************************
******************************************************************************************


**# saving and clean-up
*  *******************************
*
*  ****  SAVING AND CLEAN-UP  ****
*
*  *******************************



*  saving

if "`outfile'" ~= ""  {
   noi di _n(1) " "
   noi putdocx save "`OUTF'", `OPT' 
   noi di " "
}



*  clean-up

capture matrix drop XxYyZz
capture matrix drop xX_C
capture matrix drop xX_CZ
capture matrix drop xX_CM
capture matrix drop xX_CZM
capture matrix drop xX_SE
capture matrix drop xX_ZV
capture matrix drop xX_PV
capture matrix drop xX_PVX
capture matrix drop xX_CI
capture matrix drop xX_STPC
capture matrix drop xX_EXC
forvalues p = 1/`n_p'    {
   capture matrix drop xX_MEANS`p'
   capture matrix drop xX_MAT`p'
   capture matrix drop xX_M`p'
   capture matrix drop xX_C`p'
   capture matrix drop xX_CZ`p'
   capture matrix drop xX_CM`p'
   capture matrix drop xX_CZM`p'
   capture matrix drop xX_SE`p'
   capture matrix drop xX_ZV`p'
   capture matrix drop xX_PV`p'
   capture matrix drop xX_PVX`p'
   capture matrix drop xX_CI`p'
   capture matrix drop xX_STPC1`p'
   capture matrix drop xX_STPC2`p'
}



}       //  end quietly



end
