*! _rals_mata 5.0.0  16may2026  Dr Merwan Roudane
*! Loader for _rals_mata.mata.
*!
*! ssc install / net install copy _rals_mata.mata to PLUS\_\ (because its
*! filename starts with "_") while the .ado files land in PLUS\r\.  Stata's
*! `do filename' searches only the current directory and the directory of
*! the calling .ado -- it does NOT traverse the adopath letter subdirs.
*! So we use `findfile', the canonical Stata mechanism for locating
*! installed package files, to resolve the full path and `do' it.
*!
*! Sourcing the .mata file at the top level (rather than from inside a
*! program) keeps its function definitions in Mata's *global* workspace,
*! where they persist for the rest of the Stata session.
*------------------------------------------------------------------------------
program define _rals_mata
    version 14.0
    quietly findfile _rals_mata.mata
    quietly do `"`r(fn)'"'
end
