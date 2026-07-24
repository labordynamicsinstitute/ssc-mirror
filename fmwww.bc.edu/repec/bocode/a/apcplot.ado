/*******************************************************************************
APCPLOT: A tool for visualizing APC effects to facilitate Fosse-Winship bounding
approach to APC analysis.
********************************************************************************
Version: 2.0 (23.7.2026)
Author: Gordey Yastrebov, University of Cologne
License: GPL-3.0
*******************************************************************************/

	version 14

	pr de apcplot
		syntax [anything(name=graphs)], /// APC effect selection option
		///
			[Bounded] /// plot bounded solution
			[Keepshape] /// keep shapes
			[Info] /// display assumptions / bounds legend
			[Matrix(name)] /// store bounded-solution matrices
			[ci(str)] /// CI option
			[a(numlist min=1 max=1)] /// exact linear components
			[p(numlist min=1 max=1)] ///
			[c(numlist min=1 max=1)] ///
			[PEAbounds(numlist min=2 max=2 sort)] /// custom p.-e. bounds
			[PEPbounds(numlist min=2 max=2 sort)] ///
			[PECbounds(numlist min=2 max=2 sort)] ///
			[CIAbounds(numlist min=2 max=2 sort)] /// custom c.-i. bounds
			[CIPbounds(numlist min=2 max=2 sort)] ///
			[CICbounds(numlist min=2 max=2 sort)] ///
		///
			[Grid(str)] /// diagnostic grid
			[GRIDLABels(str)] /// grid labels selection (off/right/left)
			[ANChorgrid] /// grid anchoring (A=-P=C)
			[GRIDFading(numlist max=1 >=0 <1)] /// grid fading factor
			[gridlabops(str)] /// grid labels customization
			[gridline(str)] /// grid line decoration
			[GRIDPALette(str)] /// grid color palette
		///
			[NOGRadient] /// supress gradient
			[GRADes(int 100)] /// gradient grades
			[AREACONtour(str)] /// gradient area contour
			[AREAPALette(str)] /// gradient area color palette
		///
			[SHAPEPLotops(str asis)] /// shape line options
			[PLotops(str)] /// common plot options
			[APLotops(str asis)] /// APC-specific plot options
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

*** Restore estimates from APCEST
	cap est res __apcestimates
	if _rc {
		di as err "The return from {it:apcest} not found!"
		exit
	}

*** Parse all binary options
	foreach switch in bounded keepshape info anchorgrid nogradient combined {
		if "``switch''" != "" loc `switch' = 1
		else loc `switch' = 0
	}
	if `grades' < 2 {
		di as err "Option {bf:grades()} must be an integer greater than or equal to 2."
		exit 198
	}

*** Parse which graphs requested
	loc graphs = strlower(strtrim(`"`graphs'"'))
	loc selection
	if `"`graphs'"' == "" loc selection a p c
	else {
		loc ngraphs : word count `graphs'
		if !inrange(`ngraphs', 1, 3) {
			di as err "Graph selection incorrectly specified."
			di as err "Specify one or more of {bf:A}, {bf:P}, and {bf:C}."
			exit 198
		}
		foreach graph of local graphs {
			if !inlist("`graph'", "a", "p", "c") {
				di as err "Invalid APC graph selection: {bf:`graph'}."
				di as err "Specify only {bf:A}, {bf:P}, and/or {bf:C}."
				exit 198
			}
			if strpos(" `selection' ", " `graph' ") {
				di as err "APC graph {bf:`graph'} was specified more than once."
				exit 198
			}
			loc selection `selection' `graph'
		}
	}
	loc nplots : word count `selection'
	loc suppress = (`combined' & `nplots' > 1)

*** Parse confidence interval option
	loc no_ci = 1
	if "`ci'" != "" {
		cap conf n `ci'
		if _rc {
			di as err "Confidence interval option incorrectly " ///
				"specified ({help apcbound:help apcbound})"
			exit 198
		}
		if `ci' <= 0 | `ci' >= 100 {
			di as err "Confidence level must be greater than 0 " ///
				"and less than 100."
			exit 198
		}
		if `bounded' & "`e(apcboundCI)'" != "" {
			if `ci' != `e(apcboundCI)' {
				di as err "Specified confidence level does not match " ///
					"the level from {it:apcbound}!"
			}
		}
		loc no_ci = 0
		loc ci_lvl = `ci'
	}

*** Parse matrix output option
	if "`matrix'" != "" {
		foreach apcvar in `selection' {
			loc output_matrix_pe `apcvar'PE_`matrix'
			cap conf names `output_matrix_pe'
			if _rc {
				di as err "Invalid output matrix name {bf:`output_matrix_pe'}."
				di as err "Specify a shorter or otherwise valid suffix in {bf:matrix()}."
				exit
			}
			if !`no_ci' {
				loc output_matrix_ci `apcvar'CI_`matrix'
				cap conf name `output_matrix_ci'
				if _rc {
					di as err "Invalid output matrix name {bf:`output_matrix_ci'}."
					di as err "Specify a shorter suffix in {bf:matrix()}."
                    exit 198
                }
            }
        }
    }

*** Parse whether/which bounds requested
	if !`bounded' di as txt "A bounded solution not requested, " ///
		"only the nonlinear shapes will be rendered."
	else {
		di as txt "A bounded solution requested."
		loc pe_text "point-estimate"
		loc ci_text "`ci'% confidence-interval"
		if `no_ci' loc estimates pe
		else loc estimates pe ci
		foreach est in `estimates' {
			foreach apcvar in `selection' {
				if "``est'`apcvar'bounds'" == "" {
					if "`e(`est'_bounded_solution)'" != "1" {
						di as err "Neither custom nor evaluated ``est'_text' " ///
							"bounded solution for ``apcvar'_letter' " ///
							"from {it:apcbound} could be found."
						exit
					}
					else {
						loc `est'_`apcvar'_bounds ///
							`=e(`est'`=strupper("`apcvar'")'min)' ///
							`=e(`est'`=strupper("`apcvar'")'max)'
						di as txt "   A ``est'_text' solution for ``apcvar'_letter' " ///
							"assumed from {it:apcbound}."
					}
				}
				else {
					loc `est'_`apcvar'_bounds ``est'`apcvar'bounds'
					di as txt "   A custom ``est'_text' solution for " ///
						"``apcvar'_letter' specified."
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
			loc c_value = `a' - `e(theta1)' + `e(theta2)'
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
			loc a_value = `e(theta1)' - `e(theta2)' + `c'
			loc p_value = `e(theta2)' - `c'
			loc c_value = `c'
			loc remaining a p
		}
		forv i=1/2 {
			loc imply`i' = "``: word `i' of `remaining''_letter' = " + ///
				string(``: word `i' of `remaining''_value', "%9.3g")
		}
		di as txt "Parameter {bf:``letter'_letter'} set to {bf:``letter'_value'} " ///
			"(implies {bf:`imply1'} and {bf:`imply2'})".
	}

*** Parse grid parameters
	loc no_grid = ("`grid'" == "")
	loc gridlabels = lower(strtrim(`"`gridlabels'"'))
	if "`gridlabels'" != "" & ///
			!inlist("`gridlabels'", "off", "left", "right") {
		di as err "Option {bf:gridlabels()} must be {bf:off}, {bf:left}, or {bf:right}."
		exit 198
	}
	if `no_grid' & "`gridlabels'" != "" {
		di as err "Option {bf:gridlabels()} requires option {bf:grid()}."
		exit 198
	}
	if !`no_grid' {
		loc invalid = 0
		loc grid_sign  "- +"
		loc grid_steps = 1
		loc nargs : word count `grid'
		if !inlist(`nargs', 1, 2) loc invalid = 1
		else {
			gettoken step_arg count_arg : grid
			loc grid_step = real("`step_arg'")
			if missing(`grid_step') | `grid_step' <= 0 loc invalid = 1
		}
		if !`invalid' & `nargs' == 2 {
			loc count_arg = trim("`count_arg'")
			if !regexm("`count_arg'", "^[+-]?[0-9]+$") loc invalid = 1
			else {
				loc first = substr("`count_arg'", 1, 1)
				if inlist("`first'", "+", "-") {
					loc grid_sign "`first'"
					loc count_arg = substr("`count_arg'", 2, .)
				}
				loc grid_steps = real("`count_arg'")
				if missing(`grid_steps') | `grid_steps' < 1 loc invalid = 1
			}
		}
		if `invalid' {
			di as err "Inappropriate input in {it:grid()} option!"
			exit 198
		}
	}

*** Extract values and CIs into plot matrices
	if !`no_ci' loc lincom_ci , l(`ci_lvl')
	foreach apcvar in `selection' {
		loc variable `e(`apcvar'varname)'
		loc specification `e(`apcvar'spec)'
		loc ncols = 14
		tempname ests
	* polynomial specification:
		if strpos("`specification'", "#") > 0 {
			__apcplot_value_range `variable' if __apcest_esample
			loc xvalues = r(xvalues)
			mat `ests' = J(`:word count `xvalues'', `ncols', .)
			forv i=1/`=rowsof(`ests')' {
				loc x = `:word `i' of `xvalues''
				mat `ests'[`i', 1] = `x' // x original value scale
				mat `ests'[`i', 2] = `x' - `e(`apcvar'center)' // xL
				loc formula 0
				forv j=1/`:word count `specification'' {
					loc xpowered = `ests'[`i', 2]^(`=`j'+1')
					loc formula `formula'+_b[`: word `j' of `specification'']*`xpowered'
				}
				qui lincom `formula' `lincom_ci'
				mat `ests'[`i', 3] = r(estimate) // NL
				if `no_ci' mat `ests'[`i', 4] = . // NLlbCI
					else mat `ests'[`i', 4] = r(lb)
				if `no_ci' mat `ests'[`i', 5] = . // NLubCI
					else mat `ests'[`i', 5] = r(ub)
			}
		}
	* categorical specification: // DOES NOT INCLUDE NUMLIST TYPE VARS!!!
		else if substr("`specification'", 1, 1) == "i" & strpos("`specification'", ".") > 0 {
			loc coeflist : colnames e(b)
			loc coefficients
			loc xvalues
			loc varname_length = strlen("__apcest_`apcvar'")
			foreach coef in `coeflist' {
				if strpos("`coef'", ".__apcest_`apcvar'") & ///
				(strlen("`coef'") - strpos("`coef'", ".__apcest_`apcvar'")) ///
				== `varname_length' {
					loc value = substr("`coef'", 1, strpos("`coef'", ".") - 1)
					loc value : subinstr loc value "bn" "", all
					loc value : subinstr loc value "b" "", all
					loc value : subinstr loc value "o" "", all
					loc xvalues `xvalues' `value'
					loc coefficients `coefficients' `coef'
				}
			}
			mat `ests' = J(`: word count `xvalues'', `ncols', .)
			forv i=1/`=rowsof(`ests')' {
				loc x = `:word `i' of `xvalues''
				mat `ests'[`i', 1] = `x' // x original value scale
				mat `ests'[`i', 2] = `x' - `e(`apcvar'ref)' // xL
				qui lincom _b[`:word `i' of `coefficients''] `lincom_ci'
				mat `ests'[`i', 3] = r(estimate) // NL
				if `no_ci' mat `ests'[`i', 4] = . // NLlbCI
					else mat `ests'[`i', 4] = cond(mi(r(lb)), 0, r(lb))
				if `no_ci' mat `ests'[`i', 5] = . // NLubCI
					else mat `ests'[`i', 5] = cond(mi(r(ub)), 0, r(ub))
			}
		}
	* linear specification
		else if "`specification'" == "" {
			__apcplot_value_range `variable' if __apcest_esample
			loc xvalues = r(xvalues)
			mat `ests' = J(`:word count `xvalues'', `ncols', .)
			forv i=1/`=rowsof(`ests')' {
				loc x = `:word `i' of `xvalues''
				mat `ests'[`i', 1] = `x' // x original value/scale
				mat `ests'[`i', 2] = `x' - `e(`apcvar'center)'
				mat `ests'[`i', 3] = 0
				if `no_ci' mat `ests'[`i', 4] = .
					else mat `ests'[`i', 4] = 0
				if `no_ci' mat `ests'[`i', 5] = .
					else mat `ests'[`i', 5] = 0
			}
		}
	* inappropriate input
		else {
			di as error "Variable specifications unclear! Please check."
			exit
		}
	* joint linear + nonlinear calculations
		loc baseline = ``apcvar'_value'
		forv i=1/`=rowsof(`ests')' {
			loc x = `ests'[`i', 2]
			if `bounded' {
				loc pe_slp_min = `: word 1 of `pe_`apcvar'_bounds''
				loc pe_slp_max = `: word 2 of `pe_`apcvar'_bounds''
				if "`apcvar'" == "p" { // a master flipper for period effects
					loc pe_slp_min = `: word 2 of `pe_`apcvar'_bounds''
					loc pe_slp_max = `: word 1 of `pe_`apcvar'_bounds''
				}
				if !`no_ci' loc ci_slp_min = `: word 1 of `ci_`apcvar'_bounds''
				if !`no_ci' loc ci_slp_max = `: word 2 of `ci_`apcvar'_bounds''
			}
			mat `ests'[`i', 6] = `ests'[`i', 3] + `baseline' * `x' // NLshift (PE)
			if `no_ci' {
				mat `ests'[`i', 7] = .
				mat `ests'[`i', 8] = .
			}
			else {
				mat `ests'[`i', 7] = `ests'[`i', 4] + `baseline' * `x' // NLlbCIshift (CI)
				mat `ests'[`i', 8] = `ests'[`i', 5] + `baseline' * `x' // NLubCIshift (CI)
			}
			if `bounded' {
				mat `ests'[`i', 9] = `pe_slp_min' * `x' // lbL (PE)
				mat `ests'[`i', 10] = `pe_slp_max' * `x' // ubL (PE)
				mat `ests'[`i', 11] = `ests'[`i', 9] + `ests'[`i', 3] // lb = lbL + NL (PE)
				mat `ests'[`i', 12] = `ests'[`i', 10] + `ests'[`i', 3] // ub = ubL + NL (PE)
				if `no_ci' {
					mat `ests'[`i', 13] = .
					mat `ests'[`i', 14] = .
				}
				else {
					mat `ests'[`i', 13] = ///
						min(`ci_slp_min' * `x', `ci_slp_max' * `x') + ///
						`ests'[`i', 4] // lbCI = NLlbCI (CI)
					mat `ests'[`i', 14] = ///
						max(`ci_slp_min' * `x', `ci_slp_max' * `x') + ///
						`ests'[`i', 5] // ubCI = NLubCI (CI)
				}
			}
			else {
				foreach j in 9 10 11 12 13 14 {
					mat `ests'[`i', `j'] = .
				}
			}
		}
		mat coln `ests' = x xL NL NLlbCI NLubCI /// cols 1-5
			NLshift NLlbCIshift NLubCIshift /// cols 6-8
			lbL ubL lb ub lbCI ubCI // cols 9-14
		tempname `apcvar'_ests
		mat ``apcvar'_ests' = `ests'
	}

*** Grid palette, matrix and label rendering (if requested)
	if !`no_grid' {
	* palettes:
		if "`gridpalette'" == "" loc gridpalette = "tableau"
		if strpos("`gridpalette'", ",") {
			loc comma = strpos("`gridpalette'", ",")
			loc pal1 = trim(substr("`gridpalette'", `comma' + 1, .))
			loc pal2 = trim(substr("`gridpalette'", 1, `comma' - 1))
			forv i = 1/2 {
				colorpalette `pal`i'', nogr n(`grid_steps')
				forv j = 1/`grid_steps' {
					loc pal`i'color`j' = r(p`j')
				}
			}
		}
		else {
			loc ncolors = 2 * `grid_steps'
			colorpalette `gridpalette', nogr n(`ncolors')
			forv j = 1/`grid_steps' {
				loc pal1color`j' = r(p`j')

				loc k = `grid_steps' + `j'
				loc pal2color`j' = r(p`k')
			}
		}
	* grid-line opacity:
		if "`gridfading'" == "" loc gridfading = 0
		forv j = 1/`grid_steps' {
			if `gridfading' == 0 | `grid_steps' == 1 loc fading`j' = 100
			else loc fading`j' = int(100 * (1 - (`j' - 1) / (`grid_steps' - 1))^`gridfading')
		}
	* matrices and labels:
		foreach apcvar in `selection' {
			loc signs `grid_sign'
			if `anchorgrid' & "`apcvar'" == "p" {
				if "`grid_sign'" == "-" loc signs +
				if "`grid_sign'" == "+" loc signs -
				if "`grid_sign'" == "- +" loc signs + -
			}
			loc colnames
			forv i=1/`:word count `signs'' {
				loc sign `:word `i' of `signs''
				__apcplot_make_gradient ``apcvar'_ests' ///
					NLshift `=`sign'`grid_step'' `grid_steps' grid 0
				tempname grid_matrix
				mat `grid_matrix' = r(gradient_matrix)
				loc style place(c)
				if "`gridlabops'" != "" loc style `gridlabops'
				loc xmin = ``apcvar'_ests'[1, "x"]
				loc xmax = ``apcvar'_ests'[`=rowsof(``apcvar'_ests')', "x"]
				loc grid_labels
				forv j=1/`grid_steps' {
					if "`gridlabels'" != "off" {
						loc y_xmin = `grid_matrix'[1, `j']
						loc y_xmax = `grid_matrix'[`=rowsof(`grid_matrix')', `j']
						loc left_label = "`sign'" + string(`grid_step' * `j', "%9.3g")
						loc right_label `left_label'
						if "`gridlabels'" == "left" loc right_label
						if "`gridlabels'" == "right" loc left_label
						loc color `pal`i'color`j''
						loc grid_labels `grid_labels' ///
							text(`y_xmin' `xmin' "`left_label'", c("`color'"%`fading`j'') `style') ///
							text(`y_xmax' `xmax' "`right_label'", c("`color'"%`fading`j'') `style')
					}
					loc colnames `colnames' grid`=`j'+(`i'-1)*`grid_steps''
				}
				loc `apcvar'_grid_labels ``apcvar'_grid_labels' `grid_labels'
				tempname grid_matrix`i'
				mat `grid_matrix`i'' = `grid_matrix'
				loc nruns = `i'
			}
			tempname `apcvar'_grid_matrix
			if `nruns' == 1 mat ``apcvar'_grid_matrix' = `grid_matrix1'
			else {
				mat ``apcvar'_grid_matrix' = (`grid_matrix1', `grid_matrix2')
				mat coln ``apcvar'_grid_matrix' = `colnames'
			}
		}
	}

*** Render a bounded solution matrix (if requested)
	if `bounded' {
		foreach apcvar in `selection' {
			tempname `apcvar'_gradient_matrix
			if !`nogradient' {
				if "`areapalette'" == "" loc areapalette "CET R1"
				colorpalette `areapalette', nogr n(`grades')
				forv i = 1 / `grades' {
					loc gradcolor`i' = r(p`i')
				}
				loc step = (`: word 2 of `pe_`apcvar'_bounds'' - ///
					`: word 1 of `pe_`apcvar'_bounds'') / (`grades' - 1)
				if "`apcvar'" == "p" loc step = -`step'
				__apcplot_make_gradient ``apcvar'_ests' lb `step' `grades' grad 1
				mat ``apcvar'_gradient_matrix' = r(gradient_matrix)
			}
			else {
				loc step = (`: word 2 of `pe_`apcvar'_bounds'' - ///
					`: word 1 of `pe_`apcvar'_bounds'')
				__apcplot_make_gradient ``apcvar'_ests' lb `step' 2 grad 1
				mat ``apcvar'_gradient_matrix' = r(gradient_matrix)
			}
		}
	}

*** Combine (and drop redundant) matrices
	foreach apcvar in `selection' {
		tempname `apcvar'_plot_matrix
		mat ``apcvar'_plot_matrix' = ``apcvar'_ests'
		foreach m in grid gradient {
			cap mat ``apcvar'_plot_matrix' = ///
				(``apcvar'_plot_matrix', ``apcvar'_`m'_matrix')
		}
	}

*** Combine matrices, render graphs, and assemble the plot
	loc recast rarea
	loc recastci rarea
	loc atitle Age
	loc ptitle Period
	loc ctitle Cohort
	foreach apcvar in `selection' {
		loc xlabels : val lab `e(`apcvar'varname)'
		preserve
		clear
		qui svmat ``apcvar'_plot_matrix', n(col)
		la val x `xlabels'
		if !`bounded' | `keepshape' ///
			loc pe_plot (line NLshift x, sort `shapeplotops')
		if !`bounded' & !`no_ci' ///
			loc cipe_plot (`recastci' NLlbCIshift NLubCIshift x, sort `ciplotops')
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
		if `bounded' {
			if `info' {
				loc assumptions `""{bf:Assumptions:}" "`=e(Aassumptions)'" "`=e(Passumptions)'" "`=e(Cassumptions)'""'
				loc letter = upper("`apcvar'")
				loc infos "`=e(pe`letter'bounds)'"
				if !`no_ci' loc infos "`infos'" "`=e(ci`letter'bounds)' (CI-adjusted)"
				if `combined' {
					loc infos note("`infos'")
					loc infos_comb note(`assumptions', pos(6) span justification(center))
				}
				else {
					loc infos "`infos'" " " `assumptions'
					loc infos note("`infos'")
				}
			}
			loc i = 1
			if !`nogradient' {
				loc gradient_plot
				foreach v of var grad* {
					loc color `gradcolor`i''
					loc gradient_plot `gradient_plot' ///
						(line grad`i' x, sort lc("`color'") lp(solid))
					loc ++i
				}
				loc bounded_plot `gradient_plot'
			}
			else loc bounded_plot (rarea grad1 grad2 x, sort lw(0) fc(`areapalette'))
			if !`no_ci' loc cibounded_plot (`recastci' lbCI ubCI x, sort `ciplotops')
		}
	* MASTER PLOT:
        loc plot `cibounded_plot' `bounded_plot' `contour_plot' ///
            `cipe_plot' `grid_plot' `pe_plot'
        loc graphics `c(graphics)'
        if `suppress' qui set graphics off
        cap noi tw `plot', ``apcvar'_grid_labels' ///
            yti("") xti(``apcvar'title', height(7)) ///
            leg(off) name(``apcvar'title', replace) ///
            `plotops' ``apcvar'plotops' `infos'
        loc rc = _rc
        if `suppress' qui set gr `graphics'
        restore
        if `rc' exit `rc'
		loc plots_to_combine `plots_to_combine' ``apcvar'title'
	}
	* COMBINED PLOT:
	if `combined' & `nplots' > 1 { 
		gr combine `plots_to_combine', r(1) ycom name(Combined, replace) ///
			xsiz(`: word count `plots_to_combine'') ysiz(1) `combplotops' `infos_comb'
	}
	* MATRICES:
    if "`matrix'" != "" { // ADD SUFFIX TO MATRIX NAMES PROVIDED IN MATRIX(NAME)???
		loc stored_matrices
		foreach apcvar in `selection' {
			loc output_matrix_pe `apcvar'PE_`matrix'
			mat `output_matrix_pe' = (``apcvar'_ests'[1..., "lb"], ///
									  ``apcvar'_ests'[1..., "ub"], ///
									  ``apcvar'_ests'[1..., "x"])
			mat colnames `output_matrix_pe' = lower_Y upper_Y X
			loc stored_matrices `stored_matrices' `output_matrix_pe'
			if !`no_ci' {
				loc output_matrix_ci `apcvar'CI_`matrix'
				mat `output_matrix_ci' = (``apcvar'_ests'[1..., "lbCI"], ///
										  ``apcvar'_ests'[1..., "ubCI"], ///
										  ``apcvar'_ests'[1..., "x"])
				mat colnames `output_matrix_ci' = lower_Y upper_Y X
                loc stored_matrices `stored_matrices' `output_matrix_ci'
            }
        }
		loc nstored : word count `stored_matrices'
		if `nstored' == 1 di as txt "Plot values matrix stored: {bf:`stored_matrices'}"
		else di as txt "Plot values matrices stored: {bf:`stored_matrices'}"
	}

	end

*** Routines: ******************************************************************
	pr de __apcplot_value_range, rclass
		syntax varlist(min=1 max=1) [if]
		qui sum `varlist' `if'
		loc step = (r(max) - r(min)) / 20
		numlist "`r(min)'(`step')`r(max)'", sort
		loc values = r(numlist)
		loc xvalues
		foreach value in `values' {
			loc xvalues `xvalues' `=round(`value', 1)'
		}
		ret loc xvalues `xvalues'
	end
	pr de __apcplot_make_gradient, rclass
		args input_matrix reference_col step grades col_prefix offset
		tempname gradient
		mat `gradient' = J(`=rowsof(`input_matrix')', `grades', .)
		loc col_names
		forv j=1/`grades' {
			forv i=1/`=rowsof(`gradient')' {
				loc x = `input_matrix'[`i', "xL"]
				loc reference = `input_matrix'[`i', "`reference_col'"]
				mat `gradient'[`i', `j'] = `reference' + `x' * `step' * (`j' - `offset')
			}
			loc col_names `col_names' `col_prefix'`j'
		}
		mat coln `gradient' = `col_names'
		ret mat gradient_matrix = `gradient'
	end
	pr de __apcplot_refine_values, rclass
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
