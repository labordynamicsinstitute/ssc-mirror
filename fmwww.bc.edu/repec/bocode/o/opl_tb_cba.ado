*-------------------------------------------------------------------------------
* Command: "opl_tb_cba" = "OPL cost benefit analysis threshold based"
*-------------------------------------------------------------------------------
*! version 1.1.0 14jul2026
program define opl_tb_cba, eclass
    version 18.0

    syntax varname(numeric) [if] [in],                       ///
        COST(varname numeric)                               ///
        SELECT(varlist numeric min=1 max=2)                 ///
        [ LAMBDA(real 1)                                    ///
          NPOINTS(integer 101)                              ///
          CUSTOM(numlist)                                   ///
          CUSTOMPOLICY(varname numeric)                     ///
          GENerate(name)                                    ///
          GRAPH                                             ///
          REPLACE ]

    marksample touse
    markout `touse' `varlist' `cost' `select'

    if "`custompolicy'" != "" {
        markout `touse' `custompolicy'
    }

    if `lambda' < 0 {
        di as error "lambda() must be nonnegative"
        exit 198
    }

    if `npoints' < 2 {
        di as error "npoints() must be at least 2"
        exit 198
    }

    local tau `varlist'
    local nselect : word count `select'
    local x1 : word 1 of `select'

    if `nselect' == 2 {
        local x2 : word 2 of `select'
    }

    quietly count if `touse'
    local N = r(N)

    if `N' == 0 {
        di as error "no observations"
        exit 2000
    }

    /*
    Validate user-supplied customized policy.

    The policy must be coded:
        1 = treated
        0 = not treated
    */
    if "`custompolicy'" != "" {
        quietly count if `touse' & !inlist(`custompolicy', 0, 1)

        if r(N) > 0 {
            di as error ///
                "custompolicy() must contain only 0 and 1 in the estimation sample"
            exit 459
        }
    }

    tempvar net z1 z2 pfb popt pcand
    quietly gen double `net' = ///
        `tau' - `lambda' * `cost' if `touse'

    /*
    Standardize selection variables to [0,1]
    */
    quietly summarize `x1' if `touse', meanonly

    local x1min = r(min)
    local x1max = r(max)

    if (`x1max' - `x1min') <= 0 {
        di as error ///
            "selection variable `x1' is constant in the estimation sample"
        exit 498
    }

    quietly gen double `z1' = ///
        (`x1' - `x1min') / (`x1max' - `x1min') if `touse'

    if `nselect' == 2 {

        quietly summarize `x2' if `touse', meanonly

        local x2min = r(min)
        local x2max = r(max)

        if (`x2max' - `x2min') <= 0 {
            di as error ///
                "selection variable `x2' is constant in the estimation sample"
            exit 498
        }

        quietly gen double `z2' = ///
            (`x2' - `x2min') / (`x2max' - `x2min') if `touse'
    }

    /*
    First-best policy:
    treat individual i iff

        tau_i - lambda * cost_i > 0
    */
    quietly gen byte `pfb' = (`net' > 0) if `touse'

    quietly opl_tb_cba__eval,                         ///
        policy(`pfb')                                     ///
        tau(`tau')                                        ///
        cost(`cost')                                      ///
        lambda(`lambda')                                  ///
        touse(`touse')

    local N_fb        = r(N_treated)
    local coverage_fb = r(coverage)
    local TB_fb       = r(total_benefit)
    local TC_fb       = r(total_cost)
    local Q_fb        = r(Q)
    local ATET_fb     = r(ATET)
    local avgcost_fb  = r(avg_cost)
    local avgsurp_fb  = r(avg_surplus)

    /*
    Initialize constrained optimum at treat-none policy.
    */
    quietly gen byte `popt'  = 0 if `touse'
    quietly gen byte `pcand' = 0 if `touse'

    local bestQ  = 0
    local bestg1 = .
    local bestg2 = .

    /*
    Search over threshold policies.
    */
    tempname GRID

    if `nselect' == 1 {

        matrix `GRID' = J(`npoints', 9, .)

        matrix colnames `GRID' =                       ///
            threshold1                                ///
            N_treated                                 ///
            coverage                                  ///
            total_benefit                             ///
            total_cost                                ///
            Q                                         ///
            ATET                                      ///
            avg_cost                                  ///
            avg_surplus

        local row = 0

        forvalues m = 0/`=`npoints' - 1' {

            local ++row
            local g1 = `m' / (`npoints' - 1)

            quietly replace `pcand' = ///
                (`z1' >= `g1') if `touse'

            quietly opl_tb_cba__eval,             ///
                policy(`pcand')                        ///
                tau(`tau')                            ///
                cost(`cost')                          ///
                lambda(`lambda')                      ///
                touse(`touse')

            matrix `GRID'[`row',1] = `g1'
            matrix `GRID'[`row',2] = r(N_treated)
            matrix `GRID'[`row',3] = r(coverage)
            matrix `GRID'[`row',4] = r(total_benefit)
            matrix `GRID'[`row',5] = r(total_cost)
            matrix `GRID'[`row',6] = r(Q)
            matrix `GRID'[`row',7] = r(ATET)
            matrix `GRID'[`row',8] = r(avg_cost)
            matrix `GRID'[`row',9] = r(avg_surplus)

            if r(Q) > `bestQ' {

                local bestQ  = r(Q)
                local bestg1 = `g1'

                quietly replace `popt' = `pcand' if `touse'
            }
        }
    }
    else {

        local npolicies = `npoints' * `npoints'

        matrix `GRID' = J(`npolicies', 10, .)

        matrix colnames `GRID' =                       ///
            threshold1                                ///
            threshold2                                ///
            N_treated                                 ///
            coverage                                  ///
            total_benefit                             ///
            total_cost                                ///
            Q                                         ///
            ATET                                      ///
            avg_cost                                  ///
            avg_surplus

        local row = 0

        forvalues m1 = 0/`=`npoints' - 1' {

            local g1 = `m1' / (`npoints' - 1)

            forvalues m2 = 0/`=`npoints' - 1' {

                local ++row
                local g2 = `m2' / (`npoints' - 1)

                quietly replace `pcand' = ///
                    (`z1' >= `g1' & `z2' >= `g2') if `touse'

                quietly opl_tb_cba__eval,         ///
                    policy(`pcand')                    ///
                    tau(`tau')                        ///
                    cost(`cost')                      ///
                    lambda(`lambda')                  ///
                    touse(`touse')

                matrix `GRID'[`row',1]  = `g1'
                matrix `GRID'[`row',2]  = `g2'
                matrix `GRID'[`row',3]  = r(N_treated)
                matrix `GRID'[`row',4]  = r(coverage)
                matrix `GRID'[`row',5]  = r(total_benefit)
                matrix `GRID'[`row',6]  = r(total_cost)
                matrix `GRID'[`row',7]  = r(Q)
                matrix `GRID'[`row',8]  = r(ATET)
                matrix `GRID'[`row',9]  = r(avg_cost)
                matrix `GRID'[`row',10] = r(avg_surplus)

                if r(Q) > `bestQ' {

                    local bestQ  = r(Q)
                    local bestg1 = `g1'
                    local bestg2 = `g2'

                    quietly replace `popt' = `pcand' if `touse'
                }
            }
        }
    }

    /*
    Evaluate optimal constrained threshold policy.
    */
    quietly opl_tb_cba__eval,                         ///
        policy(`popt')                                    ///
        tau(`tau')                                        ///
        cost(`cost')                                      ///
        lambda(`lambda')                                  ///
        touse(`touse')

    local N_opt        = r(N_treated)
    local coverage_opt = r(coverage)
    local TB_opt       = r(total_benefit)
    local TC_opt       = r(total_cost)
    local Q_opt        = r(Q)
    local ATET_opt     = r(ATET)
    local avgcost_opt  = r(avg_cost)
    local avgsurp_opt  = r(avg_surplus)

    /*
    Convert optimal standardized thresholds back to original scale.
    */
    local bestg1_lev = .
    local bestg2_lev = .

    if `bestg1' < . {
        local bestg1_lev = ///
            `x1min' + `bestg1' * (`x1max' - `x1min')
    }

    if `nselect' == 2 & `bestg2' < . {
        local bestg2_lev = ///
            `x2min' + `bestg2' * (`x2max' - `x2min')
    }

    /*
    Evaluate user-supplied customized policy.
    */
    local has_custompolicy = 0

    tempname CUSTOMPOLICYMAT

    if "`custompolicy'" != "" {

        local has_custompolicy = 1

        quietly opl_tb_cba__eval,                     ///
            policy(`custompolicy')                         ///
            tau(`tau')                                    ///
            cost(`cost')                                  ///
            lambda(`lambda')                              ///
            touse(`touse')

        local N_custompolicy        = r(N_treated)
        local coverage_custompolicy = r(coverage)
        local TB_custompolicy       = r(total_benefit)
        local TC_custompolicy       = r(total_cost)
        local Q_custompolicy        = r(Q)
        local ATET_custompolicy     = r(ATET)
        local avgcost_custompolicy  = r(avg_cost)
        local avgsurp_custompolicy  = r(avg_surplus)

        matrix `CUSTOMPOLICYMAT' = J(1, 8, .)

        matrix colnames `CUSTOMPOLICYMAT' =             ///
            N_treated                                   ///
            coverage                                    ///
            total_benefit                               ///
            total_cost                                  ///
            Q                                           ///
            ATET                                        ///
            avg_cost                                    ///
            avg_surplus

        matrix `CUSTOMPOLICYMAT'[1,1] = `N_custompolicy'
        matrix `CUSTOMPOLICYMAT'[1,2] = `coverage_custompolicy'
        matrix `CUSTOMPOLICYMAT'[1,3] = `TB_custompolicy'
        matrix `CUSTOMPOLICYMAT'[1,4] = `TC_custompolicy'
        matrix `CUSTOMPOLICYMAT'[1,5] = `Q_custompolicy'
        matrix `CUSTOMPOLICYMAT'[1,6] = `ATET_custompolicy'
        matrix `CUSTOMPOLICYMAT'[1,7] = `avgcost_custompolicy'
        matrix `CUSTOMPOLICYMAT'[1,8] = `avgsurp_custompolicy'
    }

    /*
    Custom threshold policy or policies specified through custom().
    */
    tempname CUSTOMMAT
    local ncustom = 0

    if "`custom'" != "" {

        local ncustom : word count `custom'

        if `nselect' == 2 & `ncustom' != 2 {
            di as error ///
                "with two selection variables, custom() must contain exactly two thresholds"
            exit 198
        }

        foreach g of numlist `custom' {

            if (`g' < 0 | `g' > 1) {
                di as error ///
                    "all custom thresholds must lie in [0,1]"
                exit 198
            }
        }

        if `nselect' == 1 {

            matrix `CUSTOMMAT' = J(`ncustom', 9, .)

            matrix colnames `CUSTOMMAT' =                ///
                threshold1                               ///
                N_treated                                ///
                coverage                                 ///
                total_benefit                            ///
                total_cost                               ///
                Q                                        ///
                ATET                                     ///
                avg_cost                                 ///
                avg_surplus

            local crow = 0

            foreach g1 of numlist `custom' {

                local ++crow

                quietly replace `pcand' = ///
                    (`z1' >= `g1') if `touse'

                quietly opl_tb_cba__eval,           ///
                    policy(`pcand')                      ///
                    tau(`tau')                          ///
                    cost(`cost')                        ///
                    lambda(`lambda')                    ///
                    touse(`touse')

                matrix `CUSTOMMAT'[`crow',1] = `g1'
                matrix `CUSTOMMAT'[`crow',2] = r(N_treated)
                matrix `CUSTOMMAT'[`crow',3] = r(coverage)
                matrix `CUSTOMMAT'[`crow',4] = r(total_benefit)
                matrix `CUSTOMMAT'[`crow',5] = r(total_cost)
                matrix `CUSTOMMAT'[`crow',6] = r(Q)
                matrix `CUSTOMMAT'[`crow',7] = r(ATET)
                matrix `CUSTOMMAT'[`crow',8] = r(avg_cost)
                matrix `CUSTOMMAT'[`crow',9] = r(avg_surplus)

                if "`generate'" != "" {

                    local cname = "`generate'_custom`crow'"

                    capture confirm new variable `cname'

                    if _rc {

                        if "`replace'" != "" {
                            capture drop `cname'
                        }
                        else {
                            di as error ///
                                "variable `cname' already exists; specify replace"
                            exit 110
                        }
                    }

                    quietly gen byte `cname' = ///
                        `pcand' if `touse'

                    label variable `cname' ///
                        "Custom threshold policy `crow'"
                }
            }
        }
        else {

            local cg1 : word 1 of `custom'
            local cg2 : word 2 of `custom'

            quietly replace `pcand' = ///
                (`z1' >= `cg1' & `z2' >= `cg2') if `touse'

            quietly opl_tb_cba__eval,               ///
                policy(`pcand')                          ///
                tau(`tau')                              ///
                cost(`cost')                            ///
                lambda(`lambda')                        ///
                touse(`touse')

            matrix `CUSTOMMAT' = J(1, 10, .)

            matrix colnames `CUSTOMMAT' =                ///
                threshold1                               ///
                threshold2                               ///
                N_treated                                ///
                coverage                                 ///
                total_benefit                            ///
                total_cost                               ///
                Q                                        ///
                ATET                                     ///
                avg_cost                                 ///
                avg_surplus

            matrix `CUSTOMMAT'[1,1]  = `cg1'
            matrix `CUSTOMMAT'[1,2]  = `cg2'
            matrix `CUSTOMMAT'[1,3]  = r(N_treated)
            matrix `CUSTOMMAT'[1,4]  = r(coverage)
            matrix `CUSTOMMAT'[1,5]  = r(total_benefit)
            matrix `CUSTOMMAT'[1,6]  = r(total_cost)
            matrix `CUSTOMMAT'[1,7]  = r(Q)
            matrix `CUSTOMMAT'[1,8]  = r(ATET)
            matrix `CUSTOMMAT'[1,9]  = r(avg_cost)
            matrix `CUSTOMMAT'[1,10] = r(avg_surplus)

            if "`generate'" != "" {

                local cname = "`generate'_custom"

                capture confirm new variable `cname'

                if _rc {

                    if "`replace'" != "" {
                        capture drop `cname'
                    }
                    else {
                        di as error ///
                            "variable `cname' already exists; specify replace"
                        exit 110
                    }
                }

                quietly gen byte `cname' = ///
                    `pcand' if `touse'

                label variable `cname' ///
                    "Custom two-threshold policy"
            }
        }
    }

    /*
    Generate requested variables.
    */
    if "`generate'" != "" {

        foreach suffix in fb opt surplus z1 {

            local vname = "`generate'_`suffix'"

            capture confirm new variable `vname'

            if _rc {

                if "`replace'" != "" {
                    capture drop `vname'
                }
                else {
                    di as error ///
                        "variable `vname' already exists; specify replace"
                    exit 110
                }
            }
        }

        if `nselect' == 2 {

            local vname = "`generate'_z2"

            capture confirm new variable `vname'

            if _rc {

                if "`replace'" != "" {
                    capture drop `vname'
                }
                else {
                    di as error ///
                        "variable `vname' already exists; specify replace"
                    exit 110
                }
            }
        }

        quietly gen byte `generate'_fb = ///
            `pfb' if `touse'

        quietly gen byte `generate'_opt = ///
            `popt' if `touse'

        quietly gen double `generate'_surplus = ///
            `net' if `touse'

        quietly gen double `generate'_z1 = ///
            `z1' if `touse'

        if `nselect' == 2 {
            quietly gen double `generate'_z2 = ///
                `z2' if `touse'
        }

        label variable `generate'_fb ///
            "First-best treatment policy"

        label variable `generate'_opt ///
            "Optimal constrained threshold policy"

        label variable `generate'_surplus ///
            "Individual weighted surplus: tau - lambda*cost"

        label variable `generate'_z1 ///
            "`x1' standardized to [0,1]"

        if `nselect' == 2 {
            label variable `generate'_z2 ///
                "`x2' standardized to [0,1]"
        }
    }

    /*
    Graph.
    */
    if "`graph'" != "" {

        if `nselect' == 1 {

            local xlopt ""

            if `bestg1' < . {
                local xlopt ///
                    "xline(`bestg1', lpattern(solid))"
            }

            quietly twoway                                          ///
                (scatter `net' `z1' if `touse' & `popt' == 0,       ///
                    msymbol(Oh))                                    ///
                (scatter `net' `z1' if `touse' & `popt' == 1,       ///
                    msymbol(O)),                                    ///
                `xlopt'                                             ///
                yline(0, lpattern(dash))                            ///
                xtitle("`x1' standardized to [0,1]")                ///
                ytitle("Individual weighted surplus")               ///
                title("Optimal threshold welfare policy")           ///
                legend(order(1 "Not selected" 2 "Selected"))
        }
        else {

            local lines ""

            if `bestg1' < . {
                local lines ///
                    "`lines' xline(`bestg1', lpattern(solid))"
            }

            if `bestg2' < . {
                local lines ///
                    "`lines' yline(`bestg2', lpattern(solid))"
            }

            quietly twoway                                          ///
                (scatter `z2' `z1' if `touse' & `popt' == 0,        ///
                    msymbol(Oh))                                    ///
                (scatter `z2' `z1' if `touse' & `popt' == 1,        ///
                    msymbol(O)),                                    ///
                `lines'                                             ///
                xtitle("`x1' standardized to [0,1]")                ///
                ytitle("`x2' standardized to [0,1]")                ///
                title("Optimal two-threshold welfare policy")       ///
                legend(order(1 "Not selected" 2 "Selected"))
        }
    }

    /*
    Post e()-returns.
    */
    tempname b V

    matrix `b' = J(1,1,0)
    matrix colnames `b' = objective

    matrix `V' = J(1,1,0)
    matrix rownames `V' = objective
    matrix colnames `V' = objective

    ereturn post `b' `V', esample(`touse')

    ereturn scalar N         = `N'
    ereturn scalar lambda    = `lambda'
    ereturn scalar nselect   = `nselect'
    ereturn scalar npoints   = `npoints'

    ereturn scalar npolicies = ///
        cond(`nselect' == 1, `npoints', `npoints' * `npoints')

    ereturn scalar x1_min = `x1min'
    ereturn scalar x1_max = `x1max'

    if `nselect' == 2 {
        ereturn scalar x2_min = `x2min'
        ereturn scalar x2_max = `x2max'
    }

    ereturn scalar threshold1     = `bestg1'
    ereturn scalar threshold1_lev = `bestg1_lev'

    if `nselect' == 2 {
        ereturn scalar threshold2     = `bestg2'
        ereturn scalar threshold2_lev = `bestg2_lev'
    }

    /*
    First-best returns.
    */
    ereturn scalar N_fb             = `N_fb'
    ereturn scalar coverage_fb      = `coverage_fb'
    ereturn scalar total_benefit_fb = `TB_fb'
    ereturn scalar total_cost_fb    = `TC_fb'
    ereturn scalar Q_fb             = `Q_fb'
    ereturn scalar ATET_fb          = `ATET_fb'
    ereturn scalar avg_cost_fb      = `avgcost_fb'
    ereturn scalar avg_surplus_fb   = `avgsurp_fb'

    /*
    Optimal threshold policy returns.
    */
    ereturn scalar N_opt             = `N_opt'
    ereturn scalar coverage_opt      = `coverage_opt'
    ereturn scalar total_benefit_opt = `TB_opt'
    ereturn scalar total_cost_opt    = `TC_opt'
    ereturn scalar Q_opt             = `Q_opt'
    ereturn scalar ATET_opt          = `ATET_opt'
    ereturn scalar avg_cost_opt      = `avgcost_opt'
    ereturn scalar avg_surplus_opt   = `avgsurp_opt'

    /*
    Welfare loss relative to first-best.
    */
    ereturn scalar Q_loss = `Q_fb' - `Q_opt'

    if `Q_fb' > 0 {
        ereturn scalar Q_ratio = `Q_opt' / `Q_fb'
    }
    else {
        ereturn scalar Q_ratio = .
    }

    /*
    User-supplied customized policy returns.
    */
    ereturn scalar has_custompolicy = `has_custompolicy'

    if "`custompolicy'" != "" {

        ereturn scalar N_custompolicy = ///
            `N_custompolicy'

        ereturn scalar coverage_custompolicy = ///
            `coverage_custompolicy'

        ereturn scalar total_benefit_custompolicy = ///
            `TB_custompolicy'

        ereturn scalar total_cost_custompolicy = ///
            `TC_custompolicy'

        ereturn scalar Q_custompolicy = ///
            `Q_custompolicy'

        ereturn scalar ATET_custompolicy = ///
            `ATET_custompolicy'

        ereturn scalar avg_cost_custompolicy = ///
            `avgcost_custompolicy'

        ereturn scalar avg_surplus_custompolicy = ///
            `avgsurp_custompolicy'

        ereturn scalar Q_loss_custompolicy = ///
            `Q_fb' - `Q_custompolicy'

        if `Q_fb' > 0 {
            ereturn scalar Q_ratio_custompolicy = ///
                `Q_custompolicy' / `Q_fb'
        }
        else {
            ereturn scalar Q_ratio_custompolicy = .
        }

        ereturn matrix custompolicy = `CUSTOMPOLICYMAT'
        ereturn local custompolicyvar "`custompolicy'"
    }

    ereturn matrix grid = `GRID'

    if "`custom'" != "" {
        ereturn matrix custom = `CUSTOMMAT'
    }

    ereturn local cmd "opl_tb_cba"
    ereturn local cmdline `"`0'"'
    ereturn local tauvar "`tau'"
    ereturn local costvar "`cost'"
    ereturn local selectvars "`select'"
    ereturn local policytype "threshold"
    ereturn local direction "upper"
    ereturn local generate "`generate'"

    /*
    Display main comparison.
    */
    di as text _newline ///
        "Welfare-maximizing threshold policy"

    di as text "{hline 78}"

    di as text ///
        "Objective: sum_i pi_i * (tau_i - lambda * cost_i)"

    di as text ///
        "lambda = " as result %9.4f `lambda'

    di as text "{hline 78}"

    di as text ///
        %30s "Statistic"            ///
        %20s "First best"           ///
        %20s "Constrained"

    di as text "{hline 78}"

    di as text ///
        %30s "Treated units"        ///
        as result %20.0f `N_fb'     ///
        %20.0f `N_opt'

    di as text ///
        %30s "Coverage"             ///
        as result %20.4f `coverage_fb' ///
        %20.4f `coverage_opt'

    di as text ///
        %30s "Total benefit"        ///
        as result %20.4f `TB_fb'    ///
        %20.4f `TB_opt'

    di as text ///
        %30s "Total cost"           ///
        as result %20.4f `TC_fb'    ///
        %20.4f `TC_opt'

    di as text ///
        %30s "Weighted surplus Q"   ///
        as result %20.4f `Q_fb'     ///
        %20.4f `Q_opt'

    di as text ///
        %30s "ATET"                 ///
        as result %20.4f `ATET_fb'  ///
        %20.4f `ATET_opt'

    di as text ///
        %30s "Average cost"         ///
        as result %20.4f `avgcost_fb' ///
        %20.4f `avgcost_opt'

    di as text ///
        %30s "Average surplus"      ///
        as result %20.4f `avgsurp_fb' ///
        %20.4f `avgsurp_opt'

    di as text "{hline 78}"

    /*
    Display user-supplied policy.
    */
    if "`custompolicy'" != "" {

        di as text _newline ///
            "User-supplied customized policy: " ///
            as result "`custompolicy'"

        di as text "{hline 58}"

        di as text ///
            %30s "Statistic"        ///
            %20s "Customized policy"

        di as text "{hline 58}"

        di as text ///
            %30s "Treated units"    ///
            as result %20.0f `N_custompolicy'

        di as text ///
            %30s "Coverage"         ///
            as result %20.4f `coverage_custompolicy'

        di as text ///
            %30s "Total benefit"    ///
            as result %20.4f `TB_custompolicy'

        di as text ///
            %30s "Total cost"       ///
            as result %20.4f `TC_custompolicy'

        di as text ///
            %30s "Weighted surplus Q" ///
            as result %20.4f `Q_custompolicy'

        di as text ///
            %30s "ATET"             ///
            as result %20.4f `ATET_custompolicy'

        di as text ///
            %30s "Average cost"     ///
            as result %20.4f `avgcost_custompolicy'

        di as text ///
            %30s "Average surplus"  ///
            as result %20.4f `avgsurp_custompolicy'

        di as text "{hline 58}"
    }

    /*
    Display optimal thresholds.
    */
    if `bestg1' < . {

        di as text ///
            "Optimal standardized threshold 1: " ///
            as result %7.4f `bestg1'

        di as text ///
            "Optimal original-scale threshold 1: " ///
            as result %10.4f `bestg1_lev'
    }
    else {

        di as text ///
            "Optimal constrained policy: " ///
            as result "treat none"
    }

    if `nselect' == 2 & `bestg2' < . {

        di as text ///
            "Optimal standardized threshold 2: " ///
            as result %7.4f `bestg2'

        di as text ///
            "Optimal original-scale threshold 2: " ///
            as result %10.4f `bestg2_lev'
    }
end


*! version 1.1.0 14jul2026
capture program drop opl_tb_cba__eval
program define opl_tb_cba__eval, rclass
    version 18.0

    syntax,                                                 ///
        POLICY(varname numeric)                             ///
        TAU(varname numeric)                                ///
        COST(varname numeric)                               ///
        LAMBDA(real)                                        ///
        TOUSE(varname numeric)

    quietly count if `touse'
    local N = r(N)

    quietly count if `touse' & `policy' == 1
    local Nt = r(N)

    if `Nt' == 0 {

        return scalar N_treated    = 0
        return scalar coverage     = 0
        return scalar total_benefit = 0
        return scalar total_cost    = 0
        return scalar Q             = 0
        return scalar ATET          = .
        return scalar avg_cost      = .
        return scalar avg_surplus   = .

        exit
    }

    quietly summarize `tau' if ///
        `touse' & `policy' == 1, meanonly

    local TB   = r(sum)
    local ATET = r(mean)

    quietly summarize `cost' if ///
        `touse' & `policy' == 1, meanonly

    local TC = r(sum)
    local AC = r(mean)

    local Q = `TB' - `lambda' * `TC'

    return scalar N_treated     = `Nt'
    return scalar coverage      = `Nt' / `N'
    return scalar total_benefit = `TB'
    return scalar total_cost    = `TC'
    return scalar Q             = `Q'
    return scalar ATET          = `ATET'
    return scalar avg_cost      = `AC'
    return scalar avg_surplus   = `Q' / `Nt'
end
