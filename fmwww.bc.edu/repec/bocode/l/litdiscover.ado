*! litdiscover 1.0  17may2026
*! LDA topic modelling with deductive construct extraction for systematic
*! literature reviews.
*!
*! Author:     Nebojsa S. Davcik, EM Normandie Business School, Oxford, UK.
*!             ORCID 0000-0003-1041-8788. Email: davcik@live.com.
*! Repository: https://github.com/Davcik/litdiscover
*! Licence:    GPL-3.0-or-later. See LICENSE in the repository root.
*! Copyright (C) 2026 Nebojsa S. Davcik.
*!
*! This program is free software: you can redistribute it and/or modify it
*! under the GNU General Public License version 3 or later. Distributed
*! WITHOUT ANY WARRANTY; see <https://www.gnu.org/licenses/> for details.
*!
*! Citation:
*!   Davcik, N. S. 2026. litdiscover: A Stata package for theory-aware
*!     literature review and discovery. https://github.com/Davcik/litdiscover
*!
*! Version history and architectural notes: see CHANGELOG.md in the
*! repository root and the help file (help litdiscover).

capture program drop litdiscover

program define litdiscover, rclass
    version 19

    syntax , ABSTRACT(varname) [ ID(varname) YEAR(varname) THEORY(varname) DV(varname) IV(varname) MOD(varname) MED(varname) DECISION(varname) JOURNAL(varname) CONTEXT(varname) METHOD(varname) TCCMclass(string) TCCMminfreq(integer 1) SEP(string) TOPICS(integer 5) SEEDS(integer 1) COHERENCE SEED(integer 12345) MINFREQ(integer 1) MAXDF(real 1.0) NGRAM(integer 1) SCRIPT(string) EXPORT(string) KEEPTEMP OUTDIR(string) FIGURES INTERACTIVE SANKEYTOPFREQ(integer 15) VIZSCRIPT(string) NETMEASURES FREX NETSCRIPT(string) NOAUTOload ]

    /* -----------------------------------------------------------------
       Defaults and option validation
       -----------------------------------------------------------------
    */

    /* Mutual exclusion of outdir() and export() */
    if `"`outdir'"' != "" & `"`export'"' != "" {
        di as err "specify outdir() or export(), not both"
        exit 198
    }

    if `"`sep'"' == "" local sep ";"

    if `topics' < 2 {
        di as err "topics() must be at least 2"
        exit 198
    }
    if `seeds' < 1 {
        di as err "seeds() must be at least 1"
        exit 198
    }
    if `minfreq' < 1 {
        di as err "minfreq() must be at least 1"
        exit 198
    }
    if `maxdf' <= 0 | `maxdf' > 1 {
        di as err "maxdf() must be in (0, 1]"
        exit 198
    }
    if `ngram' < 1 | `ngram' > 3 {
        di as err "ngram() must be in [1, 3]"
        exit 198
    }
    if `tccmminfreq' < 1 {
        di as err "tccmminfreq() must be at least 1"
        exit 198
    }
    if `sankeytopfreq' < 1 {
        di as err "sankeytopfreq() must be at least 1"
        exit 198
    }

    /* -----------------------------------------------------------------
       Resolve output directory layout

       If outdir() is set: create ./outdir/{tables,figures,interactive}/
         and route Block A outputs to ./outdir/tables/.
       Otherwise (flat mode, Block A backward-compatible): all outputs
         go to a single flat directory named by export() (default "output").
       -----------------------------------------------------------------
    */
    local _flat = 1
    if `"`outdir'"' != "" {
        local _flat = 0
        local _root      "`outdir'"
        local _tabledir  "`outdir'/tables"
        local _figdir    "`outdir'/figures"
        local _intdir    "`outdir'/interactive"
        capture mkdir "`_root'"
        capture mkdir "`_tabledir'"
        capture mkdir "`_figdir'"
        capture mkdir "`_intdir'"
    }
    else {
        if `"`export'"' == "" local export "output"
        local _root      "`export'"
        local _tabledir  "`export'"
        local _figdir    "`export'"
        local _intdir    "`export'"
        capture mkdir "`_root'"
    }

    /* -----------------------------------------------------------------
       Resolve script paths
       -----------------------------------------------------------------
    */
    if `"`script'"' == "" {
        capture findfile litdiscover.py
        if !_rc {
            local script `"`r(fn)'"'
        }
        else {
            capture confirm file "litdiscover.py"
            if !_rc {
                local script "litdiscover.py"
            }
            else {
                di as err "litdiscover.py not found on adopath or in current directory."
                di as err "Specify location with script(path)."
                exit 601
            }
        }
    }
    else {
        capture confirm file "`script'"
        if _rc {
            di as err "Python script not found: `script'"
            exit 601
        }
    }

    local _need_viz = 0
    if "`figures'" != ""     local _need_viz = 1
    if "`interactive'" != "" local _need_viz = 1

    if `_need_viz' == 1 {
        if `"`vizscript'"' == "" {
            capture findfile litdiscover_viz.py
            if !_rc {
                local vizscript `"`r(fn)'"'
            }
            else {
                capture confirm file "litdiscover_viz.py"
                if !_rc {
                    local vizscript "litdiscover_viz.py"
                }
                else {
                    di as err "litdiscover_viz.py not found on adopath or in current directory."
                    di as err "Specify location with vizscript(path)."
                    exit 601
                }
            }
        }
        else {
            capture confirm file "`vizscript'"
            if _rc {
                di as err "Viz script not found: `vizscript'"
                exit 601
            }
        }
    }

    /* -----------------------------------------------------------------
       Block C: resolve netscript path if netmeasures is set.
       -----------------------------------------------------------------
    */
    if "`netmeasures'" != "" {
        if `"`netscript'"' == "" {
            capture findfile litdiscover_net.py
            if !_rc {
                local netscript `"`r(fn)'"'
            }
            else {
                capture confirm file "litdiscover_net.py"
                if !_rc {
                    local netscript "litdiscover_net.py"
                }
                else {
                    di as err "litdiscover_net.py not found on adopath or in current directory."
                    di as err "Specify location with netscript(path)."
                    exit 601
                }
            }
        }
        else {
            capture confirm file "`netscript'"
            if _rc {
                di as err "Net script not found: `netscript'"
                exit 601
            }
        }
    }

    /* -----------------------------------------------------------------
       Stata-side dependency check for figures: heatplot and palettes
       -----------------------------------------------------------------
    */
    if "`figures'" != "" {
        local _missing_stata ""
        capture which heatplot
        if _rc local _missing_stata "`_missing_stata' heatplot"
        capture which colorpalette
        if _rc local _missing_stata "`_missing_stata' palettes"
        local _missing_stata = strtrim("`_missing_stata'")
        if "`_missing_stata'" != "" {
            di as err "figures requires the following SSC packages: `_missing_stata'"
            di as err "Install with:  ssc install heatplot, replace"
            di as err "               ssc install palettes, replace"
            di as err "               ssc install colrspace, replace"
            exit 199
        }
    }

    /* -----------------------------------------------------------------
       Identify the construct fields actually supplied
       -----------------------------------------------------------------
    */
    local mv_fields theory dv iv mod med decision context method
    local fields_supplied ""
    foreach f of local mv_fields {
        if "``f''" != "" {
            local fields_supplied "`fields_supplied' `f'"
        }
    }
    if "`journal'" != "" {
        local fields_supplied "`fields_supplied' journal"
    }
    local fields_supplied = strtrim("`fields_supplied'")

    /* -----------------------------------------------------------------
       Validate tccmclass
       -----------------------------------------------------------------
    */
    if "`tccmclass'" != "" {
        local _valid_tccm dv iv mod med decision journal
        local _ok = 0
        foreach v of local _valid_tccm {
            if "`tccmclass'" == "`v'" {
                local _ok = 1
            }
        }
        if `_ok' == 0 {
            di as err "tccmclass() must be one of: dv, iv, mod, med, decision, journal"
            exit 198
        }
        if "``tccmclass''" == "" {
            di as err "tccmclass(`tccmclass') requires the `tccmclass'() option to be specified"
            exit 198
        }
    }

    /* Resolve the TCCM characteristic field label (empty if TCCM not triggered) */
    local _tccm_class_label ""
    if "`tccmclass'" != "" {
        local _tccm_class_label "`tccmclass'"
    }
    else if "`dv'" != "" {
        local _tccm_class_label "dv"
    }

    /* -----------------------------------------------------------------
       Decide which framework outputs to emit
       -----------------------------------------------------------------
    */
    local emit_tccm = 0
    if "`theory'" != "" & "`context'" != "" & "`method'" != "" & "`_tccm_class_label'" != "" {
        local emit_tccm = 1
    }

    local emit_ado = 0
    foreach f in iv decision dv {
        if "``f''" != "" {
            local emit_ado = 1
        }
    }

    local emit_constructs = ("`fields_supplied'" != "")
    local emit_year       = ("`year'" != "")

    /* -----------------------------------------------------------------
       Resolve id variable
       -----------------------------------------------------------------
    */
    if "`id'" == "" {
        capture confirm variable study_id
        if !_rc {
            local id "study_id"
        }
        else {
            tempvar id_auto
            qui gen `id_auto' = "study_" + string(_n, "%05.0f")
            local id "`id_auto'"
        }
    }

    capture confirm string variable `id'
    if _rc {
        tempvar id_str
        qui gen `id_str' = string(`id')
        local id "`id_str'"
    }

    marksample touse

    /* -----------------------------------------------------------------
       Tempfiles for Python interchange and state management
       -----------------------------------------------------------------
    */
    tempfile corpuscsv doccsv keywordcsv modelcsv stabcsv stabtopiccsv cohcsv
    tempfile userdata_orig
    local pyldavispath ""
    if "`interactive'" != "" {
        tempfile _pyldavis_tmp
        local pyldavispath "`_pyldavis_tmp'"
    }

    /* Single outer preserve covers the entire body. Any exit (normal or
       error) automatically restores the user's session data. Inside the
       preserve, we use tempfiles for state management; no nested preserve.
    */
    preserve

    qui keep if `touse'
    qui count
    local N_input = r(N)
    if `N_input' == 0 {
        di as err "No observations to process after if/in restrictions."
        exit 2000
    }
    qui save `userdata_orig', replace

    /* -----------------------------------------------------------------
       Step 1: Export corpus CSV for Python
       -----------------------------------------------------------------
    */
    qui use `userdata_orig', clear
    keep `id' `abstract'
    if "`id'" != "study_id" rename `id' study_id
    if "`abstract'" != "abstract" rename `abstract' abstract
    qui export delimited using "`corpuscsv'", replace

    /* -----------------------------------------------------------------
       Step 2: Set local for the Python script and invoke
       -----------------------------------------------------------------
    */
    local docoh = 0
    if "`coherence'" != "" local docoh = 1

    /* Block B (v0.3): tell the engine whether to add the FREX column. */
    local dofrex = 0
    if "`frex'" != "" local dofrex = 1

    /* Initialise FREX feedback locals so r() returns are safe even when
       the engine does not set them.
    */
    local frex_omega      = ""
    local frex_epsilon    = ""
    local frex_topics     = ""
    local frex_vocab_size = ""

    di as txt "litdiscover: invoking Python (`script')..."
    python script "`script'"

    /* -----------------------------------------------------------------
       Step 3: Import engine outputs and save as .dta
       -----------------------------------------------------------------
    */
    qui import delimited using "`doccsv'", clear varnames(1) case(preserve) stringcols(1)
    qui save "`_tabledir'/litdiscover_doctopic.dta", replace
    qui count
    local N_docs = r(N)

    qui import delimited using "`keywordcsv'", clear varnames(1) case(preserve)
    qui save "`_tabledir'/litdiscover_topicterms.dta", replace

    if `seeds' > 1 {
        qui import delimited using "`stabcsv'", clear varnames(1) case(preserve)
        qui save "`_tabledir'/litdiscover_stability.dta", replace
    }

    /* v0.3.1: per-topic stability file. Written only when seeds() >= 2;
       litdiscover.py emits the CSV only in that case. Path local is
       initialised here so the r() return below is safe in either case.
    */
    local _topic_stability_file ""
    if `seeds' > 1 {
        capture confirm file "`stabtopiccsv'"
        if !_rc {
            qui import delimited using "`stabtopiccsv'", clear varnames(1) case(preserve)
            qui save "`_tabledir'/litdiscover_topic_stability.dta", replace
            local _topic_stability_file `"`_tabledir'/litdiscover_topic_stability.dta"'
        }
    }

    if "`coherence'" != "" {
        qui import delimited using "`cohcsv'", clear varnames(1) case(preserve)
        qui save "`_tabledir'/litdiscover_coherence.dta", replace
    }

    /* -----------------------------------------------------------------
       Step 4: Construct extraction and downstream outputs
       -----------------------------------------------------------------
    */
    if `emit_constructs' | `emit_year' {

        qui use `userdata_orig', clear

        local _user_vars `id'
        foreach f of local mv_fields {
            if "``f''" != "" {
                local _user_vars `_user_vars' ``f''
            }
        }
        if "`journal'" != "" local _user_vars `_user_vars' `journal'
        if "`year'"    != "" local _user_vars `_user_vars' `year'

        keep `_user_vars'
        if "`id'" != "study_id" rename `id' study_id

        capture confirm string variable study_id
        if _rc {
            tostring study_id, replace
        }

        tempfile userdata
        qui save `userdata', replace

        /* -------------------------------------------------------------
           Step 4a: Extract each construct field into long format
           (study_id, field, value), stacked into `long_all'.
           -------------------------------------------------------------
        */
        tempfile long_all
        local _have_any_long = 0

        foreach f of local mv_fields {
            if "``f''" == "" continue

            qui use `userdata', clear
            keep study_id ``f''
            qui drop if missing(``f'')
            qui drop if ``f'' == ""
            qui count
            if r(N) == 0 {
                local N_`f' = 0
                continue
            }

            qui split ``f'', parse(`"`sep'"') generate(_tok)
            drop ``f''
            qui reshape long _tok, i(study_id) j(_pos)
            drop _pos
            rename _tok value
            qui replace value = strtrim(value)
            qui drop if missing(value)
            qui drop if value == ""
            qui gen field = "`f'"
            order study_id field value

            tempfile _long_f
            qui save `_long_f', replace

            qui levelsof value, local(_distvals)
            local N_`f' : word count `_distvals'

            if `_have_any_long' == 0 {
                qui save `long_all', replace
                local _have_any_long = 1
            }
            else {
                qui use `long_all', clear
                qui append using `_long_f'
                qui save `long_all', replace
            }
        }

        /* journal (single-valued field, with sep validation) */
        if "`journal'" != "" {
            qui use `userdata', clear
            keep study_id `journal'
            qui drop if missing(`journal')
            qui drop if `journal' == ""

            qui count if strpos(`journal', "`sep'") > 0
            local _bad = r(N)
            if `_bad' > 0 {
                di as err "journal() must be single-valued, but `_bad' observation(s) contain the separator '`sep''."
                di as err "Offending study_ids:"
                list study_id `journal' if strpos(`journal', "`sep'") > 0, noobs sepby(study_id)
                exit 459
            }

            rename `journal' value
            qui replace value = strtrim(value)
            qui drop if value == ""
            qui gen field = "journal"
            order study_id field value

            qui levelsof value, local(_distvals)
            local N_journal : word count `_distvals'

            if `_have_any_long' == 0 {
                qui save `long_all', replace
                local _have_any_long = 1
            }
            else {
                tempfile _long_j
                qui save `_long_j', replace
                qui use `long_all', clear
                qui append using `_long_j'
                qui save `long_all', replace
            }
        }

        /* -------------------------------------------------------------
           Step 4b: construct_freq.dta + marginals tempfile
           -------------------------------------------------------------
        */
        if `_have_any_long' == 1 {
            qui use `long_all', clear
            qui contract field value, freq(n_docs)
            order field value n_docs
            qui save "`_tabledir'/litdiscover_construct_freq.dta", replace

            qui use `long_all', clear
            qui contract field value, freq(n_marginal)
            tempfile margins
            qui save `margins', replace

            /* ---------------------------------------------------------
               Step 4c: cooc_within.dta
               ---------------------------------------------------------
            */
            qui use `long_all', clear
            rename value value_a
            tempfile within_L
            qui save `within_L', replace

            qui use `long_all', clear
            rename value value_b
            tempfile within_R
            qui save `within_R', replace

            qui use `within_L', clear
            qui joinby study_id field using `within_R'
            qui keep if value_a < value_b
            qui count
            if r(N) == 0 {
                clear
                qui set obs 0
                qui gen str1 field = ""
                qui gen str1 value_a = ""
                qui gen str1 value_b = ""
                qui gen long n_both = .
                qui gen long n_a = .
                qui gen long n_b = .
                qui gen double jaccard = .
                qui save "`_tabledir'/litdiscover_cooc_within.dta", replace
            }
            else {
                qui contract field value_a value_b, freq(n_both)

                rename value_a value
                qui merge m:1 field value using `margins', keep(master match) nogen
                rename n_marginal n_a
                rename value value_a

                rename value_b value
                qui merge m:1 field value using `margins', keep(master match) nogen
                rename n_marginal n_b
                rename value value_b

                qui gen double jaccard = n_both / (n_a + n_b - n_both)
                order field value_a value_b n_both n_a n_b jaccard
                qui save "`_tabledir'/litdiscover_cooc_within.dta", replace
            }

            /* ---------------------------------------------------------
               Step 4d: cooc_cross.dta
               ---------------------------------------------------------
            */
            qui use `long_all', clear
            rename value value_a
            rename field field_a
            tempfile cross_L
            qui save `cross_L', replace

            qui use `long_all', clear
            rename value value_b
            rename field field_b
            tempfile cross_R
            qui save `cross_R', replace

            qui use `cross_L', clear
            qui joinby study_id using `cross_R'
            qui keep if field_a < field_b
            qui count
            if r(N) == 0 {
                clear
                qui set obs 0
                qui gen str1 field_a = ""
                qui gen str1 value_a = ""
                qui gen str1 field_b = ""
                qui gen str1 value_b = ""
                qui gen long n_both = .
                qui gen long n_a = .
                qui gen long n_b = .
                qui gen double jaccard = .
                qui save "`_tabledir'/litdiscover_cooc_cross.dta", replace
            }
            else {
                qui contract field_a value_a field_b value_b, freq(n_both)

                rename field_a field
                rename value_a value
                qui merge m:1 field value using `margins', keep(master match) nogen
                rename n_marginal n_a
                rename field field_a
                rename value value_a

                rename field_b field
                rename value_b value
                qui merge m:1 field value using `margins', keep(master match) nogen
                rename n_marginal n_b
                rename field field_b
                rename value value_b

                qui gen double jaccard = n_both / (n_a + n_b - n_both)
                order field_a value_a field_b value_b n_both n_a n_b jaccard
                qui save "`_tabledir'/litdiscover_cooc_cross.dta", replace
            }

            /* ---------------------------------------------------------
               Step 4e: topic_by_field.dta
               ---------------------------------------------------------
            */
            qui use "`_tabledir'/litdiscover_doctopic.dta", clear
            keep study_id topic_*
            qui reshape long topic_, i(study_id) j(topic)
            rename topic_ share
            tempfile doctopic_long
            qui save `doctopic_long', replace

            qui use `long_all', clear
            qui joinby study_id using `doctopic_long'
            qui collapse (mean) mean_share=share (count) n_docs=share, by(field value topic)
            order field value topic mean_share n_docs
            qui save "`_tabledir'/litdiscover_topic_by_field.dta", replace

            /* ---------------------------------------------------------
               Step 4f: TCCM
               ---------------------------------------------------------
            */
            if `emit_tccm' == 1 {
                local _cl `_tccm_class_label'

                qui use `long_all', clear
                qui keep if field == "theory"
                keep study_id value
                rename value theory_v
                tempfile tccm_t
                qui save `tccm_t', replace
                qui count
                local _n_t = r(N)

                qui use `long_all', clear
                qui keep if field == "context"
                keep study_id value
                rename value context_v
                tempfile tccm_c
                qui save `tccm_c', replace
                qui count
                local _n_c = r(N)

                qui use `long_all', clear
                qui keep if field == "method"
                keep study_id value
                rename value method_v
                tempfile tccm_m
                qui save `tccm_m', replace
                qui count
                local _n_m = r(N)

                qui use `long_all', clear
                qui keep if field == "`_cl'"
                keep study_id value
                rename value class_v
                tempfile tccm_cl
                qui save `tccm_cl', replace
                qui count
                local _n_cl = r(N)

                if `_n_t' > 0 & `_n_c' > 0 & `_n_m' > 0 & `_n_cl' > 0 {
                    qui use `tccm_t', clear
                    qui joinby study_id using `tccm_c'
                    qui joinby study_id using `tccm_m'
                    qui joinby study_id using `tccm_cl'
                    qui contract theory_v context_v method_v class_v, freq(n)
                    qui keep if n >= `tccmminfreq'
                    rename theory_v theory
                    rename context_v context
                    rename method_v method
                    rename class_v `_cl'
                    order theory context method `_cl' n
                    qui save "`_tabledir'/litdiscover_tccm.dta", replace
                    qui count
                    local tccm_cells = r(N)
                }
                else {
                    local tccm_cells = 0
                }
            }

            /* ---------------------------------------------------------
               Step 4g: ADO
               ---------------------------------------------------------
            */
            if `emit_ado' == 1 {
                qui use `long_all', clear
                qui keep if inlist(field, "iv", "decision", "dv")
                qui count
                if r(N) > 0 {
                    qui gen ado_class = ""
                    qui replace ado_class = "A" if field == "iv"
                    qui replace ado_class = "D" if field == "decision"
                    qui replace ado_class = "O" if field == "dv"
                    qui gen byte _one = 1
                    qui collapse (count) n_values=_one, by(study_id ado_class)
                    bysort study_id: egen double _total = total(n_values)
                    qui gen double share_within_class = n_values / _total
                    drop _total n_values
                    order study_id ado_class share_within_class
                    qui save "`_tabledir'/litdiscover_ado.dta", replace

                    qui count if ado_class == "A"
                    local ado_a = r(N)
                    qui count if ado_class == "D"
                    local ado_d = r(N)
                    qui count if ado_class == "O"
                    local ado_o = r(N)
                }
                else {
                    local ado_a = 0
                    local ado_d = 0
                    local ado_o = 0
                }
            }
        }

        /* -------------------------------------------------------------
           Step 4h: topic_by_year.dta
           Independent of construct fields; built from userdata + doctopic.
           -------------------------------------------------------------
        */
        if `emit_year' == 1 {
            qui use `userdata', clear
            keep study_id `year'
            qui drop if missing(`year')
            rename `year' year
            tempfile yearfile
            qui save `yearfile', replace

            qui count
            if r(N) > 0 {
                qui sum year, meanonly
                local years_min = r(min)
                local years_max = r(max)

                if `_have_any_long' == 0 {
                    qui use "`_tabledir'/litdiscover_doctopic.dta", clear
                    keep study_id topic_*
                    qui reshape long topic_, i(study_id) j(topic)
                    rename topic_ share
                    tempfile doctopic_long
                    qui save `doctopic_long', replace
                }

                qui use `doctopic_long', clear
                qui merge m:1 study_id using `yearfile', keep(match) nogen
                qui collapse (mean) mean_share=share (count) n_docs=share, by(year topic)
                order year topic mean_share n_docs
                qui save "`_tabledir'/litdiscover_topic_by_year.dta", replace
            }
        }
    }

    /* -----------------------------------------------------------------
       Step 4i (Block C): netmeasures
       -----------------------------------------------------------------
    */
    local net_networks_within = 0
    local net_networks_cross  = 0
    local net_nodes_within    = 0
    local net_nodes_cross     = 0
    local net_modularity_mean = ""
    local net_modularity_min  = ""
    local net_modularity_max  = ""
    local net_louvain_seed    = ""
    local _net_within_file ""
    local _net_cross_file  ""

    if "`netmeasures'" != "" {
        if `_have_any_long' == 0 {
            di as txt "litdiscover: netmeasures set but no construct field supplied; skipping."
        }
        else {
            di as txt "litdiscover: computing network-analytic measures (`netscript')..."

            tempfile _net_within_csv
            tempfile _net_cross_csv
            local withindta `"`_tabledir'/litdiscover_cooc_within.dta"'
            local crossdta  `"`_tabledir'/litdiscover_cooc_cross.dta"'
            local withincsv `"`_net_within_csv'"'
            local crosscsv  `"`_net_cross_csv'"'

            python script "`netscript'"

            qui import delimited using "`withincsv'", clear varnames(1) case(preserve) stringcols(1 2)
            qui save "`_tabledir'/litdiscover_network_measures.dta", replace
            local _net_within_file `"`_tabledir'/litdiscover_network_measures.dta"'

            qui import delimited using "`crosscsv'", clear varnames(1) case(preserve) stringcols(1 2 3 4)
            qui save "`_tabledir'/litdiscover_network_measures_cross.dta", replace
            local _net_cross_file `"`_tabledir'/litdiscover_network_measures_cross.dta"'

            di as txt "litdiscover: network measures written (within networks = `net_networks_within', cross networks = `net_networks_cross')."
        }
    }

    /* -----------------------------------------------------------------
       Step 5a: Stata-tier figures
       -----------------------------------------------------------------
    */
    local figures_n = 0
    local figures_list ""

    if "`figures'" != "" {
        di as txt "litdiscover: generating Stata-tier figures..."

        /* -----------------------------------------------------------
           Fig 1: construct frequency per field
           One .gph/.png per field, top-15 by n_docs.
           -----------------------------------------------------------
        */
        capture confirm file "`_tabledir'/litdiscover_construct_freq.dta"
        if !_rc {
            qui use "`_tabledir'/litdiscover_construct_freq.dta", clear
            tempfile freq_master
            qui save `freq_master', replace
            qui levelsof field, local(_flds_for_fig) clean
            foreach f of local _flds_for_fig {
                qui use `freq_master', clear
                qui keep if field == "`f'"
                qui count
                if r(N) == 0 continue
                gsort -n_docs
                qui keep if _n <= 15
                local _gph "`_figdir'/litdiscover_fig_constructfreq_`f'.gph"
                local _png "`_figdir'/litdiscover_fig_constructfreq_`f'.png"
                qui graph hbar (asis) n_docs, over(value, sort(1) descending label(labsize(small))) ytitle("Documents") title("Top constructs: `f'", size(medium)) bar(1, color("0 114 178")) name(_fig_freq_`f', replace)
                qui graph save _fig_freq_`f' "`_gph'", replace
                qui graph export "`_png'", as(png) width(2250) replace
                qui graph drop _fig_freq_`f'
                local figures_n = `figures_n' + 1
                local figures_list "`figures_list' litdiscover_fig_constructfreq_`f'.png"
            }
        }

        /* -----------------------------------------------------------
           Fig 2: topic share by year
           -----------------------------------------------------------
        */
        capture confirm file "`_tabledir'/litdiscover_topic_by_year.dta"
        if !_rc {
            qui use "`_tabledir'/litdiscover_topic_by_year.dta", clear
            qui count
            if r(N) > 0 {
                local _gph "`_figdir'/litdiscover_fig_topicyear.gph"
                local _png "`_figdir'/litdiscover_fig_topicyear.png"
                qui levelsof topic, local(_tlist) clean
                local _plotcmd ""
                local _legcmd  ""
                local _i = 0
                foreach t of local _tlist {
                    local _i = `_i' + 1
                    local _plotcmd `"`_plotcmd' (line mean_share year if topic == `t', lwidth(medthick))"'
                    local _legcmd  `"`_legcmd' `_i' "Topic `t'""'
                }
                qui twoway `_plotcmd', legend(order(`_legcmd') rows(1) size(small)) ytitle("Mean topic share") xtitle("Year") title("Topic prevalence over time", size(medium)) name(_fig_topicyear, replace)
                qui graph save _fig_topicyear "`_gph'", replace
                qui graph export "`_png'", as(png) width(2250) replace
                qui graph drop _fig_topicyear
                local figures_n = `figures_n' + 1
                local figures_list "`figures_list' litdiscover_fig_topicyear.png"
            }
        }

        /* -----------------------------------------------------------
           Fig 3: ADO frequency
           -----------------------------------------------------------
        */
        capture confirm file "`_tabledir'/litdiscover_ado.dta"
        if !_rc {
            qui use "`_tabledir'/litdiscover_ado.dta", clear
            qui count
            if r(N) > 0 {
                tempfile ado_for_fig
                qui contract ado_class, freq(n_rows)
                qui save `ado_for_fig', replace
                local _gph "`_figdir'/litdiscover_fig_ado.gph"
                local _png "`_figdir'/litdiscover_fig_ado.png"
                qui graph bar (asis) n_rows, over(ado_class, sort(1) descending) ytitle("Coded (study, class) rows") title("ADO class frequency", size(medium)) bar(1, color("213 94 0")) name(_fig_ado, replace)
                qui graph save _fig_ado "`_gph'", replace
                qui graph export "`_png'", as(png) width(2250) replace
                qui graph drop _fig_ado
                local figures_n = `figures_n' + 1
                local figures_list "`figures_list' litdiscover_fig_ado.png"
            }
        }

        /* -----------------------------------------------------------
           Fig 4: TCCM heatmap (theory x tccm_class_label, summed)
           -----------------------------------------------------------
        */
        capture confirm file "`_tabledir'/litdiscover_tccm.dta"
        if !_rc & "`_tccm_class_label'" != "" {
            qui use "`_tabledir'/litdiscover_tccm.dta", clear
            qui count
            if r(N) > 0 {
                qui collapse (sum) n, by(theory `_tccm_class_label')
                local _gph "`_figdir'/litdiscover_fig_tccm.gph"
                local _png "`_figdir'/litdiscover_fig_tccm.png"
                capture noisily heatplot n theory `_tccm_class_label', values(format(%9.0f) size(vsmall)) color(viridis) xlabel(, angle(45) labsize(vsmall)) ylabel(, labsize(vsmall)) title("TCCM frequency: theory x `_tccm_class_label'", size(medium)) name(_fig_tccm, replace)
                if !_rc {
                    qui graph save _fig_tccm "`_gph'", replace
                    qui graph export "`_png'", as(png) width(2250) replace
                    qui graph drop _fig_tccm
                    local figures_n = `figures_n' + 1
                    local figures_list "`figures_list' litdiscover_fig_tccm.png"
                }
            }
        }

        /* -----------------------------------------------------------
           Fig 5: topic-by-field heatmap, one per field, top-15 values
           -----------------------------------------------------------
        */
        capture confirm file "`_tabledir'/litdiscover_topic_by_field.dta"
        if !_rc {
            qui use "`_tabledir'/litdiscover_topic_by_field.dta", clear
            tempfile tbf_master
            qui save `tbf_master', replace
            qui levelsof field, local(_flds_for_heatmap) clean
            foreach f of local _flds_for_heatmap {
                qui use `tbf_master', clear
                qui keep if field == "`f'"
                qui count
                if r(N) == 0 continue
                /* keep top-15 values by total mean_share across topics */
                tempfile _f_data
                qui save `_f_data', replace
                qui collapse (sum) _total=mean_share, by(value)
                gsort -_total
                qui keep if _n <= 15
                keep value
                tempfile _f_top
                qui save `_f_top', replace
                qui use `_f_data', clear
                qui merge m:1 value using `_f_top', keep(match) nogen
                local _gph "`_figdir'/litdiscover_fig_topicheatmap_`f'.gph"
                local _png "`_figdir'/litdiscover_fig_topicheatmap_`f'.png"
                capture noisily heatplot mean_share value topic, values(format(%4.2f) size(vsmall)) color(viridis) xlabel(, labsize(vsmall)) ylabel(, labsize(vsmall)) title("Topic share by `f' (top 15)", size(medium)) name(_fig_heat_`f', replace)
                if !_rc {
                    qui graph save _fig_heat_`f' "`_gph'", replace
                    qui graph export "`_png'", as(png) width(2250) replace
                    qui graph drop _fig_heat_`f'
                    local figures_n = `figures_n' + 1
                    local figures_list "`figures_list' litdiscover_fig_topicheatmap_`f'.png"
                }
            }
        }

        local figures_list = strtrim("`figures_list'")
    }

    /* -----------------------------------------------------------------
       Step 5b: Python-tier figures and interactive HTMLs
       -----------------------------------------------------------------
    */
    local interactive_n = 0
    local interactive_list ""

    if `_need_viz' == 1 {
        di as txt "litdiscover: invoking Python viz helper (`vizscript')..."

        /* Locals expected by litdiscover_viz.py. */
        local viz_do_figures     = ("`figures'"     != "")
        local viz_do_interactive = ("`interactive'" != "")
        local viz_tabledir       = `"`_tabledir'"'
        local viz_figdir         = `"`_figdir'"'
        local viz_intdir         = `"`_intdir'"'
        local viz_sankeytopfreq  = `sankeytopfreq'
        /* The pyLDAvis interchange file is written by litdiscover.py
           earlier in this same .ado invocation (only if interactive set).
        */
        local viz_pyldavispath   = `"`pyldavispath'"'

        python script "`vizscript'"

        /* The viz script writes a CSV manifest enumerating what it produced. */
        capture confirm file "`_figdir'/_viz_manifest_figures.txt"
        if !_rc {
            tempname fh
            file open `fh' using "`_figdir'/_viz_manifest_figures.txt", read
            file read `fh' line
            while r(eof) == 0 {
                local _ln = strtrim("`line'")
                if "`_ln'" != "" {
                    local figures_list "`figures_list' `_ln'"
                    local figures_n = `figures_n' + 1
                }
                file read `fh' line
            }
            file close `fh'
            qui erase "`_figdir'/_viz_manifest_figures.txt"
        }

        capture confirm file "`_intdir'/_viz_manifest_interactive.txt"
        if !_rc {
            tempname fh2
            file open `fh2' using "`_intdir'/_viz_manifest_interactive.txt", read
            file read `fh2' line
            while r(eof) == 0 {
                local _ln = strtrim("`line'")
                if "`_ln'" != "" {
                    local interactive_list "`interactive_list' `_ln'"
                    local interactive_n = `interactive_n' + 1
                }
                file read `fh2' line
            }
            file close `fh2'
            qui erase "`_intdir'/_viz_manifest_interactive.txt"
        }

        local figures_list = strtrim("`figures_list'")
        local interactive_list = strtrim("`interactive_list'")
    }

    restore

    /* -----------------------------------------------------------------
       Step 6: Optionally retain intermediate corpus CSV for inspection
       -----------------------------------------------------------------
    */
    if "`keeptemp'" != "" {
        capture copy "`corpuscsv'" "`_tabledir'/_intermediate_corpus.csv", replace
    }

    /* -----------------------------------------------------------------
       Step 7: Return scalars and macros
       -----------------------------------------------------------------
    */
    return scalar N_input  = `N_input'
    return scalar N_docs   = `N_docs'
    return scalar k_topics = `topics'
    return scalar n_seeds  = `seeds'
    return scalar coherence = `docoh'

    if "`year'" != "" {
        if "`years_min'" != "" {
            return scalar years_min = `years_min'
            return scalar years_max = `years_max'
        }
    }

    foreach f of local mv_fields {
        if "``f''" != "" {
            return scalar N_`f' = `N_`f''
        }
    }
    if "`journal'" != "" {
        return scalar N_journal = `N_journal'
    }

    if `emit_tccm' == 1 {
        return scalar tccm_cells   = `tccm_cells'
        return scalar tccm_minfreq = `tccmminfreq'
        return local  tccm_class_field "`_tccm_class_label'"
    }

    if `emit_ado' == 1 {
        return scalar ado_a = `ado_a'
        return scalar ado_d = `ado_d'
        return scalar ado_o = `ado_o'
    }

    /* Block A.5 returns */
    return scalar figures_n     = `figures_n'
    return scalar interactive_n = `interactive_n'
    if `_flat' == 0 {
        return local outdir "`_root'"
    }
    else {
        return local outdir ""
    }
    return local tables_dir       "`_tabledir'"
    return local figures_dir      "`_figdir'"
    return local interactive_dir  "`_intdir'"
    return local figures_list     "`figures_list'"
    return local interactive_list "`interactive_list'"

    return local fields_supplied "`fields_supplied'"
    if `_flat' == 1 {
        return local export "`_tabledir'"
    }
    else {
        return local export ""
    }

    /* -----------------------------------------------------------------
       Block C returns: netmeasures
       -----------------------------------------------------------------
    */
    return scalar net_networks_within = real("`net_networks_within'")
    return scalar net_networks_cross  = real("`net_networks_cross'")
    return scalar net_nodes_within    = real("`net_nodes_within'")
    return scalar net_nodes_cross     = real("`net_nodes_cross'")
    if "`net_modularity_mean'" != "" {
        return scalar net_modularity_mean = real("`net_modularity_mean'")
    }
    if "`net_modularity_min'" != "" {
        return scalar net_modularity_min  = real("`net_modularity_min'")
    }
    if "`net_modularity_max'" != "" {
        return scalar net_modularity_max  = real("`net_modularity_max'")
    }
    if "`net_louvain_seed'" != "" {
        return scalar net_louvain_seed    = real("`net_louvain_seed'")
    }
    return local network_measures_file       "`_net_within_file'"
    return local network_measures_cross_file "`_net_cross_file'"

    /* v0.3.1: path to the per-topic stability file (empty when seeds=1). */
    return local topic_stability_file "`_topic_stability_file'"

    /* -----------------------------------------------------------------
       Block B returns: frex
       -----------------------------------------------------------------
    */
    if "`frex_omega'" != "" {
        return scalar frex_omega      = real("`frex_omega'")
    }
    if "`frex_epsilon'" != "" {
        return scalar frex_epsilon    = real("`frex_epsilon'")
    }
    if "`frex_topics'" != "" {
        return scalar frex_topics     = real("`frex_topics'")
    }
    if "`frex_vocab_size'" != "" {
        return scalar frex_vocab_size = real("`frex_vocab_size'")
    }

    /* -----------------------------------------------------------------
       v1.0 usability layer: end-of-run summary and autoload.
       -----------------------------------------------------------------
    */
    local _topicterms_file  `"`_tabledir'/litdiscover_topicterms.dta"'
    local _input_recovery   `"`_tabledir'/_litdiscover_input_recovery.dta"'

    /* Step (1): save the input dataset to a stable path for recovery. */
    qui use `userdata_orig', clear
    capture drop __*
    capture confirm string variable study_id
    if _rc {
        tostring study_id, replace
    }
    qui save `"`_input_recovery'"', replace

    return local topicterms_file      `"`_topicterms_file'"'
    return local input_recovery_file  `"`_input_recovery'"'

    /* Step (2): print the end-of-run summary. */
    di as txt _newline "{hline 70}"
    di as txt "LITDISCOVER summary"
    di as txt "{hline 70}"
    di as txt "Output directory: " as result `"`_tabledir'"'

    /* List every .dta file in the tables directory. We use file commands
       rather than shell to keep this cross-platform friendly. */
    local _dtafiles : dir `"`_tabledir'"' files "litdiscover_*.dta"
    if `"`_dtafiles'"' != "" {
        di as txt _newline "Tables produced:"
        foreach f of local _dtafiles {
            di as txt "  " as result `"`_tabledir'/`f'"'
        }
    }

    /* Figures and interactive subdirectories, only when set. */
    if "`figures'" != "" & `figures_n' > 0 {
        di as txt _newline "Figures produced: " as result `figures_n'
        di as txt "  in " as result `"`_figdir'"'
    }
    if "`interactive'" != "" & `interactive_n' > 0 {
        di as txt _newline "Interactive HTML files: " as result `interactive_n'
        di as txt "  in " as result `"`_intdir'"'
    }

    /* Step (3): autoload behaviour. */
    if "`noautoload'" == "" {
        capture confirm file `"`_topicterms_file'"'
        if !_rc {
            qui use `"`_topicterms_file'"', clear
            di as txt _newline as result "litdiscover_topicterms.dta is now in memory."
            di as txt "Try these commands directly:"
            di as input "  . list topic rank term weight if rank <= 5, sepby(topic) noobs"
            di as input "  . tabulate topic"
            di as input "  . graph bar (mean) weight, over(topic)"
        }
        else {
            di as txt _newline as error "Note: litdiscover_topicterms.dta not found; nothing was loaded."
        }
    }
    else {
        di as txt _newline "Auto-load suppressed (noautoload). Your input dataset is still in memory."
    }

    /* Always show the user how to switch to other tables and recover input. */
    di as txt _newline "To inspect another table:"
    di as input `"  . use "`_tabledir'/litdiscover_doctopic.dta", clear"'
    di as input `"  . use "`_tabledir'/litdiscover_coherence.dta", clear"'
    di as input `"  . use "`_tabledir'/litdiscover_topic_by_field.dta", clear"'
    di as txt _newline "To return to your input dataset:"
    di as input `"  . use "`_input_recovery'", clear"'
    di as txt "{hline 70}"
end
