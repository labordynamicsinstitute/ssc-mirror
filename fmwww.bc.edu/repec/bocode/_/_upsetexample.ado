*! version 1.0.0 22may2026

prog define _upsetexample
	
	args exnum
	
	if (`"`exnum'"' == "") {
		di as err "missing example number"
		exit 121
	}
	
	if (`exnum' == 1) local opts over(over)
	
	else if (`exnum' == 2) local opts over(over) bar(1,col(stc2)) 			///
												 bar(2,col(stc2*0.66)) 		///
												 bar(3,col(stc2*0.33))
	
	else if (`exnum' == 3) local opts grid(msym(O S D T) 					///
									  oncol(stc2 stc2 stc2 stc2))
	
	else if (`exnum' == 4) local opts int(ysc(off) ylab(none) ytit("")		///
										  xsc(off) blab(total, perc))		///
									  set(ysc(off) ylab(none) ytit("")		///
										  xsc(off) blab(total, perc))
	
	else if (`exnum' == 5) local opts int(ylab(0(100)500)) set(ylab(#3))
	
	else if (`exnum' == 6) local opts fillin sort(0000 -bitsum frequency)
	
	// Secret example for anyone snooping around my code
	// Repeating the first plot, but you're a huge fan of Damien Hirst
	
	else if (`exnum' == 7) local opts fillin sort(rand) int(off) set(off) 	///
							 grid(msize(vlarge vlarge vlarge vlarge) 		///
								  offcolor(stc1 stc6 stc7 stc10)			///
								  lcolor(none))
	
	preserve
	
	// Easier to just recreate the data than trying to find it
	
	clear
	
	set seed 12345
	qui set obs 1000

	local NATO Alfa Bravo Charlie Delta

	foreach i of local NATO {
			
		local iletter = strlower(substr("`i'", 1, 1))
		local iprob = runiform()
		
		qui gen `iletter' = rbinomial(1, `iprob')
		label variable `iletter' "`i'"
		
	}
	
	qui gen over = round(runiform(-0.5, 2.5))
	label variable over "Over variable"
	label define over 0 "Lower" 1 "Middle" 2 "Upper"
	label values over over
	
	upset_plot a b c d, `opts'
	
	restore
	
end
