*! bbandits, version 2, 24.01.2026
*! Authors: Jan Kemper, Davud Rostam-Afschar

*** Import python functions
* Import python functions used for the bbandits package. 
* All function are in the file bbandits_functions.py which has to be in the ado folder (likely under subfolder "py")

python:


from bbandits_functions import *

keys = ['Beta_OLS', 'Beta_BOLS_aggregated', 'Z-value', 'P-value', 'CI_lower_bound_95', 'CI_upper_bound_95', 'Treatment_arm_n', 'Reference_arm_n', 'Standard_error_BOLS', 'Arm_indicator']

keys_stats =  ['optimal_mean', 'optimal_reward', 'actual_reward_mean' , 'actual_reward' , 'uniform_reward_mean', 'uniform_reward']

end


program bbandits, eclass
	version 17
	syntax varlist [if] [in] [, Reference_arm(int 0) Test_value(real 0.0) Plot_thompson STacked histoptions(string asis) twoptions_thompson(string asis) twoptions_ols(string asis) twoptions_bols(string asis) twoptions_sharebybatch(string asis) twoptions_stackedsharebybatch(string asis) twoptions_cumsharesbyybatch(string asis) NO_plot] 

*** Parse 3rd input variable
*di "`3'"
* problem: Data.get requires variable name as string but string stata parser
* returns "var," if "," is placed without space in the syntax "syntax varlist," instead of "syntax varlist ,"
* solution: replace "," with empty space

local var3 = subinstr("`3'", ",", "", .)

* Capture some input errors
local nvars : word count `varlist'
if `nvars' < 3 {
    di as error "bbandits requires at least outcome, treatment, and batch variables."
    di as error "Usage:  bbandits outcome treatment batch"
    exit 198
}

*** Stop the program if there are any missing values
qui count if missing(`1') | missing(`2') | missing(`var3')
if r(N) > 0 {
    display as error "ERROR: Missing values are not allowed in `1', `2', or `var3'."
    exit 198
}

** check if any arm is not played in any batch and warn the user
qui tabulate `2' `var3', matcell(freq)

local zero_found 0
forvalues i = 1/`=rowsof(freq)' {
    forvalues j = 1/`=colsof(freq)' {
        if (freq[`i',`j'] == 0) local zero_found 1
    }
}

if (`zero_found' == 1) {
    di as error "WARNING: One or more batches contain arms that were not played. Such batches are excluded from the corresponding BOLS calculations (see warnings below). To avoid this, ensure that every arm is played in every batch, for example by increasing the clipping rate or epsilon for epsilon-greedy."
}

matrix drop freq
* drop existing alpha_list and beta_list matrices 
capture matrix drop alpha_list beta_list

*******************************************
*** Inference
*******************************************

********* Parsing & pre-processing *******

	capture drop label_chosen_arm
	capture drop chosen_arm_py
	* create a tempvar for chosen_arm
	tempvar chosen_arm_py 
	capture confirm numeric variable `2'
if !_rc {
    * Numeric input → preserve numeric ordering
    egen `chosen_arm_py' = group(`2'), label
	* label variable for exports
	qui tostring `2', gen(label_chosen_arm) force
}
else {
    * String input → group by string labels
    egen `chosen_arm_py' = group(`2'), label
	capture gen label_chosen_arm = `2'

}
	qui replace `chosen_arm_py' = `chosen_arm_py' - 1

	capture confirm variable chosen_arm
	if !_rc {
		// The variable exists, do something
		drop chosen_arm // Not an elegant solution to drop the existing chosen_arm, better to work with tempvars
		gen chosen_arm = `chosen_arm_py'
	}
	else {
		// The variable does not exist, do something else or nothing
		gen chosen_arm = `chosen_arm_py'
	}
	
	*************** Get Data into python *******************
	* run inference command in python
	python: reward, chosen_arm, batch  = Data.get(var="`1'"), Data.get(var="chosen_arm"), Data.get(var="`var3'")
	python: data = pd.DataFrame({"reward": reward, "chosen_arm": chosen_arm, "batch": batch})
	python: results, ereturn_results = bols_inference_k(data, chosen_arm = "chosen_arm", reward = "reward", batch = "batch", reference_arm = `reference_arm', test_value = `test_value')
	*python: print(ereturn_results)
	* save results to matrix
	python: values = [results.get(key) for key in keys]
	python: mat_res = np.array(values).T 
	
	python: batch_beta = ereturn_results["batch_beta"]
	python: weights_bols = ereturn_results["weights_bols"]
	
	* save beta coefficients for each batch
	python: Matrix.store("adaptive_inference", mat_res)
	python: Matrix.setColNames("adaptive_inference", keys)
	
	* beta bols estimates
	python: Matrix.store("batch_beta", batch_beta)
	python: Matrix.store("weights_bols", weights_bols)
	
	*matrix list weights_bols
	ereturn matrix res adaptive_inference 
	ereturn matrix batch_ols_coefficients batch_beta
	ereturn matrix batched_ols_weights weights_bols
	
	* Additional stats from python to stata matrix
	python: values = [ereturn_results.get(key) for key in keys_stats]
	python: mat_add_stats = np.array(values).T 
	python: Matrix.store("mat_add_stats", mat_add_stats)
	python: Matrix.setRowNames("mat_add_stats", keys_stats)

	
	tempname res batch_ols_coefficients batched_ols_weights
	mat `res' = e(res) 
	mat `batch_ols_coefficients' = e(batch_ols_coefficients)
	mat `batched_ols_weights' = e(batched_ols_weights)
	* store estimation results
	* Display the results in a nice fashion
	*** Plot thompson development if specified
	if "`plot_thompson'" == "" & "`stacked'" != ""{
	di in red "please use stacked with plot_thompson. That is specify as option:" in ye " plot_thompson stacked"	
	}
	
	if "`plot_thompson'" != "" {
		
	display "Distribution by batch for Thompson sampling"
		* Get alpha and beta values if it is a thompson algorithm
	python: ts_list = get_alpha_beta(reward, chosen_arm, batch)
		* store values for thompson
	python: Matrix.store("alpha_list", ts_list["alpha_list_cum"])
	python: Matrix.store("beta_list", ts_list["beta_list_cum"])
	
	local batch_size = rowsof(beta_list)
	local arms = colsof(beta_list) 
	di "Number of arms: " + `arms'
	di "Number of batches: " + `batch_size'
				 
		forvalues i =1/`batch_size' {
					local name =  "t" + "`i'"
					di "`name'"

					
					if "`stacked'" == ""{
						local beta_densities
						local legend_label
						forv j=1/`=`arms'' {
							local beta_densities `beta_densities' (function y=betaden(alpha_list[`i', `j'], beta_list[`i', `j'] , x), range(0 1)) 
							local legend_label `legend_label' label(`j' "Arm `=`j'-1'")
									
						   }
						   
						twoway `beta_densities' ///
							   , ///
								name("`name'", replace) legend( `legend_label') `=`"`twoptions_thompson'"''

					}
					if "`stacked'" != ""{
				local combine
				forv j=1/`=`arms'' {

							tw (function y = betaden(alpha_list[`i', `j'], beta_list[`i', `j'],x), range(0.01 0.99) lwidth(medthick)),  ///
						   ytitle("B(`=round(alpha_list[`i', `j'])',`=round(beta_list[`i', `j'])')" "density") ylabel(#0, nolabels nogrid) xlabel(, nogrid) xtitle(Share of successes) plotr(m(zero)) name("g_`j'_`i'", replace) nodraw  `=`"`twoptions_thompson'"'' /**/ 
							local combine "`combine' g_`j'_`i'"
					   }
						gr combine `combine', xcommon col(1) iscale(1) name("combine_`i'", replace)
						}
					
				}
 
}

*** Histogram shares ***	

	tempname res armnr share share2 share_ref N fixed max rewards rewards_bandits rewards_balanced // temp variable leads to not returning the stata estimates
	
	mat `res' = e(res)
	mat `armnr' = .
	
qui tab chosen_arm, matcell(`share')
	mat `rewards' = `res'[1...,1]
	
	mata : st_matrix("`N'", colsum(st_matrix("`share'")))
	
	mat `fixed' = `N'[1,1]*`=1/(`=rowsof(`res')+1')'

	mata : st_matrix("`max'", colmax(st_matrix("`rewards'"))) // Returns maximum reward value
	mata : st_matrix("`share'", st_matrix("`share'")/colsum(st_matrix("`share'")))

if "`no_plot'" == "" {
	qui levelsof chosen_arm

	qui hist chosen_arm , discrete frac xtitle(Treatment Arm) xlabel(0(1)`=max(`=subinstr("`r(levels)'"," ",",",.)')', valuelabel angle(90)) ylabel(#10) xlabel(,nogrid) ytitle("Share of Arm Selected") name("ShareArmSelected", replace) `=`"`histoptions'"''
}

*** Main table ***
        qui su `1' if chosen_arm ==`reference_arm'
        scalar refmean = r(mean)
        mat  `rewards'=`rewards'+J(`=rowsof(`res')', 1, refmean)
	
	
* OLS regression change reference arm
	qui reg `1' ib(`reference_arm').chosen_arm, vce(robust)
	
	*matrix list `share'
*** Remove reference arm from OLS results.
* Depending on whether the reference arm is first (base category),
* last, or in the middle, drop the corresponding row/column from
* the variance–covariance matrix e(V), the coefficient vector e(b),
* and the arm-share vector. Store non-reference-arm results in A,
* b_ols, and share2, and keep the reference-arm share in share_ref.
* case separation necessary because of allowed matrix operations (negative indexing does not work)
	if `reference_arm' == 0 {
	di "Reference arm: `reference_arm'"
    // base category is not in e(V)
    matrix A = e(V)[2..., 2...]
	matrix b_ols = e(b)' 
	matrix b_ols = b_ols[2..., 1...]
	
	* drop the reference arm from the share
	mat `share2'=`share'[2...,1]
	mat `share_ref' = `share'[1,1]
	
}
	else if `reference_arm' == rowsof(`res') {
	di "Reference arm: `reference_arm'"

		matrix A = ///
    e(V)[1..`reference_arm', 1..`reference_arm'] , ///
    e(V)[1..`reference_arm', `=`reference_arm'+2'...]
matrix A = A \ ///
    ( e(V)[`=`reference_arm'+2'..., 1..`reference_arm'] , ///
      e(V)[`=`reference_arm'+2'..., `=`reference_arm'+2'...] )
	
* store OLS stats in named matrices (not tempnames, we reuse them)
    matrix b_ols = e(b)' 
	* adept b_ols
	matrix b_ols = ///
    b_ols[1..`reference_arm', 1...] \ ///
    b_ols[`=`reference_arm'+2'..rowsof(b_ols), 1...]
	
	
	* drop the reference arm from the share
	mat `share2'=`share'[1..`reference_arm',1] // because of this snippet different if command necessary
	mat `share_ref' = `share'[`=`reference_arm'+1',1]
		
	}
	else{
	di "Reference arm: `reference_arm'"
	matrix A = ///
    e(V)[1..`reference_arm', 1..`reference_arm'] , ///
    e(V)[1..`reference_arm', `=`reference_arm'+2'...]
matrix A = A \ ///
    ( e(V)[`=`reference_arm'+2'..., 1..`reference_arm'] , ///
      e(V)[`=`reference_arm'+2'..., `=`reference_arm'+2'...] )
	
* store OLS stats in named matrices (not tempnames, we reuse them)
    matrix b_ols = e(b)' 
	* adept b_ols
	matrix b_ols = ///
    b_ols[1..`reference_arm', 1...] \ ///
    b_ols[`=`reference_arm'+2'..rowsof(b_ols), 1...]
	
	* drop reference arm from share and create share matrix for ref arm
	mat `share2' = `share'[1..`reference_arm', 1...] \ ///
    `share'[`=`reference_arm'+2'..rowsof(`share'), 1...]
	mat `share_ref' = `share'[`=`reference_arm'+1',1]
	
	}
	
	* calculate specific summary stats
	mata : st_matrix("se_ols", sqrt(diagonal(st_matrix("A"))))
	
	*matrix list `share2'
	scalar df_ols = e(df_r)
    local alpha = 0.05

    * t-stats and p-values
    matrix t_ols = J(rowsof(b_ols), 1, .)
    matrix p_ols = J(rowsof(b_ols), 1, .)

    forvalues j = 1/`=rowsof(b_ols)' {      // row 1 = intercept (arm b), j>1 = arm j-1 vs b
        scalar t_j = (b_ols[`j',1]- `test_value') / se_ols[`j',1]
        scalar p_j = 2*ttail(df_ols, abs(t_j))
        matrix t_ols[`j',1] = t_j
        matrix p_ols[`j',1] = p_j
    }

    * 95% robust CI
    matrix ciL_ols = b_ols - invttail(df_ols, 0.5*`alpha')*se_ols
    matrix ciU_ols = b_ols + invttail(df_ols, 0.5*`alpha')*se_ols
	
* =========================
* Compact stacked summary
* =========================

	di in smcl in gr "{hline 71}"

* ---- Totals (left) and means (right) ----
di in smcl in gr ///
    _col(1)  "N"               _col(18) "= " in ye %8.0f `N'[1,1]

di in smcl in gr ///
    _col(1)  "Best-arm total"  _col(18) "= " in ye %8.0f mat_add_stats[2,1] ///
    _col(40) "Best-arm mean"   _col(58) "= " in ye %8.4f mat_add_stats[1,1]

di in smcl in gr ///
    _col(1)  "Actual total"    _col(18) "= " in ye %8.0f mat_add_stats[4,1] ///
    _col(40) "Actual mean"     _col(58) "= " in ye %8.4f mat_add_stats[3,1]

di in smcl in gr ///
    _col(1)  "Uniform total"   _col(18) "= " in ye %8.0f mat_add_stats[6,1] ///
    _col(40) "Uniform mean"    _col(58) "= " in ye %8.4f mat_add_stats[5,1]
	
* ========== Share b + comparison table as ONE box ==========
* Top border with junction at column 9
di in smcl in gr "{hline 8}{c TT}{hline 62}"

* Header for arm b line
di in smcl in gr ///
    "Share b" ///
    _col(9)  "{c |}" ///
    _col(11) "Mean reward arm b"

* Line between header and value
di in smcl in gr "{hline 8}{c +}{hline 62}"

* Arm b values (0.1606 aligned with Marg. below at col 21)
di in smcl ///
    _col(1)  in ye %6.4f `share_ref'[1,1] ///
    _col(9)  in gr "{c |}" ///
    _col(21) in ye %7.4f refmean

* Line between arm b row and main header
di in smcl in gr "{hline 8}{c +}{hline 62}"

* Main header (Share k etc.)
di in smcl in gr ///
    "Share k" ///
    _col(9)  "{c |}" ///
    _col(11) "Arm/Est." ///
    _col(21) "Marg." ///
    _col(30) "Robust SE" ///
    _col(38) "  z" ///
    _col(45) "P>|z|" ///
    _col(54) "[95% CI]"

* Line between header and data rows
di in smcl in gr "{hline 8}{c +}{hline 62}"

forvalues i = 1/`=rowsof(`res')' {

	local arm_val = `res'[`i',10]
	local arm_lab "`arm_val'-`reference_arm'"
	*local arm_lab "`=`res'[`i',10]'" "-" "`reference_arm'"
    *local share_k = `share'[`=`i'+1',1]
	local share_k = `share2'[`i',1]
    * BOLS SE from CI
    *scalar se_bols = (`res'[`i',6] - `res'[`i',5]) / (2*invnormal(0.975))
	scalar se_bols = `res'[`i', 9]

    * ---- Share row for arm k ----
    di in smcl ///
        _col(1)  in ye %6.4f `share_k' ///
        _col(9)  in gr "{c |}" ///
        _col(11) in ye "`arm_lab'"


    * ---- OLS row (robust) ----
	local r = `i' // just loop over i
    di in smcl ///
        _col(1)  " " ///
        _col(9)  in gr "{c |}" ///
        _col(11) in gr "OLS" ///
        _col(21) in ye %7.4f `res'[`i',1]          /// margin OLS (from Python)
        _col(30) in ye %7.4f se_ols[`r',1]         /// robust SE
        _col(38) in ye %6.2f t_ols[`r',1]          /// t (you can still label the column "z")
        _col(45) in ye %6.3f p_ols[`r',1]          /// P>|t|
        _col(54) in ye "[" %6.4f ciL_ols[`r',1] ", " %6.4f ciU_ols[`r',1] "]"


    * ---- BOLS row ----
    di in smcl ///
        _col(1)  " " ///
        _col(9)  in gr "{c |}" ///
        _col(11) in gr "BOLS" ///
        _col(21) in ye %7.4f `res'[`i',2] ///
        _col(30) in ye %7.4f se_bols ///
        _col(38) in ye %6.2f `res'[`i',3] ///
        _col(45) in ye %6.3f `res'[`i',4] ///
        _col(54) in ye "[" %6.4f `res'[`i',5] ", " %6.4f `res'[`i',6] "]"

    mat `armnr' = `armnr' \ `i'
}

* Bottom border with junction at column 9
di in smcl in gr "{hline 8}{c BT}{hline 62}"


	
*** Add conf bands to res matrix - used for ereturn and ols graph
 	tempname ols_ci_l ols_ci_u arm se
	local alpha = 0.05
	
	mat `ols_ci_l' = b_ols - invttail(e(N)-1,0.5*`alpha')*se_ols 
	mat `ols_ci_u' = b_ols + invttail(e(N)-1,0.5*`alpha')*se_ols
	mata : st_matrix("`res'", sort(st_matrix("`res'"), 10))
	*mat `res' = `res' , `ols_ci_l'[2..`=rowsof(`ols_ci_l')-1', 1], `ols_ci_u'[2..`=rowsof(`ols_ci_u')-1', 1]
	mat `res' = `res' , `ols_ci_l'[1..`=rowsof(`ols_ci_l')-1', 1], `ols_ci_u'[1..`=rowsof(`ols_ci_u')-1', 1]
* sort matrix by highest estimate for coefficients plots
mata : st_matrix("`res'", sort(st_matrix("`res'"), 2))

*****************************************************************
********************** Plots ************************************
*****************************************************************

*** BOLS graph ***
if "`no_plot'" == "" { // only when plots allowed
	tempname bols ols ci_l ci_u arm

	qui gen `bols' = `res'[_n,2] in 1/`=rowsof(`res')'
	qui gen `ols' = `res'[_n,1] in 1/`=rowsof(`res')'
	qui gen `ci_l' = `res'[_n,5] in 1/`=rowsof(`res')'
	qui gen `ci_u' = `res'[_n,6] in 1/`=rowsof(`res')'
	qui gen `arm' = _n in 1/`=rowsof(`res')'
	scalar best = `=`res'[`=rowsof(`res')',10]' 
	scalar worst = `=`res'[1,10]'

	local xlab ""
		forvalues i = 1/`=rowsof(`res')' {
			local xlab "`xlab' `i' "`""`=`res'[`i',10]'""'" "
		}
		local x: di "`xlab'"

twoway (scatter `bols' `arm', /*mcolor("142 69 97")*/) ///
       (rcap `ci_l' `ci_u' `arm', /*lcolor("142 69 97")*/) ///
       , legend(off ) yline(0, lpattern(dash) /*lcolor("85 164 168")*/) ///
       xlabel(`x', noticks) ylabel(#6, grid) ///
       xtitle("Arm") ytitle("Treatment Effect") plotregion(margin(b=0)) name("BOLS", replace) ///
	   `=`"`twoptions_bols'"'' 


*** OLS graph ***

	tempname ci_l_ols ci_u_ols arm2 arm

	qui gen `ci_l_ols' = `res'[_n,11] in 1/`=rowsof(`res')'
	qui gen `ci_u_ols' = `res'[_n,12] in 1/`=rowsof(`res')'
	qui gen `arm' = _n in 1/`=rowsof(`res')'
	qui gen `arm2' = `arm'+0.2 in 1/`=rowsof(`res')'
	
twoway (scatter `ols' `arm2', /*mcolor(gs13) m(D)*/) ///
       (rcap `ci_l_ols' `ci_u_ols' `arm2', /*lcolor(gs13)*/) ///
	   (scatter `bols' `arm', /*mcolor("142 69 97")*/) ///
       (rcap `ci_l' `ci_u' `arm', /*lcolor("142 69 97")*/) ///
       , legend(order(1 3) label(1 "OLS") label(3 "BOLS") ) yline(0, lpattern(dash) /*lcolor("85 164 168")*/) ///
       xlabel(`x', noticks) ylabel(#6, grid) ///
       xtitle("Arm") ytitle("Treatment Effect") plotregion(margin(b=0)) name("OLS", replace) ///
	    `=`"`twoptions_ols'"''


*** Share by batch graph ***
tempname all total share cumshare batch_enc
 
capture confirm numeric variable `var3'
if !_rc {
    gen `batch_enc' = `var3'
}
else {
    gen `batch_enc' = 0
    qui replace `batch_enc' = 1 if `var3'[_n] ~= `var3'[_n-1]
    qui replace `batch_enc' = sum(`batch_enc')
}

 
gen `all'=1
preserve
collapse (mean) `1' (count) `all' , by(`batch_enc' chosen_arm)
bys `batch_enc': egen `total'=total(`all')
gen `share'= `all'/`total'
bys `batch_enc': gen `cumshare' = sum(`share')
																																													
local area ""
local line ""
	forvalues i = `=rowsof(`res')'(-1)0 {
		local area "`area' (area `cumshare' `batch_enc' if chosen_arm ==`i', fintensity(100))"
		local line "`line' (line `share' `batch_enc' if chosen_arm ==`i')"
	}
	
qui levelsof `batch_enc' 

qui sum `batch_enc'
tw `line', legend(off) ytitle(Share) xtitle(Batch) ylabel(0(.2)1) xlabel(`r(min)'(1)`r(max)') name("ShareByBatch", replace) ///
`=`"`twoptions_sharebybatch'"''

*** Stacked share by batch graph ***
qui sum `batch_enc'
tw `area', legend(off) ytitle(Share) xtitle(Batch) ylabel(0(.2)1) xlabel(`r(min)'(1)`r(max)') name("StackedShareByBatch", replace) ///
`=`"`twoptions_stackedsharebybatch'"''

*** Cumulative share by batch graph ***
tempname cumall cumttotal cumshare cumshare2

sort chosen_arm `batch_enc'
by chosen_arm: gen `cumall' = sum(`all')
bys `batch_enc' : egen `cumttotal'=total(`cumall')


gen `cumshare'= `cumall'/`cumttotal'
sort `batch_enc' chosen_arm 
by `batch_enc' : gen `cumshare2' = sum(`cumshare')

	
local area ""
	forvalues i = `=rowsof(`res')'(-1)0 {
		local area "`area' (area `cumshare2' `batch_enc' if chosen_arm ==`i', fintensity(100))"
	}
	
qui levelsof `batch_enc'
tokenize "`r(levels)'"
tw `area', legend(off) ytitle(Share) xtitle(Batch) ylabel(0(.2)1) xlabel(`1'(1)`=`1'+r(r)-1') name("CumSharesByBatch", replace) ///
`=`"`twoptions_cumsharesbyybatch'"''

} // end noplot graph
*** restore the main results ***
// Assign new column names to the matrix 'res'
* drop generated matrices for plots etc. 
capture matrix drop ciU_ols ciL_ols p_ols t_ols se_ols b_ols A

matrix colnames `res' = "margin OLS" "margin OLS BOLS" "z" "p-value" ///
                      "95% BOLS conf lower bound"   "95% conf upper bound" "obs reference arm" ///
                      "obs treatment arm" "Standard Error BOLS" "treatment arm indicator" ///
                      "95% OLS conf lower bound" "95% OLS conf upper bound" 

* Return results
ereturn matrix res `res' 
ereturn matrix batch_ols_coefficients `batch_ols_coefficients'
ereturn matrix batched_ols_weights `batched_ols_weights'
ereturn matrix reward_evaluation mat_add_stats
* remove mat add stats
capture matrix drop mat_add_stats

end

