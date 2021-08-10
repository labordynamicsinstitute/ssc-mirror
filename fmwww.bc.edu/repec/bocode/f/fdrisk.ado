*!False confirmatory/discovery risk calculations for Second Generation P-Values
*!Author: Sven-Kristjan Bormann
*Based on the R-code for fdisk.R  from the sgpv-package from https://github.com/weltybiostat/sgpv
*!Version 1.1  24.12.2020 : Changed the syntax of the command to match more closely Stata standards, the old syntax still works: (dialog not changed yet) ///
							Option sgpval became one option 'fcr'. The default is to calculate the Fdr. ///
							Option nullweights became 'nulltruncnormal'. The option nullweights("Point") is automatically selected if option nullspace contains only one element. If option nullspace contains two elements then the Uniform distribution is used as the default weighting distribution. ///
							Option altweights became 'alttruncnormal'. The option altweights("Point") is automatically selected if option altspace contains only one element. If option altspace contains two elements then the Uniform distribution is used as the default weighting distribution. ///
							Options inttype and intlevel became options level(#) and likelihood(#). If no option is set then the confidence interval with the default confidence interval level is used. 							
*Version 1.04 09.11.2020 : Changed in the dialog the option sgpval (Set Fdr/Fcr) to display "Fdr" or "Fcr" instead of numerical values.
*Version 1.03 24.05.2020 : Added more input checks. 
*Version 1.02 14.05.2020 : Changed type of returned results from macro to scalar to be more inline with standard practises.
*Version 1.01 : Removed unused code for Generalized Beta distribution -> I don't believe that this code will ever be used in the original R-code.
*Version 1.00 : Initial SSC release, no changes compared to the last Github version.
*Version 0.97a: Made error messages hopefully more understandable.
*Version 0.97 : Added another input check for the pi0 option. Options altspace and nullspace deal now with spaces, but require their arguments now in "" if spaces are to be used with formulas. 
*Version 0.96 : Minor bugfixes; added all missing examples from the R-code to the help file and some more details to the help file.
*Version 0.95 : Updated documentation, added more possibilities to abbreviate options, probably last Github release before submission to SSC 
*Version 0.91 : Removed the dependency on the user-provided integrate-command -> Removed nomata option
*Version 0.90 : Initial Github release
*To-Do: Rewrite to use Mata whenever possible instead of workarounds in Stata -> Shorten the code and make it faster
*		 Evaluate input of options directly with the expression parser `= XXX' to allow more flexible input -> somewhat done, but not available for all options
*		 Rewrite input logic for nullspace and altspace to allow spaces in the input and make it easier to generate inputs in the dialog box -> make options nullspace_lower and nullspace_upper and the same for altspace available.
* 		Make error messages more descriptive and give hints how resolve the problems.


capture program drop fdrisk

program define fdrisk, rclass
version 12.0
syntax, nulllo(string) nullhi(string) STDerr(real)   ///
		NULLSpace(string asis)  ALTSpace(string asis) ///
		[ Pi0(real 0.5) ///
		/*Depreciated options */  NULLWeights(string)  ALTWeights(string) INTType(string) INTLevel(string) SGPVal(integer 0) ///
		/*Newly added options to replace existing ones*/  fcr Level(cilevel) LIKelihood(numlist min=1 max=2)  NULLTruncnormal ALTTruncnormal]
*Syntax parsing
local integrate nomataInt // Keep this macro in case I offer a Mata-based solution for the integration at some future point.


*New syntax(checks)---------------------------
// The new command syntax is mapped to the old syntax so that existing code still works with new version.
// But the new syntax should be more Stata-like than the old R-based one. 

*Set sgpval
if "`fcr'"!="" local sgpval 1
if "`fcr'"=="" local sgpval 0

*Set nullweights
if `:word count `nullspace''==1 local nullweights "Point"

if `:word count `nullspace''==2 & "`nulltruncnormal'" =="" & "`nullweights'"==""{
		*disp "No distribution for the nullspace provided. Using 'Uniform' as the default distribution."
		local nullweights "Uniform"
	}

if `:word count `nullspace''==2 & ("`nulltruncnormal'"==""){
	local nullweights "Uniform"
}

if `:word count `nullspace''==2 & "`nulltruncnormal'" !=""{
	local nullweights "TruncNormal"
}

*Set altweights
if `:word count `altspace''==1 local altweights "Point"

if `:word count `altspace''==2 & "`alttruncnormal'" =="" & "`altweights'"==""{
		*disp "No distribution for the altspace provided. Using 'Uniform' as the default distribution."
		local altweights "Uniform"
	}

if `:word count `altspace''==2 & "`alttruncnormal'"==""{
	local altweights "Uniform"
}

if `:word count `altspace''==2 & "`alttruncnormal'" !=""{
	local altweights "TruncNormal"
}


*Set inttype & intlevel only if old syntax has not been used.

if "`level'"!="" & "`likelihood'"=="" & "`inttype'"=="" & "`intlevel'"==""{
	local inttype "confidence"
	local intlevel = 1 - 0.01*`level'
}
if "`likelihood'"!=""{
	local inttype "likelihood"
	local intlevel = `likelihood'
}


*Old syntax (checks)-----------------------------
if !inlist(`sgpval',0,1){
	stop "Only values 0 and 1 allowed for the option 'sgpval'"	
}


if !inlist("`inttype'", "confidence","likelihood"){
	stop "Option 'inttype' must be one of the following: confidence or likelihood."	
}

if !inlist("`nullweights'", "Point", "Uniform", "TruncNormal"){
	stop "Option 'nullweights' must be one of the following: Point, Uniform or TruncNormal."
}

if !inlist("`altweights'", "Point", "Uniform", "TruncNormal"){
	stop "Option 'altweights' must be one of the following: Point, Uniform or TruncNormal."
}

if !(`pi0'>0 & `pi0'<1){
	stop "Values for option 'pi0' need to lie within the exclusive 0 - 1 interval. A prior probability outside of this interval is not sensible. The default value assumes that both hypotheses are equally likely."
}



*Code taken from sgpower.ado -> in R-code things are handled directly by the sgpower() function. This would be only possible in Mata in the same way.
local intlevel = `intlevel' 

if "`inttype'"=="confidence"{
	local z = invnorm(1- `intlevel'/2)
}

if "`inttype'"=="likelihood"{
	local z = invnorm(1- 2*normal(-sqrt(2*log(1/`intlevel')))/2)
}

*Evaluate inputs to allow more flexible specifications of intervals, null & alt spaces; no further checks yet for non-sensical input -> errors should be caught here by the expression parser -> the code will ignore more than two arguments, seems to be more robust than I initially thought 
	if wordcount("`nullhi'")>1 stop "Option {cmd:nullhi} has more than one number."
	capture local nullhi = `nullhi'
	isValid `nullhi' nullhi
	if wordcount("`nulllo'")>1 stop "Option {cmd:nullhi} has more than one number."
	capture local nulllo = `nulllo'
	isValid `nulllo' nulllo

	*if wordcount(`"`nullspace'"')>2 stop "Option {cmd:nullspace} can have at maximum two arguments."
	if `: word count `nullspace''==1 local nullspace = `nullspace'
	if `: word count `nullspace''==2{
		local nullspace1  `: word 1 of `nullspace''
		capture local nullspace1 = `nullspace1'
		isValid `nullspace1' nullspace 1		
		local nullspace2  `: word 2 of `nullspace''
		capture local nullspace2 = `nullspace2'
		isValid `nullspace2' nullspace 2	
		local nullspace `nullspace1' `nullspace2'
	} 

	*if wordcount(`"`altspace'"')>2 stop "Option {cmd:altspace} can have at maximum two arguments.{break} You have provided `=wordcount(`"`altspace'"')' number of arguments." 
	if `: word count `altspace''==1 local altspace = `altspace'
	if `: word count `altspace''==2{
		local altspace1  `: word 1 of `altspace''
		capture local altspace1 = `altspace1'
		local altspace2  `: word 2 of `altspace''
		capture local altspace2 = `altspace2'
		local altspace `altspace1' `altspace2'
	} 


*Power functions -> taken from sgpower.ado 
	if `sgpval'==0{
		local powerx normal(`nulllo'/`stderr' - x/`stderr' -`z') + normal(-`nullhi'/`stderr' + x/`stderr' - `z')		
	}
	if `sgpval'==1{
		if (`nullhi'-`nulllo')>= 2*`z'*`stderr' {
		local powerx normal(`nullhi'/`stderr' - x/`stderr' - `z') - normal(`nulllo'/`stderr' - x/`stderr' + `z')	
		}
		if (`nullhi'-`nulllo') < 2*`z'*`stderr'{
		local powerx = 0 
		}
	}
    if(`nulllo' == `nullhi')  {
      if "`nulllo'" != "`nullspace'"{
		disp as error "For a point indifference zone, specification of a different 'nullspace' is not permitted; Option 'nullspace' set to be " round(`nulllo', 0.01)
	  } 
	  local powerxnull : subinstr local powerx "x" "`nulllo'", all // Need substitution to emulate the parameter passing of R-functions only possible in Mata but in Stata -> Could be reworked by switching over to Mata
      local PsgpvH0 = `powerxnull'
	} 


*** calculate PsgpvH0
    * point null
	   *interval null
     if(`nulllo' != `nullhi')  {
     *PsgpvH0 @ point (=type I error at nullspace)
     if ("`nullweights'" == "Point"){
        if(`:word count `nullspace''!=1){
			stop "Option 'nullspace' must contain only one value when using a point null probability distribution, e.g. 'nullspace(0)'."
		} 
		local powerxnullint : subinstr local powerx "x" "`nullspace'", all
		local PsgpvH0 = `powerxnullint' 
      }
	 * PsgpvH0 averaged: check 'nullspace' input
	 if inlist("`nullweights'","Uniform","TruncNormal"){
		if `:word count `nullspace''<2{
			stop "Option 'nullspace' must not be a single number to use averaging methods. Set nullweights(Point) instead."
		}
		if `:word count `nullspace''==2{
			if max(`:word 1 of `nullspace'', `:word 2 of `nullspace'')>`nullhi' | min(`:word 1 of `nullspace'', `:word 2 of `nullspace'')<`nulllo'{
				disp as error "Option 'nullspace' must be inside originally specified null hypothesis specified by options 'nulllo' and 'nullhi'; at least one null space bound has been truncated."
				
				if max(`:word 1 of `nullspace'', `:word 2 of `nullspace'')>`nullhi'{
					local nullspace `=min(`:word 1 of `nullspace'', `:word 2 of `nullspace'')' `nullhi'
				}  
				if min(`:word 1 of `nullspace'', `:word 2 of `nullspace'')<`nulllo'{
					local nullspace `nulllo' `=max(`:word 1 of `nullspace'', `:word 2 of `nullspace'')' 
			
				}
				
			}
		}
	 }
 * PsgpvH0 averaged uniformly
      if("`nullweights'" == "Uniform") { // two steps instead of one are needed because results from one command cannot be used directly as the input of another command -> works in Stata only for functions
		qui `integrate' ,f(`powerx') l(`=min(`:word 1 of `nullspace'', `:word 2 of `nullspace'')') u(`=max(`:word 1 of `nullspace'', `:word 2 of `nullspace'')') 
        local PsgpvH0 = 1/(`=max(`:word 1 of `nullspace'', `:word 2 of `nullspace'')' - `=min(`:word 1 of `nullspace'', `:word 2 of `nullspace'')') * `r(integral)' 
      }

	   *PsgpvH0 averaged using truncated normal as weighting distribution function
      if("`nullweights'" == "TruncNormal") {
        * default: mean of Normal distr at midpoint of null.space // I assume that nullspace can have only two elements: upper and lower bound
        local truncNormmu = (`:word 1 of `nullspace'' + `:word 2 of `nullspace'')/2
        * default: std. dev of Normal distr same as assumed for estimator
        local truncNormsd  `stderr'
        local integrand `powerx' * ( normalden(x, `truncNormmu', `truncNormsd') * (normal((`=max(`:word 1 of `nullspace'', `:word 2 of `nullspace'')' - `truncNormmu')/`truncNormsd') - normal((`=min(`:word 1 of `nullspace'', `:word 2 of `nullspace'')'- `truncNormmu')/ `truncNormsd'))^(-1) ) 
        qui `integrate', f(`integrand') l(`=min(`:word 1 of `nullspace'', `:word 2 of `nullspace'')') u(`=max(`:word 1 of `nullspace'', `:word 2 of `nullspace'')') 
        local PsgpvH0 `r(integral)'

      }
	 } 
	 *** calculate PsgpvH1
    * PsgpvH1 @ point
    if("`altweights'" == "Point")  {
      if(`:word count `altspace''!=1){
	    stop "Option 'altspace' must be a one number or expression when using a point alternative probability distribution."	
	  }	  
      if inrange(`altspace',`nulllo',`nullhi') {
		stop "Option 'altspace' must be outside of the originally specified indifference zone by options 'nulllo' and 'nullhi'."	  
	  } 
	  local powerxaltpoint : subinstr local powerx "x" "`altspace'", all
      local PsgpvH1 = `powerxaltpoint' 
    }

    * PsgpvH1 averaged: check `altspace' input
    if inlist("`altweights'" ,"Uniform", "TruncNormal") {
      if( `:word count `altspace''<2)  stop "Option 'altspace' must not be a point to use averaging methods."
      if `:word count `altspace''==2  {
        if (`=min(`:word 1 of `altspace'', `:word 2 of `altspace'')' > `nulllo') & (`=max(`:word 1 of `altspace'', `:word 2 of `altspace'')'< `nullhi') {
			disp as error "Option 'altspace' can not be contained inside indifference zone specified by options 'nulllo' and 'nullhi'" _n "'nullspace' and `'altspace' might be flipped."
			disp as error "If you see this message after running the {cmd:sgpv} command, then you need to the set options 'nulllo' and 'nullhi' to " _n " values which are smaller than the lower and upper bound of the smallest confidence interval. "
			exit 198
		} 
        if ((`:word 1 of `altspace'' >`nulllo'| `:word 2 of `altspace''> `nulllo' ) & (`:word 1 of `altspace'' < `nullhi'| `:word 2 of `altspace'' < `nullhi')){
			stop "Option 'altspace' can not intersect with the indifference zone specified by options 'nulllo' and 'nullhi'." //Not sure if translated correctly
		}  
      }
    }

    * PsgpvH1 averaged uniformly
    if("`altweights'" == "Uniform") {
	 qui `integrate', f(`powerx') l(`=min(`:word 1 of `altspace'', `:word 2 of `altspace'')') u(`=max(`:word 1 of `altspace'', `:word 2 of `altspace'')') 
      local PsgpvH1 = 1/(`=max(`:word 1 of `altspace'', `:word 2 of `altspace'')' - `=min(`:word 1 of `altspace'', `:word 2 of `altspace'')') * `r(integral)'
    }


    * PsgpvH1 averaged using truncated normal as weighting distribution function
    if("`altweights'" == "TruncNormal") {
      * default: mean of Normal distr at midpoint of `altspace'
      local truncNormmu = (`:word 1 of `altspace'' + `:word 2 of `altspace'')/2
      * default: std. dev of Normal distr same as assumed for estimator
      local truncNormsd = `stderr'
	  if !real("`truncNormmu'") | !real("`truncNormsd'") stop "Both elements of the option 'altspace' must be numeric or be expressions which evaluate to a number."
        local integrand `powerx' * ( normalden(x, `truncNormmu', `truncNormsd') * (normal((`=max(`:word 1 of `altspace'', `:word 2 of `altspace'')' - `truncNormmu')/`truncNormsd') - normal((`=min(`:word 1 of `altspace'', `:word 2 of `altspace'')'- `truncNormmu')/ `truncNormsd'))^(-1) ) 
        qui `integrate', f(`integrand') l(`=min(`:word 1 of `altspace'', `:word 2 of `altspace'')') u(`=max(`:word 1 of `altspace'', `:word 2 of `altspace'')')      
        *qui integrate, f(`integrand') l(`=min(`:word 1 of `altspace'', `:word 2 of `altspace'')') u(`=max(`:word 1 of `altspace'', `:word 2 of `altspace'')') vectorise
      local PsgpvH1 = `r(integral)'
    }
	
 * Calculate FDR or FCR
  if(`sgpval' == 0){
	local fdr = (1 + `PsgpvH1' / `PsgpvH0' *  (1-`pi0') / `pi0'     ) ^ (-1) 
	}
  if(`sgpval' == 1){
  local fcr = (1 + `PsgpvH0' / `PsgpvH1' *  `pi0'     / (1-`pi0') ) ^ (-1)
  }
  
  if "`fdr'"!="" | !mi(real("`fdr'")){
	disp _n "The false discovery risk (fdr) is: " %9.0g `fdr'
  }
  if "`fcr'"!="" | !mi(real("`fcr'")){
	disp _n "The false confirmation rate (fcr) is: " %9.0g `fcr'
  }
  if "`fdr'" !="" return scalar fdr = `fdr'
  if "`fcr'" !="" return scalar fcr = `fcr'  	
end


*Additional commands------------------------------------------------------------------------------------
*Simulate the behaviour of the R-function with the same name 
program define stop
 args text 
 disp as error `"`text'"'
 exit 198
end

*Check if the input is valid
program define isValid
args valid optname i
if real("`=`valid''")==.{
	if "`i'"!=.{
		disp as error "`valid' in option {cmd:`optname'} on position `i'  is not a number nor . (missing value) nor empty."
	}
	else{
		disp as error "`valid' in option {cmd:`optname'}  is not a number nor . (missing value) nor empty."
	} 
	exit 198
		}
		
end

*Shortcut to the Stata integration command, same syntax as the user-provided integrate-command.
program define nomataInt, rclass
syntax , Lower(real) Upper(real) Function(string) [*]
preserve
range x `lower' `upper' 1000
gen y  = `function'
integ y x
return local integral `r(integral)'
restore
 
end
