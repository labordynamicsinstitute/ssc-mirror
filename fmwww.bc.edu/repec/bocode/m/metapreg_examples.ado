 program metapreg_examples
	version 14.1
	`1'
end

program define metapreg_example_one_one
	preserve
	use "http://fmwww.bc.edu/repec/bocode/a/arbyn2009jcellmolmedfig1.dta", clear
	
	di ". decode tgroup, g(STRtgroup)"
	
	di ". metapreg num denom, ///"
	di "	studyid(study) ///"
	di "	by(STRtgroup)  ///"
	di "	cimethod(exact) ///"
	di "	label(namevar=author, yearvar=year) ///"
	di "	xlab(.25, 0.5, .75, 1) ///"
	di "	subti(Atypical cervical cytology, size(4)) ///"
	di "	graphregion(color(white)) ///"
	di "	texts(1.25)  smooth gof	"

	set more off
	
	decode tgroup, g(STRtgroup)
		
	metapreg num denom, ///
		studyid(study) ///
		by(STRtgroup) ///
		cimethod(exact) ///
		label(namevar=author, yearvar=year) ///
		xlab(.25, 0.5, .75, 1) ///
		subti(Atypical cervical cytology, size(4)) ///
		graphregion(color(white)) /// 
		texts(1.25) smooth gof	
	restore
end

program define metapreg_example_one_two
	preserve
	use "http://fmwww.bc.edu/repec/bocode/a/arbyn2009jcellmolmedfig1.dta", clear
	di ". bys tgroup, rc0: metapreg num denom, ///"
	di "	studyid(study) ///"
	di "	cimethod(wilson) ///"
	di "	label(namevar=author, yearvar=year) ///"
	di "	xlab(.25, 0.5, .75, 1) ///"
	di "	subti(Atypical cervical cytology, size(4)) ///"
	di "	graphregion(color(white)) /// "
	di "	texts(1.5) smooth"

	set more off
	bys tgroup, rc0: metapreg num denom, ///
		studyid(study) ///
		cimethod(wilson) ///
		label(namevar=author, yearvar=year) ///
		xlab(0, .25, 0.5, .75, 1) ///
		subti(Atypical cervical cytology, size(4)) ///
		graphregion(color(white)) /// 
		texts(1.5) smooth
	restore
end

program define metapreg_example_one_three
	preserve
	use "http://fmwww.bc.edu/repec/bocode/a/arbyn2009jcellmolmedfig1.dta", clear
	di ". decode tgroup, g(STRtgroup)"
	di ""
	di ". metapreg num denom STRtgroup, ///"
	di "	studyid(study) ///"
	di "	sumtable(all) ///"
	di "	cimethod(exact) ///"
	di "	label(namevar=author, yearvar=year) ///"
	di "	xlab(.25, 0.5, .75, 1) ///"
	di "	subti(Atypical cervical cytology, size(4)) ///"
	di "	graphregion(color(white)) ///" 
	di "	texts(1.5)  summaryonly"
	
	set more off
	
	decode tgroup, g(STRtgroup)

	metapreg num denom STRtgroup, ///
		studyid(study) ///
		cimethod(exact) ///
		sumtable(all)  ///
		label(namevar=author, yearvar=year) ///
		xlab(0, .25, 0.5, .75, 1) ///
		subti(Atypical cervical cytology, size(4)) ///
		graphregion(color(white)) /// 
		texts(1.5)  summaryonly
		
	restore
end

program define metapreg_example_two_one
	preserve
	use "http://fmwww.bc.edu/repec/bocode/t/tsoumpou2009cancertreatrevfig2WNL.dta", clear
	di ". metapreg p16p p16ptot, ///" 
	di "	studyid(study)  sumtable(all) ///"
	di "	label(namevar=author, yearvar=year) ///" 
	di "	sortby(year author) ///"
	di "	xlab(0, .1, .2, 0.3,0.4,0.5)  ///"
	di "	xline(0, lcolor(black)) ///"
	di "	ti(Positivity of p16 immunostaining, size(4) color(blue)) ///"
	di "	subti(Cytology = WNL, size(4) color(blue)) ///"
	di "	pointopt(msymbol(x)msize(2)) ///"
	di "	graphregion(color(white)) ///"
	di "	texts(1.5) smooth gof"

	set more off

	metapreg p16p p16tot, ///		
		studyid(study) sumtable(all) ///
		label(namevar=author, yearvar=year) ///
		sortby(year author) ///
		xlab(0, .1, .2, 0.3, 0.4, 0.5) ///
		xline(0, lcolor(black)) ///
		ti(Positivity of p16 immunostaining, size(4) color(blue)) ///
		subti(Cytology = WNL, size(4) color(blue)) ///
		graphregion(color(white)) /// 
		pointopt(msymbol(X)msize(2)) /// 
		texts(1.5) smooth gof
	restore
end

program define metapreg_example_two_two
	preserve
	use "http://fmwww.bc.edu/repec/bocode/t/tsoumpou2009cancertreatrevfig2WNL.dta", clear
	di ". metapreg p16p p16ptot, link(loglog) ///" 
	di "	studyid(study) sumtable(all) ///"
	di "	label(namevar=author, yearvar=year) ///" 
	di "	sortby(year author) ///"
	di "	xlab(0, .1, .2, 0.3,0.4,0.5)  ///"
	di "	xline(0, lcolor(black)) ///"
	di "	ti(Positivity of p16 immunostaining, size(4) color(blue)) ///"
	di "	subti(Cytology = WNL, size(4) color(blue)) ///"
	di "	pointopt(msymbol(x)msize(2)) ///"
	di "	graphregion(color(white)) ///"
	di "	texts(1.5) smooth gof"

	set more off

	metapreg p16p p16tot, link(loglog) ///		
		studyid(study) sumtable(all) ///
		label(namevar=author, yearvar=year) ///
		sortby(year author) ///
		xlab(0, .1, .2, 0.3, 0.4, 0.5) ///
		xline(0, lcolor(black)) ///
		ti(Positivity of p16 immunostaining, size(4) color(blue)) ///
		subti(Cytology = WNL, size(4) color(blue)) ///
		graphregion(color(white)) /// 
		pointopt(msymbol(X)msize(2)) /// 
		texts(1.5) smooth gof
	restore
end


program define metapreg_example_three_one
	preserve
	use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta", clear
	di ". metapreg cases_tb population bcg,  ///" 
	di "	studyid(study) ///"
	di "	sumtable(all) ///"
	di "	design(comparative)	///"
	di "	outplot(rr) ///"
	di "	sumstat(Risk ratio) ///"
	di "	graphregion(color(white)) /// "
	di "	xlab(0, 1, 2) ///"
	di "	xtick(0, 1, 2)  /// "
	di "	rcols(cases_tb population) /// "
	di "	astext(80) /// "
	di "	texts(1.5) logscale smooth" 

	set more off
	
	metapreg cases_tb population bcg,  /// 
		studyid(study) ///
		sumtable(all)  ///
		design(comparative)	///
		outplot(rr) ///
		sumstat(Risk ratio) ///
		graphregion(color(white)) /// 
		xlab(0, 1, 2) /// 
		xtick(0, 1, 2)  /// 
		rcols(cases_tb population) /// 
		astext(80) /// 
		texts(1.5) logscale smooth	
	restore
end

program define metapreg_example_three_two
	preserve
	use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta", clear
	di ". metapreg cases_tb population lat,  /// "
	di "	studyid(study) ///"
	di "	sumtable(all) by(bcg)  ///"
	di "	design(comparative)	sortby(lat) ///"
	di "	graphregion(color(white)) /// "
	di "	xlab(0, 0.05, 0.1) /// "
	di "	xtick(0, 0.05, 0.1)  /// "
	di "	sumstat(Proportion) ///"
	di "	rcols(cases_tb population) /// "
	di "	astext(80) /// "
	di "	texts(1.5)  smooth "
		
	set more off
	
	metapreg cases_tb population lat,  /// 
		studyid(study) ///
		sortby(lat) ///
		sumtable(all) by(bcg) ///
		graphregion(color(white)) /// 
		xlab(0, 0.05, 0.15) /// 
		xtick(0, 0.05, 0.15)  /// 
		sumstat(Proportion) ///
		rcols(cases_tb population) /// 
		astext(80) /// 
		texts(1.5)  smooth 		
	restore
end

program define metapreg_example_three_three
	preserve
	use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta", clear
	di ". metapreg cases_tb population bcg lat,  ///" 
	di "	studyid(study) ///"
	di "	sortby(lat) ///"
	di "	sumtable(all) ///"
	di "	design(comparative)  ///"
	di "	outplot(rr) ///"
	di "	interaction ///"
	di "	graphregion(color(white)) /// "
	di "	xlab(0, 1, 2) /// "
	di "	xtick(0, 1, 2)  /// "
	di "	rcols(cases_tb population) /// "
	di "	astext(80) ///" 
	di "	texts(1.5) logscale smooth" 
	
	set more off

	metapreg cases_tb population bcg lat,  /// 
		studyid(study) ///
		sortby(lat) ///
		sumtable(all) ///
		design(comparative)  ///
		outplot(rr) ///
		interaction ///
		graphregion(color(white)) /// 
		xlab(0, 1, 2) /// 
		xtick(0, 1, 2)  /// 
		rcols(cases_tb population) /// 
		astext(80)  /// 
		texts(1.5) logscale smooth
	restore
end

program define metapreg_example_four_one
	preserve
	use "http://fmwww.bc.edu/repec/bocode/s/schizo.dta", clear
	di ". gsort firstauthor arm  "
	di ""
	di ". metapreg response total arm missingdata,  /// "
	di "	studyid(firstauthor) ///"
	di "	sortby(year) link(loglog) ///"
	di "	sumtable(all) ///"
	di "	design(comparative)   ///"
	di "	outplot(rr) ///"
	di "	interaction ///"
	di "	graphregion(color(white)) /// "
	di "	xlab(0, 5, 15) /// "
	di "	xtick(0, 5, 15)  ///" 
	di "	sumstat(Rel Ratio) ///"
	di "	lcols(response total) /// "
	di "	astext(70) /// "
	di "	texts(1.5) logscale smooth ///"
	di "	xsize(12) ysize(6)"
			

	set more off
	
	gsort firstauthor arm
	
	metapreg response total arm missingdata,  /// 
		studyid(firstauthor) ///
		sortby(year) link(loglog) ///
		sumtable(all) ///
		design(comparative)  ///
		outplot(rr) ///
		interaction ///
		graphregion(color(white)) /// 
		xlab(0, 0.5, 1.5) /// 
		xtick(0, .5, 1.5)  /// 
		sumstat(Rel Ratio) ///
		lcols(response total) /// 
		astext(70) /// 
		texts(1.5) logscale smooth xsize(12) ysize(6) 
	restore
end

program define metapreg_example_five_one
	preserve
	use "http://fmwww.bc.edu/repec/bocode/m/matched.dta", clear
	di ". metapreg a b c d index comparator,  /// "
	di "	studyid(study) ///"
	di "	model(fixed)  /// "
	di "	sumtable(all) ///"
	di "	design(mcbnetwork)  ///"
	di "	by(comparator)  ///"
	di "	graphregion(color(white)) /// "
	di "	xlab(0.9, 1, 1.1) /// "
	di "	xtick(0.9, 1, 1.1)  ///" 
	di "	sumstat(Ratio) ///"
	di "	lcols(a b c d comparator index) /// "
	di "	astext(80) /// "
	di "	texts(1.5) logscale  "
	
	set more off
	
	metapreg a b c d index comparator, /// 
		studyid(study) ///
		model(fixed)  /// 
		sumtable(all) ///
		design(mcbnetwork) ///
		by(comparator) ///
		graphregion(color(white)) /// 
		xlab(0.9, 1, 1.1) /// 
		xtick(0.9, 1, 1.1)  /// 
		sumstat(Ratio) ///
		lcols(a b c d comparator index) /// 
		astext(80) /// 
		texts(1.5) logscale smooth
			
	restore
end
