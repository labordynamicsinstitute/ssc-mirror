*! _xtmcg_mata 1.0.0  22may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Mata loader for xtmulticointgrat.  Sources _xtmcg_mata.mata once per session.

program define _xtmcg_mata
    version 14.0
    cap findfile _xtmcg_mata.mata
    if _rc {
        di as err "required file {bf:_xtmcg_mata.mata} not found on the adopath"
        exit 601
    }
    qui run "`r(fn)'"
end
