*! slist.ado  writes smart lists as compact as possible - Stata version 7 and 8.
*! 2.0   11mar2003   Svend Juul   sj@soci.au.dk + John Gallup and Jens M. Lauritsen
*! slist is an extension by Svend Juul of wlist.ado by John Gallup and Jens M. Lauritsen, July 2001

program define slist
  version 7
  syntax [varlist] [if] [in] [, Label noObs Decimal(numlist >=0) Id(varlist) ]
  preserve                           /* Modifications to data are temporary */
  if "`varlist'" != "" { 
     local varlist `id' `varlist'
  }
  quietly compress `varlist'         /* To economize with space */

* value labels are not shown by default 
     if "`label'" == "" {
        local nolabel = "nolabel"
     }  /* show values= default */
     else {
        local nolabel = ""
     } 
  
* NEEDED WIDTH FOR EACH VARIABLE. MODIFY FORMAT
  foreach V of local varlist {                  /* V: variable name */
     local T : type `V'                         /* T: variable type */
     local F : format `V'                       /* F: format string */
     local SIGN = 1                             /* SIGN: Sign in format */
     if index("`F'","-") {
        local SIGN = -1
     }
     local WN = length("`V'")                   /* WN: Width variable name */

     * if labels are shown, then modify LN width max length of label
     if "`nolabel'" == "" {
        local vlV : lab (`V') maxlength        /* length of longest value label ==: no value label defined */
        if `vlV' > 0 {
           local WN=max(`WN',`vlV') /*now WN is max of name or widest value label*/
        }
     }

     * STRING FORMATS: 
     if index("`T'","str") {  
        local WD = real(substr("`T'",4,3))      /* WD: Data width */
        local W = `SIGN' * max(`WD',`WN')       /* W: Max width name, data */
        format `V' %`W's                        /* String format */
     }

     * DATE AND TIME SERIES FORMATS: NO CHANGE
     else if index("`F'","d") | index("`F'","t") {
     }

     * FLOATING POINTS: 
     else if inlist("`T'","float","double") {
        if "`decimal'" == "" {                      /* DECIMALS NOT SPECIFIED */
           local WD = 9 + (inlist("`T'","double"))
           local W = `SIGN' * max(`WD',`WN')        /* Max width name, data */
           format `V' %`W'.0g                       /* General format */
        }
        else {                                      /* DECIMALS SPECIFIED */
           summarize `V' `if' `in' , meanonly
           if "`r(min)'" == "" {
              local W1 = 1
           }
           else {
              local W1 = abs(int(`r(min)'))
              local W1 = length("`W1'") + (`r(min)'<0)
           }
           if "`r(max)'" == "" {
              local W2 = 1
           }
           else {
              local W2 = int(`r(max)')
              local W2 = length("`W2'")
           }
           local WD = max(`W1',`W2') + `decimal' + (`decimal'>0)
           if `WD' < max(11,`WN') {
              local W = `SIGN' * max(`WD',`WN')     /* Max width name, data */
              format `V' %`W'.`decimal'f            /* Fixed format */
           }
           else {
              local W = `SIGN' * max(10,`WN')       /* LARGE NUMBERS: */
              format `V' %`W'.0g                    /* General format */
           }
        }
     }

     * INTEGERS:
     else if inlist("`T'","byte","int","long") {
        summarize `V' `if' `in' , meanonly
        if "`r(min)'" == "" {
           local W1 = 1
        }
        else {
           local W1 = length("`r(min)'")
        }
        if "`r(max)'" == "" {
           local W2 = 1
        }
        else {
           local W2 = length("`r(max)'")
        }
        local W = `SIGN' * max(`W1',`W2',`WN')      /* Max width name, data */
        format `V' %`W'.0f                          /* Integer format */
     }
  }

* Following: slightly modified from wlist.ado (John Gallup, Jens M. Lauritsen)
* REMOVE ID VARIABLES FROM VARLIST?
   if "`id'" != "" {
      local outlist ""
      foreach idvar of local id {
         foreach avar of local varlist {
            if "`idvar'" !="`avar'" {
               local outlist "`outlist'`avar' "
            }
         }  /* Now id variable has been cut out of varlist */
         local varlist "`outlist'"
         local outlist ""
      }
   } 

* GENERATE LIST
   Varwidth `varlist', `obs' id(`id')
   local pages `r(pages)'
   forvalues p = 1/`pages' {
      local varlist`p' `"`r(varlist`p')'"'
         }
   forvalues p = 1/`pages' {
* DETERMINE STATA VERSION
  capture assert `c(version)' >= 8, rc0
  if !_rc {
         clist `id' `varlist`p'' `if' `in', nodisplay `nolabel' `obs'
      }   
      else {
         list `id' `varlist`p'' `if' `in', nodisplay `nolabel' `obs'
      }
   }
end

* DETERMINE WIDTH AND PLACEMENT OF VARIABLE COLOUMNS
program define Varwidth, rclass
   syntax varlist, [noobs id(varlist)]
   if "`obs'" == "" { local obswidth = length(string(_N)) + 3 }
   else {local obswidth = 0}
   local totwidth = `obswidth'
   foreach avar of local varlist {
      local fmt : format `avar'
      local n1 = cond(index("`fmt'", "-"),3,2)
      local dotn = index("`fmt'", ".")
      if `dotn' { local n2 =  `dotn' - `n1' }
      else { local n2 = index("`fmt'", "s") - `n1' }
      if index("`fmt'","d") | index("`fmt'","t") {       /* date and time */
         local varw = length(string(-1,"`fmt'")) }       /* series formats */
      else { local varw = substr("`fmt '", `n1', `n2') }
      local varw = `varw' + 2
      local widthlist "`widthlist' `varw'"
      local totwidth = `totwidth' + `varw'  /* total width of variable columns */
   }
   local winwidth : set linesize  /* get width of user's result window */

   * MAKE ROOM FOR ID VARIABLE
   foreach idvar of local id {  /* subtract width of id variable */   
      local fmt : format `idvar'
      local n1 = cond(index("`fmt'", "-"),3,2)
      local dotn = index("`fmt'", ".")
      if `dotn' { local n2 =  `dotn' - `n1' }
      else { local n2 = index("`fmt'", "s") - `n1' }
      if index("`fmt'","d") | index("`fmt'","t") {       /* date and time */
         local varw = length(string(-1,"`fmt'")) }       /* series formats */
      else { local varw = substr("`fmt '", `n1', `n2') }
      local varw = `varw' + 2
      local winwidth = `winwidth' - `varw'  /* total width of variable columns minus id
field */
   }

   * NEW PAGE ?
   if `totwidth' <= `winwidth' {
      local pages 1
      local varlist1 `"`varlist'"'
   }
   else {
      local p 1
      local newwidth = `obswidth'
      foreach w of local widthlist {
         local newwidth = `newwidth' + `w'
         gettoken avar varlist : varlist
         if `newwidth' <= `winwidth' { local varlist`p' "`varlist`p'' `avar'" }
         else {
            local p = `p' + 1
            local newwidth = `obswidth' + `w'
            local varlist`p' "`avar'"
         }
      }
      local pages = `p'
   }
   return local pages `pages'
   forvalues p = 1/`pages' { return local varlist`p' "`varlist`p''" }
end /* Varwidth */
