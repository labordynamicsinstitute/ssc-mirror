*! Version 1.0.1 2019-08-02
*! Author: Dejin Xie (Nanchang University, China)

** Version 1.0.1 2024-02-22, use "forvalues" to replace "foreach"
** Version 1.0.0 2019-08-02, the initial version

****** Drop or Keep A Range of Observations  ******

program define dkobs, rclass sortpreserve
version 13

syntax anything [if] [in], [ By(varlist) Keep Last Quietly ]

marksample touse, novarlist strok

quietly {
  tempvar DKIDs
  gen `DKIDs'=_n
  if "`by'"~="" {
    local By_Vars "bysort `by' (`DKIDs') :"
  }

  tempvar DKVars
  gen `DKVars'=0
  tempvar DKObs
  `By_Vars' gen `DKObs'=_n if `touse'
  local DKNum = wordcount("`anything'")
  tokenize "`anything'"
  if "`last'"=="" {
    forvalues dn = 1/`DKNum' {
      capture confirm integer number ``dn''
      if !_rc {
        replace `DKVars'=1 if `DKObs'==``dn''
      }
      else if regexm("``dn''","[-0-9f]+(/|\([-0-9]+\))[-0-9l]+") {
        if regexm("``dn''","^f") {
          local word("`anything'",`dn') = subinstr("``dn''","f",1,1)
          forvalues i = `=subinstr("``dn''","f","1",1)' {
            replace `DKVars'=1 if `DKObs'==`i'
          }
        }
        else if regexm("``dn''","l$") {
          forvalues i = `=subinstr("``dn''","l","`c(N)'",1)' {
            replace `DKVars'=1 if `DKObs'==`i'
          }
        }
		else {
          forvalues i = ``dn'' {
            replace `DKVars'=1 if `DKObs'==`i'
          }			
		}
	  }
      else {
        dis as error "The `dn'th in `anything' is not integer number or numlist."
        exit
      }
    }
/* The Former Program :
    foreach i of numlist `anything' {
      replace `DKVars'=1 if `DKObs'==`i'
    }
*/
  }
  else {
    tempvar DKLast
    `By_Vars' gen `DKLast'=_N if `touse'
    forvalues dn = 1/`DKNum' {
      capture confirm integer number ``dn''
      if !_rc {
        replace `DKVars'=1 if `DKObs'==`DKLast'-``dn''+1
      }
      else if regexm("``dn''","[-0-9f]+(/|\([-0-9]+\))[-0-9l]+") {
        if regexm("``dn''","^f") {
          local word("`anything'",`dn') = subinstr("``dn''","f",1,1)
          forvalues i = `=subinstr("``dn''","f","1",1)' {
            replace `DKVars'=1 if `DKObs'==`DKLast'-`i'+1
          }
        }
        else if regexm("``dn''","l$") {
          forvalues i = `=subinstr("``dn''","l","`c(N)'",1)' {
            replace `DKVars'=1 if `DKObs'==`DKLast'-`i'+1
          }
        }
		else {
          forvalues i = ``dn'' {
            replace `DKVars'=1 if `DKObs'==`DKLast'-`i'+1
          }
        }
	  }
      else {
        dis as error "The `dn'th in `anything' is not integer number or numlist."
        exit
      }
    }
/* The Former Program :
    foreach i of numlist `anything' {
      replace `DKVars'=1 if `DKObs'==`DKLast'-`i'+1
    }
*/
  }
}    /* Close brace of quietly */

if "`keep'"=="" {  
  `quietly' drop if `DKVars'==1
}
else { 
  `quietly' keep if `DKVars'==1
}

end
