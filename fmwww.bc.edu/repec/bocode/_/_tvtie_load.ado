*! _tvtie_load 1.2.0 13sep2026
*! Levent Kutlu
program define _tvtie_load
    version 16.0
    syntax [, FORCE]
    if "`force'" == "" {
        capture mata: assert(_tvtie_version()==10200)
        if !_rc exit
    }
    * Remove only this package's compiled functions, including a partial load.
    capture mata: mata drop _tvtie_*()
    capture program drop _tvtie_mata
    quietly findfile _tvtie_mata.ado
    local source `"`r(fn)'"'
    local strict "`c(matastrict)'"
    capture noisily run `"`source'"'
    local rc = _rc
    quietly mata: mata set matastrict `strict'
    if !`rc' {
        capture noisily mata: _tvtie_smoke()
        local rc = _rc
    }
    if `rc' {
        capture mata: mata drop _tvtie_version()
        capture program drop _tvtie_mata
        di as error "TVTIE's Mata source did not load: `source'"
        di as error "No TVTIE estimates have been posted. The original error is shown above."
        exit `rc'
    }
    capture mata: assert(_tvtie_version()==10200)
    if _rc {
        di as error "TVTIE files are from different releases. Reinstall from one complete package directory."
        exit 459
    }
end
