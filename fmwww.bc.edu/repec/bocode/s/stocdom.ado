*! version v1.0 14 March 2024
*! Alejandro Ome (alejandro.ome@gmail.com)
*! Treatment effect bounds assuming stochastic dominance


program define stocdom, rclass
version 18.0

tempvar panel valid_sample0 id_temp0 valid_sample1 id_temp1

qui {
gen byte `panel' = `1' !=.


**Lower bound: 


	*Lower bound for Treatment group

	sum `1' if `2' == 1
	 
	local y1=r(mean)


	*Upper bound for Control group: In this case the max of defiers is the fraction of the treatment that is not observed (Assumes there are no Nevers)

	gen `valid_sample0'=`1'!=. & `2' == 0

	gsort -`valid_sample0' `1'

	gen `id_temp0'=_n if `valid_sample0'==1


	tabstat `panel' ,  by(`2') save
	tabstatmat panels


	sum `2' if `2'==0
	local p = (1 - panels[2,1] )*`r(N)'


	display `p'


	replace `valid_sample0' = . if `id_temp0'<=`p'

	sum `1' if `2'==0 & `valid_sample0'==1
	local y0=r(mean)


	local lower_imp = `y1' - `y0'

	display `lower_imp'




**Upper bound: 

			

	*Upper bound for Treatment group

	gen `valid_sample1'=`1'!=. & `2'==1
	gsort -`valid_sample1' `1'
	gen `id_temp1'=_n if `valid_sample1'==1

	sum `2' if `2'==1
	local p = (1 - panels[1,1] )*`r(N)'


	display `p'


	replace `valid_sample1' = . if `id_temp1'<=`p'

	sum `1' if `2'==1 & `valid_sample1'==1
	local y1=r(mean)


	*Lower bound for C: Mean Y of Always is at least as high as Defiers' so mean Y of always is mean of all Control


	sum `1' if `2'==0
	local y0=r(mean)



	local upper_imp = `y1' - `y0'

	display `upper_imp'


mat temp=( `lower_imp' , `upper_imp' )
mat colnames temp = lower upper

tempname bb


matrix `bb'=temp



ereturn post `bb'


}

matlist temp

end
