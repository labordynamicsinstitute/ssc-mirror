*! _xtcspqardl_qccepmg v1.1.0  29aug2026 -- QCCEPMG wrapper
*! Quantile CCE Pooled estimator: the shared engine run with the
*! inverse-variance (CCEP) weighting of Pesaran (2006).
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! github.com/merwanroudane
*!
*! Prior to v1.1.0 this file duplicated the mean-group code and returned
*! results numerically IDENTICAL to qccemg, i.e. the pooled option had no
*! effect.  It now delegates to _xtcspqardl_qccemg with `pooled', which
*! forms
*!      W_i        = Omega_i^{-1}                (unit quantile VCE)
*!      theta_P    = (sum_i W_i)^{-1} sum_i W_i theta_i
*!      Var_hom    = (sum_i W_i)^{-1}
*!      Var_robust = (1/N) Psi^{-1} R Psi^{-1},  Psi = (1/N) sum_i W_i,
*!                   R = (1/(N-1)) sum_i W_i d_i d_i' W_i,
*!                   d_i = theta_i - theta_MG        [Pesaran 2006, eq. 67]

capture program drop _xtcspqardl_qccepmg
program define _xtcspqardl_qccepmg, rclass
	version 15.1
	syntax , DEPVAR(string) INDEPVARS(string) ///
		TAU(numlist >0 <1 sort) IVAR(string) TVAR(string) ///
		TOUSE(string) CSAVARS(string) ///
		NCSAORIG(integer) CRLAGS(integer) ///
		[ NOCONStant SHOWIndividual UNITVCE(string) MINT(integer 0) NOCD ]

	_xtcspqardl_qccemg, depvar(`depvar') indepvars(`indepvars') ///
		tau(`tau') ivar(`ivar') tvar(`tvar') touse(`touse') ///
		csavars(`csavars') ncsaorig(`ncsaorig') crlags(`crlags') ///
		pooled unitvce(`unitvce') mint(`mint') `nocd' ///
		`constant' `showindividual'

	return add
end
