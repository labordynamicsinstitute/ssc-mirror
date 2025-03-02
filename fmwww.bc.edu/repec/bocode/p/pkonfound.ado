* This version contains small patches for resolving unconditional ITCV sign error and default `replace' setting.
* for help file
* this part "replace(#) Whether using entire sample or the control group to calculate the base rate; the default value is control replace(0), to change to entire use replace(1)"
* should be changed as "replace(#) Whether using entire sample or the control group to calculate the base rate; the default value is control replace(1), to change to entire use replace(0)"


* made by JC 111924 / edited by JC 022825

// #1
capture program drop isinvalidate
program define isinvalidate, rclass
version 16.0
	
syntax anything

local thr_t :word 1 of `anything'
local ob_t :word 2 of `anything'

	
if ((0 < `thr_t' & `thr_t' < `ob_t') | (`ob_t' < `thr_t' & `thr_t' < 0)) {
	local x=1
	dis "`x'"
  } 
 else {
	local x=0
	dis "`x'"
 }
 
return local isinva =`x'
end
	
// #2
capture program drop isdcroddsratio
program define isdcroddsratio, rclass
version 16.0
	
syntax anything

local thr_t :word 1 of `anything'
local ob_t :word 2 of `anything'

	
if (`thr_t' < `ob_t') {
	local x=1
	dis "`x'"
  }   
 else {
	local x=0
	dis "`x'"
 }

return local isdcrodds =`x'
end

// #3
capture program drop geta1kfnl
program define geta1kfnl, rclass
version 16.0
	
syntax anything

local odds_ratio :word 1 of `anything'
local std_err :word 2 of `anything'
local n_obs :word 3 of `anything'
local n_trm :word 4 of `anything'


// Step 1: Calculate a1_1 and round it
local a1_1 = -(1 / round((2 * (1 + `odds_ratio'^2 + `odds_ratio' * (-2 + `n_trm' * `std_err'^2))), 0.0001))

// Step 2: Calculate a1_2 and round it
local a1_2 = round(2 * `n_trm' * (-1 + `odds_ratio') * `odds_ratio' + `n_trm'^2 * `odds_ratio' * `std_err'^2 - `n_obs' * `odds_ratio' * (-2 + 2 * `odds_ratio' + `n_trm' * `std_err'^2), 0.0001)

// Step 3: Calculate the temp_value and round it
local temp_value = round(`n_trm' * (-`n_obs' + `n_trm') * `odds_ratio' * (4 + 4 * `odds_ratio'^2 + `odds_ratio' * (-8 + 4 * `n_obs' * `std_err'^2 - `n_obs' * `n_trm' * `std_err'^4 + `n_trm'^2 * `std_err'^4)), 0.0001)


// Step 4: Check if temp_value is negative and adjust slightly to avoid imaginary numbers
if `temp_value' < 0 {
    local temp_value = 0.00000001  // Small positive adjustment to avoid imaginary number
    //di as error "Warning: Adjusting temp_value to avoid imaginary number."
}

// Step 5: Calculate a1_3 (apply square root on rounded temp_value)
local a1_3 = sqrt(`temp_value')

// Step 6: Combine the components to calculate final a1 
local a1 = `a1_1' * (`a1_2' + `a1_3')

dis "`a1'"
return local a1kfnl = `a1'

end

// #4
capture program drop getc1kfnl
program define getc1kfnl, rclass
version 16.0
syntax anything

local odds_ratio :word 1 of `anything'
local std_err :word 2 of `anything'
local n_obs :word 3 of `anything'
local n_trm :word 4 of `anything'


// Step 1: Calculate the expression inside the square root and round it
local inside_sqrt_exp = round(`n_trm' * (-`n_obs' + `n_trm') * `odds_ratio' * (4 + 4 * `odds_ratio'^2 + `odds_ratio' * (-8 + 4 * `n_obs' * `std_err'^2 - `n_obs' * `n_trm' * `std_err'^4 + `n_trm'^2 * `std_err'^4)), 0.0001)

// Step 2: Check if inside_sqrt_exp is negative and adjust slightly to avoid imaginary numbers
if `inside_sqrt_exp' < 0 {
    local inside_sqrt_exp = 0.00000001  // Small positive adjustment to avoid imaginary number
    //di as error "Warning: Adjusting inside_sqrt_exp to avoid imaginary number."
}

// Step 3: Calculate the square root of the rounded expression
local sqrt_value = sqrt(`inside_sqrt_exp')

// Step 4: Calculate c1 using the rounded and adjusted values
local c1 = -((-2 * `n_trm' + 2 * `n_trm' * `odds_ratio' - `n_obs' * `n_trm' * `odds_ratio' * `std_err'^2 + `n_trm'^2 * `odds_ratio' * `std_err'^2 + `sqrt_value') / (2 * (1 + `odds_ratio'^2 + `odds_ratio' * (-2 + `n_obs' * `std_err'^2 - `n_trm' * `std_err'^2))))

// Step 5: Display the calculated c1 value
dis "`c1'"

return local c1kfnl = `c1'

end

// #5
capture program drop geta2kfnl
program define geta2kfnl, rclass
version 16.0

syntax anything

local odds_ratio :word 1 of `anything'
local std_err :word 2 of `anything'
local n_obs :word 3 of `anything'
local n_trm :word 4 of `anything'


// Step 1: Calculate a2_1 and round it
local a2_1 = (1 / round((2 * (1 + `odds_ratio'^2 + `odds_ratio' * (-2 + `n_trm' * `std_err'^2))), 0.0001))

// Step 2: Calculate a2_2 and round it
local a2_2 = round(-2 * `n_trm' * (-1 + `odds_ratio') * `odds_ratio' - `n_trm'^2 * `odds_ratio' * `std_err'^2 + `n_obs' * `odds_ratio' * (-2 + 2 * `odds_ratio' + `n_trm' * `std_err'^2), 0.0001)

// Step 3: Calculate the temp_value and round it
local temp_value = round(`n_trm' * (-`n_obs' + `n_trm') * `odds_ratio' * (4 + 4 * `odds_ratio'^2 + `odds_ratio' * (-8 + 4 * `n_obs' * `std_err'^2 - `n_obs' * `n_trm' * `std_err'^4 + `n_trm'^2 * `std_err'^4)), 0.0001)

// Step 4: Check if temp_value is negative and adjust slightly to avoid imaginary numbers
if `temp_value' < 0 {
    local temp_value = 0.00000001  // Small positive adjustment to avoid imaginary number
    //di as error "Warning: Adjusting temp_value to avoid imaginary number."
}

// Step 5: Calculate a2_3 (apply square root on rounded temp_value)
local a2_3 = sqrt(`temp_value')

// Step 6: Combine the components to calculate final a2 and display it
local a2 = `a2_1' * (`a2_2' + `a2_3')

dis "`a2'"
return local a2kfnl = `a2'
end

// #6
capture program drop getc2kfnl
program define getc2kfnl,rclass
version 16.0

syntax anything

local odds_ratio :word 1 of `anything'
local std_err :word 2 of `anything'
local n_obs :word 3 of `anything'
local n_trm :word 4 of `anything'


// Step 1: Calculate the expression inside the square root for c2 and round it
local inside_sqrt_exp_c2 = round(`n_trm' * (-`n_obs' + `n_trm') * `odds_ratio' * (4 + 4 * `odds_ratio'^2 + `odds_ratio' * (-8 + 4 * `n_obs' * `std_err'^2 - `n_obs' * `n_trm' * `std_err'^4 + `n_trm'^2 * `std_err'^4)), 0.0001)

// Step 2: Check if inside_sqrt_exp_c2 is negative and adjust slightly to avoid imaginary numbers
if `inside_sqrt_exp_c2' < 0 {
    local inside_sqrt_exp_c2 = 0.00000001  // Small positive adjustment to avoid imaginary number
    //di as error "Warning: Adjusting inside_sqrt_exp_c2 to avoid imaginary number."
}

// Step 3: Calculate the square root of the rounded expression for c2
local sqrt_value_c2 = sqrt(`inside_sqrt_exp_c2')

// Step 4: Calculate c2 using the rounded and adjusted values
local c2 = (2 * `n_trm' - 2 * `n_trm' * `odds_ratio' + `n_obs' * `n_trm' * `odds_ratio' * `std_err'^2 - `n_trm'^2 * `odds_ratio' * `std_err'^2 + `sqrt_value_c2') / (2 * (1 + `odds_ratio'^2 + `odds_ratio' * (-2 + `n_obs' * `std_err'^2 - `n_trm' * `std_err'^2)))

dis "`c2'"
return local c2kfnl = `c2'

end


// #7
capture program drop taylorexp
program define taylorexp, rclass
version 16.0

syntax anything

local a1 :word 1 of `anything'
local b1 :word 2 of `anything'
local c1 :word 3 of `anything'
local d1 :word 4 of `anything'
local q :word 5 of `anything'
local thr :word 6 of `anything'

if (`q' > 0 & `d1' - `q' < 0){
	local q = `d1' - 1
}

if (`q' < 0 & `c1' + `q' < 0){
	local q = 1 - `c1'
}

local num1 = 2 * `b1' * (`c1' + `q') * (-`a1' * (`d1' - `q') / (`b1' * (`c1' + `q')^2) - `a1' / (`b1' * (`c1' + `q'))) * log(`a1' * (`d1' - `q') / (`b1' * (`c1' + `q')))

local den1 = `a1' * (`d1' - `q') * (1 / `a1' + 1 / `b1' + 1 / (`d1' - `q') + 1 / (`c1' + `q'))

local num2 = (1 / (`d1' - `q')^2 - 1 / (`c1' + `q')^2) * (log(`a1' * (`d1' - `q') / (`b1' * (`c1' + `q'))))^2

local den2 = (1 / `a1' + 1 / `b1' + 1 / (`d1' - `q') + 1 / (`c1' + `q'))^2

// d1square is the first derivative of the squared term
local d1square = `num1' / `den1' - `num2' / `den2'

// d1unsquare is the first derivative of the unsquared term
local d1unsquare = `d1square' / (2 * log(`a1' * (`d1' - `q') / (`b1' * (`c1' + `q'))) / sqrt(1 / `a1' + 1 / `b1' + 1 / (`c1' + `q') + 1 / (`d1' - `q')))

// x is the number of cases need to be replaced solved based on the taylor expansion
// this is the (linear approximation) of the original/unsquared term around the value of q
local x = (`thr' - log(`a1' * (`d1' - `q') / (`b1' * (`c1' + `q'))) / sqrt((1 / `a1' + 1 / `b1' + 1 / (`c1' + `q') + 1 / (`d1' - `q')))) / `d1unsquare' + `q'

// edit 092924
if missing(`x') {
    local x = 0
}

dis `x'
return local taylor =`x'
end

// #8
capture program drop gettkfnl
program define gettkfnl, rclass
version 16.0

syntax anything

local a1 :word 1 of `anything'
local b1 :word 2 of `anything'
local c1 :word 3 of `anything'
local d1 :word 4 of `anything'

if (`a1' == 0) {
	local a1 = `a1' + 0.5
}

if (`b1' == 0) {
	local b1 = `b1' + 0.5
}
if (`c1' == 0) {
	local c1 = `c1' + 0.5
}
if (`d1' == 0) {
	local d1 = `d1' + 0.5
}

local est = log(`a1' * `d1'/`b1' /`c1')
local se = sqrt(1 / `a1' + 1 / `b1' + 1 / `c1' + 1 / `d1')
local t = `est' / `se'

dis "`t'"
return local tknfl =`t'
end

// #9
capture program drop getabcdkfnl
program define getabcdkfnl, rclass
version 16.0

syntax anything

local a1 :word 1 of `anything'
local b1 :word 2 of `anything'
local c1 :word 3 of `anything'
local d1 :word 4 of `anything'

* Round values
local ra1 = round(`a1')
local rb1 = round(`b1')
local rc1 = round(`c1')
local rd1 = round(`d1')

* Use return locals to pass back rounded values
return local ra1 = `ra1'
return local rb1 = `rb1'
return local rc1 = `rc1'
return local rd1 = `rd1'
end

// #10
// please run isinvalidate.ado; isdcroddsratio.ado; gettkfnl.ado; taylorexp.ado before use this file
capture program drop getswitch
program define getswitch, rclass
version 16.0

syntax anything

local a1 :word 1 of `anything'
local b1 :word 2 of `anything'
local c1 :word 3 of `anything'
local d1 :word 4 of `anything'
local thr_t :word 5 of `anything'
local switch_trm :word 6 of `anything' //0 or 1
local n_obs :word 7 of `anything'

local est_eff_start = log(`a1' * `d1' / `b1' / `c1') 
local std_err_start = sqrt(1 / `a1' + 1 / `b1' + 1 / `c1' + 1 / `d1')

matrix define table_start = (`a1', `b1' \ `c1', `d1')

// return variable: tknfl
quietly gettkfnl `a1' `b1' `c1' `d1'
local t_start =  `r(tknfl)'


* Adjust tstart to .0000001 if it's between 0 and .0000001
if `t_start' >= 0 & `t_start' <= .0000001 {
    local t_start = .0000001
}
else if `t_start' <= 0 & `t_start' >= -.0000001 {
    local t_start = -.0000001
}

local inf_value = 10e16 // numeric Inf value to mimic R

// return variable: isinva
quietly isinvalidate `thr_t' `t_start'
local invalidate_start = `r(isinva)'

// return variable: isdcrodds
quietly isdcroddsratio `thr_t' `t_start'
local dcroddsratio_start = `r(isdcrodds)'

if (`dcroddsratio_start' == 1){
	local step = 1 // transfer cases from D to C or A to B
}
else {
	local step = -1 // transfer cases from B to A or C to D
}
dis `step'
if (`t_start' < `thr_t'){
	// transfer cases from B to A or C to D to increase odds ratio
    local c_tryall = `c1' - (`c1' - 1) * `switch_trm'
    local d_tryall = `d1' + (`c1' - 1) * `switch_trm'
    local a_tryall = `a1' + (`b1' - 1) * (1 - `switch_trm')
    local b_tryall = `b1' - (`b1' - 1) * (1 - `switch_trm')

	quietly gettkfnl `a_tryall' `b_tryall' `c_tryall' `d_tryall'
	local tryall_t = `r(tknfl)'
	
		* edit 101524 Inf (NaN in Stata) to big number
    if (`c_tryall' == 0 | `b_tryall' == 0) {
        local tryall_est = -`inf_value'  // -Inf when numerator is zero
    } 
	else if (`b_tryall' == 0 | `c_tryall' == 0) {
        local tryall_est = `inf_value'  // +Inf when denominator is zero
    } 
	else {
        local tryall_est = log(`a_tryall' * `d_tryall' / `c_tryall' / `b_tryall')
    }
	
	
	
	if (`thr_t' - `tryall_t' > 0 & `tryall_est' * `est_eff_start' >= 0){
		local allnotenough = 1
	}
	else {
		local allnotenough = 0
	}
  }

if (`t_start' > `thr_t'){
    // transfer cases from A to B or D to C to decrease odds ratio
    local c_tryall = `c1' + (`d1' - 1) * `switch_trm'
    local d_tryall = `d1' - (`d1' - 1) * `switch_trm'
    local a_tryall = `a1' - (`a1' - 1) * (1 - `switch_trm')
    local b_tryall = `b1' + (`a1' - 1) * (1 - `switch_trm')
	
    quietly gettkfnl `a_tryall' `b_tryall' `c_tryall' `d_tryall'
	local tryall_t = `r(tknfl)'
	
	* edit 101524 Inf (NaN in Stata) to big number
    if (`c_tryall' == 0 | `b_tryall' == 0) {
        local tryall_est = -`inf_value'  // -Inf when numerator is zero
    } 
	else if (`b_tryall' == 0 | `c_tryall' == 0) {
        local tryall_est = `inf_value'  // +Inf when denominator is zero
    } 
	else {
        local tryall_est = log(`a_tryall' * `d_tryall' / `c_tryall' / `b_tryall')
    }
	
	if (`tryall_t' - `thr_t' > 0 & `tryall_est' * `est_eff_start' >= 0){
		local allnotenough = 1
	}
	else {
		local allnotenough = 0
	}
 }

//run following if transfering one row is enough
if (`allnotenough' == 0){
    // calculate percent of bias and predicted switches
    if (`invalidate_start' == 1){
      local perc_bias = 1 - `thr_t' / `t_start'
    } 
	else {
      local perc_bias = abs(`thr_t' - `t_start') / abs(`t_start')
    }
    if (`switch_trm' == 1 & `dcroddsratio_start' == 1){
      local perc_bias_pred = `perc_bias' * `d1' * (`a1' + `c1') / `n_obs'
    }
    if (`switch_trm' == 1 & `dcroddsratio_start' == 0){
      local perc_bias_pred = `perc_bias' * `c1' * (`b1' + `d1') / `n_obs'
    }
    if (`switch_trm' == 0 & `dcroddsratio_start' == 1){
      local perc_bias_pred = `perc_bias' * `a1' * (`b1' + `d1') / `n_obs'
    }
    if (`switch_trm' == 0 & `dcroddsratio_start' == 0){
      local perc_bias_pred = `perc_bias' * `b1' * (`a1' + `c1') / `n_obs'
    } 
	
	// calculate predicted switches based on Taylor expansion
	if (`switch_trm' == 1){	
		quietly taylorexp `a1' `b1' `c1' `d1' `step'*`perc_bias_pred' `thr_t'
		local taylor_pred = abs(`r(taylor)')
		local a_taylor = round(`a1')
		local b_taylor = round(`b1')
		local c_taylor = round(`c1' + `taylor_pred' * `step')
		local d_taylor = round(`d1' - `taylor_pred' * `step')
		} 
	else{		
		quietly taylorexp `d1' `c1' `b1' `a1' `step'*`perc_bias_pred' `thr_t'
		local taylor_pred = abs(`r(taylor)')
		local a_taylor = round(`a1' - `taylor_pred' * `step')
		local b_taylor = round(`b1' + `taylor_pred' * `step')
		local c_taylor = round(`c1')
		local d_taylor = round(`d1')
		}
	
	// check whether taylor_pred move too many and causes non-positive odds ratio
	if (`a_taylor' <= 0){
      local b_taylor = `a_taylor' + `b_taylor' - 1
      local a_taylor = 1
    }
    if (`b_taylor' <= 0){
      local a_taylor = `a_taylor' + `b_taylor' - 1
      local b_taylor = 1
    }
    if (`c_taylor' <= 0){
      local d_taylor = `c_taylor' + `d_taylor' - 1
      local c_taylor = 1
    }
    if (`d_taylor' <= 0){
      local c_taylor = `c_taylor' + `d_taylor' - 1
      local d_taylor = 1
    }

    // set brute force starting point from the taylor expansion result	
	quietly gettkfnl `a_taylor' `b_taylor' `c_taylor' `d_taylor'
	local t_taylor =  `r(tknfl)'
	
    local a_loop = `a_taylor'
    local b_loop = `b_taylor'
    local c_loop = `c_taylor'
    local d_loop = `d_taylor'
    local t_loop = `t_taylor'
  }

if (`allnotenough' == 1){
    // Later: set tryall as the starting point and call this getswitch function again
    local a_loop = `a_tryall'
    local b_loop = `b_tryall'
    local c_loop = `c_tryall'
    local d_loop = `d_tryall'
	
    quietly gettkfnl `a_loop' `b_loop' `c_loop' `d_loop'
	local t_loop = `r(tknfl)'
  } 

// start brute force

if (`switch_trm' == `allnotenough'){
	local switch_indicator = 1
}
else {
	local switch_indicator = 0
}

if (`t_loop' < `thr_t'){
    while (`t_loop' < `thr_t') {
      local c_loop = `c_loop' - 1 * (1 - `switch_indicator')
      local d_loop = `d_loop' + 1 * (1 - `switch_indicator')
      local a_loop = `a_loop' + 1 * `switch_indicator'
      local b_loop = `b_loop' - 1 * `switch_indicator'
	  
	  //dis "a, b, c, d_loop = `a_loop', `b_loop', `c_loop', `d_loop'"
	  
	  * Check for non-positive values and stop if any are found
	  if (`a_loop' <= 0 | `b_loop' <= 0 | `c_loop' <= 0 | `d_loop' <= 0) {
	  	di as error "An issue was encountered during the computation: one of the values became non-positive, leading to the generation of NaN in the calculations."
		exit 1
        }
	  
	  
	  quietly gettkfnl `a_loop' `b_loop' `c_loop' `d_loop'
	  local t_loop =  `r(tknfl)'
	  //dis "t_loop "`t_loop'
    }
    // make a small adjustment to make it just below/above the thresold
    if (`t_start' > `thr_t'){
      local c_final = `c_loop' + 1 * (1 - `switch_indicator')
      local d_final = `d_loop' - 1 * (1 - `switch_indicator')
      local a_final = `a_loop' - 1 * `switch_indicator'
      local b_final = `b_loop' + 1 * `switch_indicator'
    } 
	else if (`t_start' < `thr_t'){
      local c_final = `c_loop'
      local d_final = `d_loop'
      local a_final = `a_loop'
      local b_final = `b_loop'
    }
  }

if (`t_loop' > `thr_t'){
    while (`t_loop' > `thr_t') {
      local c_loop = `c_loop' + 1 * (1 - `switch_indicator')
      local d_loop = `d_loop' - 1 * (1 - `switch_indicator')
      local a_loop = `a_loop' - 1 * `switch_indicator'
      local b_loop = `b_loop' + 1 * `switch_indicator'
	 //dis "a, b, c, d_loop = `a_loop', `b_loop', `c_loop', `d_loop'"
	  * Check for non-positive values and stop if any are found
	  if (`a_loop' <= 0 | `b_loop' <= 0 | `c_loop' <= 0 | `d_loop' <= 0) {
	  	di as error "An issue was encountered during the computation: one of the values became non-positive, leading to the generation of NaN in the calculations."
		exit 1
        }
	 
	  quietly gettkfnl `a_loop' `b_loop' `c_loop' `d_loop'
	  local t_loop =  `r(tknfl)'
	  //dis "t_loop" `t_loop'
    }
    if (`t_start' < `thr_t'){
      local c_final = `c_loop' - 1 * (1 - `switch_indicator')
      local d_final = `d_loop' + 1 * (1 - `switch_indicator')
      local a_final = `a_loop' + 1 *  `switch_indicator'
      local b_final = `b_loop' - 1 *  `switch_indicator'
    } 
	else if (`t_start' > `thr_t'){
      local c_final = `c_loop'
      local d_final = `d_loop'
      local a_final = `a_loop'
      local b_final = `b_loop'
    }
  }

// so the final results (after switching) is as follows:
local est_eff_final = log(`a_final' * `d_final' / (`b_final' * `c_final'))
local std_err_final = sqrt(1 / `a_final' + 1 / `b_final' + 1 / `c_final' + 1 / `d_final')
local t_final = `est_eff_final' / `std_err_final'
matrix define table_final = (`a_final', `b_final' \ `c_final', `d_final')

if (`switch_trm' == `allnotenough'){
    local final = abs(`a1' - `a_final') + `allnotenough' * abs(`c1' - `c_final')
  } 

else{
    local final = abs(`c1' - `c_final') + `allnotenough' * abs(`a1' - `a_final')
  }

// final_extra is the extra switch
if (`allnotenough' == 1){
    local taylor_pred = 0
    local perc_bias_pred = 0
    if (`switch_trm' == 1){
      local final_extra = abs(`a1' - `a_final')
    }
    else{
      local final_extra = abs(`c1' - `c_final')
    }
  } 
  else{
    local final_extra = 0
	}


return local final_switch =`final'
return local x 
// table start and table final can be used in other function
// by using mat list table_start/ table_final
// return local table_start = `table_start'
// return local table_final = `table_final'
return local est_eff_start = `est_eff_start'
return local est_eff_final = `est_eff_final'
return local std_err_start = `std_err_start'
return local std_err_final = `std_err_final'
return local t_start = `t_start'
return local t_final = `t_final'
return local taylor_pred = `taylor_pred'
return local perc_bias_pred = `perc_bias_pred'
return local step = `step'
return local needtworows = `allnotenough'
return local final_extra = `final_extra'




dis "Switch is done for now!"
mat list table_start
mat list table_final

// // testing block
// dis `t_start'
// dis `invalidate_start'
// dis `dcroddsratio_start'
// dis `step'
// dis `tryall_est'
// dis `perc_bias_pred'
// dis `taylor_pred'
// dis `a_taylor'
// dis `t_taylor'
// dis `allnotenough'
// dis "switch_indicator " `switch_indicator'
// dis "t_loop " `t_loop'
//dis "final_switch " `final'

end

// #11
capture program drop getpi
program define getpi, rclass
version 16.0

syntax anything

local odds_ratio :word 1 of `anything'
local std_err :word 2 of `anything'
local n_obs :word 3 of `anything'
local n_trm :word 4 of `anything'

local a = `odds_ratio' * `n_obs'^2 * `std_err'^4
local b = -1 * `a'
local c = 4 + 4 * `odds_ratio'^2 + `odds_ratio' * (-8 + 4 * `n_obs' * `std_err'^2)


// dis "(`b'^2 - 4 * `a' * `c')"
// dis (`b'^2 - 4 * `a' * `c')
// dis `b' * `b'


local x1 = (-1 *`b' - sqrt((`b')^2 - 4 * `a' * `c')) / (`a' * 2)
local x2 = (-1 *`b' + sqrt((`b')^2  - 4 * `a' * `c')) / (`a' * 2)
if (`n_trm' / `n_obs' <= 0.5) {
    local x = `x1'
  }
else 
{
    local x = `x2'
  }

dis `x'
return local pi =`x'
end

// #12
capture program drop chisqp
program define chisqp, rclass
version 16.0

syntax anything

local a1 = round(real(word("`anything'", 1)))
local b1 = round(real(word("`anything'", 2)))
local c1 = round(real(word("`anything'", 3)))
local d1 = round(real(word("`anything'", 4)))

quietly tabi `a1' `b1' \ `c1' `d1', chi2

dis `r(p)'


return local chisq_p=`r(p)'

end

// #13
capture program drop fisher_p
program define fisher_p,rclass
version 16.0

syntax anything

local a1 = real(word("`anything'", 1))
local b1 = real(word("`anything'", 2))
local c1 = real(word("`anything'", 3))
local d1 = real(word("`anything'", 4))

* If any value is negative, stop execution with an error message
if (`a1' < 0 | `b1' < 0 | `c1' < 0 | `d1' < 0) {
	di as error "All values must be nonnegative and finite."
    exit 1  
	}

* Round non-negative values and assign 0 if value < 1
local a1 = cond(`a1' < 1, 0, round(`a1'))
local b1 = cond(`b1' < 1, 0, round(`b1'))
local c1 = cond(`c1' < 1, 0, round(`c1'))
local d1 = cond(`d1' < 1, 0, round(`d1'))
	
quietly tabi `a1' `b1' \ `c1' `d1'

dis "`r(p_exact)'"
return local fisherp = `r(p_exact)'


end

// #14
capture program drop chisq_value
program define chisq_value, rclass
version 16.0

syntax anything

local a1 = round(real(word("`anything'", 1)))
local b1 = round(real(word("`anything'", 2)))
local c1 = round(real(word("`anything'", 3)))
local d1 = round(real(word("`anything'", 4)))

quietly tabi `a1' `b1' \ `c1' `d1', chi2
dis `r(chi2)'
return local chisq_va=`r(chi2)'
end

// #15
capture program drop fisher_oddsratio
program define fisher_oddsratio,rclass
version 16.0

syntax anything

local a1 = cond(real(word("`anything'", 1)) < 1, 0, round(real(word("`anything'", 1))))
local b1 = cond(real(word("`anything'", 2)) < 1, 0, round(real(word("`anything'", 2))))
local c1 = cond(real(word("`anything'", 3)) < 1, 0, round(real(word("`anything'", 3))))
local d1 = cond(real(word("`anything'", 4)) < 1, 0, round(real(word("`anything'", 4))))


//local ratio = `a1' * `d1' / (`c1' * `b1')
quietly cci `a1' `b1' `c1' `d1'
local ratio = `r(or)'

dis "`ratio'"
return local fratio = `ratio'
end

// #16
// please run chisqp.ado;chisq_value.ad; gettkfnl.ado; taylorexp.ado; 
capture program drop getswitch_chisq
program defin getswitch_chisq, rclass
version 16.0
// please run chisqp.ado;chisq_value.ad; gettkfnl.ado; taylorexp.ado; 
syntax anything

local a1 :word 1 of `anything'
local b1 :word 2 of `anything'
local c1 :word 3 of `anything'
local d1 :word 4 of `anything'
// edit 092924
local odds_ratio : word 5 of `anything'
local thr_p :word 6 of `anything'
local switch_trm :word 7 of `anything' //Default True -> 1

//local thr_p = 0.05

//local odds_ratio = `a1' * `d1' / (`b1' * `c1') muted 092924
local n_cnt = `a1' + `b1'
local n_trm = `c1' + `d1'
local n_obs = `n_cnt' + `n_trm'
local est = log(`odds_ratio')

// this is the 2 by 2 table we start with
matrix define table_ob = (`a1', `b1' \ `c1', `d1')

//p_ob is the return value of fisher_p
quietly chisqp `a1' `b1' `c1' `d1'
local p_ob = `r(chisq_p)'

// to evaluate whther we are moving cases to invalidate or sustain the inference
if (`p_ob' < `thr_p'){
	local isinvalidate_ob = 1
	}
if (`p_ob' > `thr_p'){
	local isinvalidate_ob = 0
	}

if (`odds_ratio' >= 1){
	local dcroddsratio_ob = `isinvalidate_ob'
	}
if (`odds_ratio' < 1){
	local dcroddsratio_ob = 1 - `isinvalidate_ob'
	} 

local isinvalidate_start = `isinvalidate_ob'
local dcroddsratio_start = `dcroddsratio_ob'
local p_start = `p_ob'

// table_start <- table_ob? ************************************

//return variable: tknfl
quietly gettkfnl `a1' `b1' `c1' `d1'
local t_start =  `r(tknfl)'
local t_ob = `t_start'

if (`est' < 0){
	local thr_t = invttail(`n_obs'-1, 1 - (`thr_p'/2))
  } 
else{
    // local `thr_t' = stats::qt(1 - thr_p/2, n_obs - 1)
	local thr_t = invttail(`n_obs'-1, 1 - (`thr_p'/2)) * (-1)
  }

if (`dcroddsratio_start' == 1){
  local step = 1 // transfer cases from D to C or A to B
} 
else{
  local step = -1 // transfer cases from B to A or C to D
}

if (`dcroddsratio_start'== 0){
  // transfer cases from B to A or C to D to increase odds ratio
  // edit 092924
    local c_tryall = `c1' - `c1' * `switch_trm'
    local d_tryall = `d1' + `c1' * `switch_trm'
    local a_tryall = `a1' + `b1' * (1 - `switch_trm')
    local b_tryall = `b1' - `b1' * (1 - `switch_trm')
	
    quietly chisqp `a_tryall' `b_tryall' `c_tryall' `d_tryall'
    local tryall_p = `r(chisq_p)'

	local inf_value = 10e16 // numeric Inf value to mimic R
	
	* edit 100724 Inf (NaN in Stata) to big number
    if (`a_tryall' == 0 | `d_tryall' == 0) {
        local tryall_est = -`inf_value'  // -Inf when numerator is zero
    } 
	else if (`b_tryall' == 0 | `c_tryall' == 0) {
        local tryall_est = `inf_value'  // -Inf when denominator is zero
    } 
	else {
        local tryall_est = log(`a_tryall' * `d_tryall' / `c_tryall' / `b_tryall')
    }
	
    if (((`thr_p' - `tryall_p') * `tryall_est')< 0 & `tryall_est' * `est' >= 0){
  	  local allnotenough = 1
    }
    else{
  	  local allnotenough = 0
    }
}

if (`dcroddsratio_start'== 1){
	// edit 092924
    local c_tryall = `c1' + `d1' * `switch_trm'
    local d_tryall = `d1' - `d1' * `switch_trm'
    local a_tryall = `a1' - `a1' * (1 - `switch_trm')
    local b_tryall = `b1' + `a1' * (1 - `switch_trm')
	
	quietly chisqp `a_tryall' `b_tryall' `c_tryall' `d_tryall'
    local tryall_p = `r(chisq_p)'

	local inf_value = 10e16 // numeric Inf value to mimic R
	
	* edit 100724 Inf (NaN in Stata) to big number
    if (`a_tryall' == 0 | `d_tryall' == 0) {
        local tryall_est = -`inf_value'  // -Inf when numerator is zero
    } 
	else if (`b_tryall' == 0 | `c_tryall' == 0) {
        local tryall_est = `inf_value'  // -Inf when denominator is zero
    } 
	else {
        local tryall_est = log(`a_tryall' * `d_tryall' / `c_tryall' / `b_tryall')
    }	
	if (((`thr_p' - `tryall_p') * `tryall_est')> 0  & `tryall_est'*`est' >= 0){
	    local allnotenough = 1
	}
	else{
		local allnotenough = 0
	}	
}


if (`allnotenough' == 0){
	if(`isinvalidate_start' == 1){
		local perc_bias = 1 - (`thr_t' / `t_start')
	}
	else{
		local perc_bias = abs(`thr_t' - `t_start') / abs(`t_start')
	}

	if (`switch_trm' == 1 & `dcroddsratio_start' == 1){
		local perc_bias_pred = `perc_bias' * `d1' * (`a1' + `c1') / `n_obs'
  }
	if (`switch_trm' == 1 & `dcroddsratio_start' == 0){
		local perc_bias_pred = `perc_bias' * `c1' * (`b1' + `d1') / `n_obs'
  }
	if (`switch_trm' == 0 & `dcroddsratio_start' == 1){
		local perc_bias_pred = `perc_bias' * `a1' * (`b1' + `d1') / `n_obs'
	}
	if (`switch_trm' == 0 & `dcroddsratio_start' == 0){
		local perc_bias_pred = `perc_bias' * `b1' * (`a1' + `c1') / `n_obs'
  }

  	// calculate predicted switches based on Taylor expansion
	if (`switch_trm' == 1){	
		quietly taylorexp `a1' `b1' `c1' `d1' `step'*`perc_bias_pred' `thr_t'
		local taylor_pred = abs(`r(taylor)')
		local a_taylor = round(`a1')
		local b_taylor = round(`b1')
		local c_taylor = round(`c1' + `taylor_pred' * `step')
		local d_taylor = round(`d1' - `taylor_pred' * `step')
		} 
	else{		
		quietly taylorexp `d1' `c1' `b1' `a1' `step'*`perc_bias_pred' `thr_t'
		local taylor_pred = abs(`r(taylor)')
		local a_taylor = round(`a1' - `taylor_pred' * `step')
		local b_taylor = round(`b1' + `taylor_pred' * `step')
		local c_taylor = round(`c1')
		local d_taylor = round(`d1')
		}

	// check whether taylor_pred move too many and causes non-positive odds ratio
	if (`a_taylor' <= 0){
      local b_taylor = `a_taylor' + `b_taylor' - 1
      local a_taylor = 1
    }
    if (`b_taylor' <= 0){
      local a_taylor = `a_taylor' + `b_taylor' - 1
      local b_taylor = 1
    }
    if (`c_taylor' <= 0){
      local d_taylor = `c_taylor' + `d_taylor' - 1
      local c_taylor = 1
    }
    if (`d_taylor' <= 0){
      local c_taylor = `c_taylor' + `d_taylor' - 1
      local d_taylor = 1
    }
	
	// set brute force starting point from the taylor expansion result
	quietly chisqp `a_taylor' `b_taylor' `c_taylor' `d_taylor'
	local p_taylor = `r(chisq_p)'
	local a_loop = `a_taylor'
	local b_loop = `b_taylor'
	local c_loop = `c_taylor'
	local d_loop = `d_taylor'
	local p_loop = `p_taylor'
	
	quietly gettkfnl `a_loop' `b_loop' `c_loop' `d_loop'
	local t_loop = `r(tknfl)'

}

// when we need to transfer two rows the previously defined tryall are the starting point for brute force

if (`allnotenough' == 1){
	local a_loop = `a_tryall'
	local b_loop = `b_tryall'
	local c_loop = `c_tryall'
	local d_loop = `d_tryall'
	
	quietly chisqp `a_loop' `b_loop' `c_loop' `d_loop'
	local p_taylor = `r(chisq_p)'
	
	quietly gettkfnl `a_loop' `b_loop' `c_loop' `d_loop'
	local t_loop = `r(tknfl)'
}

// start brute force
if (`switch_trm' == `allnotenough'){
	local switch_indicator = 1
}
else{
	local switch_indicator = 0
}

if (`t_loop' < `thr_t'){
	
	while (`t_loop' < `thr_t'){
      local c_loop = `c_loop' - 1 * (1 - `switch_indicator')
      local d_loop = `d_loop' + 1 * (1 - `switch_indicator')
      local a_loop = `a_loop' + 1 * `switch_indicator'
      local b_loop = `b_loop' - 1 * `switch_indicator'
	  
	   * Check for non-positive values and stop if any are found
        if (`a_loop' < 0 | `b_loop' < 0 | `c_loop' < 0 | `d_loop' < 0) {
            di as error "An issue was encountered during the computation: one of the values became non-positive, leading to the generation of NaN in the calculations."
			exit 1
*		continue
        }
	  
	  
      quietly gettkfnl `a_loop' `b_loop' `c_loop' `d_loop'
	  local t_loop =  `r(tknfl)'

    }
	// make a small adjustment to make it just below/above the thresold
	
	if (`t_start' > `thr_t'){
      local c_loopsec = `c_loop' + 1 * (1 - `switch_indicator')
      local d_loopsec = `d_loop' - 1 * (1 - `switch_indicator')
      local a_loopsec = `a_loop' - 1 * `switch_indicator'
      local b_loopsec = `b_loop' + 1 * `switch_indicator'
    } 
	else if (`t_start' < `thr_t'){
      local c_loopsec = `c_loop'
      local d_loopsec = `d_loop'
      local a_loopsec = `a_loop'
      local b_loopsec = `b_loop'
    }
}


if (`t_loop' > `thr_t'){
    while (`t_loop' > `thr_t') {
      local c_loop = `c_loop' + 1 * (1 - `switch_indicator')
      local d_loop = `d_loop' - 1 * (1 - `switch_indicator')
      local a_loop = `a_loop' - 1 * `switch_indicator'
      local b_loop = `b_loop' + 1 * `switch_indicator'
	 
	  * Check for non-positive values and stop if any are found
	  if (`a_loop' < 0 | `b_loop' < 0 | `c_loop' < 0 | `d_loop' < 0) {
	  	di as error "An issue was encountered during the computation: one of the values became non-positive, leading to the generation of NaN in the calculations."
		exit 1
*		continue
        }
	 
	  quietly gettkfnl `a_loop' `b_loop' `c_loop' `d_loop'
	  local t_loop =  `r(tknfl)'

    }
    if (`t_start' < `thr_t'){
      local c_loopsec = `c_loop' - 1 * (1 - `switch_indicator')
      local d_loopsec = `d_loop' + 1 * (1 - `switch_indicator')
      local a_loopsec = `a_loop' + 1 *  `switch_indicator'
      local b_loopsec = `b_loop' - 1 *  `switch_indicator'
    } 
	else if (`t_start' > `thr_t'){
      local c_loopsec = `c_loop'
      local d_loopsec = `d_loop'
      local a_loopsec = `a_loop'
      local b_loopsec = `b_loop'
    }
  }

quietly chisqp `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
local p_loopsec = `r(chisq_p)'
// start 2nd round brute force - use fisher test p value as evaluation criterion
// scenario 1 need to reduce odds ratio to invalidate the inference-need to increase p
if (`isinvalidate_start' == 1 & `dcroddsratio_start' == 1){
	if (`p_loopsec' < `thr_p'){
		while (`p_loopsec' < `thr_p'){
			local c_loopsec = `c_loopsec' + 1 * (1 - `switch_indicator')
			local d_loopsec = `d_loopsec' - 1 * (1 - `switch_indicator')
			local a_loopsec = `a_loopsec' - 1 * `switch_indicator'
			local b_loopsec = `b_loopsec' + 1 * `switch_indicator'
			
			quietly chisqp `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
			local p_loopsec = `r(chisq_p)'
		}
		local c_final = `c_loopsec'
        local d_final = `d_loopsec'
        local a_final = `a_loopsec'
        local b_final = `b_loopsec'
	}
	
	if (`p_loopsec' > `thr_p'){
		//taylor too much, return some odds ratio
		while (`p_loopsec' > `thr_p'){
			local c_loopsec = `c_loopsec' - 1 * (1 - `switch_indicator')
			local d_loopsec = `d_loopsec' + 1 * (1 - `switch_indicator')
			local a_loopsec = `a_loopsec' + 1 * `switch_indicator'
			local b_loopsec = `b_loopsec' - 1 * `switch_indicator'
			
			quietly chisqp `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
			local p_loopsec = `r(chisq_p)'
		}
		local c_final = `c_loopsec' + 1 * (1 - `switch_indicator')
        local d_final = `d_loopsec' - 1 * (1 - `switch_indicator')
        local a_final = `a_loopsec' - 1 * `switch_indicator'
        local b_final = `b_loopsec' + 1 * `switch_indicator'
	}
}

// scenario 2 need to reduce odds ratio to sustain the inference-need to reduce p
if (`isinvalidate_start' == 0 & `dcroddsratio_start' == 1){
	if (`p_loopsec' < `thr_p'){
		// taylor too  much, return some odds ratio
		while (`p_loopsec' < `thr_p') {
			local c_loopsec = `c_loopsec' - 1 * (1 - `switch_indicator')
			local d_loopsec = `d_loopsec' + 1 * (1 - `switch_indicator')
			local a_loopsec = `a_loopsec' + 1 * `switch_indicator'
			local b_loopsec = `b_loopsec' - 1 * `switch_indicator'
			
			quietly chisqp `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
			local p_loopsec = `r(chisq_p)'
		}
		local c_final = `c_loopsec' + 1 * (1 - `switch_indicator')
        local d_final = `d_loopsec' - 1 * (1 - `switch_indicator')
        local a_final = `a_loopsec' - 1 * `switch_indicator'
        local b_final = `b_loopsec' + 1 * `switch_indicator'
	}
	if (`p_loopsec' > `thr_p'){
		// taylor not enough, continue to reduce odds ratio
		while (`p_loopsec' > `thr_p') {
			local c_loopsec = `c_loopsec' + 1 * (1 - `switch_indicator')
			local d_loopsec = `d_loopsec' - 1 * (1 - `switch_indicator')
			local a_loopsec = `a_loopsec' - 1 * `switch_indicator'
			local b_loopsec = `b_loopsec' + 1 * `switch_indicator'
			
			quietly chisqp `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
			local p_loopsec = `r(chisq_p)'
		}
		local c_final = `c_loopsec'
        local d_final = `d_loopsec'
        local a_final = `a_loopsec'
        local b_final = `b_loopsec'
	}
}

// scenario 3 need to increase odds ratio to invalidate the inference-need to increase p
if (`isinvalidate_start' == 1 & `dcroddsratio_start' == 0){
	
	if (`p_loopsec' < `thr_p'){
		// taylor not enough, continue to increase odds ratio 
		while (`p_loopsec' < `thr_p'){
			local c_loopsec = `c_loopsec' - 1 * (1 - `switch_indicator')
			local d_loopsec = `d_loopsec' + 1 * (1 - `switch_indicator')
			local a_loopsec = `a_loopsec' + 1 * `switch_indicator'
			local b_loopsec = `b_loopsec' - 1 * `switch_indicator'
			
			quietly chisqp `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
			local p_loopsec = `r(chisq_p)'
		}
		local c_final = `c_loopsec'
        local d_final = `d_loopsec'
        local a_final = `a_loopsec'
        local b_final = `b_loopsec'
	}
	if (`p_loopsec' > `thr_p'){
		// taylor too much, returns some odds ratio - decrease
		while (`p_loopsec' > `thr_p'){		
			local c_loopsec = `c_loopsec' + 1 * (1 - `switch_indicator')
			local d_loopsec = `d_loopsec' - 1 * (1 - `switch_indicator')
			local a_loopsec = `a_loopsec' - 1 * `switch_indicator'
			local b_loopsec = `b_loopsec' + 1 * `switch_indicator'
			
			quietly chisqp `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
			local p_loopsec = `r(chisq_p)'
			
			
		}
		local c_final = `c_loopsec' - 1 * (1 - `switch_indicator')
        local d_final = `d_loopsec' + 1 * (1 - `switch_indicator')
        local a_final = `a_loopsec' + 1 * `switch_indicator'
        local b_final = `b_loopsec' - 1 * `switch_indicator'
	}
}

// scenario 4 need to increase odds ratio to sustain the inference-need to decrease p
if (`isinvalidate_start' == 0 & `dcroddsratio_start' == 0){
	if (`p_loopsec' > `thr_p'){
		// taylor not enough, continue to increase odds ratio 
		while (`p_loopsec' > `thr_p'){
			local c_loopsec = `c_loopsec' - 1 * (1 - `switch_indicator')
			local d_loopsec = `d_loopsec' + 1 * (1 - `switch_indicator')
			local a_loopsec = `a_loopsec' + 1 * `switch_indicator'
			local b_loopsec = `b_loopsec' - 1 * `switch_indicator'
			
			quietly chisqp `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
			local p_loopsec = `r(chisq_p)'
		}
		local c_final = `c_loopsec'
        local d_final = `d_loopsec'
        local a_final = `a_loopsec'
        local b_final = `b_loopsec'
	}
	
	if (`p_loopsec' < `thr_p'){
		while (`p_loopsec' < `thr_p'){
			local c_loopsec = `c_loopsec' + 1 * (1 - `switch_indicator')
			local d_loopsec = `d_loopsec' - 1 * (1 - `switch_indicator')
			local a_loopsec = `a_loopsec' - 1 * `switch_indicator'
			local b_loopsec = `b_loopsec' + 1 * `switch_indicator'
			
			quietly chisqp `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
			local p_loopsec = `r(chisq_p)'
		}
		local c_final = `c_loopsec' - 1 * (1 - `switch_indicator')
        local d_final = `d_loopsec' + 1 * (1 - `switch_indicator')
        local a_final = `a_loopsec' + 1 * `switch_indicator'
        local b_final = `b_loopsec' - 1 * `switch_indicator'
	}
}


// so the final results (after switching) is as follows:
matrix define table_final = (`a_final', `b_final' \ `c_final', `d_final')
quietly chisqp `a_final' `b_final' `c_final' `d_final'
local p_final = `r(chisq_p)'

quietly chisq_value `a_final' `b_final' `c_final' `d_final'
local chisq_final = `r(chisq_va)' 

if (`switch_trm' == `allnotenough'){
	local final = abs(`a1' - `a_final') + `allnotenough' * abs(`c1' - `c_final')
}
else{
	local final = abs(`c1' - `c_final') + `allnotenough' * abs(`a1' - `a_final')
}

if (`allnotenough' == 1){
	local taylor_pred = 0
    local perc_bias_pred = 0
	if (`switch_trm' == 1){
		local final_extra = abs(`a1' - `a_final')
	}
	else{
		local final_extra = abs(`c1' - `c_final')
	}
}
else {
	local final_extra = 0
}

local total_switch = `final' + `allnotenough' * `final_extra'

return local final_switch =`final'
return local p_final = `p_final' 
return local chisq_final = `chisq_final'
return local needtworows = `allnotenough'
return local taylor_pred = `taylor_pred'
return local perc_bias_pred = `perc_bias_pred'
return local final_extra = `final_extra'
return local dcroddsratio_ob = `dcroddsratio_ob'
// muted 092924
//return local total_switch = `total_switch'
return local isinvalidate_ob = `isinvalidate_ob'

dis "table_start"
mat list table_ob

dis "table_final"
mat list table_final

end

// #17
// please run fisher_oddsratio.ado; fisher_p.ado; gettkfnl; taylorexp
* nonlinear auxiliary function
capture program drop getswitch_fisher
program define getswitch_fisher, rclass
version 16.0
// please run fisher_oddsratio.ado; fisher_p.ado; gettkfnl; taylorexp
syntax anything

local a1 :word 1 of `anything'
local b1 :word 2 of `anything'
local c1 :word 3 of `anything'
local d1 :word 4 of `anything'
// edit 092924
local odds_ratio :word 5 of `anything'
local thr_p :word 6 of `anything'
local switch_trm :word 7 of `anything' //Default True -> 1

// muted 092924
//if (`a1' > 0 & `b1' > 0 & `c1' > 0 & `d1' > 0){
//	quietly fisher_oddsratio `a1' `b1' `c1' `d1'
//	local odds_ratio = `r(fratio)'
//}
//else{
//	local odds_ratio = 1 + 0.1 * (`a1' * `d1' - `b1' * `c1')
//}


local est1 = log(`odds_ratio')
local n_cnt = `a1' + `b1'
local n_trm = `c1' + `d1'
local n_obs = `n_cnt' + `n_trm'

matrix define table_ob = (`a1', `b1' \ `c1', `d1')

quietly fisher_p  `a1' `b1' `c1' `d1'
local p_ob = `r(fisherp)'

// dis `p_ob'
// dis "odds_ratio `odds_ratio'"

if (`p_ob' < `thr_p'){
	local isinvalidate_ob = 1
	}
if (`p_ob' > `thr_p'){
	local isinvalidate_ob = 0
	}

// dis `isinvalidate_ob'

if (`odds_ratio' > 1){
	local dcroddsratio_ob = `isinvalidate_ob'
	}
if (`odds_ratio' < 1){
	local dcroddsratio_ob = (1 - `isinvalidate_ob')
	}

local isinvalidate_start = `isinvalidate_ob'
local dcroddsratio_start = `dcroddsratio_ob'
local p_start = `p_ob'
matrix define table_start = (`a1', `b1' \ `c1', `d1')



quietly gettkfnl `a1' `b1' `c1' `d1'
local t_ob = `r(tknfl)'
local t_start = `r(tknfl)'



if (`est1' < 0){
	local thr_t = invttail(`n_obs' - 1, 1 - (`thr_p' / 2))
}
else{
	local thr_t = invttail(`n_obs' - 1, 1 - (`thr_p' / 2)) * (-1)
}

if (`dcroddsratio_start' == 1){
	local step = 1
}
else{
	local step = -1
}


// check whether it is enough to transfer all cases in one row
if (`dcroddsratio_start' == 0){
	local c_tryall = `c1' - `c1' * `switch_trm'
    local d_tryall = `d1' + `c1' * `switch_trm'
    local a_tryall = `a1' + `b1' * (1 - `switch_trm')
    local b_tryall = `b1' - `b1' * (1 - `switch_trm')
	
	quietly fisher_p `a_tryall' `b_tryall' `c_tryall' `d_tryall'
	local tryall_p = `r(fisherp)'
	
	// please note, I changed the logic slightly from R 
	// muted 092924
    //if (`a_tryall' == 0){
	//	local a_tryall = `a_tryall' + 0.5
	//	}
    //if (`b_tryall' == 0){
	//	local b_tryall = `b_tryall' + 0.5
	//	}
    //if (`c_tryall' == 0){
	//	local c_tryall = `c_tryall' + 0.5
	//	}
    //if (`d_tryall' == 0){
	//	local d_tryall = `d_tryall' + 0.5
	//	}
	
	local inf_value = 10e16 // numeric Inf value to mimic R
	
	* edit 100724 Inf (NaN in Stata) to big number
    if (`a_tryall' == 0 | `d_tryall' == 0) {
        local tryall_est = -`inf_value'  // -Inf when numerator is zero
    } 
	else if (`b_tryall' == 0 | `c_tryall' == 0) {
        local tryall_est = `inf_value'  // -Inf when denominator is zero
    } 
	else {
        local tryall_est = log(`a_tryall' * `d_tryall' / (`c_tryall' * `b_tryall'))
    }
		
	if ((`thr_p' - `tryall_p') * `tryall_est' < 0 & `tryall_est' * `est1' >= 0){
		local allnotenough = 1
	}
	else{
		local allnotenough = 0
	}
	
}

if (`dcroddsratio_start' == 1){
	local c_tryall = `c1' + `d1' * `switch_trm'
    local d_tryall = `d1' - `d1' * `switch_trm'
    local a_tryall = `a1' - `a1' * (1 - `switch_trm')
    local b_tryall = `b1' + `a1' * (1 - `switch_trm')
	
	
	quietly fisher_p `a_tryall' `b_tryall' `c_tryall' `d_tryall'
	local tryall_p = `r(fisherp)'
	local tryall_p = abs(`tryall_p')
	
	// muted 092924
    //if (`a_tryall' == 0){
	//	local a_tryall = `a_tryall' + 0.5
	//	}
    //if (`b_tryall' == 0){
	//	local b_tryall = `b_tryall' + 0.5
	//	}
    //if (`c_tryall' == 0){
	//	local c_tryall = `c_tryall' + 0.5
	//	}
    //if (`d_tryall' == 0){
	//	local d_tryall = `d_tryall' + 0.5
	//}
	
	local inf_value = 10e16 // numeric Inf value to mimic R
	
	* edit 100724 Inf (NaN in Stata) to big number
    if (`a_tryall' == 0 | `d_tryall' == 0) {
        local tryall_est = -`inf_value'  // -Inf when numerator is zero
    } 
	else if (`b_tryall' == 0 | `c_tryall' == 0) {
        local tryall_est = `inf_value'  // -Inf when denominator is zero
    } 
	else {
        local tryall_est = log(`a_tryall' * `d_tryall' / (`c_tryall' * `b_tryall'))
    }
	
	if ((`thr_p' - `tryall_p') * `tryall_est' > 0) & (`tryall_est' * `est1' >= 0){
		local allnotenough = 1
	}
	else{
		local allnotenough = 0

	}
}


if (`allnotenough' == 0){
	if (`isinvalidate_start' == 1){
		local perc_bias = 1 - (`thr_t' / `t_start')
	}
	else{
		local perc_bias = abs(`thr_t' - `t_start') / abs(`t_start')
	}
	
	if (`switch_trm' == 1 & `dcroddsratio_start' == 1){
      local perc_bias_pred = `perc_bias' * `d1' * (`a1' + `c1') / `n_obs'
    }
    if (`switch_trm' == 1 & `dcroddsratio_start' == 0){
      local perc_bias_pred = `perc_bias' * `c1' * (`b1' + `d1') / `n_obs'
    }
    if (`switch_trm' == 0 & `dcroddsratio_start' == 1){
      local perc_bias_pred = `perc_bias' * `a1' * (`b1' + `d1') / `n_obs'
    }
    if (`switch_trm' == 0 & `dcroddsratio_start' == 0){
      local perc_bias_pred = `perc_bias' * `b1' * (`a1' + `c1') / `n_obs'
    } 
	
	
	if (`switch_trm' == 1){	
		
		quietly taylorexp `a1' `b1' `c1' `d1' `step'*`perc_bias_pred' `thr_t'
		local taylor_pred = abs(`r(taylor)')
		local a_taylor = round(`a1')
		local b_taylor = round(`b1')
		local c_taylor = round(`c1' + `taylor_pred' * `step')
		local d_taylor = round(`d1' - `taylor_pred' * `step')
		} 
	else{		
		quietly taylorexp `d1' `c1' `b1' `a1' `step'*`perc_bias_pred' `thr_t'
		local taylor_pred = abs(`r(taylor)')
		
		local a_taylor = round(`a1' - `taylor_pred' * `step')
		local b_taylor = round(`b1' + `taylor_pred' * `step')
		local c_taylor = round(`c1')
		local d_taylor = round(`d1')
		}
	
	if (`a_taylor' < 0){
      local b_taylor = `a_taylor' + `b_taylor'
      local a_taylor = 0
    }
    if (`b_taylor' < 0){
      local a_taylor = `a_taylor' + `b_taylor'
      local b_taylor = 0
    }
    if (`c_taylor' < 0){
      local d_taylor = `c_taylor' + `d_taylor'
      local c_taylor = 0
    }
    if (`d_taylor' < 0){
      local c_taylor = `c_taylor' + `d_taylor'
      local d_taylor = 0
    }
	
	//set brute force starting point from the taylor expansion result
	quietly fisher_p `a_taylor' `b_taylor' `c_taylor' `d_taylor'
	local p_taylor = `r(fisherp)'
	
	local a_loop = `a_taylor'
	local b_loop = `b_taylor'
	local c_loop = `c_taylor'
	local d_loop = `d_taylor'
	local p_loop = `p_taylor'
	
	quietly gettkfnl `a_loop' `b_loop' `c_loop' `d_loop'
	local t_loop = `r(tknfl)'
}

// when we need to transfer two rows the previously defined tryall are the starting point for brute force
if (`allnotenough' == 1){
	local a_loop = `a_tryall'
	local b_loop = `b_tryall'
	local c_loop = `c_tryall'
	local d_loop = `d_tryall'
	
	quietly fisher_p `a_loop' `b_loop' `c_loop' `d_loop'
	local p_loop = `r(fisherp)'
	
	quietly gettkfnl `a_loop' `b_loop' `c_loop' `d_loop'
	local t_loop = `r(tknfl)'
}
if (`switch_trm' == `allnotenough'){
	local switch_indicator = 1
}
else {
	local switch_indicator = 0
}


// use t as evaluation criterion to start first round brute force


if (`t_loop' < `thr_t'){
	while ((`t_loop' < `thr_t') & (`a_loop' + 1 * `switch_indicator' > 0) & (`b_loop' - 1 * `switch_indicator' > 0) & (`c_loop' - 1 * (1 - `switch_indicator') > 0) & (`d_loop' + 1 * (1 - `switch_indicator') > 0)){
				local c_loop = `c_loop' - 1 * (1 - `switch_indicator')
				local d_loop = `d_loop' + 1 * (1 - `switch_indicator')
				local a_loop = `a_loop' + 1 * `switch_indicator'
				local b_loop = `b_loop' - 1 * `switch_indicator'
				
				* Check for non-positive values and stop if any are found
				if (`a_loop' < 0 | `b_loop' < 0 | `c_loop' < 0 | `d_loop' < 0) {
					di as error "An issue was encountered during the computation: one of the values became non-positive, leading to the generation of NaN in the calculations."
					exit 1
					}
	  
				quietly gettkfnl `a_loop' `b_loop' `c_loop' `d_loop'
				local t_loop = `r(tknfl)'

	}

	 
	if (`t_start' > `thr_t'){
		local c_loopsec = `c_loop' + 1 * (1 - `switch_indicator')
        local d_loopsec = `d_loop' - 1 * (1 - `switch_indicator')
        local a_loopsec = `a_loop' - 1 * `switch_indicator'
        local b_loopsec = `b_loop' + 1 * `switch_indicator'
		
	}
	
	else if(`t_start' < `thr_t'){
		local c_loopsec = `c_loop'
        local d_loopsec = `d_loop'
        local a_loopsec = `a_loop'
        local b_loopsec = `b_loop'
	}

}

if (`t_loop' > `thr_t'){
	while ((`t_loop' > `thr_t') & (`c_loop' + 1 * (1 - `switch_indicator') > 0) & (`d_loop' - 1 * (1 - `switch_indicator') > 0) & (`a_loop' - 1 * `switch_indicator' > 0) & (`b_loop' + 1 * `switch_indicator' > 0)){
			local c_loop = `c_loop' + 1 * (1 - `switch_indicator')
			local d_loop = `d_loop' - 1 * (1 - `switch_indicator')
			local a_loop = `a_loop' - 1 * `switch_indicator'
			local b_loop = `b_loop' + 1 * `switch_indicator'
			
		* Check for non-positive values and stop if any are found
	  if (`a_loop' < 0 | `b_loop' < 0 | `c_loop' < 0 | `d_loop' < 0) {
	  	di as error "An issue was encountered during the computation: one of the values became non-positive, leading to the generation of NaN in the calculations."
		exit 1
        }
			
			quietly gettkfnl `a_loop' `b_loop' `c_loop' `d_loop'
			local t_loop = `r(tknfl)'
			}

	if (`t_start' < `thr_t'){
		local c_loopsec = `c_loop' - 1 * (1 - `switch_indicator')
        local d_loopsec = `d_loop' + 1 * (1 - `switch_indicator')
        local a_loopsec = `a_loop' + 1 * `switch_indicator'
        local b_loopsec = `b_loop' - 1 * `switch_indicator'
	}
	else if (`t_start' > `thr_t') {
		local c_loopsec = `c_loop'
        local d_loopsec = `d_loop'
        local a_loopsec = `a_loop'
        local b_loopsec = `b_loop'
	}
}


quietly fisher_p  `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
local p_loopsec = `r(fisherp)'

// // start 2nd round brute force - use fisher test p value as evaluation criterion
// // scenario 1 need to reduce odds ratio to invalidate the inference-need to increase p

if (`isinvalidate_start' == 1 & `dcroddsratio_start' == 1){
	if (`p_loopsec' < `thr_p'){
		while (`p_loopsec' < `thr_p'){
			local c_loopsec = `c_loopsec' + 1 * (1 - `switch_indicator')
			local d_loopsec = `d_loopsec' - 1 * (1 - `switch_indicator')
			local a_loopsec = `a_loopsec' - 1 * `switch_indicator'
			local b_loopsec = `b_loopsec' + 1 * `switch_indicator'
			
			quietly fisher_p  `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
			local p_loopsec = `r(fisherp)'
		}
		local c_final = `c_loopsec'
		local d_final = `d_loopsec'
		local a_final = `a_loopsec'
		local b_final = `b_loopsec'
	}
	dis "(`p_loopsec' > `thr_p')"
	
	if (`p_loopsec' > `thr_p'){
		dis "here"
		
		while (`p_loopsec' > `thr_p'){
			dis "while loop"
			local c_loopsec = `c_loopsec' - 1 * (1 - `switch_indicator')
			local d_loopsec = `d_loopsec' + 1 * (1 - `switch_indicator')
			local a_loopsec = `a_loopsec' + 1 * `switch_indicator'
			local b_loopsec = `b_loopsec' - 1 * `switch_indicator'
			
			quietly fisher_p  `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
			local p_loopsec = `r(fisherp)'
		}
		
		local c_final = `c_loopsec' + 1 * (1 - `switch_indicator')
        local d_final = `d_loopsec' - 1 * (1 - `switch_indicator')
        local a_final = `a_loopsec' - 1 * `switch_indicator'
        local b_final = `b_loopsec' + 1 * `switch_indicator'
	}	
}

// // scenario 2 need to reduce odds ratio to sustain the inference-need to reduce p
if (`isinvalidate_start' == 0 & `dcroddsratio_start' == 1){
	if (`p_loopsec' < `thr_p'){ //taylor too  much, return some odds ratio
		while (`p_loopsec' < `thr_p'){
			local c_loopsec = `c_loopsec' - 1 * (1 - `switch_indicator')
			local d_loopsec = `d_loopsec' + 1 * (1 - `switch_indicator')
			local a_loopsec = `a_loopsec' + 1 * `switch_indicator'
			local b_loopsec = `b_loopsec' - 1 * `switch_indicator'
			
			quietly fisher_p  `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
			local p_loopsec = `r(fisherp)'
		}
		local c_final = `c_loopsec' + 1 * (1 - `switch_indicator')
		local d_final = `d_loopsec' - 1 * (1 - `switch_indicator')
		local a_final = `a_loopsec' - 1 * `switch_indicator'
		local b_final = `b_loopsec' + 1 * `switch_indicator'
	}
	
	if (`p_loopsec' > `thr_p'){ //taylor not enough, continue to reduce odds ratio
		while (`p_loopsec' > `thr_p'){
			local c_loopsec = `c_loopsec' + 1 * (1 - `switch_indicator')
			local d_loopsec = `d_loopsec' - 1 * (1 - `switch_indicator')
			local a_loopsec = `a_loopsec' - 1 * `switch_indicator'
			local b_loopsec = `b_loopsec' + 1 * `switch_indicator'
			
			quietly fisher_p  `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
			local p_loopsec = `r(fisherp)'
		}
		
		local c_final = `c_loopsec'
        local d_final = `d_loopsec'
        local a_final = `a_loopsec'
        local b_final = `b_loopsec'
	}	
}

// // scenario 3 need to increase odds ratio to invalidate the inference-need to increase p
if (`isinvalidate_start' == 1 & `dcroddsratio_start' == 0){
	if (`p_loopsec' < `thr_p'){ //taylor too  much, return some odds ratio
		while (`p_loopsec' < `thr_p'){
			local c_loopsec = `c_loopsec' - 1 * (1 - `switch_indicator')
			local d_loopsec = `d_loopsec' + 1 * (1 - `switch_indicator')
			local a_loopsec = `a_loopsec' + 1 * `switch_indicator'
			local b_loopsec = `b_loopsec' - 1 * `switch_indicator'
			
			quietly fisher_p  `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
			local p_loopsec = `r(fisherp)'
		}
		local c_final = `c_loopsec'
		local d_final = `d_loopsec'
		local a_final = `a_loopsec'
		local b_final = `b_loopsec'
	}
	
	if (`p_loopsec' > `thr_p'){ //taylor not enough, continue to reduce odds ratio
		while (`p_loopsec' > `thr_p'){
			local c_loopsec = `c_loopsec' + 1 * (1 - `switch_indicator')
			local d_loopsec = `d_loopsec' - 1 * (1 - `switch_indicator')
			local a_loopsec = `a_loopsec' - 1 * `switch_indicator'
			local b_loopsec = `b_loopsec' + 1 * `switch_indicator'
			
			quietly fisher_p  `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
			local p_loopsec = `r(fisherp)'
		}
		
		local c_final = `c_loopsec' - 1 * (1 - `switch_indicator')
		local d_final = `d_loopsec' + 1 * (1 - `switch_indicator')
		local a_final = `a_loopsec' + 1 * `switch_indicator'
		local b_final = `b_loopsec' - 1 * `switch_indicator'
	}	
}

// // scenario 4 need to increase odds ratio to sustain the inference-need to decrease p

if (`isinvalidate_start' == 0 & `dcroddsratio_start' == 0){
	if (`p_loopsec' < `thr_p'){ //taylor too  much, return some odds ratio
		while (`p_loopsec' < `thr_p'){
			local c_loopsec = `c_loopsec' + 1 * (1 - `switch_indicator')
			local d_loopsec = `d_loopsec' - 1 * (1 - `switch_indicator')
			local a_loopsec = `a_loopsec' - 1 * `switch_indicator'
			local b_loopsec = `b_loopsec' + 1 * `switch_indicator'
			
			quietly fisher_p  `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
			local p_loopsec = `r(fisherp)'
		}
		
		local c_final = `c_loopsec' - 1 * (1 - `switch_indicator')
		local d_final = `d_loopsec' + 1 * (1 - `switch_indicator')
		local a_final = `a_loopsec' + 1 * `switch_indicator'
		local b_final = `b_loopsec' - 1 * `switch_indicator'
		
	}	
	
	if (`p_loopsec' > `thr_p'){ //taylor not enough, continue to reduce odds ratio
	
		while (`p_loopsec' > `thr_p'){
			local c_loopsec = `c_loopsec' - 1 * (1 - `switch_indicator')
			local d_loopsec = `d_loopsec' + 1 * (1 - `switch_indicator')
			local a_loopsec = `a_loopsec' + 1 * `switch_indicator'
			local b_loopsec = `b_loopsec' - 1 * `switch_indicator'
			
			quietly fisher_p  `a_loopsec' `b_loopsec' `c_loopsec' `d_loopsec'
			local p_loopsec = `r(fisherp)'
		}
		local c_final = `c_loopsec'
		local d_final = `d_loopsec'
		local a_final = `a_loopsec'
		local b_final = `b_loopsec'
	}
}

// final result and returns:
matrix define table_final = (`a_final', `b_final' \ `c_final', `d_final')

quietly fisher_p  `a_final' `b_final' `c_final' `d_final'
local p_final = `r(fisherp)'

quietly fisher_oddsratio `a_final' `b_final' `c_final' `d_final'
local fisher_final = `r(fratio)'

if (`switch_trm' == `allnotenough'){
	local final = abs(`a1' - `a_final') + `allnotenough' * abs(`c1' - `c_final')
}
else {
	local final = abs(`c1' - `c_final') + `allnotenough' * abs(`a1' - `a_final')
}

if (`allnotenough' == 1){
	local taylor_pred = .
	local perc_bias_pred = .
	
	if (`switch_trm'){
		local final_extra = abs(`a1' - `a_final')
	}
	else{
		local final_extra = abs(`c1' - `c_final')
	}
}
else {
	local final_extra = 0
}

local total_switch = `final' + `allnotenough' * `final_extra'


return local final_switch =`final'
return local p_final = `p_final'
return local fisher_final = `fisher_final'
return local needtworows = `allnotenough'
return local taylor_pred = `taylor_pred'
return local perc_bias_pred = `perc_bias_pred'
return local final_extra = `final_extra'
return local dcroddsratio_ob = `dcroddsratio_ob'
// muted 092924
//return local total_switch = `total_switch'
return local isinvalidate_ob = `isinvalidate_ob'

dis "Switch fisher is done for now!"
mat list table_start

mat list table_final

// dis "tryall_p `tryall_p'"
// dis "fisher_p `fisher_p'"
// dis `dcroddsratio_start'
// dis "switch_trm "`switch_trm'
// dis "thr_t `thr_t'"
// dis "(`thr_p' - `tryall_p') * `tryall_est'"
// dis "`tryall_est' * `est1'"
// dis `allnotenough'
// dis "`a_tryall' \ `b_tryall' \ `c_tryall' \ `d_tryall'"
// dis `tryall_p'
// dis "here"
//

end

// #18
* cop_pse_aux function: 1
capture program drop cal_ryz
program define cal_ryz, rclass
    syntax anything
    local ryxgz : word 1 of `anything'
    local rs : word 2 of `anything'
    local r2yz = (`ryxgz'*`ryxgz' - `rs')/(`ryxgz'*`ryxgz' - 1)
	
    if `r2yz' >= 0 {
        local ryz = sqrt(`r2yz')
    }
    else {
        display as error "The calculated variance in Y explained by Z is less than 0. This can occur if Z" _newline "suppresses the relationship between X and Y. That is, if partialling on Z increases" _newline "the relationship between X and Y. Note, the unconditional ITCV is not conceptualized for this scenario."
        exit 198
    }
    return scalar ryz = `ryz'
end

// #19
* cop_pse_aux function: 2
capture program drop cal_rxz
program define cal_rxz, rclass
    syntax anything
    local var_x : word 1 of `anything'
    local var_y : word 2 of `anything'
    local r2 : word 3 of `anything'
    local df : word 4 of `anything'
    local std_err : word 5 of `anything'
	*local denom = `var_x' * `df' * `std_err'^2
    *di "Denominator = `denom'"
    *local r2xz = 1 - ((`var_y' * (1 - `r2'))/`denom')
    *di "r2xz = `r2xz'"

    local r2xz = 1 - ((`var_y' * (1 - `r2'))/(`var_x' * `df' * `std_err'^2))
    if `r2xz' <= 0 {
        di "error! r2xz < 0!"
        exit 198
    }
    local rxz = sqrt(`r2xz')
    return scalar rxz = `rxz'
end

// #20
* cop_pse_aux function: 3
capture program drop cal_rxy
program define cal_rxy, rclass
    syntax anything
    local ryxgz : word 1 of `anything'
    local rxz : word 2 of `anything'
    local ryz : word 3 of `anything'
    local rxy = `ryxgz' * sqrt((1 - `rxz'^2)*(1 - `ryz'^2)) + `rxz' * `ryz'
    return scalar rxy = `rxy'
end

// #21
* cop_pse_aux function: 4
capture program drop cal_delta_star
program define cal_delta_star, rclass
    syntax anything
    local fr2max : word 1 of `anything'
    local r2 : word 2 of `anything'
    local r2_uncond : word 3 of `anything'
    local est_eff : word 4 of `anything'
    local eff_thr : word 5 of `anything'
    local var_x : word 6 of `anything'
    local var_y : word 7 of `anything'
    local eff_uncond : word 8 of `anything'
    local rxz : word 9 of `anything'
    local n_obs : word 10 of `anything'
  
    if `fr2max' > .99 {
        local fr2max = .99
    }
    if `fr2max' > `r2' {
        local d = sqrt(`fr2max' - `r2')
    }
    
	
    local bt_m_b = `est_eff' - `eff_thr'
    local rt_m_ro_t_syy = (`r2' - `r2_uncond') * `var_y'
    local b0_m_b1 = `eff_uncond' - `est_eff'
	local b0_m_b1_2 = (`b0_m_b1')^2
    local rm_m_rt_t_syy = (`fr2max' - `r2') * `var_y'
    local t_x = `var_x' * (`n_obs' / (`n_obs' - 1)) * (1 - `rxz'^2)
    local num1 = `bt_m_b' * `rt_m_ro_t_syy' * `t_x'
    local num2 = `bt_m_b' * `var_x' * `t_x' * `b0_m_b1_2'
    local num3 = 2 * `bt_m_b'^2 * (`t_x' * `b0_m_b1' * `var_x')
    local num4 = `bt_m_b'^3 * (`t_x' * `var_x' - `t_x'^2)
    local num = `num1' + `num2' + `num3' + `num4'   
    local den1 = `rm_m_rt_t_syy' * `b0_m_b1' * `var_x'
    local den2 = `bt_m_b' * `rm_m_rt_t_syy' * (`var_x' - `t_x')
    local den3 = `bt_m_b'^2 * (`t_x' * `b0_m_b1' * `var_x')
    local den4 = `bt_m_b'^3 * (`t_x' * `var_x' - `t_x'^2)
    local den = `den1' + `den2' + `den3' + `den4'
    local delta_star = `num' / `den'
    return scalar bt_m_b = `bt_m_b'
    return scalar rt_m_ro_t_syy = `rt_m_ro_t_syy'
    return scalar b0_m_b1 = `b0_m_b1'
	return scalar b0_m_b1_2 = `b0_m_b1_2'
    return scalar rm_m_rt_t_syy = `rm_m_rt_t_syy'
    return scalar t_x = `t_x'
    return scalar num1 = `num1'
    return scalar num2 = `num2'
    return scalar num3 = `num3'
    return scalar num4 = `num4'
    return scalar num = `num'   
    return scalar den1 = `den1'
    return scalar den2 = `den2'
    return scalar den3 = `den3'
    return scalar den4 = `den4'
    return scalar den = `den'
    display "bt_m_b = "`bt_m_b'
    display "rt_m_ro_t_syy = "`rt_m_ro_t_syy'
    display "b0_m_b1 = "`b0_m_b1'
	display "b0_m_b1_2 = "`b0_m_b1_2'
    display "rm_m_rt_t_syy = "`rm_m_rt_t_syy'
    display "t_x = "`t_x'
    display "num1 = "`num1'
    display "num2 = "`num2'
    display "num3 = "`num3'
    display "num4 = "`num4'
    display "num = "`num'   
    display "den1 = "`den1'
    display "den2 = "`den2'
    display "den3 = "`den3'
    display "den4 = "`den4'
    display "den = "`den'
    display "delta_star = "`delta_star'
			
	return scalar delta_star = `delta_star'
end

// #22
* cop_pse_aux function: 5
capture program drop cal_pse

program define cal_pse, rclass
syntax anything
* parse input parameters
local thr : word 1 of `anything'
local kryx : word 2 of `anything'
    
* Define complex numbers i1 and i2
local i1_real = 1
local i1_imag = -sqrt(3)
local i2_real = 1
local i2_imag = sqrt(3)

* Calculate a
local a = -((2 - `thr'^2 + 2 * `thr' * `kryx' - 2 * `kryx'^2) / (3 * (-1 + `kryx'^2)))

* Calculate b (split into real and imaginary parts)
local b_real = `i1_real' * (-(2 - `thr'^2 + 2 * `thr' * `kryx' - 2 * `kryx'^2)^2 + 6 * (-1 + `kryx'^2) * (`thr'^2 - 2 * `thr' * `kryx' + `kryx'^2))
local b_imag = `i1_imag' * (-(2 - `thr'^2 + 2 * `thr' * `kryx' - 2 * `kryx'^2)^2 + 6 * (-1 + `kryx'^2) * (`thr'^2 - 2 * `thr' * `kryx' + `kryx'^2))


***

* Calculate c1_expr
local c1_expr = -16 + 15 * `thr'^2 + 6 * `thr'^4 + 2 * `thr'^6 - 30 * `thr' * `kryx' - 24 * `thr'^3 * `kryx' - 12 * `thr'^5 * `kryx' + 39 * `kryx'^2 + 12 * `thr'^2 * `kryx'^2 + 18 * `thr'^4 * `kryx'^2 + 24 * `thr' * `kryx'^3 + 8 * `thr'^3 * `kryx'^3 - 30 * `kryx'^4 - 27 * `thr'^2 * `kryx'^4 + 6 * `thr' * `kryx'^5 + 7 * `kryx'^6

dis "c1_expr = `c1_expr'"

* Calculate the components for c1_sqrt
local part1 = (`c1_expr')^2
local part2 = 4 * (-(2 - `thr'^2 + 2 * `thr' * `kryx' - 2 * `kryx'^2)^2 + 6 * (-1 + `kryx'^2) * (`thr'^2 - 2 * `thr' * `kryx' + `kryx'^2))^3
local sum_parts = `part1' + `part2'

dis "part1 = `part1', part2 = `part2', sum_parts = `sum_parts'"

* Compute the real and imaginary parts of the square root
local real_part_sqrt = sqrt((`sum_parts' + abs(`sum_parts')) / 2)
local imag_part_sqrt = sqrt((abs(`sum_parts') - `sum_parts') / 2)

* Display the components of c1_sqrt
display "Real part of c1_sqrt: `real_part_sqrt'"
display "Imaginary part of c1_sqrt: `imag_part_sqrt'"


local c1_expr_2 = -16 + 15 * `thr'^2 + 6 * `thr'^4 + 2 * `thr'^6 - 30 * `thr' * `kryx' - 24 * `thr'^3 * `kryx' - 12 * `thr'^5 * `kryx' + 39 * `kryx'^2 + 12 * `thr'^2 * `kryx'^2 + 18 * `thr'^4 * `kryx'^2 + 24 * `thr' * `kryx'^3 + 8 * `thr'^3 * `kryx'^3 - 30 * `kryx'^4 - 27 * `thr'^2 * `kryx'^4 + 6 * `thr' * `kryx'^5 + 7 * `kryx'^6 

dis "c1_expr_2 = `c1_expr_2'"

* Calculate modulus and argument of the complex number c1_expr_2 + imag_part_sqrt * i
local modulus = sqrt((`c1_expr_2')^2 + `imag_part_sqrt'^2)
local argument = atan2(`imag_part_sqrt', `c1_expr_2')

dis "modulus = `modulus', argument = `argument'"

* Calculate the cube root of the modulus
local cube_root_modulus = `modulus'^(1/3)

dis "cube_root_modulus = `cube_root_modulus'"

* Calculate the real and imaginary parts of the cube root
local c1_real = `cube_root_modulus' * cos(`argument' / 3)
local c1_imag = `cube_root_modulus' * sin(`argument' / 3)

dis "c1_real = `c1_real', c1_imag = `c1_imag'"

if missing(`c1_real') {
    local c1_real = 0
}

if missing(`c1_imag') {
    local c1_imag = 0
}

* Display the components of c1
display "Real part of c1: `c1_real'"
display "Imaginary part of c1: `c1_imag'"

* Calculate c2
local c2 = 3 * 2^(2/3) * (-1 + `kryx'^2)

* Calculate c (considering only the real part for simplicity)
local c_real = `c2' * `c1_real'

local c_imag = `c2' * `c1_imag'

* Display the result
display "Real part of c: `c_real'"
display "Imaginary part of c: `c_imag'"

***

* Calculate d (split into real and imaginary parts)
local d_real = 1 / (6 * 2^(1/3) * (-1 + `kryx'^2)) * `i2_real'
local d_imag = 1 / (6 * 2^(1/3) * (-1 + `kryx'^2)) * `i2_imag'

dis "d = `d_real' + `d_imag'"


*****

local f1_expr = -16 + 15 * `thr'^2 + 6 * `thr'^4 + 2 * `thr'^6 - 30 * `thr' * `kryx' - 24 * `thr'^3 * `kryx' - 12 * `thr'^5 * `kryx' + 39 * `kryx'^2 + 12 * `thr'^2 * `kryx'^2 + 18 * `thr'^4 * `kryx'^2 + 24 * `thr' * `kryx'^3 + 8 * `thr'^3 * `kryx'^3 - 30 * `kryx'^4 - 27 * `thr'^2 * `kryx'^4 + 6 * `thr' * `kryx'^5 + 7 * `kryx'^6

dis "f1_expr = `f1_expr'"

local f1_expr_2 = -(2 - `thr'^2 + 2 * `thr' * `kryx' - 2 * `kryx'^2)^2 + 6 * (-1 + `kryx'^2) * (`thr'^2 - 2 * `thr' * `kryx' + `kryx'^2)

dis "f1_expr_2 = `f1_expr_2'"


* Calculate the components for f1_sqrt
local part1 = (`f1_expr')^2
local part2 = 4 * (`f1_expr_2')^3
local sum_parts = `part1' + `part2'

display "part1 = `part1'"
display "part2 = `part2'"
display "sum_parts = `sum_parts'"

* Compute the real and imaginary parts of the square root
local real_part_sqrt = sqrt((`sum_parts' + abs(`sum_parts')) / 2)
local imag_part_sqrt = sqrt((abs(`sum_parts') - `sum_parts') / 2)

* Combine the real and imaginary parts into a complex number
local f1_sqrt_real = `real_part_sqrt'
local f1_sqrt_imag = `imag_part_sqrt'

* Display the components of f1_sqrt
display "Real part of f1_sqrt: `f1_sqrt_real'"
display "Imaginary part of f1_sqrt: `f1_sqrt_imag'"

* Calculate f1 as given in R code
local f1 = -16 + 15 * `thr'^2 + 6 * `thr'^4 + 2 * `thr'^6 - 30 * `thr' * `kryx' - 24 * `thr'^3 * `kryx' - 12 * `thr'^5 * `kryx' + 39 * `kryx'^2 + 12 * `thr'^2 * `kryx'^2 + 18 * `thr'^4 * `kryx'^2 + 24 * `thr' * `kryx'^3 + 8 * `thr'^3 * `kryx'^3 - 30 * `kryx'^4 - 27 * `thr'^2 * `kryx'^4 + 6 * `thr' * `kryx'^5 + 7 * `kryx'^6

display "f1 = `f1'"

* Calculate the modulus and argument of the complex number (f1 + f1_sqrt)
local f_combined_real = `f1' + `f1_sqrt_real'
local f_combined_imag = `f1_sqrt_imag'

local f_modulus = sqrt((`f_combined_real')^2 + (`f_combined_imag')^2)
local f_argument = atan2(`f_combined_imag', `f_combined_real')

* Calculate the cube root of the modulus
local f_cube_root_modulus = `f_modulus'^(1/3)

* Calculate the real and imaginary parts of the cube root
local f_real = `f_cube_root_modulus' * cos(`f_argument' / 3)
local f_imag = `f_cube_root_modulus' * sin(`f_argument' / 3)

* Handle NaN case for real part
if missing(`f_real') {
    local f_real = 0
}

if missing(`f_imag') {
    local f_imag = 0
}

* Display the result
display "Real part of f: `f_real'"
display "Imaginary part of f: `f_imag'"

*****

* Calculate temp (separate real and imaginary parts)
local temp_real = `a' + `b_real' / `c_real' - `d_real' * `f_real'
local temp_imag = `b_imag' / `c_imag' - `d_imag' * `f_imag'

display "a = `a'"
display "b_real = `b_real'"
display "c_real = `c_real'"
display "d_real = `d_real'"
display "f_real = `f_real'"

display "b_imag = `b_imag'"
display "c_imag = `c_imag'"
display "d_imag = `d_imag'"
display "f_imag = `f_imag'"


* Calculate temp_real and temp_imag
* temp = a + b / c - d * f
local denominator_real = `c_real' * `c_real' + `c_imag' * `c_imag'
local denominator_imag = `c_real' * `c_imag' - `c_imag' * `c_real'

local b_over_c_real = (`b_real' * `c_real' + `b_imag' * `c_imag') / `denominator_real'
local b_over_c_imag = (`b_imag' * `c_real' - `b_real' * `c_imag') / `denominator_real'

local d_times_f_real = `d_real' * `f_real' - `d_imag' * `f_imag'
local d_times_f_imag = `d_real' * `f_imag' + `d_imag' * `f_real'

local temp_real = `a' + `b_over_c_real' - `d_times_f_real'
local temp_imag = `b_over_c_imag' - `d_times_f_imag'

* Display the results of temp_real and temp_imag
display "temp_real = `temp_real'"
display "temp_imag = `temp_imag'"

* Calculate rxcvGz_sepreserve and rycvGz_sepreserve
local rxcvGz_sepreserve = sqrt(`temp_real')
local rycvGz_sepreserve = (`kryx' - `thr' * (1 - `rxcvGz_sepreserve'^2)) / `rxcvGz_sepreserve'

* Display the results
display "rxcvGz_sepreserve: " `rxcvGz_sepreserve'
display "rycvGz_sepreserve: " `rycvGz_sepreserve'

return scalar rxcvgz_sepreserve = `rxcvGz_sepreserve'
return scalar rycvgz_sepreserve = `rycvGz_sepreserve'

end

// #23
* cop_pse_aux function: 6
capture program drop verify_reg_gzcv
program define verify_reg_gzcv, rclass
syntax anything

* input
local n_obs : word 1 of `anything'
local sdx : word 2 of `anything'
local sdy : word 3 of `anything'
local sdz : word 4 of `anything'
local sdcv : word 5 of `anything'
local rxy : word 6 of `anything'
local rxz : word 7 of `anything'
local rzy : word 8 of `anything'
local rcvy : word 9 of `anything'
local rcvx : word 10 of `anything'
local rcvz : word 11 of `anything'

* cal
local ccvy = `rcvy' * `sdcv' * `sdy'
local ccvx = `rcvx' * `sdcv' * `sdx'
local ccvz = `rcvz' * `sdcv' * `sdz'
local cxy = `rxy' * `sdx' * `sdy'
local czy = `rzy' * `sdz' * `sdy'
local cxz = `rxz' * `sdx' * `sdz'
local sdy2 = `sdy'^2
local sdx2 = `sdx'^2
local sdz2 = `sdz'^2
local sdcv2 = `sdcv'^2
*verify_reg_gzcv 6174 0.217 0.991 1 1 0.439670055967072 0.864070322724123 0.500809512977466 0.599320205585528 0.00967147228824988 0


* set matrix
matrix covmatrix = (`sdy2', `cxy', `czy', `ccvy' \ `cxy', `sdx2', `cxz', `ccvx' \ `czy', `cxz', `sdz2', `ccvz' \ `ccvy', `ccvx', `ccvz', `sdcv2')
matrix rownames covmatrix = y x z cv
matrix colnames covmatrix = y x z cv

preserve
clear
quietly ssd init y x z cv
quietly ssd set obs `n_obs'
quietly ssd set cov `sdy2' \ `cxy' `sdx2' \ `czy' `cxz' `sdz2' \ `ccvy' `ccvx' `ccvz' `sdcv2'
quietly ssd set means 0 0 0 0
*ssd status
*ssd list
quietly save matrixcov, replace
	
    quietly sem (y <- x z cv)
    *est store m1
	
    * Checking and displaying results
    if _rc == 0 {
        display "Model fitted successfully."

    * display unstandardized coefficient and std_err
    estimates table, b se

    * R-squared
    quietly estat gof, stats(all)
    matrix B = e(b)
    matrix V = e(V)
    /*
	matrix list e(b)
    matrix list e(V) 
	*/

    * 计算Y变量的残差方差
    local resvar = el(B,1,5)

    * 计算R-squared
    local r2 = 1 - (`resvar'/`sdy2')
    
    /*display "R-squared is " `r2'*/
    return scalar r2 = `r2'	
    local betax = el(B, 1, 1)
    local betaz = el(B, 1, 2)
    local betacv = el(B, 1, 3)
    local sex = sqrt(el(V, 1, 1))
    local sez = sqrt(el(V, 2, 2))
    local secv = sqrt(el(V, 3, 3))	
    return scalar r2 = `r2'
    return scalar betax = `betax'
    return scalar sex = `sex'
    return scalar betaz = `betaz'
    return scalar sez = `sez'
    return scalar betacv = `betacv'
    return scalar secv = `secv'
/*
    di "r2: " `r2'
	di "Betax: " `betax'
	di "Betaz: " `betaz'
	di "Betacv: " `betacv'
	di "sex: " `sex'
	di "sez: " `sez'
	di "secv: " `secv'
	*/
    }
    else {
        display "Error fitting model."
    }

restore

* set matrix
matrix cormatrix = (1, `rxy', `rzy', `rcvy' \ `rxy', 1, `rxz', `rcvx' \ `rzy', `rxz', 1, `rcvz' \ `rcvy', `rcvx', `rcvz', 1)
matrix rownames cormatrix = yr xr zr cvr
matrix colnames cormatrix = yr xr zr cvr

preserve
clear
quietly ssd init yr xr zr cvr
quietly ssd set obs `n_obs'
quietly ssd set cor 1 \ `rxy' 1 \ `rzy' `rxz' 1 \ `rcvy' `rcvx' `rcvz' 1
quietly ssd set means 0 0 0 0
*ssd status
*ssd list
quietly save matrixcor, replace
    quietly sem (yr <- xr zr cvr)

* check
    if _rc == 0 {
display "SEM model fitted successfully."
    * display unstandardized coefficient and std_err
    estimates table, b se
* R-squared
    quietly estat gof, stats(all)

    matrix Br = e(b)
    matrix Vr = e(V)
    /*
	matrix list e(b)
    matrix list e(V) 
	*/
    * 计算Y变量的残差方差
    local resvarr = el(Br,1,5)

    * 计算R-squared
    local r2r = 1 - (`resvarr'/`sdy2')
    
    /*display "R-squared is " `r2r'*/
    return scalar r2r = `r2r'	
    local betaxr = el(Br, 1, 1)
    local betazr = el(Br, 1, 2)
    local betacvr = el(Br, 1, 3)
    local sexr = sqrt(el(Vr, 1, 1))
    local sezr = sqrt(el(Vr, 2, 2))
    local secvr = sqrt(el(Vr, 3, 3))

    return scalar r2r = `r2r'
    return scalar betaxr = `betaxr'
    return scalar sexr = `sexr'
    return scalar betazr = `betazr'
    return scalar sezr = `sezr'
    return scalar betacvr = `betacvr'
    return scalar secvr = `secvr'
svmat cormatrix

* Save the dataset
quietly save cormatrix_dataset.dta, replace
}
else {
    display "SEM model fitting encountered an error with code `_rc'."
}

// Return the matrices
return matrix covmatrix = covmatrix
return matrix cormatrix = cormatrix

restore


end

// #24
* cop_pse_aux function: 7
* defining verify_manual in stata
capture program drop verify_manual
program define verify_manual, rclass
    syntax anything
	
local rxy : word 1 of `anything'
local rxz : word 2 of `anything'
local rxcv : word 3 of `anything'
local ryz : word 4 of `anything'
local rycv : word 5 of `anything'
local rzcv : word 6 of `anything'
local sdy : word 7 of `anything'
local sdx : word 8 of `anything'


* calculating beta
local beta = (`rxy' + `rycv' * `rxz' * `rzcv' + `ryz' * `rxcv' * `rzcv' - `rxy' * `rzcv'^2 - `rycv' * `rxcv' - `ryz' * `rxz') / (1 + 2 * `rxcv' * `rzcv' * `rxz' - `rxcv'^2 - `rzcv'^2 - `rxz'^2)
local eff = `beta' * `sdy' / `sdx'

* display outcome
di "Beta: " `beta'
di "Effect Size: " `eff'

end


// #25
* cop_pse_aux function: 8
capture program drop verify_reg_gz
program define verify_reg_gz, rclass
syntax anything

* parse input parameters
local n_obs : word 1 of `anything'
local sdx : word 2 of `anything'
local sdy : word 3 of `anything'
local sdz : word 4 of `anything'
local rxy : word 5 of `anything'
local rxz : word 6 of `anything'
local rzy : word 7 of `anything'

*verify_reg_gz 6174 0.217 0.991 1 0.439670055967072 0.864070322724123 0.500809512977466  0.599320205585528 1 0.00967147228824988 0	

local cxy = `rxy' * `sdx' * `sdy'
local czy = `rzy' * `sdz' * `sdy'
local cxz = `rxz' * `sdx' * `sdz'
local sdy2 = `sdy'^2
local sdx2 = `sdx'^2
local sdz2 = `sdz'^2

* set matrix
matrix covmatrix = (`sdy2', `cxy', `czy' \ `cxy', `sdx2', `cxz' \ `czy', `cxz', `sdz2' )
matrix rownames covmatrix = y x z
matrix colnames covmatrix = y x z
	
preserve

* setup the covariance matrix in stata
clear
quietly ssd init y x z
quietly ssd set obs `n_obs'
quietly ssd set cov `sdy2' \ `cxy' `sdx2' \ `czy' `cxz' `sdz2'
quietly ssd set means 0 0 0

quietly sem (y <- x z)

* Check for errors in the model fitting process
if _rc == 0 {
	display "SEM model fitted successfully."
    estimates table, b se

    * R-squared
    quietly estat gof, stats(all)
    matrix B_gz = e(b)
    matrix V_gz = e(V)
    
	/*
	matrix list e(b)
    matrix list e(V) 
	*/

    * calculate 
    local resvar_gz = el(B_gz,1,4)

    * Calculate R-squared
    local r2_gz = 1 - (`resvar_gz'/`sdy2')
    
    /*display "R-squared is " `r2'*/
    return scalar r2_gz = `r2_gz'	
    
	local betax_gz = el(B_gz, 1, 1)
    local betaz_gz = el(B_gz, 1, 2)
    local sex_gz = sqrt(el(V_gz, 1, 1))
    local sez_gz = sqrt(el(V_gz, 2, 2))
        
    * Return coefficients and standard errors
	return scalar r2_gz = `r2_gz'
    return scalar betax_gz = `betax_gz'
    return scalar betaz_gz = `betaz_gz'
    return scalar sex_gz = `sex_gz'
    return scalar sez_gz = `sez_gz'

	/*
    di "r2_gz: " `r2_gz'
	di "Betax_gz: " `betax_gz'
	di "Betaz_gz: " `betaz_gz'
	di "sex_gz: " `sex_gz'
	di "sez_gz: " `sez_gz'
	*/
	}
	else {
		if _rc == 601 {
            display "Data-related error in SEM model fitting."
        }
        else if _rc == 602 {
            display "Specification-related error in SEM model fitting."
        }
        else {
            display "SEM model fitting failed. Unspecified error code: `_rc'."
        }
    }
    restore

end

// #26
* cop_pse_aux function: 9
capture program drop verify_reg_uncond

program define verify_reg_uncond, rclass
syntax anything

* parse input parameters
local n_obs : word 1 of `anything'
local sdx : word 2 of `anything'
local sdy : word 3 of `anything'
local rxy : word 4 of `anything'

* calculate covariance based on input parameters
local cxy = `rxy' * `sdx' * `sdy'
local sdy2 = `sdy'^2
local sdx2 = `sdx'^2
	
matrix covmatrix = (`sdy2', `cxy' \ `cxy', `sdx2' )
matrix rownames covmatrix = y x
matrix colnames covmatrix = y x
	
preserve	

* setup covariance matrix in stata
clear
quietly ssd init y x
quietly ssd set obs `n_obs'
quietly ssd set cov `sdy2' \ `cxy' `sdx2'
quietly ssd set means 0 0

quietly sem (y <- x)

* check for errors in the model fitting process
if _rc == 0 {
	display "SEM model fitted successfully."
    estimates table, b se

    * R-squared
    quietly estat gof, stats(all)
    matrix B_uncond = e(b)
    matrix V_uncond = e(V)
   
	matrix list e(b)
    matrix list e(V) 
	*/

    * calculate
    local resvar_uncond = el(B_uncond,1,3)

    * R-squared
    local r2_uncond = 1 - (`resvar_uncond'/`sdy2')
    
    /*display "R-squared is " `r2'*/
    return scalar r2_uncond = `r2_uncond'	
	local betax_uncond = el(B_uncond, 1, 1)
    local sex_uncond = sqrt(el(V_uncond, 1, 1))
        
    * return
	return scalar r2_uncond = `r2_uncond'
    return scalar betax_uncond = `betax_uncond'
    return scalar sex_uncond = `sex_uncond'
		
	di "r2_uncond: " `r2_uncond'
	di "Betax_uncond: " `betax_uncond'
	di "sex_uncond: " `sex_uncond'
	*/
	}
    else {
        if _rc == 601 {
            display "Data-related error in SEM model fitting."
        }
        else if _rc == 602 {
            display "Specification-related error in SEM model fitting."
        }
        else {
            display "SEM model fitting failed. Unspecified error code: `_rc'."
        }
    }
    restore
end



capture program drop cal_max_rcvz
program define cal_max_rcvz, rclass
    syntax anything

    local fr2max    : word 1 of `anything'
    local est_eff   : word 2 of `anything'
    local sdx       : word 3 of `anything'
    local sdy       : word 4 of `anything'
    local std_err   : word 5 of `anything'
    local df        : word 6 of `anything'
    local eff_thr   : word 7 of `anything'
    local var_x     : word 8 of `anything'
    local var_y     : word 9 of `anything'
    local r2        : word 10 of `anything'
    local RX_Z      : word 11 of `anything'
	

    local r2xz = 1 - ((`var_y' * (1 - `r2'))/(`var_x' * `df' * (`std_err'^2)))
    if (`r2xz' <= 0) {
        di as error "Error: r2xz <= 0! 请检查 std_err, r2 或 df 的输入。"
        exit 198
    }
    local rxz = sqrt(`r2xz')
    return scalar rxz = `rxz'
	display "rxz "= `rxz'
    
    * -------------------------------
    * 标准化系数计算
    * -------------------------------
    local beta_thr = `eff_thr' * `sdx' / `sdy'
    return scalar beta_thr = `beta_thr'
    
    local se = `std_err' * `sdx' / `sdy'
    return scalar se = `se'
    
    local beta = `est_eff' * `sdx' / `sdy'
    return scalar beta = `beta'
    
    local tyxgz = `beta' / `se'
    return scalar tyxgz = `tyxgz'
    
    local ryxgz = `tyxgz' / sqrt(`df' - 6  + (`tyxgz'^2))
    return scalar ryxgz = `ryxgz'
	display "ryxgz="`ryxgz'
    
    local sdxgz = `sdx' * sqrt(1 - `rxz'^2)
    return scalar sdxgz = `sdxgz'
	display "sdxgz="`sdxgz'
    
    * -------------------------------
    * 计算 ryz（利用 ryxgz 和 r2 的关系）
    * -------------------------------
    local r2yz = ((`ryxgz'^2) - `r2') / ((`ryxgz'^2) - 1)
    if (`r2yz' < 0) {
        di as error "Error: r2yz < 0! 请检查输入值。"
        exit 198
    }
    local ryz = sqrt(`r2yz')
    return scalar ryz = `ryz'
    display "ryz="`ryz'
	
    local sdygz = `sdy' * sqrt(1 - `ryz'^2)
    return scalar sdygz = `sdygz'
    display "sdygz="`sdygz'
	
    * -------------------------------
    * 计算中间量 ryxcvgz_exact_sq
    * 公式： (fr2max - ryz^2) / (1 - ryz^2)
    * -------------------------------
    local ryxcvgz_exact_sq = (`fr2max' - `ryz'^2) / (1 - `ryz'^2)
    if (`ryxcvgz_exact_sq' < 0) {
        di as error "Error: ryxcvgz_exact_sq < 0!"
        exit 198
    }
    return scalar ryxcvgz_exact_sq = `ryxcvgz_exact_sq'
    display "ryxcvgz_exact_sq="`ryxcvgz_exact_sq'
	
    * -------------------------------
    * 计算 rxcvgz_exact（对应 R 中 rxcvGz_exact）
    * 公式：
    *   rxcvgz_exact = [ryxgz - (sdxgz/sdygz)*beta_thr] / 
    *                  sqrt( (sdxgz^2/sdygz^2)*beta_thr^2 - 2*ryxgz*(sdxgz/sdygz)*beta_thr + ryxcvgz_exact_sq )
    * -------------------------------
    local rxcvgz_exact = ( `ryxgz' - (`sdxgz' / `sdygz') * `beta_thr' ) / ///
        sqrt( (`sdxgz'^2 / `sdygz'^2) * `beta_thr'^2 - 2 * `ryxgz' * (`sdxgz' / `sdygz') * `beta_thr' + `ryxcvgz_exact_sq' )
    if (abs(`rxcvgz_exact') > 1) {
        di as error "Error: rxcvgz_exact 超出 [-1, 1] 范围！"
        exit 198
    }
    return scalar rxcvgz_exact = `rxcvgz_exact'
    display "rxcvgz_exact="`rxcvgz_exact'
	
    * -------------------------------
    * 根据 R 代码，首先计算 delta_exact
    * 其中先计算 rxcv_exact = sqrt(1 - rxz^2)*rxcvgz_exact，
    * 然后 delta_exact = rxcv_exact / rxz
    * -------------------------------
    local rxcv_exact = sqrt(1 - `rxz'^2) * `rxcvgz_exact'
    local delta_exact = `rxcv_exact' / `rxz'
	return scalar rxcv_exact = `rxcv_exact'
	return scalar delta_exact = `delta_exact'
    display "rxcv_exact="`rxcv_exact'
	display "delta_exact="`delta_exact'
    * -------------------------------
    * 根据 delta_exact 判断
    * 如果 delta_exact < 1，则 max_rCVZ 返回缺失值（在 Stata 中用 . 表示）
    * 否则按公式计算：
    *   max_rCVZ = [2 * rxcvgz_exact * rxz * sqrt(1 - rxz^2)] / abs(rxcvgz_exact^2 * rxz^2 - rxcvgz_exact^2 - rxz^2)
    * -------------------------------
    if (`delta_exact' < 1) {
        return scalar max_rcvz = .
        exit 0
    }
    else {
        local num = 2 * `rxcvgz_exact' * `RX_Z' * sqrt(1 - `RX_Z'^2)
        local denom = abs((`rxcvgz_exact'^2 * `RX_Z'^2) - `rxcvgz_exact'^2 - `RX_Z'^2)
        if (`denom' == 0) {
            di as error "Error: denominator is zero!"
            exit 198
        }
        local max_rcvz = `num' / `denom'
        return scalar max_rcvz = `max_rcvz'
    }
    display "max_rcvz="`max_rcvz'
end


// Main Function
* pkonfound_v2 (now its most updated pkonfound) with 3 types
capture program drop pkonfound
program define pkonfound, rclass
version 16.0
// please run geta1kfnl.ado; getc1kfnl.ado; geta2kfnl.ado; getc2kfnl.ado; isinvalidate.ado; isdcroddsratio.ado; getswitch.ado (gettknfl.ado,taylorexp.ado) prior to run this file with model_type == 1!!!

// please run fisher_p.ado, fisher_oddsratio.ado, chisqp.ado, chisq_value.ado, getswitch_fisher.ado (fisher_oddsratio.ado; fisher_p.ado; gettkfnl.ado; taylorexp.ado), getswitch_chisq.ado prior to run this file with model_type == 2!!!

syntax anything, [if] [in] [sig(real 0.05) nu(real 0) onetail(real 0) model_type(real 0) switch_trm(real 1) replace(real 1) rep_0(real 0) test1(real 0) far_bound(real 0) sdx(real -98765432123456789.987654321) sdy(real -98765432123456789.987654321) rs(real -98765432123456789.987654321) eff_thr(real -98765432123456789.987654321) fr2max_multiplier(real 1.3) fr2max(real 0) alpha(real 0.05) tails(integer 2) indx(str) ]

// replace: 0 = entire //1 = control
// switch_trm: default = True
// test1: 0 = fisher; 1 = chisq

// default function is pkonfound; user can define model type
** 0 = pkonfound
** 1 = test_sensitivity_ln
** 2 = tkonfound

if "`indx'" == "" {
    local indx "RIR"
}

if `model_type'== 0 { 
	dis ""
	
	*changed:: coef >> est_eff, sd >> std_err, N >> n_obs, Ncov >> n_covariates
	local est_eff : word 1 of `anything'
	local std_err : word 2 of `anything'
	local n_obs : word 3 of `anything'
	local n_covariates : word 4 of `anything'
	
	*if ("`indx'" == "COP" | "`indx'" == "PSE") 

	*local sdx : word 5 of `anything'
	*local sdy : word 6 of `anything'
	*local rs : word 7 of `anything'
	
	if ("`indx'" == "COP" | "`indx'" == "PSE") {
		local sdx : word 5 of `anything'
		local sdy : word 6 of `anything'
		local rs : word 7 of `anything'
	}
	
	*define the NA
	local NA = -98765432123456789.987654321
	
	

	
	* JC
	*warning messages for potential confusion
    if (`far_bound' == 1){
		display as error "Warning: far_bound is defined by whether the estimated effect is moved to the" _newline "boundary closer(0) or further away(1)."
		dis ""
	}
    if ((`eff_thr'!=`NA') & (`nu' != 0)) {
        local nu = 0
        display as error "Warning: Cannot test statistical significance from nu and evaluate relative to" _newline "a specific threshold. Using the specified threshold for calculations and ignoring nu."
		dis ""
}

    if ((`eff_thr'!=`NA') & ("`indx'" == "RIR")) {
        display as error "Warning: Interpreting the metric of the threshold in the metric of the estimated" _newline "effect because you specified RIR."
		dis ""
} 

    if ((`eff_thr'!=`NA') & ("`indx'" == "IT")) {
        display as error "Warning: Interpreting the effect threshold as a correlation because you specified ITCV." _newline "Future work will allow for thresholds in raw metric."
		dis ""
} 
    * error message if input is inappropriate
	if (`std_err' <= 0) {
		display as error "Did not run! Standard error needs to be greater than zero."
		error 11111
}

    if (`n_obs' <= `n_covariates'+3) {
		display as error "Did not run! There are too few observations relative to the number of observations and" _newline "covariates. Please specify a less complex model to use KonFound-It."
		error 22222
}

    if ((`sdx'==`NA' | `sdy'==`NA' | `rs'==`NA') & !(`sdx' == `NA' & `sdy' == `NA' & `rs' == `NA')) {
        display as error "Did not run! Info regarding sdx, sdy and R2 are all needed to generate unconditional ITCV."
		error 33333
 }

 * JC

    * calculate critical_t 
    if (`est_eff' < `nu') {
		local critical_t = -1 * invttail(`n_obs'-`n_covariates'-2,`sig'/(2 - `onetail'))
    } 
    else {
        local critical_t = invttail(`n_obs'-`n_covariates'-2,`sig'/(2 - `onetail'))
    }

    * create CI centered nu    
    local UPbound = `nu' + abs(`critical_t' * `std_err')
    local LWbound = `nu' - abs(`critical_t' * `std_err')

    * determine beta_threshold
	** if user does not specify eff_thr 
	if (`eff_thr'==`NA') {
		if (`est_eff'< `nu'){
			if (`far_bound'== 1){
				local beta_threshold = `UPbound'
			}
			else if(`far_bound'== 0){
				local beta_threshold = `LWbound'
			}
		}
		else if (`est_eff'>= `nu'){
			if (`far_bound'== 1){
				local beta_threshold = `LWbound'
			}
			else if(`far_bound'== 0){
				local beta_threshold = `UPbound'
			}
		}
	}
	** if user specifies eff_thr
	else if(`eff_thr'!=`NA'){
	 	if (`est_eff'< 0){
			if (`far_bound'== 1){
				local beta_threshold = abs(`eff_thr')
			}
			else if(`far_bound'== 0){
				local beta_threshold = -1 * abs(`eff_thr')
			}
		}
		else if (`est_eff'>= 0){
			if (`far_bound'== 1){
				local beta_threshold = -1 * abs(`eff_thr') 
			}
			else if(`far_bound'== 0){
				local beta_threshold = abs(`eff_thr')
			}
		}
	}
	* added for resolve output error
	local bias = .
	local sustain = .
	
    * I. for RIR
    * calculating percentage of effect and number of observations to sustain or invalidate inference
	local perc_to_change = -999
	local recase = -999
    
	if (abs(`est_eff') > abs(`beta_threshold')){
        local perc_to_change = 100 * (1 - (`beta_threshold' / `est_eff'))
	    local bias = 100 * (1 - (`beta_threshold' / `est_eff'))
        local recase = round(`n_obs' * (`bias' / 100))
    } 
    else if (abs(`est_eff') < abs(`beta_threshold')){
        local perc_to_change = 100 * (1 - (`est_eff' / `beta_threshold'))
	    local sustain = 100 * (1 - (`est_eff' / `beta_threshold'))
        local recase = round(`n_obs' * (`sustain' / 100))
    } 


    if ((`est_eff' == `beta_threshold')&("`indx'" == "RIR")){
        display as error "The estimated effect equals the threshold value. Therefore no omitted variable" _newline "is needed to make them equal."
		error 44444
    }
	
	if ((`est_eff' * `beta_threshold' < 0) & ("`indx'" == "RIR")) {
        display as error "The condition you specified implies a threshold of" string(round(`beta_threshold', 0.001)) ". Cannot calculate RIR" _newline "because replacement values would need to be arbitrarily more extreme than the threshold" _newline string(round(`beta_threshold', 0.001)) " to achieve the threshold value. Consider using ITCV."
		error 55555
    }
	
	if ((`beta_threshold' == 0) & ("`indx'" == "RIR")) {
        display as error "The condition you specified implies a threshold of 0. Therefore, 100% of the" _newline "data points would have to be replaced with data points with an effect of 0 to" _newline "reduce the estimate to 0. If you would like to use a threshold based on statistical" _newline "significance for a null hypothesis of 0 then do not specify an eff_thr value" _newline "but instead specify nu value."
		error 66666
    }
	if ((`est_eff' == 0) & ("`indx'" == "RIR")) {
        display as error "The estimated effect is 0. Cannot modify the effect by replacing it with cases" _newline "for which the effect is also 0."
		error 77777
    }

	* verify results 
    if ((`est_eff' * `beta_threshold' < 0) & ("`indx'" == "IT")) {
		local perc_to_change = 101 
		local recase = `n_obs' + 1
		* solution for expl
	}
    
    if (abs(`est_eff') > abs(`beta_threshold')) {
        local beta_threshold_verify = `perc_to_change' / 100 * 0 + (1 - `perc_to_change' / 100) * `est_eff'
    } 
    if (abs(`est_eff') < abs(`beta_threshold')) {
        local beta_threshold_verify = `est_eff' / (1 - `perc_to_change' / 100)
    }
    
		
    * II. for correlation-based approach
  
    * transforming t into obs_r
    local obs_r = (`est_eff' / `std_err') / sqrt((`n_obs'-`n_covariates' - 2) + (`est_eff' / `std_err')^2)
  
    * finding critical r
    if (`eff_thr'==`NA'){
        local critical_r = `critical_t' / sqrt((`critical_t')^2 + (`n_obs'-`n_covariates' - 2))
		if (`far_bound' == 1){
			local critical_r = `critical_r' * (-1)
		}
    } 
    else if (`eff_thr'!=`NA') {
        local critical_r = `eff_thr'
    } 
	
	if ((abs(`critical_r') > 1) & ("`indx'" == "IT")) {
        display as error "Effect threshold for ITCV is interpreted as a correlation. You entered a value" _newline "that is greater than 1 in absolute value. Please convert your threshold to a" _newline "correlation by multiplying by sdx/sdy. This will be addressed in future versions."
		error 88888
    } 

    * calculating actual t and r (to account for non-zero nu)
    local act_t = (`est_eff' - `nu')/`std_err'
    local act_r = `act_t' / sqrt((`act_t')^2 + `n_obs' - `n_covariates' - 2)
	
	 * determine mp
	if (`eff_thr'==`NA'){
		if ((`est_eff' > `LWbound')&(`est_eff' < `UPbound')) {
			local mp = 1
		}
        else if ((`est_eff' < `LWbound')|(`est_eff' > `UPbound')) {
  	        local mp = -1
	    }
	}
	else if (`eff_thr'!=`NA'){
		if (abs(`act_r') < abs(`eff_thr')){
			local mp = 1
		}
		else if (abs(`act_r') > abs(`eff_thr')){
			local mp = -1
		}
	}
	
	if (`far_bound' == 1){
		local mp = 1
	}
    
	if ((`eff_thr'!=`NA') & (abs(`act_r') == abs(`eff_thr')) & ("`indx'" == "IT")) {
		display as error "The estimated effect equals the threshold value. Therefore no omitted variable" _newline "is needed to make them equal."
		error 99999
    }

	* determine signITCV
	if (`eff_thr'==`NA'){
		if (`est_eff' < `beta_threshold') {
			local signITCV = -1
	    }
        if (`est_eff' > `beta_threshold') {
  	        local signITCV = 1
	    }
        if (`est_eff' == `beta_threshold') {
  	        local signITCV = 0
	    } 		
	}
	else if (`eff_thr'!=`NA'){
		if (`act_r' < `eff_thr') {
			local signITCV = -1
	    }
        if (`act_r' > `eff_thr') {
  	        local signITCV = 1
	    }
        if (`act_r' == `eff_thr') {
  	        local signITCV = 0
	    } 
	}

    * calculating impact of the confounding variable
    local itcv = `signITCV' * abs(`act_r' - `critical_r') / (1 + `mp' * abs(`critical_r'))

    * finding correlation of confound to invalidate / sustain inference
    local r_con = sqrt(abs(`itcv'))
	
	* error message if r_con >= 1
    if ((`r_con' >= 1) & ("`indx'" == "IT")) {
		display as error "To achieve the threshold the absolute value of the correlations associated with" _newline "the omitted confounding variable would have to be greater than or equal to one."
		error 00000
    }
	
	* warning message when r_con is larger than 0.999
    if (`r_con' >= 0.9995) {
		display as error "Warning: The correlations associated with the omitted confounding variable neccessary" _newline "to change the inference have an absolute value larger than or equal to 0.9995. Due to" _newline "rounding, print output will show as 1. Check raw_ouput for the specific values." _newline "This is an unusually robust inference. Confirm your input values."
    }
	

    ** calculate the unconditional ITCV if user inputs sdx, sdy and R2
    *pull in the auxiliary function for R2yz and R2xz
	if ((`sdx' != `NA') & (`sdy' != `NA') & (`rs' != `NA') & (`n_covariates' > 0)) {
    	capture noisily cal_ryz `obs_r' `rs'
		if (_rc == 0) {
        	local r2yz = `r(ryz)'^2
			local uncond_rycv = `r_con' * sqrt(1 - `r2yz')
			} 
			else {
				dis ""
				local sdx = .
				local sdy = .
				local rs = .
				local r2yz = .
				local uncond_rycv = .
				}
				capture noisily cal_rxz `sdx'^2 `sdy'^2 `rs' (`n_obs'-`n_covariates'-2) `std_err'
				if (_rc == 0) {
					local r2xz = `r(rxz)'^2
					local uncond_rxcv = `r_con' * sqrt(1 - `r2xz')
					}
					else {
						dis ""
						local sdx = .
						local sdy = .
						local rs = .
						local r2xz = .
						local uncond_rxcv = .
						}
					} 
					else if (`n_covariates' == 0) {
					local r2yz = .
					local r2xz = .
					local uncond_rycv = `r_con'
					local uncond_rxcv = `r_con'
				}
				else {
					local r2yz = .
					local uncond_rycv = .
					local r2xz = .
					local uncond_rxcv = .
					}
					  
    local uncond_rycv = `uncond_rycv' * `signITCV'
    local rycvGz = `r_con' * `signITCV'
	local rxcvGz = `r_con'
	local itcvGz = `itcv'
	
	*verify result
	local act_r_forvf = `act_t' / sqrt(`act_t'^2 + `n_obs' - `n_covariates' - 2)
    local r_final = (`act_r_forvf' - `r_con' * `rycvGz')/sqrt((1 - `r_con'^2) * (1 - `rycvGz'^2))
	*local r_finall = ((`act_t' / sqrt(`act_t'^2 + `N' - `Ncov' - 2))- `r_con'^2 *`signITCV')/sqrt((1 - `r_con'^2) * (1 - `r_con'^2))
	
	local r_finall = ((`act_t' / sqrt(`act_t'*`act_t' + `n_obs' - `n_covariates' - 2))- `itcv')/sqrt((1 - abs(`itcv')) * (1 - abs(`itcv')))
	*return scalar r_finall = `r_finall'
  
    * prepare for display
    local impact_ =  string(`itcv',"%6.3f")
    local r_conn = string(sqrt(abs(`itcv')),"%6.3f")
    local nr_conn = -1 * `r_conn'
	
	* updated 240112 JC0
	if ((`sdx' != `NA') & (`sdy' != `NA') & (`rs' != `NA') & (`n_covariates' > 0)) {
		
		local benchmark_corr_product = `r2xz' * `r2yz' 
		
		local itcv_ratio_to_benchmark = abs((`uncond_rxcv' * `uncond_rycv') / `benchmark_corr_product') 
	}
	*


	
    * III. for test_cop
	if ("`indx'" == "COP"){	
    * define degrees of freedom once to avoid repetition
    local df = `n_obs' - `n_covariates' - 3
    local var_x = `sdx'^2
    local var_y = `sdy'^2
	local var_z = 1
	local var_cv = 1
    local sdz = 1
	local sdcv = 1
	local rcvz = 0
	local rzcv = 0
	//return scalar df = `df'
	//return scalar var_x = `var_x'
	//return scalar var_y = `var_y'
	//return scalar var_z = `var_z'
	//return scalar var_cv = `var_cv'
	//return scalar sdz = `sdz'
	//return scalar sdcv = `sdcv'
	//return scalar rcvz = `rcvz'
	//return scalar rzcv = `rzcv'
	
    * check if R2max is specified, if not use multiplier
    if (`fr2max' == 0) {
        local fr2max = `fr2max_multiplier' * `rs'
        di "note: R2max was not specified, using FR2max_multiplier * R2."
    }
	
    * input validation
    if (`std_err' <= 0) {
        di "did not run! standard error needs to be greater than zero."
        error 198
    }
    if (`sdx' <= 0) {
        di "did not run! standard deviation of x needs to be greater than zero."
        error 198
    }
    if (`sdy' <= 0) {
        di "did not run! standard deviation of y needs to be greater than zero."
        error 198
    }
    if (`n_obs' <= `n_covariates' + 3) {
        di "did not run! there are too few observations relative to the number of observations and covariates. please specify a less complex model to use konfound-it."
        error 198
    }
    if (`rs' >= `fr2max') {
        di "did not run! r2 max needs to be greater than r2."
        error 198
    }

    if (`fr2max' >= 1) {
        di "did not run! r2 max needs to be less than 1."
        error 198
    }

    * additional input validation to ensure rxz^2 > 0
    local crit_value = 1-((`sdy'^2/`sdx'^2)*(1-`rs')/((`df'+1) * `std_err'^2))
    if (`crit_value' <= 0) {
        di "did not run! entered values produced rxz^2 <=0, consider adding more significant digits to your entered values."
        error 198
    }

    * check for negative estimated effect and adjust
    local negest = 0
    if (`est_eff' < 0) {
        local est_eff = abs(`est_eff')
        local negest = 1
        di "Note: using the absolute value of the estimated effect. negativity was adjusted."
    }

	//return scalar negest = `negest'
	//return scalar crit_value = `crit_value'
	//return scalar est_eff = `est_eff'
	
	* standardizing coefficients

	local beta_thr = `eff_thr' * `sdx' / `sdy'
	local beta = `est_eff' * `sdx' / `sdy'
	local se = `std_err' * `sdx' / `sdy'

	* calculate observed regression coefficients
	local tyxgz = `beta' / `se'
	local ryxgz = `tyxgz' / sqrt(`df' + 1 + `tyxgz'^2)

	* calculate ryxgz for model 2, not including the omitted variable
	local ryxgz_m2 = `tyxgz' / sqrt(`n_obs' + `tyxgz'^2)

	//return scalar beta_thr = `beta_thr'
	//return scalar beta = `beta'
	//return scalar se = `se'
	//return scalar tyxgz = `tyxgz'
	//return scalar ryxgz = `ryxgz'
	//return scalar ryxgz_m2 = `ryxgz_m2'
	
	* condition check for r2 due to x alone not being larger than overall or observed r2
	local illcond_ryxgz = cond(`ryxgz'^2 > `rs', 1, 0)
	//return scalar illcond_ryxgz = `illcond_ryxgz'

	* integrate auxiliary functions for calculating ryz, rxz, rxy
	* calculate ryz using cal_ryz
	quietly cal_ryz `ryxgz' `rs'
	local ryz = `r(ryz)'
	local rzy = `r(ryz)'

	//return scalar ryz = `r(ryz)'
	//return scalar rzy = `r(ryz)'

	* call cal_rxz and capture its result
	local df_one = `df' + 1
	cal_rxz `var_x' `var_y' `rs' `df_one' `std_err' 
	local rxz = `r(rxz)'

	* call cal_rxy and capture its result for the main model
	quietly cal_rxy `ryxgz' `rxz' `ryz'
	local rxy = `r(rxy)'
	//return scalar rxy = `r(rxy)'

	* rzy ryx and rzx are the same as ryz rxy and rxz respectively, due to symmetry in correlation
	local rzy = `ryz'
	local rzx = `rxz'
	local ryx = `rxy'
	//return scalar rzy = `rzy'
	//return scalar rzx = `rzx'
	//return scalar ryx = `ryx'

	* calculate rxy for model 2, simulating to recover the exact number
	quietly cal_rxy `ryxgz_m2' `rxz' `ryz'
	local rxy_m2 = `r(rxy)'
	//return scalar rxy_m2 = `r(rxy)'

	* baseline regression model, no z (unconditional)
	local eff_uncond = sqrt(`var_y' / `var_x') * `rxy'
	local t_uncond = `rxy' * sqrt(`n_obs' - 2)/sqrt(1 - `rxy'^2)

	* adjust the degrees of freedom (df) in the model 1 (m1) as n_obs - 2
	local std_err_uncond = `eff_uncond' / `t_uncond'
	local r2_uncond = `rxy'^2
	*display "fr2max= "`fr2max'
	*display "r2= "`rs'

	//return scalar eff_uncond = `eff_uncond'
	//return scalar t_uncond = `t_uncond'
	//return scalar r2_uncond = `r2_uncond'

	//return scalar sdz = `sdz'
	//return scalar sdcv = `sdcv'
	//return scalar rxz = `rxz'

	quietly cal_delta_star `fr2max' `rs' `r2_uncond' `est_eff' `eff_thr' `var_x' `var_y' `eff_uncond' `rxz' `n_obs'
	local delta_star = `r(delta_star)'
	//return scalar delta_star = `r(delta_star)'
	*display "delta_star = "`r(delta_star)'

	* calculate rxcv & rycv implied by oster from delta_star (assuming rcvz=0)
	local v = 1 - `rxz'^2
	local d = sqrt(`fr2max' - `rs')
	
	* updated 053024
	local rcvx_oster = `delta_star' * `rxz' * (`sdcv' / `sdz') * sqrt(1 - `rxz'^2)
	local rxcv_oster = `rcvx_oster'

	if (abs(`rcvx_oster') < 1 & (`rcvx_oster'^2/`v') < 1) {
		local rcvy_oster = `d' * sqrt(1 - (`rcvx_oster'^2 / `v')) + (`ryx' * `rcvx_oster') / `v' - (`ryz' * `rcvx_oster' * `rxz') / `v'
	}
	local rycv_oster = `rcvy_oster'

	quietly verify_reg_gzcv `n_obs' `sdx' `sdy' `sdz' `sdcv' `rxy' `rxz' `rzy' `rycv_oster' `rxcv_oster' `rcvz'
	local r2_m3_oster = `r(r2)'
	local eff_x_m3_oster = `r(betax)'
	local se_x_m3_oster = `r(sex)'
	local beta_x_m3_oster = `r(betaxr)' 
	local t_x_m3_oster = `eff_x_m3_oster' / `se_x_m3_oster'
	local eff_z_m3_oster = `r(betaz)'
	local se_z_m3_oster = `r(sez)'
	local eff_cv_m3_oster = `r(betacv)'
	local se_cv_m3_oster = `r(secv)'

	* return matrix
	matrix cov_oster = r(covmatrix)
	matrix cor_oster = r(cormatrix)
	
	* exact/true calculations
	local sdxgz = `sdx' * sqrt(1 - `rxz'^2)
	local sdygz = `sdy' * sqrt(1 - `ryz'^2)
	local ryxcvgz_exact_sq = (`fr2max' - `ryz'^2) / (1 - `ryz'^2)
	local rxcvgz_exact = (`ryxgz' - `sdxgz' / `sdygz' * `beta_thr') / sqrt((`sdxgz'^2) / (`sdygz'^2) * (`beta_thr'^2) -  2 * `ryxgz' * `sdxgz' / `sdygz' * `beta_thr' + `ryxcvgz_exact_sq')

	local rycvgz_exact = `ryxgz' * `rxcvgz_exact' + sqrt((`ryxcvgz_exact_sq' - `ryxgz'^2) * (1 - `rxcvgz_exact'^2))

	* calculate unconditional exact rxcv and rycv
	local rycv_exact = sqrt(1 - `ryz'^2) * `rycvgz_exact'
	local rxcv_exact = sqrt(1 - `rxz'^2) * `rxcvgz_exact'

	* calculate delta_exact
	local delta_exact = `rxcv_exact' / `rxz'

	* calculate % bias in delta comparing oster's delta_star with true delta
	local delta_pctbias = 100 * (`delta_star' - `delta_exact') / `delta_exact'

	//return scalar sdxgz = `sdxgz'
	//return scalar sdygz = `sdygz'
	//return scalar ryxcvgz_exact_sq = `ryxcvgz_exact_sq'
	//return scalar rxcvgz_exact = `rxcvgz_exact'
	//return scalar rycvgz_exact = `rycvgz_exact'
	//return scalar rycv_exact = `rycv_exact'
	//return scalar rxcv_exactt = `rxcv_exact'
	//return scalar delta_exact = `delta_exact'

	quietly cal_max_rcvz `fr2max' `est_eff' `sdx' `sdy' `std_err' `df' `eff_thr' `var_x' `var_y' `rs' `rxz'
	local max_rcvz = `r(max_rcvz)'

	* calculate critical t based on the sign of the estimated effect
	local alpha_tails = `alpha' / `tails'
	if (`est_eff' < 0) {
    local critical_t = invttail(`n_obs' - `n_covariates' - 2, `alpha_tails') * -1
	} 
	else {
		local critical_t = invttail(`n_obs' - `n_covariates' - 2, `alpha_tails')
	}

	* calculate critical r
	local critical_r = `critical_t' / sqrt((`critical_t'^2) + (`n_obs' - `n_covariates' - 2))

	* final solutions for conditional rir
	local cond_rirpi_fixedy = (`rs' - `ryz'^2 + `ryz'^2 * `critical_r'^2 - `critical_r'^2) / ///
							  (`rs' - `ryz'^2 + `ryz'^2 * `critical_r'^2)

	local cond_rir_fixedy = `cond_rirpi_fixedy' * `n_obs'

	local cond_rirpi_null = 1 - sqrt(`critical_r'^2 / ///
							(`rs' - `ryz'^2 + `ryz'^2 * `critical_r'^2))

	local cond_rir_null = `cond_rirpi_null' * `n_obs'

	local cond_rirpi_rxyz = 1 - sqrt((`critical_r'^2 * (1 - `ryz'^2)) / ///
									(`rs' - `ryz'^2))
	local cond_rir_rxyz = `cond_rirpi_rxyz' * `n_obs'

	//return scalar alpha_tails = `alpha_tails'
	//return scalar critical_t = `critical_t'
	//return scalar critical_r = `critical_r'
	//return scalar cond_rirpi_fixedy = `cond_rirpi_fixedy'
	//return scalar cond_rir_fixedy = `cond_rir_fixedy'
	//return scalar cond_rirpi_null = `cond_rirpi_null'
	//return scalar cond_rir_null = `cond_rir_null'
	//return scalar cond_rirpi_rxyz = `cond_rirpi_rxyz'
	//return scalar cond_rir_rxyz = `cond_rir_rxyz'


	*verify_reg_gzcv is a previously defined program that returns a list of results
	quietly verify_reg_gzcv `n_obs' `sdx' `sdy' `sdz' `sdcv' `rxy' `rxz' `rzy' `rycv_exact' `rxcv_exact' `rcvz'

	local r2_m3 = `r(r2)'
	local eff_x_m3 = `r(betax)'
	local se_x_m3 = `r(sex)'
	local beta_x_m3 = `r(betaxr)' 
	local t_x_m3 = `eff_x_m3' / `se_x_m3'
	local eff_z_m3 = `r(betaz)'
	local se_z_m3 = `r(sez)'
	local eff_cv_m3 = `r(betacv)'
	local se_cv_m3 = `r(secv)'


	* return matrix
	*matrix cov_exact = r(matrixcov)
	*matrix cor_exact = r(matrixcor)
	matrix cov_exact = r(covmatrix)
	matrix cor_exact = r(cormatrix)
	*matrix cormatrix = r(cormatrix)
	
	*cal exact

	local sdxgz = `sdx' * sqrt(1 - `rxz'^2)
	local sdygz = `sdy' * sqrt(1 - `ryz'^2)
	local ryxcvgz_exact_sq = (`fr2max' - `ryz'^2) / (1 - `ryz'^2)
	local rxcvgz_exact = (`ryxgz' - `sdxgz' / `sdygz' * `beta_thr') / ///
		sqrt((`sdxgz'^2) / (`sdygz'^2) * (`beta_thr'^2) - ///
		2 * `ryxgz' * `sdxgz' / `sdygz' * `beta_thr' + ///
		`ryxcvgz_exact_sq')
	local rycvgz_exact =  `ryxgz' * `rxcvgz_exact' + ///
		sqrt((`ryxcvgz_exact_sq' - `ryxgz'^2) * ///
		(1 - `rxcvgz_exact'^2))
	local rycv_exact = sqrt(1 - `ryz'^2) * `rycvgz_exact'
	local rxcv_exact = sqrt(1 - `rxz'^2) * `rxcvgz_exact'
	local delta_exact = `rxcv_exact' / `rxz'

	* cal verify_reg_gzcv to get delta score
	quietly verify_reg_gzcv `n_obs' `sdx' `sdy' `sdz' `sdcv' `rxy' `rxz' `rzy' `rycv_exact' `rxcv_exact' `rcvz'

	quietly verify_reg_gz `n_obs' `sdx' `sdy' `sdz' `rxy_m2' `rxz' `rzy'

	* handle output for model m2
	local r2_m2 = `r(r2_gz)'
	local eff_x_m2 = `r(betax_gz)'
	local se_x_m2 = `r(sex_gz)'
	local t_x_m2 = `eff_x_m2' / `se_x_m2'

	* verify regression for m1 (unconditional model)
	quietly verify_reg_uncond `n_obs' `sdx' `sdy' `rxy'

	* handle output for model m1
	local r2_m1 = `r(r2_uncond)'
	local eff_x_m1 = `r(betax_uncond)'
	local se_x_m1 = `r(sex_uncond)'
	local t_x_m1 = `eff_x_m1' / `se_x_m1'

	* calculate delta_star_restricted
	local delta_star_restricted = ((`est_eff' - `eff_thr')/(`eff_x_m1' - `est_eff')) * ((`r2_m2' - `r2_m1')/(`r2_m3' - `r2_m2'))

	* constructing the final table matrix
	matrix ftable = (`r2_m1', `r2_m2', `r2_m3', `r2_m3_oster' \ ///
					`eff_x_m1', `eff_x_m2', `eff_x_m3', `eff_x_m3_oster' \ ///
					`se_x_m1', `se_x_m2', `se_x_m3', `se_x_m3_oster' \ ///
					`rxy', `ryxgz', `beta_x_m3', `beta_x_m3_oster' \ ///
					`t_x_m1', `t_x_m2', `t_x_m3', `t_x_m3_oster' \ ///
					., ., `eff_cv_m3', `eff_cv_m3_oster' \ ///
					., ., `se_cv_m3', `se_cv_m3_oster' \ ///
					., ., `eff_cv_m3' / `se_cv_m3', `eff_cv_m3_oster' / `se_cv_m3_oster')

	matrix rownames ftable = "r2" "coef_x" "se_x" "std_coef_x" "t_x" "coef_cv" "se_cv" "t_cv"
	matrix colnames ftable = "m1:x" "m2:x,z" "m3(delta_exact):x,z,cv" "m3(delta*):x,z,cv"
	if _N < 5{
		quietly set obs 5
	}

	quietly capture confirm variable modellabel

	quietly if _rc != 0 {
		gen modellabel = ""
	}

	quietly replace modellabel = "Baseline(m1)" in 1
	quietly replace modellabel = "Final(m3)" in 2
	quietly replace modellabel = "Intermediate(m2)" in 3
	quietly replace modellabel = "Final(m3)" in 4
	quietly replace modellabel = "Intermediate(m2)" in 5

	quietly capture confirm variable cat
	quietly if _rc != 0 {
		gen cat = ""
	}
	quietly replace cat = "exact" in 1/3
	quietly replace cat = "star" in 4/5

	quietly capture confirm variable coef_x
	quietly if _rc != 0 {
		gen coef_x = .
	}

	quietly replace coef_x = `eff_x_m1' in 1 
	quietly replace coef_x = `eff_x_m2' in 2
	quietly replace coef_x = `eff_x_m3' in 3
	quietly replace coef_x = `eff_x_m2' in 4
	quietly replace coef_x = `eff_x_m3_oster' in 5

	quietly capture confirm variable r2r
	quietly if _rc != 0 {
		gen r2r = .
	}

	quietly replace r2r = `r2_m1' in 1
	quietly replace r2r = `rs' in 2 
	quietly replace r2r = `fr2max' in 3
	quietly replace r2r = `rs' in 4
	quietly replace r2r = `fr2max' in 5

	quietly summarize coef_x, detail
	local maxCoefX = r(max)
	local scale = 1 / (round(`maxCoefX' * 10) / 10)

	quietly capture confirm variable r2r
	quietly if _rc != 0 {
		gen r2r = .
	}

	* check if modellabelNum already exist
	capture confirm variable modellabelNum

	if _rc == 0 {
		drop modellabelNum
	}

	* create modellabel
	encode modellabel, generate(modellabelNum)

	local max_r2_scaled = `maxCoefX' * `scale'
	quietly levelsof modellabel, local(levels)
	local m1index = strpos("`levels'", "Baseline(m1)")
	local m2index = strpos("`levels'", "Final(m3)")
	local m3index = strpos("`levels'", "Intermediate(m2)")


	capture confirm variable shape
	if _rc == 0 {
		drop shape
	}

	* encode
	encode cat, gen(shape)

	* check if ltype already exist
	capture confirm variable ltype
	if _rc == 0 {
		drop ltype
	}

	*create ltype
	quietly gen ltype = "solid" if cat == "exact"
	quietly replace ltype = "dotted" if cat == "star"

	* graphing finally!
 
	twoway (scatter coef_x modellabelNum if cat == "exact", mcolor(blue) msymbol(O)) ///
		   (scatter coef_x modellabelNum if cat == "star", mcolor(blue) msymbol(T)) ///
           (line coef_x modellabelNum if cat == "exact", lcolor(blue)) ///
           (line coef_x modellabelNum if cat == "star", lcolor(blue) lpattern(dash)) ///
           (scatter r2r modellabelNum if cat == "exact", mcolor(green) msymbol(S) yaxis(2)) ///
           (line r2r modellabelNum if cat == "exact", lcolor(green) yaxis(2)), ///
	       yscale(axis(1)) ///
           yscale(axis(2) range(0 `max_r2_scaled')) ///
           ytitle("Coefficient (X)", axis(1)) ///
	       ytitle("Scaled R2", axis(2)) ///
           xtitle("Model Label") ///
           xlabel(1 "Baseline(M1)" 2 "Intermediate(M2)" 3 "Final(M3)", axis(1)) ///
		   legend(order(1 "Exact coef_x" 2 "Star coef_x" 6 "Exact R2"))
			  
			  }
	
	
    * IV. for test_pse
	if ("`indx'" == "PSE"){ 
    * Check if n_covariates is provided and set default if not:: Default value set to 0
    if ("`n_covariates'" == "") {
        local n_covariates = 1  
    }
		   
    // Prepare input
    local var_x = `sdx'^2
    local var_y = `sdy'^2
    local var_z = 1
    local df = `n_obs' - `n_covariates' - 3

    // Error checking
    if `std_err' <= 0 {
        di "Did not run! Standard error needs to be greater than zero."
        exit 498
    }
    if `sdx' <= 0 {
        di "Did not run! Standard deviation of x needs to be greater than zero."
        exit 498
    }
    if `sdy' <= 0 {
        di "Did not run! Standard deviation of y needs to be greater than zero."
        exit 498
    }
    if `n_obs' <= `n_covariates' + 3 { 
        di "Did not run! There are too few observations relative to the number of observations and covariates. Please specify a less complex model to use KonFound-It."
        exit 498
    }
    if `rs' <= 0 | `rs' >= 1 {
        di "Did not run! R2 needs to be between 0 and 1."
        exit 498
    }
    local Rxz2 = 1 - ((`var_y'/`var_x')*(1-`rs')/((`df'+1) * `std_err'^2))
    if `Rxz2' <= 0 {
        di "Did not run! Entered values produced Rxz^2 <= 0, consider adding more significant digits to your entered values."
        exit 498
    }

	// Standardization and calculations
    local beta_thr = `eff_thr' * `sdx' / `sdy'
    local beta = `est_eff' * `sdx' / `sdy'
    local SE = `std_err' * `sdx' / `sdy'
    local tyxGz = `beta' / `SE'
    local ryxGz = `tyxGz' / sqrt(`df' + `tyxGz'*`tyxGz')

    if (`ryxGz'^2 > `rs') {
        di "Error! ryxGz^2 > R2"
        exit 498
    }

	cal_ryz `ryxGz' `rs'
	local ryz = `r(ryz)'
	local rzy = `r(ryz)'
	
	local df_one = `df' + 1
	
	cal_rxz `var_x' `var_y' `rs' `df_one' `std_err'
	local rxz = `r(rxz)'
	local rzx = `r(rxz)'
	
	cal_rxy `ryxGz' `rxz' `ryz'
	local rxy = `r(rxy)'
	local ryx = `r(rxy)'

	return scalar rxy = `r(rxy)'
	
    local thr = `eff_thr' * `sdx' / `sdy'
    local sdz = 1
	local sdcv = 1
    local rcvz = 0
	local rzcv = 0
	
    // Using cal_pse, defined separately
    quietly cal_pse `thr' `ryxGz'
    local rxcvGz = r(rxcvgz_sepreserve)
    local rycvGz = r(rycvgz_sepreserve)
	
	* Convert conditional correlations to unconditional correlations to be used in new regression
	local rxcv = `rxcvGz' * sqrt((1 - `rcvz'^2) * (1 - `rxz'^2)) + `rxz' * `rcvz'
	local rycv = `rycvGz' * sqrt((1 - `rcvz'^2) * (1 - `rzy'^2)) + `rzy' * `rcvz'

	* Run verify_reg_gzcv with appropriate arguments and capture its outputs
	quietly verify_reg_gzcv `n_obs' `sdx' `sdy' `sdz' `sdcv' `rxy' `rxz' `rzy' `rycv' `rxcv' `rcvz'
	
	* make local matrix for raw_output:: matrix cov_pse = `r(covmatrix)'
	matrix cov_pse = r(covmatrix)
	local R2_M3 = `r(r2)'
	local eff_x_M3 = `r(betax)'
	local se_x_M3 = `r(sex)'
	local beta_x_M3 = `r(betaxr)'
	local t_x_M3 = `eff_x_M3' / `se_x_M3'
	local eff_z_M3 = `r(betaz)'
	local se_z_M3 = `r(sez)'
	local eff_cv_M3 = `r(betacv)'
	local se_cv_M3 = `r(secv)'

	* Run verify_reg_gz with appropriate arguments and capture its outputs
	quietly verify_reg_gz `n_obs' `sdx' `sdy' `sdz' `rxy' `rxz' `rzy'
	local R2_M2 = `r(r2_gz)'
	local eff_x_M2 = `r(betax_gz)'
	local se_x_M2 = `r(sex_gz)'
	local eff_z_M2 = `r(betaz_gz)'
	local se_z_M2 = `r(sez_gz)'
	local t_x_M2 = `eff_x_M2' / `se_x_M2'

	* Run verify_reg_uncond with appropriate arguments and capture its outputs
	quietly verify_reg_uncond `n_obs' `sdx' `sdy' `rxy'
	local R2_M1 = `r(r2_uncond)'
	local eff_x_M1 = `r(betax_uncond)'
	local se_x_M1 = `r(sex_uncond)'
	local t_x_M1 = `eff_x_M1' / `se_x_M1'
	
	* Define the matrix with the necessary values
	matrix fTable = ( ///
		`R2_M1', `R2_M2', `R2_M3' \ ///
		`eff_x_M1', `eff_x_M2', `eff_x_M3' \ ///
		`se_x_M1', `se_x_M2', `se_x_M3' \ ///
		`rxy', `ryxGz', `beta_x_M3' \ ///
		`t_x_M1', `t_x_M2', `t_x_M3' \ ///
		., `eff_z_M2', `eff_z_M3' \ ///
		., `se_z_M2', `se_z_M3' \ ///
		., `eff_z_M2' / `se_z_M2', `eff_z_M3' / `se_z_M3' \ ///
		., ., `eff_cv_M3' \ ///
		., ., `se_cv_M3' \ ///
		., ., `eff_cv_M3' / `se_cv_M3' ///
	)

	* Set row names for the matrix
	matrix rownames fTable = R2 coef_X SE_X std_coef_X t_X coef_Z SE_Z t_Z coef_CV SE_CV t_CV

	* Set column names for the matrix
	matrix colnames fTable = "M1:X" "M2:X,Z" "M3:X,Z,CV"
	
	// mat list fTable	
	}
		
	* Output language part	

	if ("`indx'" == "IT"){ 	
		* output language for ITCV

		dis "Impact Threshold for a Confounding Variable (ITCV):"
		dis ""
	
		if abs(`obs_r') > abs(`critical_r') & `obs_r' > 0 {
			if ((`sdx'!=`NA') & (`sdy'!=`NA') & (`rs'!=`NA') & (`n_covariates' != 0)) {
			dis "Unconditional ITCV:"
			dis ""
			dis "The minimum impact of an omitted variable to nullify the inference for a null hypothesis"
			dis "of an effect of `nu' (nu) is based on a correlation of " string(round(`uncond_rycv', 0.001), "%9.3f") " with the outcome and " string(round(`uncond_rxcv', 0.001), "%9.3f") " with"
			dis "the predictor of interest (BEFORE conditioning on observed covariates; signs are interchangeable"
			dis "if they are different). This is based on a threshold effect of " string(round(`critical_r', 0.001), "%9.3f") " for statistical significance"
			dis "(alpha = " string(round(`sig', 0.001), "%9.3f") ")."
			dis ""
			dis "Correspondingly the UNCONDITIONAL impact of an omitted variable (as defined in Frank 2000) must be"
			dis string(round(`uncond_rxcv', 0.001), "%9.3f") " X " string(round(`uncond_rycv', 0.001), "%9.3f") " = " string(round(`uncond_rxcv' * `uncond_rycv', 0.001), "%9.3f") " to nullify the inference for a null hypothesis of an effect of `nu' (nu)."
			dis ""
			dis "Conditional ITCV:"
			dis ""
			}
			
			dis "The minimum impact of an omitted variable to nullify the inference for a null hypothesis"
			dis "of an effect of `nu' (nu) is based on a correlation of " string(round(`rycvGz', 0.001), "%9.3f") " with the outcome and " string(round(`rxcvGz', 0.001), "%9.3f") " with"
			dis "the predictor of interest (conditioning on all observed covariates in the model; signs are"
			dis "interchangeable if they are different). This is based on a threshold effect of " string(round(`critical_r', 0.001), "%9.3f") " for"
			dis "statistical significance (alpha = " string(round(`sig', 0.001), "%9.3f") ")."
			dis ""
			dis "Correspondingly the impact of an omitted variable (as defined in Frank 2000) must be"
			dis string(round(`rycvGz', 0.001), "%9.3f") " X " string(round(`rxcvGz', 0.001), "%9.3f") " = " string(round(`rycvGz'*`rxcvGz', 0.001), "%9.3f") " to nullify the inference for a null hypothesis of an effect of `nu' (nu)."
    
    } 
	else if abs(`obs_r') > abs(`critical_r') & `obs_r' < 0 {
		if ((`sdx'!=`NA') & (`sdy'!=`NA') & (`rs'!=`NA') & (`n_covariates' != 0)) {

			dis "Unconditional ITCV:"
			dis ""
			dis "The minimum (in absolute value) impact of an omitted variable to nullify the inference"
			dis "for a null hypothesis of an effect of `nu' (nu) is based on a correlation of " string(round(`uncond_rycv', 0.001), "%9.3f") " with the"
			dis "outcome and " string(round(`uncond_rxcv', 0.001), "%9.3f") " with the predictor of interest (BEFORE conditioning on observed covariates;"
			dis "signs are interchangeable if they are different). This is based on a threshold effect of " string(round(`critical_r', 0.001), "%9.3f")
			dis "for statistical significance (alpha = " string(round(`sig', 0.001), "%9.3f") ")."
			dis ""
			dis "Correspondingly the UNCONDITIONAL impact of an omitted variable (as defined in Frank 2000) must be"
			dis string(round(`uncond_rxcv', 0.001), "%9.3f") " X " string(round(`uncond_rycv', 0.001), "%9.3f") " = " string(round(`uncond_rxcv' * `uncond_rycv', 0.001), "%9.3f") " to nullify the inference for a null hypothesis of an effect of `nu' (nu)."
			dis ""
			dis "Conditional ITCV:"
			dis ""
			}
		
        dis "The minimum (in absolute value) impact of an omitted variable to nullify the inference"
		dis "for a null hypothesis of an effect of `nu' (nu) is based on a correlation of " string(round(`rycvGz', 0.001), "%9.3f") " with the"
		dis "outcome and " string(round(`rxcvGz', 0.001), "%9.3f") " with the predictor of interest (conditioning on all observed covariates"
		dis "in the model; signs are interchangeable if they are different). This is based on a threshold"
		dis "effect of " string(round(`critical_r', 0.001), "%9.3f") " for statistical significance (alpha = " string(round(`sig', 0.001), "%9.3f") ")."
		dis ""
		dis "Correspondingly the impact of an omitted variable (as defined in Frank 2000) must be"
		dis string(round(`rycvGz', 0.001), "%9.3f") " X " string(round(`rxcvGz', 0.001), "%9.3f") " = " string(round(`rycvGz'*`rxcvGz', 0.001), "%9.3f") " to nullify the inference for a null hypothesis of an effect of `nu' (nu)."
    
    } 
	else if abs(`obs_r') < abs(`critical_r') & `obs_r' >= 0 {
		if ((`sdx'!=`NA') & (`sdy'!=`NA') & (`rs'!=`NA') & (`n_covariates' != 0)) {
			
			dis "Unconditional ITCV:"
			dis ""
			dis "The maximum impact (in absolute value) of an omitted variable to sustain an inference"
			dis "for a null hypothesis of an effect of `nu' (nu) is based on a correlation of " string(round(`uncond_rycv', 0.001), "%9.3f")
			dis "with the outcome and " string(round(`uncond_rxcv', 0.001), "%9.3f") " with the predictor of interest (BEFORE conditioning on"
			dis "observed covariates; signs are interchangeable if they are different). This is based"
			dis "on a threshold effect of " string(round(`critical_r', 0.001), "%9.3f") " for statistical significance (alpha = " string(round(`sig', 0.001), "%9.3f") ")."
			dis ""
			dis "Correspondingly the UNCONDITIONAL impact of an omitted variable (as defined in Frank 2000) must be"
			dis string(round(`uncond_rxcv', 0.001), "%9.3f") " X " string(round(`uncond_rycv', 0.001), "%9.3f") " = " string(round(`uncond_rxcv' * `uncond_rycv', 0.001), "%9.3f") " to sustain an inference for a null hypothesis of an effect of `nu' (nu)."
			dis ""
			dis "Conditional ITCV:"
			dis ""
			}
			
        dis "The maximum impact (in absolute value) of an omitted variable to sustain an inference"
		dis "for a null hypothesis of an effect of `nu' (nu) is based on a correlation of " string(round(`rycvGz', 0.001), "%9.3f") " with"
		dis "the outcome and " string(round(`rxcvGz', 0.001), "%9.3f") " with the predictor of interest (conditioning on all observed"
		dis "covariates in the model; signs are interchangeable if they are different). This is"
		dis "based on a threshold effect of " string(round(`beta_threshold', 0.001), "%9.3f") " for statistical significance (alpha = " string(round(`sig', 0.001), "%9.3f") ")."
		dis ""
		dis "Correspondingly the impact of an omitted variable (as defined in Frank 2000) must be"
		dis string(round(`rycvGz', 0.001), "%9.3f") " X " string(round(`rxcvGz', 0.001), "%9.3f") " = " string(round(`rycvGz'*`rxcvGz', 0.001), "%9.3f") " to sustain an inference for a null hypothesis of an effect of `nu' (nu)."
    
    } 
	else if abs(`obs_r') < abs(`critical_r') & `obs_r' < 0 {
		
    	if ((`sdx'!=`NA') & (`sdy'!=`NA') & (`rs'!=`NA') & (`n_covariates' != 0)) {

			dis "Unconditional ITCV:"
			dis ""
			dis "The maximum impact of an omitted variable to sustain an inference for a null hypothesis"
			dis "of an effect of `nu' (nu) is based on a correlation of " string(round(`uncond_rycv', 0.001), "%9.3f") " with the outcome and " string(round(`uncond_rxcv', 0.001), "%9.3f") " with"
			dis "the predictor of interest (BEFORE conditioning on observed covariates; signs are interchangeable"
			dis "if they are different). This is based on a threshold effect of " string(round(`critical_r', 0.001), "%9.3f") " for statistical significance"
			dis "(alpha = " string(round(`sig', 0.001), "%9.3f") ")."
			dis ""
			dis "Correspondingly the UNCONDITIONAL impact of an omitted variable (as defined in Frank 2000) must be"
			dis string(round(`uncond_rxcv', 0.001), "%9.3f") " X " string(round(`uncond_rycv', 0.001), "%9.3f") " = " string(round(`uncond_rxcv' * `uncond_rycv', 0.001), "%9.3f") " to sustain an inference for a null hypothesis of an effect of `nu' (nu)."
			dis ""
			dis "Conditional ITCV:"
			dis ""
			}
			
		dis "The maximum impact of an omitted variable to sustain an inference for a null hypothesis"
		dis "of an effect of `nu' (nu) is based on a correlation of " string(round(`rycvGz', 0.001), "%9.3f") " with the outcome and " string(round(`rxcvGz', 0.001), "%9.3f") " with"
		dis "the predictor of interest (conditioning on all observed covariates in the model; signs are"
		dis "interchangeable if they are different). This is based on a threshold effect of " string(round(`beta_threshold', 0.001), "%9.3f") " for"
		dis "statistical significance (alpha = " string(round(`sig', 0.001), "%9.3f") ")."
		dis ""
		dis "Correspondingly the impact of an omitted variable (as defined in Frank 2000) must be"
		dis string(round(`rycvGz', 0.001), "%9.3f") " X " string(round(`rxcvGz', 0.001), "%9.3f") " = " string(round(`rycvGz'*`rxcvGz', 0.001), "%9.3f") " to sustain an inference for a null hypothesis of an effect of `nu' (nu)."
    
    } 
	else if `obs_r' == `critical_r' {
        di as error "The correlation is exactly equal to the threshold."
    }
	
		dis ""
		if ((`sdx'==`NA') & (`sdy'==`NA') & (`rs'==`NA')) {    		
			dis "For calculation of unconditional ITCV, include the rs (for R2), sdx and sdy as input" _newline "and include 'return list' following the pkonfound command."
			dis ""
			}

		if ((`sdx'!=`NA') & (`sdy'!=`NA') & (`rs'!=`NA') & (`n_covariates' == 0)){
			dis "sdx and sdy and R2 are only used to calculate the unconditional ITCV when there are" _newline "covariates included (number of covariates > 0)."
			dis ""
		}
		
		if ((`sdx'!=`NA') & (`sdy'!=`NA') & (`rs'!=`NA') & (`n_covariates' != 0)) {
			dis "Interpretation of Benchmark Correlations for ITCV:"
			dis ""
			dis "Benchmark correlation product ('benchmark_corr_product') is Rxz * Ryz = " string(round(`benchmark_corr_product', 0.001), "%9.3f") ", showing"
			dis "the association strength of all observed covariates Z with X and Y."
			dis ""
			dis "The ratio ('itcv_ratio_to_benchmark') is unconditional ITCV/Benchmark = " string(abs(round(`uncond_rxcv' * `uncond_rycv', 0.001)), "%9.3f") "/" string(round(`benchmark_corr_product', 0.001), "%9.3f") " = " string(round(`itcv_ratio_to_benchmark', 0.001), "%9.3f") ","
			dis "indicating the robustness of inference."
			dis ""
			dis "A larger the ratio the stronger must be the unobserved impact relative to the"
			dis "impact of all observed covariates to nullify the inference. The larger the ratio"
			dis "the more robust the inference."
			dis ""
			dis "If Z includes pretests or fixed effects, the benchmark may be inflated, making the ratio"
			dis "unusually small. Interpret robustness cautiously in such cases."
			dis ""
		}

			
		dis "See Frank. (2000) for a description of the method."
		dis ""
		dis "Citation:"
		dis "Frank, K. (2000). Impact of a confounding variable on the inference of a"
		dis "regression coefficient. Sociological Methods and Research, 29 (2), 147-194"
		dis ""
		dis "Accuracy of results increases with the number of decimals reported."
		dis ""
		dis "The ITCV analysis was originally derived for OLS standard errors. If the standard errors" _newline "reported in the table were not based on OLS, some caution should be used to interpret the ITCV."
		
	}
	else if ("`indx'" == "RIR") {
		* output language for RIR
		
    dis "Robustness of Inference to Replacement (RIR):"
    dis ""
	dis "RIR = `recase'"
	dis ""
	
    if (abs(`est_eff') > abs(`beta_threshold') & `eff_thr' == `NA') {

        dis "To nullify the inference of an effect using the threshold of " string(round(`beta_threshold', 0.001), "%9.3f") " for"
        dis "statistical significance (with null hypothesis = `nu' and alpha = `sig'), " string(round(`bias', 0.001), "%9.3f") "%"
        dis "of the (`est_eff') estimate would have to be due to bias. This implies that to"
        dis "nullify the inference one would expect to have to replace `recase' (" string(round(`bias', 0.001), "%9.3f") "%)"
        dis "observations with data points for which the effect is `nu' (RIR = `recase')."
        dis ""
        
    } 
	else if (abs(`est_eff') > abs(`beta_threshold') & `eff_thr' != `NA') {

        if (`far_bound' == 0 & `est_eff' * `eff_thr' < 0) {
            dis "Sign for effect threshold changed to be that of estimated effect. The threshold"
            dis "is now " string(round(`beta_threshold', 0.001), "%9.3f") ". Different signs would require replacement values to be arbitrarily"
            dis "more extreme than the threshold (`eff_thr') to achieve the threshold value."
            dis "Consider using ITCV."
            dis ""
        }
        dis "The estimated effect is `est_eff', and specified threshold for inference is `eff_thr'."
        if (`far_bound' == 0 & `est_eff' * `eff_thr' < 0) {
            dis "The threshold used takes the same sign as the estimated effect. See comment above."
            dis ""
        }
        dis "To nullify the inference based on your estimate, " string(round(`bias', 0.001), "%9.3f") "% of the (`est_eff')"
        dis "estimate would have to be due to bias. This implies that to nullify"
        dis "the inference one would expect to have to replace `recase' (" string(round(`bias', 0.001), "%9.3f") "%) observations"
        dis "with data points for which the effect is `nu' (RIR = `recase')."
        dis ""
        
    } 
	else if (abs(`est_eff') < abs(`beta_threshold') & `eff_thr' == `NA') {

        dis "The estimated effect is `est_eff'. The threshold value for statistical significance"
        dis "is " string(round(`beta_threshold', 0.001), "%9.3f") " (with null hypothesis = `nu' and alpha = `sig'). To reach that threshold,"
        dis string(round(`sustain', 0.001), "%9.3f") "% of the (`est_eff') estimate would have to be due to bias. This implies to sustain"
        dis "an inference one would expect to have to replace `recase' (" string(round(`sustain', 0.001), "%9.3f") "%) observations with"
        dis "effect of `nu' with data points with effect of " string(round(`beta_threshold', 0.001), "%9.3f") " (RIR = `recase')."
        dis ""
        
    } 
	else if (abs(`est_eff') < abs(`beta_threshold') & `eff_thr' != `NA') {

        if (`far_bound' == 0 & `est_eff' * `eff_thr' < 0) {
            dis "Sign for effect threshold changed to be that of estimated effect. The threshold"
            dis "is now " string(round(`beta_threshold', 0.001), "%9.3f") ". Different signs would require replacement values to be arbitrarily"
            dis "more extreme than the threshold (`eff_thr') to achieve the threshold value."
            dis "Consider using ITCV."
            dis ""
        }
        dis "The estimated effect is `est_eff', and specified threshold for inference is `eff_thr'."
        if (`far_bound' == 0 & `est_eff' * `eff_thr' < 0) {
            dis "The threshold used takes the same sign as the estimated effect. See comment above."
            dis ""
        }
        dis "To reach that threshold, " string(round(`sustain', 0.001), "%9.3f") "% of the (`est_eff') estimate would have to be due"
        dis "to bias. This implies that to sustain an inference one would expect to have"
        dis "to replace `recase' (" string(round(`sustain', 0.001), "%9.3f") "%) observations with effect of `nu' with data points with"
        dis "effect of " string(round(`beta_threshold', 0.001), "%9.3f") " (RIR = `recase')."
        dis ""
    }
    else if (`est_eff' == `beta_threshold') {
        di as error "The coefficient is exactly equal to the threshold."
    }
	
	dis "See Frank et al. (2013) for a description of the method."
	dis ""
	dis "Citation: Frank, K.A., Maroulis, S., Duong, M., and Kelcey, B. (2013)."
	dis "What would it take to change an inference?"
	dis "Using Rubin's causal model to interpret the robustness of causal inferences."
	dis "Education, Evaluation and Policy Analysis, 35, 437-460."	
	dis ""
	dis "Accuracy of results increases with the number of decimals reported."
	
	}
	else if ("`indx'" == "COP") {
    if (`negest' == 1) {
        display "Using the absolute value of the estimated effect, result can be interpreted by symmetry."
		dis ""
    }
	dis "Coefficient of Proportionality (COP):"
	dis ""
	dis "This function calculates a correlation-based coefficient of"
	dis "proportionality (delta) as well as Oster's delta*."
	dis ""
	dis "delta* is " string(`delta_star', "%9.3f") " (assuming no covariates in the baseline model M1),"
	dis "the correlation-based delta is " string(`delta_exact', "%9.3f") ", with a bias of " string(`delta_pctbias', "%9.3f") "%."
	dis "Note that %bias = (delta* - delta) / delta."
	dis ""
	dis "With delta*, the coefficient in the final model will be " string(`eff_x_m3_oster', "%9.3f")
	dis "With the correlation-based delta, the coefficient will be " string(`eff_x_m3', "%9.3f")
	dis ""
	di "Include 'return list' following the pkonfound command to see more specific results" _newline "and graphic presentation of the result."
	di ""
	di "This function also calculates conditional RIR that nullifies the statistical inference."
	di "If the replacement cases have a fixed value, then RIR = " string(`cond_rir_fixedy', "%9.3f") "."
	di "If the replacement cases follow a null distribution, then RIR = " string(`cond_rir_null', "%9.3f") "."
	di "If the replacement cases satisfy rxy|Z = 0, then RIR = " string(`cond_rir_rxyz', "%9.3f") "."  
	
	}
	else if ("`indx'" == "PSE") {
		
	dis "Note: Interpreting results from the PSE index in Stata may involve slight inaccuracies" _newline "due to approximations in calculations with complex numbers, which are not fully" _newline "supported by Stata. For more precise results, consider cross-checking with the" _newline "konfound-it app or using the konfound package in R. See the instructions below for using R."
	
	dis ""
	dis "This function calculates the correlations associated with the confound that " 
	dis "generate an estimated effect that is approximately equal to the threshold " 
    dis "while preserving the standard error."
    dis ""
    dis "The correlation between X and CV is " string(`rxcv', "%9.3f") ", and the correlation between " 
    dis "Y and CV is " string(`rycv', "%9.3f") "."
    dis ""
    dis "Conditional on the covariates, the correlation between X and CV is " string(`rxcvGz', "%9.3f") ", " 
	dis "and the correlation between Y and CV is " string(`rycvGz', "%9.3f") "."
    dis ""
    dis "Including such a CV, the coefficient changes to " string(`eff_x_M3', "%9.3f") ", with standard error "
	dis "of " string(`se_x_M3', "%9.3f") "."
    dis ""
    dis "To see more specific results include 'return list' following the pkonfound command."
	dis ""
	dis "To replicate these results in R, use the following code:"
	dis ""
	dis `"install.package("konfound")"'
	dis ""
	dis `"library(konfound)"'
	dis ""
	dis `"pkonfound(est_eff = `est_eff', std_err = `std_err', n_obs = `n_obs', n_covariates = `n_covariates',"'
	dis `"          eff_thr = `eff_thr', sdx = `sdx', sdy = `sdy', R2 = `rs', "' 
	dis `"          index = "PSE")"'
	}	

	* raw_output for model_type = 0 and 1
	
	* return raw_output for RIR & ITCV
	if ("`indx'" == "RIR" | "`indx'" == "IT") {
		
		return scalar RIR_perc = `perc_to_change'
		return scalar RIR_primary = `recase'

		return scalar perc_bias_to_change = `perc_to_change'
		return scalar beta_threshold_verify = `beta_threshold_verify'
		return scalar beta_threshold = `beta_threshold'
		return scalar itcv = `uncond_rxcv' * `uncond_rycv'	
		return scalar itcvGz = `itcvGz'
		return scalar rycvGz = `rycvGz'
		return scalar rxcvGz = `rxcvGz'
		if ((`sdx'!=`NA') & (`sdy'!=`NA') & (`rs'!=`NA')){
			return scalar rycv = `uncond_rycv'
			return scalar rxcv = `uncond_rxcv'
			return scalar benchmark_corr_product = `benchmark_corr_product'
			return scalar itcv_ratio_to_benchmark = `itcv_ratio_to_benchmark'
		}
		
		return scalar r_final = `r_finall' // should be updated soon
		*return scalar r_finall = `r_finall' // should be updated soon

		return scalar critical_r = `critical_r'
		return scalar act_r = `act_r'		
		return scalar obs_r = `obs_r'
	}

	* return raw_output for test_cop
	if ("`indx'" == "COP") {
		return scalar max_rcvz = `max_rcvz' 
		return scalar conditional_rir_rxygz = `cond_rir_rxyz'
		return scalar conditional_rir_pi_rxygz = `cond_rirpi_rxyz'
		return scalar conditional_rir_null = `cond_rir_null'
		return scalar conditional_rir_pi_null = `cond_rirpi_null'
		return scalar conditional_rir_fixed_y = `cond_rir_fixedy'
		return scalar conditional_rir_pi_fixed_y = `cond_rirpi_fixedy'
		return scalar var_cv = `sdcv'^2
		return scalar var_x = `sdx'^2
		return scalar var_y = `sdy'^2
		return scalar delta_pctbias = `delta_pctbias'
		return scalar delta_exact = `delta_exact'
		return scalar delta_star_restricted = `delta_star_restricted'
		return scalar delta_star = `delta_star'
		dis ""
		dis "Final table"
		matlist ftable, format(%15.6f)
		*matlist cormatrix
		dis "
		dis "Correlation matrix implied by delta*"
		matlist cor_oster 
		dis ""
		dis "Correlation matrix implied by delta_exact"
		matlist cor_exact 

	}

	* return raw_output for test_pse
	if ("`indx'" == "PSE") {	
		return scalar rxcvGz = `rxcvGz'
		return scalar rycvGz = `rycvGz'
		return scalar rxcv = `rxcv'
		return scalar rycv = `rycv'
		dis ""
		*return matrix cov_pse = cov_pse
		dis "Covariance matrix"
		matlist cov_pse
		*return matrix fTable = fTable
		return scalar eff_x_M3 = `eff_x_M3'
		return scalar se_x_M3 = `se_x_M3'
		dis ""
		dis "Final table"
		matlist fTable
	}
	
	
	
}

if `model_type'== 1 {
	dis ""
	local est_eff :word 1 of `anything'
	local std_err :word 2 of `anything'
	local n_obs :word 3 of `anything'
	local n_covariates :word 4 of `anything'
	local n_treat :word 5 of `anything'
	//local tails :word 6 of `anything' //== onetail=0 ==> two tail; onetail = 1 ==> one tail
	// removed to_return variable due to STATA's restriction
	
	// assign `tails' use the existing/user-inserted `onetail' value
	if (`onetail' == 0){
		local tails = 2
	}
	if (`onetail' == 1){
		local tails = 1
	}
	
	if (`est_eff' < 0){
		local thr_t = invttail(`n_obs' - `n_covariates' - 2, 1 - (`sig' / `tails')) 
	}
	else{
		local thr_t = invttail(`n_obs' - `n_covariates' - 2, 1 - (`sig' / `tails'))* -1 
	}

	if (`n_obs' <= 0 | `n_treat'<= 0){
		dis "Please enter positive integers for sample size and number of treatment group cases."
		exit
	}
	if (`n_obs' <= `n_treat'){
		dis "The total sample size should be larger than the number of treatment group cases."
		exit
	}


	if (`thr_t' ==.){
		dis "please enter valid value make, 0 < 1 - (`sig' / `tails')< 1; and (`n_obs' - `n_covariates' - 1)>=1"
	}


	local odds_ratio = exp(`est_eff')
	
	local minse = sqrt((4 * `n_obs' + sqrt(16 * `n_obs'^2 + 4 * `n_treat' * (`n_obs' - `n_treat') * ((4 + 4 * `odds_ratio'^2) / `odds_ratio' - 8)))/(2 * `n_treat' * (`n_obs' - `n_treat')))
	
	local changeSE = 0
	if (`std_err' < `minse'){
		local haveimaginary = 1
		local changeSE = 1
		local user_std_err = `std_err'
		local std_err = `minse'
	}
	
	// n_treat is the number of observations in the treatment group (c+d)
	// n_cnt is the number of observations in the control group (a+b)
	local n_cnt = `n_obs' - `n_treat'
	local t_ob = `est_eff' / `std_err'

	quietly isinvalidate `thr_t' `t_ob'
	local invalidate_ob = `r(isinva)'

	quietly isdcroddsratio `thr_t' `t_ob'
	local dcroddsratio_ob = `r(isdcrodds)'


	quietly geta1kfnl `odds_ratio' `std_err' `n_obs' `n_treat'
	local a1 = `r(a1kfnl)'
	local b1 = `n_cnt' - `a1'
	quietly getc1kfnl `odds_ratio' `std_err' `n_obs' `n_treat'
	local c1 = `r(c1kfnl)'
	local d1 = `n_treat' - `c1'

	// // a2, b2, c2, d2 are the second solution for the 4 cells in the contingency table

	quietly geta2kfnl `odds_ratio' `std_err' `n_obs' `n_treat'
	local a2 = `r(a2kfnl)'
	local b2 = `n_cnt' - `a2'
	quietly getc2kfnl `odds_ratio' `std_err' `n_obs' `n_treat'
	local c2 = `r(c2kfnl)'
	local d2 = `n_treat' - `c2'
	
	//    Differences between these two sets of solutions:
	//	 a1 c1 are small while a2 c2 are large
	//	 b1 d1 are large while b2 d2 are small
	//	 remove the solution if one cell has fewerer than 5 cases or negative cells or nan cells
	local check1 = 1
	local check2 = 1

	if (!(`n_cnt' >= `a1' & `a1' >= 5 & `n_cnt' >= `b1' & `b1' >= 5 & `n_treat' >= `c1' & `c1' >= 5 & `n_treat' >= `d1' & `d1' >= 5)| `a1' ==. | `b1' ==. | `c1' ==. | `d1' ==.){
		local check1 = 0
	}

	if (!(`n_cnt' >= `a2' & `a2' >= 5 & `n_cnt' >= `b2' & `b2' >= 5 & `n_treat' >= `c2' & `c2' >= 5 & `n_treat' >= `d2' & `d2' >= 5)|  `a2' ==. | `b2' ==. | `c2' ==. | `d2' ==.) {
		local check2 = 0
	}

	* before rounding
	
	if (`check1' == 1){
	* Round values
    quietly getabcdkfnl `a1' `b1' `c1' `d1'
	local a_1 = `r(ra1)'
	local b_1 = `r(rb1)'
	local c_1 = `r(rc1)'
	local d_1 = `r(rd1)'
    quietly getswitch `a_1' `b_1' `c_1' `d_1' `thr_t' `switch_trm' `n_obs'
	local solution1_final_switch = `r(final_switch)'  
	}

	if (`check2' == 1){
    * Round values 
    quietly getabcdkfnl `a2' `b2' `c2' `d2'
	local a_2 = `r(ra1)'
	local b_2 = `r(rb1)'
	local c_2 = `r(rc1)'
	local d_2 = `r(rd1)'
    quietly getswitch `a_2' `b_2' `c_2' `d_2' `thr_t' `switch_trm' `n_obs'
	local solution2_final_switch = `r(final_switch)'
	}

	if (`check1' == 0 & `check2' == 0){
		dis "Cannot generate a usable contingency table!"
		exit
	}

	if (`check1' == 1 & `check2' == 1){
		if (`solution1_final_switch' < `solution2_final_switch'){
			local indicator = 1
		}
		else{
			local indicator = 2
		}
	}

	if (`check1' == 1 & `check2' == 0){
		local indicator = 1
	}

	if (`check1' == 0 & `check2' == 1){
		local indicator = 2
	}

	if (`indicator' == 1){
		* Round values
		quietly getabcdkfnl `a1' `b1' `c1' `d1'
		local a_1 = `r(ra1)'
		local b_1 = `r(rb1)'
		local c_1 = `r(rc1)'
		local d_1 = `r(rd1)'
		quietly getswitch `a_1' `b_1' `c_1' `d_1' `thr_t' `switch_trm' `n_obs'
		matrix define table_start = (`a_1', `b_1' \ `c_1', `d_1')
	}
	else{
		* Round values
		quietly getabcdkfnl `a2' `b2' `c2' `d2'
		local a_2 = `r(ra1)'
		local b_2 = `r(rb1)'
		local c_2 = `r(rc1)'
		local d_2 = `r(rd1)'
		quietly getswitch `a_2' `b_2' `c_2' `d_2' `thr_t' `switch_trm' `n_obs'
		matrix define table_start = (`a_2', `b_2' \ `c_2', `d_2')
	}
	
	local needtworows = `r(needtworows)'
	local final_extra = `r(final_extra)'
	local final = `r(final_switch)' // total switch
	local final_primary = `final' - `final_extra'
	local est_eff_start = `r(est_eff_start)'
	local std_err_start = `r(std_err_start)'
	local t_start = `r(t_start)'


	// Check if the value is x.5 (i.e., has a fractional part of 0.5)
	if mod(`final_primary', 1) == 0.5 {
		// Round down by taking the floor of the value
		local final_primary = floor(`final_primary')
	}
	
	local est_eff_final = `r(est_eff_final)'
	local std_err_final = `r(std_err_final)'
	local t_final = `r(t_final)'

	local a = table_start[1,1]
	local b = table_start[1,2]
	local c = table_start[2,1]
	local d = table_start[2,2]
	
	local RIR_pi = .
	
	* switch the order of defining extra values due to error in defining extra values (final_extra, RIR_extra)

	if (`switch_trm' == 1 & `dcroddsratio_ob' == 1){
		local transferway = "treatment success to treatment failure"
		local transferway_start = "treatment row"
		local RIR = ceil(`final_primary'/((`a'+`c')/`n_obs'))*(1 - `replace') + ceil(`final_primary'/(`a'/(`a'+`b')))*`replace'
		local RIRway = "treatment success"
		local RIRway_start = "treatment row"		
		* add RIR_pi
		local RIR_pi = `RIR' / `d' * 100
		local p_destination = ((`a'+`c')/(`a'+`b'+`c'+`d'))*100 * (1-`replace') + (`a'/(`a' + `b'))*100*`replace'			
		* add RIRway_phrase
		if (`replace' == 0){
			local RIRway_phrase = "success in the entire sample"
		}
		else if (`replace' == 1){
			local RIRway_phrase = "success in the control group"
		}
		}

	if (`switch_trm' == 1 & `dcroddsratio_ob'== 0) {
		local transferway = "treatment failure to treatment success"
		local transferway_start = "treatment row"
		local RIR = ceil(`final_primary'/((`b'+`d')/`n_obs'))*(1 - `replace') + ceil(`final_primary'/(`b'/(`a'+`b')))*`replace'
		local RIRway = "treatment failure"
		local RIRway_start = "treatment row"
		local RIR_pi = `RIR' / `c' * 100
		local p_destination = ((`b'+`d')/(`a'+`b'+`c'+`d'))*100 * (1-`replace') + (`b'/(`a' + `b'))*100*`replace'			
		if (`replace' == 0){
			local RIRway_phrase = "failure in the entire sample"
		}
		else if (`replace' == 1){
			local RIRway_phrase = "failure in the control group"
		}
	  }

	if (`switch_trm' == 0 & `dcroddsratio_ob' == 1) {
		local transferway = "control failure to control success"
		local transferway_start = "control row"
		local RIR = ceil(`final_primary'/((`b'+`d')/`n_obs'))*(1 - `replace') + ceil(`final_primary'/(`b'/(`a'+`b')))*`replace'
		local RIRway = "control failure"
		local RIRway_start = "control row"		
		local RIR_pi = `RIR' / `a' * 100
		local p_destination = ((`b'+`d')/(`a'+`b'+`c'+`d'))*100 * (1-`replace') + (`b'/(`a' + `b'))*100*`replace'			
		if (`replace' == 0){
			local RIRway_phrase = "failure in the entire sample"
		}
		else if (`replace' == 1){
			local RIRway_phrase = "failure in the control group"
		}		
	  }

	if (`switch_trm' == 0 & `dcroddsratio_ob' == 0) {
		local transferway = "control success to control failure"
		local transferway_start = "control row"		
		local RIR = ceil(`final_primary'/((`a'+`c')/`n_obs'))*(1 - `replace') + ceil(`final_primary'/(`a'/(`a'+`b')))*`replace'
		local RIRway = "control success"
		local RIRway_start = "control row"
		local RIR_pi = `RIR' / `b' * 100
		local p_destination = ((`a'+`c')/(`a'+`b'+`c'+`d'))*100 * (1-`replace') + (`a'/(`a' + `b'))*100*`replace'		
		if (`replace' == 0){
			local RIRway_phrase = "success in the entire sample"
		}
		else if (`replace' == 1){
			local RIRway_phrase = "success in the control group"
		}		
	  }
	
	if (`needtworows' == 0){
		* add to consistent extra values (it should be non-NA when needtworows == 1)
		local RIR_extra = 0
		local final_extra = 0
	}

	if (`needtworows' == 1){
		
		local RIR_pi = .
		
		if (`switch_trm' == 1 & `dcroddsratio_ob' == 1){
		  local transferway_extra = "control failure to control success"
		  local transferway_extra_start = "control row"		
		  local RIR_extra = ceil(`final_extra'/((`b'+`d')/`n_obs'))*(1 - `replace') + ceil(`final_extra'/(`b'/(`b'+`a')))*`replace'
		  local RIRway_extra = "control failure"
		  local RIRway_extra_start = "control row"
		  local p_destination_extra = ((`b'+`d')/(`a'+`b'+`c'+`d'))*100 * (1-`replace') + (`b'/(`a' + `b'))*100*`replace'		  
		}
		
		if (`switch_trm' == 1 & `dcroddsratio_ob' == 0){
		  local transferway_extra = "control success to control failure"
		  local transferway_extra_start = "control row"				  
		  local RIR_extra = ceil(`final_extra'/((`a'+`c')/`n_obs'))*(1 - `replace') + ceil(`final_extra'/(`a'/(`a'+`b')))*`replace'
		  local RIRway_extra = "control success"
		  local RIRway_extra_start = "control row"
		  local p_destination_extra = ((`a'+`c')/(`a'+`b'+`c'+`d'))*100 * (1-`replace') + (`a'/(`a' + `b'))*100*`replace'			  
		}
		
		if (`switch_trm' == 0 & `dcroddsratio_ob' == 1){
		  local transferway_extra = "treatment success to treatment failure"
		  local transferway_extra_start = "treatment row"				  
		  local RIR_extra = ceil(`final_extra'/((`a'+`c')/`n_obs'))*(1 - `replace') + ceil(`final_extra'/(`a'/(`a'+`b')))*`replace'
		  local RIRway_extra = "treatment success"
		  local RIRway_extra_start = "treatment row"
		  local p_destination_extra = ((`a'+`c')/(`a'+`b'+`c'+`d'))*100 * (1-`replace') + (`a'/(`a' + `b'))*100*`replace'		  
		}
		
		if (`switch_trm' == 0 & `dcroddsratio_ob' == 0) {
		  local transferway_extra = "treatment failure to treatment success"
		  local transferway_extra_start = "treatment row"				  
		  local RIR_extra = ceil(`final_extra'/((`b'+`d')/`n_obs'))*(1 - `replace') + ceil(`final_extra'/(`b'/(`b'+`a')))*`replace'
		  local RIRway_extra = "treatment failure"
		  local RIRway_extra_start = "treatment row"
		  local p_destination_extra = ((`b'+`d')/(`a'+`b'+`c'+`d'))*100 * (1-`replace') + (`b'/(`a' + `b'))*`replace'
		}
	}	
	
	if (`onetail' == 0){
		local tails = 2
	}
	if (`onetail' == 1){
		local tails = 1
	}
	
	*add for p-calculation
	if (`onetail' == 0) {
    	local p_str = 2 * ttail(`n_obs' - `n_covariates' - 2, abs(`t_start'))
		local p_fin = 2 * ttail(`n_obs' - `n_covariates' - 2, abs(`t_final'))
		}
		else if (`onetail' == 1) {
		local p_str = ttail(`n_obs' - `n_covariates' - 2, abs(`t_start'))
		local p_fin = ttail(`n_obs' - `n_covariates' - 2, abs(`t_final'))
		}

	*Add to indicate probability of failure in control/entire group  
	if (`replace' == 1) {
		local prob_replace = table_start[1,1] / `n_cnt' *100
		} 
		else {
		local prob_replace = table_start[1,1] / `n_obs' * 100
		}		
		
	if (`needtworows' == 1){
		local total_switch = `final_primary' + `final_extra'
		local total_RIR = `RIR' + `RIR_extra'
	}
	else{
		local total_switch = `final_primary'
		local total_RIR = `RIR'
	}
	
	* add column/row label
	matrix rownames table_start = Control Treatment
	matrix colnames table_start = Fail Success
	matrix rownames table_final = Control Treatment
	matrix colnames table_final = Fail Success

	* Extract values for table_start
	scalar a_start = el(table_start, 1, 1)
	scalar b_start = el(table_start, 1, 2)
	scalar c_start = el(table_start, 2, 1)
	scalar d_start = el(table_start, 2, 2)
		
	* Calculate success rates and totals for table_start
	scalar success_percent_control_start = (b_start / (a_start + b_start)) * 100
	scalar success_percent_treatment_start = (d_start / (c_start + d_start)) * 100
	scalar total_fail_start = a_start + c_start
	scalar total_success_start = b_start + d_start
	scalar total_percentage_start = (total_success_start / (total_fail_start + total_success_start)) * 100
	
	* Initialize a 3x3 matrix with zeros
	matrix revised_table_start = J(3,3,0)

	* Fill in the matrix with values for table_start
	matrix revised_table_start[1,1] = a_start
	matrix revised_table_start[1,2] = b_start
	matrix revised_table_start[1,3] = success_percent_control_start

	matrix revised_table_start[2,1] = c_start
	matrix revised_table_start[2,2] = d_start
	matrix revised_table_start[2,3] = success_percent_treatment_start

	matrix revised_table_start[3,1] = total_fail_start
	matrix revised_table_start[3,2] = total_success_start
	matrix revised_table_start[3,3] = total_percentage_start

	* Name the columns and rows appropriately
	matrix colnames revised_table_start = Fail Success Success_%
	matrix rownames revised_table_start = Control Treatment Total
	
	
	* Extract values for table_final
	scalar a_fin = el(table_final, 1, 1)
	scalar b_fin = el(table_final, 1, 2)
	scalar c_fin = el(table_final, 2, 1)
	scalar d_fin = el(table_final, 2, 2)
	
	* Calculate success rates and totals for table_final
	scalar success_percent_control_final = (b_fin / (a_fin + b_fin)) * 100
	scalar success_percent_treatment_final = (d_fin / (c_fin + d_fin)) * 100
	scalar total_fail_final = a_fin + c_fin
	scalar total_success_final= b_fin + d_fin
	scalar total_percentage_final = (total_success_final / (total_fail_final + total_success_final)) * 100
	
	* Initialize a 3x3 matrix with zeros
	matrix revised_table_final = J(3,3,0)

	* Fill in the matrix with values for table_final
	matrix revised_table_final[1,1] = a_fin
	matrix revised_table_final[1,2] = b_fin
	matrix revised_table_final[1,3] = success_percent_control_final

	matrix revised_table_final[2,1] = c_fin
	matrix revised_table_final[2,2] = d_fin
	matrix revised_table_final[2,3] = success_percent_treatment_final

	matrix revised_table_final[3,1] = total_fail_final
	matrix revised_table_final[3,2] = total_success_final
	matrix revised_table_final[3,3] = total_percentage_final

	* Name the columns and rows appropriately
	matrix colnames revised_table_final = Fail Success Success_%
	matrix rownames revised_table_final = Control Treatment Total	
		
		
	
		// Conditional Fragility calculation component
	if `p_str' < 0.05 {
    	if "`RIRway'" == "treatment success" {
        	local prob_indicator = "failure"
			}
			else if "`RIRway'" == "treatment failure" {
				local prob_indicator = "success"
			}
			else if "`RIRway'" == "control success" {
				local prob_indicator = "failure"
			}
			else if "`RIRway'" == "control failure" {
				local prob_indicator = "success"
			}
		}
		else {  // p_ob > 0.05
			if "`RIRway'" == "treatment success" {
				local prob_indicator = "failure"
			}
			else if "`RIRway'" == "treatment failure" {
				local prob_indicator = "success"
			}
			else if "`RIRway'" == "control success" {
				local prob_indicator = "failure"
			}
			else if "`RIRway'" == "control failure" {
				local prob_indicator = "success"
			}
		}

	// Check for the allnotenough condition and apply similar logic for RIRway_extra
	if (`needtworows' == 1) {
		if `p_str' < 0.05 {
			if "`RIRway_extra'" == "treatment success" {
				local prob_indicator_extra = "failure"
			}
			else if "`RIRway_extra'" == "treatment failure" {
				local prob_indicator_extra = "success"
			}
			else if "`RIRway_extra'" == "control success" {
				local prob_indicator_extra = "failure"
			}
			else if "`RIRway_extra'" == "control failure" {
				local prob_indicator_extra = "success"
			}
		}
		else {  // p_ob > 0.05
			if "`RIRway_extra'" == "treatment success" {
				local prob_indicator_extra = "failure"
			}
			else if "`RIRway_extra'" == "treatment failure" {
				local prob_indicator_extra = "success"
			}
			else if "`RIRway_extra'" == "control success" {
				local prob_indicator_extra = "failure"
			}
			else if "`RIRway_extra'" == "control failure" {
				local prob_indicator_extra = "success"
			}
		}
	}
	
	* Output Language Objects	
	
	* Summarizing statement for the start
	if (`needtworows' == 0) {
		local conclusion_sum_1 "RIR = `total_RIR'"
		local conclusion_sum_2 "Fragility = `total_switch'"
	} 
	else if (`needtworows' == 1) {
		local conclusion_sum_1 "RIR = `RIR' + `RIR_extra' = `total_RIR'"
		local conclusion_sum_2 "Total RIR = Primary RIR in `RIRway_start' + Supplemental RIR in `RIRway_extra_start'"
		local conclusion_sum_3 "Fragility = `final_primary' + `final_extra' = `total_switch'"
		local conclusion_sum_4 "Total Fragility = Primary Fragility in `transferway_start' + Supplemental Fragility in `transferway_extra_start'"

	}

	
	* Table output
	local table_header1 "The table implied by the parameter estimates and sample sizes you entered:"
	local table_header1_1 "User-entered Table:"

	local table_header2 "The transfer of `total_switch' data points yields the following table:"
	local table_header2_1 "Transfer Table"

	// The summary of the estimates of the implied table
	if (`changeSE' == 1) {
		local estimates_summary1 "The reported log odds = " `=string(`est_eff',"%9.3f")' ", SE = " `=string(`user_std_err',"%9.3f")' ", and p-value = " `=string(`p_str',"%9.3f")' "."
		local estimates_summary1_1 "The SE has been adjusted to " `=string(`std_err_start',"%9.3f")' " to generate real numbers in the implied table"
		local estimates_summary1_2 "for which the p-value would be " `=string(`p_str',"%9.3f")' ". Numbers in the table cells have been rounded"
		local estimates_summary1_3 "to integers, which may slightly alter the estimated effect from the value originally entered."
	}
	else if (`changeSE' == 0) {
		local estimates_summary1 "The reported log odds = " `=string(`est_eff',"%9.3f")' ", SE = " `=string(`std_err',"%9.3f")' ", and p-value = " `=string(`p_str',"%9.3f")' "."
		local estimates_summary1_1 "Values in the table have been rounded to the nearest integer. This may cause"
		local estimates_summary1_2 "a small change to the estimated effect for the table."
	}
	
	* Summary of the estimates of the transfer table
	local estimates_summary2 "The log odds (estimated effect) = `=string(`est_eff_final',"%9.3f")', SE = `=string(`std_err_final',"%9.3f")', p-value = `=string(`p_fin',"%9.3f")'."
	local estimates_summary2_1 "This is based on t = estimated effect/standard error"
	
	* Decision on invalidation or sustaining the inference
	if (`invalidate_ob' == 1) {
		local change "To nullify the inference that the effect is different from 0 (alpha = `=string(`sig',"%9.3f")'),"
		local change_t "to nullify the inference,"
	}
	else {
		local change "To sustain an inference that the effect is different from 0 (alpha = `=string(`sig',"%9.3f")'),"
		local change_t "to sustain an inference,"
	}

	* Conclusion for single-row scenario
	if (`needtworows' == 0) {
		local conclusion1 "`change' one would" 
		local conclusion1_1 "need to transfer `total_switch' data points from `transferway' (Fragility = `total_switch')."
		local conclusion1_2 "This is equivalent to replacing `total_RIR' (`=string(`RIR_pi', "%9.3f")'%) `RIRway' data points with data points"
	}

	// Conclusion for control or entire sample condition
	if (`replace' == 1) {
		local conclusion2 "for which the probability of `prob_indicator' in the control group (" =string(`p_destination', "%9.3f") "%) applies (RIR = `total_RIR')."
	} 
	else {
		local conclusion2 "for which the probability of `prob_indicator' in the entire sample (" =string(`p_destination', "%9.3f") "%) applies (RIR = `total_RIR')."
	}

	local conclusion3 "RIR = Fragility/P(destination)"

	// Special case for RIR percentage > 100
	if (`needtworows' == 0 & `RIR_pi' > 100) {
		local conclusion_large_rir "Note the RIR exceeds 100%. Generating the transfer of `total_switch' data points would"
		local conclusion_large_rir2 "require replacing more data points than are in the `RIRway' condition."
	}
	else {
		local conclusion_large_rir ""
		local conclusion_large_rir2 ""
	}

	// Conclusion for two-row scenario
	if (`needtworows' == 1) {
		local conclusion_twoway_1 "In terms of Fragility, `change_t' only transferring `final_primary' data points from" 
		local conclusion_twoway_2 "`transferway' is not enough to change the inference."
		local conclusion_twoway_3 "One would also need to transfer `final_extra' data points from `transferway_extra'"
		local conclusion_twoway_4 "as shown, from the User-entered Table to the Transfer Table."
		local conclusion_twoway_5 "In terms of RIR, generating the `final_primary' switches from `transferway',"
		local conclusion_twoway_6 "is equivalent to replacing `RIR' `RIRway' data points with data points for which"
		
		if (`replace' == 1) {
			local conclusion_twoway_7 "the probability of `prob_indicator' in the control sample (`=string(`p_destination',"%9.3f")'%) applies."
			local conclusion_twoway_10 "the probability of `prob_indicator_extra' in the control sample (`=string(`p_destination_extra',"%9.3f")'%) applies."
		} 
		else {
			local conclusion_twoway_7 "the probability of `prob_indicator' in the entire sample (`=string(`p_destination',"%9.3f")'%) applies."
			local conclusion_twoway_10 "the probability of `prob_indicator_extra' in the entire sample (`=string(`p_destination_extra',"%9.3f")'%) applies."
		}
	
		local conclusion_twoway_8 "In addition, generating the `final_extra' switches from `transferway_extra' is"
		local conclusion_twoway_9 "equivalent to replacing `RIR_extra' `RIRway_extra' data points with data points for which"
		local conclusion_twoway_11 "Therefore, the total RIR is `total_RIR'."
		local conclusion_twoway_12 "RIR = Fragility/P(destination)"
	}

	// Citation section
	local citation "See Frank et al. (2021) for a description of the methods."
	local citation_1 "*Frank, K. A., *Lin, Q., *Maroulis, S., *Mueller, A. S., Xu, R., Rosenberg, J. M., ... & Zhang, L. (2021)."
	local citation_2 "Hypothetical case replacement can be used to quantify the robustness of trial results."
	local citation_3 "Journal of Clinical Epidemiology, 134, 150-159. *authors are listed alphabetically."
	local citation_4 "Accuracy of results increases with the number of decimals entered."	

	
	* Output language starts here	
		
	
	dis "Robustness of Inference to Replacement (RIR):"
	dis ""		
	dis "`conclusion_sum_1'"
	dis "`conclusion_sum_2'"
	dis ""
	if (`needtworows' == 1){
	dis "`conclusion_sum_3'"
	dis "`conclusion_sum_4'"	
	dis ""
	}

	dis "`table_header1'"	
	dis "`table_header1_1'"	
	matlist revised_table_start
	dis ""
	
	if (`changeSE' == 1) {
		dis "`estimates_summary1'"
		dis "`estimates_summary1_1'"
		dis "`estimates_summary1_2'"
		dis "`estimates_summary1_3'"
	} 
	else if (`changeSE' == 0){
		dis "`estimates_summary1'"
		dis "`estimates_summary1_1'"
		dis "`estimates_summary1_2'"		
	}

	dis ""
	if (`needtworows' == 0) {
		dis "`conclusion1'"
		dis "`conclusion1_1'"
		dis "`conclusion1_2'"
		dis "`conclusion2'"
		dis ""
		dis "`conclusion3'"
	} 
	else if (`needtworows' == 1){
		dis "`conclusion_twoway_1'"
		dis "`conclusion_twoway_2'"
		dis "`conclusion_twoway_3'"
		dis "`conclusion_twoway_4'"
		dis ""
		dis "`conclusion_twoway_5'"
		dis "`conclusion_twoway_6'"
		dis "`conclusion_twoway_7'"
		dis ""
		dis "`conclusion_twoway_8'"
		dis "`conclusion_twoway_9'"
		dis "`conclusion_twoway_10'"
		dis ""
		dis "`conclusion_twoway_11'"
		dis ""
		dis "`conclusion_twoway_12'"
	}
	
	if (`needtworows' == 0 & `RIR_pi' > 100){
	dis ""	
	dis "`conclusion_large_rir'"
	dis "`conclusion_large_rir2'"		
	}	
	dis ""
	dis "`table_header2'"	
	dis "`table_header2_1'"	
	matlist revised_table_final
	dis ""
	dis "`estimates_summary2'"
	dis "`estimates_summary2_1'" 
	dis ""
	dis "`citation'"
	dis ""
	dis "`citation_1'"
	dis "`citation_2'"
	dis "`citation_3'"
	dis ""
	dis "`citation_4'"
		

	* raw_output for model_type = 1
	return scalar needtworows = `needtworows'
	if (`needtworows' == 1){
			return scalar RIR_supplemental = `RIR_extra'	
			return scalar fragility_supplemental = `final_extra'
	}

	return scalar analysis_SE = `std_err'	

	if (`changeSE' == 1){
		return scalar user_SE = `user_std_err'
	}

    return scalar fragility_primary = `final_primary'
	return scalar RIR_perc = `RIR_pi'
	return scalar RIR_primary = `RIR'
	
}

if `model_type'== 2 {
	local a1 :word 1 of `anything'
	local b1 :word 2 of `anything'
	local c1 :word 3 of `anything'
	local d1 :word 4 of `anything'
	if (`a1' < 0 | `b1' < 0 | `c1' < 0 | `d1' < 0){
		dis "Please enter non-negative integers for each cell."
		exit
	} 

	if (`a1' != round(`a1') | `b1' != round(`b1') | `c1' != round(`c1') | `d1' != round(`d1')){
		dis "Please enter non-negative integers for each cell."
		exit
	}

	if (`test1' == 1 & (`a1' < 5 | `b1' < 5 | `c1' < 5 | `d1' < 5)){
		di as error "Because the expected value in at least one cell is less than 5 consider rerunning using Fisher's exact p-value."
	}

	// edit 092924
	// Calculate expected values
	local total = `a1' + `b1' + `c1' + `d1'
	local expected_a = (`a1' + `c1') * (`a1' + `b1') / (`a1' + `b1' + `c1' + `d1')
	local expected_b = (`a1' + `b1') * (`b1' + `d1') / (`a1' + `b1' + `c1' + `d1')
	local expected_c = (`a1' + `c1') * (`c1' + `d1') / (`a1' + `b1' + `c1' + `d1')
	local expected_d = (`c1' + `d1') * (`b1' + `d1') / (`a1' + `b1' + `c1' + `d1')

	// Check if expected values are less than 5 and if test is not Fisher's exact
	if ((`test1' != 0) & (`expected_a' < 5 | `expected_b' < 5 | `expected_c' < 5 | `expected_d' < 5)) {
		display as error "Because the expected value in at least one cell is less than 5, consider rerunning using Fisher's exact p-value."
		dis ""
		}
	

	// Check if any of a1, b1, c1, d1 are zero and adjust by adding 0.5
	if (`a1' == 0 | `b1' == 0 | `c1' == 0 | `d1' == 0) {
		local a1_OR = `a1' + 0.5
		local b1_OR = `b1' + 0.5
		local c1_OR = `c1' + 0.5
		local d1_OR = `d1' + 0.5
		} 
		else {
			local a1_OR = `a1'
			local b1_OR = `b1'
			local c1_OR = `c1'
			local d1_OR = `d1'
			}

	// Calculate the odds ratio
	local odds_ratio = `a1_OR' * `d1_OR' / (`b1_OR' * `c1_OR')

	local n_cnt = `a1' + `b1'
	local n_trm = `c1' + `d1'
	local n_obs = `n_cnt' + `n_trm'

	if (`test1' == 0){
		quietly fisher_p  `a1' `b1' `c1' `d1'
		local p_ob = `r(fisherp)'
		quietly fisher_oddsratio `a1' `b1' `c1' `d1'
		local fisher_ob = `r(fratio)'
	}

	if (`test1' == 1){
		quietly chisqp  `a1' `b1' `c1' `d1'
		local p_ob = `r(chisq_p)'
		
		quietly chisq_value `a1' `b1' `c1' `d1'
		local chisq_ob = `r(chisq_va)'

	}
	// get solution

	if (`test1' == 0){
		quietly getswitch_fisher `a1' `b1' `c1' `d1' `odds_ratio' `sig' `switch_trm'
		local fisher_final = `r(fisher_final)'
	}
	if (`test1' == 1){
		quietly getswitch_chisq `a1' `b1' `c1' `d1' `odds_ratio' `sig' `switch_trm'
		local chisq_final = `r(chisq_final)'
	}

	local dcroddsratio_ob = `r(dcroddsratio_ob)'
	local allnotenough = `r(needtworows)'
	local final = `r(final_switch)'
	local p_final = `r(p_final)'
	local taylor_pred = `r(taylor_pred)'
	local perc_bias_pred = `r(perc_bias_pred)'
	local final_extra = `r(final_extra)'
	local final_primary = `final' - `final_extra'
	
	// Check if the value is x.5 (i.e., has a fractional part of 0.5)
	if mod(`final_primary', 1) == 0.5 {
		// Round down by taking the floor of the value
		local final_primary = floor(`final_primary')
		}
	
	matrix rownames table_start = Control Treatment
	matrix colnames table_start = Fail Success
	matrix rownames table_final = Control Treatment
	matrix colnames table_final = Fail Success
 
 	* Extract values for table_start (if test1 == 1, chisq_getswitch, starting table's name is table_ob)
	if (`test1' == 0){
		scalar a_start = el(table_start, 1, 1)
		scalar b_start = el(table_start, 1, 2)
		scalar c_start = el(table_start, 2, 1)
		scalar d_start = el(table_start, 2, 2)	
		}
		else {
			scalar a_start = el(table_ob, 1, 1)
			scalar b_start = el(table_ob, 1, 2)
			scalar c_start = el(table_ob, 2, 1)
			scalar d_start = el(table_ob, 2, 2)	
		}
	
	* Calculate success rates and totals for table_start
	scalar success_percent_control_start = round((b_start / (a_start + b_start)) * 100, .01)
	scalar success_percent_treatment_start = round((d_start / (c_start + d_start)) * 100, .01)
	scalar total_fail_start = a_start + c_start
	scalar total_success_start = b_start + d_start
	scalar total_percentage_start = round((total_success_start / (total_fail_start + total_success_start)) * 100, .01)

	* Initialize a 3x3 matrix with zeros
	matrix revised_table_start = J(3,3,0)

	* Fill in the matrix with values for table_start
	matrix revised_table_start[1,1] = a_start
	matrix revised_table_start[1,2] = b_start
	matrix revised_table_start[1,3] = success_percent_control_start

	matrix revised_table_start[2,1] = c_start
	matrix revised_table_start[2,2] = d_start
	matrix revised_table_start[2,3] = success_percent_treatment_start

	matrix revised_table_start[3,1] = total_fail_start
	matrix revised_table_start[3,2] = total_success_start
	matrix revised_table_start[3,3] = total_percentage_start

	* Name the columns and rows appropriately
	matrix colnames revised_table_start = Fail Success Success_%
	matrix rownames revised_table_start = Control Treatment Total
	
	* Extract values for table_final
	scalar a_fin = el(table_final, 1, 1)
	scalar b_fin = el(table_final, 1, 2)
	scalar c_fin = el(table_final, 2, 1)
	scalar d_fin = el(table_final, 2, 2)
	
	// Check if any of the scalars are exactly 0.5 and set them to 0 if so
	if a_fin == 0.5 {
    	scalar a_fin = 0
		}

	if b_fin == 0.5 {
    	scalar b_fin = 0
		}

	if c_fin == 0.5 {
    	scalar c_fin = 0
		}
	
	if d_fin == 0.5 {
    	scalar d_fin = 0
		}
	
	* Calculate success rates and totals for table_final
	scalar success_percent_control_final = round((b_fin / (a_fin + b_fin)) * 100, .01)
	scalar success_percent_treatment_final = round((d_fin / (c_fin + d_fin)) * 100, .01)
	scalar total_fail_final = a_fin + c_fin
	scalar total_success_final= b_fin + d_fin
	scalar total_percentage_final = round((total_success_final / (total_fail_final + total_success_final)) * 100, .01)
	
	* Initialize a 3x3 matrix with zeros
	matrix revised_table_final = J(3,3,0)

	* Fill in the matrix with values for table_final
	matrix revised_table_final[1,1] = a_fin
	matrix revised_table_final[1,2] = b_fin
	matrix revised_table_final[1,3] = success_percent_control_final

	matrix revised_table_final[2,1] = c_fin
	matrix revised_table_final[2,2] = d_fin
	matrix revised_table_final[2,3] = success_percent_treatment_final

	matrix revised_table_final[3,1] = total_fail_final
	matrix revised_table_final[3,2] = total_success_final
	matrix revised_table_final[3,3] = total_percentage_final

	* Name the columns and rows appropriately
	matrix colnames revised_table_final = Fail Success Success_%
	matrix rownames revised_table_final = Control Treatment Total	
	
	// replace: 0 = entire //1 = control
	if (`switch_trm' == 1 & `dcroddsratio_ob' == 1){
		local transferway = "treatment success to treatment failure"
		local transferway_start = "treatment row"
		local RIR = ceil(`final_primary'/((`a1'+`c1')/`n_obs')) * (1-`replace') + ceil(`final_primary'/(`a1'/(`a1' + `b1')))*`replace'
		local RIRway = "treatment success"
		local RIRway_start = "treatment row"
		local RIR_pi = `RIR' / `d1' * 100
		local p_destination = ((`a1'+`c1')/(`a1'+`b1'+`c1'+`d1')) * 100 * (1-`replace') + (`a1'/(`a1' + `b1'))*100*`replace'	  
		}
	 
	if (`switch_trm' == 1 & `dcroddsratio_ob' == 0){
		local transferway = "treatment failure to treatment success"
		local transferway_start = "treatment row"
		local RIR = ceil(`final_primary'/((`b1'+`d1')/`n_obs')) * (1-`replace') + ceil(`final_primary'/(`b1'/(`a1' + `b1')))*`replace'
		local RIRway = "treatment failure"
		local RIRway_start = "treatment row"
		local RIR_pi = `RIR' / `c1' * 100
		local p_destination = ((`b1'+`d1')/(`a1'+`b1'+`c1'+`d1')) * 100 * (1-`replace') + (`b1'/(`a1' + `b1'))*100*`replace'
	  }
	 
	if (`switch_trm' == 0 & `dcroddsratio_ob' == 1){
		local transferway = "control failure to control success"
		local transferway_start = "control row"
		local RIR = ceil(`final_primary'/((`b1'+`d1')/`n_obs')) * (1-`replace') + ceil(`final_primary'/(`b1'/(`a1' + `b1')))*`replace'
		local RIRway = "control failure"
		local RIRway_start = "control row"
		local RIR_pi = `RIR' / `a1' * 100
		local p_destination = ((`b1'+`d1')/(`a1'+`b1'+`c1'+`d1'))*100* (1-`replace') + (`b1'/(`a1' + `b1'))*100*`replace'

	  }
	 
	if (`switch_trm' == 0 & `dcroddsratio_ob' == 0){
		local transferway = "control success to control failure"
		local transferway_start = "control row"
		local RIR = ceil(`final_primary'/((`a1' + `c1')/`n_obs'))*(1-`replace') + ceil(`final_primary'/(`a1'/(`a1' + `b1')))*`replace'
		local RIRway = "control success"
		local RIRway_start = "control row"
		local RIR_pi = `RIR' / `b1' * 100
		local p_destination = ((`a1'+`c1')/(`a1'+`b1'+`c1'+`d1'))*100 * (1-`replace') + (`a1'/(`a1' + `b1'))*100*`replace'	
	  }

	local RIR_extra = .
	local p_destination_extra = .

	if (`allnotenough' == 1) {
		local RIR_pi = .
		
		if mod(`final_extra', 1) == 0.5 {
			// Round down by taking the floor of the value
			local final_extra = floor(`final_extra')
			}
		
		if (`switch_trm' == 1 & `dcroddsratio_ob' == 1) {
		  local transferway_extra = "control failure to control success"
		  local transferway_extra_start = "control row"
		  local RIR_extra = ceil(`final_extra'/((`b1' + `d1')/`n_obs'))*(1 - `replace') + ceil(`final_extra'/(`b1'/(`b1' + `a1')))*`replace'
		  local RIRway_extra = "control failure"
		  local RIRway_extra_start = "control row"
		  local p_destination_extra = ((`b1'+`d1')/(`a1'+`b1'+`c1'+`d1'))*100 * (1-`replace') + (`b1'/(`a1' + `b1'))*100*`replace'
		}
		if (`switch_trm' == 1 & `dcroddsratio_ob' == 0) {
		  local transferway_extra = "control success to control failure"
		  local transferway_extra_start = "control row"
		  local RIR_extra = ceil(`final_extra'/((`a1' + `c1')/`n_obs'))*(1 - `replace') + ceil(`final_extra'/(`a1'/(`a1' + `b1')))*`replace'
		  local RIRway_extra = "control success"
		  local RIRway_extra_start = "control row"
		  local p_destination_extra = ((`a1'+`c1')/(`a1'+`b1'+`c1'+`d1'))*100 * (1-`replace') + ceil(`a1'/(`a1' + `b1'))*100*`replace'
		}
		if (`switch_trm' == 0 & `dcroddsratio_ob' == 1) {
		  local transferway_extra = "treatment success to treatment failure"
		  local transferway_extra_start = "treatment row"
		  local RIR_extra = ceil(`final_extra'/((`a1' + `c1')/`n_obs'))*(1 - `replace') + ceil(`final_extra'/(`a1'/(`a1' + `b1')))*`replace'
		  local RIRway_extra = "treatment success"
		  local RIRway_extra_start = "treatment row"
		  local p_destination_extra = ((`a1'+`c1')/(`a1'+`b1'+`c1'+`d1'))*100 * (1-`replace') + (`a1'/(`a1' + `b1'))*100*`replace'
		}
		if (`switch_trm' == 0 & `dcroddsratio_ob' == 0) {
		  local transferway_extra = "treatment failure to treatment success"
		  local transferway_extra_start = "treatment row"
		  local RIR_extra = ceil(`final_extra'/((`b1' + `d1')/`n_obs'))*(1 - `replace') + ceil(`final_extra'/(`b1'/(`b1' + `a1')))*`replace'
		  local RIRway_extra = "treatment failure"
		  local RIRway_extra_start = "treatment row"
		  local p_destination_extra = ((`b1'+`d1')/(`a1'+`b1'+`c1'+`d1'))*100 * (1-`replace') + (`b1'/(`a1' + `b1'))*100*`replace'
		}
	 }
	
	
	// Conditional Fragility calculation component
	if `p_ob' < 0.05 {
    	if "`RIRway'" == "treatment success" {
        	local prob_indicator = "failure"
			}
			else if "`RIRway'" == "treatment failure" {
				local prob_indicator = "success"
			}
			else if "`RIRway'" == "control success" {
				local prob_indicator = "failure"
			}
			else if "`RIRway'" == "control failure" {
				local prob_indicator = "success"
			}
		}
		else {  // p_ob > 0.05
			if "`RIRway'" == "treatment success" {
				local prob_indicator = "failure"
			}
			else if "`RIRway'" == "treatment failure" {
				local prob_indicator = "success"
			}
			else if "`RIRway'" == "control success" {
				local prob_indicator = "failure"
			}
			else if "`RIRway'" == "control failure" {
				local prob_indicator = "success"
			}
		}

	// Check for the allnotenough condition and apply similar logic for RIRway_extra
	if (`allnotenough' == 1) {
		if `p_ob' < 0.05 {
			if "`RIRway_extra'" == "treatment success" {
				local prob_indicator_extra = "failure"
			}
			else if "`RIRway_extra'" == "treatment failure" {
				local prob_indicator_extra = "success"
			}
			else if "`RIRway_extra'" == "control success" {
				local prob_indicator_extra = "failure"
			}
			else if "`RIRway_extra'" == "control failure" {
				local prob_indicator_extra = "success"
			}
		}
		else {  // p_ob > 0.05
			if "`RIRway_extra'" == "treatment success" {
				local prob_indicator_extra = "failure"
			}
			else if "`RIRway_extra'" == "treatment failure" {
				local prob_indicator_extra = "success"
			}
			else if "`RIRway_extra'" == "control success" {
				local prob_indicator_extra = "failure"
			}
			else if "`RIRway_extra'" == "control failure" {
				local prob_indicator_extra = "success"
			}
		}
	}
	
	
	///// start from here
	// Define conditional statement for p_ob and alpha
	if (`p_ob' < `alpha') {
		local change "To nullify the inference that the effect is different from 0 (alpha = `alpha'), "
	} 
	else {
		local change "To sustain an inference that the effect is different from 0 (alpha = `alpha'), "
	}


	// Case: final > 1
	if (`allnotenough' == 0 & `final' > 1) {
		local conclusion1 "`change'one would"
		local conclusion1a "need to transfer `final' data points from `transferway' as shown,"
		local conclusion1b "from the User-entered Table to the Transfer Table (Fragility = `final')."
		local conclusion1c "This is equivalent to replacing `RIR' (" =string(`RIR_pi', "%9.3f") "%) `RIRway' data points with data points"

		// Handle the condition for `replace`
		if (`replace' == 1) {
			local conclusion1d "for which the probability of `prob_indicator' in the control group (" =string(`p_destination', "%9.3f") "%) applies (RIR = `RIR')."
		} 
		else {
			local conclusion1d "for which the probability of `prob_indicator' in the entire group (" =string(`p_destination', "%9.3f") "%) applies (RIR = `RIR')."
		}
	}

	// Case: final == 1
	if (`allnotenough' == 0 & `final' == 1) {
		local conclusion1 "`change'one would"
		local conclusion1a "need to transfer `final' data point from `transferway' as shown,"
		local conclusion1b "from the User-entered Table to the Transfer Table (Fragility = `final')."
		local conclusion1c "This is equivalent to replacing `RIR' (" =string(`RIR_pi', "%9.3f") "%) `RIRway' data points with data points"

		// Handle the condition for `replace`
		if ("`replace'" == "control") {
			local conclusion1d "for which the probability of `prob_indicator' in the control group (" =string(`p_destination', "%9.3f") "%) applies (RIR = `RIR')."
		} 
		else {
			local conclusion1d "for which the probability of `prob_indicator' in the entire group (" =string(`p_destination', "%9.3f") "%) applies (RIR = `RIR')."
		}
	}
		
		local conclusion1_cal "RIR = Fragility/P(destination)"

	// Handle the case if RIR percentage > 100
	if (`allnotenough' == 0 & `RIR_pi' > 100) {
		local total_Fragility = `final_primary' + `final_extra'
		local conclusion_large_rir "Note the RIR exceeds 100%. Generating the transfer of `total_Fragility' data points would "
		local conclusion_large_rir2 "require replacing more data points than are in the `RIRway' condition."
	} 
	else {
		local conclusion_large_rir ""
		local conclusion_large_rir2 ""
	}

	// Case: allnotenough is true
	if (`allnotenough' == 1) {
		
			if (`p_ob' < `alpha') {
				local change_t "to nullify the inference that the effect is different from 0 (alpha = `alpha'), "
			} 
			else {
				local change_t "to sustain an inference that the effect is different from 0 (alpha = `alpha'), "
			}
		
		local conclusion1 "In terms of Fragility, `change_t'" 
		local conclusion1a "only transferring `final_primary' data points from  `transferway' is not enough to change"
		local conclusion1b "the inference. One would also need to transfer `final_extra' data points from `transferway_extra'"
		local conclusion1c "as shown, from User-entered Table to Transfer Table."
		
		local conclusion1d "In terms of RIR, generating the `final_primary' switches from `transferway' is" 
		local conclusion1e "equivalent to replacing `RIR' `RIRway' data points for which the probability of `prob_indicator'"
		
		if (`replace' == 1) {
			local conclusion1f "in the control sample (" =string(`p_destination', "%9.3f") "%) applies."
			local conclusion1i "in the control sample (" =string(`p_destination_extra', "%9.3f") "%) applies."
			}
			else {
				local conclusion1f "in the entire sample (" =string(`p_destination', "%9.3f") "%) applies."
				local conclusion1i "in the entire sample (" =string(`p_destination_extra', "%9.3f") "%) applies."
			}
			
		local conclusion1g "In addition, generating the `final_extra' switches from `transferway_extra' is equivalent to"
		local conclusion1h "replacing `RIR_extra' `RIRway_extra' data points with data points for which the probability of `prob_indicator_extra'"
		local conclusion1j "Therefore, the total RIR is " `RIR' + `RIR_extra' "."
	}

	// Citation section
	local citation "See Frank et al. (2021) for a description of the methods."
	local citation2 "*Frank, K. A., *Lin, Q., *Maroulis, S., *Mueller, A. S., Xu, R., Rosenberg, J. M., ... & Zhang, L. (2021)."
	local citation3 "Hypothetical case replacement can be used to quantify the robustness of trial results."
	local citation4 "Journal of Clinical Epidemiology, 134, 150-159. *authors are listed alphabetically."

	// Test outputs for chi-squared
	if (`test1' == 1) {
		local conclusion2 "For the User-entered Table, the Pearson's chi-square is " =string(`chisq_ob', "%9.3f") ", with p-value of " =string(`p_ob', "%9.3f") "."
		local conclusion3 "For the Transfer Table, the Pearson's chi-square is " =string(`chisq_final', "%9.3f") ", with p-value of " =string(`p_final', "%9.3f") "."
	}

	// Test outputs for Fisher's exact
	if (`test1' == 0) {
		local conclusion2 "For the User-entered Table, the estimated odds ratio is " =string(`fisher_ob', "%9.3f") ", with p-value of " =string(`p_ob', "%9.3f") "."
		local conclusion3 "For the Transfer Table, the estimated odds ratio is " =string(`fisher_final', "%9.3f") ", with p-value of " =string(`p_final', "%9.3f") "."
	}

	// Additional information
	local info1 "This function calculates the number of data points that would have to be replaced with" 
	local info2 "zero effect data points (RIR) to nullify the inference made about the association"
	local info3 "between the rows and columns in a 2x2 table."
	local info4 "One can also interpret this as switches (Fragility) from one cell to another, such as from"
	local info5 "the treatment success cell to the treatment failure cell."

	
	// Output Dispatch
	dis ""
	dis "Robustness of Inference to Replacement (RIR):"
	dis ""
	if (`allnotenough' == 0) {
		dis "RIR = `RIR'"
		dis "Fragility = `final_primary'"
		dis ""
	}
	else if (`allnotenough' == 1){
		local total_RIR = `RIR' + `RIR_extra'
		dis "RIR = `RIR' + `RIR_extra' = `total_RIR'"
		dis "Total RIR = Primary RIR in `RIRway_start' + Supplemental RIR in `RIRway_extra_start'"
		dis ""
		local total_Fragility = `final_primary' + `final_extra'
		dis "Fragility = `final_primary' + `final_extra' = `total_Fragility'"
		dis "Total Fragility = Primary Fragility in `transferway_start' + Supplemental Fragility in `transferway_extra_start'"
		dis ""
		
	}
	dis "`info1'"
	dis "`info2'"
	dis "`info3'"
	dis "`info4'"
	dis "`info5'"
	dis ""
	
	if (`allnotenough' == 0) {
		dis "`conclusion1'"
		dis "`conclusion1a'"
		dis "`conclusion1b'"
		dis "`conclusion1c'"
		dis "`conclusion1d'"
		dis ""
		dis "`conclusion1_cal'"
			if (`RIR_pi' > 100) {
				dis ""
				dis "`conclusion_large_rir'"
				dis "`conclusion_large_rir2'"
			}
		}
		else if (`allnotenough' == 1) {
			dis "`conclusion1'"
			dis "`conclusion1a'"
			dis "`conclusion1b'"
			dis "`conclusion1c'"
			dis ""
			dis "`conclusion1d'"		
			dis "`conclusion1e'"
			dis "`conclusion1f'"
			dis ""
			dis "`conclusion1g'"
			dis "`conclusion1h'"
			dis "`conclusion1i'"
			dis ""
			dis "`conclusion1j'"
			dis ""
			dis "`conclusion1_cal'"
	}	
	
	dis ""
	dis "`conclusion2'"
	dis "User-entered Table:"
	matlist revised_table_start
	dis ""

	dis "`conclusion3'"
	dis "Transfer table:""
	matlist revised_table_final
	
	dis ""
	dis "`citation'"
	dis ""
	dis "`citation2'"
	dis "`citation3'"
	dis "`citation4'"
	
	// Message for non-integer values
	if (`replace' == 1 & (`p_destination' == 0 | (`p_destination_extra' != . & `p_destination_extra' == 0))) {
		dis ""
		di as error "The RIR is infinite because the probability used to represent the target cell is zero:" _newline "RIR=Fragility/p(replacement source). Consider rerunning specifying that replacements" _newline "should be based on the probability of success/failure in the overall sample rather than" _newline "a specific cell (replace(0))."
		}

	* raw_output for model_type = 2	
	return scalar needtworows = `allnotenough'
	
	if (`allnotenough' == 1){
		return scalar fragility_supplemental = `final_extra'
	}
	
	return scalar fragility_primary = `final_primary'
	
	if (`RIR_pi' != .){
		return scalar RIR_perc = `RIR_pi'
	}
	
	if (`allnotenough' == 1){
		return scalar RIR_supplemental = `RIR_extra'
	}
	
	return scalar RIR_primary = `RIR'
	
	quietly capture drop row col pop
}
  
  end
