*! _xtcspqardl_mata v1.1.0  29aug2026
*! Loader for the xtcspqardl Mata aggregation engine.
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! github.com/merwanroudane
*!
*! Stata's ado loader does NOT execute a trailing `mata: ... end' block
*! inside an .ado file: it defines the programs and stops.  A shared Mata
*! library therefore cannot be compiled by simply appending it to an ado.
*! This program locates the source file _xtcspqardl_mata.mata on the
*! adopath and executes it with `run', which does compile it.
*!
*! It is safe to call repeatedly.  A cheap probe, _xtcspq_ver(), tells the
*! loader whether the library is already compiled in this session, so the
*! usual cost is a single `capture'.  If a partial state is found (some
*! functions dropped by hand, or a `discard' after an interrupted run) the
*! remaining functions are dropped one at a time and the library is
*! recompiled from scratch.

capture program drop _xtcspqardl_mata
program define _xtcspqardl_mata
	version 15.1

	* already compiled and complete?
	capture mata: st_numscalar("__xtcspq_ok", _xtcspq_ver())
	if _rc == 0 {
		if __xtcspq_ok == 110 {
			scalar drop __xtcspq_ok
			exit
		}
		scalar drop __xtcspq_ok
	}

	* Drop anything left over, one name at a time: a single multi-name
	* `mata drop' aborts wholesale if any one name is absent, which would
	* leave the session permanently unable to recompile.
	foreach f in _xtcspq_init _xtcspq_put _xtcspq_mg _xtcspq_pool   ///
		_xtcspq_lrdelta _xtcspq_wald _xtcspq_iqr _xtcspq_cd      ///
		_xtcspq_gjmo _xtcspq_r1 _xtcspq_getall _xtcspq_getok       ///
		_xtcspq_drop _xtcspq_ver {
		capture mata mata drop `f'()
	}

	capture quietly findfile "_xtcspqardl_mata.mata"
	if _rc != 0 {
		di as err "_xtcspqardl_mata.mata not found on the adopath"
		di as err "  reinstall xtcspqardl, or check {cmd:adopath}"
		exit 601
	}
	quietly run "`r(fn)'"

	capture mata: st_numscalar("__xtcspq_ok", _xtcspq_ver())
	if _rc == 0 scalar drop __xtcspq_ok
	if _rc != 0 {
		di as err "the xtcspqardl Mata library failed to compile"
		di as err "  run {cmd:do} on the file reported by " ///
			"{cmd:findfile _xtcspqardl_mata.mata} to see the line"
		exit 3000
	}
end
