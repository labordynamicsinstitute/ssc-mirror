*! threshcoint_diagnose.do -- STRICT diagnostic
*! Sources the mata file and verifies each function actually got defined.
*! Author: Dr Merwan Roudane

clear all
capture mata mata clear

capture confirm file "../mata/_threshcoint_mata.mata"
if !_rc {
    local mfile = "../mata/_threshcoint_mata.mata"
}
else {
    capture confirm file "mata/_threshcoint_mata.mata"
    if !_rc {
        local mfile = "mata/_threshcoint_mata.mata"
    }
    else {
        di as error "Could not find _threshcoint_mata.mata."
        exit 198
    }
}

di as text "{hline 70}"
di as result "Sourcing: " as text "`mfile'"
di as text "Scroll up after this to find any 'invalid expression' lines."
di as text "{hline 70}"

do "`mfile'"

di as text "{hline 70}"
di as result "Now verifying each function is actually defined in mata:"
di as text "{hline 70}"

local fns ///
    tc_quantile tc_seq tc_pick tc_ols tc_lagmat tc_embed tc_gls_detrend ///
    tc_cv_es_phi tc_cv_es_phi_row tc_cv_gls_mtar tc_cv_gls_mtar_row     ///
    tc_cv_adl_bdm tc_cv_adl_bo tc_cv_supf tc_cv_bbc tc_cv_kss           ///
    tc_cv_eg tc_cv_adf tc_cv_covaug                                     ///
    tc_adf tc_pp tc_eg                                                  ///
    tc_enders_siklos tc_gls_mtar tc_ext_es tc_covaug                    ///
    tc_balke_fomby tc_adl_bdm tc_adl_bo tc_system_adl                   ///
    tc_supf tc_hansen_seo tc_kss tc_bbc                                 ///
    tc_tar_fit tc_band_regime tc_eqtar_search tc_eqtar_fit              ///
    tc_setar_fit tc_tvecm_fit

local missing ""
foreach f of local fns {
    capture mata: `f'()
    * rc==198 means "argument count wrong" but function exists
    * rc==3499 means function not found
    if _rc == 3499 {
        local missing "`missing' `f'"
        di as error "MISSING: `f'"
    }
    else {
        di as text "  ok: `f'"
    }
}

di as text "{hline 70}"
if "`missing'" == "" {
    di as result "All `: word count `fns'' functions are defined."
}
else {
    di as error "FAILED to define: `missing'"
    di as text "Look in the mata-load output above for the 'invalid expression'"
    di as text "messages; the function defined just BEFORE the first failure is"
    di as text "where the bug lives."
}
di as text "{hline 70}"
