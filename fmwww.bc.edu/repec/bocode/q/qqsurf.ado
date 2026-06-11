*! qqsurf 1.0.0 16may2026
*! Pseudo-3D surface plot for QQR results (uses oblique projection on
*! a (theta, tau) grid with z-coloured cells). For true rotatable 3D
*! export results to MATLAB / Python.
*! Author: Merwan Roudane

program qqsurf
    version 14
    syntax [using/] [,                       ///
        Value(string)                        ///
        VARiable(string)                     ///
        BAND(string)                         ///
        COLormap(string)                     ///
        Title(string)                        ///
        XTitle(string)                       ///
        YTitle(string)                       ///
        ZTitle(string)                       ///
        Levels(integer 30)                   ///
        AZIMuth(real 35)                     ///
        ELEvation(real 25)                   ///
        SAVE(string)                         ///
        Name(string asis)                    ///
        SCheme(string)                       ///
        REPLACE ]

    if "`value'"==""    local value    "coef"
    if "`colormap'"=="" local colormap "jet"
    if "`title'"==""    local title    "QQR pseudo-3D surface"
    if "`xtitle'"==""   local xtitle   "{&theta}"
    if "`ytitle'"==""   local ytitle   "{&tau}"
    if "`ztitle'"==""   local ztitle   "{&beta}"
    if "`scheme'"==""   local scheme   "s2color"

    preserve

    if `"`using'"' != "" use `"`using'"', clear

    cap confirm variable `value'
    if _rc {
        di as err "value variable `value' not found"
        exit 111
    }
    foreach v in tau theta {
        cap confirm variable `v'
        if _rc {
            di as err "expected variable `v' in dataset"
            exit 111
        }
    }

    if "`variable'" != "" {
        cap confirm variable variable
        if !_rc keep if variable == "`variable'"
    }
    if "`band'" != "" {
        cap confirm variable band
        if !_rc keep if band == "`band'"
    }

    * Project (theta, tau, z) onto 2D plane
    local cosA = cos(`azimuth'   * _pi / 180)
    local sinA = sin(`azimuth'   * _pi / 180)
    local sinE = sin(`elevation' * _pi / 180)

    qui su `value', meanonly
    local zmin = r(min)
    local zmax = r(max)
    if (`zmin' < 0) & (`zmax' > 0) {
        local zabs = max(abs(`zmin'), abs(`zmax'))
        local zmin = -`zabs'
        local zmax =  `zabs'
    }
    local zrng = `zmax' - `zmin'
    if `zrng' <= 0 local zrng = 1

    qui gen double _xproj = theta * `cosA' - tau * `sinA'
    qui gen double _yproj = theta * `sinA' * `sinE' + tau * `cosA' * `sinE' ///
                          + (`value' - `zmin') / `zrng'

    * Color the points by z using the same colormap
    _qqcolors, map(`colormap') zmin(`zmin') zmax(`zmax') levels(`levels')
    local colors `"`r(colors)'"'
    local cuts   `r(cuts)'

    * Build a series of scatter overlays, one per color bucket
    local ncolors : word count `colors'

    * _qqcolors returns `ncolors' colors but only `ncolors'-1 cuts (the interior
    * boundaries). Bucket i spans [cut(i-1), cut(i)); the first bucket opens at
    * zmin-eps and the last closes at zmax+eps so every point lands in exactly
    * one bucket. The old code read word(i) of cuts as the LOWER bound, so for
    * the last bucket(s) word(i+1) overran the cuts list -> empty `lo'/`hi' ->
    * "if coef >= & coef <" -> "coef< invalid name" r(198).
    local plot ""
    forval i = 1/`ncolors' {
        if `i' == 1 {
            local lo = `zmin' - 1
        }
        else {
            local im1 = `i' - 1
            local lo : word `im1' of `cuts'
        }
        if `i' == `ncolors' {
            local hi = `zmax' + 1
        }
        else {
            local hi : word `i' of `cuts'
        }
        local col : word `i' of `colors'
        * strip quotes
        local col = subinstr(`"`col'"', `"""', "", .)
        local plot `plot' (scatter _yproj _xproj if `value' >= `lo' & `value' < `hi', ///
            msymbol(square) msize(medsmall) mcolor("`col'") mlcolor("`col'"))
    }

    local nameopt
    if `"`name'"' != "" {
        if strpos(`"`name'"', ",") local nameopt name(`name')
        else                       local nameopt name(`name', replace)
    }

    twoway `plot', legend(off) ///
        title(`"`title'"', size(medium))    ///
        subtitle(`"projection: az=`azimuth' el=`elevation', color={bf:`value'}"', size(small)) ///
        xtitle(`"`xtitle'"') ytitle(`"`ytitle'"') ///
        scheme(`scheme') aspectratio(1) `nameopt'

    if `"`save'"' != "" {
        if "`replace'"=="replace" graph export `"`save'"', replace
        else                       graph export `"`save'"'
    }

    restore
end
