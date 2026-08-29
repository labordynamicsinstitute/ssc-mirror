*! _xtpqardl_vce v1.0.4 — Variance engine for quantile ARDL regressions
*! Robust (Powell sandwich), HAC (Newey-West type) and cluster VCEs
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: August 2026
*!
*! Thin Stata wrapper around _xtpq_vcemat() in _xtpqardl_mlib.ado.
*!
*!   V = (1/n) H^-1 J H^-1
*!     H = (1/n) sum_t  K_h(u_t) x_t x_t'         (Powell 1991)
*!     J = (1/n) sum_t sum_s w(|t-s|) psi_t psi_s x_t x_s'
*!     psi_t = tau - 1{u_t < 0}
*!   w(.) : Bartlett / Parzen / quadratic-spectral, or the indicator
*!          1{t=s} (robust), or the full within-group sum (cluster).

capture program drop _xtpqardl_vce
program define _xtpqardl_vce, rclass
	version 15.1
	syntax , YVAR(string) XVARS(string) TOUSE(string) TAU(real) ///
		BNAME(string) ///
		[VCE(string) BW(integer -1) KERNel(string) ///
		 TVAR(string) CLUSTvar(string) NOCONstant]

	_xtpqardl_load

	if "`vce'"    == "" local vce "robust"
	if "`kernel'" == "" local kernel "bartlett"
	local vce    = lower("`vce'")
	local kernel = lower("`kernel'")

	if !inlist("`kernel'", "bartlett", "parzen", "qs") {
		di as err "kernel() must be bartlett, parzen or qs"
		exit 198
	}
	if !inlist("`vce'", "robust", "hac", "cluster") {
		di as err "vce(`vce') not handled by _xtpqardl_vce"
		exit 198
	}
	if "`vce'" == "hac" & "`tvar'" == "" {
		di as err "vce(hac) requires tvar()"
		exit 198
	}

	local cons = cond("`noconstant'" == "", 1, 0)

	tempname V
	capture mata: _xtpq_vce("`yvar'", "`xvars'", "`touse'", `tau', ///
		"`bname'", "`V'", "`vce'", `bw', "`kernel'", "`tvar'", ///
		"`clustvar'", `cons')
	if _rc {
		return scalar ok = 0
		exit 0
	}

	return matrix V = `V'
	return scalar ok = 1
end
