*! namecheck 1.0  2jan2026
*! author cpk 

/********************************************************/
/* Program to check for name mismatches                 */
/*  List of standardized names kept in "names.dta"      */
/*  If current names don't all match, generates         */
/*  diagnostics file and stops execution                */
/*                                                      */
/* Syntax: namecheck varname                            */
/*  where varname is name variable used in both files   */
/* NOTE:  You first have to create a list of "correct"  */
/*        names and save in "names.dta".  You also have */
/*        to use the same variable name for the naming  */
/*        variable in both locations                    */
/********************************************************/
 
capture program drop namecheck
program define namecheck
version 10.0
 
quietly {
  preserve
  keep `1'
  duplicates drop
  merge 1:1 `1' using "names.dta"
  count if _merge==1
  local r1=`r(N)'
  count if _merge==2
  local r2=`r(N)'
}
  if `r1'>0 & `r2'>0 {
    quietly { 
    	drop if _merge==3
      rename _merge matchtype
      sort `1'
      gen sequence=_n
      reshape wide `1', i(sequence) j(matchtype)
      rename `1'1 `1'
      rename `1'2 standard_`1'
      order standard_`1' `1'
      drop sequence
      export excel using "namelist.xlsx", firstrow(variables) nolabel replace
    }
    display as smcl "Name mismatches written to {browse  "`"namelist.xlsx}"'"
    error(1)
  }
  else {
  	display "No name mismatches problems found."
  }
  restore
end
*end of program namecheck*
