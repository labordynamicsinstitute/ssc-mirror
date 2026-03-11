



clear all

* Set PERSONAL ado folder to the folder where the github ado folder is located
* Then the programs could be run immediately
*sysdir set PERSONAL "C:\Users\JKP\Dropbox\batched bandits\review_package\bbandits\ado" 
sysdir set PERSONAL "C:\Users\JKP\Dropbox\batched bandits\submission_acceptance\package\ado"

* specify a log file
log using example.log, replace


**********************************************************************************
****** Reproduce paper specifications
**********************************************************************************

*** Figure 1 - Graph will always look slightly different because there is no seed for the bbandits_sim function
bbandits_sim 0.5 0.4 0.3, size(100) batch(100) clipping(0.05) decay(0.9) thompson

**** Cumulative rewards *****
set seed 12345
local batch_length = 100

* the classic experiment
* Generate Bernoulli samples with probability 0.5
gen bernoulli1 = runiform() < 0.5

* Generate Bernoulli samples with probability 0.4
gen bernoulli2 = runiform() < 0.4

* Generate Bernoulli samples with probability 0.3
gen bernoulli3 = runiform() < 0.3

gen reward_classic = .
* Replace the first 3333 observations with bernoulli1
replace reward_classic = bernoulli1 in 1/1000

* Replace the next 3333 observations with bernoulli2
replace reward_classic = bernoulli2 in 1001/2000

* Replace the last 3334 observations with bernoulli3
replace reward_classic = bernoulli3 in 2001/`=_N'

** Only optimal arm
gen optimal = bernoulli1

* shuffle variable
shufflevar reward_classic, dropold
rename reward_classic_shuffled reward_classic

collapse (mean) reward (mean) reward_classic (mean) optimal, by(batch)
* Create a cumulative sum and count of rewards
* Batched
gen cumulative_sum = sum(reward)
gen cumulative_count = _n
* Calculate the cumulative mean
gen cumulative_reward = cumulative_sum / cumulative_count

* classic
gen cumulative_sum_classic = sum(reward_classic)
gen cumulative_count_classic = _n
* Calculate the cumulative mean
gen cumulative_reward_classic = cumulative_sum_classic / cumulative_count_classic

* optimal
gen cumulative_sum_optimal = sum(optimal)
gen cumulative_count_optimal = _n
gen cumulative_reward_optimal = cumulative_sum_optimal / cumulative_count_optimal

set scheme sj

local batch_length = `batch_length' -1
* Generate the line plot
twoway (line cumulative_reward batch) (line cumulative_reward_classic batch) (line cumulative_reward_optimal batch), xlabel(0(10)`batch_length') ylabel(0.30(0.05)0.60)  ///
       title("Cumulative Mean Reward by Batch") ///
       xtitle("Batch") ytitle("Cumulative Mean Reward")	 ///
	   legend(order(1 "Bandit" 2 "Classic Experiment" 3 "Optimal only")) graphregion(color(white))     plotregion(color(white))


**** Figure 2 - Graph will always look slightly different because there is no seed for the bbandits_sim function
bbandits_sim 0.5 0.4 0.3, size(200) batch(10) clipping(0.1) thompson plot_thompson

***** Empirical examples from section 6 ******

*Kasy, M. and Sautmann, A. (2021), Adaptive Treatment Assignment in Experiments for Policy Choice. Econometrica, 89: 113-132. https://doi.org/10.3982/ECTA17527

* Generate Table on page 20 and Figure 3 and 4
use "example data\kasy_sautmann_2021.dta", clear
bbandits outcome treatment date , twoptions_sharebybatch(ylabel(0(0.1)0.6))

/*
graph export "figures\ShareArmSelected_kasy_sautmann.png", replace width(1280) name(ShareArmSelected)
graph export "figures\ShareByBatch_kasy_sautmann.png", replace width(1280) name(ShareByBatch)
graph export "figures\StackedShareArmSelected_kasy_sautmann.png", replace width(1280) name(StackedShareByBatch)
graph export "figures\BOLS_kasy_sautmann.png", replace width(1280) name(BOLS)
graph export "figures\OLS_kasy_sautmann.png", replace width(1280) name(OLS)
graph export "figures\CumSharesByBatch_kasy_sautmann.png", replace width(1280) name(CumSharesByBatch)
*/

* Generates among others Figure 5 and Figure 6
use "example data\gaul_et_al_2024.dta", clear
bbandits reward selected trial , twoptions_sharebybatch(ylabel(0(0.1)0.6))

/*
graph export "figures\ShareArmSelected_gaul_et_al.png", replace width(1280) name(ShareArmSelected)
graph export "figures\OLS_gaul_et_al.png", replace width(1280) name(OLS)
graph export "figures\CumSharesByBatch_gaul_et_al.png", replace width(1280) name(CumSharesByBatch)
*/

**********************************************************************************
****** Showcase pacakge functions 
**********************************************************************************
set scheme stcolor // Use colored graphic scheme

*********************************************************
*** bbandit_sim simulation command ***
*********************************************************

*** Epsilon greedy ****
* Default - greedy 
bbandits_sim  1 1 // most simple

* with many arms and adjusted epsilon rate
bbandits_sim  1 1 2 5 6, size(100) batch(10) eps(0.3) // size not divisible by 10

* add eploration phase and decay rate for greedy algorithm
bbandits_sim  1 1 2, size(200) batch(10) eps(0.2) decay(0.9) exploration(3) greedy
matrix list e(decay_rate) // bbandit_sim returns the decay rate of epsilon_greedy

* Change Standard deviation
bbandits_sim  1 1 2, standard_deviations(1 2 3)


*** Bernoulli Thompson Sampling ****
bbandits_sim  0.5 0.5 , size(100) batch(10) clipping(0.05) thompson
* many arms
bbandits_sim  0.1 0.5 0.3 0.2, size(500) batch(10) clipping(0.1) thompson

*** Monte Carlo simulation ***
* Epsilon Greedy
bbandits_sim 1 1, monte_carlo greedy reference_arm(0) arm(1) standard_deviations(1 2) test_value(0) n(1000) eps(0.2) // works
* Thompson Sampling
bbandits_sim 0.5 0.5, monte_carlo thompson n(2000)


*******************************************************************
******* bbandits - Analysis/Inference command
*******************************************************************

*** Inference
bbandits_sim  1 2 1 , greedy eps(0.2) standard_deviations(1 1 1) // From epsilon_greedy algorithm
bbandits reward chosen_arm batch // analyse data with bbandits

* change reference arm
bbandits reward chosen_arm batch, reference_arm(1) no_plot // reference arm goes from 0 to k

* simulate data with thompson algorithm 
bbandits_sim  0.5 0.5 0.3 , size(100) batch(10) clipping(0.1) thompson 
* Analyse and plot beta distributions from thompson sampling
bbandits reward chosen_arm batch, plot_thompson  reference_arm(0)
* analyse weights
matrix list e(batched_ols_weights)
matrix bols_by_weights = e(batched_ols_weights)'  * e(batch_ols_coefficients)
* multiply weights times batch OLS estimates to get BOLS --> weighted average
matrix list bols_by_weights // BOLS estimates are on the diagonal

*****************************************************************************
******** bbandit_initializ/bbandit_update - Run your own adaptive experiment
*****************************************************************************

******** Epsilon Greedy **********************
******* Conduct your own experiment - Fictious school example section 7 **************
clear
set obs 1000  // Create 1000 observations - defines the total size of the experiment

gen ID = ""  // Initialize the string variable

// Loop to populate the variable with "school1", "school2", ..., "school1000"
forval i = 1/1000 {
    qui replace ID = "school_" + string(`i') if _n == `i'
} 


****** Use bbandit_initialize ********

bbandits_initialize, batches(10) arms(3) exploration_phase(2)  // 10 equally sized batches, 3 treatment arms, 2 exploration periods

***** Assign treatment and observe rewards in exploration phase  ******
generate rand = runiform()
replace reward = .

forval i = 1/2{
	
	replace reward = 0 if batch == `i'
	replace reward = 1 if rand < 0.4 & batch == `i' & chosen_arm == 1
	replace reward = 1 if rand < 0.5 & batch == `i' & chosen_arm == 2
	replace reward = 1 if rand < 0.6 & batch == `i' & chosen_arm == 3
	
}

bbandits_update reward chosen_arm_numeric batch, greedy eps(0.3) // excel export option can be added

forval i = 3/10{
	display `i'
	replace reward = 0 if batch == `i'
	replace reward = 1 if rand < 0.4 & batch == `i' & chosen_arm_numeric == 0
	replace reward = 1 if rand < 0.5 & batch == `i' & chosen_arm_numeric == 1
	replace reward = 1 if rand < 0.6 & batch == `i' & chosen_arm_numeric == 2
	capture bbandits_update reward chosen_arm_numeric batch, greedy eps(0.3) 

}

bbandits reward chosen_arm_numeric batch

********* Thompson Sampling with many arms *********************

* simulate and test from thompson 
clear 
clear
set obs 5000  // Create 5000 observations

gen ID = ""  // Initialize the string variable

// Loop to populate the variable with "school1", "school2", ..., "school1000"
forval i = 1/5000 {
    qui replace ID = "school_" + string(`i') if _n == `i'
} 


****** Use bbandit_initialize ********

bbandits_initialize, batches(10) arms(15) exploration_phase(2) // 10 equally sized batches, 3 treatment arms, 2 exploration periods

***** Assign treatment and observe rewards in exploration phase  ******
generate rand = runiform()
replace reward = .

forval i = 1/2{
	
    replace reward = 0 if batch == `i'
  
    replace reward = 1 if rand < 0.20 & batch == `i' & chosen_arm_numeric == 0
    replace reward = 1 if rand < 0.25 & batch == `i' & chosen_arm_numeric == 1
    replace reward = 1 if rand < 0.30 & batch == `i' & chosen_arm_numeric == 2
    replace reward = 1 if rand < 0.35 & batch == `i' & chosen_arm_numeric == 3
    replace reward = 1 if rand < 0.40 & batch == `i' & chosen_arm_numeric == 4
    replace reward = 1 if rand < 0.45 & batch == `i' & chosen_arm_numeric == 5
    replace reward = 1 if rand < 0.50 & batch == `i' & chosen_arm_numeric == 6
    replace reward = 1 if rand < 0.55 & batch == `i' & chosen_arm_numeric == 7
    replace reward = 1 if rand < 0.60 & batch == `i' & chosen_arm_numeric == 8
    replace reward = 1 if rand < 0.65 & batch == `i' & chosen_arm_numeric == 9
    replace reward = 1 if rand < 0.70 & batch == `i' & chosen_arm_numeric == 10
    replace reward = 1 if rand < 0.75 & batch == `i' & chosen_arm_numeric == 11
    replace reward = 1 if rand < 0.80 & batch == `i' & chosen_arm_numeric == 12
    replace reward = 1 if rand < 0.85 & batch == `i' & chosen_arm_numeric == 13
    replace reward = 1 if rand < 0.90 & batch == `i' & chosen_arm_numeric == 14
	
}

bbandits_update reward chosen_arm_numeric batch, thompson clipping(0.02) 

forval i = 3/10 {
    display `i'
    replace reward = 0 if batch == `i'
    
    replace reward = 1 if rand < 0.20 & batch == `i' & chosen_arm_numeric == 0
    replace reward = 1 if rand < 0.25 & batch == `i' & chosen_arm_numeric == 1
    replace reward = 1 if rand < 0.30 & batch == `i' & chosen_arm_numeric == 2
    replace reward = 1 if rand < 0.35 & batch == `i' & chosen_arm_numeric == 3
    replace reward = 1 if rand < 0.40 & batch == `i' & chosen_arm_numeric == 4
    replace reward = 1 if rand < 0.45 & batch == `i' & chosen_arm_numeric == 5
    replace reward = 1 if rand < 0.50 & batch == `i' & chosen_arm_numeric == 6
    replace reward = 1 if rand < 0.55 & batch == `i' & chosen_arm_numeric == 7
    replace reward = 1 if rand < 0.60 & batch == `i' & chosen_arm_numeric == 8
    replace reward = 1 if rand < 0.65 & batch == `i' & chosen_arm_numeric == 9
    replace reward = 1 if rand < 0.70 & batch == `i' & chosen_arm_numeric == 10
    replace reward = 1 if rand < 0.75 & batch == `i' & chosen_arm_numeric == 11
    replace reward = 1 if rand < 0.80 & batch == `i' & chosen_arm_numeric == 12
    replace reward = 1 if rand < 0.85 & batch == `i' & chosen_arm_numeric == 13
    replace reward = 1 if rand < 0.90 & batch == `i' & chosen_arm_numeric == 14

    capture bbandits_update reward chosen_arm_numeric batch, greedy eps(0.3)
}

bbandits reward chosen_arm_numeric batch //, plot_thompson



****************** successive arm elimination (SAE) ******************************

clear
set obs 1000  // Create 1000 observations

gen ID = ""  // Initialize the string variable

// Loop to populate the variable with "school1", "school2", ..., "school1000"
forval i = 1/1000 {
    qui replace ID = "school_" + string(`i') if _n == `i'
} 


bbandits_initialize, batches(5) arms(3) sae  // 10 equally sized batches, 3 treatment arms, 2 exploration periods
di "$active_arms_macro"


* generate some rewards 
generate rand = runiform()
replace reward = .

forval i = 1/1{
	
	replace reward = 0 if batch == `i'
	replace reward = 1 if rand < 0.4 & batch == `i' & chosen_arm == 1
	replace reward = 1 if rand < 0.5 & batch == `i' & chosen_arm == 2
	replace reward = 1.5 if rand < 0.8 & batch == `i' & chosen_arm == 3
	
}

* Update according to the sequential arm elimination algorithm
bbandits_update reward chosen_arm_numeric batch, sae active_arms("$active_arms_macro") batch_sae(5) 

forval i = 2/2{
	
	replace reward = 0 if batch == `i'
	replace reward = 1 if rand < 0.4 & batch == `i' & chosen_arm_numeric == 0
	replace reward = 1 if rand < 0.5 & batch == `i' & chosen_arm_numeric == 1
	replace reward = 1.5 if rand < 0.8 & batch == `i' & chosen_arm_numeric == 2
	
}

di "$active_arms_macro"
bbandits_update reward chosen_arm_numeric batch, sae active_arms("$active_arms_macro") batch_sae(5) 

forval i = 3/3{
	
	replace reward = 0 if batch == `i'
	replace reward = 1 if rand < 0.4 & batch == `i' & chosen_arm_numeric == 0
	replace reward = 1 if rand < 0.5 & batch == `i' & chosen_arm_numeric == 1
	replace reward = 1.5 if rand < 0.8 & batch == `i' & chosen_arm_numeric == 2
	
}

bbandits_update reward chosen_arm_numeric batch, sae active_arms("$active_arms_macro") batch_sae(5) 


forval i = 4/4{
	
	replace reward = 0 if batch == `i'
	replace reward = 1 if rand < 0.4 & batch == `i' & chosen_arm_numeric == 0
	replace reward = 1 if rand < 0.5 & batch == `i' & chosen_arm_numeric == 1
	replace reward = 1.5 if rand < 0.8 & batch == `i' & chosen_arm_numeric == 2
	
}
bbandits_update reward chosen_arm_numeric batch, sae active_arms("$active_arms_macro") batch_sae(5) 
** warning and exit if optimal arm was already detected

 

log close