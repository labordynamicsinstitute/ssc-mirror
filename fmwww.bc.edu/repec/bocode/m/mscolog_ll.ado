program define mscolog_ll
	version 17
	local cutp = "$cutp"
	args lnf theta `cutp'

	quietly {
		forval i=1/$mxscale {
			replace `lnf' = exp(`c`i'_1'-`theta')/(1+exp(`c`i'_1'-`theta')) ///
				if $ML_samp==1 & _sc==`i' & ${ML_y`i'}==1
			if ${mxs`i'}>=3 {
				local k = ${mxs`i'}-1
				forval j=2/`k' {
					local l = `j'-1
					replace `lnf' = exp(`c`i'_`j''-`theta')/(1+exp(`c`i'_`j''-`theta')) ///
						- exp(`c`i'_`l''-`theta')/(1+exp(`c`i'_`l''-`theta')) if $ML_samp==1 & _sc==`i' & ${ML_y`i'}==`j'
				}
			}
			replace `lnf' = 1-exp(`c`i'_`k''-`theta')/(1+exp(`c`i'_`k''-`theta')) ///
				if $ML_samp==1 & _sc==`i' & ${ML_y`i'}==${mxs`i'}
		}
		replace `lnf' = ln(`lnf') if $ML_samp==1
	}
end
