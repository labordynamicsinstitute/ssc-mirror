*! _gvar_engine 1.0.1  21aug2026
*! Loads and verifies the Mata computational engine of the gvar package.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* The whole engine lives in _gvar_mata.ado as a single mata: block, so that
* `struct gvarmodel' is always compiled before the routines that use it.
*
* The file is sourced with -run- (not by invoking a program) because -run-
* executes it top to bottom exactly like -do-, which is the only mechanism
* that reliably compiles a mata: block held inside an ado-file.

program define _gvar_engine
    version 14.0

    * -----------------------------------------------------------------------
    * 1.  Shared helper programs (_gvar_title, _gvar_palette, _gvar_require...)
    * -----------------------------------------------------------------------
    * They live together in _gvar_util.ado.  Stata only auto-loads an ado-file
    * whose NAME matches the command being called, so a helper defined inside
    * a differently-named file is never found on its own; the file has to be
    * sourced explicitly.
    capture _gvar_palette
    if (_rc) {
        capture findfile _gvar_util.ado
        if (_rc) {
            di as err "gvar: cannot locate {bf:_gvar_util.ado} on the adopath"
            exit 601
        }
        quietly run `"`r(fn)'"'
    }
    capture _gvar_palette
    if (_rc) {
        di as err "gvar: the shared helper programs failed to load"
        exit 499
    }

    * -----------------------------------------------------------------------
    * 2.  The Mata engine
    * -----------------------------------------------------------------------
    * The engine is reloaded unless the COMPILED version is the one this file
    * expects.  Testing only that gvar_version() resolves was wrong: Mata
    * functions survive -discard-, so a user who ran -ssc install gvar, replace-
    * mid-session kept executing the previous engine against the new ado files,
    * silently, for the rest of the session.  Comparing versions costs one Mata
    * call and makes an in-session upgrade take effect.
    local gvarexpect 1.0.1
    capture mata: st_local("__gvarver", gvar_version())
    if (_rc == 0 & "`__gvarver'" == "`gvarexpect'") {
        exit
    }
    if (_rc == 0 & "`__gvarver'" != "") {
        * A DIFFERENT engine is compiled -- the ado files have been upgraded
        * under a session that still holds the old Mata code.  Mata refuses to
        * redefine an existing function ("gvar_version() already exists",
        * r(3000)), so the old one has to go before the new file is run.  The
        * drop is scoped to gvar_*(): -mata clear- would work too but would
        * destroy whatever Mata functions and objects the USER has defined,
        * which is not this package's to throw away.
        * Say what is about to be lost.  Replacing the engine drops gvar_MODEL
        * along with the struct it is an instance of, so any fitted model goes
        * with it -- the alternative, keeping a stale engine, means running new
        * ado files against old Mata code and getting wrong answers quietly.
        * Without this message the user sees only "no GVAR in memory" from the
        * NEXT command and has no idea why.
        di as text "{p}gvar: the compiled Mata engine is version " ///
           as result "`__gvarver'" as text " but these ado files are " ///
           as result "`gvarexpect'" as text " -- the package was upgraded " ///
           "during this session.  Reloading the engine now.  Any model in " ///
           "memory is discarded with it, so re-run {bf:gvar setup} and the " ///
           "steps after it.{p_end}"
        * Everything the engine defines, in dependency order: the functions
        * first, then the model object, then the struct it is an instance of.
        * gvarmodel does NOT match gvar_* -- it has no underscore -- and six
        * routines carry the _gvar_ prefix, so a single gvar_*() drop leaves
        * both behind and the recompile dies "gvarmodel() already exists".
        capture mata: mata drop gvar_*()
        capture mata: mata drop _gvar_*()
        capture mata: mata drop gvar_MODEL
        capture mata: mata drop gvarmodel()
    }

    capture findfile _gvar_mata.ado
    if (_rc) {
        di as err "gvar: cannot locate {bf:_gvar_mata.ado} on the adopath"
        di as err "the gvar package looks incompletely installed"
        exit 601
    }
    local mfile `"`r(fn)'"'
    quietly run `"`mfile'"'

    capture mata: st_local("__gvarver", gvar_version())
    if (_rc | "`__gvarver'" == "") {
        di as err "gvar: the Mata engine failed to compile"
        di as err `"run {bf:do "`mfile'"} directly to see the offending line"'
        exit 499
    }
end
