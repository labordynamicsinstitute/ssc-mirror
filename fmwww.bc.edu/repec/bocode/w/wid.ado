*! wid v1.0.7 world inequality database 28Jul2026

program wid
	version 15
	
	local wid_cmdline `"`0'"'
	syntax, [INDicators(string) AReas(string) Years(numlist) Perc(string) AGes(string) POPulation(string) METAdata QUALITY_filter(string asis) clear VERBOSE]
	
	// ---------------------------------------------------------------------- //
	// Check if there are already some data in memory
	// ---------------------------------------------------------------------- //
	
	quietly count
	if (r(N) > 0 & "`clear'" == "") {
		display as error "no; data in memory would be lost"
		exit 4
	}
	
	// ---------------------------------------------------------------------- //
	// Define verbosity
	// ---------------------------------------------------------------------- //
	
	local verbosity = cond("`verbose'" != "", "verbose", "silent")

	// ---------------------------------------------------------------------- //
	// Parse quality filters before any API request is made
	// ---------------------------------------------------------------------- //

	local wid_cmdline_lower = lower(`"`wid_cmdline'"')
	local wid_cmdline_normalized = subinstr(`"`wid_cmdline_lower'"', char(9), " ", .)
	local quality_filter_specified = regexm(`"`wid_cmdline_normalized'"', "(^|[ ,])quality[_a-z]*[ ]*\(")
	local data_quality_filter = 0
	local avg_quality_filter = 0
	local data_quality_min = .
	local data_quality_max = .
	local avg_quality_min = .
	local avg_quality_max = .
	if (`quality_filter_specified') {
		if (trim(`"`quality_filter'"') == "") {
			display as error "quality_filter() cannot be empty"
			exit 198
		}
		wid_parse_quality_filter `"`quality_filter'"'
		local data_quality_filter = r(data_quality_filter)
		local avg_quality_filter = r(avg_quality_filter)
		local data_quality_min = r(data_quality_min)
		local data_quality_max = r(data_quality_max)
		local avg_quality_min = r(avg_quality_min)
		local avg_quality_max = r(avg_quality_max)
	}
	
	// ---------------------------------------------------------------------- //
	// Check the user specified at least some countries and/or indicators
	// ---------------------------------------------------------------------- //
	
	if (inlist("`indicators'", "", "_all") & inlist("`areas'", "", "_all")) {
		display as error "you need to specify some indicators, some areas, or both"
		exit 198
	}
	
	// ---------------------------------------------------------------------- //
	// Parse the arguments
	// ---------------------------------------------------------------------- //
	
	// If no area specified, use all of them
	if inlist("`areas'", "_all", "") {
		local areas "all"
	}
	else {
		// Add a comma between areas
		foreach a of local areas {
			if ("`areas_comma'" != "") {
				local areas_comma "`areas_comma',`a'"
			}
			else {
				local areas_comma "`a'"
			}
		}
		local areas `areas_comma'
	}
	
	// ---------------------------------------------------------------------- //
	// Retrieve all possible variables for the area(s)
	// ---------------------------------------------------------------------- //
	
	display as text ""
	display as text "* Get variables associated to your selection...", _continue
	
	tempfile allvars
	clear
	quietly save "`allvars'", emptyok
	
	foreach sixlet in `indicators' {
		clear
		if regexm("`sixlet'", "^[a-z][a-z][a-z][a-z][a-z][a-z]$") {
			clear
			javacall com.wid.WIDDownloader importCountriesAvailableVariables, args("`areas'" "`sixlet'" "`verbosity'") jars("wid.jar" "json-20180813.jar" "sfi-api.jar")
		}
		else if ("`sixlet'" == "_all") {
			clear
			javacall com.wid.WIDDownloader importCountriesAvailableVariables, args("`areas'" "all" "`verbosity'") jars("wid.jar" "json-20180813.jar" "sfi-api.jar")
		}
		else {
			display as error "`name' is not a valid six letter code"
			exit 198
		}
		quietly append using "`allvars'"
		quietly save "`allvars'", replace
	}
	
	// Check if there are some results
	quietly use "`allvars'"
	quietly count
	if (r(N) == 0) {
		display as text "DONE"
		display as text "(no data matching your selection)"
		exit 0
	}
	
	// ---------------------------------------------------------------------- //
	// Only keep variables that the user asked for
	// ---------------------------------------------------------------------- //
	
	// Create a file with all indicators specified, if any
	clear
	if !inlist("`indicators'", "", "_all") {
		local n: word count `indicators'
		quietly set obs `n'
		quietly generate variable = ""
		forvalues i = 1/`n' {
			local name: word `i' of `indicators'
			if !regexm("`name'", "^[a-z][a-z][a-z][a-z][a-z][a-z]$") {
				display as error "`name' is not a valid six letter code"
				exit 198
			}
			quietly replace variable = "`name'" in `i'
		}
		quietly duplicates drop
		tempfile list_indicators
		quietly save "`list_indicators'"
	}
	
	// Create a list with all the years specified, if any
	clear
	if !inlist("`years'", "", "_all") {
		local n: word count `years'
		quietly set obs `n'
		quietly generate year = .
		forvalue i = 1/`n' {
			local year: word `i' of `years'
			quietly replace year = `year' in `i'
		}
		quietly duplicates drop
		tempfile list_years
		quietly save "`list_years'"
	}
	
	// Create a list with all percentiles specified, if any
	clear
	if !inlist("`perc'", "", "_all") {
		local n: word count `perc'
		quietly set obs `n'
		quietly generate percentile = ""
		forvalues i = 1/`n' {
			local p: word `i' of `perc'
			if !(regexm("`p'", "^p[\.0-9]+$") | regexm("`p'", "^p[\.0-9]+p[\.0-9]+$")) {
				display as error "`p' is not a valid percentile or percentile group"
				exit 198
			}
			quietly replace percentile = "`p'" in `i'
		}
		quietly duplicates drop
		tempfile list_perc
		quietly save "`list_perc'"
	}
	
	// Create a list with all ages specified, if any
	clear
	if !inlist("`ages'", "", "_all") {
		local n: word count `ages'
		quietly set obs `n'
		quietly generate age = ""
		forvalues i = 1/`n' {
			local a: word `i' of `ages'
			if !regexm("`a'", "^[0-9][0-9][0-9]$") {
				display as error "`a' is not a valid age code"
				exit 198
			}
			quietly replace age = "`a'" in `i'
		}
		quietly duplicates drop
		tempfile list_ages
		quietly save "`list_ages'"
	}
	
	// Create a list with all populations specified, if any
	clear
	if !inlist("`population'", "", "_all") {
		local n: word count `population'
		quietly set obs `n'
		quietly generate pop = ""
		forvalues i = 1/`n' {
			local pop: word `i' of `population'
			if !inlist("`pop'", "i", "j", "m", "f", "t", "e") {
				display as error "`pop' is not a valid population code"
				exit 198
			}
			quietly replace pop = "`pop'" in `i'
		}
		quietly duplicates drop
		tempfile list_population
		quietly save "`list_population'"
	}
	
	// From the list of all indicators, only keep the one we are interested in
	quietly use "`allvars'", clear
	if !inlist("`indicators'", "", "_all") {
		quietly merge n:1 variable using "`list_indicators'", nogenerate keep(match)
	}
	if !inlist("`perc'", "", "_all") {
		quietly merge n:1 percentile using "`list_perc'", nogenerate keep(match)
	}
	if !inlist("`ages'", "", "_all") {
		quietly merge n:1 age using "`list_ages'", nogenerate keep(match)
	}
	if !inlist("`population'", "", "_all") {
		quietly merge n:1 pop using "`list_population'", nogenerate keep(match)
	}
	
	// Check that there are some data left
	quietly count
	if (r(N) == 0) {
		display as text "DONE"
		display as text "(no data matching you selection)"
		exit 0
	}
	
	// ---------------------------------------------------------------------- //
	// Display how many variables remain
	// ---------------------------------------------------------------------- //
	
	quietly tab variable
	local nb_variable = r(r)
	if (`nb_variable' > 1) {
		local plural_variable "s"
	}
	quietly tab country
	local nb_country = r(r)
	if (`nb_country' > 1) {
		local plural_country "s"
	}
	quietly tab percentile
	local nb_percentile = r(r)
	if (`nb_percentile' > 1) {
		local plural_percentile "s"
	}
	quietly tab age
	local nb_age = r(r)
	if (`nb_age' > 1) {
		local plural_age "ies"
	}
	else {
		local plural_age "y"
	}
	quietly tab pop
	local nb_pop = r(r)
	if (`nb_pop' > 1) {
		local plural_pop "ies"
	}
	else {
		local plural_pop "y"
	}
	
	display as text "DONE"
	display as text "(found `nb_variable' variable`plural_variable'", _continue
	display as text "for `nb_country' area`plural_country',", _continue
	display as text "`nb_percentile' percentile`plural_percentile',", _continue
	display as text "`nb_age' age categor`plural_age',", _continue
	display as text "`nb_pop' population categor`plural_pop')"
	display as text ""
	
	// ---------------------------------------------------------------------- //
	// Retrieve the data from the API
	// ---------------------------------------------------------------------- //
	
	display as text "* Downloading the data",, _continue
	
	// Generate the variable names to be used in the API
	quietly generate data_code = variable + "_" + percentile + "_" + age + "_" + pop
		
	// Divide the data in smaller chunks before making the request: group by
	// variable and percentiles
	sort variable percentile age pop country
	quietly egen grp = group(variable percentile age pop)
	quietly generate chunk = round(grp/10)
	quietly drop grp
	
	tempfile codes output_data
	quietly save "`codes'"
		
	display ""
	display ""
	display "{c LT} 0% {hline 3}{c +}{hline 3} 20% {hline 3}{c +}{hline 3} 40% {hline 3}{c +}{hline 3} 60% {hline 3}{c +}{hline 3} 80% {hline 3}{c +}{hline 3} 100% {c RT}" in smcl
	
	quietly tabulate chunk
	local nchunks = r(r)
	quietly levelsof chunk, local(chunk_list)
	local progress = 1
	foreach c of local chunk_list {
		quietly use "`codes'"
		quietly levelsof data_code if (chunk == `c'), separate(",") local(variables_list) clean
		quietly levelsof country if (chunk == `c'), separate(",") local(areas_list) clean
		
		clear
		javacall com.wid.WIDDownloader importCountriesVariables, args("`areas_list'" "`variables_list'" "`verbosity'")  jars("wid.jar" "json-20180813.jar" "sfi-api.jar")
		
		quietly drop if missing(value)
		
		if (`c' != 0) {
			quietly append using "`output_data'"
		}
		quietly save "`output_data'", replace
		
		while (`c'/`nchunks'*68 > `progress') {
			di "=",, _continue
			local progress = `progress' + 1
		}
	}
	while (`progress' < 68) {
		di "=",, _continue
		local progress = `progress' + 1
	}
	display ""
	display ""
	
	if ("`list_years'" != "") {
		quietly merge n:1 year using "`list_years'", nogenerate keep(match)
	}
	
	quietly count
	if (r(N) == 0) {
		display as text "(no data matching you selection)"
		exit 0
	}
	
	quietly duplicates drop country variable age pop percentile year, force
	quietly replace variable = variable + age + pop
	capture confirm variable data_quality
	if (_rc) {
		quietly generate double data_quality = .
	}
	if (`data_quality_filter') {
		quietly drop if missing(data_quality) | data_quality < `data_quality_min' | data_quality > `data_quality_max'
	}
	order country variable percentile year value
	quietly save "`output_data'", replace
	
	// ---------------------------------------------------------------------- //
	// Retrieve the metadata, if requested or needed for avg_quality filtering
	// ---------------------------------------------------------------------- //
	
	if ("`metadata'" != "" | `avg_quality_filter') {
		if ("`metadata'" != "") {
			display as text "* Download the metadata...", _continue
		}
		else {
			display as text "* Download the metadata for quality filtering...", _continue
		}
		local metadata_mode "compact"
		if ("`metadata'" == "") {
			local metadata_mode "score_only"
		}
		
		// Metadata are percentile-invariant, but vary by country, indicator,
		// age category, and population category.
		tempfile output_metadata
		quietly use "`codes'", clear
		drop chunk
		quietly duplicates drop variable country age pop, force
		quietly generate chunk = round(_n/50)
		quietly save "`codes'", replace
		
		quietly levelsof chunk, local(chunk_list)
		local first 1
		foreach c of local chunk_list {
			quietly use "`codes'", clear
			quietly levelsof data_code if (chunk == `c'), separate(",") local(variables_list) clean
			quietly levelsof country if (chunk == `c'), separate(",") local(areas_list) clean
			
			clear
			javacall com.wid.WIDDownloader importCountriesVariablesMetadata, args("`areas_list'" "`variables_list'" "`verbosity'" "`metadata_mode'")  jars("wid.jar" "json-20180813.jar" "sfi-api.jar")
			
			// Pass if the dataset is empty (can happen with metadata)
			quietly count
			if (r(N) == 0) {
				continue
			}
		
			capture drop percentile
			quietly replace variable = variable + agecode + popcode
			quietly duplicates drop variable country, force
			
			if (`first' == 0) {
				quietly append using "`output_metadata'"
			}
			local first 0
			quietly save "`output_metadata'", replace
		}
				
		if (`first' == 0) {
			quietly use "`output_metadata'", clear
			display as text "DONE"
			capture drop quality imputation
			quietly duplicates drop variable country, force
			quietly save "`output_metadata'", replace
			
			if ("`metadata'" != "") {
				use "`output_data'", clear
				capture drop age pop
				quietly merge n:1 country variable using "`output_metadata'", nogenerate keep(master match)
			}
			else {
				quietly keep country variable avg_quality
				quietly save "`output_metadata'", replace
				use "`output_data'", clear
				quietly merge n:1 country variable using "`output_metadata'", nogenerate keep(master match)
			}
		}
		else {
			display as text "DONE (no metadata found for requested data)"
			use "`output_data'", clear
			if ("`metadata'" != "") {
				capture drop age pop
			}
			if (`avg_quality_filter') {
				quietly generate double avg_quality = .
			}
		}
	}
	
	if (`avg_quality_filter') {
		capture confirm variable avg_quality
		if (_rc) {
			quietly generate double avg_quality = .
		}
		quietly drop if missing(avg_quality) | avg_quality < `avg_quality_min' | avg_quality > `avg_quality_max'
	}
	
	capture drop quality imputation
	
	if ("`metadata'" != "") {
		foreach v in countryname shortname shortdes pop age source method {
			capture confirm variable `v'
			if (_rc) {
				quietly generate str1 `v' = ""
			}
		}
		foreach v in data_quality avg_quality {
			capture confirm variable `v'
			if (_rc) {
				quietly generate double `v' = .
			}
		}
		quietly keep country countryname variable percentile year value shortname shortdes pop age source data_quality avg_quality method
		order country countryname variable percentile year value shortname shortdes pop age source data_quality avg_quality method
	}
	else {
		if (!`avg_quality_filter') {
			capture drop avg_quality
		}
		local quality_columns data_quality
		if (`avg_quality_filter') {
			local quality_columns `quality_columns' avg_quality
		}
		capture order country variable percentile year value age pop `quality_columns'
	}
	
	// Saves memory
	quietly compress
	
	sort country variable percentile year
end

program wid_parse_quality_filter, rclass
	version 15
	args filter
	
	local filter = lower(trim(`"`filter'"'))
	if (`"`filter'"' == "") {
		display as error "quality_filter() cannot be empty"
		exit 198
	}
	
	local data_quality_used = 0
	local avg_quality_used = 0
	local data_quality_min = .
	local data_quality_max = .
	local avg_quality_min = .
	local avg_quality_max = .
	
	if (strpos(`"`filter'"', "data_quality") == 0 & strpos(`"`filter'"', "avg_quality") == 0) {
		wid_parse_score_bounds `"`filter'"'
		local data_quality_used = 1
		local data_quality_min = r(min)
		local data_quality_max = r(max)
	}
	else {
		local work = subinstr(`"`filter'"', char(9), " ", .)
		local work = subinstr(`"`work'"', "data_quality", ";data_quality", .)
		local work = subinstr(`"`work'"', "avg_quality", ";avg_quality", .)
		
		local rest `"`work'"'
		while (`"`rest'"' != "") {
			gettoken segment rest : rest, parse(";")
			local segment = trim(`"`segment'"')
			if (`"`segment'"' == "" | `"`segment'"' == ";") {
				continue
			}
			local junk = subinstr(`"`segment'"', "{", "", .)
			local junk = subinstr(`"`junk'"', "}", "", .)
			local junk = subinstr(`"`junk'"', ",", "", .)
			if (trim(`"`junk'"') == "") {
				continue
			}
			
			if (substr(`"`segment'"', 1, 12) == "data_quality") {
				local name data_quality
				local values = substr(`"`segment'"', 13, .)
			}
			else if (substr(`"`segment'"', 1, 11) == "avg_quality") {
				local name avg_quality
				local values = substr(`"`segment'"', 12, .)
			}
			else {
				display as error "quality_filter() only supports data_quality and avg_quality"
				exit 198
			}
			
			local separator = substr(`"`values'"', 1, 1)
			if (`"`separator'"' != "" & !inlist(`"`separator'"', " ", "=", ":", "{", "[")) {
				display as error "invalid quality_filter() score name"
				exit 198
			}
			
			wid_parse_score_bounds `"`values'"'
			if ("`name'" == "data_quality") {
				if (`data_quality_used') {
					display as error "data_quality specified more than once in quality_filter()"
					exit 198
				}
				local data_quality_used = 1
				local data_quality_min = r(min)
				local data_quality_max = r(max)
			}
			else {
				if (`avg_quality_used') {
					display as error "avg_quality specified more than once in quality_filter()"
					exit 198
				}
				local avg_quality_used = 1
				local avg_quality_min = r(min)
				local avg_quality_max = r(max)
			}
		}
	}
	
	if (!`data_quality_used' & !`avg_quality_used') {
		display as error "quality_filter() cannot be empty"
		exit 198
	}
	
	return scalar data_quality_filter = `data_quality_used'
	return scalar avg_quality_filter = `avg_quality_used'
	return scalar data_quality_min = `data_quality_min'
	return scalar data_quality_max = `data_quality_max'
	return scalar avg_quality_min = `avg_quality_min'
	return scalar avg_quality_max = `avg_quality_max'
end

program wid_parse_score_bounds, rclass
	version 15
	args raw
	
	local spec = lower(trim(`"`raw'"'))
	local first = substr(`"`spec'"', 1, 1)
	if (inlist(`"`first'"', "=", ":")) {
		local spec = trim(substr(`"`spec'"', 2, .))
	}
	if (`"`spec'"' == "") {
		display as error "quality_filter() bounds cannot be empty"
		exit 198
	}
	
	local min_set = 0
	local max_set = 0
	local min = .
	local max = .
	
	if (strpos(`"`spec'"', "min") > 0 | strpos(`"`spec'"', "max") > 0) {
		local clean `"`spec'"'
		foreach ch in "{" "}" "[" "]" "," ":" "=" "/" {
			local clean = subinstr(`"`clean'"', "`ch'", " ", .)
		}
		local clean = itrim(trim(`"`clean'"'))
		
		while (`"`clean'"' != "") {
			gettoken key clean : clean
			local key = trim(`"`key'"')
			if (inlist(`"`key'"', "min", "minimum")) {
				if (`min_set') {
					display as error "minimum score specified more than once"
					exit 198
				}
				gettoken token clean : clean
				wid_parse_score_number `"`token'"'
				local min = r(value)
				local min_set = 1
			}
			else if (inlist(`"`key'"', "max", "maximum")) {
				if (`max_set') {
					display as error "maximum score specified more than once"
					exit 198
				}
				gettoken token clean : clean
				wid_parse_score_number `"`token'"'
				local max = r(value)
				local max_set = 1
			}
			else {
				display as error "invalid quality_filter() bounds"
				exit 198
			}
		}
		
		if (!`min_set' & !`max_set') {
			display as error "quality_filter() bounds cannot be empty"
			exit 198
		}
		if (!`min_set') {
			local min = 0
		}
		if (!`max_set') {
			local max = 5
		}
	}
	else {
		local clean `"`spec'"'
		foreach ch in "{" "}" "[" "]" "," "/" {
			local clean = subinstr(`"`clean'"', "`ch'", " ", .)
		}
		local clean = itrim(trim(`"`clean'"'))
		local n : word count `clean'
		if (!inlist(`n', 1, 2)) {
			display as error "quality_filter() bounds must be one number, two numbers, or min/max bounds"
			exit 198
		}
		
		gettoken token clean : clean
		wid_parse_score_number `"`token'"'
		local min = r(value)
		if (`n' == 1) {
			local max = 5
		}
		else {
			gettoken token clean : clean
			wid_parse_score_number `"`token'"'
			local max = r(value)
		}
	}
	
	if (`min' < 0 | `min' > 5 | `max' < 0 | `max' > 5) {
		display as error "quality_filter() bounds must be between 0 and 5"
		exit 198
	}
	if (`min' > `max') {
		display as error "quality_filter() minimum cannot exceed maximum"
		exit 198
	}
	
	return scalar min = `min'
	return scalar max = `max'
end

program wid_parse_score_number, rclass
	version 15
	args token
	
	local token = trim(`"`token'"')
	local value = real(`"`token'"')
	if (`"`token'"' == "" | missing(`value')) {
		display as error "quality_filter() bounds must be numeric"
		exit 198
	}
	
	return scalar value = `value'
end
