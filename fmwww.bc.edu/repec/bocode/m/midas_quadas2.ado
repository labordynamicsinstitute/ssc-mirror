
*! midas_quadas2 v2.0 - QUADAS-2 quality assessment plots
*! Single overall legend for both bar and sum plots
capture program drop midas_quadas2
program define midas_quadas2, rclass sortpreserve
	version 12
	syntax , id(varname) ROBvars(varlist) ACvars(varlist) plot(string) ///
		[COLor scheme(string) SAVing(string) *]

	qui {
		capture graph drop _midas_robbar _midas_acbar _midas_robsum _midas_acsum
		
		if "`plot'" == "bar" {
			// Bar plots with legends suppressed
			quadas2plotr `robvars', bar `color' nolegend title("Risk of Bias") `options'
			graph rename Graph _midas_robbar, replace

			quadas2plotr `acvars', bar `color' nolegend title("Applicability Concerns") `options'
			graph rename Graph _midas_acbar, replace

			// Helper graph for bar legend (graphics off to suppress display)
			set graphics off
			if "`color'" != "" {
				tw (scatteri 1 1, ms(S) msize(*3) mcol(midgreen)) ///
					(scatteri 1 1, ms(S) msize(*3) mcol(gold)) ///
					(scatteri 1 1, ms(S) msize(*3) mcol(red)), ///
					legend(on order(3 "Low risk" 2 "Unclear risk" 1 "High risk") ///
					pos(6) rows(1) size(medium) symxsize(3) ///
					region(lcolor(black))) ///
					name(_midas_leghelp, replace)
			}
			else {
				tw (scatteri 1 1, ms(S) msize(*3) mcol(black)) ///
					(scatteri 1 1, ms(S) msize(*3) mcol(white)) ///
					(scatteri 1 1, ms(S) msize(*3) mcol(gray)), ///
					legend(on order(2 "Low risk" 3 "Unclear risk" 1 "High risk") ///
					pos(6) rows(1) size(medium) symxsize(3) ///
					region(lcolor(black))) ///
					name(_midas_leghelp, replace)
			}
			set graphics on

			graph combine _midas_robbar _midas_acbar, rows(2) ysiz(3)

			.Graph.insert (legend = ._midas_leghelp.legend) below plotregion1
			_gm_edit .Graph.legend.draw_view.set_true
			_gm_edit .Graph.legend.style.box_alignment.setstyle, style(south)

			nois gr draw Graph
			
			if `"`saving'"' != `""' {
				gr_save `"Graph"' `saving'
			}
			
			capture graph drop _midas_robbar _midas_acbar _midas_leghelp
		}
		else if "`plot'" == "sum" {
			// Sum plots: suppress by-legends, inject overall legend from helper
			quadas2plotr `robvars', id(`id') sum `color' nolegend ysiz(6) xsiz(3) ///
				title("Risk of Bias") `options'
			graph rename Graph _midas_robsum, replace

			quadas2plotr `acvars', id(`id') sum `color' nolegend ysiz(6) xsiz(2) ///
				title("Applicability Concerns") `options'
			graph rename Graph _midas_acsum, replace

			// Helper graph for sum legend (graphics off to suppress display)
			set graphics off
			if "`color'" != "" {
				tw (scatteri 1 1, ms(O) msize(*3) mcol(midgreen)) ///
					(scatteri 1 1, ms(O) msize(*3) mcol(gold)) ///
					(scatteri 1 1, ms(O) msize(*3) mcol(red)), ///
					legend(on order(1 "Low risk" 2 "Unclear risk" 3 "High risk") ///
					pos(6) rows(1) size(medium) symxsize(5) ///
					region(lcolor(black))) ///
					name(_midas_leghelp, replace)
			}
			else {
				tw (scatteri 1 1, ms(Oh) msize(*3) mcol(black)) ///
					(scatteri 1 1, ms(none)) ///
					(scatteri 1 1, ms(none)), ///
					legend(on order(1 "+ Low risk" 2 "? Unclear risk" 3 "- High risk") ///
					pos(6) rows(1) size(medium) symxsize(5) ///
					region(lcolor(black))) ///
					name(_midas_leghelp, replace)
			}
			set graphics on

			graph combine _midas_robsum _midas_acsum, cols(2) ysiz(6) xsiz(4)

			.Graph.insert (legend = ._midas_leghelp.legend) below plotregion1
			_gm_edit .Graph.legend.draw_view.set_true
			_gm_edit .Graph.legend.style.box_alignment.setstyle, style(south)

			nois gr draw Graph
			
			if `"`saving'"' != `""' {
				gr_save `"Graph"' `saving'
			}
			
			capture graph drop _midas_robsum _midas_acsum _midas_leghelp
		}
	}
end

program define quadas2plotr, rclass sortpreserve
	version 12
	syntax varlist(string min=2) [if] [in] , ///
		[id(varname) BAR SUM COLor NOLEGend scheme(string) title(string) *]
	
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

		if "`nolegend'" != "" {
			local _byleg "legend(off)"
		}
		else {
			local _byleg ""
		}

		if "`color'" != "" {
			tw (scatter `obs' `xvar', subtitle(, box nobex fcolor(none) ///
				lcolor(none) orientation(vertical) placement(s)) ///
				by(GQ, compact rows(1) noixl noixt note("") `_byleg' ///
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
			tw (scatter `obs' `xvar', subtitle(, box nobex fcolor(none) ///
				lcolor(none) orientation(vertical) placement(s)) ///
				by(GQ, compact rows(1) noixl noixt note("") `_byleg' ///
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

		// Handle nolegend option for bar plots
		if "`nolegend'" != "" {
			local _barleg "legend(off)"
		}
		else if "`color'" != "" {
			local _barleg `"legend(pos(6) order(3 "Low risk" 2 "Unclear risk" 1 "High risk") row(1) size(small) symxsize(3) region(lcolor(black)))"'
		}
		else {
			local _barleg `"legend(pos(6) order(2 "Low risk" 3 "Unclear risk" 1 "High risk") row(1) size(small) symxsize(3) region(lcolor(black)))"'
		}

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
					`_barleg'
					stack percent lintensity(*.75) scale(0.85) title(`title') 
					bargap(10) nodraw `options';
				#delimit cr
			}
			else {
				#delimit;
				graph hbar (asis) High Low Unclear, over(Criterion, sort(Total) descending)
					nolabel bar(1, fcolor(black)) bar(2, fcolor(white)) 
					bar(3, fcolor(gray)) plotregion(lcolor(black) margin(zero))
					`_barleg'
					stack percent lintensity(*.75) scale(0.85) title(`title')  
					nodraw `options';
				#delimit cr
			}
		}
	}
end

program grc1leg2
	version 12
	syntax [anything] [, LEGendfrom(string) ///
		POSition(string) RING(integer -1) SPAN ///
		NAME(passthru) SAVing(string asis) ///
		XTOB1title XTItlefrom(string) LSize(string) *]

	gr_setscheme, refscheme

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

	.`name'.insert (legend = .`name'.graphs[`lfrom'].legend) ///
		`location' plotregion1, `ring' `span'

	_gm_log .`name'.insert (legend = .graphs[`lfrom'].legend) ///
		`location' plotregion1, `ring' `span'

	_gm_edit .`name'.legend.style.box_alignment.setstyle, ///
		style(`.`clockpos'.compass2style')

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
