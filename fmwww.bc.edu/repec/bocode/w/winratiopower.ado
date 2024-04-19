*! Version 1.0.4 22-03-2024
* Version 1.0.3 30-08-2023
* Version 1.0.2 06-04-2023
* Version 1.0.1 20-01-2023

prog winratiopower , rclass 

version 12.0 
preserve 

syntax , outcome(string) [ power(real 0.8) n(integer 0) alpha(real 0.05) nratio(real 1)  *  ]

* ------------------------------------------
* Checks other than outcome()
* ------------------------------------------
if !(0<`power' & `power'<1) {
	di in r "Power must be between 0 and 1"
	exit
}
if !(0<`alpha' & `alpha'<1) {
	di in r "Alpha must be between 0 and 1"
	exit
}
if `nratio'<=0  {
	di in r "nratio must be positive"
	exit
}
			
* ------------------------------------------

* Calculate proportion allocated to treatment group
local allocation=`nratio'/(`nratio'+1)
local z_alpha=invnormal(1-`alpha'/2)
local z_power=invnormal(`power')				

* Put each set of outcomes into local macros outcome1, outcome2, etc. 
local outcome1 `outcome'

local i=1
while (`"`options'"'!="")  {
	local ++i
	local outcome
	local 0 , `options'
	syntax , [OUTcome(string) * ]
		if (`"`outcome'"'=="")  {
		di as err `"invalid option `options'"'
		exit 198 
		}
		local outcome`i' `outcome'
}

local noutcomes=`i'  // number of outcomes in hierarchy

* LOOP 1 -> each outcome in turn 
forvalues j=1/`noutcomes' { 

gettoken type outcome`j':outcome`j' 

if inlist("`type'", "c" , "b" , "r", "ts", "tf")!=1  {
	disp as err "Outcome type must be c, b, r, ts or tf"
	exit 198
	}

* -------------------------------------------------------------
* Normal Outcome 
* -------------------------------------------------------------
if "`type'"=="c" {
wrnormal , `outcome`j''  

* Map diff and margin to a SND so number 
* of expected WLT can be cauclated

	local diff_mean=`r(mean_t)'-`r(mean_c)'
	local diff_sd=sqrt(`r(sd_t)'^2 + `r(sd_c)'^2)

	local diff_mean_scaled=`diff_mean'/`diff_sd'
	local margin_scaled=`r(margin)'/`diff_sd'
			
	local w=normal(-`margin_scaled'-`diff_mean_scaled')			
	local l=1-normal(`margin_scaled'-`diff_mean_scaled')
	local t=1-`w'-`l'	

	if "`r(win)'"=="higher" {		
		local w_temp=`w'
		local l_temp=`l'
		local w=`l_temp'
		local l=`w_temp'
	}
}
* -------------------------------------------------------------
* Binary Outcome
* -------------------------------------------------------------
if "`type'"=="b" {
wrbinary , `outcome`j''
				
	if inrange(`r(prop_t)', 0,1)!=1 | inrange(`r(prop_c)',0,1)!=1 {
		di in r "Probabilities must be in range (0,1) for binary outcomes"
		exit
		}

* Calculate WLT assuming event (1) is harmful 
	local w=`r(prop_c)'-`r(prop_c)'*`r(prop_t)'
	local l=`r(prop_t)'-`r(prop_t)'*`r(prop_c)'
	local t=(`r(prop_c)'*`r(prop_t)' + (1-`r(prop_c)')*(1-`r(prop_t)'))	

	if "`r(win)'"=="event" {		
		local w_temp=`w'
		local l_temp=`l'
		local w=`l_temp'
		local l=`w_temp'
	}
}
* -------------------------------------------------------------
* Time-to-event Outcome
* -------------------------------------------------------------
if "`type'"=="tf" | "`type'"=="ts" {
wrtte , `outcome`j''

	local lambda_c=-log(1-`r(prob_c)')
	local lambda_t=`lambda_c'*`r(hr)'
	
	local w=(`lambda_c'/(`lambda_t' + `lambda_c')) * (1-exp(-(`lambda_t' + `lambda_c')))
	local l=(`lambda_t'/(`lambda_t' + `lambda_c')) * (1-exp(-(`lambda_t' + `lambda_c')))
	local t=1-`w'-`l'

	if "`type'"=="ts" {		
		local w_temp=`w'
		local l_temp=`l'
		local w=`l_temp'
		local l=`w_temp'
	}
}
* -------------------------------------------------------------
* Repeat Event
* -------------------------------------------------------------
if "`type'"=="r" {
wrrepeat , `outcome`j''

local max_mean=max(`r(mean_t)', `r(mean_c)')
local max_events=0
local ev_prob=1
local cum_prob=0

* Excluding >N events where event probability is less than 1 in a billion and where the cumulative probability distribution function is already very close to 1 
 
while `ev_prob'>0.000000001 | `cum_prob'<0.999999999 {

	if `r(disp)'==0 {
		local ev_prob=poissonp(`max_mean',`max_events')
		}
	else {
		local nb1_num=exp(lngamma(`max_events'+1/`r(disp)')) 
		local nb1_den=exp(lngamma(1/`r(disp)'))*exp(lngamma(`max_events'+1))
		local nb1=`nb1_num'/`nb1_den'
		local nb2=((`r(disp)'*`max_mean'^2)/(`max_mean'+`r(disp)'*`max_mean'^2))^`max_events'
		local nb3=(1/(1+`max_mean'*`r(disp)'))^(1/`r(disp)')
		local ev_prob=`nb1'*`nb2'*`nb3'
		if `ev_prob'==. {
		* Hopefully this is never required! If dispersion is very small 
		* Stata fails to calculate the probability 
		di as err "The event probability could not be calculated for the repeat event outcome. In our experience, this is most likely to occur when there is a reasonable probability that a very large numbers of repeat events could occur. Usually this is because either the assumed mean values or the assumed dispersion parameter is large. Consider altering the assumed distribution of repeat event outcome."
		exit 198 
		}
		}
		local cum_prob=`cum_prob'+`ev_prob'
		local ++max_events
}
	
* It's a win if fewer events on control than treatment
	local w=0
	local l=0
	forvalues ev_t=0/`max_events' {
	forvalues ev_c=0/`max_events' {
	
	if `r(disp)'==0 {
		local prob=poissonp(`r(mean_t)',`ev_t')*poissonp(`r(mean_c)',`ev_c')
		}
	else {
		*Calculating event probability in the treatment group
		local nb1_num=exp(lngamma(`ev_t'+1/`r(disp)')) 
		local nb1_den=exp(lngamma(1/`r(disp)'))*exp(lngamma(`ev_t'+1))
		local nb1=`nb1_num'/`nb1_den'
		local nb2=((`r(disp)'*`r(mean_t)'^2)/(`r(mean_t)'+`r(disp)'*`r(mean_t)'^2))^`ev_t'
		local nb3=(1/(1+`r(mean_t)'*`r(disp)'))^(1/`r(disp)')
		local ev_prob_t=`nb1'*`nb2'*`nb3'
		
		* Calcuating event probability in the control group
		local nb1_num=exp(lngamma(`ev_c'+1/`r(disp)')) 
		local nb1_den=exp(lngamma(1/`r(disp)'))*exp(lngamma(`ev_c'+1))
		local nb1=`nb1_num'/`nb1_den'
		local nb2=((`r(disp)'*`r(mean_c)'^2)/(`r(mean_c)'+`r(disp)'*`r(mean_c)'^2))^`ev_c'
		local nb3=(1/(1+`r(mean_c)'*`r(disp)'))^(1/`r(disp)')
		local ev_prob_c=`nb1'*`nb2'*`nb3'
		* Calculating probability in both groups 
		local prob=`ev_prob_t'*`ev_prob_c'
		}
	
	if `ev_t'<`ev_c' {
		local w=`w'+`prob'
		}
	if `ev_t'>`ev_c' {
		local l=`l'+`prob'
		}
	}
	}

	local t=1-`w'-`l'
	
	if "`r(win)'"=="more" {		
		local w_temp=`w'
		local l_temp=`l'
		local w=`l_temp'
		local l=`w_temp'
	}
}
* -------------------------------------------------------------
* END OF DIFFERENT TYPES OF OUTCOMES
* -------------------------------------------------------------

* Warning if treatment harmful
	if `l'>`w' {
	di in r "You have specified treatment to be harfmul at some level of the hierarchy"
	}

* Store % WLT at each level 
local w`j'=`w'
local l`j'=`l'
local t`j'=`t'

}		// END OF LOOP THROUGH OUTCOMES 


* ------------------------------------------
* LOOP 2: CALCULATE OVERALL WLT 
* ------------------------------------------
local all_wins=0
local all_losses=0
local remaining_ties=1

forvalues i=1/`noutcomes' {
		local wins`i'=`w`i''*`remaining_ties'
		local losses`i'=`l`i''*`remaining_ties'
		local ties`i'=`remaining_ties'*`t`i''
		
		local all_wins=`all_wins'+`wins`i''
		local all_losses=`all_losses'+`losses`i''
		local remaining_ties=1-`all_wins'-`all_losses'
}		

* ------------------------------------------
* CALCULATE LOG(WR) AND N or POWER 
* ------------------------------------------
local log_win_ratio=log(`all_wins'/`all_losses')
local sigma_sq=4*(1+`remaining_ties')/ ((3*`allocation')*(1-`allocation')*(1-`remaining_ties'))		

if `n'==0 {
local N=(`sigma_sq'*(`z_alpha'+`z_power')^2)/(`log_win_ratio'^2)
}

else {
local z_power=sqrt(`n'*`log_win_ratio'^2/`sigma_sq')-`z_alpha'
local power=normal(`z_power') 
}

* ------------------------------------------
* RETURNED VALUES
* ------------------------------------------
forvalues i=`noutcomes'(-1)1 {
return scalar ties`i' = `ties`i''
return scalar losses`i' = `losses`i''
return scalar wins`i' = `wins`i''
}

return scalar ties = `remaining_ties'
return scalar losses = `all_losses'
return scalar wins = `all_wins'
return scalar winratio = exp(`log_win_ratio')
if "`n'"=="" {
return scalar N = `N'
}
else {
return scalar power=`power'
}
return scalar sigma_sq=`sigma_sq'

* ------------------------------------------
* TABLE OF RESULTS
* ------------------------------------------
di 
di as text "{title: Estimated sample size for the win ratio}"
di 
disp  "{text: Study parameters:}"
di 
disp as text _col(5) "alpha = " %3.2f `alpha'
if `n'==0 {
disp as text  _col(5) "power = " %3.2f `power'
}
else {
disp as text  _col(5) "N = " %2.0f `n'	
}

if "`dropout'"!="" {
disp _col(5) "dropout = " %5.2f `dropout'
}

di 
di "{text: Estimated percentage of wins, losses and ties:}"
disp 
disp _col(5) _dup(43)"-" 
disp _col(5) "Level `i'" 	_col(20) "Wins"  _col(30)  "Ties" _col(40) "Losses"
disp _col(5) _dup(43)"-" 
forvalues i=1/`noutcomes' {
disp _col(5) "Level `i'" 	_col(20) %3.2f `wins`i''  _col(30)  %3.2f `ties`i'' _col(40) %3.2f `losses`i''
}
disp _col(5) _dup(43)"-" 
disp _col(5) "Overall"  	_col(20) %3.2f `all_wins'  _col(30)  %3.2f `remaining_ties' _col(40) %3.2f `all_losses'
disp _col(5) _dup(43)"-" 

if `n'==0 {
di 
di "{text: Estimated sample size:}"
dis
disp _col(5) "N = " %2.1f `N'
if `nratio'==1 {
	disp _col(5) "N per group = " %2.1f `N'/2
	}
else {
	local N1=`nratio'*`N'/(`nratio'+1)
	local N2=`N'/(`nratio'+1)
	disp _col(5) "N Group 1 = " %2.1f `N1'
	disp _col(5) "N Group 2 = " %2.1f `N2'
	}
}

else {
di 
di "{text: Estimated power:}"
dis
disp _col(5) "Power = " %3.2f `power'
}


end 


cap prog drop wrnormal
prog wrnormal , rclass
syntax  ,  mean(numlist min=2 max=2) sd(numlist min=2 max=2) win(string) [margin(real 0) ]

tokenize `mean' 
local mean_t=`1'
local mean_c=`2'

tokenize `sd'
local sd_t=`1'
local sd_c=`2'

return local margin = `margin'
return local mean_t = `mean_t'
return local mean_c = `mean_c'
return local sd_t = `sd_t'
return local sd_c = `sd_c'
return local win `win'

if inlist("`win'", "lower" , "higher")!=1 {
	disp in red  "With a continuous outcome win must be either lower or higher" 
	exit 198
	}

end 			


cap prog drop wrbinary
prog wrbinary , rclass
syntax  ,  proportions(numlist min=2 max=2) win(string) 

tokenize `proportions' 
local prop_t=`1'
local prop_c=`2'

return local prop_t = `prop_t'
return local prop_c = `prop_c'
return local win `win'

if inlist("`win'", "noevent" , "event")!=1 {
	disp in red  "With a binary outcome win must be either noevent or event" 
	exit 198
	}


end 		

cap prog drop wrtte 
prog wrtte , rclass
syntax  ,  eventprob(numlist min=1 max=1) hr(numlist min=1 max=1) 

return local prob_c = `eventprob'
return local hr = `hr'
return local win `win'

end 		

cap prog drop wrrepeat
prog wrrepeat , rclass
syntax  ,  mean(numlist min=2 max=2) win(string) [dispersion(real 0)]

if `dispersion'>0 & `dispersion'<0.01 {
	disp in red "Dispersion parameter has to be either 0 or ≥0.01."
	exit 198
	}

tokenize `mean' 
local mean_t=`1'
local mean_c=`2'

return local mean_t = `mean_t'
return local mean_c = `mean_c'
return local win `win'
return local disp `dispersion'

if inlist("`win'", "more" , "fewer")!=1 {
	disp in red  "With a repeat event outcome win must be either fewer or more" 
	exit 198
	}

end 			


