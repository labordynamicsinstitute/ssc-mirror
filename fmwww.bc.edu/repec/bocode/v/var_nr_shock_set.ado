program define var_nr_shock_set, rclass
version 16.0

	syntax , SRname(string) SHOCK(string) AFFECTING(varname) STARThzn(numlist integer >0) [ENDhzn(numlist integer>0) POSitive NEGative]
	
	// catch any preliminary errors	
	if "`positive'"=="" & "`negative'"=="" {
		di as error "must specify if restriction is positive or negative"
		exit 198 // change number
	}
	
	if "`shock'"=="" {
		di as error "must give shock a title"
		exit 198 // change number
	}
	
	loc wc = "`positive'" + " " + "`negative'"
	loc wc = wordcount("`wc'")
	if (`wc'>1) {
		di as error "cannot specify both positive and negative"
		exit 198
	}
	
	if "`endhzn'"!="" {
		if (`starthzn'>`endhzn') {
			di as error "starthzn must be less than or equal to endhzn"
		}
	}
	else {
		loc endhzn = `starthzn'
	}
	
	// assign sign restriction locals
	if "`positive'"!="" {
		loc sr_type = "positive"
	}
	else if "`negative'"!="" {
		loc sr_type = "negative"
	}
	
	mata: shock_set(`starthzn',`endhzn',"`sr_type'","`shock'","`affecting'",`srname')

end