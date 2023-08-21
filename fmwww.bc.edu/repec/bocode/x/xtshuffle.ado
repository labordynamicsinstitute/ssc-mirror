prog def xtshuffle, sortpreserve
    qui xtset
	version 16
	syntax varname, [Id(varname) Time(varname) GENerate(name)]
	if "`r(panelvar)'" != "" & "`r(timevar)'" != "" {
		loc id "`r(panelvar)'"
		loc time "`r(timevar)'"
	}
	else {
		if "`id'"== "" & "`time'"== "" {
		di as err "panel variable or time variable missing, please use -{bf:xtset} {it:panelvar} {it:timevar} or specify {opt id(panelvarname)} and {opt time(timevarname)}"
		exit 198
		}
    }
	cap qui ds `generate'
	if "`r(varlist)'" == "`generate'" {
		di as err "variable {bf:`generate'} already defined"
        exit 198
	}
	qui fillin `id' `time'
	qui sort  `time' `id'
	mata: xtshuffle("`id'", "`time'", "`varlist'", "`generate'");
	qui drop if _fillin == 1
	qui drop _fillin
end

mata:
	real matrix xtshuffle(string scalar panelvar, string scalar timevar, string scalar treatvar, string scalar genvar){
		real matrix units, units_random, data; real scalar unitnum;
		data = st_data(., panelvar + " " + timevar + " " + treatvar);
		units = uniqrows(data[., 1])';
		units_random = jumble(units');
		unitnum = cols(units);
		data[, 1] = J(rows(data)/unitnum, 1, units_random);
		_sort(data,(2, 1));
		if(genvar == "") {
			st_store(., treatvar,  data[, 3]);
			printf("{txt}({res}" + treatvar +"{txt} has been changed)");
		} else {
			st_store(., st_addvar(st_vartype(treatvar), genvar),  data[, 3]);
			printf("{txt}({res}" + genvar +"{txt} has been generated)");
		}
	}
end