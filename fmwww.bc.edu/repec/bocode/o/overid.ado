*! overid 3.0.0 25june2020
*! Authors C F Baum, Vince Wiggins, Steve Stillman, Mark Schaffer
* replaces overid 2.0.8, now renamed as overid9
* now serves as wrapper for overid9, xtoverid and underid

program define overid, rclass
	syntax [ , LIMLresid kp jgmm2s jcue j2lr j2l lr * ]
		
* Branching is to underid, overid9 or xtoverid.
* If caller is Stata 13.1 or above and estimator is supported by underid, branch to underid.
* If caller is Stata 13 or below, branch to either overid9 or xtoverid.
* If estimator is unsupported by underid, branch to either overid9 or xtoverid.

	local isxt	= (strpos(e(cmd),"xt")==1)

	if			"`e(cmd)'" == "reg3"		| 	/* unsupported by underid
		*/		"`e(cmd)'" == "ivprobit"	|	/*
		*/		"`e(cmd)'" == "ivtobit"		|	/*
		*/		"`e(cmd)'" == "ivreg29"		|	/*
		*/		"`e(cmd)'" == "ivreg3"		|	/*
		*/		{
					* overid9 is part of package, no need to check if installed
					overid9, `options'
					return add
				}
	else if		"`e(cmd)'" == "xtreg"			/* unsupported by underid
		*/		{
					cap noi xtoverid, `options'
					if _rc > 0 {
						di as err "Error: must have xtoverid installed"
						di as err "To install, from within Stata type " _c
						di in smcl "{stata ssc install xtoverid :ssc install xtoverid}"
						exit _rc
					}
					return add
				}
	else if _caller() < 13.1 & `isxt'			/* _caller(.) too low for underid and command is xt-type
		*/		{
					cap noi xtoverid, `options'
					if _rc > 0 {
						di as err "Error: command xtoverid required"
						di as err "To install, from within Stata type " _c
						di in smcl "{stata ssc install xtoverid :ssc install xtoverid}"
						exit _rc
					}
					return add
				}
	else if _caller() < 13.1 					/* _caller(.) too low for underid and command is not xt-type
		*/		{
					* overid9 is part of package, no need to check if installed
					overid9, `options'
					return add
				}
	else		{	
					cap underid, version
					if _rc > 0 {
						di as err "Error: command underid required"
						di as err "To install, from within Stata type " _c
						di in smcl "{stata ssc install underid :ssc install underid}"
						exit _rc
					}
					else {
						// check syntax - can choose only one
						local check			: word count `limlresid' `kp' `jgmm2s' `jcue' `j2lr' `j2l' `lr'
						// overid default is jgmm2s, whereas underid default is LIML resid (iid) or jcue (robust)
						if `check'==0 {
							// no statistic specified, so 2-step GMM is requested
							local rkstat	jgmm2s
						}
						else if `check'==1 {
							// if limlresid specified, rkstat macro will be empty (default)
							// if another test specified, rkstat macro will have it
							local rkstat	`kp' `jgmm2s' `jcue' `j2lr' `j2l' `lr'
						}
						else if `check'>1 {
							di as err "synax error: incompatible options "`limlresid' `kp' `jgmm2s' `jcue' `j2lr' `j2l' `lr'"
							exit 198
						}
						else {
							// should never reach here
							di as err "internal overid error"
							exit 198
						}

						underid, overid `rkstat' `options'
						return add
					}
				}

end

exit
