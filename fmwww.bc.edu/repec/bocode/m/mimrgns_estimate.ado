*! version 2.1.1 07apr2017 daniel klein
program mimrgns_estimate , eclass properties(mi)
	version 11.2
	
	/*
		mimrgns_work.class passes a handle */
		
	syntax name(name = mh id = "mimrgns handle")
	
	capture assert ("`mh'" == "`.`mh'.myname'")
	if (_rc) {
		display as err "invalid mimrgns handle `mh'"
		exit 101
	}
	
	.`mh'.est_number = (`.`mh'.est_number' + 1)
	
	if (!`.`mh'.is_verbose')  {
		local quietly quietly
	}
	
	if (`"`.`mh'.using'"' != "") {
		/* using syntax
			we get results from .ster file */
			
		`quietly' estimates use `"`.`mh'.using'"' , number(`.`mh'.est_number')
		quietly estimates esample : if `.`mh'.esample'
	}
	else {
		/* not using
			we run previous estimation command */
			
		`quietly' display _newline ///
			`"{inp}. `.`mh'.caller' `quietly' `.`mh'.cmdline_mi'{sf}"'
		
		`.`mh'.caller' `quietly' `.`mh'.cmdline_mi'
	}
	
	/*
		collect additional r() matrices */
		
	_return restore `.`mh'.rr'
	foreach name in b_vs V_vs error_vs at {
		tempname `name'_mi
		local matnames `matnames' `name'
		local tmpnames `tmpnames' ``name'_mi'
	}
	
	if (`.`mh'.est_number' > 1) {
		mimrgns_estimate_get_matrices "`matnames'" "`tmpnames'"
	}
	
	/*
		now we run margins */
	
	`quietly' display _newline ///
		`"{inp}. `.`mh'.caller' margins `.`mh'.margins_call'{sf}"'
	
	`.`mh'.caller' margins `.`mh'.margins_call'
	
	/*
		update additional r() matrices */
		
	mimrgns_estimate_set_matrices "`matnames'" "`tmpnames'" `.`mh'.est_number'	
	_return hold `.`mh'.rr'
end

program mimrgns_estimate_get_matrices
	version 11.2
	
	args matnames tmpnames
	
	foreach mat of local matnames {
		gettoken tmp tmpnames : tmpnames
		if ("`r(`mat')'" == "matrix") {
			matrix `tmp' = r(`mat'_mi)
		}
	}
end

program mimrgns_estimate_set_matrices
	version 11.2
	
	args matnames tmpnames update
	
	foreach mat of local matnames {
		gettoken tmp tmpnames : tmpnames
		if ("`r(`mat')'" != "matrix") {
			continue
		}
		if (`update' > 1) {
			if ("`mat'" == "b_vs") {
				matrix `tmp' = (`tmp'\ r(`mat'))
			}
			else {
				matrix `tmp' = `tmp' + r(`mat')
			}
		}
		else {
			matrix `tmp' = r(`mat')
		}
		mata : st_matrix("r(`mat'_mi)", st_matrix("`tmp'"))
	}
end
exit

2.1.1	07apr2017	display command lines with option verbose
2.1.0	03nov2016	additionally collect r(at) matrix
2.0.0	28jun2016	support estimation results from ster-file
					verbose output if requested
					code polish
1.0.2	14mar2016	declare version 11 in subroutines 
					(never released)
1.0.1 	02jul2015 	better error message for invalid handle
1.0.0 	02jul2015	first release on SSC
