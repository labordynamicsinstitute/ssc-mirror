program midas9_examples
	version 9.0
	`1'
end

program define midas9_example_results
	preserve
	di ""
	use http://repec.org/nasug2007/midas_example_data9.dta, clear
	di in wh ""
	di ". midas9 tp fp fn tn, es(g) res(all)"
	
	midas9 tp fp fn tn, es(g) res(all)
	restore
end

program define midas9_example_table
	preserve
	di ""
	 use http://repec.org/nasug2007/midas_example_data9.dta, clear
	di in wh ""
	di ". midas9 tp fp fn tn,"
	di " es(g) table(dlr)"
	
	midas9 tp fp fn tn, es(g) table(dlr)
	restore
end

program define midas9_example_srocellip
	preserve
	di ""
	 use http://repec.org/nasug2007/midas_example_data9.dta, clear
	di in whi ""
	di ". midas9 tp fp fn tn, es(g) plot sroc2"
	
	midas9 tp fp fn tn, es(g) plot sroc2	
     restore
end

program define midas9_example_pubbias
	preserve
	di ""
	 use http://repec.org/nasug2007/midas_example_data9.dta, clear
	di in whi ""
	di ". midas9 tp fp fn tn, pubbias"
     
     midas9 tp fp fn tn, pubbias
	restore
end

program define midas9_example_funnel
	preserve
	di ""
	 use http://repec.org/nasug2007/midas_example_data9.dta, clear
	di in whi ""
	di ". midas9 tp fp fn tn, fun" 
     
     midas9 tp fp fn tn, fun 
	restore
end

program define midas9_example_forest1
	preserve
	di ""
	 use http://repec.org/nasug2007/midas_example_data9.dta, clear
	di in whi ""
	di ". midas9 tp fp fn tn, "
	di "> id(author) year(year) ms(0.75)"
	di "> for(dss) es(g) texts(0.80)"
	
	midas9 tp fp fn tn, ///
	id(author) year(year) ms(0.75) for(dss) es(g) texts(0.80) 
	restore
end

program define midas9_example_forest2
	preserve
	di ""
	 use http://repec.org/nasug2007/midas_example_data9.dta, clear
	di in whi ""
	di ". midas9 tp fp fn tn, id(author) year(year)"
	di "> es(g) ms(0.75) ford for(dss) " 	

		
	midas9 tp fp fn tn, id(author) year(year) es(g) ms(0.75) ford for(dss)  	
     restore
end

program define midas9_example_forest3
	preserve
	di ""
	 use http://repec.org/nasug2007/midas_example_data9.dta, clear
	di in whi ""
	di ". midas9 tp fp fn tn, id(author) year(year) ms(0.75)" 
	di "> for(dss) ford es(g) test(Forest Plot for" 	
     di "> Axillary PET in Breast Cancer) vsize(15)"
 
		
	midas9 tp fp fn tn, id(author) year(year) ms(0.75) ///
     for(dss) ford es(g) test(Forest Plot for Axillary PET in Breast Cancer) vsize(15) 
     restore
end


program define midas9_example_fagan
	preserve
	di ""
	 use http://repec.org/nasug2007/midas_example_data9.dta, clear
	di in whi ""
	di ". midas9 tp fp fn tn, es(g) fagan prior(0.20)" 
		
	
	midas9 tp fp fn tn, es(g) fagan prior(0.20) 
     restore
end

program define midas9_example_lrmatrix
	preserve
	di ""
	 use http://repec.org/nasug2007/midas_example_data9.dta, clear
	di in whi ""
	di ". midas9 tp fp fn tn, es(g) lrmat"  

     
     midas9 tp fp fn tn, es(g) lrmat  
	restore
end

program define midas9_example_bivbox
	preserve
	di ""
	 use http://repec.org/nasug2007/midas_example_data9.dta, clear
	di in whi ""
	di ". midas9 tp fp fn tn, bivbox scheme(s2color)"  

     
     midas9 tp fp fn tn, bivbox scheme(s2color)  
	restore
end

program define midas9_example_chi
	preserve
	di ""
	 use http://repec.org/nasug2007/midas_example_data9.dta, clear
	di in whi ""
	di ". midas9 tp fp fn tn, chip scheme(s2color)"  

    
     midas9 tp fp fn tn, chip scheme(s2color)  
	restore
end

program define midas9_example_pddamp
	preserve
	di ""
	 use http://repec.org/nasug2007/midas_example_data9.dta, clear
	di in whi ""
	di ". midas9 tp fp fn tn, pddam(p) hsize(6) scheme(s2color)"  
     di "> test(Conditional Probability Plot for" 	
     di "> Axillary PET in Breast Cancer) vsize(15)"
    
     midas9 tp fp fn tn, es(g) pddam(p) hsize(6) scheme(s2color) ///
     test(Conditional Probability Plot for Axillary PET in Breast Cancer) vsize(15)" 
	restore
end

program define midas9_example_pddamr
	preserve
	di ""
	 use http://repec.org/nasug2007/midas_example_data9.dta, clear
	di in whi ""
	di ". midas9 tp fp fn tn, es(g) pddam(r)"
         
     midas9 midas9 tp fp fn tn, es(g) pddam(r)
	restore
end

program define midas9_example_quadas
	preserve
	di ""
	 use http://repec.org/nasug2007/midas_example_data9.dta, clear
	di in whi ""
	di ""
	di ". midas9 tp fp fn tn prodesign ssize30 fulverif testdescr"
	di "> refdescr subjdescr report brdspect blinded, qualib"

	midas9 tp fp fn tn prodesign ssize30 fulverif testdescr ///
     refdescr subjdescr report brdspect blinded, qualib 
	restore
end

program define midas9_example_midareg
	preserve
	di ""
	 use http://repec.org/nasug2007/midas_example_data9.dta, clear
	di in whi ""
	di ""
	di ". midas9 tp fp fn tn prodesign ssize30 fulverif testdescr"
	di "> refdescr subjdescr report brdspect blinded, es(g) covars"

	midas9 tp fp fn tn prodesign ssize30 fulverif testdescr ///
     refdescr subjdescr report brdspect blinded, es) covars 
	restore
end
