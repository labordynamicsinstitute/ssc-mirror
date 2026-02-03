*! version 2.2.1  Jonathan Dries  01Feb2026
program define rddidplot
    version 14.0

    syntax [, Title(string) CIlevel(integer 95) *]

    if "`e(cmd)'" != "rddid" {
        di as err "rddidplot is a postestimation command; run rddid first"
        exit 301
    }

    local depvar   "`e(depvar)'"
    local runvar   "`e(runvar)'"
    local group    "`e(group)'"
    local cutoff   = e(cutoff)
    local h_t_l    = e(h_t_l)
    local h_t_r    = e(h_t_r)
    local h_c_l    = e(h_c_l)
    local h_c_r    = e(h_c_r)

    if "`title'" == "" local title "Difference-in-Discontinuities"

    * CI options
    local ci_opt ""
    if `cilevel' > 0 {
        local ci_opt "ci(`cilevel') shade"
    }

    * Build legend note
    local legend_note `""{bf:o}" "Sample average within bin"  "{bf:{hline 3}}" "Polynomial fit""'
    if `cilevel' > 0 {
        local legend_note `"`legend_note'  "{bf:///}" "`cilevel'% confidence interval""'
    }

    * Treated plot
    quietly rdplot `depvar' `runvar' if `group'==1 & e(sample), ///
        c(`cutoff') h(`h_t_l' `h_t_r') `ci_opt' ///
        graph_options(title("Treated") legend(off) name(__rddid_t, replace))

    * Control plot
    quietly rdplot `depvar' `runvar' if `group'==0 & e(sample), ///
        c(`cutoff') h(`h_c_l' `h_c_r') `ci_opt' ///
        graph_options(title("Control") legend(off) name(__rddid_c, replace))

    * Combine side by side with unified legend as note
    graph combine __rddid_t __rddid_c, ///
        title("`title'") rows(1) ///
        note(`legend_note', size(small)) ///
        `options'

    graph drop __rddid_t __rddid_c
end
