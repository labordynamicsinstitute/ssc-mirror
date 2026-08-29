*! _xtpqardl_delta v1.0.4 — delta-method mapping of a quantile ARDL fit
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: August 2026
*!
*! Maps the estimated conditional-ECM coefficient vector
*!     b = (rho, gamma_1..gamma_kx, phi_1..phi_{p-1}, theta_1..theta_s, _cons)
*! into the reported parameter vector
*!     g = (rho, beta_1..beta_kx, phi_1..phi_{p-1}, theta_1..theta_s)
*! with beta_j = -gamma_j / rho, transporting the covariance by the
*! delta method.  Thin wrapper around _xtpq_delta() in _xtpqardl_mlib.ado.

capture program drop _xtpqardl_delta
program define _xtpqardl_delta, rclass
	version 15.1
	syntax , BNAME(string) VNAME(string) KX(integer) NREST(integer) ///
		GNAME(string) VGNAME(string)

	_xtpqardl_load

	mata: _xtpq_delta("`bname'", "`vname'", `kx', `nrest', "`gname'", "`vgname'")
end
