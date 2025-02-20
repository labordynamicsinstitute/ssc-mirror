*! version 1.0.0  19feb2025
program goprobit2_sged_llf
	
	args lnf ${args}
	if (${univariate}) local mu ${ML_y}
	gettoken j J: (global) gloJ
	tempvar Fl Fu phi Xl Xu Zl Zu
	
	* Phi calculation and helper variables
	quietly gen double `phi' = 1 / [sqrt(exp(lngamma(3/`p') - lngamma(1/`p'))*(3*`lambda'^2 + 1))]
	quietly gen double `Xl' = .
	quietly gen double `Xu' = .
	quietly gen double `Zl' = .
	quietly gen double `Zu' = .
	
	
	* Fl,Fu of minimum value of depvar
	quietly replace `Xu' = (`cut`j''-`mu')
	quietly replace `Zu' = abs(`Xu')^`p' / (`phi'^`p' * (1 + `lambda'*sign(`Xu'))^`p') 
	
	quietly gen double `Fl' = 0 if (${ML_y}==`j')
	quietly gen double `Fu' = /*
	*/ (1 - `lambda')/2 + ((1 + `lambda'*sign(`Xu'))/2) * sign(`Xu') * gammap(1/`p', `Zu') /*
	*/ if (${ML_y}==`j')
	
	* Fl,Fu of middle value(s) of depvar, if any (ie 2+ categories)
	gettoken j J: J 
	while ("`J'"!="") {
		quietly replace `Xl' = (`cut`=`j'-1''-`mu')
		quietly replace `Xu' = (`cut`j''-`mu')
		quietly replace `Zl' = abs(`Xl')^`p' / (`phi'^`p' * (1 + `lambda'*sign(`Xl'))^`p') 
		quietly replace `Zu' = abs(`Xu')^`p' / (`phi'^`p' * (1 + `lambda'*sign(`Xu'))^`p') 

		quietly replace `Fl' = /*
		*/ (1 - `lambda')/2 + ((1 + `lambda'*sign(`Xl'))/2) * sign(`Xl') * gammap(1/`p', `Zl') /*
		*/ if (${ML_y}==`j')
		quietly replace `Fu' = /*
		*/ (1 - `lambda')/2 + ((1 + `lambda'*sign(`Xu'))/2) * sign(`Xu') * gammap(1/`p', `Zu') /*
		*/ if (${ML_y}==`j')
		
		gettoken j J: J
	}
	
	* Fl,Fu of maximum value of depvar
	quietly replace `Xl' = (`cut`=`j'-1''-`mu')
	quietly replace `Zl' = abs(`Xl')^`p' / (`phi'^`p' * (1 + `lambda'*sign(`Xl'))^`p') 
	quietly replace `Fl' = /*
	*/ (1 - `lambda')/2 + ((1 + `lambda'*sign(`Xl'))/2) * sign(`Xl') * gammap(1/`p', `Zl') /*
	*/ if (${ML_y}==`j')
	quietly replace `Fu' = 1 if (${ML_y}==`j')

	* Bring it all together
	quietly replace `lnf' = ln(`Fu'-`Fl')

end
