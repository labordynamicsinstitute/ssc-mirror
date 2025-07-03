 program metapreg_examples
	version 14.1
	
	if _caller() >= 16 {
		version 16.1
	}
	`1'
end

*global wdir "C:\DATA\WIV\Projects\Stata\Metapreg\mcmcresults"

//1.1
program define metapreg_example_one_one
	preserve
	use "http://fmwww.bc.edu/repec/bocode/a/arbyn2009jcellmolmedfig1.dta", clear
		
	di ". metapreg num denom, ///"
	di "	studyid(study) ///"
	di "	by(tgroup)  ///"
	di "	cimethod(exact) ///"
	di "	label(namevar=author, yearvar=year) catpplot ///"
	di "	xlab(.25, 0.5, .75, 1) ///"
	di "	subti(Atypical cervical cytology, size(4)) ///"
	di "	texts(1.25)  smooth gof	"

	set more off

	metapreg num denom,   ///
		studyid(study) ///
		by(tgroup) ///
		/*inference(bayesian) bwd($wdir) */ /// 
		cimethod(exact) ///
		label(namevar=author, yearvar=year) catpplot  ///
		xlab(.25, 0.5, .75, 1) ///
		subti(Atypical cervical cytology, size(4)) ///
		texts(1.25) smooth gof	
	restore
end

//1.2
program define metapreg_example_one_two
	preserve
	use "http://fmwww.bc.edu/repec/bocode/a/arbyn2009jcellmolmedfig1.dta", clear
	di ". bys tgroup, rc0: metapreg num denom, ///"
	di "	studyid(study) ///"
	di "	cimethod(wilson) ///"
	di "	label(namevar=author, yearvar=year) catpplot ///"
	di "	xlab(.25, 0.5, .75, 1) ///"
	di "	subti(Atypical cervical cytology, size(4)) ///"
	di "	texts(1.5) smooth"

	set more off

	bys tgroup, rc0: metapreg num denom,  ///
		/*inference(bayesian) bwd($wdir)*/ /// 
		studyid(study) ///
		cimethod(wilson) ///
		label(namevar=author, yearvar=year) catpplot ///
		xlab(0, .25, 0.5, .75, 1)  ///
		subti(Atypical cervical cytology, size(4)) ///
		graphregion(color(white)) /// 
		texts(1.5) smooth
	restore
end

//1.3
program define metapreg_example_one_three
	preserve
	use "http://fmwww.bc.edu/repec/bocode/t/tsoumpou2009cancertreatrevfig2WNL.dta", clear
	di ". metapreg p16p p16ptot, ///" 
	di "	studyid(study)  ///"
	di "	label(namevar=author, yearvar=year) catpplot  ///" 
	di "	sortby(year author) ///"
	di "	xlab(0, .1, .2, 0.3, 0.4, 0.5)  ///"
	di "	xline(0, lcolor(black)) ///"
	di "	ti(Positivity of p16 immunostaining, size(4) color(blue)) ///"
	di "	subti(Cytology = WNL, size(4) color(blue)) ///"
	di "	pointopt(msymbol(X)msize(2)) ///"
	di "	texts(1.5) smooth gof"

	set more off

	metapreg p16p p16tot, ///		
		studyid(study)  ///
		label(namevar=author, yearvar=year) catpplot  ///
		/*inference(bayesian) bwd($wdir)*/  /// 
		sortby(year author) ///
		xlab(0, .1, .2, 0.3, 0.4, 0.5) ///
		xline(0, lcolor(black)) ///
		ti(Positivity of p16 immunostaining, size(4) color(blue)) ///
		subti(Cytology = WNL, size(4) color(blue)) ///
		pointopt(msymbol(X)msize(2)) /// 
		texts(1.5) smooth gof
	restore
end

//1.4
program define metapreg_example_one_four
	preserve
	use "http://fmwww.bc.edu/repec/bocode/t/tsoumpou2009cancertreatrevfig2WNL.dta", clear
	di ". metapreg p16p p16ptot, link(loglog) ///" 
	di "	studyid(study) sumtable(all) ///"
	di "	label(namevar=author, yearvar=year) catpplot ///" 
	di "	sortby(year author)  ///"
	di "	xlab(0, .1, .2, 0.3, 0.4, 0.5)  ///"
	di "	xline(0, lcolor(black)) ///"
	di "	ti(Positivity of p16 immunostaining, size(4) color(blue)) ///"
	di "	subti(Cytology = WNL, size(4) color(blue)) ///"
	di "	pointopt(msymbol(X)msize(2)) ///"
	di "	texts(1.5) smooth gof"

	set more off
		
	metapreg p16p p16tot, link(loglog) ///		
		studyid(study) sumtable(all) ///
		label(namevar=author, yearvar=year) catpplot ///
		sortby(year author)  ///
		xlab(0, .1, .2, 0.3, 0.4, 0.5) ///
		xline(0, lcolor(black)) ///
		ti(Positivity of p16 immunostaining, size(4) color(blue)) ///
		subti(Cytology = WNL, size(4) color(blue)) ///
		pointopt(msymbol(X)msize(2)) /// 
		texts(1.5) smooth gof
	restore
end

//2.1
program define metapreg_example_two_one
	preserve
	use "http://fmwww.bc.edu/repec/bocode/a/arbyn2009jcellmolmedfig1.dta", clear

	di ". metapreg num denom tgroup, ///"
	di "	studyid(study) ///"
	di "	sumtable(rd rr) ///"
	di "	cimethod(exact) ///"
	di "	label(namevar=author, yearvar=year) ///"
	di "	xlab(.25, 0.5, .75) ///"
	di "	subti(Atypical cervical cytology, size(4)) ///"
	di "	texts(1.5)  summaryonly"
	
	set more off
	
	metapreg num denom tgroup,  ///
		/*inference(bayesian) bwd($wdir)*/ /// 
		studyid(study) ///
		cimethod(exact) ///
		sumtable(all)  ///
		label(namevar=author, yearvar=year)  ///
		xlab(.25, 0.5, .75) ///
		subti(Atypical cervical cytology, size(4)) ///
		texts(1.5)  summaryonly 
	restore
end

//2.2.1
program define metapreg_example_two_two_one
	preserve
	use "https://github.com/VNyaga/Metapreg/blob/master/Build/hemkens2016analysis110.dta?raw=1", clear

	di ". gsort study -treatment"
	di ". metapreg events total treatment,   ///"
	di "	studyid(study)  design(comparative, cov(independent))   ///"
	di "	smooth gof  catpplot nofplot   ///"
	di "	outplot(rr)  xline(1) sumstat(Risk Ratio)  ///"	
	di "	xlab(0, 1, 30) logscale  ///"
	di "	texts(2.35)  astext(80)" 
	
	gsort study -treatment

	set more off

	metapreg events total treatment,   ///
	studyid(study)  design(comparative, cov(independent))   ///
	/*inference(bayesian) bwd($wdir)*/ ///
	smooth gof  catpplot nofplot   ///
	outplot(rr)  xline(1) sumstat(Risk Ratio)  ///	
	xlab(0, 1, 30) logscale  ///
	texts(2.35)  astext(80) 
	restore

end

//2.2.2 Three studies -  bender 2018 fig2
program define metapreg_example_two_two_two
	preserve
	use "https://github.com/VNyaga/Metapreg/blob/master/Build/bender2018fig2.dta?raw=1", clear
	
	di ". metapreg event total treatment,  ///"
	di "	studyid(study) design(comparative, cov(independent))  ///"
	di "	smooth gof  catpplot nofplot cimethod(,wald)  ///"
	di "	outplot(rr)  xline(1) sumstat(Risk Ratio)  	///"
	di "	xlab(1, 5, 30) logscale  ///"
	di "	texts(2) astext(70)"

	set more off
	
	metapreg event total treatment,  ///
	studyid(study) design(comparative, cov(independent))  ///
	smooth gof  catpplot nofplot cimethod(,wald)  ///
	/*inference(bayesian) bwd($wdir)*/ ///
	outplot(rr)  xline(1) sumstat(Risk Ratio)  	///
	xlab(1, 5, 30) logscale  ///
	texts(2) astext(70) 

	restore
	
end

//2.2.3 - Extreme data sparsity
program define metapreg_example_two_two_three
	preserve
	use "https://github.com/VNyaga/Metapreg/blob/master/Build/hemkens2016analysis18.dta?raw=1", clear

	di ". gsort study -treatment"	
		
	di ". metapreg event total treatment,   ///" 
	di "	studyid(study) ///" 
	di "	design(comparative, cov(commonint))  ///" 
	di "	smooth gof  catpplot nofplot  ///" 
	di "	outplot(rr) xline(1) sumstat(Risk Ratio) ///" 
	di "	xlab(0.01, 1, 100) logscale  ///" 
	di "	texts(1.75) astext(60)" 

	gsort study -treatment	
	
	set more off	
	
	metapreg event total treatment,   ///
		studyid(study) ///
		design(comparative, cov(commonint))  ///
		/*inference(bayesian) bwd($wdir)*/ ///
		smooth gof  catpplot nofplot  ///
		outplot(rr) xline(1) sumstat(Risk Ratio)	///
		xlab(0.01, 1, 100) logscale  ///
		texts(1.75) astext(60)
	restore
end

//2.2.4
program define metapreg_example_two_two_four
	preserve
	use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta", clear
	
	di ". metapreg cases_tb population bcg,  ///" 
	di "	studyid(study) model(mixed, intmethod(mv)) ///"
	di "	design(comparative, cov(commonslope)) ///"
	di "	outplot(rr) ///"
	di "	sumstat(Risk ratio) ///"
	di "	xlab(0, 1, 2) ///"
	di "	xtick(0, 1, 2)  /// "
	di "	rcols(cases_tb population) /// "
	di "	astext(80) /// "
	di "	texts(1.5) logscale smooth gof" 

	set more off
	
	#delimit ;
	metapreg cases_tb population bcg, 
		studyid(study) model(mixed, intmethod(mv))
		design(comparative, cov(commonslope))	
		/*inference(bayesian) bwd($wdir)*/ 
		outplot(rr) 
		sumstat(Risk ratio) 
		xlab(0, 1, 2) 
		xtick(0, 1, 2)  
		rcols(cases_tb population) 
		astext(80) 
		texts(1.5) logscale smooth gof
		;
	#delimit cr	
	restore
end

//2.2.5
program define metapreg_example_two_two_five
	preserve
	use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta", clear
	di ". metapreg cases_tb population lat,  /// "
	di "	studyid(study) model(mixed, intmethod(mv)) ///"
	di "	sumtable(all) by(bcg)  ///"
	di "	sortby(lat) ///"
	di "	xlab(0, 0.05, 0.1) /// "
	di "	xtick(0, 0.05, 0.1)  /// "
	di "	sumstat(Proportion) ///"
	di "	rcols(cases_tb population) /// "
	di "	astext(80) /// "
	di "	texts(1.5)  smooth "
		
	set more off

	
	metapreg cases_tb population lat,  /// 
		/*inference(bayesian) bwd($wdir)*/ /// 
		studyid(study) model(mixed, intmethod(mv)) ///
		sortby(lat) by(bcg) ///
		xlab(0, 0.05, 0.15) /// 
		xtick(0, 0.05, 0.15)  /// 
		sumstat(Proportion) ///
		rcols(cases_tb population) /// 
		astext(80) /// 
		texts(1.5) smooth gof		
	restore
end

//2.2.6
program define metapreg_example_two_two_six
	preserve
	use "http://fmwww.bc.edu/repec/bocode/b/bcg.dta", clear
	
	di ". metapreg cases_tb population bcg lat,  ///" 
	di "	studyid(study) model(mixed, intmethod(mv)) ///"
	di "	sortby(lat) ///"
	di "	design(comparative, cov(commonslope))  ///"
	di "	outplot(rr) ///"
	di "	interaction ///"
	di "	xlab(0, 1, 2) /// "
	di "	xtick(0, 1, 2)  /// "
	di "	rcols(cases_tb population) /// "
	di "	astext(80) ///" 
	di "	texts(1.5) logscale smooth gof" 
	
	set more off
	
	metapreg cases_tb population bcg lat,  /// 
		/*inference(bayesian) bwd($wdir)*/ /// 
		studyid(study) model(mixed, intmethod(mv)) ///
		sortby(lat) ///
		design(comparative, cov(commonslope))  ///
		outplot(rr) ///
		interaction ///
		xlab(0, 1, 2) /// 
		xtick(0, 1, 2)  /// 
		rcols(cases_tb population) /// 
		astext(80)  /// 
		texts(1.5) logscale smooth gof
		
	restore
end

//2.2.7  ---Check the differences!!!
program define metapreg_example_two_two_seven
	preserve
	use "http://fmwww.bc.edu/repec/bocode/s/schizo.dta", clear
	di ". gsort firstauthor arm  "
	di ""
	di ". metapreg response total arm missingdata,  /// "
	di "	studyid(firstauthor) ///"
	di "	sortby(year)  ///"
	di "	sumtable(all) ///"
	di "	design(comparative, cov(commonslope))   ///"
	di "	outplot(rr) ///"
	di "	interaction ///"
	di "	xlab(0.5, 5, 20) /// "
	di "	xtick(0.5, 5, 20)  ///" 
	di "	sumstat(Rel Ratio) ///"
	di "	lcols(response total) /// "
	di "	astext(70) /// "
	di "	texts(1.5) logscale smooth ///"
	di "	xsize(12) ysize(6) gof"
			

	set more off

	gsort firstauthor -arm

	metapreg response total arm missingdata, /// 
		studyid(firstauthor) ///
		sortby(year)  ///
		sumtable(all) ///
		design(comparative, cov(commonslope))  ///
		/*inference(bayesian) bwd($wdir)*/  /// 
		outplot(rr) ///
		interaction ///
		xlab(0.5, 5, 20) /// 
		xtick(0.5, 5, 20)  /// 
		sumstat(Rel Ratio) ///
		lcols(response total) /// 
		astext(70) texts(1.5)  /// 
		logscale smooth xsize(12) ysize(6) gof
	restore
end

//2.3.1
program define metapreg_example_two_three_one
	preserve
	use "https://github.com/VNyaga/Metapreg/blob/master/Build/repro.dta?raw=1", clear
	
	di ". metapreg pp pn np nn,  ///"
	di "	design(mpair, cov(commonslope)) ///"
	di "	studyid(paper) ///"
	di "	stratify by(type) ///"
	di "	xlab(0.5, 1, 2) ///"
	di "	sumstat(Positivity Ratio) ///"
	di "	lcols(test)  ///"
	di "	boxopts(msize(0.1) mcolor(black)) pointopt(msymbol(none)) 	///"
	di "	astext(50)  logscale  xline(1) smooth" 
	
	
	set more off

	metapreg pp pn np nn,  ///
		design(mpair, cov(commonslope)) ///
		/*inference(bayesian) bwd($wdir)*/  /// 
		studyid(paper) sumtable(all) ///
		stratify by(type) ///
		xlab(0.5, 1, 2) ///
		sumstat(Positivity Ratio) ///
		lcols(test)  ///
		boxopts(msize(0.1) mcolor(black)) pointopt(msymbol(none)) 	///
		astext(50)  logscale  xline(1) smooth 
				
	restore
end

//2.3.2
program define metapreg_example_two_three_two
	preserve
	use "http://fmwww.bc.edu/repec/bocode/m/matched.dta", clear
	di ". metapreg a b c d index comparator,  /// "
	di "	studyid(study) ///"
	di "	model(fixed)  /// "
	di "	design(mcbnetwork)  ///"
	di "	by(comparator)  ///"
	di "	xlab(0.9, 1, 1.1) /// "
	di "	xtick(0.9, 1, 1.1)  ///" 
	di "	sumstat(Ratio) ///"
	di "	lcols(a b c d comparator index) /// "
	di "	astext(80) /// "
	di "	texts(1.5) logscale  "
	
	set more off
			
	metapreg a b c d index comparator,  /// 
		/*inference(bayesian) bwd($wdir)*/  /// 
		studyid(study)  ///
		model(fixed)  /// 
		design(mcbnetwork) ///
		by(comparator) ///
		xlab(0.9, 1, 1.1) /// 
		xtick(0.9, 1, 1.1)  /// 
		sumstat(Ratio) ///
		lcols(a b c d comparator index) /// 
		astext(80) /// 
		texts(1.5) logscale smooth gof
			
	restore
end