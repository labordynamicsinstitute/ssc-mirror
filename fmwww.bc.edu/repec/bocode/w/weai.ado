*! weai
*! version 1.1 08/Aug/2022
*! Author: WEAI index team

*-------------------------
*Computing Main Indicators
*------------------------- 
program define _3de_main, sortpreserve rclass
    version 14.0
   
	syntax anything(equalok)

    quietly {

	*Read in all the to-be-used locals supplied to the program.
        foreach pair in `*' {
            local eq_pos = strpos("`pair'", "=")
            local before = substr("`pair'", 1, `eq_pos'-1)
            local after  = substr("`pair'", `eq_pos'+1, .)
            local `before' = "`after'"
        }

        tempname res resV res_add resV_add
        
    *If a by-option was specified, prepare the respective statements.
        		
        if "`by'" != "" {
            local over_statement = ", over(`by', nolabel)"
        }
        else {
            local over_statement = ""
        }
	  
    *Check if all individuals are non-disempowered, as this requires additional messages below.       
		
        cap assert `_H' == 0
        if _rc == 9 {
            local warn_no_disemp = 0
        }
        else {
            error _rc
            local warn_no_disemp = 1
        }

        local main_eval = "`_H' `_M0'"
    
	*"Average Deprivation Share Among Disempowered"
        local add_eval = "(`_M0' / `_H')"

        
       *Perform the evaluation        
       `svy' mean `main_eval' `weight_exp' `l_if' `over_statement'
        matrix `res' = e(b)
        matrix `resV' = e(V)
        local N = e(N)

        *The additional variable (A) will not be by-decomposed.
		 if "`by'" == "" {
           `svy' ratio `add_eval' `weight_exp' `l_if'
            matrix `res_add' = e(b)
            matrix `resV_add' = e(V)

            local cols = colsof(`resV_add')
            forvalues i = 1/`cols' {
                forvalues j = 1/`cols' {
                    if missing(1 * `resV_add'[`i', `j']) & !missing(`resV_add'[`i', `j']) {
                       matrix `resV_add'[`i', `j'] = 0
                    }
                }
            }

    *Checking the computation: M0 = H*A
            local H = `res'[1, 1]
            local M0 = `res'[1, 2]
            local A = `res_add'[1, 1]
            capture assert abs(`M0' - `H'*`A') < `assertion_sensitivity' | (missing(`M0') | missing(`H'*`A'))
            if _rc == 9 {
                noi di as error "Computation M0 failed. M0=`M0' H=`H' A=`A'."
            }
            else {
                error _rc
            }
        }
		
    *Calculating relative results in the case of there being a by-variable.        
        if "`by'" != "" {
            *Naming the matrix (for later)
            local levelnames = e(over_namelist)

            *Estimate the relative contribution
            tempname res_perc res_percV

            *Ratios to evaluate in the end.
            local ratios = ""

            local lvl_idx = 0
            foreach i of local levelnames {
                local lvl_idx = `lvl_idx' + 1
                tempvar l_H_`lvl_idx'
                gen `l_H_`lvl_idx'' = `_H' * (`by' == `i')
                local ratios = "`ratios' (`l_H_`lvl_idx''/`_H')"
            }

            foreach i of local levelnames {
                local lvl_idx = `lvl_idx' + 1
                tempvar l_M0_`lvl_idx'
                gen `l_M0_`lvl_idx'' = `_M0' * (`by' == `i')
                local ratios = "`ratios' (`l_M0_`lvl_idx''/`_M0')"
            }

           `svy' ratio `ratios' `weight_exp' `l_if'
            matrix `res_perc' = e(b)
            matrix `res_percV' = e(V)

            local cols = colsof(`res_percV')
            forvalues i = 1/`cols' {
                forvalues j = 1/`cols' {
                    /* The entry is not missing if unmodified, but if
                       used in a formula, it becomes missing. */
                    if missing(1 * `res_percV'[`i', `j']) & !missing(`res_percV'[`i', `j']) {
                        matrix `res_percV'[`i', `j'] = 0
                    }
                }
            }

        } // End by

    *Name the absolute results created above.
        local name_main = ""
        local name_add = ""
        if "`by'" == "" {
           *Labels and output of estimate matrix.
            local by_n_1 = `"Main"'
            local by_n_2 = `"Additional"'

                local name_main = `"`name_main' "Main:H" "Main:M0" "'
                local name_add =  `"`name_add' "Additional:A" "'			
        } // End no by.
        else {
            local levels = `"`levelnames'"'
                foreach by_level of local levels {
                    local name_main = `"`name_main' "H:`by'_`by_level'" "M0:`by'_`by_level'""'
                }
        }

    *Apply the naming for the standard results.
        matrix rownames `res' = "Estimate"
        matrix colnames `res' = `name_main'
        matrix colnames `resV' = `name_main'
        matrix rownames `resV' = `name_main'

    *Additional results are only computed in the no-by case.
        if "`by'" == "" {
            matrix rownames `res_add' = "Estimate"
            matrix colnames `res_add' = `name_add'
            matrix colnames `resV_add' = `name_add'
            matrix rownames `resV_add' = `name_add'
        }
    *Relative contributions only matter in the by-case.
        else {
            matrix rownames `res_perc' = "Estimate"
            matrix colnames `res_perc' = `name_main'
            matrix colnames `res_percV' = `name_main'
            matrix rownames `res_percV' = `name_main'
        }
       
     *Return results.
        return matrix weai_main = `res'
        return matrix weai_main_V = `resV'
        if "`by'" == "" {
            return matrix weai_add = `res_add'
            return matrix weai_add_V = `resV_add'
        }
        else {
            return matrix weai_perc = `res_perc'
            return matrix weai_perc_V = `res_percV'
            return local over_namelist `levelnames'
        }
        return scalar N = `N'
    
	} // End quietly
	ereturn clear
end

*-------------------------------
*Decomposition of M by Indicator
*-------------------------------
program define _3de_domains, sortpreserve rclass
    version 14.0
   
	syntax anything(equalok)
    quietly {
    *Read in all the to-be-used locals supplied to the program.
        foreach pair in `*' {
            local eq_pos = strpos("`pair'", "=")
            local before = substr("`pair'", 1, `eq_pos'-1)
            local after  = substr("`pair'", `eq_pos'+1, .)
            local `before' = "`after'"
        }

    *If a by-option was specified, prepare the respective statements.

	   if "`by'" != "" {
            local over_statement = ", over(`by', nolabel)"
        }
        else {
            local over_statement = ""
        }

        tempname m m_C m_V m_C_V

        local tot_m0_shares = 0
		local prev_ind = 0

        *The ratios to finally evaluate.
        local eval_ratio = ""
        local eval_ratios = ""		

        *Iterate over domains
		tempname m_decomp
        forvalues j = 1 / `ndom' {
            local nind`j' = wordcount("`d`j''")
			tempname m_decomp_`j'

         
            *Iterate over indicators, create the to-be-estimated variables.
            forvalues i = 1 / `nind`j'' {
                local w = word("`w`j''", `i')
                local ind = word("`d`j''", `i')

                tempname m_`j'_`i' m_C_`j'_`i' M_temp_`j'_`i'
				g `M_temp_`j'_`i''=1
				
                generate `m_`j'_`i''   = (`isinadequate_`j'_`i''==1  & empowered==0)*100 
                generate `m_C_`j'_`i'' = (`isinadequate_`j'_`i''==1  & empowered==0) 	
				
                local eval_ratio  = "`eval_ratio' (`m_`j'_`i'' / `_M0')"			
                local eval_ratios = "`eval_ratios' (`m_C_`j'_`i''/ `M_temp_`j'_`i'')"			 				
            }
			   
        } // End iterating over domains
		
    *Calculating ratios.
       `svy' ratio `eval_ratio' `weight_exp' `l_if' `over_statement'
        matrix `m' = e(b)
        matrix `m_V' = e(V)

        local cols = colsof(`m')
        forvalues i = 1/`cols' {
            forvalues j = 1/`cols' {
                *The entry is not missing if unmodified, but if
                *used in a formula, it becomes missing.
                if missing(1 * `m_V'[`i', `j']) & !missing(`m_V'[`i', `j']) {
                    matrix `m_V'[`i', `j'] = 0
                 }
            }
        }		
						
       `svy' ratio `eval_ratios' `weight_exp' `l_if' `over_statement'		
        matrix `m_C' = e(b)				
        matrix `m_C_V' = e(V)
		
        local colsc = colsof(`m_C')
        forvalues i = 1/`colsc' {
            forvalues j = 1/`colsc' {
                *The entry is not missing if unmodified, but if
                *used in a formula, it becomes missing.
                if missing(1 * `m_C_V'[`i', `j']) & !missing(`m_C_V'[`i', `j']) {
                    matrix `m_C_V'[`i', `j'] = 0
                 }
            }
        }
 
        *Naming the matrix (for later)
        local levelnames = e(over_namelist)
        
		tempname mat_weights
        local n_levels = cond("`by'" == "", 1, wordcount(`"`=e(over_namelist)'"'))
		
        local size = `ni' * `n_levels'		
        matrix `mat_weights' = J(`size', `size', 0)
        local idx = 0
        forvalues j = 1 / `ndom' {
            forvalues i = 1 / `nind`j'' {		
		      local iterate = "0"
                foreach a of local iterate {
                    forvalues level = 1 / `n_levels' {
                        local idx = `idx' + 1
                        matrix `mat_weights'[`idx', `idx'] = `=word("`w`j''", `i')'
                    }
                }
            }
        }
	
        matrix `m'   = `m' * `mat_weights'
        matrix `m_V' = `mat_weights'' * `m_V' * `mat_weights'

        matrix `m_C' = `m_C' * `mat_weights'
		matrix `m_C_V' = `mat_weights'' * `m_C_V' * `mat_weights'
		
        if "`by'" == "" {
            local levels = `" "" "'
        }
        else {
            local levels = `"`levelnames'"'
        }

        *Holds the names for the estimated matrices.
        local names = ""
        
        *Iterate over domains/indicators, create the labels.       
        forvalues j = 1 / `ndom' {
            forvalues i = 1 / `nind`j'' {
                local ind = word("`d`j''", `i')

                   *Create the names for each indicator within each domain

                    foreach by_level of local levels {
                        *Labels and output of estimate matrix.
                        if `"`by_level'"' != "" {
                            local by_n = `"`by'_`by_level':"'
                        }
                        else {
                            local by_n = `""'
                        }
                        local names = `"`names' "`by_n'`ind'_M0""'
                    } // Iterating over by-levels (if they exist)
				
            } // Iterating over indicators
        } // Iterating over domains.

       *Put the names.
        matrix colnames `m' = `names'
        matrix colnames `m_V' = `names'
        matrix rownames `m_V' = `names'

        matrix colnames `m_C' = `names'				
        matrix colnames `m_C_V' = `names'
        matrix rownames `m_C_V' = `names'
		
        return matrix weai_decomposed = `m'	
        return matrix weai_decomposed_V = `m_V'
        return matrix weai_decomposed_C = `m_C'	
        return matrix weai_decomposed_C_V = `m_C_V'
		
        if "`by'" != "" {
            return local over_namelist `levelnames'
        }
    } // End quietly
    ereturn clear
end

*----------------------------------------
*Get matrix rownames for labelling graphs
*----------------------------------------
capture program drop getRowName
 program define getRowName, rclass
    version 14.0
	 
	 local thismatrix="`1'"
	   local rowindex=`2'
	   matrix TWO= `thismatrix', `thismatrix'
	   matrix TEMPORARY=TWO[`rowindex',1..2]
	   local rowname: rownames TEMPORARY
	   return local matrixname="`thismatrix'"
	   return scalar rowindex=`rowindex'
	   return local rowname = "`rowname'"
	   ereturn clear
 end

*-----------------
*Full weai program
*-----------------
program weai, sortpreserve eclass
    version 14.0

    cap syntax anything  [if] [in] [pw fw],  Sex(varname) Female(integer) HHid(varname) ///
              [Cutoff(real .8) by(varname) Svy SUBpop(passthru) Details Save(string) Graph(string)] 		 
		
    *Take care of error messages when calling weai through bootstrap.
    if _rc == 100 {
        local cmd = e(cmd)
        if `"`cmd'"' == "weai" {
            noi display as text "Replaying last e(b) / e(V) results as weai was started without options."
            noi display as text "This is normal for {help bootstrap}. Otherwise, see {help weai} on how to specify options."
			
            if _rc == 1 {
                error 1
            }
            else if _rc != 0 {
                noi _coef_table
            }
            exit
        }
        else {
            error _rc
        }
    }
    else {
		
        syntax anything  [if] [in] [pw fw], Sex(varname) Female(integer) HHid(varname) ///
               [Cutoff(real .8) by(varname) Svy SUBpop(passthru) Details Save(string) Graph(string)]  			
    }
	
		
quietly {
	
    *Checking for computation of the index for each category of by the option.		
      if ("`by'" != "")   {
	  levelsof `by' `l_if', local(by_levels)      
	  foreach by_s of local by_levels {
	      
	     levelsof `sex', local(gender_cat)    
		   foreach g_cat of local gender_cat {
		     count if `by'==`by_s' & `sex'==`g_cat'
		   if r(N)<2 {
            noi display in gr "Warning: There are not enough observations." 
			noi display in gr "The indicator cannot be calculated for the category `by_s' of the by option and the option `g_cat' of the gender variable."            
             		
		   exit, clear
		   }
		}	            
	}
}		
		
		
*Check if "sex" variable has more than two values
	levelsof `sex', local(sex_count)
		if `r(r)' > 2 {
			noi display in gr "Error: Variable `sex' should have only two values."
			exit, clear
		}

*Get unique values of the "Sex" variable
   *local female 2
	foreach value of  local sex_count {
		if `value' != `female' {
			local male `value'
			break
		}
	}
	
		putdocx clear
		putdocx begin, pagesize(letter) font(Aptos, 12, black)		

        *Globally required names present everywhere
        tempvar sweight dscore _H _M0

        local var_submit = `"sweight=`sweight'"'
        local var_submit = `"`var_submit' dscore=`dscore'"'
        local var_submit = `"`var_submit' _H=`_H'"'
        local var_submit = `"`var_submit' _M0=`_M0'"'

        *Mark sample
        marksample touse

        *Prepare weights
        if "`exp'" != "" {
            generate `sweight' `exp'
        }
        else {
            generate `sweight' = 1
        }
        if "`weight'`exp'" != "" {
            local weight_exp = "[`weight'`exp']"
        }
        else {
            local weight_exp = ""
        }
				
        // Prepare svy usage
        if "`svy'" != "" {
            // Standard If and In are not allowed with svy.
            if "`if'" != "" & "`in'" != "" {
                noi display as error "Error: The svy option cannot be combined with if and in. Use the extended svy option."
                error 101
            }
            else if "`if'" != "" {
                noi display as error "Error: The svy option cannot be combined with if. Use the extended svy option."
                error 101
            }
            else if "`in'" != "" {
                noi display as error "Error: The svy option cannot be combined with in. Use the extended svy option."
                error 101
            }
            else if `"`subpop'"' != "" {
                // Get content between braces for subpop clause.
                local firstbrace = strpos(`"`subpop'"', "(")
                local lastbrace = -1
                forvalues i = 1/`=strlen(`"`subpop'"')' {
                    if substr(`"`subpop'"', `i', `i'+1) == ")" {
                        local lastbrace = `i'
                    }
                }
                // If the subpop clause is a variable, change it into an if statement.
                local subpop_clause = substr(`"`subpop'"', `firstbrace'+1, `lastbrace'-`firstbrace'-1)
                capture confirm variable `clause'
                if _rc == 0 {
                    local clause = `"if `clause'"''
                }

                local subpop_clause = substr(`"`subpop'"', 1, `firstbrace') + `"`clause'"' + substr(`"`subpop'"', `lastbrace', .)
                local svy = `"svy, `subpop': "'
            }
            else {
                local svy = "svy:"
            }
            local l_if = ""
        }
        // Standard: no svy, if as in touse
        else {
            local svy = ""
            local l_if = "if `touse'"
        }

        if `"`subpop'"' != "" & "`svy'" == "" {
            noi display as error "Error: The subpop option requires the svy option to be specified."
            error 101
        }
		
		
        *As long as no weight information is given, assume weighting to be equal.
        local equalw = 1

        *Maximum Variable Length - to be generated later
        local max_var_length = -1

        *Sensitivity for all assumptions
        local assertion_sensitivity = 0.00001

        *To compute:
          *Number of indicators
        local ni = 0
          *Number of domains
        local ndom = 0
          * nidX: Number of indicators in each domain
          * dX: Domain X
          * wX: Weights X
        local use_thresholds = 0
		 
        while strpos("`anything'", ")") > 0 {
            local entry = trim(substr("`anything'", 1, strpos("`anything'", ")")))
            local anything = substr("`anything'", strpos("`anything'", ")") + 1, .)
            *Argument type should be "w" or "d"
            local argtype = lower(substr(trim("`entry'"), 1, 1))
			
			if !(inlist("`argtype'", "w", "weight", "d", "dom", "domain") ) {
                noi display as error "Only domains (d) or weights (w) can be supplied. Found: '`argtype'"
            }			
			
            *Get the number of weight / indicator
            local brstartpos = strpos("`entry'", "(")
            local idx = trim(substr("`entry'", 2, `brstartpos'-2))
            capture confirm number `idx'
            if _rc != 0 {
                noi display as error "Argument '`entry'' did not follow the proper form, after d/w should follow the index."
                error 197
            }
            else {
                error _rc
            }
			
            *Get content of brackets
            local inbr = substr("`entry'", `brstartpos' + 1, strpos("`entry'", ")") - `brstartpos' - 1)
            *Check that the variables exist if it is a domain
            if "`argtype'" == "d" | "`argtype'" == "dom" | "`argtype'" == "domain" {
                local count_ind = 0
                unab inbr : `inbr'
                foreach d of varlist `inbr' {
                    confirm var `d'
                    local count_ind = `count_ind' + 1
                    local max_var_length = max(`max_var_length', strlen("`d'"))
                }
                *Save the number of indicators for this domain
                local nid`idx' = `count_ind'
                local ni = `ni' + `nid`idx''
                local argtype = "d"
            }
            if "`argtype'" == "w" | "`argtype'" == "weight" {
                foreach w of local inbr {
                    confirm number `w'
                }
                local equalw = 0
                local argtype = "w"
            }
 
            *Set weight / indicator
            local `argtype'`idx' = "`inbr'"
            local ndom = max(`idx', `ndom')
        }

    *Make sure that at least 1 domain is specified.
        if `ndom' <3 {
            noi display as error "At least 3 empowerment domains should be specified"
            error 197
        }

    *Make sure that no domains or weights are missing
        forvalues idx = 1/`ndom' {
            if ("`d`idx''" == "") {
                noi display as error "Deprivation domain `idx' not specified"
                error 197
            }
            if (`equalw' == 0) & ("`w`idx''" == "") {
                noi display as error "Weight `idx' not specified."
                error 197
            }
            if (`equalw' == 0) & (wordcount("`w`idx''") != `nid`idx'') {
                noi display as error "Vector w`idx'(`w`idx'') does not have the same number of elements as the number of indicators in domain d`idx'(`d`idx'')"
                error 197
            }
        }

	*So far all_indicators were defined so 1 identifies adequate
	*Now we transform indicators so 1 identifies inadequate.		
		
		forvalues j=1/`ndom' {
            foreach ind of varlist `d`j'' {
		    recode `ind' (1=0) (0=1) 
			}
		}			
    *Make sure that alpha does not include 0, 1 and 2, they are computed by default.
        local newalpha = ""
        foreach a of local alpha {
            if !inlist(`a', 0, 1, 2) {
                local newalpha = "`newalpha' `a'"
            }
        }
        local alpha = "1 2 `newalpha'"

        *Check if any observations are left
        tempname all_missing
        gen `all_missing' = 0
        forvalues i = 1 / `ndom' {
            foreach vari of varlist `d`i'' {
                replace `all_missing' = `all_missing' | missing(`vari')
            }
        }
        if "`by'" != "" {
            replace `all_missing' = 1 if missing(`by') & `touse'
        }
        count if `all_missing' & `touse'
        if r(N) == _N {
            *No observations
            error 2000
        }

        *Exclude missing values from the estimation sample
        count if `all_missing' == 1
        if r(N)>0 {
            noi display in gr "Note: Missing values encountered, excluding them."
            recode `all_missing' 1=.
            markout `touse' `sweight' `all_missing'
        }
        *drop `all_missing'

        *If equal weighting is specified, assign equal weights for every indicator.
        
		*Default for the orignal WEAI       
		if `equalw' & `ndom'==5 {
            local domshare = 1 / `ndom'
            forvalues i = 1 / `ndom' {
                local w`i' = ""
                local indshare = `domshare'/`nid`i''
                forvalues j = 1/`nid`i'' {
                    local w`i' = "`indshare' `w`i''"
                }
            }
        }

        *Default for the Abbreviated WEAI (A-WEAI)      
		if `equalw' & `ndom'==5 & `ni'==6 {
            local domshare = 1 / `ndom'
            forvalues i = 1 / `ndom' {
                local w`i' = ""
                local indshare = `domshare'/`nid`i''
                forvalues j = 1/`nid`i'' {
                    local w`i' = "`indshare' `w`i''"
                }
				local w2="0.13333 0.06667"
            }					
		}		
		
	    *Default for pro-WEAI       
        *If equal weighting is specified, assign equal weights for every indicator.
        if `equalw' & `ndom'==3 {
            forvalues i = 1 / `ndom' {
                local w`i' = ""
                local indshare = 1 / `ni'
                forvalues j = 1/`nid`i'' {
                    local w`i' = "`indshare' `w`i''"
                }
            }
        }		

		
        confirm number `cutoff'
				
        * Check that relevant variables are numeric and get the number of missing values
        * Check that each variable contains only 0, 1 and missing entries
        forvalues j=1/`ndom' {
            foreach ind of varlist `d`j'' {
                capture confirm numeric variable `ind'
                if _rc != 0 {
                    noi display as error "Variable `ind' is not numeric."
                    exit 459
                }
                else {
                    error _rc
                }
				
                * If no thresholds are used, 0 is adequate and 1 is inadequate. Hence,
                * check that the variable contents match to the case.
                    capture assert inlist(`ind', 0, 1) | missing(`ind') | !`touse'
                    if _rc == 9 {
                        noi display as error "Variable `ind' contains values besides " ///
                            "0, 1 and missing. Supply indicators containing 1 for adequate " ///
                            "and 0 for inadequate individuals."
                        exit 459
                    }
                    else {
                        error _rc
                    }		
            }
        }

        *Check if the supplied domainal weights add up to one:
        local totwcheck = 0
        forvalues j = 1/`ndom' {
            local countw = 1
            foreach ind of varlist `d`j'' {
                local w = word("`w`j''", `countw')
                local totwcheck = `totwcheck' + `w'
                local countw = `countw' + 1
            }
        }
        if abs(`totwcheck' - 1) > .01 {
            noi display in re "Total sum of weight is " _c
            noi display in ye `totwcheck' in re ", it should be 1."
            error 9
        }
        *If the difference between the weights is close to 1, scale them and the
        *cutoff to remove even the slight differences.
        else if abs(`totwcheck' - 1) > `assertion_sensitivity' {
            noi display in ye "Note: the total sum of weight was close to 1, the weights and the cutoff were rescaled to add up to exactly 1."
            forvalues j = 1/`ndom' {
                local new_weight = ""
                local countw = 1
                foreach ind of varlist `d`j'' {
                    local w = word("`w`j''", `countw')
                    local w  = `w' / `totwcheck'
                    local new_weight = "`new_weight' `w'"
                    local countw = `countw' + 1
                }
                local w`j' = "`new_weight'"
            }
            local cutoff = `cutoff' / `totwcheck'
        }

        if `totwcheck' < `cutoff' & "`noinitialcall'" == "" {
            noi display in re "Attention, cutoff is larger than the sum of weights. " _c
            noi display in ye "(C: `cutoff' W: 1). " _c
            noi display in re "No individual could possibly be empowered."
        }

        *Create matrix of deprivation domains and overall deprivation score      
		foreach a of local alpha {
            local a_name = subinstr("`a'", ".", "p", .)
            local a_name = subinstr("`a_name'", "-", "m", .)
            tempname gap_`a_name'
            generate `gap_`a_name'' = 0
            local var_submit = `"`var_submit' gap_`a_name'=`gap_`a_name''"'
        }
		
        generate `dscore' = 0
        forvalues j = 1/`ndom' {
            tempvar wdom`j'
			
            foreach a of local alpha {
                local a_name = subinstr("`a'", ".", "p", .)
                local a_name = subinstr("`a_name'", "-", "m", .)
                tempvar gap`j'_`a_name'
                generate `gap`j'_`a_name'' = 0
                local var_submit = `"`var_submit' gap`j'_`a_name'=`gap`j'_`a_name''"'
            }
			
            generate `wdom`j'' = 0
            c_local wdom`j' "`wdom`j''"
            local nind`j' = wordcount("`d`j''")
            forvalues i = 1 / `nind`j'' {
                local w = word("`w`j''", `i')
                local ind = word("`d`j''", `i')
                local threshold = word("`thres`j''", `i')

                tempvar isinadequate_`j'_`i'
                generate `isinadequate_`j'_`i'' = (`ind'== 1) if !missing(`ind')               
				local var_submit = `"`var_submit' isinadequate_`j'_`i'=`isinadequate_`j'_`i''"'
                replace `wdom`j'' = `wdom`j'' + `isinadequate_`j'_`i''*`w'
				
            }
            replace `dscore' = `dscore' + `wdom`j''
            foreach a of local alpha {
                local a_name = subinstr("`a'", ".", "p", .)
                local a_name = subinstr("`a_name'", "-", "m", .)
                replace `gap_`a_name'' = `gap_`a_name'' + `gap`j'_`a_name''
            }
        }

        foreach a of local alpha {
            local a_name = subinstr("`a'", ".", "p", .)
            local a_name = subinstr("`a_name'", "-", "m", .)
            replace `gap_`a_name'' = 0 if `dscore' < `cutoff'
        }
     format `dscore' %8.2f
     generate `_H' = (`dscore' > (1 - `cutoff')) if !missing(`dscore')

    **Drop added variables in order to avoid error when re-runing the command in the same dataset
    local var empowered emp_score hh_ineq gender_parity emp_index gpi weai emp_score emp_score_ empowered  
	foreach x in `var' {
		capture	drop `x'
			*exit 111	
		}

    *Generate Adjusted Multidimensional Deprivation Headcount (M0)
        generate `_M0' = cond(`_H' > 0, `dscore', 0)
        
		generate emp_score=1-`dscore' if !missing(`dscore') & `touse'
		lab var  emp_score "Empowerment Score"
		replace  emp_score=0 if emp_score <.0006
		
		generate empowered =(emp_score>=`cutoff'-0.0001) if !missing(emp_score) & `touse'
		lab var  empowered "Empowered"
        
		`svy' mean empowered if `touse'
		 matrix empow = e(b)
		
    *Mean disempowerment score among the disempowered
		`svy' mean `dscore' if empowered==0 & `touse'
		 matrix empscore =e(b)
 		 *matrix empscore = 1-e(b)

    *Return all locals generated over the course of the program.
          
		foreach loc_name in weight_exp  equalw max_var_length assertion_sensitivity ///
                            ni ndom use_thresholds alpha level svy touse l_if  {
            local var_submit = `"`var_submit' "`loc_name'=``loc_name''" "'
        }
				
        forvalues i = 1 / `ndom' {
            local var_submit = `"`var_submit' "d`i'=`d`i''""'
            local var_submit = `"`var_submit' "w`i'=`w`i''""'
            local var_submit = `"`var_submit' "nind`i'=`nind`i''""'
            local var_submit = `"`var_submit' "vartype`i'=`vartype`i''""'
        }

        *A is a local for naming mata matrices, res for temporarily saving results.
        tempname res A lgender

		lab def `lgender' `female' Women `male' Men, replace
		lab val `sex'  `lgender' 		
*-------------------------------------------------------------------------------
*Computing Main Indicators
*-------------------------------------------------------------------------------
    
    *Check if all individuals are non-disempowered, as this requires additional messages below.
	
      cap assert `_H' == 0
        if _rc == 9 {
            local warn_no_disemp = 0
        }
        else {
            error _rc
            local warn_no_disemp = 1
        }
		 
        noi _3de_main `"`var_submit'"'

        tempname hm_1 hm_2 hm_V_1 hm_V_2

        matrix `hm_1' = r(weai_main)
        matrix `hm_V_1' = r(weai_main_V)
        matrix `hm_2' = r(weai_add)
        matrix `hm_V_2' = r(weai_add_V)
        local N = r(N)
		 
    *Intermission: Display the results.
        tempname sum_main sum_main_sex disp_b disp_V tmp

        local hm_1_col = colsof(`hm_1')
        local hm_2_col = colsof(`hm_2')
        matrix `disp_b' = `hm_1', `hm_2'
        matrix `tmp' = J(`hm_1_col', `hm_2_col', 0)
        local names : colfullnames `hm_1'
        matrix rownames `tmp' = `names'
        local names : colfullnames `hm_2'
        matrix colnames `tmp' = `names'
        matrix `disp_V' = (`hm_V_1', `tmp')
        matrix `disp_V' = `disp_V' \ (`tmp'', `hm_V_2')

        local n_string = "N = `N'"
        local len_n_string = strlen("`n_string'")
        
		* 5/3DE score
		matrix DE= 1-(empscore*(1-empow))
		
		matrix `sum_main'=(`N'\DE \ 100*(1-empow) \ empscore)
		matrix rownames `sum_main'="Number of observations" "5/3DE score" "% Not Achieving empowerment (H)"  "Mean disempowerment score (A)"
		matrix colnames `sum_main'=""
		
	
	* Individual level Indicators
	 *Individual 5/3DE score
		generate emp_index= 1-(`dscore'*(1-empowered))
		lab var  emp_index "Individual 5/3DE Index" 
						
	    tempvar disemp
		gen `disemp'=.
		local sexs `female' `male'
		foreach s of local sexs {
		     
 preserve		    
		
		keep if `sex'==`s' & `touse'
        cap assert `_H' == 0
        if _rc == 9 {
            local warn_no_disemp = 0
        }
        else {
            error _rc
            local warn_no_disemp = 1
        }

        noi _3de_main `"`var_submit'"'

        tempname hm_1_`s' hm_2_`s' hm_V_1_`s' hm_V_2_`s'

        matrix `hm_1_`s'' = r(weai_main)
        matrix `hm_V_1_`s'' = r(weai_main_V)
        matrix `hm_2_`s'' = r(weai_add)
        matrix `hm_V_2_`s'' = r(weai_add_V)
        local N = r(N)
        matlist `hm_1_`s''
		matlist `hm_2_`s''

    *Intermission: Display the results.
       
		tempname sum_main_`s' disp_b_`s' disp_V_`s' tmp_`s'

        local hm_1_col_`s' = colsof(`hm_1_`s'')
        local hm_2_col_`s' = colsof(`hm_2_`s'')
        matrix `disp_b_`s'' = `hm_1_`s'', `hm_2_`s''
        matrix `tmp_`s'' = J(`hm_1_col_`s'', `hm_2_col_`s'', 0)
        local names_`s' : colfullnames `hm_1_`s''
        matrix rownames `tmp_`s'' = `names_`s''
        local names_`s' : colfullnames `hm_2_`s''
        matrix colnames `tmp_`s'' = `names_`s''
        matrix `disp_V_`s'' = (`hm_V_1_`s'', `tmp_`s'')
        matrix `disp_V_`s'' = `disp_V_`s'' \ (`tmp_`s''', `hm_V_2_`s'')

        local n_string = "N = `N'"
        local len_n_string = strlen("`n_string'")

		
	*Index by sex	
	   `svy' mean empowered if `sex'==`s' & `touse'
		matrix empow_`s' = e(b)
		
		*Mean empowerment score among the disempowered
	   `svy' mean emp_score if `sex'==`s'  & empowered==0 & `touse'
		matrix empscore_`s' = 1-e(b)
		
		
		matrix DE_`s'= 1-(empscore_`s'*(1-empow_`s'))		
		matrix `sum_main_`s''=(`N'\DE_`s'\ 100*(1-empow_`s')\ empscore_`s')
		
		local vlname: value label `sex'
        local vl_`s': label `vlname' `s'
		matrix colnames `sum_main_`s'' = `vl_`s''
		
		if `female'==`s' {
			local emp = DE_`s'[1,1]
		} 
		
		matrix `sum_main_sex' = (nullmat(`sum_main_sex'), `sum_main_`s'')		
  restore		
		}

		matrix rownames `sum_main_sex'="Number of observations" "5/3DE score" "% Not Achieving empowerment (H)"  "Mean disempowerment score (A)"
		
        if `warn_no_disemp' == 1 {
            error _rc
            noi di as result "Note: No individual is multidimensionally deprived."
        }
        noi display as text ""
*-------------------------------------------------------------------------------
*GPI
*------------------------------------------------------------------------------- 		
preserve
	
	forvalues j = 1 / `ndom' {
            local nind`j' = wordcount("`d`j''")
            forvalues i = 1 / `nind`j'' {
                g we_`j'_`i' = word("`w`j''", `i')
				destring we_`j'_`i', replace
                local ind = word("`d`j''", `i')
				gen double wg0_`ind'= `ind'*we_`j'_`i' 
            }
        }						

    *If a by-option was specified, prepare the respective statements.
   
        if "`by'" != "" {
            local over_statement = ", over(`by', nolabel)"
        }
        else {
            local over_statement = ""
        }
	
        drop if `all_missing'
		
	** Focus on male and female households
        tempname n i ci
		sort `hhid' `sex'
		bys `hhid': gen `i'=_n if `touse'
		bys `hhid': egen `n'=max(`i') if `touse'

		*tab hh_type n, miss
		keep if `n' ==2 & `touse'
		egen double `ci'=rsum(wg0_*)
		tempname n_missing
		egen `n_missing'=rowmiss(wg0_*)
		*drop if `n_missing'>0

		replace `ci'=round(`ci', 0.0001)
		label variable `ci' "Inadequacy Count without Parity"
		
********************************************
*** Compute censored inadequacy scores  ***
********************************************
        tempvar w_ci_id m_ci_id W_ci M_ci W_cen_ci M_cen_ci

		bys `hhid': gen double `w_ci_id'=`ci' if `sex'==`female' 
		bys `hhid': gen double `m_ci_id'=`ci' if `sex'==`male' 
		bys `hhid': egen double `W_ci'=max(`w_ci_id')
		bys `hhid': egen double `M_ci'=max(`m_ci_id')
		drop `w_ci_id' `m_ci_id'

		bys `hhid': gen double `W_cen_ci'=`W_ci'
		bys `hhid': replace    `W_cen_ci'=(1-`cutoff') if (`W_cen_ci'<=(1-`cutoff') & `W_cen_ci'!=.)
		
		bys `hhid': gen double `M_cen_ci'=`M_ci'
		bys `hhid': replace    `M_cen_ci'=(1-`cutoff') if (`M_cen_ci'<=(1-`cutoff') & `M_cen_ci'!=.)	
				
		bys `hhid': gen hh_ineq=(`W_ci'-`M_ci')
	    label var hh_ineq "Intra-household inequality score"
			
******************************************************
*** Identify inadequate in terms of gender parity  ***
******************************************************
        tempvar ci_above
		bys `hhid': gen `ci_above'=(`W_cen_ci'>`M_cen_ci' )
		bys `hhid': replace `ci_above'=. if (`W_cen_ci'==. | `M_cen_ci'==.)
		
		label var `ci_above' "Equals 1 if individual lives in MF hh where the depr score of the woman is higher than the man - EI 1"		
		
		gen gender_parity=1-`ci_above' if `ci_above'!=. 
		replace gender_parity=1 if gender_parity==0 & empowered==1 & `sex'==`female' 
		
		tempvar max_gpi
		bys `hhid': egen `max_gpi'=max(gender_parity) if !missing(gender_parity)
		bys `hhid': replace gender_parity=`max_gpi'   if !missing(gender_parity)
		
		replace `ci_above'=0 if `ci_above'==1 & gender_parity==1 & `sex'==`female' 		
    	label var gender_parity "Household achieves Gender Parity"
		
************************************
*** Compute Gender Parity Index  ***
************************************
        tempvar females IndP1 women_n inadequate inadequate_n ci_gap ci_gap_sum ci_average
		
		** Full sample
		gen  `females'=(`sex'==`female' & `ci_above'!=.)
		egen `women_n'=total(`females')
		drop `females'

		** Headcount ratio of inadequate women
		tempvar H
		gen  `inadequate'=(`ci_above'==1 & `sex'==`female')
		egen `inadequate_n' = total(`inadequate')
		gen  `H'=`inadequate_n'/`women_n' // Considering unweighted sample
		

		** Computation of normalized gap
		qui gen `ci_gap'=(`W_cen_ci'-`M_cen_ci')/(1-`M_cen_ci') if (`ci_above'==1 & `sex'==`female') 
		egen `ci_gap_sum' = total(`ci_gap')
		gen `ci_average'=`ci_gap_sum'/`inadequate_n'

		** Computation of GPI
		tempvar  H_GPI P1 GPI
		gen `H_GPI'=`inadequate_n'/`women_n'
		gen `P1'   =`H_GPI'*`ci_average'
		gen `GPI'  =1-`P1'
        

		** Individual level GPI computation //added
		g `IndP1'=`ci_above' * `ci_gap'
		replace `IndP1'=0 if `ci_above'==0
		g gpi=1-`IndP1' if `sex'==`female' 
		
		lab var gpi "Individual-level GPI"
		
**************************
*** Summarize results  ***
**************************
	   `svy' mean `H_GPI' `ci_average' `P1' `GPI' if `touse'
	
		*** CREATE DUAL-HEADED HOUSEHOLD VARIABLE *** 	
		tempvar temp temp1 dahh
		bysort `hhid': egen `temp' = max(`n_missing')   // This looks at if either respondent in a hh has missing indicators
		gen    `temp1'=1 if (`sex'==`male' & `temp'==0) // Indicator varible for men in HHs where both respondents have all indicators 
		egen   `dahh' =total(`temp1')                   // Count HHs where both respondents have all indicators
		
	   `svy' mean `dahh' if `touse'		
		matrix Ndh = e(b)

	   `svy' mean `GPI' `H_GPI' `ci_average' if `touse'
		matrix gend = e(b)
		
		local par=gend[1,1]
		local weai_ind=(0.1*`par') + (0.9*`emp')
		

       `svy' mean hh_ineq if `touse'
		matrix a_hh_ineq= e(b)
		matrix gend_p =(Ndh \ gend[1,1]\ 100*gend[1,2]\ gend[1,3] \ `weai_ind')
		matrix rownames gend_p="Number of dual households" "Gender Parity Index (GPI)" "% Without gender parity (HGPI)" "Mean empowerment gap (IGPI)" "WEAI/A-WEAI/pro-WEAI"

		*Individual level Indicators
		g weai=(0.1*gpi) + (0.9*emp_index) if `sex'==`female'
		lab var weai "Individual-level pro-WEAI"
	
		tempfile tmpdata
		save `tmpdata', replace
restore

       merge 1:1 `hhid' `sex' using `tmpdata', keepusing(gender_parity hh_ineq gpi weai)
	   cap drop _m 
*-------------------------------------------------------------------------------
*Table 1
*-------------------------------------------------------------------------------		
        local rname : colfullnames `sum_main_sex'

		matrix gendd=(.\.\.\.\.)
		matrix gend_p=(gend_p,gendd)
	    
		matrix indices= (`sum_main_sex'\ gend_p)
        matrix indices= (indices[9,1..2]\indices[2,1..2]\indices[6,1..2]\indices[3,1..2]\indices[4,1..2]\indices[7,1..2]\indices[8,1..2]\indices[5,1..2]\indices[1,1..2])
						
		matrix colnames indices = `rname'
		matrix rownames indices = "WEAI/A-WEAI/pro-WEAI" "5/3DE Index" "Gender Parity Index (GPI)" /// 
		                          "% Not achieving empowerment (H)"  "Mean disempowerment score (A)*" "% Without gender parity (HGPI)" /// 
								  "Mean empowerment gap (IGPI)" "Number of dual households" "Number of observations"
		
		noi: matlist indices, nodotz bor(rows) twidth(35) names(all) aligncolnames(r) form(%9.3gc) title("Empowerment results")
 	    noi di as text "Note: `ni' indicators calculated."
 	    noi di as text "* Refers to the mean disempowerment score among only women/men who are disempowered. 5/3DE = 1 - (H*A); GPI = 1 - (HGPI*IGPI)"
				
		putdocx table Table1= matrix(indices),  nformat(%9.3f) rownames colnames headerrow(1) /// 
												layout(autofitco) border(all, nil) ///
												title("Empowerment results") ///
												note("Note: `ni' indicators calculated.", font(Aptos, 9)) ///
												note("* Refers to the mean disempowerment score among only women/men who are disempowered.", font(Aptos, 9)) ///
												note("5/3DE = 1 - (H*A); GPI = 1 - (HGPI*IGPI)", font(Aptos, 9))
        
		*return matrix Mat indices		
		putdocx table Table1(2,.) ,  border(bottom, double)
		putdocx table Table1(2,.) ,  border(top, double)		
		putdocx table Table1(3,.) ,  border(bottom)
		putdocx table Table1(5,.) ,  border(bottom)		
		
		putdocx table Table1(11,.),  border(bottom, double)
		
  	    putdocx table Table1(3,.),  nformat(%9.3f)	    
		putdocx table Table1(7,.),  nformat(%9.3f)	   
  	    putdocx table Table1(10,.), nformat(%9.0f)	    
		putdocx table Table1(11,.), nformat(%9.0f)		
		putdocx table Table1(1,.),  bold	 														
********************************************************************************		
		
*-------------------------------------------------------------------------------
*    by decomposition of Main Indicators:
*-------------------------------------------------------------------------------		
if ("`by'" != "")   {
	
*======================		
*Decomposition: Female		
*======================		
		
      tempname sum_main_f_sex sum_main_fm_sex

	  levelsof `by' `l_if', local(by_levels)      
	  foreach by_s of local by_levels {
		
      preserve		    
		
		keep if `by'==`by_s' & `touse'
		keep if `sex'==`female'
		
        cap assert `_H' == 0
        if _rc == 9 {
            local warn_no_disemp = 0
        }
        else {
            error _rc
            local warn_no_disemp = 1
        }

        noi _3de_main `"`var_submit'"'

        tempname hm_1_`by_s' hm_2_`by_s' hm_V_1_`by_s' hm_V_2_`by_s'

        matrix `hm_1_`by_s'' = r(weai_main)
        matrix `hm_V_1_`by_s'' = r(weai_main_V)
        matrix `hm_2_`by_s'' = r(weai_add)
        matrix `hm_V_2_`by_s'' = r(weai_add_V)
        local N = r(N)
        matlist `hm_1_`by_s''
		matlist `hm_2_`by_s''
        
        *Intermission: Display the results.
            
		tempname sum_main_f_`by_s' disp_b_`by_s' disp_V_`by_s' tmp_`by_s'

        local hm_1_col_`by_s' = colsof(`hm_1_`by_s'')
        local hm_2_col_`by_s' = colsof(`hm_2_`by_s'')
        matrix `disp_b_`by_s'' = `hm_1_`by_s'', `hm_2_`by_s''
        matrix `tmp_`by_s'' = J(`hm_1_col_`by_s'', `hm_2_col_`by_s'', 0)
        local names_`by_s' : colfullnames `hm_1_`by_s''
        matrix rownames `tmp_`by_s'' = `names_`by_s''
        local names_`by_s' : colfullnames `hm_2_`by_s''
        matrix colnames `tmp_`by_s'' = `names_`by_s''
        matrix `disp_V_`by_s'' = (`hm_V_1_`by_s'', `tmp_`by_s'')
        matrix `disp_V_`by_s'' = `disp_V_`by_s'' \ (`tmp_`by_s''', `hm_V_2_`by_s'')

        local n_string = "N = `N'"
        local len_n_string = strlen("`n_string'")
		
		*Indicators by sex	
	   `svy' mean empowered if `sex'==`female' & `touse'
		matrix empow_`by_s' = e(b)
		
	   `svy' mean emp_score if `sex'==`female' & empowered==0 & `touse'
		matrix empscore_`by_s' = 1-e(b)
		
		
		matrix DE_`by_s'= 1-(empscore_`by_s'*(1-empow_`by_s'))				
		matrix `sum_main_f_`by_s''=(`N'\DE_`by_s'\ 100*(1-empow_`by_s')\ empscore_`by_s')
		
	    * Prepare subpopulation labels
            local levels ""
            
			* Check if the by-variable has a label.
            local by_lab: value label `by'

            if "`by_lab'" != "" {
                    local label: label `by_lab' `by_s'
            }
            else {
                    local label= `"`by'_`by_s'"' 
                 }

		local vlname: value label `sex'
        local vl_`female': label `vlname' `female'
		matrix colnames `sum_main_f_`by_s'' = "`label': `vl_`female''"
		
	    tempname emp_f_`by_s'
		local emp_f_`by_s' = DE_`by_s'[1,1]
				
		matrix `sum_main_f_sex' = (nullmat(`sum_main_f_sex'), `sum_main_f_`by_s'')
			
     restore		
		}


		matrix rownames `sum_main_f_sex'="Number of observations" "5/3DE Index" "% Not achieving empowerment (H)"  "Mean disempowerment score (A)*"		

        if `warn_no_disemp' == 1 {
            error _rc
            noi di as result "Note: No individual is multidimensionally deprived."
        }	
*======================		
*Decomposition: Male		
*======================		
      tempname sum_main_m_sex

	  levelsof `by' `l_if', local(by_levels)      
	  foreach by_s of local by_levels {
		
    preserve		    		
		keep if `by'==`by_s' & `touse'
		keep if `sex'==`male'
		
        cap assert `_H' == 0
        if _rc == 9 {
            local warn_no_disemp = 0
        }
        else {
            error _rc
            local warn_no_disemp = 1
        }

        noi _3de_main `"`var_submit'"'

        tempname hm_1_`by_s' hm_2_`by_s' hm_V_1_`by_s' hm_V_2_`by_s'

        matrix `hm_1_`by_s'' = r(weai_main)
        matrix `hm_V_1_`by_s'' = r(weai_main_V)
        matrix `hm_2_`by_s'' = r(weai_add)
        matrix `hm_V_2_`by_s'' = r(weai_add_V)
        local N = r(N)
        matlist `hm_1_`by_s''
		matlist `hm_2_`by_s''

        *Intermission: Display the results.
        
		tempname sum_main_m_`by_s' disp_b_`by_s' disp_V_`by_s' tmp_`by_s'

        local hm_1_col_`by_s' = colsof(`hm_1_`by_s'')
        local hm_2_col_`by_s' = colsof(`hm_2_`by_s'')
        matrix `disp_b_`by_s'' = `hm_1_`by_s'', `hm_2_`by_s''
        matrix `tmp_`by_s'' = J(`hm_1_col_`by_s'', `hm_2_col_`by_s'', 0)
        local names_`by_s' : colfullnames `hm_1_`by_s''
        matrix rownames `tmp_`by_s'' = `names_`by_s''
        local names_`by_s' : colfullnames `hm_2_`by_s''
        matrix colnames `tmp_`by_s'' = `names_`by_s''
        matrix `disp_V_`by_s'' = (`hm_V_1_`by_s'', `tmp_`by_s'')
        matrix `disp_V_`by_s'' = `disp_V_`by_s'' \ (`tmp_`by_s''', `hm_V_2_`by_s'')

        local n_string = "N = `N'"
        local len_n_string = strlen("`n_string'")
		
		*Index by sex	
	   `svy' mean empowered if `sex'==`male' & `touse'
		matrix empow_`by_s' = e(b)
		
	   `svy' mean emp_score if `sex'==`male' & empowered==0 & `touse'
		matrix empscore_`by_s' = 1-e(b)
		
		matrix DE_`by_s'= 1-(empscore_`by_s'*(1-empow_`by_s'))						
		matrix `sum_main_m_`by_s''=(`N'\DE_`by_s'\ 100*(1-empow_`by_s')\ empscore_`by_s')
		
			*Prepare subpopulation labels
            local levels ""
            
			*Check if the by-variable has a label.
            local by_lab: value label `by'

            if "`by_lab'" != "" {
                    local label: label `by_lab' `by_s'
            }
            else {
                    local label= `"`by'_`by_s'"' //`"`levels' ":`by'_`i'""''
                 }

		local vlname: value label `sex'
        local vl_`male': label `vlname' `male'
		matrix colnames `sum_main_m_`by_s'' = "`label': `vl_`male''"
		
		tempname emp_`by_s'
		local emp_`by_s' = DE_`by_s'[1,1]

		
		matrix `sum_main_m_sex' = (nullmat(`sum_main_m_sex'), `sum_main_m_`by_s'')
			
     restore		
		}

		matrix rownames `sum_main_m_sex'="Number of observations" "5/3DE Index" "% Not achieving empowerment (H)"  "Mean disempowerment score (A)*"		

        if `warn_no_disemp' == 1 {
            error _rc
            noi di as result "Note: No individual is multidimensionally deprived."
        }
		
	  matrix `sum_main_fm_sex'=(`sum_main_f_sex', `sum_main_m_sex')
		
      tempname sum_main_fm   
	  levelsof `by' `l_if', local(by_levels)      
	     foreach by_s of local by_levels {
	  	 
		 tempname sum_main_fm_`by_s'
		 
		 matrix `sum_main_fm_`by_s''=(`sum_main_f_`by_s'', `sum_main_m_`by_s'')		 
		 matrix `sum_main_fm'=(nullmat(`sum_main_fm'), `sum_main_fm_`by_s'')		
	    }
		 
		 matrix rownames `sum_main_fm'="Number of observations" "5/3DE Index" "% Not achieving empowerment (H)"  "Mean disempowerment score (A)*"		
	
*-------------------------------------------------------------------------------
*GPI FOR BY DECOMPOSITION
*------------------------------------------------------------------------------- 	

      tempname indices	
	  levelsof `by' `l_if', local(by_levels)      
	  foreach by_s of local by_levels {

   preserve
    keep if `by'==`by_s' & `touse'
	forvalues j = 1 / `ndom' {
            local nind`j' = wordcount("`d`j''")
            forvalues i = 1 / `nind`j'' {
                g we_`j'_`i' = word("`w`j''", `i')
				destring we_`j'_`i', replace
                local ind = word("`d`j''", `i')
				gen double wg0_`ind'= `ind'*we_`j'_`i' 
            }
        }								
	   	
    *If a by-option was specified, prepare the respective statements.
  	
        if "`by'" != "" {
            local over_statement = ", over(`by', nolabel)"
        }
        else {
            local over_statement = ""
        }
		
        drop if `all_missing'
		
	** Focus on male and female households
        
		tempvar i n ci
		sort `hhid' `sex'
		bys  `hhid': gen `i'=_n
		bys  `hhid': egen `n'=max(`i')

		*tab hh_type n, miss
		keep if `n' !=1
		egen double `ci'=rsum(wg0_*)
		
		replace `ci'=round(`ci', 0.0001)
		label variable `ci' "Inadequacy Count without Parity"
			
********************************************
*** Compute censored inadequacy scores  ***
********************************************

        tempvar w_ci_id m_ci_id W_ci M_ci W_cen_ci M_cen_ci
		bys `hhid': gen double  `w_ci_id'=`ci' if `sex'==`female' 
		bys `hhid': gen double  `m_ci_id'=`ci' if `sex'==`male' 
		bys `hhid': egen double `W_ci'=max(`w_ci_id')
		bys `hhid': egen double `M_ci'=max(`m_ci_id')

		bys `hhid': gen double `W_cen_ci'=`W_ci'
		bys `hhid': replace `W_cen_ci'=(1-`cutoff') if (`W_cen_ci'<=(1-`cutoff') & `W_cen_ci'!=.)
		
		bys `hhid': gen double `M_cen_ci'=`M_ci'
		bys `hhid': replace `M_cen_ci'=(1-`cutoff') if (`M_cen_ci'<=(1-`cutoff') & `M_cen_ci'!=.)	
		
	    tempvar hh_ineq
		gen `hh_ineq'=(`W_ci'-`M_ci') if `sex'==`female' 
	    label var `hh_ineq' "Intra-household inequality score"
			
******************************************************
*** Identify inadequate in terms of gender parity  ***
******************************************************

		tempvar ci_above
		bys `hhid': gen `ci_above'=(`W_cen_ci'>`M_cen_ci')
		bys `hhid': replace `ci_above'=. if (`W_cen_ci'==.| `M_cen_ci'==.)
		label var `ci_above' "Equals 1 if individual lives in MF hh where the depr score of the woman is higher than the man - EI 1"		

        tempvar gender_parity	
		gen `gender_parity'=1-`ci_above' if `ci_above'!=. 		
		replace `gender_parity'=1 if `gender_parity'==0 & empowered==1 & `sex'==`female' 

		tempvar max_gpi
		bys `hhid': egen `max_gpi'=max(`gender_parity') if !missing(`gender_parity')
		bys `hhid': replace `gender_parity'=`max_gpi'   if !missing(`gender_parity')

	    replace `ci_above'=0 if `ci_above'==1 & `gender_parity'==1 & `sex'==`female' 		
				
		label var `gender_parity' "Household achieves Gender Parity"
************************************
*** Compute Gender Parity Index  ***
************************************

		** Full sample
		tempvar females women_n
		gen `females'=(`sex'==`female' & `ci_above'!=.)
		egen `women_n'=total(`females')
		drop `females'

		** Headcount ratio of inadequate women
		tempvar inadequate inadequate_n H
		gen  `inadequate'=(`ci_above'==1 & `sex'==`female')
		egen `inadequate_n' = total(`inadequate')
		gen `H'=`inadequate_n'/`women_n' // Considering unweighted sample //
		

		** Computation of normalized gap
		tempvar ci_gap ci_gap_sum ci_average
		qui gen `ci_gap'=(`W_cen_ci'-`M_cen_ci')/(1-`M_cen_ci') if (`ci_above'==1 & `sex'==`female') 
		egen `ci_gap_sum' = total(`ci_gap')
		gen `ci_average'=`ci_gap_sum'/`inadequate_n'

		** Computation of GPI
		tempvar H_GPI P1 GPI
		gen `H_GPI'=`inadequate_n'/`women_n'
		gen `P1'=`H_GPI'*`ci_average'
		gen `GPI'=1-`P1'
**************************
*** Summarize results  ***
**************************
		tempname par_`by_s' weai_ind a_hh_ineq gend_p_`by_s' gend 
		
	   `svy' mean `H_GPI' `ci_average' `P1' `GPI' if `touse'

   		local N =_N/2
	   `svy' mean `GPI' `H_GPI' `ci_average' if `touse'
		matrix gend = e(b)
		
		local par_`by_s'=gend[1,1]
		local weai_ind=(0.1*`par_`by_s'') + (0.9*`emp_f_`by_s'')


        `svy' mean `hh_ineq' if `touse'
		matrix `a_hh_ineq'= e(b)
		matrix `gend_p_`by_s'' =(`N'\ gend[1,1]\ 100*(gend[1,2])\ gend[1,3] \ `weai_ind')
		matrix rownames `gend_p_`by_s''="Number of dual households" "Gender Parity Index (GPI)" "% Without gender parity (HGPI)" "Mean empowerment gap (IGPI)" "WEAI/A-WEAI/pro-WEAI"
                                        
		matrix gendd=(.\.\.\.\.)
		matrix `gend_p_`by_s''=(`gend_p_`by_s'',gendd)		
	    matrix `indices' = (nullmat(`indices'), `gend_p_`by_s'')	
		
*-----------------------------------------
*-----------------------------------------			
cap drop wg0_*  we_*
	forvalues j = 1 / `ndom' {
            forvalues i = 1 / `nind`j'' {
                cap drop we_`j'_`i'
				cap drop wg0_`ind' 
            }
        }				
   restore
	  }

	   tempname sum_main_decomp tab1_decomp
	   matrix `sum_main_decomp'=(`sum_main_fm' \ `indices')		    
	   matrix `tab1_decomp'= (`sum_main_decomp'[9,1...] \ `sum_main_decomp'[2,1...] \ `sum_main_decomp'[6,1...] \ `sum_main_decomp'[3,1...] \ `sum_main_decomp'[4,1...] \ `sum_main_decomp'[7,1...] \ `sum_main_decomp'[8,1...] \ `sum_main_decomp'[5,1...] \ `sum_main_decomp'[1,1...])
       
		matrix rownames `tab1_decomp' = "WEAI/A-WEAI/pro-WEAI" "5/3DE Index" "Gender Parity Index (GPI)" "% Not achieving empowerment (H)"  "Mean disempowerment score (A)*" ///
		                         "% Without gender parity (HGPI)" "Mean empowerment gap (IGPI)" "Number of dual households" "Number of observations"	   
	   
	   noi: matlist `tab1_decomp', nodotz bor(rows) twidth(35) names(all) aligncolnames(r) form(%9.3gc) ///
	   title("Decomposition of empowerment results by `by'")
	   noi di as text "Note: `ni' indicators calculated."
 	   noi di as text "* Refers to the mean disempowerment score among only women/men who are disempowered. 5/3DE = 1 - (H*A); GPI = 1 - (HGPI*IGPI)"
	   
	   putdocx table Table1b = matrix( `tab1_decomp'), nformat(%9.3f) rownames colnames headerrow(1) /// 
	   										    layout(autofitco) border(all, nil) /// 
												title("Decomposition of empowerment results by `by'") ///
												note("Note: `ni' indicators calculated.", font(Aptos, 9)) ///
												note("* Refers to the mean disempowerment score among only women/men who are disempowered.", font(Aptos, 9)) ///
												note("5/3DE = 1 - (H*A); GPI = 1 - (HGPI*IGPI)", font(Aptos, 9))

	   putdocx table Table1b(2,.),   border(bottom, double)
	   putdocx table Table1b(2,.),   border(top, double)
	   putdocx table Table1b(3,.) ,  border(bottom)
	   putdocx table Table1b(5,.) ,  border(bottom)			   
	   
	   putdocx table Table1b(11,.),  border(bottom, double)
												
	   putdocx table Table1b(3,.),  nformat(%9.3f)	    
	   putdocx table Table1b(7,.),  nformat(%9.3f)
  	   putdocx table Table1b(10,.), nformat(%9.0f)	    
	   putdocx table Table1b(11,.), nformat(%9.0f)		   
	   putdocx table Table1b(1,.),  bold	    	   
		
	}	
		 local i 0	     
	     foreach by_s of local by_levels {
	     local ++i
		  
	  	    *Prepare subpopulation labels
            local levels ""            
			*Check if the by-variable has a label.
            local by_lab: value label `by'
			
            if "`by_lab'" != "" {
                    local label: label `by_lab' `by_s'
            }
            else {
                    local label= `"`by'_`by_s'"' //`"`levels' ":`by'_`i'""''
                 }
				 
		  local k=2*`i' 
	   	  putdocx table Table1b(2, `k-1')=(""),        append linebreak 	  
	   	  putdocx table Table1b(2, `k')  =("`label'"), append  	  		  
	  }  	  
*------------------------------------------------------------------------------
*Create Summary Table: Table 2. Inadequacy uncensored headcount ratios (%).
*------------------------------------------------------------------------------
* Establish total number of individuals
        if "`details'" != "" {

            tempname inad
            forvalues j = 1 / `ndom' {
				tempname inad_`j'
                local nind`j' = wordcount("`d`j''")
                forvalues i = 1 / `nind`j'' {
                    *Extract weight and indicator from the respective locals
                    local w = round(real(word("`w`j''", `i')), 0.01)
                    local ind = word("`d`j''", `i')
					local labl: variable label `ind'

                    *Calculate how many people are deprived.
                   `svy' mean `isinadequate_`j'_`i'' `weight_exp' if `sex'==`female' & `touse' //xtouse
                    matrix `res' = e(b)
                    local f_perc_inadequate =(`res'[1, 1]) * 100

                    if missing(`f_perc_inadequate') {
                        local f_perc_inadequate = 100
                    }					
					
                   `svy' mean `isinadequate_`j'_`i'' `weight_exp' if `sex'==`male' & `touse' //xtouse
                    matrix `res' = e(b)
                    local m_perc_inadequate =(`res'[1, 1]) * 100									
					
                    if missing(`m_perc_inadequate') {
                        local m_perc_inadequate = 100
                    }
					
					local vlname: value label `sex'
					local vl_`male': label `vlname' `male'
					local vl_`female': label `vlname' `female'
					
                    tempname inad_`j'_`i'  			
					matrix `inad_`j'_`i''=(`f_perc_inadequate', `m_perc_inadequate')
					matrix rownames `inad_`j'_`i'' = "Domain `j': `ind'" 
				    matrix colnames `inad_`j'_`i'' = "`vl_`female''"  "`vl_`male''"
					
					matrix  `inad_`j''=(nullmat(`inad_`j'')\ `inad_`j'_`i'' )
					
                }
					matrix  `inad'=(nullmat(`inad')\ `inad_`j'' )
            }
            noi matlist `inad', nodotz bor(rows) twidth(30) names(all) aligncolnames(r) form(%9.1fc)  title("Uncensored inadequacy headcount ratios (%)")
            noi di as text "Note: `ni' indicators calculated."
			noi display as text "The uncensored headcount ratio reflects the percent of respondents who are inadequate"
			noi display as text "in the indicator." _n _n
           
		   
    	    putdocx table Table2a = matrix(`inad'), nformat(%9.3gc) rownames colnames headerrow(2) /// 
												layout(autofitco) border(all, nil) /// 
												title("Uncensored inadequacy headcount ratios (%)") ///
												note("Note: `ni' indicators calculated.", font(Aptos, 9)) ///
												note("The uncensored headcount ratio reflects the percent of respondents who are inadequate in the indicator.", font(Aptos, 9)) 
			local n_i=`ni'+2
			putdocx table Table2a(2,.) , border(bottom, double)
			putdocx table Table2a(2,.) , border(top, double)
			putdocx table Table2a(`n_i',.) , border(bottom, double)		    
			putdocx table Table2a(1,.), bold	 								
		
            if `"`error_message'"' != "" {
                noi display as result "Note: " `error_message'
            }
        }	
*---------------------------------------------------------------------------
*Create Summary Table: Table 2. Inadequacy uncensored headcount ratios (%)
*---------------------------------------------------------------------------      
if "`details'" != "" {

		tempname inad
	    if ("`by'" != "")   {	
		  levelsof `by' `l_if', local(by_levels)      
		  foreach by_s of local by_levels {		
	  	
    preserve			
			keep if `by'==`by_s' & `touse'
     		tempname inad_`by_s'	
			
			*Prepare subpopulation labels
            local levels ""
            
			*Check if the by-variable has a label.
            local by_lab: value label `by'

            if "`by_lab'" != "" {
                    local label: label `by_lab' `by_s'
            }
            else {
                    local label= `"`by'_`by_s'"'
                 }

            forvalues j = 1 / `ndom' {
                local nind`j' = wordcount("`d`j''")
				tempname inad_`by_s'_`j'	
                forvalues i = 1 / `nind`j'' {
                    *Extract weight and indicator from the respective locals
                    local w = round(real(word("`w`j''", `i')), 0.01)
					local ind = word("`d`j''", `i')
					
                    *Calculate how many people are deprived.
                   `svy' mean `isinadequate_`j'_`i'' `weight_exp' if `sex'==`female' & `touse'
                    matrix `res' = e(b)
                    local f_perc_inadequate =(`res'[1, 1]) * 100

                    if missing(`f_perc_inadequate') {
                        local f_perc_inadequate = 100
                    }					
					
                   `svy' mean `isinadequate_`j'_`i'' `weight_exp' if `sex'==`male' & `touse'
                    matrix `res' = e(b)
                    local m_perc_inadequate =(`res'[1, 1]) * 100									
					
                    if missing(`m_perc_inadequate') {
                        local m_perc_inadequate = 100
                    }
	
				*Prepare subpopulation labels
				local levels ""
				
				*Check if the by-variable has a label.
				local by_lab: value label `by'

				if "`by_lab'" != "" {
						local label: label `by_lab' `by_s'
				}
				else {
						local label= `"`by'_`by_s'"'
					 }

				local vlname: value label `sex'
				local vl_`male': label `vlname' `male'
				local vl_`female': label `vlname' `female'
					
                    tempname inad_`by_s'_`j'_`i'  			
					matrix `inad_`by_s'_`j'_`i''=(`f_perc_inadequate', `m_perc_inadequate')
					matrix rownames `inad_`by_s'_`j'_`i'' = "Domain `j': `ind'" 
				    matrix colnames `inad_`by_s'_`j'_`i'' = "`label': `vl_`female''"  "`label': `vl_`male''"
					
					matrix  `inad_`by_s'_`j''=(nullmat(`inad_`by_s'_`j'')\ `inad_`by_s'_`j'_`i'' )
                }
				
				matrix  `inad_`by_s''=(nullmat(`inad_`by_s'')\ `inad_`by_s'_`j'' )
            }
            if `"`error_message'"' != "" {
                noi display as result "Note: " `error_message'
            }
    restore			
			
			matrix  `inad'=(nullmat(`inad'), `inad_`by_s'' )
		}
		   noi matlist `inad', nodotz bor(rows) twidth(30) names(all) aligncolnames(r) form(%9.1fc)  title("Decomposition of the uncensored inadequacy headcount ratios (%) by `by'")
           noi di as text "Note: `ni' indicators calculated."
		   noi display as text "The uncensored headcount ratio reflects the percent of respondents who are inadequate"
		   noi display as text "in the indicator." _n _n

		   putdocx table Table2b = matrix(`inad'), nformat(%9.3gc) rownames colnames headerrow(1) /// 
												layout(autofitco) border(all, nil)  /// 
												title("Decomposition of the uncensored inadequacy headcount ratios (%) by `by'") ///
												note("Note: `ni' indicators calculated.", font(Aptos, 9)) ///
												note("The uncensored headcount ratio reflects the percent of respondents who are inadequate in the indicator.", font(Aptos, 9))
												
		   putdocx table Table2b(2,.),  border(bottom, double)
		   putdocx table Table2b(2,.),  border(top, double)
		   putdocx table Table2b(`n_i',.), border(bottom, double)												    
		   putdocx table Table2b(1,.), bold	  												
																								
		   local i 0	     
		   foreach by_s of local by_levels {
		   local ++i
			  
				*Prepare subpopulation labels
				local levels ""            
				*Check if the by-variable has a label.
				local by_lab: value label `by'
				
				if "`by_lab'" != "" {
						local label: label `by_lab' `by_s'
				}
				else {
						local label= `"`by'_`by_s'"'
					 }
					 
			  local k=2*`i' 
			  putdocx table Table2b(2, `k-1')=(""),        append linebreak 	  
			  putdocx table Table2b(2, `k')  =("`label'"), append 	  		  
		  }
																		
		}
		}			
*---------------------------------------------------------------------------
*Create Summary Table: Table 3. "Inadequacy censored headcount ratios (%)."
*---------------------------------------------------------------------------
** Establish total number of individuals
        if "`details'" != "" {
		tempname inad
            forvalues j = 1 / `ndom' {
				tempname inad_`j' 
                local nind`j' = wordcount("`d`j''")
                forvalues i = 1 / `nind`j'' {
                    *Extract weight and indicator from the respective locals
                    local w = round(real(word("`w`j''", `i')), 0.01)
                    local ind = word("`d`j''", `i')
					local labl: variable label `ind'
					
					tempvar disemp_isinad_`j'_`i'					
					generate `disemp_isinad_`j'_`i''= (`isinadequate_`j'_`i''==1  & empowered==0)

                    *Calculate how many people are deprived. 
				   `svy' mean `disemp_isinad_`j'_`i'' `weight_exp' if `sex'==`female' & `touse'			
                    matrix `res' = e(b)
                    local f_perc_inadequate =(`res'[1, 1]) * 100

                    if missing(`f_perc_inadequate') {
                        local f_perc_inadequate = 100
                    }					
										
				   `svy' mean `disemp_isinad_`j'_`i'' `weight_exp' if `sex'==`male' & `touse'
                    matrix `res' = e(b)
                    local m_perc_inadequate =(`res'[1, 1]) * 100									
					
                    if missing(`m_perc_inadequate') {
                        local m_perc_inadequate = 100
                    }
					
					local vlname: value label `sex'
					local vl_`male': label `vlname' `male'
					local vl_`female': label `vlname' `female'
					
                    tempname inad_`j'_`i'  			
					matrix `inad_`j'_`i''=(`f_perc_inadequate', `m_perc_inadequate')
					matrix rownames `inad_`j'_`i'' = "Domain `j': `ind'" 
				    matrix colnames `inad_`j'_`i'' = "`vl_`female''"  "`vl_`male''"
					
					matrix  `inad_`j''=(nullmat(`inad_`j'')\ `inad_`j'_`i'' )
					
                }
					matrix  `inad'=(nullmat(`inad')\ `inad_`j'' )
            }            
			
            noi matlist `inad', nodotz bor(rows) twidth(30) names(all) aligncolnames(r) form(%9.1fc)  title("Censored inadequacy headcount ratios (%)")
			noi di as text "Note: `ni' indicators calculated."
			noi display as text "The censored headcount ratio reflects the percent of respondents who are both disempowered and inadequate"
			noi display as text "in the indicator." _n _n
            			
			putdocx table Table3a = matrix(`inad'), nformat(%9.3gc) rownames colnames headerrow(4) border(top) border(bottom) /// 
												border(all, nil) layout(autofitco) /// 
												title("Censored inadequacy headcount ratios (%)") ///
												note("Note: `ni' indicators calculated.", font(Aptos, 9)) ///
												note("The censored headcount ratio reflects the percent of respondents who are both disempowered and inadequate in the indicator.", font(Aptos, 9))
												
			local n_i=`ni'+2
			putdocx table Table3a(2,.) , border(bottom, double)
			putdocx table Table3a(2,.) , border(top, double)
			putdocx table Table3a(`n_i',.) , border(bottom, double)		    
			putdocx table Table3a(1,.), bold	 													
							
            if `"`error_message'"' != "" {
                noi display as result "Note: " `error_message'
            }
        }				
*---------------------------------------------------------------------------
*Table 3 DECOMPOSITION
*Summary table: Table 3. "Inadequacy censored headcount ratios (%)."
*---------------------------------------------------------------------------
    if "`details'" != "" {
		tempname inad
	    if ("`by'" != "")   {	
		  levelsof `by' `l_if', local(by_levels)      
		  foreach by_s of local by_levels {			  	
       preserve			
			keep if `by'==`by_s' & `touse'
     		tempname inad_`by_s'	
			
			*Prepare subpopulation labels
            local levels ""
            
			*Check if the by-variable has a label.
            local by_lab: value label `by'

            if "`by_lab'" != "" {
                    local label: label `by_lab' `by_s'
            }
            else {
                    local label= `"`by'_`by_s'"' 
                 }

		    local vlname: value label `sex'
            local vl_`male': label `vlname' `male'
				

            forvalues j = 1 / `ndom' {
                local nind`j' = wordcount("`d`j''")
				tempname inad_`by_s'_`j'	
                forvalues i = 1 / `nind`j'' {
                    
					*Extract weight and indicator from the respective locals
                    local w = round(real(word("`w`j''", `i')), 0.01)
					local ind = word("`d`j''", `i')

					tempvar disemp_isinad_`j'_`i'					
					generate `disemp_isinad_`j'_`i''= (`isinadequate_`j'_`i''==1  & empowered==0)
					
                   *Calculate how many people are deprived.
				   `svy' mean `disemp_isinad_`j'_`i'' `weight_exp' if `sex'==`female' & `touse' 					
                    matrix `res' = e(b)
                    local f_perc_inadequate =(`res'[1, 1]) * 100

                    if missing(`f_perc_inadequate') {
                        local f_perc_inadequate = 100
                    }					
					
                   `svy' mean `disemp_isinad_`j'_`i'' `weight_exp' if `sex'==`male'	& `touse' 				
					matrix `res' = e(b)
                    local m_perc_inadequate =(`res'[1, 1]) * 100									
					
                    if missing(`m_perc_inadequate') {
                        local m_perc_inadequate = 100
                    }
	
				*Prepare subpopulation labels
				local levels ""
				
				*Check if the by-variable has a label.
				local by_lab: value label `by'

				if "`by_lab'" != "" {
						local label: label `by_lab' `by_s'
				}
				else {
						local label= `"`by'_`by_s'"'
					 }

				local vlname: value label `sex'
				local vl_`male': label `vlname' `male'
				local vl_`female': label `vlname' `female'
	
                    tempname inad_`by_s'_`j'_`i'  			
					matrix `inad_`by_s'_`j'_`i''=(`f_perc_inadequate', `m_perc_inadequate')
					matrix rownames `inad_`by_s'_`j'_`i'' = "Domain `j': `ind'" 
				    matrix colnames `inad_`by_s'_`j'_`i'' = "`label': `vl_`female''"  "`label': `vl_`male''"
					
					matrix  `inad_`by_s'_`j''=(nullmat(`inad_`by_s'_`j'')\ `inad_`by_s'_`j'_`i'' )
					
                }
				
				matrix  `inad_`by_s''=(nullmat(`inad_`by_s'')\ `inad_`by_s'_`j'' )
            }
            if `"`error_message'"' != "" {
                noi display as result "Note: " `error_message'
            }
    restore						
			matrix  `inad'=(nullmat(`inad'), `inad_`by_s'' )
		}
		    noi matlist `inad', nodotz bor(rows) twidth(30) names(all) aligncolnames(r) form(%9.1fc)  title("Decomposition of the censored inadequacy headcount ratios (%) by `by'")
            noi di as text "Note: `ni' indicators calculated."
			noi display as text "The censored headcount ratio reflects the percent of respondents who are both disempowered and inadequate"
			noi display as text "in the indicator." _n _n
		
			putdocx table Table3b = matrix(`inad'), nformat(%9.3gc) rownames colnames headerrow(1) /// 
												border(all, nil) layout(autofitco) /// 
												title("Decomposition of the censored inadequacy headcount ratios (%) by `by'") ///
												note("Note: `ni' indicators calculated. The censored headcount ratio reflects the percent of respondents who are both disempowered and inadequate in the indicator.", font(Aptos, 9))
												
		   putdocx table Table3b(2,.),  border(bottom, double)
		   putdocx table Table3b(2,.),  border(top, double)
		   putdocx table Table3b(`n_i',.), border(bottom, double)												    
		   putdocx table Table3b(1,.), bold	  												
		   									
		   local i 0	     
		   foreach by_s of local by_levels {
		   local ++i			  
				*Prepare subpopulation labels
				local levels ""            
				*Check if the by-variable has a label.
				local by_lab: value label `by'
				
				if "`by_lab'" != "" {
						local label: label `by_lab' `by_s'
				}
				else {
						local label= `"`by'_`by_s'"'
					 }					 
			  local k=2*`i' 
			  putdocx table Table3b(2, `k-1')=(""),        append linebreak 	  
			  putdocx table Table3b(2, `k')  =("`label'"), append 	  		  
		  }																		
	  }			
	} // End details

*---------------------------------------------------------------------------
*Decomposition of M_alpha by Indicator
*---------------------------------------------------------------------------

tempname disp_sex disp_C_sex
				
	    			
		local sexs `female' `male'
     	foreach s of local sexs {
		     
   preserve		    		
		keep if `sex'==`s' & `touse'
	
            if `ni' != 1 {
                *Variables for output
                tempname decomb_ind_`s' decomb_dom_`s' decomb_ind_C_`s' decomb_ind_V_`s' decomb_dom_V_`s' mat_transform_`s'

                *Variables for display
                tempname disp_`s' decomb_ind_disp_`s' decomb_dom_disp_`s'

                noi _3de_domains `"`var_submit'"'

                matrix `decomb_ind_`s''   = r(weai_decomposed)
                matrix `decomb_ind_C_`s'' = r(weai_decomposed_C)				
                matrix `decomb_ind_V_`s'' = r(weai_decomposed_V)
				
				matrix `decomb_ind_C_`s'' = `decomb_ind_C_`s'''

				
                local ncol = `=1 + wordcount("`alpha'")*`use_thresholds''

                mata: `A'  = st_matrix("r(weai_decomposed)")
                mata: cols = strtoreal(st_local("ncol"))
                mata: `A'  = colshape(`A', cols)
                mata: st_matrix("`decomb_ind_disp_`s''", `A')
								
                *Create the correct names.
				
                if `use_thresholds' {
                    local idx = 0
                    local addlabel_alpha = ""
                    foreach a of local alpha {
                        local idx = `idx' + 1
                        local a_name = subinstr("`a'", ".", ",", .)
                        local addlabel_alpha = `"`addlabel_alpha' "M(`a_name')""'
                        local a_name = subinstr("`a'", ".", "p", .)
                        local a_name = subinstr("`a_name'", "-", "m", .)
                    }
                    local names = `""M0" `addlabel_alpha'"'
                }
                else {
                    local names = `""M0""'
                }
                matrix colnames `decomb_ind_disp_`s'' = `names'
                matrix colnames `decomb_ind_C_`s'' = `names'
				
                local e_names = ""
                local lb_ind =  " "
                local lb_dom = " "
                forvalues j = 1 / `ndom' {
                    local lb_dom = `"`lb_dom' "Domain `j'""'
                    local nind`j' = wordcount("`d`j''")

                  *Iterate over indicators, create the to-be-estimated variables and the labels.
                    forvalues i = 1 / `nind`j'' {
                        local ind = word("`d`j''", `i')
                        local lb_ind = `"`lb_ind' "Domain `j':`ind'""''
                    }
                }
            }
		
       *Prepare for display and do consistency checks.
           if `ni' != 1 {
   			
                matrix `disp_`s'' = (`decomb_ind_disp_`s'')
                matrix rownames `disp_`s'' = `lb_ind' 							
                matrix rownames `decomb_ind_C_`s'' = `lb_ind' 				
				
                if `warn_no_disemp' {
                    noi di as result "Note: No individual is multidimensionally deprived."
                }
                noi display as text ""		
            }			    
				local vlname: value label `sex'
                local vl_`s': label `vlname' `s'
		        matrix colnames `disp_`s'' = `vl_`s''
		        matrix colnames `decomb_ind_C_`s'' = `vl_`s''				
                matrix `disp_sex'   = (nullmat(`disp_sex'), `disp_`s'')	
                matrix `disp_C_sex' = (nullmat(`disp_C_sex'), `decomb_ind_C_`s'')						
restore  
		}
		
	       tempname m_weights	         
		   forvalues j = 1 / `ndom' {
		       tempname d_weight_`j'
		                forvalues i = 1 / `nind`j'' {					    
						tempname m_weight_`i'	
						matrix `m_weight_`i'' = round(real(word("`w`j''", `i')), 0.01)
						matrix colnames `m_weight_`i'' = "Weight"	
					    matrix `d_weight_`j''=(nullmat(`d_weight_`j'')\ `m_weight_`i'')					
                    }					
					    matrix `m_weights'=(nullmat(`m_weights')\ `d_weight_`j'')
		   }		
				
				matrix rownames  `disp_C_sex' = `lb_ind'
				
	            tempname w_disp_sex 				
		        matrix `w_disp_sex'=(`m_weights', `disp_sex')
                matrix rownames  `w_disp_sex' = `lb_ind' 
				
if "`details'" != "" {									
				noi display in gr "Relative contribution of each indicator to disempowerment (%)"		
				noi matlist `w_disp_sex', form(%9.2fc) nodotz bor(rows) twidth(30) names(all) aligncolnames(r)
				noi di as text "Note: `ni' indicators calculated."
				noi display as text "The relative contribution to each indicator to disempowerment reflects how much each indicator" 
				noi display as text "contributes to disempowerment among respondents who have not achieved empowerment relative to the disempowerment index (1-3/5DE)."
		
		        putdocx table Table4a = matrix(`w_disp_sex'), nformat(%9.2fc) rownames colnames headerrow(4) /// 
												border(all, nil) layout(autofitco) /// 
												title("Relative contribution of each indicator to disempowerment (%)") ///
												note("Note: `ni' indicators calculated.", font(Aptos, 9)) ///
												note("The relative contribution to each indicator to disempowerment reflects how much each indicator contributes to disempowerment among respondents who have not achieved empowerment relative to the disempowerment index (1-3/5DE).", font(Aptos, 9))
												
				local n_i=`ni'+2
				putdocx table Table4a(2,.) , border(bottom, double)
				putdocx table Table4a(2,.) , border(top, double)
				putdocx table Table4a(`n_i',.) , border(bottom, double)		    
				putdocx table Table4a(1,.), bold	 				
									
} // End details
			 			   	
				tempname var_colnames
				gen `var_colnames' = ""
				tokenize "`: colnames `disp_C_sex''"
				local labdf ""
				
				qui forval i = 1/`= rowsof(`disp_C_sex')' {

				gen ind_`i' = .	
				qui forval j = 1/`= colsof(`disp_C_sex')' {
				
				replace ind_`i' = `disp_C_sex'[`i',`j'] in `j'
				lab var ind_`i' 
				replace `var_colnames' = "``j''" in `j'
				}
				 
				getRowName `disp_C_sex' `i'
				local lab_ind_`i'=r(rowname)
				rename ind_`i' c_`lab_ind_`i''	
		} 
				
if "`graph'" != "" {	
    graph bar  c_* , over(`var_colnames', sort(1) descending) stack ///
        yreverse xalternate graphregion(color(white)) scale(.95) ///
		bar(1, fc("186 228 179")  lc(white) lw(vvthin)) ///   
		bar(2, fc("116 196 118")  lc(none) lw(vvthin)) ///
		bar(3, fc("49 163 84")    lc(none) lw(vvthin)) ///
		bar(4, fc("254 237 222")  lc(none) lw(vvthin)) ///   
		bar(5, fc("253 208 162")  lc(none) lw(vvthin)) ///
		bar(6, fc("253 174 107")  lc(none) lw(vvthin)) ///   
		bar(7, fc("253 141 60")   lc(none) lw(vvthin)) ///
		bar(8, fc("230 85 13")    lc(none) lw(vvthin)) ///
		bar(9, fc("166 54 3")     lc(none) lw(vvthin)) ///  
		bar(10, fc("188 189 220") lc(none) lw(vvthin)) ///
		legend(cols(1) pos(3) si(vsmall)   lw(vvthin) region(lwidth(none))) nolabel ///
		title("{bf:Absolute contribution of each indicator to disempowerment}", span si(medium) position(11) margin(b=5)) ///
		ytitle("Disempowerment index", si(small)) yla(, format(%9.1f)) yscale(titlegap(*2.5)) ///
		note("NOTE: `ni' indicators calculated. The absolute contribution to each indicator to disempowerment reflects how much each indicator" "contributes to disempowerment among respondents who have not achieved empowerment.", si(vsmall) margin(medium)) name(weai, replace)		
		
 	    graph save "`graph'",  replace				
		cap drop c_*				
}
        cap drop c_*	
*---------------------------------------------------------------------------
*Decomposition of M_alpha by BY
*---------------------------------------------------------------------------
	
	tempname disp_f_sex disp_m_sex  disp_C_f_sex disp_C_m_sex 
				
	    if ("`by'" != "")   {	
  		
		levelsof `by' `l_if', local(by_levels)      
		foreach by_s of local by_levels {	

    preserve			
			keep if `by'==`by_s' & `touse'
			keep if `sex'==`female'
			
            if `ni' != 1 {
                *Variables for output
                tempname decomb_ind_f_`by_s' decomb_dom_f_`by_s' decomb_ind_V_f_`by_s' decomb_dom_V_f_`by_s' mat_transform_f_`by_s' decomb_ind_C_f_`by_s'

                *Variables for display
                tempname disp_f_`by_s' decomb_ind_disp_f_`by_s' decomb_dom_disp_f_`by_s' 

                noi _3de_domains `"`var_submit'"'

                matrix `decomb_ind_f_`by_s''   = r(weai_decomposed)
                matrix `decomb_ind_C_f_`by_s'' = r(weai_decomposed_C)				
                matrix `decomb_ind_V_f_`by_s'' = r(weai_decomposed_V)
				
				matrix `decomb_ind_C_f_`by_s''= `decomb_ind_C_f_`by_s'''
								
                local ncol = `=1 + wordcount("`alpha'")*`use_thresholds''

                mata: `A' = st_matrix("r(weai_decomposed)")
                mata: cols = strtoreal(st_local("ncol"))
                mata: `A' = colshape(`A', cols)
                mata: st_matrix("`decomb_ind_disp_f_`by_s''", `A')

                *Create the correct names.
              if `use_thresholds' {
                    local idx = 0
                    local addlabel_alpha = ""
                    foreach a of local alpha {
                        local idx = `idx' + 1
                        local a_name = subinstr("`a'", ".", ",", .)
                        local addlabel_alpha = `"`addlabel_alpha' "M(`a_name')""'
                        local a_name = subinstr("`a'", ".", "p", .)
                        local a_name = subinstr("`a_name'", "-", "m", .)
                    }
                    local names = `""M0" `addlabel_alpha'"'
                }
                else {
                    local names = `""M0""'
                }
                matrix colnames `decomb_ind_disp_f_`by_s'' = `names'
                matrix colnames `decomb_ind_C_f_`by_s'' = `names'
								
                local e_names = ""
                local lb_ind =  " "
                local lb_dom = " "
                forvalues j = 1 / `ndom' {
                    local lb_dom = `"`lb_dom' "Domain `j'""'
                    local nind`j' = wordcount("`d`j''")

         *Iterate over indicators, create the to-be-estimated variables and the labels.
                    forvalues i = 1 / `nind`j'' {
                        local ind = word("`d`j''", `i')
						local labl: variable label `ind'
                        local lb_ind = `"`lb_ind' "Domain `j':`ind'""''
                    }
                }
            }
	
          *Prepare for display and do consistency checks.          
           if `ni' != 1 {
  
                matrix `disp_f_`by_s'' = (`decomb_ind_disp_f_`by_s'')
				
				*Prepare subpopulation labels
				local levels ""
				
				*Check if the by-variable has a label.
				local by_lab: value label `by'
				if "`by_lab'" != "" {
						local label: label `by_lab' `by_s'
				}
				else {
						local label= `"`by'_`by_s'"'
					 }

				local vlname: value label `sex'
				local vl_`female': label `vlname' `female'		
                matrix rownames `disp_f_`by_s'' = `lb_ind'
				matrix colnames `disp_f_`by_s'' = "`label': `vl_`female''"
				
                matrix rownames `decomb_ind_C_f_`by_s'' = `lb_ind'
				matrix colnames `decomb_ind_C_f_`by_s'' = "`label': `vl_`female''"				
								
				
                if `warn_no_disemp' {
                    noi di as result "Note: No individual is multidimensionally deprived."
                }
                noi display as text ""		
            }
			    				
                matrix `disp_f_sex' = (nullmat(`disp_f_sex'), `disp_f_`by_s'')
                matrix `disp_C_f_sex' = (nullmat(`disp_C_f_sex'), `decomb_ind_C_f_`by_s'')				
    restore
}

		levelsof `by' `l_if', local(by_levels)      
		foreach by_s of local by_levels {	
			
    preserve			
			keep if `by'==`by_s' & `touse'
			keep if `sex'==`male'			
            if `ni' != 1 {
                *Variables for output
                tempname decomb_ind_m_`by_s' decomb_dom_m_`by_s' decomb_ind_V_m_`by_s' decomb_dom_V_m_`by_s' mat_transform_m_`by_s' decomb_ind_C_m_`by_s'

                *Variables for display
                tempname disp_m_`by_s' decomb_ind_disp_m_`by_s' decomb_dom_disp_m_`by_s' 

                noi _3de_domains `"`var_submit'"'
                matrix `decomb_ind_m_`by_s'' = r(weai_decomposed)
                matrix `decomb_ind_C_m_`by_s'' = r(weai_decomposed_C)								
                matrix `decomb_ind_V_m_`by_s'' = r(weai_decomposed_V)
				
				matrix `decomb_ind_C_m_`by_s''=`decomb_ind_C_m_`by_s'''
				
                local ncol = `=1 + wordcount("`alpha'")*`use_thresholds''

                mata: `A'  = st_matrix("r(weai_decomposed)")
                mata: cols = strtoreal(st_local("ncol"))
                mata: `A'  = colshape(`A', cols)
                mata: st_matrix("`decomb_ind_disp_m_`by_s''", `A')

                *Create the correct names.
                if `use_thresholds' {
                    local idx = 0
                    local addlabel_alpha = ""
                    foreach a of local alpha {
                        local idx = `idx' + 1
                        local a_name = subinstr("`a'", ".", ",", .)
                        local addlabel_alpha = `"`addlabel_alpha' "M(`a_name')""'
                        local a_name = subinstr("`a'", ".", "p", .)
                        local a_name = subinstr("`a_name'", "-", "m", .)
                    }
                    local names = `""M0" `addlabel_alpha'"'
                }
                else {
                    local names = `""M0""'
                }
                matrix colnames `decomb_ind_disp_m_`by_s'' = `names'
                matrix colnames `decomb_ind_C_m_`by_s'' = `names'

				
                local e_names = ""
                local lb_ind =  " "
                local lb_dom = " "
                forvalues j = 1 / `ndom' {
                    local lb_dom = `"`lb_dom' "Domain `j'""'
                    local nind`j' = wordcount("`d`j''")

                 *Iterate over indicators, create the to-be-estimated variables and the labels.
                    forvalues i = 1 / `nind`j'' {
                        local ind = word("`d`j''", `i')
                        local lb_ind = `"`lb_ind' "Domain `j':`ind'""''
                    }
                }
            }
		
           *Prepare for display and do consistency checks.           
           if `ni' != 1 {
                matrix `disp_m_`by_s'' = (`decomb_ind_disp_m_`by_s'')
				
				*Prepare subpopulation labels
				local levels ""
				
				*Check if the by-variable has a label.
				local by_lab: value label `by'

				if "`by_lab'" != "" {
						local label: label `by_lab' `by_s'
				}
				else {
						local label= `"`by'_`by_s'"'
					 }

				local vlname: value label `sex'
				local vl_`male': label `vlname' `male'

				
                matrix rownames `disp_m_`by_s'' = `lb_ind' 				
				matrix colnames `disp_m_`by_s'' = "`label': `vl_`male''"
				
                matrix rownames `decomb_ind_C_m_`by_s'' = `lb_ind' 				
				matrix colnames `decomb_ind_C_m_`by_s'' = "`label': `vl_`male''"				
								
                if `warn_no_disemp' {
                    noi di as result "Note: No individual is multidimensionally deprived."
                }
                noi display as text ""		
            }			    			
                matrix `disp_m_sex' = (nullmat(`disp_m_sex'), `disp_m_`by_s'')				
                matrix `disp_C_m_sex' = (nullmat(`disp_C_m_sex'), `decomb_ind_C_m_`by_s'')				
restore  
}			
	  tempname contr_disemp graph_disemp		 
	  levelsof `by' `l_if', local(by_levels)      
	     foreach by_s of local by_levels {
	  	 tempname contr_disemp_`by_s' graph_disemp_`by_s'
		 
		 matrix `contr_disemp_`by_s''=(`disp_f_`by_s'', `disp_m_`by_s'')		 	 
		 matrix `contr_disemp'=(nullmat(`contr_disemp'), `contr_disemp_`by_s'')
		 
		 
		 matrix `graph_disemp_`by_s''=(`decomb_ind_C_f_`by_s'', `decomb_ind_C_m_`by_s'')		 	 
		 matrix `graph_disemp'=(nullmat(`graph_disemp'), `graph_disemp_`by_s'')		 
		 
	    }
		 	 
		 	    tempname contr_disemp_w_decomp
		        matrix `contr_disemp_w_decomp'=(`m_weights', `contr_disemp')
                matrix rownames  `contr_disemp_w_decomp' = `lb_ind' 
				
if "`details'" != "" {				
		 		noi display in gr "Decomposition of the relative contribution of each indicator to disempowerment (%)"		
                noi matlist `contr_disemp_w_decomp', form(%9.2fc) nodotz bor(rows) twidth(30) names(all) aligncolnames(r) 
				noi di as text "Note: `ni' indicators calculated."
				noi display as text "The relative contribution of each indicator to disempowerment reflects how much each indicator" 
				noi display as text "contributes to the disempowerment index (1 - 5/3DE) for women and men in the sample."
				
				putdocx table Table4b = matrix(`contr_disemp_w_decomp'), nformat(%9.2fc) rownames colnames headerrow(4) /// 
												border(all, nil) layout(autofitco) /// 
												title("Decomposition of the relative contribution of each indicator to disempowerment by `by' (%)") ///
												note("Note: `ni' indicators calculated.", font(Aptos, 9)) ///
												note("The relative contribution of each indicator to disempowerment reflects how much each indicator contributes to the disempowerment index (1 - 5/3DE) for women and men in the sample.", font(Aptos, 9))	
				
			   putdocx table Table4b(2,.),  border(bottom, double)
			   putdocx table Table4b(2,.),  border(top, double)
			   putdocx table Table4b(`n_i',.), border(bottom, double)												    
			   putdocx table Table4b(1,.), bold	  												
																								
		 local i 0	     
	     foreach by_s of local by_levels {
	     local ++i
		  
	  	    *Prepare subpopulation labels
            local levels ""            
			*Check if the by-variable has a label.
            local by_lab: value label `by'
			
            if "`by_lab'" != "" {
                    local label: label `by_lab' `by_s'
            }
            else {
                    local label= `"`by'_`by_s'"'
                 }
				 
			  local k=2*`i' +1
			  putdocx table Table4b(2, `k')=(""),            append  linebreak  
			  putdocx table Table4b(2, `k+1')  =("`label'"), append    		  
	  }				
	
*end details
} 		
	 *graph by options
     levelsof `by' `l_if', local(by_levels)      
	 foreach by_s of local by_levels {				
	
		local vlname: value label `sex'
		local vl_`male': label `vlname' `male'
		local vl_`female': label `vlname' `female'
		
		tempname var_colnames_`by_s'
		gen `var_colnames_`by_s'' = ""
		tokenize "`: colnames `graph_disemp_`by_s'''"
		
	    qui forval i = 1/`= rowsof(`graph_disemp_`by_s'')' {

		gen ind_`i' = .	
		qui forval j = 1/`= colsof(`graph_disemp_`by_s'')'   {
		
		replace ind_`i' = `graph_disemp_`by_s''[`i',`j'] in `j'
		replace `var_colnames_`by_s'' = "``j''" in `j'
		}
		 
		getRowName `graph_disemp_`by_s'' `i'
		local lab_ind_`i'=r(rowname)
		rename ind_`i' c_`lab_ind_`i''	
	    }

if "`graph'" != "" {  
	    graph bar  c_* , over(`var_colnames_`by_s'', sort(1) descending) stack ///
        yreverse xalternate graphregion(color(white)) scale(0.91) ///
		bar(1, fc("186 228 179") lc(white) lw(vvthin)) ///
		bar(2, fc("116 196 118")  lc(none) lw(vvthin)) ///
		bar(3, fc("49 163 84")    lc(none) lw(vvthin)) ///
		bar(4, fc("254 237 222")  lc(none) lw(vvthin)) ///
		bar(5, fc("253 208 162")  lc(none) lw(vvthin)) ///
		bar(6, fc("253 174 107") lc(none)  lw(vvthin)) ///
		bar(7, fc("253 141 60")   lc(none) lw(vvthin)) /// 
		bar(8, fc("230 85 13")    lc(none) lw(vvthin)) ///
		bar(9, fc("166 54 3")   lc(none)   lw(vvthin)) ///
		bar(10, fc("188 189 220") lc(none) lw(vvthin)) ///
		legend(cols(1) pos(3) si(vsmall)   lw(vvthin) region(lwidth(none)) ) nolabel ///
		title("{bf:Absolute contribution of each indicator to disempowerment (`by'= `by_s')}", span si(medium) position(11) margin(b=5)) /// 
		subtitle("") ytitle("Disempowerment index", si(small)) yla(, format(%9.1f)) yscale(titlegap(*2.5)) ///
		note("NOTE: `ni' indicators calculated. The absolute contribution to each indicator to disempowerment reflects how much each indicator" "contributes to disempowerment among respondents who have not achieved empowerment." , si(vsmall) margin(medium)) name(weai_by_`by_s', replace)	
 	    
	    graph save "`graph'_by_`by_s'",  replace				
		cap drop c_*
} 		
	    cap drop c_*		
*end graph by options			
} 

*end by option
} 

*------------------------------------------------------------------------------	
*------------------------------------------------------------------------------		

	   *Now we transform indicators back, so 1 identifies adequate.				
		forvalues j=1/`ndom' {
            foreach ind of varlist `d`j'' {
		    recode `ind' (1=0) (0=1) 
			}
		}		
		
		if "`save'" != "" {
		   putdocx save "`save'", replace
		}
		
     }	
	 return clear
end