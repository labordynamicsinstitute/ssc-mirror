*! bbandits, version 2, 24.01.2026
*! Authors: Jan Kemper, Davud Rostam-Afschar

*** Import python functions
* Import python functions used for the bbandits package. 
* All function are in the file bbandits_functions.py which has to be in the ado folder (likely under subfolder "py")

python:


from bbandits_functions import *

keys = ['Beta_OLS', 'Beta_BOLS_aggregated', 'Z-value', 'P-value', 'CI_lower_bound_95', 'CI_upper_bound_95', 'Treatment_arm_n', 'Reference_arm_n']

end


program bbandits_update
	version 17
	* input reward , chosen_arm, batch, [options]
	syntax varlist [, Thompson Greedy SAE Clipping(real 0.05) Epsilon(real 0.1) Seed(integer 1234) EXcel(string) ACtive_arms(numlist) BAtch_sae(int 3)]
	
	*** Exit the program if certain arguments are not given:
	if "`thompson'" == "" &  "`greedy'" == "" & "`sae'" == "" {
        display as error "No Algorithm provided. Exiting early."
        exit   // <-- stops the program here
    }
	
	*** If chosen_arm or reward has no missing values -- nothing can be updated, stop the program
	    // Count missing values
    quietly count if missing(`1')

    // If no missing values, warn and exit
    if r(N) == 0 {
        di as error "Error: Variable `1' has no missing values. The program stops here. Missing values for to be updated units in the reward variable are required to determine which parts of the data are going to get updated. Look at the examples in the help file for the required data structure."
        exit 198
    }
	
	quietly count if missing(`2')

    // If no missing values, warn and exit
    if r(N) == 0 {
        di as error "Error: Variable `2' has no missing values. The program stops here. Missing values for to be updated units in the 'chosen arm' variable are required to determine which parts of the data are going to get updated. Look at the examples in the help file for the required data structure."
        exit 198
    }
	
	
	*** Parse input -> so that chosen_arm is from 0-k in the python function
	capture drop label_chosen_arm
	capture drop chosen_arm_py
	* create a tempvar for chosen_arm
	tempvar chosen_arm_py 
	capture confirm numeric variable `2'
if !_rc {
    * Numeric input → preserve numeric ordering
    qui egen `chosen_arm_py' = group(`2'), label
	* label variable for exports
	qui tostring `2', gen(label_chosen_arm) force
}
else {
    * String input → group by string labels
	  display as error "Error: The assigned arm variable (input 2) is required to be numeric. It is recommended to number the arms from 0 up to arm k."
      exit   // <-- stops the program here
	
}
	qui replace `chosen_arm_py' = `chosen_arm_py' - 1

	capture confirm variable chosen_arm
	if !_rc {
		// The variable exists, do something
		drop chosen_arm // Not an elegant solution to drop the existing chosen_arm, better to work with tempvars
		qui gen chosen_arm = `chosen_arm_py'
	}
	else {
		// The variable does not exist, do something else or nothing
		qui gen chosen_arm = `chosen_arm_py'
	}
	
	
	*** Exit program if chosen arm is given but not sufficient rewards 
	* Count missing values
	qui count if missing(chosen_arm)
	local n_missing_arm = r(N)

	qui count if missing(`1')
	local n_missing_reward = r(N)

	* Check if missing rewards exceed missing arms
	if `n_missing_reward' > `n_missing_arm' {
		display as error "ERROR: More chosen arm data points (`n_missing_arm') than assigned arm data points (`n_missing_reward'). Both have to match. It is likely that the bbandits_update function was run twice or that there are missing values. Ensure that these dimension match, then run the command again. The program exits now."
		exit 198
	}
	
	
	*** Parse 3rd input variable
	* problem: Data.get requires variable name as string but string stata parser
	* returns "var," if "," is placed without space in the syntax "syntax varlist," instead of "syntax varlist ,"
	* solution: replace "," with empty space
	local var3 = subinstr("`3'", ",", "", .)
	dis "`var3'"

	* run inference command in python
	python: df = pd.DataFrame({"reward": stata_to_numpy(Data.get(var="`1'")), "chosen_arm": Data.get(var="chosen_arm"),"batch": stata_to_numpy(Data.get(var="`var3'")), "label_chosen_arm":Data.get(var="label_chosen_arm") })
	

	python: df.loc[df["chosen_arm"] > 100000000000, "chosen_arm"] = np.nan
	python: df["chosen_arm"] = df["chosen_arm"].astype("Int64")  # nullable integer

	* correct nan values
	python: df.loc[df['reward'] == -2147483648 , 'reward'] = np.nan # Because nans are wrongly read in
	python: pre = thompson_updating_preprocessing(df)
	python: t1 = pre["df"]
	python: next_batch = pre["next_batch"]
	*** Chose algorithm ***
	if  "`sae'" != ""{
		display("Sequential Arm Elimination (SAE) Algorithm")
		* Integrate check that active arms are given
		if "`active_arms'" == "" {
        display as error "WARNING: You must specify the option active_arms() which requires a numlist of the arms that are still active according to selected elimination arm algorithm."
        exit 198
    }
		* list of active arms
		python: list_active_arms = "`active_arms'"
		python: list_active_arms = list_active_arms.split()
		python: list_active_arms = np.array(list_active_arms, dtype = int)
		python: list_active_arms_len = len(list_active_arms)
		* return value to stata and stop program if only one active arm is left
		python: Scalar.setValue('e(active_arms_len)', list_active_arms_len)
		if `e(active_arms_len)' == 1 {
			di "Number of active arms: " `e(active_arms_len)'
			display as error "WARNING: Only one remaining arm active. The program will stop here. The remaining arm can be played for the rest of the sample."
			exit
}
		python: arms = df["chosen_arm"].nunique()
		python: res = esfandiari_update(df = df,arms = arms, active_arms = list_active_arms, batch = `batch_sae')
		python: final = res["df"]
		python: print(f"The active arms are: {res['active_arms']}")
		*** Now return the results into eresults
		python: t = pd.DataFrame({"active_arms": res["active_arms"]})
		* merge labels to numeric chosen_arm values
		* clear estimation results
		ereturn clear
		python: Matrix.store("e(active_arms)", t['active_arms'])
		* also send it via a macro
		python: active_arms_stata = " ".join(str(x) for x in res["active_arms"])
		python: Macro.setGlobal('active_arms_macro', active_arms_stata)

	}
	if "`thompson'" != "" {
		
		display("Thompson sampling algorithm arm probabilities:")
		
		python: probabilities, exact_values = thompson_updating(t1["chosen_arm"].astype(int), t1["reward"], t1["batch"], pre["batch_size"], clipping_rate = `clipping')
		* Display and store results
		python: arm_values = pre["arm_values"]
		python: Matrix.store("e(probabilities)", probabilities)
		python: Matrix.store("e(arm_labels)", arm_values)
		python: arm_values_str = [str(i) for i in arm_values]
		python: Matrix.setRowNames("e(probabilities)", arm_values_str)

		python: final = update_randomization(df, next_batch, probabilities, arm_values)

	} 
	else if "`greedy'" != "" {
		
		display("Epsilon Greedy algorithm arm probabilities:")
		python: shares, chosen_arms, arm_values = epsilon_greedy_updating(t1["chosen_arm"].astype(int), t1["reward"], t1["batch"], pre["batch_size"],  epsilon = `epsilon')
		python: Matrix.store("e(probabilities)", shares)
		python: Matrix.store("e(arm_labels)", arm_values)
		python: final = update_shuffling(df, next_batch, chosen_arms)

	}

*  for greedy and thompsons
	* Merge 
	python : unique_pairs = df[['chosen_arm', 'label_chosen_arm']].drop_duplicates() # Merge the original DataFrame with unique_pairs to replace chosen_arm with chosen_arm_label
	* Only keep unique pairs, sometimes missing is "." or "" - drop both
	python: unique_pairs = unique_pairs[unique_pairs["label_chosen_arm"] != "."]
	python: unique_pairs = unique_pairs[unique_pairs["label_chosen_arm"] != ""]

	python: final = final.drop(columns='label_chosen_arm') # Drop chonsen_arm_label so that the new label can be merged 
	python: final = final.merge(unique_pairs, on='chosen_arm', how='left')
	python: final["label_chosen_arm"] = final["label_chosen_arm"].astype(str)

	
	*** Initialize variables in stata
	capture drop chosen_arm 
	capture drop reward 
	capture drop batch
	capture drop chosen_arm_numeric
	capture drop label_chosen_arm // could also be a tempvar
	qui gen reward = .
	qui gen chosen_arm = ""
	qui gen batch = .
	qui gen chosen_arm_numeric = .
	
	python: chosen_arm_numeric = final["chosen_arm"].astype("float").to_numpy() # because pandas NA values not allowed
	
	python: Data.store("reward", None, final['reward'], None)
	python: Data.store("chosen_arm", None, final['label_chosen_arm'], None)
	python: Data.store("batch", None, final['batch'], None)
	python: Data.store("chosen_arm_numeric", None, chosen_arm_numeric, None)

	* fix "nan" should be come .
	qui replace chosen_arm = "" if chosen_arm == "nan"

	if "`thompson'" != "" | "`greedy'" != "" {
		
		*
		display("Present results")
		* Get scalar value
		python: current_batch = next_batch-1
		python: Scalar.setValue('e(current_batch)', current_batch)
		
		* format returns
			*** Update
		* Display results nicely:
		tempname value name
		mat `value' = e(probabilities)
		mat `name' = e(arm_labels)
		local rows = rowsof(`name')
		* Display the header
		   display "Arm Label Numeric        Probability"
		forval i = 1/`rows' {
			local name1 = `name'[`i', 1]
			local value1 = `value'[`i', 1]
			display "Arm `name1'            = `value1'"
			
		}
	
	}
   * If `excel' option is provided, proceed with exporting to Excel
    if "`excel'" != "" {
		capture drop `chosen_arm_py' // tempvar should not be displayed in excel file
        local path "`excel'"
		export excel using "`path'", firstrow(variables) replace
    }
	
end	





