cap program drop metadta_examples
program metadta_examples
	version 14.0
	`1'
end

program define example_one
	preserve
	di " "
	use "http://fmwww.bc.edu/repec/bocode/t/telomerase.dta", clear
	di  " "
	di `". metadta tp fp fn tn,  	///"'  
	di `"{phang}studyid(study) model(random) dp(2) sumtable(none) 	///{p_end}"' 
	di `"{phang}soptions(xtitle("False positive rate") xlabel(0(0.2)1) xscale(range(0 1))	///{p_end}"'
	di `"{pmore}ytitle("Sensitivity") yscale(range(0 1)) ylabel(0(0.2)1, nogrid)	///{p_end}"' 
	di `"{pmore}graphregion(color(white)) plotregion(margin(medium)) xsize(15) ysize(15)) 	///{p_end}"'
	di `"{phang}foptions(graphregion(color(white)) texts(3) xlabel(0, 0.5, 1) 	///{p_end}"'
	di `"{pmore}diamopt(color(red)) pointopt(msymbol(s)msize(1)) olineopt(color(red) lpattern(dash))) {p_end}"' 
	
	set more off

	
	#delimit ;
	metadta tp fp fn tn, 
		studyid(study) model(random) dp(2) sumtable(none)  
		soptions(xtitle("False positive rate") xlabel(0(0.2)1) xscale(range(0 1))
			ytitle("Sensitivity") yscale(range(0 1)) ylabel(0(0.2)1, nogrid) 
			graphregion(color(white)) plotregion(margin(medium)) xsize(15) ysize(15)) 
		foptions(graphregion(color(white)) texts(3) xlabel(0, 0.5, 1) 
			diamopt(color(red)) pointopt(msymbol(s)msize(1)) olineopt(color(red) lpattern(dash))) 
	;
	#delimit cr
	restore
end


program define example_two_one
	preserve
	di _n
	use "http://fmwww.bc.edu/repec/bocode/a/ascus.dta", clear
	di _n
	
	di `". metadta tp fp fn tn test,  			///"'
	di `"{phang}studyid(studyid) model(random) comparative sumtable(none)  			///{p_end}"'
	di `"{phang}soptions(xtitle("False positive rate") xlabel(0(0.2)1) xscale(range(0 1)) 			///{p_end}"'
	di `"{pmore}ytitle("Sensitivity") yscale(range(0 1)) ylabel(0(0.2)1, nogrid)  			///{p_end}"'
	di `"{pmore}legend(order(1 "Repeat Cytology" 2 "HC2") ring(0) bplacement(6)) 			///{p_end}"'
	di `"{pmore}graphregion(color(white)) plotregion(margin(zero)) col(red blue))  			///{p_end}"'	
	di `"{phang}foptions(graphregion(color(white)) outplot(abs) texts(2) xlabel(0, 1, 1)  			///{p_end}"'
	di `"{pmore}diamopt(color(red)) pointopt(msymbol(s)msize(1)) olineopt(color(red) lpattern(dash))) {p_end}"'
	
	set more off
	
	#delimit ;
	metadta tp fp fn tn test, 
		studyid(studyid) model(random) comparative sumtable(none) 
		soptions(xtitle("False positive rate") xlabel(0(0.2)1) xscale(range(0 1))
			ytitle("Sensitivity") yscale(range(0 1)) ylabel(0(0.2)1, nogrid) 
			legend(order(1 "Repeat Cytology" 2 "HC2") ring(0) bplacement(6))
				graphregion(color(white)) plotregion(margin(zero)) col(red blue)) 	
		foptions(graphregion(color(white)) outplot(abs) texts(2) xlabel(0, 1, 1) 
			diamopt(color(red)) pointopt(msymbol(s)msize(1)) olineopt(color(red) lpattern(dash))) 
	;
	#delimit cr
	restore
end

program define example_two_two
	preserve
	di _n
	use "http://fmwww.bc.edu/repec/bocode/a/ascus.dta", clear
	di _n
	
	di `". metadta tp fp fn tn test,  			///"'
	di `"{phang}studyid(studyid) model(random) comparative sumtable(all)  			///{p_end}"'	
	di `"{pmore}foptions(logscale graphregion(color(white)) outplot(rr) texts(2) xlabel(0.5, 1, 1.5)   			///{p_end}"' 
	di `"{phang}diamopt(color(red)) pointopt(msymbol(s)msize(1)) olineopt(color(red) lpattern(dash)))   			{p_end}"'

	set more off
	
	#delimit ;
	metadta tp fp fn tn test, 
		studyid(studyid) model(random) comparative sumtable(all)	
		foptions(logscale graphregion(color(white)) outplot(rr) texts(2) xlabel(0.5, 1, 1.5) 
			diamopt(color(red)) pointopt(msymbol(s)msize(1)) olineopt(color(red) lpattern(dash))) 
	;
	#delimit cr
	restore
end

program define example_three
	preserve
	di _n
	use "http://fmwww.bc.edu/repec/bocode/c/clinself.dta", clear
	di _n

	di `". metadta tp fp fn tn sample Setting, 						///"' 
	di `"{phang}studyid(study) interaction(sesp) model(random)					///{p_end}"' 
	di `"{phang}summaryonly comparative sumtable(rr) noitable 					///{p_end}"'
	di `"{phang}soptions(xtitle("False positive rate") xlabel(0(0.2)1) xscale(range(0 1))					///{p_end}"'
	di `"{pmore}ytitle("Sensitivity") yscale(range(0 1)) ylabel(0(0.2)1, nogrid)					///{p_end}"' 
	di `"{pmore}graphregion(color(white)) plotregion(margin(zero)))					///{p_end}"' 
	di `"{phang}foptions(diamopt(color(red)) olineopt(color(red) lpattern(dash)) 					///{p_end}"'
	di `"{pmore}outplot(rr) graphregion(color(white)) texts(2) xlabel(0.7, 1, 1.2))					{p_end}"'

	set more off
		
	#delimit ;
	metadta tp fp fn tn sample Setting, 
		studyid(study) interaction(sesp) model(random) 
		summaryonly comparative sumtable(rr) noitable 
		soptions(xtitle("False positive rate") xlabel(0(0.2)1) xscale(range(0 1))
			ytitle("Sensitivity") yscale(range(0 1)) ylabel(0(0.2)1, nogrid) 
			graphregion(color(white)) plotregion(margin(zero))) 
		foptions(diamopt(color(red)) olineopt(color(red) lpattern(dash)) 
				outplot(rr) graphregion(color(white)) texts(2) xlabel(0.7, 1, 1.2)) 	
	;
	#delimit cr
	restore
end

program define example_four
	preserve
	di _n
	use "http://fmwww.bc.edu/repec/bocode/c/clinself.dta", clear
	di _n
	
	di `". metadta tp fp fn tn sample Setting TA,   			///"'
	di `"{phang}studyid(study) interaction(sesp)    			///{p_end}"' 
	di `"{phang}model(random) cov(unstructured) comparative noitable sumtable(rr)    			///{p_end}"'
	di `"{phang}soptions(xtitle("False positive rate") xlabel(0(0.2)1) xscale(range(0 1))    			///{p_end}"'
	di `"{pmore}ytitle("Sensitivity") yscale(range(0 1)) ylabel(0(0.2)1, nogrid)    			///{p_end}"'
	di `"{pmore}graphregion(color(white)) plotregion(margin(zero)))    			///{p_end}"'
	di `"{phang}foptions(outplot(rr) grid graphregion(color(white)) texts(1.5) xlabel(0.7, 1, 1.3)    			///{p_end}"'
	di `"{pmore}arrowopt(msize(1)) diamopt(color(red)) olineopt(color(red) lpattern(dash)))   			{p_end}"'
	
	set more off
	#delimit ;
	metadta tp fp fn tn sample Setting TA, 
	studyid(study) interaction(sesp) 
		model(random) cov(unstructured) comparative noitable sumtable(rr)
		soptions(xtitle("False positive rate") xlabel(0(0.2)1) xscale(range(0 1))
			ytitle("Sensitivity") yscale(range(0 1)) ylabel(0(0.2)1, nogrid) 
			graphregion(color(white)) plotregion(margin(zero))) 
		foptions(outplot(rr) grid graphregion(color(white)) texts(1.5) xlabel(0.7, 1, 1.3) 
			arrowopt(msize(1)) diamopt(color(red)) olineopt(color(red) lpattern(dash))) 
	;
	#delimit cr
	restore
end

program define example_five
	preserve
	di _n
	use "http://fmwww.bc.edu/repec/bocode/p/pairedta.dta", clear
	di _n
	
	di `". metadta tp1 fp1 fn1 tn1 tp2 fp2 fn2 tn2 hpv1 hpv2, ///"'
	di `"{phang}studyid(study) model(random) cov(, zero) ///{p_end}"'
	di `"{phang}cbnetwork sumtable(rr)  ///{p_end}"'
	di `"{phang}foptions(outplot(rr) grid graphregion(color(white)) texts(1.85) ///{p_end}"'
	di `"{pmore}xlabel(0.75, 0.90, 1, 1.11, 1.33) logscale lcols(hpv2 setting)  astext(70)    ///{p_end}"' 
	di `"{pmore}arrowopt(msize(1)) pointopt(msymbol(s)msize(1)) diamopt(color(red)) olineopt(color(red) lpattern(dash))){p_end}"'

 
	// metadta tp1---fn2 index comparator, cbnetwork
	set more off
	 metadta tp1 fp1 fn1 tn1 tp2 fp2 fn2 tn2 hpv1 hpv2, ///
		studyid(study) model(random) cov(, zero) ///
		cbnetwork sumtable(rr)  ///
		foptions(outplot(rr) grid graphregion(color(white)) texts(1.85) ///
			xlabel(0.75, 0.90, 1, 1.11, 1.33) logscale lcols(hpv2 setting)  astext(70)    /// 
			arrowopt(msize(1)) pointopt(msymbol(s)msize(1)) diamopt(color(red)) olineopt(color(red) lpattern(dash)))
	restore
end

program define example_six

	preserve
	di _n
	use "http://fmwww.bc.edu/repec/bocode/n/network.dta", clear
	di _n
	
	di `". metadta  tp fp fn tn test ,  ///"' 
	di `"{phang}studyid(study) model(random, laplace) ///{p_end}"'
	di `"{phang}abnetwork ref(HC2) sumtable(all) ///{p_end}"'
	di `"{phang}foptions(outplot(rr) graphregion(color(white)) texts(1.75) ///{p_end}"'
	di `"{pmore}xlabel(0.80, 0.90, 1, 1.11, 2) logscale astext(70) ///{p_end}"'
	di `"{pmore}arrowopt(msize(1)) pointopt(msymbol(s)msize(.5)) ///{p_end}"'
	di `"{pmore}diamopt(color(red)) olineopt(color(red) lpattern(dash))){p_end}"'


//ab network meta-analysis
	set more off
	metadta  tp fp fn tn test ,  /// 
		studyid(study) model(random, laplace) ///
		abnetwork ref(HC2) sumtable(all) ///
		foptions(outplot(rr) graphregion(color(white)) texts(1.75) ///
		xlabel(0.80, 0.90, 1, 1.11, 2) logscale astext(70) ///
	arrowopt(msize(1)) pointopt(msymbol(s)msize(.5)) ///
	diamopt(color(red)) olineopt(color(red) lpattern(dash)))
	restore
end

