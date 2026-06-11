*! qqheat 1.0.3 16may2026
*! MATLAB-style heatmap / contour for QQR results
*! Author: Merwan Roudane

program qqheat
    version 14
    syntax [using/] [, VALUE(name) VARIABLE(name) BAND(name) COLORMAP(name) ///
        LEVELS(integer 9) SIGMARK ALPHA(real 0.05) ASPECT(real 1) ///
        TITLE(string) SUBTITLE(string) XTITLE(string) ///
        YTITLE(string) ZTITLE(string) ///
        SAVE(string) NAME(string asis) SCHEME(name) REPLACE]

    if "`value'"==""    local value    "coef"
    if "`colormap'"=="" local colormap "jet"
    if `"`title'"' == ""    local title    "QQR coefficient surface"
    if `"`xtitle'"' == ""   local xtitle   "theta"
    if `"`ytitle'"' == ""   local ytitle   "tau"
    if `"`ztitle'"' == ""   local ztitle   "coefficient"
    if "`scheme'"==""       local scheme   "s2color"

    preserve

    if `"`using'"' != "" {
        qui use `"`using'"', clear
    }

    cap confirm variable `value'
    if _rc {
        di as err "variable {bf:`value'} not found"
        exit 111
    }
    cap confirm variable tau
    if _rc {
        di as err "expected variable tau"
        exit 111
    }
    cap confirm variable theta
    if _rc {
        di as err "expected variable theta"
        exit 111
    }

    if "`variable'" != "" {
        cap confirm variable variable
        if !_rc qui keep if variable == "`variable'"
    }
    if "`band'" != "" {
        cap confirm variable band
        if !_rc qui keep if band == "`band'"
    }

    qui count
    if r(N) == 0 {
        di as err "no observations after filtering"
        exit 2000
    }

    qui su `value', meanonly
    local zmin = r(min)
    local zmax = r(max)
    if (`zmin' < 0) & (`zmax' > 0) {
        local zabs = max(abs(`zmin'), abs(`zmax'))
        local zmin = -`zabs'
        local zmax =  `zabs'
    }

    * twoway contour can fill at most 9 custom color bands: each band needs a
    * scheme cstyle slot, and asking for a 10th throws r(4018) ("class type not
    * found") — which inside a program surfaces as the misleading "matching
    * close brace not found". Sample the colormap into <=9 bands so the palette
    * still spans its whole range (blue->red for jet, etc.).
    local clev = `levels'
    if `clev' > 9 {
        local clev 9
        di as txt "note: twoway contour supports <=9 color bands; using 9" ///
            " (pass levels() <=9 to silence this note)"
    }
    _qqcolors, map(`colormap') zmin(`zmin') zmax(`zmax') levels(`clev')
    local cuts   `r(cuts)'
    local colors `"`r(colors)'"'

    local namopt
    if `"`name'"' != "" {
        if strpos(`"`name'"', ",") local namopt name(`name')
        else                       local namopt name(`name', replace)
    }

    if "`sigmark'" != "" {
        cap confirm variable p
        if !_rc {
            * Build three-tier significance stars (paper style): *** 1%, ** 5%,
            * * 10%. Centred in each cell via marker labels (no marker symbol).
            tempvar star
            qui gen str3 `star' = ""
            qui replace `star' = "*"   if p < 0.10 & p < .
            qui replace `star' = "**"  if p < 0.05 & p < .
            qui replace `star' = "***" if p < 0.01 & p < .
            * Title/axis text live as OVERALL options (after the final comma),
            * never inside a (plot) group: the plot-group parser miscounts
            * parentheses/SMCL braces in titles like "{&beta}({&tau},{&theta})".
            * Use compound quotes `"..."' so parens/commas/em-dashes/SMCL in the
            * title cannot break the option parser.
            twoway (contour `value' tau theta, ccuts(`cuts') ccolors(`colors') ///
                       interp(none) ztitle(`"`ztitle'"'))                      ///
                   (scatter tau theta, msymbol(none)                          ///
                       mlabel(`star') mlabposition(0) mlabcolor(black)         ///
                       mlabsize(small)),                                       ///
                   title(`"`title'"', size(medium))                          ///
                   xtitle(`"`xtitle'"') ytitle(`"`ytitle'"')                 ///
                   note(`"*** p<0.01   ** p<0.05   * p<0.10"', size(vsmall))  ///
                   aspectratio(`aspect') scheme(`scheme') legend(off) `namopt'
        }
        else {
            di as txt "note: variable p not found; significance overlay skipped"
            twoway contour `value' tau theta, ccuts(`cuts') ccolors(`colors')  ///
                interp(none) title(`"`title'"', size(medium))                  ///
                xtitle(`"`xtitle'"') ytitle(`"`ytitle'"') ztitle(`"`ztitle'"') ///
                aspectratio(`aspect') scheme(`scheme') `namopt'
        }
    }
    else {
        twoway contour `value' tau theta, ccuts(`cuts') ccolors(`colors')      ///
            interp(none) title(`"`title'"', size(medium))                      ///
            xtitle(`"`xtitle'"') ytitle(`"`ytitle'"') ztitle(`"`ztitle'"')     ///
            aspectratio(`aspect') scheme(`scheme') `namopt'
    }

    if `"`save'"' != "" {
        if "`replace'"=="replace" graph export `"`save'"', replace
        else                      graph export `"`save'"'
    }

    restore
end
