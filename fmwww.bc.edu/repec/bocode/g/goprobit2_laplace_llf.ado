*! version 1.0.0  19feb2025
program goprobit2_laplace_llf
	
	args lnf ${args}
	if (${univariate}) local mu ${ML_y}
	gettoken j J: (global) gloJ
	tempvar Fl Fu
	local sigma = .70710678 // 1/sqrt(2)
	
	* Fl,Fu of minimum value of depvar
	quietly gen double `Fl' = 0                              if (${ML_y}==`j')
	quietly gen double `Fu' = laplace(`mu',`sigma',`cut`j'') if (${ML_y}==`j')
	
	* Fl,Fu of middle value(s) of depvar, if any (ie if 2+ categories)
	gettoken j J: J 
	while ("`J'"!="") {
		quietly replace `Fl' = laplace(`mu',`sigma',`cut`=`j'-1'') if (${ML_y}==`j')
		quietly replace `Fu' = laplace(`mu',`sigma',`cut`j'')      if (${ML_y}==`j')
		gettoken j J: J
	}
	
	* Fl,Fu of maximum value of depvar
	quietly replace `Fl' = laplace(`mu',`sigma',`cut`=`j'-1'') if (${ML_y}==`j')
	quietly replace `Fu' = 1                                   if (${ML_y}==`j')

	* Bring it all together
	quietly replace `lnf' = ln(`Fu'-`Fl')

end
