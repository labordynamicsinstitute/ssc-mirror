*! ifete 1.0.1 2026/09/03
prog def ifete, eclass sortpreserve
	version 17
	preserve
	cap qui xtset
    if "`r(panelvar)'" == "" | "`r(timevar)'" == "" {
		di as err "panel variable or time variable missing, please use -{bf:xtset} {it:panelvar} {it:timevar}"
		exit 198
    }
	else if "`r(balanced)'" != "strongly balanced"{
		di as err "a strongly balanced panel dataset is required"
		exit 198		
	}
	syntax varlist [if] [in], TReatvar(varname) [ ///
		r(numlist min = 1 max = 1 int) ITERate(integer 1000) TOLerance(real 0.0001) trend(integer 0) ///
		BOOTStrap(integer 500) seed(integer 1) ///
		RMEthod(string) rmax(numlist min = 1 max = 1 int) rmin(numlist min = 1 max = 1 int)  ///
		CIType(string) frame(string) noFIGure SAVEGraph(string) ]
	tempvar touse
	mark `touse' `if' `in'
	qui keep if `touse'
	/* Check that the panel is still strongly balanced after if/in */
	qui xtset
	if "`r(balanced)'" != "strongly balanced" {
		di as err "the subsample selected by {bf:if}/{bf:in} is not a strongly balanced panel"
		exit 198
	}
	local panelVar "`r(panelvar)'"
	local timeVar "`r(timevar)'"
	/* Check missing values */
	foreach i in `varlist' `treatvar'{
		qui count if missing(`i')
		if `r(N)' != 0 {
			di as err "There are {bf:`r(N)'} missing values in variable {bf:`i'}, which is not allowed by {bf:ifete}"
			exit 198
		}
	}
	/* Check that the treatment variable is a 0/1 indicator */
	qui count if `treatvar' != 0 & `treatvar' != 1
	if `r(N)' != 0 {
		di as err "invalid treatvar() -- {bf:`treatvar'} must be binary, taking the value 0 or 1"
		exit 198
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
			di as err "invalid citype() -- citype() must be specified as one of {bf:eq sy}"
			exit 198
		}
	}
	/* Check r(), rmin() and rmax() */
	if "`rmin'" == "" loc rmin = 1
	if `rmin' < 1 {
		di as err "invalid rmin() -- rmin() must be a positive integer"
		exit 198
	}
	if "`r'" != "" {
		if `r' < 1 {
			di as err "invalid r() -- r() must be a positive integer"
			exit 198
		}
	}
	if "`rmax'" != "" {
		if `rmax' < `rmin' {
			di as err "invalid rmax() -- rmax() must be greater than or equal to rmin()"
			exit 198
		}
	}
	if "`r'" == "" & "`rmax'" == ""{
		loc rmax = 10
		loc rstart = -`rmax'
	}
	else if "`r'" == "" & "`rmax'" != ""{
		loc rstart = -`rmax'
	}
	else if "`r'" != "" & "`rmax'" == ""{
		loc rstart = `r'
	}
	else {
		di as err "invalid r() or rmax() -- only one of r() and rmax() can be specified at a time"
		exit 198
	}
	/* Check trend(), bootstrap(), iterate() and tolerance() */
	if !inlist(`trend', 0, 1) {
		di as err "invalid trend() -- trend() must be either 0 or 1"
		exit 198
	}
	if `bootstrap' < 2 {
		di as err "invalid bootstrap() -- bootstrap() must be an integer no less than 2"
		exit 198
	}
	if `iterate' < 1 {
		di as err "invalid iterate() -- iterate() must be a positive integer"
		exit 198
	}
	if `tolerance' <= 0 {
		di as err "invalid tolerance() -- tolerance() must be a positive real number"
		exit 198
	}
	/* Check rmethod() */
	if "`rmethod'" == "" loc rmethod "loo"
	else {
		if "`rmethod'" != "loo" & "`rmethod'" != "ic1" & "`rmethod'" != "ic2" & "`rmethod'" != "ic3" & "`rmethod'" != "pc1" & "`rmethod'" != "pc2" & "`rmethod'" != "pc3" & "`rmethod'" != "er"  & "`rmethod'" != "gr" & substr("`rmethod'", 1, 2) != "cv" {
			di as err "invalid rmethod() -- rmethod() must be specified one of {bf:cv() loo ic1 ic2 ic3 pc1 pc2 pc3 er gr}"
			exit 198
		}
	}
	if(substr("`rmethod'", 1, 2) == "cv" ){
		mata: tmp = tokens(subinstr(subinstr(subinstr("`rmethod'", "(", "", .), ")", "", .), "cv", "", .), " "); st_local("ncv", strofreal(cols(tmp))); if(cols(tmp) == 2){ st_local("KK", strofreal(strtoreal(tmp[1]))); st_local("J", strofreal(strtoreal(tmp[2]))); } else { st_local("KK", "."); st_local("J", "."); }
		loc rmethod "cv"
		if `ncv' != 0 & `ncv' != 2 {
			di as err "invalid rmethod() -- cv() takes either no argument or two integers, as in {bf:cv(}{it:K} {it:J}{bf:)}"
			exit 198
		}
		if `ncv' == 2 {
			if "`KK'" == "." | "`J'" == "." {
				di as err "invalid rmethod() -- {it:K} and {it:J} in cv({it:K} {it:J}) must be numeric"
				exit 198
			}
			if `KK' < 1 | `J' < 1 | `KK' != int(`KK') | `J' != int(`J') {
				di as err "invalid rmethod() -- {it:K} and {it:J} in cv({it:K} {it:J}) must be positive integers"
				exit 198
			}
		}
	}
	else{
		loc J = .
		loc KK = .
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
		mata: ifete("`panelVar'", "`timeVar'", "`varlist'", "`treatvar'", `rmin' ,`rstart', `tolerance', `iterate', `bootstrap', `trend', `seed', ///
			("`rmethod'" == "cv"  ? 10 :  ///
			("`rmethod'" == "loo" ? 0 :  ///
			("`rmethod'" == "pc1" ? 1 :  ///
			("`rmethod'" == "pc2" ? 2 :  ///
			("`rmethod'" == "pc3" ? 3 :  ///
			("`rmethod'" == "ic1" ? 4 :  ///
			("`rmethod'" == "ic2" ? 5 :  ///
			("`rmethod'" == "ic3" ? 6 :  ///
			("`rmethod'" == "er"  ? 8 : 9))))))))), `J', `KK');
		
		loc depvar = word("`varlist'", 1)
		
		label variable pred·`depvar' "predicted outcome"
		label variable tr·`depvar' "treatment effect (residual for untreated observations)"
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
		
		mata: printf("\n{txt}Estimation results based on the data from control units and the pretreatment data of treated units:\n")
		mata: ifete_summary(st_data(., "`depvar' pred·`depvar' `treatvar'"));
		ereturn clear
		if `K' > 0 {
			ereturn post b V, depname(`depvar') dof(`dof') obs(`obs') 
			ereturn display
		}
		if "`r'" == ""{
			if "`rmethod'" == "loo" {
				mata: printf("{p 0 6 2}{txt}Note: The number of factors is estimated using the leave-one-out cross validation ({res}`rmethod'{txt}) (Xu, 2017), with the number of factors selected from the range [{res}`rmin'{txt}, {res}`rmax'{txt}].{p_end}\n");
			}
			else if inlist("`rmethod'", "pc1", "pc2", "pc3", "ic1", "ic2", "ic3") {
				mata: printf("{p 0 6 2}{txt}Note: The number of factors is estimated using the {res}`rmethod'{txt} criterion (Bai and Ng, 2002), with the number of factors selected from the range [{res}`rmin'{txt}, {res}`rmax'{txt}].{p_end}\n");
			}
			else if "`rmethod'" == "er" {
				mata: printf("{p 0 6 2}{txt}Note: The number of factors is estimated using the {res}eigenvalue ratio{txt} criterion (Ahn and Horenstein, 2013), with the number of factors selected from the range [{res}`rmin'{txt}, {res}`rmax'{txt}].{p_end}\n");
			}
			else if "`rmethod'" == "gr" {
				mata: printf("{p 0 6 2}{txt}Note: The number of factors is estimated using the {res}growth ratio{txt} criterion (Ahn and Horenstein, 2013), with the number of factors selected from the range [{res}`rmin'{txt}, {res}`rmax'{txt}].{p_end}\n");
			}
			else if "`rmethod'" == "cv" {
				mata: printf("{p 0 6 2}{txt}Note: The number of factors is estimated using the twice K-fold cross validation ({res}`rmethod'(`KK' `J'){txt}) (Wei and Chen, 2020), with the number of factors selected from the range [{res}`rmin'{txt}, {res}`rmax'{txt}].{p_end}\n");
			}
		}
		mata: unit_index = ifete_index(st_sdata(., "`panelVarStr'"), st_data(., "`panelVar'"))
		mata: time_index = ifete_index(st_sdata(., "`timeVarStr'"), st_data(., "`timeVar'"))
		foreach i of loc trunits {
			mata: ord = selectindex(st_data(., "`panelVar'") :== `i' :& st_data(., "`treatvar'") :== 1)
			di
			mata: st_local("istr", unit_index.str[selectindex(unit_index.val :== `i'),.])
			mata: printf("{txt}Estimation and prediction results during the posttreatment periods in {res}`istr'{txt}, with " + ("`citype'" == "eq"? "equal-tailed":"symmetric") + " confidence intervals:\n");
			mata: ifete_print(time_index, st_data(ord, "`timeVar' `depvar' pred·`depvar' pred·`depvar'·`citype'025 pred·`depvar'·`citype'975"), ("Time", "   Actual Outcome", "   Predicted Outcome", "       [95% Confidence", " Interval]"), (13, 16, 16, 16), 0)
			mata: ifete_print(time_index, st_data(ord, "`timeVar' tr·`depvar' tr·`depvar'·`citype'pval tr·`depvar'·`citype'025 tr·`depvar'·`citype'975"), ("Time", "    Treatment Effect", "{space 6}{it:p}-value", "{space 11}[95% Confidence", " Interval]"), (13, 16, 16, 16), 1)
			if("`figure'" == ""){
				mata: st_local("xline", strofreal(min(st_data(ord, "`timeVar'"))));
				mata: st_local("xlinestr", time_index.str[selectindex(time_index.val :== `xline'), .]);
				mata: st_local("istrname", strtoname(subinstr("`istr'", " ", "", .)))
				if ("`c(scheme)'" == "sj") mata: st_local("color1", "gs1"); st_local("color2", "gs3"); st_local("color3", "gs1");
				else mata: st_local("color1", "maroon"); st_local("color2", "navy"); st_local("color3", "dkgreen");
				loc ylab : variable label `depvar'
				if "`ylab'" == "" loc ylab "`depvar'"
				loc xlab : variable label `timeVar'
				if "`xlab'" == "" loc xlab "`timeVar'"
				twoway (rarea pred·`depvar'·`citype'025 pred·`depvar'·`citype'975 `timeVar', fcolor(gs8%30) lwidth(none)) ///
					(connected `depvar' `timeVar', lcolor(`color1') msymbol(smtriangle_hollow) mcolor(`color1')) /// 
					(connect pred·`depvar' `timeVar', lpattern(dash) lcolor(`color2') msymbol(X) mcolor(`color2')) if `panelVar' == `i', ///
					title("Actual and Predicted Outcomes in `istr'") name(pred_`istrname', replace) ///
					ytitle("`ylab'") xtitle("`xlab'") xline(`xline', lp(dot) lc(black)) ///
					note("Note: The vertical dotted line marks the start of the treatment period (`xlinestr').") ///
					legend(order(2 "Actual" 3 "Predicted" 1 "95% Confidence Interval") rows(1) position(6)) nodraw
				twoway (rarea tr·`depvar'·`citype'025 tr·`depvar'·`citype'975 `timeVar', fcolor(gs8%30) lwidth(none)) ///
					(connected tr·`depvar' `timeVar', lcolor(`color3') msymbol(smcircle_hollow) mcolor(`color3')) if `panelVar' == `i', ///
					yline(0, lp(dot) lc(black%40) lwidth(0.5)) ///
					title("Treatment Effects in `istr'") xline(`xline', lp(dot) lc(black)) ///
					note("Note: The vertical dotted line marks the start of the treatment period (`xlinestr').") ///
					legend(order(2 "Treatment Effect" 1 "95% Confidence Interval") ///
					rows(1) cols(2) position(6)) ytitle("Treatment Effects on `ylab'") xtitle("`xlab'") name(eff_`istrname', replace) nodraw
				loc graphlist = "`graphlist' pred_`istrname' eff_`istrname'"
			}
		}
	}
	/* Display or save graphs */
	if "`savegraph'" == "" {
		foreach graph in `graphlist'{
			capture graph display `graph'
		}
	}
	else{
		di
		ereturn local graph "`graphlist'"
		ifete_savegraph `savegraph'
	}
	mata: st_local("graphlist", strtrim("`graphlist'"))
	ereturn scalar r = `rend'
	ereturn scalar T = `T'
	ereturn scalar T0 = `T0'
	ereturn scalar T1 = `T' - `T0'
	ereturn scalar G = `N'
	ereturn scalar G0 = `N0'
	ereturn scalar G1 = `N' - `N0'
	ereturn scalar mse = `MSE'
	ereturn scalar rmse = `RMSE'
	ereturn scalar r2 = `R2'
	
	ereturn local graph "`graphlist'"
	if "`framename'" != "" ereturn loc frame "`framename'"
	ereturn local seed "`seed'"
	ereturn local cmdline "ifete `0'"
	ereturn local cmd "ifete"
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

program ifete_savegraph
	version 17
	preserve
	syntax [anything], [asis replace]
	foreach graph in `e(graph)'{
		capture graph display `graph'
		graph save `anything'_`graph', `asis' `replace' 
	}
end

mata:
	struct ifete_indexs{
		real matrix val
		string matrix str
	}
	struct ifete_indexs scalar ifete_index(string matrix str, real matrix val){
		struct ifete_indexs scalar res
		ord = order(val, 1);
		val = val[ord,.];
		str = str[ord,.];
		info = panelsetup(val, 1);
		info_sum = sort((info, val[info[.,1], .]), 2);
		res.val = val[info_sum[., 1], 1];
		res.str = str[info_sum[., 1], 1];
		return(res)
	}
	void ifete_print(struct ifete_indexs scalar index, real matrix M, string matrix colnames, real matrix wides, real scalar significance){
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
			printf("{p 6 6 2}{txt}(2) {res}***{txt}, {res}**{txt}, and {res}* {txt}denote statistical significance of treatment effect at the {res}1%%{txt}, {res}5%%{txt}, and {res}10%%{txt} level, respectively.{p_end}\n")
		}
	}
	struct ifete_svds{
		real matrix U, D, V
	}
	struct ifete_svds scalar ifete_svd(real matrix data, real scalar r){
		struct ifete_svds scalar res
		fullsvd(data, res.U, res.D, res.V)
		if(r == .){
			res.D = diag(res.D)
		}else{
			if(cols(res.U) >= r) res.U = res.U[., 1..r]; else res.U = .
			if(rows(res.D) >= r) res.D = diag(res.D)[1..r, 1..r]; else res.D = .
			if(rows(res.V) >= r) res.V = res.V[1..r, .]; else res.V = .
		}
		return(res)
	}
	struct ifete_ifes{
		real matrix betahat, Fhat, Lhat, V
	}
	struct ifete_ifes scalar ifete_ife(real matrix Y, real matrix X, real scalar r, real scalar epsln, real scalar iter, real scalar trend, real scalar isV){
		struct ifete_svds scalar tmp; struct ifete_ifes scalar res;
		T = rows(Y);
		N = cols(Y);		
		effT = T^(1 + trend);
		p = cols(X)/N;
		Ylong = colshape(Y',1);
		Xlong = J(N * T, p, .);
		for(i = 0; i < N; i++) Xlong[(i * T) :+ (1..T), .] = X[., (i * p) :+ (1..p)];
		betanew = invsym(quadcross(Xlong, Xlong)) * quadcross(Xlong, Ylong);
		tmpX = J(N * T, p, .);
		tmpY = J(N * T, 1, .);
		flag = .;
		i = 0;
		while(i < iter & (flag == . | flag > epsln)){
			i = i + 1;
			betaold = betanew;
			R = (Y - X * (I(N) # betaold))/(sqrt(N*effT));
			tmp = ifete_svd(R, r)
			F = sqrt(effT)*tmp.U;
			H = I(T)-(F * F')/effT;
			/* apply the annihilator unit by unit, instead of forming the (NT x NT) matrix I(N) # H */
			for(j = 0; j < N; j++){
				tmpX[(j * T) :+ (1..T), .] = H * Xlong[(j * T) :+ (1..T), .];
				tmpY[(j * T) :+ (1..T), .] = H * Ylong[(j * T) :+ (1..T), .];
			}
			betanew = invsym(quadcross(tmpX, tmpX)) * quadcross(tmpX, tmpY)
			flag = sqrt((betanew - betaold)'*(betanew - betaold));
		}
		if(flag > epsln) printf("{txt}Warning: the LSPC estimator did not converge in {res}%g{txt} iterations (L2 norm of the last change = {res}%g{txt}).\n", iter, flag);
		res.betahat = betanew;
		res.Fhat = F;
		res.Lhat = sqrt(N) * tmp.V' * tmp.D;
		if (isV) {
			/* V = sigma2 * (sum_i Zi'Zi)^(-1) with Zi = M_F X_i - sum_k G[i,k] M_F X_k and
			   G = Lhat * (Lhat'Lhat/N)^(-1) * Lhat'/N; see Bai (2009).  This is the p x p block of
			   sigma2 * (W'W)^(-1) with W = (X, Fhat # I(N), I(T) # Lhat), computed without ever
			   forming W, which is of dimension NT x (p + N*r + T*r). */
			Lhat = res.Lhat;
			Q = J(T * p, N, .);
			for(j = 1; j <= N; j++) Q[., j] = colshape(tmpX[((j - 1) * T) :+ (1..T), .], 1);
			Q = Q - ((Q * Lhat) * invsym(quadcross(Lhat, Lhat)/N)) * Lhat'/N;
			D = J(p, p, 0);
			for(j = 1; j <= N; j++){
				Zj = rowshape(Q[., j], T);
				D = D + quadcross(Zj, Zj);
			}
			e2 = (tmpY - tmpX * betanew):^2;
			res.V = (quadsum(e2)/(N * T - p - N * r - T * r)) * invsym(D);
		}
		return(res);
	}
	struct ifete_fmbcs{
		real matrix Chat, betahat, V, SEP, Ehat, Ftall, Fwide, Ltall, Lwide
	}
	struct ifete_fmbcs scalar ifete_fmbc(real matrix Y, real matrix X, real scalar iscov, real scalar T0, real scalar N0, real scalar r, real scalar epsilon, real scalar iter, real scalar KK, real scalar trend){
		struct ifete_fmbcs scalar res; 
		struct ifete_svds scalar tmpsvds; 
		struct ifete_ifes scalar tmpifes; 
		N = cols(Y);
		T = rows(Y);
		effT = T^(1 + trend);
		effT0 = T0^(1 + trend);
		Ytall = Y[1..T, 1..N0];
		Ywide = Y[1..T0, 1..N];
		if(iscov == 0){
			tmpsvds = ifete_svd(Ytall/sqrt(effT * N0), r);
			Ftall = sqrt(effT) * tmpsvds.U;
			Ltall = sqrt(N0) * tmpsvds.V' * tmpsvds.D;
			tmpsvds =ifete_svd(Ywide/sqrt(effT0*N), r);
			Fwide = sqrt(effT0) * tmpsvds.U;
			Lwide = sqrt(N) * tmpsvds.V' * tmpsvds.D;
		} else {
			p = cols(X)/N;
			Xtall = X[1..T, 1..(N0 * p)];
			Xwide = X[1..T0, 1..N * p];
			tmpifes = ifete_ife(Ytall, Xtall, r, epsilon, iter, trend, 1);
			Ftall = tmpifes.Fhat;
			Ltall = tmpifes.Lhat;
			betahat = tmpifes.betahat;
			V = tmpifes.V;
			tmpsvds = ifete_svd((Ywide - Xwide * (I(N) # betahat))/sqrt(effT0*N), r);
			Fwide = sqrt(effT0) * tmpsvds.U;
			Lwide = sqrt(N) * tmpsvds.V' * tmpsvds.D;
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
	struct ifete_ciers{
		real matrix est, betahat, V, eq05, eq95, eq025, eq975, eq005, eq995, eqpval, sy05, sy95, sy025, sy975, sy005, sy995, sypval, Yhat
	}
	real matrix ifete_quantile(real matrix data, real matrix prob){
		N = rows(data);
		res = J(rows(prob), cols(data), .);
		idx = ceil(prob * N);
		idx = idx :* (idx :>= 1) :+ (idx :< 1);
		for(i = 1; i<=cols(data); i++) res[., i] = data[order(data, i)[idx, ], i];
		return(res);
	}
	real matrix ifete_pval(real matrix eff, real matrix effs, real matrix SEP, real matrix citype){
		s = -eff :/ SEP
		if(citype == 0){
			pvalues = 2 * colmin(mean(effs:>=s) \ mean(effs:<=s))
			pvalues = pvalues :* (pvalues :<= 1) :+ (pvalues :> 1)
		}else{
			pvalues = mean(abs(effs):>=abs(s))
		}
		return(pvalues);
	}
	struct ifete_ciers scalar ifete_cier(real matrix Y, real matrix X, real scalar iscov, real scalar T0, real scalar N0, real scalar r, real scalar epsilon, real scalar iter, real scalar B, real scalar trend){
		struct ifete_fmbcs scalar tmp;
		struct ifete_ciers scalar res;
		N = cols(Y);
		T = rows(Y);
		T1 = T - T0;
		N1 = N - N0;
		KK = floor(T0 ^ (1/5));
		tmp = ifete_fmbc(Y, X, iscov, T0, N0, r, epsilon, iter, KK, trend);
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
		BW = cholesky(SigBW) * rnormal(T, B, 0 ,1)
		Eibar = mean(Ehat[1..T0, N0 + 1..N]);
		S_star = J(B, N1 * T1, .);
		for(b = 1; b<=B; b++){
			Estar = BW[., b]:*Ehat;
			for(i = N0 +1; i <= N; i++){
				 Estar[T0 + 1..T, i] = Ehat[runiformint(T1, 1, 1, T0), i] :- Eibar[1, i - N0];
			}
			Ystar = Chat + Estar;
			tmp = ifete_fmbc(Ystar, ., 0, T0, N0, r, epsilon, iter, KK, trend);
 			Chatstar = tmp.Chat;
 			SEPstar = tmp.SEP;
            S_star[b, .] = rowshape((Chatstar[T0 + 1..T, N0 + 1..N] - Ystar[T0 + 1..T,N0 + 1..N]):/SEPstar, 1);	
		}
		est = Y[T0 + 1..T, N0 + 1..N] - Chat[T0 + 1..T, N0 + 1..N];
		est = (iscov == 1? est - X[T0+1..T, N0 * p + 1..N * p] * (I(N1) # betahat) : est)
		res.est = est;
		res.betahat = (iscov == 1? betahat : .);
		res.V = (iscov == 1? V : .);
		eqpval = ifete_pval(rowshape(est, 1), S_star, rowshape(SEP, 1), 0);
		res.eqpval = rowshape(eqpval, T1);
		sypval = ifete_pval(rowshape(est, 1), S_star, rowshape(SEP, 1), 1);
		res.sypval = rowshape(sypval, T1);
		eqci = ifete_quantile(S_star, (0.05\0.95\0.025\0.975\0.005\0.995));
		res.eq05 = est + rowshape(eqci[1, .], T1) :* SEP;
		res.eq95 = est + rowshape(eqci[2, .], T1) :* SEP;
		res.eq025 = est + rowshape(eqci[3, .], T1) :* SEP;
		res.eq975 = est + rowshape(eqci[4, .], T1) :* SEP;
		res.eq005 = est + rowshape(eqci[5, .], T1) :* SEP;
		res.eq995 = est + rowshape(eqci[6, .], T1) :* SEP;
		syci = ifete_quantile(abs(S_star), (0.90\0.95\0.99));
		res.sy05 = est - rowshape(syci[1, .], T1) :* SEP;
		res.sy95 = est + rowshape(syci[1, .], T1) :* SEP;
		res.sy025 = est - rowshape(syci[2, .], T1) :* SEP;
		res.sy975 = est + rowshape(syci[2, .], T1) :* SEP;
		res.sy005 = est - rowshape(syci[3, .], T1) :* SEP;
		res.sy995 = est + rowshape(syci[3, .], T1) :* SEP;
 		res.Yhat = (iscov == 0? Chat : Chat + X * (I(N) # betahat));
		return(res);
	}
	real scalar ifete_BNofY(real matrix Y, real scalar rmin, real scalar rmax, real scalar trend, real scalar type){
		struct ifete_svds scalar tmpsvds;
		T = rows(Y);
		N = cols(Y);
		rmax = min((rmax, N - 1, T - 1))
		if(rmax < rmin) return(rmax);
		effT = T^(1 + trend);
		tmpsvds = ifete_svd(Y/sqrt(effT*N), rmax);
		F = sqrt(effT) * tmpsvds.U;
		L = sqrt(N) * tmpsvds.V' * tmpsvds.D;
		sig2hat = sum((Y - F * L'):^2)/(N * T);
		C2_NT = min((N, T));
		r_star= rmax;
		BN = J(6, 1, .)
		BNmin = .
		for(r = rmin; r <= rmax; r++){
			F = sqrt(effT) * tmpsvds.U[., 1..r];
			L = sqrt(N) * (tmpsvds.V')[., 1..r] * tmpsvds.D[1..r, 1..r];
			SSR = sum((Y - F * L'):^2)/(N * T);
			BN[1] = SSR + r * sig2hat * ((N+T)/(N*T))*ln((N*T)/(N+T));
			BN[2] = SSR + r * sig2hat * ((N+T)/(N*T))*ln(C2_NT);
			BN[3] = SSR + r * sig2hat * ln(C2_NT)/(C2_NT);
			BN[4] = ln(SSR) + r * ((N+T)/(N*T))*ln((N*T)/(N+T))
			BN[5] = ln(SSR) + r * ((N+T)/(N*T))*ln(C2_NT);
			BN[6] = ln(SSR) + r * ln(C2_NT)/(C2_NT);
			if(BNmin == . | BN[type] < BNmin){
				BNmin = BN[type];
				r_star = r;
			}
		}
		return(r_star);
	}
	real scalar ifete_ERofY(real matrix Y, real scalar rmin, real scalar rmax, real scalar trend){
		/* the eigenvalue ratio is invariant to the scale of Y, hence trend is irrelevant here */
		T = rows(Y);
		N = cols(Y);
		rmax = min((rmax, N - 1, T - 1));
		/* eigenvalues of Y*Y'/(N*T), sorted in descending order */
		eignvals = (svdsv(Y/sqrt(N * T)):^2)';
		m = cols(eignvals);
		r_star = rmin;
		ERmax = .;
		for(r = rmin; r <= min((rmax, m - 1)); r++){
			if(eignvals[r + 1] <= 0) break;
			ER = eignvals[r]/eignvals[r + 1];
			if(ERmax == . | ER > ERmax){
				ERmax = ER;
				r_star = r;
			}
		}
		return(r_star);
	}
	real scalar ifete_GRofY(real matrix Y, real scalar rmin, real scalar rmax, real scalar trend){
		/* the growth ratio is invariant to the scale of Y, hence trend is irrelevant here */
		T = rows(Y);
		N = cols(Y);
		rmax = min((rmax, N - 1, T - 1));
		/* eigenvalues of Y*Y'/(N*T), sorted in descending order */
		eignvals = (svdsv(Y/sqrt(N * T)):^2)';
		m = cols(eignvals);
		r_star = rmin;
		GRmax = .;
		for(r = rmin; r <= min((rmax, m - 2)); r++){
			V = sum(eignvals[(r + 1)..m]);
			Vplus = sum(eignvals[(r + 2)..m]);
			if(V <= 0 | Vplus <= 0) break;
			GR = ln(1 + eignvals[r]/V)/ln(1 + eignvals[r + 1]/Vplus);
			if(GRmax == . | GR > GRmax){
				GRmax = GR;
				r_star = r;
			}
		}
		return(r_star);
	}
	real scalar ifete_LOOofY(real matrix Ytall, real matrix Yrest, real scalar trend, real scalar rmin, real scalar rmax){
		struct ifete_svds scalar tmpsvds;
		T = rows(Ytall);
		N0 = cols(Ytall);
		T0 = rows(Yrest);
		rmax = min((rmax, N0 - 1, T0 - 1));
		if(rmax < rmin) return(rmax);
		effT = T^(1 + trend);
		MSPElist = J(1, rmax, .)
		for(r = rmin; r <= rmax; r++){
			tmpsvds = ifete_svd(Ytall/sqrt(effT*N0), r);
			F = sqrt(effT) * tmpsvds.U;
			tmpsum = 0;
			for(t = 1; t<= T0; t++){
				tmpindex = selectindex((1::T0):!=t)
				L = svsolve(F[tmpindex, .], Yrest[tmpindex, .])
				tmpsum = tmpsum + sum((Yrest[t, .] - F[t, .]* L):^2)
			}
			MSPElist[1, r] = tmpsum/T0
		}
		minindex(MSPElist[., rmin..rmax], 1, r_star, .)
		return(r_star + rmin - 1);
	}
	real matrix ifete_dropRows(real matrix A, real colvector drop)
	{
		tmp = J(rows(A), 1, 1);
		tmp[drop, 1] = J(rows(drop), 1, 0);
		return(A[selectindex(tmp), .]);
	}
	real matrix ifete_dropCols(real matrix A, real rowvector drop)
	{
		tmp = J(1, cols(A), 1);
		tmp[1, drop] = J(1, cols(drop), 0);
		return(A[., selectindex(tmp)]);
	}
	class AssociativeArray scalar ifete_ranSplitRows(real matrix A, real scalar J){
		T = rows(A);
		key = asarray_create("real"); 
		tmp = jumble(1::rows(A));
		step = ceil(T/J);
		for(j = 1; j <= J; j++){
			if(j * step <= T){
				asarray(key, j, tmp[((j - 1)*step + 1) :: (j * step)]);
			} else{
				asarray(key, j, tmp[((j - 1)*step + 1)::T]);
			}
		} 
		return(key);
	}
	class AssociativeArray scalar ifete_ranSplitCols(real matrix A, real scalar K){
		N = cols(A);
		key = asarray_create("real"); 
		tmp = jumble(1::cols(A))';
		step = ceil(N/K);
		for(k = 1; k <= K; k++){
			if(k * step <= N){
				asarray(key, k, tmp[((k - 1)*step + 1)..(k * step)]);
			} else{
				asarray(key, k, tmp[((k - 1)*step + 1)..N]);
			}
		} 
		return(key);
	}
	real scalar ifete_CVofY(real matrix Ytall, real matrix Ywide,  string scalar type, real scalar J, real scalar K, real scalar trend, real scalar rmin, real scalar rmax){
		struct ifete_svds scalar tmpsvds;
		if(type == "tall") Y = Ytall; else Y = Ywide;
		T = rows(Y);
		N = cols(Y);
		rmax = min((rmax, cols(Ytall) - 1, rows(Ywide) - 1));
		if(rmax < rmin) return(rmax);
		J = min((max((J, 1)), N));
		K = min((max((K, 1)), T));
		Tlist = ifete_ranSplitRows(Y, K);
		Nlist = ifete_ranSplitCols(Y, J);
		effT = T^(1 + trend);
		MSPElist = J(1, rmax, .)
		for(r = rmin; r <= rmax; r++){
			tmpsum = 0;
			for(j = 1; j<= J; j++){
				tmpsvds = ifete_svd(ifete_dropCols(Y, asarray(Nlist, j))/sqrt(effT*(N - cols(asarray(Nlist, j)))), r);
				F = sqrt(effT) * tmpsvds.U;
				for(k = 1; k<= K; k++){
					L = svsolve(ifete_dropRows(F, asarray(Tlist, k)), ifete_dropRows(Y[., asarray(Nlist, j)], asarray(Tlist, k)));
					tmpsum = tmpsum + sum((Y[asarray(Tlist, k), asarray(Nlist, j)] - F[asarray(Tlist, k), .]* L):^2)
				}
			}
			MSPElist[1, r] = tmpsum;
		}
		minindex(MSPElist[., rmin..rmax], 1, r_star, .)
		return(r_star + rmin - 1);
	}
	real scalar ifete_rfind(real matrix Ytall, real matrix Ywide, real matrix Yrest, real matrix Xtall, real matrix Xwide, real matrix Xrest, real scalar rmin, real scalar rmax, real scalar epsilon, real scalar iter, real scalar trend, real scalar rcriterion, real scalar iscov, real scalar J, real scalar K){
		struct ifete_ifes scalar tmp;
		N0 = cols(Ytall);
		N = cols(Ywide);
		N1 = cols(Yrest);
		T0 = rows(Ywide);
		/* the number of factors must be feasible for both the tall and the wide block */
		rmaxf = min((rmax, N0 - 1, T0 - 1));
		if(rmaxf < 1) _error("too few control units or pretreatment periods to estimate any factor");
		if(rmaxf < rmax) printf("{txt}Note: rmax() is reduced to {res}%g{txt}, the largest number of factors allowed by the tall and wide blocks.\n", rmaxf);
		rminf = min((rmin, rmaxf));
		type = "tall";
		if(J == .) J = N0;
		if(K == .) K = rows(Ytall);
		J = min((J, N0));
		K = min((K, rows(Ytall)));
		st_local("J", strofreal(J));
		st_local("KK", strofreal(K));
		/* reuse the same random folds in every round so that the loop below is deterministic */
		cvstate = rseed();
		rnew = rmaxf;
		rold = .;
		i = 0;
		while(rnew != rold & i < 20){
			i = i + 1;
			rold = rnew;
			if(iscov){
				tmp = ifete_ife(Ytall, Xtall, rold, epsilon, iter, trend, 0);
				Rtall = Ytall - Xtall * (I(N0) # tmp.betahat);
				Rwide = Ywide - Xwide * (I(N) # tmp.betahat);
				Rrest = Yrest - Xrest * (I(N1) # tmp.betahat);
			} else {
				Rtall = Ytall;
				Rwide = Ywide;
				Rrest = Yrest;
			}
			if(rcriterion == 0) rnew = ifete_LOOofY(Rtall, Rrest, trend, rminf, rmaxf);
			if(rcriterion >= 1 & rcriterion <= 6) rnew = ifete_BNofY(Rtall, rminf, rmaxf, trend, rcriterion);
			if(rcriterion == 8) rnew = ifete_ERofY(Rtall, rminf, rmaxf, trend);
			if(rcriterion == 9) rnew = ifete_GRofY(Rtall, rminf, rmaxf, trend);
			if(rcriterion == 10){
				rseed(cvstate);
				rnew = ifete_CVofY(Rtall, Rwide, type, J, K, trend, rminf, rmaxf);
			}
			/* without covariates the criterion does not depend on rold: one round suffices */
			if(!iscov) rold = rnew;
		}
		if(rnew != rold) printf("{txt}Warning: the selection of the number of factors did not stabilize in {res}%g{txt} rounds; {res}%g{txt} factors are used.\n", i, rnew);
		return(rnew);
	}
	void ifete(string scalar panelvar, string scalar timevar, string scalar varlist, string scalar treatvar, real scalar rmin, real scalar r, real scalar epsilon, real scalar iter, real scalar reps, real scalar trend, real scalar seed, real scalar rcriterion, real scalar J, real scalar K){
		struct ifete_ciers scalar res;
		data = st_data(., panelvar + " " + timevar + " " + treatvar + " " + varlist);
		times = uniqrows(data[., 2]);
		T = rows(times);
		info = panelsetup(data, 1, 2);
		info_sum = (info, panelsum(data[., 3], info) :> 0);
		_sort(info_sum, (3, 1));
		N = rows(info_sum);
		N1 = sum(info_sum[., 3]);
		N0 = N - N1;
		if(N1 == 0) _error("no treated unit found: the treatment variable is 0 for all observations");
		if(N0 == 0) _error("no control unit found: every unit is treated in some period");
		tmp = select(info_sum, info_sum[., 3]);
		unit_tr = data[tmp[., 1], 1];
		tmp = select(info_sum, !info_sum[., 3]);
		unit_ctrl = data[tmp[., 1], 1];
		time_tr = min(select(data[., 2], data[., 3]));
		time_pre = times[selectindex(times :< time_tr), .];
		units = (unit_ctrl \ unit_tr);
		T0 = sum(times :< time_tr);
		T1 = T - T0;
		if(T0 == 0) _error("no pretreatment period found: the treatment starts in the first period");
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
				r = ifete_rfind(Y[., 1..N0], Y[1..T0, .], Y[1..T0, (N0 + 1)..N], X[., 1..(p*N0)], X[1..T0, .], X[1..T0, (p*N0+1)..(p*N)], rmin, -r, epsilon, iter, trend, rcriterion, iscov, J, K);	
			}else{
				r = ifete_rfind(Y[., 1..N0], Y[1..T0, .], Y[1..T0, (N0 + 1)..N], ., ., ., rmin, -r, epsilon, iter, trend, rcriterion, iscov, J, K);
			}
		}
		else if(r > min((N0 - 1, T0 - 1))) _error(sprintf("r() must not exceed min(T0 - 1, N0 - 1) = %g", min((N0 - 1, T0 - 1))));
		rseed(seed);
		res = ifete_cier(Y, X, iscov, T0, N0, r,  epsilon, iter, reps, trend);
		st_matrixrowstripe("Ftall", (J(rows(times), 1, ""), strtrim(strofreal(times, "%18.0g"))));
		st_matrixrowstripe("Ltall", (J(rows(unit_ctrl), 1, ""), strtrim(strofreal(unit_ctrl, "%18.0g"))));
		st_matrixrowstripe("Fwide", (J(rows(time_pre), 1, ""), strtrim(strofreal(time_pre, "%18.0g"))));
		st_matrixrowstripe("Lwide", (J(rows(units), 1, ""), strtrim(strofreal(units, "%18.0g"))));
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
		st_local("trunits", invtokens(strtrim(strofreal(unit_tr', "%18.0g"))));
		st_local("ctrlunits", invtokens(strtrim(strofreal(unit_ctrl', "%18.0g"))));
		st_local("depvar", varnames[., 1]);
		st_local("indepvars", (iscov == 1? invtokens(varnames[., 2..cols(varnames)]) : ""));
		st_local("rend", strofreal(r));
		st_local("N0", strofreal(N0));
		st_local("T0", strofreal(T0));
		st_local("N", strofreal(N));
		st_local("T", strofreal(T));
		st_local("dof", strtrim(strofreal(N0 * T - (p + N0 * r + T * r), "%18.0g")));
		st_local("obs", strtrim(strofreal(N0 * T, "%18.0g")));
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
		rseed(seed_org);
	}
	void ifete_summary(real matrix data){
		M = select(data[., 1..2], !data[., 3]);
		y = M[., 1];
		pred = M[., 2];
		MSE = mean((y :- pred) :* (y :- pred));
		RMSE = sqrt(MSE);
		R2 = 1 - sum((y :- pred) :* (y :- pred))/sum((y :- mean(y)) :* (y :- mean(y)));
		wide = 12;
		wide = wide < 9 ? 9 : (wide + 72 > st_numscalar("c(linesize)") ? max((st_numscalar("c(linesize)") - 72, 9)) : wide);
		printf("{hline " + strofreal(wide + 70) + "}\n")
		printf(" {txt}%-30uds =   {res}%8.0f {space "+ strofreal(wide - 9)
			+ "}{txt}%-18uds =  {res}%12uds\n",  "Number of Control Units", strtoreal(st_local("N0")), "Size of Tall Block", sprintf("(%s, %s)", st_local("T"), st_local("N0")))
		printf(" {txt}%-30uds =   {res}%8.0f {space "+ strofreal(wide - 9)
			+ "}{txt}%-18uds =  {res}%12uds\n",  "Number of Pretreatment Periods", strtoreal(st_local("T0")), "Size of Wide Block", sprintf("(%s, %s)", st_local("T0"), st_local("N")))
		printf(" {txt}%-30uds =   {res}%8.0f {space "+ strofreal(wide - 9)
			+ "}{txt}%-18uds =  {res}%12.0f\n",  "Number of Covariates", strtoreal(st_local("K")), "Number of Factors", strtoreal(st_local("rend")))
		printf(" {txt}%-30uds =   {res}%8.3f {space "+ strofreal(wide - 9)
			+ "}{txt}%-23uds =  {res}%12.5f\n",  "Root Mean Squared Error", RMSE, "Pretreatment {it:R}²", R2)
		printf("{hline " + strofreal(wide + 70) + "}\n")
		st_local("MSE", strtrim(strofreal(MSE, "%18.0g")));
		st_local("RMSE", strtrim(strofreal(RMSE, "%18.0g")));
		st_local("R2", strtrim(strofreal(R2, "%18.0g")));
	}
end

* Version history
* 1.0.0 Submit the initial version of ifete
* 1.0.1 Bug fixes and input validation:
*       - ifete_BNofY(): '=' corrected to '==' in the comparison with BNmin, which
*         previously made pc1-pc3 and ic1-ic3 always return rmax
*       - ifete_cier(): the wild bootstrap multipliers now use cholesky(SigBW), not its
*         transpose, so that their covariance matrix is the intended Bartlett one
*       - ifete_rfind(): the number of factors is now selected from the residualized
*         matrices under all criteria (cv() previously used the raw outcomes); rmax is
*         capped at min(N0 - 1, T0 - 1) for every criterion; the loop is bounded and the
*         cross-validation folds are held fixed across rounds
*       - ifete_ERofY(), ifete_GRofY(): eigenvalues are obtained from the singular values,
*         which are sorted in descending order, and the range of r is guarded
*       - ifete_ife(): the annihilator is applied unit by unit and the variance of the
*         coefficients is computed from Bai (2009)'s D(F), so that the (NT x NT) and
*         (NT x (p + N*r + T*r)) matrices are no longer formed
*       - ifete_quantile(), ifete_pval(): guarded quantile index, p-values capped at 1
*       - e(mse), e(rmse), e(r2) and e(graph) renamed to match the documentation
*       - validation of r(), rmin(), rmax(), trend(), bootstrap(), iterate(), tolerance(),
*         cv(K J) and of the treatment variable; balance is rechecked after if/in
*       - removed unused code (ifete_std(), the abc branch, the PC criterion, the matrices
*         beta and variance, and the arguments wtype, cmax, step and nbck)
