*! xtbalfront v1.2.3  06may2026  Noman Arshed
*! Trade-off frontier diagnostics and balanced-subsample selection for
*! unbalanced panel data.
*!
*! Author : Noman Arshed (Sunway Business School, Sunway University)
*! Email  : nomana@sunway.edu.my
*! Web    : https://econistics.com
*!
*! v1.2.3  Removed title from trade-off plots (rendering issue with macros);
*!         added xtset + xtdescribe panel-structure summary at the start of
*!         the command; added overlaid pre/post histogram comparison plots
*!         (one per variable) when a subsample is selected, with mean %
*!         change in the note; trimmed the help (removed MCAR / R-squared
*!         discussion and Future work section).
*! v1.2.2  bug fixes: heatmap helper now computes the cross-section count
*!         internally; plot title built as plain text in twoway directly.
*! v1.2.1  bug fix: renamed sub-program option from anchor_label to anchorlbl.
*! v1.2.0  Renamed from balancepanel; added recency-anchored curve as default,
*!         two separate trade-off plots, heatmap, gap detection, comparison
*!         table, selected-cross-section listing, dryrun, and SSC-ready help.
*! v1.1.0  added endperiod()/startperiod()/recent/savematrix() (as balancepanel)
*! v1.0.0  initial release (as balancepanel)

capture program drop xtbalfront
program define xtbalfront, rclass
    version 16.0

    syntax varlist(numeric min=1) [if] [in],         ///
        ID(varname numeric)                           ///
        TIME(varname numeric)                         ///
        [                                             ///
            YEARS(integer 0)                          ///
            CROSSsections(integer 0)                  ///
            ENDperiod(numlist max=1)                  ///
            STARTperiod(numlist max=1)                ///
            RECent                                    ///
            GENerate(name)                            ///
            KEEP                                      ///
            DRYrun                                    ///
            ANY                                       ///
            NOGRAPH                                   ///
            NOHEAtmap                                 ///
            NOHIST                                    ///
            NOLIST                                    ///
            NOCOMPare                                 ///
            NOGAPnote                                 ///
            NOSELlist                                 ///
            NOHISTcompare                             ///
            MAXLIst(integer 50)                       ///
            MAXShow(integer 200)                      ///
            LColor(string)                            ///
            MColor(string)                            ///
            SAVEmatrix(name)                          ///
            SAVErecent(name)                          ///
        ]

    local mode = cond("`any'" != "", "any", "window")
    if "`lcolor'"  == "" local lcolor "navy"
    if "`mcolor'"  == "" local mcolor "navy"

    *--------------------------------------------------------------
    * 1. Validate inputs
    *--------------------------------------------------------------
    marksample touse, novarlist
    qui replace `touse' = 0 if missing(`id') | missing(`time')

    qui count if `touse'
    if r(N) == 0 {
        di as error "no observations to analyse after if/in"
        exit 2000
    }

    tempvar nrep
    qui egen long `nrep' = total(`touse'), by(`id' `time')
    qui count if `nrep' > 1 & `touse'
    if r(N) > 0 {
        di as error "{bf:`id'} and {bf:`time'} do not uniquely identify observations"
        di as error "after the if/in restriction; remove duplicate id-time obs and try again"
        exit 459
    }

    if "`generate'" != "" {
        capture confirm new variable `generate'
        if _rc {
            di as error "variable {bf:`generate'} already exists; pick another name"
            exit 110
        }
    }

    if `years' < 0 | `crosssections' < 0 {
        di as error "years() and crosssections() must be non-negative"
        exit 198
    }

    if `years' > 0 & `crosssections' > 0 {
        di as error "specify only one of years() or crosssections(), not both"
        exit 198
    }

    *--------------------------------------------------------------
    * 2. Resolve the user-specified anchor (if any)
    *--------------------------------------------------------------
    if "`recent'" != "" {
        if "`endperiod'" != "" {
            di as error "specify only one of recent or endperiod()"
            exit 198
        }
        qui summarize `time' if `touse', meanonly
        local endperiod = r(max)
    }

    foreach a in endperiod startperiod {
        if "``a''" != "" {
            qui count if `time' == ``a'' & `touse'
            if r(N) == 0 {
                di as error "{bf:`a'(``a'')} is not a period present in the data"
                exit 198
            }
        }
    }

    if "`endperiod'" != "" & "`startperiod'" != "" {
        if `startperiod' > `endperiod' {
            di as error "startperiod() must not exceed endperiod()"
            exit 198
        }
    }

    if "`mode'" == "any" & ("`endperiod'`startperiod'" != "") {
        di as error "endperiod()/startperiod()/recent are not allowed with the any option"
        exit 198
    }

    * For the anchored curve: if user specified an anchor, use it; otherwise
    * default to anchor at the maximum time period (the recency-anchored case).
    local user_specified_anchor = ("`endperiod'`startperiod'" != "")
    local anc_endperiod   "`endperiod'"
    local anc_startperiod "`startperiod'"
    if "`mode'" == "window" & !`user_specified_anchor' {
        qui summarize `time' if `touse', meanonly
        local anc_endperiod = r(max)
    }

    local anchor_label ""
    if "`mode'" == "window" {
        if `user_specified_anchor' {
            if "`endperiod'" != "" & "`startperiod'" != "" {
                local anchor_label "fixed window [`startperiod', `endperiod']"
            }
            else if "`endperiod'" != "" {
                local anchor_label "end-anchored at `endperiod'"
            }
            else {
                local anchor_label "start-anchored at `startperiod'"
            }
        }
        else {
            local anchor_label "recency-anchored at `anc_endperiod'"
        }
    }

    *--------------------------------------------------------------
    * 3. Build the row-wise validity indicator
    *--------------------------------------------------------------
    tempvar miss valid
    qui egen `miss' = rowmiss(`varlist') if `touse'
    qui gen byte `valid' = (`miss' == 0) if `touse'
    qui replace `valid' = 0 if missing(`valid')

    qui count if `valid' == 1
    if r(N) == 0 {
        di as error "no observation has all `varlist' non-missing"
        exit 2000
    }

    *--------------------------------------------------------------
    * 3b. Panel-structure summary (xtset + xtdescribe)
    *--------------------------------------------------------------
    di
    di as text "{hline 70}"
    di as text "Panel structure"
    di as text "{hline 70}"
    qui xtset `id' `time'
    capture noisily xtdescribe if `touse'
    if _rc {
        di as text "  (xtdescribe could not be displayed for the if/in sample)"
    }

    *--------------------------------------------------------------
    * 4. Compute curves and diagnostics in Mata
    *--------------------------------------------------------------
    tempname CURVE_BEST CURVE_ANC

    * Best-window curve (no anchor)
    mata: xtbf_compute("`id'", "`time'", "`valid'", "`touse'", ///
                       "`mode'", ".", ".", "`CURVE_BEST'")
    local nrows_best  = r(nrows)
    local totalN      = r(totalN)
    local maxL        = r(maxL)
    local gap_count   = r(gap_count)
    local nodata_count = r(nodata_count)
    local gap_severity = r(gap_severity)

    * Anchored curve (only in window mode)
    local has_anc 0
    if "`mode'" == "window" {
        local epstr = cond("`anc_endperiod'"   == "", ".", "`anc_endperiod'")
        local spstr = cond("`anc_startperiod'" == "", ".", "`anc_startperiod'")
        mata: xtbf_compute("`id'", "`time'", "`valid'", "`touse'", ///
                           "window", "`epstr'", "`spstr'", "`CURVE_ANC'")
        local nrows_anc = r(nrows)
        local has_anc 1
    }

    local timefmt : format `time'

    *--------------------------------------------------------------
    * 5. Decide which curve drives the filter selection
    *--------------------------------------------------------------
    * If the user explicitly requested an anchor (endperiod/startperiod/recent),
    * filter from the anchored curve. Otherwise the default filter uses the
    * best-window curve.
    local filter_curve "`CURVE_BEST'"
    local filter_nrows = `nrows_best'
    local filter_label ""
    if "`mode'" == "window" & `user_specified_anchor' {
        local filter_curve "`CURVE_ANC'"
        local filter_nrows = `nrows_anc'
        local filter_label " (`anchor_label')"
    }

    *--------------------------------------------------------------
    * 6. If a target was requested, identify the selected window
    *--------------------------------------------------------------
    local selL .
    local selN .
    local selS .
    local selE .
    local has_filter 0

    if `years' > 0 | `crosssections' > 0 {
        local has_filter 1

        if `years' > 0 {
            forvalues r = 1/`filter_nrows' {
                if `filter_curve'[`r', 1] == `years' & `filter_curve'[`r', 2] >= 1 {
                    local selL = `filter_curve'[`r', 1]
                    local selN = `filter_curve'[`r', 2]
                    local selS = `filter_curve'[`r', 3]
                    local selE = `filter_curve'[`r', 4]
                    continue, break
                }
            }
            if missing(`selL') {
                di as error "no balanced panel of `years' years can be formed`filter_label'"
                exit 2000
            }
        }
        else {
            forvalues r = `filter_nrows'(-1)1 {
                if `filter_curve'[`r', 2] >= `crosssections' {
                    local selL = `filter_curve'[`r', 1]
                    local selN = `filter_curve'[`r', 2]
                    local selS = `filter_curve'[`r', 3]
                    local selE = `filter_curve'[`r', 4]
                    continue, break
                }
            }
            if missing(`selL') {
                di as error "no balanced panel with at least `crosssections' " ///
                    "cross-sections can be formed`filter_label'"
                exit 2000
            }
        }
    }

    *--------------------------------------------------------------
    * 7. Tag selected observations (without applying yet)
    *--------------------------------------------------------------
    tempvar selected
    qui gen byte `selected' = 0

    if `has_filter' {
        tempvar inwin nwin
        if "`mode'" == "window" {
            qui gen byte `inwin' = (`touse' & `valid' == 1 & ///
                `time' >= `selS' & `time' <= `selE')
            qui bysort `id': egen `nwin' = total(`inwin')
            qui replace `selected' = 1 if `inwin' == 1 & `nwin' == `selL'
        }
        else {
            qui gen byte `inwin' = (`touse' & `valid' == 1)
            qui bysort `id': egen `nwin' = total(`inwin')
            qui replace `selected' = 1 if `inwin' == 1 & `nwin' >= `selL'
        }
    }

    *--------------------------------------------------------------
    * 8. Save matrices if requested
    *--------------------------------------------------------------
    if "`savematrix'" != "" {
        capture matrix drop `savematrix'
        matrix `savematrix' = `CURVE_BEST'
    }
    if "`saverecent'" != "" & `has_anc' {
        capture matrix drop `saverecent'
        matrix `saverecent' = `CURVE_ANC'
    }

    *--------------------------------------------------------------
    * 9. Display: trade-off tables
    *--------------------------------------------------------------
    if "`nolist'" == "" {
        _xtbalfront_listcurve `CURVE_BEST', label("Best consecutive window") ///
            timefmt(`timefmt') mode(`mode')
        if `has_anc' {
            _xtbalfront_listcurve `CURVE_ANC', label("`anchor_label'") ///
                timefmt(`timefmt') mode(`mode')
        }
    }

    *--------------------------------------------------------------
    * 10. Display: L*N peak info
    *--------------------------------------------------------------
    if "`nolist'" == "" {
        di
        di as text "{hline 70}"
        di as text "Largest balanced sample (L x N peak)"
        di as text "{hline 70}"
        _xtbalfront_peak `CURVE_BEST', label("Best window") timefmt(`timefmt')
        return scalar peak_best_L = r(peak_L)
        return scalar peak_best_N = r(peak_N)
        if `has_anc' {
            _xtbalfront_peak `CURVE_ANC', label("`anchor_label'") timefmt(`timefmt')
            return scalar peak_anc_L = r(peak_L)
            return scalar peak_anc_N = r(peak_N)
        }
        di as text "  Tip: use {bf:years()} or {bf:crosssections()} to extract that subsample."
    }

    *--------------------------------------------------------------
    * 11. Gap detection note
    *--------------------------------------------------------------
    if "`nogapnote'" == "" {
        di
        di as text "{hline 70}"
        di as text "Internal-gap diagnostic"
        di as text "{hline 70}"
        local active = `totalN' - `nodata_count'
        di as result "  Cross-sections with at least one valid observation: " %6.0f `active' " of " %4.0f `totalN'
        di as result "  Cross-sections with internal gaps in tenure:        " %6.0f `gap_count'
        if `gap_count' > 0 {
            di as result "  Total interior missing periods:                     " %6.0f `gap_severity'
            di as text   "{p 2 4 2}Note: " ///
                "`gap_count' cross-sections have one or more interior missing periods " ///
                "(`gap_severity' values in total). Interpolating these (e.g. with " ///
                "{bf:xtmispanel}, {bf:mipolate}, or linear interpolation via " ///
                "{bf:ipolate}) may enlarge the achievable balanced panel. " ///
                "This is a suggestion only - the analysis below proceeds on the data " ///
                "as supplied.{p_end}"
        }
        return scalar gap_count    = `gap_count'
        return scalar gap_severity = `gap_severity'
    }

    *--------------------------------------------------------------
    * 12. Plot: trade-off curves (one plot per curve)
    *--------------------------------------------------------------
    if "`nograph'" == "" {
        if "`mode'" == "any" {
            _xtbalfront_curveplot, curve(`CURVE_BEST') kind(any) ///
                lcolor(`lcolor') mcolor(`mcolor')
        }
        else {
            _xtbalfront_curveplot, curve(`CURVE_BEST') kind(best) ///
                lcolor(`lcolor') mcolor(`mcolor')

            if `has_anc' {
                if `user_specified_anchor' {
                    local kind_label "anchored"
                }
                else {
                    local kind_label "recent"
                }
                _xtbalfront_curveplot, curve(`CURVE_ANC') kind(`kind_label') ///
                    anchorlbl(`"`anchor_label'"') ///
                    lcolor(cranberry) mcolor(cranberry)
            }
        }

        if "`noheatmap'" == "" & "`mode'" == "window" {
            _xtbalfront_heatmap, id(`id') time(`time') valid(`valid') touse(`touse') ///
                maxshow(`maxshow')
        }

        if "`nohist'" == "" {
            _xtbalfront_validhist, id(`id') valid(`valid') touse(`touse')
        }
    }

    *--------------------------------------------------------------
    * 13. Filter results: comparison table + selected list
    *--------------------------------------------------------------
    if `has_filter' {
        di
        di as text "{hline 70}"
        di as text "Selected balanced panel`filter_label'"
        di as text "{hline 70}"
        di as result "  Balanced years     = `selL'"
        di as result "  Cross-sections     = `selN'"
        if "`mode'" == "window" {
            di as result "  Window start       = " %9.0g `selS'
            di as result "  Window end         = " %9.0g `selE'
        }
        di as result "  Total observations = " %9.0g `selL' * `selN'

        if "`nocompare'" == "" {
            _xtbalfront_compare, varlist(`varlist') touse(`touse') selected(`selected')
        }

        if "`nohistcompare'" == "" & "`nograph'" == "" {
            _xtbalfront_histcompare, varlist(`varlist') touse(`touse') selected(`selected')
        }

        if "`nosellist'" == "" {
            _xtbalfront_listsel, id(`id') selected(`selected') maxlist(`maxlist')
        }

        *--- Apply gen()/keep unless dryrun ------------------------
        if "`dryrun'" != "" {
            di
            di as text "{p}{bf:dryrun} specified - no changes have been made " ///
                "to the data. Re-run without {bf:dryrun} to apply the " ///
                "{bf:gen()}/{bf:keep} actions.{p_end}"
        }
        else {
            if "`generate'" != "" {
                qui gen byte `generate' = `selected'
                label variable `generate' "Selected balanced subsample (L=`selL', N=`selN')"
                di as text "Indicator variable {bf:`generate'} now marks the selected sample."
            }
            if "`keep'" != "" {
                qui keep if `selected' == 1
                di as text "Data have been restricted to the selected balanced sample."
            }
        }

        return scalar selected_years = `selL'
        return scalar selected_cross = `selN'
        if "`mode'" == "window" {
            return scalar selected_start = `selS'
            return scalar selected_end   = `selE'
        }
        return scalar selected_obs   = `selL' * `selN'
    }

    *--------------------------------------------------------------
    * 14. Returns
    *--------------------------------------------------------------
    return matrix curve = `CURVE_BEST'
    if `has_anc' return matrix curve_anchored = `CURVE_ANC'
    return scalar total_cross  = `totalN'
    return scalar nodata_cross = `nodata_count'
    return scalar max_years    = `maxL'
    return local  mode         = "`mode'"
    if "`anchor_label'" != "" return local anchor = "`anchor_label'"
end


*======================================================================
* Helper: list a single trade-off curve as a table
*======================================================================
capture program drop _xtbalfront_listcurve
program define _xtbalfront_listcurve
    syntax anything(name=mat) , LABel(string) TIMEfmt(string) MODE(string)

    preserve
        drop _all
        qui svmat double `mat', names(col)
        qui gen long balanced_obs = valid_years * max_cross
        label var valid_years   "Balanced years"
        label var max_cross     "Max cross-sections"
        label var start_period  "Window start"
        label var end_period    "Window end"
        label var balanced_obs  "L x N"
        if "`timefmt'" != "" {
            capture format start_period end_period `timefmt'
        }

        di
        di as text "{hline 70}"
        di as text "Trade-off curve: `label'"
        di as text "{hline 70}"
        if "`mode'" == "window" {
            list valid_years max_cross start_period end_period balanced_obs, ///
                noobs sep(0) abbrev(15)
        }
        else {
            list valid_years max_cross balanced_obs, noobs sep(0) abbrev(15)
        }
    restore
end


*======================================================================
* Helper: identify and print the L*N peak of a single curve
*======================================================================
capture program drop _xtbalfront_peak
program define _xtbalfront_peak, rclass
    syntax anything(name=mat) , LABel(string) TIMEfmt(string)

    preserve
        drop _all
        qui svmat double `mat', names(col)
        qui gen long lxn = valid_years * max_cross
        qui summarize lxn, meanonly
        local maxLN = r(max)
        qui keep if lxn == `maxLN'
        qui keep in 1
        local L = valid_years[1]
        local N = max_cross[1]

        if missing(start_period[1]) {
            di as result "  `label': L = " %3.0f `L' "   N = " %5.0f `N' ///
                "   L x N = " %7.0f `maxLN'
        }
        else {
            local s = start_period[1]
            local e = end_period[1]
            local sf : display %9.0g `s'
            local ef : display %9.0g `e'
            local sf = strtrim("`sf'")
            local ef = strtrim("`ef'")
            di as result "  `label': L = " %3.0f `L' "   N = " %5.0f `N' ///
                "   L x N = " %7.0f `maxLN' "   window = `sf' to `ef'"
        }

        return scalar peak_L = `L'
        return scalar peak_N = `N'
    restore
end


*======================================================================
* Helper: trade-off plot for a single curve (called once per curve)
*======================================================================
capture program drop _xtbalfront_curveplot
program define _xtbalfront_curveplot
    syntax , CURVE(name) KIND(string) [ ANCHORlbl(string) ///
        LColor(string) MColor(string) ]

    local anchor_label "`anchorlbl'"

    if "`lcolor'" == "" local lcolor "navy"
    if "`mcolor'" == "" local mcolor "navy"

    preserve
        drop _all
        qui svmat double `curve', names(col)
        qui keep if max_cross > 0 & !missing(max_cross)
        qui count
        if r(N) == 0 {
            di as text "(no positive trade-off rows for `kind' curve; nothing to plot)"
            exit
        }

        qui gen long lxn = valid_years * max_cross
        qui summarize lxn, meanonly
        local maxLN = r(max)
        qui gen byte peak = (lxn == `maxLN')

        if "`kind'" == "best" {
            local cap1 "x-axis: balanced window length L"
            local cap2 "y-axis: maximum cross-sections that can form a balanced panel of L consecutive years"
            local cap3 "Window may sit anywhere in time. Moving right = longer span = fewer eligible cross-sections."
            local legend_main "Best-window frontier"
        }
        else if "`kind'" == "anchored" {
            local cap1 "x-axis: balanced window length L"
            local cap2 "y-axis: cross-sections that survive when the window is held to the requested anchor"
            local cap3 "Moving right extends the window from the anchor: how many cross-sections survive at length L?"
            local legend_main "`anchor_label'"
        }
        else if "`kind'" == "recent" {
            local cap1 "x-axis: balanced window length L"
            local cap2 "y-axis: cross-sections with valid data in the L most recent periods"
            local cap3 "Moving right extends the window further back from the latest period."
            local legend_main "Recency-anchored"
        }
        else {  // any
            local cap1 "x-axis: number of valid years per cross-section"
            local cap2 "y-axis: cross-sections with at least L valid years anywhere in time"
            local cap3 "This is a per-firm survival curve, not a consecutive-window curve."
            local legend_main "Survival curve"
        }

        twoway                                                                       ///
            (line max_cross valid_years, sort lwidth(medthick) lcolor(`lcolor'))     ///
            (scatter max_cross valid_years, mcolor(`mcolor') msize(small))           ///
            (scatter max_cross valid_years if peak,                                  ///
                mcolor(cranberry) msize(medlarge) msymbol(D)),                       ///
            xtitle("Count of years (L)")                                             ///
            ytitle("Count of cross-sections")                                        ///
            legend(order(2 "`legend_main'" 3 "L x N peak") rows(1)                   ///
                   region(lstyle(none)))                                             ///
            caption(`"`cap1'"' `"`cap2'"' `"`cap3'"', size(small) span)              ///
            graphregion(color(white)) plotregion(color(white))                       ///
            name(xtbalfront_`kind', replace)
    restore
end


*======================================================================
* Helper: heatmap of presence/absence
*======================================================================
capture program drop _xtbalfront_heatmap
program define _xtbalfront_heatmap
    syntax , ID(varname) TIME(varname) VALID(varname) TOUSE(varname) ///
        MAXShow(integer)

    qui levelsof `id' if `touse', local(_idvals)
    local nids : word count `_idvals'

    if `nids' > `maxshow' {
        di
        di as text "{p}note: heatmap suppressed because the panel has " ///
            "`nids' cross-sections (> maxshow(`maxshow')). Use " ///
            "{bf:maxshow(N)} to allow more, or rely on the histogram " ///
            "of valid-year counts.{p_end}"
        exit
    }

    preserve
        qui keep if `touse'
        qui keep `id' `time' `valid'
        qui fillin `id' `time'
        qui replace `valid' = 0 if missing(`valid')
        qui egen long _id_idx = group(`id')

        twoway                                                                       ///
            (scatter _id_idx `time' if `valid' == 1,                                 ///
                msymbol(square) mcolor(navy) msize(*0.4))                            ///
            (scatter _id_idx `time' if `valid' == 0,                                 ///
                msymbol(square_hollow) mcolor(red%30) msize(*0.4)),                  ///
            xtitle("`time'") ytitle("Cross-section index")                           ///
            title("Data presence / absence by cross-section and period")             ///
            legend(order(1 "valid" 2 "missing") rows(1) region(lstyle(none)))        ///
            caption("Each square represents one cross-section x period cell.",       ///
                size(small))                                                         ///
            graphregion(color(white)) plotregion(color(white))                       ///
            name(xtbalfront_heatmap, replace)
    restore
end


*======================================================================
* Helper: histogram of valid-years count per cross-section
*======================================================================
capture program drop _xtbalfront_validhist
program define _xtbalfront_validhist
    syntax , ID(varname) VALID(varname) TOUSE(varname)

    preserve
        qui keep if `touse'
        qui collapse (sum) _vyears = `valid', by(`id')

        twoway (histogram _vyears, discrete frequency fcolor(navy%70) lcolor(navy)), ///
            xtitle("Number of valid years per cross-section")                         ///
            ytitle("Count of cross-sections")                                         ///
            title("Distribution of data availability across cross-sections")          ///
            caption("This is the per-firm survival distribution: it shows how many " ///
                "cross-sections have k valid years anywhere, for each k.",            ///
                size(small) span)                                                     ///
            graphregion(color(white)) plotregion(color(white))
    restore
end


*======================================================================
* Helper: comparison table (full sample vs proposed subset) with t-tests
*======================================================================
capture program drop _xtbalfront_compare
program define _xtbalfront_compare
    syntax , VARLIST(varlist) TOUSE(varname) SELECTED(varname)

    di
    di as text "{hline 79}"
    di as text "Distributional comparison: full sample vs selected subsample"
    di as text "{hline 79}"
    di as text %15s "variable" "  " %10s "N (full)" "  " %10s "mean (full)" "  " ///
        %10s "sd (full)" "  " %9s "mean (sub)" "  " %8s "sd (sub)" "  " %7s "t (diff)" "  " %6s "p"
    di as text "{hline 79}"

    foreach v of local varlist {
        qui summarize `v' if `touse', detail
        local n_full = r(N)
        local m_full = r(mean)
        local s_full = r(sd)

        qui summarize `v' if `touse' & `selected' == 1, detail
        local n_sub = r(N)
        local m_sub = r(mean)
        local s_sub = r(sd)

        capture qui ttest `v' if `touse', by(`selected') unequal
        if _rc == 0 {
            local tstat = r(t)
            local pval  = r(p)
            di as result %15s "`v'" "  " %10.0f `n_full' "  " %10.4f `m_full' "  " ///
                %10.4f `s_full' "  " %9.4f `m_sub' "  " %8.4f `s_sub' "  " ///
                %7.2f `tstat' "  " %6.3f `pval'
        }
        else {
            di as result %15s "`v'" "  " %10.0f `n_full' "  " %10.4f `m_full' "  " ///
                %10.4f `s_full' "  " %9.4f `m_sub' "  " %8.4f `s_sub' "  " ///
                %7s "n/a" "  " %6s "n/a"
        }
    }
    di as text "{hline 79}"
    di as text "{p 0 2 0}t and p test the difference in means between the selected " ///
        "subsample and its complement (cross-sections that would be dropped). " ///
        "A small p-value warns that the subsetting is removing systematic " ///
        "variation, not just observations.{p_end}"
end


*======================================================================
* Helper: list selected cross-sections (with value labels if present)
*======================================================================
capture program drop _xtbalfront_listsel
program define _xtbalfront_listsel
    syntax , ID(varname) SELECTED(varname) MAXList(integer)

    qui levelsof `id' if `selected' == 1, local(selids)
    local nsel : word count `selids'

    di
    di as text "{hline 70}"
    di as text "Selected cross-sections  (`nsel' total)"
    di as text "{hline 70}"

    local labname : value label `id'
    local i = 0
    foreach v of local selids {
        local ++i
        if `i' > `maxlist' {
            di as text "  ... and " (`nsel' - `maxlist') " more (suppressed; raise maxlist() to show)"
            continue, break
        }
        if "`labname'" != "" {
            local lab : label `labname' `v'
            di as result "  " %6.0f `v' "  " "`lab'"
        }
        else {
            di as result "  " %6.0f `v'
        }
    }
end


*======================================================================
* Helper: pre/post overlaid histograms (one per variable in varlist)
*======================================================================
capture program drop _xtbalfront_histcompare
program define _xtbalfront_histcompare
    syntax , VARLIST(varlist) TOUSE(varname) SELECTED(varname)

    foreach v of local varlist {
        qui summarize `v' if `touse', meanonly
        local m_pre = r(mean)
        local n_pre = r(N)

        qui summarize `v' if `touse' & `selected' == 1, meanonly
        local m_post = r(mean)
        local n_post = r(N)

        if `n_pre' == 0 | `n_post' == 0 {
            di as text "  (skipping histogram for `v': empty pre or post sample)"
            continue
        }

        if abs(`m_pre') > 1e-12 {
            local pct = (`m_post' - `m_pre') / `m_pre' * 100
            local pct_str  : display %6.2f `pct'
            local pre_str  : display %9.4g `m_pre'
            local post_str : display %9.4g `m_post'
            local note_str "Mean change: `=strtrim("`pct_str'")'%   (full = `=strtrim("`pre_str'")'   selected = `=strtrim("`post_str'")')"
        }
        else {
            local pre_str  : display %9.4g `m_pre'
            local post_str : display %9.4g `m_post'
            local note_str "Full mean = `=strtrim("`pre_str'")'   Selected mean = `=strtrim("`post_str'")'"
        }

        local v_short = substr("`v'", 1, 24)

        capture noisily twoway                                                       ///
            (histogram `v' if `touse', color(navy%40) lcolor(navy))                  ///
            (histogram `v' if `touse' & `selected' == 1,                             ///
                color(cranberry%40) lcolor(cranberry)),                              ///
            xtitle("`v'") ytitle("Density")                                          ///
            legend(order(1 "Full sample" 2 "Selected subsample") rows(1)             ///
                   region(lstyle(none)))                                             ///
            note(`"`note_str'"', size(small) span)                                   ///
            graphregion(color(white)) plotregion(color(white))                       ///
            name(xtbf_h_`v_short', replace)
        if _rc {
            di as text "  (could not draw histogram for `v')"
        }
    }
end


*======================================================================
*                              MATA BLOCK
*======================================================================
version 16.0

mata:

void xtbf_compute(string scalar idvar,    string scalar timevar,                ///
                  string scalar validvar, string scalar tousevar,               ///
                  string scalar mode,                                           ///
                  string scalar endperiod_str, string scalar startperiod_str,   ///
                  string scalar curvename)
{
    real colvector ids, times, valids, uids, utimes, rowsumV
    real matrix    V, Spre, curve
    real scalar    ni, nt, k, L, s, e, c, bestN, bestS, bestE, n, ir, ic, maxv
    real scalar    end_anchor, start_anchor, Lmin, Lmax, row_idx
    real scalar    end_val, start_val
    real scalar    gap_count, nodata_count, gap_severity, fv, lv, vc, span, i

    st_view(ids,    ., idvar,    tousevar)
    st_view(times,  ., timevar,  tousevar)
    st_view(valids, ., validvar, tousevar)

    uids   = uniqrows(ids)
    utimes = uniqrows(times)
    ni = rows(uids)
    nt = rows(utimes)

    V = J(ni, nt, 0)
    n = rows(ids)
    for (k = 1; k <= n; k++) {
        ir = xtbf_bsearch(uids,   ids[k])
        ic = xtbf_bsearch(utimes, times[k])
        if (ir > 0 & ic > 0) V[ir, ic] = valids[k]
    }

    // ----- Gap diagnostic -----
    gap_count    = 0
    nodata_count = 0
    gap_severity = 0
    for (i = 1; i <= ni; i++) {
        fv = 0
        lv = 0
        for (k = 1; k <= nt; k++) {
            if (V[i, k] == 1) {
                if (fv == 0) fv = k
                lv = k
            }
        }
        if (fv == 0) {
            nodata_count++
        }
        else {
            vc = sum(V[i, .])
            span = lv - fv + 1
            if (vc < span) {
                gap_count++
                gap_severity = gap_severity + (span - vc)
            }
        }
    }

    // ----- Anchor parsing -----
    end_anchor   = 0
    start_anchor = 0
    if (endperiod_str != "" & endperiod_str != ".") {
        end_val = strtoreal(endperiod_str)
        end_anchor = xtbf_bsearch(utimes, end_val)
    }
    if (startperiod_str != "" & startperiod_str != ".") {
        start_val = strtoreal(startperiod_str)
        start_anchor = xtbf_bsearch(utimes, start_val)
    }

    // ----- Curve construction -----
    if (mode == "any") {
        rowsumV = rowsum(V)
        maxv    = colmax(rowsumV)
        if (maxv < 1) maxv = 1
        curve = J(maxv, 4, 0)
        for (L = 1; L <= maxv; L++) {
            curve[L, 1] = L
            curve[L, 2] = colsum(rowsumV :>= L)
            curve[L, 3] = .
            curve[L, 4] = .
        }
    }
    else {
        Spre = J(ni, nt+1, 0)
        for (k = 1; k <= nt; k++) {
            Spre[., k+1] = Spre[., k] + V[., k]
        }

        Lmin = 1
        Lmax = nt
        if (end_anchor > 0 & start_anchor > 0) {
            Lmin = end_anchor - start_anchor + 1
            Lmax = Lmin
        }
        else if (end_anchor > 0) {
            Lmax = end_anchor
        }
        else if (start_anchor > 0) {
            Lmax = nt - start_anchor + 1
        }

        curve = J(Lmax - Lmin + 1, 4, 0)
        row_idx = 0
        for (L = Lmin; L <= Lmax; L++) {
            row_idx++
            bestN = -1
            bestS = .
            bestE = .

            if (end_anchor > 0) {
                s = end_anchor - L + 1
                e = end_anchor
                if (s >= 1) {
                    c = colsum((Spre[., e+1] - Spre[., s]) :== L)
                    bestN = c
                    bestS = s
                    bestE = e
                }
            }
            else if (start_anchor > 0) {
                s = start_anchor
                e = start_anchor + L - 1
                if (e <= nt) {
                    c = colsum((Spre[., e+1] - Spre[., s]) :== L)
                    bestN = c
                    bestS = s
                    bestE = e
                }
            }
            else {
                for (s = 1; s <= nt - L + 1; s++) {
                    e = s + L - 1
                    c = colsum((Spre[., e+1] - Spre[., s]) :== L)
                    if (c > bestN) {
                        bestN = c
                        bestS = s
                        bestE = e
                    }
                }
            }

            curve[row_idx, 1] = L
            curve[row_idx, 2] = (bestN >= 0 ? bestN : 0)
            curve[row_idx, 3] = (bestN > 0 ? utimes[bestS] : .)
            curve[row_idx, 4] = (bestN > 0 ? utimes[bestE] : .)
        }
    }

    st_matrix(curvename, curve)
    st_matrixcolstripe(curvename,
        (J(4, 1, "") ,
         ("valid_years" \ "max_cross" \ "start_period" \ "end_period")))

    st_numscalar("r(nrows)",        rows(curve))
    st_numscalar("r(totalN)",       ni)
    st_numscalar("r(maxL)",         nt)
    st_numscalar("r(gap_count)",    gap_count)
    st_numscalar("r(nodata_count)", nodata_count)
    st_numscalar("r(gap_severity)", gap_severity)
}

real scalar xtbf_bsearch(real colvector v, real scalar x)
{
    real scalar lo, hi, mid
    lo = 1
    hi = rows(v)
    while (lo <= hi) {
        mid = floor((lo + hi) / 2)
        if (v[mid] == x) return(mid)
        if (v[mid] <  x) lo = mid + 1
        else             hi = mid - 1
    }
    return(0)
}

end
