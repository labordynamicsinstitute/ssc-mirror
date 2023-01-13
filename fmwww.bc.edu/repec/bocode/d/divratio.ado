/*
divratio
version 14.2
version date 04nov2022

This file outputs diversion ratios based on the semiparametric model (see Raval, 
Rosenbaum, and Tenn (2017)), with flexible options.

Arguments:
	1. a_side - Indicator variable for which observations belong to the A-side
	2. b_side - Indicator variable for which observations belong to the B-side
	3. hosp_id - Hospital ID (e.g., the name of the medical center)
	4. owner_id - Ownership structure ID (e.g., the common healthcare group, or "system", that owns the hospitals in hosp_id)
	5. geo - Geographic reference categorical variable (for example, this could be ZIP code)
	6. prod - Products offered by the firms to overlap (for example, this could be DRG or MDC)
Options:
	groups(varlist) - Patient characteristic variables to define groups.
	wtp - If specified, also conducts WTP analysis. 
	weight(varlist) - Weight for each observation in the data. For example, if data is aggregated, specify as variable that represents number of discharges per observation.
	ungrouped(string) - Instructions on what to do with observations that cannot be grouped. Can either keep them ("keep") or drop them ("drop"). If unspecified, will drop ungrouped observations.
	allow_within - Allows hospital-to-hospital diversions within the same ownership group.
	replacement - Groups variables based off of resampling with replacement. 
	geo_ref(string) - Identify whether geographic region has A-side focus ("a-side"), B-side focus ("b-side"), combined ("combined") or union focus ("union"). Default is union focus. If all
					  geographic regions to be used, specify `svc_pct' as 100.
	prod_ref(string) - Identify whether products considered have A-side focus ("a-side"), B-side focus ("b-side"), or overlap focus ("overlap"). Default is overlap focus. If all 
					   products are to be used, input "union".
	svc_pct(integer 100) - Percent service area based on "geo_ref" specification, will use 100% service area as default.
	min_group_size(integer 20) - Minimum number of observations in a bin, will use 20 as a default. Represents the tuning parameter in Raval, et. al.
	outside_cutoff(real 0.005) - Cutoff in terms of relative size (share) to be considered as an "outside option", will use 0.005 as default.
	topcode(real 0.99) - A percentage to ensure probabilities are < 1 for WTP calculations (since otherwise WTP is undefined).
	inter_input(string) - Input file from previous intermediate step (X Service Area Group Probabilities.dta) to save time in later executions of the program.
	save_inter(string) - Directory to save intermediate files. Default will not save the files.
	output(string) - Directory to save the results. Default will not save the file.
	disp_str(integer 30) - Number of string characters to display in results.
Version updates:
	1.1 - adds in geo_ref and prod_ref to allow flexibility with respect to which
		  side's geography/products to focus on.
	1.2 - fixes error when bin sizes are too small; keeps parties' firm location
		  even when its share is below the threshold.
	1.3 - adds in a way to compute diversions with aggregated data.
	1.4 - adds in option to exclude diversions within firm, add in inter_input().
	1.5 - alters some options to use strings instead of integers, adds in binning without resampling.
	1.6 - adds "if" option, cleans up output, and includes command to drop 
		  unbinned observations. Also includes "combined" option for geo_ref command.
	1.7 - adds in WTP results.
	
Author: Chris Lau, clau@ftc.gov, chris.vlau@gmail.com
*/
program define divratio, rclass
	version 14.2

	syntax varlist(min=6) [if] [, groups(varlist) wtp weight(varlist) allow_within ungrouped(string) replacement geo_ref(string) prod_ref(string) svc_pct(integer 100) outside_cutoff(real 0.005) topcode(real 0.99) min_group_size(integer 20) inter_input(string) save_inter(string) output(string) disp_str(integer 30)]
	
	// Parse variable list //
	tokenize `varlist'
	args a_side b_side hosp_id owner_id geo prod
	
	// Step 0: Display primatives //
	display("")
	display("{bf:Semiparametric Estimation}")
	
	display("")
	display("{ul:Selected Options:}")
	
	// Set locals for file names //
	if "`output'" != "" {
			qui local results = "`output'"
			display("- Diversion results are saved to: `results'")
			if "`wtp'" != "" {
				qui local wtp_results = "`save_inter'\Results - Willingness-to-pay.dta" 
				display("- WTP results are saved to: `wtp_results'")
				}
			}
	if "`save_inter'" != "" {
		qui local svc_area_name_1 = "`save_inter'\\RAW - A-side `svc_pct' Service Area Regions.dta"
		qui local svc_area_name_2 = "`save_inter'\\RAW - B-side `svc_pct' Service Area Regions.dta"
		qui local svc_area_samp_1 = "`save_inter'\\RAW - A-side `svc_pct' Service Area Sample.dta"
		qui local svc_area_samp_2 = "`save_inter'\\RAW - B-side `svc_pct' Service Area Sample.dta"
		qui local svc_area_name = "`save_inter'\\RAW - Combined `svc_pct' Service Area Regions.dta"
		qui local svc_area_samp = "`save_inter'\\RAW - Combined `svc_pct' Service Area Sample.dta"
		qui local prods_1 = "`save_inter'\\RAW - A-side Products.dta"
		qui local prods_2 = "`save_inter'\\RAW - B-side Products.dta"
		qui local overlapprods = "`save_inter'\\RAW - Overlapping Products.dta"
		qui local full_samp = "`save_inter'\\RAW - `svc_pct' Service Area Overlapping Products Sample.dta"
		qui local choiceset = "`save_inter'\\RAW -  Choice Set.dta"
		qui local choices_samp = "`save_inter'\\RAW - Panel Estimation Sample.dta"
		qui local bindata_final "`save_inter'\\Results - Choice Probabilities.dta"
		qui local tempdata = "`save_inter'\\tempdata.dta"
		qui local bindata = "`save_inter'\\RAW - Probabilities by Group.dta"
		if "`wtp'" != "" {
			qui local wtp_raw = "`save_inter'\\RAW - All Pre- and Post-merger WTP.dta"
			}
		if "`output'" == "" {
			qui local results = "`save_inter'\Results - Diversions.dta" 
			display("- Diversion Results are saved to: `results'")
			if "`wtp'" != "" {
				qui local wtp_results = "`save_inter'\Results - Willingness-to-pay.dta" 
				display("- WTP results are saved to: `wtp_results'")
				}
			}
		}
	
	// Display selected options //
	if "`inter_input'" == "" {
		if "`agg'" == "" {
			qui gen num = 1
			}
		else {
			display("- Data is aggregated; variable '`agg'' represents number of individuals")
			qui gen num = `agg'
			}
		if "`geo_ref'" == "a-side" {
			display("- Reference service area is: A-side")
			}
		else if "`geo_ref'" == "b-side" {
			display("- Reference service area is: B-side")
			}
		else if "`geo_ref'" == "combined" {
			display("- Reference service area is: Combined")
			}
		else {
			display("- Reference service area is: Union")
			}
		if "`prod_ref'" == "a-side" {
			display("- Reference product is for: A-side")
			}
		else if "`prod_ref'" == "b-side" {
			display("- Reference product is for: B-side")
			}
		else if "`prod_ref'" == "union" {
			display("- Reference product is for: Union")
			}
		else {
			display("- Reference product is for: Overlapping")
			}
		display("- Service area: `svc_pct'%")
		if length("`if'") > 0 {
			local restrict = subinstr("`if'", "if ", "", 1)
			display("- Restricted on: `restrict'")
			}
		if "`groups'" != "" {
			display("- Variables used to create groups: `groups'")
			}
		else {
			display("- Variables used to create groups: None")
			}
		display("- Minimum group size: `min_group_size'")
		display("- Minimum share to be counted as a choice: `outside_cutoff'")
		if "`replacement'" == "" {
			display("- Groups constructed without replacement")
			}
		else {
			display("- Groups constructed with replacement")
			}
		if "`allow_within'" != "" {
			display("- Allow within system diversion: Yes")
			}
		else {
			display("- Allow within system diversion: No")
			}
		if "`wtp'" != "" {
			display("- Topcode for WTP: `topcode'")
			}

		// Step 1: Find service areas //	
		*timer on 1
		** Identify reference firms **
		capture drop ref_firm*
		qui gen ref_firm1 = (`a_side' == 1)
		local ref_firm1_name = "A-side"
		qui gen ref_firm2 = (`b_side' == 1)
		local ref_firm2_name = "B-side"
		
		display ""
		display("{ul:Intermediate Calculations:}")
		
		if "`geo_ref'" == "combined" {
			if `svc_pct' < 100 {
				preserve
					if length("`if'") > 0 {
						quietly keep `if'
						}
					qui gen num_ref_firm = num*(ref_firm1 + ref_firm2)
					collapse (sum) obs = num_ref_firm (sum) totalObs = num, by(`geo')
					
					* Calculate geo and firm shares *
					qui egen total = sum(obs)
					qui gen geoshare = obs / total
					qui gen firmshare = obs/totalObs	
					
					* Sort by cumulative share *
					qui gsort -geoshare `geo'
					qui gen cumshare = sum(geoshare)
					
					* Create market shares *
					qui gen obsSum = sum(obs)
					qui gen totalObsSum = sum(totalObs)
					qui gen market_share = obsSum/totalObsSum
					
					* Drop observations not in service areas *
					qui gen svc = (cumshare[_n-1] < `svc_pct'/100)
					qui replace svc = 1 if _n == 1
					qui keep if svc == 1
					
					* Keep relative variables *
					qui keep `geo' cumshare firmshare totalObs geoshare obs market_share
					
					* Display service area stats *
					qui count
					display "- There are " r(N) " geographic regions in the combined `svc_pct'% service area."
					
					* Save file *
					if "`save_inter'" == "" {
						qui tempfile svc_area_name
						qui save "`svc_area_name'"
						}
					else {
						qui save "`svc_area_name'", replace
						}
				restore
				}
				
				preserve
					if length("`if'") > 0 {
						quietly keep `if'
						}
							
					* Keep observations that are in the service area *
					capture drop _merge
					if `svc_pct' < 100 {
						qui merge m:1 `geo' using "`svc_area_name'", keep(matched) keepusing(`geo') nogen
					}
					if "`save_inter'" == "" {
						qui tempfile svc_area_samp
						qui save "`svc_area_samp'"
						}
					else {
						qui save "`svc_area_samp'", replace
						}
					forvalues svc_base = 1(1)2 {
						qui use "`svc_area_samp'", clear
						if "`prod_ref'" != "union" {
							* Keep products that are in the service area *
							qui keep if ref_firm`svc_base' == 1
							}
						qui keep `prod'
						qui duplicates drop
						
						if "`save_inter'" == "" {	
							qui tempfile prods_`svc_base'
							qui save "`prods_`svc_base''"
							}
						else {		
							qui save "`prods_`svc_base''", replace
							}
						}
				restore
			}
		
		if "`geo_ref'" != "combined" {
			forvalues svc_base = 1(1)2 {
				** Identify service area for each side **
				if `svc_pct' < 100 {
					preserve
						if length("`if'") > 0 {
							quietly keep `if'
							}
						qui gen num_ref_firm`svc_base' = num*ref_firm`svc_base'
						collapse (sum) obs = num_ref_firm`svc_base' (sum) totalObs = num, by(`geo')
						
						* Calculate geo and firm shares *
						qui egen total = sum(obs)
						qui gen geoshare = obs / total
						qui gen firmshare = obs/totalObs	
						
						* Sort by cumulative share *
						qui gsort -geoshare `geo'
						qui gen cumshare = sum(geoshare)
						
						* Create market shares *
						qui gen obsSum = sum(obs)
						qui gen totalObsSum = sum(totalObs)
						qui gen market_share = obsSum/totalObsSum
						
						* Drop observations not in service areas *
						qui gen svc = (cumshare[_n-1] < `svc_pct'/100)
						qui replace svc = 1 if _n == 1
						qui keep if svc == 1
						
						* Keep relative variables *
						qui keep `geo' cumshare firmshare totalObs geoshare obs market_share
						
						* Display service area stats *
						qui count
						if "`geo_ref'" == lower("`ref_firm`svc_base'_name'") | "`geo_ref'" == "union" {
							display "- There are " r(N) " geographic regions in the `ref_firm`svc_base'_name''s `svc_pct'% service area."
							}
						
						* Save file *
						if "`save_inter'" == "" {
							qui tempfile svc_area_name_`svc_base'
							qui save "`svc_area_name_`svc_base''"
							}
						else {
							qui save "`svc_area_name_`svc_base''", replace
							}
					restore
					}
				
				preserve
					if length("`if'") > 0 {
						quietly keep `if'
						}
							
					* Keep observations that are in the service area *
					capture drop _merge
					if `svc_pct' < 100 {
						qui merge m:1 `geo' using "`svc_area_name_`svc_base''", keep(matched) keepusing(`geo') nogen
					}
					if "`save_inter'" == "" {
						qui tempfile svc_area_samp_`svc_base'
						qui save "`svc_area_samp_`svc_base''"
						}
					else {
						qui save "`svc_area_samp_`svc_base''", replace
						}
					
					if "`prod_ref'" != "union" {
						* Keep products that are in the service area *
						qui keep if ref_firm`svc_base' == 1
						}
					qui keep `prod'
					qui duplicates drop
					
					if "`save_inter'" == "" {	
						qui tempfile prods_`svc_base'
						qui save "`prods_`svc_base''"
						}
					else {		
						qui save "`prods_`svc_base''", replace
						}
				restore
				}
			}
		*timer off 1
		*timer list 1
		// Step 2: Identify relevant products //
			// If `prod_ref' == "overlap", (default) use overlapping products of A-side and B-side.
			// If `prod_ref' == "a-side", use all products from A-side.
			// If `prod_ref' == "b-side", use all products from B-side.
			// If `prod_ref' == "union", use all products. 
		*timer on 2
		preserve
			if "`prod_ref'" == "a-side" {
				qui use "`prods_1'", clear
				}
			else if "`prod_ref'" == "b-side" {
				qui use "`prods_2'", clear
				}
			else{
				qui use "`prods_1'", clear
				if "`prod_ref'" == "union" {
					qui merge 1:1 `prod' using "`prods_2'", nogen
					}
				else {
					qui merge 1:1 `prod' using "`prods_2'", keep(3) nogen
					}
				}
			
			* Display overlapping product stats *
			qui count
			if "`prod_ref'" == "a-side" {
				display "- There are " r(N) " products for the A-side."
				}
			else if "`prod_ref'" == "b-side" {
				display "- There are " r(N) " products for the B-side."
				}
			else if "`prod_ref'" == "union" {
				display "- All prodcuts are being used."
				}
			else {
				display "- There are " r(N) " overlapping products between the A-side and B-side."
				}
		
			* Save file *
			if "`save_inter'" == "" {
				qui tempfile overlapprods
				qui save "`overlapprods'"
				}
			else {
				qui save "`overlapprods'", replace
				}
		restore
		
		* Create usable dataset limiting to observations within service area and relevant products *
		preserve
			if "`geo_ref'" == "a-side" {
				qui use "`svc_area_samp_1'", clear
				}
			else if "`geo_ref'" == "b-side" {
				qui use "`svc_area_samp_2'", clear
				}
			else if "`geo_ref'" == "combined" {
				qui use "`svc_area_samp'", clear
				}
			else {
				qui use "`svc_area_samp_1'", clear
				qui append using "`svc_area_samp_2'"
				}
			qui duplicates drop
			qui merge m:1 `prod' using "`overlapprods'", keep(3) nogen
				
			qui drop ref_firm*
			qui tabstat num, s(sum) save
			matrix A = r(StatTotal)
			qui scalar N = A[1,1]
			display "- There are " N " customers in the estimation sample."
			* Save file *
			if "`save_inter'" == "" {
				qui tempfile full_samp
				qui save "`full_samp'"
				}
			else {
				qui save "`full_samp'", replace
				}
		restore
		*timer off 2
		*timer list 2
		
		// Step 3: Create choice sets for each patient //
		*timer on 3
		preserve
			* Ideintify relevant choice set *
			qui use "`full_samp'", clear
			
			qui gen purchase = num
			qui collapse (sum) purchase, by(`hosp_id' `owner_id' `a_side' `b_side')
			
			qui egen totPurch = sum(purchase)
			qui gen purchShare = purchase/totPurch
			
			* Discard firm locations where there exists a small share *
			qui keep if purchShare > `outside_cutoff' | `a_side' == 1 | `b_side' == 1
			
			* Add in outside option
			qui set obs `=_N+1'
			qui local last = _N
			qui replace `hosp_id' = "Outside" in `last'
		
			qui gen cross = 1
			
			* Display choice set stats *
			qui count
			display "- There are " r(N)-1 " firm locations in the choice set."
			
			* Save File *
			if "`save_inter'" == "" {
				qui tempfile choiceset
				qui save "`choiceset'"
				}
			else {
				qui save "`choiceset'", replace
				}
				
			* Cross choiec set with sample observations *
			qui use "`full_samp'", clear

			qui gen cross = 1
			gen id = _n
			qui rename `hosp_id' `hosp_id'_chosen
			drop `a_side' `b_side' `owner_id'
			qui joinby cross using "`choiceset'"
					
			* Create variable indicating which firm location was observably chosen *
			qui gen obs_choice = num*(`hosp_id' == `hosp_id'_chosen)
			qui egen x = sum(obs_choice), by(id)
			qui replace obs_choice = num if x == 0 & `hosp_id' == "Outside"
			qui replace `hosp_id'_chosen = "Outside" if x == 0
			qui drop x
			
			* Save file *
			if "`save_inter'" == "" {
				qui tempfile choices_samp
				qui save "`choices_samp'"
				}
			else {
				qui save "`choices_samp'", replace
				}
		*timer off 3
		*timer list 3
			
		// Step 4: Estimate bins //
		*timer on 4
			if "`ungrouped'" == "keep" {
				quietly gen all = 1
				local bin_var = "all `groups'"
				}
			else {
				local bin_var = "`groups'"
				}
			local bin_num = wordcount("`bin_var'")+1
			
			qui keep id `hosp_id' `owner_id' `a_side' `b_side' obs_choice `bin_var'
			if "`save_inter'" == "" {
				qui tempfile tempdata
				qui save "`tempdata'"
				qui tempfile bindata
				qui save "`bindata'"
				}
			else {
				qui save "`tempdata'", replace
				qui save "`bindata'", replace
				}
		
			forvalues i = `bin_num'(-1)2{
				qui use "`tempdata'", clear
				
				* Limit to those that were not binned previously if not resampling *
				if "`replacement'" == "" & `i' < `bin_num' {
					qui merge 1:1 id `hosp_id' using "`bindata'", keep(1 3) nogen
					qui gen bin_id0 = 0
					qui egen bin_id_tot = rowtotal(bin_id*)
					qui keep if bin_id_tot == 0
					drop bin_id0 bin_id_tot
					}
				
				* Create bin definition *
				qui tokenize "`bin_var'"
				qui local bin_var = trim(subinword("`bin_var'","``i''","",.))
				*display("- Bin by: `bin_var'")
				
				if _N > 0 {
					* Create unique bin ID
					qui egen bin_id = group(`bin_var')
					qui drop if bin_id == .
					
					* Collapse over bins *
					qui collapse (sum) episodes = obs_choice, by(bin_id `bin_var' `hosp_id') fast
					qui egen bin_tot = total(episodes), by(bin_id)
					
					if `i' > 2 {
						qui drop if bin_tot <= `min_group_size'
						}
					}
				
				* Report statistics *
				if _N == 0 {
					display("- Grouping by: `bin_var'; no obs. used.")
					}
				else {
					quietly sum episodes
					display "- Grouping by: `bin_var'; " round(100*r(sum)/N,0.01) "% of obs. used."
					}
				
				if _N > 0 {
					* Generate bin shares *
					qui gen bin_share`i' = episodes/bin_tot 
					qui bys bin_id: egen check = sum(bin_share`i')
					qui assert abs(1-check)< .001
				
					* Reset Bin ID *
					qui rename bin_id bin_id`i'	
					qui rename bin_tot bin_tot`i' 
				
					* Merge back into data *
					qui keep `bin_var' `hosp_id' bin_share`i' bin_id`i' bin_tot`i'
					qui joinby `bin_var' `hosp_id' using "`bindata'", unmatched(both) update
					qui drop if _merge == 1
					qui drop _merge
				
					if "`save_inter'" == "" {
						qui tempfile bindata
						qui save "`bindata'"
						}
					else {
						qui save "`bindata'", replace
						}
					}
				}
			
			* Combine into single bin variable *
			qui use "`bindata'", clear
			qui gen firm_probBin = .
			qui gen bin_id = .
			qui gen bin_no = .
			qui gen se_Bin = .
			qui gen bin_tot = .
			
			forvalues i = `bin_num'(-1)2 {
				capture sum bin_id`i'
				if _rc == 0 {
					qui local CONDITIONAL "firm_probBin == . & bin_share`i' != ."
					qui replace bin_id = bin_id`i' if `CONDITIONAL'
					qui replace bin_no = `i' if `CONDITIONAL'
					qui replace se_Bin = sqrt(bin_share`i' * (1-bin_share`i') / bin_tot`i') if `CONDITIONAL'
					qui replace bin_tot = bin_tot`i' if `CONDITIONAL'
					qui replace firm_probBin = bin_share`i' if `CONDITIONAL'
					}
				}
			
			* Drop unmatched bins (probabilities do not sum to 1) *
			qui bys id: egen check = sum(firm_probBin)
			qui keep if abs(1-check)< .001
			qui drop check

			* Renew bin ID *
			qui rename bin_id bin_id_old
			qui egen bin_id = group(bin_id_old bin_no)
			
			*qui keep bin_id `hosp_id' `owner_id' firm_probBin bin_tot `a_side' `b_side' `groups'
			*qui duplicates drop
			// Currently patient X choice panel -- each customer belongs to a bin; add up "num" over bin_id
			// and hosp_id to get number of customers in each bin. Add up "firm_probBin" to get expcted number
			// of episodes for each firm within bin
			gen num = 1
			collapse (sum) bin_tot=num episodes=firm_probBin (mean) firm_probBin, by(bin_id `hosp_id' `owner_id' `a_side' `b_side') fast
			
			if "`save_inter'" == "" {
				qui tempfile bindata_final
				qui save "`bindata_final'"
				}
			else {
				qui save "`bindata_final'", replace
				}
				
		*timer off 4
		*timer list 4
		}
	else {
		preserve
		display("- Input intermediate data from: `inter_input'")
		qui levelsof `hosp_id' if `a_side' == 1, local(a_side_firms)
		qui levelsof `hosp_id' if `b_side' == 1, local(b_side_firms)
		qui local bindata_final "`inter_input'"
		qui use "`bindata_final'", clear

		foreach x in "a" "b" {
			capture gen ``x'_side' = 0
			foreach y of local `x'_side_firms {
				qui replace ``x'_side' = 1 if `hosp_id' == "`y'"
				}
			}
		}
		
	// Step 5: Estimate diversions //
	*timer on 5
		* Identify system if allow_within == 1
		if "`allow_within'" == "" {
			qui levelsof `owner_id' if `a_side' == 1, local(a_side_name)
			qui gen ref_comp_a = (`owner_id' == `a_side_name')
			qui levelsof `owner_id' if `b_side' == 1, local(b_side_name)
			qui gen ref_comp_b = (`owner_id' == `b_side_name')
			}
		else {
			qui gen ref_comp_a = `a_side'
			qui gen ref_comp_b = `b_side'
			}
		
		* Compute number diverted to each alternative facility within each bin
		foreach j in "a" "b" {
			* Compute share proportional diversion ratio
			qui gen divert_numerator_omit_`j' = episodes if ref_comp_`j' != 1
			qui egen divert_denominator_omit_`j' = total(divert_numerator_omit_`j'), by(bin_id)
			qui gen bin_diversion_ratio_omit_`j' = divert_numerator_omit_`j' / divert_denominator_omit_`j'
			
			* Find number to divert (total number of episodes - total number at alternative facilities = number to be diverted from facility in question)
			if "`allow_within'" == "" {
				qui gen chose_alternative_to_`j' = episodes if ``j'_side' != 1
				qui egen total_chose_alternative_to_`j' = total(chose_alternative_to_`j'), by(bin_id)
				}
			else {
				qui gen total_chose_alternative_to_`j' = divert_denominator_omit_`j'
				}
			
			qui gen diverted_from_omitted_`j' = bin_tot - total_chose_alternative_to_`j'
			
			* Calculate number diverted from facility in question to each alternative facility
			qui gen num_diverted_`j' = bin_diversion_ratio_omit_`j' * diverted_from_omitted_`j'
		}
		
		qui collapse (sum) num_diverted* episodes, by(`hosp_id' `owner_id' `a_side' `b_side') fast

		* Calcaulte overall diversion ratios
		foreach j in "a" "b" {
			qui egen diversion_ratio_omit_`j' = pc(num_diverted_`j')
		}

		* Calculate shares to include in output
		qui egen shares = pc(episodes)
		
		* Clean up results *
		order `hosp_id' `owner_id' shares diversion_ratio_omit_a diversion_ratio_omit_b episodes num_diverted_a num_diverted_b	
		qui gen sortvar = `a_side' + `b_side'
		qui replace sortvar = -1 if `hosp_id' == "Outside"
		gsort -sortvar -`a_side' -`b_side' `owner_id' `hosp_id'
		
		* Display results *
		display("")
		display("{ul:Diversion Results:}")
		qui gen Hospital = `hosp_id'
		qui gen Owner = `owner_id'
		qui gen Shares = round(shares,0.01)
		qui gen Diversion_Exclude_A = round(diversion_ratio_omit_a,0.001)
		qui gen Diversion_Exclude_B = round(diversion_ratio_omit_b,0.001)
		list Hospital Owner Shares Diversion_Exclude_A Diversion_Exclude_B, nolabel sepby(Owner) table string(`disp_str') compress abbreviate(20)
		qui drop sortvar Hospital Owner Shares Diversion_Exclude_A Diversion_Exclude_B
		
		* Save results *
		if "`save_inter'" != "" | "`output'" != "" {
			foreach var of varlist shares diversion_ratio_omit_a diversion_ratio_omit_b {
				qui replace `var' = `var'/100
				}
			qui save "`results'", replace
			}
			
		mkmat shares diversion_*, matrix(results) rownames(`hosp_id')
		return matrix results results

	// Step 6: Willingness-to-pay //
	if "`wtp'" != "" {
		qui use "`bindata_final'", clear
		qui gen counterfactual = 0
		qui append using "`bindata_final'"
				
		* Assign pre- and post-merger ownership *
		qui replace counterfactual = 1 if counterfactual == .
		
			* Pre-merger ownership *
			gen entity = 0
			qui levelsof `owner_id' if `a_side' == 1, local(a_side_name)
			foreach owner_a of local a_side_name {
				qui replace entity = 1 if `owner_id' == "`owner_a'" & counterfactual == 0
				}
			qui levelsof `owner_id' if `b_side' == 1, local(b_side_name)
			foreach owner_b of local b_side_name {
				qui replace entity = 2 if `owner_id' == "`owner_b'" & counterfactual == 0
				}
			/*qui replace entity = 1 if `a_side' == 1 & counterfactual == 0
			qui replace entity = 2 if `b_side' == 1 & counterfactual == 0*/
		
			* Post-merger ownership *
			qui replace `owner_id' = "MERGED ENTITY" if (`a_side' == 1 | `b_side' == 1) & counterfactual == 1
			qui replace entity = 3 if (`a_side' == 1 | `b_side' == 1) & counterfactual == 1
		
		qui collapse (sum) firm_prob=firm_probBin (mean) bin_tot, by(bin_id `owner_id' entity counterfactual) fast

		* Topcode firm probabilities *
		qui replace firm_prob = `topcode' if firm_prob > `topcode' & firm_prob < .
		
		* Calculate individual WTP
		qui gen wtp = bin_tot*log(1/(1 - firm_prob))
		
		* Aggregate *
		gen episodes = firm_prob*bin_tot
		qui collapse (sum) episodes wtp_agg=wtp, by(`owner_id' entity counterfactual) fast
		qui gen wtp_per = wtp_agg/episodes
		
		* Compute for A-side and B-side
		qui matrix wtp_results = J(5,2,.)
		qui matrix colnames wtp_results = wtp episodes
		qui matrix rownames wtp_results = aside bside merge pctch_agg pctch_per
		
		local j = 1
		foreach x in "wtp_agg" "episodes" {
			qui sum `x' if entity == 1 & counterfactual == 0
			qui matrix wtp_results[1,`j'] = r(sum)
			qui sum `x' if entity == 2 & counterfactual == 0
			qui matrix wtp_results[2,`j'] = r(sum)
			qui sum `x' if entity == 3 & counterfactual == 1
			qui matrix wtp_results[3,`j'] = r(sum)
			local j = `j' + 1
			}

		* Save results *
		if "`save_inter'" != "" {
			qui save "`wtp_raw'", replace
			}
		
		* Calculate percent change in WTP *
			/* Calculate firm weights for WTP-per-person calculation
			qui sum episodes if entity == 1 & counterfactual == 0
			local num_a = r(sum)
			qui sum episodes if entity == 2 & counterfactual == 0
			local num_b = r(sum)
			local weight = `num_a'/(`num_a' + `num_b')*/
			
			local weight = wtp_results[1,2]/(wtp_results[1,2] + wtp_results[2,2])
			qui matrix wtp_results[4,1] = 100*(wtp_results[3,1] - wtp_results[1,1] - wtp_results[2,1])/(wtp_results[1,1] + wtp_results[2,1])
			qui matrix wtp_results[5,1] = 100*((wtp_results[3,1]/wtp_results[3,2]) - `weight'*(wtp_results[1,1]/wtp_results[1,2]) - (1-`weight')*(wtp_results[2,1]/wtp_results[2,2]))/(`weight'*(wtp_results[1,1]/wtp_results[1,2]) + (1-`weight')*(wtp_results[2,1]/wtp_results[2,2]))
			
			* Display results *
			display ""
			display "{ul:WTP Results:}"
			display ""
			display "Percent Change in aggregate WTP is: " wtp_results[4,1] "%"
			display "Percent Change in WTP-per-person is: " wtp_results[5,1] "%"
			
		
		* Save results *
		if "`save_inter'" != "" | "`output'" != "" {
			// Turn matrix into data //
			qui svmat wtp_results
			qui keep wtp_results*
			qui drop if wtp_results1 == .
			qui rename (wtp_results1 wtp_results2) (wtp_agg episodes)
			
			// Label //
			qui label var wtp_agg "Aggregate WTP"
			qui label var episodes "Episodes"
			qui gen var = "A-side"
			qui replace var = "B-side" if _n == 2
			qui replace var = "Merged" if _n == 3
			qui replace var = "Percent Change in Aggregate WTP" if _n == 4
			qui replace var = "Percent Change in WTP-per-person" if _n == 5

			qui order var wtp_agg episodes
			
			qui save "`wtp_results'", replace
		}
		
		return matrix wtp_results = wtp_results, copy
		
		}
		
		
	*timer off 5
	*timer list 5
	restore
	capture qui drop ref_firm* num
end
