
// example from helpfile
cap program drop aic_model_selection_examples
cap program drop aic_model_1

program define aic_model_selection_examples
	if ("`1'" == "aic"){
		aic_model_1
	}
end

program define aic_model_1 
	sysuse auto
	sw, pe(0.5): logistic foreign mpg rep78 headroom trunk weight length turn displacement gear_ratio
	matrix list r(table)
	aic_model_selection logistic foreign weight gear_ratio rep78 mpg headroom turn 
end 

