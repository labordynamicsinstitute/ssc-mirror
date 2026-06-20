/*
    _littext_export -- write the candidate relationships (lt_relations) as a
    hypothesis register for hand-curation.

    Reads the lt_relations frame left in memory by -littext analyze-, applies
    optional confidence / relation-type / top-N filters, sorts by descending
    confidence so the strongest candidates are reviewed first, and writes a
    clean candidate table to CSV and/or XLSX. No curation columns are added;
    the analyst adds their own.

    Part of the littext package. GPL-3.0-or-later; see LICENSE.
*/

*! version 1.0  17june2026

program define _littext_export, rclass
    version 19.0
    syntax , OUTdir(string) [ Name(string) FORMat(string) MINConf(real -1) Type(string) TOP(integer -1) COLumns(string) Replace ]

    /* outdir() is required and should be absolute, matching littext graph. */
    if `"`outdir'"' == "" {
        di as err "littext export: outdir() is required."
        di as txt `"        Pass an absolute path, e.g. outdir("D:/myproject/register")."'
        exit 198
    }
    local first2 = substr(`"`outdir'"', 2, 1)
    local first1 = substr(`"`outdir'"', 1, 1)
    local is_abs = (`"`first2'"' == ":") | (`"`first1'"' == "/")
    if !`is_abs' {
        di as txt `"littext: WARNING -- outdir() looks relative; resolving against the current working directory ("`c(pwd)'")."'
        local outdir `"`c(pwd)'/`outdir'"'
    }
    capture mkdir `"`outdir'"'

    /* Resolve format(): csv (default), xlsx, or both. */
    if `"`format'"' == "" local format "csv"
    local format = lower(trim(`"`format'"'))
    if !inlist("`format'", "csv", "xlsx", "both") {
        di as err `"littext export: format() must be csv, xlsx, or both (got "`format'")."'
        exit 198
    }

    if `"`name'"' == "" local name "littext_register"

    /* Default column set: essentials + provenance. Overridable via columns(). */
    if `"`columns'"' == "" {
        local columns "source target relation_type confidence evidence_text extraction_method doc_id"
    }

    /* The relations must be in memory. Work on a copy of the lt_relations
       frame so we never disturb the user's data or the cached frame. */
    capture frame lt_relations: describe
    if _rc {
        di as err "littext export: no lt_relations frame found."
        di as txt "        Run -littext analyze- before exporting."
        exit 198
    }

    tempname wf
    frame copy lt_relations `wf'
    frame `wf' {
        /* Verify requested columns exist; drop unknowns with a warning. */
        local keep ""
        foreach v of local columns {
            capture confirm variable `v'
            if _rc {
                di as txt "littext export: NOTE -- column '`v'' not in lt_relations; skipped."
            }
            else {
                local keep "`keep' `v'"
            }
        }
        if "`keep'" == "" {
            di as err "littext export: no valid columns to export."
            exit 198
        }

        /* Filters. */
        if `minconf' >= 0 {
            capture confirm variable confidence
            if !_rc qui keep if confidence >= `minconf'
        }
        if `"`type'"' != "" {
            capture confirm variable relation_type
            if !_rc {
                local tlist : subinstr local type "," " ", all
                gen byte _keep_t = 0
                foreach t of local tlist {
                    qui replace _keep_t = 1 if relation_type == "`t'"
                }
                qui keep if _keep_t == 1
                drop _keep_t
            }
        }

        /* Sort strongest-first, then cap to top() if requested. */
        capture confirm variable confidence
        if !_rc gsort -confidence
        if `top' > 0 {
            qui keep if _n <= `top'
        }

        local nrows = _N
        if `nrows' == 0 {
            di as err "littext export: no rows survive the filters; nothing written."
            exit 198
        }

        keep `keep'
        order `keep'

        /* Write the requested format(s). */
        local stub `"`outdir'/`name'"'
        if inlist("`format'", "csv", "both") {
            export delimited using `"`stub'.csv"', replace quote
            di as txt `"littext export: wrote "`stub'.csv" (`nrows' candidates)."'
        }
        if inlist("`format'", "xlsx", "both") {
            export excel using `"`stub'.xlsx"', firstrow(variables) replace
            di as txt `"littext export: wrote "`stub'.xlsx" (`nrows' candidates)."'
        }
    }

    return scalar n_exported = `nrows'
    return local register_stub `"`outdir'/`name'"'
end
