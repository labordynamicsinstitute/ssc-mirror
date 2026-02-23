*! bayeshmc.ado -- Bayesian regression via CmdStan HMC/NUTS
*! Version 4.2.0 | 2026-02-21
*! Author: Ben Adarkwa Dwamena
*!         Clinical Associate Professor Emeritus of Radiology
*!         University of Michigan, Ann Arbor
*!
*! Pure Stata/Mata implementation -- no Python dependency.
*! Requires: CmdStan (set path with: bayeshmc, setup path(/path/to/cmdstan))

program define bayeshmc, eclass
    version 16.0

    // --- Route subcommands ---------------------------------------
    local orig_input `"`0'"'
    capture _on_colon_parse `0'
    if _rc != 0 {
        // No colon -- must be a subcommand or option-only call
        local 0 `"`orig_input'"'

        // Strip leading comma if present, then get first word
        local stripped = strtrim("`orig_input'")
        if substr("`stripped'", 1, 1) == "," {
            local stripped = strtrim(substr("`stripped'", 2, .))
        }
        local subcmd = strlower(word("`stripped'", 1))
        // Strip trailing comma if present (e.g., "trace," -> "trace")
        if substr("`subcmd'", -1, 1) == "," {
            local subcmd = substr("`subcmd'", 1, strlen("`subcmd'") - 1)
        }

        if "`subcmd'" == "setup" {
            // Re-parse the full input for path() option
            local 0 `", `stripped'"'
            syntax [, SETup Path(string)]
            _bhmc3_setup `path'
            exit
        }
        if "`subcmd'" == "summary" {
            _bhmc3_summary
            exit
        }
        if "`subcmd'" == "ess" {
            _bhmc3_ess
            exit
        }
        if "`subcmd'" == "trace" {
            local 0 `"`orig_input'"'
            syntax anything [, SAVing(string) PARAMeters(string)]
            _bhmc3_trace, saving(`saving') parameters(`parameters')
            exit
        }
        if "`subcmd'" == "ac" {
            local 0 `"`orig_input'"'
            syntax anything [, SAVing(string) PARAMeters(string) LAGs(integer 40)]
            _bhmc3_ac, saving(`saving') parameters(`parameters') lags(`lags')
            exit
        }
        if "`subcmd'" == "density" {
            local 0 `"`orig_input'"'
            syntax anything [, SAVing(string) PARAMeters(string)]
            _bhmc3_density, saving(`saving') parameters(`parameters')
            exit
        }
        if "`subcmd'" == "histogram" {
            local 0 `"`orig_input'"'
            syntax anything [, SAVing(string) PARAMeters(string) Bins(integer 30)]
            _bhmc3_histogram, saving(`saving') parameters(`parameters') bins(`bins')
            exit
        }
        if "`subcmd'" == "waic" {
            _bhmc3_waic
            exit
        }
        if "`subcmd'" == "loo" {
            _bhmc3_loo
            exit
        }

        // No recognized subcommand
        di as error "bayeshmc: specify a model after colon, e.g. bayeshmc: regress y x"
        di as error "  subcommands: setup, summary, ess, trace, ac, density, histogram, waic, loo"
        exit 198
    }

    local before `"`s(before)'"'
    local after  `"`s(after)'"'

    // --- Parse options (before colon) ----------------------------
    local 0 `"`before'"'
    syntax [, Chains(integer 4) ITERations(integer 2000)          ///
              WARMup(integer 1000) SEED(integer -1)               ///
              THin(integer 1) THINning(integer -1)                ///
              CLEVEL(integer 95) HPD                              ///
              adapt_delta(real 0.8) max_treedepth(integer 10)     ///
              SAVing(string) DRYrun VERBose DIAGnostics             ///
              prior_sd(real -1) NORMalprior(real 100)             ///
              noHEADer                                            ///
              CMDstan(string) NOCAChe                              ///
              LKJprior(real 1) REPARAM                            ///
              COVPrior(string) PARallel THReads(integer 1)]

    // Covariance prior: default to lkj
    if "`covprior'" == "" local covprior "lkj"
    local covprior = lower("`covprior'")
    if !inlist("`covprior'", "lkj", "iw", "siw", "huangwand", "spherical") {
        di as error "covprior() must be one of: lkj, iw, siw, huangwand, spherical"
        exit 198
    }
    if `prior_sd' < 0 {
        local prior_sd = `normalprior'
    }
    // thinning -> thin
    if `thinning' > 0 {
        local thin = `thinning'
    }

    // --- Parse model (after colon) -------------------------------
    local 0 `"`after'"'

    // Check for || (multilevel separator)
    local hasbar = strpos(`"`0'"', "||")
    local groupvar ""
    local re_terms ""
    local cov_type "independent"
    local binomial ""
    if `hasbar' > 0 {
        local model_part = substr(`"`0'"', 1, `hasbar' - 1)
        local re_part = substr(`"`0'"', `hasbar' + 2, .)
        gettoken groupvar re_rest : re_part, parse(":")
        local re_terms : subinstr local re_rest ":" ""
        local re_terms = strtrim("`re_terms'")
        // Extract covariance() option from re_terms
        local cov_pos = strpos("`re_terms'", "covariance(")
        if `cov_pos' > 0 {
            local cov_str = substr("`re_terms'", `cov_pos', .)
            local cov_end = strpos("`cov_str'", ")")
            local cov_type = substr("`cov_str'", 12, `cov_end' - 12)
            local before_cov = substr("`re_terms'", 1, `cov_pos' - 1)
            local after_cov = substr("`re_terms'", `cov_pos' + `cov_end', .)
            local re_terms = strtrim("`before_cov'" + "`after_cov'")
        }
        // Also check for comma-separated options
        local comma_pos = strpos("`re_terms'", ",")
        if `comma_pos' > 0 {
            local re_vars = strtrim(substr("`re_terms'", 1, `comma_pos' - 1))
            local re_opts = strtrim(substr("`re_terms'", `comma_pos' + 1, .))
            local re_terms "`re_vars'"
            if strpos("`re_opts'", "covariance(") > 0 {
                local cov_pos2 = strpos("`re_opts'", "covariance(")
                local cov_str2 = substr("`re_opts'", `cov_pos2', .)
                local cov_end2 = strpos("`cov_str2'", ")")
                local cov_type = substr("`cov_str2'", 12, `cov_end2' - 12)
            }
            if strpos("`re_opts'", "binomial(") > 0 {
                local bin_pos = strpos("`re_opts'", "binomial(")
                local bin_str = substr("`re_opts'", `bin_pos', .)
                local bin_end = strpos("`bin_str'", ")")
                local binomial = substr("`bin_str'", 10, `bin_end' - 10)
            }
            // Extract het() if after ||
            if strpos("`re_opts'", "het(") > 0 {
                local het_pos = strpos("`re_opts'", "het(")
                local het_str = substr("`re_opts'", `het_pos', .)
                local het_end = strpos("`het_str'", ")")
                local het_from_re = strtrim(substr("`het_str'", 5, `het_end' - 5))
                // Append to model_part so syntax can parse it
                local model_part `"`model_part', het(`het_from_re')"'
            }
            // Extract select() if after ||
            if strpos("`re_opts'", "select(") > 0 {
                local sel_pos = strpos("`re_opts'", "select(")
                local sel_str = substr("`re_opts'", `sel_pos', .)
                local sel_end = strpos("`sel_str'", ")")
                local sel_from_re = strtrim(substr("`sel_str'", 8, `sel_end' - 8))
                local model_part `"`model_part', select(`sel_from_re')"'
            }
        }
        local 0 `"`model_part'"'
    }

    // Determine number of random effects
    local n_re = 1
    if "`re_terms'" != "" {
        local n_re_vars : word count `re_terms'
        local n_re = `n_re_vars' + 1
    }
    if "`cov_type'" == "unstructured" & `n_re' < 2 {
        local cov_type "independent"
    }

    gettoken family 0 : 0
    local family = strlower("`family'")

    // Extract family() option before syntax (to avoid clash with model family)
    local glmfamily ""
    local fam_pos = strpos(`"`0'"', "family(")
    if `fam_pos' > 0 {
        local fam_str = substr(`"`0'"', `fam_pos', .)
        local fam_end = strpos("`fam_str'", ")")
        local glmfamily = substr("`fam_str'", 8, `fam_end' - 8)
        // Remove family(...) from the string
        local before_fam = substr(`"`0'"', 1, `fam_pos' - 1)
        local after_fam = substr(`"`0'"', `fam_pos' + `fam_end', .)
        local 0 `"`before_fam' `after_fam'"'
    }

    // Save binomial parsed from re_opts before syntax overwrites it
    local _saved_binomial "`binomial'"

    // Parse varlist and model options
    syntax varlist(min=1 fv ts) [if] [in] [,                     ///
        OFFset(varname) EXPosure(varname)                         ///
        INFlate(varlist fv) BINomial(varname)                     ///
        HET(varlist fv) SELect(varlist fv)                        ///
        LINk(string)                                              ///
        DISTribution(string)                                      ///
        ll(real -999999) ul(real 999999)]

    // Restore binomial if it was parsed from re_opts
    if "`binomial'" == "" & "`_saved_binomial'" != "" {
        local binomial "`_saved_binomial'"
    }

    gettoken depvar predictors : varlist

    // Survival models: all varlist items are predictors; depvar = _t from stset
    if "`family'" == "streg" | "`family'" == "mestreg" {
        local predictors "`varlist'"
        local depvar "_t"
    }

    // Interval regression: two depvars (y_lo y_hi) then predictors
    local depvar_hi ""
    if "`family'" == "intreg" {
        gettoken depvar_hi predictors : predictors
    }

    // Panel models (xtreg, xtlogit, etc.): get panel var from xtset
    if "`groupvar'" == "" {
        if substr("`family'", 1, 2) == "xt" {
            local groupvar "`_dta[iis]'"
            if "`groupvar'" == "" {
                qui xtset
                local groupvar "`r(panelvar)'"
            }
            if "`groupvar'" == "" {
                di as error "Panel variable not set. Use xtset before xt* commands."
                exit 198
            }
            di as text "  Panel var:    " as result "`groupvar'"
        }
    }

    // Expand factor variables and create indicator dummies
    if "`predictors'" != "" {
        local expanded_preds ""
        foreach v of local predictors {
            // Check if this is a factor variable (i. or c. prefix, or #)
            if regexm("`v'", "^(i|c|o)\.") | regexm("`v'", "#") {
                // Factor variable: expand and create dummies
                fvexpand `v' `if' `in'
                local fvlist `"`r(varlist)'"'
                foreach fv of local fvlist {
                    // Skip base levels (contain 'b')
                    if regexm("`fv'", "b\.") continue
                    if regexm("`fv'", "o\.") continue
                    // Parse: e.g. "2.agecat" -> level=2, var=agecat
                    if regexm("`fv'", "^([0-9]+)\.(.+)$") {
                        local lvl = regexs(1)
                        local vname = regexs(2)
                        local dname "_I`vname'_`lvl'"
                        // Truncate if too long for Stata
                        if length("`dname'") > 32 {
                            local dname = substr("`dname'", 1, 32)
                        }
                        capture drop `dname'
                        qui gen byte `dname' = (`vname' == `lvl') `if' `in'
                        local expanded_preds "`expanded_preds' `dname'"
                    }
                }
            }
            else {
                // Regular variable
                local expanded_preds "`expanded_preds' `v'"
            }
        }
        local predictors "`expanded_preds'"
    }

    // Expand het() variables (factor variables)
    local het_vars ""
    local n_het = 0
    if "`het'" != "" {
        local expanded_het ""
        foreach v of local het {
            if regexm("`v'", "^(i|c|o)\.") | regexm("`v'", "#") {
                fvexpand `v' `if' `in'
                local fvlist `"`r(varlist)'"'
                foreach fv of local fvlist {
                    if regexm("`fv'", "b\.") continue
                    if regexm("`fv'", "o\.") continue
                    if regexm("`fv'", "^([0-9]+)\.(.+)$") {
                        local lvl = regexs(1)
                        local vname = regexs(2)
                        local dname "_I`vname'_`lvl'"
                        if length("`dname'") > 32 local dname = substr("`dname'", 1, 32)
                        capture drop `dname'
                        qui gen byte `dname' = (`vname' == `lvl') `if' `in'
                        local expanded_het "`expanded_het' `dname'"
                    }
                }
            }
            else {
                local expanded_het "`expanded_het' `v'"
            }
        }
        local het_vars "`expanded_het'"
        local n_het : word count `het_vars'
    }

    // Expand select() variables (factor variables)
    local sel_vars ""
    local n_sel = 0
    if "`select'" != "" {
        local expanded_sel ""
        foreach v of local select {
            if regexm("`v'", "^(i|c|o)\.") | regexm("`v'", "#") {
                fvexpand `v' `if' `in'
                local fvlist `"`r(varlist)'"'
                foreach fv of local fvlist {
                    if regexm("`fv'", "b\.") continue
                    if regexm("`fv'", "o\.") continue
                    if regexm("`fv'", "^([0-9]+)\.(.+)$") {
                        local lvl = regexs(1)
                        local vname = regexs(2)
                        local dname "_I`vname'_`lvl'"
                        if length("`dname'") > 32 local dname = substr("`dname'", 1, 32)
                        capture drop `dname'
                        qui gen byte `dname' = (`vname' == `lvl') `if' `in'
                        local expanded_sel "`expanded_sel' `dname'"
                    }
                }
            }
            else {
                local expanded_sel "`expanded_sel' `v'"
            }
        }
        local sel_vars "`expanded_sel'"
        local n_sel : word count `sel_vars'
    }

    marksample touse
    qui count if `touse'
    local N = r(N)
    if `N' == 0 {
        di as error "no observations"
        exit 2000
    }

    if `seed' < 0 {
        local seed = floor(runiform() * 2147483647)
    }

    // --- Resolve CmdStan path ------------------------------------
    if "`cmdstan'" == "" local cmdstan "$CMDSTAN_HOME"
    if "`cmdstan'" == "" {
        mata: st_local("cmdstan", _bhmc3_find_cmdstan())
    }
    if "`cmdstan'" == "" {
        di as error "CmdStan not found. Run: bayeshmc, setup path(/path/to/cmdstan)"
        exit 198
    }
    mata: st_local("cmdstan", subinstr(st_local("cmdstan"), char(92), "/"))

    // --- Header --------------------------------------------------
    local total_draws = `chains' * `iterations'
    if "`header'" != "noheader" & "`verbose'" != "" {
        di as text ""
        di as text "{hline 72}"
        di as text " BayesHMC v4: Bayesian `family' regression via CmdStan HMC/NUTS"
        di as text "{hline 72}"
        di as text "  Outcome:      " as result "`depvar'"
        di as text "  Predictors:   " as result "`predictors'"
        if "`groupvar'" != "" {
            di as text "  Group:        " as result "`groupvar'"
            if "`re_terms'" != "" {
                di as text "  Random eff:   " as result "_cons `re_terms'"
            }
            if "`cov_type'" == "unstructured" {
                if "`covprior'" == "lkj" {
                    di as text "  Covariance:   " as result "unstructured (LKJ eta=`lkjprior')"
                }
                else if "`covprior'" == "iw" {
                    di as text "  Covariance:   " as result "unstructured (Inverse-Wishart)"
                }
                else if "`covprior'" == "siw" {
                    di as text "  Covariance:   " as result "unstructured (Scaled Inverse-Wishart)"
                }
                else if "`covprior'" == "huangwand" {
                    di as text "  Covariance:   " as result "unstructured (Huang-Wand)"
                }
                else if "`covprior'" == "spherical" {
                    di as text "  Covariance:   " as result "unstructured (Spherical decomposition)"
                }
            }
        }
        if "`het_vars'" != "" {
            di as text "  Scale vars:   " as result "`het_vars'"
        }
        if "`sel_vars'" != "" {
            di as text "  Selection:    " as result "`sel_vars'"
        }
        di as text "  Observations: " as result "`N'"
        if "`parallel'" != "" & `chains' > 1 & `threads' > 1 {
            di as text "  Chains:       " as result "`chains' (parallel, `threads' threads each)"
        }
        else if "`parallel'" != "" & `chains' > 1 {
            di as text "  Chains:       " as result "`chains' (parallel, background)"
        }
        else if `threads' > 1 {
            di as text "  Chains:       " as result "`chains' (parallel, `threads' threads)"
        }
        else {
            di as text "  Chains:       " as result "`chains'"
        }
        di as text "  Iterations:   " as result "`warmup' warmup + `iterations' sampling"
        if `thin' > 1 {
            di as text "  Thinning:     " as result "`thin'"
        }
        di as text "  Seed:         " as result "`seed'"
    }

    // --- Work directory ------------------------------------------
    local wdir "`cmdstan'/bhmc3_work"
    capture mkdir "`wdir'"
    if "`c(os)'" == "Windows" local wdir_w = subinstr("`wdir'", "/", "\", .)
    local stanpath "`wdir'/model.stan"
    local datapath "`wdir'/data.json"
    local outbase  "`wdir'/output"

    // --- Generate Stan code --------------------------------------
    mata: _bhmc3_write_stan("`family'", "`depvar'", "`predictors'",   ///
        "`groupvar'", "`re_terms'", `prior_sd', "`cov_type'",       ///
        `n_re', `lkjprior', "`het_vars'", `n_het',                  ///
        "`sel_vars'", `n_sel', "`glmfamily'`link'", "`stanpath'",   ///
        "`binomial'", "`covprior'")

    if "`dryrun'" == "dryrun" {
        di as text ""
        di as text "{hline 50}"
        di as text " Stan code:"
        di as text "{hline 50}"
        type "`stanpath'"
        di as text "{hline 50}"
        exit
    }

    // --- Export data as JSON -------------------------------------
    if "`verbose'" != "" di as text "  Exporting data..."
    preserve
    qui keep if `touse'
    if "`family'" == "intreg" {
        // For intreg, missing y_lo or y_hi indicates censoring -- keep them
        foreach v of varlist `predictors' {
            qui drop if missing(`v')
        }
        // But drop if BOTH are missing
        qui drop if missing(`depvar') & missing(`depvar_hi')
    }
    else {
        foreach v of varlist `depvar' `predictors' {
            qui drop if missing(`v')
        }
    }
    if "`groupvar'" != "" {
        qui drop if missing(`groupvar')
    }
    if "`re_terms'" != "" {
        foreach v of varlist `re_terms' {
            qui drop if missing(`v')
        }
    }
    if "`het_vars'" != "" {
        foreach v of varlist `het_vars' {
            qui drop if missing(`v')
        }
    }
    if "`sel_vars'" != "" {
        foreach v of varlist `sel_vars' {
            qui drop if missing(`v')
        }
    }
    // Truncated regression: drop observations outside truncation bounds
    if "`family'" == "truncreg" {
        if `ll' > -999999 {
            qui drop if `depvar' < `ll'
        }
        if `ul' < 999999 {
            qui drop if `depvar' > `ul'
        }
    }
    local N = _N
    mata: _bhmc3_write_json("`family'", "`depvar'", "`predictors'",   ///
        "`groupvar'", "`re_terms'", "`cov_type'", `n_re',           ///
        "`het_vars'", "`sel_vars'", "`datapath'", `ll', `ul',       ///
        "`depvar_hi'", "`binomial'")
    // Generate init file with data-driven starting values
    local initpath "`wdir'/init.json"
    mata: _bhmc3_write_init("`family'", "`depvar'", "`predictors'", "`initpath'")
    restore

    // --- Compile (with caching) ----------------------------------
    mata: st_local("codehash", _bhmc3_hash("`stanpath'"))
    // Threaded models get different cache key
    if `threads' > 1 {
        local codehash "`codehash't"
    }
    local model_stan "`cmdstan'/bhmc_m`codehash'.stan"
    local model_exe  "`cmdstan'/bhmc_m`codehash'"

    // Determine make flags for threading
    local make_flags ""
    if `threads' > 1 {
        local make_flags "STAN_THREADS=TRUE"
    }


    local need_compile 1
    if "`nocache'" == "" {
        if "`c(os)'" == "Windows" {
            capture confirm file "`model_exe'.exe"
        }
        else {
            capture confirm file "`model_exe'"
        }
        if _rc == 0 {
            local need_compile 0
            if "`verbose'" != "" di as text "  Using cached model (hash `codehash')..."
        }
    }

    if `need_compile' {
        capture copy "`stanpath'" "`model_stan'", replace
        if _rc != 0 {
            mata: _bhmc3_write_stan("`family'", "`depvar'", "`predictors'", ///
                "`groupvar'", "`re_terms'", `prior_sd', "`cov_type'",    ///
                `n_re', `lkjprior', "`het_vars'", `n_het',              ///
                "`sel_vars'", `n_sel', "`glmfamily'`link'", "`model_stan'", ///
                "`binomial'", "`covprior'")
        }
        if "`verbose'" != "" di as text "  Compiling Stan model..."
        if "`c(os)'" == "Windows" {
            local make_cmd ""
            local make_paths ""
            foreach rt in 44 43 42 {
                local mp "C:/rtools`rt'/usr/bin"
                capture confirm file "`mp'/make.exe"
                if _rc == 0 {
                    local make_cmd "`mp'/make.exe"
                    local gpp "C:/rtools`rt'/x86_64-w64-mingw32.static.posix/bin"
                    capture confirm file "`gpp'/g++.exe"
                    if _rc != 0 {
                        local gpp "C:/rtools`rt'/mingw64/bin"
                    }
                    local make_paths "`mp';`gpp'"
                    continue, break
                }
            }
            if "`make_cmd'" == "" {
                foreach mp in "C:/msys64/usr/bin" "C:/mingw64/bin" {
                    capture confirm file "`mp'/make.exe"
                    if _rc == 0 {
                        local make_cmd "`mp'/make.exe"
                        local make_paths "`mp'"
                        continue, break
                    }
                }
            }
            if "`make_cmd'" == "" {
                foreach condadir in "anaconda3" "miniconda3" {
                    local mp "C:/Users/`c(username)'/`condadir'/Library/usr/bin"
                    capture confirm file "`mp'/make.exe"
                    if _rc == 0 {
                        local make_cmd "`mp'/make.exe"
                        local make_paths "`mp'"
                        continue, break
                    }
                }
            }
            local make_tgt "bhmc_m`codehash'.exe"
            if "`make_cmd'" != "" {
                local make_cmd_w = subinstr("`make_cmd'", "/", "\", .)
                local make_paths_w = subinstr("`make_paths'", "/", "\", .)
                local cmdstan_w = subinstr("`cmdstan'", "/", "\", .)
                if "`verbose'" != "" di as text "  Using make: `make_cmd_w'"
                capture confirm file "`cmdstan'/make/local"
                if _rc != 0 {
                    mata: _bhmc3_ensure_make_local("`cmdstan'")
                }
                if "`verbose'" == "" {
                    shell (set "PATH=`make_paths_w';%PATH%" & cd /d "`cmdstan_w'" & "`make_cmd_w'" `make_flags' "`make_tgt'") > "`wdir_w'\make.log" 2>&1
                }
                else {
                    shell set "PATH=`make_paths_w';%PATH%" & cd /d "`cmdstan_w'" & "`make_cmd_w'" `make_flags' "`make_tgt'"
                }
            }
            else {
                shell cd /d "`cmdstan'" & make "`make_tgt'" 2>&1
                capture confirm file "`model_exe'.exe"
                if _rc != 0 {
                    shell cd /d "`cmdstan'" & mingw32-make "`make_tgt'" 2>&1
                }
            }
        }
        else {
            shell cd "`cmdstan'" && make `make_flags' "`model_exe'" 2>&1
        }
        if "`c(os)'" == "Windows" {
            capture confirm file "`model_exe'.exe"
        }
        else {
            capture confirm file "`model_exe'"
        }
        if _rc != 0 {
            di as error "Stan compilation failed."
            di as error "  Check CmdStan: `cmdstan'"
            di as error "  Stan file: `model_stan'"
            // Show compiler error log
            local wdir_w2 = subinstr("`wdir'", "/", "\", .)
            capture confirm file "`wdir'/make.log"
            if _rc == 0 {
                di as error "  Compiler output:"
                type "`wdir'/make.log"
            }
            exit 198
        }
    }

    // --- Sample --------------------------------------------------
    forvalues c = 1/`chains' {
        capture erase "`outbase'_`c'.csv"
    }

    local exe "`model_exe'"
    if "`c(os)'" == "Windows" local exe "`model_exe'.exe"

    // Common CmdStan arguments
    local sample_args "method=sample num_warmup=`warmup' num_samples=`iterations' thin=`thin' algorithm=hmc engine=nuts max_depth=`max_treedepth' adapt delta=`adapt_delta'"
    local sample_args "`sample_args' init=`initpath'"

    // === MODE 1: CmdStan native multi-chain (threads > 1, no parallel) =
    //     Uses num_chains + STAN_NUM_THREADS (requires STAN_THREADS compile)
    if `threads' > 1 & "`parallel'" == "" {
        if "`verbose'" != "" di as text "  Sampling `chains' chains with `threads' threads (CmdStan native parallel)..."
        local total_threads = `threads'
        if "`c(os)'" == "Windows" {
            local make_paths_w = subinstr("`make_paths'", "/", "\", .)
            local wdir_w = subinstr("`wdir'", "/", "\", .)
            if "`verbose'" == "" {
                shell (set "PATH=`make_paths_w';%PATH%" & set "STAN_NUM_THREADS=`total_threads'" & "`exe'" `sample_args' num_chains=`chains' random seed=`seed' data file="`datapath'" output file="`outbase'.csv") > "`wdir_w'\sampling.log" 2>&1
            }
            else {
                shell set "PATH=`make_paths_w';%PATH%" & set "STAN_NUM_THREADS=`total_threads'" & "`exe'" `sample_args' num_chains=`chains' random seed=`seed' data file="`datapath'" output file="`outbase'.csv"
            }
        }
        else {
            if "`verbose'" == "" {
                shell STAN_NUM_THREADS=`total_threads' "`exe'" `sample_args' num_chains=`chains' random seed=`seed' data file="`datapath'" output file="`outbase'.csv" > "`wdir'/sampling.log" 2>&1
            }
            else {
                shell STAN_NUM_THREADS=`total_threads' "`exe'" `sample_args' num_chains=`chains' random seed=`seed' data file="`datapath'" output file="`outbase'.csv"
            }
        }
        // CmdStan multi-chain naming: output_1.csv, output_2.csv, ...
    }
    // === MODE 2: Parallel via background processes ================
    else if "`parallel'" != "" & `chains' > 1 {
        if `threads' > 1 {
            if "`verbose'" != "" di as text "  Sampling `chains' chains in parallel (`threads' threads each, `warmup' warmup + `iterations' draws)..."
        }
        else {
            if "`verbose'" != "" di as text "  Sampling `chains' chains in parallel (`warmup' warmup + `iterations' draws)..."
        }

        if "`c(os)'" == "Windows" {
            local make_paths_w = subinstr("`make_paths'", "/", "\", .)
            local wdir_w = subinstr("`wdir'", "/", "\", .)
            local exe_w = subinstr("`exe'", "/", "\", .)
            local datapath_w = subinstr("`datapath'", "/", "\", .)
            // Build batch script that launches all chains then polls for completion
            tempname batfh
            local batfile "`wdir'/run_chains.bat"
            capture file close `batfh'
            file open `batfh' using "`batfile'", write replace
            file write `batfh' "@echo off" _n
            file write `batfh' `"set "PATH=`make_paths_w';%PATH%""' _n
            if `threads' > 1 {
                file write `batfh' `"set "STAN_NUM_THREADS=`threads'""' _n
            }
            forvalues c = 1/`chains' {
                local outfile_w = subinstr("`outbase'_`c'.csv", "/", "\", .)
                local logfile_w = subinstr("`wdir'/chain`c'.log", "/", "\", .)
                file write `batfh' `"start "" /b cmd /c ""`exe_w'" id=`c' `sample_args' random seed=`seed' data file="`datapath_w'" output file="`outfile_w'" > "`logfile_w'" 2>&1""' _n
            }
            // Poll until all CmdStan processes finish
            file write `batfh' ":wait_loop" _n
            file write `batfh' "timeout /t 2 /nobreak >nul 2>&1" _n
            local exe_name = substr("`exe_w'", strrpos("`exe_w'", "\") + 1, .)
            file write `batfh' `"tasklist /FI "IMAGENAME eq `exe_name'" 2>NUL | find /I "`exe_name'" >NUL"' _n
            file write `batfh' "if %ERRORLEVEL%==0 goto wait_loop" _n
            // Extra delay for file system flush
            file write `batfh' "timeout /t 2 /nobreak >nul 2>&1" _n
            file close `batfh'
            if "`verbose'" == "" {
                shell "`batfile'" > "`wdir_w'\parallel.log" 2>&1
            }
            else {
                shell "`batfile'"
            }
        }
        else {
            // Unix/macOS: background all chains, then wait
            local thread_prefix ""
            if `threads' > 1 {
                local thread_prefix "STAN_NUM_THREADS=`threads' "
            }
            local shellcmd ""
            forvalues c = 1/`chains' {
                local shellcmd `"`shellcmd' `thread_prefix'"`exe'" id=`c' `sample_args' random seed=`seed' data file="`datapath'" output file="`outbase'_`c'.csv" > "`wdir'/chain`c'.log" 2>&1 &"'
            }
            local shellcmd `"`shellcmd' wait"'
            shell `shellcmd'
        }
    }
    // === MODE 3: Sequential (default) ============================
    else {
        if "`verbose'" != "" di as text "  Sampling `chains' chains (`warmup' warmup + `iterations' draws)..."

        if "`c(os)'" == "Windows" {
            local make_paths_w = subinstr("`make_paths'", "/", "\", .)
            local wdir_w = subinstr("`wdir'", "/", "\", .)
            forvalues c = 1/`chains' {
                if "`verbose'" != "" di as text "  Chain `c'/`chains'..."
                if "`verbose'" == "" {
                    shell (set "PATH=`make_paths_w';%PATH%" & "`exe'" id=`c' `sample_args' random seed=`seed' data file="`datapath'" output file="`outbase'_`c'.csv") > "`wdir_w'\chain`c'.log" 2>&1
                }
                else {
                    shell set "PATH=`make_paths_w';%PATH%" & "`exe'" id=`c' `sample_args' random seed=`seed' data file="`datapath'" output file="`outbase'_`c'.csv"
                }
            }
        }
        else {
            forvalues c = 1/`chains' {
                if "`verbose'" != "" di as text "  Chain `c'/`chains'..."
                if "`verbose'" == "" {
                    shell "`exe'" id=`c' `sample_args' random seed=`seed' data file="`datapath'" output file="`outbase'_`c'.csv" > "`wdir'/chain`c'.log" 2>&1
                }
                else {
                    shell "`exe'" id=`c' `sample_args' random seed=`seed' data file="`datapath'" output file="`outbase'_`c'.csv"
                }
            }
        }
    }

    // Verify chain output files
    local missing_chains 0
    forvalues c = 1/`chains' {
        capture confirm file "`outbase'_`c'.csv"
        if _rc != 0 {
            capture confirm file "`outbase'-`c'.csv"
            if _rc == 0 {
                capture copy "`outbase'-`c'.csv" "`outbase'_`c'.csv", replace
            }
            else {
                local missing_chains = `missing_chains' + 1
                di as error "  Chain `c' failed -- output not found."
            }
        }
    }
    if `missing_chains' == `chains' {
        di as error "Sampling failed -- no output files found."
        // Show CmdStan error log for diagnosis
        capture confirm file "`wdir'/chain1.log"
        if _rc == 0 {
            di as error "  CmdStan log (chain 1):"
            type "`wdir'/chain1.log"
        }
        else {
            capture confirm file "`wdir'/sampling.log"
            if _rc == 0 {
                di as error "  CmdStan log:"
                type "`wdir'/sampling.log"
            }
        }
        exit 198
    }
    if `missing_chains' > 0 {
        local chains = `chains' - `missing_chains'
        local total_draws = `chains' * `iterations'
        di as text "  WARNING: `missing_chains' chain(s) failed. Using `chains' chain(s)."
    }

    di as text "  Sampling complete."

    // --- Parse output & compute diagnostics ----------------------
    if "`verbose'" != "" di as text "  Computing summaries..."

    tempfile respath
    mata: _bhmc3_parse_output("`outbase'", `chains', "`respath'",     ///
        "`family'", "`depvar'", "`predictors'", "`groupvar'",        ///
        `clevel', "`hpd'", `iterations', "`het_vars'", "`sel_vars'")

    // --- Display -------------------------------------------------
    _bhmc3_display "`respath'" "`family'" "`depvar'" `N'              ///
        `chains' `iterations' `warmup' "`hpd'" `clevel' `seed'

    // Store for subcommands
    capture copy "`respath'" "__bhmc3_results.csv", replace
    global BHMC3_RESULTS "__bhmc3_results.csv"
    // Store chain output base for trace/ac/density
    global BHMC3_OUTBASE "`outbase'"
    global BHMC3_CHAINS "`chains'"
    global BHMC3_FAMILY "`family'"
    global BHMC3_DEPVAR "`depvar'"
    global BHMC3_PREDS  "`predictors'"

    // Save draws if requested
    if "`saving'" != "" {
        forvalues c = 1/`chains' {
            capture copy "`outbase'_`c'.csv" "`saving'_chain`c'.csv", replace
        }
        di as text "  Draws saved to `saving'_chain*.csv"
    }
end


// =================================================================
//  DISPLAY
// =================================================================

program define _bhmc3_display, eclass
    args respath family depvar N chains iter warmup hpd clevel seed

    local total_draws = `chains' * `iter'

    preserve
    qui import delimited using "`respath'", clear stringcols(1)
    local np = _N

    // Get max R-hat and ESS range for header
    local maxrhat = .
    local minESS = .
    local maxESS = .
    capture confirm variable rhat
    if _rc == 0 {
        qui sum rhat
        if r(N) > 0 local maxrhat = r(max)
    }
    capture confirm variable ess
    if _rc == 0 {
        qui sum ess
        if r(N) > 0 {
            local minESS = r(min)
            local maxESS = r(max)
        }
    }

    // --- Header block ------------------------------------------------
    local famu = proper("`family'")
    local cilab = cond("`hpd'"=="hpd", "HPD", "Equal-tailed")
    local opc = `iter'

    di as text ""
    di as text "{hline 100}"
    di as text " Bayesian `famu' regression"                          ///
       _col(70) as text "MCMC draws  = " as result %10.0fc `total_draws'
    di as text " Sampler: NUTS (CmdStan HMC)"                        ///
       _col(70) as text "Num. of obs = " as result %10.0fc `N'
    di as text " Num. of chains = " as result `chains'                ///
       _col(70) as text "Draws/chain = " as result %10.0fc `opc'
    di as text ""
    di as text " Warmup         = " as result %6.0fc `warmup'         ///
       _col(70) as text "Seed        = " as result %10.0f `seed'
    di as text " Min ESS        = " as result %6.0f `minESS'          ///
       _col(70) as text "Max ESS     = " as result %10.0f `maxESS'
    if !missing(`maxrhat') {
        di as text " Max R-hat      = " as result %6.4f `maxrhat'
    }
    else {
        di as text " Max R-hat      = " as result "     ."
    }
    di as text "{hline 100}"

    // --- Column headers ----------------------------------------------
    di as text _col(26) "{c |}" _col(71) as text "`cilab'"
    di as text %25s " " "{c |}" as text                               ///
       %10s "Mean" " " %10s "Std. dev." " "                          ///
       %9s "MCSE" " " %10s "Median"                                  ///
       "  [" "`clevel'%" " cred. interval]"
    di as text "{hline 25}{c +}{hline 74}"

    tempname b V
    mat `b' = J(1, `np', 0)
    mat `V' = J(`np', `np', 0)
    local cnames ""

    // --- Parse equation:variable for grouping ------------------------
    local prev_eq ""
    forvalues i = 1/`np' {
        local pn   = param[`i']
        local mn   = mean[`i']
        local sd   = sd[`i']
        local mc   = mcse[`i']
        local med  = median[`i']
        local lo   = ci_lo[`i']
        local hi   = ci_hi[`i']

        // Build equation:variable name
        local pn_mat "`pn'"
        local cur_eq ""
        local cur_var "`pn'"
        local dotpos = strpos("`pn'", ".")
        if `dotpos' > 0 {
            local cur_eq  = substr("`pn'", 1, `dotpos'-1)
            local cur_var = substr("`pn'", `dotpos'+1, .)
            local pn_mat "`cur_eq':`cur_var'"
        }

        // Equation separator line when equation changes
        if "`cur_eq'" != "`prev_eq'" & "`prev_eq'" != "" {
            di as text "{hline 25}{c +}{hline 74}"
        }
        local prev_eq "`cur_eq'"

        // Format numbers
        if missing(`mn') {
            local f1 "         ."
            local f2 "         ."
            local f3 "        ."
            local f4 "         ."
            local f5 "         ."
            local f6 "         ."
        }
        else {
            local f1 : di %10.5f `mn'
            local f2 : di %10.5f `sd'
            local f3 : di %9.5f  `mc'
            local f4 : di %10.5f `med'
            local f5 : di %10.4f `lo'
            local f6 : di %10.4f `hi'
        }

        // Display name: {eq:var} for Stata-style
        local dn = substr("`pn_mat'", 1, 24)
        if strpos("`pn_mat'", ":") > 0 local dn = "{" + "`pn_mat'" + "}"

        di as text %24s "`dn'" " {c |}" as result                    ///
           " `f1' `f2' `f3' `f4'" "  `f5'" "  `f6'"

        if !missing(`mn') mat `b'[1, `i'] = `mn'
        if !missing(`sd') mat `V'[`i', `i'] = `sd'^2
        local cnames "`cnames' `pn_mat'"
    }

    di as text "{hline 25}{c +}{hline 74}"
    di as text ""

    mat colnames `b' = `cnames'
    mat colnames `V' = `cnames'
    mat rownames `V' = `cnames'
    ereturn post `b' `V', obs(`N')
    ereturn local cmd "bayeshmc"
    ereturn local family "`family'"
    ereturn local depvar "`depvar'"
    ereturn scalar chains = `chains'
    ereturn scalar mcmc_size = `total_draws'

    restore
end


// =================================================================
//  SUBCOMMANDS
// =================================================================

// --- bhmc_setup --------------------------------------------------
program define _bhmc3_setup
    args path

    if "`path'" != "" {
        global CMDSTAN_HOME "`path'"
        di as text "CmdStan path set: `path'"
    }
    else {
        // Auto-detect
        mata: st_local("found", _bhmc3_find_cmdstan())
        if "`found'" != "" {
            global CMDSTAN_HOME "`found'"
            di as text "CmdStan found: `found'"
        }
        else {
            di as error "CmdStan not found. Specify: bayeshmc, setup path(/path/to/cmdstan)"
            exit 198
        }
    }

    // Verify
    capture confirm file "$CMDSTAN_HOME/makefile"
    if _rc == 0 {
        di as text "  makefile:   OK"
    }
    else {
        di as error "  makefile not found in $CMDSTAN_HOME"
    }
    capture confirm file "$CMDSTAN_HOME/bin/stanc"
    if _rc == 0 {
        di as text "  stanc:      OK"
    }
    else {
        capture confirm file "$CMDSTAN_HOME/bin/stanc.exe"
        if _rc == 0 {
            di as text "  stanc.exe:  OK"
        }
        else {
            di as error "  stanc not found -- may need to build CmdStan first"
        }
    }
end

// --- summary -----------------------------------------------------
program define _bhmc3_summary
    capture confirm file "$BHMC3_RESULTS"
    if _rc != 0 {
        di as error "No results. Run bayeshmc first."
        exit 198
    }
    preserve
    qui import delimited using "$BHMC3_RESULTS", clear
    list param mean sd mcse median ci_lo ci_hi, sep(0) noobs
    restore
end

// --- ess ---------------------------------------------------------
program define _bhmc3_ess
    capture confirm file "$BHMC3_RESULTS"
    if _rc != 0 {
        di as error "No results. Run bayeshmc first."
        exit 198
    }
    preserve
    qui import delimited using "$BHMC3_RESULTS", clear
    list param ess rhat, sep(0) noobs
    restore
end

// --- trace -------------------------------------------------------
program define _bhmc3_trace
    syntax [, SAVing(string) PARAMeters(string)]

    if "$BHMC3_OUTBASE" == "" {
        di as error "No results. Run bayeshmc first."
        exit 198
    }

    // Get parameter mapping (display name -> stan name)
    preserve
    tempfile parmap
    qui import delimited using "$BHMC3_RESULTS", clear
    if "`parameters'" == "" {
        // Default: first 4 parameters
        local nplt = min(4, _N)
        local parameters ""
        local stan_pars ""
        forvalues i = 1/`nplt' {
            local p = param[`i']
            local s = stan_name[`i']
            local parameters "`parameters' `p'"
            local stan_pars "`stan_pars' `s'"
        }
    }
    else {
        // Map user-specified display names to stan names
        local stan_pars ""
        foreach p of local parameters {
            local found = 0
            forvalues i = 1/`=_N' {
                if param[`i'] == "`p'" | stan_name[`i'] == "`p'" {
                    local s = stan_name[`i']
                    local stan_pars "`stan_pars' `s'"
                    local found = 1
                    continue, break
                }
            }
            if !`found' local stan_pars "`stan_pars' `p'"
        }
    }
    drop _all

    // Load draws
    _bhmc3_load_draws

    // Convert stan parameter names: import delimited strips dots/brackets
    local stan_pars_clean ""
    foreach p of local stan_pars {
        local p_clean = subinstr("`p'", ".", "", .)
        local p_clean = subinstr("`p_clean'", "[", "", .)
        local p_clean = subinstr("`p_clean'", "]", "", .)
        local stan_pars_clean "`stan_pars_clean' `p_clean'"
    }
    local stan_pars "`stan_pars_clean'"

    local nplt : word count `stan_pars'
    if `nplt' == 0 {
        di as error "No parameters to plot"
        restore
        exit 198
    }

    // Create trace plots -- one panel per parameter
    local graphs ""
    local i = 0
    foreach p of local stan_pars {
        local i = `i' + 1
        capture confirm variable `p'
        if _rc != 0 continue
        local dname : word `i' of `parameters'
        local gname "_bhmc_tr`i'"
        twoway line `p' _iter, lwidth(vthin) lcolor(navy%60) ///
            title("`dname'", size(small)) xtitle("") ytitle("") ///
            name(`gname', replace) nodraw
        local graphs "`graphs' `gname'"
    }

    if "`graphs'" == "" {
        di as error "Parameters not found in draws"
        restore
        exit 198
    }

    graph combine `graphs', title("Trace Plots") ///
        cols(1) xsize(7) ysize(`=max(3, `nplt' * 1.5)') ///
        name(_bhmc_trace, replace)

    if "`saving'" != "" {
        graph export "`saving'", replace
        di as text "Trace plot saved to `saving'"
    }
    restore
end

// --- ac (autocorrelation) ----------------------------------------
program define _bhmc3_ac
    syntax [, SAVing(string) PARAMeters(string) LAGs(integer 40)]

    if "$BHMC3_OUTBASE" == "" {
        di as error "No results. Run bayeshmc first."
        exit 198
    }

    preserve
    qui import delimited using "$BHMC3_RESULTS", clear
    if "`parameters'" == "" {
        // Default: all parameters (up to 6)
        local nplt = min(6, _N)
        local parameters ""
        local stan_pars ""
        forvalues i = 1/`nplt' {
            local parameters "`parameters' `=param[`i']'"
            local stan_pars "`stan_pars' `=stan_name[`i']'"
        }
    }
    else {
        local stan_pars ""
        foreach p of local parameters {
            local sp "`p'"
            forvalues i = 1/`=_N' {
                if param[`i'] == "`p'" | stan_name[`i'] == "`p'" {
                    local sp = stan_name[`i']
                    continue, break
                }
            }
            local stan_pars "`stan_pars' `sp'"
        }
    }
    drop _all
    _bhmc3_load_draws

    // Convert Stan names for Stata variable name compatibility
    local stan_pars_clean ""
    foreach p of local stan_pars {
        local p_clean = subinstr("`p'", ".", "", .)
        local p_clean = subinstr("`p_clean'", "[", "", .)
        local p_clean = subinstr("`p_clean'", "]", "", .)
        local stan_pars_clean "`stan_pars_clean' `p_clean'"
    }
    local stan_pars "`stan_pars_clean'"

    // tsset for ac command
    qui tsset _iter

    // Create AC plots -- one panel per parameter
    local graphs ""
    local i = 0
    local nplt : word count `stan_pars'
    foreach p of local stan_pars {
        local i = `i' + 1
        capture confirm variable `p'
        if _rc != 0 continue
        local dname : word `i' of `parameters'
        local gname "_bhmc_ac`i'"
        ac `p', lags(`lags') title("`dname'", size(small)) ///
            ytitle("") name(`gname', replace) nodraw
        local graphs "`graphs' `gname'"
    }

    if "`graphs'" == "" {
        di as error "Parameters not found in draws"
        restore
        exit 198
    }

    graph combine `graphs', title("Autocorrelation") ///
        cols(2) xsize(7) ysize(`=max(3, ceil(`nplt'/2) * 2)') ///
        name(_bhmc_ac, replace)

    if "`saving'" != "" {
        graph export "`saving'", replace
        di as text "AC plot saved to `saving'"
    }
    restore
end

// --- density -----------------------------------------------------
program define _bhmc3_density
    syntax [, SAVing(string) PARAMeters(string)]

    if "$BHMC3_OUTBASE" == "" {
        di as error "No results. Run bayeshmc first."
        exit 198
    }

    preserve
    qui import delimited using "$BHMC3_RESULTS", clear
    if "`parameters'" == "" {
        local nplt = min(4, _N)
        local parameters ""
        local stan_pars ""
        forvalues i = 1/`nplt' {
            local parameters "`parameters' `=param[`i']'"
            local stan_pars "`stan_pars' `=stan_name[`i']'"
        }
    }
    else {
        local stan_pars ""
        foreach p of local parameters {
            local sp "`p'"
            forvalues i = 1/`=_N' {
                if param[`i'] == "`p'" | stan_name[`i'] == "`p'" {
                    local sp = stan_name[`i']
                    continue, break
                }
            }
            local stan_pars "`stan_pars' `sp'"
        }
    }
    drop _all
    _bhmc3_load_draws

    // Convert Stan names for Stata variable name compatibility
    local stan_pars_clean ""
    foreach p of local stan_pars {
        local p_clean = subinstr("`p'", ".", "", .)
        local p_clean = subinstr("`p_clean'", "[", "", .)
        local p_clean = subinstr("`p_clean'", "]", "", .)
        local stan_pars_clean "`stan_pars_clean' `p_clean'"
    }
    local stan_pars "`stan_pars_clean'"

    // Create density plots -- one panel per parameter
    local graphs ""
    local i = 0
    local nplt : word count `stan_pars'
    foreach p of local stan_pars {
        local i = `i' + 1
        capture confirm variable `p'
        if _rc != 0 continue
        local dname : word `i' of `parameters'
        local gname "_bhmc_dn`i'"
        kdensity `p', title("`dname'", size(small)) ///
            xtitle("") ytitle("") lcolor(navy) ///
            name(`gname', replace) nodraw
        local graphs "`graphs' `gname'"
    }

    if "`graphs'" == "" {
        di as error "Parameters not found in draws"
        restore
        exit 198
    }

    graph combine `graphs', title("Posterior Density") ///
        cols(2) xsize(7) ysize(`=max(3, ceil(`nplt'/2) * 2)') ///
        name(_bhmc_density, replace)

    if "`saving'" != "" {
        graph export "`saving'", replace
        di as text "Density plot saved to `saving'"
    }
    restore
end

// --- histogram ---------------------------------------------------
program define _bhmc3_histogram
    syntax [, SAVing(string) PARAMeters(string) Bins(integer 30)]

    if "$BHMC3_OUTBASE" == "" {
        di as error "No results. Run bayeshmc first."
        exit 198
    }

    preserve
    qui import delimited using "$BHMC3_RESULTS", clear
    if "`parameters'" == "" {
        local nplt = min(6, _N)
        local parameters ""
        local stan_pars ""
        forvalues i = 1/`nplt' {
            local parameters "`parameters' `=param[`i']'"
            local stan_pars "`stan_pars' `=stan_name[`i']'"
        }
    }
    else {
        local stan_pars ""
        foreach p of local parameters {
            local sp "`p'"
            forvalues i = 1/`=_N' {
                if param[`i'] == "`p'" | stan_name[`i'] == "`p'" {
                    local sp = stan_name[`i']
                    continue, break
                }
            }
            local stan_pars "`stan_pars' `sp'"
        }
    }
    drop _all
    _bhmc3_load_draws

    // Convert Stan names for Stata variable name compatibility
    local stan_pars_clean ""
    foreach p of local stan_pars {
        local p_clean = subinstr("`p'", ".", "", .)
        local p_clean = subinstr("`p_clean'", "[", "", .)
        local p_clean = subinstr("`p_clean'", "]", "", .)
        local stan_pars_clean "`stan_pars_clean' `p_clean'"
    }
    local stan_pars "`stan_pars_clean'"

    // Create histogram plots -- one panel per parameter
    local graphs ""
    local i = 0
    local nplt : word count `stan_pars'
    foreach p of local stan_pars {
        local i = `i' + 1
        capture confirm variable `p'
        if _rc != 0 continue
        local dname : word `i' of `parameters'
        local gname "_bhmc_ht`i'"
        histogram `p', bin(`bins') title("`dname'", size(small)) ///
            xtitle("") ytitle("") fcolor(navy%40) lcolor(navy) ///
            name(`gname', replace) nodraw
        local graphs "`graphs' `gname'"
    }

    if "`graphs'" == "" {
        di as error "Parameters not found in draws"
        restore
        exit 198
    }

    graph combine `graphs', title("Posterior Histograms") ///
        cols(2) xsize(7) ysize(`=max(3, ceil(`nplt'/2) * 2)') ///
        name(_bhmc_hist, replace)

    if "`saving'" != "" {
        graph export "`saving'", replace
        di as text "Histogram saved to `saving'"
    }
    restore
end

// --- Helper: load chain draws into dataset -----------------------
program define _bhmc3_load_draws
    local outbase "$BHMC3_OUTBASE"
    local nchains = $BHMC3_CHAINS

    // CmdStan CSVs have # comment lines before the header.
    // We need to find and skip them.
    // Count comment lines in first chain to find where data starts
    tempname fh
    local skip = 0
    file open `fh' using "`outbase'_1.csv", read text
    file read `fh' line
    while r(eof) == 0 {
        if substr("`line'", 1, 1) == "#" {
            local skip = `skip' + 1
        }
        else {
            continue, break
        }
        file read `fh' line
    }
    file close `fh'

    // Import all chains, skipping comment lines
    // The header row is at line skip+1
    tempfile combined
    local has_data = 0
    forvalues c = 1/`nchains' {
        capture confirm file "`outbase'_`c'.csv"
        if _rc != 0 continue

        // Count comment lines for this chain (may differ)
        local skipc = 0
        file open `fh' using "`outbase'_`c'.csv", read text
        file read `fh' line
        while r(eof) == 0 {
            if substr("`line'", 1, 1) == "#" {
                local skipc = `skipc' + 1
            }
            else {
                continue, break
            }
            file read `fh' line
        }
        file close `fh'

        // Import with bindquote(nobind) to handle large files
        qui import delimited using "`outbase'_`c'.csv", ///
            clear rowr(`=`skipc'+2':) varnames(`=`skipc'+1') ///
            encoding("utf-8") bindquote(nobind)

        if `has_data' == 0 {
            qui save "`combined'", replace
            local has_data = 1
        }
        else {
            qui append using "`combined'"
            qui save "`combined'", replace
        }
    }
    if `has_data' {
        qui use "`combined'", clear
    }
    qui gen _iter = _n
end

// --- waic ------------------------------------------------------------
program define _bhmc3_waic
    if "$BHMC3_OUTBASE" == "" {
        di as error "No results. Run bayeshmc first."
        exit 198
    }
    mata: _bhmc3_compute_waic("$BHMC3_OUTBASE", $BHMC3_CHAINS)
end

// --- loo (PSIS-LOO) --------------------------------------------------
program define _bhmc3_loo
    if "$BHMC3_OUTBASE" == "" {
        di as error "No results. Run bayeshmc first."
        exit 198
    }
    mata: _bhmc3_compute_loo("$BHMC3_OUTBASE", $BHMC3_CHAINS)
end

mata:

// --- Find CmdStan ------------------------------------------------
string scalar _bhmc3_find_cmdstan()
{
    string vector paths
    string scalar p, os, home
    real scalar i

    os = st_global("c(os)")
    home = st_global("c(sysdir_personal)")

    if (os == "Windows") {
        home = pathsubsysdir("PERSONAL")
        // Try USERPROFILE
        home = st_global("c(homedir)")  // Stata 18+
        if (home == "") home = "C:/Users"
        paths = ("C:/cmdstan",
                 home + "/.cmdstan/cmdstan-2.36.0",
                 home + "/.cmdstan/cmdstan-2.35.0",
                 home + "/.cmdstan/cmdstan-2.34.1",
                 home + "/.cmdstanr/cmdstan-2.36.0",
                 home + "/.cmdstanr/cmdstan-2.35.0",
                 home + "/cmdstan")
    }
    else {
        paths = ("~/.cmdstan/cmdstan-2.36.0",
                 "~/.cmdstan/cmdstan-2.35.0",
                 "~/.cmdstan/cmdstan-2.34.1",
                 "~/.cmdstanr/cmdstan-2.36.0",
                 "~/.cmdstanr/cmdstan-2.35.0",
                 "~/cmdstan",
                 "/opt/cmdstan",
                 "/usr/local/cmdstan")
    }

    for (i = 1; i <= length(paths); i++) {
        p = paths[i]
        if (fileexists(p + "/makefile") | fileexists(p + "/Makefile")) {
            return(p)
        }
    }
    return("")
}


// --- Hash file contents ------------------------------------------
string scalar _bhmc3_hash(string scalar fpath)
{
    string scalar txt, line
    real scalar fh, h

    fh = fopen(fpath, "r")
    txt = ""
    while ((line = fget(fh)) != J(0, 0, "")) {
        txt = txt + line
    }
    fclose(fh)
    h = hash1(txt, 2^28 - 1)
    return(strofreal(h, "%15.0f"))
}


// =================================================================
//  Stan code generation
// =================================================================

void _bhmc3_write_stan(string scalar fam, string scalar dv,
                       string scalar predstr, string scalar gv,
                       string scalar re, real scalar sd,
                       string scalar cov_type, real scalar n_re,
                       real scalar lkj_eta,
                       string scalar het_str, real scalar n_het,
                       string scalar sel_str, real scalar n_sel,
                       string scalar fam_link, string scalar outpath,
                       string scalar binvar, string scalar covprior)
{
    string scalar code
    string vector preds, re_vars
    real scalar K, fh, has_re

    preds = tokens(predstr)
    K = length(preds)
    re_vars = tokens(re)
    has_re = (gv != "")

    // Dispatch: multilevel models with unstructured covariance
    if (has_re & cov_type == "unstructured" & n_re >= 2) {
        code = _stan_me_unstruct(fam, K, n_re, sd, lkj_eta, binvar, covprior)
    }
    else if (fam == "regress")        code = _stan_regress(K, sd)
    else if (fam == "logit")          code = _stan_logit(K, sd)
    else if (fam == "logistic")       code = _stan_logit(K, sd)
    else if (fam == "probit")         code = _stan_probit(K, sd)
    else if (fam == "cloglog")        code = _stan_cloglog(K, sd)
    else if (fam == "poisson")        code = _stan_poisson(K, sd)
    else if (fam == "nbreg")          code = _stan_nbreg(K, sd)
    else if (fam == "gnbreg")         code = _stan_gnbreg(K, sd)
    else if (fam == "tpoisson")       code = _stan_tpoisson(K, sd)
    else if (fam == "ologit")         code = _stan_ologit(K, sd)
    else if (fam == "oprobit")        code = _stan_oprobit(K, sd)
    else if (fam == "xtreg")          code = _stan_xtreg(K, sd)
    else if (fam == "mixed")          code = _stan_mixed(K, sd)
    else if (fam == "melogit")        code = _stan_melogit(K, sd)
    else if (fam == "xtlogit")        code = _stan_melogit(K, sd)
    else if (fam == "meprobit")       code = _stan_meprobit(K, sd)
    else if (fam == "xtprobit")       code = _stan_meprobit(K, sd)
    else if (fam == "mepoisson")      code = _stan_mepoisson(K, sd)
    else if (fam == "xtpoisson")      code = _stan_mepoisson(K, sd)
    else if (fam == "menbreg")        code = _stan_menbreg(K, sd)
    else if (fam == "xtnbreg")        code = _stan_menbreg(K, sd)
    else if (fam == "meologit")       code = _stan_meologit(K, sd)
    else if (fam == "xtologit")       code = _stan_meologit(K, sd)
    else if (fam == "meoprobit")      code = _stan_meoprobit(K, sd)
    else if (fam == "xtoprobit")      code = _stan_meoprobit(K, sd)
    else if (fam == "mecloglog")      code = _stan_mecloglog(K, sd)
    else if (fam == "meglm")          code = _stan_mixed(K, sd)
    else if (fam == "metobit")        code = _stan_mixed(K, sd)
    else if (fam == "mestreg")        code = _stan_mestreg(K, sd)
    // Heteroscedastic models
    else if (fam == "hetregress")     code = _stan_hetregress(K, n_het, sd)
    else if (fam == "hetprobit")      code = _stan_hetprobit(K, n_het, sd)
    else if (fam == "hetoprobit")     code = _stan_hetoprobit(K, n_het, sd)
    else if (fam == "mehetregress")   code = _stan_mehetregress(K, n_het, sd)
    else if (fam == "mehetoprobit")   code = _stan_mehetoprobit(K, n_het, sd)
    // Selection models
    else if (fam == "heckman")        code = _stan_heckman(K, n_sel, sd)
    else if (fam == "heckprobit")     code = _stan_heckprobit(K, n_sel, sd)
    // Censored/truncated
    else if (fam == "truncreg")       code = _stan_truncreg(K, sd)
    else if (fam == "intreg")         code = _stan_intreg(K, sd)
    // Other
    else if (fam == "streg")          code = _stan_streg(K, sd)
    else if (fam == "zip")            code = _stan_zip(K, sd)
    else if (fam == "zinb")           code = _stan_zinb(K, sd)
    else if (fam == "tobit")          code = _stan_tobit(K, sd)
    else if (fam == "betareg")        code = _stan_betareg(K, sd)
    else if (fam == "glm")            code = _stan_regress(K, sd)
    else if (fam == "mlogit")         code = _stan_mlogit(K, sd)
    else {
        errprintf("bayeshmc: unknown family '%s'\n", fam)
        exit(198)
    }

    // --- Post-process: binomial(n) for any binary model ---
    if (binvar != "") {
        // Replace binary y declaration with count y + trials
        code = subinstr(code, "array[N] int<lower=0,upper=1> y;",
            "array[N] int<lower=0> y;" + _nl() + "  array[N] int<lower=1> trials;")
        // Replace bernoulli_logit with binomial_logit
        code = subinstr(code, "y ~ bernoulli_logit(", "y ~ binomial_logit(trials, ")
        // Replace bernoulli_logit_lpmf
        code = subinstr(code, "bernoulli_logit_lpmf(y[n]|", "binomial_logit_lpmf(y[n]|trials[n],")
        // Replace vectorized bernoulli log-lik
        code = subinstr(code, "log_lik = yr .* eta - log1p_exp(eta);",
            "for (n in 1:N) log_lik[n] = binomial_logit_lpmf(y[n]|trials[n],eta[n]);")
        // Replace bernoulli_lpmf
        code = subinstr(code, "bernoulli_lpmf(y[n]|p)",
            "binomial_lpmf(y[n]|trials[n],p)")
        // Replace manual log-lik: y[n]*log(p) + (1-y[n])*log1m(p)
        code = subinstr(code, "(1-y[n])*log1m(p)",
            "(trials[n]-y[n])*log1m(p)+lchoose(trials[n],y[n])")
        code = subinstr(code, "y[n]*log(p)+(1-y[n])*log1m(p)",
            "y[n]*log(p)+(trials[n]-y[n])*log1m(p)+lchoose(trials[n],y[n])")
    }

    if (fileexists(outpath)) stata("capture erase " + char(34) + outpath + char(34))
    fh = fopen(outpath, "w")
    fput(fh, code)
    fclose(fh)
}

// -- Shorthand ----------------------------------------------------
string scalar _nl()
{
    return(char(10))
}
string scalar _pr(string scalar par, real scalar sd)
{
    return("  " + par + " ~ normal(0, " + strofreal(sd) + ");" + _nl())
}

// -- regress ------------------------------------------------------
string scalar _stan_regress(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; matrix[N,K] X; vector[N] y; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> sigma; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  sigma ~ cauchy(0, 5);" + _nl()
    c = c + "  y ~ normal(alpha + X * beta, sigma);" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] mu = alpha + X * beta;" + _nl()
    c = c + "    log_lik = -0.5*(log(2*pi()) + 2*log(sigma) + square((y - mu)/sigma)); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- logit --------------------------------------------------------
string scalar _stan_logit(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; matrix[N,K] X; array[N] int<lower=0,upper=1> y; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  y ~ bernoulli_logit(alpha + X * beta);" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[K] odds_ratio = exp(beta);" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] eta = alpha + X*beta; vector[N] yr = to_vector(y);" + _nl()
    c = c + "    log_lik = yr .* eta - log1p_exp(eta); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- probit -------------------------------------------------------
string scalar _stan_probit(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; matrix[N,K] X; array[N] int<lower=0,upper=1> y; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  { vector[N] eta = alpha + X * beta;" + _nl()
    c = c + "    for (n in 1:N) {" + _nl()
    c = c + "      if (y[n] == 1) target += std_normal_lcdf(eta[n]);" + _nl()
    c = c + "      else target += std_normal_lccdf(eta[n]);" + _nl()
    c = c + "    }" + _nl()
    c = c + "  }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] eta = alpha + X * beta;" + _nl()
    c = c + "    for (n in 1:N) {" + _nl()
    c = c + "      if (y[n] == 1) log_lik[n] = std_normal_lcdf(eta[n]);" + _nl()
    c = c + "      else log_lik[n] = std_normal_lccdf(eta[n]);" + _nl()
    c = c + "    }" + _nl()
    c = c + "  }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- poisson ------------------------------------------------------
string scalar _stan_poisson(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; matrix[N,K] X; array[N] int<lower=0> y; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  y ~ poisson_log(alpha + X * beta);" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[K] irr = exp(beta);" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] eta = alpha + X*beta; vector[N] yr = to_vector(y);" + _nl()
    c = c + "    log_lik = yr .* eta - exp(eta) - lgamma(yr + 1); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- nbreg --------------------------------------------------------
string scalar _stan_nbreg(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; matrix[N,K] X; array[N] int<lower=0> y; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> phi; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  phi ~ cauchy(0, 5);" + _nl()
    c = c + "  { vector[N] mu = exp(alpha + X*beta); y ~ neg_binomial_2(mu, phi); }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  real lnalpha = -log(phi);" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] mu = exp(alpha + X*beta);" + _nl()
    c = c + "    for (n in 1:N) log_lik[n] = neg_binomial_2_lpmf(y[n]|mu[n],phi); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- ologit -------------------------------------------------------
string scalar _stan_ologit(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=2> J; matrix[N,K] X; array[N] int<lower=1,upper=J> y; }" + _nl()
    c = c + "parameters { vector[K] beta; ordered[J-1] cutpoints; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd)
    c = c + "  cutpoints ~ normal(0, 10);" + _nl()
    c = c + "  y ~ ordered_logistic(X * beta, cutpoints);" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  for (n in 1:N) log_lik[n] = ordered_logistic_lpmf(y[n]|dot_product(X[n],beta),cutpoints);" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- oprobit ------------------------------------------------------
string scalar _stan_oprobit(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=2> J; matrix[N,K] X; array[N] int<lower=1,upper=J> y; }" + _nl()
    c = c + "parameters { vector[K] beta; ordered[J-1] cutpoints; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd)
    c = c + "  cutpoints ~ normal(0, 10);" + _nl()
    c = c + "  y ~ ordered_probit(X * beta, cutpoints);" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  for (n in 1:N) log_lik[n] = ordered_probit_lpmf(y[n]|dot_product(X[n],beta),cutpoints);" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- xtreg (panel RE linear) --------------------------------------
string scalar _stan_xtreg(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=1> J;" + _nl()
    c = c + "  matrix[N,K] X; vector[N] y; array[N] int<lower=1,upper=J> panel; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> sigma; real<lower=0> tau; vector[J] z_u; }" + _nl()
    c = c + "transformed parameters { vector[J] u = tau * z_u; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  sigma ~ cauchy(0,5); tau ~ cauchy(0,2.5); z_u ~ std_normal();" + _nl()
    c = c + "  y ~ normal(alpha + X*beta + u[panel], sigma);" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  real<lower=0> var_U = square(tau);" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] mu = alpha + X*beta + u[panel];" + _nl()
    c = c + "    log_lik = -0.5*(log(2*pi()) + 2*log(sigma) + square((y-mu)/sigma)); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- mixed (multilevel linear, RI) --------------------------------
string scalar _stan_mixed(real scalar K, real scalar sd)
{
    // Random intercept version -- identical structure to xtreg
    // but uses 'group' instead of 'panel'
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=1> J;" + _nl()
    c = c + "  matrix[N,K] X; vector[N] y; array[N] int<lower=1,upper=J> group; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> sigma; real<lower=0> tau; vector[J] z_u; }" + _nl()
    c = c + "transformed parameters { vector[J] u = tau * z_u; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  sigma ~ cauchy(0,5); tau ~ cauchy(0,2.5); z_u ~ std_normal();" + _nl()
    c = c + "  y ~ normal(alpha + X*beta + u[group], sigma);" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  real<lower=0> var_U = square(tau);" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] mu = alpha + X*beta + u[group];" + _nl()
    c = c + "    log_lik = -0.5*(log(2*pi()) + 2*log(sigma) + square((y-mu)/sigma)); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- melogit ------------------------------------------------------
string scalar _stan_melogit(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=1> J;" + _nl()
    c = c + "  matrix[N,K] X; array[N] int<lower=0,upper=1> y; array[N] int<lower=1,upper=J> group; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> tau; vector[J] z_u; }" + _nl()
    c = c + "transformed parameters { vector[J] u = tau * z_u; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  tau ~ cauchy(0,2.5); z_u ~ std_normal();" + _nl()
    c = c + "  y ~ bernoulli_logit(alpha + X*beta + u[group]);" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[K] odds_ratio = exp(beta);" + _nl()
    c = c + "  real<lower=0> var_U = square(tau);" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] eta = alpha + X*beta + u[group]; vector[N] yr = to_vector(y);" + _nl()
    c = c + "    log_lik = yr .* eta - log1p_exp(eta); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- meprobit -----------------------------------------------------
string scalar _stan_meprobit(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=1> J;" + _nl()
    c = c + "  matrix[N,K] X; array[N] int<lower=0,upper=1> y; array[N] int<lower=1,upper=J> group; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> tau; vector[J] z_u; }" + _nl()
    c = c + "transformed parameters { vector[J] u = tau * z_u; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  tau ~ cauchy(0,2.5); z_u ~ std_normal();" + _nl()
    c = c + "  { vector[N] eta = alpha + X*beta + u[group];" + _nl()
    c = c + "    for (n in 1:N) { if (y[n]==1) target += normal_lcdf(eta[n]|0,1);" + _nl()
    c = c + "      else target += normal_lccdf(eta[n]|0,1); } }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  real<lower=0> var_U = square(tau);" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] eta = alpha + X*beta + u[group];" + _nl()
    c = c + "    for (n in 1:N) {" + _nl()
    c = c + "      if (y[n] == 1) log_lik[n] = std_normal_lcdf(eta[n]);" + _nl()
    c = c + "      else log_lik[n] = std_normal_lccdf(eta[n]);" + _nl()
    c = c + "    } }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- mepoisson ----------------------------------------------------
string scalar _stan_mepoisson(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=1> J;" + _nl()
    c = c + "  matrix[N,K] X; array[N] int<lower=0> y; array[N] int<lower=1,upper=J> group; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> tau; vector[J] z_u; }" + _nl()
    c = c + "transformed parameters { vector[J] u = tau * z_u; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  tau ~ cauchy(0,2.5); z_u ~ std_normal();" + _nl()
    c = c + "  y ~ poisson_log(alpha + X*beta + u[group]);" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[K] irr = exp(beta);" + _nl()
    c = c + "  real<lower=0> var_U = square(tau);" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] eta = alpha + X*beta + u[group]; vector[N] yr = to_vector(y);" + _nl()
    c = c + "    log_lik = yr .* eta - exp(eta) - lgamma(yr + 1); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- menbreg ------------------------------------------------------
string scalar _stan_menbreg(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=1> J;" + _nl()
    c = c + "  matrix[N,K] X; array[N] int<lower=0> y; array[N] int<lower=1,upper=J> group; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> phi; real<lower=0> tau; vector[J] z_u; }" + _nl()
    c = c + "transformed parameters { vector[J] u = tau * z_u; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  phi ~ cauchy(0,5); tau ~ cauchy(0,2.5); z_u ~ std_normal();" + _nl()
    c = c + "  { vector[N] mu = exp(alpha + X*beta + u[group]); y ~ neg_binomial_2(mu, phi); }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  real<lower=0> var_U = square(tau);" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] mu = exp(alpha + X*beta + u[group]);" + _nl()
    c = c + "    for (n in 1:N) log_lik[n] = neg_binomial_2_lpmf(y[n]|mu[n],phi); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- meologit (multilevel ordered logit, RI) ----------------------
string scalar _stan_meologit(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=2> J_cat; int<lower=1> J;" + _nl()
    c = c + "  matrix[N,K] X; array[N] int<lower=1,upper=J_cat> y; array[N] int<lower=1,upper=J> group; }" + _nl()
    c = c + "parameters { vector[K] beta; ordered[J_cat-1] cutpoints; real<lower=0> tau; vector[J] z_u; }" + _nl()
    c = c + "transformed parameters { vector[J] u = tau * z_u; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd)
    c = c + "  cutpoints ~ normal(0, 10); tau ~ cauchy(0,2.5); z_u ~ std_normal();" + _nl()
    c = c + "  y ~ ordered_logistic(X * beta + u[group], cutpoints);" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  real<lower=0> var_U = square(tau);" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  for (n in 1:N) log_lik[n] = ordered_logistic_lpmf(y[n]|dot_product(X[n],beta)+u[group[n]],cutpoints);" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- meoprobit (multilevel ordered probit, RI) --------------------
string scalar _stan_meoprobit(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=2> J_cat; int<lower=1> J;" + _nl()
    c = c + "  matrix[N,K] X; array[N] int<lower=1,upper=J_cat> y; array[N] int<lower=1,upper=J> group; }" + _nl()
    c = c + "parameters { vector[K] beta; ordered[J_cat-1] cutpoints; real<lower=0> tau; vector[J] z_u; }" + _nl()
    c = c + "transformed parameters { vector[J] u = tau * z_u; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd)
    c = c + "  cutpoints ~ normal(0, 10); tau ~ cauchy(0,2.5); z_u ~ std_normal();" + _nl()
    c = c + "  y ~ ordered_probit(X * beta + u[group], cutpoints);" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  real<lower=0> var_U = square(tau);" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  for (n in 1:N) log_lik[n] = ordered_probit_lpmf(y[n]|dot_product(X[n],beta)+u[group[n]],cutpoints);" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- mecloglog (multilevel complementary log-log, RI) -------------
string scalar _stan_mecloglog(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=1> J;" + _nl()
    c = c + "  matrix[N,K] X; array[N] int<lower=0,upper=1> y; array[N] int<lower=1,upper=J> group; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> tau; vector[J] z_u; }" + _nl()
    c = c + "transformed parameters { vector[J] u = tau * z_u; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  tau ~ cauchy(0,2.5); z_u ~ std_normal();" + _nl()
    c = c + "  { vector[N] eta = alpha + X*beta + u[group];" + _nl()
    c = c + "    for (n in 1:N) { real p = 1 - exp(-exp(eta[n]));" + _nl()
    c = c + "      target += y[n]*log(p) + (1-y[n])*log1m(p); } }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  real<lower=0> var_U = square(tau);" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] eta = alpha + X*beta + u[group];" + _nl()
    c = c + "    for (n in 1:N) { real p = 1 - exp(-exp(eta[n])); p = fmin(fmax(p,1e-12),1-1e-12);" + _nl()
    c = c + "      log_lik[n] = y[n]*log(p) + (1-y[n])*log1m(p); } }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- mestreg (multilevel Weibull survival, RI) --------------------
string scalar _stan_mestreg(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=1> J;" + _nl()
    c = c + "  matrix[N,K] X; vector<lower=0>[N] t; array[N] int<lower=0,upper=1> event;" + _nl()
    c = c + "  array[N] int<lower=1,upper=J> group; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> shape;" + _nl()
    c = c + "  real<lower=0> tau; vector[J] z_u; }" + _nl()
    c = c + "transformed parameters { vector[J] u = tau * z_u; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  shape ~ gamma(1,1); tau ~ cauchy(0,2.5); z_u ~ std_normal();" + _nl()
    c = c + "  { vector[N] ll = alpha + X*beta + u[group];" + _nl()
    c = c + "    for (n in 1:N) { real sc = exp(-ll[n]/shape);" + _nl()
    c = c + "      if (event[n]==1) target += weibull_lpdf(t[n]|shape,sc);" + _nl()
    c = c + "      else target += weibull_lccdf(t[n]|shape,sc); } }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  real<lower=0> var_U = square(tau);" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] ll = alpha + X*beta + u[group];" + _nl()
    c = c + "    for (n in 1:N) { real sc = exp(-ll[n]/shape);" + _nl()
    c = c + "      if (event[n]==1) log_lik[n] = weibull_lpdf(t[n]|shape,sc);" + _nl()
    c = c + "      else log_lik[n] = weibull_lccdf(t[n]|shape,sc); } }" + _nl()
    c = c + "}" + _nl()
    return(c)
}


// =================================================================
//  Heteroscedastic models
//  Scale equation: log(sigma) = W * gamma  (or scale for probit)
// =================================================================

// -- hetregress (heteroscedastic linear) --------------------------
string scalar _stan_hetregress(real scalar K, real scalar H, real scalar sd)
{
    string scalar c, Hs
    Hs = strofreal(H)
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=1> H;" + _nl()
    c = c + "  matrix[N,K] X; vector[N] y; matrix[N,H] W; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; vector[H] gamma; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd) + _pr("gamma", sd)
    c = c + "  { vector[N] mu = alpha + X*beta; vector[N] sig = exp(W*gamma);" + _nl()
    c = c + "    y ~ normal(mu, sig); }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] mu = alpha + X*beta; vector[N] sig = exp(W*gamma);" + _nl()
    c = c + "    log_lik = -0.5*(log(2*pi()) + 2*log(sig) + square((y-mu)./sig)); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- hetprobit (heteroscedastic probit) ---------------------------
string scalar _stan_hetprobit(real scalar K, real scalar H, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=1> H;" + _nl()
    c = c + "  matrix[N,K] X; array[N] int<lower=0,upper=1> y; matrix[N,H] W; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; vector[H] gamma; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd) + _pr("gamma", sd)
    c = c + "  for (n in 1:N) { real eta = (alpha + dot_product(X[n],beta)) / exp(dot_product(W[n],gamma));" + _nl()
    c = c + "    if (y[n]==1) target += normal_lcdf(eta|0,1);" + _nl()
    c = c + "    else target += normal_lccdf(eta|0,1); }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  for (n in 1:N) { real eta = (alpha + dot_product(X[n],beta)) / exp(dot_product(W[n],gamma));" + _nl()
    c = c + "    if (y[n] == 1) log_lik[n] = std_normal_lcdf(eta);" + _nl()
    c = c + "    else log_lik[n] = std_normal_lccdf(eta); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- hetoprobit (heteroscedastic ordered probit) ------------------
string scalar _stan_hetoprobit(real scalar K, real scalar H, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=2> J; int<lower=1> H;" + _nl()
    c = c + "  matrix[N,K] X; array[N] int<lower=1,upper=J> y; matrix[N,H] W; }" + _nl()
    c = c + "parameters { vector[K] beta; ordered[J-1] cutpoints; vector[H] gamma; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + "  cutpoints ~ normal(0, 10);" + _nl() + _pr("gamma", sd)
    c = c + "  for (n in 1:N) { real s = exp(dot_product(W[n],gamma)); real xb = dot_product(X[n],beta);" + _nl()
    c = c + "    if (y[n]==1) target += normal_lcdf((cutpoints[1]-xb)/s|0,1);" + _nl()
    c = c + "    else if (y[n]==J) target += normal_lccdf((cutpoints[J-1]-xb)/s|0,1);" + _nl()
    c = c + "    else target += log(Phi((cutpoints[y[n]]-xb)/s) - Phi((cutpoints[y[n]-1]-xb)/s)); }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  for (n in 1:N) { real s = exp(dot_product(W[n],gamma)); real xb = dot_product(X[n],beta);" + _nl()
    c = c + "    if (y[n]==1) log_lik[n] = normal_lcdf((cutpoints[1]-xb)/s|0,1);" + _nl()
    c = c + "    else if (y[n]==J) log_lik[n] = normal_lccdf((cutpoints[J-1]-xb)/s|0,1);" + _nl()
    c = c + "    else log_lik[n] = log(Phi((cutpoints[y[n]]-xb)/s) - Phi((cutpoints[y[n]-1]-xb)/s)); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- mehetregress (multilevel heteroscedastic linear, RI) ---------
string scalar _stan_mehetregress(real scalar K, real scalar H, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=1> H; int<lower=1> J;" + _nl()
    c = c + "  matrix[N,K] X; vector[N] y; matrix[N,H] W; array[N] int<lower=1,upper=J> group; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; vector[H] gamma;" + _nl()
    c = c + "  real<lower=0> tau; vector[J] z_u; }" + _nl()
    c = c + "transformed parameters { vector[J] u = tau * z_u; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd) + _pr("gamma", sd)
    c = c + "  tau ~ cauchy(0,2.5); z_u ~ std_normal();" + _nl()
    c = c + "  { vector[N] mu = alpha + X*beta + u[group]; vector[N] sig = exp(W*gamma);" + _nl()
    c = c + "    y ~ normal(mu, sig); }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  real<lower=0> var_U = square(tau);" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] mu = alpha + X*beta + u[group]; vector[N] sig = exp(W*gamma);" + _nl()
    c = c + "    log_lik = -0.5*(log(2*pi()) + 2*log(sig) + square((y-mu)./sig)); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- mehetoprobit (multilevel heteroscedastic ordered probit, RI) --
string scalar _stan_mehetoprobit(real scalar K, real scalar H, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=2> J_cat; int<lower=1> H; int<lower=1> J;" + _nl()
    c = c + "  matrix[N,K] X; array[N] int<lower=1,upper=J_cat> y; matrix[N,H] W;" + _nl()
    c = c + "  array[N] int<lower=1,upper=J> group; }" + _nl()
    c = c + "parameters { vector[K] beta; ordered[J_cat-1] cutpoints; vector[H] gamma;" + _nl()
    c = c + "  real<lower=0> tau; vector[J] z_u; }" + _nl()
    c = c + "transformed parameters { vector[J] u = tau * z_u; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + "  cutpoints ~ normal(0, 10);" + _nl() + _pr("gamma", sd)
    c = c + "  tau ~ cauchy(0,2.5); z_u ~ std_normal();" + _nl()
    c = c + "  for (n in 1:N) { real s = exp(dot_product(W[n],gamma));" + _nl()
    c = c + "    real xb = dot_product(X[n],beta) + u[group[n]];" + _nl()
    c = c + "    if (y[n]==1) target += normal_lcdf((cutpoints[1]-xb)/s|0,1);" + _nl()
    c = c + "    else if (y[n]==J_cat) target += normal_lccdf((cutpoints[J_cat-1]-xb)/s|0,1);" + _nl()
    c = c + "    else target += log(Phi((cutpoints[y[n]]-xb)/s) - Phi((cutpoints[y[n]-1]-xb)/s)); }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  real<lower=0> var_U = square(tau);" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  for (n in 1:N) { real s = exp(dot_product(W[n],gamma));" + _nl()
    c = c + "    real xb = dot_product(X[n],beta) + u[group[n]];" + _nl()
    c = c + "    if (y[n]==1) log_lik[n] = normal_lcdf((cutpoints[1]-xb)/s|0,1);" + _nl()
    c = c + "    else if (y[n]==J_cat) log_lik[n] = normal_lccdf((cutpoints[J_cat-1]-xb)/s|0,1);" + _nl()
    c = c + "    else log_lik[n] = log(Phi((cutpoints[y[n]]-xb)/s) - Phi((cutpoints[y[n]-1]-xb)/s)); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}
//  Uses separation strategy: tau_k ~ half-cauchy, Omega ~ LKJ(eta)
//  Sigma = diag(tau) * Omega * diag(tau)
//  Non-centered parameterization via Cholesky: u = (diag(tau) * L_Omega * z)'
// =================================================================

string scalar _stan_me_unstruct(string scalar fam, real scalar K,
                                real scalar n_re, real scalar sd,
                                real scalar lkj_eta, string scalar binvar,
                                string scalar covprior)
{
    string scalar c, likelihood, gq_extras, eta_str
    eta_str = strofreal(lkj_eta)

    // --- Data block (common) ---
    c = ""
    c = c + "data {" + _nl()
    c = c + "  int<lower=1> N;" + _nl()
    c = c + "  int<lower=1> K;" + _nl()
    c = c + "  int<lower=1> J;  // number of groups" + _nl()
    c = c + "  int<lower=1> R;  // number of random effects (intercept + slopes)" + _nl()
    c = c + "  matrix[N,K] X;" + _nl()

    // Outcome type depends on family
    if (fam == "mixed" | fam == "meglm" | fam == "metobit" | fam == "xtreg") {
        c = c + "  vector[N] y;" + _nl()
    }
    else if (fam == "meologit" | fam == "meoprobit") {
        c = c + "  int<lower=2> J_cat;  // number of ordinal categories" + _nl()
        c = c + "  array[N] int<lower=1,upper=J_cat> y;" + _nl()
    }
    else if (fam == "mepoisson" | fam == "menbreg") {
        c = c + "  array[N] int<lower=0> y;" + _nl()
    }
    else if (fam == "mestreg") {
        c = c + "  vector<lower=0>[N] t;" + _nl()
        c = c + "  array[N] int<lower=0,upper=1> event;" + _nl()
    }
    else {
        // binary: melogit, meprobit, mecloglog
        if (binvar != "") {
            // Binomial: y is count, need trials vector
            c = c + "  array[N] int<lower=0> y;" + _nl()
            c = c + "  array[N] int<lower=1> trials;" + _nl()
        }
        else {
            c = c + "  array[N] int<lower=0,upper=1> y;" + _nl()
        }
    }

    c = c + "  array[N] int<lower=1,upper=J> group;" + _nl()
    c = c + "  matrix[N,R] Z;  // random-effects design matrix" + _nl()
    c = c + "}" + _nl()

    // --- Parameters block (depends on covprior) ---
    c = c + "parameters {" + _nl()
    c = c + "  vector[K] beta;" + _nl()
    if (fam != "meologit" & fam != "meoprobit") {
        c = c + "  real alpha;" + _nl()
    }
    else {
        c = c + "  ordered[J_cat-1] cutpoints;" + _nl()
    }
    if (fam == "mixed" | fam == "meglm" | fam == "metobit" | fam == "xtreg") {
        c = c + "  real<lower=0> sigma;" + _nl()
    }
    if (fam == "menbreg") {
        c = c + "  real<lower=0> phi;" + _nl()
    }
    if (fam == "mestreg") {
        c = c + "  real<lower=0> shape;" + _nl()
    }

    if (covprior == "lkj") {
        c = c + "  vector<lower=0>[R] tau;   // RE standard deviations" + _nl()
        c = c + "  cholesky_factor_corr[R] L_Omega;  // Cholesky of correlation" + _nl()
        c = c + "  matrix[R,J] z_u;  // standardized RE" + _nl()
    }
    else if (covprior == "iw") {
        c = c + "  cov_matrix[R] Sigma_u;  // RE covariance matrix" + _nl()
        c = c + "  matrix[R,J] z_u;  // standardized RE" + _nl()
    }
    else if (covprior == "siw") {
        c = c + "  vector<lower=0>[R] xi;   // scale parameters" + _nl()
        c = c + "  cov_matrix[R] S_raw;  // unscaled IW matrix" + _nl()
        c = c + "  matrix[R,J] z_u;  // standardized RE" + _nl()
    }
    else if (covprior == "huangwand") {
        c = c + "  vector<lower=0>[R] tau;   // RE standard deviations" + _nl()
        c = c + "  cholesky_factor_corr[R] L_Omega;  // Cholesky of correlation" + _nl()
        c = c + "  vector<lower=0>[R] a_tau;   // local shrinkage (mixing)" + _nl()
        c = c + "  matrix[R,J] z_u;  // standardized RE" + _nl()
    }
    else if (covprior == "spherical") {
        c = c + "  vector<lower=0>[R] tau;   // RE standard deviations" + _nl()
        // R*(R-1)/2 angles in (0, pi)
        c = c + "  vector<lower=0,upper=pi()>[R*(R-1)/2] theta;  // spherical angles" + _nl()
        c = c + "  matrix[R,J] z_u;  // standardized RE" + _nl()
    }
    c = c + "}" + _nl()

    // --- Transformed parameters (depends on covprior) ---
    c = c + "transformed parameters {" + _nl()
    c = c + "  matrix[J,R] u;  // actual random effects" + _nl()

    if (covprior == "lkj" | covprior == "huangwand") {
        c = c + "  u = (diag_pre_multiply(tau, L_Omega) * z_u)';  // J x R" + _nl()
    }
    else if (covprior == "spherical") {
        // Build Cholesky factor of correlation matrix from angles
        c = c + "  matrix[R,R] L_sph;" + _nl()
        c = c + "  { int idx = 1;" + _nl()
        c = c + "    for (i in 1:R) {" + _nl()
        c = c + "      real prod_sin = 1.0;" + _nl()
        c = c + "      for (j in 1:i) {" + _nl()
        c = c + "        if (j < i) {" + _nl()
        c = c + "          L_sph[i,j] = prod_sin * cos(theta[idx]);" + _nl()
        c = c + "          prod_sin = prod_sin * sin(theta[idx]);" + _nl()
        c = c + "          idx += 1;" + _nl()
        c = c + "        } else {" + _nl()
        c = c + "          L_sph[i,j] = prod_sin;" + _nl()
        c = c + "        }" + _nl()
        c = c + "      }" + _nl()
        c = c + "      for (j in (i+1):R) L_sph[i,j] = 0;" + _nl()
        c = c + "    }" + _nl()
        c = c + "  }" + _nl()
        c = c + "  u = (diag_pre_multiply(tau, L_sph) * z_u)';  // J x R" + _nl()
    }
    else if (covprior == "iw") {
        c = c + "  { matrix[R,R] L_Sigma = cholesky_decompose(Sigma_u);" + _nl()
        c = c + "    u = (L_Sigma * z_u)'; }" + _nl()
    }
    else if (covprior == "siw") {
        c = c + "  cov_matrix[R] Sigma_u = diag_matrix(xi) * S_raw * diag_matrix(xi);" + _nl()
        c = c + "  { matrix[R,R] L_Sigma = cholesky_decompose(Sigma_u);" + _nl()
        c = c + "    u = (L_Sigma * z_u)'; }" + _nl()
    }
    c = c + "}" + _nl()

    // --- Model block ---
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd)
    if (fam != "meologit" & fam != "meoprobit") {
        c = c + _pr("alpha", sd)
    }
    else {
        c = c + "  cutpoints ~ normal(0, 10);" + _nl()
    }
    if (fam == "mixed" | fam == "meglm" | fam == "metobit" | fam == "xtreg") {
        c = c + "  sigma ~ cauchy(0, 5);" + _nl()
    }
    if (fam == "menbreg") {
        c = c + "  phi ~ cauchy(0, 5);" + _nl()
    }
    if (fam == "mestreg") {
        c = c + "  shape ~ gamma(1, 1);" + _nl()
    }

    // Covariance priors
    if (covprior == "lkj") {
        c = c + "  tau ~ cauchy(0, 2.5);" + _nl()
        c = c + "  L_Omega ~ lkj_corr_cholesky(" + eta_str + ");" + _nl()
        c = c + "  to_vector(z_u) ~ std_normal();" + _nl()
    }
    else if (covprior == "iw") {
        // Inverse-Wishart: Sigma ~ IW(R+1, I) -- weakly informative
        c = c + "  Sigma_u ~ inv_wishart(R + 1, diag_matrix(rep_vector(1.0, R)));" + _nl()
        c = c + "  to_vector(z_u) ~ std_normal();" + _nl()
    }
    else if (covprior == "siw") {
        // Scaled Inverse-Wishart (Gelman & Hill 2006)
        // xi ~ half-cauchy, S_raw ~ IW(R+1, I)
        c = c + "  xi ~ cauchy(0, 2.5);" + _nl()
        c = c + "  S_raw ~ inv_wishart(R + 1, diag_matrix(rep_vector(1.0, R)));" + _nl()
        c = c + "  to_vector(z_u) ~ std_normal();" + _nl()
    }
    else if (covprior == "huangwand") {
        // Huang-Wand (2013): half-t on SDs via scale mixture
        c = c + "  a_tau ~ inv_gamma(0.5, 1.0 / square(2.5));" + _nl()
        c = c + "  tau ~ normal(0, a_tau);" + _nl()
        c = c + "  L_Omega ~ lkj_corr_cholesky(" + eta_str + ");" + _nl()
        c = c + "  to_vector(z_u) ~ std_normal();" + _nl()
    }
    else if (covprior == "spherical") {
        // Spherical decomposition: uniform on angles (implicit from bounds)
        // Jacobian adjustment for the angle-to-correlation transformation
        c = c + "  tau ~ cauchy(0, 2.5);" + _nl()
        c = c + "  // theta ~ uniform(0, pi) -- implicit from bounds" + _nl()
        c = c + "  // Jacobian: log|det(d corr / d theta)| for proper density" + _nl()
        c = c + "  { int idx = 1;" + _nl()
        c = c + "    for (i in 2:R)" + _nl()
        c = c + "      for (j in 1:(i-1)) {" + _nl()
        c = c + "        target += (i - j - 1) * log(sin(theta[idx]));" + _nl()
        c = c + "        idx += 1;" + _nl()
        c = c + "      }" + _nl()
        c = c + "  }" + _nl()
        c = c + "  to_vector(z_u) ~ std_normal();" + _nl()
    }

    // Likelihood
    c = c + "  {" + _nl()
    if (fam != "meologit" & fam != "meoprobit") {
        c = c + "    vector[N] eta;" + _nl()
        c = c + "    for (n in 1:N) eta[n] = alpha + dot_product(X[n], beta) + dot_product(Z[n], u[group[n]]');" + _nl()
    }
    else {
        c = c + "    vector[N] eta;" + _nl()
        c = c + "    for (n in 1:N) eta[n] = dot_product(X[n], beta) + dot_product(Z[n], u[group[n]]');" + _nl()
    }

    if (fam == "mixed" | fam == "meglm" | fam == "metobit" | fam == "xtreg") {
        c = c + "    y ~ normal(eta, sigma);" + _nl()
    }
    else if (fam == "melogit" | fam == "xtlogit") {
        if (binvar != "") {
            c = c + "    y ~ binomial_logit(trials, eta);" + _nl()
        }
        else {
            c = c + "    y ~ bernoulli_logit(eta);" + _nl()
        }
    }
    else if (fam == "meprobit" | fam == "xtprobit") {
        c = c + "    for (n in 1:N) {" + _nl()
        c = c + "      if (y[n]==1) target += normal_lcdf(eta[n]|0,1);" + _nl()
        c = c + "      else target += normal_lccdf(eta[n]|0,1);" + _nl()
        c = c + "    }" + _nl()
    }
    else if (fam == "mecloglog") {
        c = c + "    for (n in 1:N) { real p = 1 - exp(-exp(eta[n]));" + _nl()
        c = c + "      target += y[n]*log(p) + (1-y[n])*log1m(p); }" + _nl()
    }
    else if (fam == "mepoisson" | fam == "xtpoisson") {
        c = c + "    y ~ poisson_log(eta);" + _nl()
    }
    else if (fam == "menbreg" | fam == "xtnbreg") {
        c = c + "    { vector[N] mu = exp(eta); y ~ neg_binomial_2(mu, phi); }" + _nl()
    }
    else if (fam == "meologit" | fam == "xtologit") {
        c = c + "    y ~ ordered_logistic(eta, cutpoints);" + _nl()
    }
    else if (fam == "meoprobit" | fam == "xtoprobit") {
        c = c + "    y ~ ordered_probit(eta, cutpoints);" + _nl()
    }
    else if (fam == "mestreg") {
        c = c + "    for (n in 1:N) { real sc = exp(-eta[n]/shape);" + _nl()
        c = c + "      if (event[n]==1) target += weibull_lpdf(t[n]|shape,sc);" + _nl()
        c = c + "      else target += weibull_lccdf(t[n]|shape,sc); }" + _nl()
    }

    c = c + "  }" + _nl()
    c = c + "}" + _nl()

    // --- Generated quantities ---
    c = c + "generated quantities {" + _nl()

    if (covprior == "lkj" | covprior == "huangwand") {
        c = c + "  corr_matrix[R] Omega = multiply_lower_tri_self_transpose(L_Omega);" + _nl()
        c = c + "  vector[R] var_U = square(tau);" + _nl()
    }
    else if (covprior == "spherical") {
        c = c + "  corr_matrix[R] Omega = multiply_lower_tri_self_transpose(L_sph);" + _nl()
        c = c + "  vector[R] var_U = square(tau);" + _nl()
    }
    else if (covprior == "iw" | covprior == "siw") {
        // Extract tau and Omega from Sigma_u
        c = c + "  vector[R] tau_gq = sqrt(diagonal(Sigma_u));" + _nl()
        c = c + "  corr_matrix[R] Omega;" + _nl()
        c = c + "  vector[R] var_U = diagonal(Sigma_u);" + _nl()
        c = c + "  { vector[R] inv_sd = inv(tau_gq);" + _nl()
        c = c + "    Omega = diag_matrix(inv_sd) * Sigma_u * diag_matrix(inv_sd); }" + _nl()
    }

    // Extract correlations as named scalars
    if (n_re == 2) {
        c = c + "  real rho = Omega[1,2];" + _nl()
    }
    else {
        c = c + "  // Correlation parameters" + _nl()
    }

    // Family-specific extras
    if (fam == "melogit" | fam == "xtlogit") {
        c = c + "  vector[K] odds_ratio = exp(beta);" + _nl()
    }
    if (fam == "mepoisson" | fam == "xtpoisson") {
        c = c + "  vector[K] irr = exp(beta);" + _nl()
    }
    if (fam == "menbreg" | fam == "xtnbreg") {
        c = c + "  real lnalpha = -log(phi);" + _nl()
    }

    // Log-likelihood for LOO/WAIC
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  {" + _nl()
    if (fam != "meologit" & fam != "meoprobit") {
        c = c + "    vector[N] eta;" + _nl()
        c = c + "    for (n in 1:N) eta[n] = alpha + dot_product(X[n], beta) + dot_product(Z[n], u[group[n]]');" + _nl()
    }
    else {
        c = c + "    vector[N] eta;" + _nl()
        c = c + "    for (n in 1:N) eta[n] = dot_product(X[n], beta) + dot_product(Z[n], u[group[n]]');" + _nl()
    }

    if (fam == "mixed" | fam == "meglm" | fam == "metobit" | fam == "xtreg") {
        c = c + "    log_lik = -0.5*(log(2*pi()) + 2*log(sigma) + square((y-eta)/sigma));" + _nl()
    }
    else if (fam == "melogit" | fam == "xtlogit") {
        if (binvar != "") {
            c = c + "    for (n in 1:N) log_lik[n] = binomial_logit_lpmf(y[n]|trials[n],eta[n]);" + _nl()
        }
        else {
            c = c + "    vector[N] yr = to_vector(y);" + _nl()
            c = c + "    log_lik = yr .* eta - log1p_exp(eta);" + _nl()
        }
    }
    else if (fam == "meprobit" | fam == "xtprobit") {
        c = c + "    for (n in 1:N) {" + _nl()
        c = c + "      if (y[n] == 1) log_lik[n] = std_normal_lcdf(eta[n]);" + _nl()
        c = c + "      else log_lik[n] = std_normal_lccdf(eta[n]);" + _nl()
        c = c + "    }" + _nl()
    }
    else if (fam == "mecloglog") {
        c = c + "    for (n in 1:N) { real p = 1-exp(-exp(eta[n])); p=fmin(fmax(p,1e-12),1-1e-12);" + _nl()
        c = c + "      log_lik[n] = y[n]*log(p)+(1-y[n])*log1m(p); }" + _nl()
    }
    else if (fam == "mepoisson" | fam == "xtpoisson") {
        c = c + "    vector[N] yr = to_vector(y);" + _nl()
        c = c + "    log_lik = yr .* eta - exp(eta) - lgamma(yr + 1);" + _nl()
    }
    else if (fam == "menbreg" | fam == "xtnbreg") {
        c = c + "    vector[N] mu = exp(eta);" + _nl()
        c = c + "    for (n in 1:N) log_lik[n] = neg_binomial_2_lpmf(y[n]|mu[n],phi);" + _nl()
    }
    else if (fam == "meologit" | fam == "xtologit") {
        c = c + "    for (n in 1:N) log_lik[n] = ordered_logistic_lpmf(y[n]|eta[n],cutpoints);" + _nl()
    }
    else if (fam == "meoprobit" | fam == "xtoprobit") {
        c = c + "    for (n in 1:N) log_lik[n] = ordered_probit_lpmf(y[n]|eta[n],cutpoints);" + _nl()
    }
    else if (fam == "mestreg") {
        c = c + "    for (n in 1:N) { real sc = exp(-eta[n]/shape);" + _nl()
        c = c + "      if (event[n]==1) log_lik[n] = weibull_lpdf(t[n]|shape,sc);" + _nl()
        c = c + "      else log_lik[n] = weibull_lccdf(t[n]|shape,sc); }" + _nl()
    }

    c = c + "  }" + _nl()
    c = c + "}" + _nl()

    return(c)
}

// -- streg (Weibull survival) -------------------------------------
string scalar _stan_streg(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; matrix[N,K] X;" + _nl()
    c = c + "  vector<lower=0>[N] t; array[N] int<lower=0,upper=1> event; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> shape; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  shape ~ gamma(1, 1);" + _nl()
    c = c + "  { vector[N] ll = alpha + X*beta;" + _nl()
    c = c + "    for (n in 1:N) { real sc = exp(-ll[n]/shape);" + _nl()
    c = c + "      if (event[n]==1) target += weibull_lpdf(t[n]|shape,sc);" + _nl()
    c = c + "      else target += weibull_lccdf(t[n]|shape,sc); } }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] ll = alpha + X*beta;" + _nl()
    c = c + "    for (n in 1:N) { real sc = exp(-ll[n]/shape);" + _nl()
    c = c + "      if (event[n]==1) log_lik[n] = weibull_lpdf(t[n]|shape,sc);" + _nl()
    c = c + "      else log_lik[n] = weibull_lccdf(t[n]|shape,sc); } }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- zip ----------------------------------------------------------
string scalar _stan_zip(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; matrix[N,K] X; array[N] int<lower=0> y; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0,upper=1> theta; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  theta ~ beta(1, 1);" + _nl()
    c = c + "  for (n in 1:N) { real ll = alpha + dot_product(X[n],beta);" + _nl()
    c = c + "    if (y[n]==0) target += log_sum_exp(log(theta), log1m(theta) + poisson_log_lpmf(0|ll));" + _nl()
    c = c + "    else target += log1m(theta) + poisson_log_lpmf(y[n]|ll); }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  for (n in 1:N) { real ll = alpha + dot_product(X[n],beta);" + _nl()
    c = c + "    if (y[n]==0) log_lik[n] = log_sum_exp(log(theta), log1m(theta) + poisson_log_lpmf(0|ll));" + _nl()
    c = c + "    else log_lik[n] = log1m(theta) + poisson_log_lpmf(y[n]|ll); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- zinb ---------------------------------------------------------
string scalar _stan_zinb(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; matrix[N,K] X; array[N] int<lower=0> y; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> phi; real<lower=0,upper=1> theta; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  phi ~ cauchy(0,5); theta ~ beta(1,1);" + _nl()
    c = c + "  for (n in 1:N) { real mu = exp(alpha + dot_product(X[n],beta));" + _nl()
    c = c + "    if (y[n]==0) target += log_sum_exp(log(theta), log1m(theta) + neg_binomial_2_lpmf(0|mu,phi));" + _nl()
    c = c + "    else target += log1m(theta) + neg_binomial_2_lpmf(y[n]|mu,phi); }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  real lnalpha = -log(phi);" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  for (n in 1:N) { real mu = exp(alpha + dot_product(X[n],beta));" + _nl()
    c = c + "    if (y[n]==0) log_lik[n] = log_sum_exp(log(theta), log1m(theta) + neg_binomial_2_lpmf(0|mu,phi));" + _nl()
    c = c + "    else log_lik[n] = log1m(theta) + neg_binomial_2_lpmf(y[n]|mu,phi); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- tobit --------------------------------------------------------
string scalar _stan_tobit(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; matrix[N,K] X; vector[N] y;" + _nl()
    c = c + "  real ll; array[N] int<lower=0,upper=1> cens; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> sigma; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  sigma ~ cauchy(0,5);" + _nl()
    c = c + "  { vector[N] mu = alpha + X*beta;" + _nl()
    c = c + "    for (n in 1:N) { if (cens[n]==1) target += normal_lcdf(ll|mu[n],sigma);" + _nl()
    c = c + "      else target += normal_lpdf(y[n]|mu[n],sigma); } }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] mu = alpha + X*beta;" + _nl()
    c = c + "    for (n in 1:N) { if (cens[n]==1) log_lik[n] = normal_lcdf(ll|mu[n],sigma);" + _nl()
    c = c + "      else log_lik[n] = normal_lpdf(y[n]|mu[n],sigma); } }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- betareg ------------------------------------------------------
string scalar _stan_betareg(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; matrix[N,K] X; vector<lower=0,upper=1>[N] y; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> phi; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  phi ~ cauchy(0,5);" + _nl()
    c = c + "  { vector[N] mu = inv_logit(alpha + X*beta);" + _nl()
    c = c + "    y ~ beta_proportion(mu, phi); }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] mu = inv_logit(alpha + X*beta);" + _nl()
    c = c + "    for (n in 1:N) log_lik[n] = beta_proportion_lpdf(y[n]|mu[n],phi); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- cloglog (complementary log-log) ------------------------------
string scalar _stan_cloglog(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; matrix[N,K] X; array[N] int<lower=0,upper=1> y; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  for (n in 1:N) {" + _nl()
    c = c + "    real eta = alpha + X[n]*beta;" + _nl()
    c = c + "    real log_q = -exp(eta);" + _nl()
    c = c + "    if (y[n] == 1) target += log1m_exp(log_q);" + _nl()
    c = c + "    else target += log_q;" + _nl()
    c = c + "  }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  for (n in 1:N) {" + _nl()
    c = c + "    real eta = alpha + X[n]*beta;" + _nl()
    c = c + "    real log_q = -exp(eta);" + _nl()
    c = c + "    if (y[n] == 1) log_lik[n] = log1m_exp(log_q);" + _nl()
    c = c + "    else log_lik[n] = log_q;" + _nl()
    c = c + "  }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- gnbreg (generalized negative binomial) -----------------------
string scalar _stan_gnbreg(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; matrix[N,K] X; array[N] int<lower=0> y; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> phi; real delta; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  phi ~ cauchy(0,5); delta ~ normal(0,1);" + _nl()
    c = c + "  { vector[N] mu = exp(alpha + X*beta);" + _nl()
    c = c + "    vector[N] alpha_i = exp(delta) * pow(mu, delta);" + _nl()
    c = c + "    for (n in 1:N) y[n] ~ neg_binomial_2(mu[n], 1.0/alpha_i[n]); }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] mu = exp(alpha + X*beta);" + _nl()
    c = c + "    vector[N] alpha_i = exp(delta) * pow(mu, delta);" + _nl()
    c = c + "    for (n in 1:N) log_lik[n] = neg_binomial_2_lpmf(y[n]|mu[n], 1.0/alpha_i[n]); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- tpoisson (truncated Poisson) ---------------------------------
string scalar _stan_tpoisson(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; matrix[N,K] X; array[N] int<lower=1> y; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  { vector[N] eta = alpha + X*beta;" + _nl()
    c = c + "    for (n in 1:N) target += poisson_log_lpmf(y[n]|eta[n]) - log1m_exp(-exp(eta[n])); }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] eta = alpha + X*beta;" + _nl()
    c = c + "    for (n in 1:N) log_lik[n] = poisson_log_lpmf(y[n]|eta[n]) - log1m_exp(-exp(eta[n])); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- truncreg (truncated regression) ------------------------------
string scalar _stan_truncreg(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; matrix[N,K] X; vector[N] y; real ll; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> sigma; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  sigma ~ cauchy(0,5);" + _nl()
    c = c + "  { vector[N] mu = alpha + X*beta;" + _nl()
    c = c + "    for (n in 1:N) y[n] ~ normal(mu[n], sigma) T[ll, ]; }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] mu = alpha + X*beta;" + _nl()
    c = c + "    for (n in 1:N) log_lik[n] = normal_lpdf(y[n]|mu[n],sigma) - normal_lccdf(ll|mu[n],sigma); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- intreg (interval regression) ---------------------------------
string scalar _stan_intreg(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; matrix[N,K] X; vector[N] y_lo; vector[N] y_hi;" + _nl()
    c = c + "  array[N] int<lower=0,upper=3> obs_type; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> sigma; }" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd)
    c = c + "  sigma ~ cauchy(0,5);" + _nl()
    c = c + "  { vector[N] mu = alpha + X*beta;" + _nl()
    c = c + "    for (n in 1:N) {" + _nl()
    c = c + "      if (obs_type[n]==0) target += normal_lpdf(y_lo[n]|mu[n],sigma);" + _nl()
    c = c + "      else if (obs_type[n]==1) target += normal_lcdf(y_hi[n]|mu[n],sigma);" + _nl()
    c = c + "      else if (obs_type[n]==2) target += normal_lccdf(y_lo[n]|mu[n],sigma);" + _nl()
    c = c + "      else target += log(Phi((y_hi[n]-mu[n])/sigma) - Phi((y_lo[n]-mu[n])/sigma)); } }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { vector[N] mu = alpha + X*beta;" + _nl()
    c = c + "    for (n in 1:N) {" + _nl()
    c = c + "      if (obs_type[n]==0) log_lik[n] = normal_lpdf(y_lo[n]|mu[n],sigma);" + _nl()
    c = c + "      else if (obs_type[n]==1) log_lik[n] = normal_lcdf(y_hi[n]|mu[n],sigma);" + _nl()
    c = c + "      else if (obs_type[n]==2) log_lik[n] = normal_lccdf(y_lo[n]|mu[n],sigma);" + _nl()
    c = c + "      else log_lik[n] = log(Phi((y_hi[n]-mu[n])/sigma) - Phi((y_lo[n]-mu[n])/sigma)); } }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- heckman (sample selection) -----------------------------------
string scalar _stan_heckman(real scalar K, real scalar S, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=1> S;" + _nl()
    c = c + "  matrix[N,K] X; vector[N] y; matrix[N,S] W; array[N] int<lower=0,upper=1> selected; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; real<lower=0> sigma;" + _nl()
    c = c + "  vector[S] gamma; real gamma0; real rho_raw; }" + _nl()
    c = c + "transformed parameters {" + _nl()
    c = c + "  real rho = tanh(rho_raw);" + _nl()
    c = c + "}" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd) + _pr("gamma", sd) + _pr("gamma0", sd)
    c = c + "  sigma ~ cauchy(0,5); rho_raw ~ normal(0,2);" + _nl()
    c = c + "  { real r2 = sqrt(1.0 - square(rho));" + _nl()
    c = c + "    vector[N] w = gamma0 + W * gamma;" + _nl()
    c = c + "    vector[N] v = alpha + X * beta;" + _nl()
    c = c + "    for (n in 1:N) {" + _nl()
    c = c + "      if (selected[n]==1) {" + _nl()
    c = c + "        target += normal_lpdf(y[n]|v[n],sigma) + std_normal_lcdf((w[n] + rho*(y[n]-v[n])/sigma) / r2);" + _nl()
    c = c + "      } else target += std_normal_lccdf(w[n]); } }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  real mills_lambda = rho * sigma;" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  { real r2 = sqrt(1.0 - square(rho));" + _nl()
    c = c + "    vector[N] w = gamma0 + W * gamma;" + _nl()
    c = c + "    vector[N] v = alpha + X * beta;" + _nl()
    c = c + "    for (n in 1:N) {" + _nl()
    c = c + "      if (selected[n]==1) {" + _nl()
    c = c + "        log_lik[n] = normal_lpdf(y[n]|v[n],sigma) + std_normal_lcdf((w[n] + rho*(y[n]-v[n])/sigma) / r2);" + _nl()
    c = c + "      } else log_lik[n] = std_normal_lccdf(w[n]); } }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- heckprobit (probit with sample selection) --------------------
string scalar _stan_heckprobit(real scalar K, real scalar S, real scalar sd)
{
    string scalar c
    c = ""
    // Heckprobit: bivariate probit with sample selection.
    // Uses exact conditional decomposition of Phi2:
    //   log Phi2(a,b,r) = log Phi(b) + log Phi((a - r*b)/sqrt(1-r^2))
    //
    // Key optimization: Fisher-z reparameterization of rho.
    //   rho_raw ~ normal(0, 1) on unconstrained scale
    //   rho = tanh(rho_raw) maps (-inf,inf) -> (-1,1)
    // This eliminates the bounded parameter that creates HMC difficulties
    // near rho = +/-1 where sqrt(1-rho^2) -> 0.
    // The tanh transform has a smooth Jacobian and NUTS navigates it easily.
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=1> S;" + _nl()
    c = c + "  matrix[N,K] X; array[N] int<lower=0,upper=1> y; matrix[N,S] W; array[N] int<lower=0,upper=1> selected; }" + _nl()
    c = c + "parameters { vector[K] beta; real alpha; vector[S] gamma; real gamma0;" + _nl()
    c = c + "  real rho_raw; }" + _nl()
    c = c + "transformed parameters {" + _nl()
    c = c + "  real rho = tanh(rho_raw);" + _nl()
    c = c + "}" + _nl()
    c = c + "model {" + _nl()
    c = c + _pr("beta", sd) + _pr("alpha", sd) + _pr("gamma", sd) + _pr("gamma0", sd)
    c = c + "  rho_raw ~ normal(0, 2);" + _nl()
    c = c + "  {" + _nl()
    c = c + "    real r2 = sqrt(1.0 - square(rho));" + _nl()
    c = c + "    vector[N] w = gamma0 + W * gamma;" + _nl()
    c = c + "    vector[N] v = alpha + X * beta;" + _nl()
    c = c + "    for (n in 1:N) {" + _nl()
    c = c + "      if (selected[n] == 0) {" + _nl()
    c = c + "        target += std_normal_lccdf(w[n]);" + _nl()
    c = c + "      } else if (y[n] == 1) {" + _nl()
    c = c + "        target += std_normal_lcdf(w[n]) + std_normal_lcdf((v[n] - rho * w[n]) / r2);" + _nl()
    c = c + "      } else {" + _nl()
    c = c + "        target += std_normal_lcdf(w[n]) + std_normal_lcdf((-v[n] + rho * w[n]) / r2);" + _nl()
    c = c + "      }" + _nl()
    c = c + "    }" + _nl()
    c = c + "  }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  {" + _nl()
    c = c + "    real r2 = sqrt(1.0 - square(rho));" + _nl()
    c = c + "    vector[N] w = gamma0 + W * gamma;" + _nl()
    c = c + "    vector[N] v = alpha + X * beta;" + _nl()
    c = c + "    for (n in 1:N) {" + _nl()
    c = c + "      if (selected[n] == 0) {" + _nl()
    c = c + "        log_lik[n] = std_normal_lccdf(w[n]);" + _nl()
    c = c + "      } else if (y[n] == 1) {" + _nl()
    c = c + "        log_lik[n] = std_normal_lcdf(w[n]) + std_normal_lcdf((v[n] - rho * w[n]) / r2);" + _nl()
    c = c + "      } else {" + _nl()
    c = c + "        log_lik[n] = std_normal_lcdf(w[n]) + std_normal_lcdf((-v[n] + rho * w[n]) / r2);" + _nl()
    c = c + "      }" + _nl()
    c = c + "    }" + _nl()
    c = c + "  }" + _nl()
    c = c + "}" + _nl()
    return(c)
}

// -- mlogit (multinomial logit) -----------------------------------
string scalar _stan_mlogit(real scalar K, real scalar sd)
{
    string scalar c
    c = ""
    c = c + "data { int<lower=1> N; int<lower=1> K; int<lower=2> J;" + _nl()
    c = c + "  matrix[N,K] X; array[N] int<lower=1,upper=J> y; }" + _nl()
    c = c + "parameters { matrix[J-1,K] beta; vector[J-1] alpha; }" + _nl()
    c = c + "model {" + _nl()
    c = c + "  to_vector(beta) ~ normal(0, " + strofreal(sd) + ");" + _nl()
    c = c + "  alpha ~ normal(0, " + strofreal(sd) + ");" + _nl()
    c = c + "  for (n in 1:N) { vector[J] eta; eta[1] = 0;" + _nl()
    c = c + "    for (j in 2:J) eta[j] = alpha[j-1] + dot_product(X[n], beta[j-1]');" + _nl()
    c = c + "    y[n] ~ categorical_logit(eta); }" + _nl()
    c = c + "}" + _nl()
    c = c + "generated quantities {" + _nl()
    c = c + "  vector[N] log_lik;" + _nl()
    c = c + "  for (n in 1:N) { vector[J] eta; eta[1] = 0;" + _nl()
    c = c + "    for (j in 2:J) eta[j] = alpha[j-1] + dot_product(X[n], beta[j-1]');" + _nl()
    c = c + "    log_lik[n] = categorical_logit_lpmf(y[n]|eta); }" + _nl()
    c = c + "}" + _nl()
    return(c)
}


// =================================================================
//  JSON data export
// =================================================================

void _bhmc3_write_json(string scalar fam, string scalar dv,
                       string scalar predstr, string scalar gv,
                       string scalar re_str, string scalar cov_type,
                       real scalar n_re, string scalar het_str,
                       string scalar sel_str, string scalar outpath,
                       real scalar ll_val, real scalar ul_val,
                       string scalar dv_hi, string scalar binvar)
{
    real scalar fh, N, K, J, i, j, R, H, S
    real matrix X, Z, W, Ws
    real colvector y, grp, uv, gc, ucat, re_col, sel_ind, cens_ind, surv_t, surv_d, y_hi, obs_type_v, trials_v
    string vector preds, re_vars, het_vars, sel_vars

    preds = tokens(predstr)
    K = length(preds)
    N = st_nobs()
    X = st_data(., preds)

    re_vars = tokens(re_str)
    het_vars = tokens(het_str)
    sel_vars = tokens(sel_str)
    H = length(het_vars)
    S = length(sel_vars)
    R = n_re

    if (fileexists(outpath)) stata("capture erase " + char(34) + outpath + char(34))
    fh = fopen(outpath, "w")
    fput(fh, "{")
    _jint(fh, "N", N, 1)
    _jint(fh, "K", K, 1)

    // X matrix
    _jmat(fh, "X", X, 1)

    // Outcome -- family-dependent type
    y = st_data(., dv)
    if (fam == "streg" | fam == "mestreg") {
        // Survival models: need _t (time) and _d (event) from stset
        surv_t = st_data(., "_t")
        surv_d = st_data(., "_d")
        _jvec(fh, "t", surv_t, 1)
        _jivec(fh, "event", surv_d, 1)
    }
    else if (fam == "regress" | fam == "xtreg" | fam == "mixed" | fam == "meglm" |
        fam == "metobit" | fam == "tobit" | fam == "betareg" |
        fam == "hetregress" | fam == "mehetregress" |
        fam == "heckman" | fam == "truncreg" | fam == "glm") {
        _jvec(fh, "y", y, 1)
    }
    else if (fam == "intreg") {
        // Interval regression: depvar is y_lo, dv_hi is y_hi
        _jvec(fh, "y_lo", y, 1)
        // y_hi and obs_type
        y_hi = st_data(., dv_hi)
        obs_type_v = J(N, 1, 0)
        for (i = 1; i <= N; i++) {
            if (!missing(y[i]) & !missing(y_hi[i])) {
                if (y[i] == y_hi[i]) obs_type_v[i] = 0      // point
                else obs_type_v[i] = 3                        // interval
            }
            else if (missing(y[i]) & !missing(y_hi[i])) {
                obs_type_v[i] = 1                             // left-censored
                y[i] = y_hi[i]                                // fill y_lo
            }
            else if (!missing(y[i]) & missing(y_hi[i])) {
                obs_type_v[i] = 2                             // right-censored
                y_hi[i] = y[i]                                // fill y_hi
            }
        }
        _jvec(fh, "y_hi", y_hi, 1)
        _jivec(fh, "obs_type", obs_type_v, 1)
    }
    else {
        _jivec(fh, "y", y, 1)
    }

    // --- Family-specific data -------------------------------------

    // Group variable (multilevel)
    if (gv != "") {
        grp = st_data(., gv)
        uv = uniqrows(grp)
        J = rows(uv)
        gc = J(N, 1, .)
        for (i = 1; i <= N; i++) {
            for (j = 1; j <= J; j++) {
                if (grp[i] == uv[j]) {
                    gc[i] = j
                    break
                }
            }
        }
        _jint(fh, "J", J, 1)

        // Ordinal categories for meologit/meoprobit/mehetoprobit
        if (fam == "meologit" | fam == "meoprobit" |
            fam == "xtologit" | fam == "xtoprobit" |
            fam == "mehetoprobit") {
            ucat = uniqrows(y)
            _jint(fh, "J_cat", rows(ucat), 1)
        }

        if (fam == "xtreg") {
            _jivec(fh, "panel", gc, 1)
        }
        else {
            _jivec(fh, "group", gc, 1)
        }

        // Unstructured covariance: write R and Z matrix
        if (cov_type == "unstructured" & R >= 2) {
            _jint(fh, "R", R, 1)
            Z = J(N, R, 1)
            for (j = 1; j <= length(re_vars); j++) {
                re_col = st_data(., re_vars[j])
                Z[., j + 1] = re_col
            }
            if (H > 0) {
                _jmat(fh, "Z", Z, 1)
            }
            else if (binvar != "") {
                _jmat(fh, "Z", Z, 1)
            }
            else {
                _jmat(fh, "Z", Z, 0)
            }
        }

        // Binomial trials variable
        if (binvar != "") {
            trials_v = st_data(., binvar)
            _jivec(fh, "trials", trials_v, 0)
        }

        // Het variables: write H and W matrix
        if (H > 0) {
            _jint(fh, "H", H, 1)
            W = st_data(., het_vars)
            _jmat(fh, "W", W, 0)
        }
        else if (cov_type != "unstructured" | R < 2) {
            fput(fh, "  " + char(34) + "_dummy" + char(34) + ": 0")
        }
    }
    // Ordinal single-level
    else if (fam == "ologit" | fam == "oprobit" | fam == "mlogit") {
        ucat = uniqrows(y)
        J = rows(ucat)
        if (H > 0) {
            _jint(fh, "J", J, 1)
            _jint(fh, "H", H, 1)
            W = st_data(., het_vars)
            _jmat(fh, "W", W, 0)
        }
        else {
            _jint(fh, "J", J, 0)
        }
    }
    else if (fam == "hetoprobit") {
        ucat = uniqrows(y)
        J = rows(ucat)
        _jint(fh, "J", J, 1)
        _jint(fh, "H", H, 1)
        W = st_data(., het_vars)
        _jmat(fh, "W", W, 0)
    }
    // Selection models
    else if (fam == "heckman" | fam == "heckprobit") {
        _jint(fh, "S", S, 1)
        Ws = st_data(., sel_vars)
        _jmat(fh, "W", Ws, 1)
        // Selection indicator: 1 if outcome observed, 0 otherwise
        // Use non-missing y as selection indicator
        sel_ind = (y :!= .)
        _jivec(fh, "selected", sel_ind, 0)
    }
    // Het variables without group
    else if (H > 0) {
        _jint(fh, "H", H, 1)
        W = st_data(., het_vars)
        _jmat(fh, "W", W, 0)
    }
    // Truncated regression needs ll
    else if (fam == "truncreg") {
        _jreal(fh, "ll", ll_val, 0)
    }
    // Tobit: needs ll scalar and cens indicator
    else if (fam == "tobit" | fam == "metobit") {
        _jreal(fh, "ll", ll_val, 1)
        // cens[n] = 1 if y[n] <= ll (left-censored)
        cens_ind = (y :<= ll_val)
        _jivec(fh, "cens", cens_ind, 0)
    }
    else {
        fput(fh, "  " + char(34) + "_dummy" + char(34) + ": 0")
    }

    // Binomial trials for non-grouped models
    if (binvar != "" & gv == "") {
        // Need to backtrack and add comma to previous line
        // Actually, just write it with a preceding comma
        trials_v = st_data(., binvar)
        fput(fh, ",")
        _jivec(fh, "trials", trials_v, 0)
    }

    fput(fh, "}")
    fclose(fh)
}

// JSON helpers
// Format a real number as valid JSON (leading zero for decimals)
string scalar _jnum(real scalar v)
{
    string scalar s
    if (missing(v)) return("0")
    s = strtrim(strofreal(v, "%21.15g"))
    if (substr(s, 1, 1) == ".") s = "0" + s
    else if (substr(s, 1, 2) == "-.") s = "-0" + substr(s, 2, .)
    return(s)
}

void _jint(real scalar fh, string scalar key, real scalar val, real scalar comma)
{
    string scalar c
    c = (comma ? "," : "")
    fput(fh, "  " + char(34) + key + char(34) + ": " + strofreal(val, "%10.0f") + c)
}

void _jreal(real scalar fh, string scalar key, real scalar val, real scalar comma)
{
    string scalar c, sv
    c = (comma ? "," : "")
    sv = _jnum(val)
    fput(fh, "  " + char(34) + key + char(34) + ": " + sv + c)
}

void _jvec(real scalar fh, string scalar key, real colvector v, real scalar comma)
{
    real scalar i, n
    string scalar s, c
    n = rows(v)
    c = (comma ? "," : "")
    s = "  " + char(34) + key + char(34) + ": [" 
    for (i = 1; i <= n; i++) {
        s = s + _jnum(v[i])
        if (i < n) s = s + ","
    }
    fput(fh, s + "]" + c)
}

void _jivec(real scalar fh, string scalar key, real colvector v, real scalar comma)
{
    real scalar i, n
    string scalar s, c
    n = rows(v)
    c = (comma ? "," : "")
    s = "  " + char(34) + key + char(34) + ": [" 
    for (i = 1; i <= n; i++) {
        s = s + strofreal(v[i], "%10.0f")
        if (i < n) s = s + ","
    }
    fput(fh, s + "]" + c)
}

void _jmat(real scalar fh, string scalar key, real matrix M, real scalar comma)
{
    real scalar i, j, nr, nc
    string scalar row, c
    nr = rows(M)
    nc = cols(M)
    c = (comma ? "," : "")
    fput(fh, "  " + char(34) + key + char(34) + ": [")
    for (i = 1; i <= nr; i++) {
        row = "    ["
        for (j = 1; j <= nc; j++) {
            row = row + _jnum(M[i,j])
            if (j < nc) row = row + ","
        }
        row = row + "]"
        if (i < nr) row = row + ","
        fput(fh, row)
    }
    fput(fh, "  ]" + c)
}


// =================================================================
//  Parse CmdStan output + ESS/R-hat
// =================================================================

void _bhmc3_parse_output(string scalar outbase, real scalar nchains,
                         string scalar respath,
                         string scalar fam, string scalar dv,
                         string scalar predstr, string scalar gv,
                         real scalar clevel, string scalar hpd,
                         real scalar expected_iter,
                         string scalar het_str, string scalar sel_str)
{
    string vector preds, colnames, sv, pnames, dnames, het_preds, sel_preds
    string scalar line, cf, cn, pn, idx_s, row, hdr_line, fc, fc2
    string scalar initf, wdir_base, logf, dline, frag
    real scalar ci_lo_p, ci_hi_p, fh, past_hdr, ncols, ndraws, ndpc, n_valid_chains
    real scalar i, j, k, np, bi, ess_v, rhat_v, fout, in_header, dfh, lc
    real scalar max_pidx, ncommas_needed, ncommas, o_r, o_c, rows_before, chain_start
    real matrix all_draws, res, cm, trimmed_draws
    real vector pidx
    real rowvector rv, chain_nrows
    real colvector d, ds
    preds = tokens(predstr)
    het_preds = tokens(het_str)
    sel_preds = tokens(sel_str)

    ci_lo_p = (100 - clevel) / 200
    ci_hi_p = 1 - ci_lo_p

    // -- Read chain CSVs ------------------------------------------
    // Read header from first chain
    // Note: fget() returns max 32767 chars. If the header line is longer
    // (common with random-effect models), it comes in multiple fragments.
    // We concatenate fragments until we hit a line starting with a digit,
    // minus sign, or EOF (which indicates actual data rows).

    cf = outbase + "_1.csv"
    fh = fopen(cf, "r")
    hdr_line = ""
    in_header = 0
    while ((line = fget(fh)) != J(0, 0, "")) {
        if (substr(line, 1, 1) == "#") continue
        if (!in_header) {
            // First non-comment line = start of header
            hdr_line = line
            in_header = 1
        }
        else {
            // Check if this is header continuation or data
            // Data lines start with a digit, minus, or dot (numeric value)
            fc = substr(line, 1, 1)
            if (fc == "-" | fc == "." | (fc >= "0" & fc <= "9")) {
                break  // This is actual data, header is complete
            }
            // Otherwise it's header continuation
            hdr_line = hdr_line + line
        }
    }
    fclose(fh)
    colnames = tokens(subinstr(hdr_line, ",", " "))
    ncols = length(colnames)

    if (ncols == 0) {
        errprintf("Sampling failed: CmdStan produced no output.\n")
        errprintf("The model compiled but the sampler could not initialize.\n")
        // Show init file for diagnosis
        lc = strrpos(outbase, "/")
        if (lc > 0) wdir_base = substr(outbase, 1, lc)
        else wdir_base = "./"
        initf = wdir_base + "init.json"
        if (fileexists(initf)) {
            printf("{err}  Init file (%s):\n", initf)
            dfh = fopen(initf, "r")
            while ((dline = fget(dfh)) != J(0, 0, "")) {
                printf("{err}    %s\n", dline)
            }
            fclose(dfh)
        }
        // Show CmdStan log
        logf = wdir_base + "chain1.log"
        if (fileexists(logf)) {
            printf("{err}  CmdStan log (chain1):\n")
            dfh = fopen(logf, "r")
            lc = 0
            while ((dline = fget(dfh)) != J(0, 0, "")) {
                lc++
                if (lc <= 60) printf("{err}    %s\n", dline)
            }
            fclose(dfh)
        }
        else {
            logf = wdir_base + "sampling.log"
            if (fileexists(logf)) {
                printf("{err}  CmdStan log:\n")
                dfh = fopen(logf, "r")
                lc = 0
                while ((dline = fget(dfh)) != J(0, 0, "")) {
                    lc++
                    if (lc <= 60) printf("{err}    %s\n", dline)
                }
                fclose(dfh)
            }
        }
        exit(198)
    }

    // -- Identify which columns we need (BEFORE reading data) -----
    // This avoids loading thousands of random-effect columns
    pidx = J(1, 0, .)
    pnames = J(1, 0, "")

    for (j = 1; j <= ncols; j++) {
        cn = colnames[j]
        // Skip internals
        if (cn == "lp__" | cn == "accept_stat__" | cn == "stepsize__" |
            cn == "treedepth__" | cn == "n_leapfrog__" | cn == "divergent__" |
            cn == "energy__") continue
        if (substr(cn, 1, 7) == "log_lik") continue
        if (substr(cn, 1, 5) == "y_rep") continue
        if (substr(cn, 1, 3) == "z_u") continue
        if (cn == "u" | substr(cn, 1, 2) == "u." | substr(cn, 1, 2) == "u[") continue
        // Skip L_Omega (Cholesky factor) -- we report Omega instead
        if (substr(cn, 1, 8) == "L_Omega." | substr(cn, 1, 8) == "L_Omega[") continue
        // Skip Sigma_u elements (IW/SIW) -- we report tau_gq/Omega/var_U instead
        if (substr(cn, 1, 8) == "Sigma_u." | substr(cn, 1, 8) == "Sigma_u[") continue
        // Skip S_raw elements (SIW internal)
        if (substr(cn, 1, 6) == "S_raw." | substr(cn, 1, 6) == "S_raw[") continue
        // Skip a_tau (Huang-Wand mixing parameters)
        if (substr(cn, 1, 6) == "a_tau." | substr(cn, 1, 6) == "a_tau[") continue
        // Skip xi (SIW scale parameters)
        if (substr(cn, 1, 3) == "xi." | substr(cn, 1, 3) == "xi[") continue
        // Skip theta (spherical angles) and L_sph (spherical Cholesky)
        if (substr(cn, 1, 6) == "theta." | substr(cn, 1, 6) == "theta[") continue
        if (cn == "theta") continue
        if (substr(cn, 1, 6) == "L_sph." | substr(cn, 1, 6) == "L_sph[") continue
        // Skip Omega diagonal (always 1) and upper triangle (duplicates)
        if (substr(cn, 1, 6) == "Omega." | substr(cn, 1, 6) == "Omega[") {
            idx_s = subinstr(subinstr(subinstr(cn, "Omega[", ""), "Omega.", ""), "]", "")
            idx_s = subinstr(idx_s, ".", ",")
            o_r = strtoreal(substr(idx_s, 1, strpos(idx_s, ",") - 1))
            o_c = strtoreal(substr(idx_s, strpos(idx_s, ",") + 1, .))
            if (o_r <= o_c) continue
        }
        // Skip standardized parameters (probit internal)
        if (substr(cn, 1, 8) == "beta_std" | cn == "alpha_std") continue
        // Skip derived quantities (odds ratios, IRRs) -- transformations of beta
        if (substr(cn, 1, 10) == "odds_ratio" | substr(cn, 1, 3) == "irr") continue
        // Skip rho (redundant with Omega off-diagonal corr_2_1)
        if (cn == "rho" & fam != "heckman" & fam != "heckprobit") continue
        // Skip rho_raw (internal unconstrained parameterization, report rho instead)
        if (cn == "rho_raw") continue
        // Skip lnalpha (internal nbreg transformation)
        if (cn == "lnalpha") continue
        pidx = pidx, j
        pnames = pnames, cn
    }

    np = length(pidx)

    if (np == 0) {
        errprintf("No reportable parameters found in CmdStan output.\n")
        errprintf("CSV columns found: %s\n", invtokens(colnames, ", "))
        exit(198)
    }

    // Read all chains -- extract only needed columns
    // Note: fget() returns max 32767 chars. Data lines may be longer,
    // Read data rows. For models with many parameters (multilevel),
    // each row can exceed fget()'s 32767 char limit.
    // Since we only need early columns (pidx has small indices),
    // we check if we have enough commas; if not, read more.
    max_pidx = max(pidx)
    ncommas_needed = max_pidx  // need at least this many commas to extract all columns

    all_draws = J(0, np, .)
    chain_nrows = J(1, nchains, 0)
    for (k = 1; k <= nchains; k++) {
        cf = outbase + "_" + strofreal(k) + ".csv"
        if (!fileexists(cf)) {
            continue
        }
        rows_before = rows(all_draws)
        fh = fopen(cf, "r")
        while ((line = fget(fh)) != J(0, 0, "")) {
            if (substr(line, 1, 1) == "#") continue
            // Only process lines that start with a numeric value
            fc2 = substr(line, 1, 1)
            if (fc2 != "-" & fc2 != "." & !(fc2 >= "0" & fc2 <= "9")) continue
            // For long lines, we may need to concatenate fget() fragments
            // But we only need enough to cover max_pidx columns
            // Count commas in current fragment
            ncommas = 0
            for (i = 1; i <= strlen(line); i++) {
                if (substr(line, i, 1) == ",") ncommas++
            }
            // If not enough commas, keep reading
            while (ncommas < ncommas_needed) {
                frag = fget(fh)
                if (frag == J(0, 0, "")) break
                line = line + frag
                for (i = strlen(line) - strlen(frag) + 1; i <= strlen(line); i++) {
                    if (substr(line, i, 1) == ",") ncommas++
                }
            }
            // Extract only needed columns by counting commas
            rv = _bhmc3_extract_cols(line, pidx, np)
            if (cols(rv) == np) {
                // Validate: skip rows with missing values (header leak)
                if (!hasmissing(rv)) {
                    all_draws = all_draws \ rv
                }
            }
        }
        fclose(fh)
        chain_nrows[k] = rows(all_draws) - rows_before
    }

    ndraws = rows(all_draws)
    if (ndraws == 0) {
        errprintf("No valid draws found. All chains may have failed.\n")
        exit(198)
    }
    // Use minimum draws per chain for balanced splitting
    // Cap at expected iterations to avoid counting extra/corrupt rows
    // Use min of non-zero chain row counts (skip failed chains)
    ndpc = .
    for (k = 1; k <= nchains; k++) {
        if (chain_nrows[k] > 0) {
            if (ndpc == . | chain_nrows[k] < ndpc) ndpc = chain_nrows[k]
        }
    }
    if (ndpc == . | ndpc == 0) {
        errprintf("No valid draws found. All chains may have failed.\n")
        exit(198)
    }
    if (expected_iter > 0 & ndpc > expected_iter) {
        ndpc = expected_iter
    }

    // Count actual valid chains
    n_valid_chains = 0
    for (k = 1; k <= nchains; k++) {
        if (chain_nrows[k] > 0) n_valid_chains++
    }

    // Trim all_draws to exactly ndpc rows per valid chain
    trimmed_draws = J(0, np, .)
    chain_start = 0
    for (k = 1; k <= nchains; k++) {
        if (chain_nrows[k] > 0 & chain_nrows[k] >= ndpc) {
            trimmed_draws = trimmed_draws \ all_draws[(chain_start+1)..(chain_start+ndpc), .]
        }
        chain_start = chain_start + chain_nrows[k]
    }
    all_draws = trimmed_draws
    ndraws = rows(all_draws)
    nchains = n_valid_chains

    // Build display names
    dnames = J(1, np, "")
    for (i = 1; i <= np; i++) {
        pn = pnames[i]
        if (substr(pn, 1, 5) == "beta[" | substr(pn, 1, 5) == "beta.") {
            idx_s = subinstr(subinstr(subinstr(pn, "beta[", ""), "beta.", ""), "]", "")
            bi = strtoreal(idx_s)
            if (bi >= 1 & bi <= length(preds)) {
                dnames[i] = dv + "." + preds[bi]
            }
            else dnames[i] = pn
        }
        else if (pn == "alpha") dnames[i] = dv + "._cons"
        else if (pn == "sigma") dnames[i] = "sigma._cons"
        else if (pn == "tau") dnames[i] = "sigma_u._cons"
        else if (pn == "tau_gq") dnames[i] = "sigma_u._cons"
        // tau vector (unstructured): tau.1, tau.2, tau[1], tau[2]
        else if (substr(pn, 1, 4) == "tau." | substr(pn, 1, 4) == "tau[") {
            idx_s = subinstr(subinstr(subinstr(pn, "tau[", ""), "tau.", ""), "]", "")
            dnames[i] = "sigma_u" + idx_s + "._cons"
        }
        // tau_gq vector (IW/SIW): tau_gq.1, tau_gq[1]
        else if (substr(pn, 1, 7) == "tau_gq." | substr(pn, 1, 7) == "tau_gq[") {
            idx_s = subinstr(subinstr(subinstr(pn, "tau_gq[", ""), "tau_gq.", ""), "]", "")
            dnames[i] = "sigma_u" + idx_s + "._cons"
        }
        else if (pn == "rho") dnames[i] = "rho._cons"
        // Omega matrix entries
        else if (substr(pn, 1, 6) == "Omega." | substr(pn, 1, 6) == "Omega[") {
            idx_s = subinstr(subinstr(subinstr(pn, "Omega[", ""), "Omega.", ""), "]", "")
            dnames[i] = "corr_" + subinstr(idx_s, ",", "_") + "._cons"
        }
        // var_U vector entries
        else if (substr(pn, 1, 5) == "var_U" & strlen(pn) > 5) {
            idx_s = subinstr(subinstr(subinstr(pn, "var_U[", ""), "var_U.", ""), "]", "")
            dnames[i] = "var_u" + idx_s + "._cons"
        }
        else if (pn == "var_U") dnames[i] = "var_u._cons"
        else if (pn == "phi") dnames[i] = "phi._cons"
        else if (pn == "shape") dnames[i] = "shape._cons"
        else if (pn == "lnalpha") dnames[i] = "lnalpha._cons"
        else if (pn == "theta") dnames[i] = "theta._cons"
        else if (substr(pn, 1, 10) == "odds_ratio" | substr(pn, 1, 3) == "irr") {
            // Skip these from main display -- shown separately if needed
            dnames[i] = pn
        }
        else if (substr(pn, 1, 9) == "cutpoints" | substr(pn, 1, 4) == "cut[" | substr(pn, 1, 4) == "cut.") {
            // Extract index: cutpoints.1 -> 1, cutpoints[2] -> 2
            idx_s = subinstr(subinstr(subinstr(pn, "cutpoints[", ""), "cutpoints.", ""), "]", "")
            if (idx_s != pn) dnames[i] = "cut" + idx_s + "._cons"
            else dnames[i] = pn
        }
        // gamma (scale/selection equation) parameters
        else if (substr(pn, 1, 6) == "gamma[" | substr(pn, 1, 6) == "gamma.") {
            idx_s = subinstr(subinstr(subinstr(pn, "gamma[", ""), "gamma.", ""), "]", "")
            bi = strtoreal(idx_s)
            if (fam == "heckman" | fam == "heckprobit") {
                if (bi >= 1 & bi <= length(sel_preds)) {
                    dnames[i] = "select." + sel_preds[bi]
                }
                else dnames[i] = "select." + pn
            }
            else {
                if (bi >= 1 & bi <= length(het_preds)) {
                    dnames[i] = "lnsigma." + het_preds[bi]
                }
                else dnames[i] = "lnsigma." + pn
            }
        }
        else if (pn == "gamma") {
            if (fam == "heckman" | fam == "heckprobit") dnames[i] = "select.gamma"
            else dnames[i] = "lnsigma.gamma"
        }
        else if (pn == "gamma0") {
            if (fam == "heckman" | fam == "heckprobit") dnames[i] = "select._cons"
            else dnames[i] = "gamma0._cons"
        }
        else if (pn == "mills_lambda") dnames[i] = "mills._cons"
        else dnames[i] = pn
    }

    // -- Summaries ------------------------------------------------
    res = J(np, 8, .)

    for (i = 1; i <= np; i++) {
        d = all_draws[., i]

        res[i, 1] = mean(d)
        res[i, 2] = sqrt(variance(d))

        ds = sort(d, 1)
        res[i, 4] = ds[ceil(ndraws / 2)]
        res[i, 5] = ds[max((1, ceil(ndraws * ci_lo_p)))]
        res[i, 6] = ds[min((ndraws, ceil(ndraws * ci_hi_p)))]

        // ESS + R-hat: chains are now contiguous in trimmed all_draws
        cm = J(ndpc, nchains, .)
        for (k = 1; k <= nchains; k++) {
            cm[., k] = all_draws[((k-1)*ndpc+1)..(k*ndpc), i]
        }
        _bhmc3_ess_rhat(cm, ess_v, rhat_v)
        res[i, 7] = ess_v
        res[i, 8] = rhat_v
        res[i, 3] = res[i, 2] / sqrt(max((ess_v, 1)))
    }

    // -- Write CSV ------------------------------------------------
    if (fileexists(respath)) {
        stata("capture erase " + char(34) + respath + char(34))
    }
    fout = fopen(respath, "w")
    fput(fout, "param,stan_name,mean,sd,mcse,median,ci_lo,ci_hi,ess,rhat")
    for (i = 1; i <= np; i++) {
        row = dnames[i] + "," + pnames[i]
        for (j = 1; j <= 6; j++) row = row + "," + strofreal(res[i,j], "%21.15g")
        row = row + "," + strofreal(res[i,7], "%10.0f")
        row = row + "," + strofreal(res[i,8], "%8.5f")
        fput(fout, row)
    }
    fclose(fout)
}


// --- ESS and R-hat -----------------------------------------------
// Extract specific columns from a CSV line by counting commas.
// This avoids tokenizing the entire line (which may exceed fget's 32KB limit).
// colidx: 1-indexed column positions to extract
// np: number of columns to extract
real rowvector _bhmc3_extract_cols(string scalar line, real rowvector colidx, real scalar np)
{
    real rowvector result
    real scalar col, pos, start, len, ci, maxcol
    string scalar val

    result = J(1, np, .)
    len = strlen(line)
    if (len == 0) return(J(1, 0, .))

    col = 1       // current CSV column (1-indexed)
    start = 1     // start position of current field
    ci = 1        // index into colidx
    maxcol = colidx[np]

    for (pos = 1; pos <= len; pos++) {
        if (substr(line, pos, 1) == "," | pos == len) {
            if (ci <= np && col == colidx[ci]) {
                if (pos == len & substr(line, pos, 1) != ",") {
                    val = substr(line, start, pos - start + 1)
                }
                else {
                    val = substr(line, start, pos - start)
                }
                result[ci] = strtoreal(val)
                ci++
                if (ci > np) break
            }
            col++
            start = pos + 1
            if (col > maxcol) break
        }
    }
    if (ci <= np) return(J(1, 0, .))  // didn't find all columns
    return(result)
}

void _bhmc3_ess_rhat(real matrix chains, real scalar ess, real scalar rhat)
{
    real scalar n, m, i, j, lag, gm, B, W, vh, mlag, tau, ps, half, V_t
    real vector cm, cv
    real colvector x, rho_hat
    real matrix split_chains
    n = rows(chains)
    m = cols(chains)

    // Single chain: use split-chain approach (split into 2 halves)
    if (m == 1) {
        half = floor(n / 2)
        if (half < 10) {
            ess = n
            rhat = .
            return
        }
        split_chains = (chains[1::half, 1], chains[(half+1)::(2*half), 1])
        _bhmc3_ess_rhat(split_chains, ess, rhat)
        return
    }

    // Chain means and variances
    cm = J(1, m, .)
    cv = J(1, m, .)
    for (j = 1; j <= m; j++) {
        cm[j] = mean(chains[., j])
        cv[j] = variance(chains[., j])
    }

    gm = mean(cm')
    B = n * variance(cm')
    W = mean(cv')
    vh = (n - 1) / n * W + B / n

    // R-hat
    if (W > 1e-30) {
        rhat = sqrt(vh / W)
    }
    else {
        rhat = .
        ess = m * n
        return
    }

    // ESS via variogram-based autocorrelation (Vehtari et al. 2021)
    mlag = min((n - 3, floor(10 * log10(max((n, 2))))))

    rho_hat = J(mlag + 1, 1, 0)
    for (lag = 0; lag <= mlag; lag++) {
        V_t = 0
        for (j = 1; j <= m; j++) {
            for (i = 1; i <= n - lag; i++) {
                V_t = V_t + (chains[i + lag, j] - chains[i, j])^2
            }
        }
        V_t = V_t / (m * (n - lag))
        rho_hat[lag + 1] = 1 - V_t / (2 * vh)
    }

    // Sum paired autocorrelations (Geyer's initial positive sequence)
    tau = 1
    for (lag = 1; lag <= floor((mlag - 1) / 2); lag++) {
        ps = rho_hat[2*lag] + rho_hat[2*lag + 1]
        if (ps < 0) break
        tau = tau + 2 * ps
    }
    tau = max((tau, 1))
    ess = min((m * n / tau, m * n))
    ess = max((ess, 1))
}

// --- Ensure make/local has CC=g++ --------------------------------
void _bhmc3_ensure_make_local(string scalar cmdstan)
{
    string scalar fpath, line, contents
    real scalar fh, has_cc

    fpath = cmdstan + "/make/local"
    has_cc = 0
    contents = ""

    if (fileexists(fpath)) {
        fh = fopen(fpath, "r")
        while ((line = fget(fh)) != J(0, 0, "")) {
            contents = contents + line + char(10)
            if (substr(strtrim(line), 1, 3) == "CC=") {
                has_cc = 1
            }
        }
        fclose(fh)
    }

    if (!has_cc) {
        if (fileexists(fpath)) stata("capture erase " + char(34) + fpath + char(34))
        fh = fopen(fpath, "w")
        fput(fh, contents + "CC=g++")
        fclose(fh)
    }
}
void _bhmc3_json_preview(string scalar path)
{
    real scalar fh, i
    string scalar line
    fh = fopen(path, "r")
    for (i = 1; i <= 5; i++) {
        line = fget(fh)
        if (line == J(0, 0, "")) break
        if (strlen(line) > 80) line = substr(line, 1, 77) + "..."
        printf("    %s\n", line)
    }
    fclose(fh)
}


// =================================================================
//  WAIC and LOO-CV
// =================================================================

// --- Extract log_lik matrix from chain CSVs ----------------------
// Returns S x N matrix where S = total draws, N = data points
real matrix _bhmc3_get_loglik(string scalar outbase, real scalar nchains)
{
    real scalar fh, c, ncols, j, n_ll, S_total, s, S_c
    string scalar header, line, tok
    string vector hdr_tok, cols
    real rowvector ll_idx, vals
    real matrix loglik

    // Read header from first chain to find log_lik columns
    fh = fopen(outbase + "_1.csv", "r")
    while ((line = fget(fh)) != J(0,0,"")) {
        if (substr(line, 1, 1) != "#") break
    }
    header = line
    fclose(fh)

    hdr_tok = tokens(header, ",")
    // Count non-comma tokens
    ncols = 0
    for (j = 1; j <= length(hdr_tok); j++) {
        if (hdr_tok[j] != ",") ncols++
    }
    // Rebuild clean column names
    cols = J(1, ncols, "")
    s = 0
    for (j = 1; j <= length(hdr_tok); j++) {
        if (hdr_tok[j] != ",") {
            s++
            cols[s] = strtrim(hdr_tok[j])
        }
    }

    // Find log_lik columns
    n_ll = 0
    for (j = 1; j <= ncols; j++) {
        if (substr(cols[j], 1, 7) == "log_lik") n_ll++
    }
    if (n_ll == 0) {
        errprintf("No log_lik columns found in output.\n")
        return(J(0, 0, .))
    }
    ll_idx = J(1, n_ll, 0)
    s = 0
    for (j = 1; j <= ncols; j++) {
        if (substr(cols[j], 1, 7) == "log_lik") {
            s++
            ll_idx[s] = j
        }
    }

    // Count total draws across chains
    S_total = 0
    for (c = 1; c <= nchains; c++) {
        fh = fopen(outbase + "_" + strofreal(c) + ".csv", "r")
        while ((line = fget(fh)) != J(0,0,"")) {
            if (substr(line, 1, 1) != "#" & strpos(line, "lp__") == 0) {
                S_total++
            }
        }
        fclose(fh)
    }

    // Extract log_lik values
    loglik = J(S_total, n_ll, .)
    s = 0
    for (c = 1; c <= nchains; c++) {
        fh = fopen(outbase + "_" + strofreal(c) + ".csv", "r")
        while ((line = fget(fh)) != J(0,0,"")) {
            if (substr(line, 1, 1) == "#") continue
            if (strpos(line, "lp__") > 0) continue
            s++
            if (s <= S_total) {
                vals = _bhmc3_extract_cols(line, ll_idx, n_ll)
                loglik[s, .] = vals
            }
        }
        fclose(fh)
    }

    return(loglik)
}

// --- WAIC (Watanabe-Akaike IC) -----------------------------------
// WAIC = -2 * (lppd - p_waic)
//   lppd  = sum_n log( mean_s exp(log_lik[s,n]) )
//   p_waic = sum_n var_s(log_lik[s,n])
void _bhmc3_compute_waic(string scalar outbase, real scalar nchains)
{
    real matrix ll
    real scalar N, S, n, lppd, p_waic, waic, se, mx
    real colvector lppd_n, pwaic_n, ll_col

    ll = _bhmc3_get_loglik(outbase, nchains)
    if (rows(ll) == 0) return

    S = rows(ll)
    N = cols(ll)

    lppd_n = J(N, 1, .)
    pwaic_n = J(N, 1, .)

    for (n = 1; n <= N; n++) {
        ll_col = ll[., n]
        // log-sum-exp for numerical stability
        mx = max(ll_col)
        lppd_n[n] = mx + log(mean(exp(ll_col :- mx)))
        // p_waic2: variance of log-lik across draws
        pwaic_n[n] = variance(ll_col)
    }

    lppd = sum(lppd_n)
    p_waic = sum(pwaic_n)
    waic = -2 * (lppd - p_waic)
    se = sqrt(N * variance(-2 * (lppd_n - pwaic_n)))

    printf("\n")
    printf("{hline 50}\n")
    printf("  WAIC (Watanabe-Akaike Information Criterion)\n")
    printf("{hline 50}\n")
    printf("  lppd            = %12.2f\n", lppd)
    printf("  p_waic           = %12.2f\n", p_waic)
    printf("  WAIC             = %12.2f\n", waic)
    printf("  SE(WAIC)         = %12.2f\n", se)
    printf("{hline 50}\n")
    printf("  Computed from %g posterior draws x %g observations\n", S, N)
    printf("{hline 50}\n")

    st_numscalar("r(waic)", waic)
    st_numscalar("r(lppd)", lppd)
    st_numscalar("r(p_waic)", p_waic)
    st_numscalar("r(se_waic)", se)
}

// --- PSIS-LOO (Pareto-smoothed importance sampling LOO-CV) -------
// Following Vehtari, Gelman & Gabry (2017)
void _bhmc3_compute_loo(string scalar outbase, real scalar nchains)
{
    real matrix ll
    real scalar N, S, n, loo_lppd, p_loo, looic, se, n_highk
    real scalar mx, lse, M, tail_start, t, lw_max, lppd_total
    real scalar mean_exc, var_exc
    real colvector loo_n, lppd_n, khat_n, ll_col, lw_col, sorted_lw
    real colvector tail_vals, norm_w

    ll = _bhmc3_get_loglik(outbase, nchains)
    if (rows(ll) == 0) return

    S = rows(ll)
    N = cols(ll)

    loo_n = J(N, 1, .)
    lppd_n = J(N, 1, .)
    khat_n = J(N, 1, .)

    // Tail size for Pareto fit
    M = floor(min((S / 5, 3 * sqrt(S))))
    if (M < 5) M = 5
    tail_start = S - M + 1

    // PSIS weight truncation threshold
    lw_max = 0.75 * log(S)

    for (n = 1; n <= N; n++) {
        ll_col = ll[., n]

        // Raw log importance weights: -log_lik[s,n]
        lw_col = -ll_col

        // Stabilize
        mx = max(lw_col)
        lw_col = lw_col :- mx

        // Sort for tail fitting
        sorted_lw = sort(lw_col, 1)
        tail_vals = sorted_lw[tail_start..S]

        // Estimate GPD shape (k-hat) via moment estimator
        mean_exc = mean(tail_vals :- tail_vals[1])
        var_exc = variance(tail_vals :- tail_vals[1])
        if (var_exc > 0 & mean_exc > 0) {
            khat_n[n] = 0.5 * (1 - mean_exc^2 / var_exc)
        }
        else {
            khat_n[n] = 0
        }

        // Truncate weights (PSIS)
        for (t = 1; t <= S; t++) {
            if (lw_col[t] > lw_max) lw_col[t] = lw_max
        }

        // Normalize on log scale
        lse = log(sum(exp(lw_col)))
        norm_w = exp(lw_col :- lse)

        // LOO log predictive density (stabilized)
        mx = max(ll_col)
        loo_n[n] = mx + log(sum(norm_w :* exp(ll_col :- mx)))

        // Standard lppd_n
        lppd_n[n] = mx + log(mean(exp(ll_col :- mx)))
    }

    loo_lppd = sum(loo_n)
    lppd_total = sum(lppd_n)
    p_loo = lppd_total - loo_lppd
    looic = -2 * loo_lppd
    se = sqrt(N * variance(-2 * loo_n))

    // Count problematic k-hat values
    n_highk = sum(khat_n :> 0.7)

    printf("\n")
    printf("{hline 55}\n")
    printf("  LOO-CV (Pareto-smoothed importance sampling)\n")
    printf("{hline 55}\n")
    printf("  LOO log pred. density = %12.2f\n", loo_lppd)
    printf("  p_loo                 = %12.2f\n", p_loo)
    printf("  LOO-IC                = %12.2f\n", looic)
    printf("  SE(LOO-IC)            = %12.2f\n", se)
    printf("{hline 55}\n")
    printf("  Computed from %g posterior draws x %g observations\n", S, N)
    if (n_highk > 0) {
        printf("  WARNING: %g observations with k-hat > 0.7\n", n_highk)
        printf("  (LOO estimates may be unreliable for these points)\n")
    }
    else {
        printf("  All Pareto k-hat < 0.7 -- estimates reliable\n")
    }
    printf("{hline 55}\n")

    st_numscalar("r(looic)", looic)
    st_numscalar("r(loo_lppd)", loo_lppd)
    st_numscalar("r(p_loo)", p_loo)
    st_numscalar("r(se_looic)", se)
    st_numscalar("r(n_high_khat)", n_highk)
}


// =================================================================
//  Init file generator -- data-driven starting values
// =================================================================
void _bhmc3_write_init(string scalar fam, string scalar dv,
                       string scalar predstr, string scalar outpath)
{
    real scalar fh, K, my, sy, Jm1, jj
    real colvector y
    string vector preds
    string scalar row, cuts

    preds = tokens(predstr)
    K = length(preds)
    y = st_data(., dv)

    // Compute data-driven inits
    my = mean(y)
    sy = sqrt(variance(y))
    if (missing(sy) | sy < 1e-10) sy = 1

    if (fileexists(outpath)) stata("capture erase " + char(34) + outpath + char(34))
    fh = fopen(outpath, "w")
    fput(fh, "{")

    // --- Multinomial logit: beta is matrix[J-1, K], alpha is vector[J-1]
    if (fam == "mlogit") {
        Jm1 = rows(uniqrows(y)) - 1
        // beta: (J-1) x K matrix of zeros
        fput(fh, "  " + char(34) + "beta" + char(34) + ": [")
        row = "    [" + invtokens(J(1, K, "0"), ",") + "]"
        for (jj = 1; jj <= Jm1; jj++) {
            if (jj < Jm1) fput(fh, row + ",")
            else fput(fh, row)
        }
        fput(fh, "  ],")
        // alpha: vector of zeros
        fput(fh, "  " + char(34) + "alpha" + char(34) + ": [" + invtokens(J(1, Jm1, "0"), ",") + "]")
    }
    // --- Ordinal models: cutpoints is ordered vector
    else if (fam == "ologit" | fam == "oprobit" |
             fam == "meologit" | fam == "meoprobit" |
             fam == "xtologit" | fam == "xtoprobit" |
             fam == "hetoprobit" | fam == "mehetoprobit") {
        Jm1 = rows(uniqrows(y)) - 1
        fput(fh, "  " + char(34) + "beta" + char(34) + ": [" + invtokens(J(1, K, "0"), ",") + "],")
        // cutpoints: evenly spaced ordered values
        cuts = ""
        for (jj = 1; jj <= Jm1; jj++) {
            if (jj > 1) cuts = cuts + ","
            cuts = cuts + _jnum(jj - (Jm1 + 1) / 2)
        }
        fput(fh, "  " + char(34) + "cutpoints" + char(34) + ": [" + cuts + "]")
    }
    // --- Continuous outcome models: data-driven alpha and sigma
    else if (fam == "regress" | fam == "tobit" | fam == "truncreg" |
        fam == "intreg" | fam == "hetregress" | fam == "heckman" |
        fam == "xtreg" | fam == "mixed" | fam == "metobit" |
        fam == "mehetregress" | fam == "glm" | fam == "streg" |
        fam == "mestreg") {
        fput(fh, "  " + char(34) + "beta" + char(34) + ": [" + invtokens(J(1, K, "0"), ",") + "],")
        fput(fh, "  " + char(34) + "alpha" + char(34) + ": " + _jnum(my) + ",")
        fput(fh, "  " + char(34) + "sigma" + char(34) + ": " + _jnum(sy))
    }
    // --- Count models: log-link init
    else if (fam == "poisson" | fam == "nbreg" | fam == "gnbreg" |
             fam == "tpoisson" | fam == "mepoisson" | fam == "menbreg") {
        fput(fh, "  " + char(34) + "beta" + char(34) + ": [" + invtokens(J(1, K, "0"), ",") + "],")
        fput(fh, "  " + char(34) + "alpha" + char(34) + ": " + _jnum(log(max((my, 0.1)))))
    }
    // --- Binary/other models: all zeros
    else {
        fput(fh, "  " + char(34) + "beta" + char(34) + ": [" + invtokens(J(1, K, "0"), ",") + "],")
        fput(fh, "  " + char(34) + "alpha" + char(34) + ": 0")
    }

    fput(fh, "}")
    fclose(fh)
}


end
