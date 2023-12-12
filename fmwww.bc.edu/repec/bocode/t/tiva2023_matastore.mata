mata:
	void tiva2023::_checkClear(| string scalar clear) {

		stata("capture sysuse cancer")
		stata("local error = _rc")
		error = st_local("error")
		if (error == "4" & clear == "") stata("error 4") 

		stata("clear")
		
	/* 	stata("clear") */
	/* 	st_addobs(T*rows(result)) */
	/* if (rows(result) == N * K) { */
	/* 		st_addvar("str10", ("year", "cou", "ind")) */
	/* 		st_sstore(., ("year", "cou", "ind"), year_cou_ind) */
	/* 		st_addvar("double", "toKeep") */
	/* 		} */
		}

	void tiva2023::_initStorage(real matrix input, | string scalar ccc) {
		st_addobs(T * N * K)
		st_addvar("str10", ("year", "cou", "ind"))
		st_sstore(., ("year", "cou", "ind"), year_cou_ind)
		st_addvar("double", "toKeep")

		}

	string rowvector tiva2023::_storeIndicator(string scalar indicator, real matrix result, | string scalar ppp) {

		if (cols(result) == N) indicator_name = indicator :+ "_" :+ cou'
		
		else if (cols(result) == 1) {
			if (ppp == "") indicator_name = indicator
			else indicator_name =  indicator :+ "_" :+ ppp
			}
		
		else if (regexm(indicator, "MY")) {
			if (ppp == "") indicator_name = indicator :+ "_" :+ ("DVA", "DDC", "FVA", "FDC")
			else indicator_name = indicator :+ "_" :+ ("DVA", "DDC", "FVA", "FDC") :+ "_" :+ ppp
			}

		st_addvar("double", indicator_name)
		printf("type: %s %s \n", orgtype(indicator_name), eltype(indicator_name))
		return(indicator_name)
		
		}

	void tiva2023::_storeResult(string rowvector indicator_name, real matrix result, real scalar t, | string scalar ccc) {

		real colvector which_year_cou

		if (ccc == "") which_year_cou = selectindex(year_cou_ind[, 1] :== strofreal(t))
		else which_year_cou = selectindex(year_cou_ind[, 1] :== strofreal(t) :& year_cou_ind[, 2] :== ccc)

		st_store(which_year_cou, "toKeep", J(rows(result), 1, 1))
		st_store(which_year_cou, indicator_name, result)
		}
end


