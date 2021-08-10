*! version 1.2.2 25sep2014 Daniel Klein, Rafael Reckmann

pr kalpha ,by(r)
	vers 11.2
	
	sret clear
	
	syntax varlist [if] [in] ///
	[ , SCale(str) TRANSPOSE XPOSE ///
	FORMAT(str) BOOTstrap BOOTstrap2(str)]
	
	if mi("`format'") loc format %4.3f
	else conf numeric fo `format'
	if ("`xpose'" != "") loc transpose transpose
	
	marksample touse, nov strok
	
	cap conf numeric v `varlist'
	loc strv = (_rc != 0)
	if (`strv') cap conf str v `varlist'
	loc strv = `strv' + (_rc)
	
	// set metric
	if mi("`scale'") {
		loc scale = cond(`strv', "nominal", "interval")
	}
	else {
		ParseScaleOpt ,strv(`strv') `= strlower("`scale'")'
		loc scale `s(scale)'
	}
	
	// bootstrap option
	if ("`bootstrap2'" != "") loc bootstrap bootstrap
	if ("`bootstrap'" != "") {
		ParseBootOpts ,isby(`= _by()') `bootstrap2'
		loc reps `s(reps)'
		loc level `s(level)'
		loc mina `s(mina)'
		loc seed `s(seed)'
		loc dots `s(dots)'
		loc dotn `s(dotn)'
		loc return `s(return)'
		loc draws `s(draws)'
	}
	
	// calculate alpha
	m : mKalpha("`varlist'", "`touse'", `strv', "`scale'")
	
	// output
	loc txt as txt
	loc res as res
	loc fmt `format'
	
	di `txt' _n "Krippendorff's Alpha-Reliability"
	di `txt' "(" `res' r(metric) `txt' " data)" _n
	
	di `txt' %21s "No. of units " "= " `res' r(units)
	di `txt' %21s "No. of observers " "= " `res' r(observers)
	di `txt' %21s "Krippendorff's alpha " "= " `res' `fmt' r(kalpha)
	
	if ("`bootstrap'" != "") {
		di `txt' _n "Bootstrap results" _n
		di `txt' %21s "No. of coincidences " "= " `res' r(n)
		di `txt' %21s "Replications " "= " `res' r(reps)  _n
		di `txt' %12s "[`level'% " " Conf. Interval]"
		di `res' _col(8) `fmt' r(ci_lb) _c
		loc col = 29 - length("`: di `fmt' `r(ci_ub)''")
		di `res' _col(`col') `fmt' r(ci_ub)
		
		if ("`mina'" != "") {
			di `txt' _n _col(2) "Probability of failure to reach alpha"
			di `txt' _n _col(8) "min. alpha" _col(`= `col' + 1') "q"
			forv j = 1/`: word count `mina'' {
				di `res' _col(8) `fmt' el(r(q), `j', 1) _c
				di `res' _col(`col') `fmt' el(r(q), `j', 2)
			}
		}
	}
end

pr ParseScaleOpt ,sclass
	syntax [, STRV(numlist) ///
	Nominal Ordinal Interval Ratio ///
	Circular CIRCULARDeg ///
	Circular2(str) CIRCULARDeg2(str) ///
	Polar Polar2(str) ]
	
	foreach copt in circular circulardeg {
		if ("``copt'2'" != "") {
			cap numlist "``copt'2'" ,int max(1) r(>0)
			if (_rc) {
				di as err _c "invalid option `copt'(): "
				err _rc
			}
			loc U `r(numlist)'
			loc `copt' `copt'
		}
	}
	if !inlist("", "`circular'", "`circulardeg'") {
		di as err "only one of circular or circulardeg allowed"
		e 198
	}
	loc U `circular2'`circulardeg2'
	
	if ("`polar2'" != "") {
		cap numlist "`polar2'" ,asc min(2) max(2)
		if (_rc) {
			di as err _c "invalid option polar(): "
			err _rc
		}
		token `r(numlist)'
		loc Min `1'
		loc Max `2'
		loc polar polar
	}
	
	loc scale `nominal'`ordinal'`interval'`ratio'
	loc scale `scale'`circular'`circulardeg'`polar'
	if (`: word count `scale'' > 1) {
		di as err "option scale() incorrectly specified"
		e 198
	}
	
	if (`strv') & ("`scale'" != "nominal") {
		di as err "`scale' scale not allowed with string variables"
		e 109
	}
	
	sret loc scale `scale'
	sret loc U `U'
	sret loc Min `Min'
	sret loc Max `Max'
end

pr ParseBootOpts, sclass
	syntax [, ISBY(numlist) ///
	Reps(int 20000) ///
	Level(cilevel) ///
	MINAlpha(numlist > 0 < 1) ///
	SEED(str) ///
	NODOTS DOTS DOTS2(numlist int max = 1 > 0) ///
	RETURN DRAWs(numlist int max = 1 > 1) ]
	
	if (`reps' < 2) {
		di as err "reps() must be an integer greater than 1"
		e 198
	}
	
	if (`"`seed'"' != "") & (`isby') {
		di as err "option seed() may not be combined with by"
		e 190
	}
	
	if ("`dots2'" != "") loc dots dots
	if mi("`dots2'") & ("`dots'" != "") loc dots2 1
	
	sret loc reps `reps'
	sret loc level `level'
	sret loc mina `minalpha'
	sret loc seed `seed'
	sret loc dots `dots'
	sret loc dotn `dots2'
	sret loc return `return'
	sret loc draws `draws'
end

vers 11.2
m :
void mKalpha(string scalar units,
				string scalar tu,
				real scalar strv,
				string scalar sc)
{
	transmorphic matrix R
	real matrix VbU, delta2, coin, Qmat
	transmorphic colvector uqv
	real colvector ndotc, balpha
	real rowvector nudot, ci
	real scalar nddot, Do, De, alpha, reps, levl
	
	// get reliability matrix
	R = mGetRelMat(tokens(units), tu, strv)
	if (st_local("transpose") != "") R = R'
	
	// get unique values (sorted)
	uqv = uniqrows(vec(R))
	uqv = select(uqv, (uqv :!= missingof(uqv)))
	
	// set up values-by-units matrix
	VbU = mGetVbUMat(R, uqv)
	
	// claculate marginal sums
	nudot = colsum(VbU)
	ndotc = rowsum(select(VbU, (nudot :> 1)))
	nddot = colsum(ndotc)
	
	// get delta matrix
	delta2 = mGetDeltaMat(uqv, ndotc, sc)
	
	// calculate disagreement measures
	if (length(R) > 1) {
		Do = (nddot - 1) * mSumSum(VbU, delta2, nudot)
		De = mSumSum(ndotc, delta2)
	}
	if ((Do == 0) & (De == 0)) alpha = 0
	else alpha = 1 - (Do/De)
	
	// bootstrap
	if (st_local("bootstrap") != "") {
		reps = strtoreal(st_local("reps"))
		levl = strtoreal(st_local("level"))
		coin = mGetCoinMat(VbU, uqv, nudot)
		balpha = mKalphaBoot(coin, rows(R), De, delta2, nddot, reps)
		ci = mBootCI(balpha, levl, reps)
		if (st_local("mina") != "") Qmat = mBootQ(balpha, reps)
	}
	
	// return
	st_rclear()
	if (sc == "circulardeg") sc = "circular"
	if (sc == "polar") sc = "bipolar"
	st_global("r(metric)", sc)
	
	st_numscalar("r(kalpha)", alpha)
	st_numscalar("r(observers)", rows(R))
	st_numscalar("r(units)", rowsum(nudot :> 1))
	st_numscalar("r(n)", nddot)
	
	st_matrix("r(csum)", nudot)
	st_matrix("r(rsum)", ndotc)
	st_matrix("r(delta2)", delta2)
	st_matrix("r(vbu)", VbU)
	if (!(strv)) {
		st_matrix("r(uniqv)", uqv)
		st_matrix("r(rel)", R)
		uqv = strofreal(uqv, "%9.2g")
	}
	st_matrixcolstripe("r(delta2)", (J(rows(uqv), 1, ""), uqv))
	st_matrixrowstripe("r(delta2)", (J(rows(uqv), 1, ""), uqv))
	st_matrixrowstripe("r(vbu)", (J(rows(uqv), 1, ""), uqv))
	
	if (st_local("bootstrap") != "") {
		st_numscalar("r(level)", strtoreal(st_local("level")))
		st_numscalar("r(reps)", reps)
		st_numscalar("r(ci_lb)", ci[1, 1])
		st_numscalar("r(ci_ub)", ci[1, 2])
		
		st_matrix("r(coin)", coin)
		if (st_local("return") != "") {
			st_matrix("r(bkalpha)", balpha)
		}
		if (st_local("mina") != "") {
			st_matrix("r(q)", Qmat)
			st_matrixcolstripe("r(q)", ///
			(("min."\ ""), ("alpha"\ "q")))
		}
	}
}

transmorphic matrix mGetRelMat(string rowvector vns, 
								string scalar tu,
								real scalar strv)
{
	transmorphic matrix X
	real colvector rX
	
	if (!(strv)) X = st_data(., vns, tu)
	else if (strv == 1) X = st_sdata(., vns, tu)
	else {
		X = J(colsum(st_data(., tu) :== 1), cols(vns), "")
		for (i = 1; i <= cols(vns); ++i) {
			if (st_isnumvar(vns[1, i])) {
				rX = editmissing(st_data(., vns[1, i], tu), .)
				X[., i] = editvalue(strofreal(rX, "%18.0g"), ".", "")
			}
			else X[., i] = st_sdata(., vns[1, i], tu)
		}
	}
	X = select(X, (colsum(X :== missingof(X)) :< rows(X)))
	X = select(X, (rowsum(X :== missingof(X)) :< cols(X)))
	
	return(X)
}

real matrix mGetVbUMat(transmorphic matrix R,
						transmorphic colvector uqv)
{
	real matrix X
	
	X = J(rows(uqv), cols(R), .)
	for (u = 1; u <= cols(X); ++u) {
		for (c = 1; c <= rows(X); ++c) {
			X[c, u] = colsum(R[., u] :== uqv[c, 1])
		}
	}
	return(X)
}

real matrix mGetDeltaMat(transmorphic colvector uqv,
							real colvector ndotc,
							string scalar sc)
{
	real matrix X
	real scalar U, Min, Max
	
	if ((sc == "circular") | (sc == "circulardeg")) {
		U = strtoreal(st_global("s(U)"))
		if (missing(U)) U = uqv[rows(uqv), 1] - uqv[1, 1] + 1
	}
	if (sc == "polar") {
		Min = strtoreal(st_global("s(Min)"))
		if (missing(Min)) {
			Min = uqv[1, 1]
			Max = uqv[rows(uqv), 1]
		}
		else Max = strtoreal(st_global("s(Max)"))
	}
	
	X = J(rows(uqv), rows(uqv), 0)
	
	for (c = 1; c <= (rows(uqv) - 1); ++c) {
		for (k = c + 1; k <= rows(uqv); ++k) {
			if (sc == "nominal") X[c, k] = 1
			if (sc == "ordinal") {
				X[c, k] = (colsum(ndotc[(c..k), 1]) ///
				- (ndotc[c, 1] + ndotc[k, 1])/2)^2
			}
			if (sc == "interval") {
				X[c, k] = (uqv[c, 1] - uqv[k, 1])^2
			}
			if (sc == "ratio") {
				X[c, k] = ///
				((uqv[c, 1] - uqv[k, 1]) / ///
				(uqv[c, 1] + uqv[k, 1]))^2
			}
			if (sc == "circular") {
				X[c, k] = ///
				(sin(c("pi")*((uqv[c, 1] - uqv[k, 1])/U)))^2
			}
			if (sc == "circulardeg") {
				X[c, k] = ///
				(sin(180*((uqv[c, 1] - uqv[k, 1])/U)))^2
			}
			if (sc == "polar") {
				X[c, k] = (uqv[c, 1] - uqv[k, 1])^2 / ///
				((uqv[c, 1] + uqv[k, 1] - 2*Min) * /// 
				(2*Max - uqv[c, 1] - uqv[k, 1]))
			}
			X[k, c] = X[c, k]
		}
	}
	
	return(X)
}

real scalar mSumSum(real matrix X,
					real matrix d2,
					| real rowvector nudot)
{
	real scalar Ss	
	
	if (!length(nudot)) nudot = J(1, cols(X), 2)
	
	Ss = 0
	
	for (u = 1; u <= cols(X); ++u) {
		if (colsum(X[., u] :== 0) >= (rows(X) - 1)) continue	
		for (c = 1; c <= (rows(X) - 1); ++c) {
			for (k = c + 1; k <= rows(X); ++k) {
				Ss = Ss + ///
				(1/(nudot[1, u] - 1)) * X[c, u] * X[k, u] * d2[c, k]
			}
		}
	}
	return(Ss)
}

real matrix mGetCoinMat(real matrix VbU, 
						transmorphic colvector uqv, 
						real rowvector nudot)
{
	real matrix X
	
	VbU = select(VbU, (nudot :> 1))
	nudot = select(nudot, (nudot :> 1))
	
	X = J(rows(uqv), rows(uqv), 0)		
	for (c = 1; c <= rows(uqv); ++c) {
		for (k = c; k <= rows(uqv); ++k) {
			for (u = 1; u <= cols(VbU); ++u) {	
				if (c == k) {
					X[k, c] = X[c, k] + ///
					VbU[c, u] * (VbU[c, u] - 1) / (nudot[1, u] - 1)
				}
				else X[c, k] = X[c, k] + ///
				(VbU[c, u] * VbU[k, u]) / (nudot[1, u] - 1)
				X[k, c] = X[c, k]
			}
		}
	}
	
	return(X)
}

real colvector mKalphaBoot(real matrix coin,
							real scalar nobs,
							real scalar De,
							real matrix delta2,
							real scalar nddot,
							real scalar reps)
{
	real scalar M ,sfr, nx, prntd
	real matrix pcoin, fr
	real colvector r, balpha
	
	if (st_local("seed") != "") {
		if (missing(strtoreal(st_local("seed")))) {
			rseed(st_local("seed"))
		}
		else rseed(strtoreal(st_local("seed")))
	}
	
	if (st_local("dots") != "") {
		prntd = strtoreal(st_local("dotn"))
	}
	
	// first: get M
	M = strtoreal(st_local("draws"))
	if (missing(M)) {
		M = min(((25 * (sum(coin :!= 0))), ///
		round((nddot * (nobs - 1)/2))))
	}
	
	// second: create function
	De = 2 * (De / (nddot * (nddot - 1)))
	pcoin = (lowertriangle(coin) / nddot) ///
	+ (lowertriangle(coin, 0) / nddot)	
	fr = (runningsum(vech(pcoin)), vech(delta2) :/ (M * De))	
	
	// thrid: bootstrap
	balpha = J(reps, 1, .)
	for (rep = 1; rep <= reps; ++rep) {
		
		if (!(mod(rep, prntd))) {
			printf("{txt}%s", ".")
			displayflush()
		}
		if (!(mod(rep/prntd, 50))) printf("{txt}%6.0f\n", rep)
		
		r = runiform(M, 1)
		sfr = 0
		sfr = sfr + ///
		colsum((r :>= 0) :& (r :<= fr[1, 1])) * fr[1, 2]
		for (i = 1; i <= (rows(fr) - 1); ++i) {
			sfr = sfr + (colsum((r :>= fr[i, 1]) ///
			:& (r :<= fr[(i + 1), 1])) * fr[(i + 1), 2])
		}
		
		balpha[rep, 1] = 1 - sfr
	}	
	
	// fourth: correct
	if (colsum(balpha :< -1)) {
		balpha = balpha - ((balpha :+ 1) :* (balpha :< -1))
	}
	if (anyof(balpha, 1)) {
		if ((colsum(diagonal(coin)) :> 0) == 1) {
			balpha = balpha + ((balpha :== 1) :* (-1))
		}
		if ((colsum(diagonal(coin)) :> 0) > 1) {
			nx = round(reps * colsum(diagonal(pcoin) :^ M))
			if (nx >= (colsum(balpha :== 1))) {
				balpha = balpha + ((balpha :== 1) :* (-1))
			}
			else {
				balpha = sort(balpha, 1)
				for (i = 1; i <= nx; ++i) {
					balpha[(rows(balpha) - (i - 1)), 1] = 0
				}
			}
		}
	}
	
	// fith: distribution
	balpha = sort(balpha, 1)
	
	return(balpha)
}

real rowvector mBootCI(real colvector balpha, 
						real scalar levl, 
						real scalar reps)
{
	real rowvector ci
	
	levl = 1 - (levl/100)
	ci = balpha[max(((levl/2 * reps), 1)), 1]
	ci = ci ,balpha[floor((((1 - (levl/2)) * reps) + 1)), 1]
	
	return(ci)
}

real matrix mBootQ(real colvector balpha,
					real scalar reps)
{
	real matrix q
	
	q = strtoreal(tokens(st_local("mina"))')
	q = q, J(rows(q), 1, .)
	for (i = 1; i <= rows(q); ++i) {
		q[i, 2] = (colsum(balpha :< q[i, 1])/reps)
	}
	
	return(q)
}
end
e

1.2.2	25sep2014	bug fix -polar- default min and max
1.2.1	14aug2014	bug fix all missing rows or cols in R
					may not combine option -seed- with by
					extend and document -dots- option
					new rc for inappropriate scale with strings
					minor code polish
1.2.0	11jul2014	implement bootstrap algorithm
					additional r-results
					no longer return r(Do) and r(De)
					option -format- (not documented)
					option -dots- (not documented)
					option -return- (not documented)
					option -draws- (not documented)
					sent to SSC
1.1.0 	07jul2014	allow string variables
					alpha = 0 if Do == De == 0 (by definition)
					fix conformability error if R matrix is scalar
					return Do and De
					-xpose- synonym for -transpose- (not documented)
1.0.0 	03jul2014	first version
					display results
					support all levels of measurement
					new option -scale()-
					new option -transpose-
					byable
					new Mata function calculates sums
					sent to Jim Lemon and Alexander Staudt
1.0.0	01jul2014	beta version
					rudimetary do-file and Mata function
					sent to Alexander Staudt
