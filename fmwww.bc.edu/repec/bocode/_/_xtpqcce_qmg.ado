*! _xtpqcce_qmg v1.0.0  20jun2026  Dr Merwan Roudane
*! QCCEMG engine for xtpqcce  (Harding, Lamarche & Pesaran 2018)
*! Per-unit cross-sectionally augmented quantile AR(p) regression (eq 2.17),
*! mean-group averaging (eq 2.21), nonparametric MG variance (sec 2.3).

capture program drop _xtpqcce_qmg
program define _xtpqcce_qmg, rclass
	version 15.1
	syntax , DEPVAR(string) INDEPVARS(string) TAU(numlist) ///
		IVAR(string) TVAR(string) TOUSE(string) CSA(string) ///
		LAGS(integer) [ noCONStant noDOTs ]

	local k    : word count `indepvars'
	local ntau : word count `tau'
	local ncsa : word count `csa'
	qui levelsof `ivar' if `touse', local(ids)
	local N : word count `ids'

	* -----------------------------------------------------------------
	* Plain (non-ts) regressor copies (qreg dislikes ts operators)
	* -----------------------------------------------------------------
	tempvar yp
	qui gen double `yp' = `depvar' if `touse'

	local arvars ""
	forvalues l = 1/`lags' {
		tempvar ly`l'
		qui gen double `ly`l'' = L`l'.`depvar' if `touse'
		local arvars "`arvars' `ly`l''"
	}
	local xp ""
	forvalues j = 1/`k' {
		local xj : word `j' of `indepvars'
		tempvar x`j'
		qui gen double `x`j'' = `xj' if `touse'
		local xp "`xp' `x`j''"
	}
	* csa already plain temp variables
	local reg "`arvars' `xp' `csa'"
	local ncoef : word count `reg'

	* -----------------------------------------------------------------
	* Storage: per-unit blocks (rows = units, cols = tau-major)
	*   Bbeta : N x (ntau*k)   beta_j per tau
	*   Blam  : N x ntau       lambda = sum of AR coefs per tau
	* -----------------------------------------------------------------
	tempname Bbeta Blam Btheta
	matrix `Bbeta'  = J(`N', `ntau'*`k', .)
	matrix `Blam'   = J(`N', `ntau', .)
	matrix `Btheta' = J(`N', `ntau'*`k', .)

	local needed = `ncoef' + 3
	local pi 0
	local good 0
	if "`dots'" == "" di as txt "  estimating `N' panels: " _c
	foreach id of local ids {
		local ++pi
		qui count if `touse' & `ivar'==`id' & `yp'<.
		if r(N) < `needed' {
			if "`dots'" == "" di as txt "x" _c
			continue
		}
		local okany 0
		local ti 0
		foreach q of local tau {
			local ++ti
			capture qui qreg `yp' `reg' if `touse' & `ivar'==`id', ///
				quantile(`q')
			if _rc & _rc!=498 continue
			if e(N) < `needed' continue
			tempname b
			matrix `b' = e(b)
			local okany 1
			* lambda = sum of AR coefficients (positions 1..lags)
			local lam 0
			forvalues l = 1/`lags' {
				local lam = `lam' + `b'[1,`l']
			}
			if `lags' > 0 matrix `Blam'[`pi', `ti'] = `lam'
			* beta_j = coefficient on x_j (positions lags+1 .. lags+k)
			forvalues j = 1/`k' {
				local bcol = (`ti'-1)*`k' + `j'
				local bv = `b'[1, `lags'+`j']
				matrix `Bbeta'[`pi', `bcol'] = `bv'
				* long-run effect theta = beta/(1-lambda)
				if `lags' > 0 {
					if abs(1-`lam') > 1e-8 {
						matrix `Btheta'[`pi', `bcol'] = `bv'/(1-`lam')
					}
				}
				else {
					matrix `Btheta'[`pi', `bcol'] = `bv'
				}
			}
		}
		if `okany' {
			local ++good
			if "`dots'" == "" di as txt "." _c
		}
		else if "`dots'" == "" di as txt "x" _c
	}
	if "`dots'" == "" di ""

	* -----------------------------------------------------------------
	* Mean group + nonparametric MG variance via shared Mata
	* -----------------------------------------------------------------
	tempname bmg bV bSE bnv
	mata: xtpqcce_mgvar("`Bbeta'", `ntau', `k', "`bmg'", "`bV'", "`bSE'", "`bnv'")

	tempname tmg tV tSE tnv
	mata: xtpqcce_mgvar("`Btheta'", `ntau', `k', "`tmg'", "`tV'", "`tSE'", "`tnv'")

	tempname lmg lV lSE lnv
	if `lags' > 0 {
		mata: xtpqcce_mgvar("`Blam'", `ntau', 1, "`lmg'", "`lV'", "`lSE'", "`lnv'")
	}
	else {
		matrix `lmg' = J(1, `ntau', .)
		matrix `lV'  = J(`ntau', `ntau', 0)
		matrix `lSE' = J(1, `ntau', .)
	}

	* -----------------------------------------------------------------
	* Assemble final mg / V / SE  = [ beta-block | lambda-block ]
	* lambda columns named lam_1..lam_ntau so the display can find them
	* -----------------------------------------------------------------
	local pb = `ntau'*`k'
	local pf = `pb' + `ntau'
	tempname MG VV SE
	matrix `MG' = J(1, `pf', 0)
	matrix `VV' = J(`pf', `pf', 0)
	matrix `SE' = J(1, `pf', 0)
	matrix `MG'[1, 1] = `bmg'
	matrix `SE'[1, 1] = `bSE'
	forvalues r = 1/`pb' {
		forvalues c = 1/`pb' {
			matrix `VV'[`r',`c'] = `bV'[`r',`c']
		}
	}
	forvalues t = 1/`ntau' {
		local cc = `pb' + `t'
		matrix `MG'[1, `cc'] = `lmg'[1, `t']
		matrix `SE'[1, `cc'] = `lSE'[1, `t']
		matrix `VV'[`cc', `cc'] = `lV'[`t', `t']
	}
	* column / row names (lambda part)
	local cn ""
	forvalues t = 1/`ntau' {
		forvalues j = 1/`k' {
			local cn "`cn' b`j'_`t'"
		}
	}
	forvalues t = 1/`ntau' {
		local cn "`cn' lam_`t'"
	}
	matrix colnames `MG' = `cn'
	matrix colnames `SE' = `cn'
	matrix colnames `VV' = `cn'
	matrix rownames `VV' = `cn'

	* half-life from MG lambda
	tempname HL
	matrix `HL' = J(1, `ntau', .)
	forvalues t = 1/`ntau' {
		local lv = `lmg'[1, `t']
		if `lv'<. & abs(`lv')>0 & abs(`lv')<1 {
			matrix `HL'[1, `t'] = ln(0.5)/ln(abs(`lv'))
		}
	}

	* -----------------------------------------------------------------
	* Return
	* -----------------------------------------------------------------
	return scalar valid_panels = `good'
	return matrix b_i   = `Bbeta'
	return matrix mg    = `MG'
	return matrix V     = `VV'
	return matrix SE    = `SE'
	return matrix lr_i  = `Btheta'
	return matrix lr_mg = `tmg'
	return matrix lr_V  = `tV'
	return matrix lr_SE = `tSE'
	return matrix hl_mg = `HL'
end


* =====================================================================
* MATA: nonparametric mean-group mean and variance (HLP 2018, sec 2.3)
*   B : N x (ntau*kblk) matrix of unit estimates (. = missing/failed)
*   per quantile block of width kblk:
*     mean = (1/Nb) sum_i theta_i
*     V    = (1/(Nb*(Nb-1))) sum_i dev dev'   (covariance of the MG mean)
* =====================================================================
version 15.1
mata:
mata set matastrict off

void xtpqcce_mgvar(string scalar Bname, real scalar ntau, real scalar kblk,
                   string scalar omean, string scalar oV, string scalar oSE,
                   string scalar onvalid)
{
    real matrix B, V
    real rowvector M, SE
    real colvector nvb
    real scalar N, p, t, c0, c1, i, r, c, Nb, sm, ok

    B = st_matrix(Bname)
    N = rows(B)
    p = ntau*kblk
    M  = J(1, p, .)
    SE = J(1, p, .)
    V  = J(p, p, 0)
    nvb = J(ntau, 1, 0)

    for (t=1; t<=ntau; t++) {
        c0 = (t-1)*kblk + 1
        c1 = t*kblk
        // count complete units in this block
        Nb = 0
        for (i=1; i<=N; i++) {
            ok = 1
            for (c=c0; c<=c1; c++) {
                if (B[i,c]==.) ok = 0
            }
            if (ok) Nb = Nb + 1
        }
        nvb[t] = Nb
        if (Nb < 1) continue
        // means
        for (c=c0; c<=c1; c++) {
            sm = 0
            for (i=1; i<=N; i++) {
                if (B[i,c]!=.) sm = sm + B[i,c]
            }
            M[c] = sm/Nb
        }
        if (Nb < 2) continue
        // covariance of the MG mean = (1/(Nb(Nb-1))) sum dev dev'
        for (i=1; i<=N; i++) {
            ok = 1
            for (c=c0; c<=c1; c++) {
                if (B[i,c]==.) ok = 0
            }
            if (ok==0) continue
            for (r=c0; r<=c1; r++) {
                for (c=c0; c<=c1; c++) {
                    V[r,c] = V[r,c] + (B[i,r]-M[r])*(B[i,c]-M[c])
                }
            }
        }
        for (r=c0; r<=c1; r++) {
            for (c=c0; c<=c1; c++) {
                V[r,c] = V[r,c] / (Nb*(Nb-1))
            }
            SE[r] = sqrt(V[r,r])
        }
    }
    st_matrix(omean, M)
    st_matrix(oV, V)
    st_matrix(oSE, SE)
    st_matrix(onvalid, nvb)
}
end
