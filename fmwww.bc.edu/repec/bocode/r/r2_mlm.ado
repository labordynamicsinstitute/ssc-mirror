program r2_mlm, rclass sortpreserve
	version 17
	syntax [, ]
	if "`e(cmd)'" != "mixed" {
		di as err "r2_mlm can only be used with models estimated by the {help mixed:mixed} command."
	}
	else if mi("`e(N_g)'") {
		di as err "r2_mlm cannot be used with single-level models."
	}
	else if strpos("`e(cmdline)'","R.") != 0 {
		di as err "r2_mlm cannot currently be used with cross-classified models."
	}
	else {
		loc nlevels = colsof(e(N_g))+1
		//TWO-LEVEL
		if `nlevels' == 2 {
			r2_mlm_2L
		}
		//THREE-LEVEL
		else if `nlevels' == 3 {
			r2_mlm_3L
		}
		//FOUR-LEVEL
		else if `nlevels' == 4 {
			r2_mlm_4L
		}
		//FIVE-LEVEL
		else if `nlevels' == 5 {
			r2_mlm_5L
		}
		else if `nlevels' > 5 {
			di as err "r2_mlm cannot currently be used with models containing more than 5 levels."
		}
		return add
	}
end
exit