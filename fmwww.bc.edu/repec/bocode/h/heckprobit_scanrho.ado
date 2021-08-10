*!  version 1.0.0 01jun2020

program  heckprobit_scanrho, eclass
    version 11
	
	syntax varlist(numeric default=none ts fv) [if] [in], SELect(string) [minrho(real -.9) maxrho(real .9) step(real .1) Robust vce(string) DIFficult TOLerance(real 1e-6) LTOLerance(real 1e-7) NRTOLerance(real 1e-5) SHOWTOLerance nolog level(cilevel) NOGraph]

	local maxopts `difficult' tol(`tolerance') 	`showtolerance'	`nolog'	 ///
	  ltol(`ltolerance') nrtol(`nrtolerance')
	
	preserve

	tempvar list_rho list_ll
	local beginning = `minrho' 
	matrix `list_rho' = `beginning'
	qui heckprobit_fixedrho `varlist' `if' `in', sel(`select') rho(`beginning')
    matrix `list_ll' = e(ll)
	di as text "Performing estimation for each value of rho..."
	forval i = `minrho'(`step')`maxrho' {
		matrix `list_rho' = `list_rho' \ `i'
        qui heckprobit_fixedrho `varlist' `if' `in', sel(`select') rho(`i') `maxopts'
        matrix `list_ll' = `list_ll' \ e(ll)
    }
	
	
	capture matrix drop ind31415
	matrix ind31415 = 0
	mata: get_location(st_matrix("`list_ll'"))
	capture scalar drop val31415
    scalar val31415 = ind31415[1,1]	
	
	svmat `list_rho'
    svmat `list_ll'
	
	local max_rho = `list_rho'[val31415]
	local max_ll = `list_ll'[val31415]
	qui gen Maximum = `max_ll' in 1
	qui gen max_rho_value = `max_rho' in 1	
	
	label variable `list_ll' "Log Likelihood"
	
	if "`nograph'" == "" {
		line `list_ll' `list_rho', ytitle("Log Likelihood Value") xtitle("Rho") || scatter Maximum max_rho_value
	}
	

	heckprobit_fixedrho `varlist' `if' `in', sel(`select') rho(`max_rho') level(`level') `maxopts'
	
	* Return values for init
	tempvar init_values athrho
	scalar `athrho' = 0.5 * log((1+`max_rho') / /*
				*/ (1-`max_rho'))
	matrix `init_values' = e(b) 
	matrix `init_values' = `init_values' , `athrho'
	local eb_names: colnames `init_values'
	tokenize `"`eb_names'"'
	local n= wordcount("`eb_names'")
	local m `=`n'-1'
	forval n1=1/`m' {
		local new_eb "`new_eb' ``n1''"
	}
	local new_eb "`new_eb' athrho"
	matrix colnames `init_values' = `new_eb'
	ereturn matrix init_values = `init_values'
	
	restore
	
end


mata:
function get_location(vlist_in)
{
	maxindex(vlist_in, 1, i, w)
	st_replacematrix("ind31415",i)
}
end
