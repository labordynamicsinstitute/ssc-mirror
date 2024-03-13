*! xtteifeci 1.0.0 2024/03/08
prog def xtteifeci, eclass sortpreserve
	version 17
	preserve
	qui xtset
    if "`r(panelvar)'" == "" | "`r(timevar)'" == "" {
		di as err "panel variable or time variable missing, please use -{bf:xtset} {it:panelvar} {it:timevar}"
		exit 198
    }
	else if "`r(balanced)'" != "strongly balanced"{
		di as err "strongly panel dataset is required"
		exit 198		
	}
	syntax varlist [if] [in], TReatvar(varname) [ ///
		r(numlist min = 1 max = 1 int) Iterate(integer 1000) TOLerance(real 0.0001) trend(integer 0) ///
		BOOTStrap(integer 500) seed(integer 1) ///
		RMEthod(string) rmax(numlist min = 1 max = 1 int) ///
		citype(string) frame(string) noFIGure SAVEGraph(string) ]
	local panelVar "`r(panelvar)'"
    local timeVar "`r(timevar)'"
	tempvar touse
	mark `touse' `if' `in'
	qui keep if `touse'
	/* Check missing values*/
	foreach i in `varlist'{
		qui count if `i' == .
		if `r(N)' != 0 {
			di as err "There are {bf:`r(N)'} missing values in variable {bf:`i'}, which is not allowed by {bf:xtteifeci}"
			exit 198
		}
	}
	/* Check frame() */
	if "`frame'" == "" tempname frame
	else {
		cap frame drop `frame'
		qui pwf
		if "`frame'" == "`r(currentframe)'" {
				di as err "invalid frame() -- current frame can not be specified"
				exit 198
		}
		loc framename "`frame'"
	}
	/* Check citype() */
	if "`citype'" == "" loc citype "eq"
	else {
		if "`citype'" != "eq" & "`citype'" != "sy" {
			di as err "invalid frame() -- citype() must be specified one of {bf:eq sy}"
			exit 198
		}
	}
	/* Check r() and rmax() */
	if "`r'" == "" & "`rmax'" == ""{
		loc rmax = 8
		loc rstart = -`rmax'
	}
	else if "`r'" == "" & "`rmax'" != ""{
		loc rstart = -`rmax'
	}
	else if "`r'" != "" & "`rmax'" == ""{
		loc rstart = `r'
	}
	else if "`r'" != "" & "`rmax'" != ""{
		di as err "invalid r() or rmax() -- either r() or rmax() can be specified at a time"
		exit 198
	}
	local nbck = .
	local step = 500
	local cmax = 3
	local wtype = 1	
	/* Check rmethod() */
	if "`rmethod'" == "" loc rmethod "bn"
	else {
		if "`rmethod'" != "bn" & "`rmethod'" != "abc" {
			di as err "invalid rmethod() -- rmethod() must be specified one of {bf:bn abc}"
			exit 198
		}
	}


	frame put `panelVar' `timeVar' `varlist' `treatvar', into(`frame')
	frame `frame'{
        /* Generate panelVarStr */
        tempvar panelVarStr 
		cap decode `panelVar', gen(`panelVarStr')
		if _rc qui tostring `panelVar', gen(`panelVarStr') usedisplayformat force
		
		/* Generate timeVarStr */
		tempvar timeVarStr 
		qui tostring `timeVar', gen(`timeVarStr') usedisplayformat force
		
		mata: xtteifeci("`panelVar'", "`timeVar'", "`varlist'", "`treatvar'", `rstart', `tolerance', `iterate', `bootstrap', `trend', `seed', `cmax', `step', `wtype', `nbck', ("`rmethod'" == "bn"? 1 : 2));
		
		label variable pred·`depvar' "predicted outcome"
		label variable tr·`depvar' "treatment effect"
		label variable pred·`depvar'·eq95 "upper bound of equal tailed 90% confidence interval of predicted outcome"
		label variable pred·`depvar'·eq05 "lower bound of equal tailed 90% confidence interval of predicted outcome"
		label variable pred·`depvar'·eq975 "upper bound of equal tailed 95% confidence interval of predicted outcome"
		label variable pred·`depvar'·eq025 "lower bound of equal tailed 95% confidence interval of predicted outcome"
		label variable pred·`depvar'·eq995 "upper bound of equal tailed 99% confidence interval of predicted outcome"
		label variable pred·`depvar'·eq005 "lower bound of equal tailed 99% confidence interval of predicted outcome"
		label variable pred·`depvar'·sy95 "upper bound of symmetric 90% confidence interval of predicted outcome"
		label variable pred·`depvar'·sy05 "lower bound of symmetric 90% confidence interval of predicted outcome"
		label variable pred·`depvar'·sy975 "upper bound of symmetric 95% confidence interval of predicted outcome"
		label variable pred·`depvar'·sy025 "lower bound of symmetric 95% confidence interval of predicted outcome"
		label variable pred·`depvar'·sy995 "upper bound of symmetric 99% confidence interval of predicted outcome"
		label variable pred·`depvar'·sy005 "lower bound of symmetric 99% confidence interval of predicted outcome"

		label variable tr·`depvar'·eq95 "upper bound of equal tailed 90% confidence interval of treatment effect"
		label variable tr·`depvar'·eq05 "lower bound of equal tailed 90% confidence interval of treatment effect"
		label variable tr·`depvar'·eq975 "upper bound of equal tailed 95% confidence interval of treatment effect"
		label variable tr·`depvar'·eq025 "lower bound of equal tailed 95% confidence interval of treatment effect"
		label variable tr·`depvar'·eq995 "upper bound of equal tailed 99% confidence interval of treatment effect"
		label variable tr·`depvar'·eq005 "lower bound of equal tailed 99% confidence interval of treatment effect"
		label variable tr·`depvar'·eqpval "p-value corresponding to equal tailed confidence interval of treatment effect"
		
		label variable tr·`depvar'·sy95 "upper bound of symmetric 90% confidence interval of treatment effect"
		label variable tr·`depvar'·sy05 "lower bound of symmetric 90% confidence interval of treatment effect"
		label variable tr·`depvar'·sy975 "upper bound of symmetric 95% confidence interval of treatment effect"
		label variable tr·`depvar'·sy025 "lower bound of symmetric 95% confidence interval of treatment effect"
		label variable tr·`depvar'·sy995 "upper bound of symmetric 99% confidence interval of treatment effect"
		label variable tr·`depvar'·sy005 "lower bound of symmetric 99% confidence interval of treatment effect"
		label variable tr·`depvar'·sypval "p-value corresponding to symmetric confidence interval of treatment effect"
		
		loc depvar = word("`varlist'", 1)
		mata: printf("\n{txt}Estimation results based on the data from control units and the pre-treatment data of treated units:\n")
		mata: xtteifeci_summary(st_data(., "`depvar' pred·`depvar' `treatvar'"));
		ereturn clear
		if `K' > 0 {
			matrix beta = b
			matrix variance = V
			ereturn post b V, depname(`depvar') dof(`dof') obs(`obs') 
			ereturn display
		}
		if "`r'" == ""{
			if "`rmethod'" == "bn" mata: printf("{p 0 6 2}{txt}Note: The number of factors is estimated using the method proposed by Bai and Ng (2002) with the maximum number of factors set to be {res}`rmax'{txt}.{p_end}\n");
			else mata: printf("{p 0 6 2}{txt}Note: The number of factors is estimated using the method proposed by Alessi et al. (2010) with the maximum number of factors set to be {res}`rmax'{txt}.{p_end}\n");
		}
		mata: unit_index = xtteifeci_index(st_sdata(., "`panelVarStr'"), st_data(., "`panelVar'"))
		mata: time_index = xtteifeci_index(st_sdata(., "`timeVarStr'"), st_data(., "`timeVar'"))
		foreach i of loc trunits {
			mata: ord = selectindex(st_data(., "`panelVar'") :== `i' :& st_data(., "`treatvar'") :== 1)
			di
			mata: st_local("istr", unit_index.str[selectindex(unit_index.val :== `i'),.])
			mata: printf("{txt}Estimation and prediction results during the posttreatment periods in {res}`istr'{txt}, with " + ("`citype'" == "eq"? "equal-tailed":"symmetric") + " confidence intervals:\n");
			mata: xtteifeci_print(time_index, st_data(ord, "`timeVar' `depvar' pred·`depvar' pred·`depvar'·`citype'025 pred·`depvar'·`citype'975"), ("Time", "   Actual Outcome", "   Predicted Outcome", "       [95% Confidence", " Interval]"), (13, 16, 16, 16), 0)
			mata: xtteifeci_print(time_index, st_data(ord, "`timeVar' tr·`depvar' tr·`depvar'·`citype'pval tr·`depvar'·`citype'025 tr·`depvar'·`citype'975"), ("Time", "    Treatment Effect", "{space 6}{it:p}-value", "{space 11}[95% Confidence", " Interval]"), (13, 16, 16, 16), 1)
			if("`figure'" == ""){
				mata: st_local("xline", strofreal(min(st_data(ord, "`timeVar'"))));
				mata: st_local("istrname", strtoname(subinstr("`istr'", " ", "", .)))
				if ("`c(scheme)'" == "sj") mata: st_local("color1", "gs1"); st_local("color2", "gs3"); st_local("color3", "gs1");
				else mata: st_local("color1", "maroon"); st_local("color2", "navy"); st_local("color3", "dkgreen");
				twoway (connected `depvar' `timeVar', lcolor(`color1') msymbol(smtriangle_hollow) mcolor(`color1')) ///
					(connect pred·`depvar' `timeVar', lpattern(dash) lcolor(`color2') msymbol(X) mcolor(`color2'))  if `panelVar' == `i' & `treatvar' == 0, ///
					title("Actual and Predicted Outcomes") subtitle("during pretreatment periods in `istr'") ///
					name(pred_pre_`istrname', replace) ///
					ytitle(`depvar')  legend(order(1 "Actual Outcome" 2 "Predicted Outcome") ///
					rows(1) position(6)) nodraw
				twoway (rarea pred·`depvar'·`citype'005 pred·`depvar'·`citype'995 `timeVar', fcolor(gs12%30) lwidth(none)) ///
					(rarea pred·`depvar'·`citype'025 pred·`depvar'·`citype'975 `timeVar', fcolor(gs8%30) lwidth(none)) ///
					(rarea pred·`depvar'·`citype'05 pred·`depvar'·`citype'95 `timeVar', fcolor(gs4%30) lwidth(none)) ///
					(connected `depvar' `timeVar', lcolor(`color1') msymbol(smtriangle_hollow) mcolor(`color1')) /// 
					(connect pred·`depvar' `timeVar', lpattern(dash) lcolor(`color2') msymbol(X) mcolor(`color2')) if `panelVar' == `i' & `treatvar' == 1, ///
					title("Actual and Predicted Outcomes") subtitle("during posttreatment periods in `istr'") ///
					name(pred_post_`istrname', replace) ///
					ytitle(`depvar')  legend(order(4 "Actual Outcome" 5 "Predicted Outcome"  1 "99% Confidence Interval" 2 "95% Confidence Interval" 3 "90% Confidence Interval") ///
					rows(3) position(6)) nodraw
				
				twoway (connected tr·`depvar' `timeVar', lcolor(`color3') msymbol(smcircle_hollow) mcolor(`color3')) if `panelVar' == `i' & `treatvar' == 0, ///
					yline(0, lp(dot) lc(black%40) lwidth(0.5)) ///
					title("Gaps between Acutal and Predicted Outcomes ") subtitle("during pretreatment periods in `istr'") ///
					name(eff_pre_`istrname', replace) ytitle("gaps on `depvar'") nodraw
				twoway (rarea tr·`depvar'·`citype'005 tr·`depvar'·`citype'995 `timeVar', fcolor(gs12%30) lwidth(none)) ///
					(rarea tr·`depvar'·`citype'025 tr·`depvar'·`citype'975 `timeVar', fcolor(gs8%30) lwidth(none)) ///
					(rarea tr·`depvar'·`citype'05 tr·`depvar'·`citype'95 `timeVar', fcolor(gs4%30) lwidth(none)) ///
					(connected tr·`depvar' `timeVar', lcolor(`color3') msymbol(smcircle_hollow) mcolor(`color3')) if `panelVar' == `i' & `treatvar' == 1, ///
					yline(0, lp(dot) lc(black%40) lwidth(0.5)) ///
					title("Treatment Effects") subtitle("during posttreatment periods in `istr'") name(eff_post_`istrname', replace) ///
					legend(order(4 "Treatment Effect" 1 "99% Confidence Interval" 2 "95% Confidence Interval" 3 "90% Confidence Interval" ) ///
					rows(2) cols(2) position(6)) ytitle("treatment effects on `depvar'") nodraw
				loc graphlist = "`graphlist' pred_pre_`istrname' pred_post_`istrname' eff_pre_`istrname' eff_post_`istrname'"
			}
		}
	}
	/* Display graphs */
	if "`savegraph'" == "" foreach graph in `graphlist'{
		capture graph display `graph'
	}
	else{
		di
		ereturn local graphlist "`graphlist'"
		xtteifeci_savegraph `savegraph'
	}
	mata: st_local("graphlist", strtrim("`graphlist'"))
	ereturn scalar r = `rend'
	ereturn scalar T = `T'
	ereturn scalar T0 = `T0'
	ereturn scalar T1 = `T' - `T0'
	ereturn scalar G = `N'
	ereturn scalar G0 = `N0'
	ereturn scalar G1 = `N' - `N0'
	ereturn scalar MSE = `MSE'
	ereturn scalar RMSE = `RMSE'
	ereturn scalar R2 = `R2'
	
	ereturn local graphlist "`graphlist'"
	if "`framename'" != "" ereturn loc frame "`framename'"
	ereturn local seed "`seed'"
	ereturn local cmdline "xtteifeci `0'"
	ereturn local cmd "xtteifeci"
	ereturn local trend "`trend'"
	ereturn local indepvars "`indepvars'"
	ereturn local depvar "`depvar'"
	ereturn local varlist "`varlist'"
	ereturn local timevar "`timeVar'"
	ereturn local panelvar "`panelVar'"
	
	ereturn matrix Lwide = Lwide
	ereturn matrix Fwide = Fwide
	ereturn matrix Ltall = Ltall
	ereturn matrix Ftall = Ftall
	di _newline as txt "Finished."
end

program xtteifeci_savegraph
        version 16
        preserve
        syntax [anything], [asis replace]
        foreach graph in `e(graphlist)'{
                capture graph display `graph'
                graph save `anything'_`graph', `asis' `replace' 
        }
end

mata:
	struct xtteifeci_indexs{
		real matrix val
		string matrix str
	}
	struct xtteifeci_indexs scalar xtteifeci_index(string matrix str, real matrix val){
		struct xtteifeci_indexs scalar res
		ord = order(val, 1);
		val = val[ord,.];
		str = str[ord,.];
		info = panelsetup(val, 1);
		info_sum = sort((info, val[info[.,1], .]), 2);
		res.val = val[info_sum[., 1], 1];
		res.str = str[info_sum[., 1], 1];
		return(res)
	}
	void xtteifeci_print(struct xtteifeci_indexs scalar index, real matrix M, string matrix colnames, real matrix wides, real scalar significance){
		rowsindex = J(rows(M), 1, .)
		for(i = 1; i <= rows(M); i++) rowsindex[i, .] = selectindex(M[i, 1] :== index.val);
		if(significance){
			S = J(rows(M), 1, "");
			for(i = 1; i <= rows(M); i++) S[i, 1] = (M[i, 3] < 0.01 ? "***" : (M[i, 3] < 0.05 ? "**" : (M[i, 3] < 0.1 ? "*": "")));
		}
		wide = max(udstrlen(colnames[1]\index.str[rowsindex, .]))
		printf(sprintf("{hline %g}{c TT}", wide + 2));
		for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wides[j] + 2))
		printf("\n")
		
		printf(sprintf(" {txt}%%~%guds {c |}", wide), colnames[1])
		for(j = 2; j <= cols(colnames); j++) printf("%s", colnames[j]);
		printf("\n")
		
		printf(sprintf("{hline %g}{c +}", wide + 2));
		for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wides[j] + 2))
		printf("\n")
		
		for(i = 1; i <= rows(M); i++){
			printf(sprintf(" {txt}%%%guds {c |}{res}", wide), index.str[rowsindex[i, .], .])
			for(j = 1; j <= cols(M) - 1; j++) {
				if(j == 1 & significance){
					printf(sprintf(" %%%g.4f", wides[j]), M[i, j + 1]);
					printf(sprintf("%%-%guds ", 3), S[i, 1]);
				}else if(j == 2 & significance){
					printf(sprintf(" %%%g.3f ", wides[j] - 3), M[i, j + 1]);
				}else printf(sprintf(" %%%g.4f ", wides[j]), M[i, j + 1]);
				
			}
			printf("\n");
		}
		if(significance){
			printf(sprintf("{hline %g}{c +}", wide + 2))
			for(j = 1; j <= cols(colnames)-1; j++) printf(sprintf("{hline %g}", wides[j] + 2))
			printf("\n")
			meanM = mean(M[., 2..cols(M)])
			ATE = meanM[., 1]
			printf(sprintf(" {txt}%%~%guds {c |}{res}", wide), "Mean")
			printf(sprintf(" %%%g.4f{space 4}", wides[1]), meanM[1, 1]);
			printf("\n")
		}
		printf(sprintf("{hline %g}{c BT}", wide + 2));
		for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wides[j] + 2))
		printf("\n")
		if(significance){
			printf(stritrim(sprintf("{p 0 6 2}{txt}Note: (1) The average treatment effect over the posttreatment period is{res} %10.4f{txt}.{p_end}\n", ATE)))
			printf("{p 6 6 2}{txt}(2) {res}***{txt}, {res}**{txt}, and {res}* {txt}denote statistical significance of treatment effect at the {res}1{txt}, {res}5{txt}, and {res}10{txt} level, respectively.{p_end}\n")
		}
	}
	struct xtteifeci_svds{
		real matrix U, D, V
	}
	struct xtteifeci_svds scalar xtteifeci_svd(real matrix data, real scalar r){
		struct xtteifeci_svds scalar res
		fullsvd(data, res.U, res.D, res.V)
		if(r == .){
			res.D = diag(res.D)
		}else{
			res.U = res.U[., 1..r]
			res.D = diag(res.D)[1..r, 1..r]
			res.V = res.V[1..r, .]
		}
		return(res)
	}
	struct xtteifeci_ifes{
		real matrix betahat, Fhat, Lhat, V
	}
	struct xtteifeci_ifes scalar xtteifeci_ife(real matrix Y, real matrix X, real scalar r, real scalar epsln, real scalar iter, real scalar trend, real scalar isV){
		struct xtteifeci_svds scalar tmp; real matrix U, D, V; struct xtteifeci_ifes scalar res;
		T = rows(Y);
		N = cols(Y);		
		effT = T^(1 + trend);
		p = cols(X)/N;
		Ylong = colshape(Y',1);
		Xlong = J(N * T, p, .);
		for(i = 0; i < N; i++){
			Xlong[(i * T) :+ (1..T), .] = X[., (i * p) :+ (1..p)];
		}
		betanew = invsym(Xlong' * Xlong) * Xlong' * Ylong;
		flag = 1;
		i = 1;
		while(flag > epsln & i <= iter){
			i = i + 1;
			betaold = betanew;
			R = (Y - X * (I(N) # betaold))/(sqrt(N*effT));
			tmp = xtteifeci_svd(R, r)
			F = sqrt(effT)*tmp.U;
			H = I(T)-(F * F')/effT;
			tmpX = (I(N) # H) * Xlong
			tmpY = (I(N) # H) * Ylong
			betanew = invsym(quadcross(tmpX, tmpX)) * quadcross(tmpX, tmpY)
			flag = sqrt((betanew - betaold)'*(betanew - betaold));
		}
		betahat = betanew;
		Fhat = F;
		Lhat = sqrt(N) * tmp.V' * tmp.D;
		res.betahat = betahat;
		res.Fhat = Fhat;
		res.Lhat = Lhat;
		if (isV) {
			Xall = (colshape(X, p), Fhat # I(N), I(T) # Lhat)
			e2 = (tmpY - tmpX * betanew):^2;
			res.V = ((quadsum(e2)/(N * T - p - N * r - T * r)) * invsym(quadcross(Xall, Xall)))[1..p, 1..p];
		}
		return(res);
	}
	struct xtteifeci_fmbcs{
		real matrix Chat, betahat, V, SEP, Ehat, Ftall, Fwide, Ltall, Lwide
	}
	struct xtteifeci_fmbcs scalar xtteifeci_fmbc(real matrix Y, real matrix X, real scalar iscov, real scalar T0, real scalar N0, real scalar r, real scalar epsilon, real scalar iter, real scalar KK, real scalar trend){
		struct xtteifeci_fmbcs scalar res; 
		struct xtteifeci_svds scalar tmpsvds; 
		struct xtteifeci_ifes scalar tmpifes; 
		N = cols(Y);
		T = rows(Y);
		effT = T^(1 + trend);
		effT0 = T0^(1 + trend);
		Ytall = Y[1..T, 1..N0];
		Ywide = Y[1..T0, 1..N];
		if(iscov == 0){
			tmpsvds = xtteifeci_svd(Ytall/sqrt(effT * N0), r);
			Ftall = sqrt(effT) * tmpsvds.U;
			Ltall = sqrt(N0) * tmpsvds.V' * tmpsvds.D;
			tmpsvds =xtteifeci_svd(Ywide/sqrt(effT0*N), r);
			Fwide = sqrt(effT0) * tmpsvds.U;
			Lwide = sqrt(N) * tmpsvds.V' * tmpsvds.D;
		} else {
			p = cols(X)/N;
			Xtall = X[1..T, 1..(N0 * p)];
			Xwide = X[1..T0, 1..N * p];
			tmpifes = xtteifeci_ife(Ytall, Xtall, r, epsilon, iter, trend, 1);
			Ftall = tmpifes.Fhat;
			Ltall = tmpifes.Lhat;
			betahat = tmpifes.betahat;
			V = tmpifes.V;
			tmpifes = xtteifeci_ife(Ywide, Xwide, r, epsilon, iter, trend, 0);
			Fwide = tmpifes.Fhat;
			Lwide = tmpifes.Lhat;
		}
		res.Ftall = Ftall;
		res.Fwide = Fwide;
		res.Ltall = Ltall;
		res.Lwide = Lwide;
		Hmiss = (svsolve(Lwide[1..N0, .], Ltall))';
		Chat = Ftall * Hmiss * Lwide';
		Ehat = (iscov == 0 ? Y - Chat: Y - Chat - X * (I(N) # betahat));
		Ehat[T0 + 1..T,N0 + 1..N] = J(T - T0,N - N0, 0);
		bVhat = J(T - T0,N - N0, 0);
		SEP = J(T - T0,N - N0, 0);
		sig2ihat=J(1, N - N0, 0);
		SigF = Fwide' * Fwide/effT0;
		SigFINV = invsym(SigF)
		SigL = Ltall' * Ltall/N0;
		SigLINV = invsym(SigL)
		for(j = N0 + 1; j <= N; j++){
			Phihat = Fwide[1..T0,.]' * diag(Ehat[1..T0,j]:^2) * Fwide[1..T0, .]/effT0;
			if (KK > 0){
				for(k = 1; k <= KK; k++){
					Lk = Fwide[1 + k..T0, .]' * diag(Ehat[1 + k..T0,j]) * diag(Ehat[1..T0 - k, j]) * Fwide[1..T0 - k,.]/effT0;
					Phihat = Phihat+(1-k/(KK + 1))*(Lk + Lk');				
				}	
			}
			sig2ihat[1, j - N0] = Ehat[1..T0, j]' * Ehat[1..T0, j]/T0;
			for(t = T0 + 1; t <= T; t++){
				term1 = (Ftall[t, .] * SigFINV) * (Phihat * SigFINV) * Ftall[t,.]'/effT0;
				term2 = (Lwide[j, .] * SigLINV) * ((Ltall[1..N0, .]' * diag(Ehat[t, 1..N0]:^2) * Ltall[1..N0, .]/N0) * SigLINV)*Lwide[j, .]'/N0;
				bVhat[t - T0, j - N0] = term1 + term2;
				SEP[t - T0, j - N0] = sqrt(bVhat[t - T0, j - N0] + sig2ihat[1, j - N0]);
			} 
		}
		res.Chat = Chat
		res.betahat = (iscov == 0 ? . : betahat)
		res.V = (iscov == 0 ? . : V)
		res.Ehat = Ehat
		res.SEP = SEP
		return(res)
	}
	struct xtteifeci_ciers{
		real matrix est, betahat, V, eq05, eq95, eq025, eq975, eq005, eq995, eqpval, sy05, sy95, sy025, sy975, sy005, sy995, sypval, Yhat
	}
	real matrix xtteifeci_quantile(real matrix data, real matrix p){
		N = rows(data);
		res = J(rows(p), cols(data), .);
		p = ceil(p * N)
		for(i = 1; i<=cols(data); i++) res[., i] = data[order(data, i)[p, ], i];
		return(res);
	}
	real matrix xtteifeci_pval(real matrix eff, real matrix effs, real matrix SEP, real matrix citype){
		s = -eff :/ SEP
		if(citype == 0){
			pvalues = 2 * colmin(mean(effs:>=s) \ mean(effs:<=s))
		}else{
			pvalues = mean(abs(effs):>=abs(s))
		}
		return(pvalues);
	}
	struct xtteifeci_ciers scalar xtteifeci_cier(real matrix Y, real matrix X, real scalar iscov, real scalar T0, real scalar N0, real scalar r, real scalar epsilon, real scalar iter, real scalar B, real scalar trend){
		struct xtteifeci_fmbcs scalar tmp;
		struct xtteifeci_ciers scalar res;
		N = cols(Y);
		T = rows(Y);
		T1 = T - T0;
		N1 = N - N0;
		KK = floor(T0 ^ (1/5));
		tmp = xtteifeci_fmbc(Y, X, iscov, T0, N0, r, epsilon, iter, KK, trend);
		st_matrix("Ftall", tmp.Ftall);
		st_matrix("Fwide", tmp.Fwide);
		st_matrix("Ltall", tmp.Ltall);
		st_matrix("Lwide", tmp.Lwide);
		SEP = tmp.SEP;
		Ehat = tmp.Ehat;
		Chat = tmp.Chat;
		if(iscov == 1){
			p = cols(X)/N;
			betahat = tmp.betahat;
			V = tmp.V
		}
		SigBW = I(T);
		bandwidth=ceil(T^(1/3));
		for(k = 1; k < bandwidth; k++){
			for(h = 1; h <= T - k; h++){
				SigBW[h, h + k] = SigBW[h, h + k] + (1 - k/bandwidth)
				SigBW[h + k, h] = SigBW[h + k, h] + (1 - k/bandwidth)
			}
		}
		BW = cholesky(SigBW)' * rnormal(T, B, 0 ,1)
		Eibar = mean(Ehat[1..T0, N0 + 1..N]);
		S_star = J(B, N1 * T1, .);
		for(b = 1; b<=B; b++){
			Estar = BW[., b]:*Ehat;
			for(i = N0 +1; i <= N; i++){
				 Estar[T0 + 1..T, i] = Ehat[runiformint(T1, 1, 1, T0), i] :- Eibar[1, i - N0];
			}
			Ystar = Chat + Estar;
			tmp = xtteifeci_fmbc(Ystar, ., 0, T0, N0, r, epsilon, iter, KK, trend);
 			Chatstar = tmp.Chat;
 			SEPstar = tmp.SEP;
            S_star[b, .] = rowshape((Chatstar[T0 + 1..T, N0 + 1..N] - Ystar[T0 + 1..T,N0 + 1..N]):/SEPstar, 1);	
		}
		est = Y[T0 + 1..T, N0 + 1..N] - Chat[T0 + 1..T, N0 + 1..N];
		est = (iscov == 1? est - X[T0+1..T, N0 * p + 1..N * p] * (I(N1) # betahat) : est)
		res.est = est;
		res.betahat = (iscov == 1? betahat : .);
		res.V = (iscov == 1? V : .);
		eqpval = xtteifeci_pval(rowshape(est, 1), S_star, rowshape(SEP, 1), 0);
		res.eqpval = rowshape(eqpval, T1);
		sypval = xtteifeci_pval(rowshape(est, 1), S_star, rowshape(SEP, 1), 1);
		res.sypval = rowshape(sypval, T1);
		eqci = xtteifeci_quantile(S_star, (0.05\0.95\0.025\0.975\0.005\0.995));
		res.eq05 = est + rowshape(eqci[1, .], T1) :* SEP;
		res.eq95 = est + rowshape(eqci[2, .], T1) :* SEP;
		res.eq025 = est + rowshape(eqci[3, .], T1) :* SEP;
		res.eq975 = est + rowshape(eqci[4, .], T1) :* SEP;
		res.eq005 = est + rowshape(eqci[5, .], T1) :* SEP;
		res.eq995 = est + rowshape(eqci[6, .], T1) :* SEP;
		syci = xtteifeci_quantile(abs(S_star), (0.90\0.95\0.99));
		res.sy05 = est - rowshape(syci[1, .], T1) :* SEP;
		res.sy95 = est + rowshape(syci[1, .], T1) :* SEP;
		res.sy025 = est - rowshape(syci[2, .], T1) :* SEP;
		res.sy975 = est + rowshape(syci[2, .], T1) :* SEP;
		res.sy005 = est - rowshape(syci[3, .], T1) :* SEP;
		res.sy995 = est + rowshape(syci[3, .], T1) :* SEP;
 		res.Yhat = (iscov == 0? Chat : Chat + X * (I(N) # betahat));
		return(res);
	}
	real scalar xtteifeci_enofY(real matrix Y, real scalar rmax, real scalar trend){
		struct xtteifeci_svds scalar tmpsvds;
		T = rows(Y);
		N = cols(Y);
		effT = T^(1+trend);
		alphaT = T/(4*log(log(T))) * trend + (1 - trend);
		tmpsvds = xtteifeci_svd(Y/sqrt(effT*N), rmax);
		F = sqrt(effT) * tmpsvds.U;
		L = sqrt(N) * tmpsvds.V' * tmpsvds.D;
		sig2hat = trace((Y - F * L')*(Y - F * L')')/(N * T);
		PCmin = sig2hat + rmax*sig2hat*alphaT*((N+T)/(N*T))*log(N*T/(N+T));
		r_star= rmax;
		for(r = 1; r <= (rmax - 1); r++){
			F = sqrt(effT) * tmpsvds.U[., 1..r];
			L = sqrt(N) * (tmpsvds.V')[., 1..r] * tmpsvds.D[1..r, 1..r];
			SSR = trace((Y - F * L')*(Y - F * L')')/(N * T);
			PC = SSR + r * sig2hat * alphaT * ((N+T)/(N*T)) * log(N * T/(N+T));
			if(PC < PCmin){
				PCmin = PC;
				r_star = r;
			}
		}
		return(r_star);
	}
	real scalar xtteifeci_enofYX(real matrix Y, real matrix X, real scalar rmax,real scalar epsln, real scalar iter, real scalar trend){
		struct xtteifeci_ifes scalar tmp;
		N = cols(Y);
		rnew = rmax;
		rold = 0;
		while(rnew!=rold){
			rold=rnew;
			tmp = xtteifeci_ife(Y, X, rold, epsln, iter, trend, 0);
			R = Y - X * (I(N) # tmp.betahat);
			rnew = xtteifeci_enofY(R, rmax, trend);			
		}
		r_star = rnew;
		return(r_star);
	}
	real matrix xtteifeci_std(real matrix A, real scalar w){
		res = J(1, cols(A), .);
		for(i = 1; i <= cols(A); i++) res[., i] = (w == 1 ? sqrt(sum((A[., i]:-mean(A[., i])):^2)/rows(A)) : sqrt(sum((A[., i]:-mean(A[., i])):^2)/(rows(A)- 1)));
		return(res);
	}
	
	real scalar xtteifeci_abc(real matrix X, real scalar kmax, real scalar wtype, real scalar cmax, real scalar step, real scalar nbck){
		npace = 1; 
		T = rows(X);
		n = cols(X);
		if (nbck == .) nbck = floor(n/10);
		x = (X - J(T, 1, 1) * mean(X)):/ (J(T, 1, 1) * xtteifeci_std(X, 1));
		s = 0;
		abc = J(0, floor(cmax*step), .);
		for(N = n - nbck; N <= n; N = N + npace){
			s = s + 1; 
			Ns = jumble(1::n);
			xs = x[1..T, Ns[1..N]];
			xs = (xs - J(T, 1, 1) * mean(xs)):/(J(T, 1, 1) * xtteifeci_std(xs, 1));
			eigv = Re(eigenvalues(variance(xs)))';
			IC1 = J(kmax + 1, 1, 0);
			for(k = 1;k <= kmax + 1; k++) IC1[k, 1] = sum(eigv[k..N]); 
			p = ((N + T)/(N * T)) * log((N * T)/(N + T));
			T0 = (0::kmax):*p;
			tmp = J(1, floor(cmax * step), .);
			for(c = 1; c <= floor(cmax * step); c++){
				cc = c/step;
				IC = (IC1:/N) + T0*cc;
				rr = order(IC, 1)[1];
				tmp[1, c] = rr - 1;
			}
			abc = abc \ tmp;
		}
		cr = (1::floor(cmax*step)):/step;
		ABC = (kmax, 0, 0);
		sabc = xtteifeci_std(abc, 0);
		for(ii = 1; ii <= rows(cr); ii++){
			if(sabc[1, ii] == 0){
				if(abc[rows(abc), ii] == ABC[rows(ABC), 1]){
					ABC[rows(ABC), 3] = cr[ii];
				}else{
					ABC = (ABC \ abc[rows(abc), ii], cr[ii], cr[ii]);
				}
			}
		}
		ABC = (ABC, ABC[. ,3] - ABC[. ,2]);
		if(wtype == 1) return((ABC[selectindex(ABC[2..rows(ABC), 4] :> 0.05) :+ 1, 1])[1]); else return((ABC[selectindex(ABC[2..rows(ABC), 4] :> 0.01) :+ 1, 1])[1]);
	}
	real scalar xtteifeci_enofabcYX(real matrix Y, real matrix X, real scalar rmax, real scalar wtype, real scalar epsilon, real scalar iter, real scalar trend, real scalar cmax, real scalar step, real scalar nbck){
		struct xtteifeci_ifes scalar tmp;
		N = cols(Y);
		rnew = rmax;
		rold = 0;
		i = 0;
		while (rnew !=rold){
			i = i + 1;
			rold = rnew;
			tmp = xtteifeci_ife(Y, X, rold, epsilon, iter, trend, 0);
			R = Y - X * (I(N) # tmp.betahat);
			rnew = xtteifeci_abc(R, rmax, wtype, cmax, step, nbck);
		}
		r_star = rnew;
		return(r_star);
	}
	real scalar xtteifeci_rfind(real matrix Y, real matrix X, real scalar rmax, real scalar wtype, real scalar epsilon, real scalar iter, real scalar trend, real scalar cmax, real scalar step, real scalar nbck, real scalar rcriterion, real scalar iscov){
		struct xtteifeci_ifes scalar tmp;
		N = cols(Y);
		rnew = rmax;
		rold = 0;
		i = 0;
		while (rnew !=rold){
			i = i + 1;
			rold = rnew;
			if(iscov){
				tmp = xtteifeci_ife(Y, X, rold, epsilon, iter, trend, 0);
				R = Y - X * (I(N) # tmp.betahat);
			} else R = Y;
			if(rcriterion == 1) rnew = xtteifeci_enofY(R, rmax, trend); else rnew = xtteifeci_abc(R, rmax, wtype, cmax, step, nbck);
		}
		r_star = rnew;
		return(r_star);
	}
	
	void xtteifeci(string scalar panelvar, string scalar timevar, string scalar varlist, string scalar treatvar, real scalar r, real scalar epsilon, real scalar iter, real scalar reps, real scalar trend, real scalar seed, real scalar cmax, real scalar step, real scalar wtype, real scalar nbck, real scalar rcriterion){
		struct xtteifeci_ciers scalar res;
		data = st_data(., panelvar + " " + timevar + " " + treatvar + " " + varlist);
		times = uniqrows(data[., 2]);
		T = rows(times);
		info = panelsetup(data, 1, 2);
		info_sum = (info, panelsum(data[., 3], info) :> 0);
		_sort(info_sum, (3, 1));
		N = rows(info_sum);
		tmp = select(info_sum, info_sum[., 3]);
		unit_tr = data[tmp[., 1], 1];
		tmp = select(info_sum, !info_sum[., 3]);
		unit_ctrl = data[tmp[., 1], 1];
		N1 = rows(select(info_sum, info_sum[., 3]));
		N0 = N - N1;
		time_tr = min(select(data[., 2], data[., 3]));
		time_pre = times[selectindex(times :< time_tr), .];
		units = (unit_ctrl \ unit_tr);
		T0 = sum(times :< time_tr);
		T1 = T - T0;
		Y = J(T, N, .)
		for(i = 1; i <= N; i++) Y[., i] = panelsubmatrix(data[., 4], i, info_sum);
		varnames = tokens(varlist);
		p = cols(varnames) - 1;
		if(cols(varnames) > 1){
			data_addcons = (data, J(rows(data), 1, 1));
			p = p + 1;
			X = J(T, N * p, .);
			iscov = 1;
			for(i = 0; i < N; i++) X[., (i * p + 1)..(i * p + p)] = panelsubmatrix(data_addcons[., 5..(4 + p)], i + 1, info_sum);
		}else{
			iscov = 0;
			X = .;
			p = 0;
		}
		seed_org = rseed();
		if(r < 0){
            rseed(seed);
			if(iscov){
				r = xtteifeci_rfind(Y[., 1..N0], X[., 1..(p*N0)], -r, wtype, epsilon, iter, trend, cmax, step, nbck, rcriterion, iscov);	
			}else{
				r = xtteifeci_rfind(Y[., 1..N0], ., -r, wtype, epsilon, iter, trend, cmax, step, nbck, rcriterion, iscov);
			}
		}
		rseed(seed);
		res = xtteifeci_cier(Y, X, iscov, T0, N0, r,  epsilon, iter, reps, trend);
		st_matrixrowstripe("Ftall", (J(rows(times), 1, ""), strofreal(times)));
		st_matrixrowstripe("Ltall", (J(rows(unit_ctrl), 1, ""), strofreal(unit_ctrl)));
		st_matrixrowstripe("Fwide", (J(rows(time_pre), 1, ""), strofreal(time_pre)));
		st_matrixrowstripe("Lwide", (J(rows(units), 1, ""), strofreal(units)));
		st_matrixcolstripe("Ftall", (J(r, 1, ""), "r":+strofreal(1::r)));
		st_matrixcolstripe("Ltall", (J(r, 1, ""), "r":+strofreal(1::r)));
		st_matrixcolstripe("Fwide", (J(r, 1, ""), "r":+strofreal(1::r)));
		st_matrixcolstripe("Lwide", (J(r, 1, ""), "r":+strofreal(1::r)));
		
		Ehat = Y - res.Yhat;
		data_pred = J(rows(data), 2, .)
		for(i = 1; i <= N; i++) data_pred[info_sum[i, 1]..info_sum[i, 2], .] = (res.Yhat[., i], Ehat[., i]);
		st_store(., st_addvar("double", ("pred·", "tr·"):+ tokens(varlist)[., 1]), data_pred);
		data_pred = J(rows(data), 14, .);
		for(i = 1; i <= N1; i++){
			data_pred[(info_sum[N0 + i, 1] + T0)..info_sum[N0 + i, 2], .] = 
				(res.eq05[., i], res.eq95[., i], res.eq025[., i], res.eq975[., i], res.eq005[., i], res.eq995[., i],
				 res.sy05[., i], res.sy95[., i], res.sy025[., i], res.sy975[., i], res.sy005[., i], res.sy995[., i], res.eqpval[., i], res.sypval[., i])
		}
		st_store(., st_addvar("double", "pred·" :+ varnames[., 1] :+ ("·eq95", "·eq05", "·eq975", "·eq025", "·eq995", "·eq005", "·sy95", "·sy05", "·sy975", "·sy025", "·sy995", "·sy005")), 
				 data[., 4] :- data_pred[., 1..12])
		st_store(., st_addvar("double", ("tr·" :+ varnames[., 1] :+ ("·eq05", "·eq95", "·eq025", "·eq975", "·eq005", "·eq995", "·sy05", "·sy95", "·sy025", "·sy975", "·sy005", "·sy995", "·eqpval", "·sypval"))), data_pred);
		st_local("trunits", invtokens(strofreal(unit_tr')));
		st_local("ctrlunits", invtokens(strofreal(unit_ctrl')));
		st_local("depvar", varnames[., 1]);
		st_local("indepvars", (iscov == 1? invtokens(varnames[., 2..cols(varnames)]) : ""));
		st_local("rend", strofreal(r));
		st_local("N0", strofreal(N0));
		st_local("T0", strofreal(T0));
		st_local("N", strofreal(N));
		st_local("T", strofreal(T));
		st_local("dof", strofreal(N0 * T - (p + N0 * r + T * r)));
		st_local("obs", strofreal(N0 * T));
		st_local("K", strofreal((iscov? p - 1: 0)))
		if(iscov) {
			st_matrix("b", res.betahat');
			mnames = (J(cols(varnames), 1,""), (varnames[., 2..cols(varnames)]'\ "_cons"))
			st_matrixcolstripe("b", mnames);
			st_matrix("V", res.V);
			st_matrixcolstripe("V", mnames);
			st_matrixrowstripe("V", mnames);
			st_local("indepvars", invtokens(varnames[., 2..cols(varnames)]));
		}
		rngstate(seed_org);
	}
	void xtteifeci_summary(real matrix data){
		M = select(data[., 1..2], !data[., 3]);
		y = M[., 1];
		pred = M[., 2];
		MSE = mean((y :- pred) :* (y :- pred));
		MAE = mean(abs(y :- pred));
		RMSE = sqrt(MSE);
		R2 = 1 - sum((y :- pred) :* (y :- pred))/sum((y :- mean(y)) :* (y :- mean(y)));
		wide = 12;
		wide = wide < 9 ? 9 : (wide + 67 > st_numscalar("c(linesize)") ? max((st_numscalar("c(linesize)") - 67, 9)) : wide);
		printf("{hline " + strofreal(wide + 66) + "}\n")
		printf(" {txt}%-18uds =  {res}%12.0f {space "+ strofreal(wide - 9) 
				+ "} {txt}%-24uds  =   {res}%8.0f\n", "Factor dimension", strtoreal(st_local("rend")), "Number of Covariates", strtoreal(st_local("K")))
		printf(" {txt}%-18uds =  {res}%12uds {space "+ strofreal(wide - 9) 
				+ "} {txt}%-24uds  =   {res}%8.0f\n", "Size of Tall Block", sprintf("(%s, %s)", st_local("N0"), st_local("T")),  "Number of Control Obs.", rows(M))
		printf(" {txt}%-18uds =  {res}%12uds {space "+ strofreal(wide - 9) 
				+ "} {txt}%-24uds  =   {res}%8.3f\n", "Size of Wide Block", sprintf("(%s, %s)", st_local("N"), st_local("T0")),  "Mean Squared Error", MSE)
		printf(" {txt}%-23uds =  {res}%12.5f {space "+ strofreal(wide - 9) 
				+ "} {txt}%-24uds  =   {res}%8.3f\n", "{it:R}-squared", R2 , "Root Mean Squared Error", RMSE)
		printf("{hline " + strofreal(wide + 66) + "}\n")
		st_local("MSE", strofreal(MSE));
		st_local("RMSE", strofreal(RMSE));
		st_local("R2", strofreal(R2));
	}
end

* Version history
* 1.0.0 Submit the initial version of xtteifeci
