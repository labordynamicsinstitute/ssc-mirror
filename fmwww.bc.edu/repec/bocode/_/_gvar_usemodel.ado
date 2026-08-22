*! _gvar_usemodel 1.0.1  21aug2026
*! gvar use -- read a GVAR back from disk.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane

program define _gvar_usemodel, rclass
    version 14.0

    syntax anything(name=fname id="filename") [, CLEAR noSUMmary ]

    local fname `fname'
    if (strpos("`fname'", ".") == 0) local fname "`fname'.gvar"

    capture confirm file "`fname'"
    if (_rc) {
        di as err "file {bf:`fname'} not found"
        exit 601
    }

    * the engine has to be compiled before a struct instance can be restored:
    * -mata matuse- needs gvarmodel to be a known type
    _gvar_engine

    * a model already in memory would be silently replaced
    capture mata: st_local("busy", strofreal(gvar_isbuilt()))
    if ("`busy'" == "1" & "`clear'" == "") {
        di as err "a GVAR is already in memory"
        di as err "use {bf:gvar use `fname', clear} to replace it, or"
        di as err "{bf:gvar clear} first"
        exit 4
    }

    capture mata: mata drop gvar_MODEL
    quietly mata: mata matuse "`fname'", replace

    capture mata: st_local("ok", strofreal(gvar_isbuilt()))
    if (_rc | "`ok'" != "1") {
        di as err "{bf:`fname'} did not contain a usable GVAR"
        di as err "it may have been written by a different version of the"
        di as err "package, in which case re-estimate and save it again"
        exit 610
    }

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("K",  strofreal(gvar_getK()))
    mata: st_local("T",  strofreal(gvar_getT()))
    mata: st_local("es", strofreal(gvar_isestimated()))
    mata: st_local("sv", strofreal(gvar_issolved()))

    if ("`summary'" != "nosummary") {
        di as text "  model read from " as result "`fname'"
        di as text "  " as result `N' as text " units, " as result `K' ///
                   as text " endogenous variables, " as result `T' ///
                   as text " periods"
        local st "set up"
        if ("`es'" == "1") local st "estimated"
        if ("`sv'" == "1") local st "estimated and solved"
        di as text "  stage: " as result "`st'"
        if ("`sv'" != "1") {
            di as text "  run {bf:gvar solve} before any dynamic analysis"
        }
        di as text "  see {bf:gvar describe} for the specification"
    }

    return scalar N = `N'
    return scalar K = `K'
    return scalar T = `T'
    return scalar estimated = ("`es'" == "1")
    return scalar solved    = ("`sv'" == "1")
end
