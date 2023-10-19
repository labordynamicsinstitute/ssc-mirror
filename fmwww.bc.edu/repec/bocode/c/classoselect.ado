cap program drop classoselect

program define classoselect, eclass

	syntax [if] [in] [,  ///
		POSTselection 				/// use postselection (unpenalized) coefficients; the default
		PENalized					/// use penalized coefficients
		Group(real 0)				/// report the result of certain group number; default is in e(group)
		*							///
	]		

	if ("`e(cmd)'" != "classifylasso") exit
	if ("`postselection'" == "postselection") ereturn local coef = "postselection"
	if ("`penalized'" == "penalized") ereturn local coef = "penalized"
	if (`group' > 0) ereturn scalar group = `group'
end
