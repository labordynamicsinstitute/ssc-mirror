*! Xia P.S. : xia_ps@yeah.net
*! Version 1.0: October 1st, 2021

program define autofill
	version 12
	syntax varlist [, forward backward groupby(varname)]
	if ("`forward'"==""&"`backward'"==""){
		display in red "The option 'forward' or 'backward' is required."
		exit
	}
	if ("`forward'"!=""&"`backward'"!=""){
		display in red "You can only choose one of the options 'forward' and 'backward'."
		exit
	}
	local Num=_N
	local changenum=0
	
	// fill the missing value backward
	if "`backward'"!=""{
		foreach var0 in `varlist'{
			local value0=""
			local groupby0=""
			forvalues i =1(1)`Num'{
				// no group
				if "`groupby'"==""{
					if missing(`var0'[`i']){
						if "`value0'"!=""{
							quietly replace `var0'=`value0' in `i'
							local changenum=`changenum'+1
						}
					}
					else{
						local value0=`var0'[`i']
					}
				}
				// group
				else {
					if "`groupby0'"!=string(`groupby'[`i']){
						local groupby0=`groupby'[`i']
						if missing(`var0'[`i']){
						}
						else{
							local value0=`var0'[`i']
						}
					}
					else{
						if missing(`var0'[`i']){
							if "`value0'"!=""{
								quietly replace `var0'=`value0' in `i'
								local changenum=`changenum'+1
							}
						}
						else{
							local value0=`var0'[`i']
						}
					}
				}
			}
		}
	}
	
	// fill the missing value forward
	if "`forward'"!=""{
		foreach var0 in `varlist'{
			local value0=""
			local groupby0=""
			forvalues i =`Num'(-1)1{
				// no group
				if "`groupby'"==""{
					if missing(`var0'[`i']){
						if "`value0'"!=""{
							quietly replace `var0'=`value0' in `i'
							local changenum=`changenum'+1
						}
					}
					else{
						local value0=`var0'[`i']
					}
				}
				// group
				else {
					if "`groupby0'"!=string(`groupby'[`i']){
						local groupby0=`groupby'[`i']
						if missing(`var0'[`i']){
						}
						else{
							local value0=`var0'[`i']
						}
					}
					else{
						if missing(`var0'[`i']){
							if "`value0'"!=""{
								quietly replace `var0'=`value0' in `i'
								local changenum=`changenum'+1
							}
						}
						else{
							local value0=`var0'[`i']
						}
					}
				}
			}
		}
	}
	
	dis "(`changenum' missing value filled)"
end