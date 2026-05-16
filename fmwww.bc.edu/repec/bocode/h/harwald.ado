program define harwald, rclass
    version 15.0
    if "`e(cmd)'" != "harreg" {
        di as err "harwald may only be used after harreg"
        exit 301
    }

    /* `equalok' allows `=' inside the `anything' token so input like
       `harwald x1=0' reaches our parsing code instead of being
       rejected at the syntax line with the unhelpful Stata error
       "=exp not allowed". The bare-mode parser below detects `='
       and redirects users to the supported parens-mode form. */
    syntax [anything(name=coeflist equalok)] [, Level(cilevel) CRITDRAWS(integer 5000) SEED(integer 88741997)]

    if `critdraws' < 1000 local critdraws = 1000
    local lev = `level'/100

    * All internal scalars/matrices live in tempnames so they cannot
    * collide with the user's namespace.
    tempname b V Rmat cvec bR_t VR_t factor_t Fstat_t df2_t pval_t cv_t
    matrix `b' = e(b)
    matrix `V' = e(V)
    local est = lower(e(estimator))

    /* The seed is consumed only by harwald_sim (NW/QS Monte-Carlo
       p/cv path); EWC/EWP use analytic Ftail/invFtail. Reseed only
       when the simulator will run, so EWC/EWP `harwald' leaves the
       user's RNG state untouched. */
    if (`seed' != 0 & inlist("`est'","nw","qs")) {
        quietly set seed `seed'
    }
    local cn : colfullnames `b'
    local k = colsof(`b')

    * Build a normalized parallel list of coefficient names so user
    * input like `1.rep78` resolves to regress's base column
    * `1b.rep78` (which carries a structural zero, matching the
    * regress/test convention). The normalization strips a single
    * `b`, `bn`, or `bo` letter group appearing immediately before
    * a `.` that is preceded by a digit — i.e., factor-base markers
    * `1b.rep78`, `1bn.rep78`, `1bo.rep78` all map to `1.rep78`.
    * Identity on non-factor tokens.
    local cn_norm ""
    foreach name of local cn {
        local nname = ustrregexra("`name'", "([0-9]+)b[no]?\.", "$1.")
        local cn_norm "`cn_norm' `nname'"
    }

    /* Check if input contains parentheses (linear hypothesis syntax) */
    local has_parens = strpos("`coeflist'", "(")

    if `has_parens' > 0 {
        /* Refuse mixed list+parens. Any non-whitespace content before
           the first `(` is a bare-variable list mixed with
           parenthesized expressions; the parens-mode parser below
           only extracts content inside `(...)` and would silently
           drop the leading list portion. */
        local prefix = strtrim(substr("`coeflist'", 1, `has_parens'-1))
        if "`prefix'" != "" {
            di as err "cannot mix bare variable list and parenthesized expressions: `coeflist'"
            di as err `"use either "harwald x1 x2 ..." or "harwald (expr1) (expr2) ..."'"'
            exit 198
        }

        /* Linear hypothesis mode: parse expressions in parentheses */
        local exprs ""
        local rest "`coeflist'"
        local q = 0

        /* Extract all parenthesized expressions */
        while strpos("`rest'", "(") > 0 {
            local start = strpos("`rest'", "(")
            local end = strpos("`rest'", ")")
            if `end' == 0 {
                di as err "unmatched parenthesis in expression"
                exit 198
            }
            /* Validate any text between the previous `)' and this `('
               is whitespace only. Without this check the parser
               silently extracts the next `(...)' group and drops the
               intervening tokens (so `(x1) garbage (x2)' would test
               x1 and x2 and silently ignore `garbage'). */
            local gap = strtrim(substr("`rest'", 1, `start'-1))
            if "`gap'" != "" {
                di as err "stray tokens between parenthesized expressions: `gap'"
                di as err `"use "harwald (expr1) (expr2) ..." without text between groups"'
                exit 198
            }
            local expr = substr("`rest'", `start'+1, `end'-`start'-1)
            if strtrim("`expr'") == "" {
                di as err "empty expression in parentheses"
                exit 198
            }
            local rest = substr("`rest'", `end'+1, .)
            local q = `q' + 1
            local expr`q' "`expr'"
        }
        /* Validate trailing text after the final `)' is whitespace
           only. Same silent-drop pathology as the inter-group gap. */
        local tail = strtrim("`rest'")
        if "`tail'" != "" {
            di as err "stray tokens after final parenthesized expression: `tail'"
            exit 198
        }

        /* Build R matrix and c vector from expressions */
        matrix `Rmat' = J(`q', `k', 0)
        matrix `cvec' = J(`q', 1, 0)
        local testnames ""

        forvalues i = 1/`q' {
            local expr = strtrim("`expr`i''")
            local testnames "`testnames' (`expr')"

            /* The `lhs = rhs' form (e.g., `2*x1 - x2 = 1') is accepted.
               Split on the first `=' if present; process the LHS with
               sign +1 and the RHS with sign -1 (so the test is
               `lhs - rhs = 0'). Reject more than one `=' */
            local eqcount = length("`expr'") - length(subinstr("`expr'", "=", "", .))
            if `eqcount' > 1 {
                di as err "expression contains more than one `=': `expr'"
                exit 198
            }
            local eqpos = strpos("`expr'", "=")
            if `eqpos' > 0 {
                local lhs_str = substr("`expr'", 1, `eqpos'-1)
                local rhs_str = substr("`expr'", `eqpos'+1, .)
                if strtrim("`lhs_str'") == "" | strtrim("`rhs_str'") == "" {
                    di as err "empty side of `=' in expression: `expr'"
                    exit 198
                }
            }
            else {
                local lhs_str "`expr'"
                local rhs_str ""
            }

            /* Process LHS (sign=+1) then RHS (sign=-1). */
            forvalues side = 1/2 {
                if `side' == 1 {
                    local side_expr "`lhs_str'"
                    local side_sign = 1
                }
                else {
                    local side_expr "`rhs_str'"
                    local side_sign = -1
                    if "`side_expr'" == "" continue
                }

                /* Tokenize the expression into +/- separated terms.
                   First protect scientific-notation exponents (1e-3,
                   2.5E+4, ...) with sentinels so the next `-` -> `+-`
                   substitution does not split inside an exponent.
                   The `~M~`/`~P~` strings cannot appear in valid Stata
                   expressions; they are restored after the split. */
                local side_expr = subinstr("`side_expr'", " ", "", .)
                local side_expr = subinstr("`side_expr'", "e-", "e~M~", .)
                local side_expr = subinstr("`side_expr'", "e+", "e~P~", .)
                local side_expr = subinstr("`side_expr'", "E-", "E~M~", .)
                local side_expr = subinstr("`side_expr'", "E+", "E~P~", .)
                local side_expr = subinstr("`side_expr'", "-", "+-", .)

                /* Split by + */
                local terms ""
                local remaining "`side_expr'"
                while "`remaining'" != "" {
                    local pluspos = strpos("`remaining'", "+")
                    if `pluspos' == 0 {
                        if "`remaining'" != "" {
                            local terms "`terms' `remaining'"
                        }
                        local remaining ""
                    }
                    else if `pluspos' == 1 {
                        local remaining = substr("`remaining'", 2, .)
                    }
                    else {
                        local term = substr("`remaining'", 1, `pluspos'-1)
                        local terms "`terms' `term'"
                        local remaining = substr("`remaining'", `pluspos'+1, .)
                    }
                }

                /* Process each term. Restore scientific-notation
                   exponents that were sentinel-protected above. */
                foreach term of local terms {
                    local term = subinstr("`term'", "~M~", "-", .)
                    local term = subinstr("`term'", "~P~", "+", .)
                    local term = strtrim("`term'")
                    if "`term'" == "" continue

                    /* Parse coefficient*variable or just variable or constant */
                    local coef = `side_sign'
                    local varname "`term'"
                    local is_constant = 0

                    /* Check for negative sign */
                    if substr("`term'", 1, 1) == "-" {
                        local coef = -1 * `side_sign'
                        local term = substr("`term'", 2, .)
                        local varname "`term'"
                    }

                    /* Check for explicit coefficient (e.g., 2*x or 0.5*x) */
                    local starpos = strpos("`term'", "*")
                    if `starpos' > 0 {
                        local numpart = substr("`term'", 1, `starpos'-1)
                        local varname = substr("`term'", `starpos'+1, .)
                        local coef = `coef' * real("`numpart'")
                        if missing(`coef') {
                            di as err "invalid coefficient in expression: `numpart'"
                            exit 198
                        }
                    }
                    else {
                        /* Check if the term is a pure number (constant) */
                        local testnum = real("`varname'")
                        if !missing(`testnum') {
                            local is_constant = 1
                        }
                    }

                    /* Reject a literal `.' (missing-value) reaching this
                       point. The constant-detection above maps `.' to
                       testnum=., is_constant stays 0, and the coef-name
                       lookup below would error rc=111 "not found among
                       estimated coefficients" — misleading for a
                       missing-value input. Refuse explicitly. */
                    if "`varname'" == "." {
                        di as err "missing value (.) in restriction expression: `expr'"
                        exit 198
                    }

                    if `is_constant' {
                        /* This is a constant term - add to c vector (move to RHS) */
                        /* If expression has +constant, we test Rb = constant, so c = constant */
                        /* If expression has -constant, we test Rb = -constant */
                        matrix `cvec'[`i', 1] = `cvec'[`i', 1] - `coef' * real("`varname'")
                    }
                    else {
                        /* Find variable position. Direct match against
                           e(b)'s colnames first; on miss, the
                           normalized list so factor inputs like
                           `1.rep78` resolve to base columns
                           `1b.rep78`. */
                        local varname = strtrim("`varname'")
                        local pos : list posof `"`varname'"' in cn
                        if `pos' == 0 {
                            local pos : list posof `"`varname'"' in cn_norm
                        }
                        if `pos' == 0 {
                            di as err "`varname' not found among estimated coefficients"
                            exit 111
                        }

                        /* Add to R matrix */
                        matrix `Rmat'[`i', `pos'] = `Rmat'[`i', `pos'] + `coef'
                    }
                }
            }
        }
        local varlist = strtrim("`testnames'")
    }
    else {
        /* Original syntax: list of variable names */
        local varlist "`coeflist'"
        if "`varlist'" == "" {
            /* Default: test every estimated slope. Skip `_cons',
               and skip factor base levels (`Nb.var', `Nbn.var',
               `Nbo.var') and `_rmcoll' omitted markers (`o.x',
               `oL.x', etc.) — those sit at structurally-zero columns
               of `e(b)' / `e(V)' and adding them to R would zero out
               the corresponding row/col of VR_t, making syminv(VR_t)
               return a g-inverse that hides the degeneracy and
               inflates q. */
            foreach v of local cn {
                if "`v'" == "_cons" continue
                if regexm("`v'", "^o([LFDS][0-9]*)*\.") continue
                if regexm("`v'", "[0-9]+b[no]?\.") continue
                local varlist "`varlist' `v'"
            }
        }

        /* Reject bare equality syntax (e.g., `harwald x1=0',
           `harwald x1=x2'). Bare mode is a list of coefficient names
           and the lookup below treats `x1=0' as a single token,
           failing with the confusing "not found among estimated
           coefficients" error. The parens-mode parser supports
           equality restrictions; redirect users there. */
        if strpos("`varlist'", "=") > 0 {
            di as err "bare equality syntax not supported in this mode"
            di as err `"wrap each restriction in parentheses: "harwald (x1=0)" or "harwald (x1=x2)""'
            exit 198
        }

        local selrows
        local dropped_zero ""
        foreach v of local varlist {
            /* Factor base levels (`Nb.var', `Nbn.var', `Nbo.var')
               and `_rmcoll' omitted markers (`o.x', `oL.x', ...)
               sit at structural-zero columns of `e(b)' / `e(V)';
               testing them yields a zero row/col of `VR_t' and an
               inflated q. Drop and log (the default path at lines
               258-263 skips silently; here the user typed them). */
            if regexm("`v'", "^o([LFDS][0-9]*)*\.") | ///
               regexm("`v'", "[0-9]+b[no]?\.") {
                local dropped_zero "`dropped_zero' `v'"
                continue
            }
            local pos : list posof `"`v'"' in cn
            if `pos' == 0 {
                local pos : list posof `"`v'"' in cn_norm
            }
            if `pos' == 0 {
                di as err "`v' not found among estimated coefficients"
                exit 111
            }
            /* Resolved column may be a structural zero even when the
               typed name lacked the `b'/`o.' marker (e.g. `1.rep78'
               -> base `1b.rep78' via `cn_norm', or an `_rmcoll'
               drop with no `o.' alias). Check `e(b)' / `e(V)'. */
            local b_val = `b'[1, `pos']
            local v_val = `V'[`pos', `pos']
            if `b_val' == 0 & `v_val' == 0 {
                local matched : word `pos' of `cn'
                local dropped_zero "`dropped_zero' `v' (-> `matched')"
                continue
            }
            local selrows "`selrows' `pos'"
        }
        if "`dropped_zero'" != "" {
            di as txt "note: structural-zero column(s) dropped from joint test (factor base / collinearity-omitted):`dropped_zero'"
        }

        local q = wordcount("`selrows'")
        if (`q' == 0) {
            if "`coeflist'" == "" {
                /* No args + model has no estimable slopes (constant
                   only, or every slope is base/omitted): refuse. */
                di as err "no coefficients to test (model has no estimable slopes)"
                exit 198
            }
            /* User named columns, all filtered as structural zeros.
               Match Stata `test 1b.rep78' (Constraint 1 dropped;
               F(0, ...) = .; r(F)=.; r(df)=0; rc=0). */
            return scalar F = .
            return scalar q = 0
            return scalar df = 0
            return scalar df_r = .
            return scalar p = .
            return scalar cv = .
            exit 0
        }
        matrix `Rmat' = J(`q', `k', 0)
        matrix `cvec' = J(`q', 1, 0)
        local i = 1
        foreach pos of local selrows {
            matrix `Rmat'[`i', `pos'] = 1
            local ++i
        }
    }

    tempname Wald mtmp
    matrix `bR_t' = `Rmat'*`b'' - `cvec'
    matrix `VR_t' = `Rmat'*`V'*`Rmat''

    /* Drop rows with zero variance: VR_t[i,i] = 0 covers both
       no-coefficient-term restrictions (Rmat row is all zero, e.g.
       `(1=0)') and parens-mode hits on structural-zero columns of
       `V' (factor base / `_rmcoll' omitted; bare-mode names were
       regex-filtered above). syminv(VR_t) on such rows returns a
       g-inverse that leaves q inflated, silently understating
       F = W/q. Stata `test' drops the same way with the
       "Constraint N dropped" notice. */
    local q_orig = `q'
    local keep_rows ""
    forvalues __i = 1/`q_orig' {
        if `VR_t'[`__i', `__i'] != 0 {
            local keep_rows "`keep_rows' `__i'"
        }
    }
    local q_testable : word count `keep_rows'
    if `q_testable' < `q_orig' {
        if `q_testable' == 0 {
            di as txt "note: no testable restriction (zero variance for every restriction); F, p, crit. value left missing"
            return scalar F = .
            return scalar q = 0
            return scalar df = 0
            return scalar df_r = .
            return scalar p = .
            return scalar cv = .
            exit 0
        }
        di as txt "note: " `q_orig' - `q_testable' " restriction(s) not testable against e(V) — dropped from joint test (testable q = " `q_testable' " of " `q_orig' ")"
        tempname Rmat_t cvec_t
        matrix `Rmat_t' = J(`q_testable', `k', 0)
        matrix `cvec_t' = J(`q_testable', 1, 0)
        local new_i = 0
        foreach old_i of local keep_rows {
            local ++new_i
            forvalues __j = 1/`k' {
                matrix `Rmat_t'[`new_i', `__j'] = `Rmat'[`old_i', `__j']
            }
            matrix `cvec_t'[`new_i', 1] = `cvec'[`old_i', 1]
        }
        matrix `Rmat' = `Rmat_t'
        matrix `cvec' = `cvec_t'
        matrix `bR_t' = `Rmat'*`b'' - `cvec'
        matrix `VR_t' = `Rmat'*`V'*`Rmat''
        local q = `q_testable'
    }

    /* Reduce q to rank(Rmat) when the row set is linearly dependent
       (duplicates, sum-to-zero pairs). `syminv(VR_t)' already gives
       the rank-r Wald scalar on the row column space; only q in
       F = W/q and `Ftail(q, ...)' / `invFtail(q, ...)' must reflect
       the rank. Rank is checked on `Rmat' not `VR_t' so that
       insufficient-estimator-df cases (rank-deficient `V' on its
       active columns, e.g. EWC nu < q) remain governed by the
       `df_fb - q + 1 <= 0' refusal below, not silently absorbed. */
    mata: st_local("_har_rmat_rank", strofreal(rank(st_matrix("`Rmat'"))))
    local q_rank = `_har_rmat_rank'
    if `q_rank' < `q' {
        di as txt "note: restriction set is rank-deficient (rank " `q_rank' " < q = " `q' "); reducing joint-test q to " `q_rank'
        local q = `q_rank'
    }

    matrix `mtmp' = `bR_t''*syminv(`VR_t')*`bR_t'
    scalar `Wald' = `mtmp'[1,1]
    scalar `factor_t' = 1
    if inlist("`est'","ewc","ewp") {
        scalar `factor_t' = (e(df_fb) - `q' + 1)/e(df_fb)
    }
    scalar `Fstat_t' = `factor_t'*`Wald'/`q'

    scalar `df2_t'  = .
    scalar `pval_t' = .
    scalar `cv_t'   = .

    if inlist("`est'","ewc","ewp") {
        scalar `df2_t' = e(df_fb) - `q' + 1
        if missing(`df2_t') | `df2_t'<=0 {
            di as err "insufficient fixed-b degrees of freedom for joint test"
            exit 498
        }
        scalar `pval_t' = Ftail(`q', `df2_t', `Fstat_t')
        scalar `cv_t'   = invFtail(`q', `df2_t', 1-`lev')
    }
    else {
        local S = e(bw)
        local T = e(N)
        /* Tukey kernel-equivalent df nu = T / (S * integral_k_squared)
           integral_k_squared = 2/3 (Bartlett) -> nu = (3/2)*T/S
           integral_k_squared = 6/5 (QS)      -> nu = (5/6)*T/S
           Used for the printed header denominator df and the q > nu
           sanity warning. The p-value and critical value below come
           from the simulator (`harwald_sim'), not from F(q, nu) */
        local _kernel_constant = cond("`est'"=="nw", 3/2, 5/6)
        scalar `df2_t' = ceil(`_kernel_constant' * `T' / `S')
        if (`q' > `S' | `q' > `df2_t') {
            di as txt "warning: q = `q' exceeds " ///
                cond(`q' > `S', "truncation parameter S = `S'", "kernel-equivalent df = " + string(`df2_t')) ///
                "; the simulated null distribution may be unreliable for joint tests of this dimension"
        }
        tempname cvF_sim_t pF_sim_t
        mata: harwald_sim("`est'", `S', `T', `critdraws', `q', st_numscalar("`Fstat_t'"), `lev', "`cvF_sim_t'", "`pF_sim_t'")
        scalar `cv_t'   = `cvF_sim_t'
        scalar `pval_t' = `pF_sim_t'
    }

    local df2_int = floor(`df2_t')
    local _p_label = cond(inlist("`est'","nw","qs"), "p (sim)", "p")
    local varlist = strtrim("`varlist'")
    di as txt "HAR Wald test of coefficients: `varlist'"
    di as txt "F(" as res `q' as txt "," as res `df2_int' as txt ")" ///
        " = " as res %9.2f `Fstat_t' as txt ",  `_p_label' = " as res %6.4f `pval_t' ///
        as txt "  (crit. val. @ " %4.1f (`lev'*100) "% : " as res %6.4f `cv_t' as txt ")"

    return scalar F = `Fstat_t'
    return scalar q = `q'
    return scalar df = `q'
    return scalar df_r = `df2_t'
    return scalar p = `pval_t'
    return scalar cv = `cv_t'
end
