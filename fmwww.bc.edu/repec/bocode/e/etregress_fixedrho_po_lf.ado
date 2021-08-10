*!  version 1.0.0 01jun2020

program define etregress_fixedrho_po_lf
        version 11
	args 		lf	xb1	xb2 sigma0 sigma1


        /* Calculate the log-likelihood */

	local rho $rho
	local rho1 $rho1

	qui replace `lf' = (normprob((`xb2'+`rho1'*($ML_y1-`xb1')/exp(`sigma1'))/((1-`rho1'^2)^.5)))*(normalden($ML_y1,`xb1',exp(`sigma1')))   if $ML_y2
	qui replace `lf' = (1 - normprob((`xb2'+`rho'*($ML_y1-`xb1')/exp(`sigma0'))/((1-`rho'^2)^.5)))*(normalden($ML_y1,`xb1',exp(`sigma0')))   if !$ML_y2
	qui replace `lf' = ln(`lf') if $ML_samp
end
