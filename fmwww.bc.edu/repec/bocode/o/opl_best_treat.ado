********************************************************************************
* Command "opl_best_treat", V.1
* G.Cerulli
* September 1, 2025
********************************************************************************
program define opl_best_treat
    version 18.0
    // Syntax: best_treat Y0 Y1 ... YM-1
    syntax varlist(min=2 fv ts) 
	
    tempvar ymax tbest
    egen `ymax' = rowmax(`varlist')
    gen `tbest' = .

    local i = 0
    foreach v of local varlist {
        replace `tbest' = `i' if missing(`tbest') & `v' == `ymax'
        local ++i
    }
    gen __Y_hat_max  = `ymax'
    gen __T_best = `tbest'
    label var __Y_hat_max  "Max outcome"
    label var __T_best "Best treatment index"
end
