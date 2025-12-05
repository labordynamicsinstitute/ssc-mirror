/*==================================================================================
Program to perform Monte Carlo simulations through placebo zone. 
See Kettlewell & Siminski 'Optimal Model Selection for RDD and Related Designs'

Authors: Nathan Kettlewell & Peter Siminski
Updated: 1 December 2025
Version: 1.2
==================================================================================*/

capture program drop pzms_sim
program define pzms_sim, eclass
version 12.1
#delimit ;
syntax varlist(min=2 max=2) [if] [in], MAXBW(numlist min=1) [Sims(integer 50) C(real 0) pzms_opts(string) cct_opts(string)] ;
#delimit cr

tokenize "`varlist'"
tempvar d dXrv rv rv2 rv3 rv4 rv5 res rv0_1 res newrv newy

capture ssc install pzms

capture which rdrobust
if _rc == 111 {
	noi di as err "pzms_sim requires the user command {bf:rdobust} to be installed."
	exit
}

capture which betafit
if _rc == 111 {
	noi di as err "pzms_sim requires the user command {bf:betafit} to be installed."
	exit
}

*Preserve dataset
preserve
capture keep `if'
capture keep `in'

qui {
	sum `2', detail
	local rvmin = r(min)
	local rvmax = r(max)
	* fit a beta distribution to the data
	g `rv0_1' = (`2' - `rvmin')/(`rvmax'-`rvmin') // this is the rv rescaled to range from zero to 1
	betafit `rv0_1'
	local alpha = e(alpha)
	local beta = e(beta)

	* first fit a 5th order polynomial with a discontinuity and kink at the threshold
	g `rv' = `2' - `c'
	g `d' = `rv' > 0
	g `rv2' = `rv'^2
	g `rv3' = `rv'^3
	g `rv4' = `rv'^4
	g `rv5' = `rv'^5
	g `dXrv' = `d'*`rv'

	reg `1' `d' `rv' `rv2' `rv3' `rv4' `rv5' `dXrv'

	foreach coef in `d' `rv' `rv2' `rv3' `rv4' `rv5' `dXrv' {
		local b`coef' = _b[`coef']
}
local target = _b[`d']
predict `res', resid
sum `res'
local res_mean = r(mean)
local res_sd = r(sd)

g double `newrv' = .
g double `newy' = .

local z = 0
foreach x in `maxbw' {
	local z = `z'+1
	local mean_ssq_pzms`z' = 0
	local mean_bw_pzms`z' = 0
}	

local mean_ssq_cct = 0
local mean_bw_cct = 0

*Loop through each simulated dataset
forvalues i = 1/`sims' {
	replace `newrv' = rbeta(`alpha', `beta')*(`rvmax'-`rvmin')+`rvmin' 
	replace `rv' = `newrv' - `c'
	replace `d' = `rv' > 0
	replace `dXrv' = `d'*`rv'
	replace `rv2' = `rv'^2
	replace `rv3' = `rv'^3
	replace `rv4' = `rv'^4
	replace `rv5' = `rv'^5
	replace `newy' = `b_cons' +`b`d''*`d' +`b`rv''*`rv' + `b`dXrv''*`dXrv' + `b`rv2''*`rv2' + ///
	`b`rv3''*`rv3' + `b`rv4''*`rv4' + `b`rv5''*`rv5' + rnormal(0,`res_sd')  //simulated dep var
	local z = 0
	foreach x in `maxbw' {
		if `i' == 1 {
			noi di as error _newline "Be mindful of any warning messages (checking maxbw = `x' case...)"
			noi pzms `newy' `newrv', maxbw(`x') c(`c') `pzms_opts' nolog nodisplay(1)  //for first iteration, display pzms output so user sees any warnings
		}
		else {
			pzms `newy' `newrv', maxbw(`x') c(`c') `pzms_opts'
		}
		local z = `z'+1
		local mean_ssq_pzms`z' = `mean_ssq_pzms'`z'+(1/`sims')*(e(pz_est)-`target')^2
		local mean_bw_pzms`z' = `mean_bw_pzms'`z' + (1/`sims')*e(pz_winbw)
	}
	rdrobust `newy' `newrv', c(`c') `cct_opts'
	local mean_ssq_cct = `mean_ssq_cct'+(1/`sims')*(e(tau_cl)-`target')^2
	local mean_bw_cct = `mean_bw_cct' + (1/`sims')*e(h_l)
	if `i' == 1 {
		noi di as text _newline "pzms_sim iterations count below. pzms_sim will perform `sims' simulations."
	}
	noi di "." _cont
	if `i'/50 == round(`i'/50) { 
		noi di as text "     `i'/`sims' reps" _cont
		noi di ""
	}
}
}

local j = wordcount("`maxbw'")
matrix J = J(`j',3,0)  //matrix for storing KS results
matrix colnames J = "Max BW" "RMSE" "Mean BW"

local z = 0
foreach x in `maxbw' {
	local z = `z'+1
	local rmse_pzms = `mean_ssq_pzms'`z'^0.5
	matrix J[`z',1] = `x'
	matrix J[`z',2] = `rmse_pzms'
	matrix J[`z',3] = `mean_bw_pzms'`x'
	noi di _newline
	noi di as result "RMSE KS = `rmse_pzms' with maxbw = `x'"
	noi di as result "Mean bandwidth KS = `mean_bw_pzms'`x' with maxbw = `x'"
}
local rmse_cct = `mean_ssq_cct'^0.5
noi di _newline
noi di as result "RMSE CCT = `rmse_cct'"
noi di as result "Mean bandwidth CCT = `mean_bw_cct'"

capture ereturn clear
capture ereturn matrix pzms_rmse = J
capture ereturn scalar cct_rmse = `rmse_cct'
capture ereturn scalar cct_bw = `mean_bw_cct'

restore
end

