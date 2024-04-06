********************************************************************************
* ratio_plot
********************************************************************************

program ratio_plot

version 11

syntax varlist(min=1 numeric)    	/// 
       [if]                      	/// 
	   [in],                    	///
	    Base(varname)    			///
	   [Over(varname)]    			///
	   [Title(string)]				///
	   [Sort]						///
	   [SCale]						///
	   [Graphopts(string asis)]  	

qui {	   
	   
	cap which coefplot
	if _rc == 111{
			
	display as err "	Sorry, this wrapper function requires the 'coefplot' package"
	display as err "	Prior to running this command, you need to run:" 
	display as err "	ssc install coefplot, replace"
	exit 198
}
	      	   	
* 	Temp files

	tempfile main
	save     `main', replace

* 	Sample indicator for mapping the [IF] [IN] conditions

	marksample touse, strok
	keep if `touse' == 1
	
	drop if missing(`varlist') | missing(`base')
	
* 	Locals	

	local p_title 	"Ratio graph" 
	local p_lab 	"#5"

	if "`title'" != "" {
   local p_title "`title'"
}

	if "`scale'" != "" {
   local p_lab "0(.2)1" 
}

	if "`over'" == "" {

	ratio `varlist'/ `base'

	scalar myratio = 			e(b)[1,1]
	scalar variance = 			e(V)[1,1]
	scalar st_error = 			sqrt(variance)
	scalar dof = 				e(df_r) 

	matrix R = 				(myratio, st_error, dof)
	mat  R = R'
	matrix colnames R = "Estimated Ratio"

	global call "(matrix(R), se(2) df(R[3,.]))"

}

	if "`over'" != "" {
	
	decode `over', 			gen(ratio_temp_var)
	encode ratio_temp_var, 	gen(ratio_temp_var2)

	global call
	
	ratio `varlist'/ `base', over(ratio_temp_var2)
	
	levelsof ratio_temp_var2, local(levels)

	foreach l of local levels {

	scalar myratio = 			e(b)[1,`l']
	scalar variance = 			e(V)[`l',`l']
	scalar st_error = 			sqrt(variance)
	scalar dof = 				e(df_r)
	
	local cat_obs = 			e(_N)[1,`l']

	matrix R`l' = 				(myratio, st_error, dof)
	mat  R`l' = R`l''    

    local c_label: label (ratio_temp_var2) `l'		
	local n_label = "`c_label' (n = `cat_obs')"

	matrix colnames R`l' = "`n_label'"
	
	global call "$call (matrix(R`l'), se(2) df(R[3,.]))"

}

}
	
	ratio `varlist'/ `base'
	scalar overall_ratio = 		e(b)[1,1]
	local rounded_ratio = 		round(overall_ratio, 0.01) 
	local obs =  				e(N)
	
	coefplot $call,   `sort'         		///
	ciopts(recast(rcap))                 	///
	title("`p_title'",  size(medium)) 		///
	subtitle("Overall ratio = `rounded_ratio', N = `obs'", size(small))    ///
	xlab(`p_lab')                      		///
	mlabel                              	///
	format(%9.2f)                       	///
	mlabposition(12)                    	///
	legend(off)								///
	`graphopts'     

	macro drop call

	use `main', clear
}	
end


