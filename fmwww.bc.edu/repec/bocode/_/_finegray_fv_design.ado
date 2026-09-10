*! _finegray_fv_design Version 1.3.2  2026/09/08
*! Resolve the fitted factor-variable design from the FIT-TIME expansion
*! Author: Timothy P Copeland, Karolinska Institutet
*! Program class: rclass

/*
Returns, for the factor-variable fit currently in e():

  r(k)        number of non-base design columns (== e(designvars); under
              tvc() that is NARROWER than e(b), which holds one coefficient
              per interval for each time-varying column)
  r(terms)    those columns' semantic terms, in order, VERBATIM as
              e(fvsemantic) spells them -- `2.race', `2.race#c.age'
  r(expr#)    a Stata expression that evaluates design column # from the
              raw covariates, e.g. `(race == 2) * age'
  r(rawvars)  the unique underlying variables the design is built from, in
              first-appearance order (e.g. `grp x')
  r(fvars)    the subset of r(rawvars) that enters as a factor level
  r(pieces#)  the factors of design column #, encoded `var:level' for a
              factor indicator and bare `var' for a continuous part, so a caller can
              re-evaluate the column at a chosen profile without parsing the
              term itself.  r(expr#) is the same information as a Stata
              expression; pieces# is the form a profile builder needs.

WHY THIS EXISTS.  A post-estimation command needs two things from a factor
fit: what to CALL each column, and how to REBUILD it if the package-owned
_fg_* columns have been dropped.  Both must come from the expansion that was
in force AT FIT TIME, which is what e(fvsemantic) stores.

Re-running `fvexpand e(fvvarlist)' against the current data instead is wrong
in a way no count check can catch.  fvexpand resolves the base level from the
variable's CURRENT fvset setting, so

    finegray Z1 i.grp, ...      // fvexpand -> 1b.grp 2.grp 3.grp
    fvset base 3 grp            // no refit
    <post-estimation command>   // fvexpand -> 1.grp 2.grp 3b.grp

keeps the same NUMBER of non-base terms while changing WHICH ones.  Observed
2026-07-21 in finegray_phtest: with the design columns still in memory the
table mislabelled level 2 and 3 coefficients as levels 1 and 2; with them
dropped, the rebuild fed the level-1/2 indicators against e(b) for levels 2/3
and every statistic changed (correlations -0.2348/-0.2062/0.1931 ->
-0.2300/0.0315/-0.2124).  Both at rc 0.  finegray_predict and finegray_cif were already
immune because they read e(fvsemantic); this helper is how the rest of the
package joins them.

Immune in the DESIGN they compute, that is -- which is not the same as the
vocabulary they REPORT.  finegray_cif reported e(designvars) in
r(profile_vars) before this fix, so a user who fit `i.grp' and passed
`at(grp=1)' got `_fg_grp_2 _fg_grp_3' back: internal column names they never
typed, for a matrix they are told to read positionally.  Now taken from
that command's own non-base term list.  When adding a consumer, check both
axes -- what it computes from, and what it calls the result.

The same reasoning covers a shifted level support -- fit on {1,2,3}, recode to
{2,3,4} -- which is why r(expr#) keys each indicator to the level VALUE rather
than to a position.

The caller creates the columns, because a `tempvar' made here would be dropped
the moment this program returns.  It supplies only the expression, so the
parsing -- the part that goes wrong -- lives in one place.
*/

capture program drop _finegray_fv_design
program define _finegray_fv_design, rclass
    version 16.0
    local _orig_varabbrev = c(varabbrev)
    set varabbrev off

    capture noisily {

        syntax [, CALLER(string)]
        if `"`caller'"' == "" local caller "this post-estimation command"

        local _fvsem `"`e(fvsemantic)'"'
        if `"`_fvsem'"' == "" {
            display as error "estimation results predate this version of finegray"
            display as error "e(fvsemantic) is not set, so the fitted factor-variable"
            display as error "design cannot be resolved; re-run {bf:finegray} before"
            display as error "using `caller'"
            exit 301
        }

        local _terms ""
        local _rawv  ""
        local _fvarv ""
        local _k = 0
        foreach _term of local _fvsem {
            * Base levels carry no coefficient.  This rule must agree with
            * finegray.ado's own kept-term filter, which decides what goes into
            * e(b) in the first place: `Nb.' is skipped, `Nbn.' is kept, because
            * ibn. omits no reference and its first level carries a real
            * coefficient.  Everything downstream pairs terms with e(b) by
            * position, so a divergence here mislabels silently.
            if regexm("`_term'", "[0-9]+b\.") continue
            local ++_k
            local _terms "`_terms' `_term'"

            * An fvexpand term is a `#'-separated product of factor levels and
            * continuous parts.  `##' never survives expansion, but it is
            * flattened anyway so a hand-set e(fvsemantic) cannot smuggle one in.
            local _parts = subinstr(subinstr("`_term'", "##", "#", .), "#", " ", .)
            local _expr ""
            local _pieces ""
            foreach _p of local _parts {
                * Tolerate any factor operator on the level marker (b, bn, o).
                if regexm("`_p'", "^([0-9]+)[a-z]*\.(.+)$") {
                    local _lv = regexs(1)
                    local _vr = regexs(2)
                    capture confirm numeric variable `_vr'
                    if _rc {
                        display as error "factor variable `_vr' (from the fitted term `_term') is not in the data"
                        display as error "`caller' requires the original finegray estimation data"
                        exit 111
                    }
                    local _piece "(`_vr' == `_lv')"
                    local _pieces "`_pieces' `_vr':`_lv'"
                    local _rawv   "`_rawv' `_vr'"
                    local _fvarv  "`_fvarv' `_vr'"
                }
                else {
                    local _vr = subinstr("`_p'", "c.", "", .)
                    capture confirm numeric variable `_vr'
                    if _rc {
                        display as error "covariate `_vr' (from the fitted term `_term') is not in the data"
                        display as error "`caller' requires the original finegray estimation data"
                        exit 111
                    }
                    local _piece "`_vr'"
                    local _pieces "`_pieces' `_vr'"
                    local _rawv   "`_rawv' `_vr'"
                }
                if `"`_expr'"' == "" local _expr "`_piece'"
                else                 local _expr "`_expr' * `_piece'"
            }
            return local expr`_k' "`_expr'"
            local _pieces : list retokenize _pieces
            return local pieces`_k' "`_pieces'"
        }

        if `_k' == 0 {
            display as error "the fitted factor-variable design has no estimable columns"
            exit 198
        }
        * Compare against the DESIGN width, not colsof(e(b)).  Under tvc() the
        * coefficient vector is wider than the design -- each time-varying
        * column carries one coefficient per interval -- so equality with
        * colsof(e(b)) is the wrong contract there and would reject every
        * factor-variable tvc() fit at the first rebuild.  e(designvars) names
        * the design columns and is the quantity this expansion reproduces.
        local _kexp : word count `e(designvars)'
        if `_kexp' == 0 {
            * Results posted before e(designvars) existed carry the narrow
            * stripe, so colsof(e(b)) is the design width there; a current fit
            * always posts e(designvars), and its e(b) may be wider (base
            * columns), so this fallback must never be reached by one.
            local _kexp = colsof(e(b))
        }
        if `_k' != `_kexp' {
            display as error "fitted factor-variable design does not match e(b)"
            display as error "(`_k' non-base terms in e(fvsemantic), `_kexp' design columns)"
            exit 198
        }

        local _rawv  : list uniq _rawv
        local _fvarv : list uniq _fvarv
        return local rawvars "`_rawv'"
        return local fvars   "`_fvarv'"

        return local terms : list retokenize _terms
        return scalar k = `_k'
    }
    local rc = _rc
    set varabbrev `_orig_varabbrev'
    if `rc' exit `rc'
end
