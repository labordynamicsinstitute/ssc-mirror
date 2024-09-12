* exitma version 1.1 - 11 Sep 2024
* Authors: Luis Furuya-Kanamori (l.furuya@uq.edu.au), Suhail AR Doi, Jazeel AbdulMajeed

	*v1.1 revised reference (in help file) and fig y-label 

	
program define exitma, rclass
version 14

syntax varlist(min=2 max=4 numeric) [if] [in] ///
, SEQuence(varname) [, samplesize(varname)] ///
[, ivhet QE(varname numeric) noGraph]

tokenize `varlist'

preserve
marksample touse, novarlist 
quietly keep if `touse'


************************
*Check required packages
	foreach package in admetan {
	capture which `package'
	if _rc==111 ssc install `package'
	}


************************
*Data input for analysis

	*ES seES 
		if "`3'" == "" & "`4'" == "" {
		display ""
		display as text "Data input format ES seES assumed"
			quietly{
				gen __ES = `1'
				gen __seES = `2'
			}
			
			*check entry error (negative SE and all positive ES)
			sort `2'
				if `2'[1] <= 0 {
				di as error "{bf:`2'} cannot contain negative values"
				exit 198
				}
			sort `1'
				if `1'[1] > 0 {
				di in red "verify {bf:`1'} is log transformed"
				}
		}
		
	*ES lci uci 
		if "`3'" != "" & "`4'" == "" {
		display ""
		display as text "Data input format ES lci uci assumed"
			quietly{
				gen __ES = `1'
				gen __lci = `2'
				gen __uci = `3'
				gen __seES = (__ES - __lci)/(invnormal(0.975))
			}
			
			*check entry error (all positive ES)
			sort `1'
				if `1'[1] > 0 {
				di in red "verify {bf:`1'} is log transformed"
				}
		}		

	*event_treat noevent_treat event_ctrl noevent_ctrl
		if "`3'" != "" & "`4'" != ""{
		display ""
		display as text "Data input format t_cases t_non-cases c_cases c_non-cases assumed"
			quietly{ 
				gen __a = `1'
				gen __b = `2'
				gen __c = `3'
				gen __d = `4'
				
					*cont correction
						gen __continuity = 1 if __a==0 | __c==0 
							replace __a = __a+0.5 if __continuity ==1
							replace __b = __b+0.5 if __continuity ==1
							replace __c = __c+0.5 if __continuity ==1
							replace __d = __d+0.5 if __continuity ==1
				
				gen __ES = ln((__a*__d)/(__b*__c))
				gen __seES = sqrt((1/__a)+(1/__b)+(1/__c)+(1/__d))
			}
			
			*check entry error (negative and non-integers)
			sort `1'
				if `1' <0{
				di as error "{bf:`1'} cannot contain negative values"
				exit 198
				}
			sort `2'
				if `2'[1] <0{
				di as error "{bf:`2'} cannot contain negative values"
				exit 198
				}
			sort `3'
				if `3'[1] <0{
				di as error "{bf:`3'} cannot contain negative values"
				exit 198
				}
			sort `4'
				if `4'[1] <0{
				di as error "{bf:`4'} cannot contain negative values"
				exit 198
				}
			cap assert int(`1')==`1'
				if _rc!=0{
				di as error "{bf:`1'} contains non-integers" 
				exit _rc
				}
			cap assert int(`2')==`2'
				if _rc!=0{
				di as error "{bf:`2'} contains non-integers" 
				exit _rc
				}
			cap assert int(`3')==`3'
				if _rc!=0{
				di as error "{bf:`3'} contains non-integers" 
				exit _rc
				}
			cap assert int(`4')==`4'
				if _rc!=0{
				di as error "{bf:`4'} contains non-integers" 
				exit _rc
				}
		}

		
*************************
*Cumulative meta-analysis		
	
	gen __studyseq = `sequence'	
	sort __studyseq
		gen __k_studies= __studyseq[_N]
		local k_studies = __k_studies
	
	if "`qe'"!="" & "`ivhet'"!="" {
	display as error "specify only one model"
	exit 198
	}
	
	if "`qe'"=="" {
		quietly {
			admetan __ES __seES, or ivhet cumulative nograph nowarn notable
				qui gen __ma_es = _ES[_N] in 1
				gen __se_ma_es = _seES[_N] in 1
		}
	display as text "IVhet model selected"
	}
	
	if "`qe'"!="" {
		quietly {
			admetan __ES __seES, or qe(`qe') cumulative nograph nowarn notable
				qui gen __ma_es = _ES[_N] in 1
				gen __se_ma_es = _seES[_N] in 1
		}
	display as text "QE model selected"	
	}	
	
	
*****		
*DAts	
	
	quietly {
		gen __delta_c = _ES[_N]-_ES
		gen __se_delta_c = sqrt(_seES^2 + (_seES[_N])^2)
			gen __lower = 0 - 0.15
			gen __upper = 0 + 0.15

		gen __sample_size = .
			 if "`4'" != "" {
				replace __sample_size = __a + __b + __c + __d
			 }
			 
			 if "`4'" == "" {
				cap assert `samplesize'!=.
					if _rc {
					display as error "specify samplesize"
					exit 198
					}
				replace __sample_size = `samplesize'
			}

		gen __n = 0
			replace __n = __sample_size in 1
			replace __n = __sample_size[_n] + __n[_n-1] in 2/`k_studies'

		gen __total_n = __n[_N]
		gen __prop = __n/__total_n
				summ __delta_c if __prop>=0.5, det
					gen __dats = (r(Var)-0.002)*10 in 1
		
		gen __k_studies50 = 1 if __prop>=0.5
		egen __k_studies50max = count(__k_studies50)
		local k_studies50max = __k_studies50max
		
		*scalar
			return scalar nstudy50 = __k_studies50max[1]
			return scalar nstudy = __k_studies[1]
			return scalar dats = __dats[1]		
	}
		
		*display DAts
		qui tostring __dats, gen(__dats_str) force
			if __dats !=. {
				qui gen ___dats_str1 = substr(__dats_str,1, strpos(__dats_str,".")+4)
					local dats_str1 = ___dats_str1[1]
					display ""
					di as text "DAts index = " `dats_str1'	
			}
			
			if __dats ==. {
				di ""
				di as text "DAts index cannot be computed, single study with >= 50% of the total participants"
			}
			
		*display study number
			di as text "Total number of studies = " `k_studies'
			di as text "Number of steps at or beyond 50% of participants = " `k_studies50max'	

		
*****		
*Plot
	if "`graph'" != "nograph"{	
		twoway (rarea __lower __upper __prop, sort fcolor(gs10) fintensity(30) lcolor(white) cmissing(y)) ///
			(connected __delta_c __prop, sort mcolor(navy) msymbol(circle) msize(large) lcolor(navy) yline(-.165 .165, lwidth(medthick) lpattern(dash) extend) xline(.5, lwidth(medthick) lpattern(dash) extend)), ///
			ytitle(ΔCi) ytitle(, size(vlarge)) ylabel(, labsize(vlarge) angle(horizontal) labgap(small)) ///
			xtitle(Cumulative proportion of participants) xtitle(, margin(medium) size(vlarge)) xlabel(0(.25)1, labsize(vlarge) labgap(small)) ///
			legend(off) graphregion(fcolor(white))	///
			title(DAts = `dats_str1', size(medium) margin(medium)) 

	}	
	

restore
end
exit
			
			
		