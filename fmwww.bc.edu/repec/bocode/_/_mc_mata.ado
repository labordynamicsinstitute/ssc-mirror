*! _mc_mata 1.0.0  18may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Loader for _mc_mata.mata - sources the Mata file at top level so the
*! function definitions live in Mata's GLOBAL workspace (rather than being
*! scoped to a Stata program and lost on return).

program define _mc_mata
    version 14.0
    quietly findfile _mc_mata.mata
    quietly do `"`r(fn)'"'
end
