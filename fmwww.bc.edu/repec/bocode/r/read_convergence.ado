* Read in Mplus output file and determine if the model converged.

version 9

capture program drop read_convergence
program define read_convergence , rclass


syntax , out(string) 

preserve

set more off


*local out="c:/trash/log.out"

qui infix str line 1-85 ///
      using `out' , clear
format line %85s





qui gen linenum=_n
qui gen x1=_n if (ltrim(line)=="THE MODEL ESTIMATION TERMINATED NORMALLY")

qui summarize x1
if r(min)>0 & r(N)>0 {
   qui drop if linenum<(r(min)+2)
   qui drop if linenum>=(r(min)+3)
   qui gen x2 = 1 if (ltrim(line)=="")
   if x2==1 {
      di in green "The model estimation seems to have terminated normally"
      local stop = 0
      local termination = "normal"
   }
   else {
      di as error "THE MODEL ESTIMATION TERMINATED NORMALLY BUT WITH ERRORS"
      local stop = 1
      local termination = "normal with errors"
   }
}
else {
   di as error "THE MODEL ESTIMATION DID NOT TERMINATE NORMALLY"
   local stop = 1
   local termination = "not normal"
}

return local stop = `stop'
return local termination = "`termination'"

end

