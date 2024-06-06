*! version 16.19   3.6.2024   John Casterline
capture program drop mswtable
program define mswtable, rclass
version 16

set adosize 60


#d ;

local INPUT `"`0'"';

syntax , COLWidth(string)
         [ mat(string)
           mat1(string) mat2(string) mat3(string) mat4(string) mat5(string)
           est(string) 
           est1(string) est2(string) est3(string) est4(string) est5(string)
           est_stat(string) 
           est_stat1(string) est_stat2(string) est_stat3(string) est_stat4(string)
           est_stat5(string)
           est_star(string)  est_se  est_se(string)  est_no(string) 
           est_means(string)  est_mat(string)
           title(string) SUBTitle(string)
           note1(string) note2(string) note3(string) note4(string) note5(string)
           note6(string) note7(string) note8(string) note9(string)
           font(passthru)
           tline(string) bline(string)   firstX lastX   extra_place
           sdec(string)  
           ct(string)
           cst_set(string)
           cst1(string asis) cst2(string asis) cst3(string asis) cst4(string asis)
           cst5(string asis) cst6(string asis) cst7(string asis) cst8(string asis)
           cst9(string asis) cst10(string asis)
           cst11(string asis) cst12(string asis) cst13(string asis) cst14(string asis) cst15(string asis)
           rt(string)
           rt1(string) rt2(string) rt3(string) rt4(string) rt5(string)
           rst_set(string)  
           rst1(string asis)  rst2(string asis)  rst3(string asis)  rst4(string asis)  rst5(string asis)
           rst6(string asis)  rst7(string asis)  rst8(string asis)  rst9(string asis)  rst10(string asis)
           rst11(string asis)  rst12(string asis)  rst13(string asis)  rst14(string asis)  rst15(string asis)
           rst16(string asis)  rst17(string asis)  rst18(string asis)  rst19(string asis)  rst110(string asis)
           rst111(string asis) rst112(string asis) 
           rst21(string asis)  rst22(string asis)  rst23(string asis)  rst24(string asis)  rst25(string asis)
           rst26(string asis)  rst27(string asis)  rst28(string asis)  rst29(string asis)  rst210(string asis)
           rst211(string asis) rst212(string asis)
           rst31(string asis)  rst32(string asis)  rst33(string asis)  rst34(string asis)  rst35(string asis)
           rst36(string asis)  rst37(string asis)  rst38(string asis)  rst39(string asis)  rst310(string asis)
           rst311(string asis) rst312(string asis) 
           rst41(string asis)  rst42(string asis)  rst43(string asis)  rst44(string asis)  rst45(string asis)
           rst46(string asis)  rst47(string asis)  rst48(string asis)  rst49(string asis)  rst410(string asis)
           rst411(string asis) rst412(string asis) 
           rst51(string asis)  rst52(string asis)  rst53(string asis)  rst54(string asis)  rst55(string asis)
           rst56(string asis)  rst57(string asis)  rst58(string asis)  rst59(string asis)  rst510(string asis)
           rst511(string asis) rst512(string asis)  
           pt_set(string)
           pt1(string) pt2(string) pt3(string) pt4(string) pt5(string)
           pline   
           extra1(string) extra2(string) extra3(string) extra4(string) extra5(string)
           extra6(string) extra7(string) extra8(string) extra9(string) 
           extra11(string) extra12(string) extra13(string) extra14(string)
           extra15(string) extra16(string) extra17(string) extra18(string)
           extra19(string)
           extra21(string) extra22(string) extra23(string) extra24(string)
           extra25(string) extra26(string) extra27(string) extra28(string)
           extra29(string)
           extra31(string) extra32(string) extra33(string) extra34(string)
           extra35(string) extra36(string) extra37(string) extra38(string)
           extra39(string)
           extra41(string) extra42(string) extra43(string) extra44(string)
           extra45(string) extra46(string) extra47(string) extra48(string)
           extra49(string)
           extra51(string) extra52(string) extra53(string) extra54(string)
           extra55(string) extra56(string) extra57(string) extra58(string)
           extra59(string) 
           slim
           tabname(string)  
           OUTFile(string) ];  

#d cr

*  n = 206 options  (max allowed = 256)


if "`mat'"~="" & "`mat1'"~=""     {
   di _n(1) _col(3) in y  "ERROR:  mat or mat1 can be specified but not both"  _n(1) " "
   exit
}

if "`est'"~="" & "`est1'"~=""     {
   di _n(1) _col(3) in y  "ERROR:  est or est1 can be specified but not both"  _n(1) " "
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

if ("`est'"=="" & "`est1'"=="") & ("`est_stat'"~="" | "`est_star'"~="" | "`est_se'"~="" | "`est_means'"~="")     {
   noi di _n(1) _col(3) in y  "ERROR:  est option requested but not est"   _n(1) " "
   exit
}

if "`est_means'"~=""  &  "`est_mat'"~=""  {
   noi di _n(1) _col(3) in y  "ERROR:  cannot specify BOTH est_means and est_mat"  _n(1) " "
   exit
}




*************************************************************************************
*************************************************************************************


*  ***********************************************************
*
*  ****  RECONCILING SINGLE-PANEL AND MULTI-PANEL SYNTAX  ****
*
*  ***********************************************************



if "`mat'" ~= ""             {
   local mat1 "`mat'"
   macro drop _mat
}

if "`est'" ~= ""             {
   local est1 "`est'"
   macro drop _est
}

if "`est_stat'" ~= ""        {
   local est_stat1 "`est_stat'"
   macro drop _est_stat
   forvalues p = 2/5         {
      if "`est`p''"~="" & "`est_stat`p''"==""  {
         local est_stat`p' "`est_stat1'"
      }
   }
}

if "`rt'" ~= ""              {
   local rt1 "`rt'"
   macro drop _rt
}

if `"`rst1'"' ~= ""          {
   forvalues r = 16(-1)1     {
      if `"`rst`r''"' ~= ""  {
         local rst1`r' `"`rst`r''"'  
         capture macro drop _rst`r'
      }
   }
}



*************************************************************************************
*************************************************************************************


*  *********************************
*
*  ****  SOME INITIAL SETTINGS  ****
*
*  *********************************



if "`tabname'" == ""  {
   local tabname "DdMmTtZz"
}


*  fonts

local FONT "Cambria"
local t_fsize  "12.5"    //  title
local s_fsize  "12.5"    //  sub-title
local l_fsize  "12"      //  column labels, row labels
local b_fsize  "12"      //  body of table
local st_fsize "11"      //  statistics 
local ex_fsize "11"      //  extra information
local se_fsize "10.5"    //  standard errors (including t and p)
local ci_fsize "10"      //  confidence intervals
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
      local b_fsizeX = real("`b_fsize'")
      local st_fsize = `b_fsizeX' - 1.0    //  statistics
      local ex_fsize = `b_fsizeX' - 1.0    //  extra information
      local se_fsize = `b_fsizeX' - 1.5    //  standard errors (including t and p)
      local ci_fsize = `b_fsizeX' - 2.0    //  confidence intervals
      local a_fsize  = `b_fsizeX' - 1.5    //  asterisks
      local n_fsize  "`font5'"             //  notes
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
local bf121 = `b_fsize'*(14.5/12)*`inflate'
local bf125 = `b_fsize'*(15/12)*`inflate'
local bf142 = `b_fsize'*(17/12)*`inflate'
local bf150 = `b_fsize'*(18/12)*`inflate'
local bf167 = `b_fsize'*(20/12)*`inflate'
local bf182 = `b_fsize'*(22/12)*`inflate'
local bf250 = `b_fsize'*(30/12)*`inflate'
local bf375 = `b_fsize'*(45/12)*`inflate'


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



*  cst_set

local cst_format "underline"
if "`cst_set'" == "bold"    {
   local cst_format "bold"
}
if "`cst_set'" == "none"    {
   local cst_format ""
}



*  rst_set

local rst_format ""
local rst_indent ""
if "`rst_set'" ~= ""           {
   tokenize "`rst_set'", parse(" ,")
   while "`1'" ~= ""           {
      if "`1'" == "bold"       {
        local rst_format "bold"
      }
      if "`1'" == "underline"  {
         local rst_format "underline"
      }
      if "`1'" == "indent"     {
         local rst_indent "indent"
      }
      mac shift
   }
}



*  pt_set

local pt_format "underline"
if "`pt_set'" == "bold"    {
   local pt_format "bold"
}
if "`pt_set'" == "none"    {
   local pt_format ""
}



*  est_se

tokenize `"`INPUT'"', parse(" ,")
while `"`1'"' ~= ""        {
   if `"`1'"' == "est_se"  {
      local est_se "XX"
      local STPC   "se"
      local BE     "below"
      local PAREN  "yes"
   }
   mac shift
}
 


* PUTDOCX table:  a few preliminaries

if "`outfile'" ~= ""  {
   local OPT "replace"
   tokenize "`outfile'", parse(" ,")
   local OUTF "`1'"
   mac shift
   while "`1'" ~= ""  {
      if "`1'" == "append"     {
         local OPT "append(pagebreak stylesrc(own))"
      } 
      if "`1'" == "landscape"  {
         local landscape "landscape"
      }
      mac shift
   }
}




quietly  {


*************************************************************************************
*************************************************************************************


*  **********************************
*
*  ****  PROCESSING MAT and EST  ****
*
*  **********************************



local n_mat   = 0
local n_est   = 0
local n_pstat = 0
local n_pt    = 0
local n_rt    = 0
forvalues p = 1/5  {
   if "`mat`p''" ~= ""      {
      local n_mat = `n_mat' + 1
      local n_pt  = `n_pt'  + 1
   }
   if "`est`p''" ~= ""      {
      local n_est = `n_est' + 1
      local n_pt  = `n_pt'  + 1
   }
   if "`est_stat`p''" ~= "" {
      local n_pstat = `n_pstat' + 1
   }
   if "`rt`p''"  ~= ""      {
      local n_rt  = `n_rt' + 1
   }
}
local n_p = `n_mat' + `n_est'


if "`mat1'" ~= ""  {
   if `n_mat' ~= `n_rt'     {
      noi di _n(2) _col(3) in y  "ERROR:  must have equal numbers of mat# and rt#"   _n(1) " "
      exit  
   }
}
if "`est1'" ~= ""  {
   if `n_est' ~= `n_rt'  {
      noi di _n(2) _col(3) in y  "ERROR:  must have equal numbers of est# and rt#"   _n(1) " "
      exit  
   }
   if (`n_est'~=`n_pstat') & "`est_stat1'"~=""  {
      noi di _n(2) _col(3) in y  "ERROR:  must have equal numbers of est# and est_stat#"   _n(1) " "
      exit  
   }
}



*  processing matrices

if "`mat1'" ~= ""  {

   local n_colD : colsof `mat1'
   local n_colM = 0                  //  means/matrix - always zero with matrix input
   local n_rowD = 0
   local n_rowS = 0                  //  statistics - always zero with matrix input
   matrix XxYyZz = `mat1'
   forvalues m = 1/5   {
      if "`mat`m''" ~= ""  {
         local n_rowD`m' : rowsof `mat`m''
         local n_rowD = `n_rowD' + `n_rowD`m''
         local n_rowS`m' = 0        //  statistics - always zero with matrix input
         if `m' > 1        {
            matrix XxYyZz = XxYyZz \ `mat`m''
         }
      }
   }
}
local mat "XxYyZz"



*  processing estimates

if "`est1'" ~= ""  {

   forvalues p = 1/`n_est'  {
      local eqs`p' " "
      tokenize "`est`p''", parse(", ")
      local k = 1
      while "`1'" ~= ""     {
         if "`1'" ~= ","    {
            local eq`p'`k' "`1'"
            local eqs`p' "`eqs`p'' `eq`p'`k''"
            local ++k
         }
         mac shift
      }
    } 


   forvalues p = 1/`n_est'    {
      local stats`p' " "
      if "`est_stat`p''" ~= ""   {
         tokenize "`est_stat`p''", parse("!")
         local s = 0
         local N_STAT = 0
         while "`1'" ~= ""    {
            if "`1'" ~= "!"   {
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

   if "`est_star'" == ""  {
      local num_es = 3
      local pv1 = 0.10
      local pv2 = 0.01
      local pv3 = 0.001
   }
   if "`est_star'" ~= ""  {
      local num_es = 0
      tokenize "`est_star'", parse(" ,")
      local k = 1
      while "`1'" ~= ""    {
         if "`1'" ~= ","   {
            local ++num_es
            local pv`k' "`1'"
            local ++k
         }
         mac shift
      }    
   }

   local ci_p = .05
   if "`est_se'" ~= ""  {
      local STPC   "se"
      local BE     "below"
      local PAREN  "yes"
      tokenize "`est_se'", parse(" ,()")
      while "`1'" ~= ""  {
         if "`1'" == "t"        {
            local STPC "t"
         }
         if "`1'" == "p"        {
            local STPC "p"
         } 
         if "`1'" == "ci"       {
            local STPC "ci"
         }
         if real("`1'")>=.0001 & real("`1'")<=.50  {
            local ci_p = `1'
         }
         if real("`1'")>=4 & real("`1'")<30  {
            local ci_fsize "`1'"    
         }
         if "`1'" == "noparen"  {
            local PAREN "no"
         }      
         if "`1'" == "beside"   {
            local BE "beside"
         }
         if "`BE'"=="beside" & "`est_star'"~=""  {
            noi di _n(2) _col(3) in y  "ERROR:  est_star and se/t/p/ci beside are incompatible"   _n(1) " "
            exit         
         }
         mac shift
      }
   }


*  matrix EQ:  coefficients and variances 

   forvalues p = 1/`n_est'  {
      qui estimates table `eqs`p''
      matrix EQ`p' = r(coef)
   }
   local n_colD : colsof EQ1
   local n_colDX = `n_colD'         //  n columns - coefficients and variances
   local n_colD  = `n_colD'/2       //  n columns - coefficients only


*  model degrees of freedom (for t-distribution)

   forvalues p = 1/`n_est'  {
      local k = 1
      foreach e of local eqs`p'  {
         estimates restore `e'
         local DF`p'`k' = `e(df_r)'
         local ++k
      }
   }
  

*  matrices C#:  coefficients only

   forvalues p = 1/`n_est'          {
      local C "coef1"
      capture matrix drop coef1
      matrix coef1 = EQ`p'[1...,1]
      local k = 2
      forvalues c = 3(2)`n_colDX'   {
         capture matrix drop coef`k'
         matrix coef`k' = EQ`p'[1...,`c']
         local C "`C',coef`k'"
         local ++k
      }
      matrix C`p' = `C'
      local n_rowD`p' : rowsof C`p'            //  # data/coeff rows in each panel
      local ROWNAMES  : rownames C`p'
      local ROWNAMESX = subinstr("`ROWNAMES'","_cons","intercept",1)
      matrix rownames C`p' = `ROWNAMESX'
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


*  matrices V#:  variances

   forvalues p = 1/`n_est'          {
      local V "var1"
      capture matrix drop var1
      matrix var1 = EQ`p'[1...,2]
      local k = 2
      forvalues c = 4(2)`n_colDX'   {
         capture matrix drop var`k'
         matrix var`k' = EQ`p'[1...,`c']
         local V "`V',var`k'"
         local ++k
      }
      matrix V`p' = `V'
   }


*  matrices se#:   vector of se for each coefficient (including z and p)
*  matrices tv#:   vector of t-statistics for each coefficient
*  matrices pv#:   vector of p-values for each coefficient
*  matrices pvx#:  vector of p-values ( "1" "2" "3" according to p-value thresholds; miss = -99 )
*  matrices ci_l#: vector of confidence interval lower value
*  matrices ci_u#: vector of confidence interval upper value

   forvalues p = 1/`n_est'             {
      forvalues c = 1/`n_colD'         {
         matrix se`p'`c'   = J(`n_rowD`p'',1,0)
         matrix tv`p'`c'   = J(`n_rowD`p'',1,0)
         matrix pv`p'`c'   = J(`n_rowD`p'',1,0)
         matrix pvx`p'`c'  = J(`n_rowD`p'',1,0)
         matrix ci_l`p'`c' = J(`n_rowD`p'',1,0)
         matrix ci_u`p'`c' = J(`n_rowD`p'',1,0)
         forvalues r = 1/`n_rowD`p''  {
            scalar coef_`r'_`c' = C`p'[`r',`c']
            scalar var_`r'_`c'  = V`p'[`r',`c']
            scalar se_`r'_`c'   = sqrt(var_`r'_`c')
            scalar tv_`r'_`c'   = abs(coef_`r'_`c'/se_`r'_`c')
            scalar pv_`r'_`c'   = 2*(ttail(`DF`p'`c'',tv_`r'_`c'))
            gen pvx_`r'_`c' = -99
            forvalues PVX = 1/`num_es'  {
               replace pvx_`r'_`c' = `PVX'  if (pv_`r'_`c'<=`pv`PVX'')
            }
            scalar ci_l_`r'_`c' = coef_`r'_`c' - ((invttail(`DF`p'`c'',`ci_p')*se_`r'_`c'))
            scalar ci_u_`r'_`c' = coef_`r'_`c' + ((invttail(`DF`p'`c'',`ci_p')*se_`r'_`c'))
            matrix se`p'`c'[`r',1]   = se_`r'_`c'
            matrix tv`p'`c'[`r',1]   = tv_`r'_`c'
            matrix pv`p'`c'[`r',1]   = pv_`r'_`c'
            matrix ci_l`p'`c'[`r',1] = ci_l_`r'_`c'
            matrix ci_u`p'`c'[`r',1] = ci_u_`r'_`c'
            sum pvx_`r'_`c', meanonly
            matrix pvx`p'`c'[`r',1]  = `r(mean)'
            scalar drop coef_`r'_`c'  var_`r'_`c'  se_`r'_`c'  tv_`r'_`c'  pv_`r'_`c'
            scalar drop ci_l_`r'_`c' ci_u_`r'_`c'
            capture drop pvx_`r'_`c'
         }
      }
   }


*  matrix SE#:   standard errors
*  matrix TV#:   t-statistics
*  matrix PV#:   p-values
*  matrix PVX#:  p-values  ( "1" "2" "3" according to p-value thresholds; miss = -99 )
*  matrix CI#:   confidence interval bounds - lower and upper

   forvalues p = 1/`n_est'      {

      local SE "se`p'1"
      forvalues c = 2/`n_colD'  {
         local SE "`SE',se`p'`c'"
      }
      matrix SE`p' = `SE'

      local TV "tv`p'1"
      forvalues c = 2/`n_colD'  {
         local TV "`TV',tv`p'`c'"
      }
      matrix TV`p' = `TV'

      local PV "pv`p'1"
      forvalues c = 2/`n_colD'  {
         local PV "`PV',pv`p'`c'"
      }
      matrix PV`p' = `PV'

      local PVX "pvx`p'1"
      forvalues c = 2/`n_colD'  {
         local PVX "`PVX',pvx`p'`c'"
      }
      matrix PVX`p' = `PVX'

      local CI "ci_l`p'1,ci_u`p'1"
      forvalues c = 2/`n_colD'  {
         local CI "`CI',ci_l`p'`c',ci_u`p'`c'"
      }
      matrix CI`p' = `CI'

   }


*  define matrix for standard errors (or t-statistic or p-value or confidence-interval):

   if "`est_se'" ~= ""          {
      forvalues p = 1/`n_est'   {
         if "`STPC'" == "se"    {
            matrix STPC`p' = SE`p'
         }
         if "`STPC'" == "t"     {
            matrix STPC`p' = TV`p' 
         }
         if "`STPC'" == "p"     {
            matrix STPC`p' = PV`p'
         }
         if "`STPC'" == "ci"    {
            matrix STPC`p' = CI`p'
         }
      }
   }


   local n_colM = 0


*  est_means option -- obtain vector of means

   if "`est_means'" ~= ""          {
      local k = 0
      tokenize "`est_means'", parse(" ,")
      local ADD_SIDE = cond("`1'"=="left" | "`1'"=="right","`1'","left")
      while "`1'" ~= ""            {
         if "`1'"~="left" & "`1'"~="right" & "`1'" ~= ","   {
            local ++k
            estimates restore `1'
            qui margins, atmeans          //  or, could employ estat summarize
            matrix MEANS`k' = r(at)'
            local n_colM = 1
         }
         mac shift
      }
      if `k' ~= `n_pt'             {
         noi di _n(2) _col(3) in y  "ERROR:  est_means - number of equation names unequal to number of panels"   _n(1) " "
         exit  
      }
   }  


*  est_mat - additional matrix

   if "`est_mat'" ~= ""          {
      if "`mat1'" ~= ""          {
         noi di _n(2) _col(3) in y  "ERROR:  est_mat cannot be used with mat"
         noi di       _col(3) in y  "        use matrix utilities to combine the matrices"    _n(1) " "
         exit  
      }
      local k = 0
      tokenize "`est_mat'", parse(" ,")
      local ADD_SIDE = cond("`1'"=="left" | "`1'"=="right","`1'","left")
      while "`1'" ~= ""          {
         if "`1'"~="left" & "`1'"~="right" & "`1'" ~= ","   {
            local ++k
            matrix MAT`k' = `1'
            local n_rowM`k' : rowsof MAT`k'
            local n_colM`k' : colsof MAT`k'
         }
         mac shift
      }
      if `k' ~= `n_pt'           {
         noi di _n(2) _col(3) in y  "ERROR:  est_mat - number of matrix names unequal to number of panels"   _n(1) " "
         exit  
      }
      forvalues p = 1/`n_pt'     { 
         forvalues P = 1/`n_pt'  {
            if `n_colM`p'' ~= `n_colM`P''  {
               noi di _n(2) _col(3) in y  "ERROR:  est_mat - number of matrix columns must be the same in all panels"   _n(1) " "
               exit
            }
         }
      }
      local n_colM = `n_colM1'
   }  


*  est_no option -- identify "no" columns (accounting for extra means/matrix columns)

   forvalues c = 1/`n_colD'        { 
      local est_no`c' "yes"
   }
   if "`est_no'" ~= ""             {
      tokenize "`est_no'", parse(" ,")
      while "`1'" ~= ""            {
         forvalues c = 1/`n_colD'  {
            if "`1'" == "`c'"      {
               local d = cond("`ADD_SIDE'"=="left",`c' + `n_colM',`c')
               local est_no`d' "no"
            }
         }
         mac shift
      }
   }   



*  construct matrices for input to putdocx table:
*      C    if no statistics have been requested
*      CM   if no statistics, but means or matrix have been requested
*      CZ   if statistics have been requested [ CZ = C + STAT ]
*      CZM  if statistics and means/matrix have been requested  [ CZM = CM + STAT ] 

   matrix C = C1
   forvalues p = 2/`n_est'      {
      matrix C = C \ C`p'
   }
   local mat "C"
   if "`est_stat1'" ~= ""       {
      matrix CZ1 = C1 \ STAT1
      matrix CZ = CZ1
      forvalues p = 2/`n_est'   { 
         matrix CZ`p' = C`p' \ STAT`p'
         matrix CZ = CZ \ CZ`p'
      }
      local mat "CZ"
   } 
   if "`est_means'"~="" & "`est_stat1'"==""   {
      if "`ADD_SIDE'" == "left"               {
         matrix coljoinbyname CM1 = MEANS1 C1
         matrix CM = CM1
         forvalues p = 2/`n_est'              {
            matrix coljoinbyname CM`p' = MEANS`p' C`p'
            matrix CM = CM \ CM`p'
         }
      }
      if "`ADD_SIDE'" == "right"              {
         matrix coljoinbyname CM1 = C1 MEANS1
         matrix CM = CM1
         forvalues p = 2/`n_est'              {
            matrix coljoinbyname CM`p' = C`p' MEANS`p'
            matrix CM = CM \ CM`p'
         }
      }
      local mat "CM"
   }
   if "`est_means'"~="" & "`est_stat1'"~=""   {
      if "`ADD_SIDE'" == "left"               {
         matrix coljoinbyname CZM1 = MEANS1 CZ1
         matrix CZM = CZM1
         forvalues p = 2/`n_est'              {
            matrix coljoinbyname CZM`p' = MEANS`p' CZ`p'
            matrix CZM = CZM \ CZM`p'
         }
      }
      if "`ADD_SIDE'" == "right"              {
         matrix coljoinbyname CZM1 = CZ1 MEANS1
         matrix CZM = CZM1
         forvalues p = 2/`n_est'              {
            matrix coljoinbyname CZM`p' = CZ`p' MEANS`p'
            matrix CZM = CZM \ CZM`p'
         }
      }
      local mat "CZM"
   }
   if "`est_mat'"~=""                         {     //  truncate rows if exceeds rows in C matrix 
      forvalues p = 1/`n_est'                 {
         matrix M`p' = MAT`p'
         if `n_rowM`p'' > `n_rowD`p''         {
            matrix M`p' = MAT`p'[1..`n_rowD`p'', 1..`n_colM`p'']
         }
      }      
   }
   if "`est_mat'"~="" & "`est_stat1'"==""     {
      local n_colCM = `n_colD' + `n_colM1'
      local leftX  = `n_colM1' + 1
      local rightX = `n_colD'  + 1
      forvalues p = 1/`n_est'                 {     
         matrix CM`p' = J(`n_rowD`p'',`n_colCM',.)   //  create empty matrix
         if "`ADD_SIDE'" == "left"            {
            matrix CM`p'[1,1] = M`p'
            matrix CM`p'[1,`leftX'] = C`p'
         }
         if "`ADD_SIDE'" == "right"           {
            matrix CM`p'[1,1] = C`p'
            matrix CM`p'[1,`rightX'] = M`p'
         }
      }
      matrix CM = CM1
      forvalues p = 2/`n_est'                 {
         matrix CM = CM \ CM`p'
      }
      local mat "CM"
   }
   if "`est_mat'"~="" & "`est_stat1'"~=""     {
      local n_colCM = `n_colD' + `n_colM1'
      local leftX  = `n_colM1' + 1
      local rightX = `n_colD'  + 1
      forvalues p = 1/`n_est'                 {     
         local n_rowDS`p' = `n_rowD`p'' + `n_rowS`p''
         matrix CZM`p' = J(`n_rowDS`p'',`n_colCM',.)   //  create empty matrix
         if "`ADD_SIDE'" == "left"            {
            matrix CZM`p'[1,1] = M`p'
            matrix CZM`p'[1,`leftX'] = CZ`p'
         }
         if "`ADD_SIDE'" == "right"           {
            matrix CZM`p'[1,1] = CZ`p'
            matrix CZM`p'[1,`rightX'] = M`p'
         }
      }
      matrix CZM = CZM1
      forvalues p = 2/`n_est'                 {
         matrix CZM = CZM \ CZM`p'
      }
      local mat "CZM"
   }



*  est clean up

   forvalues p = 1/`n_est'  {
      capture matrix drop EQ`p'
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
   
  
}     //  end processing est  




*************************************************************************************
*************************************************************************************


*  **********************************
*
*  **** INITIALIZING DIMENSIONS  ****
*
*  **********************************


*  Guide to rows and columns
*
*     n_rowD   number data rows (coefficients or matrix elements):        all panels
*     n_rowS   number statistics rows (N, r-squared, BIC, etc):           all panels
*
*     n_colD   number of data columns (equations or matrix elements), excluding means/matrices
*     n_colM   number of means/matrix columns
*     n_colT   number of data/means/matrix columns
*     n_colTX  number of columns:  row title + data/means/matrix columns
*
*     col_DF   first data column (with extra column: row title)
*     col_DL   last data column (with extra columns: row title, stars, se)
*     col_MF   first means/matrix column (with extra column for row title)
*     col_ML   last means/matrix column (with extra column for row title) 
*     col_F    first data/means/matrix column (with extra column for row title)
*     col_L    last data/means/matrix column (with extra column for row titles)
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


*  Guide to columns
*
*     n_colD   number of data columns (equations or matrix elements), excluding means/matrices
*     n_colM   number of means/matrix columns
*     n_colT   number of data/means/matrix columns
*     n_colTX  number of columns:  row title + data/means/matrix columns
*
*     col_DF   first data column (with extra column: row title)
*     col_DL   last data column (with extra columns: row title, stars, se)
*     col_MF   first means/matrix column (with extra column for row title)
*     col_ML   last means/matrix column (with extra column for row title) 
*     col_F    first data/means/matrix column (with extra column for row title)
*     col_L    last data/means/matrix column (with extra column for row titles)
*

local n_colT  = `n_colD' + `n_colM'
local n_colTX = `n_colT' + 1

local col_MF = 0
local col_ML = 0

if "`ADD_SIDE'" ~= "left"    {
   local col_DF = 1 + 1 
   local col_DL = `col_DF' + (`n_colD' - 1)
   if "`est_star'"~="" | "`BE'"=="beside"    {
      local col_DL = `col_DF' + ((2*`n_colD') - 1)
   }
   if "`est_means'"~="" | "`est_mat'"~=""    {
      local col_MF = `col_DL' + 1
      local col_ML = `col_MF' + (`n_colM' - 1)
   }
}
if "`ADD_SIDE'" == "left"    {
   local col_DF = 1 + `n_colM' + 1
   local col_DL = `col_DF' + (`n_colD' - 1)
   if "`est_star'"~="" | "`BE'"=="beside"    {
      local col_DL = `col_DF' + ((2*`n_colD') - 1)
   }
   local col_MF = 1 + 1
   local col_ML = `col_MF' + (`n_colM' - 1)
}

local col_F = cond(`col_MF'<`col_DF' & `col_MF'>0,`col_MF',`col_DF')
local col_L = cond(`col_ML'>`col_DL' & `col_ML'>0,`col_ML',`col_DL')




*************************************************************************************
*************************************************************************************


*  ******************************
*
*  ****  FORMATTING COLUMNS  ****
*
*  ******************************


*  width of columns  ( allowing extra columns for est_star and est_se_beside )
*                    ( takes into account columns of means/matrices )
*                    ( use last entry in `colwidth' to fill in remainder of columns )

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
                       
if "`est_star'"=="" & "`BE'"~="beside"   {
   forvalues c = 1/`n_colTX'     {
      local colwidth`c' "1in"
      if "`cw`c'" ~= ""   {
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
   if `col_MF' > 0               {
      local k = cond("`ADD_SIDE'"=="right",`n_colD' + 2,2)
      forvalues c = `col_MF'/`col_ML'   {
         local colwidth`c' "1in"
         if "`cw`k''" ~= ""      {
            local colwidth`c' "`cw`k''in"
         }
         local ++k
      }
   }      
}

if "`BE'" == "beside"            {
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
      if "`STPC'" ~= "ci"       {
         if "`cw`k''" ~= ""     {
            local cwX = 0.75*`cw`k''
            local colwidth`c' "`cwX'in"     
         }
      }
      if "`STPC'" == "ci"       {
         if "`cw`k''" ~= ""     {
            local cwX = 1.8*`cw`k''
            local colwidth`c' "`cwX'in"     
         }
      }
      local ++k
   }
   if `col_MF' > 0               {
      local k = cond("`ADD_SIDE'"=="right",`n_colD' + 2,2)
      forvalues c = `col_MF'/`col_ML'  {
         local colwidth`c' "1in"
         if "`cw`k''" ~= ""      {
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


*  format of data columns (number of decimals)  ( allowing extra columns for est_star and est_se "beside" )
*  default = %8.1f

if "`sdec'" ~= ""         {
   tokenize "`sdec'", parse(" ,")
   local k = 1
   while "`1'"~=""        {
      if "`1'" ~= ","     {
         local nf`k' "`1'"
         local D = `1' + 1             //  set additional decimals (if any) for standard error
         local sef`k' "`D'"
         local NF "`nf`k''"
         local ++k
      }
      mac shift
   }
   forvalues j = `k'/`n_colT'   {      //  extend through all data columns
      local nf`j' "`NF'"
      local sef`j' "`D'"
   }      
}

if "`est_star'"=="" & "`BE'"~="beside"  {
   local k = 1
   forvalues c = `col_F'/`col_L'        {
      local nform`c' "%8.1f"
      if "`sdec'" ~= ""                 {
         if "`nf`k''" ~= ""             {
            local NFORM "%8.`nf`k''f"
         }
         local nform`c' "`NFORM'"
      }
      local ++k
   } 
   if "`BE'" == "below"                 {
      local k = `col_DF' - 1
      forvalues c = `col_DF'/`col_DL'   {
         if "`STPC'" == "se"            {
            local stpcform`c' "%8.2f"
            if "`sdec'" ~= ""           {
               if "`sef`k''" ~= ""      {
                  local STPCFORM "%8.`sef`k''f"
               }
               local stpcform`c' "`STPCFORM'"
            }
         }
         if "`STPC'"=="t"               {
            local stpcform`c' "%3.2f"
         }
         if "`STPC'"=="p"               {
            local stpcform`c' "%4.3f"
         }
         if "`STPC'"=="ci"              {
            local stpcform`c' "`nform`c''"
         }
         local ++k
      }
   }   
}

if "`est_star'" ~= ""                   {
   local k = `col_DF' - 1
   forvalues c = `col_DF'(2)`col_DL'    {
      local nform`c' "%8.1f"
      if "`sdec'" ~= ""                 {
         if "`nf`k''" ~= ""             {
            local NFORM "%8.`nf`k''f"
         }
         local nform`c' "`NFORM'"
      }
      local ++k
   }  
   if "`BE'" == "below"                 {
      local k = `col_DF' - 1
      forvalues c = `col_DF'(2)`col_DL' {
         if "`STPC'" == "se"            {
            local stpcform`c' "%8.2f"
            if "`sdec'" ~= ""           {
               if "`sef`k''" ~= ""      {
                  local STPCFORM "%8.`sef`k''f"
               }
               local stpcform`c' "`STPCFORM'"
            }
         }
         if "`STPC'"=="t"               {
            local stpcform`c' "%3.2f"
         }
         if "`STPC'"=="p"               {
            local stpcform`c' "%4.3f"
         }
         if "`STPC'"=="ci"              {
            local stpcform`c' "`nform`c''"
         }
         local ++k
      }
   } 
   if `col_MF' > 0                      {
      local k = cond("`ADD_SIDE'"=="right",`n_colD' + 1,1)
      forvalues c = `col_MF'/`col_ML'   {
         local nform`c' "%8.1f"
         if "`sdec'" ~= ""              {
            if "`nf`k''" ~= ""          {
               local NFORM "%8.`nf`k''f"
            }
            local nform`c' "`NFORM'"
         }
         local ++k
      }
   }  
}

if "`BE'" == "beside"                   {
   local k = `col_DF' - 1
   forvalues c = `col_DF'(2)`col_DL'    {
      local nform`c' "%8.1f"
      if "`sdec'" ~= ""                 {
         if "`nf`k''" ~= ""             {
            local NFORM "%8.`nf`k''f"
         }
         local nform`c' "`NFORM'"
      }
      local ++k
   }  
   local k = `col_DF' - 1
   local col_DFX = `col_DF' + 1
   forvalues c = `col_DFX'(2)`col_DL'   {
      if "`STPC'" == "se"               {
         local stpcform`c' "%8.2f"
         if "`sdec'" ~= ""              {
            if "`sef`k''" ~= ""         {
               local STPCFORM "%8.`sef`k''f"
            }
            local stpcform`c' "`STPCFORM'"
         }
      }
      if "`STPC'"=="t"                  {
         local stpcform`c' "%3.2f"
      }
      if "`STPC'"=="p"                  {
         local stpcform`c' "%4.3f"
      }
      if "`STPC'"=="ci"                 {
         local b = `c' - 1
         local stpcform`c' "`nform`b''"
      }
      local ++k
   } 
   if `col_MF' > 0                      {
      local k = cond("`ADD_SIDE'"=="right",`n_colD' + 1,1)
      forvalues c = `col_MF'/`col_ML'   {
         local nform`c' "%8.1f"
         if "`sdec'" ~= ""              {
            if "`nf`k''" ~= ""          {
               local NFORM "%8.`nf`k''f"
            }
            local nform`c' "`NFORM'"
         }
         local ++k
      }
   }  
}




*************************************************************************************
*************************************************************************************


*  ************************
*
*  **** PUTDOCX TABLE  ****
*
*  ************************



*  start document


capture putdocx clear


putdocx begin, font(`font', `b_fsize') `landscape'



*  main command

local cellmargL "cellmargin(left, 0.01in)"
local cellmargR "cellmargin(right, 0.05in)"
local cellmargB "cellmargin(bottom, 0.01in)"
if "`est_se'"~="" & "`BE'"=="beside"  {
   local cellmargL "cellmargin(left, 0.02in)"
   if "`STPC'" == "ci"  {
      local cellmargL "cellmargin(left, 0.03in)"
   }
}

#d ;
putdocx table `tabname' = mat(`mat'),
   rownames colnames 
   nformat(%6.2f) 
   layout(autofitcontents)
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
*     n_colT   number of data/means/matrix columns
*     n_colTX  number of columns:  row title + data/means/matrix columns
*
*     col_DF   first data column (with extra column: row title)
*     col_DL   last data column (with extra columns: row title, stars, se)
*     col_MF   first means/matrix column (with extra column for row title)
*     col_ML   last means/matrix column (with extra column for row title) 
*     col_F    first data/means/matrix column (with extra column for row title)
*     col_L    last data/means/matrix column (with extra column for row titles)
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
qui gen VVV = .
local r = `row_F'
forvalues RR = 1/`ROWS'         {
   local c = 2
   forvalues CC = 1/`n_colT'    {
      qui replace VVV = `mat'[`RR',`CC']
      sum VVV, meanonly
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
capture drop VVV



*  column titles and data cells: horizontal right align, vertical bottom align

putdocx table `tabname'(`row_C'/`row_LS',2/`n_colTX'), halign(right) valign(bottom)



*  column titles
*  (syntax assumes three lines maximum, separated by slashes)

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
forvalues c = 1/`n_colTX'             {
   if "`ctitle`c''" ~= ""             {        
      tokenize "`ctitle`c''", parse("\")
      if "`3'" == ""                  {
         putdocx table `tabname'(`row_C',`c') = ("`1'"), font(`font', `l_fsize') 
      }
      if "`3'" ~= ""                  {
         if "`ctitleht'" ~= "triple"  {
            local ctitleht "double" 
         }
         putdocx table `tabname'(`row_C',`c') = ("`1'"), font(`font', `l_fsize') linebreak(1)
         if "`5'" == ""               {
            putdocx table `tabname'(`row_C',`c') = ("`3'"), font(`font', `l_fsize') append
         }
         if "`5'" ~= ""               {
            local ctitleht "triple" 
            putdocx table `tabname'(`row_C',`c') = ("`3'"), font(`font', `l_fsize') append linebreak(1)
            putdocx table `tabname'(`row_C',`c') = ("`5'"), font(`font', `l_fsize') append
         }
      }
      if `c'==1  {
         putdocx table `tabname'(`row_C',`c'), halign(left)
      }
      if `c'>1   {
         putdocx table `tabname'(`row_C',`c'), halign(right)
      }
   }
}



*  height of column titles row (depends on number of lines)

local htR = `bf125'
if "`ctitleht'" == "double"  {
   local htR = round(`bf250')
}
if "`ctitleht'" == "triple"  {
   local htR = round(`bf375')
}
putdocx table `tabname'(`row_C',.), height(`htR'pt, exact) valign(bottom)



*  row titles:  horizontal left align, vertical bottom align

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
      if "`rst_indent'" == "indent"     {
         local K = `k'
         forvalues k = 1/`K'            {
            forvalues j = 1/12          {
               if `"`rst`p'`j''"' ~= "" {
                  local RST ""
                  tokenize `"`rst`p'`j''"', parse(" ,")
                  while "`1'" ~= ""     {
                     if "`1'" ~= ","    {
                        local RST "`RST'`1',"
                     }
                     mac shift
                  }
                  tokenize `"`RST'"', parse(",")
                  if `k'>=`3' & `k'<=(`3'+`5')   {
                     local indent`p'`k' "yes"
                  }
               }
            }
         }
      }
   }

   local row_I = 99
   local r = 1
   forvalues R = `row_F`p''/`row_LS`p''   {
      if "`rtitle`p'`r''" ~= ""  {
         tokenize "`rtitle`p'`r''", parse("\")
         if "`3'" == ""      {
            putdocx table `tabname'(`R',1) = ("`1'"), font(`font', `l_fsize') 
            if "`indent`p'`r''" == "yes"  {
               putdocx table `tabname'(`R',1) = ("   `1'"), font(`font', `l_fsize') 
            }
            local X = strtrim("`1'")
            if "`X'"=="_cons" | "`X'"=="constant" | "`X'"=="Constant" |    ///
               "`X'"=="intercept" | "`X'"=="Intercept"          {
               local row_I = `R'
               putdocx table `tabname'(`R',.), height(`bf150'pt, exact) valign(center)
            }
         }
         if "`3'" ~= ""      {
            putdocx table `tabname'(`R',1) = ("`1'"), font(`font', `l_fsize') linebreak(1) 
            putdocx table `tabname'(`R',1) = ("`3'"), font(`font', `l_fsize') append 
            if "`indent`p'`r''" == "yes"  {
               putdocx table `tabname'(`R',1) = ("   `1'"), font(`font', `l_fsize') linebreak(1)
               putdocx table `tabname'(`R',1) = ("   `3'"), font(`font', `l_fsize') append
            }
            putdocx table `tabname'(`R',.), height(`bf182'pt, exact)
            putdocx table `tabname'(`R',1), halign(left) valign(bottom)
         }
      }
      local ++r
   }
   forvalues R = `row_F`p''/`row_LS`p''   {      //  right-align "Intercept" and beyond
      if `R' >= `row_I'  {
         putdocx table `tabname'(`R',1), halign(right)
      }
   }  
}


*  note:  row-spanning titles are below, after: insertion of columns and filling of columns
*                                        OR     insertion of rows and filling of rows



*  Guide to rows and columns  (reprise)
*
*     n_rowD   number data rows (coefficients or matrix elements):        all panels
*     n_rowS   number statistics rows (N, r-squared, BIC, etc):           all panels
*
*     n_colD   number of data columns (equations or matrix elements), excluding means/matrices
*     n_colM   number of means/matrix columns
*     n_colT   number of data/means/matrix columns
*     n_colTX  number of columns:  row title + data/means/matrix columns
*
*     col_DF   first data column (with extra column: row title)
*     col_DL   last data column (with extra columns: row title, stars, se)
*     col_MF   first means/matrix column (with extra column for row title)
*     col_ML   last means/matrix column (with extra column for row title) 
*     col_F    first data/means/matrix column (with extra column for row title)
*     col_L    last data/means/matrix column (with extra column for row titles)
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

if "`est_star'"=="" & "`BE'"~="beside"  {
   forvalues c = 1/`col_L'   {
      putdocx table `tabname'(.,`c'), width(`colwidth`c'')
   }
}



*  est_star or est_se_beside:  insert columns, set width

if "`est_star'"~="" | "`BE'"=="beside"   {
   local c = `col_DF'
   forvalues CC = 1/`n_colD'             {
      putdocx table `tabname'(.,`c'), addcols(1, after)          
      local c = `c' + 2
   }
   forvalues c = 1/`col_L'               {
      putdocx table `tabname'(.,`c'), width(`colwidth`c'') border(all,nil) 
   }
}



*  format data cells:  numeric format, row height  
*  (note:  statistics formatting corrected later)

forvalues c = 2/`col_L'         {
   putdocx table `tabname'(`row_F'/`row_LS',`c'), nformat("`nform`c''") font(`font',`b_fsize')
}
forvalues r = `row_F'/`row_LS'  {
   putdocx table `tabname'(`r',.), height(`bf121'pt, exact)
   if "`est_se'" == ""          {
      putdocx table `tabname'(`r',.), height(`bf117'pt, exact)
   }
}



*  setting the asterisks in column to right of coefficients 

if "`est_star'" ~= ""               {
   qui gen AST = .
   forvalues p = 1/`n_p'            {
      local r = `row_F`p''
      forvalues RR = 1/`n_rowD`p''  {
         local c = `col_DF' + 1
         forvalues CC = 1/`n_colD'  {
            qui replace AST = PVX`p'[`RR',`CC']
            sum AST, meanonly
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
            if "`BE'" == "below"    {
               putdocx table `tabname'(`r',`c'), halign(left) valign(bottom)
            }
            local c = `c' + 2
         }
         local ++r
      }
   }
   capture drop AST
}



*  standard errors (or t_statistic or p-value) in column to right of coefficients:  add values, format 
*  adjust vertical alignment to center (to achieve visual alignment despite different font sizes)

if ("`est_se'"~="" & "`STPC'"~="ci") & "`BE'"=="beside"   {
   qui gen STPC = .
   forvalues p = 1/`n_p'              {
      local r = `row_F`p''
      forvalues RR = 1/`n_rowD`p''    {
         local c = `col_DF' + 1
         forvalues CC = 1/`n_colD'    {
            local b = `c' - 1
            qui replace STPC = STPC`p'[`RR',`CC']
            sum STPC, meanonly
            if "`r(mean)'" ~= ""      {
               local stpc : display `stpcform`c'' `r(mean)'
               local stpc = strtrim("`stpc'")
               if "`PAREN'" == "yes"  {
                  putdocx table `tabname'(`r',`c') = ("(`stpc')"), font(`font', `se_fsize')
               }
               if "`PAREN'" == "no"   {
                  putdocx table `tabname'(`r',`c') = ("`stpc'"), font(`font', `se_fsize')
               }
               putdocx table `tabname'(`r',`c'), halign(left) valign(center)
               putdocx table `tabname'(`r',`b'), valign(center)
            }
            local c = `c' + 2
         }
         putdocx table `tabname'(`r',1), valign(center)
         local ++r
      }
   }
   capture drop STPC
}



*  confidence interval in column to right of coefficients:  add values, format 
*  adjust vertical alignment to center (to achieve visual alignment despite different font sizes)

if ("`est_se'"~="" & "`STPC'"=="ci") & "`BE'"=="beside"  {
   local n_colCI = 2*`n_colD'
   qui gen STPC_L = .
   qui gen STPC_U = .
   forvalues p = 1/`n_p'               {
      local r = `row_F`p''
      forvalues RR = 1/`n_rowD`p''     {
         local c = `col_DF' + 1
         forvalues CC = 1(2)`n_colCI'  {
            local b = `c' - 1
            local CCX = `CC' + 1
            qui replace STPC_L = STPC`p'[`RR',`CC']
            qui replace STPC_U = STPC`p'[`RR',`CCX']
            sum STPC_L, meanonly
            if "`r(mean)'" ~= ""       {
               local stpc_l : display `stpcform`c'' `r(mean)'
               local stpc_l = strtrim("`stpc_l'")
               sum STPC_U, meanonly
               local stpc_u : display `stpcform`c'' `r(mean)'
               local stpc_u = strtrim("`stpc_u'")
               if "`PAREN'" == "yes"   {
                  putdocx table `tabname'(`r',`c') = ("[`stpc_l' - `stpc_u']"),    ///
                          font(`font', `ci_fsize')
               }
               if "`PAREN'" == "no"    {
                  putdocx table `tabname'(`r',`c') = ("`stpc_l' - `stpc_u'"),      ///
                          font(`font', `ci_fsize')
               }
               putdocx table `tabname'(`r',`c'), halign(left) valign(center)
               putdocx table `tabname'(`r',`b'), valign(center)
            }
            local c = `c' + 2
         }
         putdocx table `tabname'(`r',1), valign(center)
         local ++r
      }
   }
   capture drop STPC_L STPC_U
}



*  standard errors (or t_statistic or p-value) in row below coefficients:  add rows, add values, format
*  OR
*  confidence interval in row below coefficients:  add rows, add values, format
*  (est_no cells are set to " ")

if "`BE'" == "below"        {

   forvalues p = 1/`n_p'    {
      local r = `row_F`p''
      local n_extra = 0
      forvalues R = `row_F`p''/`row_L`p''  {
         putdocx table `tabname'(`r',.), addrows(1, after) 
         putdocx table `tabname'(`r',.), height(`bf108'pt, exact)
         local rx = `r' + 1
         putdocx table `tabname'(`rx',.), height(`bf121'pt, exact)
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

      if "`STPC'" ~= "ci"    {
         qui gen STPC = .
         local r = `row_F`p'' + 1
         forvalues RR = 1/`n_rowD`p''     {
            local c = `col_DF'
            local k = cond("`ADD_SIDE'"=="left",1 + `n_colM',1)
            forvalues CC = 1/`n_colD'     {
               qui replace STPC = STPC`p'[`RR',`CC']
               sum STPC, meanonly
               if "`r(mean)'" ~= ""       {
                  local stpc : display `stpcform`c'' `r(mean)'
                  local stpc = strtrim("`stpc'")
                  if "`PAREN'" == "yes"   {
                     putdocx table `tabname'(`r',`c') = ("(`stpc')"), font(`font', `se_fsize')
                  }
                  if "`PAREN'" == "no"    {
                     putdocx table `tabname'(`r',`c') = ("`stpc'"), font(`font', `se_fsize')
                  }
                  if "`est_no'" ~= "" & "`est_no`k''"=="no"    {
                     putdocx table `tabname'(`r',`c') = (" ")
                  }
                  putdocx table `tabname'(`r',`c'), halign(right) valign(top)
               }
               if "`est_star'" == ""      {
                  local c = `c' + 1
               }
               if "`est_star'" ~= ""      {
                  local c = `c' + 2
               }
               local ++k
            }
            local r = `r' + 2
         }
         capture drop STPC
      } 

      if "`STPC'" == "ci"    {
         local n_colCI = 2*`n_colD'
         qui gen STPC_L = .
         qui gen STPC_U = .
         local r = `row_F`p'' + 1
         forvalues RR = 1/`n_rowD`p''      {
            local c = `col_DF'
            local k = cond("`ADD_SIDE'"=="left",1 + `n_colM',1)
            forvalues CC = 1(2)`n_colCI'   {
               local CCX = `CC' + 1
               qui replace STPC_L = STPC`p'[`RR',`CC']
               qui replace STPC_U = STPC`p'[`RR',`CCX']
               sum STPC_L, meanonly
               if "`r(mean)'" ~= ""        {
                  local stpc_l : display `stpcform`c'' `r(mean)'
                  local stpc_l = strtrim("`stpc_l'")
                  sum STPC_U, meanonly
                  local stpc_u : display `stpcform`c'' `r(mean)'
                  local stpc_u = strtrim("`stpc_u'")
                  if "`PAREN'" == "yes"    {
                     putdocx table `tabname'(`r',`c') = ("[`stpc_l' - `stpc_u']"),     ///
                             font(`font', `ci_fsize')
                  }
                  if "`PAREN'" == "no"     {
                     putdocx table `tabname'(`r',`c') = ("`stpc_l' - `stpc_u'"),       ///
                             font(`font', `ci_fsize')
                  }
                  if "`est_no'" ~= "" & "`est_no`k''"=="no"   {
                     putdocx table `tabname'(`r',`c') = (" ")
                  }
                  putdocx table `tabname'(`r',`c'), halign(right) valign(top)
               }
               if "`est_star'" == ""       {
                  local c = `c' + 1
               }
               if "`est_star'" ~= ""       {
                  local c = `c' + 2
               }
               local ++k
            }
            local r = `r' + 2
         }
         capture drop STPC_L STPC_U
      } 
   }
}



*  row spanning titles (maximum twelve per panel)
*  (syntax assumes three values in each rst#, separated by comma or space)
*  (assumes within-panel numbering)
*  (must occur after:  insertion of columns and filling of columns
*                  OR  insertion of rows and filling of rows)
*  
 
if `"`rst11'"' ~= "" |   `"`rst21'"' ~= "" |  `"`rst31'"' ~= "" |    ///
   `"`rst41'"' ~= "" |   `"`rst51'"' ~= ""    {

   forvalues p = 1/`n_p'              {
      local Q = `p' + 1
      local MAX = cond(`p'==1,16,12)
      forvalues r = 1/`MAX'           {
         if `"`rst`p'`r''"' ~= ""     {
            local RST ""
            local n = `r' - 1
            tokenize `"`rst`p'`r''"', parse(" ,")
            while "`1'" ~= ""         {
               if "`1'" ~= ","        {
                  local RST "`RST'`1',"
               }
               mac shift
            }
            tokenize `"`RST'"', parse(",")
            local lab_rst`r' "`1'"
            if "`BE'"~="below"  {
               local row_rst`r' = `3' + (`row_F`p'' - 1) + `n'
               local alignV "bottom"
            }
            if "`BE'"=="below"        {
               local row_rst`r' = `3' + (`3'-1) + (`row_F`p'' - 1) + `n'
               local alignV "center"
            }
            local HT "bf167"
            if `3'==1 | "`BE'"=="below"  {
               local HT "bf142"
            }
            if `3'~=1 & "`slim'"~=""     {
               local HT "bf121"
            }
            putdocx table `tabname'(`row_rst`r'',.), addrows(1, before)
            putdocx table `tabname'(`row_rst`r'',.), height(``HT''pt, exact) valign(`alignV')
            putdocx table `tabname'(`row_rst`r'',1) = ("`lab_rst`r''"),   ///
               font(`font', `l_fsize') `rst_format' halign(left)
            local row_L      = `row_L'   + 1         //  last data/coeff row
            local row_LS     = `row_LS'  + 1         //  last data/coeff/stat row
            local row_LSE    = `row_LSE' + 1         //  last data/coeff/stat/extra row
            local row_L`p'   = `row_L`p''  + 1       //  last data/coeff row, panel-specific
            local row_LS`p'  = `row_LS`p'' + 1       //  last data/coeff/stat row, panel-specific
            forvalues q = `Q'/`n_p'  {
               local row_F`q'   = `row_F`q''  + 1    //  first data/coeff row, subsequent panels
               local row_L`q'   = `row_L`q''  + 1    //  last data/coeff row, subsequent panels 
               local row_LS`q'  = `row_LS`q'' + 1    //  last data/coeff/stat row, subsequent panels
            }
         }
      }
   }

}



*  linespaces:  add line between  (i)  first and next row ("firstX")
*                                 (ii) last and previous row ("lastX")

if "`slim'" == ""             {
   if "`firstX'" ~= ""        {
      forvalues p = 1/`n_p'   {
         putdocx table `tabname'(`row_F`p'',.), addrows(1, after)
         local row_F_1 = `row_F`p'' + 1           //  after first row:  additional row
         putdocx table `tabname'(`row_F_1',.), height(`bf025'pt, exact)
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
         putdocx table `tabname'(`row_L`p'',.), addrows(1, before)
         putdocx table `tabname'(`row_L`p'',.), height(`bf025'pt, exact)
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
*     n_colT   number of data/means/matrix columns
*     n_colTX  number of columns:  row title + data/means/matrix columns
*
*     col_DF   first data column (with extra column: row title)
*     col_DL   last data column (with extra columns: row title, stars, se)
*     col_MF   first means/matrix column (with extra column for row title)
*     col_ML   last means/matrix column (with extra column for row title) 
*     col_F    first data/means/matrix column (with extra column for row title)
*     col_L    last data/means/matrix column (with extra column for row titles)
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
            putdocx table `tabname'(`row_FS`p'',.), height(`bf044'pt, exact)
            if "`BE'" == "below"  {
               putdocx table `tabname'(`row_FS`p'',.), height(`bf050'pt, exact)
            }
         }
         if "`lastX'"~="" | ("`extra_place'"~="" & ("`extra1'"~="" | "`extra`p'1'"~=""))  {
            putdocx table `tabname'(`row_FS`p'',.), height(`bf050'pt, exact)
            if "`BE'" == "below"  {
               putdocx table `tabname'(`row_FS`p'',.), height(`bf058'pt, exact)
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



*  if there are extra information rows
*  one set below all panels and multiple panels
*  linespace:  add one after last data/stat row (unless slim requested) 

if "`extra1'"~="" & `n_p'>1        {
   local n_extra = 0
   local max_col = 0
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
         local max_col = `k'
      } 
   }
   if `max_col' > `n_colTX'        {
      di _n(1) _col(3) in y  "ERROR:  too many elements in one or more extra rows"   _n(1) " "
      exit
   }
   if "`slim'" == ""               {
      putdocx table `tabname'(`row_LS',.), addrows(1, after)
      local row_LS_1  = `row_LS' + 1
      if "`est_stat1'"~="" & "`extra_place'"==""  {
         putdocx table `tabname'(`row_LS_1',.), height(`bf067'pt, exact)  
      }
      if "`est_stat1'"=="" | "`extra_place'"~=""  {
         putdocx table `tabname'(`row_LS_1',.), height(`bf058'pt, exact)  
      }
      local row_LSE = `row_LSE' + 1
   }
   if "`slim'" ~= ""               {
      local row_LS_1 = `row_LS'
   }      
   putdocx table `tabname'(`row_LS_1',.), addrows(`n_extra', after)
   forvalues r = 1/`n_extra'  {
      local R = `row_LS_1' + `r'
      if "`est_star'"=="" & "`BE'"~="beside"         {
         forvalues c = 1/`max_col'                   {
            local C = `c'
            if "`ex`r'_`c''"~=""                     {
               putdocx table `tabname'(`R',`C') = ("`ex`r'_`c''"), font(`font', `ex_fsize')  
            }
            if "`ex`r'_`c''" == " "                  {
               putdocx table `tabname'(`R',`C') = (" "), font(`font', `ex_fsize')  
            }
            putdocx table `tabname'(`R',`C'), halign(right) 
         }
      }
      if "`est_star'"~="" | "`BE'"=="beside"         {
         local k = 1
         local m = 1
         forvalues c = 1/`max_col'                   {
            if `c' <= `col_DF'                       {
               local C = `c'
               if "`ex`r'_`c''"~=""                  {
                  putdocx table `tabname'(`R',`C') = ("`ex`r'_`c''"), font(`font', `ex_fsize')  
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
   }
   local row_LSE  = `row_LSE'  + `n_extra'     //  last data/coeff/stat/extra row 
}  



*  if there are extra information rows
*  one set per panel

if ("`extra1'"~="" & `n_p'==1) |                            ///
   ("`extra11'"~="" | "`extra21'"~="" | "`extra31'"~="" |   ///
   "`extra41'"~="" | "`extra51'"~="")     {
   if "`extra1'"~="" & `n_p'==1           {
      forvalues x = 1/9                   {
         local extra1`x' = "`extra`x''"
      }
   }
   forvalues p = 1/`n_p'                  {
      if "`extra`p'1'" ~= ""              {
         local n_extra = 0
         local max_col = 0
         forvalues x = 1/9  {
            if "`extra`p'`x''" ~= ""      {
               local ++n_extra
               tokenize "`extra`p'`x''", parse("!")
               local k  = 0
               local EX = 0
               while "`1'" ~= ""    {
                  if "`1'" == "!"   {
                     if `k' == 0   { 
                        local ++k
                        local ex`p'`x'_`k' " "
                     }
                     local EX = `EX' + 1
                     if `EX' >= 2   {
                        local ++k
                        local ex`p'`x'_`k' " "
                     }
                  }
                  if "`1'" ~= "!"   {
                     local EX = 0
                     local ++k
                     local ex`p'`x'_`k' "`1'"
                  }
                  mac shift
               }
               local max_col = `k'
            } 
         }
         if `max_col' > `n_colTX'        {
            di _n(1) _col(3) in y  "ERROR:  too many elements in one or more extra rows"   _n(1) " "
            exit
         }
         local ZZZ = cond("`extra_place'"=="","LS","L")
         local row_ZZZ_1 = cond("`slim'"=="",`row_`ZZZ'`p''+1,`row_`ZZZ'`p'')
         if "`slim'" == ""   {
            putdocx table `tabname'(`row_`ZZZ'`p'',.), addrows(1, after)
            putdocx table `tabname'(`row_ZZZ_1',.), height(`bf050'pt, exact)
         }
         putdocx table `tabname'(`row_ZZZ_1',.), addrows(`n_extra', after)
         forvalues r = 1/`n_extra'   {
            local R = `row_ZZZ_1' + `r'
            if "`est_star'"=="" & "`BE'"~="beside"      {
               forvalues c = 1/`max_col'                {
                  local C = `c'
                  if "`ex`p'`r'_`c''"~=""               {
                     putdocx table `tabname'(`R',`C') = ("`ex`p'`r'_`c''"), font(`font', `ex_fsize')  
                  }
                  if "`ex`p'`r'_`c''" == " "            {
                     putdocx table `tabname'(`R',`C') = (" "), font(`font', `ex_fsize')  
                  }
                  putdocx table `tabname'(`R',`C'), halign(right)
               }
            }
            if "`est_star'"~="" | "`BE'"=="beside"      {
               local k = 1
               local m = 1
               forvalues c = 1/`max_col'                {
                  if `c' <= `col_DF'                    {
                     local C = `c'
                     if "`ex`p'`r'_`c''"~=""            {
                        putdocx table `tabname'(`R',`C') = ("`ex`p'`r'_`c''"), font(`font', `ex_fsize')  
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



*  linespace:  add one between last data/coeff/stat/extra row and bottom line
*  horizontal line:  below last data/coeff/stat/extra
*  linespace:  add one between bottom line and notes, if there are notes

if "`slim'" ~= ""      {
   putdocx table `tabname'(`row_LSE',.), border(bottom, `lineB')
}

if "`slim'" == ""      {
   putdocx table `tabname'(`row_LSE',.), addrows(1, after)        //  after last data/coeff/stat/extra row:  add row
   local row_LSE = `row_LSE' + 1 
   putdocx table `tabname'(`row_LSE',.), height(`bf044'pt, exact) border(bottom, `lineB')
   if ("`est_stat1'"~="")  |          ///
      ("`extra1'"~="")     |          ///
      ("`extra11'"~="" | "`extra21'"~="" | "`extra31'"~="" | "`extra41'"~="" | "`extra51'"~="")   {
      putdocx table `tabname'(`row_LSE',.), height(`bf050'pt, exact) border(bottom, `lineB')
   }
   if "`note1'" ~= ""  {
      putdocx table `tabname'(`row_LSE',.), addrows(1, after)          //  after bottom line:  add row if there are notes
      local row_LSE = `row_LSE' + 1  
      putdocx table `tabname'(`row_LSE',.), height(`bf092'pt, exact)   //  row before notes
   }
}



****************************************************************************************
****************************************************************************************


*  *************************************
*
*  ****  FINISHING TOUCHES, I  ****
*
*        column deletion
*
*  *************************************


*  Guide to rows and columns  (reprise)
*
*     n_rowD   number data rows (coefficients or matrix elements):        all panels
*     n_rowS   number statistics rows (N, r-squared, BIC, etc):           all panels
*
*     n_colD   number of data columns (equations or matrix elements), excluding means/matrices
*     n_colM   number of means/matrix columns
*     n_colT   number of data/means/matrix columns
*     n_colTX  number of columns:  row title + data/means/matrix columns
*
*     col_DF   first data column (with extra column: row title)
*     col_DL   last data column (with extra columns: row title, stars, se)
*     col_MF   first means/matrix column (with extra column for row title)
*     col_ML   last means/matrix column (with extra column for row title) 
*     col_F    first data/means/matrix column (with extra column for row title)
*     col_L    last data/means/matrix column (with extra column for row titles)
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
*  begin by defining starting and ending columns, prior to column deletion
*  est_no is specified in terms of data matrix, but deletion must take account of row-title column

if "`est_star'"=="" & "`BE'"~="beside"     {
   local k = 1
   if `n_colM'>0  &  "`ADD_SIDE'"=="left"  {
      forvalues c = `col_MF'/`col_ML'      {
         local start`k' = `c'
         local end`k' = `c'
         local ++k
      }
   }
   forvalues c = `col_DF'/`col_DL'         {
      local start`k' = `c'
      local end`k' = `c'
      local ++k
   }
   if `n_colM'>0  &  "`ADD_SIDE'"=="right" {
      forvalues c = `col_MF'/`col_ML'      {
         local start`k' = `c'
         local end`k' = `c'
         local ++k
      }
   }
}

if "`est_star'"~="" | "`BE'"=="beside"     {
   local k = 1
   if `n_colM'>0  &  "`ADD_SIDE'"=="left"  {
      forvalues c = `col_MF'/`col_ML'      {
         local start`k' = `c'
         local end`k' = `c'
         local ++k
      }
   }
   forvalues c = `col_DF'(2)`col_DL'       {
      local firstD = `k'
      local start`k' = `c'
      local end`k' = `c' + 1
      local ++k
   }
   local lastD = `k' - 1
   if `n_colM'>0  &  "`ADD_SIDE'"=="right" {
      forvalues c = `col_MF'/`col_ML'      {
         local start`k' = `c'
         local end`k' = `c'
         local ++k
      }
   }
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




*  *************************************
*
*  ****  FINISHING TOUCHES, II  ****
*
*        panel titles
*
*  *************************************


*  panel titles:  insert row
*                 add title

forvalues p = 1/`n_p'   {
   if `p' == 1  {
      if "`pt1'" ~= ""  {
         putdocx table `tabname'(`row_F`p'',.), addrows(1,before)
         putdocx table `tabname'(`row_F`p'',1), colspan(`col_L')
         putdocx table `tabname'(`row_F`p'',.), height(`bf167'pt, exact)
         putdocx table `tabname'(`row_F`p'',1) = ("`pt`p''"),       ///
            font(`font', `l_fsize') `pt_format'  halign(left) valign(center)    
         local row_F   = `row_F'  + 1                //  first data/coeff row
         local row_L   = `row_L'  + 1                //  last data/coeff row
         local row_LS  = `row_LS' + 1                //  last data/coeff/stat row
         local row_LSE = `row_LSE' + 1               //  last data/coeff/stat/extra row
         forvalues PP = `p'/`n_p'   {
            local row_F`PP'   = `row_F`PP''   + 1    //  first data/coeff row:           panel-specific
            local row_L`PP'   = `row_L`PP''   + 1    //  last data/coeff row:            panel-specific
            local row_LS`PP'  = `row_LS`PP''  + 1    //  last data/coeff/stat row:       panel-specific
         }
      }
   }
   local HT1 "bf058"            //  HT1:  height of row immediately before beginning of panel
   local HT2 "bf033"            //  HT2:  height of pline row (line is top border), prior to panel
   if `p' > 1                      {
      local q = `p' - 1
      if "`pline'" == ""           {
         if "`pt`p''"==""          {
            local HT1 = cond("`lastX'"~="","bf092","bf075")
            if "`est_stat'"~="" | "`est_stat`q''"~="" | "`extra`q'1'"~=""    {
               local HT1 "bf083"
            }
            if "`BE'"=="below"     {
               local HT1 "bf067"
            }
         }
         if "`pt`p''"~=""               {
            local HT1 "bf050"
            if "`est_stat'"~="" | "`est_stat`q''"~="" | "`extra`q'1'"~=""    {
               if `"`rst`p'1'"'==""     {
                  local HT1 "bf067"
                  if "`BE'"=="below"    {
                     local HT1 "bf058"
                  }
               }
               if `"`rst`p'1'"'~=""     {
                  local HT1 "bf075"
                  if "`BE'"=="below"    {
                     local HT1 "bf067"
                  }
               }
            }
            if ("`est_stat'"~="" | "`est_stat`q''"~="") & ("`extra`q'1'"~="")   {
               if `"`rst`p'1'"'==""     {
                  local HT1 "bf075"
                  if "`BE'"=="below"    {
                     local HT1 "bf067"
                  }
               }
               if `"`rst`p'1'"'~=""     {
                  local HT1 "bf083"
                  if "`BE'"=="below"    {
                     local HT1 "bf075"
                  }
               }
            }
            if "`est_stat'"=="" & "`est_stat`q''"=="" & "`extra`q'1'"=="" & "`lastX'"~=""  {
               local HT1 "bf058"
            }
         }
      }
      if "`pline'" ~= ""           {
         if "`pt`p''"==""          {
            local HT1 "bf092"
            local HT2 "bf058"
            if "`est_stat'"~="" | "`est_stat`q''"~="" | "`extra`q'1'"~=""    {
               local HT1 "bf100"
            }
            if "`BE'"=="below"     {
               local HT1 "bf083"
            }
         }
         if "`pt`p''"~=""              {
            local HT1 "bf075"
            local HT2 "bf050"
            if "`est_stat'"~="" | "`est_stat`q''"~="" | "`extra`q'1'"~=""     {
               if `"`rst`p'1'"'==""    {
                  local HT1 "bf083"
                  if "`BE'"=="below"   {
                     local HT1 "bf075"
                  }
               }
               if `"`rst`p'1'"'~=""    {
                  local HT1 "bf092"
                  if "`BE'"=="below"   {
                     local HT1 "bf083"
                  }
               }
            }
            if ("`est_stat'"~="" | "`est_stat`q''"~="") & ("`extra`q'1'"~="")   {
               if `"`rst`p'1'"'==""    {
                  local HT1 "bf092"
                  if "`BE'"=="below"   {
                     local HT1 "bf083"
                  }
               }
               if `"`rst`p'1'"'~=""    {
                  local HT1 "bf100"
                  if "`BE'"=="below"   {
                     local HT1 "bf092"
                  }
               }
            }
         }
      }
      local X = 1
      if "`slim'" == ""      {
         if "`pline'" ~= ""  {
            putdocx table `tabname'(`row_F`p'',.), addrows(1,before) height(``HT2''pt, exact)
            putdocx table `tabname'(`row_F`p'',.), border(top,,,0.25pt)
            local X = 2
         }
         putdocx table `tabname'(`row_F`p'',.), addrows(1,before) border(top, nil)
         putdocx table `tabname'(`row_F`p'',.), height(``HT1''pt, exact)
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
         putdocx table `tabname'(`row_F`p'',.), height(`bf167'pt, exact)
         putdocx table `tabname'(`row_F`p'',1) = ("`pt`p''"),          ///
            font(`font', `l_fsize')  `pt_format'  halign(left)  valign(center)  
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



*  *************************************
*
*  ****  FINISHING TOUCHES, III  ****
*
*        notes
*        column-spanning titles
*        title and subtitle
*
*  *************************************


*  Guide to rows and columns  (reprise)
*
*     n_rowD   number data rows (coefficients or matrix elements):        all panels
*     n_rowS   number statistics rows (N, r-squared, BIC, etc):           all panels
*
*     n_colD   number of data columns (equations or matrix elements), excluding means/matrices
*     n_colM   number of means/matrix columns
*     n_colT   number of data/means/matrix columns
*     n_colTX  number of columns:  row title + data/means/matrix columns
*
*     col_DF   first data column (with extra column: row title)
*     col_DL   last data column (with extra columns: row title, stars, se)
*     col_MF   first means/matrix column (with extra column for row title)
*     col_ML   last means/matrix column (with extra column for row title) 
*     col_F    first data/means/matrix column (with extra column for row title)
*     col_L    last data/means/matrix column (with extra column for row titles)
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
            if "`note`n''"~=" "  &  ("`note`k''"~=""  &  "`note`k''"~=" ")  {
               putdocx table `tabname'(`row_N',.), addrows(1,after)
               local row_N = `row_N' + 1
               putdocx table `tabname'(`row_N',.), height(1pt, exact) 
            }
            if ("`note`n''"=="" | "`note`n''"==" ") & ("`note`k''"~="" | "`note`k''"~=" ")  {
               putdocx table `tabname'(`row_N',.), height(`HT2'pt, exact)
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



*  column spanning titles:  add row for spanning titles
*
*  horizontal line:  on top of spanning titles row
*  


*  second-level column spanning titles

if `"`cst11'"' ~= ""    {

   if `"`cst1'"' == ""  {
      di _n(2) _col(3) in y  "ERROR:  cannot have cst1# without cst# - higher-level presumes lower-level"   _n(1) " "
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
  
   local cstitleht "single"
   forvalues s = 5(-1)1        {
      if `"`cst1`s''"' ~= ""   {
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
         if "`3'" == ""  { 
            putdocx table `tabname'(`row_SP',`start`cststart''), colspan(`cstwidth') 
            putdocx table `tabname'(`row_SP',`start`cststart'') = ("`1'"),       ///
               font(`font', `l_fsize') `cst_format'  halign(center) valign(bottom)  
         }
         if "`3'" ~= ""  {
            local cstitleht "double" 
            putdocx table `tabname'(`row_SP',`start`cststart''), colspan(`cstwidth') 
            if "`cst_format'" == "bold"  {
               putdocx table `tabname'(`row_SP',`start`cststart'') = ("`1'"),    ///
                  font(`font', `l_fsize') `cst_format'  halign(center) valign(bottom) append linebreak(1)  
            }
            if "`cst_format'" ~= "bold"  {
               putdocx table `tabname'(`row_SP',`start`cststart'') = ("`1'"),    ///
                  font(`font', `l_fsize') halign(center) valign(bottom) append linebreak(1)  
            }
            putdocx table `tabname'(`row_SP',`start`cststart'') = ("`3'"),       ///
               font(`font', `l_fsize') `cst_format'  halign(center) valign(bottom) append 
         }
      }
   }
   local htR = `bf150'
   if "`cstitleht'" == "double"  {
      local htR = `bf250'
   }
   putdocx table `tabname'(`row_SP',.), height(`htR'pt, exact) border(top, `lineT') 

}


*  first-level column spanning titles

if `"`cst1'"' ~= ""  {

   putdocx table `tabname'(`row_C',.), addrows(1, before)
   local row_SP = `row_C'
   local row_C  = `row_C'  + 1      //  column title row
         

*  first-level column spanning titles (maximum ten)
*
*  relies on starting and ending columns, calculated above
*  (syntax assumes three values in each cst#, separated by comma or space)
*  (syntax allows for two lines maximum per piece of text, separated by slashes)
  
   local cstitleht "single"
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
         if "`3'" == ""  { 
            putdocx table `tabname'(`row_SP',`start`cststart''), colspan(`cstwidth') 
            putdocx table `tabname'(`row_SP',`start`cststart'') = ("`1'"),       ///
               font(`font', `l_fsize') `cst_format'  halign(center) valign(bottom)  
         }
         if "`3'" ~= ""      {
            local cstitleht "double" 
            putdocx table `tabname'(`row_SP',`start`cststart''), colspan(`cstwidth') 
            if "`cst_format'" == "bold"  {
               putdocx table `tabname'(`row_SP',`start`cststart'') = ("`1'"),    ///
                  font(`font', `l_fsize') `cst_format'  halign(center) valign(bottom) append linebreak(1)  
            }
            if "`cst_format'" ~= "bold"  {
               putdocx table `tabname'(`row_SP',`start`cststart'') = ("`1'"),    ///
                  font(`font', `l_fsize') halign(center) valign(bottom) append linebreak(1)  
            }
            putdocx table `tabname'(`row_SP',`start`cststart'') = ("`3'"),       ///
               font(`font', `l_fsize') `cst_format'  halign(center) valign(bottom) append 
         }
      }
   }
   local htR = `bf150'
   if "`cstitleht'" == "double"  {
      local htR = `bf250'
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
   putdocx table `tabname'(`row_C_2',.), height(`bf050'pt, exact)
   if "`pt1'" ~= ""   {
      putdocx table `tabname'(`row_C_2',.), height(`bf044'pt, exact)
   }
}
if "`slim'" ~= ""     {
   putdocx table `tabname'(`row_C',.), border(bottom)
}



*  title and subtitle (including linespace after)

if "`title'" ~= ""           {
   putdocx table `tabname'(1,.), addrows(1,before)
   putdocx table `tabname'(1,1), colspan(`col_L')
   putdocx table `tabname'(1,1) = ("`title'"), font(`font', `t_fsize')   
   putdocx table `tabname'(1,1), halign(center) valign(center) 
   if "`slim'" == ""         {
      if "`subtitle'" == ""  {
         putdocx table `tabname'(1,.), addrows(1, after)
         putdocx table `tabname'(2,.), height(`bf092'pt, exact) 
      }
   }
   if "`subtitle'" ~= ""     {
      putdocx table `tabname'(1,.), addrows(1, after)
      putdocx table `tabname'(2,1), colspan(`col_L')
      putdocx table `tabname'(2,1) = ("`subtitle'"), font(`font', `s_fsize')  
      putdocx table `tabname'(2,1), halign(center) valign(center)
      if "`slim'" == ""      {
         putdocx table `tabname'(2,.), addrows(1, after) 
         putdocx table `tabname'(3,.), height(`bf092'pt, exact) 
      }
   }
}




****************************************************************************************
****************************************************************************************


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

capture matrix drop C
capture matrix drop CZ
capture matrix drop CM
capture matrix drop CZM
capture matrix drop SE
capture matrix drop TV
capture matrix drop PV
capture matrix drop PVX
capture matrix drop CI
capture matrix drop STPC
forvalues p = 1/`n_pt'   {
   capture matrix drop MEANS`p'
   capture matrix drop MAT`p'
   capture matrix drop M`p'
   capture matrix drop C`p'
   capture matrix drop CZ`p'
   capture matrix drop CM`p'
   capture matrix drop CZM`p'
   capture matrix drop SE`p'
   capture matrix drop TV`p'
   capture matrix drop PV`p'
   capture matrix drop PVX`p'
   capture matrix drop CI`p'
   capture matrix drop STPC`p'
}
capture matrix drop XxYyZz



}       //  end quietly



end
