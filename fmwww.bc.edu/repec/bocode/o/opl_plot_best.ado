********************************************************************************
* Command "opl_plot_best", V.1
* G.Cerulli
* September 1, 2025
********************************************************************************
program define opl_plot_best
    version 18.0
    // Sintassi: plot_best Y_hat_obs T_obs Y_hat_max T_best
    syntax varlist(min=4 max=4 fv ts) , [gr_reward_train(name) gr_action_train(name)]

    local Y_hat_obs  : word 1 of `varlist'
    local T_obs  : word 2 of `varlist'
    local Y_hat_max  : word 3 of `varlist'
    local T_best : word 4 of `varlist'
    
	tempvar _ID
	gen `_ID'=_n
	
    * 1) Plot Y_obs vs. Y_max
    qui twoway (connected  `Y_hat_obs' `_ID', lc(gray) mcolor(gray) mlabel(`T_obs')) ///
	       (connected  `Y_hat_max' `_ID', lc(orange) lp(dash) mcolor(orange) mlabel(`T_best')), ///
           title("Actual vs. maximal expected reward")   ///
           xtitle("Observation / Round") ytitle("Reward") ///
		   legend(order(1 "Actual expected reward" 2 "Max expected reward") pos(6) col(2)) ///
		   saving("`gr_reward_train'", replace) ///
           name("`gr_reward_train'", replace) 

    * 2) Plot T_obs vs. T_best
    qui twoway (connected `T_obs' `_ID' , lc(gray) lp(dash) mcolor(gray)) ///
	       (connected `T_best' `_ID' , lc(orange) mcolor(orange)), ///
           title("Actual vs. optimal action allocation") ///
		   legend(order(1 "Actual action" 2 "Optimal action") pos(6) col(2)) ///
           xtitle("Observation / Round") ///
           ytitle("Action") ///
           ylabel(, angle(horizontal)) ///
		   saving("`gr_action_train'", replace) ///
		   name("`gr_action_train'", replace)
end
********************************************************************************
