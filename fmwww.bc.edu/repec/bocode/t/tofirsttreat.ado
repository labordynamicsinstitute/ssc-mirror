prog def tofirsttreat, sortpreserve
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
	mata: data = st_data(., "`id' `time' `varlist'");
	mata: units = uniqrows(data[., 1])'
	mata: tofirsttreat(data, "`varlist'", units, "`generate'")
end

mata:
	real matrix tofirsttreat(real matrix data, string scalar treatvar, real matrix units, string scalar genvar){
		real scalar i; real matrix data_tmp, data_sum, info, key, data_sum_random, data_res;
		data_tmp = select(data, data[.,3]);
		_sort(data_tmp, (1,2,3));
		info = panelsetup(data_tmp, 1, 2);
		data_sum = data_tmp[info[.,1],1..2];
		data_res = data;
		key = asarray_create("real"); 
		asarray_notfound(key, .); 
		for(i = 1; i <= rows(data_sum); i ++) asarray(key, data_sum[i, 1], data_sum[i, 2]);
		for(i = 1; i <= rows(data_res); i++) data_res[i, 3] = asarray(key, data_res[i, 1])
		if(genvar == "") {
			st_store(., treatvar,  data_res[, 3]);
			printf("{txt}({res}" + treatvar +"{txt} has been changed)");
		} else {
			st_store(., st_addvar(st_vartype(treatvar), genvar),  data_res[, 3]);
			printf("{txt}({res}" + genvar +"{txt} has been generated)");
		}
	}
end