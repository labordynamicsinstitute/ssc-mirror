*! v1.1.4 SConcas June242026 Sisinnio Concas concas@usf.edu
capture program drop lodes
program lodes
    version 16.1
    gettoken subcmd 0 : 0, parse(" ,")
    _lodes_parse_subcmd `subcmd'
    lodes_`subcmd' `macval(0)'
    if `"`local'"'!="" { // pass through returns
        c_local `local' `"`value'"'
    }
end

capture program drop _lodes_parse_subcmd
program _lodes_parse_subcmd
    version 16.1
    local l = strlen(`"`0'"')
	if `"`0'"'=="get"											local 0 get
    else if `"`0'"'== substr("area_profile", 1, max(4,`l')) 	local 0 area_profile
	else if `"`0'"'== substr("destination", 1, max(4,`l')) 		local 0 destination
    else if `"`0'"'== substr("inflow_outflow", 1, max(4,`l')) 	local 0 inflow_outflow
	capt mata: assert(st_islmname(st_local("0")))
    if _rc==1 exit _rc
    if _rc {
        di as err `"`0' invalid subcommand"'
        exit 198
    }
    c_local subcmd `"`0'"'
end

********************************************************************************
********************************Get*********************************************
********************************************************************************
capture program drop lodes_get
program lodes_get
		version 16.1
		syntax	[anything(name=state)], ///
				[DATA_type(string)][JOB_type(string) SEGment(string)] ///
				[YEARs(string)] [od_part(string) LODEs_version(string)]	///
				[saveas(string) EXportexcel saveframes]				///
				[replace BRowse CLear]

		// NOTE: we do NOT call `frames reset` here. Doing so would silently
		// destroy any frames the user has open. Instead, downloads run in a
		// dedicated scratch frame (created below) and only frames lodes
		// creates may be overwritten -- and only if the user passes clear.

		// check arguments have been provided
		if "`state'" == "" {
			display as error "{p} You must specify a state abbreviation (e.g., fl). {p_end}"
			exit
		}
		// Normalize state to lower case (LODES URLs and frame names use lower).
		// Done early so downstream validation/frame-collision checks see the
		// canonical form.
		local state = lower("`state'")

		**data type
		local data_type: di lower("`data_type'")
		if "`data_type'" == "" {
			local data_type od
			display as text "{p} Default data type is {result:`data_type'}. To change, setup {input:{it: data_type}}{p_end}"
			*exit
		}
		else if !inlist("`data_type'", "od", "wac", "rac") {
			display as error "{p} You must specify which data type: 'rac', 'wac', or 'od{p_end}"
			exit
		}
		
		** years 
		if "`years'" == "" {
			local years = 2023
			display as text "{p} Using latest year ({result:`years'}) as default. To change, setup {input:{it:years}}{p_end}"
		}
		
		
		**job type 
		local job_type: di upper("`job_type'")
		if "`job_type'" == "" {
			local job_type = "JT00" 
			display as text "{p} Using value of {result:`job_type'} (All Jobs) as default for job type.To change, setup {input:{it:job_type}}{p_end}"
		}

		**segment (only meaningful for WAC and RAC; OD CSVs aren't
		**segmented, so the option is ignored for OD with a warning).
		local segment : di upper("`segment'")
		if "`data_type'" == "od" {
			if "`segment'" != "" {
				display as text "{p} The {input:{it:segment}} option (here: {result:`segment'}) does not apply to {result:OD} data and is being ignored.{p_end}"
				local segment ""
			}
		}
		else {
			if "`segment'" == "" {
				local segment = "S000"
				display as text "{p} Using value of {result:`segment'} (Total number of jobs) as default for segment. To change, setup {input:{it:segment}}{p_end}"
			}
		}

		**O-D file state part (main or aux)
		if "`od_part'" == "" {
			local od_part = "main aux"
			display as text "{p} Using {result:`od_part'} as default for state file in O-D data.To change, setup {input:{it:od_part}}{p_end}"
			
		}
		
		**LODES version
		if "`lodes_version'" == "" {
			local lodes_version = "LODES8"
			display as text "{p} Using {result:`lodes_version'} as default. To change, setup {input:{it:lodes_version}}{p_end}"
		}
		
		// prelim checks and parsing  ------------------------------------------

		// Refuse to clobber pre-existing output frames unless user passes clear.
		// The frames lodes_get creates and leaves behind are:
		//   <state>_xwalk
		//   <state>_<data_type>_<job_type>
		local _lodes_outframes `state'_xwalk `state'_`data_type'_`job_type'
		local _lodes_conflicts
		foreach fr of local _lodes_outframes {
			capture quietly frame `fr': describe
			if _rc == 0 local _lodes_conflicts `_lodes_conflicts' `fr'
		}
		if "`_lodes_conflicts'" != "" {
			if "`clear'" == "" {
				di as error "{p}The following frame(s) already exist: " ///
					"{result:`_lodes_conflicts'}. Pass option {bf:clear} " ///
					"to overwrite, or drop/rename them first.{p_end}"
				exit 110
			}
			foreach fr of local _lodes_conflicts {
				frame drop `fr'
			}
		}

		// Remember the user's entry frame so error paths can restore it.
		local _entry_frame = c(frame)

		// Create a scratch frame for downloads. gzimport's `clear` option wipes
		// the *current* frame's data, so doing this in default would destroy
		// the user's working dataset. We work in the scratch frame instead
		// and only frame-put results into the user-visible output frames.
		local _lodes_scratch __lodes_get_scratch__
		capture frame drop `_lodes_scratch'
		frame create `_lodes_scratch'
		frame change `_lodes_scratch'

		// Detect required user-written packages and, if any are missing,
		// instruct the user to install them and exit. We intentionally do
		// NOT silently install on the user's behalf: the user should know
		// what is being added to their ado-path.
		local _missing_ssc
		foreach d in fframeappend geoinpoly {
			capture which "`d'"
			if _rc local _missing_ssc `_missing_ssc' `d'
		}
		capture which gzimport
		local _missing_gzimport = cond(_rc, 1, 0)

		if "`_missing_ssc'" != "" | `_missing_gzimport' {
			di as error "{p}{bf:lodes} requires the following user-written package(s), which are not currently installed:{p_end}"
			foreach d of local _missing_ssc {
				di as error `"    {bf:`d'} (from SSC) -- install with: {cmd:ssc install `d'}"'
			}
			if `_missing_gzimport' {
				di as error `"    {bf:gzimport} (from GitHub) -- install with: {cmd:net install gzimport, from(https://raw.githubusercontent.com/mdroste/stata-gzimport/master/)}"'
			}
			di as error "{p}Install the missing package(s) and re-run {cmd:lodes get}. (See {bf:help lodes##requirements} for details.){p_end}"

			// Clean up the scratch frame we created above so we don't leave
			// debris behind when we abort.
			capture frame change `_entry_frame'
			capture frame drop `_lodes_scratch'
			exit 199
		}

		
		// (state already lower-cased earlier; see normalization above)

		// parse years
		local years = ustrregexra("`years'", "-", "/")
		qui numlist "`years'", sort
		local years = "`r(numlist)'"

		//make call to download data
		local url_base "https://lehd.ces.census.gov/data/lodes/`lodes_version'/`state'"
		
		**check for mispelled state
		lodes_state_check "`url_base'" "`state'"
		
		**check for data availability 
		lodes_data_check "`state'" "`data_type'" "`years'"
		
		
		*state xwalk reference call (runs in the scratch frame)
		capture qui gzimport delimited using "`url_base'/`state'_xwalk.csv.gz", stringcols(_all) clear
		if _rc {
			local _save_rc = _rc
			di as error `"{p}Failed to download crosswalk for state {result:`state'} from {result:`url_base'/`state'_xwalk.csv.gz} (rc=`_save_rc'). Check network connectivity and that the state has LODES data available.{p_end}"'
			capture frame change `_entry_frame'
			capture frame drop `_lodes_scratch'
			exit `_save_rc'
		}
		capture frame drop `state'_xwalk
		frame put *, into(`state'_xwalk)
		
		
		*dataset call 
		*"https://lehd.ces.census.gov/data/lodes/LODES8/fl/od/fl_od_aux_JT00_2010.csv.gz"
		if "`data_type'" == "od" {
			local files "`od_part'"
			foreach y of local years {
				foreach f of local files {
					capture qui gzimport delimited using "`url_base'/`data_type'/`state'_`data_type'_`f'_`job_type'_`y'.csv.gz" ,stringcols(1 2) clear
					if _rc {
						local _save_rc = _rc
						di as error `"{p}Failed to download {result:`data_type'} data for state {result:`state'}, year {result:`y'}, part {result:`f'}, job type {result:`job_type'} (rc=`_save_rc'). Check network connectivity and per-state year availability in the LODES tech doc.{p_end}"'
						capture frame change `_entry_frame'
						capture frame drop `_lodes_scratch'
						capture frame drop `state'_xwalk
						exit `_save_rc'
					}
					gen year = `y'
					gen od_type = "`f'"
					capture frame drop `state'_`data_type'_`job_type'_`y'_`f'
					frame put *, into(`state'_`data_type'_`job_type'_`y'_`f')
				}
			}
		}

		else {
			foreach y of local years {
				capture qui gzimport delimited using "`url_base'/`data_type'/`state'_`data_type'_`segment'_`job_type'_`y'.csv.gz", stringcols(1) clear
				if _rc {
					local _save_rc = _rc
					di as error `"{p}Failed to download {result:`data_type'} data for state {result:`state'}, year {result:`y'}, segment {result:`segment'}, job type {result:`job_type'} (rc=`_save_rc'). Check network connectivity and per-state year availability in the LODES tech doc.{p_end}"'
					capture frame change `_entry_frame'
					capture frame drop `_lodes_scratch'
					capture frame drop `state'_xwalk
					exit `_save_rc'
				}
				gen year = `y'
				capture frame drop `state'_`data_type'_`job_type'_`y'
				frame put *, into(`state'_`data_type'_`job_type'_`y')
			}
		}


		// Append frames  
		frame create `state'_`data_type'_`job_type'
		frame change `state'_`data_type'_`job_type'
		*frame list 
		if "`data_type'" == "od" {
			local files "`od_part'"
				foreach y of local years {
					foreach f of local files {
						fframeappend, using(`state'_`data_type'_`job_type'_`y'_`f')
						frame drop `state'_`data_type'_`job_type'_`y'_`f'
				}

			}
		}

		else {
			foreach y of local years {
				fframeappend, using(`state'_`data_type'_`job_type'_`y')
				frame drop `state'_`data_type'_`job_type'_`y'
				}
		}



		// Clean up our scratch frame; leave the user's default frame alone.
		// (Previously this dropped the default frame, which destroyed any
		// data the user had loaded before calling lodes.)
		capture frame drop `_lodes_scratch'
		qui frame dir

		//Add links from xwalk file 
		if "`data_type'" == "od" {
			*link frame to identify blocks where workers live (residence block code)
			qui frlink m:1 h_geocode, frame(`state'_xwalk tabblk2020) generate(xwalk_h)
			*link frame to identify blocks where workers work (workplace block code)
			qui frlink m:1 w_geocode, frame(`state'_xwalk tabblk2020) generate(xwalk_w)
		}
		
		if "`data_type'" == "rac" {
			*link frame to identify blocks where workers live (residence block code)
			qui frlink m:1 h_geocode, frame(`state'_xwalk tabblk2020) generate(xwalk_h)
		}
		
		if "`data_type'" == "wac" {
			*link frame to identify blocks where workers work (workplace block code)
			qui frlink m:1 w_geocode, frame(`state'_xwalk tabblk2020) generate(xwalk_w)
		}
		

		// variable labeling
		la var createdate "Year data created"
		la var year "Database year"
		
		if "`data_type'" == "od" {
			la var xwalk_h "Frame link residence block code"
			la var xwalk_w "Frame link workplace block code"
		}
		if "`data_type'" == "rac" {
			la var xwalk_h "Frame link residence block code"
		}
		if "`data_type'" == "wac" {
			la var xwalk_w "Frame link workplace block code"
		}
		
		if "`data_type'" == "od" {
			la var od_type "State part file"
		}
		
		
		//Export Data
		if "`saveas'" != "" {
			local fr_opt
			if "`saveframes'" != "" {
				local fr_opt "saveframes(`state'_xwalk `state'_`data_type'_`job_type')"
			}
			lodes_save_output, saveas(`"`saveas'"') `replace' `fr_opt'
		}

		`browse'

end

********************************************************************************
******************************Destination***************************************
********************************************************************************
capture program drop lodes_destination
program lodes_destination
		version 16.1
		syntax	[anything(name=oname)], 									///
				[origin(string) dname(string) ] 	///
				[oname_id(string) top_loc(string) shapedir(string)]							///
				[saveas(string) EXportexcel saveframes]					///
				[replace deleteframe BRowse] 
				*clear SAVEas(string)
		
		// Validate that the current frame was created by `lodes get' with
		// OD data and set up in_frame, data_type, state, xwalk locals.
		lodes_check_input_frame od

			
		// entries checks
		**oname list
		if "`oname'" == "" {
			di as error `"{p} You must specify a geography of origin (bgrp, trct, zcta, cty, stplc, cbsa, st){p_end}"'
			exit 198
		}

		// Determine whether oname is a standard geography or a custom polygon.
		// `oname_poly' is reused later (top_loc keep, xwalk cleanup).
		lodes_is_polygon `oname'
		local oname_poly = `is_polygon'

		// Custom polygon: hand off to the shapefile-processing helper
		if `oname_poly' {
			local name "`oname'"
			lodes_polygon_process "`name'" "`shapedir'"
		}
	
		**origin type check
		if "`origin'" == "" {
			local origin home
			di as text `"{p} Default origin is: {result:home}. To change, specify {input:{it: origin}} value {p_end}"'
		
		}
		else {
			if !inlist("`origin'", "home", "work") {
				di as error `"{p} You must specify either "home" or "work" as origin{p_end}"'
				exit 198
			}
		}
	

		**otype assign 
		local otype =substr("`origin'",1,1)
	
		** dname list
		if "`dname'" == "" {
			di as error `"{p} You must specify a geography of destination (bgrp, trct, zcta, cty, stplc, cbsa, st).{p_end}"'
			exit 198
		}
		// dname must be a standard geography; custom polygons are not allowed as a destination
		lodes_is_polygon `dname'
		if `is_polygon' {
			di as error `"{p} Destination geography ({result:`dname'}) is not a recognised standard geography (bgrp, trct, zcta, cty, stplc, cbsa, st). Custom polygons are only supported as origins.{p_end}"'
			exit 198
		}
	
		**dtype assign
		if "`otype'" == "w" {
			local dtype h
		}
		if "`otype'" == "h" {
			local dtype w
		}
	
		
		//process data
		
		*define frame output name (max 32 characters)
		local out_frame `in_frame'_`oname'_`otype'
		lodes_check_frame_name `out_frame'
		
		qui frame copy 		`in_frame'								/// 
						`out_frame', replace 
	
		frame change 	`out_frame'

		// add aliases based on selected geography 
		qui fralias add `oname'_`otype' = `oname', from(xwalk_`otype') // geography ID of origin
		la var `oname'_`otype' "`oname'_`otype' code"

		qui fralias add `oname'_name_`otype' = `oname'name, from(xwalk_`otype') // geography name of origin
		la var `oname'_name_`otype' "`oname'_name_`otype' name"

		qui fralias add `dname'_`dtype' = `dname', from(xwalk_`dtype') // geography ID of destination
		la var `dname'_`dtype' "`dname'_`dtype' code"

		qui fralias add `dname'_name_`dtype' = `dname'name, from(xwalk_`dtype') // geography name  of destination
		la var `dname'_name_`dtype' "`dname'_name_`dtype' name"

		// aggregate by selected geography 
		egen s000_`oname'_`otype'_`dname'_`dtype' = sum(s000), by(`oname'_`otype' `dname'_`dtype' year) 
		la var s000_`oname'_`otype'_`dname'_`dtype'  "Job counts by `oname'_`otype'_`dname'_`dtype'"

		qui duplicates drop `oname'_`otype' `dname'_`dtype' s000_`oname'_`otype'_`dname'_`dtype' year, force 

		gsort -s000_`oname'_`otype'_`dname'_`dtype' year

		
		// Options

		**generate thresholds by location 

		egen workers_`oname'_`otype' = sum(s000_`oname'_`otype'_`dname'_`dtype'), by (`oname'_`otype' year)
		la var workers_`oname'_`otype' "Total workers in `oname'_`otype'"

		gen workers_`dname'_`dtype'_sh = 100*(s000_`oname'_`otype'_`dname'_`dtype'/workers_`oname'_`otype')
		la var workers_`dname'_`dtype'_sh "Share of `dname'_`dtype' workers by `oname'_`otype'"

		gsort  `oname'_`otype' year -workers_`dname'_`dtype'_sh

		by  `oname'_`otype' year: gen `dname'_`dtype'_cum_share = sum(workers_`dname'_`dtype'_sh)
		la var `dname'_`dtype'_cum_share "Cumulative share of `dname'_`dtype' workers by `oname'_`otype'"

		**remove locations as below before ranking 
		qui drop if od_type == "aux"  //removing workers residing in other states 
		qui drop if `dname'_`dtype' == "9999999" //undefined destinations because outside of origin

		egen `dname'_`dtype'_rank = rank(-workers_`dname'_`dtype'_sh), by (`oname'_`otype' year)
		la var `dname'_`dtype'_rank "Rank by jobs counts/share in `dname'_`dtype'"

		**recast linked variables
		qui frunalias 	`oname'_`otype'  `oname'_name_`otype' `dname'_`dtype' `dname'_name_`dtype' 


		**retain only results by top x locations
		local top_loc = real("`top_loc'")
		if `top_loc' == . {
			di as text "{p}No specific threshold defined, entire output dataset retained. To change, specify {input:{it:top_loc}}{p_end}"
		}
		
		**polygon case
		if `top_loc'!= . & `oname_poly' {
			qui keep if `dname'_`dtype'_rank <= `top_loc' & `oname'_`otype' == 1
			di as result "{p}retaining only the top `top_loc' output observations{p_end}"
		}
	
		**all others
		else {
			if `top_loc'!= . {
				qui keep if `dname'_`dtype'_rank <= `top_loc'
			di as result "{p}retaining only the top `top_loc' output observations{p_end}"
			}
		}
		**process by selected geography of origin
		if "`oname_id'" == "" {
			di as text "{p} No specific origin geography ID defined, entire output dataset retained. To change, specify {input:{it:oname_id}}{p_end}"
		}

		else {
				qui keep if `oname'_`otype' == "`oname_id'"
				gsort  `oname'_`otype' year -s000_`oname'_`otype'_`dname'_`dtype'
				di as text "{p}Retaining only data on geography - {result:`oname' `oname_id'} - selected as origin type: {result:`origin'} {p_end}"
		}

		//retain only relevant variables
		keep 	year `oname'_`otype' `oname'_name_`otype' 	///
				`dname'_`dtype' `dname'_name_`dtype' 		///
				s000_`oname'_`otype'_`dname'_`dtype' 		///
				workers_`oname'_`otype' 					///
				workers_`dname'_`dtype'_sh 					///
				`dname'_`dtype'_cum_share 					///
				`dname'_`dtype'_rank 
				
		//Export Data
		if "`saveas'" != "" {
			local fr_opt
			if "`saveframes'" != "" local fr_opt "saveframes(`out_frame')"
			local ex_opt
			if "`exportexcel'" != "" local ex_opt "exportexcel"
			lodes_save_output, saveas(`"`saveas'"') `replace' `ex_opt' `fr_opt'
		}

		//clean up data frames
		if "`deleteframe'" != "" {
			frame change `in_frame'
			frame drop `out_frame'
		}


		// clean xwalk file if polygon analysis was conducted
		if `oname_poly' {
			frame change `xwalk'
			drop `oname' `oname'name
		}
		
		//return to main frame
		frame change `in_frame'
		
		// browse if frame retained
		if "`deleteframe'" =="" {
			frame change `out_frame'
			`browse'
		}
end

********************************************************************************
**************************Inflow-Outflow****************************************
********************************************************************************
capture program drop lodes_inflow_outflow
program lodes_inflow_outflow
		version 16.1
		syntax	[anything(name=geography)], 							///
				[geo_id(string) work_seg(string) shapedir(string)] 		///
				[saveas(string) EXportexcel saveframes]				///
				[replace deleteframe BRowse] 
		
		// Validate that the current frame was created by `lodes get' with
		// OD data and set up in_frame, data_type, state, xwalk locals.
		lodes_check_input_frame od
			
		// entries checks
				
		**geography list
		if "`geography'" == "" {
			di as error `"{p} You must specify a geography of origin (bgrp, trct, zcta, cty, stplc, cbsa, st).{p_end}"'
			exit 198
		}
		// Determine whether geography is a standard one or a custom polygon.
		// `geog_poly' is reused later in the dedup step.
		lodes_is_polygon `geography'
		local geog_poly = `is_polygon'

		if `geog_poly' {
			local name "`geography'"
			lodes_polygon_process "`name'" "`shapedir'"
		}

		
		// Copy data to new frame 
		local out_frame `in_frame'_`geography'
		lodes_check_frame_name `out_frame'
		qui frame copy 	`in_frame'	/// 
						`out_frame', replace 

		frame change `out_frame'

		// Add aliases based on selected geography 

		qui fralias add `geography'_h = `geography', from(xwalk_h) // geography ID of origin
		la var `geography'_h "`geography'_h code"

		qui fralias add `geography'_name_h = `geography'name, from(xwalk_h) // geography name of origin
		la var `geography'_name_h "`geography'_name_h name"

		qui fralias add `geography'_w = `geography', from(xwalk_w) // geography ID of destination
		la var `geography'_w "`geography'_w code"

		qui fralias add `geography'_name_w = `geography'name, from(xwalk_w) // geography name  of destination
		la var `geography'_name_w "`geography'_name_w name"

		// Estimate Inflow/Outflow Job Counts
		// Note: previously this was two near-identical loops (with vs without
		// `qui`); they are now a single loop that always quiets egen output.
		local work_seg : di lower("`work_seg'")
		if "`work_seg'" == "" {
			local jobs s000
		}
		else {
			local jobs `work_seg'
		}
		foreach v of local jobs {
			qui egen live_area_`v' = sum(`v'), by(`geography'_h year)
			la var live_area_`v' "Living in the Selection Area job `v'"

			qui egen live_area_emp_out_`v'_ = sum(`v') if `geography'_h != `geography'_w, by(`geography'_h year)
			qui egen live_area_emp_out_`v' = max(live_area_emp_out_`v'_), by(`geography'_h year)
			drop live_area_emp_out_`v'_
			la var live_area_emp_out_`v' "Living in the Selection Area but Employed Outside job `v'"

			qui gen live_area_emp_in_`v'_ = live_area_`v' - live_area_emp_out_`v'
			qui egen live_area_emp_in_`v' = max(live_area_emp_in_`v'_), by(`geography'_h year)
			drop live_area_emp_in_`v'_
			la var live_area_emp_in_`v' "Living and Employed in the Selection Area job `v'"

			qui egen emp_area_`v' = sum(`v'), by(`geography'_w year)
			la var emp_area_`v' "Employed in the Selection Area job `v'"

			qui egen emp_area_lvng_out_`v'_ = sum(`v') if `geography'_h != `geography'_w, by(`geography'_w year)
			qui egen emp_area_lvng_out_`v' = max(emp_area_lvng_out_`v'_), by(`geography'_w year)
			drop emp_area_lvng_out_`v'_
			la var emp_area_lvng_out_`v' "Employed in the Selection Area but Living Outside job `v'"

			qui gen emp_area_lvng_in_`v'_ = emp_area_`v' - emp_area_lvng_out_`v'
			qui egen emp_area_lvng_in_`v' = max(emp_area_lvng_in_`v'_), by(`geography'_w year)
			drop emp_area_lvng_in_`v'_
			la var emp_area_lvng_in_`v' "Employed and Living in the Selection Area job `v'"
		}
		
		// Recast linked variables
		qui frunalias 	`geography'_h  `geography'_name_h 	///
					`geography'_w `geography'_name_w 

		// Deduplicate to retain geography with Inflow/Outflow results
		if !`geog_poly' {
			**US Census geographies
			keep if `geography'_h == `geography'_w
			qui duplicates drop `geography'_h `geography'_w year, force
		}
		else {
			**polygon
			keep if `geography'_h == 1 & `geography'_h == `geography'_w
			qui duplicates drop emp_area_lvng_in_*, force
		}
		
		sort  `geography'_h year 
			
		//clean up variables		
		qui drop 	w_geocode h_geocode createdate od_type xwalk_h xwalk_w ///
					s000 sa01-sa03 se01-se03 si01-si03 ///
					`geography'_w `geography'_name_w 
		rename (`geography'_h  `geography'_name_h) (`geography' `geography'_name )
		la var year "Year"

		//process by selected geography 
		if "`geo_id'" == "" {
			di as text "{p}no specific geography defined, entire inflow-outflow dataset retained unless custom polygon being used. {p_end}"
		}

		else {
			if "`geo_id'" != "" {
				qui keep if `geography' == "`geo_id'"
				di as text "{p}Retaining ouput for geography:{result:`geography'} and geography id: {result:`geo_id'}. {p_end}"
				sort year 
			}
		}

*******************************************************************************
		//Export Data
		if "`saveas'" != "" {
			local fr_opt
			if "`saveframes'" != "" local fr_opt "saveframes(`out_frame')"
			local ex_opt
			if "`exportexcel'" != "" local ex_opt "exportexcel"
			lodes_save_output, saveas(`"`saveas'"') `replace' `ex_opt' `fr_opt'
		}

		//clean up data frames
		if "`deleteframe'" != "" {
			frame change `in_frame'
			frame drop `out_frame'
		}

		//return to main frame
		frame change `in_frame'
		frame list
		
		// browse if frame retained
		if "`deleteframe'" =="" {
			frame change `out_frame'
			`browse'
		}
end

********************************************************************************
**************************Area_Profile******************************************
********************************************************************************
capture program drop lodes_area_profile
program lodes_area_profile
		version 16.1
		syntax	[anything(name=geography)], 							///
				[geo_id(string) work_seg(string) shapedir(string)] 		///
				[saveas(string) EXportexcel saveframes]				///
				[replace deleteframe BRowse] 

		// Validate that the current frame was created by `lodes get' with
		// WAC or RAC data and set up in_frame, data_type, state, xwalk locals.
		lodes_check_input_frame wac rac

		// entries checks
		**geography list
		if "`geography'" == "" {
			di as error `"{p} You must specify a geography of origin (bgrp, trct, zcta, cty, stplc, cbsa, st).{p_end}"'
			exit 198
		}

		// Determine whether geography is a standard one or a custom polygon.
		// `geog_poly' is reused later in the dedup step.
		lodes_is_polygon `geography'
		local geog_poly = `is_polygon'

		if `geog_poly' {
			local name "`geography'"
			lodes_polygon_process "`name'" "`shapedir'"
		}


		// Copy data to new frame 
		local out_frame `in_frame'_`geography'
		lodes_check_frame_name `out_frame'
		qui frame copy `in_frame' /// 
		`out_frame', replace 

		frame change `out_frame'
		drop createdate //not needed for analysis

		// Add aliases based on selected geography 
		if "`data_type'" == "rac" {
			fralias add `geography', from(xwalk_h)
			la var `geography' "`geography' code"
			fralias add `geography'_name = `geography'name, from(xwalk_h)
			la var `geography'_name "`geography'_name name"
			// Recast linked variables
			frunalias 	`geography'  `geography'_name 
			}
		
		if "`data_type'" == "wac" {
			qui fralias add `geography', from(xwalk_w)
			la var `geography' "`geography' code"
			qui fralias add `geography'_name = `geography'name, from(xwalk_w)
			la var `geography'_name "`geography'_name name"
			// Recast linked variables
			qui frunalias 	`geography'  `geography'_name 
			}
				
		// process data 
		local work_seg: di lower("`work_seg'") //to match lower case in dataset 

		if "`work_seg'" == "" {
			*create varlist to be used
			qui ds c*, has(type numeric)
			local jobs "`r(varlist)'"
			foreach v of local jobs {
			egen job_`v' = sum(`v'), by(`geography' year)
			la var job_`v' "Number of Jobs Category `v'"
			}
		}
		else {
			local jobs `work_seg'
			foreach v of local jobs {
				egen job_`v' = sum(`v'), by(`geography' year)
				la var job_`v' "Number of Jobs Category `v'"
			}
		}
	
		//retain only key variables
		keep year `geography' `geography'_name job_* 
	
		// Deduplicate to retain geography with Inflow/Outflow results
		if !`geog_poly' {
			**US Census geographies
			qui duplicates drop `geography' year, force
		}
		else {
			**polygon
			qui duplicates drop `geography' year, force
			keep if `geography' == 1
		}
	
		//process by selected geography 
		if "`geo_id'" == "" {
			di as text "{p}no specific geography defined, entire output dataset retained.{p_end}"
			}

		else {
			if "`geo_id'" != "" {
				keep if `geography' == "`geo_id'"
				di as text "{p}Retaining ouput for geography:{result:`geography'} and geography id: {result:`geo_id'}. {p_end}"
				sort year 
			}
		}

		// export results ------------------------------------------------------
		if "`saveas'" != "" {
			local fr_opt
			if "`saveframes'" != "" local fr_opt "saveframes(`out_frame')"
			local ex_opt
			if "`exportexcel'" != "" local ex_opt "exportexcel"
			lodes_save_output, saveas(`"`saveas'"') `replace' `ex_opt' `fr_opt'
		}


		//clean up data frames
		if "`deleteframe'" != "" {
			frame change `in_frame'
			frame drop `out_frame'
		}
		
		//return to main frame
		frame change `in_frame'
		frame list 
		
		// browse if frame retained
		if "`deleteframe'" =="" {
			frame change `out_frame'
			`browse'
		}
		
end
********************************************************************************
**************************Polygon Process***************************************
********************************************************************************
capture program drop lodes_polygon_process
program lodes_polygon_process
		version 16.1
		args name shapedir

		di as text "{p}Shapefile directory used: {result:`shapedir'}{p_end}"

		// validate inputs
		if "`shapedir'" == "" {
			di as error "{p}You must supply the directory location of the shapefile. Set up using option: {input:{it:shapedir()}}{p_end}"
			exit 111
		}
		if !fileexists("`shapedir'/`name'.zip") {
			di as error `"{p}You must provide the shapefile (zipped) in the `shapedir' directory.{p_end}"'
			exit 111
		}

		di as result "{p}Shapefile `name' exists and processed.{p_end}"

		// Remember the user's working directory and the frame they came in
		// on so we can restore both on any exit path. Previously a successful
		// run did `cd ..' (wrong: it assumed the user was originally in the
		// shapedir's parent), and any mid-flight error left the user stranded
		// in shapedir and/or in the xwalk frame.
		local _orig_pwd  : pwd
		local _entry_frame = c(frame)

		// Wrap the shapefile work in capture-noisily so any error short-
		// circuits to the restore section below (instead of returning to the
		// caller with pwd/frame still pointing at the wrong place).
		capture noisily {
			qui cd "`shapedir'"

			// extract just the .shp and .dbf members of the zip
			foreach f in shp dbf {
				qui unzipfile "`name'", ifilter(".*`f'") replace
			}

			// locate the unzipped .shp file (expect exactly one)
			local _shp_files : dir "." files "*.shp"
			local _shp_count : list sizeof _shp_files
			if `_shp_count' == 0 {
				di as error "{p}No .shp file found after unzipping {result:`name'.zip}.{p_end}"
				exit 601
			}
			if `_shp_count' > 1 {
				di as error "{p}Multiple .shp files found in {result:`name'.zip}; expected exactly one.{p_end}"
				exit 601
			}
			// `: dir' returns each name in double quotes; gettoken strips them
			gettoken shpname _ : _shp_files

			qui spshape2dta `"`shpname'"', replace

			// apply geoinpoly to the LODES crosswalk frame
			local _state = substr("`_entry_frame'", 1, 2)
			frame change `_state'_xwalk

			// remove pre-existing copies of the polygon ID/name variables
			capture confirm variable `name'
			if _rc == 0 qui drop `name'
			capture confirm variable `name'name
			if _rc == 0 qui drop `name'name

			qui destring blklatdd blklondd, replace

			// spshape2dta writes `stem'_shp.dta from `stem'.shp
			local stem = usubinstr(`"`shpname'"', ".shp", "_shp", .)
			qui geoinpoly blklatdd blklondd using "`stem'", unique

			rename _ID `name'
			qui replace `name' = 0 if `name' == .
			qui gen `name'name = "`name'"

			// Clean up the temp files we unzipped/created. Uses Stata's
			// erase (portable) instead of `!del' (Windows-only) so the
			// command also works on macOS and Linux.
			foreach ext in dta shp dbf shx prj sbn sbx {
				local _tmp : dir "." files "*.`ext'"
				foreach f of local _tmp {
					capture erase `f'
				}
			}
		}
		local _rc = _rc

		// Restore the user's working directory and original frame on any
		// exit path (success or error).
		qui cd `"`_orig_pwd'"'
		capture frame change `_entry_frame'

		if `_rc' exit `_rc'
end

********************************************************************************
**************************Data Check***************************************
********************************************************************************
*Per-state year availability for OD and WAC data (LODES8 tech doc v8.4).
*RAC has broader coverage and is not restricted here.
*Flags any requested year that falls outside the available window for the state
*(the previous implementation only fired when *all* requested years were
*unavailable, silently passing partial-overlap requests).
capture program drop lodes_data_check
program lodes_data_check
		version 16.1
		args state data_type years

		// Only OD and WAC have per-state restrictions
		if !inlist("`data_type'", "od", "wac") exit

		// Per-state availability window (start/end inclusive).
		// Update these constants as LODES publishes new years.
		local avail
		if      "`state'" == "ak" local avail "2002/2016"
		else if "`state'" == "ar" local avail "2003/2023"
		else if "`state'" == "az" local avail "2004/2023"
		else if "`state'" == "dc" local avail "2010/2023"
		else if "`state'" == "ma" local avail "2002/2023"
		else if "`state'" == "mi" local avail "2002/2021"
		else if "`state'" == "ms" local avail "2004/2023"
		else if "`state'" == "nh" local avail "2003/2023"
		else if "`state'" == "pr" local avail ""
		else exit  // no known restrictions for this state

		// Expand requested years into a flat numlist
		qui numlist "`years'"
		local req `r(numlist)'

		// Expand the availability window
		local avail_list
		if "`avail'" != "" {
			qui numlist "`avail'"
			local avail_list `r(numlist)'
		}

		// Requested years that are not in the available window
		local unavail : list req - avail_list

		if "`unavail'" != "" {
			local STATE = strupper("`state'")
			local DTYPE = strupper("`data_type'")
			di as error "{p}`DTYPE' data for state `STATE' is not available for year(s): {result:`unavail'}.{p_end}"
			if "`avail'" != "" {
				di as error "{p}Available years for `STATE' `DTYPE': {result:`avail'} (per LODES8 tech doc).{p_end}"
			}
			else {
				di as error "{p}No years currently available for `STATE' `DTYPE'.{p_end}"
			}
			exit 198
		}
end

********************************************************************************
**************************Geography Helper*************************************
********************************************************************************
*Sets c_local is_polygon = 1 if `geog' is NOT one of the standard
*Census-recognised LODES geographies (and is therefore treated as a
*user-supplied polygon name); 0 otherwise. The canonical geography list
*lives only here -- update it in one place if LODES adds new geographies.
capture program drop lodes_is_polygon
program lodes_is_polygon
	version 16.1
	args geog
	local _std_geos "bgrp trct zcta cty stplc cbsa st"
	local _pos : list posof "`geog'" in _std_geos
	c_local is_polygon = !`_pos'
end

********************************************************************************
**************************Input-Frame Validation*******************************
********************************************************************************
*Validates that the current frame was created by `lodes get' with one of
*the allowed data types, and sets up the locals subcommands expect.
*
*Usage:
*    lodes_check_input_frame od        // destination, inflow_outflow
*    lodes_check_input_frame wac rac   // area_profile
*
*Sets c_local: in_frame, data_type, state, xwalk
*Exits with error 198 if the current frame's data_type is not in the list.
capture program drop lodes_check_input_frame
program lodes_check_input_frame
	version 16.1
	// `0' is all positional args (space-separated), e.g. "od" or "wac rac"
	local _in_frame = c(frame)
	local _state = substr("`_in_frame'", 1, 2)

	local _dtype
	foreach _t in `0' {
		local _len = ustrlen("`_t'")
		local _candidate = substr("`_in_frame'", 4, `_len')
		if "`_candidate'" == "`_t'" {
			local _dtype "`_t'"
			continue, break
		}
	}

	if "`_dtype'" == "" {
		di as error `"{p}The current frame ({result:`_in_frame'}) was not created by {bf:lodes get} with data type {result:`0'}. Run {bf:lodes get} with one of those data types first, then re-run this subcommand.{p_end}"'
		exit 198
	}

	c_local in_frame  "`_in_frame'"
	c_local data_type "`_dtype'"
	c_local state     "`_state'"
	c_local xwalk     "`_state'_xwalk"
end

********************************************************************************
**************************Frame-Name Length Check******************************
********************************************************************************
*Errors out if `fr_name' exceeds Stata's 32-character frame-name limit.
*Without this, frame copy / frame create would fail with an opaque
*Stata-internal error; this helper surfaces a clearer cause and remedy.
capture program drop lodes_check_frame_name
program lodes_check_frame_name
	version 16.1
	args fr_name
	if ustrlen("`fr_name'") > 32 {
		di as error `"{p}Generated frame name {bf:`fr_name'} exceeds Stata's 32-character frame-name limit. Use a shorter geography name (or origin specifier) to keep the composite name under the limit.{p_end}"'
		exit 198
	}
end

capture program drop lodes_state_check
program lodes_state_check
	version 16.1
	args url_base state
	// Probe the URL by copying it into a unique tempfile. tempfile names are
	// generated by Stata and auto-erased when the program ends, so this works
	// safely when multiple lodes invocations run concurrently and leaves no
	// debris in c(tmpdir).
	tempfile _lodes_probe
	cap copy "`url_base'" `"`_lodes_probe'"', replace
	if _rc != 0 {
		di as error "{p} State abbreviation {result:`state'} does not exist.{p_end}"
		exit 601
	}
end

********************************************************************************
**************************Save Output Helper***********************************
********************************************************************************
*Shared save/export logic used by lodes_get, lodes_destination,
*lodes_inflow_outflow, and lodes_area_profile.
*
*Always saves the current data as `saveas'.dta. Optionally:
*  - exportexcel       : also writes `saveas'.xlsx
*  - saveframes(list)  : also writes `saveas'.dtas containing the named frames
*                        (caller passes the explicit frame list to save)
*  - replace           : overwrite any of the above if they already exist;
*                        without replace, a pre-existing .xlsx or .dtas errors
capture program drop lodes_save_output
program lodes_save_output
	version 16.1
	syntax , SAVEas(string) [EXportexcel SAVEFrames(string) replace]

	// strip any extension from saveas (.dta, .xlsx, etc.)
	local saveas = ustrregexra("`saveas'", "\.(.*)$", "")

	// save the current data as a Stata dataset
	qui save "`saveas'.dta", `replace'

	// optional Excel export
	if "`exportexcel'" != "" {
		if "`replace'" == "" {
			capture confirm file "`saveas'.xlsx"
			if _rc == 0 {
				di as error "file `saveas'.xlsx already exists"
				exit 602
			}
		}
		qui export excel using "`saveas'.xlsx", firstrow(variables) `replace'
	}

	// optional Stata frames file
	if "`saveframes'" != "" {
		if "`replace'" == "" {
			capture confirm file "`saveas'.dtas"
			if _rc == 0 {
				di as error "file `saveas'.dtas already exists"
				exit 602
			}
		}
		qui frames save "`saveas'", frames(`saveframes') `replace'
	}
end
