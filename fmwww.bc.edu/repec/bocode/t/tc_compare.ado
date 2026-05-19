*! tc_compare.ado -- Run a panel of threshold cointegration tests and tabulate
*! Author: Dr Merwan Roudane

program define tc_compare, rclass
    version 14
    syntax varlist(min=2 numeric) [if] [in] [, MAXLag(integer 8) TESTs(string)]
    gettoken depvar indepvars : varlist
    marksample touse
    _tc_load

    if "`tests'" == "" {
        local tests "es_tar es_mtar glsmtar exes covaug_tar covaug_mtar bf adlbdm adlbo kss"
    }

    di
    di as text "{hline 92}"
    di as result "  Threshold cointegration test comparison -- `depvar' on `indepvars'"
    di as text "{hline 92}"
    di as text %-32s "Test" %14s "Statistic" %12s "5% CV" "  " "Conclusion"
    di as text "{hline 92}"

    foreach t of local tests {
        local name "(unknown)"
        local stat = .
        local cv5  = .
        local concl ""

        capture {
            if "`t'" == "es_tar" {
                qui tc_es `varlist' if `touse', model(tar) maxlag(`maxlag')
                local stat = r(phi_stat)
                if "`r(cv)'" != "" {
                    matrix _tcv = r(cv)
                    local cv5 = el(_tcv, 1, 2)
                }
                local name "Enders-Siklos TAR"
            }
            else if "`t'" == "es_mtar" {
                qui tc_es `varlist' if `touse', model(mtar) maxlag(`maxlag')
                local stat = r(phi_stat)
                matrix _tcv = r(cv)
                local cv5 = el(_tcv, 1, 2)
                local name "Enders-Siklos MTAR"
            }
            else if "`t'" == "glsmtar" {
                qui tc_glsmtar `varlist' if `touse', maxlag(`maxlag')
                local stat = r(phi_gls_stat)
                matrix _tcv = r(cv)
                local cv5 = el(_tcv, 1, 2)
                local name "Cook GLS-MTAR"
            }
            else if "`t'" == "exes" {
                qui tc_exes `varlist' if `touse', maxlag(`maxlag')
                local stat = r(sup_phi)
                local name "Extended E-S (sup-Phi)"
            }
            else if "`t'" == "covaug_tar" {
                qui tc_covaug `varlist' if `touse', model(tar) maxlag(`maxlag')
                local stat = r(phi_stat)
                matrix _tcv = r(cv)
                local cv5 = el(_tcv, 1, 2)
                local name "Covariates-Aug TAR"
            }
            else if "`t'" == "covaug_mtar" {
                qui tc_covaug `varlist' if `touse', model(mtar) maxlag(`maxlag')
                local stat = r(phi_stat)
                matrix _tcv = r(cv)
                local cv5 = el(_tcv, 1, 2)
                local name "Covariates-Aug MTAR"
            }
            else if "`t'" == "bf" {
                qui tc_bf `varlist' if `touse', maxlag(4)
                local stat = r(sup_wald)
                local name "Balke-Fomby sup-Wald"
            }
            else if "`t'" == "adlbdm" {
                qui tc_adlbdm `varlist' if `touse', maxlag(`maxlag')
                local stat = r(sup_t)
                matrix _tcv = r(cv)
                local cv5 = el(_tcv, 1, 2)
                local name "ADL-BDM"
            }
            else if "`t'" == "adlbo" {
                qui tc_adlbo `varlist' if `touse', maxlag(`maxlag')
                local stat = r(sup_wald)
                matrix _tcv = r(cv)
                local cv5 = el(_tcv, 1, 2)
                local name "ADL-BO"
            }
            else if "`t'" == "kss" {
                qui tc_kss `varlist' if `touse', maxlag(`maxlag')
                local stat = r(t_stat)
                matrix _tcv = r(cv)
                local cv5 = el(_tcv, 1, 2)
                local name "KSS nonlinear"
            }
        }
        local rc = _rc

        if `rc' di as text %-32s "`name'" "  " as error %12s "(error)"
        else    di as text %-32s "`name'" "  " as result %12.4f `stat' "  " %10.3f `cv5'
    }
    di as text "{hline 92}"
    capture matrix drop _tcv
end
