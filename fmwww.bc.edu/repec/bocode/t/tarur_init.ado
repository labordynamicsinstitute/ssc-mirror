*! tarur_init.ado — Loads TARUR shared mata helpers into memory.
*! Run automatically by every tarur_* command on first use.
*!
*! NOTE: Stata's `discard` does NOT clear Mata. After updating
*! `_tarur_mata.do`, run `mata: mata clear` (or `tarur_init, force`)
*! before the next test so Stata reloads the new mata functions.

program define tarur_init
    version 14.0
    syntax [, FORCE]

    if "`force'" == "" {
        capture mata: _tarur_loaded()
        if _rc == 0 exit 0
    }

    findfile "_tarur_mata.do"
    if "`r(fn)'" == "" {
        di as error "_tarur_mata.do not found on adopath."
        di as error "Place the tarur/ folder on the adopath, e.g.:"
        di as error `"    adopath + "C:/path/to/tarur""'
        exit 601
    }
    quietly do "`r(fn)'"
end
