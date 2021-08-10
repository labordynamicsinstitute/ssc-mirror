*! ver 1.5; 2020-09-05
*  ver 1.4; 2020-05-21
*  ver 1.3; 2020-04-24
*  ver 1.2; 2019-11-20
*  ver 1.1; 2019-11-18
*  ver 1; 2019-11-05

program define bunchfilter, sortpreserve rclass
        version 14
		syntax varname(numeric) [if] [in] [fw] ///
		, GENerate(name) DELTAM(real) DELTAP(real) Kink(real) ///
		[ NOPIC BINWidth(real 9999425) PERC_obs(integer 40) POLorder(integer 7) ]
		
		********************************************************************************************
		*1. SETUP
		********************************************************************************************
		** initial checks
		* 1. observations to use
		marksample touse
		//marksample touse, strok
        qui count if `touse'
        if r(N) == 0 error 2000
		
		* 2. generate() is a valid name
		cap confirm variable `generate'
		if !_rc {
				di as err "variable {bf:`generate'} already exists"
				exit 110
		}
		if `deltap' < 0 | `deltam' < 0 {
				di as err "delta values must be weakly positive"
				exit 198
		}
		if `deltap' ==. | `deltam' ==. {
				di as err "must enter both delta values"
				exit 198
		}
		if `binwidth' <= 0  {
				di as err "option {bf:binwidth()} incorrectly specified: must be strictly bigger than 0"
				exit 198
		}
		if `perc_obs' <= 0 | `perc_obs' >= 100  {
				di as err "option {bf:perc_obs()} incorrectly specified: must be integer between 1 and 99"
				exit 198
		}
		if `polorder' < 2 | `polorder' > 7  {
				di as err "option {bf:polorder()} incorrectly specified: must be integer between 2 and 7"
				exit 198
		}
		
	
        * 3. setup variables
		tokenize `varlist'
		** variables:
        * trunc = truncation to perc_obs% around the kink
        * id_obs = sorting order
		* right = dummy for obs on the right of the kink
		* cdf_y_i_1 = CDF with friction error
		* cdf_y_i_0 = extrapolation to excluded region using polynomial regression
		* copy = a copy of the unfiltered variable
		* delta_cdf = a delta betweeb current and previous value - make sure cdf0 is monotonically increasing 
        qui {
                tempvar test_perc_obs temp trunc id_obs right cdf_y_i_1 copy cdf_y_i_0 delta_cdf			//variables
				tempname R2 vars_dropped num_drop cdf_y_i_0_p cdf_y_i_0_m Bhat cdf_y_i_1_val y_i_min 		//scalars
                gen double `copy' = `1' if `touse'
				
				forval j = 1/`polorder' { 
					tempvar y_i_`j' 
					local y_i_list `y_i_list' `y_i_`j''
					qui gen `y_i_`j'' = `copy'^`j' if `touse'
				}
		}

		
		********************************************************************************************
		*2. INPUT: Tunning parameters of filtering  
		********************************************************************************************
		*truncation:
		***for better fit, polynomial filtering works within a window around the kink that
		***has perc_obs% of the data 
		***WARNING: make sure the window [ k-deltam; k+deltap] contains way less data 
		***than perc_obs% of the data
		qui gen `test_perc_obs' = (`kink' - `deltam' <= `copy') * (`copy' <= `deltap' + `kink') if `touse'
		qui sum `test_perc_obs'
		if `r(mean)' * 100 > `perc_obs' {
				di as err "Truncation window is too small compared to excluded region. Either increase the truncation window (perc_obs) or decrease excluded region (deltam, deltap)."
				exit 2001
		}
		


		********************************************************************************************
		*3. Estimate CDF with friction error
		********************************************************************************************
		*generate trunc dummy
		***truncation to perc_obs% around the kink
		qui gen `temp' = abs(`copy' - `kink') if `touse'
		_pctile `temp' [`weight'`exp'], percentiles(`perc_obs')
		qui gen `trunc' = abs(`copy' - `kink') <= r(r1) if `touse'

		*sorting
		sort `copy'
		qui gen `id_obs' = _n if `touse'

		*dummy for obs on the right of the kink
		qui gen `right' = (`copy' >= `kink') if `touse' 

		*adjustment: make sure the kink point k appears once in the data (asymptotically negligible)
		qui sum `id_obs' if `touse' & `copy' >= `kink'
		qui replace `copy' = `kink' if `touse' & `id_obs' == r(min)

		*CDF with friction error
		cumul `copy' [`weight'`exp'] if `touse', generate(`cdf_y_i_1') eq

		
		********************************************************************************************
		*4. Estimate CDF without friction error
		********************************************************************************************
		***WARNING: make sure there is enough observations inside truncation window and outside excluded region
		****to run this polynomial regression 
		* count nubmer of obs
		qui count if `touse' & `trunc'  & (`copy' < `kink' - `deltam' | `copy' > `kink' + `deltap' )
		local reg_obs = r(N)
		* count number of covariates
		local covariates = `polorder' + 1 
		* rule of a thumb: need 10-20 observations per parameter (covariate)
		if `reg_obs' < `covariates' {
				di as err "Not enough observations to run polynomial regression. Try increasing estimation window using perc_obs."
				exit 2001
		}
		else if `reg_obs' < `covariates' * 10 {
				di as result "Warning: low number of observations to run polynomial regression:`reg_obs' observations for `covariates' parameters. Try increasing estimation window using option perc_obs"
		}
		
		
		*polynomial regression [no need of weights] outside of excluded region but inside truncation window
		qui reg `cdf_y_i_1' `y_i_list' `right' if `touse' & `trunc'  & (`copy' < `kink' - `deltam' | `copy' > `kink' + `deltap' )
		scalar `R2' = e(r2)
		scalar `vars_dropped' = `covariates' + 1 - e(rank) // covariates + constant - matrix rank
	
		*extrapolation to excluded region using polynomial regression
		qui predict `cdf_y_i_0' if `trunc' & `touse'
		**outside the truncation window, the cdf_y_i_0 is the same cdf_y_i_1 
		qui replace `cdf_y_i_0' = `cdf_y_i_1' if !`trunc' & `touse'


		*two adjustments (asympt negligible)
		**adjustment 1: make sure cdf0 is monotonically increasing 
		qui sort `y_i_list'
		qui gen `delta_cdf' = (`cdf_y_i_0' - `cdf_y_i_0'[_n-1]) if `trunc' & `touse'
		qui count if `delta_cdf' < 0
		scalar `num_drop' = r(N)

		while `num_drop' > 0 {
			qui replace `cdf_y_i_0' = `cdf_y_i_0'[_n-1] if `trunc' & `touse' & `delta_cdf' < 0 
			qui replace `delta_cdf' = (`cdf_y_i_0' - `cdf_y_i_0'[_n-1])	if `trunc' & `touse'
			qui count if `delta_cdf' < 0 
			scalar `num_drop' = r(N)
		}



		**adjustment 2: make sure cdf0<=cdf1 if y_i<k
		***and cdf0>=cdf1 if y_i>=k (both inside truncation window)
		qui replace `cdf_y_i_0' = `cdf_y_i_1' if `touse' & (`copy' <  `kink') & (`cdf_y_i_0' > `cdf_y_i_1') & `trunc'
		qui replace `cdf_y_i_0' = `cdf_y_i_1' if `touse' & (`copy' >= `kink') & (`cdf_y_i_0' < `cdf_y_i_1') & `trunc'

		* show graphs
		if missing("`nopic'") {
			local varlabel : variable label `1'
				
					*graph CDFs of filtered and unfiltered 
					* add a "ghost" graph to increase marker size in the legend
					local legend_cdf_opt = "on ring(0) pos(11) label(3 CDF unfiltered) label(4 CDF filtered) cols(1) order(3 4) symysize(*1) symxsize(*1) size(large)" 
					
					# delimit ; 
					twoway 
					(
						scatter `cdf_y_i_1' `copy' if `touse' & `trunc', msize(vtiny) mc(sand)
					)
					(
						scatter `cdf_y_i_0' `copy' if `touse' & `trunc', msize(vtiny) mc(black)
					)
					(
						scatter `cdf_y_i_0' `copy' `copy' if `copy' == ., ms(o o) mcolor(sand black) msize(*3 *3)
					) ,
					title("Bunching - Filter", color(black))

					xlabel(#10, labsize(large))
					xtitle("`varlabel'", size(vlarge)) xline(`kink')
					
					ylabel(#7, angle(horizontal) format(%12.2f) labsize(large) glwidth(thin) glcolor(black) glpattern(dot)) 
					ytitle("Cumulative distribution function", size(large))
					
					legend(`legend_cdf_opt')
					
					graphregion(margin(right) style(none) color(gs16))
					name(bunchfilter_two_cdfs, replace);
					# delimit cr
					
					
					
		}

		*compute side limits
		qui sum `cdf_y_i_0' if `touse' & `copy' >= `kink' & `trunc'
		scalar `cdf_y_i_0_p' = r(min)
		qui sum `cdf_y_i_0' if `touse' & `copy' <  `kink' & `trunc'
		scalar `cdf_y_i_0_m' = r(max)

		*estimate bunching mass [no need of weights]
		scalar `Bhat' = `cdf_y_i_0_p' - `cdf_y_i_0_m'
		***WARNING: make sure this is greater than or equal to zero
		if `Bhat' < 0 {
					di as err "Something is not right: bunching mass is less than zero. Look at the graph with the CDFs. We should have a positive jump discontinuity at the graph of the CDF of the filtered variable."
					exit 198
		}

		

		********************************************************************************************
		*5. Construct Filtered var -> `generate'
		********************************************************************************************
		*new variable yf_i, filtered income
		qui gen double `generate' = .   
		*varname is the same outside of excluded region
		qui replace `generate' = `copy' if `touse' & ( `copy' < `kink' - `deltam' | `copy' > `kink' + `deltap' ) 

		** progress bar:
		* (1)
		qui sum `id_obs'  if `touse' & (`copy' >= `kink' - `deltam') & (`cdf_y_i_1' < `cdf_y_i_0_m') & `trunc'
		local area1_min = r(min)
		local area1_max = r(max)
		local length1 = (`area1_max' - `area1_min' + 1)
		
		if `area1_min' == . {
					di as err "Not enough observations inside the excluded region. Look at the graph with the CDFs. We are lacking observations before the kink whose unfiltered CDF value is less than the left limit of the filtered CDF value at the kink."
					drop `generate'
					exit 2001
		}
		
		* (2)
		qui sum `id_obs' if `touse' &  (`cdf_y_i_1' > `cdf_y_i_0_p') & (`copy' <= `kink' + `deltap') & `trunc'
		local area3_min = r(min)
		local area3_max = r(max)
		local length3 = (`area3_max' - `area3_min' + 1)
		
		if `area3_min' == . {
					di as err "Not enough observations inside the excluded region. Look at the graph with the CDFs. We are lacking observations after the kink whose unfiltered CDF value is greater than the right limit of the filtered CDF value at the kink."
					drop `generate'
					exit 2001
		}
		
		* (1) + (2) = length of a progress bar
		local length = `length1' + `length3'
		local progress_bin = 10				//set the number of "#" to 10
		local progress_norm = 100 / `length'
		//local modif = round(`length' / `progress_bin')
		
		
		*varname is different inside the excluded region
		***three sub-regions
		****Area 1: obs shift forward
		* "transforming area 1 out of 3"
		local progress_cnt = 0
		scalar `y_i_min' = `kink' - `deltam'
		forvalues i = `area1_min'/`area1_max' {
			qui sum `cdf_y_i_1' if `touse' & `id_obs' == `i'
			scalar `cdf_y_i_1_val' = r(min)
			
			qui sum `copy' if `touse' & (`copy' >= `y_i_min') & (`copy' < `kink') & (`cdf_y_i_0' >= `cdf_y_i_1_val') & `trunc'
			qui replace `generate' = r(min) if `touse' & `id_obs' ==`i'
			scalar `y_i_min' = r(min)
			
			* progress bar
			local progress_cnt = `progress_cnt' + 1
			if `progress_cnt' == 1 local modif = 1
			progress  `progress_cnt', length(`length') progress_bin_cnt(`modif')
			local modif = s(progress_bin_cnt)
		}

		****Area 2: obs move to the kink
		* "transforming area 2 out of 3"
		qui sum `id_obs' if `touse' & (`cdf_y_i_1' >= `cdf_y_i_0_m') & (`cdf_y_i_1' <= `cdf_y_i_0_p') & `trunc'
		local area2_min = r(min)
		local area2_max = r(max)
		qui replace `generate' = `kink' if `touse' & `id_obs' >= `area2_min' & `id_obs' <= `area2_max'

		****Area 3: obs shift backward
		* "transforming area 3 out of 3"
		scalar `y_i_min' = `kink'
		forvalues i = `area3_min'/`area3_max' {
			qui sum `cdf_y_i_1' if `touse' & `id_obs' == `i'
			scalar `cdf_y_i_1_val' = r(min)
			qui sum `copy' if `touse' & (`copy' >= `y_i_min') & (`copy' <= `kink' + `deltap') & (`cdf_y_i_0' >= `cdf_y_i_1_val') & `trunc'
			qui replace `generate' = r(min) if `touse' & `id_obs' ==`i'
			scalar `y_i_min' = r(min)
			
			* progress bar
			local progress_cnt = `progress_cnt' + 1
			if `progress_cnt' == 1 local modif = 1
			progress  `progress_cnt', length(`length') progress_bin_cnt(`modif')
			local modif = s(progress_bin_cnt)
		}


		********************************************************************************************
		*6. Comparison: Before and After Filtering
		********************************************************************************************
		if missing("`nopic'") { 
			** if binwidth option is not entered by user calculate the binwidth using this
			if `binwidth' == 9999425 {
				qui sum `copy' [`weight'`exp'] if `touse'
				local binwidth = round(0.5*(r(max)-r(min))/(min(sqrt(r(N)), 10*ln(r(N))/ln(10))),0.01)
			}
			
			qui tempvar den_`copy' grid_`copy' den_`generate' grid_`generate'
			
			qui twoway__histogram_gen `copy' if `touse' [`weight'`exp'], gen(`den_`copy'' `grid_`copy'') density width(`binwidth') 
			qui twoway__histogram_gen `generate'  if `touse' [`weight'`exp'], gen(`den_`generate'' `grid_`generate'') density width(`binwidth')	
			
		
			* set scales on the graph for better-looking 
			** define y-axis
			qui sum `den_`copy'', nomean

			qui sum `den_`copy'' if `den_`copy'' != r(max), nomean
			local ymax = r(max)  
			local ymin = 0
			local margin_y = (1/5) * (`ymax' - `ymin')/9
			** define last values on axes
			local yscalemin = `ymin'
			local yscalemax = `ymax' + `margin_y'


			** define x-axis
			quietly su `grid_`copy'', d
			local xmax = r(p99) 
			local xmin = r(p1) 
			local margin_x = (1/5) * (`xmax' - `xmin')/9
			local xscalemin = `xmin' - `margin_x'
			local xscalemax = `xmax' + `margin_x'

		

		
			/* first original filter graph
			twoway (hist `copy' [`weight'`exp'] , width(`binwidth') bcolor(red)) ///
				(hist `generate' [`weight'`exp'] , width(`binwidth')) ///
				if `touse', ytitle("Density") xtitle("`varlabel'") title("Bunching - Filter") ///
				name(bunchfilter_hist_1, replace) legend(label(1 "CDF unfiltered") label(2 "CDF filtered"))
			*/
			
			local legend_pdf_opt = "on ring(0) pos(2) label(1 PDF unfiltered) label(2 PDF filtered) cols(1) order(1 2) symysize(*1) symxsize(*1) size(large)" 
		
			# delimit ; 
			twoway 
			(
			bar `den_`copy'' `grid_`copy'' if `grid_`copy'' >= `xscalemin' & `grid_`copy''<= `xscalemax', bcolor(sand) bstyle(histogram) barwidth(`binwidth')  title("", ring(1) pos(2) size(medlarge) color(black))
			)
			(
			bar `den_`generate'' `grid_`generate'' if `grid_`generate'' >= `xscalemin' & `grid_`generate'' <= `xscalemax', bcolor(black) bstyle(histogram) barwidth(`binwidth')  title("", ring(1) pos(11) size(medlarge) color(black))
			),
			title("Bunching - Filter", color(black))

			xscale(range(`xscalemin' `xscalemax'))
			xlabel(#10, labsize(large))
			xtitle("`varlabel'", size(vlarge)) 
					
			yscale(range(`yscalemin' `yscalemax'))
			ylabel(#7, angle(horizontal) format(%12.2f) labsize(large) glwidth(thin) glcolor(black) glpattern(dot)) 
			ytitle("Density (bin width of `binwidth')", size(large))
					
			legend(`legend_pdf_opt')
					
			graphregion(margin(right) style(none) color(gs16))
			name(bunchfilter_den_1, replace);
			# delimit cr

			/* second original filter graph
			twoway (hist `generate' [`weight'`exp'] , width(`binwidth') ) ///
				(hist `copy' [`weight'`exp'] , width(`binwidth') bcolor(red) ) ///
				if `touse', ytitle("Density") xtitle("`varlabel'") title("Bunching - Filter") ///
				name(bunchfilter_hist_2, replace) legend(label(1 "CDF filtered") label(2 "CDF unfiltered"))
					*/
					
			# delimit ; 
			twoway 
			(
			bar `den_`copy'' `grid_`copy'' if `grid_`copy'' >= `xscalemin' & `grid_`copy''<= `xscalemax', bcolor(black) bstyle(histogram) barwidth(`binwidth')  title("", ring(1) pos(2) size(medlarge) color(black))
			)
			(
			bar `den_`generate'' `grid_`generate'' if `grid_`generate'' >= `xscalemin' & `grid_`generate'' <= `xscalemax', bcolor(sand) bstyle(histogram) barwidth(`binwidth')  title("", ring(1) pos(11) size(medlarge) color(black))
			),
			title("Bunching - Filter", color(black))

			xscale(range(`xscalemin' `xscalemax'))
			xlabel(#10, labsize(large))
			xtitle("`varlabel'", size(vlarge)) 
					
			yscale(range(`yscalemin' `yscalemax'))
			ylabel(#7, angle(horizontal) format(%12.2f) labsize(large) glwidth(thin) glcolor(black) glpattern(dot)) 
			ytitle("Density (bin width of `binwidth')", size(large))
					
			legend(`legend_pdf_opt')
					
			graphregion(margin(right) style(none) color(gs16))
			name(bunchfilter_den_2, replace);
			# delimit cr
					
		}

		
		********************************************************************************************
		*6. OUTPUT
		********************************************************************************************
		* label output variable
		local varlabel : variable label `1'
		label variable `generate' "`varlabel' (filtered)"

		* return scalars 
		return scalar filter_Bhat = `Bhat'
		return scalar filter_R2 = `R2'
		return scalar filter_vars_dropped = `vars_dropped'
		if missing("`nopic'") { 
			return scalar binwidth = `binwidth'
		}
end

		
program progress, sclass
/* parse the contents of the -progress- option:
 * displays a progress bar of 10% 20% ... 100%
 */
	version 10
	syntax [anything], length(integer) [progress_bin_cnt(integer 1)]
	
	local progress_bin = 10				//set the number of "#" to 10
	local progress_cnt = `anything'

	* first value
	if `progress_cnt' == 1 	{
		display "[" _continue 
		local progress_bin_cnt = 1
	}
	
	* progress bar
	local chunk = round(`progress_cnt' / `length' * 100) 
	if mod(`chunk', `progress_bin' * `progress_bin_cnt') == 0 & `chunk' > 0 {
		display " `chunk'%" _continue 
		local progress_bin_cnt = `progress_bin_cnt' + 1
	}	
	
	* last value
	if `progress_cnt' == `length' display " ]" _continue 
	
	* return modificator for bins
	sreturn local progress_bin_cnt `progress_bin_cnt'
end
