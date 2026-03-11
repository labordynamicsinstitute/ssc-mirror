*! bbandits, version 2, 24.01.2026
*! Authors: Jan Kemper, Davud Rostam-Afschar

*** Import python functions
* Import python functions used for the bbandits package. 
* All function are in the file bbandits_functions.py which has to be in the ado folder (likely under subfolder "py")

python:

from bbandits_functions import *

end


*** stata subroutines

*** epsilon greedy 
* e_greedy
* Runs a batched epsilon-greedy multi-armed bandit algorithm via Python.
* Parses true arm means and (optionally) reward standard deviations from Stata input,
* calls a Python function that simulates arm choices and rewards over batches,
* and returns the chosen arms, observed rewards, and batch indicators as a Stata dataset.
* Also stores the effective decay rate of epsilon as an e-class result.


program e_greedy, eclass
	* syntax	
	syntax anything [, Batch(int 25) Size(int 100) Eps(real 0.1) Exploration(int 0) Decay(real 1) Standard_deviations(numlist)]
		
	capture matrix drop greedy
	* Python parsing
	python: list_of_true_mean = `anything' # Read in anything
	python: list_of_true_mean = list_of_true_mean.split() # Split based on tabs
	python: list_of_true_mean = np.array(list_of_true_mean, dtype = float) # save as float array
	python: list_of_standard_deviations = "`standard_deviations'"
	python: list_of_standard_deviations = list_of_standard_deviations.split()
	python: list_of_standard_deviations = np.array(list_of_standard_deviations, dtype = float)
	
	python: results = check_and_run_greedy(list_of_true_mean, list_of_standard_deviations, greedy_alg_k, `eps', `batch', `size', `exploration', `decay')
	python: keys = ["chosen_arm_list", "rewards_list", "batch_indicator_list"]
	python: values = [results.get(key) for key in keys]
	python: mat_res = np.array(values).T
	
	* save as a matrix in back into stata
	python: Matrix.store("greedy", mat_res)
	
	* Save other outputs as estimation results
	python: decay_res = results["decay_rate"]
	
	python: Matrix.store("decay_res", decay_res)
	* transform into stata dataset
	clear
	qui svmat greedy, names(col)
	rename (c1 c2 c3) (chosen_arm reward batch)
	
	* return estimates
	ereturn matrix decay_rate = decay_res
	
end

*** bernoulli thompson
* thompson_bernoulli
* Implements batched Bernoulli Thompson Sampling using a Python backend.
* Takes true success probabilities for each arm, runs Bayesian updating of Beta priors,
* and returns simulated arm choices, rewards, and batch indicators as a stata dataset
* Also retrieves and stores the evolving alpha/beta posterior parameters and clipping rates.
* Optionally produces plots of the Beta posterior densities for each arm by batch.


program thompson_bernoulli, eclass

	syntax anything [, Batch(int 25) Size(int 100) Clipping(real 0.05) Exploration(int 0) Decay(real 1) Plot_thompson STacked TWoptions(string asis)]
	*drop resulting matrices - otherwise problems when dimensions of outcome matrix changes
	capture matrix drop beta_list
	capture matrix drop alpha_list  
	capture matrix drop thompson
	capture matrix drop clipping_rate
	capture matrix drop true
	* python implementation
	python: list_of_true_mean = `anything'
	python: list_of_true_mean = list_of_true_mean.split()
	python: list_of_true_mean = np.array(list_of_true_mean, dtype = float)
	* run epsilon greedy algorithm from python
	python: results = bernoulli_thompson_batched_clipping(list_of_true_mean, `batch', `size', `clipping', `exploration', `decay')
	python: keys = ["chosen_arm_list", "rewards_list", "batch_indicator_list"]
	python: values = [results.get(key) for key in keys]
	python: mat_res = np.array(values).T
	* Get alpha and beta values into stata
	python: keys = ["alpha_values_list", "beta_values_list"]
	python: values = [results.get(key) for key in keys]
	python: mat_alpha = np.array(values[0])
	python: mat_beta = np.array(values[1])

	* save as a matrix in back into stata
	python: Matrix.store("true", list_of_true_mean)
	python: Matrix.store("thompson", mat_res)
	python: Matrix.store("alpha_list", mat_alpha)
	python: Matrix.store("beta_list", mat_beta)
	* Save other outputs as estimation results
	python: clipping_rate = results["clipping_rate_list"]
	
	python: Matrix.store("clipping_rate", clipping_rate)
	ereturn matrix decay_rate = clipping_rate
* transform into stata dataset
	clear
	qui svmat thompson, names(col)
	rename (c1 c2 c3) (chosen_arm reward batch)	

di `twoptions'
	
	if "`plot_thompson'" == "" & "`stacked'" != ""{
	di in red "please use stacked with plot_thompson. That is specify as option:" in ye " plot_thompson stacked"	
	}
	
	if "`plot_thompson'" != ""{
	* get batch size 
	local batch_size = rowsof(beta_list)
	local arms = colsof(beta_list) 
	di "Number of arms: " + `arms'
	di "Number of batches: " + `batch_size'
	*

		forvalues i =1/`batch_size' {
					local name =  "t" + "`i'"
					di "`name'"
					if "`stacked'" == ""{
						local vertical_line
						local beta_densities
						local legend_label
						forv j=1/`=`arms'' {
							local beta_densities `beta_densities' (function y=betaden(alpha_list[`i', `j'], beta_list[`i', `j'] , x), range(0 1)) 
							local vertical_line `vertical_line' xline(`=true[`j',1]', lpattern(dash) lc(gray) lwidth(medthick))
							local legend_label `legend_label' label(`j' "Arm `j'")
									
						   }
						   
						twoway `beta_densities' ///
							   , ///
							   `vertical_line' ///
								name("`name'", replace) legend( `legend_label') `=`twoptions''

					}
					if "`stacked'" != ""{
				local combine
				forv j=1/`=`arms'' {

							tw (function y = betaden(alpha_list[`i', `j'], beta_list[`i', `j'],x), range(0.01 0.99) lwidth(medthick)),  xline(`=true[`j',1]', lpattern(dash) lc(black) lwidth(medthick)) ///
						   ytitle("B(`=alpha_list[`i', `j']',`=beta_list[`i', `j']')" "density") ylabel(#0, nolabels nogrid) xlabel(, nogrid) xtitle(Share of successes) plotr(m(zero)) name("g_`j'_`i'", replace) nodraw `=`twoptions'' /**/ 
							local combine "`combine' g_`j'_`i'"
					   }
						gr combine `combine', xcommon col(1) iscale(1) name("combine_`i'", replace)
						}
					
				}
	}
	
end 

*** Epsilon Greedy Monte Carlo simulation
* epsilon_greedy_simulation
* Performs a Monte Carlo study of the epsilon-greedy bandit algorithm.
* Repeats the full adaptive experiment N times in Python and collects test statistics
* (standard OLS and heteroskedastic robust OLS/BOLS) for treatment effect inference.
* Outputs the simulated test statistics as a Stata dataset and can plot their
* empirical distributions against the standard normal benchmark.

program epsilon_greedy_simulation
	version 17
	syntax anything [, Batch(int 25) Size(int 100) Eps(real 0.1) N(int 1000) Decay(real 1) Reference_arm(int 0), Arm(int 1), Test_value(real 0.0) Exploration(int 0) Plot TWoptions(string asis) STandard_deviations(numlist)]
	capture matrix drop	greedy_simulation
	python: list_of_true_mean = `anything'
	python: list_of_true_mean = list_of_true_mean.split()
	python: list_of_true_mean = np.array(list_of_true_mean, dtype = float)
	* correct for non given standard deviations
	if "`standard_deviations'" == "" {
		
	python: list_of_standard_deviations = [1] * len(list_of_true_mean)
	python: print("Standard deviations not provided. For all arms, standard deviations for the normal distributions of rewards are set to 1.")
		
	}
	else {
		
	python: list_of_standard_deviations = "`standard_deviations'"
	python: list_of_standard_deviations = list_of_standard_deviations.split()
	python: list_of_standard_deviations = np.array(list_of_standard_deviations, dtype = float)
	
		
	}
	* run epsilon greedy algorithm from python
	python: results = simulation_greedy(`n' ,list_of_true_mean, list_of_standard_deviations, `eps', `batch', `size', `exploration', `decay', `reference_arm', `arm', `test_value')
	python: keys = ["beta_test_statistic", "bols_test_statistic"]
	python: values = [results.get(key) for key in keys]
	python: mat_res = np.array(values).T
	* save as a matrix in back into stata
	python: Matrix.store("greedy_simulation", mat_res)

* transform into stata dataset
clear
qui svmat greedy_simulation, names(col)
rename (c1 c2) (beta_test_statistic bols_test_statistic)

tokenize `anything'
local k : display %04.3f `1'
local l : display %04.3f `2'
if "`plot'" != ""{


	tw (hist beta_test_statistic , width(0.1)) ///
	(kdensity beta_test_statistic) ///
	(function y=normalden(x, 0, 1) , range( -3.5 3.5)) ///
	, legend(off) name(OLS, replace) xtitle("OLS test statistic with true values " "`k', `l'" " batch size=`=`size'' with `=`batch'' batches, repetitions=`=`n''" "Kernel density of normal distribution at zero")  `=`twoptions'' xline(0, lp(dash) lc(gs6))

	tw (hist bols_test_statistic , width(0.1)) ///
	(kdensity bols_test_statistic) ///
	(function y=normalden(x, 0, 1) , range(-4 4)) ///
	, legend(off) name(BOLS, replace) xtitle("BOLS test statistic with true values " "`k', `l'" " batch size=`=`size'' with `=`batch'' batches, repetitions=`=`n''" "Kernel density of normal distribution at zero")  `=`twoptions'' xline(0, lp(dash) lc(gs6))

}

end

*** Bernoulli Thompson Monte Carlo simulation 
* bernoulli_thompson_simulation
* Monte Carlo simulation for the Bernoulli Thompson Sampling algorithm.
* Repeats the adaptive allocation process many times using binary rewards,
* computes OLS and heteroskedastic-robust BOLS test statistics for a target arm comparison,
* and returns their sampling distributions in Stata.
* Optional plots compare the empirical distributions to the normal reference.

program bernoulli_thompson_simulation
	version 17
	syntax anything [, Batch(int 25) Size(int 100) Clipping(real 0.05) Test_value(real 0.0) Reference_arm(int 0) Arm(int 1) Exploration(int 0) N(int 1000) Plot TWoptions(string asis)] // Here clipping noch einführen
	* drop resulting matrix
	capture matrix drop thompson_simulation
	* python
	python: list_of_true_mean = `anything'
	python: list_of_true_mean = list_of_true_mean.split()
	python: list_of_true_mean = np.array(list_of_true_mean, dtype = float)
	* run epsilon greedy algorithm from python
	python: results = simulation_thompson(`n' ,list_of_true_mean, `batch', `size', `clipping', `exploration', `reference_arm', `arm', `test_value')
	python: keys = ["beta_test_statistic", "bols_test_statistic"]
	python: values = [results.get(key) for key in keys]
	python: mat_res = np.array(values).T
	* save as a matrix in back into stata
	python: Matrix.store("thompson_simulation", mat_res)

* transform into stata dataset
clear
qui svmat thompson_simulation, names(col)
rename (c1 c2) (beta_test_statistic bols_test_statistic)

tokenize `anything'
local k : display %04.3f `1'
local l : display %04.3f `2'
if "`plot'" != ""{


	tw (hist beta_test_statistic , width(0.1)) ///
	(kdensity beta_test_statistic) ///
	(function y=normalden(x, 0, 1) , range( -4 4)) ///
	, legend(off) name(OLS, replace) xtitle("OLS test statistic with true values " "`k', `l'" " batch size=`=`size'' with `=`batch'' batches, repetitions=`=`n''" "Kernel density of normal distribution at zero")  `=`twoptions'' xline(0, lp(dash) lc(gs6))

	tw (hist bols_test_statistic , width(0.1)) ///
	(kdensity bols_test_statistic) ///
	(function y=normalden(x, 0, 1) , range(-4 4)) ///
	, legend(off) name(BOLS, replace) xtitle("BOLS test statistic with true values " "`k', `l'" " batch size=`=`size'' with `=`batch'' batches, repetitions=`=`n''" "Kernel density of normal distribution at zero")  `=`twoptions'' xline(0, lp(dash) lc(gs6))

}

end

*** Master command
* bbandits_sim
* Master wrapper that selects and runs one of the bandit procedures.
* Depending on options, it executes either epsilon-greedy or Thompson Sampling,
* in single-run mode or Monte Carlo simulation mode.
* Performs basic input validation (e.g., probability bounds, minimum batch size)
* and forwards all relevant parameters to the appropriate subroutine,
* optionally triggering posterior or simulation result plots.


program bbandits_sim

syntax anything [, Batch(int 25) Size(int 100) Eps(real 0.1) Clipping(real 0.05) EXploration_phase(int 0) Test_value(real 0.0) Greedy Thompson Monte_carlo N(int 1000) Decay(real 1) Reference_arm(int 0) Arm(int 1) Plot_thompson STacked TWopts(string asis) STAndard_deviations(numlist)]
	
if ("`greedy'" != "" & "`monte_carlo'" == "") | ("`greedy'" == "" & "`thompson'" == "" ){ /// Default value epsilon greedy
	
	display "Epsilon greedy"
	* Check if the sample size (or any relevant scalar) is too small
	if `size' < 2 {
    display as error "ERROR: For Epsilon Greedy, the batch size has to be at least 2."
    exit 198
}
	
	e_greedy "`anything'", batch(`batch') size(`size') eps(`eps') decay(`decay') standard_deviations(`standard_deviations') exploration(`exploration_phase')

	}

if "`thompson'" != "" & "`monte_carlo'" == "" {
	
	*** detect syntax errors
	* Input greater than 1
	 foreach var of local anything {
        // Check if the current input value is greater than 1
        if `var' > 1 {
            // Display an error message
            di as error "Error: Input value `" `var' "' is greater than 1. The Bernoulli Thompson algorithm only permits valid probabilities ([0,1])"
            // Exit the program
            exit 198
        }
    }
	
	display "Thompson algorithm"
	thompson_bernoulli "`anything'", batch(`batch') size(`size') clipping(`clipping') exploration(`exploration_phase') decay(`decay') `plot_thompson' `stacked' tw(`"`twopts'"')
}	

*** Monte Carlo 
* Epsilon greedy 
if "`monte_carlo'" != "" & "`greedy'" != "" {
	
	display "Epsilon greedy - Monte Carlo simulation"
	epsilon_greedy_simulation "`anything'", batch(`batch') size(`size') eps(`eps') test_value(`test_value') reference_arm(`reference_arm') arm(`arm') n(`n') exploration(`exploration_phase') plot tw(`"`twopts'"') standard_deviations(`standard_deviations') /// Always plot
	
}

if "`monte_carlo'" != "" & "`thompson'" != "" {
	
	display "Bernoulli thompson sampling - Monte Carlo simulation"
	bernoulli_thompson_simulation "`anything'", batch(`batch') size(`size') clipping(`clipping') test_value(`test_value') reference_arm(`reference_arm') arm(`arm') n(`n') plot tw(`"`twopts'"') /// Always plot
	
}

end



