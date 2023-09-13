*! version 2.0  6Aug2004  Joseph Hilbe
* CENSORED POISSON REGRESSION - WITH SURVEY CAPABILITIES
program svycepois
    version 8.0
    
    syntax [varlist] [aweight fweight pweight] [if] [in] /*
 */ [, Level(integer $S_level) OFFset(string) svy noLOg /* 
 */ Exposure(string) ITerate CENsor(string) CLuster(varname) Robust * ]

    mlopts mlopts rest, `options'

    if "`offset'" != "" {
       local ovar "'offset'"
    }
    else  local ovar  0

    if "`exposure'" != ""  {
      tempvar offset
      qui gen double `offset' = ln(`exposure')
      local ovar "ln(`exposure')"
    }

   global S_mloff "`offset'"

   marksample touse
   if "`svy'" != "" {
       svymarkout `touse'
   }


   if `level' <10 | `level'>99 {
        di in red "level() must be between 10 and 99"
        exit 198
   }

   if "`cluster'" != ""  {
      local clopt cluster(`cluster')
   }

   if "`log'" != ""  { 
        local log "quietly"
   }

   global S_cen "`censor'"

   tokenize `varlist'
   local lhs "`1'"
   mac shift
   local rhs "`*'"
   
   if "`weight'" ~= "" {
      tempvar wvar
      qui gen double `wvar' `exp' if `touse'
      local weight "[`weight' `exp']"
   }



   ml model lf cepois_ll (`lhs' = `rhs', `offopt') `weight'  if `touse', `log' /*
      */ `mlopts' `robust' `svy' `clopt' title("Censored Poisson Regression")

  ml maximize, level(`level') `options'

 


end




