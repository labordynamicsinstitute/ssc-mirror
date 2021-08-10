*! tlabel.ado v 1.1.0 Program to enter tlabels
*! syntax varname newvarlabel or varname "newvarlabel" 
* v 1.0.0 fw 7/6/02 
* c 1.1.0 8/3/02 added -clearall -
program define tlabel
   version 7.0
   args vname lname
   if "`vname'" == "clearall" {
      foreach var of varlist _all {char `var'[tlabel]}
      di "  tlabels cleared from all variables"
      exit
   }
   confirm v `vname'
   char `vname'[tlabel] `lname'
   local labvar2: char `vname'[tlabel]
   di in text "Tlabel for " in result"`vname': `labvar2'"
end
