*! | Version: 1.2 | Last Updated: August 18, 2024
/*----------------------------------------------------------------------------*\
|   PELOD-2 Score Calculator - a statistical package designed to calculate     |
|       the Pediatric Logistic Organ Dysfunction-2 score.                      |
|                                                                              |
|   For help, please see help pelod2.                                          |
|   Additional information available at:                                       |
|       https://azamfirei.com/pelod2                                           |
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
cap program drop pelod2
program pelod2
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
        loc cat_vars pupils mv
        loc num_vars map lactate gcs wbc plt creatinine pco2
        loc num_vars_opt fio2 pao2 pfratio
        loc score_vars map_score lactate_score pupils_score                  ///
            gcs_score mv_score pco2_score wbc_score plt_score pfratio_score  ///
            creatinine_score pelod_score
        loc all_vars `cat_vars' `num_vars' `num_vars_opt'
        loc options sioption wbcoption plateletoption noimputation           ///
            rawscoreoption validation trace
        loc results pelod_intermediate pelod_final
        loc scalars coef_intercept coef_score                                ///
            age0_high age0_low age1_high age1_low age2_high age2_low         ///
            age3_high age3_low age4_high age4_low age5_low                   ///
            age0_map_high age0_map_low age0_map_medium age0_map_medium2      ///
            age1_map_high age1_map_low age1_map_medium age1_map_medium2      ///
            age2_map_high age2_map_low age2_map_medium age2_map_medium2      ///
            age3_map_high age3_map_low age3_map_medium age3_map_medium2      ///
            age4_map_high age4_map_low age4_map_medium age4_map_medium2      ///
            age5_map_high age5_map_low age5_map_medium age5_map_medium2      ///
            cr0 cr1 cr2 cr3 cr4 cr5 plt0 plt1 wbc0 gcs0 gcs1 lac0 lac1       ///
            fio2oor0 fio2oor1 pao2oor0 pao2oor1 pco20 pco21 pfr0             ///
            mapoor0 mapoor1
        loc help_msg "See help pelod2 for more details."

/*----------------------------------------------------------------------------*/

        syntax newvarname(generate) [if] [in],                               ///
            [age(varname num)] [dob(varname)] [doa(varname)]                 ///
            map(varname numeric)                                             ///
            lactate(varname numeric)                                         ///
            PUPils(varname numeric)                                          ///
            GCS(varname numeric)                                             ///
            [Fio2(varname numeric)                                           ///
            pao2(varname numeric)                                            ///
            pfratio(varname numeric)]                                        ///
            pco2(varname numeric)                                            ///
            mv(varname numeric)                                              ///
            WBC(varname numeric)                                             ///
            CReatinine(varname numeric)                                      ///
            PLT(varname numeric)                                             ///
            [WBCUnit(int 1)] [PLTUnit(int 1)] [si]                           ///
            [RAWscore(name)]                                                 ///
            [noIMPutation] [noVALidation] [TRACE]

        marksample touse, nov

/*----------------------------------------------------------------------------*/

        tempname `options'
        tempvar `results'
        tempvar calculated_age age dob doa

        sca imputationoption = 1
        sca traceoption = 0
        sca validationoption = 1

        sca rawscoreoption = 0

        sca sioption = 0
        sca plateletoption = 1
        sca wbcoption = 1

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

        if "`si'" != "" {
            sca sioption = 1
        }

        /* Get Target Variable */

        foreach var in `varlist' {
            loc pelod2var `var'
        }

        if "`rawscore'" != "" {
            sca rawscoreoption = 1
            loc rawscorevar `rawscore'
        }

        /* Define Variables and Avoid Name Collisions  */

        foreach score in `score_vars' {
            tempvar `score'
        }

        foreach var in `all_vars' {
            tempvar `var'_i
        }

        foreach var in `cat_vars' `num_vars'  {
            gen ``var'_i' = ``var''
            tempvar `var'
            gen ``var'' = ``var'_i'
            drop ``var'_i'
        }

        foreach var in `num_vars_opt' {
            capture {
                gen``var'_i' = ``var''
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
        sca coef_intercept = -6.61
        sca coef_score = 0.47

        /* Age Bounds -- days */
        sca age0_low = 0
        sca age0_high = 30
        sca age1_low = 31
        sca age1_high = 365
        sca age2_low = 366
        sca age2_high = 730
        sca age3_low = 731
        sca age3_high = 1825
        sca age4_low = 1826
        sca age4_high = 4380
        sca age5_low = 4381

        /* MAP Bounds (by age) */
        sca age0_map_low = 17
        sca age0_map_medium = 30
        sca age0_map_medium2 = 31
        sca age0_map_high = 45
        sca age1_map_low = 25
        sca age1_map_medium = 38
        sca age1_map_medium2 = 39
        sca age1_map_high = 54
        sca age2_map_low = 31
        sca age2_map_medium = 43
        sca age2_map_medium2 = 44
        sca age2_map_high = 59
        sca age3_map_low = 32
        sca age3_map_medium = 44
        sca age3_map_medium2 = 45
        sca age3_map_high = 61
        sca age4_map_low = 36
        sca age4_map_medium = 48
        sca age4_map_medium2 = 49
        sca age4_map_high = 64
        sca age5_map_low = 38
        sca age5_map_medium = 51
        sca age5_map_medium2 = 52
        sca age5_map_high = 66

        /* GCS Bounds */

        sca gcs0 = 5
        sca gcs1 = 10

        /* Respiratory Bounds */

        sca pfr0 = 60
        sca pco20 = 59
        sca pco21 = 94

        /* Heme Bounds (cells/mL) */

        sca wbc0 = 2000
        sca plt0 = 77000
        sca plt1 = 141000

        /* Out of Range Bounds */

        sca mapoor0 = 0
        sca mapoor1 = 200
        sca pao2oor0 = 1
        sca pao2oor1 = 600
        sca fio2oor0 = float(0.21)
        sca fio2oor1 = float(1)
        sca gcsoor0 = 3
        sca gcsoor1 = 15

        /* Bounds for Laboratory Values with Multiple Units */

        sca cr_conversion_factor = 0.0113
        sca lactate_conversion_factor = 0.111
        if sioption == 1 {
            sca cr0 = float(70)
            sca cr1 = float(23)
            sca cr2 = float(35)
            sca cr3 = float(51)
            sca cr4 = float(59)
            sca cr5 = float(93)

            sca lac0 = float(5.0)
            sca lac1 = float(10.9)
        }
        else {
            sca cr0 = float(70 * cr_conversion_factor)
            sca cr1 = float(23 * cr_conversion_factor)
            sca cr2 = float(35 * cr_conversion_factor)
            sca cr3 = float(51 * cr_conversion_factor)
            sca cr4 = float(59 * cr_conversion_factor)
            sca cr5 = float(93 * cr_conversion_factor)

            sca lac0 = float(5.0 * lactate_conversion_factor)
            sca lac1 = float(10.9 * lactate_conversion_factor)
        }

        /* Updates Platelet and WBC Bounds  */

        if `pltunit' == 1000 {
            sca plateletoption = 1000
        }
        if `wbcunit' == 1000 {
            sca wbcoption = 1000
        }
        if `pltunit' != 1 & `pltunit' != 1000 & !missing(`pltunit') {
            di as err "Platelet Unit incorrectly specified."
            err 499
        }
        if `wbcunit' != 1 & `wbcunit' != 1000 & !missing(`wbcunit') {
            di as err "WBC Unit incorrectly specified."
            err 499
        }
        forvalues x = 0(1)1 {
            sca plt`x' = plt`x' / plateletoption
        }
        sca wbc0 = wbc0 / wbcoption

/*----------------------------------------------------------------------------*/

        /* Age Format Confirmation */

        cap conf numeric v `age'
        if _rc != 0 {
            sca ag1 = 0
        }
        else {
            sca ag1 = 1
        }

        cap conf numeric v `dob'
        if _rc != 0 {
            sca ag2 = 0
        }
        else {
            sca ag2 = 1
        }

        cap conf numeric v `doa'
        if _rc != 0 {
            sca ag3 = 0
        }
        else {
            sca ag3 = 1
        }

        sca ag4 = ag2 + ag3

        if ag1 == 1 & ag4 == 0 {
            sca agecase = 1
        }
        if ag1 == 1 & inrange(ag4, 1, 2) {
            sca agecase = 2
        }
        if ag1 == 0 & ag4 == 0 {
            sca agecase = 3
        }
        if ag1 == 0 & ag4 == 1 {
            sca agecase = 4
        }
        if ag1 == 0 & ag4 == 2 {
            sca agecase = 5
        }
        if agecase == 2 {
            di as err "Both age, DoB and DoA are specified."
            di as err "Specify either age or DoB and DoA"
            err 103
        }
        if agecase == 3 {
            di as err "Neither age, DoB or DoA are specified."
            di as err "Specify either age or DoB and DoA"
            err 102
        }
        if agecase == 4 {
            di as err "You must specify both DoB and DoA"
            err 102
        }

        if agecase == 1 {
            cou if !inlist(`age', 0, 1, 2, 3, 4, 5, .)
            if r(N) != 0 {
                di as err "Age is not in the correct format. `help_msg'"
                err 498
            }
        }

        if agecase == 5 {
            gen `calculated_age' = datediff(`dob', `doa', "d")
            cap as `calculated_age' >= 0, fast
            if _rc != 0 {
                di as err "Calculated age is negative. Observations will "   ///
                    "be ignored."
            }
            tempvar age
            gen `age' = 0 if inrange(`calculated_age', age0_low, age0_high)
            replace `age' = 1 if inrange(`calculated_age', age1_low, age1_high)
            replace `age' = 2 if inrange(`calculated_age', age2_low, age2_high)
            replace `age' = 3 if inrange(`calculated_age', age3_low, age3_high)
            replace `age' = 4 if inrange(`calculated_age', age4_low, age4_high)
            replace `age' = 5 if inrange(`calculated_age', age5_low, .)
        }

        /* Binary Format Confirmation  */

        foreach var in mv pupils {
            cou if !inlist(``var'', 0, 1, .)
            if r(N) != 0 {
                di as err "`var' is not binary. `help_msg'"
                err 450
            }
            if imputationoption == 1 {
                cou if ``var'' == .
                if r(N) != 0 {
                    di as err "Some `var' values missing and default values were used. `help_msg'"
                }
            }
        }


        qui replace `fio2' = `fio2'/100 if inrange(`fio2', 21, 100)

        /* OOB Data Validation  */

        if validationoption == 1 {
            noi {
                di "Checking for out-of-range values..."
                di as text "The following lists out-of-range values:"

                di "GCS"
                replace `gcs' = . if !inrange(`gcs', gcsoor0, gcsoor1)

                di as text "MAP"
                replace `map' = . if !inrange(`map', mapoor0, mapoor1)

                capture confirm v `pao2'
                if _rc == 0 {
                    di as text "PaO2"
                    replace `pao2' = . if !inrange(`pao2', pao2oor0, pao2oor1)
                }
                capture confirm v `fio2'
                if _rc == 0 {
                    di as text "FiO2"
                    replace `fio2' = . if                            ///
                        !inrange(`fio2', fio2oor0, fio2oor1)
                }
            }
        }

/*----------------------------------------------------------------------------*/
        /* Rounding to whole number where appropriate  */

        replace `pco2' = round(`pco2', 1)
        replace `plt' = round(`plt', 1000 / plateletoption)
        if sioption == 1 {
            replace `creatinine' = round(`creatinine', 1)
        }

        /* Calculating PF Ratio if not provided  */

        capture confirm v `pfratio'
        if _rc != 0 {
            tempname pfratio
            gen `pfratio' = .
            replace `pfratio' = `pao2'/`fio2' if !missing(`pao2') &          ///
                !missing(`fio2') & missing(`pfratio')
            replace `pfratio' = round(`pfratio', 1)
        }
        else {
            replace `pfratio' = round(`pfratio', 1)
        }

        /* Score Calculation  */

        replace `gcs_score' = 4 if `gcs' <= gcs0 & !missing(`gcs')
        replace `gcs_score' = 1 if inrange(`gcs', gcs0, gcs1)
        replace `gcs_score' = 0 if `gcs' >= gcs1 & !missing(`gcs')

        replace `pupils_score' = 5 if `pupils' == 1 & !missing(`pupils')
        replace `pupils_score' = 0 if `pupils' == 0 & !missing(`pupils')

        replace `pfratio_score' = 2 if `pfratio' <= pfr0 & !missing(`pfratio')
        replace `pfratio_score' = 0 if `pfratio' > pfr0 & !missing(`pfratio')

        replace `pco2_score' = 3 if `pco2' > pco21 & !missing(`pco2')
        replace `pco2_score' = 1 if inrange(`pco2', pco20, pco21)
        replace `pco2_score' = 0 if `pco2' < pco20 & !missing(`pco2')

        replace `mv_score' = 3 if `mv' == 1
        replace `mv_score' = 0 if `mv' == 0

        replace `wbc_score' = 2 if `wbc' <= wbc0 &  !missing(`wbc')
        replace `wbc_score' = 0 if `wbc' > wbc0 & !missing(`wbc')

        replace `plt_score' = 2 if `plt' < plt0 & !missing(`plt')
        replace `plt_score' = 1 if inrange(`plt', plt0, plt1)
        replace `plt_score' = 0 if `plt' > plt1 & !missing(`plt')

        replace `lactate_score' = 4 if `lactate' >= lac1 & !missing(`lactate')
        replace `lactate_score' = 1 if `lactate' >= lac0 & `lactate' <  lac1
        replace `lactate_score' = 0 if `lactate' < lac0 & !missing(`lactate')

        replace `map_score' = 6 if (                                         ///
            (`age' == 0 & `map' < age0_map_low) |                            ///
            (`age' == 1 & `map' < age1_map_low) |                            ///
            (`age' == 2 & `map' < age2_map_low) |                            ///
            (`age' == 3 & `map' < age3_map_low) |                            ///
            (`age' == 4 & `map' < age4_map_low) |                            ///
            (`age' == 5 & `map' < age5_map_low)                              ///
            ) & !missing(`map')

        replace `map_score' = 3 if (    ///
            (`age' == 0 & inrange(`map', age0_map_low, age0_map_medium)) |   ///
            (`age' == 1 & inrange(`map', age1_map_low, age1_map_medium)) |   ///
            (`age' == 2 & inrange(`map', age2_map_low, age2_map_medium)) |   ///
            (`age' == 3 & inrange(`map', age3_map_low, age3_map_medium)) |   ///
            (`age' == 4 & inrange(`map', age4_map_low, age4_map_medium)) |   ///
            (`age' == 5 & inrange(`map', age5_map_low, age5_map_medium))     ///
            ) & !missing(`map')

        replace `map_score' = 2 if (    ///
            (`age' == 0 & inrange(`map', age0_map_medium2, age0_map_high)) | ///
            (`age' == 1 & inrange(`map', age1_map_medium2, age1_map_high)) | ///
            (`age' == 2 & inrange(`map', age2_map_medium2, age2_map_high)) | ///
            (`age' == 3 & inrange(`map', age3_map_medium2, age3_map_high)) | ///
            (`age' == 4 & inrange(`map', age4_map_medium2, age4_map_high)) | ///
            (`age' == 5 & inrange(`map', age5_map_medium2, age5_map_high))   ///
            ) & !missing(`map')

        replace `map_score' = 0 if (                                         ///
            (`age' == 0 & `map' > age0_map_high) |                           ///
            (`age' == 1 & `map' > age1_map_high) |                           ///
            (`age' == 2 & `map' > age2_map_high) |                           ///
            (`age' == 3 & `map' > age3_map_high) |                           ///
            (`age' == 4 & `map' > age4_map_high) |                           ///
            (`age' == 5 & `map' > age5_map_high)                             ///
            ) & !missing(`map')

        replace `creatinine_score' = 2 if (                                  ///
            (`age' == 0 & `creatinine' >= cr0) |                             ///
            (`age' == 1 & `creatinine' >= cr1) |                             ///
            (`age' == 2 & `creatinine' >= cr2) |                             ///
            (`age' == 3 & `creatinine' >= cr3) |                             ///
            (`age' == 4 & `creatinine' >= cr4) |                             ///
            (`age' == 5 & `creatinine' >= cr5)                               ///
            ) & !missing(`creatinine')

        replace `creatinine_score' = 0 if (                                  ///
            (`age' == 0 & `creatinine' < cr0) |                              ///
            (`age' == 1 & `creatinine' < cr1) |                              ///
            (`age' == 2 & `creatinine' < cr2) |                              ///
            (`age' == 3 & `creatinine' < cr3) |                              ///
            (`age' == 4 & `creatinine' < cr4) |                              ///
            (`age' == 5 & `creatinine' < cr5)                                ///
            ) & !missing(`creatinine')


/*----------------------------------------------------------------------------*/
        /* Numeric Score  */

        tempvar pelod_score
        egen `pelod_score' = rowtotal(`map_score' `lactate_score'            ///
            `pupils_score' `gcs_score' `mv_score' `pco2_score' `wbc_score'   ///
            `plt_score' `pfratio_score' `creatinine_score')
        if imputationoption == 0 {
            tempvar missing
            egen `missing' = rowmiss(`map_score' `lactate_score'             ///
                `pupils_score' `gcs_score' `mv_score' `pco2_score'           ///
                `wbc_score' `plt_score' `pfratio_score' `creatinine_score')
            replace `pelod_score' = . if `missing' != 0
        }
        if rawscoreoption == 1 {
            gen `rawscorevar' = `pelod_score'
        }
/*----------------------------------------------------------------------------*/

        /* Mortality  */

        gen double `pelod_intermediate' = coef_intercept +                   ///
            (`pelod_score' * coef_score) if `touse'

        /* Logistic Transformation and Rounding  */

        gen double `pelod_final' =                                           ///
            round(100 / (1 + exp(-`pelod_intermediate')), 0.1) if `touse'

        /* Asign to Permanent Variable  */

        replace `pelod2var' = `pelod_final' if `touse'

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
