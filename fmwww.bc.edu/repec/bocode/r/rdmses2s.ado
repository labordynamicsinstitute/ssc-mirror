*version 1.0 January 2021
*accommodates different bandwidths and polynomial orders on two sides of the threshold

*version 1.1 July 2022
*Fixed minor bug that returns an error message when kernel is specified as "triangular"

*version 1.2 March 2023
*Updated Stata version number
*Per Kit Baum's suggestion, changed program from eclass to rclass
*These changes do not affect any calculation

set type double
capture program drop rdmses2s
program define rdmses2s, rclass
	version 15.0
	syntax anything [if] [in] [, c(real 0) deriv(real 0) pl(real 1) pr(real 1) hl(real 0) hr(real 0) bl(real 0) br(real 0) kernel(string) scalepar(real 1)]
	
	marksample touse
	
	local ql = `pl'+1
	local qr = `pr'+1
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

	local pl1 = `pl' + 1
	local pr1 = `pr' + 1
	local ql1 = `ql' + 1
	local qr1 = `qr' + 1
	
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

	if ("`pl'"<"0" | "`pr'"<"0" | "`deriv'"<"0"){
	 di "{err}{cmd:pl()}, {cmd:pr()}, and {cmd:deriv()} should be positive"  
	 exit 411
	}

	if (("`deriv'">"`pl'" | "`deriv'">"`pr'") & "`deriv'">"0" ){
	 di "{err}{cmd:deriv()} can not be higher than {cmd:pl()} or {cmd:pr()}"  
	 exit 125
	}

	if ("`pl'">"0" & "`pr'">"0") {
		local pl_round = round(`pl')/`pl'
		local pr_round = round(`pr')/`pr'	
		local ql_round = round(`ql')/`ql'
		local qr_round = round(`qr')/`qr'		
		local d_round = round(`deriv'+1)/(`deriv'+1)
		local m_round = round(`matches')/`matches'

		if (`pl_round'!=1 | `pr_round'!=1 | `ql_round'!=1 | `qr_round'!=1 | `d_round'!=1 |`m_round'!=1 ){
			di "{err}{cmd:pl()}, {cmd:pr()}, {cmd:deriv()}, and {cmd:matches()} should be integers"  
			exit 126
																		}
					}
					
	if (`pl'>8 | `pr'>8) {
		di "{err}The upper bound of {cmd:pl()} and {cmd:pr()} is 8"
		exit 125
				}				
					

	if ("`hl'"=="0" | "`hr'"=="0" | "`bl'"=="0" | "`br'"=="0" | `hl'==. | `hr'==. | `bl'==. | `br'==.) {
		disp in ye "Bandwidths hl, hr, bl, and br need to be specified"
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


	if ("`kernel'"=="uniform" | "`kernel'"=="uni") {
			local kid=2
			local C_pilot=1.84
	}
	else  {
			local kid=1
			local C_pilot=2.58
	}
	
	kconst `ql1' `ql1' `kid'
	local C1_lq = e(C1)
	local C2_lq = e(C2)		
	
	kconst `qr1' `qr1' `kid'
	local C1_rq = e(C1)
	local C2_rq = e(C2)	
	
	** compute bias and variance for the conventional estimator **	
	qui su `x', d
	local h_pilot_CCT = `C_pilot'*min(r(sd),(r(p75)-r(p25))/1.349)*r(N)^(-1/5)
	
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
		deriv = `deriv'
		pl = `pl'
		pr = `pr'
		ql = `ql'
		qr = `qr'
		pl1 = `pl' + 1
		pr1 = `pr' + 1		
		ql1 = `ql' + 1
		qr1 = `qr' + 1
		pl2 = `pl' + 2
		pr2 = `pr' + 2		
		ql2 = `ql' + 2
		qr2 = `qr' + 2
		pl3 = `pl' + 3
		pr3 = `pr' + 3		
		ql3 = `ql' + 3
		qr3 = `qr' + 3		
		h_pilot_CCT=`h_pilot_CCT'
		C1_lq = `C1_lq'
		C2_lq = `C2_lq'
		C1_rq = `C1_rq'
		C2_rq = `C2_rq'
		
		X_lq2 = J(N_l, ql+3, .);	X_rq2 = J(N_r, qr+3, .)
		for (j=1; j<=ql3; j++) {
			X_lq2[.,j] = (X_l:-c):^(j-1)
		}
	
		for (j=1; j<=qr3; j++) {
			X_rq2[.,j] = (X_r:-c):^(j-1)
		}
		
		X_lq1 = X_lq2[.,1::ql2];X_rq1 = X_rq2[.,1::qr2]		

		w_pilot_l = kweight(X_l,c,h_pilot_CCT,"`kernel'")
		w_pilot_r = kweight(X_r,c,h_pilot_CCT,"`kernel'")

		Gamma_pilot_lq1 = quadcross(X_lq1, w_pilot_l, X_lq1);	Gamma_pilot_rq1 = quadcross(X_rq1, w_pilot_r, X_rq1)
		invGamma_pilot_lq1 = cholinv(Gamma_pilot_lq1);	invGamma_pilot_rq1 = cholinv(Gamma_pilot_rq1)
		sigma_l_pilot = altrdvce(X_l, Y_l, Y_l, `pl', `h_pilot_CCT', `matches', "`vce'", "`kernel'")
		sigma_r_pilot = altrdvce(X_r, Y_r, Y_r, `pr', `h_pilot_CCT', `matches', "`vce'", "`kernel'")	
		Psi_pilot_lq1 = quadcross(X_lq1, w_pilot_l:*sigma_l_pilot:*w_pilot_l, X_lq1)
		Psi_pilot_rq1 = quadcross(X_rq1, w_pilot_r:*sigma_r_pilot:*w_pilot_r, X_rq1)		

		V_l_m3_pilot_CCT = (invGamma_pilot_lq1*Psi_pilot_lq1*invGamma_pilot_lq1)[ql2,ql2]   
		V_r_m3_pilot_CCT = (invGamma_pilot_rq1*Psi_pilot_rq1*invGamma_pilot_rq1)[qr2,qr2]

		m4_l_pilot_CCT = (cholinv(quadcross(X_lq2,X_lq2))*quadcross(X_lq2,Y_l))[ql3,1]
		m4_r_pilot_CCT = (cholinv(quadcross(X_rq2,X_rq2))*quadcross(X_rq2,Y_r))[qr3,1]	
		
		q_l_CCT = ((2*ql+3)*`N'*`h_pilot_CCT'^(2*ql+3)*V_l_m3_pilot_CCT)/((`N'*(2*(C1_lq*(m4_l_pilot_CCT))^2))^(1/(2*ql+5)))
		q_r_CCT = ((2*qr+3)*`N'*`h_pilot_CCT'^(2*qr+3)*V_r_m3_pilot_CCT)/((`N'*(2*(C1_rq*(m4_r_pilot_CCT))^2))^(1/(2*qr+5)))

		w_q_l=kweight(X_l,c,q_l_CCT,"`kernel'")
		w_q_r=kweight(X_r,c,q_r_CCT,"`kernel'")
	
		* m3_l and m3_r are m3_l_CCT and m3_r_CCT from the bw programs
		m3_l = (cholinv(quadcross(X_lq1, w_q_l, X_lq1))*quadcross(X_lq1, w_q_l, Y_l))[ql2,1]
		m3_r = (cholinv(quadcross(X_rq1, w_q_r, X_rq1))*quadcross(X_rq1, w_q_r, Y_r))[qr2,1]
		
		wh_l = kweight(X_l,`c',`hl',"`kernel'");	wh_r = kweight(X_r,`c',`hr',"`kernel'")
		wb_l = kweight(X_l,`c',`bl',"`kernel'");	wb_r = kweight(X_r,`c',`br',"`kernel'")

		uh_l = (X_l-c_l)/`hl';	uh_r = (X_r-c_r)/`hr';
		uhh_l=select(uh_l,wh_l:> 0);	uhh_r=select(uh_r,wh_r:> 0)

		ub_l = (X_l-c_l)/`bl';   ub_r = (X_r-c_r)/`br';
		ubb_l = select(ub_l,wb_l:>0); ubb_r=select(ub_r,wb_r:>0)			
			
		Yh_l  = select(Y_l,  wh_l:> 0);	Yh_r  = select(Y_r,  wh_r:> 0)
		Yb_l  = select(Y_l,  wb_l:> 0);	Yb_r  = select(Y_r,  wb_r:> 0)
		Xh_l  = select(X_l,  wh_l:> 0);	Xh_r  = select(X_r,  wh_r:> 0)
		Xb_l  = select(X_l,  wb_l:> 0);	Xb_r  = select(X_r,  wb_r:> 0)
		whh_l = select(wh_l, wh_l:> 0);	whh_r = select(wh_r, wh_r:> 0)
		wbb_l = select(wb_l, wb_l:> 0);	wbb_r = select(wb_r, wb_r:> 0)

		Nh_l = length(Xh_l);	Nb_l = length(Xb_l)
		Nh_r = length(Xh_r);	Nb_r = length(Xb_r)
		X_lp  = J(N_l,pl1,.);	X_rp  = J(N_r,pr1,.)
		X_lq =  J(N_l,ql1,.);	X_rq =  J(N_r,qr1,.)
		Xh_lp = J(Nh_l,pl1,.);	Xh_rp = J(Nh_r,pr1,.)
		Xb_lq = J(Nb_l,ql1,.);	Xb_rq = J(Nb_r,qr1,.)

		for (j=1; j<=pl1; j++)  {
			X_lp[.,j]  = (X_l:-c):^(j-1)
			Xh_lp[.,j] = (Xh_l:-c):^(j-1)
								}

		for (j=1; j<=pr1; j++)  {
			X_rp[.,j]  = (X_r:-c):^(j-1)
			Xh_rp[.,j] = (Xh_r:-c):^(j-1)
								}								
								
		for (j=1; j<=ql1; j++)  {
			X_lq[.,j]  = (X_l:-c):^(j-1)
			Xb_lq[.,j] = (Xb_l:-c):^(j-1)
								}
	
		for (j=1; j<=qr1; j++)  {
			X_rq[.,j]  = (X_r:-c):^(j-1)
			Xb_rq[.,j] = (Xb_r:-c):^(j-1)
								}	
	
		st_numscalar("Nh_l", Nh_l[1,1]);	st_numscalar("Nb_l", Nb_l[1,1])
		st_numscalar("Nh_r", Nh_r[1,1]);	st_numscalar("Nb_r", Nb_r[1,1])

		if (Nh_l<5 | Nh_r<5 | Nb_l<5 | Nb_r<5){
			display("{err}Not enough observations to perform calculations")
			exit()
												}

		sigmah_l = altrdvce(Xh_l, Yh_l, Yh_l, `pl', `hl', `matches', "`vce'", "`kernel'")
		sigmah_r = altrdvce(Xh_r, Yh_r, Yh_r, `pr', `hr', `matches', "`vce'", "`kernel'")
		sigmab_l = altrdvce(Xb_l, Yb_l, Yb_l, `pl', `hl', `matches', "`vce'", "`kernel'")
		sigmab_r = altrdvce(Xb_r, Yb_r, Yb_r, `pr', `hr', `matches', "`vce'", "`kernel'")
	
		invGamma_lp  = cholinv(quadcross(X_lp,wh_l,X_lp));	invGamma_rp  = cholinv(quadcross(X_rp,wh_r,X_rp))
		invGamma_lq  = cholinv(quadcross(X_lq,wb_l,X_lq));	invGamma_rq  = cholinv(quadcross(X_rq,wb_r,X_rq))
		invGammah_lp = cholinv(quadcross(Xh_lp,whh_l,Xh_lp));	invGammah_rp = cholinv(quadcross(Xh_rp,whh_r,Xh_rp))
		invGammab_lq = cholinv(quadcross(Xb_lq,wbb_l,Xb_lq));	invGammab_rq = cholinv(quadcross(Xb_rq,wbb_r,Xb_rq))
	
		Psih_lp = quadcross(Xh_lp, whh_l:*sigmah_l:*whh_l, Xh_lp);	Psih_rp = quadcross(Xh_rp, whh_r:*sigmah_r:*whh_r, Xh_rp)
		Psib_lq = quadcross(Xb_lq, wbb_l:*sigmab_l:*wbb_l, Xb_lq);	Psib_rq = quadcross(Xb_rq, wbb_r:*sigmab_r:*wbb_r, Xb_rq)

		factor_lp = J(pl1, 1, .)
		factor_rp = J(pr1, 1, .)		
		factor_lq = J(ql1, 1, .)
		factor_rq = J(qr1, 1, .)
		
		for (j=1; j<=pl1; j++) {
			factor_lp[j] = factorial(j-1)
								}

		for (j=1; j<=pr1; j++) {
			factor_rp[j] = factorial(j-1)
								}								
								
		for (j=1; j<=ql1; j++) {
			factor_lq[j] = factorial(j-1)
								}
								
		for (j=1; j<=qr1; j++) {
			factor_rq[j] = factorial(j-1)
								}								
	
		Hlp_vec = J(pl1, 1, .)
		for (j=1; j<=pl1; j++) {
			Hlp_vec[j] = `hl'^(-(j-1))
								}
		Hlp = diag(Hlp_vec)

		Hrp_vec = J(pr1, 1, .)
		for (j=1; j<=pr1; j++) {
			Hrp_vec[j] = `hr'^(-(j-1))
								}
		Hrp = diag(Hrp_vec)	
		
		Hlq_vec = J(ql1, 1, .)
		for (j=1; j<=ql1; j++) {
			Hlq_vec[j] = `bl'^(-(j-1))
								}
		Hlq = diag(Hlq_vec)
		
		Hrq_vec = J(qr1, 1, .)
		for (j=1; j<=qr1; j++) {
			Hrq_vec[j] = `br'^(-(j-1))
								}
		Hrq = diag(Hrq_vec)		
	
		tau_lp = factor_lp:*(invGammah_lp*quadcross(Xh_lp, whh_l, Yh_l));	tau_rp = factor_rp:*(invGammah_rp*quadcross(Xh_rp, whh_r, Yh_r))
		tau_lq = factor_lq:*(invGammab_lq*quadcross(Xb_lq, wbb_l, Yb_l));	tau_rq = factor_rq:*(invGammab_rq*quadcross(Xb_rq, wbb_r, Yb_r))

		V_lp = invGammah_lp*Psih_lp*invGammah_lp;	V_rp = invGammah_rp*Psih_rp*invGammah_rp
		V_lq = invGammab_lq*Psib_lq*invGammab_lq;	V_rq = invGammab_rq*Psib_rq*invGammab_rq

		
		if (`bl'>=`hl'){
			whb_l = select(wh_l,wb_l:>0)
			Xb_lp = select(X_lp,wb_l:>0)
			Psi_lpq = quadcross(Xb_lp,whb_l:*sigmab_l:*wbb_l,Xb_lq)
						}
		else {
			wbh_l = select(wb_l,wh_l:>0)
			Xh_lq = select(X_lq,wh_l:>0)
			Psi_lpq = quadcross(Xh_lp,whh_l:*sigmah_l:*wbh_l,Xh_lq)
				}

		if (`br'>=`hr'){
			whb_r = select(wh_r,wb_r:>0)
			Xb_rp = select(X_rp,wb_r:>0)
			Psi_rpq = quadcross(Xb_rp,whb_r:*sigmab_r:*wbb_r,Xb_rq)
						}
		else {
			wbh_r = select(wb_r,wh_r:>0)
			Xh_rq = select(X_rq,wh_r:>0)
			Psi_rpq = quadcross(Xh_rp,whh_r:*sigmah_r:*wbh_r,Xh_rq)
				}				
				
		Cov_l = invGamma_lp*Psi_lpq*invGamma_lq;	Cov_r = invGamma_rp*Psi_rpq*invGamma_rq

		v_lp = (Xh_lp:*whh_l)'*(uhh_l:^(`pl'+1));	v_rp = (Xh_rp:*whh_r)'*(uhh_r:^(`pr'+1)) 
		v_lq = (Xb_lq:*wbb_l)'*(ubb_l:^(`ql'+1));	v_rq = (Xb_rq:*wbb_r)'*(ubb_r:^(`qr'+1))
		v_lp1 = (Xh_lp:*whh_l)'*(uhh_l:^(`pl'+2));	v_rp1 = (Xh_rp:*whh_r)'*(uhh_r:^(`pr'+2)) 
	
		BiasConst_lp = factorial(`deriv')*cholinv(Hlp)*invGamma_lp*v_lp 
		BiasConst_rp = factorial(`deriv')*cholinv(Hrp)*invGamma_rp*v_rp
	
		BiasConst_lp1= factorial(`deriv')*cholinv(Hlp)*invGamma_lp*v_lp1
		BiasConst_rp1= factorial(`deriv')*cholinv(Hrp)*invGamma_rp*v_rp1
	
		BiasConst_lq = cholinv(Hlq)*invGamma_lq*v_lq
		BiasConst_rq = cholinv(Hrq)*invGamma_rq*v_rq

		Bias_l_tau_CCT_part1 = (`hl')^(`pl'+2-`deriv')*(-m3_l*BiasConst_lp1[`deriv'+1,1])
		Bias_l_tau_CCT_part2 = (`hl')^(`pl'+1-`deriv')*(`bl'^(`ql'-`pl'))*factorial(`deriv')*(m3_l*BiasConst_lq[`pl'+2,1]*BiasConst_lp[`deriv'+1,1])

		Bias_r_tau_CCT_part1 = (`hr')^(`pr'+2-`deriv')*(m3_r*BiasConst_rp1[`deriv'+1,1])
		Bias_r_tau_CCT_part2 = (`hr')^(`pr'+1-`deriv')*(`br'^(`qr'-`pr'))*factorial(`deriv')*(m3_r*BiasConst_rq[`pr'+2,1]*BiasConst_rp[`deriv'+1,1])		
		
		Bias_l_tau_CCT = Bias_l_tau_CCT_part1-Bias_l_tau_CCT_part2		
		Bias_r_tau_CCT = Bias_r_tau_CCT_part1-Bias_r_tau_CCT_part2		
	
		Bias_l_tau = (-tau_lq[`pl'+2,1]*BiasConst_lp[`deriv'+1,1]) * (`hl'^(`pl'+1-`deriv')/factorial(`pl'+1))
		Bias_r_tau = (tau_rq[`pr'+2,1]*BiasConst_rp[`deriv'+1,1]) * (`hr'^(`pr'+1-`deriv')/factorial(`pr'+1))	
	
		*Bias_tau = (tau_rq[`p'+2,1]*BiasConst_rp[`deriv'+1,1] - tau_lq[`p'+2,1]*BiasConst_lp[`deriv'+1,1])*(`h'^(`p'+1-`deriv')/factorial(`p'+1))
		
		*tau_cl = tau_rp[`deriv'+1,1] - tau_lp[`deriv'+1,1]
		*tau_bc = tau_rp[`deriv'+1,1] - tau_lp[`deriv'+1,1] - Bias_tau

		V_l_cl = factorial(`deriv')^2*V_lp[`deriv'+1,`deriv'+1] 
		V_r_cl = factorial(`deriv')^2*V_rp[`deriv'+1,`deriv'+1]  
		V_l_rb = factorial(`deriv')^2*V_lp[`deriv'+1,`deriv'+1] + factorial(`pl'+1)^2*V_lq[`pl'+2,`pl'+2]*(BiasConst_lp[`deriv'+1]*`hl'^(`pl'+1-`deriv')/factorial(`pl'+1))^2 - 2*factorial(`deriv')*factorial(`pl'+1)*Cov_l[`deriv'+1,`pl'+2]*(BiasConst_lp[`deriv'+1]*`hl'^(`pl'+1-`deriv')/factorial(`pl'+1))
		V_r_rb = factorial(`deriv')^2*V_rp[`deriv'+1,`deriv'+1] + factorial(`pr'+1)^2*V_rq[`pr'+2,`pr'+2]*(BiasConst_rp[`deriv'+1]*`hr'^(`pr'+1-`deriv')/factorial(`pr'+1))^2 - 2*factorial(`deriv')*factorial(`pr'+1)*Cov_r[`deriv'+1,`pr'+2]*(BiasConst_rp[`deriv'+1]*`hr'^(`pr'+1-`deriv')/factorial(`pr'+1))
		*V_cl   = V_l_cl + V_r_cl
		*V_rb   = V_l_rb + V_r_rb
	
		*V_bias = factorial(`p'+1)^2*V_rq[`p'+2,`p'+2]*(BiasConst_rp[`deriv'+1]*`h'^(`p'+1-`deriv')/factorial(`p'+1))^2 + factorial(`p'+1)^2*V_lq[`p'+2,`p'+2]*(BiasConst_lp[`deriv'+1]*`h'^(`p'+1-`deriv')/factorial(`p'+1))^2
		
		st_numscalar("m3_l", m3_l)
		st_numscalar("m3_r", m3_r)		
		st_numscalar("amse_l_cl", `scalepar'^2*(Bias_l_tau^2 + V_l_cl))
		st_numscalar("amse_r_cl", `scalepar'^2*(Bias_r_tau^2 + V_r_cl))		
		st_numscalar("amse_l_bc", `scalepar'^2*(Bias_l_tau_CCT^2 + V_l_rb))
		st_numscalar("amse_r_bc", `scalepar'^2*(Bias_r_tau_CCT^2 + V_r_rb))		
			
		}
			
		
	restore
	
	************************************************
	********* OUTPUT RESULT ************************
	************************************************
	di ""
	di "The estimated AMSE for the conventional left-side estimator of order `pl' is " amse_l_cl
	di "The estimated AMSE for the conventional right-side estimator of order `pr' is " amse_r_cl		
	
	if (m3_l!=.) {	
		di "The estimated AMSE for the bias-corrected left-side estimator of order `pl' is " amse_l_bc	
					}
	else {
		di "Due to multicollinearity in estimating higher derivatives," 
		di "the AMSE for the bias-corrected left-side estimator of order `pl' cannot be computed."
		}
						
	if (m3_r!=.) {	
		di "The estimated AMSE for the bias-corrected right-side estimator of order `pr' is " amse_r_bc	
					}
	else {
		di "Due to multicollinearity in estimating higher derivatives," 
		di "the AMSE for the bias-corrected right-side estimator of order `pr' cannot be computed."
		}
		
	return scalar amse_l_cl = amse_l_cl
	return scalar amse_r_cl = amse_r_cl	
	return scalar amse_l_bc = amse_l_bc
	return scalar amse_r_bc = amse_r_bc			
			
	*mata mata clear

end


