*! 1.0.1 Ariel Linden 04Dec2023 // added format option
*! 1.0.0 Ariel Linden 30Oct2023

program define maxsum, rclass byable(recall)
version 11.0

		syntax anything [if][in], [ Format(string) ]
		
		tokenize `anything'
		marksample touse
		
		tempname madmax total
		quietly {
			gen `madmax' = `anything' if `touse'
			sum `madmax' if `touse'
			scalar `total' = r(sum)
		}
		
        /* format numeric maxsum value */
        if "`format'" != "" { 
            confirm numeric format `format' 
            local fmt "`format'" 
        } 
        else local fmt "%-14.2fc" 
		
		
		di _n
		di as txt "   Maximum value of the running-sum for [`anything']: " as result `fmt' `total' 
		
		return scalar maxsum = `total'
		
end		

