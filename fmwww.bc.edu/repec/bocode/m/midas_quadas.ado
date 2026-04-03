
*! Improved version with composite legend and flexible file paths
capture program drop midas_quadas
program define midas_quadas, rclass sortpreserve
	version 12
	syntax , id(varname) ROBvars(varlist) ACvars(varlist) plot(string) ///
		[COLor scheme(string) SAVing(string) *]

	qui {
		// Use temp directory instead of hardcoded path
		tempfile robbar acbar robsum acsum
		
		if "`plot'" == "bar" {
			quadas2plotr `robvars', bar `color' title("Risk of Bias") `options'
			graph save `robbar', replace

			quadas2plotr `acvars', bar `color' title("Applicability Concerns") `options'
			graph save `acbar', replace  

			nois grc1leg2 `robbar' `acbar', ysiz(3) rows(2) `saving'
		}
		else if "`plot'" == "sum" {
			quadas2plotr `robvars', id(`id') sum `color' ysiz(6) xsiz(3) ///
				title("Risk of Bias") `options'
			graph save `robsum', replace

			quadas2plotr `acvars', id(`id') sum `color' ysiz(6) xsiz(2) ///
				title("Applicability Concerns") `options'
			graph save `acsum', replace

			nois grc1leg2 `robsum' `acsum', legendfrom(`robsum') ///
				ysiz(6) xsiz(4) `saving'
		}
	}
end

capture program drop quadas2plotr
program define quadas2plotr, rclass sortpreserve
	version 12
	syntax varlist(string min=2) [if] [in] , ///
		[id(varname) BAR SUM COLor scheme(string) title(string) *]
	
	preserve
	marksample touse, novarlist
	keep if `touse'

	if "`sum'" == "sum" {
		tokenize `varlist'
		local b 1
		foreach var in `varlist' {
			local critvar : variable label `var'
			if "`critvar'" == "" {
				local critvar = "`var'"
			}
			gen str40 GQ`b' = "`critvar'"
			gen qq`b' = `var'
			local b = `b' + 1
		}
		
		if "`scheme'" == "" {
			set scheme s2mono
		}
		else {
			set scheme `scheme'
		}

		tempvar qmark qplus qminus studyid studdy Quality xvar obs

		if "`id'" == "" {
			gen str10 `studyid' = string(_n)  
		}
		else {
			gen `studyid' = `id'
		}

		gen `studdy' = _n
		gen `obs' = _n
		count
		local max = r(N)
		local maxx = `max' + 0.5
		label value `obs' obs
		forval i = 1/`max' {
			local value = `"`value' `i'"'
			label define obs `i' "`=`studyid'[`i']'", modify
		}

		reshape long qq GQ, i(`studdy') j(`Quality')
		gen `xvar' = 0.05
		generate `qmark' = "?"
		generate `qplus' = "+"
		generate `qminus' = "-"

		local mscale "msize(*4)"

		if "`color'" != "" {
			// COLOR VERSION WITH COMPOSITE LEGEND
			tw (scatter `obs' `xvar', subtitle(, box nobex fcolor(none) ///
				lcolor(none) orientation(vertical) placement(s)) ///
				by(GQ, compact rows(1) noixl noixt note("") ///
				title("`title'", pos(12))) ///
				ymtick(0.5(1)`maxx', grid glc(black) tlcolor(none)) ///
				ylabel(`"`value'"', valuelabel angle(360) nogrid) ///
				ms(O) `mscale' mcol(midgreen) ) ///
			(scatter `obs' `xvar' if qq == "unclear", ms(O) `mscale' mcol(gold)) ///
			(scatter `obs' `xvar' if qq == "high", ms(O) `mscale' mcol(red)) ///
			(scatter `obs' `xvar' if qq == "low", ms(none) mlabs(*2.5) ///
				mla(`qplus') mcol(black) mlabpos(0)) ///
			(scatter `obs' `xvar' if qq == "unclear", ms(none) mlabs(*2.5) ///
				mla(`qmark') mcol(black) mlabpos(0)) ///
			(scatter `obs' `xvar' if qq == "high", ms(none) mla(`qminus') ///
				mlabs(*2.5) mcol(black) mlabpos(0)), ///
			yscale(rev) ytitle("") xtitle("") ///
			legend(order(1 "Low risk" 2 "Unclear risk" 3 "High risk") ///
				pos(6) rows(1) size(small) symxsize(5) region(lcolor(black))) ///
			nodraw `options'
		}
		else {
			// GRAYSCALE VERSION WITH COMPOSITE LEGEND
			tw (scatter `obs' `xvar', subtitle(, box nobex fcolor(none) ///
				lcolor(none) orientation(vertical) placement(s)) ///
				by(GQ, compact rows(1) noixl noixt note("") ///
				title("`title'", pos(12))) ///
				ymtick(0.5(1)`maxx', grid glc(black) tlcolor(none)) ///
				ylabel(`"`value'"', valuelabel angle(360) nogrid) ///
				ms(Oh) `mscale' mcol(black)) ///
			(scatter `obs' `xvar' if qq == "low", ms(none) mlabs(*2.5) ///
				mla(`qplus') mcol(black) mlabpos(0)) ///
			(scatter `obs' `xvar' if qq == "unclear", ms(none) mlabs(*2.5) ///
				mla(`qmark') mcol(black) mlabpos(0)) ///
			(scatter `obs' `xvar' if qq == "high", ms(none) mla(`qminus') ///
				mlabs(*2.5) mcol(black) mlabpos(0)), ///
			yscale(rev) ytitle("") xtitle("") ///
			legend(order(1 "+ Low risk" 2 "? Unclear risk" 3 "- High risk") ///
				pos(6) rows(1) size(small) symxsize(5) region(lcolor(black))) ///
			nodraw `options'
		}
	}

	if "`bar'" == "bar" {
		tokenize `varlist'
		qui {
			tempfile qualires
			tempname qualifile
			postfile `qualifile' str40 Criterion High Unclear Low ///
				using `qualires', replace
			
			foreach var in `varlist' {
				count if `var' == "high"
				local highvar = r(N)
				count if `var' == "unclear"
				local unclear = r(N)
				count if `var' == "low"
				local lowvar = r(N)

				local critvar: variable label `var'
				if "`critvar'" == "" {
					local critvar = "`var'"
				}
				post `qualifile' ("`critvar'") (`highvar') (`unclear') (`lowvar')  
			}
			postclose `qualifile'
			use `qualires', clear
			
			if "`color'" != "" {
				#delimit;
				graph hbar (asis) High Unclear Low, over(Criterion, sort(Total) descending)
					nolabel bar(1, fcolor(red)) bar(2, fcolor(gold)) 
					bar(3, fcolor(midgreen)) plotregion(lcolor(black) margin(zero))
					legend(pos(6) order(3 "Low risk" 2 "Unclear risk" 1 "High risk") 
					row(1) size(small) symxsize(3) region(lcolor(black)))
					stack percent lintensity(*.75) scale(0.85) title(`title') 
					bargap(10) nodraw `options';
				#delimit cr
			}
			else {
				#delimit;
				graph hbar (asis) High Low Unclear, over(Criterion, sort(Total) descending)
					nolabel bar(1, fcolor(black)) bar(2, fcolor(white)) 
					bar(3, fcolor(gray)) plotregion(lcolor(black) margin(zero))
					legend(pos(6) order(2 "Low risk" 3 "Unclear risk" 1 "High risk") 
					row(1) size(small) symxsize(3) region(lcolor(black)))
					stack percent lintensity(*.75) scale(0.85) title(`title')  
					nodraw `options';
				#delimit cr
			}
		}
	}
end

capture program drop grc1leg2
program grc1leg2
	version 12
	syntax [anything] [, LEGendfrom(string) ///
		POSition(string) RING(integer -1) SPAN ///
		NAME(passthru) SAVing(string asis) ///
		XTOB1title XTItlefrom(string) LSize(string) *]

	gr_setscheme, refscheme

	// Location and alignment in cell
	tempname clockpos
	if ("`position'" == "") local position 6
	.`clockpos' = .clockdir.new, style(`position')
	local location `.`clockpos'.relative_position'

	if `ring' > -1 {
		if (`ring' == 0) {
			local location "on"
			local ring ""
		}
		else local ring "ring(`ring')"
	}
	else local ring ""

	if "`span'" != "" {
		if "`location'" == "above" | "`location'" == "below" {
			local span spancols(all)
		}
		else local span spanrows(all)
	}

	// Allow legend to be from any graph
	if "`legendfrom'" != "" {
		local lfrom : list posof "`legendfrom'" in anything
		if `lfrom' == 0 {
			di as error `"`legendfrom' not found in graph name list"'
			exit 198
		}
	}
	else local lfrom 1

	graph combine `anything', `options' `name'

	if "`name'" != "" {
		local 0 `", `name'"'
		syntax [, name(string)]
		local 0 `"`name'"'
		syntax [anything(name=name)] [, replace]
	}
	else local name Graph

	forvalues i = 1/`:list sizeof anything' {
		_gm_edit .`name'.graphs[`i'].legend.draw_view.set_false
		_gm_edit .`name'.graphs[`i'].legend.fill_if_undrawn.set_false

		if "`xtob1title'" ~= "" {
			_gm_edit .`name'.graphs[`i'].xaxis1.title.draw_view.set_false
		}
	}

	// Insert overall legend
	.`name'.insert (legend = .`name'.graphs[`lfrom'].legend) ///
		`location' plotregion1, `ring' `span'

	_gm_log .`name'.insert (legend = .graphs[`lfrom'].legend) ///
		`location' plotregion1, `ring' `span'

	_gm_edit .`name'.legend.style.box_alignment.setstyle, ///
		style(`.`clockpos'.compass2style')

	// Use xtitlefrom xtitle as overall b1title
	if "`xtob1title'" == "" & "`xtitlefrom'" ~= "" {
		local xtob1title xtob1title
	}
	
	if "`xtob1title'" ~= "" {
		if "`xtitlefrom'" != "" {
			local xfrom : list posof "`xtitlefrom'" in anything
			if `xfrom' == 0 {
				di as error `"`xtitlefrom' not found in graph name list"'
				exit 198
			}
		}
		else local xfrom 1

		.`name'.b1title = .`name'.graphs[`xfrom'].xaxis1.title
		_gm_log .`name'.b1title = .graphs[`xfrom'].xaxis1.title
		_gm_edit .`name'.b1title.draw_view.set_true
	}

	_gm_edit .`name'.legend.draw_view.set_true

	// Maintain serset reference counts
	forvalues i = 1/`.`name'.legend.keys.arrnels' {
		if "`.`name'.legend.keys[`i'].view.serset.isa'" != "" {
			_gm_edit .`name'.legend.keys[`i'].view.serset.ref_n + 99
			.`name'.legend.keys[`i'].view.serset.ref = ///
				.`name'.graphs[`lfrom'].legend.keys[`i'].view.serset.ref
			_gm_log .`name'.legend.keys[`i'].view.serset.ref = ///
				.graphs[`lfrom'].legend.keys[`i'].view.serset.ref
		}
		if "`.`name'.legend.plotregion1.key[`i'].view.serset.isa'" != "" {
			_gm_edit ///
				.`name'.legend.plotregion1.key[`i'].view.serset.ref_n + 99
			.`name'.legend.plotregion1.key[`i'].view.serset.ref = ///
				.`name'.graphs[`lfrom'].legend.keys[`i'].view.serset.ref
			_gm_log ///
				.`name'.legend.plotregion1.key[`i'].view.serset.ref = ///
				.graphs[`lfrom'].legend.keys[`i'].view.serset.ref
		}

		// Handle lsize option
		if "`lsize'" ~= "" {
			.`name'.legend.plotregion1.label[`i'].style.editstyle ///
				size(`lsize') editcopy
			_gm_log .`name'.legend.plotregion1.label[`i'].style.editstyle ///
				size(`lsize') editcopy
			_gm_edit .`name'.legend.plotregion1.label[`i'].style.editstyle ///
				size(`lsize') editcopy
		}
	}

	gr draw `name'

	if `"`saving'"' != `""' {
		gr_save `"`name'"' `saving'
	}
end

program GetPos
	gettoken pmac  0 : 0
	gettoken colon 0 : 0

	local 0 `0'
	if `"`0'"' == `""' {
		c_local `pmac' below
		exit
	}

	local 0 ", `0'"
	syntax [, Above Below Leftof Rightof]

	c_local `pmac' `above' `below' `leftof' `rightof'
end
