program mlmr2, rclass sortpreserve
	version 17
	syntax [, ]
	if "`e(cmd)'" != "mixed" {
		error 301
	}
	loc nlevels = colsof(e(N_g))+1
	//TWO-LEVEL
	if `nlevels'==2 {
		mlmr2_2L
	}
	//THREE-LEVEL
	else if `nlevels'==3 {
		mlmr2_3L
	}
	//FOUR-LEVEL
	else if `nlevels'==4 {
		mlmr2_4L
	}
	//FIVE-LEVEL
	else if `nlevels'==5 {
		mlmr2_5L
	}
	else if `nlevels'>5 {
		di as err "No more than 5 levels are currently allowed."
	}
	return add
end
exit