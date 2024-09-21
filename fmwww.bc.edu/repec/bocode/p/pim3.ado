*! | Version: 1.2 | Last Updated: August 18, 2024
/*----------------------------------------------------------------------------*\
|   PIM3 Score Calculator - a statistical package designed to calculate        |
|       the Paediatric Index of Mortality 3 score.                             |
|                                                                              |
|   For help, please see help pim3.                                            |
|   Additional information available at:                                       |
|       https://azamfirei.com/pim3                                             |
|                                                                              |
|   Version: 1.2 | Created: November 12, 2023 | Last Updated: August 18, 2024  |
|   Author: Razvan Azamfirei - stata@azamfirei.com                             |
|                                                                              |
|   LICENSE:                                                                   |
|   Copyright 2024 Razvan Azamfirei                                            |
|                                                                              |
|       Licensed under the Apache License, Version 2.0 (the"License"); you may |
|       not use this file except in compliance with the License. You may obtain|
|       a copy of the License at:                                              |
|           http://www.apache.org/licenses/LICENSE-2.0                         |
|       Unless required by applicable law or agreed to in writing, software    |
|       distributed under the License is distributed on an "AS IS" BASIS,      |
|       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or        |
|       implied.                                                               |
|                                                                              |
|    See the License for the specific language governing permissions and       |
|    limitations under the License.                                            |
\*----------------------------------------------------------------------------*/
cap program drop pim3
program pim3
    preserve

*** Check Stata version compatibility
if (c(stata_version) < 17) {
    di as txt "Note: this command is written " ///
        "and comprehensively tested for Stata release 17.0 or higher."
    di as txt "The command was tested on Stata 12.0 with no " ///
        "issues. However, a comprehensive validation was not performed."

    if (c(stata_version) >= 12) {
        di as txt "There are no technical reasons preventing this " ///
            "command from working with Stata version " ///
            "`c(stata_version)'. However no guarantees are made."
    }
    else {
        di as txt "The command might not work properly with " ///
            "Stata version `c(stata_version)'"
    }
    loc vers = c(stata_version)
}
else loc vers 17
version `vers'

novarabbrev {
    qui {
/*----------------------------------------------------------------------------*/
        loc cat_vars pupils elective procedure mv
        loc cat_vars_opt lowrisk highrisk veryhighrisk risk
        loc num_vars sbp fio2 pao2 baseexcess
        loc score_vars elective_score baseexcess_score fp_score mv_score     ///
            risk_score procedure_score pupils_score sbp_score sbp_square_score
        loc all_vars `cat_vars' `num_vars'
        loc options imputation validation trace simple
        loc results pim_intermediate pim_final
        loc scalars coef_intercept                                           ///
            coef_baseexcess coef_elective coef_fp coef_mv coef_pupils        ///
            coef_procedure0 coef_procedure1 coef_procedure2 coef_procedure3  ///
            coef_risk0 coef_risk1 coef_risk2 coef_risk3                      ///
            coef_sbp coef_sbp_square                                         ///
            sbpoor0 sbpoor1 pao2oor0 pao2oor1 fio2oor0 fio2oor1
        loc help_msg "See help pim3 for more details."

/*----------------------------------------------------------------------------*/

        syntax newvarname(generate) [if] [in],                               ///
            PUPils(varname numeric)                                          ///
            elective(varname numeric)                                        ///
            mv(varname numeric)                                              ///
            BASEexcess(varname numeric)                                      ///
            Sbp(varname numeric)                                             ///
            Fio2(varname numeric)                                            ///
            pao2(varname numeric)                                            ///
            PROCedure(varname numeric)                                       ///
            [LOWRisk(varname numeric)                                        ///
            HIGHRisk(varname numeric)                                        ///
            VERYHIGHRisk(varname numeric)]                                   ///
            [RISK(varname numeric)]                                          ///
            [SIMple]                                                         ///
            [noIMPutation] [noVALidation] [TRACE]

        marksample touse, nov

/*----------------------------------------------------------------------------*/

        tempname `options'
        tempvar `results'

        sca imputationoption = 1
        sca traceoption = 0
        sca simpleoption = 0
        sca validationoption = 1

        /* Get Option State */

        if "`trace'" != "" {
            set tr on
            sca traceoption = 1
        }

        if "`imputation'" != "" {
            sca imputationoption = 0
        }

        if "`validation'" != "" {
            sca validationoption = 0
        }

        if "`simple'" != "" {
            di as error "The simplified version of the PIM3 score has been"  ///
                "removed from this package."
            err 499
        }

        /* Get Target Variable */

        foreach var in `varlist' {
            loc pim3var `var'
        }

        /* Define Variables and Avoid Name Collisions  */

        foreach score in `score_vars' {
            tempvar `score'
        }

        foreach var in `all_vars' {
            tempvar `var'_i
        }

        foreach var in `cat_vars' `num_vars' {
            gen ``var'_i' = ``var''
            tempvar `var'
            gen ``var'' = ``var'_i'
            drop ``var'_i'
        }

        foreach var in `cat_vars_opt' {
            capture {
                gen ``var'_i' = ``var''
                tempvar `var'
                gen ``var'' = ``var'_i'
                drop ``var'_i'
            }
        }


        foreach score in `score_vars' {
            if imputationoption == 1 {
                gen ``score'' = 0
            }
            else {
                gen ``score'' = .
            }
        }

        /* Set Bounds */

        tempname `scalars'
        sca coef_intercept = -1.7928

        sca coef_pupils = 3.8233
        sca coef_elective = -0.5378
        sca coef_mv = 0.9763
        sca coef_baseexcess = 0.0671
        sca coef_sbp = -0.0431
        sca coef_sbp_square = 0.1716
        sca coef_fp = 0.4214
        sca coef_procedure0 = 0
        sca coef_procedure1 = -1.2246
        sca coef_procedure2 = -0.8762
        sca coef_procedure3 = -1.5164
        sca coef_risk0 = 0
        sca coef_risk1 = -2.1766
        sca coef_risk2 = 1.0725
        sca coef_risk3 = 1.6225

        sca sbpoor0 = 0
        sca sbpoor1 = 250
        sca pao2oor0 = 1
        sca pao2oor1 = 600
        sca fio2oor0 = 21
        sca fio2oor1 = 100


/*----------------------------------------------------------------------------*/

        /* Binary Format Confirmation  */

        loc binary_var pupils elective mv `lowrisk' `highrisk' `veryhighrisk'
        foreach var in `binary_var' {
            cou if !inlist(``var'', 0, 1, .)
            if r(N) != 0 {
                di as err "`var' is not binary. `help_msg'"
                err 450
            }
            if imputationoption == 1 {
                cou if ``var'' == .
                if r(N) != 0 {
                    di as res "Some `var' values missing and default values "///
                        "were used. `help_msg'"
                }
            }
        }

        /* Risk Format Confirmation */

        loc risk_variables `lowrisk' `highrisk' `veryhighrisk' `risk'
        loc risk_index: list sizeof risk_variables
        if inlist(`risk_index', 2, 4) {
            di as err "Incorrect number of risk variables specified."
            err 499
        }

        cap conf v `risk'
        if _rc != 0 {
            if inlist(`risk_index', 0, 1) {
                di as err "You must specify a risk variable."
                err 499
            }
            tempvar combined_risk
            gen `combined_risk' = 0
            replace `combined_risk' = 1 if `lowrisk' == 1
            replace `combined_risk' = 2 if `highrisk' == 1
            replace `combined_risk' = 3 if `veryhighrisk' == 1
            forvalues x = 0(1)3 {
                replace `risk_score' = coef_risk`x' if `combined_risk' == `x'
            }
        }
        else if _rc == 0 {
            if `risk_index' == 3 | `risk_index' == 4 {
                di as err "You must specify either risk or the risk "        ///
                    "stratification variables."
                err 499
            }
            cou if !inlist(`risk', 0, 1, 2, 3, .)
            if r(N) != 0 {
                di as err "The risk variable (`risk') is not in the correct" ///
                    "format. `help_msg'"
                err 499
            }
            cou if inlist(`risk', 2, 3)
            if r(N) == 0 {
                noi {
                    di ,
                    di as res "Your risk variable may not be in the correct" ///
                        " format."
                    di as res "Make sure you want to use this format and not"///
                        " the lowrisk, highrisk and veryhighrisk options."
                    di as res "`help_msg'"
                    di ,
                }
            }
            forvalues x = 0(1)3 {
                replace `risk_score' = coef_risk`x' if `risk' == `x'
            }
        }

        cou if !inlist(`procedure', 0, 1, 2, 3, .)
        if r(N) != 0 {
            di as err "Procedure (`procedure') is not in the correct format."///
                "`help_msg'"
            err 499
        }
        if imputationoption == 1 {
            cou if `procedure' == .
            if r(N) != 0 {
                di as res "Some `procedure' values missing and default "     ///
                    "values were used. `help_msg'"
            }
        }

        replace `fio2' = `fio2' * 100 if inrange(`fio2', float(0.21), float(1))

        /* OOB Data Validation  */

        if validationoption == 1 {
            noi {
                di as text "The following lists out-of-range values:"

                di as text _con "SBP" _col(10)
                replace `sbp' = . if !inrange(`sbp', sbpoor0, sbpoor1)

                di as text _con "PaO2" _col(10)
                replace `pao2' = . if !inrange(`pao2', pao2oor0, pao2oor1)

                di as text _con "FiO2" _col(10)
                replace `fio2' = . if !inrange(`fio2', fio2oor0, fio2oor1)
            }
        }

/*----------------------------------------------------------------------------*/

        /* Rounding to whole number where appropriate  */

        replace `pao2' = round(`pao2', 1)
        replace `fio2' = round(`fio2', 1)
        replace `baseexcess' = round(abs(`baseexcess'), 0.01)

        /* Score Calculation  */

        replace `pupils_score' = `pupils' * coef_pupils
        replace `sbp_score' = `sbp' * coef_sbp
        replace `sbp_square_score' = ((`sbp'^2)/1000) * coef_sbp_square
        replace `fp_score' = (`fio2'/`pao2') * coef_fp
        forvalues x = 0(1)3 {
            replace `procedure_score' = coef_procedure`x' if `procedure' == `x'
        }
        replace `elective_score' = `elective' * coef_elective
        replace `mv_score' = `mv' * coef_mv
        replace `baseexcess_score' = `baseexcess' * coef_baseexcess

/*----------------------------------------------------------------------------*/

        /* Numeric Score  */

        tempvar pim_score
        egen `pim_score' = rowtotal(`pupils_score' `elective_score'          ///
            `mv_score' `baseexcess_score' `sbp_score' `sbp_square_score'     ///
            `fp_score' `procedure_score' `risk_score')
        replace `pim_score' = `pim_score' + coef_intercept
        if imputationoption == 0 {
            tempvar missing
            egen `missing' = rowmiss(`pupils_score' `elective_score'         ///
                `mv_score' `baseexcess_score' `sbp_score' `sbp_square_score' ///
                `fp_score' `procedure_score' `risk_score')
            replace `pim_score' = . if missing != 0
        }

/*----------------------------------------------------------------------------*/

        /* Logistic Transformation and Rounding  */

        gen double `pim_final' =                                             ///
            round(100 / (1 + exp(-`pim_score')), 0.01) if `touse'

        /* Asign to Permanent Variable  */

        replace `pim3var' = `pim_final' if `touse'

/*----------------------------------------------------------------------------*/

        if traceoption == 1 {
            set tr off
        }
        scalar drop `scalars'
    }
    }

/*----------------------------------------------------------------------------*/

    di as text _newline "Calculation completed successfully." _continue
    restore, not
end
