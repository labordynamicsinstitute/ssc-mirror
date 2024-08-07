*! version 16.5   3.8.24   John Casterline
capture program drop matstat
program define matstat, rclass
version 16

set adosize 60

#d ;

syntax [varlist] [if] [fw aw] ,
       stats(string) mat(string)
       [ by(varlist)  missing
         dist(string)
         layout(string)
         total(string)  xpose  
         tabshow(string)
         outfile(string) ]; 

#d cr

capture matrix drop `mat'

tempname M1 M2 
tempname M11 M12 M13 M13t

local BY " "
if "`by'" ~= ""  {
   local BY "by(`by')"
   qui levelsof `by' `if', local(CATS)
   local n_cat = `r(r)'
   if "`missing'" ~= ""  {
      local n_cat = `n_cat' + 1
   }
   local VALLAB : value label `by'
   local i = 1
   foreach c of local CATS     {
      local BYNAME`i' : label `VALLAB' `c'
      local ++i
   }
   if "`missing'" ~= ""        {
      local BYNAME`n_cat' "missing"
   }

}

if "`layout'" == ""  {
   local layout "horizontal1"
}
if "`layout'"~="" & "`layout'"~="horizontal1" & "`layout'"~="horizontal2" &"`layout'"~="vertical" {
   noi di _n(2) in y "ERROR:  incorrect layout"
   exit
}

local FORMAT " "
if "`tabshow'" ~= ""   {
   local FORMAT "format(`tabshow')"
}

tempvar touse
mark `touse' `if' `in' [`weight'`exp']

tokenize `varlist'
local k = 1
while "`1'" ~= ""  {
   local VAR`k' "`1'"
   local ++k
   macro shift
}
local n_var = `k' - 1

local STATS " "
local n_stat = 0
tokenize `stats', parse(" ,")
while "`1'" ~= ""   {
   if "`1'" ~= ","  {
      local STATS "`STATS' `1'"
      local ++n_stat
      local stat`n_stat' "`1'"
   }
   macro shift
}

local nototal = cond("`total'"=="no","nototal","")
local total_place = cond("`total'"=="top","top","bottom")

local LOUD = cond("`tabshow'"~="","noi","qui")


if "`dist'" ~= ""             {

   if "`layout'"=="vertical"  {
      noi di _n(2) in y "ERROR:  dist not available with vertical layout"
      exit
   }
   if `n_var'>1 & `n_stat'>1 & "`layout'"~="horizontal1"  {
      noi di _n(2) in y "ERROR:  with 2+ variables and 2+ stats, layout must be horizontal1"
      exit
   }

   `LOUD' di " "
   `LOUD' tab `by' [`weight'`exp'], matcell(`M11') `missing'

   local N_TOTAL = `r(N)'
   matrix `M12' = 100*(`M11'/`N_TOTAL')
   if "`nototal'" ~= ""              {
      matrix `M13' = `M12'
   }
   if "`nototal'" == ""              {
      local rows : rowsof `M12'
      local rowsX = `rows' + 1
      matrix `M13' = J(`rowsX',1,.)
      if "`total_place'"=="bottom"   {
         matrix `M13'[1,1] = `M12'
         matrix `M13'[`rowsX',1] = 100.00
      }
      if "`total_place'"=="top"      {
         matrix `M13'[2,1] = `M12'
         matrix `M13'[1,1] = 100.00
      }
   }
   local ROW_LAB " "
   forvalues i = 1/`n_cat'        {
      local ROW_LAB `" `ROW_LAB' `"`BYNAME`i''"' "'
   }
   if "`nototal'" == ""              {
      if "`total_place'" == "bottom" {
         local ROW_LAB `" `ROW_LAB' `"Total"' "'
      }
      if "`total_place'" == "top"     {
         local ROW_LAB `" `"Total"' `ROW_LAB' "'
      }
   }

   matrix rownames `M13' = `ROW_LAB'
   matrix colnames `M13' = "dist"

}


`LOUD' di " "
`LOUD' tabstat `varlist' if `touse' [`weight'`exp'],      ///
    stat(`STATS') `BY' `missing' `nototal' `FORMAT' save




************************
*
*  ***  SINGLE STAT  ***
*
************************


if "`by'"~="" & `n_stat'==1   {

   local i = 1
   forvalues i = 1/`n_cat'    {
      if `i'== 1  {
         matrix `M1' = r(Stat`i')
         local rowname "`"`BYNAME`i''"'"
      }
      else   {
         matrix `M1' = `M1' \ r(Stat`i')
         local rowname "`rowname' `"`BYNAME`i''"'"
      }
   }

   if "`nototal'" == ""               {
      if "`total_place'" == "bottom"  {
         matrix `mat' = `M1' \ r(StatTotal)
      }
      if "`total_place'" == "top"     {
         matrix `mat' = r(StatTotal) \ `M1'
      }
      local rowname = cond("`total_place'"=="bottom",`"`rowname' Total"',`"Total `rowname'"')
   }

   if "`nototal'" ~= ""     {
      matrix `mat' = `M1' 
      local rowname `"`rowname'"'
   }

   matrix rownames `mat' = `rowname'

   if "`dist'" ~= ""        {
      if "`dist'"=="first"  {
         matrix `mat' = `M13',`mat'
      }
      if "`dist'"=="last"   {
         matrix `mat' = `mat',`M13'
      }
   }

}




***************************
*
*  ***  MULTIPLE STATS  ***
*
***************************


*  VERTICAL


if "`by'"~=""  &  `n_stat'>1  &  "`layout'"=="vertical"   {

   forvalues i = 1/`n_cat'    {
      if `i'== 1  {
         matrix `M1' = r(Stat`i')
         local rowname1 `"`BYNAME`i''"'
      }
      else   {
         matrix `M1' = `M1' \ r(Stat`i')
         local rowname`i' `"`BYNAME`i''"'
      }
   }
   local n_by = `i' - 1
   if "`nototal'" == ""               {
      if "`total_place'" == "bottom"  {
         matrix `mat' = `M1' \ r(StatTotal)
      }
      if "`total_place'" == "top"     {
         matrix `mat' = r(StatTotal) \ `M1'
      }
   }
   if "`nototal'" ~= ""  {
      matrix `mat' = `M1' 
   }
   
   local statlenmax = 0
   forvalues s = 1/`n_stat'  {
      local statlen = strlen("`stat`s''")
      local statlemax = cond(`statlen'>`statlenmax',`statlen',`statlenmax')
   }
   forvalues i = 1/`n_cat'         {
      local lablen = `statlenmax' + 1 + (strlen("`rowname`i''"))
      if `lablen' > 32             {
         local labtrunc = (strlen("`rowname`i''")) - (`lablen' - 32)
         local rowname`i' = abbrev("`rowname`i''",`labtrunc')
      }
   }
   local ROW_LAB " "
   forvalues i = 1/`n_cat'            {
      forvalues s = 1/`n_stat'        {
         local ROW_LAB `"`ROW_LAB' `"`rowname`i'', `stat`s''"'"'
      }
   }
   if "`nototal'" == ""               {
      if "`total_place'" == "bottom"  {
         forvalues s = 1/`n_stat'     {
            local ROW_LAB `" `ROW_LAB' `"Total, `stat`s''"' "'
         }
      }
      if "`total_place'" == "top"     {
         forvalues s = `n_stat'(-1)1  {
            local ROW_LAB `" `"Total, `stat`s''"' `ROW_LAB' "'
         }
      }
   }

   matrix rownames `mat' = `ROW_LAB'

}



*  HORIZONTAL


if "`by'"~=""  &  `n_stat'>1  &  ("`layout'"=="horizontal1" | "`layout'"=="horizontal2") {

   local n_catX = `n_cat' + 1

   forvalues i = 1/`n_cat'              {
      matrix VV = r(Stat`i')
      local byname`i' `"`BYNAME`i''"'
      forvalues v = 1/`n_var'           {
         matrix VV_`i'_`v' = VV[1...,`v']
         matrix V_`i'_`v'  = VV_`i'_`v''
      }
      matrix V_`i' = V_`i'_1
      forvalues v = 2/`n_var'           {
         matrix V_`i' = V_`i',V_`i'_`v'
      }
   }

   if "`nototal'" == ""                 {
      local i = `n_catX'
      matrix VV = r(StatTotal)
      forvalues v = 1/`n_var'           {
         matrix VV_`i'_`v' = VV[1...,`v']
         matrix V_`i'_`v'  = VV_`i'_`v''
      }
      matrix V_`i' = V_`i'_1
      forvalues v = 2/`n_var'           {
         matrix V_`i' = V_`i',V_`i'_`v'
      }
      if "`total_place'" == "bottom"    {   
         matrix `mat' = V_1
         forvalues i = 2/`n_catX'       {
            matrix `mat' = `mat'\V_`i'
         }
      }
      if "`total_place'" == "top"       { 
         matrix `mat' = V_`n_catX'
         forvalues i = 1/`n_cat'        {
            matrix `mat' = `mat'\V_`i'
         }
      }
   }

   if "`nototal'" ~= ""                 {
      matrix `mat' = V_1
      forvalues i = 2/`n_cat'           {
         matrix `mat' = `mat'\V_`i'
      }
   }

   local ROW_LAB " "
   forvalues b = 1/`n_cat'           {
      local ROW_LAB `" `ROW_LAB' `"`byname`b''"' "'
   }
   if "`nototal'" == ""              {
      if "`total_place'" == "bottom" {
         local ROW_LAB `" `ROW_LAB' `"Total"' "'
      }
      if "`total_place'" == "top"     {
         local ROW_LAB `" `"Total"' `ROW_LAB' "'
      }
   }
   local COL_LAB " "
   forvalues v = 1/`n_var'            {
      forvalues s = 1/`n_stat'        {
         local COL_LAB `"`COL_LAB' `"`VAR`v'', `stat`s''"' "' 
      }
   }      

   matrix rownames `mat' = `ROW_LAB'
   matrix colnames `mat' = `COL_LAB'

   if "`dist'"~="" & "`layout'"~="horizontal2"  {
      if "`dist'" == "first"       {
         matrix `mat' = `M13',`mat'
      }
      if "`dist'" == "last"        {
         matrix `mat' = `mat',`M13'
      }
   }    

   capture matrix drop VV
   forvalues i = 1/`n_catX'        {
      capture matrix drop V_`i'
      forvalues v = 1/`n_var'      {
         capture matrix drop VV_`i'_`v'
         capture matrix drop V_`i'_`v'
      }
   }

   if "`layout'" == "horizontal2"        {
      matrix `M2' = `mat''
      local start = 1
      local end = `n_stat'
      forvalues v = 1/`n_var'            {
         matrix `M2'`v' = `M2'[`start'..`end',1...]
         local start = `start' + `n_stat'
         local end   = `end'   + `n_stat'
      }
      matrix `mat' = `M2'1
      forvalues v = 2/`n_var'            {
         matrix `mat' = `mat',`M2'`v'
      }
      local ROW_LAB " "
      forvalues s = 1/`n_stat'        {
         local ROW_LAB "`ROW_LAB' `stat`s''"
      }
      local varlenmax = 0
      forvalues v = 1/`n_var'  {
         local varlen = strlen("`VAR`v''")
         local varlenmax = cond(`varlen'>`varlenmax',`varlen',`varlenmax')
      }
      forvalues i = 1/`n_cat'         {
         local lablen = `varlenmax' + 1 + (strlen("`byname`i''"))
         if `lablen' > 32             {
            local labtrunc = (strlen("`byname`i''")) - (`lablen' - 32)
            local byname`i' = abbrev("`byname`i''",`labtrunc')
         }
      }
      local COL_LAB " "
      forvalues v = 1/`n_var'               {
         if "`nototal'" == ""               {
            if "`total_place'" == "top"     {
              local COL_LAB `" `COL_LAB' "`VAR`v'',Total" "'
            }
         }
         forvalues i = 1/`n_cat'            {
            local COL_LAB `" `COL_LAB' "`VAR`v'',`byname`i''" "' 
         }
         if "`nototal'" == ""               {
            if "`total_place'" == "bottom"  {
              local COL_LAB `" `COL_LAB' "`VAR`v'',Total" "'
            }
         }
      }  
      matrix rownames `mat' = `ROW_LAB'
      matrix colnames `mat' = `COL_LAB'

      if "`dist'" ~= ""               {
         matrix `M13t' = `M13''
         if "`dist'" == "first"       {
            matrix `mat' = `M13t' \ `mat'
         }
         if "`dist'" == "last"        {
            matrix `mat' = `mat' \ `M13t'
         }
      }    

      forvalues v = 1/`n_var'  {
         capture matrix drop `M2'`v'
      }
   }

}




**********************
*
*  ***  NO BY !?!  ***
*
**********************


if "`by'" == ""  {

   matrix `mat' = r(StatTotal)

}




**********************
*
*  ***  TRANSPOSE  ***
*
**********************


if "`xpose'" ~= ""  {
   matrix `mat' = `mat''
}




*******************************
*
*  ***  WRITING OUT MATRIX  ***
*
*******************************


if "`outfile'" ~= ""  {

   capture putexcel clear
   qui putexcel set `outfile', replace
   qui putexcel A1 = matrix(`mat'), names
   qui putexcel save
   noi di _n(1) " "
   noi di in g "File written out:" in y _col(20) "`outfile'"
   noi di _n(1) " "

}



end
  