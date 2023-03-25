*version 1.1 June 2018

*version 1.2 July 2022
*Fixed minor bug that returns an error message when kernel is specified as "triangular"

*version 1.3 March 2023
*Updated Stata version number
*Per Kit Baum's suggestion, changed program from eclass to rclass
*These changes do not affect any calculation

capture program drop rdmses_cct2014
program define rdmses_cct2014, rclass
	version 15.0
	syntax anything [if] [in] [, c(real 0) deriv(real 0) p(real 1) h(real 0) b(real 0) kernel(string) scalepar(real 1)]
	
	marksample touse
	
	local q = `p'+1
	local kernel = lower("`kernel'")
	local matches = 3
	local bwselect = "CCT"

	preserve
	qui keep if `touse'
	
	tokenize "`anything'"
	local y `1'
	local x `2'
	
	qui drop if `y'==. | `x'==.
	
	tempvar x_l x_r y_l y_r uh_l uh_r ub_l ub_r T T_l T_r
		
	qui gen `x_l' = `x' if `x'<`c'
	qui gen `x_r' = `x' if `x'>=`c'
	qui gen `y_l' = `y' if `x'<`c'
	qui gen `y_r' = `y' if `x'>=`c'
	qui su `x'
	local x_min = r(min)
	local x_max = r(max)
	qui su `x_l'
	local N_l = r(N)
	local range_l = abs(r(max)-r(min))
	qui su `x_r' 
	local N_r = r(N)
	local range_r = abs(r(max)-r(min))
	local N = `N_r' + `N_l'
	local m = `matches' + 1	

	local p1 = `p' + 1
	local q1 = `q' + 1
	
	**************************** ERRORS
	if (`c'<=`x_min' | `c'>=`x_max'){
	 di "{err}{cmd:c()} should be set within the range of `x'"  
	 exit 125
	}
	
	if (`N_l'<20 | `N_r'<20){
	 di "{err}Not enough observations to perform calculations"  
	 exit 2001
	}
		
	if ("`kernel'"~="uni" & "`kernel'"~="uniform" & "`kernel'"~="tri" & "`kernel'"~="triangular" & "`kernel'"~="" ){
	 di "{err}{cmd:kernel()} incorrectly specified"  
	 exit 7
	}

	if ("`p'"<"0" | "`deriv'"<"0"){
	 di "{err}{cmd:p()} and {cmd:deriv()} should be positive"  
	 exit 411
	}

	if ("`deriv'">"`p'" & "`deriv'">"0" ){
	 di "{err}{cmd:deriv()} can not be higher than {cmd:p()}"  
	 exit 125
	}

	if ("`p'">"0" ) {
		local p_round = round(`p')/`p'
		local q_round = round(`q')/`q'
		local d_round = round(`deriv'+1)/(`deriv'+1)
		local m_round = round(`matches')/`matches'

		if (`p_round'!=1 | `q_round'!=1 |`d_round'!=1 |`m_round'!=1 ){
			di "{err}{cmd:p()}, {cmd:deriv()} and {cmd:matches()} should be integers"  
			exit 126
																		}
					}
					
	if (`p'>8) {
		di "{err}The upper bound of {cmd:p()} is 8"
		exit 125
				}				
					

	if ("`h'"=="0" | "`b'"=="0") {
		disp in ye "Bandwidths h and b need to be specified"
		exit 198
	}
	
	
	if ("`exit'">"0") {
			exit
		}


	if ("`kernel'"=="uniform" | "`kernel'"=="uni") {
			local kernel_type = "Uniform"
		}
	else  {
			local kernel_type = "Triangular"
		}	

		
	sort `x', stable
	
	mata{
		Y   = st_data(.,("`y'"),   0)
		X   = st_data(.,("`x'"),   0)
		Y_l = st_data(.,("`y_l'"), 0)
		Y_r = st_data(.,("`y_r'"), 0)
		X_l = st_data(.,("`x_l'"), 0)
		X_r = st_data(.,("`x_r'"), 0)
		c = `c'
		N_l = length(X_l)
		N_r = length(X_r)
		c_l  = J(N_l, 1, c)
		c_r  = J(N_r, 1, c)
		p1 = `p' + 1
		q1 = `q' + 1
	
		wh_l = kweight(X_l,`c',`h',"`kernel'");	wh_r = kweight(X_r,`c',`h',"`kernel'")
		wb_l = kweight(X_l,`c',`b',"`kernel'");	wb_r = kweight(X_r,`c',`b',"`kernel'")

		uh_l = (X_l-c_l)/`h';	uh_r = (X_r-c_r)/`h';
		uhh_l=select(uh_l,wh_l:> 0);	uhh_r=select(uh_r,wh_r:> 0)

		ub_l = (X_l-c_l)/`b';   ub_r = (X_r-c_r)/`b';
		ubb_l = select(ub_l,wb_l:>0); ubb_r=select(ub_r,wb_r:>0)			
			
		Yh_l  = select(Y_l,  wh_l:> 0);	Yh_r  = select(Y_r,  wh_r:> 0)
		Yb_l  = select(Y_l,  wb_l:> 0);	Yb_r  = select(Y_r,  wb_r:> 0)
		Xh_l  = select(X_l,  wh_l:> 0);	Xh_r  = select(X_r,  wh_r:> 0)
		Xb_l  = select(X_l,  wb_l:> 0);	Xb_r  = select(X_r,  wb_r:> 0)
		whh_l = select(wh_l, wh_l:> 0);	whh_r = select(wh_r, wh_r:> 0)
		wbb_l = select(wb_l, wb_l:> 0);	wbb_r = select(wb_r, wb_r:> 0)

		Nh_l = length(Xh_l);	Nb_l = length(Xb_l)
		Nh_r = length(Xh_r);	Nb_r = length(Xb_r)
		X_lp  = J(N_l,p1,.);	X_rp  = J(N_r,p1,.)
		X_lq =  J(N_l,q1,.);	X_rq =  J(N_r,q1,.)
		Xh_lp = J(Nh_l,p1,.);	Xh_rp = J(Nh_r,p1,.)
		Xb_lq = J(Nb_l,q1,.);	Xb_rq = J(Nb_r,q1,.)

		for (j=1; j<=p1; j++)  {
			X_lp[.,j]  = (X_l:-c):^(j-1);		X_rp[.,j]  = (X_r:-c):^(j-1)
			Xh_lp[.,j] = (Xh_l:-c):^(j-1);		Xh_rp[.,j] = (Xh_r:-c):^(j-1)
								}
	
		for (j=1; j<=q1; j++)  {
			X_lq[.,j]  = (X_l:-c):^(j-1);		X_rq[.,j]  = (X_r:-c):^(j-1)
			Xb_lq[.,j] = (Xb_l:-c):^(j-1);		Xb_rq[.,j] = (Xb_r:-c):^(j-1)
								}
	
		st_numscalar("Nh_l", Nh_l[1,1]);	st_numscalar("Nb_l", Nb_l[1,1])
		st_numscalar("Nh_r", Nh_r[1,1]);	st_numscalar("Nb_r", Nb_r[1,1])

		if (Nh_l<5 | Nh_r<5 | Nb_l<5 | Nb_r<5){
			display("{err}Not enough observations to perform calculations")
			exit()
												}

		sigmah_l = rdvce(Xh_l, Yh_l, Yh_l, `p', `h', `matches', "`vce'", "`kernel'")
		sigmah_r = rdvce(Xh_r, Yh_r, Yh_r, `p', `h', `matches', "`vce'", "`kernel'")
		sigmab_l = rdvce(Xb_l, Yb_l, Yb_l, `p', `h', `matches', "`vce'", "`kernel'")
		sigmab_r = rdvce(Xb_r, Yb_r, Yb_r, `p', `h', `matches', "`vce'", "`kernel'")
	
		invGamma_lp  = invsym(cross(X_lp,wh_l,X_lp));	invGamma_rp  = invsym(cross(X_rp,wh_r,X_rp))
		invGamma_lq  = invsym(cross(X_lq,wb_l,X_lq));	invGamma_rq  = invsym(cross(X_rq,wb_r,X_rq))
		invGammah_lp = invsym(cross(Xh_lp,whh_l,Xh_lp));	invGammah_rp = invsym(cross(Xh_rp,whh_r,Xh_rp))
		invGammab_lq = invsym(cross(Xb_lq,wbb_l,Xb_lq));	invGammab_rq = invsym(cross(Xb_rq,wbb_r,Xb_rq))
	
		Psih_lp = cross(Xh_lp, whh_l:*sigmah_l:*whh_l, Xh_lp);	Psih_rp = cross(Xh_rp, whh_r:*sigmah_r:*whh_r, Xh_rp)
		Psib_lq = cross(Xb_lq, wbb_l:*sigmab_l:*wbb_l, Xb_lq);	Psib_rq = cross(Xb_rq, wbb_r:*sigmab_r:*wbb_r, Xb_rq)

		factor_p = J(p1, 1, .);	factor_q = J(q1, 1, .)
	
		for (j=1; j<=p1; j++) {
			factor_p[j] = factorial(j-1)
								}
	
		for (j=1; j<=q1; j++) {
			factor_q[j] = factorial(j-1)
								}
	
		Hp_vec = J(p1, 1, .)
		for (j=1; j<=p1; j++) {
			Hp_vec[j] = `h'^(-(j-1))
								}
		Hp = diag(Hp_vec)
	
		Hq_vec = J(q1, 1, .)
		for (j=1; j<=q1; j++) {
			Hq_vec[j] = `b'^(-(j-1))
								}
		Hq = diag(Hq_vec)
	
		tau_lp = factor_p:*(invGammah_lp*cross(Xh_lp, whh_l, Yh_l));	tau_rp = factor_p:*(invGammah_rp*cross(Xh_rp, whh_r, Yh_r))
		tau_lq = factor_q:*(invGammab_lq*cross(Xb_lq, wbb_l, Yb_l));	tau_rq = factor_q:*(invGammab_rq*cross(Xb_rq, wbb_r, Yb_r))

		V_lp = invGammah_lp*Psih_lp*invGammah_lp;	V_rp = invGammah_rp*Psih_rp*invGammah_rp
		V_lq = invGammab_lq*Psib_lq*invGammab_lq;	V_rq = invGammab_rq*Psib_rq*invGammab_rq
	
		if (`b'>=`h'){
			whb_l = select(wh_l,wb_l:>0);    whb_r = select(wh_r,wb_r:>0)
			Xb_lp = select(X_lp,wb_l:>0);    Xb_rp = select(X_rp,wb_r:>0)
			Psi_lpq = cross(Xb_lp,whb_l:*sigmab_l:*wbb_l,Xb_lq);    Psi_rpq = cross(Xb_rp,whb_r:*sigmab_r:*wbb_r,Xb_rq)
						}
		else {
			wbh_l = select(wb_l,wh_l:>0);    wbh_r = select(wb_r,wh_r:>0)
			Xh_lq = select(X_lq,wh_l:>0);    Xh_rq = select(X_rq,wh_r:>0)
			Psi_lpq = cross(Xh_lp,whh_l:*sigmah_l:*wbh_l,Xh_lq);    Psi_rpq = cross(Xh_rp,whh_r:*sigmah_r:*wbh_r,Xh_rq)
				}
	
		Cov_l = invGamma_lp*Psi_lpq*invGamma_lq;	Cov_r = invGamma_rp*Psi_rpq*invGamma_rq

		v_lp = (Xh_lp:*whh_l)'*(uhh_l:^(`p'+1));	v_rp = (Xh_rp:*whh_r)'*(uhh_r:^(`p'+1)) 
		v_lq = (Xb_lq:*wbb_l)'*(ubb_l:^(`q'+1));	v_rq = (Xb_rq:*wbb_r)'*(ubb_r:^(`q'+1))
		v_lp1 = (Xh_lp:*whh_l)'*(uhh_l:^(`p'+2));	v_rp1 = (Xh_rp:*whh_r)'*(uhh_r:^(`p'+2)) 
	
		BiasConst_lp = factorial(`deriv')*invsym(Hp)*invGamma_lp*v_lp 
		BiasConst_rp = factorial(`deriv')*invsym(Hp)*invGamma_rp*v_rp
	
		Bias_tau = (tau_rq[`p'+2,1]*BiasConst_rp[`deriv'+1,1] - tau_lq[`p'+2,1]*BiasConst_lp[`deriv'+1,1])*(`h'^(`p'+1-`deriv')/factorial(`p'+1))

		tau_cl = `scalepar'*(tau_rp[`deriv'+1,1] - tau_lp[`deriv'+1,1])
		tau_bc = `scalepar'*(tau_rp[`deriv'+1,1] - tau_lp[`deriv'+1,1] - Bias_tau)

		V_l_cl = factorial(`deriv')^2*V_lp[`deriv'+1,`deriv'+1] 
		V_r_cl = factorial(`deriv')^2*V_rp[`deriv'+1,`deriv'+1]  
		V_cl   = `scalepar'^2*(V_l_cl + V_r_cl)
			
		st_numscalar("amse_cl", Bias_tau^2 + V_cl)
			
		}
			
		
	restore
	
	************************************************
	********* OUTPUT RESULT ************************
	************************************************
	di ""
	
		di "The estimated AMSE for the conventional sharp estimator of order `p' is " amse_cl
		
		return scalar amse_cl = amse_cl
			
			
	mata mata clear

end


