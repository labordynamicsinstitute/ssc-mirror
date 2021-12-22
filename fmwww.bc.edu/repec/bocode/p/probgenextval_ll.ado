*! version 1.0.1
*! The Max. Lik. Estimation Evaluator 
*! for the Command probgenextval
*! Method lf
*! Diallo Ibrahima Amadou
*! All comments are welcome, 30Nov2021



capture program drop probgenextval_ll
program probgenextval_ll
	version 16.0
	args lnf xb cxi
	tempvar lse
	quietly generate double `lse' = ln(exp(1 + `cxi'*`xb') + 1)	
	quietly replace `lnf' = -(`lse')^(-1/`cxi')              if $ML_y1 == 1
	quietly replace `lnf' = ln(1 - exp(-(`lse')^(-1/`cxi'))) if $ML_y1 == 0
end


