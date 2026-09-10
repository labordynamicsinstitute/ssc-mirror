*! oda_predict 1.0.0 Ariel Linden 03sep2026

program define oda_predict, rclass
	version 14.0

	syntax name(name=predname) [if] [in] [, REPLACE]

	if "$oda_lastfit_ok" != "1" {
		di as err "no successfully fitted oda model found in memory -- run oda first"
		exit 301
	}

	if "`replace'" != "" {
		capture confirm variable `predname'
		if !_rc qui drop `predname'
	}
	else {
		confirm new variable `predname'
	}

	local attrvar  "$oda_lastfit_attr"
	local classvar "$oda_lastfit_class"
	capture confirm numeric variable `attrvar'
	if _rc {
		di as err "`attrvar' (the attribute oda was fit on) not found as a numeric variable in the current data"
		exit 111
	}

	marksample touse, novarlist
	qui replace `touse' = 0 if missing(`attrvar')
	qui count if `touse'
	local nsel = r(N)
	if `nsel' == 0 {
		di as err "no observations to predict -- check if/in, and whether `attrvar' is missing throughout the selected sample"
		exit 2000
	}

	qui gen double `predname' = .

	local multiclass = $oda_lastfit_multiclass
	local iscat       = $oda_lastfit_cat
	if `multiclass' {
		local clow  = 0
		local chigh = 0
	}
	else {
		local clow  = $oda_lastfit_clow
		local chigh = $oda_lastfit_chigh
	}

	qui mata: odam_predict_apply("`predname'", "`attrvar'", "`touse'", ///
		`multiclass', `iscat', `clow', `chigh')

	label variable `predname' "oda predicted `classvar'"
	capture confirm variable `classvar'
	if !_rc {
		local vl : value label `classvar'
		if "`vl'" != "" label values `predname' `vl'
	}

	return scalar N = `nsel'
end

mata:

real colvector odam_cat_map(real colvector cat, real colvector catvals, real colvector scores)
{
	real colvector out
	real scalar n, k, i, j
	n = rows(cat)
	k = rows(catvals)
	out = J(n,1,.)
	for (i=1; i<=n; i++) {
		for (j=1; j<=k; j++) {
			if (catvals[j]==cat[i]) {
				out[i] = scores[j]
				break
			}
		}
	}
	return(out)
}

real colvector odamK_predict(real colvector a, real colvector cps, real colvector seglabels)
{
	real colvector pred
	real scalar n, i, s, nseg
	n = rows(a)
	nseg = rows(seglabels)
	pred = J(n,1,.)
	for (i=1; i<=n; i++) {
		s = 1
		while (s<=nseg-1) {
			if (a[i] > cps[s]) s++
			else break
		}
		pred[i] = seglabels[s]
	}
	return(pred)
}

real colvector odamK_predict_cat(real colvector cat, real colvector catvals, real colvector catmodel, real scalar deflt)
{
	real colvector pred
	real scalar n, nu, i, j, found
	n = rows(cat)
	nu = rows(catvals)
	pred = J(n,1,.)
	for (i=1; i<=n; i++) {
		found = 0
		for (j=1; j<=nu; j++) {
			if (catvals[j]==cat[i]) {
				pred[i] = catmodel[j]
				found = 1
				break
			}
		}
		if (!found) pred[i] = deflt
	}
	return(pred)
}

void odam_predict_apply(string scalar newvar, string scalar attrvar,
	string scalar touse, real scalar multiclass, real scalar iscat,
	real scalar clow, real scalar chigh)
{
	real colvector tv, aidx, a, ascore, predout, predK
	real colvector catvals, scores, cvals, cps, seglabels, catmodel
	real scalar cutpoint, direction, i

	tv = st_data(., touse)
	aidx = selectindex(tv:==1)
	if (rows(aidx)==0) return

	a = st_data(., attrvar)[aidx]

	if (!multiclass) {
		cutpoint  = st_numscalar("r_cutpoint")
		direction = st_numscalar("r_direction")
		if (iscat) {
			catvals = st_matrix("r_cat_vals")
			scores  = st_matrix("r_cat_scores")
			ascore  = odam_cat_map(a, catvals, scores)
		}
		else {
			ascore = a
		}
		predout = J(rows(aidx),1,.)
		for (i=1; i<=rows(aidx); i++) {
			if (ascore[i]==.) continue
			if (direction==1) predout[i] = (ascore[i] > cutpoint ? chigh : clow)
			else               predout[i] = (ascore[i] <= cutpoint ? chigh : clow)
		}
		st_store(aidx, newvar, predout)
	}
	else {
		cvals = st_matrix("r_K_cvals")
		if (iscat) {
			catvals  = st_matrix("r_K_catvals")
			catmodel = st_matrix("r_K_catmodel")
			predK = odamK_predict_cat(a, catvals, catmodel, cvals[1])
		}
		else {
			seglabels = st_matrix("r_K_seglabels")
			if (rows(seglabels)>1) cps = st_matrix("r_K_cps")
			else                   cps = J(0,1,.)
			predK = odamK_predict(a, cps, seglabels)
		}
		st_store(aidx, newvar, predK)
	}
}

end
