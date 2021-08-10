*!  version 1.0.0 01jun2020

program define biprobit_fixedrho_lf
        version 11
	args 		lf	xb1	xb2


        /* Calculate the log-likelihood */


	local rho $rho

	qui replace `lf' = binorm(`xb1',`xb2',`rho')   if $ML_y1 & $ML_y2
	qui replace `lf' = binorm(-`xb1',`xb2',-`rho') if !$ML_y1 & $ML_y2
	qui replace `lf' = binorm(`xb1',-`xb2',-`rho') if $ML_y1 & !$ML_y2
	qui replace `lf' = binorm(-`xb1',-`xb2',`rho') if !$ML_y2& !$ML_y2
	qui replace `lf' = ln(`lf') if $ML_samp
end
