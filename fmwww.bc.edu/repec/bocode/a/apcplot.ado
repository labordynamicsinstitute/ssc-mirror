/******************************************************************************* 
APCPLOT: A tool for visualizing APC effects to facilitate Fosse-Winship bounding 
approach to APC analysis.
********************************************************************************
Version: 1.1 (08.05.2025)
Author: Gordey Yastrebov, University of Cologne
License: GPL-3.0
*******************************************************************************/
	
	version 18
	
	pr de apcplot
		syntax [anything(name=graphs)], /// APC effect selection option
		///
			[Bounded] /// plot bounded solution
 			[Keepshape] /// keep shapes
			[ci(str)] /// CI option
			[a(numlist min=1 max=1)] /// exact linear components
			[p(numlist min=1 max=1)] ///
			[c(numlist min=1 max=1)] /// 
			[PEAbounds(numlist min=1 max=2 sort)] /// custom p.-e. bounds
			[PEPbounds(numlist min=1 max=2 sort)] ///
			[PECbounds(numlist min=1 max=2 sort)] ///
			[CIAbounds(numlist min=1 max=2 sort)] /// custom c.-i. bounds
			[CIPbounds(numlist min=1 max=2 sort)] ///
			[CICbounds(numlist min=1 max=2 sort)] ///
		///	
			[Grid(str)] /// diagnostic grid
			[GRIDLABels(str)] /// grid labels selection (off/right/left)
			[ANChorgrid] /// grid anchoring (A=-P=C)
			[GRIDFading(numlist max=1 >=0 <=1)] /// grid fading factor
			[gridlabops(str)] /// grid labels customization
			[gridline(str)] /// grid line decoration
			[GRIDPALette(str)] /// grid color palette
		///
			[NOGRadient] /// supress gradient
			[GRADes(int 100)] /// gradient grades
			[AREACONtour(str)] /// gradient area contour
			[AREAPALette(name)] /// gradient area color palette
		///
			[SHAPEPLops(str asis)] /// shape line options
			[PLotops(str)] /// common plot options
			[APLotops(str asis)] /// specific plot options
			[PPlotops(str asis)] ///
			[CPlotops(str asis)] ///
			[CIPLotops(str)] /// custom CI plot options
			[RECASTci(str)] /// custom CI rendering
			[COMBined] /// combine graphs
			[COMBPLotops(str asis)] // combined plot options

*** Variable symbols for printing
	loc a_letter α
	loc p_letter π
	loc c_letter γ
	loc nu_letter ν
	
*** Restore estimates from APCESTIMATE
	cap est res __apcestimate
	if _rc {
		di as err "The return from {it:apcestimate} not found!"
		exit
	}
	
*** Parse which graphs requested
	loc error = 0
	loc graphs = trim(strlower("`graphs'"))
	loc selection
	if inlist(`:word count `graphs'', 1, 2, 3) {
		forv i=1/`:word count `graphs'' {
			if !inlist("`: word `i' of `graphs''", "a", "p", "c") loc error = 1
			else loc selection `selection' `:word `i' of `graphs''
		}
	} 
	else if "`graphs'" == "" loc selection a p c
	else loc error = 1
	if `error' {
		di as err "Graph selection option incorrectly specified " ///
			"({help apcbound:help apcbound})"
		exit
	}
	
*** Parse confidence interval option
	if "`ci'" == "" loc no_ci = 1
	else {
		cap conf n `ci'
		if _rc == 0 & (`ci' > 0 & `ci' < 100) {
			loc no_ci = 0
			loc ci_lvl = `ci'
			if "`e(apcboundCI)'" != "" {
				if `ci_lvl' != `e(apcboundCI)' & "`bounded'" != "" {
					di as err "Specified confidence level does not match " ///
						"the level from {it:apcbound}." _n "Confidence-interval " ///
						"bounded solution will be inaccurate."
				}	
			}
		}
		else {
			di as err "Confidence interval option incorrectly " ///
				"specified ({help apcbound:help apcbound})"
			exit
		}
	}
	
*** Parse whether/which bounds requested
	loc no_shapes = 0
	if "`bounded'" == "" {
		di as txt "A bounded solution not requested, only shapes will be processed."
	}
	else {
		di as txt "A bounded solution requested."
		loc no_shapes = 1
		if "`keepshape'" != "" loc no_shapes = 0
		if `no_ci' loc types pe
		if !`no_ci' loc types pe ci
		loc pe "point-estimate"
		loc ci "`ci'% confidence-interval"
		foreach type in `types' {
			foreach apcvar in `selection' {
				if "``type'`apcvar'bounds'" == "" {
					if "`e(`type'_bounded_solution)'" != "1" {
						di as err "Neither custom nor evaluated ``type'' " ///
							"bounded solution for ``apcvar'_letter' " ///
							"({it:`e(`apcvar'var)'}) from {it:apcbound} " ///
							"could be found."
						exit
					}
					else {
						loc `type'_`apcvar'_bounds ///
							`=e(`type'`=strupper("`apcvar'")'min)' ///
							`=e(`type'`=strupper("`apcvar'")'max)'
						di as txt "   A ``type'' solution for ``apcvar'_letter' " ///
							"({it:`e(`apcvar'var)'}) assumed from {it:apcbound}."
					}
				}
				else {
					loc `type'_`apcvar'_bounds ``type'`apcvar'bounds'
					di as txt "   A custom ``type'' solution for ``apcvar'_letter' " ///
						" ({it:`e(`apcvar'var)'}) specified."
				}
			}
		}
	}
	
*** Parse exact linear component parameters 
	loc parameters `a' `p' `c'
	if `:word count `parameters'' > 1 {
		di as err "Only a single linear parameter (α, π or γ) can be specified."
		exit
	}
	else if `:word count `parameters'' == 0 {
		loc a_value = 0
		loc p_value = 0
		loc c_value = 0
	}
	else {
		if "`a'" != "" {
			loc letter a
			loc a_value = `a'
			loc p_value = `e(theta1)' - `a'
			loc c_value = `e(theta2)' - `e(theta1)' + `a'
			loc remaining p c
		}
		if "`p'" != "" {
			loc letter p
			loc a_value = `e(theta1)' - `p'
			loc p_value = `p'
			loc c_value = `e(theta2)' - `p'
			loc remaining a c
		}
		if "`c'" != "" {
			loc letter c
			loc a_value = `e(theta1)' - `c'
			loc p_value = `e(theta1)' - `e(theta2)' + `c'
			loc c_value = `c'
			loc remaining a p
		}
		forv i=1/2 {
			loc imply`i' = "``: word `i' of `remaining''_letter' = " + string(``: word `i' of `remaining''_value', "%9.3g")
		}
		di as txt "Parameter {bf:``letter'_letter'} set to {bf:``letter'_value'} " ///
			"(implies {bf:`imply1'} and {bf:`imply2'})".
	}
	
*** Parse grid parameters
	loc error = 0
	if "`grid'" == "" loc no_grid = 1
	* parsing:
	else if `:word count `grid'' == 1 {
		loc no_grid = 0
		loc grid_step = "`grid'"
		loc grid_sign
		loc grid_steps = 1
	}
	else if `:word count `grid'' == 2 {
		loc no_grid = 0
		gettoken grid_step chunk : grid
		if !(`grid_step' > 0 & !mi(`grid_step')) loc error = 1
		if inlist(substr(trim("`chunk'"), 1, 1), "+", "-") {
			loc grid_sign = substr(trim("`chunk'"), 1, 1)
			loc grid_steps = real(substr(trim("`chunk'"), 2, .))
		}
		else loc grid_steps = real("`chunk'")
	}
	else loc error = 1
	* integrity checks:
	if !`no_grid' {
		loc grid_step = real("`grid_step'")
		if !(`grid_step' > 0 & !mi(`grid_step')) loc error = 1
		if mi(`grid_steps') | !(`grid_steps'==int(`grid_steps')) loc error = 1
		if `error' {
			di as err "Inappropriate input in {it:grid()} option!"
			exit
		}
		if "`grid_sign'" == "" loc grid_sign - +
	}

*** Extract values and CIs into plot matrices
	foreach apcvar in `selection' {
		loc variable `e(`apcvar'var)'
		loc specification `e(`apcvar'spec)'
		loc ncols = 14
	* polynomial specification:
		if strpos("`specification'", "#") > 0 {
			default_range_of_values `variable'
			loc xvalues = r(xvalues)
			mat ests = J(`:word count `xvalues'', `ncols', .)
			forv i=1/`=rowsof(ests)' {
				loc x = `:word `i' of `xvalues''
				mat ests[`i', 1] = `x' // x original/value scale
				mat ests[`i', 2] = `x' - `e(`apcvar'center)' // xL
				loc formula 0
				forv j=1/`:word count `specification'' {
					loc xpowered = ests[`i', 2]^(`=`j'+1')
					loc formula `formula'+_b[`: word `j' of `specification'']*`xpowered'
				}
				qui lincom `formula', l(`ci_lvl')
				mat ests[`i', 3] = r(estimate) // NL
				mat ests[`i', 4] = r(lb) // NLlbCI
				mat ests[`i', 5] = r(ub) // NLubCI
			}
		}
	* categorical specification:
		else if substr("`specification'", 1, 1) == "i" & strpos("`specification'", ".") > 0 {
			mat b = e(b)
			loc coeflist : colnames b
			loc coefficients
			loc xvalues
			foreach coef of loc coeflist {
				if strpos("`coef'", ".`variable'") {
					loc value = substr("`coef'", 1, strpos("`coef'", ".") - 1)
					loc value : subinstr loc value "b" "", all
					loc value : subinstr loc value "o" "", all
					loc xvalues `xvalues' `value'
					loc coefficients `coefficients' `coef'
				}
			}
			mat ests = J(`: word count `xvalues'', `ncols', .)
			forv i=1/`=rowsof(ests)' {
				loc x = `:word `i' of `xvalues''
				mat ests[`i', 1] = `x' // x original value/scale
				mat ests[`i', 2] = `x' - `e(`apcvar'ref)' // xL
				qui lincom _b[`:word `i' of `coefficients''], l(`ci_lvl')
				mat ests[`i', 3] = r(estimate) // NL
				mat ests[`i', 4] = cond(mi(r(lb)), 0, r(lb)) // NLlbCI
				mat ests[`i', 5] = cond(mi(r(ub)), 0, r(ub)) // NLubCI
			}
		}
	* linear specification
		else if "`specification'" == "" {
			default_range_of_values `variable'
			loc xvalues = r(xvalues)
			mat ests = J(`:word count `xvalues'', `ncols', .)
			forv i=1/`=rowsof(ests)' {
				loc x = `:word `i' of `xvalues''
				mat ests[`i', 1] = `x' // x original value/scale
				mat ests[`i', 2] = `x' - `e(`apcvar'center)'
				mat ests[`i', 3] = 0
				mat ests[`i', 4] = 0
				mat ests[`i', 5] = 0
			}
		}
	* inappropriate input
		else {
			di as error "Variable specifications unclear! Please check."
			exit
		}
		loc baseline = ``apcvar'_value'
		forv i=1/`=rowsof(ests)' {
			loc letter = strupper("`apcvar'")
			loc x = ests[`i', 2]
			loc L_coef_min = `=e(pe`letter'min)'
			loc L_coef_max = `=e(pe`letter'max)'
			if "`apcvar'" == "p" { // a master flipper for period effects
				loc L_coef_min = `=e(pe`letter'max)'
				loc L_coef_max = `=e(pe`letter'min)'
			}
			mat ests[`i', 6] = ests[`i', 3] + `baseline' * `x' // NLshift (PE)
			mat ests[`i', 7] = ests[`i', 4] + `baseline' * `x' // NLlbCIshift (CI)
			mat ests[`i', 8] = ests[`i', 5] + `baseline' * `x' // NLubCIshift (CI)
			mat ests[`i', 9]  = `L_coef_min' * `x' // lbL REDUNDANT?
			mat ests[`i', 10] = `L_coef_max' * `x' // ubL REDUNDANT?
			mat ests[`i', 11] = `L_coef_min' * `x' + ests[`i', 3] // lb = lbL + NL (PE)
			mat ests[`i', 12] = `L_coef_max' * `x' + ests[`i', 3] // ub = ubL + NL (PE)
			mat ests[`i', 13] = ///
				min(`=e(ci`letter'min)' * `x', `=e(ci`letter'max)' * `x') + ///
				ests[`i', 4] // lbCI = NLlbCI (CI)
			mat ests[`i', 14] = ///
				max(`=e(ci`letter'min)' * `x', `=e(ci`letter'max)' * `x') + ///
				ests[`i', 5] // ubCI = NLubCI (CI)
		}
		mat coln ests = x xL NL NLlbCI NLubCI /// cols 1-5
			NLshift NLlbCIshift NLubCIshift /// cols 6-8
			lbL ubL lb ub lbCI ubCI // cols 9-14
		mat `apcvar'_estimates = ests
		mat drop ests
	}
	
***	Grid palette, matrix and label rendering (if requested)
	if !`no_grid' {
	* palettes:
		if "`gridpalette'" == "" loc gridpalette = "tableau"
		if strpos("`gridpalette'", ",") {
			loc comma = strpos("`gridpalette'", ",")
			loc pal1 = trim(substr("`gridpalette'", `comma' + 1, .))
			loc pal2 = trim(substr("`gridpalette'", 1, `comma' - 1))
		}
		else {
			loc pal1 "`gridpalette'"
			loc pal2 "`gridpalette'"				
		}
		if "`gridfading'" == "" loc gridfading = 0
		forv i=1/`grid_steps' {
			loc fading`i'=int(cond(`gridfading'==0,100,100*(1-(`i'-1)/(`grid_steps)'-1))^`gridfading'))
		}
		forv i=1/2 {
			colorpalette `pal`i'', nogr n(`grid_steps')
			forv j = 1/`grid_steps' {
				loc pal`i'color`j' = r(p`j')
			}
		}
	* matrices and labels:
		foreach apcvar in `selection' {
			mat estimates = `apcvar'_estimates
			loc signs `grid_sign'
			if "`anchorgrid'" != "" & "`apcvar'" == "p" {
				if "`grid_sign'" == "-" loc signs +
				if "`grid_sign'" == "+" loc signs -
				if "`grid_sign'" == "- +" loc signs + -
			}
			loc colnames
			forv i=1/`:word count `signs'' {
				loc sign `:word `i' of `signs''
				produce_gradient estimates NLshift `=`sign'`grid_step'' ///
					`grid_steps' grid 0
				mat grid_matrix = r(gradient_matrix)
				loc style place(c)
				if "`gridlabops'" != "" loc style `gridlabops'
				loc xmin = estimates[1, "x"]
				loc xmax = estimates[`=rowsof(estimates)', "x"]		
				loc grid_labels
				forv j=1/`grid_steps' {
					if "`gridlabels'" != "off" {
						loc y_xmin = grid_matrix[1, `j']
						loc y_xmax = grid_matrix[`=rowsof(grid_matrix)', `j']
						loc left_label = "`sign'" + string(`grid_step' * `j', "%9.3g")
						loc right_label `left_label'
						if "`gridlabels'" == "left" loc right_label 
						if "`gridlabels'" == "right" loc left_label
						loc color `pal`i'color`j''
						loc	grid_labels `grid_labels' ///
							text(`y_xmin' `xmin' "`left_label'", c("`color'"%`fading`j'') `style') ///
							text(`y_xmax' `xmax' "`right_label'", c("`color'"%`fading`j'') `style')
					}
					loc colnames `colnames' grid`=`j'+(`i'-1)*`grid_steps''
				}
				loc `apcvar'_grid_labels ``apcvar'_grid_labels' `grid_labels'
				mat grid_matrix`i' = grid_matrix
				loc nruns = `i'
			}
			if `nruns' == 1 mat `apcvar'_grid_matrix = grid_matrix1
			else {
				mat `apcvar'_grid_matrix = (grid_matrix1, grid_matrix2)
				mat coln `apcvar'_grid_matrix = `colnames'
			}
			foreach m in estimates grid_matrix grid_matrix1 grid_matrix2 {
				cap mat drop `m'
			}
		}
	}
	
*** Render a bounded solution matrix (if requested)
	if "`bounded'" != "" {
		if "`nogradient'" == "" {
			if "`areapalette'" == "" loc areapalette "viridis"
			colorpalette `areapalette', nogr n(`grades')
			forv i = 1 / `grades' {
				loc gradcolor`i' = r(p`i')
				//loc pgradcolor`i' = r(p`=`grades'-`i'+1')
			}
			foreach apcvar in `selection' {
				mat estimates = `apcvar'_estimates
				loc step = (`e(pe`=strupper("`apcvar'")'max)' - ///
					`e(pe`=strupper("`apcvar'")'min)') / (`grades' - 1)
				if "`apcvar'" == "p" loc step = -`step'
				produce_gradient estimates lb `step' `grades' grad 1
				mat `apcvar'_gradient_matrix = r(gradient_matrix)
			}
		}
	}
	
*** Combine (and drop redundant) matrices
	foreach apcvar in `selection' {
		mat `apcvar'_plot_matrix = `apcvar'_estimates
		foreach m in grid gradient {
			cap mat `apcvar'_plot_matrix = ///
				(`apcvar'_plot_matrix, `apcvar'_`m'_matrix)
			cap mat drop `apcvar'_`m'_matrix
		}
	}
	
*** Combine matrices,render graphs, and assemble the plot
	loc recast rarea
	loc recastci rarea
	loc atitle Age
	loc ptitle Period
	loc ctitle Cohort
	loc ytitle
	foreach apcvar in `selection' {
		loc xlabels : val lab `e(`apcvar'var)'
		preserve
		clear
		qui svmat `apcvar'_plot_matrix, n(col)
		la val x `xlabels'
		if !`no_shapes' loc pe_plot (line NLshift x, sort `shapeplops')
		if !`no_ci' & !`no_shapes' loc cipe_plot ///
			(`recastci' NLlbCIshift NLubCIshift x, sort `ciplotops')
		if "`areacontour'" != "" {
			qui de grad*, varl
			loc gradlast : word `: word count `r(varlist)'' of `r(varlist)'
			loc contour_plot (rline grad1 `gradlast' x, sort ///
				lp(solid) `areacontour') 
		}
		if !`no_grid' {
			loc grid_plot
			forv i=1/`:word count `grid_sign'' {
				forv j=1/`grid_steps' {
					loc color `pal`i'color`j''%`fading`j''
					loc ivar = `j' + (`i' - 1) * `grid_steps'
					loc grid_plot `grid_plot' ///
						(line grid`ivar' x, sort lc("`color'") lp(dash) `gridline')
				}
			}

		}
		if "`bounded'" != "" {
			loc i = 1
			if "`nogradient'" == "" {
				foreach v of var grad* {
					loc color `gradcolor`i''
					loc gradient_plot `gradient_plot' ///
						(line grad`i' x, sort lc("`color'") lp(solid))
					loc ++i
				}
				loc bounded_plot `gradient_plot'
			} 
			else {
				loc bounded_plot (rarea grad1 grad2 x, sort ///
					lp(solid) fc(`areapalette'))
			}
			if !`no_ci' loc cibounded_plot (`recastci' lbCI ubCI x, sort `ciplotops')
		}
	* MASTER PLOT:
		loc plot `cibounded_plot' `bounded_plot' `contour_plot' `cipe_plot' `grid_plot' `pe_plot'
		tw `plot', ``apcvar'_grid_labels' ///
			yti("`ytitle'") xti(``apcvar'title', height(7)) ///
			leg(off) name(``apcvar'title', replace) ///
			`plotops' ``apcvar'plotops'
		restore
		loc plots_to_combine `plots_to_combine' ``apcvar'title'
		mat drop `apcvar'_plot_matrix
	}
	if "`combined'" != "" & `:word count `graphs'' != 1 {
		gr combine `plots_to_combine', r(1) ycom name(Combined, replace) ///
			xsiz(`: word count `plots_to_combine'') ysiz(1) `combplotops'
	}

	end	

/////// Routines: //////////////////////////////////////////////////////////////
	pr de default_range_of_values, rclass
		syntax varlist(min=1 max=1)
		qui sum `varlist'
		loc step = (r(max) - r(min)) / 20
		numlist "`r(min)'(`step')`r(max)'", sort
		loc values = r(numlist)
		loc xvalues
		foreach value in `values' {
			loc xvalues `xvalues' `=round(`value', 1)'
		}
		ret loc xvalues `xvalues'
	end
	pr de produce_gradient, rclass
		args input_matrix reference_col step grades col_prefix offset
		mat gradient = J(`=rowsof(`input_matrix')', `grades', .)
		loc col_names
		forv j=1/`grades' {
			forv i=1/`=rowsof(gradient)' {
				loc x = `input_matrix'[`i', "xL"]
				loc reference = `input_matrix'[`i', "`reference_col'"]
				mat gradient[`i', `j'] = `reference' + `x' * `step' * (`j' - `offset')
			}
			loc col_names `col_names' `col_prefix'`j'
		}
		mat coln gradient = `col_names'
		ret mat gradient_matrix = gradient
	end
	pr de refine_values, rclass
		syntax, values(str) n(int)
		loc output 
		token `values'
		loc nvalues : word count `values'
		forv i = 1/`=`nvalues'-1' {
			loc a = ``i''
			loc b = ``=`i'+1''
			loc step = (`b' - `a') / (`n' + 1)
			loc output `output' `a'
			forval j = 1/`n' {
				loc newval = `a' + `j' * `step'
				loc output `output' `newval'
			}
		}
		loc output `output' ``nvalues''
		ret loc extended `output'
	end
