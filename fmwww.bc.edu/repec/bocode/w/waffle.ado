* 1.0 Jared Colston March 2022

* Program for creating Waffle Charts



capture program drop waffle 
program waffle
version 17

syntax varlist(numeric min=1 max=5) [if] [in], ///
	[WIDE BY(passthru) Title(str) COLORs(str) ///
	EMPTYcolors(str) OUTLinecolors(str) EMPTYOUTLinecolors(str) ///
	SCHeme(str) Note(str) MARKersize(numlist min=1 max=1) ///
	BYRows(numlist min=1 max=1) NAME(passthru) ///
	LEGend(passthru) COOLSgraph]
	
preserve																			// Store original data
quietly {
	tokenize `varlist'																// Define the varlist in macros
	marksample touse
	if "`missing'" == "" markout `touse', strok  
	count if `touse' 
	if r(N) == 0 exit 2000 
	capture keep if `touse' == 1													// Allow "if" conditions
	
	*cool s graph easter egg. This is just a silly add-on
		if "`coolsgraph'" != "" {
			di as err "You just drew a Cool S Graph! Nice! Only this time not on your middle school textbook."
			graph twoway scatteri 3 9 8 9, lcolor(red) recast(line) ///
			yscale(range(0 20)) xscale(range(0 20)) ylabel(, nogrid noticks nolabel) ///
			xlabel(, nogrid noticks nolabel) legend(off) ytitle("") xtitle("") ///
			|| scatteri 3 10 8 10, lcolor(red) recast(line) ///
			|| scatteri 3 11 8 11, lcolor(red) recast(line) ///
			|| scatteri 10 9 15 9, lcolor(red) recast(line) ///
			|| scatteri 10 10 15 10, lcolor(red) recast(line) ///
			|| scatteri 10 11 15 11, lcolor(red) recast(line) ///
			|| scatteri 15 9 18 10, lcolor(red) recast(line) ///
			|| scatteri 18 10 15 11, lcolor(red) recast(line) ///
			|| scatteri 3 9 1 10, lcolor(red) recast(line) ///
			|| scatteri 1 10 3 11, lcolor(red) recast(line) ///
			|| scatteri 10 9 8 10, lcolor(red) recast(line) ///
			|| scatteri 10 10 8 11, lcolor(red) recast(line) ///
			|| scatteri 8 9 8.5 9.5, lcolor(red) recast(line) ///
			|| scatteri 10 11 9.5 10.5, lcolor(red) recast(line)
			exit 198
		}
		
	// GENERAL OPTIONS
		*assign titles based on "by" option 
			if "`title'" != "" {
				local title_by "`title'"
				local title_noby "`title'"
			}
			
		*define colors of markers
			if "`colors'" != "" {
				local mcolor1 : word 1 of `colors'
				local mcolor2 : word 2 of `colors'
				local mcolor3 : word 3 of `colors'
				local mcolor4 : word 4 of `colors'
				local mcolor5 : word 5 of `colors'
			}
			
			else {
				local mcolor1 "78 121 167"
				local mcolor2 "242 142 43"
				local mcolor3 "89 161 79"
				local mcolor4 "176 122 161"
				local mcolor5 "255 157 167"
			}
			
			if "`emptycolors'" != "" {
				local ecolor "`emptycolors'"
			}
			
			else {
				local ecolor "gs14"
			}
			
		*define outline colors of markers
			if "`outlinecolors'" != "" {
				local ocolor "`outlinecolors'"
			}
			
			else {
				local ocolor "none"
			}
			
			if "`emptyoutlinecolors'" != "" {
				local eocolor "`emptyoutlinecolors'"
			}
			
			else {
				local eocolor "none"
			}
			
		*allow scheme
			if "`scheme'" != "" {
				local scheme "`scheme'"
			}
			
		*allow note
			if "`note'" != "" {
				local note "`note'"
			}

		*parse byvar from passthru code
		if "`by'" != "" {
			local byvar `by'
			local byvar : subinstr local byvar "by(" "", all 
			local byvar : subinstr local byvar ")" "", all 
			local byvar : subinstr local byvar "," " ", all
			local byvar : word 1 of `byvar'
			
			*convert byvar to numeric if string 
			local byvartype : type `byvar'
			if substr("`byvartype'",1,3) == "str" {
				encode `byvar', gen(`byvar'_waf)
				local byvar `byvar'_waf
			}
		}
			
	// IF ONLY ONE VARIABLE SPECIFIED
	if "`2'" == "" & "`3'" == "" & "`4'" == "" & "`5'" == "" {
	
		capture keep `1' `byvar' `touse'
		capture duplicates drop `1' `byvar' `touse', force
		
		*transform values to decimals if not
			if `1' > 100 {
				di as err "Variable does not appear to be a percent or decimal (it is higher than 100)"
				exit 198
			}
			
			if `1' > 1 {
				replace `1' = (`1' / 100)
			}
		
		*waffle structure
			if "`wide'" != "" {
				local rows = 20
				local cols = 5
				local aspectratio = .20
				local msize = 5
			}
			
			else if "`wide'" == "" {
				local rows = 10
				local cols = 10
				local aspectratio = 1
				local msize = 7
			}
			
		local obsv = `cols' * `rows'
		expand `obsv'
		
		*address issues with non-unique obs 
			if "`by'" == "" & _N > 100 {
				di as err "Variable selection does not uniquely define percent. Try combining with by()"
				exit 198
			}
			
			duplicates report `1' `byvar'
			local unique_value = `r(unique_value)'
			gen unique_val = `unique_value'
			capture levelsof `byvar'
			capture local groups = `r(r)'
			capture gen groups = `groups'
			gen error_dummy = 0
			capture replace error_dummy = 1 if unique_val > groups		
			if "`by'" != "" & error_dummy == 1 {
				di as err "Variable contains too many unique values. Your by() variable levels must match the number of unique values"
				exit 198
			}
			
		*by variables
			if "`by'" != "" {
				bysort `byvar' :	egen y = seq(), b(`cols')
								egen x = seq(), t(`cols')
				by `byvar' 	: 	gen id = _n 
				egen tag = tag(`byvar')
				gen category = .
				local msize = 2
				levelsof `byvar', local(lvls)
				foreach x of local lvls {
					summ `1' if `byvar' == `x' & tag == 1
					local share = `r(mean)'
					summ id if `byvar' == `x'
					replace category = id <= int(`share' * `r(max)') if `byvar' == `x'
				}
			}
			
			else {
				egen y = seq(), b(`cols')
				egen x = seq(), t(`cols')
				gen id = _n 
				gen category = .
				summ `1'
				local share = `r(mean)'
				summ id 
				replace category = id <= int(`share' * `r(max)')
			}
		
		*reverse structure for wide 
			if "`wide'" != "" {
				local y x
				local x y
			}

			else {
				local y y 
				local x x
			}
			
		*allow msize 
			if "`markersize'" != "" {
				local msize = `markersize'
			}

		*plot charts
			if "`by'" != "" {				
				twoway	(scatter `y' `x' if `touse' & category == 1, 				///
							msymbol(square) mfcolor("`mcolor1'")					///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) 		///
						(scatter `y' `x' if `touse' & category == 0, 				///
							msymbol(square) mfcolor("`ecolor'") 					///
							mlwidth(vthin) mlcolor("`eocolor'") msize(`msize') 		///
						ytitle("") yscale(noline) ylabel(, nogrid noticks nolabels) ///
						xtitle("") xscale(noline) xlabel(, nogrid noticks nolabels) ///
						legend(off) aspectratio(`aspectratio')			 			///
						by(, legend(off) noiyaxes noixaxes noiytick 				///
							noixtick noiylabel noixlabel note("`note'")				///
							title(`title_by')) `by'									///
						subtitle(, nobox) scheme(`scheme') `name')
			}
			
			else {
				twoway	(scatter `y' `x' if `touse' & category == 1, 				///
							msymbol(square) mfcolor("`mcolor1'") 					///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) 		///
						(scatter `y' `x' if `touse' & category == 0, 				///
							msymbol(square) mfcolor("`ecolor'") 					///
							mlwidth(vthin) mlcolor("`eocolor'") msize(`msize') 		///
						ytitle("") yscale(noline) ylabel(, nogrid noticks nolabels) ///
						xtitle("") xscale(noline) xlabel(, nogrid noticks nolabels) ///
						legend(off) aspectratio(`aspectratio') title(`title_noby')	///
						scheme(`scheme') note("`note'") `name')
			}
	}
	
	// IF TWO VARIABLES SPECIFIED
	else if "`2'" != "" & "`3'" == "" & "`4'" == "" & "`5'" == "" {
		capture keep `1' `2' `byvar' `touse'
		capture duplicates drop `1' `2' `byvar' `touse', force
		
		*transform values to decimals if not
			if `1' > 100 | `2' > 100 {
				di as err "Variable does not appear to be a percent or decimal (it is higher than 100)"
				exit 198
			}
			
			if `1' > 1 {
				replace `1' = (`1' / 100)
			}
			
			if `2' > 1 {
				replace `2' = (`2' / 100)
			}
		
		*waffle structure
			if "`wide'" != "" {
				local rows = 20
				local cols = 5
				local aspectratio = .20
				local msize = 4
			}
			
			else if "`wide'" == "" {
				local rows = 10
				local cols = 10
				local aspectratio = 1
				local msize = 6
			}
			
		local obsv = `cols' * `rows'
		expand `obsv'
		
		*address issues with non-unique obs 
			if "`by'" == "" & _N > 100 {
				di as err "Variable selection does not uniquely define percent. Try combining with by()"
				exit 198
			}
			
			/*
			duplicates report `1' `2' `byvar'
			local unique_value = `r(unique_value)'
			gen unique_val = `unique_value'
			capture levelsof `byvar'
			capture local groups = `r(r)'
			capture gen groups = `groups'
			gen error_dummy = 0
			capture replace error_dummy = 1 if unique_val > groups		
			if "`by'" != "" & error_dummy == 1 {
				di as err "Variable contains too many unique values. Your by() variable levels must match the number of unique values"
				exit 198
			}
			*/
			
		gen seq_cat1 = `1'
		gen seq_cat2 = seq_cat1 + `2'
		
		*by variables
			if "`by'" != "" {
				bysort `byvar' :	egen y = seq(), b(`cols')
								egen x = seq(), t(`cols')
				by `byvar' 	: 	gen id = _n 
				egen tag = tag(`byvar')
				gen category = .
				gen color_cat1 = .
				gen color_cat2 = .
				local msize = 2
				levelsof `byvar', local(lvls)
				
				foreach x of local lvls {
					summ seq_cat1 if `byvar' == `x' & tag == 1
					local share = `r(mean)'
					summ id if `byvar' == `x'
					replace color_cat1 = id <= int(`share' * `r(max)') if `byvar' == `x'
				}
				
				foreach x of local lvls {
					summ seq_cat2 if `byvar' == `x' & tag == 1
					local share = `r(mean)'
					summ id if `byvar' == `x'
					replace color_cat2 = id <= int(`share' * `r(max)') if `byvar' == `x'
				}
			}
			
			else {
				egen y = seq(), b(`cols')
				egen x = seq(), t(`cols')
				gen id = _n 
				gen category = .
				gen color_cat1 = .
				gen color_cat2 = .
				
				summ seq_cat1
				local share = `r(mean)'
				summ id 
				replace color_cat1 = id <= int(`share' * `r(max)')
				
				summ seq_cat2
				local share = `r(mean)'
				summ id 
				replace color_cat2 = id <= int(`share' * `r(max)')
			}
			
			replace category = color_cat1
			replace category = 2 if color_cat2 == 1 & category == 0
			
			
		*reverse structure for wide 
			if "`wide'" != "" {
				local y x
				local x y
			}

			else {
				local y y 
				local x x
			}
			
		*allow legends when multiple variables specified
			if "`legend'" != "" {
				local legend `legend'
				local msize = 5
			}
			
			else {
				local legend legend(off)
			}
			
		*allow msize 
			if "`markersize'" != "" {
				local msize = `markersize'
			}

		*plot charts
			if "`by'" != "" {
				if "`byrows'" != "" {
					local byr = `byrows'
				}
				
				/*
				twoway	(scatter `y' `x' if `touse' & category == 1, ///
							msymbol(square) mfcolor("`mcolor1'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///
						(scatter `y' `x' if `touse' & category == 2, ///
							msymbol(square) mfcolor("`mcolor2'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///
						(scatter `y' `x' if `touse' & category == 0, ///
							msymbol(square) mfcolor("`ecolor'") ///
							mlwidth(vthin) mlcolor("`eocolor'") msize(`msize') ///
						ytitle("") yscale(noline) ylabel(, nogrid noticks nolabels) ///
						xtitle("") xscale(noline) xlabel(, nogrid noticks nolabels) ///
						legend(off) aspectratio(`aspectratio')					 	///
						by(`byvar', `legend' noiyaxes noixaxes noiytick 		///
							noixtick noiylabel noixlabel note("`note'")				///
							title(`title_by')) 										///
						subtitle(, nobox) scheme(`scheme') `name')
				*/
				
				di as err "by() cannot be used with multiple variables. Feature will be added later. You could try plotting separately and combining."
				
			}
			
			else {
				twoway	(scatter `y' `x' if `touse' & category == 1, ///
							msymbol(square) mfcolor("`mcolor1'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///
						(scatter `y' `x' if `touse' & category == 2, ///
							msymbol(square) mfcolor("`mcolor2'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///	
						(scatter `y' `x' if `touse' & category == 0, ///
							msymbol(square) mfcolor("`ecolor'") ///
							mlwidth(vthin) mlcolor("`eocolor'") msize(`msize') ///
						ytitle("") yscale(noline) ylabel(, nogrid noticks nolabels) ///
						xtitle("") xscale(noline) xlabel(, nogrid noticks nolabels) ///
						`legend' aspectratio(`aspectratio') title(`title_noby')	///
						scheme(`scheme') note("`note'") `name')
			}
	}
	
	// IF THREE VARIABLES SPECIFIED
	else if "`2'" != "" & "`3'" != "" & "`4'" == "" & "`5'" == "" {
		capture keep `1' `2' `3' `byvar' `touse'
		capture duplicates drop `1' `2' `3' `byvar' `touse', force
		
		*transform values to decimals if not
			if `1' > 100 | `2' > 100 | `3' > 100 {
				di as err "Variable does not appear to be a percent or decimal (it is higher than 100)"
				exit 198
			}
			
			if `1' > 1 {
				replace `1' = (`1' / 100)
			}
			
			if `2' > 1 {
				replace `2' = (`2' / 100)
			}
			
			if `3' > 1 {
				replace `2' = (`2' / 100)
			}
		
		*waffle structure
			if "`wide'" != "" {
				local rows = 20
				local cols = 5
				local aspectratio = .20
				local msize = 4
			}
			
			else if "`wide'" == "" {
				local rows = 10
				local cols = 10
				local aspectratio = 1
				local msize = 6
			}
			
		local obsv = `cols' * `rows'
		expand `obsv'
		
		*address issues with non-unique obs 
			if "`by'" == "" & _N > 100 {
				di as err "Variable selection does not uniquely define percent. Try combining with by()"
				exit 198
			}
			
			/*
			duplicates report `1' `2' `byvar'
			local unique_value = `r(unique_value)'
			gen unique_val = `unique_value'
			capture levelsof `byvar'
			capture local groups = `r(r)'
			capture gen groups = `groups'
			gen error_dummy = 0
			capture replace error_dummy = 1 if unique_val > groups		
			if "`by'" != "" & error_dummy == 1 {
				di as err "Variable contains too many unique values. Your by() variable levels must match the number of unique values"
				exit 198
			}
			*/
			
		gen seq_cat1 = `1'
		gen seq_cat2 = seq_cat1 + `2'
		gen seq_cat3 = seq_cat2 + `3'
		
		*by variables
			if "`by'" != "" {
				bysort `byvar' :	egen y = seq(), b(`cols')
								egen x = seq(), t(`cols')
				by `byvar' 	: 	gen id = _n 
				egen tag = tag(`byvar')
				gen category = .
				gen color_cat1 = .
				gen color_cat2 = .
				gen color_cat3 = .
				local msize = 2
				levelsof `byvar', local(lvls)
				
				foreach x of local lvls {
					summ seq_cat1 if `byvar' == `x' & tag == 1
					local share = `r(mean)'
					summ id if `byvar' == `x'
					replace color_cat1 = id <= int(`share' * `r(max)') if `byvar' == `x'
				}
				
				foreach x of local lvls {
					summ seq_cat2 if `byvar' == `x' & tag == 1
					local share = `r(mean)'
					summ id if `byvar' == `x'
					replace color_cat2 = id <= int(`share' * `r(max)') if `byvar' == `x'
				}

				foreach x of local lvls {
					summ seq_cat3 if `byvar' == `x' & tag == 1
					local share = `r(mean)'
					summ id if `byvar' == `x'
					replace color_cat3 = id <= int(`share' * `r(max)') if `byvar' == `x'
				}

			}
			
			else {
				egen y = seq(), b(`cols')
				egen x = seq(), t(`cols')
				gen id = _n 
				gen category = .
				gen color_cat1 = .
				gen color_cat2 = .
				gen color_cat3 = .
				
				summ seq_cat1
				local share = `r(mean)'
				summ id 
				replace color_cat1 = id <= int(`share' * `r(max)')
				
				summ seq_cat2
				local share = `r(mean)'
				summ id 
				replace color_cat2 = id <= int(`share' * `r(max)')
				
				summ seq_cat3
				local share = `r(mean)'
				summ id 
				replace color_cat3 = id <= int(`share' * `r(max)')
			}
			
			replace category = color_cat1
			replace category = 2 if color_cat2 == 1 & category == 0
			replace category = 3 if color_cat3 == 1 & category == 0
			
			
		*reverse structure for wide 
			if "`wide'" != "" {
				local y x
				local x y
			}

			else {
				local y y 
				local x x
			}
			
		*allow legends when multiple variables specified
			if "`legend'" != "" {
				local legend `legend'
				local msize = 5
			}
			
			else {
				local legend legend(off)
			}
			
		*allow msize 
			if "`markersize'" != "" {
				local msize = `markersize'
			}

		*plot charts
			if "`by'" != "" {
				
				/*
				twoway	(scatter `y' `x' if `touse' & category == 1, ///
							msymbol(square) mfcolor("`mcolor1'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///
						(scatter `y' `x' if `touse' & category == 2, ///
							msymbol(square) mfcolor("`mcolor2'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///
						(scatter `y' `x' if `touse' & category == 0, ///
							msymbol(square) mfcolor("`ecolor'") ///
							mlwidth(vthin) mlcolor("`eocolor'") msize(`msize') ///
						ytitle("") yscale(noline) ylabel(, nogrid noticks nolabels) ///
						xtitle("") xscale(noline) xlabel(, nogrid noticks nolabels) ///
						legend(off) aspectratio(`aspectratio')					 	///
						by(`byvar', `legend' noiyaxes noixaxes noiytick 		///
							noixtick noiylabel noixlabel note("`note'")				///
							title(`title_by')) 										///
						subtitle(, nobox) scheme(`scheme') `name')
				*/
				
				di as err "by() cannot be used with multiple variables. Feature will be added later. You could try plotting separately and combining."
				
			}
			
			else {
				twoway	(scatter `y' `x' if `touse' & category == 1, ///
							msymbol(square) mfcolor("`mcolor1'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///
						(scatter `y' `x' if `touse' & category == 2, ///
							msymbol(square) mfcolor("`mcolor2'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///
						(scatter `y' `x' if `touse' & category == 3, ///
							msymbol(square) mfcolor("`mcolor3'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///	
						(scatter `y' `x' if `touse' & category == 0, ///
							msymbol(square) mfcolor("`ecolor'") ///
							mlwidth(vthin) mlcolor("`eocolor'") msize(`msize') ///
						ytitle("") yscale(noline) ylabel(, nogrid noticks nolabels) ///
						xtitle("") xscale(noline) xlabel(, nogrid noticks nolabels) ///
						`legend' aspectratio(`aspectratio') title(`title_noby')	///
						scheme(`scheme') note("`note'") `name')
			}
	}
	
	// IF FOUR VARIABLES SPECIFIED
	else if "`2'" != "" & "`3'" != "" & "`4'" != "" & "`5'" == "" {
		capture keep `1' `2' `3' `4' `byvar' `touse'
		capture duplicates drop `1' `2' `3' `4' `byvar' `touse', force
		
		*transform values to decimals if not
			if `1' > 100 | `2' > 100 | `3' > 100 | `4' > 100 {
				di as err "Variable does not appear to be a percent or decimal (it is higher than 100)"
				exit 198
			}
			
			if `1' > 1 {
				replace `1' = (`1' / 100)
			}
			
			if `2' > 1 {
				replace `2' = (`2' / 100)
			}
			
			if `3' > 1 {
				replace `2' = (`2' / 100)
			}
			if `4' > 1 {
				replace `4' = (`4' / 100)
			}
		
		*waffle structure
			if "`wide'" != "" {
				local rows = 20
				local cols = 5
				local aspectratio = .20
				local msize = 4
			}
			
			else if "`wide'" == "" {
				local rows = 10
				local cols = 10
				local aspectratio = 1
				local msize = 6
			}
			
		local obsv = `cols' * `rows'
		expand `obsv'
		
		*address issues with non-unique obs 
			if "`by'" == "" & _N > 100 {
				di as err "Variable selection does not uniquely define percent. Try combining with by()"
				exit 198
			}
			
			/*
			duplicates report `1' `2' `byvar'
			local unique_value = `r(unique_value)'
			gen unique_val = `unique_value'
			capture levelsof `byvar'
			capture local groups = `r(r)'
			capture gen groups = `groups'
			gen error_dummy = 0
			capture replace error_dummy = 1 if unique_val > groups		
			if "`by'" != "" & error_dummy == 1 {
				di as err "Variable contains too many unique values. Your by() variable levels must match the number of unique values"
				exit 198
			}
			*/
			
		gen seq_cat1 = `1'
		gen seq_cat2 = seq_cat1 + `2'
		gen seq_cat3 = seq_cat2 + `3'
		gen seq_cat4 = seq_cat3 + `4'
		
		*by variables
			if "`by'" != "" {
				bysort `byvar' :	egen y = seq(), b(`cols')
								egen x = seq(), t(`cols')
				by `byvar' 	: 	gen id = _n 
				egen tag = tag(`byvar')
				gen category = .
				gen color_cat1 = .
				gen color_cat2 = .
				gen color_cat3 = .
				gen color_cat4 = .
				local msize = 2
				levelsof `byvar', local(lvls)
				
				foreach x of local lvls {
					summ seq_cat1 if `byvar' == `x' & tag == 1
					local share = `r(mean)'
					summ id if `byvar' == `x'
					replace color_cat1 = id <= int(`share' * `r(max)') if `byvar' == `x'
				}
				
				foreach x of local lvls {
					summ seq_cat2 if `byvar' == `x' & tag == 1
					local share = `r(mean)'
					summ id if `byvar' == `x'
					replace color_cat2 = id <= int(`share' * `r(max)') if `byvar' == `x'
				}

				foreach x of local lvls {
					summ seq_cat3 if `byvar' == `x' & tag == 1
					local share = `r(mean)'
					summ id if `byvar' == `x'
					replace color_cat3 = id <= int(`share' * `r(max)') if `byvar' == `x'
				}
				
				foreach x of local lvls {
					summ seq_cat4 if `byvar' == `x' & tag == 1
					local share = `r(mean)'
					summ id if `byvar' == `x'
					replace color_cat4 = id <= int(`share' * `r(max)') if `byvar' == `x'
				}

			}
			
			else {
				egen y = seq(), b(`cols')
				egen x = seq(), t(`cols')
				gen id = _n 
				gen category = .
				gen color_cat1 = .
				gen color_cat2 = .
				gen color_cat3 = .
				gen color_cat4 = .
				
				summ seq_cat1
				local share = `r(mean)'
				summ id 
				replace color_cat1 = id <= int(`share' * `r(max)')
				
				summ seq_cat2
				local share = `r(mean)'
				summ id 
				replace color_cat2 = id <= int(`share' * `r(max)')
				
				summ seq_cat3
				local share = `r(mean)'
				summ id 
				replace color_cat3 = id <= int(`share' * `r(max)')
				
				summ seq_cat4
				local share = `r(mean)'
				summ id 
				replace color_cat4 = id <= int(`share' * `r(max)')

			}
			
			replace category = color_cat1
			replace category = 2 if color_cat2 == 1 & category == 0
			replace category = 3 if color_cat3 == 1 & category == 0
			replace category = 4 if color_cat4 == 1 & category == 0
			
			
		*reverse structure for wide 
			if "`wide'" != "" {
				local y x
				local x y
			}

			else {
				local y y 
				local x x
			}
			
		*allow legends when multiple variables specified
			if "`legend'" != "" {
				local legend `legend'
				local msize = 5
			}
			
			else {
				local legend legend(off)
			}
			
		*allow msize 
			if "`markersize'" != "" {
				local msize = `markersize'
			}

		*plot charts
			if "`by'" != "" {
				
				/*
				twoway	(scatter `y' `x' if `touse' & category == 1, ///
							msymbol(square) mfcolor("`mcolor1'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///
						(scatter `y' `x' if `touse' & category == 2, ///
							msymbol(square) mfcolor("`mcolor2'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///
						(scatter `y' `x' if `touse' & category == 0, ///
							msymbol(square) mfcolor("`ecolor'") ///
							mlwidth(vthin) mlcolor("`eocolor'") msize(`msize') ///
						ytitle("") yscale(noline) ylabel(, nogrid noticks nolabels) ///
						xtitle("") xscale(noline) xlabel(, nogrid noticks nolabels) ///
						legend(off) aspectratio(`aspectratio')					 	///
						by(`byvar', `legend' noiyaxes noixaxes noiytick 		///
							noixtick noiylabel noixlabel note("`note'")				///
							title(`title_by')) 										///
						subtitle(, nobox) scheme(`scheme') `name')
				*/
				
				di as err "by() cannot be used with multiple variables. Feature will be added later. You could try plotting separately and combining."
				
			}
			
			else {
				twoway	(scatter `y' `x' if `touse' & category == 1, ///
							msymbol(square) mfcolor("`mcolor1'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///
						(scatter `y' `x' if `touse' & category == 2, ///
							msymbol(square) mfcolor("`mcolor2'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///
						(scatter `y' `x' if `touse' & category == 3, ///
							msymbol(square) mfcolor("`mcolor3'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///	
						(scatter `y' `x' if `touse' & category == 4, ///
							msymbol(square) mfcolor("`mcolor4'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///	
						(scatter `y' `x' if `touse' & category == 0, ///
							msymbol(square) mfcolor("`ecolor'") ///
							mlwidth(vthin) mlcolor("`eocolor'") msize(`msize') ///
						ytitle("") yscale(noline) ylabel(, nogrid noticks nolabels) ///
						xtitle("") xscale(noline) xlabel(, nogrid noticks nolabels) ///
						`legend' aspectratio(`aspectratio') title(`title_noby')	///
						scheme(`scheme') note("`note'") `name')
			}
	}
	
	// IF FIVE VARIABLES SPECIFIED
	else if "`2'" != "" & "`3'" != "" & "`4'" != "" & "`5'" != "" {
		capture keep `1' `2' `3' `4' `5' `byvar' `touse'
		capture duplicates drop `1' `2' `3' `4' `5' `byvar' `touse', force
		
		*transform values to decimals if not
			if `1' > 100 | `2' > 100 | `3' > 100 | `4' > 100 | `5' > 100 {
				di as err "Variable does not appear to be a percent or decimal (it is higher than 100)"
				exit 198
			}
			
			if `1' > 1 {
				replace `1' = (`1' / 100)
			}
			
			if `2' > 1 {
				replace `2' = (`2' / 100)
			}
			
			if `3' > 1 {
				replace `2' = (`2' / 100)
			}
			
			if `4' > 1 {
				replace `4' = (`4' / 100)
			}
			
			if `5' > 1 {
				replace `5' = (`5' / 100)
			}
		
		*waffle structure
			if "`wide'" != "" {
				local rows = 20
				local cols = 5
				local aspectratio = .20
				local msize = 4
			}
			
			else if "`wide'" == "" {
				local rows = 10
				local cols = 10
				local aspectratio = 1
				local msize = 6
			}
			
		local obsv = `cols' * `rows'
		expand `obsv'
		
		*address issues with non-unique obs 
			if "`by'" == "" & _N > 100 {
				di as err "Variable selection does not uniquely define percent. Try combining with by()"
				exit 198
			}
			
			/*
			duplicates report `1' `2' `byvar'
			local unique_value = `r(unique_value)'
			gen unique_val = `unique_value'
			capture levelsof `byvar'
			capture local groups = `r(r)'
			capture gen groups = `groups'
			gen error_dummy = 0
			capture replace error_dummy = 1 if unique_val > groups		
			if "`by'" != "" & error_dummy == 1 {
				di as err "Variable contains too many unique values. Your by() variable levels must match the number of unique values"
				exit 198
			}
			*/
			
		gen seq_cat1 = `1'
		gen seq_cat2 = seq_cat1 + `2'
		gen seq_cat3 = seq_cat2 + `3'
		gen seq_cat4 = seq_cat3 + `4'
		gen seq_cat5 = seq_cat4 + `5'
		
		*by variables
			if "`by'" != "" {
				bysort `byvar' :	egen y = seq(), b(`cols')
								egen x = seq(), t(`cols')
				by `byvar' 	: 	gen id = _n 
				egen tag = tag(`byvar')
				gen category = .
				gen color_cat1 = .
				gen color_cat2 = .
				gen color_cat3 = .
				gen color_cat4 = .
				gen color_cat5 = .
				local msize = 2
				levelsof `byvar', local(lvls)
				
				foreach x of local lvls {
					summ seq_cat1 if `byvar' == `x' & tag == 1
					local share = `r(mean)'
					summ id if `byvar' == `x'
					replace color_cat1 = id <= int(`share' * `r(max)') if `byvar' == `x'
				}
				
				foreach x of local lvls {
					summ seq_cat2 if `byvar' == `x' & tag == 1
					local share = `r(mean)'
					summ id if `byvar' == `x'
					replace color_cat2 = id <= int(`share' * `r(max)') if `byvar' == `x'
				}

				foreach x of local lvls {
					summ seq_cat3 if `byvar' == `x' & tag == 1
					local share = `r(mean)'
					summ id if `byvar' == `x'
					replace color_cat3 = id <= int(`share' * `r(max)') if `byvar' == `x'
				}
				
				foreach x of local lvls {
					summ seq_cat4 if `byvar' == `x' & tag == 1
					local share = `r(mean)'
					summ id if `byvar' == `x'
					replace color_cat4 = id <= int(`share' * `r(max)') if `byvar' == `x'
				}
				
				foreach x of local lvls {
					summ seq_cat5 if `byvar' == `x' & tag == 1
					local share = `r(mean)'
					summ id if `byvar' == `x'
					replace color_cat5 = id <= int(`share' * `r(max)') if `byvar' == `x'
				}
			}
			
			else {
				egen y = seq(), b(`cols')
				egen x = seq(), t(`cols')
				gen id = _n 
				gen category = .
				gen color_cat1 = .
				gen color_cat2 = .
				gen color_cat3 = .
				gen color_cat4 = .
				gen color_cat5 = .
				
				summ seq_cat1
				local share = `r(mean)'
				summ id 
				replace color_cat1 = id <= int(`share' * `r(max)')
				
				summ seq_cat2
				local share = `r(mean)'
				summ id 
				replace color_cat2 = id <= int(`share' * `r(max)')
				
				summ seq_cat3
				local share = `r(mean)'
				summ id 
				replace color_cat3 = id <= int(`share' * `r(max)')
				
				summ seq_cat4
				local share = `r(mean)'
				summ id 
				replace color_cat4 = id <= int(`share' * `r(max)')
				
				summ seq_cat5
				local share = `r(mean)'
				summ id 
				replace color_cat5 = id <= int(`share' * `r(max)')

			}
			
			replace category = color_cat1
			replace category = 2 if color_cat2 == 1 & category == 0
			replace category = 3 if color_cat3 == 1 & category == 0
			replace category = 4 if color_cat4 == 1 & category == 0
			replace category = 5 if color_cat5 == 1 & category == 0
			
		*reverse structure for wide 
			if "`wide'" != "" {
				local y x
				local x y
			}

			else {
				local y y 
				local x x
			}
			
		*allow legends when multiple variables specified
			if "`legend'" != "" {
				local legend `legend'
				local msize = 5
			}
			
			else {
				local legend legend(off)
			}
			
		*allow msize 
			if "`markersize'" != "" {
				local msize = `markersize'
			}

		*plot charts
			if "`by'" != "" {
				
				/*
				twoway	(scatter `y' `x' if `touse' & category == 1, ///
							msymbol(square) mfcolor("`mcolor1'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///
						(scatter `y' `x' if `touse' & category == 2, ///
							msymbol(square) mfcolor("`mcolor2'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///
						(scatter `y' `x' if `touse' & category == 0, ///
							msymbol(square) mfcolor("`ecolor'") ///
							mlwidth(vthin) mlcolor("`eocolor'") msize(`msize') ///
						ytitle("") yscale(noline) ylabel(, nogrid noticks nolabels) ///
						xtitle("") xscale(noline) xlabel(, nogrid noticks nolabels) ///
						legend(off) aspectratio(`aspectratio')					 	///
						by(`byvar', `legend' noiyaxes noixaxes noiytick 		///
							noixtick noiylabel noixlabel note("`note'")				///
							title(`title_by')) 										///
						subtitle(, nobox) scheme(`scheme') `name')
				*/
				
				di as err "by() cannot be used with multiple variables. Feature will be added later. You could try plotting separately and combining."
				
			}
			
			else {
				twoway	(scatter `y' `x' if `touse' & category == 1, ///
							msymbol(square) mfcolor("`mcolor1'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///
						(scatter `y' `x' if `touse' & category == 2, ///
							msymbol(square) mfcolor("`mcolor2'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///
						(scatter `y' `x' if `touse' & category == 3, ///
							msymbol(square) mfcolor("`mcolor3'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///	
						(scatter `y' `x' if `touse' & category == 4, ///
							msymbol(square) mfcolor("`mcolor4'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///	
						(scatter `y' `x' if `touse' & category == 5, ///
							msymbol(square) mfcolor("`mcolor4'") ///
							mlwidth(vthin) mlcolor("`ocolor'") msize(`msize')) ///	
						(scatter `y' `x' if `touse' & category == 0, ///
							msymbol(square) mfcolor("`ecolor'") ///
							mlwidth(vthin) mlcolor("`eocolor'") msize(`msize') ///
						ytitle("") yscale(noline) ylabel(, nogrid noticks nolabels) ///
						xtitle("") xscale(noline) xlabel(, nogrid noticks nolabels) ///
						`legend' aspectratio(`aspectratio') title(`title_noby')	///
						scheme(`scheme') note("`note'") `name')
			}
	}
}
restore
end
