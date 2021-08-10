*! xthst
*! Version 1.4 - 08.01.2021
*! Tore Bersvendsen (University of Agder) tore.bersvendsen@uia.no
*! Jan Ditzen (Free University of Bozen-Bolzano) jan.ditzen@unibz.it, www.jan.ditzen.net 

/*
Version History
	- 22.12.2019 - error in deltatesthac; for calculation of xbar was removed twice.
				 - Test for PY is two sided, for BW one sided?! 
				 - Qi Vi Qi needs to be cacluated within the i-loops. 
	- 17.01.2020 - bug fix in deltahac; wrong initial gamma and divided by incorrect number of periods
				 - bug fix in deltacalc; divided by incorrect number of periods
	- 28.01.2020 - corrected output with tempvars and cross-sectional variables
	- 13.05.2020 - added comparehac option and xthst_compare program
	- 08.01.2021 - bug if CSA used, all variables were removed.
*/

capture program drop xthst
program define xthst, rclass sortpreserve
	syntax varlist(min=2 ts) [if] , [partial(varlist ts) NOCONStant ar hac bw(integer -999) WHITEning kernel(string) CRosssectional(string) NOOUTput COMPAREHac]
	
	version 14
	
	qui{
		
		local lhsrhs `varlist'

		if "`comparehac'" != "" {
			noi xthst_compare `varlist' `if' , `noconstant' `ar' partial(`partial') `ar' bw(`bw') `whitening' kernel(`kernel') cross(`crosssectional')
			exit
		}
		
		if "`whitening'" != "" & "`hac'" == "" {
			local hac hac
		}
		
		if "`bw'" != "-999" & "`hac'" == "" {
			local hac hac
		}
		
		if "`hac'" != "" & "`bw'" == "-999" {
			local bw = -1
		}
		
		if "`hac'" == "hac" & "`ar'" == "ar" {
			noi disp as error "Option hac and ar cannot be combined." ,_c
			error 184
			exit
		}
		
		if "`kernel'" == "" {
			local kernel "bartlett"
		}
		else {
			if "`kernel'" != "qs" & "`kernel'" != "bartlett" & "`kernel'" != "truncated" {
				noi disp as smcl "`kernel' is an invalid kernel. Only {it:qs}, {it:truncated} or {it:bartlett} as kernels are allowed."
				exit
			} 
		}
		tempvar touse	
		marksample touse
		
		qui xtset
		local idvar "`r(panelvar)'"
		local tvar "`r(timevar)'"	
		sort `idvar' `tvar'
		
		*** Create cross-sectional averages if requested
		if "`crosssectional'" != "" {
			local 0 `crosssectional'
			syntax varlist(ts) , [cr_lags(numlist)]
			local crosssectional `varlist'
			tempname csa
				if "`cr_lags'" == "" {
					local cr_lags = 0
				}
				xtdcce2_csa `crosssectional' , idvar(`idvar') tvar(`tvar') cr_lags(`cr_lags') touse(`touse') csa(`csa')			
				local csa `r(varlist)'	
				local cross_structure "`r(cross_structure)'"
				markout `touse' `csa'	
		}		
		
		*** check for partial vars
		if "`partial'" != "" {
			** make sure partialled out vars do not appear on rhs
			local lhsrhs: list lhsrhs - partial
			
			tsrevar `partial'
			local partial `r(varlist)'
		}

		*** check for time series variables and generate tempvar
		tsrevar `lhsrhs'
		tokenize `r(varlist)'
			
		local lhs `1'
		macro shift
		local rhs `*'
		
		if "`noconstant'" == "" {
			tempvar const
			gen double `const' = 1
			local partial `partial' `const'
		}
		
		*** start mata program here
		tempname delta delta_st delta_adj 
		if "`hac'" == "" {
			 mata st_matrix("`delta'",deltatest("`lhs'","`rhs'","`partial' `csa'","`idvar' `tvar'","`touse'",`=("`ar'"=="ar")'))
		}
		else {
			 mata st_matrix("`delta'",deltatesthac("`lhs'","`rhs'","`partial' `csa'","`idvar' `tvar'","`touse'",`bw',`=("`whitening'"=="whitening")',"`kernel'"))
			local bw = `delta'[3,1]	
		}
	}
	*** Output	
	scalar `delta_adj' = `delta'[2,1]
	scalar `delta_st' = `delta'[1,1]	
	
	local partial = subinstr("`partial'","`const'","constant",.)
	if wordcount("`cr_lags'") > 1 {
		local crosssectional_output "`cross_structure'"
	}
	else {
		local crosssectional_output "`crosssectional'"
	}
	
	*** Disagreement between PY and BW. In PY delta is two sided N(0,1) [ see p. 64, above 5.1]; in BW it is one-sided N(0,1); see footnote Tab 1; keep two sided
	if "`hac'" == "" {
		local twosided = 2
	}
	else {
		local twosided = 2
	}	
	
	if "`nooutput'" == "" {
		noi disp as text "Testing for slope heterogeneity"
		if "`hac'" == "" {
			noi disp as text "(Pesaran, Yamagata. 2008. Journal of Econometrics)"
			
		}
		else {
			noi disp as text "(Blomquist, Westerlund. 2013. Economic Letters)"
		}
		
		noi disp "H0: slope coefficients are homogenous"
		di as text "{hline 37}"
		noi disp as result _col(10) "Delta" _col(25) "p-value"
		noi disp as result  _col(7) %9.3f `delta_st' _col(23) %9.3f `twosided'*(1-normal(abs(`delta_st')))
		noi disp as result  _col(2) "adj." _col(7) %9.3f `delta_adj'  _col(23) %9.3f `twosided'*(1-normal(abs(`delta_adj')))
		di as text "{hline 37}"
		if "`hac'" != "" {
			if "`kernel'" == "qs" { 
				local kernel "quadratic spectral (QS)"
			}
			noi disp as txt "HAC Kernel: `kernel' "
			noi disp as txt "with average bandwith " `bw'
		}
		if "`partial'" != "" {
			
			noi disp "Variables partialled out: `partial'"
		}
		if "`crosssectional'" != "" {
			
			display  as text "Cross Sectional Averaged Variables: `crosssectional_output'"
		}
	}
	
	*** Return
	return clear
	matrix `delta' = (`delta_st' \ `delta_adj')
	matrix rownames `delta' = Delta Delta_adjusted
	matrix colnames `delta' = TestStat.
	return matrix delta = `delta'
	
	tempname delta_p
	matrix `delta_p' = `twosided'*(1-normal(abs(`delta_st'))) \ `twosided'*(1-normal(abs(`delta_adj')))
	matrix rownames `delta_p' = Delta Delta_adjusted
	matrix colnames `delta_p' = p-Value
	
	return matrix delta_p = `delta_p'
	
	if "`hac'" != "" {
		return scalar bw = `bw'
		return local kernel "`kernel'"
	}
	if "`partial'" != "" {
		return local partial "`partial'"
	}
	if "`crosssectional_output'" != "" {
		return local crosssectional "`crosssectional_output'"
	}
	
	 
end
/*
Steps
1. partial out
2. calculate fixed effect estimator
3. calculate sigma2i, beta2i, gives beta2wfe
4. calcualte s_tilde
5. calculate delta

*/

mata:
	function deltatest ( string scalar lhsname,		/// lhs variable
							string scalar rhsname,		/// rhs variables
							string scalar rhspartialname,	/// variables to be partialled out
							string scalar idtname, 		/// id and t variables
							string scalar tousename,	/// touse variable			
							real scalar ar)				/// 1 if ar, 0 if not ar
							
	{
		real matrix Y
		real matrix X
		real matrix idt
		real scalar Nuniq
		real scalar N_g

		/// load data
		Y = st_data(.,lhsname,tousename)
		X = st_data(.,rhsname,tousename)
		
		idt = st_data(.,idtname,tousename)

		
		K1 = 0
		Z = .

		if (rhspartialname[1,1]:!= " ") {
			Z = st_data(.,rhspartialname,tousename)
			K1 = cols(Z)		
		}
		
		Nuniq = uniqrows(idt[.,1])
		N_g = rows(Nuniq)
		K = cols(X)		
		Kpartial = 0
		/// set it as panel, for N_g dimension
		index = panelsetup(idt[.,1],1)
		
		/// 1. Partialling out
		if (Z[1,1] != .) {
			i = 1
			Kpartial = cols(Z)
			while (i<=N_g) {
				starti = index[i,1]
				endi = index[i,2]
				
				Yi = Y[(starti..endi),.]
				Xi = X[(starti..endi),.]
				Zi = Z[(starti..endi),.]
				
				/// partialling out
				tmp_zz = quadcross(Zi,Zi)
				tmp_zz1 = invsym(tmp_zz)
				
				Y[(starti..endi),.] = Yi - Zi * tmp_zz1*quadcross(Zi,Yi)
				X[(starti..endi),.] = Xi - Zi * tmp_zz1*quadcross(Zi,Xi)
				
				i++
			}

		}
		
		if (ar==1) {
			Kpartial = 0
		}
		
		//// 2 Fe estimates
		tmp_xx = quadcross(X,X)
		tmp_xy = quadcross(X,Y)
		tmp_xx1 = invsym(tmp_xx)
		b_fe = tmp_xx1 * tmp_xy
		resid = Y - X * b_fe
		
		
		
		/// 3 calcualte sigma2i, beta2i, gives beta2wfe
		sigma2 = J(N_g,1,.)
		beta2i = J(N_g,K,.)
		
		beta2wfe_up = 0
		beta2wfe_low = J(1,K,0)
		Tavg = 0
		i = 1
		while (i<=N_g) {
			starti = index[i,1]
			endi = index[i,2]

			Yi = Y[(starti..endi),.]
			Xi = X[(starti..endi),.]
			residi = resid[(starti..endi),.]
			Ti = rows(Xi)
			
			Ki = cols(Xi)
	
			sigma2[i] =  residi'residi :/ (Ti - Kpartial)
			///corrected sigma2[i] =  residi'residi :/ (Ti - Kpartial-1)
			
			tmp_xx = quadcross(Xi,Xi)
			tmp_xx1 = invsym(tmp_xx)
			tmp_xy = quadcross(Xi,Yi)
	
			beta2i[i,.] = (tmp_xx1*tmp_xy)'
			beta2wfe_up = beta2wfe_up :+ tmp_xy :/ sigma2[i]
			beta2wfe_low = beta2wfe_low :+  tmp_xx :/sigma2[i]
			
			Tavg = Tavg + Ti
			
			i++
		}
		
		Tavg = Tavg / N_g
		
		beta2wfe_low = invsym(beta2wfe_low)
		
		beta2wfe = beta2wfe_low * beta2wfe_up 
		/// 4. calcualte s_tilde
		S_tilde = 0
		i = 1

		
		while (i <= N_g) {
			starti = index[i,1]
			endi = index[i,2]
			Xi = X[(starti..endi),.]
			beta_i = beta2i[i,.]'
			
			tmp_xx = quadcross(Xi,Xi) :/ sigma2[i]

			S_tilde = S_tilde + (beta_i - beta2wfe)' * tmp_xx * (beta_i - beta2wfe)			
			i++
		}

		delta = sqrt(N_g) * (S_tilde/N_g - K) / sqrt(2*K)

		var = 2 * K * (Tavg-K-Kpartial-1)/ (Tavg-Kpartial+1)
		
		delta_adj = sqrt(N_g)*(((S_tilde/N_g)-K)/sqrt(var))
		
		return(delta\delta_adj)
		
		
		
	}
end	


mata:
	function deltatesthac ( string scalar lhsname,		/// lhs variable
							string scalar rhsname,		/// rhs variables
							string scalar rhspartialname,	/// variables to be partialled out
							string scalar idtname, 		/// id and t variables
							string scalar tousename, /// touse variable	
							real scalar bandwith_init,	///
							real scalar whitening, ///
							string scalar kernel ///
							)			
														
	{

		real matrix Y
		real matrix X
		real matrix idt
		real scalar Nuniq
		real scalar N_g

		/// load data
		Y = st_data(.,lhsname,tousename)
		X = st_data(.,rhsname,tousename)
		
		idt = st_data(.,idtname,tousename)
		
		
		K1 = 0
		Z = .
		if (rhspartialname[1,1]:!= " " ) {
			Z = st_data(.,rhspartialname,tousename)
			K1 = cols(Z)		
		}
		
		Nuniq = uniqrows(idt[.,1])
		N_g = rows(Nuniq)
		K = cols(X)		
		Kpartial = 0
		
		/// set it as panel for N_g dimension
		index = panelsetup(idt[.,1],1)
		Xbar = J(rows(X),cols(X),.)
		Ybar = J(rows(Y),cols(Y),.)
		
		/// 1. Partialling out (always used because constant is always partialled out?)
		if (Z[1,1] != .) {
			i = 1
			Kpartial = cols(Z)
			while (i<=N_g) {
				starti = index[i,1]
				endi = index[i,2]
				
				Yi = Y[(starti..endi),.]
				Xi = X[(starti..endi),.]
				Zi = Z[(starti..endi),.]
				
				/// partialling out
				tmp_zz = quadcross(Zi,Zi)
				tmp_zz1 = invsym(tmp_zz)
				
				Y[(starti..endi),.] = Yi - Zi * tmp_zz1*quadcross(Zi,Yi)
				X[(starti..endi),.] = Xi - Zi * tmp_zz1*quadcross(Zi,Xi)

				Xbar[(starti..endi),.] = J(rows(Xi),1,mean(X[(starti..endi),.]))	
				Ybar[(starti..endi),.] = J(rows(Yi),1,mean(Y[(starti..endi),.])) 
				
				i++
			}

		}
		
		//// 2. Fe estimates (from demeand variables/constant partialled out)
		tmp_xx = quadcross(X,X)
		tmp_xy = quadcross(X,Y)
		tmp_xx1 = invsym(tmp_xx)
		b_fe = tmp_xx1 * tmp_xy
		
		/// eps in paper (yit - ybari) - (xit - xbari) beta, but means are patialled out?!; in gauss code eps is e_; uhat in "e_.*(X'M)'"
		///eps = (Y - Ybar) - (X - Xbar) * b_fe 
		eps = (Y ) - (X) * b_fe 
		uhat = (X ) :* eps
		
		/// index2 is for a N*K x K matrix (stacked variances)
		id2 = Nuniq#J(K,1,1)
		index2 = panelsetup(id2[.,1],1)
					
		///init values
		beta_low = J(K,K,0)
		beta_up = J(K,1,0)
		QVQ = J(N_g*K,K,0)		
		
		/// sum of bandwith, used for output
		bandwith_sum = 0
		bandwith
		i=1
		while (i<=N_g) {
			"start with i"
			starti = index[i,1]
			endi = index[i,2]
			
			start2i = index2[i,1]
			end2i = index2[i,2]
			
			uhati = uhat[(starti..endi),.] 

			Ti= rows(uhati)
	
			
			if (whitening == 1 ) {
				uhatix =uhati[1..rows(uhati)-1,.]
				uhatiy =uhati[2..rows(uhati),.]
				
				tmp_uu = quadcross(uhatix,uhatix)
				tmp_uu1 = invsym(tmp_uu)
				tmp_uxy= quadcross(uhatix,uhatiy)

				A = tmp_uu1 * tmp_uxy
							
				/// Restrict parameters between -0.97|0.97 using svd; follows Andrews Monahan p. 957
				svd(A,svdu=.,svds=.,svsvt=.)
				tocorr = selectindex(svds:>0.97)				
				tocorr1 = selectindex(svds:<-0.97)

				if (sum(svds:>0.97):>0) {
					svds[tocorr] = J(rows(tocorr),1,0.97)
				}
				if (sum(svds:<-0.97):>0) {
					svds[tocorr1] = J(rows(tocorr),1, -0.97)
				}	
				
				A = svdu * diag(svds) * svsvt'
					
				uhati = uhatiy - uhatix*A

				Ti = rows(uhati)
				"whitening done"
			}

			if (bandwith_init == -1 ) {
				
				if (kernel == "truncated") {	
					/// Newey West 1994, p. 641
					bandwith = floor( 4 * (Ti:/100)^(1/5))		
					bandwithm = bandwith
				}
				else {
					/// q and kq; seee Andrews 1991, p. 830					
					if (kernel == "qs") {					
						q = 2							
						jj = 1
						uhatup  = 0
						uhatlow = 0
						
						while (jj <= cols(uhati)) {
							xx = uhati[(1..Ti-1),jj]
							yy = uhati[(2..Ti),jj]
							uhatb = invsym(quadcross(xx,xx))* quadcross(xx,yy) 
							///uhatb checked with gauss
							uhatii = yy - xx * uhatb
							uhatsig2 = (uhatii'uhatii)/(Ti-1)
							
							/// Eq. 3.6 in AM 1992
							uhatup = uhatup + (2*uhatb*uhatsig2 / ( 1- uhatb)^4)^2 
							uhatlow = uhatlow + (uhatsig2 / (1-uhatb)^2)^2							
														
							jj++
						}
						
						/// bandwith
						bandwith = 1.3221 * ((uhatup / uhatlow)^2 * Ti)^(1/(2*q+1))
						bandwithm = Ti - 1
						"QS dne"						
					}
					else if (kernel == "bartlett"){
						
						q = 1
						kq = 1.1447
						jj = 1
						/// follow ivreg / NW p. 641
						mstar = trunc(4 *(Ti/100)^(2/9))						
						
						bartsig0 = sqrt(uhati'uhati / Ti)
						bartsig1 = J(cols(uhati),cols(uhati),0)
						
						while (jj<=mstar) {
							/// added Ti - jj
							sigtmp = sqrt(uhati[(1..Ti-jj),.]'uhati[(jj+1..Ti),.]/ rows(uhati[(1..Ti-jj),.]))
							bartsig0 = bartsig0 + 2 * sigtmp
							bartsig1 = bartsig1 + 2 * sigtmp * jj					
							///bartsig1 = bartsig1 + 2 * sigtmp * jj:^q
							jj++
						}
						/// choose minimal bandwidth out of bartsigmas and mstar; changed to ^(2); put the ^2 only around bartsig because T^(1/3)
						bandwith = min(((min(floor(1.1447 * ((bartsig1:/bartsig0):^2 * Ti) :^(1/(2*q+1))))),mstar))
						
						if (bandwith==.) {
							bandwith = 0
						}
						
						bandwithm = (bandwith > (Ti-1)) * (Ti - 1 - bandwith) + bandwith
						
						if (bandwithm==.) {
							bandwithm = 0
						} 
						
						/// Newey West 1994, Table II, Part C
						///if (whitening == 1) {
						///	bandwith = floor( 4 * (Ti:/100)^(2/9))	
						///}
						///else {
						///	bandwith = floor( 3 * (Ti:/100)^(2/9))	
						///}
					}
					(bandwithm,bandwith)
				}
				bandwith_sum = bandwith_sum + bandwithm
			}
			else{
				bandwith = bandwith_init
				bandwithm = bandwith
				bandwith_sum = bandwith * N_g
			}
				
			/// calculation of autocorrelations
			Vi = 1/Ti * ((uhati[1..Ti,.])' * (uhati[1..Ti,.]))

			j=1			
			while (j <=bandwithm) {
				Gammaj = 1/Ti * ((uhati[j+1..Ti,.])' * (uhati[1..Ti-j,.]))
				bwcorr = 1
				
				/// bartlett kernel 
				if (kernel == "bartlett") {
					kxi = 1-j/(bandwith+1)
					if (kxi < 0) {
						kxi = 0
					}
					/// see Newey West 1994, bartlett has difference between omegas
					bwcorr = -1
				}
				/// QS Kernel
				else if (kernel == "qs") {
					kxi = j/bandwith
					kxi = 25 / (12 * pi()^2 * kxi^2) * (sin(6*pi()*kxi / 5) / (6*pi() * kxi/5)  - cos(6 * pi() * kxi/5))
					
				}
				/// Truncated Kernel
				else if (kernel == "truncated") {					
					///always 1
					kxi = 1					
				}
				
				Vi = Vi + kxi * (Gammaj + bwcorr * Gammaj')
				
				j++				
			}	
						
			/// adjust Vi if whitend
			if (whitening == 1) {
				/// eq 3.7 in Andrews and Mohnahan 1992
				Vi = invsym(I(K)-A)* Vi * invsym(I(K)-A)'
			}
			
			Xi = X[(starti..endi),.]
			Yi = Y[(starti..endi),.]
			Qi = quadcross(Xi,Xi) / rows(Xi)
			QiY = quadcross(Xi,Yi)
			
			Vi1 = invsym(Vi)
			
			QVQi = Qi * Vi1 * Qi
			QVYi = Qi * Vi1 * QiY
			
			/// QVQ/QVY required for S_HAC			
			QVQ[start2i..end2i,.] = QVQi
					
			beta_low = beta_low + rows(Xi) * QVQi
			beta_up = beta_up + QVYi			
			"i done"
			i
			i++
		}
				
		beta = invsym(beta_low) * beta_up

		/// S_HAC		
		S_HAC = 0
		Tavg = 0
		i = 1

		while (i<=N_g) {
			starti = index[i,1]
			endi = index[i,2]
		
			Yi = Y[(starti..endi),.]
			Xi = X[(starti..endi),.]
		
			start2i = index2[i,1]
			end2i = index2[i,2]			

			Ti = rows(Xi)
			
			tmp_xx = quadcross(Xi,Xi)

			tmp_xx1 = invsym(tmp_xx)
			tmp_xy = quadcross(Xi,Yi)
			betai = tmp_xx1 * tmp_xy
	
			QVQi = QVQ[start2i..end2i,.]
			
			S_HAC = S_HAC+ Ti* (betai - beta)' * (QVQi) * (betai - beta)
			Tavg = Tavg + Ti
			i++
		}

		Tavg = Tavg / N_g
		
		delta_hac = sqrt(N_g) * (S_HAC / N_g - K) / sqrt(2*K)
		
		var = 2 * K * (Tavg-K-Kpartial-1)/ (Tavg-Kpartial+1)
		
		delta_adj = sqrt(N_g)*(((S_HAC/N_g)-K)/sqrt(var))

		return(delta_hac\delta_adj\(bandwith_sum/N_g))
	}
end

/* Program from xtdcce2 to calculate CSA; creates csa and returns list with tempvars */ 
capture program drop xtdcce2_csa
program define xtdcce2_csa, rclass
        syntax varlist(ts) , idvar(varlist) tvar(varlist) cr_lags(numlist) touse(varlist) csa(string) 
               tsunab olist: `varlist'
			   
			   tsrevar `varlist'
                local varlist `r(varlist)'
				
                foreach var in `varlist' {
                                local ii `=strtoname("`var'")'
                                tempvar `ii'
                                by `tvar' (`idvar'), sort: egen ``ii'' = mean(`var') if `touse'                         
                                local clist `clist' ``ii''
                        }
                        if "`cr_lags'" == "" {
                                local cr_lags = 0
                        }
                        local i = 1
                        local lagidef = 0
                        foreach var in `clist' {
                                local lagi = word("`cr_lags'",`i')
                                if "`lagi'" == "" {
                                        local lagi = `lagidef'
                                }
                                else {
                                        local lagidef = `lagi'                                  
                                }
                                sort `idvar' `tvar'
                                tsrevar L(0/`lagi').`var'
                                
                                local cross_structure "`cross_structure' `=word("`olist'",`i')'(`lagi')"
                                local clistfull `clistfull' `r(varlist)'
                                local i = `i' + 1
                        }
                        local i = 1
                        foreach var in `clistfull' {
                                rename `var' `csa'_`i'
                                local clistn `clistn' `csa'_`i'
                                local i = `i' + 1
                        }
                        
                return local varlist "`clistn'"
                return local cross_structure "`cross_structure'"
end


/* compare program. calls xthst with preferred ts options and checks for CSD */
capture program drop xthst_compare
program define xthst_compare
	syntax varlist(min=2 ts) [if] , [ partial(varlist ts) NOCONStant ar hac bw(integer -999) WHITEning kernel(string) CRosssectional(string)   ]
	
	tempvar touse	
	marksample touse
	qui{
		*** process options
		if "`partial'" != "" {
			local partial "partial(`partial')"
		}
		if "`bw'" != "" {
			if "`bw'" == "-1" | "`bw'" == "-999" {
				local bw
			}
			local bw "bw(`bw')"
		}
		if "`kernel'" != "" {
			local kernel "kernel(`kernel')"
		}
		else {
			local kernel "kernel(qs)"
		}
		if "`hac'" == "" {
			local hac hac
		}
		local cross_cmd "`crosssectional'"
		if "`crosssectional'" != "" {
			local crosssectional "crosssectional(`crosssectional')"
		}
		
		*** check if xtcd2 is installed for csd check
		local xtcd2 = 1
		cap which xtcd2
		if _rc != 0 {
			noi disp "xtcd2 not installed. No tests for cross-sectional dependence will be performed."
			noi display in smcl "Please install from {stata findit xtcd2}."
			noi disp ""
			local xtcd2 = 0
		}
		
		*** check for cross-sectional dependence in variables only
		if `xtcd2' == 1 {
			foreach var in `varlist' {
				qui xtcd2 `var' `if' , noest
				if `r(p)' <  `=1-`c(level)'/100' {
					local CSDList "`CSDList' `var'"
				}
			}
		}
		*** Perform Tests
		*** standard 
		qui xthst `varlist' `if' , `noconstant'  `partial' `crosssectional' nooutput
		tempname st_delta st_deltap 
		local st_partial "`r(partial)'"
		local st_crosssectional "`r(crosssectional)'"
		matrix `st_delta' = r(delta)
		matrix `st_deltap' = r(delta_p)		
		
		*** HAC+QS+PRE
		qui xthst `varlist' `if' , `noconstant' `ar' `partial' `crosssectional'  `hac' `kernel' `whitening' nooutput
		tempname hac_delta hac_deltap
		local hac_partial "` r(partial)'"
		local hac_crosssectional "`r(crosssectional)'"
		local hac_bw = r(bw)
		local hac_kernel "`r(kernel)'"
		matrix `hac_delta' = r(delta)
		matrix `hac_deltap' = r(delta_p)
	
	}
	*** Output
	** clear return
	return clear
		
	tempname delta_st delta_adj
		
	local twosided = 2
		
	noi disp as text "Testing for slope heterogeneity"
	noi disp "H0: slope coefficients are homogenous"

		
	scalar `delta_st' = `st_delta'[1,1]
	scalar `delta_adj' = `st_delta'[2,1]
	
	di as text "{hline 37}"
	noi disp as result _col(10) "Delta" _col(25) "p-value"
	noi disp as result  _col(7) %9.3f `delta_st' _col(23) %9.3f `twosided'*(1-normal(abs(`delta_st')))
	noi disp as result  _col(2) "adj." _col(7) %9.3f `delta_adj'  _col(23) %9.3f `twosided'*(1-normal(abs(`delta_adj')))
	di as text "{hline 37}"
		
	scalar `delta_st' = `hac_delta'[1,1]
	scalar `delta_adj' = `hac_delta'[2,1]
	
	*di as text "{hline 37}"
	noi disp as result _col(10) "Delta (HAC)" _col(25) "p-value"
	noi disp as result  _col(7) %9.3f `delta_st' _col(23) %9.3f `twosided'*(1-normal(abs(`delta_st')))
	noi disp as result  _col(2) "adj." _col(7) %9.3f `delta_adj'  _col(23) %9.3f `twosided'*(1-normal(abs(`delta_adj')))
	di as text "{hline 37}"
	
	tempname check1 check2
	scalar `check1' = `st_deltap'[1,1]
	scalar `check2' = `hac_deltap'[1,1]
			
	if (`check1' > `=1-`c(level)'/100' & `check2' <  `=1-`c(level)'/100') |  (`check1' <  `=1-`c(level)'/100' & `check2' >  `=1-`c(level)'/100') {
		noi disp as text "Tests disagree. Autocorrelation might occur."
		noi disp in smcl "See {help xthst:helpfile} for further info."
	}
	
	*noi disp ""
	*noi disp as text "Delta Test (standard) based on"
	*noi disp as text "Pesaran, Yamagata. 2008. Journal of Econometrics"
	
	*noi disp as text "Delta Test (HAC robust) based on"
	*noi disp as text "Blomquist, Westerlund. 2013. Economic Letters"
	
	noi disp ""
	if "`hac_kernel'" == "qs" { 
			local hac_kernel "quadratic spectral (QS)"
	}
	noi disp as txt "HAC Settings:"
	noi disp as txt _col(8) "Kernel: `hac_kernel' "
	noi disp as txt _col(8) "with average bandwith " `hac_bw'
	
	local checki "`hac_partial' `st_partial'"
	local partial: list uniq checki
	
	local checki "`hac_crosssectional' `st_crosssectional'"
	local crosssectional: list uniq checki
	
	if "`partial'`crosssectional'" != "" {
		noi disp ""
	}
	
	if "`partial'" != "" {
		noi disp as txt "Variables partialled out: `partial'"
	}
	if "`crosssectional'" != "" {
		noi disp as txt "Cross Sectional Averaged Variables: `crosssectional'"
	}
	
	if "`CSDList'" != ""  {
		noi disp ""
		noi disp as txt  "Cross Sectional dependence in base variables detected:"
		noi disp as txt "   `CSDList'"
		noi disp in smcl "See helpfile for {help xthst:xthst} and {help xtcd2:xtcd2} for further info."
	}
	

end
