*! dpath_entropy: Shannon decision path entropy
*! Version 1.0.1  Subir Hait, Michigan State University (2026)

program define dpath_entropy, rclass
    version 14.0

    syntax , id(varname) time(varname) [BY(varname) MUTUALinfo]

    *--------------------------------------------------*
    * Check prerequisites
    *--------------------------------------------------*
    capture confirm variable _dp_path_str
    if _rc {
        di as error "_dp_path_str not found. Run {cmd:dpath build} first."
        exit 111
    }

    *--------------------------------------------------*
    * Detect whether by() is string or numeric
    *--------------------------------------------------*
    local by_is_string = 0
    if "`by'" != "" {
        capture confirm string variable `by'
        if !_rc local by_is_string = 1
    }

    *--------------------------------------------------*
    * Create unit-level file and compute overall entropy
    *--------------------------------------------------*
    preserve
    quietly bysort `id' (`time'): keep if _n == _N

    quietly count
    local n_units = r(N)

    quietly {
        tempvar path_n prop logp ent_contrib
        bysort _dp_path_str: gen long `path_n' = _N
        bysort _dp_path_str: keep if _n == 1
        count
        local n_unique = r(N)

        gen double `prop' = `path_n' / `n_units'
        gen double `logp' = ln(`prop') / ln(2)
        gen double `ent_contrib' = -`prop' * `logp'
        summarize `ent_contrib', meanonly
        local H = r(sum)
    }

    * Normalized entropy by observed unique paths
    if `n_unique' > 1 {
        local H_norm = `H' / (ln(`n_unique') / ln(2))
    }
    else {
        local H_norm = 0
    }

    gsort -`path_n'

    di as text  _newline "{hline 58}"
    di as result "  dpath entropy — Shannon Decision Path Entropy"
    di as text  "{hline 58}"
    di as text  "  Units               : " as result `n_units'
    di as text  "  Unique paths        : " as result `n_unique'
    di as text  "  Shannon entropy H   : " as result %7.3f `H' " bits"
    di as text  "  Normalized entropy  : " as result %7.3f `H_norm'
    di as text  "{hline 58}"
    di as text  "  Top 10 most frequent paths:"
    di as text  "  {hline 50}"
    di as text  "  Path              Count   Proportion"
    di as text  "  {hline 50}"

    local nshow = min(`n_unique', 10)
    forvalues i = 1/`nshow' {
        local pstr  = _dp_path_str[`i']
        local pn    = `path_n'[`i']
        local pprop = `prop'[`i']
        di as text  "  " %-16s "`pstr'" "  " as result %5.0f `pn' ///
            "   " %9.4f `pprop'
    }
    di as text  "  {hline 50}"

    restore

    *--------------------------------------------------*
    * By-group entropy and mutual information
    *--------------------------------------------------*
    local mi = .

    if "`by'" != "" {

        capture confirm variable `by'
        if _rc {
            di as error "Group variable `by' not found."
            exit 111
        }

        preserve
        quietly bysort `id' (`time'): keep if _n == _N

        tempvar unit_tag
        gen byte `unit_tag' = 1

        tempfile unitdata
        quietly save `unitdata', replace

        quietly levelsof `by', local(grplevels)

        di as text  _newline "  Entropy by group (`by'):"
        di as text  "  {hline 52}"
        di as text  "  Group         N   Unique Paths   H (bits)"
        di as text  "  {hline 52}"

        local H_cond = 0

        foreach g of local grplevels {

            quietly use `unitdata', clear

            if `by_is_string' {
                quietly keep if `by' == "`g'"
            }
            else {
                quietly keep if `by' == `g'
            }

            quietly count
            local ng = r(N)

            quietly {
                tempvar pn_g pp_g he_g
                bysort _dp_path_str: gen long `pn_g' = _N
                bysort _dp_path_str: keep if _n == 1
                count
                local n_uniq_g = r(N)

                gen double `pp_g' = `pn_g' / `ng'
                gen double `he_g' = -`pp_g' * (ln(`pp_g') / ln(2))
                summarize `he_g', meanonly
                local H_g = r(sum)
            }

            di as text  "  " %-12s "`g'" "  " as result %5.0f `ng' ///
                "   " %11.0f `n_uniq_g' "   " %8.3f `H_g'

            local pg = `ng' / `n_units'
            local H_cond = `H_cond' + `pg' * `H_g'
        }

        di as text  "  {hline 52}"

        if "`mutualinfo'" != "" {
            local mi = `H' - `H_cond'
            if `mi' < 0 & abs(`mi') < 1e-10 {
                local mi = 0
            }

            local mi_frac = .
            if `H' > 0 {
                local mi_frac = `mi' / `H'
            }

            di as text  "  Mutual information I(path; group): " ///
                as result %7.3f `mi' " bits"
            di as text  "  Group-attributable entropy fraction: " ///
                as result %7.4f `mi_frac'
        }

        restore
    }

    *--------------------------------------------------*
    * Return results
    *--------------------------------------------------*
    return scalar entropy            = `H'
    return scalar normalized_entropy = `H_norm'
    return scalar n_unique_paths     = `n_unique'
    return scalar n_units            = `n_units'
    if "`mutualinfo'" != "" & `mi' != . {
        return scalar mutual_info = `mi'
    }
end
