*! 1.0.0 Ariel Linden 11Nov2022

capture program drop power_cmd_tworoc
program power_cmd_tworoc, rclass
	
version 11.0
	
	
        /* obtain settings */
		syntax anything(id="numlist"),	///
			[ Alpha(real 0.05) 		/// significance level
			n(string) 				/// total sample size
			n1(string) n0(string) 	/// group sample sizes (n1 = diseased; n0 = non-diseased)
			ratio(real 1)			/// ratio N0 (non-diseased) / N1 (diseased)
			Power(string)  			///
			ONESIDed				///
			HANley					/// uses Hanley & McNeil formula for variance; default is Obuchowski formula
			corr(real 0)			/// correlation between auc1 and auc2
			]						///

			gettoken auc0 rest : anything
			gettoken auc1 rest : rest
			gettoken auc2 rest : rest
			
			numlist "`anything'", min(3) max(3)
			local variable_tally : word count `anything'
			
			if `auc0' < 0.50 | `auc0' > 1.0 { 
				di as err "auc0 must contain numbers between 0.50 and 1.0"
				exit 198
			}
			
			if `auc1' < 0.50 | `auc1' > 1.0 { 
				di as err "auc1 must contain numbers between 0.50 and 1.0"
				exit 198
			}
			
			if `auc2' < 0.50 | `auc2' > 1.0 { 
				di as err "auc2 must contain numbers between 0.50 and 1.0"
				exit 198
			}
			
			// set default test type to "twosided"  
			if "`onesided'" == "" {
				local test = `alpha'/ 2
			}
			else local test = `alpha'

			*******************************
			**** compute sample size ******
			*******************************
			if (`"`n'`n1'`n0'"' == "") {
				tempname zalpha zbeta delta A0 v0 A1 v1 A2 v2 c2 n1 n0 n q1_0 q2_0 q1_1 q2_1 q1_2 q2_2
				scalar `zalpha' = invnorm(1-`test')
				scalar `zbeta' = invnorm(`power')
				scalar `delta' = abs(`auc1' - `auc2')
				
				if "`hanley'" =="" { 
					scalar `A0' = invnorm(`auc0') * 1.414
					scalar `v0' = (0.0099 * exp(-`A0'^2 / 2)) * ((5 * `A0'^2 + 8) + (`A0'^2 + 8) / `ratio')
					scalar `A1' = invnorm(`auc1') * 1.414
					scalar `v1' = (0.0099 * exp(-`A1'^2 / 2)) * ((5 * `A1'^2 + 8) + (`A1'^2 + 8) / `ratio')
					scalar `A2' = invnorm(`auc2') * 1.414
					scalar `v2' = (0.0099 * exp(-`A2'^2 / 2)) * ((5 * `A2'^2 + 8) + (`A2'^2 + 8) / `ratio')
				} // end Hanley
				else {
					scalar `q1_0' = `auc0' / (2 - `auc0')
					scalar `q2_0' = 2 * (`auc0'^2) / (1 + `auc0') 
					scalar `q1_1' = `auc1' / (2 - `auc1')
					scalar `q2_1' = 2 * (`auc1'^2) / (1 + `auc1')
					scalar `q1_2' = `auc2' / (2 - `auc2')
					scalar `q2_2' = 2 * (`auc2'^2) / (1 + `auc2')
					scalar `v0' = `q1_0' / `ratio' + `q2_0' - `auc0'^2 * (1 /`ratio' + 1) 
					scalar `v1' = `q1_1' / `ratio' + `q2_1' - `auc1'^2 * (1 /`ratio' + 1)
					scalar `v2' = `q1_2' / `ratio' + `q2_2' - `auc2'^2 * (1 /`ratio' + 1)
				} // end Obuchowski
				
				* sample-size formula
				scalar `n1' = ceil((`zalpha' * sqrt(`v0' + `v0' - 2 * `corr' * sqrt(`v0') * sqrt(`v0')) + `zbeta' * sqrt(`v1' + `v2' - 2 * `corr' * sqrt(`v1') * sqrt(`v2')))^2 /  `delta'^2)
				
				scalar `n0' = ceil(`n1' * `ratio')
				scalar `n' = `n1' + `n0'
			} // end sample size
	
			*************************
			**** compute power ******
			*************************
			else if (`"`n'`n1'`n0'"' != "") {	
				
				//complete sample-size specifications
				if (`"`n'"'=="") {
					tempname n
					if (`"`n0'"'=="") {
					tempname n0
					scalar `n0' = ceil(`ratio'*`n1')
					}
					else if (`"`n1'"'=="") {
						tempname n1
						scalar `n1' = ceil(`n0'/`ratio')
					}
					scalar `n' = `n1'+`n0'
					local ratio = `n0'/`n1'
				} // end n == ""
				else {
					if (`"`n1'"'!="") {
						tempname n0
						scalar `n0' = `n' - `n1'
					}
					else if (`"`n0'"'!="") {
						tempname n1
						scalar `n1' = `n' - `n0'
					}
					else {
						tempname n1 n0
						scalar `n1' = ceil(`n'/(1 + `ratio'))
						scalar `n0' = `n'-`n1'
					}
				} // end sample-size specifications
				
				tempname zalpha A0 v0 delta A1 v1 A2 v2 power q1_0 q2_0 q1_1 q2_1 q1_2 q2_2
				
				scalar `zalpha' = invnorm(1-`test')
				scalar `delta' = abs(`auc1' - `auc2')
			
				if "`hanley'" =="" { 
					scalar `A0' = invnorm(`auc0') * 1.414
					scalar `v0' = (0.0099 * exp(-`A0'^2 / 2)) * ((5 * `A0'^2 + 8) + (`A0'^2 + 8) / `ratio')
					scalar `A1' = invnorm(`auc1') * 1.414
					scalar `v1' = (0.0099 * exp(-`A1'^2 / 2)) * ((5 * `A1'^2 + 8) + (`A1'^2 + 8) / `ratio')
					scalar `A2' = invnorm(`auc2') * 1.414
					scalar `v2' = (0.0099 * exp(-`A2'^2 / 2)) * ((5 * `A2'^2 + 8) + (`A2'^2 + 8) / `ratio')
				} // end Hanley
				else {
					scalar `q1_0' = `auc0' / (2 - `auc0')
					scalar `q2_0' = 2 * (`auc0'^2) / (1 + `auc0') 
					scalar `q1_1' = `auc1' / (2 - `auc1')
					scalar `q2_1' = 2 * (`auc1'^2) / (1 + `auc1')
					scalar `q1_2' = `auc2' / (2 - `auc2')
					scalar `q2_2' = 2 * (`auc2'^2) / (1 + `auc2')
					scalar `v0' = `q1_0' / `ratio' + `q2_0' - `auc0'^2 * (1 /`ratio' + 1) 
					scalar `v1' = `q1_1' / `ratio' + `q2_1' - `auc1'^2 * (1 /`ratio' + 1)
					scalar `v2' = `q1_2' / `ratio' + `q2_2' - `auc2'^2 * (1 /`ratio' + 1)
				} // end Obuchowski
					
			* Reorganized sample size formula to get power				
			scalar `power' = normal((sqrt(`n1' * `delta'^2) - `zalpha' * sqrt(`v0' + `v0' - 2 * `corr' * sqrt(`v0') * sqrt(`v0'))) / sqrt(`v1' + `v2' - 2 * `corr' * sqrt(`v1') * sqrt(`v2')))

			} // end power
		
			// saved results
			return scalar N = `n'
			return scalar N1 = `n1'
			return scalar N0 = `n0'
			return scalar alpha = `alpha'
			return scalar power = `power'
			return scalar auc2 = `auc2'
			return scalar auc1 = `auc1'
			return scalar auc0 = `auc0'
			return scalar delta = `delta'
			return scalar ratio = `ratio'
			return scalar corr = `corr'
			return scalar V2 = `v2'
			return scalar V1 = `v1'
			return scalar V0 = `v0'
		
end
