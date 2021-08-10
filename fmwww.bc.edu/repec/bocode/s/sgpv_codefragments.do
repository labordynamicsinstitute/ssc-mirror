*Contains code which I might use at some point for the SGPV command, but which is currrently not needed or would take too much time to implement in a reasonable way

*Potential returns if I switch from r-class to e-class command
ereturn matrix sgpv_comparison =  `comp'
ereturn local sgpv_cmd "sgpv"
ereturn local sgpv_cmdline `"sgpv `0'"'
ereturn local sgpv_coef `"`coefficient'"'
ereturn local sgpv_estimate `"`estimate'"'
ereturn local sgpv_nulllo `"`nulllo'"'
ereturn local sgpv_nullhi `"`nullhi'"'
ereturn local sgpv_estlo `"`estlo'"'
ereturn local sgpv_esthi `"`esthi'"'


/*Code for makehlp documentation
return[sgpv_cmd sgpv]
return[sgpv_cmdline command as typed]
return[sgpv_coef the coefficient(s) for which the SGPVs were calculated.]
return[sgpv_estimate the name of the estimate for which SGPVs were calculated.]
*/

*Allow mixture of matrix and variable input?
foreach opt in esthi estlo{
	if `:word count ``opt'''==1{
		capture disp `=`opt'' // Test if option contains a matrix and not a scalar value
		if _rc==509{
		local mat_`opt' 1
			
		}
		else if !_rc{ 
			capture confirm numeric variable ``opt''
			if !_rc{
				local var_`opt' 1
			}
		}
	}
}
*New check if both inputs are matrices
	if "`mat_esthi'" == "1" & "`mat_estlo'" =="1"{
		local matsfound 1
	}
	else if "`mat_esthi'"!="`mat_estlo'" {
		disp as error "Either `esthi' or `estlo' is not a matrix. Both options need to be matrices if you want to use matrices as inputs."
		exit 198
	}
	else if "`var_esthi'"=="" & "`var_estlo'"==""{
		local varsfound 0
	}

*Check same size of matrix and variable to allow mixed input in case it might be needed some day

if rowsof(`opt')!=`=_N'{
	stop "Matrix `opt' and variable `var' have not the same number of observations. "
}

foreach opt in null est{
	if `:word count ``opt'hi'' != `: word count ``opt'lo''{
		disp as error " `"`opt'hi"' and `"`opt'lo"' are of different length "
		exit 198
	}
}

*Write an input check command which uses 'c_local' to write back the results

*Write something to expand matrice directly into a macro


*Use new variables to store and calculate the SGPVs -> Modify this approach to work with matrices and variables as input
program define sgpv_var, rclass
 syntax ,esthi(varname) estlo(varname) nullhi(string) nulllo(string) [replace nodeltagap]
 if "`replace'"!=""{
	capture drop pdelta dg
 }
 else{
	capture confirm variable pdelta dg
		if !_rc{
			disp as error "Specifiy the replace option: variables pdelta and dg already exist."
			exit 198
		}
 }
 
 tempvar estlen nulllen overlap bottom null_hi null_lo gap delta gapmax gapmin overlapmin overlapmax
 local type : type `esthi' // Assuming that both input variables have the same type
 quietly{ //Set variable type to the same precision as input variables
		gen `type'	`null_hi' = real("`nullhi'")
		gen `type' `null_lo' =real("`nulllo'")			
 		gen `type' `estlen' = `esthi' - `estlo'
		gen `type' `nulllen' = `null_hi' -`null_lo'
		egen `type' `overlapmin' = rowmin(`esthi' `null_hi') 
		egen `type' `overlapmax' =rowmax(`estlo' `null_lo')
		gen `type' `overlap' = `overlapmin' - `overlapmax'
		replace `overlap' = max(`overlap',0)
		gen `type' `bottom' =	min(2*`nulllen',`estlen')
		gen `type' pdelta = `overlap'/`bottom'
		
		replace pdelta =0 if `overlap'==0 
		replace pdelta = 1 if (`estlen'==0 & `nulllen'>=0 & `estlo'>=`null_lo' & `esthi'<=`null_hi')
		replace pdelta = 0.5 if (`estlen'>0 & `nulllen'==0 & `estlo'<=`null_lo' & `esthi'>=`null_hi')
		replace pdelta =. if (`estlo'>`esthi' | `null_lo'>`null_hi')
		/* Calculate delta gap*/
		egen `type'	`gapmax' = rowmax(`estlo' `null_lo') 
		egen `type' `gapmin' = rowmin(`null_hi' `esthi')
		gen `type'	`gap' = `gapmax' - `gapmin'
		 
		 if "`deltagap'"!="nodeltagap"{
			 gen `type' `delta' = `nulllen'/2
			 replace `delta' = 1 if `nulllen'==0
			 gen `type' dg = .
			 replace dg = `gap'/`delta'  if (pdelta==0 & pdelta!=.)
			 label variable dg "Delta Gap"
		}
		*Label variables
		label variable pdelta "SGPV"
		
		}
 
 exit 
end


*Check if input is infinite
program define isInfinite
args infinite
	if `"`infinite'"'==.{
		c_local infinite = c(maxdouble)
	}
	else{
		c_local infinite = `infinite'
	}

end

*Check if the input is valid
program define isValid
args valid
if `valid'!=.  & real("`valid'")==.{
	disp as error "`valid'  is not a number nor . (missing value) nor empty"
	exit 198
		}
		
end

*The old command kept for reference purposes
program define isInfinite_old, rclass
args infinite
	if `"`infinite'"'==.{
		return local infinite = c(maxdouble)
	}
	else if `"`infinite'"'=="-Inf"{
		return local infinite = - c(maxdouble)
	}
	else{
		return local infinite = `infinite'
	}

end

*Parse subcommands for an extension of the sgpv command to allow dialog box usage
program ParseSubcommand
syntax anything [,*] 
	
	*Removing from graphopt impossible options which give rise to cryptic error messages
	/*gettoken opts opt2:0 ,parse(,)
	gettoken opts opt2:opt2 // Get everything after the comma
	local opts2: list uniq opts2 //Remove double options given
	*/
exit
end