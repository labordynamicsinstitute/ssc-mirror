*! _tc_load 1.0.0  16may2026  Dr Merwan Roudane
*! Loader for _threshcoint_mata.mata.
*!
*! ssc install / net install copy _threshcoint_mata.mata to PLUS\_\
*! (because its filename starts with "_") while the .ado files land in
*! PLUS\t\ (or PLUS\_\ for _tc_load.ado).  Stata's `do filename'
*! searches only the current directory and the directory of the calling
*! .ado -- it does NOT traverse the adopath letter subdirs.  So we use
*! `findfile', the canonical Stata mechanism for locating installed
*! package files, to resolve the full path and `do' it.
*!
*! Sourcing the .mata file at the top level (rather than from inside a
*! program) keeps its function definitions in Mata's *global* workspace,
*! where they persist for the rest of the Stata session.
*------------------------------------------------------------------------------
program define _tc_load
    version 14.0
    capture mata: __tc_loaded()
    if !_rc exit 0
    quietly findfile _threshcoint_mata.mata
    quietly do `"`r(fn)'"'
end
