*! version 1.0.0
*! Panel Data SFA Model Components Program 
*! for the Command xtnondynthreshsfa
*! Diallo Ibrahima Amadou
*! All comments are welcome, 25Apr2024



capture program drop xtnondynthreshsfacomps
program xtnondynthreshsfacomps, sortpreserve
	version 17.0
    if "`e(cmd)'" != "xtreg" {
		error 301
	}		
	syntax, STUB(string)
	quietly predict double fe_`stub' if e(sample), u 
	quietly summarize fe_`stub' if e(sample)
	generate double Inefficiency_`stub' = r(max) - fe_`stub' if e(sample)  
	generate double Efficiency_`stub' = exp(-Inefficiency_`stub') if e(sample) 	
	quietly drop fe_`stub'
	quietly label var Inefficiency_`stub' "Time-Invariant Technical Inefficiency"
	quietly label var Efficiency_`stub'   "Individual-Specific Efficiency"
	
end


