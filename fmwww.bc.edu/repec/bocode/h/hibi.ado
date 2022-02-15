***Version 1.0 - 20 Feb 2021
*Author: Chang Xu(xuchang2016@runbox.com), Luis Furuya-Kanamori


program define hibi, rclass
version 14

syntax varlist(min=4 max=4 numeric) [if] [in], [rr or onestage twostage ap noGraph] 

tokenize `varlist'
preserve

marksample touse, novarlist 
quietly keep if `touse'

*Check required packages
foreach package in admetan {
capture which `package'
if _rc==111 ssc install `package'
}

*Data entry (error/warning messages)
if "`3'" == "" | "`4'" == "" {
	display as error "Must specify variables as binary data (t_cases t_non-cases c_cases c_non-cases) 
	exit 198
}
*


if "`rr'" != "" & "`or'" != "" {
	display as error "Options or and rr cannot both be specified"
	exit 198
}
*


if "`1'" != "" | "`2'" != "" | "`3'" != "" | "`4'" != ""{
	sort `1'
		if `1'[1] < 0 {
			display as error "Variable {bf:`1'} cannot contain negative values"
			exit 198
		}
	sort `2'
		if `2'[1] < 0 {
			display as error "Variable {bf:`2'} cannot contain negative values"
			exit 198
		}
	sort `3'
		if `3'[1] < 0 {
			display as error "Variable {bf:`3'} cannot contain negative values"
			exit 198
		}
	sort `4'
		if `4'[1] < 0 {
			display as error "Variable {bf:`4'} cannot contain negative values"
			exit 198
		}
}
*

if "`1'" != "" | "`2'" != "" | "`3'" != "" | "`4'" != ""{
	sort `1'
		if `1'[_N] ==.  {
			display as error "There is missing data in Variable {bf:`1'}"
			exit 198
		}
	sort `2'
		if `2'[_N] ==.  {
			display as error "There is missing data in Variable {bf:`2'}"
			exit 198
		}
	sort `3'
		if `3'[_N] ==.  {
			display as error "There is missing data in Variable {bf:`3'}"
			exit 198
		}
	sort `4'
		if `4'[_N] ==.  {
			display as error "There is missing data in Variable {bf:`4'}"
			exit 198
		}
}
*



*Binary data input (default)
if  "`1'" != "" & "`2'" != "" & "`3'" != "" & "`4'" != "" & "`or'" == "" & "`rr'" == "" & "`onestage'" == "" & "`twostage'" == "" & "`ap'" == ""{
	
	display ""
	display as text "Note: two-stage peto's OR, Effect size =OR"

		quietly{ 
			gen __a = `1'
			gen __b = `2'
			gen __c = `3'
			gen __d = `4'
			
			gen ___a = __a
			gen ___c = __c
			    
				gen study_id = _n
				gen _id = _n
				gen __zero = 1 if __a==0 | __c==0
				
				egen sumzero=sum(__zero)
				
				if sumzero == 0 {
				          display as error "No zero-events studies"
	                      exit 198
				}
				else {
				
				gen __zero_single = 1 if (__a==0 & __c !=0) | (__a !=0 & __c ==0)
				gen  __zero_double = 1 if __a==0 & __c ==0 
				sort __zero
				gen  __zero_num = _n if __zero == 1
				sort __zero_single
				gen  __zero_single_num = _n if __zero_single==1
				sort __zero_double	
				gen __zero_double_t_sample = __b  if __zero_double !=.
				gen __zero_double_c_sample = __d  if __zero_double !=.			
				gsort __zero_double_t_sample
				gen __zero_double_num = _n if __zero_double==1
				gsort -__zero_double_num
					if __zero_double_num[1]!=.{
								noisily display as text "Note: Number of double-arm-zero-events studies = " as result __zero_double_num[1]
					}	
					}
				
			       egen max_zero_double = max(__zero_double_num)
				   local i  = max_zero_double
		 
				   *gen zerostudy=.
				   *gen iter =.
				   *gen events=.
				   *gen loop =.
				   
				   gen events_total = __a + __c
				   replace events_total = 1 if events_total !=0
				   egen study_num = max(_id)
			
			replace study_id = _n
			keep _id study_num __a __c __b __d ___a  ___c  events_total study_id sumzero max_zero_double
		    reshape wide __a __c __b __d ___a   ___c, i(_id) j(study_id)
            collapse __a* __b* __c* __d* ___a*   ___c*  study_num max_zero_double, by(sumzero)
	   
			gen combinations= 4^sumzero
			*sort _id
			*expand combinations
			*bysort _id: gen exp=_n
		    *sort exp _id
            *sort exp study_id
          

	       ***Combinations
	       local K `i'
           local N 3 
		   local N1 = 4
           local No = `N1'^`K'
           assert `No'<=2147483620
           
		   set obs `No'
           generate long count = _n-1
           forvalues k = `K'(-1)1 {
           generate byte _study`k' = mod(count,`N1'), after(count)
           quietly replace count = floor(count/`N1')
           }

           *consistency checking and cleanup
           drop count
		   gen count = _n
		   
		   replace sumzero = sumzero[_n - 1] if missing(sumzero)
		   replace max_zero_double = max_zero_double[_n - 1] if missing(max_zero_double)
		   replace study_num = study_num[_n - 1] if missing(study_num)
		   
		   
		   local K = study_num
		   forvalues k = 1(1)`K' {
		   replace __a`k' = __a`k'[_n-1] if missing(__a`k')
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   replace ___c`k' = ___c`k'[_n-1] if missing(___c`k')
		   }
		   *
		   
			
			local K = max_zero_double
			forvalues k = 1(1) `K' {
			    replace __a`k' = _study`k'
				replace ___c`k' = _study`k'
				}
				
			reshape long __a __b __c __d  ___a  ___c , i(count) j(study_id)
			drop combinations
			rename count comb
			
			gen __ma_ln_or_h =. 
			gen __ma_se_lnor_h =.
			gen __ma_or_h =.
	        gen __ma_lci_or_h =.
	        gen __ma_uci_or_h =.
			gen __p_h =.
			gen __ps_h=.
			
			
			*Meta-analysis for all combinations for harms
			egen max_comb = max(comb)
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan __a __b __c __d if comb == `meta', peto or nograph
			    replace __ma_ln_or_h = r(eff) if comb == `meta'
			    replace __ma_se_lnor_h = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_or_h = exp(__ma_ln_or_h) 
				replace __ma_lci_or_h=exp(__ma_ln_or_h-(invnormal(0.975)*__ma_se_lnor_h)) 
				replace __ma_uci_or_h=exp(__ma_ln_or_h+(invnormal(0.975)*__ma_se_lnor_h)) 
			    replace __p_h=2*(1-normal(abs(__ma_ln_or_h/__ma_se_lnor_h))) 
				replace __ps_h = 1 if __p_h < 0.05 
			    replace __ps_h = -1 if __p_h > 0.05 
				gen events = __a + __c
			    
				local t = max_zero_double
				   forvalues t = 1(1)`t' {
				      gen treat_arm`t' = __b[`t'] if events[`t'] ==0 
					  }
	            egen max_arm = rowmax(treat_arm*)
					
		    
			*Meta-analysis for all combinations for benifits
			
			
			gen __ma_ln_or_b =. 
			gen __ma_se_lnor_b =.
			gen __ma_or_b =.
	        gen __ma_lci_or_b =.
	        gen __ma_uci_or_b =.
			gen __p_b =.
			gen __ps_b=.
			
			
			*Meta-analysis
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan ___a __b ___c __d if comb == `meta', peto or nograph
			    replace __ma_ln_or_b = r(eff) if comb == `meta'
			    replace __ma_se_lnor_b = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_or_b = exp(__ma_ln_or_b)
				replace __ma_lci_or_b=exp(__ma_ln_or_b-(invnormal(0.975)*__ma_se_lnor_b)) 
				replace __ma_uci_or_b=exp(__ma_ln_or_b+(invnormal(0.975)*__ma_se_lnor_b)) 
			    replace __p_b=2*(1-normal(abs(__ma_ln_or_b/__ma_se_lnor_b))) 
				replace __ps_b = 1 if __p_b < 0.05 
			    replace __ps_b = -1 if __p_b > 0.05 
			   
				local t = max_zero_double
				   forvalues t = 1(1)`t' {
				      gen control_arm`t' = __d[`t'] if events[`t'] ==0 
					  }
	            egen max_arm_c = rowmax(control_arm*)
		
			    drop  _ES _seES _LCI _UCI _WT _rsample max_zero_double 
			    keep if study_id == 1
				drop study_id
			    drop study_num
				

				gen ratio_dir_h = __ma_ln_or_h/__ma_ln_or_h[1]
				gen ratio_sig_h = __ps_h/__ps_h[1]
				
				gen d_dir_h = 0 if ratio_dir_h > 0
				replace d_dir_h = 1 if ratio_dir_h < 0
				gen d_sig_h = 0 if ratio_sig_h > 0
				replace d_sig_h = 1 if ratio_sig_h < 0
				gen direction_h = d_sig_h + d_dir_h	
				
				
				gen ratio_dir_b = __ma_ln_or_b/__ma_ln_or_b[1]
				gen ratio_sig_b = __ps_b/__ps_b[1]
				
				gen d_dir_b = 0 if ratio_dir_b > 0
				replace d_dir_b = 1 if ratio_dir_b < 0
				gen d_sig_b = 0 if ratio_sig_b > 0
				replace d_sig_b = 1 if ratio_sig_b < 0
				gen direction_b = d_sig_b + d_dir_b	
				
				
				
				***max and min effects (for graph)
				egen min_lci_h = min(__ma_lci_or_h)
                egen min_uci_h = max(__ma_uci_or_h)
                egen min_lci_b = min(__ma_lci_or_b)
                egen min_uci_b = max(__ma_uci_or_b)
				
				***HI index
		        egen Hi = rowtotal(_study*)
				sort Hi
				gen direction_h_r = _n if direction_h ==1
				egen Meta_Hi = min(cond(direction_h_r,Hi,.))  if direction_h_r !=.
				replace Meta_Hi = 0 if Meta_Hi ==.
				
				
				
				***BI index
		        egen Bi = rowtotal(_study*)
				sort Bi
				gen direction_b_r = _n if direction_b ==1
				egen Meta_Bi = min(cond(direction_b_r,Bi,.)) if direction_b_r !=.
				replace Meta_Bi = 0 if Meta_Bi ==.
				
			
				***Rename
				egen max_MHi =max(Meta_Hi)
				drop Meta_Hi
				rename max_MHi Meta_Hi
				
				
				egen max_MBi =max(Meta_Bi)
				drop Meta_Bi
				rename max_MBi Meta_Bi
				
				scalar define _Meta_Hi = Meta_Hi[1]
				scalar define _Meta_Bi = Meta_Bi[1]
				
				if Meta_Hi == 0 & Meta_Bi == 0{
				      noisily display as text "Doubld-zero-events studies totally do not impact the results:"
					}	
				if (Meta_Hi > 0 & Meta_Hi < 3) | (Meta_Bi > 0 & Meta_Bi < 3){
				      noisily display as text "Doubld-zero-events studies may have some impact on the results:" 
					}
				if (Meta_Hi >= 3) | (Meta_Bi >= 3){
				      noisily display as text "Doubld-zero-events studies may have little impact on the results:"
					}			
						

		}
}		
*


					

*Binary data input + OR selected
if  "`1'" != "" & "`2'" != "" & "`3'" != "" & "`4'" != "" & "`or'" != "" & "`rr'" == "" & "`onestage'" == "" & "`twostage'" == "" & "`ap'" == ""{
	
		
    display ""
	display as text "Note: two-stage peto's OR, Effect size =OR"

		quietly{ 
			gen __a = `1'
			gen __b = `2'
			gen __c = `3'
			gen __d = `4'
			    
			gen ___a = __a
			gen ___c = __c
			    
				gen study_id = _n
				gen _id = _n
				gen __zero = 1 if __a==0 | __c==0
				
				egen sumzero=sum(__zero)
				
				if sumzero == 0 {
				          display as error "No zero-events studies"
	                      exit 198
				}
				else {
				
				gen __zero_single = 1 if (__a==0 & __c !=0) | (__a !=0 & __c ==0)
				gen  __zero_double = 1 if __a==0 & __c ==0 
				sort __zero
				gen  __zero_num = _n if __zero == 1
				sort __zero_single
				gen  __zero_single_num = _n if __zero_single==1
				sort __zero_double	
				gen __zero_double_t_sample = __b  if __zero_double !=.
				gen __zero_double_c_sample = __d  if __zero_double !=.			
				gsort __zero_double_t_sample
				gen __zero_double_num = _n if __zero_double==1
				gsort -__zero_double_num
					if __zero_double_num[1]!=.{
								noisily display as text "Note: Number of double-arm-zero-events studies = " as result __zero_double_num[1]
					}	
					}
				
			       egen max_zero_double = max(__zero_double_num)
				   local i  = max_zero_double
		 
				   *gen zerostudy=.
				   *gen iter =.
				   *gen events=.
				   *gen loop =.
				   
				   gen events_total = __a + __c
				   replace events_total = 1 if events_total !=0
				   egen study_num = max(_id)
			
			replace study_id = _n
			keep _id study_num __a __c __b __d ___a  ___c  events_total study_id sumzero max_zero_double
		    reshape wide __a __c __b __d ___a   ___c, i(_id) j(study_id)
            collapse __a* __b* __c* __d* ___a*   ___c*  study_num max_zero_double, by(sumzero)
	   
			gen combinations= 4^max_zero_double
			*sort _id
			*expand combinations
			*bysort _id: gen exp=_n
		    *sort exp _id
            *sort exp study_id
          

	       ***Combinations
	       local K `i'
           local N 3 
		   local N1 = 4
           local No = `N1'^`K'
           assert `No'<=2147483620
           
		   set obs `No'
           generate long count = _n-1
           forvalues k = `K'(-1)1 {
           generate byte _study`k' = mod(count,`N1'), after(count)
           quietly replace count = floor(count/`N1')
           }

           *consistency checking and cleanup
           drop count
		   gen count = _n
		   
		   replace sumzero = sumzero[_n - 1] if missing(sumzero)
		   replace max_zero_double = max_zero_double[_n - 1] if missing(max_zero_double)
		   replace study_num = study_num[_n - 1] if missing(study_num)
		   
		   
		   local K = study_num
		   forvalues k = 1(1)`K' {
		   replace __a`k' = __a`k'[_n-1] if missing(__a`k')
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   replace ___c`k' = ___c`k'[_n-1] if missing(___c`k')
		   }
		   *
		   
			
			local K = max_zero_double
			forvalues k = 1(1) `K' {
			    replace __a`k' = _study`k'
				replace ___c`k' = _study`k'
				}
				
			reshape long __a __b __c __d  ___a  ___c , i(count) j(study_id)
			drop combinations
			rename count comb
			
			gen __ma_ln_or_h =. 
			gen __ma_se_lnor_h =.
			gen __ma_or_h =.
	        gen __ma_lci_or_h =.
	        gen __ma_uci_or_h =.
			gen __p_h =.
			gen __ps_h=.
			
			
			*Meta-analysis for all combinations for harms
			egen max_comb = max(comb)
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan __a __b __c __d if comb == `meta', peto or nograph
			    replace __ma_ln_or_h = r(eff) if comb == `meta'
			    replace __ma_se_lnor_h = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_or_h = exp(__ma_ln_or_h) 
				replace __ma_lci_or_h=exp(__ma_ln_or_h-(invnormal(0.975)*__ma_se_lnor_h)) 
				replace __ma_uci_or_h=exp(__ma_ln_or_h+(invnormal(0.975)*__ma_se_lnor_h)) 
			    replace __p_h=2*(1-normal(abs(__ma_ln_or_h/__ma_se_lnor_h))) 
				replace __ps_h = 1 if __p_h < 0.05 
			    replace __ps_h = -1 if __p_h > 0.05 
				gen events = __a + __c
			    
				local t = max_zero_double
				   forvalues t = 1(1)`t' {
				      gen treat_arm`t' = __b[`t'] if events[`t'] ==0 
					  }
	            egen max_arm = rowmax(treat_arm*)
					
		    
			*Meta-analysis for all combinations for benifits
			
			
			gen __ma_ln_or_b =. 
			gen __ma_se_lnor_b =.
			gen __ma_or_b =.
	        gen __ma_lci_or_b =.
	        gen __ma_uci_or_b =.
			gen __p_b =.
			gen __ps_b=.
			
			
			*Meta-analysis
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan ___a __b ___c __d if comb == `meta', peto or nograph
			    replace __ma_ln_or_b = r(eff) if comb == `meta'
			    replace __ma_se_lnor_b = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_or_b = exp(__ma_ln_or_b)
				replace __ma_lci_or_b=exp(__ma_ln_or_b-(invnormal(0.975)*__ma_se_lnor_b)) 
				replace __ma_uci_or_b=exp(__ma_ln_or_b+(invnormal(0.975)*__ma_se_lnor_b)) 
			    replace __p_b=2*(1-normal(abs(__ma_ln_or_b/__ma_se_lnor_b))) 
				replace __ps_b = 1 if __p_b < 0.05 
			    replace __ps_b = -1 if __p_b > 0.05 
			   
				local t = max_zero_double
				   forvalues t = 1(1)`t' {
				      gen control_arm`t' = __d[`t'] if events[`t'] ==0 
					  }
	            egen max_arm_c = rowmax(control_arm*)
		
			    drop  _ES _seES _LCI _UCI _WT _rsample max_zero_double 
			    keep if study_id == 1
				drop study_id
			    drop study_num
				

				gen ratio_dir_h = __ma_ln_or_h/__ma_ln_or_h[1]
				gen ratio_sig_h = __ps_h/__ps_h[1]
				
				gen d_dir_h = 0 if ratio_dir_h > 0
				replace d_dir_h = 1 if ratio_dir_h < 0
				gen d_sig_h = 0 if ratio_sig_h > 0
				replace d_sig_h = 1 if ratio_sig_h < 0
				gen direction_h = d_sig_h + d_dir_h	
				
				
				gen ratio_dir_b = __ma_ln_or_b/__ma_ln_or_b[1]
				gen ratio_sig_b = __ps_b/__ps_b[1]
				
				gen d_dir_b = 0 if ratio_dir_b > 0
				replace d_dir_b = 1 if ratio_dir_b < 0
				gen d_sig_b = 0 if ratio_sig_b > 0
				replace d_sig_b = 1 if ratio_sig_b < 0
				gen direction_b = d_sig_b + d_dir_b	
				
				***max and min effects (for graph)
				egen min_lci_h = min(__ma_lci_or_h)
                egen min_uci_h = max(__ma_uci_or_h)
                egen min_lci_b = min(__ma_lci_or_b)
                egen min_uci_b = max(__ma_uci_or_b)
				
				
				***HI index
		        egen Hi = rowtotal(_study*)
				sort Hi
				gen direction_h_r = _n if direction_h ==1
				egen Meta_Hi = min(cond(direction_h_r,Hi,.))  if direction_h_r !=.
				replace Meta_Hi = 0 if Meta_Hi ==.
				
				
				
				***BI index
		        egen Bi = rowtotal(_study*)
				sort Bi
				gen direction_b_r = _n if direction_b ==1
				egen Meta_Bi = min(cond(direction_b_r,Bi,.)) if direction_b_r !=.
				replace Meta_Bi = 0 if Meta_Bi ==.
				
			
				***Rename
				egen max_MHi =max(Meta_Hi)
				drop Meta_Hi
				rename max_MHi Meta_Hi
				
				
				egen max_MBi =max(Meta_Bi)
				drop Meta_Bi
				rename max_MBi Meta_Bi
				
				scalar define _Meta_Hi = Meta_Hi[1]
				scalar define _Meta_Bi = Meta_Bi[1]
				
				if Meta_Hi == 0 & Meta_Bi == 0{
				      noisily display as text "Doubld-zero-events studies totally do not impact the results:"
					}	
				if (Meta_Hi > 0 & Meta_Hi < 3) | (Meta_Bi > 0 & Meta_Bi < 3){
				      noisily display as text "Doubld-zero-events studies may have some impact on the results:" 
					}
				if (Meta_Hi >= 3) | (Meta_Bi >= 3){
				      noisily display as text "Doubld-zero-events studies may have little impact on the results:"
					}			
						
		}
}			
*


*Binary data input + OR selected + twostage
if  "`1'" != "" & "`2'" != "" & "`3'" != "" & "`4'" != "" & "`or'" != "" & "`rr'" == "" & "`onestage'" == "" & "`twostage'" != "" & "`ap'" == ""{
	
    display ""
	display as text "Note: two-stage peto's OR, Effect size =OR"
	
	quietly{ 
			gen __a = `1'
			gen __b = `2'
			gen __c = `3'
			gen __d = `4'
			gen ___a = __a
			gen ___c = __c
			    
				gen study_id = _n
				gen _id = _n
				gen __zero = 1 if __a==0 | __c==0
				
				egen sumzero=sum(__zero)
				
				if sumzero == 0 {
				          display as error "No zero-events studies"
	                      exit 198
				}
				else {
				
				gen __zero_single = 1 if (__a==0 & __c !=0) | (__a !=0 & __c ==0)
				gen  __zero_double = 1 if __a==0 & __c ==0 
				sort __zero
				gen  __zero_num = _n if __zero == 1
				sort __zero_single
				gen  __zero_single_num = _n if __zero_single==1
				sort __zero_double	
				gen __zero_double_t_sample = __b  if __zero_double !=.
				gen __zero_double_c_sample = __d  if __zero_double !=.			
				gsort __zero_double_t_sample
				gen __zero_double_num = _n if __zero_double==1
				gsort -__zero_double_num
					if __zero_double_num[1]!=.{
								noisily display as text "Note: Number of double-arm-zero-events studies = " as result __zero_double_num[1]
					}	
					}
				
			       egen max_zero_double = max(__zero_double_num)
				   local i  = max_zero_double
		 
				   *gen zerostudy=.
				   *gen iter =.
				   *gen events=.
				   *gen loop =.
				   
				   gen events_total = __a + __c
				   replace events_total = 1 if events_total !=0
				   egen study_num = max(_id)
			
			replace study_id = _n
			keep _id study_num __a __c __b __d ___a  ___c  events_total study_id sumzero max_zero_double
		    reshape wide __a __c __b __d ___a   ___c, i(_id) j(study_id)
            collapse __a* __b* __c* __d* ___a*   ___c*  study_num max_zero_double, by(sumzero)
	   
			gen combinations= 4^max_zero_double
			*sort _id
			*expand combinations
			*bysort _id: gen exp=_n
		    *sort exp _id
            *sort exp study_id
          

	       ***Combinations
	       local K `i'
           local N 3 
		   local N1 = 4
           local No = `N1'^`K'
           assert `No'<=2147483620
           
		   set obs `No'
           generate long count = _n-1
           forvalues k = `K'(-1)1 {
           generate byte _study`k' = mod(count,`N1'), after(count)
           quietly replace count = floor(count/`N1')
           }

           *consistency checking and cleanup
           drop count
		   gen count = _n
		   
		   replace sumzero = sumzero[_n - 1] if missing(sumzero)
		   replace max_zero_double = max_zero_double[_n - 1] if missing(max_zero_double)
		   replace study_num = study_num[_n - 1] if missing(study_num)
		   
		   
		   local K = study_num
		   forvalues k = 1(1)`K' {
		   replace __a`k' = __a`k'[_n-1] if missing(__a`k')
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   replace ___c`k' = ___c`k'[_n-1] if missing(___c`k')
		   }
		   *
		   
			
			local K = max_zero_double
			forvalues k = 1(1) `K' {
			    replace __a`k' = _study`k'
				replace ___c`k' = _study`k'
				}
				
			reshape long __a __b __c __d  ___a  ___c , i(count) j(study_id)
			drop combinations
			rename count comb
			
			gen __ma_ln_or_h =. 
			gen __ma_se_lnor_h =.
			gen __ma_or_h =.
	        gen __ma_lci_or_h =.
	        gen __ma_uci_or_h =.
			gen __p_h =.
			gen __ps_h=.
			
			
			*Meta-analysis for all combinations for harms
			egen max_comb = max(comb)
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan __a __b __c __d if comb == `meta', peto or nograph
			    replace __ma_ln_or_h = r(eff) if comb == `meta'
			    replace __ma_se_lnor_h = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_or_h = exp(__ma_ln_or_h) 
				replace __ma_lci_or_h=exp(__ma_ln_or_h-(invnormal(0.975)*__ma_se_lnor_h)) 
				replace __ma_uci_or_h=exp(__ma_ln_or_h+(invnormal(0.975)*__ma_se_lnor_h)) 
			    replace __p_h=2*(1-normal(abs(__ma_ln_or_h/__ma_se_lnor_h))) 
				replace __ps_h = 1 if __p_h < 0.05 
			    replace __ps_h = -1 if __p_h > 0.05 
				gen events = __a + __c
			    
				local t = max_zero_double
				   forvalues t = 1(1)`t' {
				      gen treat_arm`t' = __b[`t'] if events[`t'] ==0 
					  }
	            egen max_arm = rowmax(treat_arm*)
					
		    
			*Meta-analysis for all combinations for benifits
			
			
			gen __ma_ln_or_b =. 
			gen __ma_se_lnor_b =.
			gen __ma_or_b =.
	        gen __ma_lci_or_b =.
	        gen __ma_uci_or_b =.
			gen __p_b =.
			gen __ps_b=.
			
			
			*Meta-analysis
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan ___a __b ___c __d if comb == `meta', peto or nograph
			    replace __ma_ln_or_b = r(eff) if comb == `meta'
			    replace __ma_se_lnor_b = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_or_b = exp(__ma_ln_or_b)
				replace __ma_lci_or_b=exp(__ma_ln_or_b-(invnormal(0.975)*__ma_se_lnor_b)) 
				replace __ma_uci_or_b=exp(__ma_ln_or_b+(invnormal(0.975)*__ma_se_lnor_b)) 
			    replace __p_b=2*(1-normal(abs(__ma_ln_or_b/__ma_se_lnor_b))) 
				replace __ps_b = 1 if __p_b < 0.05 
			    replace __ps_b = -1 if __p_b > 0.05 
			   
				local t = max_zero_double
				   forvalues t = 1(1)`t' {
				      gen control_arm`t' = __d[`t'] if events[`t'] ==0 
					  }
	            egen max_arm_c = rowmax(control_arm*)
		
			    drop  _ES _seES _LCI _UCI _WT _rsample max_zero_double 
			    keep if study_id == 1
				drop study_id
			    drop study_num
				

				gen ratio_dir_h = __ma_ln_or_h/__ma_ln_or_h[1]
				gen ratio_sig_h = __ps_h/__ps_h[1]
				
				gen d_dir_h = 0 if ratio_dir_h > 0
				replace d_dir_h = 1 if ratio_dir_h < 0
				gen d_sig_h = 0 if ratio_sig_h > 0
				replace d_sig_h = 1 if ratio_sig_h < 0
				gen direction_h = d_sig_h + d_dir_h	
				
				
				gen ratio_dir_b = __ma_ln_or_b/__ma_ln_or_b[1]
				gen ratio_sig_b = __ps_b/__ps_b[1]
				
				gen d_dir_b = 0 if ratio_dir_b > 0
				replace d_dir_b = 1 if ratio_dir_b < 0
				gen d_sig_b = 0 if ratio_sig_b > 0
				replace d_sig_b = 1 if ratio_sig_b < 0
				gen direction_b = d_sig_b + d_dir_b	
				
				
				***max and min effects (for graph)
				egen min_lci_h = min(__ma_lci_or_h)
                egen min_uci_h = max(__ma_uci_or_h)
                egen min_lci_b = min(__ma_lci_or_b)
                egen min_uci_b = max(__ma_uci_or_b)
				
				
				***HI index
		        egen Hi = rowtotal(_study*)
				sort Hi
				gen direction_h_r = _n if direction_h ==1
				egen Meta_Hi = min(cond(direction_h_r,Hi,.))  if direction_h_r !=.
				replace Meta_Hi = 0 if Meta_Hi ==.
				
				
				
				***BI index
		        egen Bi = rowtotal(_study*)
				sort Bi
				gen direction_b_r = _n if direction_b ==1
				egen Meta_Bi = min(cond(direction_b_r,Bi,.)) if direction_b_r !=.
				replace Meta_Bi = 0 if Meta_Bi ==.
				
			
				***Rename
				egen max_MHi =max(Meta_Hi)
				drop Meta_Hi
				rename max_MHi Meta_Hi
				
				
				egen max_MBi =max(Meta_Bi)
				drop Meta_Bi
				rename max_MBi Meta_Bi
				
				scalar define _Meta_Hi = Meta_Hi[1]
				scalar define _Meta_Bi = Meta_Bi[1]
				
				if Meta_Hi == 0 & Meta_Bi == 0{
				      noisily display as text "Doubld-zero-events studies totally do not impact the results:"
					}	
				if (Meta_Hi > 0 & Meta_Hi < 3) | (Meta_Bi > 0 & Meta_Bi < 3){
				      noisily display as text "Doubld-zero-events studies may have some impact on the results:" 
					}
				if (Meta_Hi >= 3) | (Meta_Bi >= 3){
				      noisily display as text "Doubld-zero-events studies may have little impact on the results:"
					}			
						
						

		}
	
		
}			
*


*Binary data input + OR selected + onestage
if  "`1'" != "" & "`2'" != "" & "`3'" != "" & "`4'" != "" & "`or'" != "" & "`rr'" == "" & "`onestage'" != "" & "`twostage'" == "" & "`ap'" == ""{
	
	display ""
	display as text "Note: One-stage method will take more time..."
	display as text "Note: Beta-binomial model, Effect size = OR"
 
	
	quietly{ 
			gen __a = `1'
			gen __b = `2'
			gen __c = `3'
			gen __d = `4'
			    
			gen ___a = __a
			gen ___c = __c
			    
				gen study_id = _n
				gen _id = _n
				gen __zero = 1 if __a==0 | __c==0
				
				egen sumzero=sum(__zero)
				
				if sumzero == 0 {
				          display as error "No zero-events studies"
	                      exit 198
				}
				else {
				
				gen __zero_single = 1 if (__a==0 & __c !=0) | (__a !=0 & __c ==0)
				gen  __zero_double = 1 if __a==0 & __c ==0 
				sort __zero
				gen  __zero_num = _n if __zero == 1
				sort __zero_single
				gen  __zero_single_num = _n if __zero_single==1
				sort __zero_double	
				gen __zero_double_t_sample = __b  if __zero_double !=.
				gen __zero_double_c_sample = __d  if __zero_double !=.			
				gsort __zero_double_t_sample
				gen __zero_double_num = _n if __zero_double==1
				gsort -__zero_double_num
					if __zero_double_num[1]!=.{
								noisily display as text "Note: Number of double-arm-zero-events studies = " as result __zero_double_num[1]
					}	
					}
				
			       egen max_zero_double = max(__zero_double_num)
				   local i  = max_zero_double
		 
				   *gen zerostudy=.
				   *gen iter =.
				   *gen events=.
				   *gen loop =.
				   
				   gen events_total = __a + __c
				   replace events_total = 1 if events_total !=0
				   egen study_num = max(_id)
			
			replace study_id = _n
			keep _id study_num __a __c __b __d ___a  ___c  events_total study_id sumzero max_zero_double
		    reshape wide __a __c __b __d ___a   ___c, i(_id) j(study_id)
            collapse __a* __b* __c* __d* ___a*   ___c*  study_num max_zero_double, by(sumzero)
	   
			gen combinations= 4^max_zero_double
			*sort _id
			*expand combinations
			*bysort _id: gen exp=_n
		    *sort exp _id
            *sort exp study_id
          

	       ***Combinations
	       local K `i'
           local N 3 
		   local N1 = 4
           local No = `N1'^`K'
           assert `No'<=2147483620
           
		   set obs `No'
           generate long count = _n-1
           forvalues k = `K'(-1)1 {
           generate byte _study`k' = mod(count,`N1'), after(count)
           quietly replace count = floor(count/`N1')
           }

           *consistency checking and cleanup
           drop count
		   gen count = _n
		   
		   replace sumzero = sumzero[_n - 1] if missing(sumzero)
		   replace max_zero_double = max_zero_double[_n - 1] if missing(max_zero_double)
		   replace study_num = study_num[_n - 1] if missing(study_num)
		   
		   
		   local K = study_num
		   forvalues k = 1(1)`K' {
		   replace __a`k' = __a`k'[_n-1] if missing(__a`k')
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   replace ___c`k' = ___c`k'[_n-1] if missing(___c`k')
		   }
		   *
		   
			
			local K = max_zero_double
			forvalues k = 1(1) `K' {
			    replace __a`k' = _study`k'
				replace ___c`k' = _study`k'
				}
				
			reshape long __a __b __c __d  ___a  ___c , i(count) j(study_id)
			drop combinations
			rename count comb
			

			
			gen __ma_ln_or_h =. 
			gen __ma_se_lnor_h =.
			gen __ma_or_h =.
	        gen __ma_lci_or_h =.
	        gen __ma_uci_or_h =.
			gen __p_h =.
			gen __ps_h=.
			
			gen __ma_ln_or_b =. 
			gen __ma_se_lnor_b =.
			gen __ma_or_b =.
	        gen __ma_lci_or_b =.
	        gen __ma_uci_or_b =.
			gen __p_b =.
			gen __ps_b=.
			
			
			
			gen r_h1 = __a
	        gen r_h2 = __c
	        gen n_h1 = __a + __b
	        gen n_h2 = __c + __d
	
	        bysort comb: egen total_r_h1 = sum(r_h1)
	        bysort comb: egen total_r_h2 = sum(r_h2)
			
			gen r_b1 = ___a
	        gen r_b2 = ___c
	        gen n_b1 = ___a + __b
	        gen n_b2 = ___c + __d
			gen _events = ___a + ___c
			replace _events = 1 if _events !=0
	
	        bysort comb: egen total_r_b1 = sum(r_b1)
	        bysort comb: egen total_r_b2 = sum(r_b2)
			
	
	       *prevent potential convergent problem due to rare events
	       gen MA_CZ=0
	       replace MA_CZ = 1 if total_r_h1 == 0 | total_r_h2 == 0 | total_r_b1 ==0 | total_r_b2 ==0
           
		   if MA_CZ == 1 {
					  display as error "Total events in one of the arm or both arms are zero, one-stage method is not applicable"
	                  exit 198
					}	
	       
		   if MA_CZ !=1 {
	           
			   gen id =_n
			   qui reshape long n_h r_h n_b r_b, i(id) j(group)
               replace group =-group+2
	
			*Meta-analysis for all combinations of harms
			egen max_comb = max(comb)
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
				
				qui betabin r_h group study_id if comb ==`meta' & _events !=0, n(n_h) link(logit) iter(20)
			    replace __ma_ln_or_h = _b[group] if comb == `meta'
			    replace __ma_se_lnor_h = _se[group] if comb == `meta'
			 	 }
				
				replace __ma_or_h = exp(__ma_ln_or_h)
				replace __ma_lci_or_h=exp(__ma_ln_or_h-(invnormal(0.975)*__ma_se_lnor_h)) 
				replace __ma_uci_or_h=exp(__ma_ln_or_h+(invnormal(0.975)*__ma_se_lnor_h)) 
			    replace __p_h=2*(1-normal(abs(__ma_ln_or_h/__ma_se_lnor_h))) 
				replace __ps_h = 1 if __p_h < 0.05 
			    replace __ps_h = -1 if __p_h > 0.05 
				sort comb
				
				
					
				
			*Meta-analysis for all combinations of benifits
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
				
				qui betabin r_b group study_id if comb ==`meta' & _events !=0, n(n_b) link(logit) iter(20)
			    replace __ma_ln_or_b = _b[group] if comb == `meta'
			    replace __ma_se_lnor_b = _se[group] if comb == `meta'
			 	 }
				
				replace __ma_or_b = exp(__ma_ln_or_b)
				replace __ma_lci_or_b=exp(__ma_ln_or_b-(invnormal(0.975)*__ma_se_lnor_b)) 
				replace __ma_uci_or_b=exp(__ma_ln_or_b+(invnormal(0.975)*__ma_se_lnor_b)) 
			    replace __p_b=2*(1-normal(abs(__ma_ln_or_b/__ma_se_lnor_b))) 
				replace __ps_b = 1 if __p_b < 0.05 
			    replace __ps_b = -1 if __p_b > 0.05 
				sort comb	
			    }
				
				qui reshape wide r_h n_h r_b n_b, i(id) j(group)
				gen events = __a + __c
			    
				   local t = max_zero_double
				   forvalues t = 1(1)`t' {
				      gen control_arm`t' = __d[`t'] if events[`t'] ==0
					  gen treat_arm`t' = __b[`t'] if events[`t'] ==0 
					  }
					  
	            egen max_arm = rowmax(treat_arm*)
	            egen max_arm_c = rowmax(control_arm*)
		
			    drop max_zero_double
				keep if study_id == 1
				drop study_id
			    drop study_num
				
		
				gen ratio_dir_h = __ma_ln_or_h/__ma_ln_or_h[1]
				gen ratio_sig_h = __ps_h/__ps_h[1]
				
				gen d_dir_h = 0 if ratio_dir_h > 0
				replace d_dir_h = 1 if ratio_dir_h < 0
				gen d_sig_h = 0 if ratio_sig_h > 0
				replace d_sig_h = 1 if ratio_sig_h < 0
				gen direction_h = d_sig_h + d_dir_h	
				
				
				gen ratio_dir_b = __ma_ln_or_b/__ma_ln_or_b[1]
				gen ratio_sig_b = __ps_b/__ps_b[1]
				
				gen d_dir_b = 0 if ratio_dir_b > 0
				replace d_dir_b = 1 if ratio_dir_b < 0
				gen d_sig_b = 0 if ratio_sig_b > 0
				replace d_sig_b = 1 if ratio_sig_b < 0
				gen direction_b = d_sig_b + d_dir_b	
				
				***max and min effects (for graph)
				egen min_lci_h = min(__ma_lci_or_h)
                egen min_uci_h = max(__ma_uci_or_h)
                egen min_lci_b = min(__ma_lci_or_b)
                egen min_uci_b = max(__ma_uci_or_b)
				
				
				***HI index
		        egen Hi = rowtotal(_study*)
				sort Hi
				gen direction_h_r = _n if direction_h ==1
				egen Meta_Hi = min(cond(direction_h_r,Hi,.))  if direction_h_r !=.
				replace Meta_Hi = 0 if Meta_Hi ==.
				
				
				
				***BI index
		        egen Bi = rowtotal(_study*)
				sort Bi
				gen direction_b_r = _n if direction_b ==1
				egen Meta_Bi = min(cond(direction_b_r,Bi,.)) if direction_b_r !=.
				replace Meta_Bi = 0 if Meta_Bi ==.
				
			
				***Rename
				egen max_MHi =max(Meta_Hi)
				drop Meta_Hi
				rename max_MHi Meta_Hi
				
				
				egen max_MBi =max(Meta_Bi)
				drop Meta_Bi
				rename max_MBi Meta_Bi
				
				scalar define _Meta_Hi = Meta_Hi[1]
				scalar define _Meta_Bi = Meta_Bi[1]
				
				if Meta_Hi == 0 & Meta_Bi == 0{
				      noisily display as text "Doubld-zero-events studies totally do not impact the results:"
					}	
				if (Meta_Hi > 0 & Meta_Hi < 3) | (Meta_Bi > 0 & Meta_Bi < 3){
				      noisily display as text "Doubld-zero-events studies may have some impact on the results:" 
					}
				if (Meta_Hi >= 3) | (Meta_Bi >= 3){
				      noisily display as text "Doubld-zero-events studies may have little impact on the results:"
					}				

		}
		
}			
*




*Binary data input + RR selected
if  "`1'" != "" & "`2'" != "" & "`3'" != "" & "`4'" != "" & "`or'" == "" & "`rr'" != "" & "`onestage'" == "" & "`twostage'" == "" & "`ap'" == ""{
	
	display ""
	display as text "Note: two-stage MH method, Effect size = RR"
      
	  quietly{ 
			gen __a = `1'
			gen __b = `2'
			gen __c = `3'
			gen __d = `4'
	
	        gen ___a = __a
			gen ___c = __c
			    
				gen study_id = _n
				gen _id = _n
				gen __zero = 1 if __a==0 | __c==0
				
				egen sumzero=sum(__zero)
				
				if sumzero == 0 {
				          display as error "No zero-events studies"
	                      exit 198
				}
				else {
				
				gen __zero_single = 1 if (__a==0 & __c !=0) | (__a !=0 & __c ==0)
				gen  __zero_double = 1 if __a==0 & __c ==0 
				sort __zero
				gen  __zero_num = _n if __zero == 1
				sort __zero_single
				gen  __zero_single_num = _n if __zero_single==1
				sort __zero_double	
				gen __zero_double_t_sample = __b  if __zero_double !=.
				gen __zero_double_c_sample = __d  if __zero_double !=.			
				gsort __zero_double_t_sample
				gen __zero_double_num = _n if __zero_double==1
				gsort -__zero_double_num
					if __zero_double_num[1]!=.{
								noisily display as text "Note: Number of double-arm-zero-events studies = " as result __zero_double_num[1]
					}	
					}
				
			       egen max_zero_double = max(__zero_double_num)
				   local i  = max_zero_double
		 
				   *gen zerostudy=.
				   *gen iter =.
				   *gen events=.
				   *gen loop =.
				   
				   gen events_total = __a + __c
				   replace events_total = 1 if events_total !=0
				   egen study_num = max(_id)
			
			replace study_id = _n
			keep _id study_num __a __c __b __d ___a  ___c  events_total study_id sumzero max_zero_double
		    reshape wide __a __c __b __d ___a   ___c, i(_id) j(study_id)
            collapse __a* __b* __c* __d* ___a*   ___c*  study_num max_zero_double, by(sumzero)
	   
			gen combinations= 4^max_zero_double
			*sort _id
			*expand combinations
			*bysort _id: gen exp=_n
		    *sort exp _id
            *sort exp study_id
          

	       ***Combinations
	       local K `i'
           local N 3 
		   local N1 = 4
           local No = `N1'^`K'
           assert `No'<=2147483620
           
		   set obs `No'
           generate long count = _n-1
           forvalues k = `K'(-1)1 {
           generate byte _study`k' = mod(count,`N1'), after(count)
           quietly replace count = floor(count/`N1')
           }

           *consistency checking and cleanup
           drop count
		   gen count = _n
		   
		   replace sumzero = sumzero[_n - 1] if missing(sumzero)
		   replace max_zero_double = max_zero_double[_n - 1] if missing(max_zero_double)
		   replace study_num = study_num[_n - 1] if missing(study_num)
		   
		   
		   local K = study_num
		   forvalues k = 1(1)`K' {
		   replace __a`k' = __a`k'[_n-1] if missing(__a`k')
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   replace ___c`k' = ___c`k'[_n-1] if missing(___c`k')
		   }
		   *
		   
			
			local K = max_zero_double
			forvalues k = 1(1) `K' {
			    replace __a`k' = _study`k'
				replace ___c`k' = _study`k'
				}
				
			reshape long __a __b __c __d  ___a  ___c , i(count) j(study_id)
			drop combinations
			rename count comb
			
			
			
			gen __ma_ln_rr_h =. 
			gen __ma_se_lnrr_h =.
			gen __ma_rr_h =.
	        gen __ma_lci_rr_h =.
	        gen __ma_uci_rr_h =.
			gen __p_h =.
			gen __ps_h=.
			
			
			*Meta-analysis for all combinations for harms
			egen max_comb = max(comb)
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan __a __b __c __d if comb == `meta', rr mh nograph
			    replace __ma_ln_rr_h = r(eff) if comb == `meta'
			    replace __ma_se_lnrr_h = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_rr_h = exp(__ma_ln_rr_h) 
				replace __ma_lci_rr_h=exp(__ma_ln_rr_h-(invnormal(0.975)*__ma_se_lnrr_h)) 
				replace __ma_uci_rr_h=exp(__ma_ln_rr_h+(invnormal(0.975)*__ma_se_lnrr_h)) 
			    replace __p_h=2*(1-normal(abs(__ma_ln_rr_h/__ma_se_lnrr_h))) 
				replace __ps_h = 1 if __p_h < 0.05 
			    replace __ps_h = -1 if __p_h > 0.05 
				gen events = __a + __c
			    
				local t = max_zero_double
				   forvalues t = 1(1)`t' {
				      gen treat_arm`t' = __b[`t'] if events[`t'] ==0 
					  }
	            egen max_arm = rowmax(treat_arm*)
					
		    
			*Meta-analysis for all combinations for benifits
			
			gen __ma_ln_rr_b =. 
			gen __ma_se_lnrr_b =.
			gen __ma_rr_b =.
	        gen __ma_lci_rr_b =.
	        gen __ma_uci_rr_b =.
			gen __p_b =.
			gen __ps_b=.
			
			
			*Meta-analysis
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan ___a __b ___c __d if comb == `meta', rr mh nograph
			    replace __ma_ln_rr_b = r(eff) if comb == `meta'
			    replace __ma_se_lnrr_b = r(se_eff) if comb == `meta'
			 	 }
				
				replace __ma_rr_b = exp(__ma_ln_rr_b)
				replace __ma_lci_rr_b=exp(__ma_ln_rr_b-(invnormal(0.975)*__ma_se_lnrr_b)) 
				replace __ma_uci_rr_b=exp(__ma_ln_rr_b+(invnormal(0.975)*__ma_se_lnrr_b)) 
			    replace __p_b=2*(1-normal(abs(__ma_ln_rr_b/__ma_se_lnrr_b))) 
				replace __ps_b = 1 if __p_b < 0.05 
			    replace __ps_b = -1 if __p_b > 0.05 
			   
				local t = max_zero_double
				   forvalues t = 1(1)`t' {
				      gen control_arm`t' = __d[`t'] if events[`t'] ==0 
					  }
	            egen max_arm_c = rowmax(control_arm*)
		
			    drop  _ES _seES _LCI _UCI _WT _rsample max_zero_double 
			    keep if study_id == 1
				drop study_id
				drop study_num
				
		
				gen ratio_dir_h = __ma_ln_rr_h/__ma_ln_rr_h[1]
				gen ratio_sig_h = __ps_h/__ps_h[1]
				
				gen d_dir_h = 0 if ratio_dir_h > 0
				replace d_dir_h = 1 if ratio_dir_h < 0
				gen d_sig_h = 0 if ratio_sig_h > 0
				replace d_sig_h = 1 if ratio_sig_h < 0
				gen direction_h = d_sig_h + d_dir_h	
				
				
				gen ratio_dir_b = __ma_ln_rr_b/__ma_ln_rr_b[1]
				gen ratio_sig_b = __ps_b/__ps_b[1]
				
				gen d_dir_b = 0 if ratio_dir_b > 0
				replace d_dir_b = 1 if ratio_dir_b < 0
				gen d_sig_b = 0 if ratio_sig_b > 0
				replace d_sig_b = 1 if ratio_sig_b < 0
				gen direction_b = d_sig_b + d_dir_b	
				
				
				***max and min effects (for graph)
				egen min_lci_h = min(__ma_lci_rr_h)
                egen min_uci_h = max(__ma_uci_rr_h)
                egen min_lci_b = min(__ma_lci_rr_b)
                egen min_uci_b = max(__ma_uci_rr_b)
				
				***HI index
		        egen Hi = rowtotal(_study*)
				sort Hi
				gen direction_h_r = _n if direction_h ==1
				egen Meta_Hi = min(cond(direction_h_r,Hi,.))  if direction_h_r !=.
				replace Meta_Hi = 0 if Meta_Hi ==.
				
				
				
				***BI index
		        egen Bi = rowtotal(_study*)
				sort Bi
				gen direction_b_r = _n if direction_b ==1
				egen Meta_Bi = min(cond(direction_b_r,Bi,.)) if direction_b_r !=.
				replace Meta_Bi = 0 if Meta_Bi ==.
				
			
				***Rename
				egen max_MHi =max(Meta_Hi)
				drop Meta_Hi
				rename max_MHi Meta_Hi
				
				
				egen max_MBi =max(Meta_Bi)
				drop Meta_Bi
				rename max_MBi Meta_Bi
				
				scalar define _Meta_Hi = Meta_Hi[1]
				scalar define _Meta_Bi = Meta_Bi[1]
				
				if Meta_Hi == 0 & Meta_Bi == 0{
				      noisily display as text "Doubld-zero-events studies totally do not impact the results:"
					}	
				if (Meta_Hi > 0 & Meta_Hi < 3) | (Meta_Bi > 0 & Meta_Bi < 3){
				      noisily display as text "Doubld-zero-events studies may have some impact on the results:" 
					}
				if (Meta_Hi >= 3) | (Meta_Bi >= 3){
				      noisily display as text "Doubld-zero-events studies may have little impact on the results:"
					}		

	}
}			
*



*Binary data input + RR selected + twostage selected
if "`1'" != "" & "`2'" != "" & "`3'" != "" & "`4'" != "" & "`or'" == "" & "`rr'" != "" & "`onestage'" == "" & "`twostage'" != "" & "`ap'" == ""{
	
	display ""
	display as text "Note: two-stage MH method, Effect size = RR"

		quietly{ 
			gen __a = `1'
			gen __b = `2'
			gen __c = `3'
			gen __d = `4'
	
	        gen ___a = __a
			gen ___c = __c
			    
				gen study_id = _n
				gen _id = _n
				gen __zero = 1 if __a==0 | __c==0
				
				egen sumzero=sum(__zero)
				
				if sumzero == 0 {
				          display as error "No zero-events studies"
	                      exit 198
				}
				else {
				
				gen __zero_single = 1 if (__a==0 & __c !=0) | (__a !=0 & __c ==0)
				gen  __zero_double = 1 if __a==0 & __c ==0 
				sort __zero
				gen  __zero_num = _n if __zero == 1
				sort __zero_single
				gen  __zero_single_num = _n if __zero_single==1
				sort __zero_double	
				gen __zero_double_t_sample = __b  if __zero_double !=.
				gen __zero_double_c_sample = __d  if __zero_double !=.			
				gsort __zero_double_t_sample
				gen __zero_double_num = _n if __zero_double==1
				gsort -__zero_double_num
					if __zero_double_num[1]!=.{
								noisily display as text "Note: Number of double-arm-zero-events studies = " as result __zero_double_num[1]
					}	
					}
				
			       egen max_zero_double = max(__zero_double_num)
				   local i  = max_zero_double
		 
				   *gen zerostudy=.
				   *gen iter =.
				   *gen events=.
				   *gen loop =.
				   
				   gen events_total = __a + __c
				   replace events_total = 1 if events_total !=0
				   egen study_num = max(_id)
			
			replace study_id = _n
			keep _id study_num __a __c __b __d ___a  ___c  events_total study_id sumzero max_zero_double
		    reshape wide __a __c __b __d ___a   ___c, i(_id) j(study_id)
            collapse __a* __b* __c* __d* ___a*   ___c*  study_num max_zero_double, by(sumzero)
	   
			gen combinations= 4^max_zero_double
			*sort _id
			*expand combinations
			*bysort _id: gen exp=_n
		    *sort exp _id
            *sort exp study_id
          

	       ***Combinations
	       local K `i'
           local N 3 
		   local N1 = 4
           local No = `N1'^`K'
           assert `No'<=2147483620
           
		   set obs `No'
           generate long count = _n-1
           forvalues k = `K'(-1)1 {
           generate byte _study`k' = mod(count,`N1'), after(count)
           quietly replace count = floor(count/`N1')
           }

           *consistency checking and cleanup
           drop count
		   gen count = _n
		   
		   replace sumzero = sumzero[_n - 1] if missing(sumzero)
		   replace max_zero_double = max_zero_double[_n - 1] if missing(max_zero_double)
		   replace study_num = study_num[_n - 1] if missing(study_num)
		   
		   
		   local K = study_num
		   forvalues k = 1(1)`K' {
		   replace __a`k' = __a`k'[_n-1] if missing(__a`k')
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   replace ___c`k' = ___c`k'[_n-1] if missing(___c`k')
		   }
		   *
		   
			
			local K = max_zero_double
			forvalues k = 1(1) `K' {
			    replace __a`k' = _study`k'
				replace ___c`k' = _study`k'
				}
				
			reshape long __a __b __c __d  ___a  ___c , i(count) j(study_id)
			drop combinations
			rename count comb
			
			
			
			gen __ma_ln_rr_h =. 
			gen __ma_se_lnrr_h =.
			gen __ma_rr_h =.
	        gen __ma_lci_rr_h =.
	        gen __ma_uci_rr_h =.
			gen __p_h =.
			gen __ps_h=.
			
			
			*Meta-analysis for all combinations for harms
			egen max_comb = max(comb)
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan __a __b __c __d if comb == `meta', rr mh nograph
			    replace __ma_ln_rr_h = r(eff) if comb == `meta'
			    replace __ma_se_lnrr_h = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_rr_h = exp(__ma_ln_rr_h) 
				replace __ma_lci_rr_h=exp(__ma_ln_rr_h-(invnormal(0.975)*__ma_se_lnrr_h)) 
				replace __ma_uci_rr_h=exp(__ma_ln_rr_h+(invnormal(0.975)*__ma_se_lnrr_h)) 
			    replace __p_h=2*(1-normal(abs(__ma_ln_rr_h/__ma_se_lnrr_h))) 
				replace __ps_h = 1 if __p_h < 0.05 
			    replace __ps_h = -1 if __p_h > 0.05 
				gen events = __a + __c
			    
				local t = max_zero_double
				   forvalues t = 1(1)`t' {
				      gen treat_arm`t' = __b[`t'] if events[`t'] ==0 
					  }
	            egen max_arm = rowmax(treat_arm*)
					
		    
			*Meta-analysis for all combinations for benifits
			
			gen __ma_ln_rr_b =. 
			gen __ma_se_lnrr_b =.
			gen __ma_rr_b =.
	        gen __ma_lci_rr_b =.
	        gen __ma_uci_rr_b =.
			gen __p_b =.
			gen __ps_b=.
			
			
			*Meta-analysis
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan ___a __b ___c __d if comb == `meta', rr mh nograph
			    replace __ma_ln_rr_b = r(eff) if comb == `meta'
			    replace __ma_se_lnrr_b = r(se_eff) if comb == `meta'
			 	 }
				
				replace __ma_rr_b = exp(__ma_ln_rr_b)
				replace __ma_lci_rr_b=exp(__ma_ln_rr_b-(invnormal(0.975)*__ma_se_lnrr_b)) 
				replace __ma_uci_rr_b=exp(__ma_ln_rr_b+(invnormal(0.975)*__ma_se_lnrr_b)) 
			    replace __p_b=2*(1-normal(abs(__ma_ln_rr_b/__ma_se_lnrr_b))) 
				replace __ps_b = 1 if __p_b < 0.05 
			    replace __ps_b = -1 if __p_b > 0.05 
			   
				local t = max_zero_double
				   forvalues t = 1(1)`t' {
				      gen control_arm`t' = __d[`t'] if events[`t'] ==0 
					  }
	            egen max_arm_c = rowmax(control_arm*)
		
			    drop  _ES _seES _LCI _UCI _WT _rsample max_zero_double
			    keep if study_id == 1
				drop study_id
				drop study_num
				
		
				gen ratio_dir_h = __ma_ln_rr_h/__ma_ln_rr_h[1]
				gen ratio_sig_h = __ps_h/__ps_h[1]
				
				gen d_dir_h = 0 if ratio_dir_h > 0
				replace d_dir_h = 1 if ratio_dir_h < 0
				gen d_sig_h = 0 if ratio_sig_h > 0
				replace d_sig_h = 1 if ratio_sig_h < 0
				gen direction_h = d_sig_h + d_dir_h	
				
				
				gen ratio_dir_b = __ma_ln_rr_b/__ma_ln_rr_b[1]
				gen ratio_sig_b = __ps_b/__ps_b[1]
				
				gen d_dir_b = 0 if ratio_dir_b > 0
				replace d_dir_b = 1 if ratio_dir_b < 0
				gen d_sig_b = 0 if ratio_sig_b > 0
				replace d_sig_b = 1 if ratio_sig_b < 0
				gen direction_b = d_sig_b + d_dir_b	
				
				
				***max and min effects (for graph)
				egen min_lci_h = min(__ma_lci_rr_h)
                egen min_uci_h = max(__ma_uci_rr_h)
                egen min_lci_b = min(__ma_lci_rr_b)
                egen min_uci_b = max(__ma_uci_rr_b)
				
				***HI index
		        egen Hi = rowtotal(_study*)
				sort Hi
				gen direction_h_r = _n if direction_h ==1
				egen Meta_Hi = min(cond(direction_h_r,Hi,.))  if direction_h_r !=.
				replace Meta_Hi = 0 if Meta_Hi ==.
				
				
				
				***BI index
		        egen Bi = rowtotal(_study*)
				sort Bi
				gen direction_b_r = _n if direction_b ==1
				egen Meta_Bi = min(cond(direction_b_r,Bi,.)) if direction_b_r !=.
				replace Meta_Bi = 0 if Meta_Bi ==.
				
			
				***Rename
				egen max_MHi =max(Meta_Hi)
				drop Meta_Hi
				rename max_MHi Meta_Hi
				
				
				egen max_MBi =max(Meta_Bi)
				drop Meta_Bi
				rename max_MBi Meta_Bi
				
				scalar define _Meta_Hi = Meta_Hi[1]
				scalar define _Meta_Bi = Meta_Bi[1]
				
				if Meta_Hi == 0 & Meta_Bi == 0{
				      noisily display as text "Doubld-zero-events studies totally do not impact the results:"
					}	
				if (Meta_Hi > 0 & Meta_Hi < 3) | (Meta_Bi > 0 & Meta_Bi < 3){
				      noisily display as text "Doubld-zero-events studies may have some impact on the results:" 
					}
				if (Meta_Hi >= 3) | (Meta_Bi >= 3){
				      noisily display as text "Doubld-zero-events studies may have little impact on the results:"
					}			
	}
}			
*



*Binary data input + RR selected + onestage selected
if "`1'" != "" & "`2'" != "" & "`3'" != "" & "`4'" != "" & "`or'" == "" & "`rr'" != "" & "`onestage'" != "" & "`twostage'" == "" & "`ap'" == ""{
	display ""
	display as text "Note: One-stage method will take more time..."
	display as text "Note: Beta-binomial model, Effect size = RR"
    
	
	quietly{ 
			gen __a = `1'
			gen __b = `2'
			gen __c = `3'
			gen __d = `4'
			    
			gen ___a = __a
			gen ___c = __c
			    
				gen study_id = _n
				gen _id = _n
				gen __zero = 1 if __a==0 | __c==0
				
				egen sumzero=sum(__zero)
				
				if sumzero == 0 {
				          display as error "No zero-events studies"
	                      exit 198
				}
				else {
				
				gen __zero_single = 1 if (__a==0 & __c !=0) | (__a !=0 & __c ==0)
				gen  __zero_double = 1 if __a==0 & __c ==0 
				sort __zero
				gen  __zero_num = _n if __zero == 1
				sort __zero_single
				gen  __zero_single_num = _n if __zero_single==1
				sort __zero_double	
				gen __zero_double_t_sample = __b  if __zero_double !=.
				gen __zero_double_c_sample = __d  if __zero_double !=.			
				gsort __zero_double_t_sample
				gen __zero_double_num = _n if __zero_double==1
				gsort -__zero_double_num
					if __zero_double_num[1]!=.{
								noisily display as text "Note: Number of double-arm-zero-events studies = " as result __zero_double_num[1]
					}	
					}
				
			       egen max_zero_double = max(__zero_double_num)
				   local i  = max_zero_double
		 
				   *gen zerostudy=.
				   *gen iter =.
				   *gen events=.
				   *gen loop =.
				   
				   gen events_total = __a + __c
				   replace events_total = 1 if events_total !=0
				   egen study_num = max(_id)
			
			replace study_id = _n
			keep _id study_num __a __c __b __d ___a  ___c  events_total study_id sumzero max_zero_double
		    reshape wide __a __c __b __d ___a   ___c, i(_id) j(study_id)
            collapse __a* __b* __c* __d* ___a*   ___c*  study_num max_zero_double, by(sumzero)
	   
			gen combinations= 4^max_zero_double
			*sort _id
			*expand combinations
			*bysort _id: gen exp=_n
		    *sort exp _id
            *sort exp study_id
          

	       ***Combinations
	       local K `i'
           local N 3 
		   local N1 = 4
           local No = `N1'^`K'
           assert `No'<=2147483620
           
		   set obs `No'
           generate long count = _n-1
           forvalues k = `K'(-1)1 {
           generate byte _study`k' = mod(count,`N1'), after(count)
           quietly replace count = floor(count/`N1')
           }

           *consistency checking and cleanup
           drop count
		   gen count = _n
		   
		   replace sumzero = sumzero[_n - 1] if missing(sumzero)
		   replace max_zero_double = max_zero_double[_n - 1] if missing(max_zero_double)
		   replace study_num = study_num[_n - 1] if missing(study_num)
		   
		   
		   local K = study_num
		   forvalues k = 1(1)`K' {
		   replace __a`k' = __a`k'[_n-1] if missing(__a`k')
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   replace ___c`k' = ___c`k'[_n-1] if missing(___c`k')
		   }
		   *
		   
			
			local K = max_zero_double
			forvalues k = 1(1) `K' {
			    replace __a`k' = _study`k'
				replace ___c`k' = _study`k'
				}
				
			reshape long __a __b __c __d  ___a  ___c , i(count) j(study_id)
			drop combinations
			rename count comb
			

			
			gen __ma_ln_rr_h =. 
			gen __ma_se_lnrr_h =.
			gen __ma_rr_h =.
	        gen __ma_lci_rr_h =.
	        gen __ma_uci_rr_h =.
			gen __p_h =.
			gen __ps_h=.
			
			gen __ma_ln_rr_b =. 
			gen __ma_se_lnrr_b =.
			gen __ma_rr_b =.
	        gen __ma_lci_rr_b =.
	        gen __ma_uci_rr_b =.
			gen __p_b =.
			gen __ps_b=.
			
			
			
			gen r_h1 = __a
	        gen r_h2 = __c
	        gen n_h1 = __a + __b
	        gen n_h2 = __c + __d
	
	        bysort comb: egen total_r_h1 = sum(r_h1)
	        bysort comb: egen total_r_h2 = sum(r_h2)
			
			gen r_b1 = ___a
	        gen r_b2 = ___c
	        gen n_b1 = ___a + __b
	        gen n_b2 = ___c + __d
			gen _events = ___a + ___c
			replace _events = 1 if _events !=0
	
	        bysort comb: egen total_r_b1 = sum(r_b1)
	        bysort comb: egen total_r_b2 = sum(r_b2)
			
	
	       *prevent potential convergent problem due to rare events
	       gen MA_CZ=0
	       replace MA_CZ = 1 if total_r_h1 == 0 | total_r_h2 == 0 | total_r_b1 ==0 | total_r_b2 ==0
           
		   if MA_CZ == 1 {
					  display as error "Total events in one of the arm or both arms are zero, one-stage method is not applicable"
	                  exit 198
					}	
	       
		   if MA_CZ !=1 {
	           
			   gen id =_n
			   qui reshape long n_h r_h n_b r_b, i(id) j(group)
               replace group =-group+2
	
			*Meta-analysis for all combinations of harms
			egen max_comb = max(comb)
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
				
				qui betabin r_h group study_id if comb ==`meta' & _events !=0, n(n_h) link(logit) iter(20) 
			    replace __ma_ln_rr_h = _b[group] if comb == `meta'
			    replace __ma_se_lnrr_h = _se[group] if comb == `meta'
			 	 }
				
				replace __ma_rr_h = exp(__ma_ln_rr_h)
				replace __ma_lci_rr_h=exp(__ma_ln_rr_h-(invnormal(0.975)*__ma_se_lnrr_h)) 
				replace __ma_uci_rr_h=exp(__ma_ln_rr_h+(invnormal(0.975)*__ma_se_lnrr_h)) 
			    replace __p_h=2*(1-normal(abs(__ma_ln_rr_h/__ma_se_lnrr_h))) 
				replace __ps_h = 1 if __p_h < 0.05 
			    replace __ps_h = -1 if __p_h > 0.05 
				sort comb
				
				
					
				
			*Meta-analysis for all combinations of benifits
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
				
				qui betabin r_b group study_id if comb ==`meta' & _events !=0, n(n_b) link(logit) iter(20) 
			    replace __ma_ln_rr_b = _b[group] if comb == `meta'
			    replace __ma_se_lnrr_b = _se[group] if comb == `meta'
			 	 }
				
				replace __ma_rr_b = exp(__ma_ln_rr_b)
				replace __ma_lci_rr_b=exp(__ma_ln_rr_b-(invnormal(0.975)*__ma_se_lnrr_b)) 
				replace __ma_uci_rr_b=exp(__ma_ln_rr_b+(invnormal(0.975)*__ma_se_lnrr_b)) 
			    replace __p_b=2*(1-normal(abs(__ma_ln_rr_b/__ma_se_lnrr_b))) 
				replace __ps_b = 1 if __p_b < 0.05 
			    replace __ps_b = -1 if __p_b > 0.05 
				sort comb	
			    }
				
				qui reshape wide r_h n_h r_b n_b, i(id) j(group)
				gen events = __a + __c
			    
				   local t = max_zero_double
				   forvalues t = 1(1)`t' {
				      gen control_arm`t' = __d[`t'] if events[`t'] ==0
					  gen treat_arm`t' = __b[`t'] if events[`t'] ==0 
					  }
					  
	            egen max_arm = rowmax(treat_arm*)
	            egen max_arm_c = rowmax(control_arm*)
		
			    drop max_zero_double
				keep if study_id == 1
				drop study_id
			    drop study_num
				
		
				gen ratio_dir_h = __ma_ln_rr_h/__ma_ln_rr_h[1]
				gen ratio_sig_h = __ps_h/__ps_h[1]
				
				gen d_dir_h = 0 if ratio_dir_h > 0
				replace d_dir_h = 1 if ratio_dir_h < 0
				gen d_sig_h = 0 if ratio_sig_h > 0
				replace d_sig_h = 1 if ratio_sig_h < 0
				gen direction_h = d_sig_h + d_dir_h	
				
				
				gen ratio_dir_b = __ma_ln_rr_b/__ma_ln_rr_b[1]
				gen ratio_sig_b = __ps_b/__ps_b[1]
				
				gen d_dir_b = 0 if ratio_dir_b > 0
				replace d_dir_b = 1 if ratio_dir_b < 0
				gen d_sig_b = 0 if ratio_sig_b > 0
				replace d_sig_b = 1 if ratio_sig_b < 0
				gen direction_b = d_sig_b + d_dir_b	
				
				
				***max and min effects (for graph)
				egen min_lci_h = min(__ma_lci_rr_h)
                egen min_uci_h = max(__ma_uci_rr_h)
                egen min_lci_b = min(__ma_lci_rr_b)
                egen min_uci_b = max(__ma_uci_rr_b)
				
				***HI index
		        egen Hi = rowtotal(_study*)
				sort Hi
				gen direction_h_r = _n if direction_h ==1
				egen Meta_Hi = min(cond(direction_h_r,Hi,.))  if direction_h_r !=.
				replace Meta_Hi = 0 if Meta_Hi ==.
				
				
				
				***BI index
		        egen Bi = rowtotal(_study*)
				sort Bi
				gen direction_b_r = _n if direction_b ==1
				egen Meta_Bi = min(cond(direction_b_r,Bi,.)) if direction_b_r !=.
				replace Meta_Bi = 0 if Meta_Bi ==.
				
			
				***Rename
				egen max_MHi =max(Meta_Hi)
				drop Meta_Hi
				rename max_MHi Meta_Hi
				
				
				egen max_MBi =max(Meta_Bi)
				drop Meta_Bi
				rename max_MBi Meta_Bi
				
				scalar define _Meta_Hi = Meta_Hi[1]
				scalar define _Meta_Bi = Meta_Bi[1]
				
				if Meta_Hi == 0 & Meta_Bi == 0{
				      noisily display as text "Doubld-zero-events studies totally do not impact the results:"
					}	
				if (Meta_Hi > 0 & Meta_Hi < 3) | (Meta_Bi > 0 & Meta_Bi < 3){
				      noisily display as text "Doubld-zero-events studies may have some impact on the results:" 
					}
				if (Meta_Hi >= 3) | (Meta_Bi >= 3){
				      noisily display as text "Doubld-zero-events studies may have little impact on the results:"
					}

		}
		
}			
*


******Approximating methods for Hi and Bi


*Binary data input (default)
if  "`1'" != "" & "`2'" != "" & "`3'" != "" & "`4'" != "" & "`or'" == "" & "`rr'" == "" & "`onestage'" == "" & "`twostage'" == "" & "`ap'" != ""{
	
	display ""
	display as text "Note: two-stage peto's OR, Effect size =OR"

		quietly{ 
			gen __a = `1'
			gen __b = `2'
			gen __c = `3'
			gen __d = `4'
			
			gen ___a = __a
			gen ___c = __c
			    
				gen study_id = _n
				gen _id = _n
				gen __zero = 1 if __a==0 | __c==0
				
				egen sumzero=sum(__zero)
				
				if sumzero == 0 {
				          display as error "No zero-events studies"
	                      exit 198
				}
				else {
				
				gen __zero_single = 1 if (__a==0 & __c !=0) | (__a !=0 & __c ==0)
				gen  __zero_double = 1 if __a==0 & __c ==0 
				sort __zero
				gen  __zero_num = _n if __zero == 1
				sort __zero_single
				gen  __zero_single_num = _n if __zero_single==1
				sort __zero_double	
				gen __zero_double_t_sample = __b  if __zero_double !=.
				gen __zero_double_c_sample = __d  if __zero_double !=.			
				gsort __zero_double_t_sample
				gen __zero_double_num = _n if __zero_double==1
				gsort -__zero_double_num
					if __zero_double_num[1]!=.{
								noisily display as text "Note: Number of double-arm-zero-events studies = " as result __zero_double_num[1]
					}	
					}
					
				  gen __a_bot = __a
				  gen __b_bot = __b
				  gen __c_bot = __c
				  gen __d_bot = __d
				  
				  replace __a_bot = 1 if __zero_double==1
				  replace __c_bot = 1 if __zero_double==1
				  admetan __a_bot __b_bot __c_bot __d_bot, peto or nograph
				  gen eff_bot = _ES*_WT
				  replace eff_bot =. if __zero_double !=1
				  egen max_eff_bot =max(eff_bot) 
				  drop if eff_bot != max_eff_bot & __zero_double==1
				  drop __a_bot __b_bot  __c_bot __d_bot _ES _seES _LCI _UCI _WT _NN _rsample
				  
				  egen max_zero_double = max(__zero_double_num)
				  local i  = max_zero_double
		 
				   *gen zerostudy=.
				   *gen iter =.
				   *gen events=.
				   *gen loop =.
				   
				   gen events_total = __a + __c
				   replace events_total = 1 if events_total !=0
				   sort _id
				   drop _id
				   gen _id=_n
				   egen study_num = max(_id)
				   gsort -__zero_double_num
			
			    replace study_id = _n
			    keep _id study_num __a __c __b __d ___a  ___c  events_total study_id sumzero max_zero_double
		        reshape wide __a __c __b __d ___a   ___c, i(_id) j(study_id)
                collapse __a* __b* __c* __d* ___a*   ___c*  study_num max_zero_double, by(sumzero)
	   
				
				gen combinations=4*max_zero_double
				

	       ***Combinations
	       local K `i'
           local N 4 
		   local No = `N'*`K' + 1
           
		   set obs `No'
           generate long count = _n-1
		   generate _study = count
           
		   
		   
		   replace sumzero = sumzero[_n - 1] if missing(sumzero)
		   replace max_zero_double = max_zero_double[_n - 1] if missing(max_zero_double)
		   replace study_num = study_num[_n - 1] if missing(study_num)
		   replace __a1=_study  
		   replace ___c1=_study
		   
		   local K = study_num
		   forvalues k = 2(1)`K' {
		   replace __a`k' = __a`k'[_n-1] if missing(__a`k')
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   replace ___c`k' = ___c`k'[_n-1] if missing(___c`k')
		   }
		   *
		   forvalues k = 1(1)`K' {
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   }
		   *
			
			
			gen _rank = _n
			reshape long __a __b __c __d  ___a  ___c , i(_rank) j(study_id)
			
			
			

			drop combinations
			rename _rank comb
			
			gen __ma_ln_or_h =. 
			gen __ma_se_lnor_h =.
			gen __ma_or_h =.
	        gen __ma_lci_or_h =.
	        gen __ma_uci_or_h =.
			gen __p_h =.
			gen __ps_h=.
			
			
			*Meta-analysis for all combinations for harms
			egen max_comb = max(comb)
			replace max_comb = __b[1] if max_comb > __b[1]
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan __a __b __c __d if comb == `meta', peto or nograph
			    replace __ma_ln_or_h = r(eff) if comb == `meta'
			    replace __ma_se_lnor_h = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_or_h = exp(__ma_ln_or_h) 
				replace __ma_lci_or_h=exp(__ma_ln_or_h-(invnormal(0.975)*__ma_se_lnor_h)) 
				replace __ma_uci_or_h=exp(__ma_ln_or_h+(invnormal(0.975)*__ma_se_lnor_h)) 
			    replace __p_h=2*(1-normal(abs(__ma_ln_or_h/__ma_se_lnor_h))) 
				replace __ps_h = 1 if __p_h < 0.05 
			    replace __ps_h = -1 if __p_h > 0.05 
				gen events = __a + __c
			    
				local t = sumzero
				   forvalues t = 1(1)`t' {
				      gen treat_arm`t' = __b[`t'] if events[`t'] ==0 
					  }
	            egen max_arm = rowmax(treat_arm*)
					
		    
			*Meta-analysis for all combinations for benifits
			
			
			gen __ma_ln_or_b =. 
			gen __ma_se_lnor_b =.
			gen __ma_or_b =.
	        gen __ma_lci_or_b =.
	        gen __ma_uci_or_b =.
			gen __p_b =.
			gen __ps_b=.
			
			
			*Meta-analysis
			replace max_comb = __d[1] if max_comb > __d[1]
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan ___a __b ___c __d if comb == `meta', peto or nograph
			    replace __ma_ln_or_b = r(eff) if comb == `meta'
			    replace __ma_se_lnor_b = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_or_b = exp(__ma_ln_or_b)
				replace __ma_lci_or_b=exp(__ma_ln_or_b-(invnormal(0.975)*__ma_se_lnor_b)) 
				replace __ma_uci_or_b=exp(__ma_ln_or_b+(invnormal(0.975)*__ma_se_lnor_b)) 
			    replace __p_b=2*(1-normal(abs(__ma_ln_or_b/__ma_se_lnor_b))) 
				replace __ps_b = 1 if __p_b < 0.05 
			    replace __ps_b = -1 if __p_b > 0.05 
			   
				local t = sumzero
				   forvalues t = 1(1)`t' {
				      gen control_arm`t' = __d[`t'] if events[`t'] ==0 
					  }
	            egen max_arm_c = rowmax(control_arm*)
		
			    drop  _ES _seES _LCI _UCI _WT _rsample max_zero_double 
			    keep if study_id == 1
				drop study_id
			    drop study_num
				drop if __ma_or_h ==. & __ma_or_b ==.
				

				gen ratio_dir_h = __ma_ln_or_h/__ma_ln_or_h[1]
				gen ratio_sig_h = __ps_h/__ps_h[1]
				
				gen d_dir_h = 0 if ratio_dir_h > 0
				replace d_dir_h = 1 if ratio_dir_h < 0
				gen d_sig_h = 0 if ratio_sig_h > 0
				replace d_sig_h = 1 if ratio_sig_h < 0
				gen direction_h = d_sig_h + d_dir_h	
				
				
				gen ratio_dir_b = __ma_ln_or_b/__ma_ln_or_b[1]
				gen ratio_sig_b = __ps_b/__ps_b[1]
				
				gen d_dir_b = 0 if ratio_dir_b > 0
				replace d_dir_b = 1 if ratio_dir_b < 0
				gen d_sig_b = 0 if ratio_sig_b > 0
				replace d_sig_b = 1 if ratio_sig_b < 0
				gen direction_b = d_sig_b + d_dir_b	
				
				
				***max and min effects (for graph)
				egen min_lci_h = min(__ma_lci_or_h)
                egen min_uci_h = max(__ma_uci_or_h)
                egen min_lci_b = min(__ma_lci_or_b)
                egen min_uci_b = max(__ma_uci_or_b)
				
				***HI index
		        gen Hi = comb
				sort Hi
				gen direction_h_r = _n if direction_h ==1
				egen Meta_Hi = min(cond(direction_h_r,Hi,.))  if direction_h_r !=.
				replace Meta_Hi = 0 if Meta_Hi ==.
				
				
				
				***BI index
		        gen Bi = comb
				sort Bi
				gen direction_b_r = _n if direction_b ==1
				egen Meta_Bi = min(cond(direction_b_r,Bi,.)) if direction_b_r !=.
				replace Meta_Bi = 0 if Meta_Bi ==.
				
			
				***Rename
				egen max_MHi =max(Meta_Hi)
				drop Meta_Hi
				rename max_MHi Meta_Hi
				
				
				egen max_MBi =max(Meta_Bi)
				drop Meta_Bi
				rename max_MBi Meta_Bi
				
				scalar define _Meta_Hi = Meta_Hi[1]
				scalar define _Meta_Bi = Meta_Bi[1]
				
				if Meta_Hi == 0 & Meta_Bi == 0{
				      noisily display as text "Doubld-zero-events studies totally do not impact the results:"
					}	
				if (Meta_Hi > 0 & Meta_Hi < 3) | (Meta_Bi > 0 & Meta_Bi < 3){
				      noisily display as text "Doubld-zero-events studies may have some impact on the results:" 
					}
				if (Meta_Hi >= 3) | (Meta_Bi >= 3){
				      noisily display as text "Doubld-zero-events studies may have little impact on the results:"
					}			
						

		}
}		
*


					

*Binary data input + OR selected
if  "`1'" != "" & "`2'" != "" & "`3'" != "" & "`4'" != "" & "`or'" != "" & "`rr'" == "" & "`onestage'" == "" & "`twostage'" == "" & "`ap'" != ""{
	
		
    display ""
	display as text "Note: two-stage peto's OR, Effect size =OR"

		quietly{ 
			gen __a = `1'
			gen __b = `2'
			gen __c = `3'
			gen __d = `4'
			    
			gen ___a = __a
			gen ___c = __c
			    
				gen study_id = _n
				gen _id = _n
				gen __zero = 1 if __a==0 | __c==0
				
				egen sumzero=sum(__zero)
				
				if sumzero == 0 {
				          display as error "No zero-events studies"
	                      exit 198
				}
				else {
				
				gen __zero_single = 1 if (__a==0 & __c !=0) | (__a !=0 & __c ==0)
				gen  __zero_double = 1 if __a==0 & __c ==0 
				sort __zero
				gen  __zero_num = _n if __zero == 1
				sort __zero_single
				gen  __zero_single_num = _n if __zero_single==1
				sort __zero_double	
				gen __zero_double_t_sample = __b  if __zero_double !=.
				gen __zero_double_c_sample = __d  if __zero_double !=.			
				gsort __zero_double_t_sample
				gen __zero_double_num = _n if __zero_double==1
				gsort -__zero_double_num
					if __zero_double_num[1]!=.{
								noisily display as text "Note: Number of double-arm-zero-events studies = " as result __zero_double_num[1]
					}	
					}
				
				  	
				  gen __a_bot = __a
				  gen __b_bot = __b
				  gen __c_bot = __c
				  gen __d_bot = __d
				  
				  replace __a_bot = 1 if __zero_double==1
				  replace __c_bot = 1 if __zero_double==1
				  admetan __a_bot __b_bot __c_bot __d_bot, peto or nograph
				  gen eff_bot = _ES*_WT
				  replace eff_bot =. if __zero_double !=1
				  egen max_eff_bot =max(eff_bot) 
				  drop if eff_bot != max_eff_bot & __zero_double==1
				  drop __a_bot __b_bot  __c_bot __d_bot _ES _seES _LCI _UCI _WT _NN _rsample
				  
				  egen max_zero_double = max(__zero_double_num)
				  local i  = max_zero_double
		 
				   *gen zerostudy=.
				   *gen iter =.
				   *gen events=.
				   *gen loop =.
				   
				   gen events_total = __a + __c
				   replace events_total = 1 if events_total !=0
				   sort _id
				   drop _id
				   gen _id=_n
				   egen study_num = max(_id)
				   gsort -__zero_double_num
			
			    replace study_id = _n
			    keep _id study_num __a __c __b __d ___a  ___c  events_total study_id sumzero max_zero_double
		        reshape wide __a __c __b __d ___a   ___c, i(_id) j(study_id)
                collapse __a* __b* __c* __d* ___a*   ___c*  study_num max_zero_double, by(sumzero)
	   
				
				gen combinations=4*max_zero_double
				

	       ***Combinations
	       local K `i'
           local N 4 
		   local No = `N'*`K' + 1
           
		   set obs `No'
           generate long count = _n-1
		   generate _study = count
           
		   
		   
		   replace sumzero = sumzero[_n - 1] if missing(sumzero)
		   replace max_zero_double = max_zero_double[_n - 1] if missing(max_zero_double)
		   replace study_num = study_num[_n - 1] if missing(study_num)
		   replace __a1=_study  
		   replace ___c1=_study
		   
		   local K = study_num
		   forvalues k = 2(1)`K' {
		   replace __a`k' = __a`k'[_n-1] if missing(__a`k')
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   replace ___c`k' = ___c`k'[_n-1] if missing(___c`k')
		   }
		   *
		   forvalues k = 1(1)`K' {
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   }
		   *
			
			
			gen _rank = _n
			reshape long __a __b __c __d  ___a  ___c , i(_rank) j(study_id)
			
			
			

			drop combinations
			rename _rank comb
			
			gen __ma_ln_or_h =. 
			gen __ma_se_lnor_h =.
			gen __ma_or_h =.
	        gen __ma_lci_or_h =.
	        gen __ma_uci_or_h =.
			gen __p_h =.
			gen __ps_h=.
			
			
			*Meta-analysis for all combinations for harms
			egen max_comb = max(comb)
			replace max_comb = __b[1] if max_comb > __b[1]
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan __a __b __c __d if comb == `meta', peto or nograph
			    replace __ma_ln_or_h = r(eff) if comb == `meta'
			    replace __ma_se_lnor_h = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_or_h = exp(__ma_ln_or_h) 
				replace __ma_lci_or_h=exp(__ma_ln_or_h-(invnormal(0.975)*__ma_se_lnor_h)) 
				replace __ma_uci_or_h=exp(__ma_ln_or_h+(invnormal(0.975)*__ma_se_lnor_h)) 
			    replace __p_h=2*(1-normal(abs(__ma_ln_or_h/__ma_se_lnor_h))) 
				replace __ps_h = 1 if __p_h < 0.05 
			    replace __ps_h = -1 if __p_h > 0.05 
				gen events = __a + __c
			    
				local t = sumzero
				   forvalues t = 1(1)`t' {
				      gen treat_arm`t' = __b[`t'] if events[`t'] ==0 
					  }
	            egen max_arm = rowmax(treat_arm*)
					
		    
			*Meta-analysis for all combinations for benifits
			
			
			gen __ma_ln_or_b =. 
			gen __ma_se_lnor_b =.
			gen __ma_or_b =.
	        gen __ma_lci_or_b =.
	        gen __ma_uci_or_b =.
			gen __p_b =.
			gen __ps_b=.
			
			
			*Meta-analysis
			replace max_comb = __d[1] if max_comb > __d[1]
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan ___a __b ___c __d if comb == `meta', peto or nograph
			    replace __ma_ln_or_b = r(eff) if comb == `meta'
			    replace __ma_se_lnor_b = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_or_b = exp(__ma_ln_or_b)
				replace __ma_lci_or_b=exp(__ma_ln_or_b-(invnormal(0.975)*__ma_se_lnor_b)) 
				replace __ma_uci_or_b=exp(__ma_ln_or_b+(invnormal(0.975)*__ma_se_lnor_b)) 
			    replace __p_b=2*(1-normal(abs(__ma_ln_or_b/__ma_se_lnor_b))) 
				replace __ps_b = 1 if __p_b < 0.05 
			    replace __ps_b = -1 if __p_b > 0.05 
			   
				local t = sumzero
				   forvalues t = 1(1)`t' {
				      gen control_arm`t' = __d[`t'] if events[`t'] ==0 
					  }
	            egen max_arm_c = rowmax(control_arm*)
		
			    drop  _ES _seES _LCI _UCI _WT _rsample max_zero_double 
			    keep if study_id == 1
				drop study_id
			    drop study_num
				drop if __ma_or_h ==. & __ma_or_b ==.
				

				gen ratio_dir_h = __ma_ln_or_h/__ma_ln_or_h[1]
				gen ratio_sig_h = __ps_h/__ps_h[1]
				
				gen d_dir_h = 0 if ratio_dir_h > 0
				replace d_dir_h = 1 if ratio_dir_h < 0
				gen d_sig_h = 0 if ratio_sig_h > 0
				replace d_sig_h = 1 if ratio_sig_h < 0
				gen direction_h = d_sig_h + d_dir_h	
				
				
				gen ratio_dir_b = __ma_ln_or_b/__ma_ln_or_b[1]
				gen ratio_sig_b = __ps_b/__ps_b[1]
				
				gen d_dir_b = 0 if ratio_dir_b > 0
				replace d_dir_b = 1 if ratio_dir_b < 0
				gen d_sig_b = 0 if ratio_sig_b > 0
				replace d_sig_b = 1 if ratio_sig_b < 0
				gen direction_b = d_sig_b + d_dir_b	
				
				***max and min effects (for graph)
				egen min_lci_h = min(__ma_lci_or_h)
                egen min_uci_h = max(__ma_uci_or_h)
                egen min_lci_b = min(__ma_lci_or_b)
                egen min_uci_b = max(__ma_uci_or_b)
				
				
				***HI index
		        gen Hi = comb
				sort Hi
				gen direction_h_r = _n if direction_h ==1
				egen Meta_Hi = min(cond(direction_h_r,Hi,.))  if direction_h_r !=.
				replace Meta_Hi = 0 if Meta_Hi ==.
				
				
				
				***BI index
		        gen Bi = comb
				sort Bi
				gen direction_b_r = _n if direction_b ==1
				egen Meta_Bi = min(cond(direction_b_r,Bi,.)) if direction_b_r !=.
				replace Meta_Bi = 0 if Meta_Bi ==.
				
			
				***Rename
				egen max_MHi =max(Meta_Hi)
				drop Meta_Hi
				rename max_MHi Meta_Hi
				
				
				egen max_MBi =max(Meta_Bi)
				drop Meta_Bi
				rename max_MBi Meta_Bi
				
				scalar define _Meta_Hi = Meta_Hi[1]
				scalar define _Meta_Bi = Meta_Bi[1]
				
				if Meta_Hi == 0 & Meta_Bi == 0{
				      noisily display as text "Doubld-zero-events studies totally do not impact the results:"
					}	
				if (Meta_Hi > 0 & Meta_Hi < 3) | (Meta_Bi > 0 & Meta_Bi < 3){
				      noisily display as text "Doubld-zero-events studies may have some impact on the results:" 
					}
				if (Meta_Hi >= 3) | (Meta_Bi >= 3){
				      noisily display as text "Doubld-zero-events studies may have little impact on the results:"
					}			
									
						
		}
}			
*


*Binary data input + OR selected + twostage
if  "`1'" != "" & "`2'" != "" & "`3'" != "" & "`4'" != "" & "`or'" != "" & "`rr'" == "" & "`onestage'" == "" & "`twostage'" != "" & "`ap'" != ""{
	
    display ""
	display as text "Note: two-stage peto's OR, Effect size =OR"
	
	quietly{ 
			gen __a = `1'
			gen __b = `2'
			gen __c = `3'
			gen __d = `4'
			gen ___a = __a
			gen ___c = __c
			    
				gen study_id = _n
				gen _id = _n
				gen __zero = 1 if __a==0 | __c==0
				
				egen sumzero=sum(__zero)
				
				if sumzero == 0 {
				          display as error "No zero-events studies"
	                      exit 198
				}
				else {
				
				gen __zero_single = 1 if (__a==0 & __c !=0) | (__a !=0 & __c ==0)
				gen  __zero_double = 1 if __a==0 & __c ==0 
				sort __zero
				gen  __zero_num = _n if __zero == 1
				sort __zero_single
				gen  __zero_single_num = _n if __zero_single==1
				sort __zero_double	
				gen __zero_double_t_sample = __b  if __zero_double !=.
				gen __zero_double_c_sample = __d  if __zero_double !=.			
				gsort __zero_double_t_sample
				gen __zero_double_num = _n if __zero_double==1
				gsort -__zero_double_num
					if __zero_double_num[1]!=.{
								noisily display as text "Note: Number of double-arm-zero-events studies = " as result __zero_double_num[1]
					}	
					}
				
				  	
				  gen __a_bot = __a
				  gen __b_bot = __b
				  gen __c_bot = __c
				  gen __d_bot = __d
				  
				  replace __a_bot = 1 if __zero_double==1
				  replace __c_bot = 1 if __zero_double==1
				  admetan __a_bot __b_bot __c_bot __d_bot, peto or nograph
				  gen eff_bot = _ES*_WT
				  replace eff_bot =. if __zero_double !=1
				  egen max_eff_bot =max(eff_bot) 
				  drop if eff_bot != max_eff_bot & __zero_double==1
				  drop __a_bot __b_bot  __c_bot __d_bot _ES _seES _LCI _UCI _WT _NN _rsample
				  
				  egen max_zero_double = max(__zero_double_num)
				  local i  = max_zero_double
		 
				   *gen zerostudy=.
				   *gen iter =.
				   *gen events=.
				   *gen loop =.
				   
				   gen events_total = __a + __c
				   replace events_total = 1 if events_total !=0
				   sort _id
				   drop _id
				   gen _id=_n
				   egen study_num = max(_id)
				   gsort -__zero_double_num
			
			    replace study_id = _n
			    keep _id study_num __a __c __b __d ___a  ___c  events_total study_id sumzero max_zero_double
		        reshape wide __a __c __b __d ___a   ___c, i(_id) j(study_id)
                collapse __a* __b* __c* __d* ___a*   ___c*  study_num max_zero_double, by(sumzero)
	   
				
				gen combinations=4*max_zero_double
				

	       ***Combinations
	       local K `i'
           local N 4 
		   local No = `N'*`K' + 1
           
		   set obs `No'
           generate long count = _n-1
		   generate _study = count
           
		   
		   
		   replace sumzero = sumzero[_n - 1] if missing(sumzero)
		   replace max_zero_double = max_zero_double[_n - 1] if missing(max_zero_double)
		   replace study_num = study_num[_n - 1] if missing(study_num)
		   replace __a1=_study  
		   replace ___c1=_study
		   
		   local K = study_num
		   forvalues k = 2(1)`K' {
		   replace __a`k' = __a`k'[_n-1] if missing(__a`k')
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   replace ___c`k' = ___c`k'[_n-1] if missing(___c`k')
		   }
		   *
		   forvalues k = 1(1)`K' {
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   }
		   *
			
			
			gen _rank = _n
			reshape long __a __b __c __d  ___a  ___c , i(_rank) j(study_id)
			
			
			

			drop combinations
			rename _rank comb
			
			gen __ma_ln_or_h =. 
			gen __ma_se_lnor_h =.
			gen __ma_or_h =.
	        gen __ma_lci_or_h =.
	        gen __ma_uci_or_h =.
			gen __p_h =.
			gen __ps_h=.
			
			
			*Meta-analysis for all combinations for harms
			egen max_comb = max(comb)
			replace max_comb = __b[1] if max_comb > __b[1]
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan __a __b __c __d if comb == `meta', peto or nograph
			    replace __ma_ln_or_h = r(eff) if comb == `meta'
			    replace __ma_se_lnor_h = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_or_h = exp(__ma_ln_or_h) 
				replace __ma_lci_or_h=exp(__ma_ln_or_h-(invnormal(0.975)*__ma_se_lnor_h)) 
				replace __ma_uci_or_h=exp(__ma_ln_or_h+(invnormal(0.975)*__ma_se_lnor_h)) 
			    replace __p_h=2*(1-normal(abs(__ma_ln_or_h/__ma_se_lnor_h))) 
				replace __ps_h = 1 if __p_h < 0.05 
			    replace __ps_h = -1 if __p_h > 0.05 
				gen events = __a + __c
			    
				local t = sumzero
				   forvalues t = 1(1)`t' {
				      gen treat_arm`t' = __b[`t'] if events[`t'] ==0 
					  }
	            egen max_arm = rowmax(treat_arm*)
					
		    
			*Meta-analysis for all combinations for benifits
			
			
			gen __ma_ln_or_b =. 
			gen __ma_se_lnor_b =.
			gen __ma_or_b =.
	        gen __ma_lci_or_b =.
	        gen __ma_uci_or_b =.
			gen __p_b =.
			gen __ps_b=.
			
			
			*Meta-analysis
			replace max_comb = __d[1] if max_comb > __d[1]
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan ___a __b ___c __d if comb == `meta', peto or nograph
			    replace __ma_ln_or_b = r(eff) if comb == `meta'
			    replace __ma_se_lnor_b = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_or_b = exp(__ma_ln_or_b)
				replace __ma_lci_or_b=exp(__ma_ln_or_b-(invnormal(0.975)*__ma_se_lnor_b)) 
				replace __ma_uci_or_b=exp(__ma_ln_or_b+(invnormal(0.975)*__ma_se_lnor_b)) 
			    replace __p_b=2*(1-normal(abs(__ma_ln_or_b/__ma_se_lnor_b))) 
				replace __ps_b = 1 if __p_b < 0.05 
			    replace __ps_b = -1 if __p_b > 0.05 
			   
				local t = sumzero
				   forvalues t = 1(1)`t' {
				      gen control_arm`t' = __d[`t'] if events[`t'] ==0 
					  }
	            egen max_arm_c = rowmax(control_arm*)
		
			    drop  _ES _seES _LCI _UCI _WT _rsample max_zero_double 
			    keep if study_id == 1
				drop study_id
			    drop study_num
				drop if __ma_or_h ==. & __ma_or_b ==.
				

				gen ratio_dir_h = __ma_ln_or_h/__ma_ln_or_h[1]
				gen ratio_sig_h = __ps_h/__ps_h[1]
				
				gen d_dir_h = 0 if ratio_dir_h > 0
				replace d_dir_h = 1 if ratio_dir_h < 0
				gen d_sig_h = 0 if ratio_sig_h > 0
				replace d_sig_h = 1 if ratio_sig_h < 0
				gen direction_h = d_sig_h + d_dir_h	
				
				
				gen ratio_dir_b = __ma_ln_or_b/__ma_ln_or_b[1]
				gen ratio_sig_b = __ps_b/__ps_b[1]
				
				gen d_dir_b = 0 if ratio_dir_b > 0
				replace d_dir_b = 1 if ratio_dir_b < 0
				gen d_sig_b = 0 if ratio_sig_b > 0
				replace d_sig_b = 1 if ratio_sig_b < 0
				gen direction_b = d_sig_b + d_dir_b	
				
				***max and min effects (for graph)
				egen min_lci_h = min(__ma_lci_or_h)
                egen min_uci_h = max(__ma_uci_or_h)
                egen min_lci_b = min(__ma_lci_or_b)
                egen min_uci_b = max(__ma_uci_or_b)
				
				
				***HI index
		        gen Hi = comb
				sort Hi
				gen direction_h_r = _n if direction_h ==1
				egen Meta_Hi = min(cond(direction_h_r,Hi,.))  if direction_h_r !=.
				replace Meta_Hi = 0 if Meta_Hi ==.
				
				
				
				***BI index
		        gen Bi = comb
				sort Bi
				gen direction_b_r = _n if direction_b ==1
				egen Meta_Bi = min(cond(direction_b_r,Bi,.)) if direction_b_r !=.
				replace Meta_Bi = 0 if Meta_Bi ==.
				
			
				***Rename
				egen max_MHi =max(Meta_Hi)
				drop Meta_Hi
				rename max_MHi Meta_Hi
				
				
				egen max_MBi =max(Meta_Bi)
				drop Meta_Bi
				rename max_MBi Meta_Bi
				
				scalar define _Meta_Hi = Meta_Hi[1]
				scalar define _Meta_Bi = Meta_Bi[1]
				
				if Meta_Hi == 0 & Meta_Bi == 0{
				      noisily display as text "Doubld-zero-events studies totally do not impact the results:"
					}	
				if (Meta_Hi > 0 & Meta_Hi < 3) | (Meta_Bi > 0 & Meta_Bi < 3){
				      noisily display as text "Doubld-zero-events studies may have some impact on the results:" 
					}
				if (Meta_Hi >= 3) | (Meta_Bi >= 3){
				      noisily display as text "Doubld-zero-events studies may have little impact on the results:"
					}			
									
						
						

		}
	
		
}			
*


*Binary data input + OR selected + onestage
if  "`1'" != "" & "`2'" != "" & "`3'" != "" & "`4'" != "" & "`or'" != "" & "`rr'" == "" & "`onestage'" != "" & "`twostage'" == "" & "`ap'" != ""{
	
	display ""
	display as text "Note: One-stage method will take more time..."
	display as text "Note: Beta-binomial model, Effect size = OR"
 
	
	quietly{ 
			gen __a = `1'
			gen __b = `2'
			gen __c = `3'
			gen __d = `4'
			    
			gen ___a = __a
			gen ___c = __c
			    
				gen study_id = _n
				gen _id = _n
				gen __zero = 1 if __a==0 | __c==0
				
				egen sumzero=sum(__zero)
				
				if sumzero == 0 {
				          display as error "No zero-events studies"
	                      exit 198
				}
				else {
				
				gen __zero_single = 1 if (__a==0 & __c !=0) | (__a !=0 & __c ==0)
				gen  __zero_double = 1 if __a==0 & __c ==0 
				sort __zero
				gen  __zero_num = _n if __zero == 1
				sort __zero_single
				gen  __zero_single_num = _n if __zero_single==1
				sort __zero_double	
				gen __zero_double_t_sample = __b  if __zero_double !=.
				gen __zero_double_c_sample = __d  if __zero_double !=.			
				gsort __zero_double_t_sample
				gen __zero_double_num = _n if __zero_double==1
				gsort -__zero_double_num
					if __zero_double_num[1]!=.{
								noisily display as text "Note: Number of double-arm-zero-events studies = " as result __zero_double_num[1]
					}	
					}
				
				   gen __a_bot = __a
				  gen __b_bot = __b
				  gen __c_bot = __c
				  gen __d_bot = __d
				  
				  replace __a_bot = 1 if __zero_double==1
				  replace __c_bot = 1 if __zero_double==1
				  admetan __a_bot __b_bot __c_bot __d_bot, peto or nograph
				  gen eff_bot = _ES*_WT
				  replace eff_bot =. if __zero_double !=1
				  egen max_eff_bot =max(eff_bot) 
				  drop if eff_bot != max_eff_bot & __zero_double==1
				  drop __a_bot __b_bot  __c_bot __d_bot _ES _seES _LCI _UCI _WT _NN _rsample
				  
				  egen max_zero_double = max(__zero_double_num)
				  local i  = max_zero_double
		 
				   *gen zerostudy=.
				   *gen iter =.
				   *gen events=.
				   *gen loop =.
				   
				   gen events_total = __a + __c
				   replace events_total = 1 if events_total !=0
				   sort _id
				   drop _id
				   gen _id=_n
				   egen study_num = max(_id)
				   gsort -__zero_double_num
			
			    replace study_id = _n
			    keep _id study_num __a __c __b __d ___a  ___c  events_total study_id sumzero max_zero_double
		        reshape wide __a __c __b __d ___a   ___c, i(_id) j(study_id)
                collapse __a* __b* __c* __d* ___a*   ___c*  study_num max_zero_double, by(sumzero)
	   
				
				gen combinations=4*max_zero_double
				

	       ***Combinations
	       local K `i'
           local N 4 
		   local No = `N'*`K' + 1
           
		   set obs `No'
           generate long count = _n-1
		   generate _study = count
           
		   
		   
		   replace sumzero = sumzero[_n - 1] if missing(sumzero)
		   replace max_zero_double = max_zero_double[_n - 1] if missing(max_zero_double)
		   replace study_num = study_num[_n - 1] if missing(study_num)
		   replace __a1=_study  
		   replace ___c1=_study
		   
		   local K = study_num
		   forvalues k = 2(1)`K' {
		   replace __a`k' = __a`k'[_n-1] if missing(__a`k')
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   replace ___c`k' = ___c`k'[_n-1] if missing(___c`k')
		   }
		   *
		   forvalues k = 1(1)`K' {
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   }
		   *
			
			
			gen _rank = _n
			reshape long __a __b __c __d  ___a  ___c , i(_rank) j(study_id)
			
			
			

			drop combinations
			rename _rank comb
			

			
			gen __ma_ln_or_h =. 
			gen __ma_se_lnor_h =.
			gen __ma_or_h =.
	        gen __ma_lci_or_h =.
	        gen __ma_uci_or_h =.
			gen __p_h =.
			gen __ps_h=.
			
			gen __ma_ln_or_b =. 
			gen __ma_se_lnor_b =.
			gen __ma_or_b =.
	        gen __ma_lci_or_b =.
	        gen __ma_uci_or_b =.
			gen __p_b =.
			gen __ps_b=.
			
			
			
			gen r_h1 = __a
	        gen r_h2 = __c
	        gen n_h1 = __a + __b
	        gen n_h2 = __c + __d
	
	        bysort comb: egen total_r_h1 = sum(r_h1)
	        bysort comb: egen total_r_h2 = sum(r_h2)
			
			gen r_b1 = ___a
	        gen r_b2 = ___c
	        gen n_b1 = ___a + __b
	        gen n_b2 = ___c + __d
			gen _events = ___a + ___c
			replace _events = 1 if _events !=0
	
	        bysort comb: egen total_r_b1 = sum(r_b1)
	        bysort comb: egen total_r_b2 = sum(r_b2)
			
	
	       *prevent potential convergent problem due to rare events
	       gen MA_CZ=0
	       replace MA_CZ = 1 if total_r_h1 == 0 | total_r_h2 == 0 | total_r_b1 ==0 | total_r_b2 ==0
           
		   if MA_CZ == 1 {
					  display as error "Total events in one of the arm or both arms are zero, one-stage method is not applicable"
	                  exit 198
					}	
	       
		   if MA_CZ !=1 {
	           
			   gen id =_n
			   qui reshape long n_h r_h n_b r_b, i(id) j(group)
               replace group =-group+2
	
			*Meta-analysis for all combinations of harms
			egen max_comb = max(comb)
			replace max_comb =__b[1] if max_comb > __b[1]
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
				
				qui betabin r_h group study_id if comb ==`meta' & _events !=0, n(n_h) link(logit) iter(20)
			    replace __ma_ln_or_h = _b[group] if comb == `meta'
			    replace __ma_se_lnor_h = _se[group] if comb == `meta'
			 	 }
				
				replace __ma_or_h = exp(__ma_ln_or_h)
				replace __ma_lci_or_h=exp(__ma_ln_or_h-(invnormal(0.975)*__ma_se_lnor_h)) 
				replace __ma_uci_or_h=exp(__ma_ln_or_h+(invnormal(0.975)*__ma_se_lnor_h)) 
			    replace __p_h=2*(1-normal(abs(__ma_ln_or_h/__ma_se_lnor_h))) 
				replace __ps_h = 1 if __p_h < 0.05 
			    replace __ps_h = -1 if __p_h > 0.05 
				sort comb
				
				
					
				
			*Meta-analysis for all combinations of benifits
			replace max_comb =__d[1] if max_comb > __d[1]
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
				
				qui qui betabin r_h group study_id comb ==`meta' & _events !=0, n(n_b) link(logit) iter(20)
			    replace __ma_ln_or_b = _b[group] if comb == `meta'
			    replace __ma_se_lnor_b = _se[group] if comb == `meta'
			 	 }
				
				replace __ma_or_b = exp(__ma_ln_or_b)
				replace __ma_lci_or_b=exp(__ma_ln_or_b-(invnormal(0.975)*__ma_se_lnor_b)) 
				replace __ma_uci_or_b=exp(__ma_ln_or_b+(invnormal(0.975)*__ma_se_lnor_b)) 
			    replace __p_b=2*(1-normal(abs(__ma_ln_or_b/__ma_se_lnor_b))) 
				replace __ps_b = 1 if __p_b < 0.05 
			    replace __ps_b = -1 if __p_b > 0.05 
				sort comb	
			    }
				
				qui reshape wide r_h n_h r_b n_b, i(id) j(group)
				gen events = __a + __c
			    
				   local t = sumzero
				   forvalues t = 1(1)`t' {
				      gen control_arm`t' = __d[`t'] if events[`t'] ==0
					  gen treat_arm`t' = __b[`t'] if events[`t'] ==0 
					  }
					  
	            egen max_arm = rowmax(treat_arm*)
	            egen max_arm_c = rowmax(control_arm*)
		
			    drop max_zero_double
				keep if study_id == 1
				drop study_id
			    drop study_num
				
		
				gen ratio_dir_h = __ma_ln_or_h/__ma_ln_or_h[1]
				gen ratio_sig_h = __ps_h/__ps_h[1]
				
				gen d_dir_h = 0 if ratio_dir_h > 0
				replace d_dir_h = 1 if ratio_dir_h < 0
				gen d_sig_h = 0 if ratio_sig_h > 0
				replace d_sig_h = 1 if ratio_sig_h < 0
				gen direction_h = d_sig_h + d_dir_h	
				
				
				gen ratio_dir_b = __ma_ln_or_b/__ma_ln_or_b[1]
				gen ratio_sig_b = __ps_b/__ps_b[1]
				
				gen d_dir_b = 0 if ratio_dir_b > 0
				replace d_dir_b = 1 if ratio_dir_b < 0
				gen d_sig_b = 0 if ratio_sig_b > 0
				replace d_sig_b = 1 if ratio_sig_b < 0
				gen direction_b = d_sig_b + d_dir_b	
				
				
				***max and min effects (for graph)
				egen min_lci_h = min(__ma_lci_or_h)
                egen min_uci_h = max(__ma_uci_or_h)
                egen min_lci_b = min(__ma_lci_or_b)
                egen min_uci_b = max(__ma_uci_or_b)
				
				***HI index
		        gen Hi = comb
				sort Hi
				gen direction_h_r = _n if direction_h ==1
				egen Meta_Hi = min(cond(direction_h_r,Hi,.))  if direction_h_r !=.
				replace Meta_Hi = 0 if Meta_Hi ==.
				
				
				
				***BI index
		        gen Bi = comb
				sort Bi
				gen direction_b_r = _n if direction_b ==1
				egen Meta_Bi = min(cond(direction_b_r,Bi,.)) if direction_b_r !=.
				replace Meta_Bi = 0 if Meta_Bi ==.
				
			
				***Rename
				egen max_MHi =max(Meta_Hi)
				drop Meta_Hi
				rename max_MHi Meta_Hi
				
				
				egen max_MBi =max(Meta_Bi)
				drop Meta_Bi
				rename max_MBi Meta_Bi
				
				scalar define _Meta_Hi = Meta_Hi[1]
				scalar define _Meta_Bi = Meta_Bi[1]
				
				if Meta_Hi == 0 & Meta_Bi == 0{
				      noisily display as text "Doubld-zero-events studies totally do not impact the results:"
					}	
				if (Meta_Hi > 0 & Meta_Hi < 3) | (Meta_Bi > 0 & Meta_Bi < 3){
				      noisily display as text "Doubld-zero-events studies may have some impact on the results:" 
					}
				if (Meta_Hi >= 3) | (Meta_Bi >= 3){
				      noisily display as text "Doubld-zero-events studies may have little impact on the results:"
					}				

		}
		
}			
*




*Binary data input + RR selected
if  "`1'" != "" & "`2'" != "" & "`3'" != "" & "`4'" != "" & "`or'" == "" & "`rr'" != "" & "`onestage'" == "" & "`twostage'" == "" & "`ap'" != ""{
	
	display ""
	display as text "Note: two-stage MH method, Effect size = RR"
      
	  quietly{ 
			gen __a = `1'
			gen __b = `2'
			gen __c = `3'
			gen __d = `4'
	
	        gen ___a = __a
			gen ___c = __c
			    
				gen study_id = _n
				gen _id = _n
				gen __zero = 1 if __a==0 | __c==0
				
				egen sumzero=sum(__zero)
				
				if sumzero == 0 {
				          display as error "No zero-events studies"
	                      exit 198
				}
				else {
				
				gen __zero_single = 1 if (__a==0 & __c !=0) | (__a !=0 & __c ==0)
				gen  __zero_double = 1 if __a==0 & __c ==0 
				sort __zero
				gen  __zero_num = _n if __zero == 1
				sort __zero_single
				gen  __zero_single_num = _n if __zero_single==1
				sort __zero_double	
				gen __zero_double_t_sample = __b  if __zero_double !=.
				gen __zero_double_c_sample = __d  if __zero_double !=.			
				gsort __zero_double_t_sample
				gen __zero_double_num = _n if __zero_double==1
				gsort -__zero_double_num
					if __zero_double_num[1]!=.{
								noisily display as text "Note: Number of double-arm-zero-events studies = " as result __zero_double_num[1]
					}	
					}
				
				  gen __a_bot = __a
				  gen __b_bot = __b
				  gen __c_bot = __c
				  gen __d_bot = __d
				  
				  replace __a_bot = 1 if __zero_double==1
				  replace __c_bot = 1 if __zero_double==1
				  admetan __a_bot __b_bot __c_bot __d_bot, mh rr nograph
				  gen eff_bot = _ES*_WT
				  replace eff_bot =. if __zero_double !=1
				  egen max_eff_bot =max(eff_bot) 
				  drop if eff_bot != max_eff_bot & __zero_double==1
				  drop __a_bot __b_bot  __c_bot __d_bot _ES _seES _LCI _UCI _WT _NN _rsample
				  
				  egen max_zero_double = max(__zero_double_num)
				  local i  = max_zero_double
		 
				   *gen zerostudy=.
				   *gen iter =.
				   *gen events=.
				   *gen loop =.
				   
				   gen events_total = __a + __c
				   replace events_total = 1 if events_total !=0
				   sort _id
				   drop _id
				   gen _id=_n
				   egen study_num = max(_id)
				   gsort -__zero_double_num
			
			    replace study_id = _n
			    keep _id study_num __a __c __b __d ___a  ___c  events_total study_id sumzero max_zero_double
		        reshape wide __a __c __b __d ___a   ___c, i(_id) j(study_id)
                collapse __a* __b* __c* __d* ___a*   ___c*  study_num max_zero_double, by(sumzero)
	   
				
				gen combinations=4*max_zero_double
				

	       ***Combinations
	       local K `i'
           local N 4 
		   local No = `N'*`K' + 1
           
		   set obs `No'
           generate long count = _n-1
		   generate _study = count
           
		   
		   
		   replace sumzero = sumzero[_n - 1] if missing(sumzero)
		   replace max_zero_double = max_zero_double[_n - 1] if missing(max_zero_double)
		   replace study_num = study_num[_n - 1] if missing(study_num)
		   replace __a1=_study  
		   replace ___c1=_study
		   
		   local K = study_num
		   forvalues k = 2(1)`K' {
		   replace __a`k' = __a`k'[_n-1] if missing(__a`k')
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   replace ___c`k' = ___c`k'[_n-1] if missing(___c`k')
		   }
		   *
		   forvalues k = 1(1)`K' {
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   }
		   *
			
			
			gen _rank = _n
			reshape long __a __b __c __d  ___a  ___c , i(_rank) j(study_id)
			
			
			

			drop combinations
			rename _rank comb
			
			gen __ma_ln_rr_h =. 
			gen __ma_se_lnrr_h =.
			gen __ma_rr_h =.
	        gen __ma_lci_rr_h =.
	        gen __ma_uci_rr_h =.
			gen __p_h =.
			gen __ps_h=.
			
			
			*Meta-analysis for all combinations for harms
			egen max_comb = max(comb)
			replace max_comb = __b[1] if max_comb > __b[1]
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan __a __b __c __d if comb == `meta', rr mh nograph
			    replace __ma_ln_rr_h = r(eff) if comb == `meta'
			    replace __ma_se_lnrr_h = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_rr_h = exp(__ma_ln_rr_h) 
				replace __ma_lci_rr_h=exp(__ma_ln_rr_h-(invnormal(0.975)*__ma_se_lnrr_h)) 
				replace __ma_uci_rr_h=exp(__ma_ln_rr_h+(invnormal(0.975)*__ma_se_lnrr_h)) 
			    replace __p_h=2*(1-normal(abs(__ma_ln_rr_h/__ma_se_lnrr_h))) 
				replace __ps_h = 1 if __p_h < 0.05 
			    replace __ps_h = -1 if __p_h > 0.05 
				gen events = __a + __c
			    
				local t = sumzero
				   forvalues t = 1(1)`t' {
				      gen treat_arm`t' = __b[`t'] if events[`t'] ==0 
					  }
	            egen max_arm = rowmax(treat_arm*)
					
		    
			*Meta-analysis for all combinations for benifits
			
			
			gen __ma_ln_rr_b =. 
			gen __ma_se_lnrr_b =.
			gen __ma_rr_b =.
	        gen __ma_lci_rr_b =.
	        gen __ma_uci_rr_b =.
			gen __p_b =.
			gen __ps_b=.
			
			
			*Meta-analysis
			replace max_comb = __d[1] if max_comb > __d[1]
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan ___a __b ___c __d if comb == `meta', rr mh nograph
			    replace __ma_ln_rr_b = r(eff) if comb == `meta'
			    replace __ma_se_lnrr_b = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_rr_b = exp(__ma_ln_rr_b)
				replace __ma_lci_rr_b=exp(__ma_ln_rr_b-(invnormal(0.975)*__ma_se_lnrr_b)) 
				replace __ma_uci_rr_b=exp(__ma_ln_rr_b+(invnormal(0.975)*__ma_se_lnrr_b)) 
			    replace __p_b=2*(1-normal(abs(__ma_ln_rr_b/__ma_se_lnrr_b))) 
				replace __ps_b = 1 if __p_b < 0.05 
			    replace __ps_b = -1 if __p_b > 0.05 
			   
				local t = sumzero
				   forvalues t = 1(1)`t' {
				      gen control_arm`t' = __d[`t'] if events[`t'] ==0 
					  }
	            egen max_arm_c = rowmax(control_arm*)
		
			    drop  _ES _seES _LCI _UCI _WT _rsample max_zero_double 
			    keep if study_id == 1
				drop study_id
			    drop study_num
				drop if __ma_rr_h ==. & __ma_rr_b ==.
				

				gen ratio_dir_h = __ma_ln_rr_h/__ma_ln_rr_h[1]
				gen ratio_sig_h = __ps_h/__ps_h[1]
				
				gen d_dir_h = 0 if ratio_dir_h > 0
				replace d_dir_h = 1 if ratio_dir_h < 0
				gen d_sig_h = 0 if ratio_sig_h > 0
				replace d_sig_h = 1 if ratio_sig_h < 0
				gen direction_h = d_sig_h + d_dir_h	
				
				
				gen ratio_dir_b = __ma_ln_rr_b/__ma_ln_rr_b[1]
				gen ratio_sig_b = __ps_b/__ps_b[1]
				
				gen d_dir_b = 0 if ratio_dir_b > 0
				replace d_dir_b = 1 if ratio_dir_b < 0
				gen d_sig_b = 0 if ratio_sig_b > 0
				replace d_sig_b = 1 if ratio_sig_b < 0
				gen direction_b = d_sig_b + d_dir_b	
				
				
				***max and min effects (for graph)
				egen min_lci_h = min(__ma_lci_rr_h)
                egen min_uci_h = max(__ma_uci_rr_h)
                egen min_lci_b = min(__ma_lci_rr_b)
                egen min_uci_b = max(__ma_uci_rr_b)
				
				***HI index
		        gen Hi = comb
				sort Hi
				gen direction_h_r = _n if direction_h ==1
				egen Meta_Hi = min(cond(direction_h_r,Hi,.))  if direction_h_r !=.
				replace Meta_Hi = 0 if Meta_Hi ==.
				
				
				
				***BI index
		        gen Bi = comb
				sort Bi
				gen direction_b_r = _n if direction_b ==1
				egen Meta_Bi = min(cond(direction_b_r,Bi,.)) if direction_b_r !=.
				replace Meta_Bi = 0 if Meta_Bi ==.
				
			
				***Rename
				egen max_MHi =max(Meta_Hi)
				drop Meta_Hi
				rename max_MHi Meta_Hi
				
				
				egen max_MBi =max(Meta_Bi)
				drop Meta_Bi
				rename max_MBi Meta_Bi
				
				scalar define _Meta_Hi = Meta_Hi[1]
				scalar define _Meta_Bi = Meta_Bi[1]
				
				if Meta_Hi == 0 & Meta_Bi == 0{
				      noisily display as text "Doubld-zero-events studies totally do not impact the results:"
					}	
				if (Meta_Hi > 0 & Meta_Hi < 3) | (Meta_Bi > 0 & Meta_Bi < 3){
				      noisily display as text "Doubld-zero-events studies may have some impact on the results:" 
					}
				if (Meta_Hi >= 3) | (Meta_Bi >= 3){
				      noisily display as text "Doubld-zero-events studies may have little impact on the results:"
					}	

	}
}			
*



*Binary data input + RR selected + twostage selected
if "`1'" != "" & "`2'" != "" & "`3'" != "" & "`4'" != "" & "`or'" == "" & "`rr'" != "" & "`onestage'" == "" & "`twostage'" != "" & "`ap'" != ""{
	
	display ""
	display as text "Note: two-stage MH method, Effect size = RR"

		quietly{ 
			gen __a = `1'
			gen __b = `2'
			gen __c = `3'
			gen __d = `4'
	
	        gen ___a = __a
			gen ___c = __c
			    
				gen study_id = _n
				gen _id = _n
				gen __zero = 1 if __a==0 | __c==0
				
				egen sumzero=sum(__zero)
				
				if sumzero == 0 {
				          display as error "No zero-events studies"
	                      exit 198
				}
				else {
				
				gen __zero_single = 1 if (__a==0 & __c !=0) | (__a !=0 & __c ==0)
				gen  __zero_double = 1 if __a==0 & __c ==0 
				sort __zero
				gen  __zero_num = _n if __zero == 1
				sort __zero_single
				gen  __zero_single_num = _n if __zero_single==1
				sort __zero_double	
				gen __zero_double_t_sample = __b  if __zero_double !=.
				gen __zero_double_c_sample = __d  if __zero_double !=.			
				gsort __zero_double_t_sample
				gen __zero_double_num = _n if __zero_double==1
				gsort -__zero_double_num
					if __zero_double_num[1]!=.{
								noisily display as text "Note: Number of double-arm-zero-events studies = " as result __zero_double_num[1]
					}	
					}
				
				  gen __a_bot = __a
				  gen __b_bot = __b
				  gen __c_bot = __c
				  gen __d_bot = __d
				  
				  replace __a_bot = 1 if __zero_double==1
				  replace __c_bot = 1 if __zero_double==1
				  admetan __a_bot __b_bot __c_bot __d_bot, mh rr nograph
				  gen eff_bot = _ES*_WT
				  replace eff_bot =. if __zero_double !=1
				  egen max_eff_bot =max(eff_bot) 
				  drop if eff_bot != max_eff_bot & __zero_double==1
				  drop __a_bot __b_bot  __c_bot __d_bot _ES _seES _LCI _UCI _WT _NN _rsample
				  
				  egen max_zero_double = max(__zero_double_num)
				  local i  = max_zero_double
		 
				   *gen zerostudy=.
				   *gen iter =.
				   *gen events=.
				   *gen loop =.
				   
				   gen events_total = __a + __c
				   replace events_total = 1 if events_total !=0
				   sort _id
				   drop _id
				   gen _id=_n
				   egen study_num = max(_id)
				   gsort -__zero_double_num
			
			    replace study_id = _n
			    keep _id study_num __a __c __b __d ___a  ___c  events_total study_id sumzero max_zero_double
		        reshape wide __a __c __b __d ___a   ___c, i(_id) j(study_id)
                collapse __a* __b* __c* __d* ___a*   ___c*  study_num max_zero_double, by(sumzero)
	   
				
				gen combinations=4*max_zero_double
				

	       ***Combinations
	       local K `i'
           local N 4 
		   local No = `N'*`K' + 1
           
		   set obs `No'
           generate long count = _n-1
		   generate _study = count
           
		   
		   
		   replace sumzero = sumzero[_n - 1] if missing(sumzero)
		   replace max_zero_double = max_zero_double[_n - 1] if missing(max_zero_double)
		   replace study_num = study_num[_n - 1] if missing(study_num)
		   replace __a1=_study  
		   replace ___c1=_study
		   
		   local K = study_num
		   forvalues k = 2(1)`K' {
		   replace __a`k' = __a`k'[_n-1] if missing(__a`k')
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   replace ___c`k' = ___c`k'[_n-1] if missing(___c`k')
		   }
		   *
		   forvalues k = 1(1)`K' {
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   }
		   *
			
			
			gen _rank = _n
			reshape long __a __b __c __d  ___a  ___c , i(_rank) j(study_id)
			
			
			

			drop combinations
			rename _rank comb
			
			gen __ma_ln_rr_h =. 
			gen __ma_se_lnrr_h =.
			gen __ma_rr_h =.
	        gen __ma_lci_rr_h =.
	        gen __ma_uci_rr_h =.
			gen __p_h =.
			gen __ps_h=.
			
			
			*Meta-analysis for all combinations for harms
			egen max_comb = max(comb)
			replace max_comb = __b[1] if max_comb > __b[1]
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan __a __b __c __d if comb == `meta', rr mh nograph
			    replace __ma_ln_rr_h = r(eff) if comb == `meta'
			    replace __ma_se_lnrr_h = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_rr_h = exp(__ma_ln_rr_h) 
				replace __ma_lci_rr_h=exp(__ma_ln_rr_h-(invnormal(0.975)*__ma_se_lnrr_h)) 
				replace __ma_uci_rr_h=exp(__ma_ln_rr_h+(invnormal(0.975)*__ma_se_lnrr_h)) 
			    replace __p_h=2*(1-normal(abs(__ma_ln_rr_h/__ma_se_lnrr_h))) 
				replace __ps_h = 1 if __p_h < 0.05 
			    replace __ps_h = -1 if __p_h > 0.05 
				gen events = __a + __c
			    
				local t = sumzero
				   forvalues t = 1(1)`t' {
				      gen treat_arm`t' = __b[`t'] if events[`t'] ==0 
					  }
	            egen max_arm = rowmax(treat_arm*)
					
		    
			*Meta-analysis for all combinations for benifits
			
			
			gen __ma_ln_rr_b =. 
			gen __ma_se_lnrr_b =.
			gen __ma_rr_b =.
	        gen __ma_lci_rr_b =.
	        gen __ma_uci_rr_b =.
			gen __p_b =.
			gen __ps_b=.
			
			
			*Meta-analysis
			replace max_comb = __d[1] if max_comb > __d[1]
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
			
			    qui admetan ___a __b ___c __d if comb == `meta', rr mh nograph
			    replace __ma_ln_rr_b = r(eff) if comb == `meta'
			    replace __ma_se_lnrr_b = r(se_eff) if comb == `meta'
			 	 }
				replace __ma_rr_b = exp(__ma_ln_rr_b)
				replace __ma_lci_rr_b=exp(__ma_ln_rr_b-(invnormal(0.975)*__ma_se_lnrr_b)) 
				replace __ma_uci_rr_b=exp(__ma_ln_rr_b+(invnormal(0.975)*__ma_se_lnrr_b)) 
			    replace __p_b=2*(1-normal(abs(__ma_ln_rr_b/__ma_se_lnrr_b))) 
				replace __ps_b = 1 if __p_b < 0.05 
			    replace __ps_b = -1 if __p_b > 0.05 
			   
				local t = sumzero
				   forvalues t = 1(1)`t' {
				      gen control_arm`t' = __d[`t'] if events[`t'] ==0 
					  }
	            egen max_arm_c = rowmax(control_arm*)
		
			    drop  _ES _seES _LCI _UCI _WT _rsample max_zero_double 
			    keep if study_id == 1
				drop study_id
			    drop study_num
				drop if __ma_rr_h ==. & __ma_rr_b ==.
				

				gen ratio_dir_h = __ma_ln_rr_h/__ma_ln_rr_h[1]
				gen ratio_sig_h = __ps_h/__ps_h[1]
				
				gen d_dir_h = 0 if ratio_dir_h > 0
				replace d_dir_h = 1 if ratio_dir_h < 0
				gen d_sig_h = 0 if ratio_sig_h > 0
				replace d_sig_h = 1 if ratio_sig_h < 0
				gen direction_h = d_sig_h + d_dir_h	
				
				
				gen ratio_dir_b = __ma_ln_rr_b/__ma_ln_rr_b[1]
				gen ratio_sig_b = __ps_b/__ps_b[1]
				
				gen d_dir_b = 0 if ratio_dir_b > 0
				replace d_dir_b = 1 if ratio_dir_b < 0
				gen d_sig_b = 0 if ratio_sig_b > 0
				replace d_sig_b = 1 if ratio_sig_b < 0
				gen direction_b = d_sig_b + d_dir_b	
				
				
				***max and min effects (for graph)
				egen min_lci_h = min(__ma_lci_rr_h)
                egen min_uci_h = max(__ma_uci_rr_h)
                egen min_lci_b = min(__ma_lci_rr_b)
                egen min_uci_b = max(__ma_uci_rr_b)
				
				***HI index
		        gen Hi = comb
				sort Hi
				gen direction_h_r = _n if direction_h ==1
				egen Meta_Hi = min(cond(direction_h_r,Hi,.))  if direction_h_r !=.
				replace Meta_Hi = 0 if Meta_Hi ==.
				
				
				
				***BI index
		        gen Bi = comb
				sort Bi
				gen direction_b_r = _n if direction_b ==1
				egen Meta_Bi = min(cond(direction_b_r,Bi,.)) if direction_b_r !=.
				replace Meta_Bi = 0 if Meta_Bi ==.
				
			
				***Rename
				egen max_MHi =max(Meta_Hi)
				drop Meta_Hi
				rename max_MHi Meta_Hi
				
				
				egen max_MBi =max(Meta_Bi)
				drop Meta_Bi
				rename max_MBi Meta_Bi
				
				scalar define _Meta_Hi = Meta_Hi[1]
				scalar define _Meta_Bi = Meta_Bi[1]
				
				if Meta_Hi == 0 & Meta_Bi == 0{
				      noisily display as text "Doubld-zero-events studies totally do not impact the results:"
					}	
				if (Meta_Hi > 0 & Meta_Hi < 3) | (Meta_Bi > 0 & Meta_Bi < 3){
				      noisily display as text "Doubld-zero-events studies may have some impact on the results:" 
					}
				if (Meta_Hi >= 3) | (Meta_Bi >= 3){
				      noisily display as text "Doubld-zero-events studies may have little impact on the results:"
					}				
	}
}			
*



*Binary data input + RR selected + onestage selected
if "`1'" != "" & "`2'" != "" & "`3'" != "" & "`4'" != "" & "`or'" == "" & "`rr'" != "" & "`onestage'" != "" & "`twostage'" == "" & "`ap'" != ""{
	display ""
	display as text "Note: One-stage method will take more time..."
	display as text "Note: Beta-binomial model, Effect size = RR"
    
	
	quietly{ 
			gen __a = `1'
			gen __b = `2'
			gen __c = `3'
			gen __d = `4'
			    
			gen ___a = __a
			gen ___c = __c
			    
				gen study_id = _n
				gen _id = _n
				gen __zero = 1 if __a==0 | __c==0
				
				egen sumzero=sum(__zero)
				
				if sumzero == 0 {
				          display as error "No zero-events studies"
	                      exit 198
				}
				else {
				
				gen __zero_single = 1 if (__a==0 & __c !=0) | (__a !=0 & __c ==0)
				gen  __zero_double = 1 if __a==0 & __c ==0 
				sort __zero
				gen  __zero_num = _n if __zero == 1
				sort __zero_single
				gen  __zero_single_num = _n if __zero_single==1
				sort __zero_double	
				gen __zero_double_t_sample = __b  if __zero_double !=.
				gen __zero_double_c_sample = __d  if __zero_double !=.			
				gsort __zero_double_t_sample
				gen __zero_double_num = _n if __zero_double==1
				gsort -__zero_double_num
					if __zero_double_num[1]!=.{
								noisily display as text "Note: Number of double-arm-zero-events studies = " as result __zero_double_num[1]
					}	
					}
				
				  gen __a_bot = __a
				  gen __b_bot = __b
				  gen __c_bot = __c
				  gen __d_bot = __d
				  
				  replace __a_bot = 1 if __zero_double==1
				  replace __c_bot = 1 if __zero_double==1
				  admetan __a_bot __b_bot __c_bot __d_bot, mh rr nograph
				  gen eff_bot = _ES*_WT
				  replace eff_bot =. if __zero_double !=1
				  egen max_eff_bot =max(eff_bot) 
				  drop if eff_bot != max_eff_bot & __zero_double==1
				  drop __a_bot __b_bot  __c_bot __d_bot _ES _seES _LCI _UCI _WT _NN _rsample
				  
				  egen max_zero_double = max(__zero_double_num)
				  local i  = max_zero_double
		 
				   *gen zerostudy=.
				   *gen iter =.
				   *gen events=.
				   *gen loop =.
				   
				   gen events_total = __a + __c
				   replace events_total = 1 if events_total !=0
				   sort _id
				   drop _id
				   gen _id=_n
				   egen study_num = max(_id)
				   gsort -__zero_double_num
			
			    replace study_id = _n
			    keep _id study_num __a __c __b __d ___a  ___c  events_total study_id sumzero max_zero_double
		        reshape wide __a __c __b __d ___a   ___c, i(_id) j(study_id)
                collapse __a* __b* __c* __d* ___a*   ___c*  study_num max_zero_double, by(sumzero)
	   
				
				gen combinations=4*max_zero_double
				

	       ***Combinations
	       local K `i'
           local N 4 
		   local No = `N'*`K' + 1
           
		   set obs `No'
           generate long count = _n-1
		   generate _study = count
           
		   
		   
		   replace sumzero = sumzero[_n - 1] if missing(sumzero)
		   replace max_zero_double = max_zero_double[_n - 1] if missing(max_zero_double)
		   replace study_num = study_num[_n - 1] if missing(study_num)
		   replace __a1=_study  
		   replace ___c1=_study
		   
		   local K = study_num
		   forvalues k = 2(1)`K' {
		   replace __a`k' = __a`k'[_n-1] if missing(__a`k')
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   replace ___c`k' = ___c`k'[_n-1] if missing(___c`k')
		   }
		   *
		   forvalues k = 1(1)`K' {
		   replace __b`k' = __b`k'[_n-1] if missing(__b`k')
		   replace __c`k' = __c`k'[_n-1] if missing(__c`k')
		   replace __d`k' = __d`k'[_n-1] if missing(__d`k')
		   replace ___a`k' = ___a`k'[_n-1] if missing(___a`k')
		   }
		   *
			
			
			gen _rank = _n
			reshape long __a __b __c __d  ___a  ___c , i(_rank) j(study_id)
			
			
			

			drop combinations
			rename _rank comb
			

			
			gen __ma_ln_rr_h =. 
			gen __ma_se_lnrr_h =.
			gen __ma_rr_h =.
	        gen __ma_lci_rr_h =.
	        gen __ma_uci_rr_h =.
			gen __p_h =.
			gen __ps_h=.
			
			gen __ma_ln_rr_b =. 
			gen __ma_se_lnrr_b =.
			gen __ma_rr_b =.
	        gen __ma_lci_rr_b =.
	        gen __ma_uci_rr_b =.
			gen __p_b =.
			gen __ps_b=.
			
			
			
			gen r_h1 = __a
	        gen r_h2 = __c
	        gen n_h1 = __a + __b
	        gen n_h2 = __c + __d
	
	        bysort comb: egen total_r_h1 = sum(r_h1)
	        bysort comb: egen total_r_h2 = sum(r_h2)
			
			gen r_b1 = ___a
	        gen r_b2 = ___c
	        gen n_b1 = ___a + __b
	        gen n_b2 = ___c + __d
			gen _events = ___a + ___c
			replace _events = 1 if _events !=0
	
	        bysort comb: egen total_r_b1 = sum(r_b1)
	        bysort comb: egen total_r_b2 = sum(r_b2)
			
	
	       *prevent potential convergent problem due to rare events
	       gen MA_CZ=0
	       replace MA_CZ = 1 if total_r_h1 == 0 | total_r_h2 == 0 | total_r_b1 ==0 | total_r_b2 ==0
           
		   if MA_CZ == 1 {
					  display as error "Total events in one of the arm or both arms are zero, one-stage method is not applicable"
	                  exit 198
					}	
	       
		   if MA_CZ !=1 {
	           
			   gen id =_n
			   qui reshape long n_h r_h n_b r_b, i(id) j(group)
               replace group =-group+2
	
			*Meta-analysis for all combinations of harms
			egen max_comb = max(comb)
			replace max_comb =__b[1] if max_comb > __b[1]
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
				
				qui betabin r_h group study_id if comb ==`meta' & _events !=0, n(n_h) link(logit) iter(20) 
			    replace __ma_ln_rr_h = _b[group] if comb == `meta'
			    replace __ma_se_lnrr_h = _se[group] if comb == `meta'
			 	 }
				
				replace __ma_rr_h = exp(__ma_ln_rr_h)
				replace __ma_lci_rr_h=exp(__ma_ln_rr_h-(invnormal(0.975)*__ma_se_lnrr_h)) 
				replace __ma_uci_rr_h=exp(__ma_ln_rr_h+(invnormal(0.975)*__ma_se_lnrr_h)) 
			    replace __p_h=2*(1-normal(abs(__ma_ln_rr_h/__ma_se_lnrr_h))) 
				replace __ps_h = 1 if __p_h < 0.05 
			    replace __ps_h = -1 if __p_h > 0.05 
				sort comb
				
				
					
				
			*Meta-analysis for all combinations of benifits
			replace max_comb =__d[1] if max_comb > __d[1]
			local meta = max_comb
			forvalues meta = 1(1)`meta' {
				
				qui betabin r_b group study_id if comb ==`meta' & _events !=0, n(n_b) link(logit) iter(20) 
			    replace __ma_ln_rr_b = _b[group] if comb == `meta'
			    replace __ma_se_lnrr_b = _se[group] if comb == `meta'
			 	 }
				
				replace __ma_rr_b = exp(__ma_ln_rr_b)
				replace __ma_lci_rr_b=exp(__ma_ln_rr_b-(invnormal(0.975)*__ma_se_lnrr_b)) 
				replace __ma_uci_rr_b=exp(__ma_ln_rr_b+(invnormal(0.975)*__ma_se_lnrr_b)) 
			    replace __p_b=2*(1-normal(abs(__ma_ln_rr_b/__ma_se_lnrr_b))) 
				replace __ps_b = 1 if __p_b < 0.05 
			    replace __ps_b = -1 if __p_b > 0.05 
				sort comb	
			    }
				
				qui reshape wide r_h n_h r_b n_b, i(id) j(group)
				gen events = __a + __c
			    
				   local t = sumzero
				   forvalues t = 1(1)`t' {
				      gen control_arm`t' = __d[`t'] if events[`t'] ==0
					  gen treat_arm`t' = __b[`t'] if events[`t'] ==0 
					  }
					  
	            egen max_arm = rowmax(treat_arm*)
	            egen max_arm_c = rowmax(control_arm*)
		
			    drop max_zero_double
				keep if study_id == 1
				drop study_id
			    drop study_num
				drop if __ma_rr_h ==. & __ma_rr_b ==.
				
		
				gen ratio_dir_h = __ma_ln_rr_h/__ma_ln_rr_h[1]
				gen ratio_sig_h = __ps_h/__ps_h[1]
				
				gen d_dir_h = 0 if ratio_dir_h > 0
				replace d_dir_h = 1 if ratio_dir_h < 0
				gen d_sig_h = 0 if ratio_sig_h > 0
				replace d_sig_h = 1 if ratio_sig_h < 0
				gen direction_h = d_sig_h + d_dir_h	
				
				
				gen ratio_dir_b = __ma_ln_rr_b/__ma_ln_rr_b[1]
				gen ratio_sig_b = __ps_b/__ps_b[1]
				
				gen d_dir_b = 0 if ratio_dir_b > 0
				replace d_dir_b = 1 if ratio_dir_b < 0
				gen d_sig_b = 0 if ratio_sig_b > 0
				replace d_sig_b = 1 if ratio_sig_b < 0
				gen direction_b = d_sig_b + d_dir_b	
				
				***max and min effects (for graph)
				egen min_lci_h = min(__ma_lci_rr_h)
                egen min_uci_h = max(__ma_uci_rr_h)
                egen min_lci_b = min(__ma_lci_rr_b)
                egen min_uci_b = max(__ma_uci_rr_b)
				
				
				***HI index
		        gen Hi = comb
				sort Hi
				gen direction_h_r = _n if direction_h ==1
				egen Meta_Hi = min(cond(direction_h_r,Hi,.))  if direction_h_r !=.
				replace Meta_Hi = 0 if Meta_Hi ==.
				
				
				
				***BI index
		        gen Bi = comb
				sort Bi
				gen direction_b_r = _n if direction_b ==1
				egen Meta_Bi = min(cond(direction_b_r,Bi,.)) if direction_b_r !=.
				replace Meta_Bi = 0 if Meta_Bi ==.
				
			
				***Rename
				egen max_MHi =max(Meta_Hi)
				drop Meta_Hi
				rename max_MHi Meta_Hi
				
				
				egen max_MBi =max(Meta_Bi)
				drop Meta_Bi
				rename max_MBi Meta_Bi
				
				scalar define _Meta_Hi = Meta_Hi[1]
				scalar define _Meta_Bi = Meta_Bi[1]
				
				if Meta_Hi == 0 & Meta_Bi == 0{
				      noisily display as text "Doubld-zero-events studies totally do not impact the results:"
					}	
				if (Meta_Hi > 0 & Meta_Hi < 3) | (Meta_Bi > 0 & Meta_Bi < 3){
				      noisily display as text "Doubld-zero-events studies may have some impact on the results:" 
					}
				if (Meta_Hi >= 3) | (Meta_Bi >= 3){
				      noisily display as text "Doubld-zero-events studies may have little impact on the results:"
					}

		}
		
}			
*










*



*Meta_Hi and Meta_Bi as string + output
	qui tostring Meta_Hi, gen(__Meta_Hi_str) force
	qui tostring Meta_Bi, gen(__Meta_Bi_str) force
	
	quietly gen ___Meta_Hi_str = substr(__Meta_Hi_str,1, strpos(__Meta_Hi_str,".")+2)
	quietly gen ___Meta_Bi_str = substr(__Meta_Bi_str,1, strpos(__Meta_Bi_str,".")+2)
	
	local Hi_str = ___Meta_Hi_str[1]
	local Bi_str = ___Meta_Bi_str[1]
	

	di as text "{hline 59}"		   
	display as text "Meta_Hi = " as result `Hi_str'
	display as text "Meta_Bi = " as result `Bi_str'
	di as text "{hline 59}"	
	


**Graphic	
  if "`graph'" != "nograph" & "`or'" == "" & "`rr'" == ""{
		sort comb
		**Favorite Harms
        twoway (rcap __ma_uci_or_h __ma_lci_or_h comb, lcolor(black) lwidth(thin))(scatter __ma_or_h comb, msymbol(circle) msize(small) mcolor(ebblue)) , xtitle("Combinations")ytitle("Odds ratio")yline(1, lcolor(black) lpattern(shortdash))  title(Harms index = `Hi_str', size(medsmall) margin(medium)) legend(col(3)label(1 "95%CI") label(2 "Effect size")) note(Add cases for zero-studies in treatment arm) graphregion(fcolor(white)) name(Favorite_Harms) 
		
		**Favorite Benifits
		 twoway (rcap __ma_uci_or_b __ma_lci_or_b comb, lcolor(black) lwidth(thin)) (scatter __ma_or_b comb, msymbol(circle) msize(small) mcolor(ebblue)), xtitle("Combinations") ytitle("Odds ratio")yline(1, lcolor(black) lpattern(shortdash)) title(Benifits index = `Bi_str', size(medsmall) margin(medium)) legend(col(3)label(1 "95%CI") label(2 "Effect size"))note(Add cases for zero-studies in control arm) graphregion(fcolor(white)) name(Favorite_Benifits)

  }
  if "`graph'" != "nograph" & "`or'" != ""{
		sort comb
		**Favorite Harms
        twoway (rcap __ma_uci_or_h __ma_lci_or_h comb, lcolor(black) lwidth(thin))(scatter __ma_or_h comb, msymbol(circle) msize(small) mcolor(ebblue)) , xtitle("Combinations")ytitle("Odds ratio")yline(1, lcolor(black) lpattern(shortdash))  title(Harms index = `Hi_str', size(medsmall) margin(medium)) legend(col(3)label(1 "95%CI") label(2 "Effect size")) note(Add cases for zero-studies in treatment arm) graphregion(fcolor(white)) name(Favorite_Harms)
		
		**Favorite Benifits
		 twoway (rcap __ma_uci_or_b __ma_lci_or_b comb, lcolor(black) lwidth(thin)) (scatter __ma_or_b comb, msymbol(circle) msize(small) mcolor(ebblue)), xtitle("Combinations") ytitle("Odds ratio")yline(1, lcolor(black) lpattern(shortdash))  title(Benifits index = `Bi_str', size(medsmall) margin(medium)) legend(col(3)label(1 "95%CI") label(2 "Effect size"))note(Add cases for zero-studies in control arm) graphregion(fcolor(white)) name(Favorite_Benifits)

  }
  if "`graph'" != "nograph" & "`rr'" != ""{
		sort comb
		**Favorite Harms
        twoway (rcap __ma_uci_rr_h __ma_lci_rr_h comb, lcolor(black) lwidth(thin))(scatter __ma_rr_h comb, msymbol(circle) msize(small) mcolor(ebblue)) , xtitle("Combinations")ytitle("Risk ratio")yline(1, lcolor(black) lpattern(shortdash))  title(Harms index = `Hi_str', size(medsmall) margin(medium)) legend(col(3)label(1 "95%CI") label(2 "Effect size")) note(Add cases for zero-studies in treatment arm) graphregion(fcolor(white)) name(Favorite_Harms)
		
		**Favorite Benifits
		 twoway (rcap __ma_uci_rr_b __ma_lci_rr_b comb, lcolor(black) lwidth(thin)) (scatter __ma_rr_b comb, msymbol(circle) msize(small) mcolor(ebblue)), xtitle("Combinations") ytitle("Risk ratio")yline(1, lcolor(black) lpattern(shortdash))  title(Benifits index = `Bi_str', size(medsmall) margin(medium)) legend(col(3)label(1 "95%CI") label(2 "Effect size"))note(Add cases for zero-studies in control arm) graphregion(fcolor(white)) name(Favorite_Benifits)

  }
  
*



restore 
qui gen _Hi = _Meta_Hi 
qui gen _Bi = _Meta_Bi 


end
exit
