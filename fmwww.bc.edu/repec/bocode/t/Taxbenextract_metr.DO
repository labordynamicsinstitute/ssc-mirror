					*********************************
					*		METR computation		*
						
/*
This program is based on the metr.do file provided by the OECD.
It makes this latter more flexible byr taking different 'steps' in the computation
of the derivative, and also by potentially providing a decomposition of the METR
into different components.
*/



/***************************************  
									   *
Desbuquois Alexandre				   *
desbuquois.alexandre@gmail.com		   * 
Or									   *
alexandre.desbuquois@ens-cachan.fr	   *
									   *
***************************************/



capture pr drop metr
capture pr drop metr_perso_v2
pr def metr
version 3.1


	/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		%_1 = abbreviated country name
	++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
capture drop GROSS METR

        gen GROSS = (earnings*workdayp/5)+(spousinc*workdays/5)
	format GROSS %10.0g

                la var GROSS "gross earnings"

				
		forvalues step = $min_step / $max_step  {
			gen METR`step'     = (1 - (NET[_n+`step']-NET)/(GROSS[_n+`step']-GROSS  ))  *100
			/*
			replace METR`step'  = min(METR`step', 120)
			replace METR`step'  = max(METR`step', -20)
			*/
			la var METR`step'  "Marginal Effective Tax Rate (step `step' PoAW)"
		}	 
		
		if "$derivd"=="yes"{
		forvalues step = $min_step / $max_step {
			foreach v of varlist FB HB SA UB IW SC IT{
				if "`v'"=="IT" | "`v'"=="SC"{
					gen METR`step'_`v'    = (abs(`v'[_n+1]) - abs(`v'))/(GROSS[_n+1] - GROSS)*100
					label var METR`step'_`v' "Marginal fiscal effect of `v' (step of `step' PoAW)" 
					} 
				else{
					gen METR`step'_`v'    = -(abs(`v'[_n+1]) - abs(`v'))/(GROSS[_n+1] - GROSS)*100
					label var METR`step'_`v' "Marginal fiscal effect of `v' (step of `step' PoAW)" 
					}					
				}
			} 
		}


         la var NET  "net income"			
	/*
	forvalues step = $min_step / $max_step{
		gr NET METR`step' GROSS, rescale xlabel ylabel rlabel c(ll) s(..)
	}
	*/
end

