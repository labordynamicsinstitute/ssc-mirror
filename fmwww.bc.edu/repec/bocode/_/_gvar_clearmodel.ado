*! _gvar_clearmodel 1.0.1  21aug2026
*! gvar clear -- drop the GVAR from memory.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Drops the model but leaves the compiled engine in place, so the next
* {help gvar_setup:gvar setup} does not have to recompile it.  Note that
* -clear all- drops both, and that -discard- drops neither: interactively
* compiled Mata survives -discard-.

program define _gvar_clearmodel
    version 14.0

    syntax [, noSUMmary ]

    capture mata: st_local("busy", strofreal(gvar_isbuilt()))
    if ("`busy'" != "1") {
        if ("`summary'" != "nosummary") {
            di as text "  no GVAR in memory"
        }
        exit
    }

    capture mata: mata drop gvar_MODEL

    if ("`summary'" != "nosummary") {
        di as text "  GVAR dropped from memory"
        di as text "  the Mata engine is still compiled; the next" ///
                   " {bf:gvar setup} will be quick"
    }
end
