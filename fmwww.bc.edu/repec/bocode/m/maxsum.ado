*! 1.0.0 Ariel Linden 30Oct2023

program define maxsum, rclass byable(recall)
version 11.0

		syntax anything [if][in]
		
		tokenize `anything'
		marksample touse
		
		tempname madmax total
		quietly {
			gen `madmax' = `anything' if `touse'
			sum `madmax' if `touse'
			scalar `total' = r(sum)
		}
		di _n
		di as txt "   Maximum value of the running-sum for [`anything']: " as result %-14.2fc `total' 
		
		return scalar maxsum = `total'
		
end		