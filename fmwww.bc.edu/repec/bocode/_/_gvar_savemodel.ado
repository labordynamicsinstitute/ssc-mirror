*! _gvar_savemodel 1.0.1  21aug2026
*! gvar save -- write the estimated GVAR to disk.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* The whole model lives in one Mata struct, gvar_MODEL, so saving it is a
* single -mata matsave-.  Estimating and solving the 26-unit demo takes a
* couple of minutes; a bootstrap takes several.  Saving means you pay that
* once.
*
* The file is a Mata .mmat, not a dataset.  It carries the estimates, the
* weights, the specification and the solved system, but NOT the panel it was
* built from: the struct holds its own copies of everything it needs, so
* {help gvar_use:gvar use} works without the original data in memory.

program define _gvar_savemodel, rclass
    version 14.0

    syntax anything(name=fname id="filename") [, REPLACE noSUMmary ]

    _gvar_require setup

    * strip any quotes the caller supplied, then add our own extension
    local fname `fname'
    if (strpos("`fname'", ".") == 0) local fname "`fname'.gvar"

    if ("`replace'" == "") {
        capture confirm new file "`fname'"
        if (_rc) {
            di as err "file {bf:`fname'} already exists"
            di as err "use {bf:gvar save `fname', replace} to overwrite it"
            exit 602
        }
    }

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("K",  strofreal(gvar_getK()))
    mata: st_local("es", strofreal(gvar_isestimated()))
    mata: st_local("sv", strofreal(gvar_issolved()))

    quietly mata: mata matsave "`fname'" gvar_MODEL, replace

    capture confirm file "`fname'"
    if (_rc) {
        di as err "the model could not be written to {bf:`fname'}"
        exit 603
    }

    if ("`summary'" != "nosummary") {
        di as text "  model saved to " as result "`fname'"
        di as text "  " as result `N' as text " units, " as result `K' ///
                   as text " endogenous variables" _continue
        if ("`es'" == "1") di as text ", estimated" _continue
        if ("`sv'" == "1") di as text ", solved" _continue
        di ""
        di as text "  restore it with {bf:gvar use `fname'}"
    }

    return local filename "`fname'"
    return scalar N = `N'
    return scalar K = `K'
end
