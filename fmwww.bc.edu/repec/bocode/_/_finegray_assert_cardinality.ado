*! _finegray_assert_cardinality Version 1.3.2  2026/09/08
*! Refuse a destructive commit that would carry zero (or too few) usable values
*! Author: Timothy P Copeland, Karolinska Institutet
*! Program class: rclass

/*
The commit contract (Critical Rule 15).

Before creating or replacing a user variable, count the usable outputs and
error when there are none.  A prediction path can complete with status OK and
still have nothing to say: every scoring covariate missing on the prediction
rows, or a cumulative incidence that is identically zero so its complementary
log-log limits are undefined everywhere.  Both shipped a user variable of pure
missings at rc 0.

Measured on the pre-fix build (webuse hypoxia, n = 109):

  finegray_predict cifhat, cif        after `replace ifp = .'
      -> rc 0, cifhat created, 0 of 109 non-missing
  finegray_predict p, cif ci timevar(t) with t below the first cause event
      -> rc 0, p identically 0, p_lci and p_uci 0 of 109 non-missing

Neither is an empty-sample failure -- `touse' is guarded non-empty upstream --
so no existing guard could see them.  The count of USABLE OUTPUTS is a
different quantity from the count of eligible rows, and this is where it is
taken.

Syntax:
  _finegray_assert_cardinality <varname> [<expected_n>] [, touse(varname)
      label(string) allowzero]

  <expected_n>  when given, the count must be at least this many.
  touse()       restrict the count to the marked prediction/estimation sample.
  label()       what to name in the error message (defaults to the varname,
                which is usually a tempvar and meaningless to a user).
  allowzero     permit an empty result.  Only for a mode documented in the
                .sthlp as producing no output; finegray has no such mode
                today, and adding one means documenting it there first.

Errors 2000 on zero, 459 when short of expected_n.  Returns r(N).
*/

program define _finegray_assert_cardinality, rclass
    version 16.0
    local _orig_varabbrev = c(varabbrev)
    set varabbrev off
    capture noisily {

        syntax anything(name=spec id="variable") ///
            [, TOUSE(varname) LABel(string) ALLOWZERO]

        gettoken cvar expected : spec
        local expected = strtrim("`expected'")
        confirm numeric variable `cvar'
        if "`expected'" != "" {
            confirm integer number `expected'
        }
        if `"`label'"' == "" local label "`cvar'"

        if "`touse'" != "" {
            quietly count if !missing(`cvar') & `touse'
        }
        else {
            quietly count if !missing(`cvar')
        }
        local found = r(N)

        if `found' == 0 & "`allowzero'" == "" {
            display as error `"`label': zero usable values"'
            display as error "  refusing to commit a result with no content"
            exit 2000
        }
        if "`expected'" != "" {
            if `found' < `expected' {
                display as error `"`label': `found' usable values, expected `expected'"'
                exit 459
            }
        }

        return scalar N = `found'
        if "`expected'" != "" {
            return scalar expected = `expected'
        }
    }
    local rc = _rc
    set varabbrev `_orig_varabbrev'
    if `rc' exit `rc'
end
