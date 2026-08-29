*! _xtpqardl_load v1.0.4 — make sure the Mata core is compiled
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: August 2026
*!
*! When Stata auto-loads an ado-file from inside another ado-file it only
*! picks up the program definitions, so the mata block in
*! _xtpqardl_mlib.ado is not compiled that way.  Every xtpqardl entry
*! point calls this program first; it runs the file explicitly the first
*! time and is a no-op afterwards.

capture program drop _xtpqardl_load
program define _xtpqardl_load
	version 15.1

	capture mata: st_local("_xtpq_ok", ///
		strofreal(findexternal("_xtpq_run()") != NULL))
	if "`_xtpq_ok'" == "1" exit

	capture findfile _xtpqardl_mlib.ado
	if _rc {
		di as err "xtpqardl: _xtpqardl_mlib.ado not found on the adopath;"
		di as err "the package is incompletely installed."
		exit 601
	}
	qui run "`r(fn)'"

	capture mata: st_local("_xtpq_ok", ///
		strofreal(findexternal("_xtpq_run()") != NULL))
	if "`_xtpq_ok'" != "1" {
		di as err "xtpqardl: the Mata core failed to compile"
		exit 3499
	}
end
