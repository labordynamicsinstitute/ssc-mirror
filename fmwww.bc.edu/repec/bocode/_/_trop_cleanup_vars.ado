*! Drop temporary variables created during trop estimation
program _trop_cleanup_vars
    version 17

    // Panel structure temporaries
    foreach v in __trop_time_diff __trop_tindex {
        capture drop `v'
    }

    // Observation validity and balance indicators
    foreach v in __trop_valid __trop_allmiss_unit __trop_allmiss_period __trop_n_valid_t __trop_n_valid_i {
        capture drop `v'
    }

    // Treatment assignment and adoption timing indicators
    foreach v in __trop_ever_treated __trop_adoption_time __trop_T_start __trop_n_switches ///
        __trop_first_treat_time __trop_W_diff __trop_any_treated_t {
        capture drop `v'
    }

    // Outlier detection flag
    foreach v in __trop_outlier_flag {
        capture drop `v'
    }

    // Pre-treatment period indicator
    foreach v in __trop_is_pretreat {
        capture drop `v'
    }

    // LOOCV working variables
    foreach v in __trop_is_control_26 __trop_never_treated_26 __trop_T_start_26 __trop_is_pre_26 ///
        __trop_n_pre_valid_26 __trop_is_control_obs_26 __trop_n_control_i_26 ///
        __trop_ever_treated_check __trop_panel_id_26 __trop_time_id_26 {
        capture drop `v'
    }
end
