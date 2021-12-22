program define var_nr_narr_set, rclass
version 16.0

	syntax , STARTpd(numlist min=1 max=1) NSRname(string) SHOCK(string) [ENDpd(numlist min=1 max=1) POSitive NEGATive MOSTimportant LEASTimportant OVERWHELMing NEGLIGible AFFECTING(string)]
	
	// catch any preliminary errors	
	if "`positive'"=="" & "`negative'"=="" & /*
	*/ "`mostimportant'"=="" & "`leastimportant'"=="" & /*
	*/ "`overwhelming'"=="" & "`negligible'"=="" {
		di as error "must specify type of narrative restriction"
		exit 198 // change number
	}
	
	if "`shock'"=="" {
		di as error "must specify shock"
		exit 198 // change number
	}
	
	if ("`mostimportant'"!="" | "`leastimportant'"!="" | "`overwhelming'"!="" | "`negligible'"!="") /*
	*/ & ("`affecting'"=="") {
		di as error "must specify affected variable using affecting() option"
		exit 198 // change number
	}
	
	loc wc = "`positive'" + " " + "`negative'" + " " + /*
		  */ "`mostimportant'" + " " + "`leastimportant'" + " " + /*
		  */ "`overwhelming'" + " " + "`negligible'"
	if wordcount("`wc'")>1 {
		di as error "can only specify one type of narrative restriction"
		exit 198
	}
	
	// assign narrative restriction type locals
	if "`positive'"!="" {
		loc nr_type = "positive"
	}
	else if "`negative'"!="" {
		loc nr_type = "negative"
	}
	else if "`mostimportant'"!="" {
		loc nr_type = "mostimportant"
	}
	else if "`leastimportant'"!="" {
		loc nr_type = "leastimportant"
	}
	else if "`overwhelming'"!="" {
		loc nr_type = "overwhelming"
	}
	else if "`negligible'"!="" {
		loc nr_type = "negligible"
	}
	
	loc var_shock = "`shock'"
	
	if "`affecting'"!="" loc var_affected = "`affecting'"
	else loc var_affected = "."
	
	if "`endpd'"=="" loc endpd = `startpd'
	
	// store pointer array into master associative array in Mata
	mata: nr_set(`startpd',`endpd',"`nr_type'","`var_shock'","`var_affected'",`nsrname')

end