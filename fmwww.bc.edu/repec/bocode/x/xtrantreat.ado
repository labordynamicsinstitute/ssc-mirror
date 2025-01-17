prog def xtrantreat, sortpreserve
    qui xtset
	version 16
	syntax varname, MEthod(numlist min=1 max=1 >=1 <=3 integer) [Id(varname) Time(varname) RANUnitnum(numlist min=1 max=1 >0 integer) RANTimescope(numlist min=2 max=2 integer) GENerate(name)]
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
	mata: units = uniqrows(data[., 1])';
	if "`ranunitnum'" == "" {
		mata: units_tr = uniqrows(select(data[., 1], data[., 3]))';
		mata: ranunitnum = cols(units_tr);
	}
	else mata: ranunitnum = strtoreal(st_local("ranunitnum"));
	if "`rantimescope'" == "" {
		mata: time = uniqrows(data[., 2])'; 
		mata: data_tmp = select(data, data[.,3]);
		mata: _sort(data_tmp, (1,2,3));
		mata: info = panelsetup(data_tmp, 1);
		mata: data_sum = data_tmp[info[.,1],1..2];
		mata: timelb = ("`method'"=="1"? sort(time', 1)[2, .]:min(data_sum[., 2])); 
		mata: timeub = ("`method'"=="1"? max(time):max(data_sum[., 2])); 
	}
	else mata: tmp = tokens("`rantimescope'"); timelb = strtoreal(tmp[1]); timeub = strtoreal(tmp[2]);
	mata: times_ltd = uniqrows(select(data[., 2], (data[., 2]:>=timelb):&(data[.,2]:<=timeub)))';
	mata: xtrantreat(data, "`varlist'", ranunitnum, units, times_ltd, strtoreal("`method'"), "`generate'");
end
mata:
	void xtrantreat(real matrix data, string scalar treatvar, real unitnum_ltd, real matrix units, real matrix times, real scalar method, string scalar genvar){
		real scalar time_max, i, unitnum; real matrix data_tmp, data_sum, info, key, data_sum_random, units_random, times_random, times_tr, data_res;
		time_max = max(data[., 2]');
		data_tmp = select(data, data[.,3]);
		_sort(data_tmp, (1,2,3));
		info = panelsetup(data_tmp, 1);
		data_sum = data_tmp[info[.,1],1..2];
		times_tr = uniqrows(data_sum[., 2]);
		unitnum = rows(uniqrows(data_sum[., 1]));
		data_res = data;
		if(method == 1){
			units_random = (jumble(units')')[.,1..unitnum_ltd];
			times_random = (jumble(times')')[.,1];
			key = asarray_create("real"); 
			asarray_notfound(key, time_max + 1); 
			for(i = 1; i <= unitnum_ltd; i ++) asarray(key, units_random[1, i], times_random);
		}
		if(method == 2){
			units_random = (jumble(units')')[.,1..unitnum_ltd];
			times_random = times[., runiformint(1, unitnum_ltd, 1, cols(times))]; 
			key = asarray_create("real"); 
			asarray_notfound(key, time_max + 1); 
			for(i = 1; i <= unitnum_ltd; i ++) asarray(key, units_random[1, i], times_random[1, i]);
		}
		if(method == 3){
			if(rows(times_tr)>cols(times)) {
				printf("{err}The range of fake treatment periods specified by the options rantimescope({it:t_min t_max}) must be greater than or equal to the number of periods in the actual treatment variable.\n")
				exit(198);
			}
			times_random = jumble(times')[1..rows(times_tr),.];
			key = asarray_create("real"); 
			for(i = 1; i <= rows(times_tr); i ++) asarray(key, times_tr[i, 1], times_random[i, 1]);
			data_sum = data_tmp[info[.,1], 1..2];
			for(i = 1; i <= rows(data_sum); i++) data_sum[i, 2] = asarray(key, data_sum[i, 2]);
			units_random = jumble(units')[1..unitnum, .];
			data_sum_random = (units_random, data_sum[., 2]);
			key = asarray_create("real"); 
			asarray_notfound(key, time_max + 1); 
			for(i = 1; i <= rows(data_sum_random); i ++) asarray(key, data_sum_random[i, 1], data_sum_random[i, 2]);
		}
		for(i = 1; i <= rows(data_res); i++) data_res[i, 3] = (data_res[i, 2] >= asarray(key, data_res[i, 1]) ? 1: 0);
		if(genvar == "") {
			st_store(., treatvar,  data_res[, 3]);
			printf("{txt}({res}" + treatvar +"{txt} has been changed)");
		} else {
			st_store(., st_addvar(st_vartype(treatvar), genvar),  data_res[, 3]);
			printf("{txt}({res}" + genvar +"{txt} has been generated)");
		}
	}
end