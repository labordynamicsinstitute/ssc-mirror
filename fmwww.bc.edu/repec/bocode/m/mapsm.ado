*! version 1.3 2May2024
***Suppachai Lawanaskol, MD***
***Phichayut Phinyo, MD, PhD***
***Jayanton Patumanond, MD, DSc***
program define mapsm, rclass
	version 16.0
	syntax varlist(min=1 max=10 numeric) [, GRoup(varlist fv) Seed(int 1234) Name(string) SIze(int 10) SMD(string asis) ITerate(int 0) REPLACE NOTABle Log APpend]
	
	**Check the arms are equal to the predicted probability from the propensity score model**
	qui tab `group'
	scalar n_group=r(r)
	if `=scalar(n_group)'!=`: word count `varlist'' & `=scalar(n_group)'>2{
		di as error "The number of propensity score variables are not equal to the number of treatment arms"
	}
	
	**Define the default**
	
	if "`name'"==""{
		local name strata
	}
	
	**Replace the previous strata variable**
	
	if "`replace'"!=""{
		capture drop `name'
	}
	
	**If Iteration option was selected, SMD should be specify,and should identical to the propensity score model**
	
	if `iterate'>0 & "`smd'"==""{
		di as error "Please identify the pre-treament confounder"
	}
	if `iterate'>0 & `seed'==1234{
		di in yellow "The iteration process start at initial seeding number of 1234"
	}
	if "`group'"==""{
		di as error "Please specify the treatment arms"
	}
	if `iterate'>0{
		di in yellow "The iteration round was set to `iterate'"
	}
	
	**Define the step**
	
	qui generate `name'=""
	scalar step=1/`size'
	
	**Pre-matching diagnostic SMD Mean / SMD Max**
	
	qui tab `group'
	scalar arms=r(r)-1
	
	**Two treament arms**
	
	if "`smd'"!="" & `=scalar(arms)'==1 {
		scalar std_accum=0
		qui stddiff `smd',by(`group')
		forvalues e=1/`=rowsof(r(stddiff))'{
			scalar std_accum=`=scalar(std_accum)'+abs(r(stddiff)[`e',1])
		}
		scalar std_represent=`=scalar(std_accum)'/`=rowsof(r(stddiff))'
		
		**Show iteration log**
		
		if "`log'"!=""{
			di in green "Pre match SMD Mean = " in yellow `=scalar(std_represent)'
		}
	}
	
	**More than two treament arms**
	
	else if "`smd'"!="" & `=scalar(arms)'>1{
		capture drop `group'_*
		qui tab `group',gen(`group'_)
		scalar std_max=0
		forvalues i=0/`=scalar(arms)'{
			forvalues j=1/`=scalar(arms)'{
				if `i'<`j'{
					qui stddiff `smd' if `group'==`i' | `group'==`j',by(`group') abs
					forvalues k=1/`=rowsof(r(stddiff))'{
						scalar std_max=max(`=scalar(std_max)',abs(r(stddiff)[`k',1]))
					}
				}
			}
		}
		scalar std_represent=`=scalar(std_max)'
		if "`log'"!=""{
			di in green "Pre match SMD Max = " in yellow `=scalar(std_represent)'
		}

	}
	
	**Alarm the too multiple groups**
	if `=scalar(arms)'>4{
		display "More than four multiple arms matching resulting in the low power of postmatch cohort"
	}
	
	**Generate strata pattern from predict probability**
	
	foreach pred_var in `varlist' {
		qui capture drop `pred_var'_cut
		qui egen `pred_var'_cut=cut(`pred_var'),at(0(`=scalar(step)')1)
		qui capture drop `pred_var'_int
		qui gen `pred_var'_int=`pred_var'_cut*`size'
		qui tostring `pred_var'_int,replace
		qui replace `name'=`name'+`pred_var'_int
	}
	qui destring `name',replace
	
	**Define scalar in the matching process**
	
	scalar seed=`seed'
	scalar n=_N
	qui tab `group'
	scalar arms=r(r)-1
	qui tab `name',matrow(s)
	qui mat li s
	scalar pattern=r(r)
	
	**Show the strata tabulation across treament groups** 
	if "`notable'"==""{
		tab `name' `group'
	} 
	scalar seed_final=`=scalar(seed)'+`iterate'-1
	
	**Iteration**
	
	if `iterate'>0{
		
		**Define the Matrix that contain seed and fitting value for each seed**
		
		mat def I=J(`iterate',2,.)
		forvalues h=`=scalar(seed)'/`=scalar(seed_final)'{
			if "`log'"==""{
				_dots `=scalar(seed_final)'-`h' 0
			}
			preserve
			forvalues p=0/`=scalar(pattern)'{
				scalar min=`=scalar(n)'
				forvalues a=0/`=scalar(arms)'{
					qui count if `name'==s[`p',1] & `group'==`a'
					scalar n_`a'=r(N)
					qui scalar min="`=scalar(min)'"+","+"`=scalar(n_`a')'"
				}
				scalar min_num=min(`=scalar(min)')
				forvalues a=0/`=scalar(arms)'{
					set seed `h'
					qui sample `=scalar(min_num)' if `name'==s[`p',1] & `group'==`a',count
				}
			}
			
			**Post matching diagnostic SMD/SMD Max**
			
			qui tab `group'
			scalar arms=r(r)-1
			
			**Two treament arms**
			
			if "`smd'"!="" & `=scalar(arms)'==1 {
				qui stddiff `smd',by(`group')
				
				**STDDIFF mean**
				
				scalar std_accum=0
				forvalues e=1/`=rowsof(r(stddiff))'{
					scalar std_accum=`=scalar(std_accum)'+abs(r(stddiff)[`e',1])
				}
				scalar std_represent=`=scalar(std_accum)'/`=rowsof(r(stddiff))'
			}
			
			**More than two treament arms**
			
			else if "`smd'"!="" & `=scalar(arms)'>1{
				
				**pairwise STDDIFF MAX**
				
				capture drop `group'_*
				qui tab `group',gen(`group'_)
				scalar std_max=0
				forvalues i=0/`=scalar(arms)'{
					forvalues j=1/`=scalar(arms)'{
						if `i'<`j'{
							qui stddiff `smd' if `group'==`i' | `group'==`j',by(`group')
							forvalues k=1/`=rowsof(r(stddiff))'{
								scalar std_max=max(`=scalar(std_max)',abs(r(stddiff)[`k',1]))
							}
						}
					}
				}
				scalar std_represent=`=scalar(std_max)'
			}
			restore
			
			**Report the seed in the first column and fitting value in the second column**
			
			scalar iterate=`h'-`=scalar(seed)'+1
			qui mat I[`=scalar(iterate)',1]=`=scalar(iterate)'
			qui mat I[`=scalar(iterate)',2]=`=scalar(std_represent)'
			
			**Tabulation should be quite if iterate**
			
			if "`smd'"!="" & `=scalar(arms)'==1 {
				**Show iteration log**
				if "`log'"!=""{
					di in green "SMD Mean at seed `h' =" in yellow %9.6f `=scalar(std_represent)'
				}
			}
			else if "`smd'"!="" & `=scalar(arms)'>1{
				**Show iteration log**
				if "`log'"!=""{
					di in green "SMD Max at seed `h' =" in yellow %9.6f `=scalar(std_represent)'
				}
			}
			
		}		
		
		**Extract maximum SMD_max/SMD and report the iteration seed**
		
		scalar fittest_value=1
		forvalues m=1/`iterate'{
			scalar fittest_value=min(`=scalar(fittest_value)',I[`m',2])
		}
		
		**Display the smallest mean/maximum pairwise SMD**
		
		di ""
		if `=scalar(arms)'==1{
			di in green "Smallest mean pairwise SMD" _col(28)"=" in yellow _col(30) %6.4f `=scalar(fittest_value)'
		}
		else if `=scalar(arms)'>1{
			di in green "Smallest maximum pairwise SMD" _col(31)"=" in yellow _col(33) %6.4f `=scalar(fittest_value)'
		}
		
		forvalues m=1/`iterate'{
			if `=scalar(fittest_value)'==I[`m',2]{
				scalar fittest_seed=`m'+`=scalar(seed)'-1
			}
		}
		
		**Display the best seed number**
		
		di ""
		if `=scalar(arms)'==1{
			di in green "Best seed number" _col(28)"=" in yellow _col(30) `=scalar(fittest_seed)'
		}
		else if `=scalar(arms)'>1{
			di in green "Best seed number" _col(31)"=" in yellow _col(33) `=scalar(fittest_seed)'
		}
			
		return matrix I I
	}
	else if `iterate'==0{
		
	**Simple Matching without iteration**
	**Keep the original data**
		if "`append'"!=""{
			qui save "`c(pwd)'\prematched.dta", replace
		}
		**Actual matching**
		forvalues p=0/`=scalar(pattern)'{
			scalar min=`=scalar(n)'
			forvalues a=0/`=scalar(arms)'{
				qui count if `name'==s[`p',1] & `group'==`a'
				scalar n_`a'=r(N)
				qui scalar min="`=scalar(min)'"+","+"`=scalar(n_`a')'"
			}
			scalar min_num=min(`=scalar(min)')
			forvalues a=0/`=scalar(arms)'{
				set seed `=scalar(seed)'
				qui sample `=scalar(min_num)' if `name'==s[`p',1] & `group'==`a',count
			}
		}
	
		
		**Post matching diagnostic SMD/SMD Max**
		
		qui tab `group'
		scalar arms=r(r)-1
		
		**Two treament arms**
		
		if "`smd'"!="" & `=scalar(arms)'==1 {
			qui stddiff `smd',by(`group')
			
			**STDDIFF mean**
				
			scalar std_accum=0
			forvalues e=1/`=rowsof(r(stddiff))'{
					scalar std_accum=`=scalar(std_accum)'+abs(r(stddiff)[`e',1])
			}
			scalar std_represent=`=scalar(std_accum)'/`=rowsof(r(stddiff))'
			**Show iteration log**
			if "`log'"!=""{
				di ""  
				di in green "Post match SMD Mean = " in yellow `=scalar(std_represent)'
			}
		}
		
		**More than two treament arms**
		
		else if "`smd'"!="" & `=scalar(arms)'>1{
			capture drop `group'_*
			qui tab `group',gen(`group'_)
			scalar std_max=0
			forvalues i=0/`=scalar(arms)'{
				forvalues j=1/`=scalar(arms)'{
					if `i'<`j'{
						qui stddiff `smd' if `group'==`i' | `group'==`j',by(`group')
						forvalues k=1/`=rowsof(r(stddiff))'{
							scalar std_max=max(`=scalar(std_max)',abs(r(stddiff)[`k',1]))
						}
					}
				}
			}
			scalar std_represent=`=scalar(std_max)'
			**Show iteration log**
			if "`log'"!=""{
				di ""  
				di in green "Post match SMD Max = " in yellow `=scalar(std_represent)'
			}
		}
		if "`notable'"==""{
			tab `name' `group'
		} 
	}
if "`smd'"!=""{
	return scalar smallest=`=scalar(std_represent)'
}
if "`append'"!=""{
	append using "`c(pwd)'\prematched.dta",generate(append)
	display "The original cohort was kept and appended next to the last observations of matched cohort"
	erase prematched.dta
}
return scalar seed=`=scalar(seed)'
return scalar size=`size'
return local name `strata'
return local group `group'
end