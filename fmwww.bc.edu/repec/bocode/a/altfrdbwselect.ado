* Updated Jan 2021: Following the update of rdrobust, changed to a more stable way matrix inverse is taken

* Updated Mar 2023: 
* Added Stata version number
* Per Kit Baum's suggestion, changed program from eclass to rclass
* These changes do not affect any calculation


capture program drop altfrdbwselect
program define altfrdbwselect, rclass
	version 15.0
	syntax anything [if] [in] [, c(real 0) deriv(real 0) fuzzy(string) p(real 1) q(real 2) kernel(string) bwselect(string) rho(real 0) vce(string) matches(real 3) scaleregul(real 1) ]

	local kernel = lower("`kernel'")
	local bwselect = upper("`bwselect'")
	local vce = lower("`vce'")

	marksample touse
	preserve
	qui keep if `touse'
	tokenize "`anything'"
	
	** declaring the y and x variables **
	local y `1'
	local x `2'
	
	** drop missing values **
	qui drop if `y'==. | `x'==. | `fuzzy'==.
	tempvar x_l x_r y_l y_r t_l t_r
	local b_calc = 0
	
	if (`rho'==0){
		local b_calc = 1
		local rho = 1
	}
	
	** the medians are used in the IK bandwidth **
		qui su `x'  if `x'<`c', d
		local medX_l = r(p50)
		qui su `x'  if `x'>=`c', d
		local medX_r = r(p50)
	
	qui gen `x_l' = `x' if `x'<`c'
	qui gen `x_r' = `x' if `x'>=`c'
	qui gen `y_l' = `y' if `x'<`c'
	qui gen `y_r' = `y' if `x'>=`c'
	qui gen `t_l' = `fuzzy' if `x'<`c'
	qui gen `t_r' = `fuzzy' if `x'>=`c'
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
	

	if ("`deriv'">"0" & "`p'"=="1" & "`q'"=="0"){
		local p = `deriv'+1
	}

		if ("`q'"=="0") {
			local q = `p'+1
		}


		**************************** ERRORS
	if (`c'<=`x_min' | `c'>=`x_max'){
	 di "{err}{cmd:c()} should be set within the range of `x'"  
	 exit 125
	}
	
	if (`N_l'<20 | `N_r'<20){
	 di "{err}Not enough observations to perform calculations"  
	 exit 2001
	}
	
	if ("`p'">"8"){
	 di "{err}{cmd:p()} should be less or equal than 8 for this version of the software package"  
	 exit 125
	}
	
	
	if ("`kernel'"~="uni" & "`kernel'"~="uniform" & "`kernel'"~="tri" & "`kernel'"~="triangular" & "`kernel'"~="epa" & "`kernel'"~="epanechnikov" & "`kernel'"~="" ){
	 di "{err}{cmd:kernel()} incorrectly specified"  
	 exit 7
	}

	** removed CV as an option from CCT **
	if ("`bwselect'"~="CCT" & "`bwselect'"~="IK" & "`bwselect'"~=""){
	 di "{err}{cmd:bwselect()} incorrectly specified"  
	 exit 7
	}

	if ("`vce'"~="resid" & "`vce'"~="nn" & "`vce'"~=""){ 
	 di "{err}{cmd:vce()} incorrectly specified"  
	 exit 7
	}

	if ("`p'"<"0" | "`q'"<="0" | "`deriv'"<"0" | "`matches'"<="0" | `scaleregul'<0){
	 di "{err}{cmd:p()}, {cmd:q()}, {cmd:deriv()}, {cmd:matches()} and {cmd:scaleregul()} should be positive"  
	 exit 411
	}

	if ("`p'">="`q'" & "`q'">"0"){
	 di "{err}{cmd:q()} should be higher than {cmd:p()}"  
	 exit 125
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
	 di "{err}{cmd:p()}, {cmd:q()}, {cmd:deriv()} and {cmd:matches()} should be integers"  
	 exit 126
	}
	}
	

	if (`rho'>1 | `rho'<0){
	 di "{err}{cmd:rho()}should be set between 0 and 1"  
	 exit 125
	}

	
		if ("`exit'">"0") {
			exit
		}

	if ("`kernel'"=="epanechnikov" | "`kernel'"=="epa") {
			local kernel_type = "Epanechnikov"
		}
	else if ("`kernel'"=="uniform" | "`kernel'"=="uni") {
			local kernel_type = "Uniform"
		}
	else  {
			local kernel_type = "Triangular"
		}
		

	disp in yellow "Calculating Preliminary Bandwidths" 
	
	if ("`bwselect'"=="IK") {

		qui altrdbwselect `y' `x', c(`c') deriv(`deriv') p(`p') q(`q') bwselect(`bwselect') kernel(`kernel') vce(`vce') precalc scaleregul(`scaleregul')
		local h = r(h_IK)
		local b = r(b_IK)
		local bwselect = "IK"
	}

	else {

		local bwselect = "CCT"
		qui altrdbwselect `y' `x', c(`c') deriv(`deriv') p(`p') q(`q') matches(`matches') bwselect(`bwselect') kernel(`kernel') vce(`vce') precalc scaleregul(`scaleregul')
		local h = r(h_CCT)
		local b = r(b_CCT)
	}	

	disp in yellow "Obtaining preliminary RD estimates" 	

	sort `x', stable
	
	mata{
	Y   = st_data(.,("`y'"),   0)
	X   = st_data(.,("`x'"),   0)
	T  = st_data(.,("`fuzzy'"), 0)
	Y_l = st_data(.,("`y_l'"), 0)
	Y_r = st_data(.,("`y_r'"), 0)
	X_l = st_data(.,("`x_l'"), 0)
	X_r = st_data(.,("`x_r'"), 0)
	T_l = st_data(.,("`t_l'"), 0)
	T_r = st_data(.,("`t_r'"), 0)
	c = `c'
	N_l = length(X_l)
	N_r = length(X_r)
	c_l  = J(N_l, 1, c)
	c_r  = J(N_r, 1, c)
	p1 = `p' + 1
	
	wh_l = kweight(X_l,`c',`h',"`kernel'");	wh_r = kweight(X_r,`c',`h',"`kernel'")

	uh_l = (X_l-c_l)/`h';	uh_r = (X_r-c_r)/`h';
	uhh_l=select(uh_l,wh_l:> 0);	uhh_r=select(uh_r,wh_r:> 0)

	Yh_l  = select(Y_l,  wh_l:> 0);	Yh_r  = select(Y_r,  wh_r:> 0)
	Xh_l  = select(X_l,  wh_l:> 0);	Xh_r  = select(X_r,  wh_r:> 0)
	whh_l = select(wh_l, wh_l:> 0);	whh_r = select(wh_r, wh_r:> 0)

	Th_l  = select(T_l, wh_l:> 0);		Th_r = select(T_r, wh_r:>0)


	Nh_l = length(Xh_l)
	Nh_r = length(Xh_r)
	X_lp  = J(N_l,p1,.);	X_rp  = J(N_r,p1,.)
	Xh_lp = J(Nh_l,p1,.);	Xh_rp = J(Nh_r,p1,.)

	for (j=1; j<=p1; j++)  {
		X_lp[.,j]  = (X_l:-c):^(j-1);		X_rp[.,j]  = (X_r:-c):^(j-1)
		Xh_lp[.,j] = (Xh_l:-c):^(j-1);		Xh_rp[.,j] = (Xh_r:-c):^(j-1)
	}
	
	st_numscalar("Nh_l", Nh_l[1,1])
	st_numscalar("Nh_r", Nh_r[1,1])

	if (Nh_l<5 | Nh_r<5){
	 display("{err}Not enough observations to perform calculations")
	 exit(1)
	}
		
	invGamma_lp  = cholinv(quadcross(X_lp,wh_l,X_lp));	invGamma_rp  = cholinv(quadcross(X_rp,wh_r,X_rp))
	invGammah_lp = cholinv(quadcross(Xh_lp,whh_l,Xh_lp));	invGammah_rp = cholinv(quadcross(Xh_rp,whh_r,Xh_rp))
	
	factor_p = J(p1, 1, .)
	
	for (j=1; j<=p1; j++) {
		factor_p[j] = factorial(j-1)
	}
	
	
	tau_lp = factor_p:*(invGammah_lp*quadcross(Xh_lp, whh_l, Yh_l));	tau_rp = factor_p:*(invGammah_rp*quadcross(Xh_rp, whh_r, Yh_r))
	

	tau_cl = tau_rp[`deriv'+1,1] - tau_lp[`deriv'+1,1]

	
	st_numscalar("tau_cl", tau_cl)
	

	tau_T_lp = factor_p:*(invGammah_lp*quadcross(Xh_lp, whh_l, Th_l))
	tau_T_rp = factor_p:*(invGammah_rp*quadcross(Xh_rp, whh_r, Th_r))



	tau_T_cl = tau_T_rp[`deriv'+1,1] - tau_T_lp[`deriv'+1,1]

	st_numscalar("tau_T_cl", tau_T_cl)
	
	tau_F_cl = tau_cl/tau_T_cl

	st_numscalar("tau_F_cl", tau_F_cl)


		}	
	
	
	di in yellow "Preliminary RD calculation completed"
	
	**frdprelim `y' `x', c(`c') deriv(`deriv') fuzzy(`fuzzy') p(`p') q(`q') h(`h') b(`b') kernel(`kernel') bwselect(`bwselect') 
	local tau_F_prelim = tau_F_cl
	local tau_T_prelim = tau_T_cl
	local tau_prelim = tau_cl
	local h_prelim = `h'
	local b_prelim = `b'
	
	local p1 = `p' + 1
	local p2 = `p' + 2
	local q1 = `q' + 1
	local q2 = `q' + 2
	local q3 = `q' + 3
	
	
	

	if ("`kernel'"=="epanechnikov" | "`kernel'"=="epa") {
			local kid=3
			local C_pilot=2.34
	}
	else if ("`kernel'"=="uniform" | "`kernel'"=="uni") {
			local kid=2
			local C_pilot=1.84
	}
	else  {
			local kid=1
			local C_pilot=2.58
	}
	
	kconst `p' `deriv' `kid'
	local C1_h = e(C1)
	local C2_h = e(C2)
	kconst `q' `p1' `kid'
	local C1_b = e(C1)
	local C2_b = e(C2)
	kconst `q1' `q1' `kid'
	local C1_q = e(C1)
	local C2_q = e(C2)
		
	kconst `q' `q' 2
	local C1_b_uni = e(C1)
	local C2_b_uni = e(C2)
	kconst `q1' `q1' 2
	local C1_q_uni = e(C1)
	local C2_q_uni = e(C2)	
	
		
		
	***********************************************************************
	**************************** CCT Approach
	***********************************************************************

	qui su `x', d
	local h_pilot_CCT = `C_pilot'*min(r(sd),(r(p75)-r(p25))/1.349)*r(N)^(-1/5)

	mata{
	h_pilot_CCT=`h_pilot_CCT'
	N_l = `N_l'
	N_r = `N_r'
	p = `p'
	q = `q'
	c = `c'
	C1_h=`C1_h'
	C2_h=`C2_h'
	C1_b=`C1_b'
	C2_b=`C2_b'
	C1_q=`C1_q'
	C2_q=`C2_q'
	
	tau_prelim=`tau_prelim'
	tau_T_prelim=`tau_T_prelim'
	tau_F_prelim=`tau_F_prelim'
	
	deriv = `deriv'
	p1 = p+1;	q1 = q+1;	p2 = p+2;	q2 = q+2;	p3 = p+3;	q3 = q+3
/*
	Y = st_data(.,("`y'"), 0);	X = st_data(.,("`x'"), 0); T = st_data(.,("`fuzzy'"),0)
	X_l = select(X,X:<c);	X_r = select(X,X:>=c)
	Y_l = select(Y,X:<c);	Y_r = select(Y,X:>=c)
	T_l = select(T,X:<c);   T_r = select(T,X:>=c)
*/	
	X_lq2 = J(N_l, q+3, .);	X_rq2 = J(N_r, q+3, .)
	for (j=1; j<=q3; j++) {
		X_lq2[.,j] = (X_l:-c):^(j-1)
		X_rq2[.,j] = (X_r:-c):^(j-1)
	}
	
	X_lq1 = X_lq2[.,1::q2];X_rq1 = X_rq2[.,1::q2]
	X_lq  = X_lq2[.,1::q1];X_rq  = X_rq2[.,1::q1]
	X_lp  = X_lq2[.,1::p1];X_rp  = X_rq2[.,1::p1]

	if ("`bwselect'"=="CCT" | "`bwselect'"=="") {

	display("Computing Fuzzy CCT Bandwidth Selector.")

	*** Step 1: q_F_CCT
	** Outcome **	
	mq3_l = cholinv(quadcross(X_lq2,X_lq2))*quadcross(X_lq2,Y_l)
	mq3_r = cholinv(quadcross(X_rq2,X_rq2))*quadcross(X_rq2,Y_r)
	m4_l_pilot_CCT = mq3_l[`q3',1];	m4_r_pilot_CCT = mq3_r[`q3',1]
	w_hpilot_l = kweight(X_l,c,h_pilot_CCT,"`kernel'")
	w_hpilot_r = kweight(X_r,c,h_pilot_CCT,"`kernel'")
	sigma_l_pilot = altrdvce(X_l, Y_l, Y_l, `p', `h_pilot_CCT', `matches', "`vce'", "`kernel'")
	sigma_r_pilot = altrdvce(X_r, Y_r, Y_r, `p', `h_pilot_CCT', `matches', "`vce'", "`kernel'")
	Gamma_hpilot_lq1 = quadcross(X_lq1, w_hpilot_l, X_lq1)
	Gamma_hpilot_rq1 = quadcross(X_rq1, w_hpilot_r, X_rq1)
	Gamma_hpilot_lq = Gamma_hpilot_lq1[1::`q1',1::`q1']
	Gamma_hpilot_rq = Gamma_hpilot_rq1[1::`q1',1::`q1']
	Gamma_hpilot_lp = Gamma_hpilot_lq1[1::`p1',1::`p1']
	Gamma_hpilot_rp = Gamma_hpilot_rq1[1::`p1',1::`p1']
	
	invGamma_hpilot_lq1 = cholinv(Gamma_hpilot_lq1);	invGamma_hpilot_rq1 = cholinv(Gamma_hpilot_rq1)
	invGamma_hpilot_lq  = cholinv(Gamma_hpilot_lq);	invGamma_hpilot_rq  = cholinv(Gamma_hpilot_rq)
	invGamma_hpilot_lp  = cholinv(Gamma_hpilot_lp);	invGamma_hpilot_rp  = cholinv(Gamma_hpilot_rp)
	Psi_hpilot_lq1 = quadcross(X_lq1, w_hpilot_l:*sigma_l_pilot:*w_hpilot_l, X_lq1)
	Psi_hpilot_rq1 = quadcross(X_rq1, w_hpilot_r:*sigma_r_pilot:*w_hpilot_r, X_rq1)
	Psi_hpilot_lq  = Psi_hpilot_lq1[1::`q1',1::`q1']
	Psi_hpilot_rq  = Psi_hpilot_rq1[1::`q1',1::`q1']
	Psi_hpilot_lp  = Psi_hpilot_lq1[1::`p1',1::`p1']
	Psi_hpilot_rp  = Psi_hpilot_rq1[1::`p1',1::`p1']
	V_m3_hpilot_CCT = (invGamma_hpilot_lq1*Psi_hpilot_lq1*invGamma_hpilot_lq1)[`q'+2,`q'+2]      + (invGamma_hpilot_rq1*Psi_hpilot_rq1*invGamma_hpilot_rq1)[`q'+2,`q'+2]
	V_m2_hpilot_CCT = (invGamma_hpilot_lq*Psi_hpilot_lq*invGamma_hpilot_lq)[`q'+1,`q'+1]         + (invGamma_hpilot_rq*Psi_hpilot_rq*invGamma_hpilot_rq)[`q'+1,`q'+1]
	V_m0_hpilot_CCT = (invGamma_hpilot_lp*Psi_hpilot_lp*invGamma_hpilot_lp)[`deriv'+1,`deriv'+1] + (invGamma_hpilot_rp*Psi_hpilot_rp*invGamma_hpilot_rp)[`deriv'+1,`deriv'+1]
	
	** First stage **
	mq3_T_l = cholinv(quadcross(X_lq2,X_lq2))*quadcross(X_lq2,T_l)
	mq3_T_r = cholinv(quadcross(X_rq2,X_rq2))*quadcross(X_rq2,T_r)
	m4_T_l_pilot_CCT = mq3_T_l[`q3',1];	m4_T_r_pilot_CCT = mq3_T_r[`q3',1]
	sigma_T_l_pilot = altrdvce(X_l, T_l, T_l, `p', `h_pilot_CCT', `matches', "`vce'", "`kernel'")
	sigma_T_r_pilot = altrdvce(X_r, T_r, T_r, `p', `h_pilot_CCT', `matches', "`vce'", "`kernel'")
	Psi_hpilot_T_lq1 = quadcross(X_lq1, w_hpilot_l:*sigma_T_l_pilot:*w_hpilot_l, X_lq1)
	Psi_hpilot_T_rq1 = quadcross(X_rq1, w_hpilot_r:*sigma_T_r_pilot:*w_hpilot_r, X_rq1)
	Psi_hpilot_T_lq  = Psi_hpilot_T_lq1[1::`q1',1::`q1']
	Psi_hpilot_T_rq  = Psi_hpilot_T_rq1[1::`q1',1::`q1']
	Psi_hpilot_T_lp  = Psi_hpilot_T_lq1[1::`p1',1::`p1']
	Psi_hpilot_T_rp  = Psi_hpilot_T_rq1[1::`p1',1::`p1']
	V_m3_hpilot_T_CCT = (invGamma_hpilot_lq1*Psi_hpilot_T_lq1*invGamma_hpilot_lq1)[`q'+2,`q'+2]      + (invGamma_hpilot_rq1*Psi_hpilot_T_rq1*invGamma_hpilot_rq1)[`q'+2,`q'+2]
	V_m2_hpilot_T_CCT = (invGamma_hpilot_lq*Psi_hpilot_T_lq*invGamma_hpilot_lq)[`q'+1,`q'+1]         + (invGamma_hpilot_rq*Psi_hpilot_T_rq*invGamma_hpilot_rq)[`q'+1,`q'+1]
	V_m0_hpilot_T_CCT = (invGamma_hpilot_lp*Psi_hpilot_T_lp*invGamma_hpilot_lp)[`deriv'+1,`deriv'+1] + (invGamma_hpilot_rp*Psi_hpilot_T_rp*invGamma_hpilot_rp)[`deriv'+1,`deriv'+1]

	
	** Covariance **
	sigma_TY_l_pilot = altrdvce(X_l, T_l, Y_l, `p', `h_pilot_CCT',`matches',"`vce'","`kernel'")
	sigma_TY_r_pilot = altrdvce(X_r, T_r, Y_r, `p', `h_pilot_CCT',`matches',"`vce'","`kernel'")

	Psi_hpilot_TY_lq1 = quadcross(X_lq1, w_hpilot_l:*sigma_TY_l_pilot:*w_hpilot_l, X_lq1)
	Psi_hpilot_TY_rq1 = quadcross(X_rq1, w_hpilot_r:*sigma_TY_r_pilot:*w_hpilot_r, X_rq1)		
	Psi_hpilot_TY_lq  = Psi_hpilot_TY_lq1[1::`q1',1::`q1']
	Psi_hpilot_TY_rq  = Psi_hpilot_TY_rq1[1::`q1',1::`q1']
	Psi_hpilot_TY_lp  = Psi_hpilot_TY_lq1[1::`p1',1::`p1']
	Psi_hpilot_TY_rp  = Psi_hpilot_TY_rq1[1::`p1',1::`p1']
	
	V_m3_hpilot_TY_CCT = (invGamma_hpilot_lq1*Psi_hpilot_TY_lq1*invGamma_hpilot_lq1)[`q'+2,`q'+2]      + (invGamma_hpilot_rq1*Psi_hpilot_TY_rq1*invGamma_hpilot_rq1)[`q'+2,`q'+2]
	V_m2_hpilot_TY_CCT = (invGamma_hpilot_lq*Psi_hpilot_TY_lq*invGamma_hpilot_lq)[`q'+1,`q'+1]         + (invGamma_hpilot_rq*Psi_hpilot_TY_rq*invGamma_hpilot_rq)[`q'+1,`q'+1]
	V_m0_hpilot_TY_CCT = (invGamma_hpilot_lp*Psi_hpilot_TY_lp*invGamma_hpilot_lp)[`deriv'+1,`deriv'+1] + (invGamma_hpilot_rp*Psi_hpilot_TY_rp*invGamma_hpilot_rp)[`deriv'+1,`deriv'+1]

	** fuzzy variance **
	V_m3_hpilot_F_CCT = (1/tau_T_prelim^2)*V_m3_hpilot_CCT + (tau_prelim^2/tau_T_prelim^4)*V_m3_hpilot_T_CCT - (2*tau_prelim/tau_T_prelim^3)*V_m3_hpilot_TY_CCT
	V_m2_hpilot_F_CCT = (1/tau_T_prelim^2)*V_m2_hpilot_CCT + (tau_prelim^2/tau_T_prelim^4)*V_m2_hpilot_T_CCT - (2*tau_prelim/tau_T_prelim^3)*V_m2_hpilot_TY_CCT
	V_m0_hpilot_F_CCT = (1/tau_T_prelim^2)*V_m0_hpilot_CCT + (tau_prelim^2/tau_T_prelim^4)*V_m0_hpilot_T_CCT - (2*tau_prelim/tau_T_prelim^3)*V_m0_hpilot_TY_CCT

	** bandwidth **
	
	N_q_F_CCT=(2*`q1'+1)*`N'*`h_pilot_CCT'^(2*`q'+3)*V_m3_hpilot_F_CCT
	*D_q_CCT=2*(`q1'+1-`q1')*(C1_q*(m4_r_pilot_CCT+m4_l_pilot_CCT))^2
	D_q_F_CCT=2*(`q1'+1-`q1')*(C1_q*(1/tau_T_prelim*(m4_r_pilot_CCT-(-1)^(deriv+q)*m4_l_pilot_CCT)-tau_prelim/tau_T_prelim^2*(m4_T_r_pilot_CCT-(-1)^(deriv+q)*m4_T_l_pilot_CCT)))^2	
	q_F_CCT=(N_q_F_CCT/(`N'*D_q_F_CCT))^(1/(2*`q'+5))

	*** Step 2: b_CCT
	** commented out the regularization stuff for now
	
	** Outcome **
	w_q_l=kweight(X_l,c,q_F_CCT,"`kernel'")
	w_q_r=kweight(X_r,c,q_F_CCT,"`kernel'")
	*invGamma_q_lq1_CCT = cholinv(quadcross(X_lq1, w_q_l, X_lq1))
	*invGamma_q_rq1_CCT = cholinv(quadcross(X_rq1, w_q_r, X_rq1))
	*Psi_q_lq1_CCT = quadcross(X_lq1, w_q_l:*sigma_l_pilot:*w_q_l, X_lq1)
	*Psi_q_rq1_CCT = quadcross(X_rq1, w_q_r:*sigma_r_pilot:*w_q_r, X_rq1)
	*V_m3_q_CCT = (invGamma_q_lq1_CCT*Psi_q_lq1_CCT*invGamma_q_lq1_CCT)[`q'+2,`q'+2] + (invGamma_q_rq1_CCT*Psi_q_rq1_CCT*invGamma_q_rq1_CCT)[`q'+2,`q'+2]
		
	m_lq_CCT = cholinv(quadcross(X_lq1, w_q_l, X_lq1))*quadcross(X_lq1, w_q_l, Y_l)
	m_rq_CCT = cholinv(quadcross(X_rq1, w_q_r, X_rq1))*quadcross(X_rq1, w_q_r, Y_r)
	*V_m3_q_CCT= V_m3_q_CCT[1,1]
	m3_l_CCT= m_lq_CCT[q2,1]
	m3_r_CCT= m_rq_CCT[q2,1]
	
	** First stage **
	m_T_lq_CCT = cholinv(quadcross(X_lq1, w_q_l, X_lq1))*quadcross(X_lq1, w_q_l, T_l)
	m_T_rq_CCT = cholinv(quadcross(X_rq1, w_q_r, X_rq1))*quadcross(X_rq1, w_q_r, T_r)	

	m3_T_l_CCT = m_T_lq_CCT[q2,1]	
	m3_T_r_CCT = m_T_rq_CCT[q2,1]	
	
	** bandwidth **
	
	D_b_F_CCT=  2*(q-p)*(C1_b*(1/tau_T_prelim*(m3_r_CCT - (-1)^(deriv+q+1)*m3_l_CCT)-tau_prelim/tau_T_prelim^2*(m3_T_r_CCT - (-1)^(deriv+q+1)*m3_T_l_CCT)))^2                        
	N_b_F_CCT=  (2*p+3)*`N'*`h_pilot_CCT'^(2*`p'+3)*V_m2_hpilot_F_CCT
	*R_b_CCT=  `scaleregul'*2*(q-p)*C1_b^2*3*V_m3_q_CCT
	*b_CCT= (N_b_CCT / (`N'*(D_b_CCT + R_b_CCT)))^(1/(2*`q'+3))
	b_F_CCT= (N_b_F_CCT / (`N'*D_b_F_CCT))^(1/(2*`q'+3))
		
	*** Step 3: h_CCT
	** Outcome **
	w_b_l=kweight(X_l,`c',b_F_CCT,"`kernel'")
	w_b_r=kweight(X_r,`c',b_F_CCT,"`kernel'")
	*invGamma_b_lq_CCT = cholinv(quadcross(X_lq, w_b_l, X_lq))
	*invGamma_b_rq_CCT = cholinv(quadcross(X_rq, w_b_r, X_rq))
	*Psi_b_lq_CCT    = quadcross(X_lq, w_b_l:*sigma_l_pilot:*w_b_l, X_lq)
	*Psi_b_rq_CCT = quadcross(X_rq, w_b_r:*sigma_r_pilot:*w_b_r, X_rq)
	*V_m2_b_CCT = (invGamma_b_lq_CCT*Psi_b_lq_CCT*invGamma_b_lq_CCT)[`p2',`p2'] + (invGamma_b_rq_CCT*Psi_b_rq_CCT*invGamma_b_rq_CCT)[`p2',`p2']
	
	m_l_CCT = cholinv(quadcross(X_lq, w_b_l, X_lq))*quadcross(X_lq, w_b_l, Y_l)
	m_r_CCT = cholinv(quadcross(X_rq, w_b_r, X_rq))*quadcross(X_rq, w_b_r, Y_r)
	*V_m2_b_CCT = V_m2_b_CCT[1,1]
	m2_l_CCT= m_l_CCT[`p2',1]
	m2_r_CCT= m_r_CCT[`p2',1]
	
	** First stage **
	m_T_l_CCT = cholinv(quadcross(X_lq, w_b_l, X_lq))*quadcross(X_lq, w_b_l, T_l)
	m_T_r_CCT = cholinv(quadcross(X_rq, w_b_r, X_rq))*quadcross(X_rq, w_b_r, T_r)
	
	m2_T_l_CCT= m_T_l_CCT[`p2',1]
	m2_T_r_CCT= m_T_r_CCT[`p2',1]
	
	** Bandwidth **
	D_h_F_CCT = 2*(`p'+1-`deriv')*(C1_h*(1/tau_T_prelim*(m2_r_CCT - (-1)^(deriv+p+1)*m2_l_CCT)-tau_prelim/tau_T_prelim^2*(m2_T_r_CCT - (-1)^(deriv+p+1)*m2_T_l_CCT)))^2
	N_h_F_CCT = (2*`deriv'+1)*`N'*`h_pilot_CCT'^(2*`deriv'+1)*V_m0_hpilot_F_CCT
	*R_h_CCT = `scaleregul'*2*(`p'+1-`deriv')*(C1_h)^2*3*V_m2_b_CCT
	h_F_CCT = (N_h_F_CCT / (`N'*D_h_F_CCT))^(1/(2*`p'+3))

	st_numscalar("h_F_CCT",h_F_CCT)
	st_numscalar("q_F_CCT",q_F_CCT)
	
	if (`b_calc'==0) {
		b_F_CCT = h_F_CCT/`rho'
	}
	st_numscalar("b_F_CCT",b_F_CCT)
	}
	

	***************************************************************************************************
	******************** IK
	**************************************************************************************************
	if ("`bwselect'"=="IK") {

	display("Computing IK Bandwidth Selector.")
	
	C1_b_uni=`C1_b_uni'
	C2_b_uni=`C2_b_uni'
	C1_q_uni=`C1_q_uni'
	C2_q_uni=`C2_q_uni'
	
	** Density Variance Estimation **
	h_pilot_IK = 1.84*sqrt(variance(X))*length(X)^(-1/5)
	n_l_h1 = length(select(X_l,X_l:>=`c'-h_pilot_IK))
	n_r_h1 = length(select(X_r,X_r:<=`c'+h_pilot_IK))

	** Density **
	f0_pilot=(n_r_h1+n_l_h1)/(2*`N'*h_pilot_IK)
	
	** Variance and Covariance **

	varmat_l=variance((select(Y_l,X_l:>=`c'-h_pilot_IK),select(T_l,X_l:>=`c'-h_pilot_IK)))

	s2_l_pilot = varmat_l[1,1]
	s2_T_l_pilot = varmat_l[2,2]
	s_TY_l_pilot = varmat_l[2,1]	
	
	if (s2_l_pilot==0){

		varmat_l=variance((select(Y_l,X_l:>=`c'-2*h_pilot_IK),select(T_l,X_l:>=`c'-2*h_pilot_IK)))

		s2_l_pilot = varmat_l[1,1]
		s2_T_l_pilot = varmat_l[2,2]
		s_TY_l_pilot = varmat_l[2,1]	
										}
	
	varmat_r=variance((select(Y_r,X_r:<=`c'+h_pilot_IK),select(T_r,X_r:<=`c'+h_pilot_IK)))	
	s2_r_pilot = varmat_r[1,1]
	s2_T_r_pilot = varmat_r[2,2]
	s_TY_r_pilot = varmat_r[2,1]	

	if (s2_r_pilot==0){
	

		varmat_r=variance((select(Y_r,X_r:<=`c'+2*h_pilot_IK),select(T_r,X_r:<=`c'+2*h_pilot_IK)))	
		s2_r_pilot = varmat_r[1,1]
		s2_T_r_pilot = varmat_r[2,2]
		s_TY_r_pilot = varmat_r[2,1]	
										}	
	
	V_F_IK_pilot = ((s2_r_pilot+s2_l_pilot)/tau_T_prelim^2-2*tau_prelim/tau_T_prelim^3*(s_TY_r_pilot+s_TY_l_pilot)+tau_prelim^2/tau_T_prelim^4*(s2_T_r_pilot+s2_T_l_pilot))/f0_pilot
	Vm0_pilot_F_IK = C2_h*V_F_IK_pilot
	Vm2_pilot_F_IK = C2_b*V_F_IK_pilot
	

	* Select Median Sample to compute derivative (as in IK code)
	x_IK_med_l = select(X_l,X_l:>=`medX_l'); y_IK_med_l = select(Y_l,X_l:>=`medX_l'); t_IK_med_l = select(T_l,X_l:>=`medX_l')
	x_IK_med_r = select(X_r,X_r:<=`medX_r'); y_IK_med_r = select(Y_r,X_r:<=`medX_r'); t_IK_med_r = select(T_r,X_r:<=`medX_r')
	x_IK_med = x_IK_med_r \ x_IK_med_l
	y_IK_med = y_IK_med_r \ y_IK_med_l
	t_IK_med = t_IK_med_r \ t_IK_med_l
	
	sample_IK = length(x_IK_med)
	X_IK_med_q2 = J(sample_IK, `q3', .)
	for (j=1; j<= `q3' ; j++) {
			X_IK_med_q2[.,j] = (x_IK_med:-`c'):^(j-1)
	}
	X_IK_med_q1 = X_IK_med_q2[.,1::`q2']
	
	* Add cutoff dummy multiplied by polynomial term of X, depending on the design
	X_IK_med_q2 = (X_IK_med_q2, (x_IK_med:>=c):*((x_IK_med:-`c'):^(`deriv')))
	X_IK_med_q1 = (X_IK_med_q1, (x_IK_med:>=c):*((x_IK_med:-`c'):^(`deriv')))
	
	*** Compute b_IK
	* Pilot Bandwidth
		N_q_r_pilot_IK = (2*q+3)*C2_q_uni*(s2_r_pilot/f0_pilot)
		N_q_l_pilot_IK = (2*q+3)*C2_q_uni*(s2_l_pilot/f0_pilot)

		m4_pilot_IK = (cholinv(quadcross(X_IK_med_q2, X_IK_med_q2))*quadcross(X_IK_med_q2, y_IK_med))[q+3,1]
		m4_T_pilot_IK = (cholinv(quadcross(X_IK_med_q2, X_IK_med_q2))*quadcross(X_IK_med_q2, t_IK_med))[q+3,1]
		D_q_pilot_IK = 2*(C1_q_uni*m4_pilot_IK)^2
		D_q_T_pilot_IK = 2*(C1_q_uni*m4_T_pilot_IK)^2
		h3_r_pilot_IK = (N_q_r_pilot_IK / (N_r*D_q_pilot_IK))^(1/(2*q+5))
		h3_l_pilot_IK = (N_q_l_pilot_IK / (N_l*D_q_pilot_IK))^(1/(2*q+5))
		h3_T_r_pilot_IK = (N_q_r_pilot_IK / (N_r*D_q_T_pilot_IK))^(1/(2*q+5))
		h3_T_l_pilot_IK = (N_q_l_pilot_IK / (N_l*D_q_T_pilot_IK))^(1/(2*q+5))
	* Data for derivative
		X_lq_IK_h3=select(X_lq1,X_l:>=c-h3_l_pilot_IK); Y_l_IK_h3 =select(Y_l,X_l:>=c-h3_l_pilot_IK); T_l_IK_h3 =select(T_l,X_l:>=c-h3_T_l_pilot_IK)
		X_rq_IK_h3=select(X_rq1,X_r:<=c+h3_r_pilot_IK);	Y_r_IK_h3 =select(Y_r,X_r:<=c+h3_r_pilot_IK); T_r_IK_h3 =select(T_r,X_r:<=c+h3_T_r_pilot_IK)
		X_T_lq_IK_h3=select(X_lq1,X_l:>=c-h3_T_l_pilot_IK); X_T_rq_IK_h3=select(X_rq1,X_r:<=c+h3_T_r_pilot_IK)
		
		m3_l_IK = (cholinv(quadcross(X_lq_IK_h3, X_lq_IK_h3))*quadcross(X_lq_IK_h3, Y_l_IK_h3))[q+2,1]
		m3_r_IK = (cholinv(quadcross(X_rq_IK_h3, X_rq_IK_h3))*quadcross(X_rq_IK_h3, Y_r_IK_h3))[q+2,1]
		m3_T_l_IK = (cholinv(quadcross(X_T_lq_IK_h3, X_T_lq_IK_h3))*quadcross(X_T_lq_IK_h3, T_l_IK_h3))[q+2,1]
		m3_T_r_IK = (cholinv(quadcross(X_T_rq_IK_h3, X_T_rq_IK_h3))*quadcross(X_T_rq_IK_h3, T_r_IK_h3))[q+2,1]				
		D_b_F_IK = 2*(q-p)*(C1_b*(1/tau_T_prelim*(m3_r_IK - (-1)^(deriv+q+1)*m3_l_IK)-tau_prelim/tau_T_prelim^2*(m3_T_r_IK - (-1)^(deriv+q+1)*m3_T_l_IK)))^2	
		N_b_F_IK = (2*p+3)*Vm2_pilot_F_IK
	* Regularization
	/***
		temp = regconst(`q1',1)
		con = temp[`q2',`q2']
		n_l_h3 = length(Y_l_IK_h3);	n_r_h3 = length(Y_r_IK_h3)
		r_l_b = (con*s2_l_pilot)/(n_l_h3*h3_l_pilot_IK^(2*`q1'))
		r_r_b = (con*s2_r_pilot)/(n_r_h3*h3_r_pilot_IK^(2*`q1'))
		R_b_IK = `scaleregul'*2*(q-p)*C1_b^2*3*(r_l_b + r_r_b)
	***/	
	* Final bandwidth:
		b_F_IK   = (N_b_F_IK / (`N'*D_b_F_IK ))^(1/(2*q+3))

	*** Step 3: h_IK	
	* Pilot Bandwidth
	N_b_r_pilot_IK = (2*p+3)*C2_b_uni*(s2_r_pilot/f0_pilot)
	N_b_l_pilot_IK = (2*p+3)*C2_b_uni*(s2_l_pilot/f0_pilot)	
	
	m3_pilot_IK = (cholinv(quadcross(X_IK_med_q1, X_IK_med_q1))*quadcross(X_IK_med_q1, y_IK_med))[q+2,1]
	m3_T_pilot_IK = (cholinv(quadcross(X_IK_med_q1, X_IK_med_q1))*quadcross(X_IK_med_q1, t_IK_med))[q+2,1]
	D_b_pilot_IK = 2*(q-p)*(C1_b_uni*m3_pilot_IK)^2
	D_b_T_pilot_IK = 2*(q-p)*(C1_b_uni*m3_T_pilot_IK)^2	
	h2_l_pilot_IK  = (N_b_l_pilot_IK / (N_l*D_b_pilot_IK))^(1/(2*q+3))
	h2_r_pilot_IK  = (N_b_r_pilot_IK / (N_r*D_b_pilot_IK))^(1/(2*q+3))
	h2_T_l_pilot_IK  = (N_b_l_pilot_IK / (N_l*D_b_T_pilot_IK))^(1/(2*q+3))
	h2_T_r_pilot_IK  = (N_b_r_pilot_IK / (N_r*D_b_T_pilot_IK))^(1/(2*q+3))	
	
	* Data for derivative
	X_lq_IK_h2=select(X_lq,X_l:>=c-h2_l_pilot_IK); Y_l_IK_h2 =select(Y_l,X_l:>=c-h2_l_pilot_IK); T_l_IK_h2 =select(T_l,X_l:>=c-h2_T_l_pilot_IK)
	X_rq_IK_h2=select(X_rq,X_r:<=c+h2_r_pilot_IK); Y_r_IK_h2 =select(Y_r,X_r:<=c+h2_r_pilot_IK); T_r_IK_h2 =select(T_r,X_r:<=c+h2_T_r_pilot_IK)
	X_T_lq_IK_h2=select(X_lq,X_l:>=c-h2_T_l_pilot_IK); X_T_rq_IK_h2=select(X_rq,X_r:<=c+h2_T_r_pilot_IK)
	
	m2_l_IK = (cholinv(quadcross(X_lq_IK_h2, X_lq_IK_h2))*quadcross(X_lq_IK_h2, Y_l_IK_h2))[p+2,1]
	m2_r_IK = (cholinv(quadcross(X_rq_IK_h2, X_rq_IK_h2))*quadcross(X_rq_IK_h2, Y_r_IK_h2))[p+2,1]
	m2_T_l_IK = (cholinv(quadcross(X_T_lq_IK_h2, X_T_lq_IK_h2))*quadcross(X_T_lq_IK_h2, T_l_IK_h2))[p+2,1]
	m2_T_r_IK = (cholinv(quadcross(X_T_rq_IK_h2, X_T_rq_IK_h2))*quadcross(X_T_rq_IK_h2, T_r_IK_h2))[p+2,1]		
	
	* Bandwidth
	D_h_F_IK = 2*(`p'+1-`deriv')*(C1_h*(1/tau_T_prelim*(m2_r_IK - (-1)^(deriv+p+1)*m2_l_IK)-tau_prelim/tau_T_prelim^2*(m2_T_r_IK - (-1)^(deriv+p+1)*m2_T_l_IK)))^2
	N_h_F_IK = (2*`deriv'+1)*Vm0_pilot_F_IK
	h_F_IK = (N_h_F_IK / (`N'*D_h_F_IK))^(1/(2*p+3))	

	st_numscalar("h_F_IK", h_F_IK)
	st_numscalar("b_F_IK", b_F_IK)
	
	if (`b_calc'==0) {
		b_F_IK = h_F_IK/`rho'
	}
	st_numscalar("b_F_IK",b_F_IK)
	}

	}

	*******************************************************************************

	disp ""
	disp in smcl in gr "Bandwidth Estimators for RD Local Polynomial Regression" 
	disp ""
	disp ""
	disp in smcl in gr "{ralign 21: Cutoff c = `c'}"      _col(22) " {c |} " _col(23) in gr "Left of " in yellow "c"  _col(36) in gr "Right of " in yellow "c" _col(61) in gr "Number of obs  = "  in yellow %10.0f `N_l'+`N_r'
	disp in smcl in gr "{hline 22}{c +}{hline 22}"                                                                                                             _col(61) in gr "NN Matches     = "  in yellow %10.0f `matches'
	disp in smcl in gr "{ralign 21:Number of obs}"        _col(22) " {c |} " _col(23) as result %9.0f `N_l'   _col(37) %9.0f  `N_r'                            _col(61) in gr "Kernel Type    = "  in yellow "{ralign 10:`kernel_type'}" 

	disp in smcl in gr "{ralign 21:Order Loc. Poly. (p)}" _col(22) " {c |} " _col(23) as result %9.0f `p'        _col(37) %9.0f  `p'                              
	disp in smcl in gr "{ralign 21:Order Bias (q)}"       _col(22) " {c |} " _col(23) as result %9.0f `q'        _col(37) %9.0f  `q'  
	disp in smcl in gr "{ralign 21:Range of `x'}"         _col(22) " {c |} " _col(23) as result %9.3f `range_l'  _col(37) %9.3f  `range_r'                               

	
	disp ""
	disp in smcl in gr "{hline 10}{c TT}{hline 35}" 
	disp in smcl in gr "{ralign 9:Method}"   _col(10) " {c |} " _col(18) "h" _col(30) "b" _col(41) "rho" _n  "{hline 10}{c +}{hline 35}"
	if ("`bwselect'"=="IK")  {
	disp in smcl in gr "{ralign 9:IK }"      _col(10) " {c |} " _col(11) in ye %9.0g h_F_IK  _col(25) in ye %9.0g b_F_IK  _col(38) in ye %9.0g h_F_IK/b_F_IK
	}
	if ("`bwselect'"=="") | ("`bwselect'"=="CCT") {
		disp in smcl in gr "{ralign 9:CCT}"      _col(10) " {c |} " _col(11) in ye %9.0g h_F_CCT _col(25) in ye %9.0g b_F_CCT _col(38) in ye %9.0g h_F_CCT/b_F_CCT
	}
	disp in smcl in gr "{hline 10}{c BT}{hline 35}"

	disp "In comparison, the h and b obtained by treating the outcome equation as a sharp design are `h_prelim' and `b_prelim' respectively."
	
	restore
	return clear
	return scalar N_l = `N_l'
	return scalar N_r = `N_r'
	return scalar c = `c'
	return scalar p = `p'
	return scalar q = `q'
	
	if ("`bwselect'"=="CCT" | "`bwselect'"=="") {
	return scalar h_F_CCT = h_F_CCT
	return scalar b_F_CCT = b_F_CCT
	}
	if ("`bwselect'"=="IK") {
	return scalar h_F_IK   = h_F_IK
	return scalar b_F_IK   = b_F_IK
	}
	
	return scalar h_prelim = `h_prelim'
	return scalar b_prelim = `b_prelim'
	
	*mata mata clear

end


