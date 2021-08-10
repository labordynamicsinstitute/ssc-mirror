*!Calculate the Second-Generation P-Value(s)(SGPV) and their associated diagnosis statistics after common estimation commands based on Blume et al. 2018,2019
*!Author: Sven-Kristjan Bormann
*!Version 1.2a 01.02.2021: Fixed a bug with the level option. Fixed a bug with regards to leading whitespaces when prefixing sgpv.
*!Version 1.2 27.12.2020 : Changed the name of the option permament to permdialog to clarify the meaning of the option. ///
							Fixed the format option in the Dialog box. /// 
							Added a remove option for the menu subcommand to remove the entries in the profile.do created by the option permdialog. ///
							Renamed the dialog tab "Display" to "Reporting". Moved the options from the dialog tab "Fdrisk" to dialog tab "Reporting". ///
							Decpreciated the option bonus() and replaced it with the new options "deltagap", "fdrisk" and "all" which have the same effect as the previous bonus() option. This way is more in line with standard Stata praxis. The bonus option still works but is no longer supported. ///
							Added a forgotten option to calculate the bonus statistics in the example file sgpv-leukemia-example.do and fixed the size of the final matrix -> Without the option, the example ends with a matrix error. ///
							Removed the fdrisk-options "nullspace" and "nullweights" because they were redudant and added a new option "truncnormal" to request the truncated Normal distribution for the null and alternative space. ///
							Renamed the options "intlevel" and "inttype" to "level" and "likelihood". The level-option works like the same named option in other estimation commands. It sets the level of the confidence interval. This option overwrites the level option of an estimation command. ///
							The likelihood-option is meant to be used together with the matrix-option. ///
							The previous "inttype" and "intlevel" options did not work as intended. They did not set interval type and level for the Fdrs correctly. ///
							The title for results matrix now shows the level and type which was used to calculate the SGPVs (, delta-gaps and Fdrs). ///
							Calculating SGPVs for stored estimations will only show the SGPV results and not the saved estimation results anymore.
*Version 1.1a 08.07.2020 : Changed the subcommand "fdrisk" to "risk" to be in line with the Python code.
*Version 1.1  09.06.2020 : Added support for multiple null hypotheses; ///
							added a noconstant-option to remove constant from list of coefficients; ///
							fixed errors in the perm-option of the "sgpv menu"-subcommand; ///
							fixed a confusion in the help-file about the nulllo and nullhi options ///
							added an experimental, undocumented option to enter the null interval -> option "null" with syntax "(lower_bound1,upper_bound2) (lower2,upper2) ... " ///
							should allow now to use expressions for options "nulllo" and "nullhi" without having to run the expression parser first ///
							removed unused "altspace" option from the syntax, help file and dialog box -> "altspace" is automatically set with lower and upper bounds of confidence intervals -> fixed remarks related to default values for altspace and nullspace							
*Version 1.03a 17.05.2020 : Made the title of the displayed matrix adapt to the type of null-hypothesis; fixed a wrong file name in the sgpv-leukemia-example.do -> should now load the dataset; minor improvements in the example section of the help file ; added a new example showing how to apply a different null-hypothesis for each coefficient; added an example how to export results by using estout from Ben Jann
*Version 1.03 14.05.2020 : added better visible warnings against using the default point 0 null-hypothesis after the displayed results -> warnings can be disabled by an option; added some more warnings in the description of the options 
*				Fixed: the Fdr's are now displayed when using the bonus-option with the values "fdrisk" or "all"
*Version 1.02 03.05.2020 : Changed name of option 'perm' to 'permanent' to be inline with Standard Stata names of options; ///
				removed some inconsistencies between help file and command file (missing abbreviation of pi0-option, format-option was already documented); ///
				removed old dead code; enforced and fixed the exclusivity of 'matrix', 'estimate' and prefix-command -> take precedence over replaying ; ///
				shortened subcommand menuInstall to menu;  ///
				added parsing of subcommands as a convenience feature ///
				allow now more flexible parsing of coefficient names -> make it easier to select coefficients for the same variable across different equations -> only the coefficient name is now required not the equation name anymore -> implemented what is "promised" by the dialog box text ///
				changed the default behaviour of the bonus option from nobonus to bonus -> bonus statistics only shown when requested		
*Version 1.00 : Initial SSC release, no changes compared to the last Github version.
*Version 0.99 : Removed automatic calculation of Fcr -> setting the correct interval boundaries of option altspace() not possible automatically
*Version 0.98a: Displays now the full name of a variable in case of multi equation commands. Shortened the displayed result and added a format option -> get s overriden by the same named option of matlistopt(); Do not calculate any more results for coefficients in r(table) with missing p-value -> previously only checked for missing standard error which is sometimes not enough, e.g. in case of heckman estimation. 
*Version 0.98 : Added a subcommand to install the dialog boxes to the User's menubar. Fixed an incorrect references to the leukemia example in the help file.
*Version 0.97 : Further sanity checks of the input to avoid conflict between different options, added possibility to install dialog box into the User menubar.
*Version 0.96 : Added an example how to calculate all statistics for the leukemia dataset; minor fixes in the documentation of all commands and better handling of the matrix option.
*Version 0.95 : Fixed minor mistakes in the documentation, added more information about SGPVs and more example use cases; minor bugfixes; changed the way the results are presented
*Version 0.90 : Initial Github release

/*
To-Do for next update (Version 1.1a?) to be released after the submission to Stata Journal:
	- Mention in help file the possibility to use formulas/expressions for options nulllo and nullhi. -> Add corresponding examples
	- Add another input check to prevent the usage of variables for options  nulllo and nullhi. -> Most likely using variables leads to non-desired output -> unless somebody saves their null bounds in variables. 

To-Do(Things that I wish to implement at some point or that I think that might be interesting to have:)
	Internal changes (Mostly re-organising the code for shorter and easier maintained code):
	- Add more paths to search the profile.do file.
	- Add code which removes the requirement of having the r(table) matrix existing after an estimation command -> Using only e(b) and e(V) requires a lot more manual calculations of the p-value and lower and upper bounds.
	- Change the code which handles the inputmatrix to make use of the newly added ability of sgpvalue to use matrices as inputs -> should allow with larger than c(matsize) matrices -> requires modification of all code/commands which create new matrices like the various parsing commands for coefficients, p-values, etc.
	- Shorten parts of the code by using the cond()-function instead if ... else if ... constructs.
	- Write a certification script which checks all possible errors (help cscript)
	- change the help file generation from makehlp to markdoc for more control over the layout of the help files -> currently requires a lot of manual tuning to get desired results.
	- Write a subcommand to parse the Fdrisk-options or at least move the code to a different place; at the moment the code is not at the best place and the fdrisk-options are set before it is checked if they are needed at all.
	
	External changes (Mostly more features):
	- Allow a mixture of case 1 & 2 for the coefficient-option -> select only some equations and variables from a multi-equation estimation -> ex. coef(((q10: q50: q90:) (mpg weight foreign)) which will then be expanded to coef(q10:mpg q10:weight ... q90:weight q90:foreign) -> requires changes in how this option is parsed
	- Unify options nulllo and nullhi into one option named "null" to make it easier for users to enter null-hypothesis -> requires rewriting the parsing of the input -> initial code written -> could rename the option to "H0" -> not sure which way to input intervals works best
	- Add an option to not display the individual null-hypothesis if multiple null hypotheses are set.
	- Make help-file easier to understand, especially what kind of input each option requires.
	- Consider dropping the default value for the null-hypothesis and require an explicit setting to the null-hypothesis.
	- Make error messages more descriptive and give hints how to resolve the problems. (somewhat done hopefully)
	- support for more commands which do not report their results in a matrix named "r(table)". (Which would be the relevant commands?)
	- Make matrix parsing more flexible and rely on the names of the rows for identifiying the necessary numbers; allow calculations for more than one stored estimate
	- Return more infos (Which infos are needed for further processing?)
	- Allow plotting of the resulting SGPVs against the normal p-values directly after the calculations -> use user-provided command plotmatrix instead?	
	- improve the speed of fdrisk.ado -> the integration part takes too long. -> switch over to Mata integration functions provided by moremata-package
	- add an immidiate version of sgpvalue similar like ttesti-command; allow two sample t-test equivalent -> currently the required numbers need be calculated or extracted from these commands.
*/

capture program drop sgpv
program define sgpv, rclass
version 12.0
*Parse the initial input 
capture  _on_colon_parse `0'

*Check if anything to calculate is given
if _rc & "`e(cmd)'"=="" & (!ustrregexm(`"`0'"',"matrix\(\w+\)") & !ustrregexm(`"`0'"',"m\(\w+\)") ) & (!ustrregexm(`"`0'"',"estimate\(\w+\)") & !ustrregexm(`"`0'"',"e\(\w+\)") ) & !inlist("`: word 1 of `0''","value","power","risk","plot", "menu" ) { // If the command was not prefixed and no previous estimation exists. -> There should be a more elegant solution to this problem 
	disp as error "No last estimate or matrix, saved estimate for calculating SGPV found."
	disp as error "No subcommand found either."
	disp as error "Make sure that the matrix option is correctly specified as 'matrix(matrixname)' or 'm(matrixname)' . "
	disp as error "Make sure that the estimate option is correctly specified as 'estimate(stored estimate name)' or 'e(stored estimate name)' . "
	disp as error "The currently available subcommands are 'value', 'power', 'fdrisk', 'plot' and 'menu'."
	exit 198
}


if !_rc{
	local cmd `"`s(after)'"'
	local 0 `"`s(before)'"' 
} 

***Parsing of subcommands -> A convenience feature to use only one command for SGPV calculation -> no further input checks of acceptable options
* Potential subcommands: value, power, fdrisk, plot, menu
local old_0 `0'
gettoken subcmd 0:0, parse(" ,:")
if inlist("`subcmd'","value","power","risk","plot", "menu" ){ // Change the code to allow shorter subcommand names? Look at the code for estpost.ado for one way how to do it
	if "`cmd'"!="" stop "Subcommands cannot be used when prefixing an estimation command."

	if ("`subcmd'"=="value"){
		local subcmd : subinstr local subcmd "`=substr("`subcmd'",1,1)'" "sgpv"
	} 
	if ("`subcmd'"=="power"){
		local subcmd : subinstr local subcmd "`=substr("`subcmd'",1,1)'" "sgp"
	} 
	if ("`subcmd'"=="plot"){
		local subcmd `subcmd'sgpv
	} 
	if ("`subcmd'"=="risk"){
		local subcmd fdrisk
	}
	`subcmd' `0'
	exit	
	
}
else{
	local 0 `old_0'
}


**Define here options
syntax [anything(name=subcmd)] [,   Estimate(name)  Matrix(name)  Coefficient(string asis) NOCONStant   /// input-options
 Quietly MATListopt(string asis)  FORmat(str) NONULLwarnings  DELTAgap FDrisk all  /// display-options
  nulllo(string) nullhi(string) Null(string)  /// null hypotheses  -> option "null" unifies nulllo and nullhi for easier entering the intervals -> not documented and a rather experimental change
  TRUNCnormal  /*set truncated normal distribution for nullspace*/ Level(cilevel) LIKelihood(numlist min=1 max=2) Pi0(real 0.5) /// fdrisk-options
    debug  /*Display additional debug messages: undocumented*/ ///
	/*depreciated options*/ Bonus(string) NULLSpace(string asis) NULLWeights(string) ALTWeights(string) ALTSpace(string asis) INTLevel(string) INTType(string) 	] 


***Option parsing
if "`cmd'"!="" & ("`estimate'"!="" | "`matrix'"!=""){
	disp as error "Options 'matrix' and 'estimate' cannot be used in combination with a new estimation command."
	exit 198
} 
else if "`estimate'"!="" & "`matrix'"!=""{
	stop "Setting both options 'estimate' and 'matrix' is not allowed."
} 

	*Stored Estimation
	if "`estimate'"!=""{
		qui estimates dir
		if regexm("`r(names)'","`estimate'"){
		qui estimates restore `estimate'
		}
		else{
			disp as error "No saved estimation result with the name `estimate' found."
			exit 198
		}
	}

	*Arbitrary matrix 
	if "`matrix'"!=""{
		capture confirm matrix `matrix'
		if _rc{
			disp as error "Matrix `matrix' does not exist."
			exit 198
		}
		else{ 
		  //Initial check if rows are correctly named as a crude check that the rows contain the expected numbers
		   local matrown : rownames `matrix'
			if "`:word 1 of `matrown''"!="b" | "`:word 2 of `matrown''"!="se" | "`:word 4 of `matrown''"!="pvalue" | "`:word 5 of `matrown''"!="ll" | "`:word 6 of `matrown''" !="ul"{
			stop "The matrix `matrix' does not have the required format. See the {help sgpv##matrix_opt:help file} for the required format and make sure that the rows of the matrix are labelled correctly."
			}
			local inputmatrix `matrix'
			*Check size of inputmatrix -> A Matrix larger than c(matsize) is not yet supported.
			if `=colsof(`matrix')'>`=c(matsize)' | `=rowsof(`matrix')'>`=c(matsize)'{
				disp as error "Matrix `matrix' is larger than the maximum allowed matrix size `c(matsize)'."
				disp as error "A  Matrix larger than `=c(matsize)' is not yet supported."
				disp as error "See {view sgpv-leukemia-example.do} for an example how to deal with such kind of matrices at the moment."
				exit 198
			}
	  }
	}
	
	*Parse alternative new syntax for entering intervals -> add exclusivity check so that only one of the ways to enter an interval is used
	*For now only parse new "null" option -> experimental change -> not sure which approach is better 
	if "`null'"!="" & ("`nulllo'"!=""|"`nullhi'"!="") stop "Values for intervals found both in option 'null' and options 'nulllo' 'nullhi'. {break} Only one way of entering intervals allowed at the same time."	
	if "`null'"!=""{
		ParseInt ,interval(`null') optname(null)
		local nulllo `r(lb)'
		local nullhi `r(ub)'
	}
		
	
	*Catch input errors when using multiple null hypotheses
	*Add checks for string input
	if `"`coefficient'"'=="" & wordcount("`nulllo'")>1{ // Allow case no coefficient set, but number of null hypotheses equals number of coefficients in estimation command? What about noconstant-option? -> Might be supported later 
		disp as error " `=wordcount("`nulllo'")' lower null-bounds and `=wordcount("`nullhi'")' upper null-bounds found but coefficient-option is empty."
		disp as error "You can use more than one null-hypothesis only if you set explicitly the coefficients with {it:coefficient}-option."
		exit 198
	} 
	 
	if `"`coefficient'"'!="" & "`nulllo'"!="" & "`nullhi'"!=""{
		if wordcount("`nulllo'")!=wordcount("`nullhi'"){
			stop "Number of lower and upper bounds for the null intervals (options 'nulllo' and 'nullhi') need to match. "
		}
		
		if wordcount(`"`coefficient'"') != wordcount("`nulllo'") & wordcount("`nulllo'")>1{
			stop "Number of null interval hypotheses bounds need to match the number of the coefficients."
		}
	}
	
	*Check for strings in the input
	forvalues i=1/`=wordcount("`nulllo'")'{
		if real("`=`=word("`nulllo'",`i')''")==. stop "Option {cmd:nulllo} needs to have a number for the lower bound number `i'."
		if real("`=`=word("`nullhi'",`i')''")==. stop "Option {cmd:nullhi} needs to have a number for the upper bound number `i'."	
	}
	
	if "`nulllo'"=="" & "`nullhi'"==""{
		local nulllo 0
		local nullhi 0
	}

	**Process fdrisk options 	
	*Nullspace option
	if "`nullhi'"!= "`nulllo'"{
		local nullspace `nulllo' `nullhi'
	}
	else if "`nullhi'"== "`nulllo'"{
		local nullspace `nulllo'
	}
	
	**Set the interval type for Fdrisk Inttype
	* Depreciated approach based on R -> will be removed after two releases
	if "`inttype'"!="" & inlist("`inttype'", "confidence","likelihood"){
		local inttype `inttype'
	}
	else if "`inttype'"!="" & !inlist("`inttype'", "confidence","likelihood"){
		stop "Parameter intervaltype must be one of the following: confidence or likelihood "
	}
	else{
		local inttype "confidence"
	}
	
	* More Stata-like documented approach
	if "`inttype'"==""{ // Make confidence the default interval type
		local inttype "confidence"
	}
	if "`likelihood'"!="" & "`matrix'"!=""{ // Allow likelihood intervals only for matrices, because likelihood intervals are not used by standard estimation commands.
		local inttype "likelihood"
	}
	else if "`likelihood'"!="" & "`matrix'"==""{
		stop "Option 'likelihood' is only allowed together with the option 'matrix'."
	}
	
	
	**Set the level of the confidence or likelihood interval: 
	*Only needed when calculating the fdr, but setting them here regardless of Fdr-calculations does not hurt.
	*Depreciated approach based on R
	if "`intlevel'"!=""{
		local intlevel = `intlevel'
	}
		
	*More Stata like approach
	if "`likelihood'"==""{
			if "`level'"!=""{
			local intlevel = 1 - 0.01*`level'
			}
			else{
				local intlevel 0.05
			}
	}
	else{
		local intlevel = `likelihood'
	}

	
	*Nullweights: 21.11.2020 -> Depreciated nullspace and nullweights option but left the code in place to not break existing code. Will be removed in another release for clearer code.
	*Not properly tested yet
	if "`nullweights'"!=""{
		local nullweights `nullweights'
	}
	else if  "`nullweights'"=="" & "`nullspace'"=="`nulllo'"{
		local nullweights "Point"
	}
	else if "`nullweights'"=="" & mod(`=wordcount("`nullspace'")',2)==0{ //Assuming that Uniform is good default nullweights for a nullspace with two values -> TruncNormal will be chosen only if explicitly set.	
		local nullweights "Uniform" 
	} 
	else if "`truncnormal'"!="" & mod(`=wordcount("`nullspace'")',2)==0{
		local nullweights "TruncNormal"
	}
	
	*Altweights
	if "`altweights'"!="" & inlist("`altweights'", "Uniform", "TruncNormal"){
		local altweights `altweights'
	}
	else if "`truncnormal'"!=""{ // Set altweights and nullweights to same distribution -> not strictly required by Blume et. al. but makes the code a bit shorter.
		local altweights "TruncNormal"	
	}
	else{
		local altweights "Uniform"
	}
	
	*Pi0
	if !(`pi0'>0 & `pi0'<1){
		stop "Values for pi0 need to lie within the exclusive 0 - 1 interval. A prior probability outside of this interval is not sensible. The default value assumes that both hypotheses are equally likely."
	}
	
	
**Parse bonus option
*Changed the default behaviour so that the option is now a bit confusing, at least the code for it.
*02.11.2020: Changed these options from one singular option to multiple optionally_on options;
*old code is kept to avoid breaking existing code,  
*no checks implemented on ensure that only one of the optionally_on options is used.
if !inlist("`bonus'","deltagap","fdrisk","all","none",""){
	stop `"Option 'bonus' is incorrectly specified. It takes only values `"none"', `"deltagap"', `"fdrisk"' or `"all"'. "'
}

if "`bonus'"=="" | "`bonus'"=="none"{ 	
	local nodeltagap nodeltagap
	local fdrisk_stat 
}

if "`bonus'"=="deltagap" | "`deltagap'"=="deltagap" {
	local nodeltagap 
	}
	
if "`bonus'"=="fdrisk" | "`fdrisk'"=="fdrisk" {
	local fdrisk_stat fdrisk
}

if "`bonus'"=="all"| "`all'"=="all"{
	local fdrisk_stat fdrisk
	local nodeltagap 
}

**Estimation command
local cmd = ustrltrim("`cmd'") // Remove trailing whitespaces which could make the second comparison fail
*Assuming that any estimation command will report a matrix named "r(table)" and a macro named "e(cmd)"
if "`cmd'"!=""{
	//Remove any level option set for the estimation command by the one for the sgpv command 
	gettoken com opt:cmd,parse(,)
	if "`com'"!="`cmd'"{
		local opt:list uniq opt // assuming that options are allowed to appear only once
		if ustrregexm("`opt'","level\(\d+\)"){
			disp "The level option of your estimation command is overwritten by the level option of the {cmd:sgpv} command." 
		}
		
		local opt = cond(ustrregexm("`opt'","level\(\d+\)"),ustrregexrf("`opt'","level\(\d+\)","level(`level')"),"`opt' level(`level')") 
		local cmd `com' `opt'
		`quietly' `cmd'
	}
	else{
		`quietly' `cmd', level(`level')
	}
	
}
else if "`e(cmd)'"!=""{ // Replay previous estimation
	quietly `e(cmd)' , level(`level')
}

*Check if the confidence level for the estimation command is different than set in the level()-option and overwrite the previously set option
if r(level)!=`level'{
	local intlevel = 1-0.01*r(level)
}
 
* disp "Start calculating SGPV"
 *Create input vectors
  tempname input  input_new sgpv pval comp rest fdrisk 
 
 *Set the required input matrix
 if "`matrix'"==""{
  capture confirm matrix r(table) //Check if required matrix was returned by estimation command
	 if _rc{
		disp as error "`e(cmd)' did not return required matrix r(table)."
		exit 198
	 }
	local inputmatrix r(table)
 }
 
 ***Input processing
 mat `input' = `inputmatrix'
 return add // save existing returned results 
 
 *Coefficient selection 
 ParseCoef `input', coefficient(`coefficient') `noconstant'
 mat `input' = r(coef_mat)
 local case `r(case)'
 local coln =colsof(`input')

*Hard coded values for the rows from which necessary numbers are extracted
*The rows could be addressed by name, but then at least Stata 14 returns a matrix
*which requires additional steps to come to the same results as with hardcoded row numbers. Unless some one complains, I won't change this restriction.
*The macros for esthi and estlo could be become too large, will fix/rewrite the logic if needed. 
*Removing not estimated coefficients from the input matrix
 forvalues i=1/`coln'{
	 if !mi(`=el(`input',2,`i')') & !mi(`=el(`input',4,`i')') { // Check here if the standard error or the p-value is missing and treat it is as indication for a variable to omit.
		local esthi `esthi' `=el(`input',6,`i')'
		local estlo `estlo' `=el(`input',5,`i')'
		mat `pval' =(nullmat(`pval')\\`input'[4,`i'])
		mat `input_new' = (nullmat(`input_new'), `input'[1..6,`i']) //Get new input matrix with only the elements for which results will be calculated

	 }
 }
  local rownames : colfullnames `input_new' //Save the variable names for later display

*Check and expand the lower and upper bounds if multiple null hypotheses are used 
if wordcount("`nullhi'")>1{
	ParseNull `input_new', coefficient(`rownames') coeforig(`coefficient') nulllo(`nulllo') nullhi(`nullhi')
	local nulllo `r(nulllo)'
	local nullhi `r(nullhi)'
	}
	
*Calculate SGPVs
qui sgpvalue, esthi(`esthi') estlo(`estlo') nullhi(`nullhi') nulllo(`nulllo') nowarnings `nodeltagap' 
if "`debug'"=="debug" disp "Finished SGPV calculations. Starting now bonus Fdr calculations."

mat `comp'=r(results)
mat colnames `pval' = "P-Value"

if "`fdrisk_stat'"=="fdrisk"{
*False discovery risks 	
	mat `fdrisk' = J(`:word count `rownames'',1,.)
	mat colnames  `fdrisk' = Fdr
	forvalues i=1/`:word count `rownames''{
		if `=`comp'[`i',1]'==0{
		if wordcount("`nullhi'")==1{
			 qui fdrisk, nullhi(`nullhi') nulllo(`nulllo') stderr(`=`input_new'[2,`i']') inttype(`inttype') intlevel(`intlevel') nullspace(`nullspace') 	nullweights(`nullweights') altspace(`=`input_new'[5,`i']' `=`input_new'[6,`i']') altweights(`altweights') sgpval(0) pi0(`pi0')
			}
		else if wordcount("`nullhi'")>1{			
			qui fdrisk, nullhi(`=word("`nullhi'",`i')') nulllo(`=word("`nulllo'",`i')') ///
			stderr(`=`input_new'[2,`i']') inttype(`inttype') intlevel(`intlevel') ///
			nullspace(`=word("`nulllo'",`i')' `=word("`nullhi'",`i')') 	nullweights(`nullweights') altspace(`=`input_new'[5,`i']' `=`input_new'[6,`i']') altweights(`altweights') sgpval(0) pi0(`pi0') 	
			}			
			capture confirm scalar r(fdr)
			if !_rc mat `fdrisk'[`i',1] = r(fdr)
				
		}
	}
}

*Final matrix composition before displaying results
 if wordcount("`nulllo'")>1  {
	 tempname  null_mat nulllo_mat nullhi_mat 
	 mat `null_mat'=J(`=wordcount("`rownames'")',2,.)
	 local nulllo_col = subinstr("`nulllo'"," ","\",.)
	 local nullhi_col = subinstr("`nullhi'"," ","\",.)
	 mat `nulllo_mat' = `nulllo_col'
	 mat `nullhi_mat' = `nullhi_col'
	 mat `null_mat'= `nulllo_mat',`nullhi_mat'
	 mat colnames `null_mat' = "Null-LB" "Null-UB"
	 mat `comp' = `comp',`null_mat'
}

if "`fdrisk_stat'"=="fdrisk"{
	mat `comp'= `pval',`comp' , `fdrisk'
}
else{
	mat `comp'= `pval',`comp'
}
 mat rownames `comp' = `rownames'

*Change the format of the displayed matrix
FormatDisplay `comp', format(`format')
*Display the results and adjust the title based on the null-hypothesis
*Modify display of results to allow multiple null hypotheses -> Not sure if displaying the null hypotheses is of great help or value

if wordcount("`nulllo'")>1{
	matlist r(display_mat) , title(`"Comparison of ordinary P-Values and Second Generation P-Values with an individual null-hypothesis for each `case' "') rowtitle(Variables) `matlistopt'
}

 if wordcount("`nulllo'")==1{
	local interval_name = cond(`nullhi'==`nulllo',"point","interval")
	local null_interval = cond(`nullhi'==`nulllo',"`nullhi'","[`nulllo',`nullhi']")
	pause before matlist
	matlist r(display_mat) , title(`"Comparison of ordinary P-Values and Second Generation P-Values for a`=cond(substr("`interval_name'",1,1)=="p","","n")'  `interval_name' Null-Hypothesis of `null_interval' based on a `=cond("`inttype'"=="confidence","`: display %6.4g 100*(1-`intlevel')'%",cond("`inttype'"=="likelihood","`intlevel'",""))' `inttype' `=cond("`inttype'"=="likelihood","support","")' interval"') rowtitle(Variables) `matlistopt'
 }


if "`nonullwarnings'"=="" & ("`nulllo'"=="0" & "`nullhi'"=="0"){
	disp _n "Warning:"
	disp "You used the default point 0 null-hypothesis for calculating the SGPVs."
	disp "This is allowed but you are strongly encouraged to set a more reasonable interval null-hypothesis."
	disp "The default point 0 null-hypothesis will result in having SGPVs of either 0 or 0.5."	
}

*return add
*Return results
return matrix comparison =  `comp'

end


*Additional helper commands (roughly ordered by appearance in the command)--------------------------------------------------------------

/*Parse a new syntax for the defining the hypotheses intervals
New syntax could be:"(lower_bound1,upper_bound1) (lower_bound2,upper_bound2)..."
Not sure which syntax use exactly if any... maybe ("lower_bound1","upper_bound1") to allow spaces in expressions
*/
capture program drop ParseInt
program define ParseInt, rclass
syntax ,INTerval(string) [optname(string)]

*Basic loop to extract the bounds from input
*Needs additional input checks but works in principal
*Does not work if input string contains a "(" -> no expressions allowed at the moment -> less powerful than existing syntax
local i 0

while "`interval'"!=""{
	local ++i	
	capture gettoken left interval:interval,match(parens)
	if _rc==132 stop "Number of left and right parentheses do not match. You may have forgotten a parenthesis somewhere. "
	if "`parens'"!="(" stop "The interval `i' in option `optname' needs to start with a '('"
	
	gettoken lb ub:left,parse(" ,")
	if real("`=`lb''")==. stop "The interval `i' in option `optname' needs to have valid number or expression after the '('."
	local lb_full `lb_full' `lb'
	
	gettoken colon ub:ub, parse(" ,")
	if "`colon'"!="," stop "The interval `i' in option `optname' needs to have ',' to separate lower and upper bound."
		
	if real("`=`ub''")==. stop "The interval `i' in option `optname' needs to have valid number or expression after the ',' to declare an upper bound."
	local ub_full `ub_full' `ub'
	
}

return local lb `lb_full'
return local ub `ub_full'
end

*Check if an interval contains missing value which are not allowed
program define IsMissing, rclass
syntax ,INTerval(string) [optname(string)]
	forvalues i=1/`=wordcount("`interval'")'{
		if real("`=word("`interval'",`i')'")==. stop "Missing value in interval `i' of option `optname' found. {break}No missing value for option `optname' allowed. One-sided intervals are not yet supported."
	}

end

*Parse the content of the coefficient-option
program define ParseCoef, rclass
	syntax name(name=matrix) [, coefficient(string asis)  noconstant ] 
	tempname coef_mat nocons_mat
	if `"`coefficient'"'==""  & "`constant'"=="" {
		return matrix coef_mat = `matrix'
		exit
	}
	 else if `"`coefficient'"'=="" & "`constant'"=="noconstant"{
		local coefficients : colfullnames `matrix'
		foreach coef of local coefficients{
			if !ustrregexm("`coef'","_cons"){
			mat `coef_mat' = (nullmat(`coef_mat'), `matrix'[1...,"`coef'"])
			} 
		}
		return matrix coef_mat = `coef_mat'
		exit
	}
		
 /* Distinguish three cases:	1. variable name only
								2. equation name only
								3. equation and variable name together
 
 */
 * No mixtures of cases allowed yet
 foreach coef of local coefficient{
	*Case 1
	if !ustrregexm("`coef'",":") & !ustrregexm("`coef'",":$"){
		local coefspec `coefspec' `coef'	
	}
	*Case 2
	if ustrregexm("`coef'",":$"){
		local eqspec `eqspec' `coef'	
	} 
	*Case 3
	if ustrregexm("`coef'",":") & !ustrregexm("`coef'",":$"){	
		local eqcoefspec `eqcoefspec' `coef'		
	}
 }
 
 *Make sure that only one specification/case is provided
 if (wordcount("`eqcoefspec'")>0 & wordcount("`eqspec'")>0) | (wordcount("`eqcoefspec'")>0 & wordcount("`coefspec'")>0) | (wordcount("`eqspec'")>0 & wordcount("`coefspec'")>0){ 
	stop `"You can only specify equation-specific (XX:YYY), equations (XX:) or general coefficients(YYY) in option {it:coefficient} at the same time."'
 }
 
 *Save specified case : 
 *Looking for the equations only needed if case 1 and set to 0 for case 2 & 3
 if (wordcount("`eqcoefspec'")>0 | wordcount("`eqspec'")>0) local coleqnumb 0
	if wordcount(`"`coefficient'"')==wordcount("`coefspec'"){ 
		local coleq : coleq `matrix'
		local coleq : list uniq coleq
		if "`coleq'"=="_" local coleqnumb 0
		else local coleqnumb = wordcount("`coleq'")
	}
	
	local coefnumb : word count `coefficient'
	if `coleqnumb'==0{ // No equations found or only fully specified coefficient names given (eq:var) Case 3 & Case 2 (eq:) 
		forvalues i=1/`coefnumb'{
			capture mat `coef_mat' = (nullmat(`coef_mat'), `matrix'[1...,"`: word `i' of `coefficient''"])
			if _rc{
				stop "Coefficient `:word `i' of `coefficient'' not found or incorrectly written."
			}			
			if "`constant'"=="noconstant" & wordcount("`eqspec'")>0 { // removing constant makes only sense for case 2
				mat `coef_mat' = `coef_mat'[1...,`=colnumb(`coef_mat',"_cons")-1']
			}
			
		}
	}
	else if `coleqnumb'>0{ // Separate equations found and only general variables given Case 1
		forvalues j=1/`coleqnumb'{
			forvalues i=1/`coefnumb'{
			capture mat `coef_mat' = (nullmat(`coef_mat'), `matrix'[1...,"`:word `j' of `coleq'':`: word `i' of `coefficient''"])
				if _rc{
					stop "Coefficient `:word `i' of `coefficient'' not found or incorrectly written."
				}
			}
		}	
	}
	
	return mat coef_mat=`coef_mat'
	return local case = cond(`=wordcount("`eqcoefspec'")>0',"coefficient",cond(`=wordcount("`eqspec'")>0',"equation","variable")) // Return case for later processing in title in case of multiple null hypotheses
	
end

*Match coefficients and null hypotheses in case of multiple null hypotheses
program define ParseNull, rclass
	syntax [name(name=matrix)], coefficient(string asis)  nulllo(string) nullhi(string) [coeforig(string asis)] 
	*Maybe use the input matrix get more information instead of the coefficient-option?
	*Count number of coefficients and compare with number of null hypotheses
	*If number of null hypotheses is not a multiple of number of coefficients, then coefficients were dropped 
	local coefn = wordcount(`"`coefficient'"')
	local coeforign = wordcount("`coeforig'")
	local nulln = wordcount("`nulllo'")	

	if `coefn'==`nulln'{ //Assuming case 1 & only single equation or 3 or no coefficients selected
		return local nulllo `nulllo'
		return local nullhi `nullhi'
		exit
	}
	else if `coefn'!=`nulln'{ //Assuming case 2 or omitted coefficients or case 1 with multiple equations		
		foreach coef of local coefficient{ //There should be a more efficient solution than looping over two lists, but it should work for now to match coefficients with null hypotheses -> maybe use ":list uniq `="
			forvalues i=1/`coeforign'{
				if ustrregexm("`coef'","`=word("`coeforig'",`i')'"){
					local nulllofull `nulllofull' `=word("`nulllo'",`i')'
					local nullhifull `nullhifull' `=word("`nullhi'",`i')'				
				}
			}
		
		}
	}

	*Case 1 "XXX" : one hypothesis -> one coefficient
	*Case 2 "XXX:" one hypothesis -> many coefficients
	*Case 3 "XXX:YYY" one hypothesis -> one coefficient
	*Return results
	return local nulllo `nulllofull'
	return local nullhi `nullhifull'
end

*Re-format the input matrix and return a new matrix to circumvent the limitations set by matlist -> using the cspec and rspec options of matlist requires more code to get these options automatically correct -> for now probably not worth the effort.
*Use round-function instead? Should result in easier and shorter code
program define FormatDisplay, rclass
syntax name(name=matrix) [, format(string)]
	if `"`format'"'==""{
		local format %5.4f
		} 
	else {
			capture local junk : display `format' 1
			if _rc {
					dis as err "Invalid %format `format'"
					dis in smcl as err "See the help file for {help format} for more information."
					exit 120
			}
		}
tempname display_mat
local display_mat_coln : colfullnames `matrix'
local display_mat_rown : rowfullnames `matrix'
mat `display_mat'=J(`=rowsof(`matrix')',`=colsof(`matrix')',.)
forvalues i=1/`=rowsof(`matrix')'{
	forvalues j=1/`=colsof(`matrix')'{
		mat `display_mat'[`i',`j']= `: display `format' `matrix'[`i',`j']'
	}

}
mat colnames `display_mat' = `display_mat_coln'
mat rownames `display_mat' = `display_mat_rown'

return matrix display_mat = `display_mat' 

end

*Simulate the behaviour of the R-function with the same name 
program define stop
 args text 
 disp as error `"`text'"'
 exit 198
end

*Make the dialog boxes accessible from the User-menu
program define menu
 syntax [, PERMdialog remove] 
 *Error checking
 if "`permdialog'"=="permdialog" & "`remove'"=="remove"{
		stop `"Only one option 'permanent' or 'remove' can be set at the same time."'
		
	}
 
 *Permanent option
 if "`permdialog'"=="permdialog"{
		capture findfile profile.do, path(STATA;.)
		if _rc{
			local replace replace
			disp "profile.do not found."
			disp "profile.do will be created in the current folder."
			disp "Move the file profile.do to a folder where Stata can find it the next time it starts."
			disp "See {help profile} for more information about where to place the profile.do"
			local profile profile.do
		}
		else{
			local replace append
			local profile `"`r(fn)'"'
			disp "Append your existing profile.do"
		}
	 
	 tempname fh
	 file open `fh' using `"`profile'"' , write text `replace'
	 file write `fh' `"window menu append submenu "stUserStatistics"  "SGPV" "' _n
	 file write `fh' `"window menu append item "stUserStatistics" "SGPV (Main Command) (&sgpv)" "db sgpv" "' _n
	 file write `fh' `"window menu append item "stUserStatistics" "SGPV Value Calculations (&sgpvalue)" "db sgpvalue" "' _n
	 file write `fh' `"window menu append item "stUserStatistics" "SGPV Power Calculations (&sgpower)" "db sgpower" "' _n
	 file write `fh' `"window menu append item "stUserStatistics" "SGPV False Confirmation/Discovery Risk (&fdrisk)" "db fdrisk" "' _n
	 file write `fh' `"window menu append item "stUserStatistics" "SGPV Plot Interval Estimates (&plotsgpv)" "db plotsgpv" "' _n
	 file write `fh' `"window menu refresh"' _n
	 file close `fh'

 }
 
 *remove option -> Read in the profile.do and write all entries which were not written by the permdialog-option -> not finished yet
 if "`remove'"=="remove"{
		capture findfile profile.do, path(STATA;.)
		if _rc==601{
			disp as error "profile.do not found. Menu entries cannot be deleted."
			exit 198
		}
	if !_rc{
			local profile `"`r(fn)'"'
			mata:pathreturn(`"`profile'"')
			local profile_new `path'\\`filename'.new
			local start_line `"window menu append submenu "stUserStatistics"  "SGPV" "'
			local end_line `"window menu refresh"'
			disp "Deleting menu entries created by the permdialog-option from your profile.do"
			tempname fh fh2 
			file open `fh' using `"`profile'"' , read text 
			file open `fh2' using `"`profile_new'"', write replace
			file read `fh' line
			while r(eof)==0{ // Skip the lines containing the window commands and write only the others back to a new file, then rename the original file to profile.do.bak and rename the new file as profile.do
				if `"`line'"'==`"`start_line'"'{
					while r(eof)==0 & `"`line'"' != `"`end_line'"'{
					file read `fh' line
					}
				
				}
				file write `fh2' `"`line'"' _n
				file read `fh' line
			}
			file close `fh'
			file close `fh2'
	}
	*plattform dependent backup file
	disp "Renaming the original profile.do to profile.do.bak"
	if strmatch(c(os),"Win*"){
		!ren "`path'\\`filename'" `filename'.bak
		!ren "`profile_new'" `filename'
		
	}
	else{ // Not testable on my system
		!mv  "`path'/`filename'" `"`path'/`filename'.bak"'
		!mv "`profile_new'" "`path'/`filename'"
	}
  exit
 }

 
 *Menu adding for one Stata session
	window menu clear // Assuming that no one else installs dialog boxes into the menubar. If this assumption is wrong then the code will be changed.
	window menu append submenu "stUserStatistics"  "SGPV"
	window menu append item "SGPV" "SGPV (Main command) (&sgpv)" "db sgpv" 
	window menu append item "SGPV" "SGPV Value Calculations (sgp&value)" "db sgpvalue"
	window menu append item "SGPV" "SGPV Power Calculations (sg&power)" "db sgpower" 
	window menu append item "SGPV" "False Confirmation/Discovery Risk (&fdrisk)" "db fdrisk" 
	window menu append item "SGPV" "SGPV Plot Interval Estimates (p&lotsgpv)" "db plotsgpv"
	window menu refresh
	disp "Menu entries succesfully created.{break}Go to User->Statistics->SGPV to access the dialog boxes for this package."
	
end


mata:
mata set matastrict on
// Split the filepath into path and filename -> convenience function to access the results of pathsplit()
void pathreturn(string scalar pathfile){

string scalar path, filename 
pragma unset path
pragma unset filename

pathsplit(pathfile,path,filename)

st_local("path" , path)
st_local("filename",filename)
}
end
