*!  version 1.0.0 01jun2020
* We thank Fernando Rios-Avila for helping us fix a bug in an earlier version

program define etregress_fixedrho_lf
        version 11
	args 		lf	xb1	xb2 sigma


        /* Calculate the log-likelihood */

	local rho $rho

	qui replace `lf' = (normprob((`xb2'+`rho'*($ML_y1-`xb1')/exp(`sigma'))/((1-(`rho')^2)^.5)))*(normalden($ML_y1,`xb1',exp(`sigma')))   if $ML_y2
	qui replace `lf' = (1 - normprob((`xb2'+`rho'*($ML_y1-`xb1')/exp(`sigma'))/((1-(`rho')^2)^.5)))*(normalden($ML_y1,`xb1',exp(`sigma')))   if !$ML_y2
	qui replace `lf' = ln(`lf') if $ML_samp
end
