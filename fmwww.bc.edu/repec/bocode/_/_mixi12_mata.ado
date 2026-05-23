*! _mixi12_mata 1.0.2  21may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*  Loader for _mixi12_mata.mata - sources the Mata file at top level so the
*  function definitions live in Mata's GLOBAL workspace.  Uses a sentinel
*  function probe (rather than a Stata global) to detect whether the
*  kernel is already loaded, which survives `clear all`.

program define _mixi12_mata
    version 14
    capture quietly mata: __mixi12_loaded()
    if _rc == 0 exit 0
    quietly findfile _mixi12_mata.mata
    quietly do `"`r(fn)'"'
end
