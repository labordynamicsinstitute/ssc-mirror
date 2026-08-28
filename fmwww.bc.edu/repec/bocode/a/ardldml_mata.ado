*! ardldml_mata 1.0.1  24aug2026
*! Mata engine loader for ardldml -- DML-Bounds (Villena 2026, SSRN 6472826)
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
*  Guarantees the ardldml_*() Mata functions are in memory, and is called by
*  ardldml, ardldml_estat and ardldml_p before any of them touch the engine.
*
*  Two ways in, tried in order:
*
*    1. lardldml.mlib, the compiled library. Fast, but Stata finds a library
*       only through its mlib search list, and that list is built when Stata
*       starts. A library installed mid-session is invisible until the user
*       runs "mata mlib index" or restarts, which is what produced reports of
*         "the ardldml Mata library (lardldml.mlib) could not be found"
*       straight after ssc install. Rebuilding the index here fixes that case.
*
*    2. ardldml.mata, the source, compiled on the spot. This is the safety
*       net: it needs no search list and no particular Stata version, so it
*       works even where the library cannot be read at all.
*
*  Note the source must be reached with "do". An ado file that Stata
*  auto-loads from the adopath has only its program definition executed --
*  anything after the program's "end", a trailing mata block included, is
*  ignored. That is exactly why the engine cannot simply live at the bottom
*  of this file, and why packages ship a .mlib in the first place.

program define ardldml_mata
	version 14.0

	// already loaded?
	capture mata: st_numscalar("__ardldml_v", ardldml_version())
	if (_rc == 0) {
		capture scalar drop __ardldml_v
		exit
	}

	// path 1: the library may be on disk but not yet in the search list
	capture quietly mata: mata mlib index
	capture mata: st_numscalar("__ardldml_v", ardldml_version())
	if (_rc == 0) {
		capture scalar drop __ardldml_v
		exit
	}

	// path 2: compile the shipped source
	capture findfile ardldml.mata
	if (_rc) {
		di as error "ardldml: the Mata engine could not be loaded."
		di as error "Neither lardldml.mlib nor ardldml.mata was found on the adopath."
		di as error "Reinstall the package: {stata ssc install ardldml, replace}"
		exit 601
	}
	capture noisily quietly do "`r(fn)'"
	if (_rc) {
		di as error "ardldml: the Mata engine failed to compile (rc = `_rc')."
		di as error "Please report this with your Stata version to"
		di as error "merwanroudane920@gmail.com"
		exit _rc
	}

	capture mata: st_numscalar("__ardldml_v", ardldml_version())
	if (_rc) {
		di as error "ardldml: the Mata engine did not load. Reinstall the package."
		exit 3499
	}
	capture scalar drop __ardldml_v
end
