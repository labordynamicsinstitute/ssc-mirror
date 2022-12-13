*! | Version: 1.1 | Last Updated: Nov 28, 2022
/*----------------------------------------------------------------------------*\
|   PRISM Score Calculator - a statistical package designed to calculate       |
|       PRISM III & IV scores.                                                 |
|                                                                              |
|   For help, please see help prismscore.                                      |
|                                                                              |
|   Version: 1.1 | Created: Jul 28, 2022 | Last Updated: Nov 28, 2022          |
|   Author: Razvan Azamfirei - stata@azamfirei.com                             |
|                                                                              |
|                                                                              |
\*----------------------------------------------------------------------------*/
cap program drop    prismscore
    program         prismscore
    preserve
        if (c(stata_version) < 17) {
            di as txt "Note: this command is written " ///
            "and comprehensively tested for Stata release 17.0 or higher."
            di as txt "The command was tested on Stata 12.0 with no "///
            "issues. However, a comprehensive validation was not performed."
            di as txt "The command might not work properly with " ///
            "Stata version `c(stata_version)'"
            loc vers = c(stata_version)
        }
        else loc vers 17
    version `vers'
    
    novarabbrev {
    qui {   
********************************************************************************
 
    tempvar ageIV calculated_age age dob doa
    loc l_catvar3 sbp gcs hr pupils
    loc l_numvar3 temp  ph  bicarb  pco2 pao2 glucose potassium creatinine  ///
            bun wbc plt 
    loc l_numvar3opt templow phhigh bicarbhigh pt ptt
    loc l_catvar4 cpr cancer risk source
    loc l_scores sbp_score temperature_score hr_score acidosis_score        ///
            bicarb_score ph_score  pao2_score pco2_score glucose_score      ///
            potassium_score creatinine_score bun_score wbc_score coag_score ///
            platelet_score mentalstatus_score pupils_score
    loc l_scores4 age_score source_score
    loc l_allvars `l_catvar3' `l_numvar3' `l_numvar3opt' `l_catvar4'
    loc l_options prismivoption                 ///
            sioption tempoption                 ///
            wbcoption plateletoption            ///
            noimputationoption validationoption ///
            suppressoption                      ///
            traceoption 
    loc l_results neuroscore nonneuroscore prismintermediate ///
            prismfinal totalscore
    loc l_scalars intercept agecoef0 agecoef1 agecoef2 agecoef3 sourcecoef0 ///
            sourcecoef1 sourcecoef2 sourcecoef3 cprcoef cancercoef riskcoef ///
            neurocoef nonneurocoef ph0 ph1 ph2 ph3 bicarb0 bicarb1 bcarb2   ///
            pao20 pao21 pco20 pco21 sbp0 sbp1 sbp2 sbp3 sbp4 sbp5 tmp0 tmp1 ///
            gcs0 hr0 hr1 hr2 hr3 hr4 hr5 pt0 ptt0 ptt1 wbc0 glu0 cr0 cr1    ///
            cr2 bun0 bun1 plt0 plt1 plt2 plt3 rc1 rc2 rc3 ag1 ag2 ag3 ag4   ///
            agecase tmpoor0 tmpoor1 gluoor0 gluoor1 croor0 croor1 bunoor0   ///
            bunoor1 sbpoor0 sbpoor1 hroor0 hroor1 gcsoor0 gcsoor1 phoor0    ///
            phoor1 co2oor0 co2oor1 pco2oor0 pco2oor1 pao2oor0 pao2oor1      ///
            potoor0 potoor1 age0 age1 age2 age3 age4 age5 age6 age7 age8
    loc helpme "See help prismscore for more details."
    
********************************************************************************    

    syntax newvarlist(min=1 max=4 generate) [if] [in],      ///
        [age(varname num)] [dob(varname)] [doa(varname)]    ///
        Sbp(varname num) Hr(varname num)                    ///
        temp(varname num) [TEMPLow(varname num)]            ///
        Gcs(varname num)  PUPils(varname num)               ///
        ph(varname num) [PHHigh(varname num)]               ///
        bicarb(varname num) [BICARBHigh(varname num)]       ///
        PCo2(varname num) PAo2(varname num)                 ///
        GLUcose(varname num) POTassium(varname num)         ///
        Bun(varname num) CReatinine(varname num)            ///
        wbc(varname num) plt(varname num)                   ///
        [pt(varname num)] [ptt(varname num)]                ///
            [PRISMiv]                                       ///
                [cpr(varname num)] [CANcer(varname num)]    ///
                [Risk(varname num)] [SOUrce(varname num)]   ///
            [SI] [FAHRenheit]                               ///
            [WBCUnit(int 1)] [PLTUnit(int 1)]               ///
            [NOIMPutation] [NOVALidation]                   ///
            [SUPPress] [SUPPRESSAll]                        ///
        [TRACE]     
    
        marksample touse, nov

********************************************************************************    
    
/// Get Option State
 
    tempname `l_options'
    tempvar `l_results'

    if "`trace'" != "" {
        set tr on
        sca traceoption = 1
    }
    else {
        sca traceoption = 0
    }
    if "`noimputation'" != "" {
        sca noimputationoption = 1
    }
    else {
        sca noimputationoption = 0
    }   
    if "`suppressall'" != "" {
        sca suppressoption = 2
    }
    if "`suppress'" != "" & "`suppressall'" == "" {
        sca suppressoption = 1
    }
    if "`suppress'" == "" & "`suppressall'" == "" {
        sca suppressoption = 0
    }   
    if "`novalidation'" == "" {
        sca validationoption = 1
    }
    else {
        sca validationoption = 0
    }
    if suppressoption == 2 {
        sca validationoption = 0
    }
    if "`prismiv'" != "" {
        sca prismivoption = 1
    }
    else {
        sca prismivoption = 0
    }
    if "`si'" != "" {
        sca sioption = 1
    }
    else {
        sca sioption = 0
    }
    if "`fahrenheit'" != "" {
        sca tempoption = 1
    }
    else {
        sca tempoption = 0
    }
    
*------------------------------------------------------------------------------*
*   Parses varlist - Counts total number of variables, assign each variable a  *
*   number corresponding to its position and then assigns final vars.          *
*   Rules:                                                                     *
*       1. If calculating PRISM IV score you must have 1 newvar (becomes       *
*       PRISM IV or 4 vars for the PRISM III scores + PRISM IV score.          *
*                                                                              *
*       2. If calculating PRISM III scores you need to have 3 variables.       *
*------------------------------------------------------------------------------*
    
    loc i = 0
    cap {
        foreach var in `varlist' {
            loc i = `i' + 1
            loc newvar_`i' `var'
        }
    }
    if prismivoption == 1 {
        if `i' == 1 {
            loc prismivvar `newvar_1' // Holds PRISM IV score 
        }
        if inlist(`i',2,3) {
            di as err "You must specify either 1 or 4 new" _continue
            di as err "variable names if you are trying to" _continue
            di as err " calculate the PRISM IV score. `helpme'"
            err 498
        }
        if `i' == 4 {
            loc neurovar `newvar_1'
            loc nonneurovar `newvar_2'
            loc totalvar `newvar_3'
            loc prismivvar `newvar_4'
        }
    }
    if prismivoption == 0 {
        if inlist(`i', 1, 2) {
            di as err "You must specify 3 newvarvarnames for" _continue
            di as err " PRISM III score calculations. `helpme'"
            err 498
        }
        if `i' == 4 {
            di as err "You have specified too many newvarnames" _continue
            di as err "or have forgotten to include prismiv"
            err 498
        }
        if `i' == 3 {
            loc neurovar `newvar_1'
            loc nonneurovar `newvar_2'
            loc totalvar `newvar_3'
        }
    }

/// Defines Variables and Various Coefficients

    foreach score in `l_scores' `l_scores4' {
        tempvar `score'
    }
    foreach var in `l_allvars' dob doa age {        // Generates Temporary Names
        tempvar `var'_i                             // for all vars
    }

    foreach cat_var in `l_catvar3' {        // Generates PRISM III
        gen ``cat_var'_i' = ``cat_var''     // categorical vars
        tempvar `cat_var'
        gen ``cat_var'' = ``cat_var'_i'
        drop ``cat_var'_i'
    }
    foreach num_var in `l_numvar3opt' dob doa age { // Generates "optional"
        cap {                                       // PRISM III num vars
            gen ``num_var'_i' = ``num_var'' 
            tempvar `num_var'
            gen ``num_var'' = ``num_var'_i'
            drop ``num_var'_i'
        }
        continue
    }

    foreach num_var in `l_numvar3' {        // Generates required PRISM III 
        gen ``num_var'_i' = ``num_var''     // num vars
        tempvar `num_var'
        gen ``num_var'' = ``num_var'_i'
        drop ``num_var'_i' 
    }
    foreach score in `l_scores' {       // Generates placeholders for PRISM III
        gen ``score'' = 0               // sub-scores
    }
    if prismivoption == 1 {                 // If calculating PRISM IV
        foreach cat_var in `l_catvar4' {    // Generates PRISM IV vars
            cap {
                gen ``cat_var'_i' = ``cat_var'' if `touse'
                tempvar `cat_var'
                gen ``cat_var'' = ``cat_var'_i' if `touse'
                drop ``cat_var'_i'
                continue
            }
            if _rc != 0 & suppressoption != 2 {
                di as err "`x' not specified. `helpme'"
                err 102
            }
        }
        if noimputationoption == 1 {    
            foreach score in `l_scores4' {
                gen ``score'' = . if `touse'
            }
        }
        if noimputationoption == 0 {
            foreach score in `l_scores4' {
                gen ``score'' = 0 if `touse'
            }
        }
    }
//  Sets coefficients and bounds

    tempname `l_scalars' 

        // PRISM IV coefficients - Change this
        sca intercept = -5.776
        sca agecoef0 = 1.311
        sca agecoef1 = 0.968
        sca agecoef2 = 0.357
        sca agecoef3 = 0
        sca sourcecoef0 = 0
        sca sourcecoef1 = 1.012
        sca sourcecoef2 = 1.626
        sca sourcecoef3 = 0.693
        sca cprcoef = 1.082
        sca cancercoef = 0.766
        sca riskcoef = -1.697
        sca neurocoef = 0.197
        sca nonneurocoef = 0.163

        /// PRISM III & IV age bounds
        
        sca age0 = 0    // 0 days
        sca age1 = 14   // 14 days
        sca age2 = 15   // 15 days
        sca age3 = 30   // 1 month
        sca age4 = 31   // 1 month + 1 day
        sca age5 = 365  // 1 year
        sca age6 = 366  // 1 year + 1 day
        sca age7 = 4380 // 12 years
        sca age8 = 4381 // 12 years + 1 day
        
        
        // PRISM III vital bounds
        sca sbp0 = 40
        sca sbp1 = 45
        sca sbp2 = 55
        sca sbp3 = 65
        sca sbp4 = 75
        sca sbp5 = 85
        sca hr0 = 145
        sca hr1 = 155
        sca hr2 = 185
        sca hr3 = 205
        sca hr4 = 215
        sca hr5 = 225
        sca tmp0 = float(33.0)
        sca tmp1 = float(40.0)
        sca gcs0 = 8

        //  PRISM III lab bounds - must be float or else comparison will not work
        //  close to the boundries because of how STATA stores numbers
        
        sca ph0 = float(7.0) 
        sca ph1 = float(7.28)
        sca ph2 = float(7.48)
        sca ph3 = float(7.55)
        sca bicarb0 = float(5)
        sca bicarb1 = float(16.9)
        sca bicarb2 = float(34.0)
        sca pao20 = float(42.0)
        sca pao21 = float(49.9)
        sca pco20 = float(50.0)
        sca pco21 = float(75)

        sca pot0 = float(6.9)
        sca glu0 = float(200)
        sca cr0 = float(0.85)
        sca cr1 = float(0.9)
        sca cr2 = float(1.30)
        sca bun0 = float(11.9)
        sca bun1 = float(14.90)

        sca wbc0 = float(3000)
        sca pt0 = float(22.0)
        sca ptt0 = float(57.0)
        sca ptt1 = float(85.0)
        sca plt0 = float(50000)
        sca plt1 = float(99999)
        sca plt2 = float(100000)
        sca plt3 = float(200000)

        sca sbpoor0 = float(0)
        sca sbpoor1 = float(300)
        sca hroor0 = float(0)
        sca hroor1 = float(300)
        sca gcsoor0 = float(3)
        sca gscoor1 = float(15)
        sca phoor0 = float(6.5)
        sca phoor1 = float(7.9)
        sca co2oor0 = float(0.1)
        sca co2oor1 = float(60)
        sca pco2oor0 = float(1)
        sca pco2oor1 = float(200)
        sca pao2oor0 = float(1)
        sca pao2oor1 = float(600)
        sca potoor0 = float(1)
        sca potoor1 = float(10)
        sca gluoor0 = float(5)
        sca gluoor1 = float(999)
        sca croor0 = float(0.01)
        sca croor1 = float(15)
        sca bunoor0 = float(1)
        sca bunoor1 = float(150)
        sca tmpoor0 = float(25.0)
        sca tmpoor1 = float(45.0)
        

//  Replaces bounds for lab values in SI units and temperature in F.

        // Rather than converting the underlying values, I'm just setting new
        // bounds; cleaner and less resource-intensive 

    if sioption == 1 {
        sca glu0 = float(11.0)
        sca cr0 = float(75)
        sca cr1 = float(80)
        sca cr2 = float(115)
        sca bun0 = float(4.3)
        sca bun1 = float(5.4)
        sca gluoor0 = float(0.2)
        sca gluoor1 = float(55.45)
        sca croor0 = float(0.8)
        sca croor1 = float(1350)
        sca bunoor0 = float(0.3)
        sca bunoor1 = float(53.6)
    }

    if tempoption == 1 {
        sca tmp0 = float(91.4)
        sca tmp1 = float(104.0) 
        sca tmpoor0 = float(77.0)
        sca tmpoor1 = float(113.0)
    }

//  Changes bounds for WBC and Platelets based on units (cells vs 1000 cells)

        // Default option is all cell counts in cells. If K cells, sets
        // option to 1000 which is used further down

    sca plateletoption = 1
    sca wbcoption = 1
    if `pltunit' == 1000 {
        sca plateletoption = 1000
    }
    if `wbcunit' == 1000 {
        sca wbcoption = 1000
    }
    if `pltunit' != 1 & `pltunit' != 1000 & `pltunit' != . {
        di as err "Platelet Unit incorrectly specified."
        err 499
    }
    if `wbcunit' != 1 & `wbcunit' != 1000 & `wbcunit' != . {
        di as err "WBC Unit incorrectly specified."
        err 499
    }
    forvalues x = 0(1)3 {       // Uses plateletoption to set platelet bounds
        sca plt`x' = plt`x' / plateletoption
    }

    sca wbc0 = wbc0 / wbcoption // Uses WBC option to set wbc bounds

*------------------------------------------------------------------------------*
*   Protects against edge cases where foo_high < foo_low. First it fills in    *
*   missing values from the paired variable (if foo_low != . & foo_high == .   *
*   foo_high = foo_low. Then it places foo_high and foo_low in tempvars and    *
*   replaces foo_high/foo_low with max/min of all values.                      *
*                                                                              *
*   In simpler terms, for measurements that have both a high and a low variable*
*   only one has to be specified. If both are specified, even if the data is   *
*   entered incorrectly (e.g. high value in low variable) this will fix it.    *
*------------------------------------------------------------------------------*

if noimputationoption == 0 {
        cap conf v `templow'
        if _rc != 0 {
            tempvar templow
            gen `templow' = `temp' if `touse'
        }
        else {
            tempvar thtmp tltmp
            replace `temp' = `templow' if `temp' == . & `touse'
            replace `templow' = `temp' if `templow' == . & `touse'
            gen `tltmp' = `templow' ///
                if inrange(`temp', `templow', .) & `touse'
            gen `thtmp' = `temp'    ///
                if inrange(`templow', ., `temp') & `touse'
            replace `temp' = min(`temp', `tltmp', `thtmp') if `touse'
            replace `templow' = max(`templow', `tltmp', `thtmp') if `touse'
            drop `thtmp' `tltmp'
        }

        cap conf v `phhigh'
        if _rc != 0 {
            tempvar phhigh
            gen `phhigh' = `ph' if `touse'
        }
        else {
            tempvar phtmp pltmp
            replace `ph' = `phhigh' if `ph' == . & `touse'
            replace `phhigh' = `ph' if `phhigh' == . & `touse'
            gen `pltmp' = `phhigh'  ///
                if inrange(`ph', `phhigh', .) & `touse'
            gen `phtmp' = `ph' if inrange(`phhigh', ., `ph') & `touse'
            replace `ph' = min(`ph', `pltmp', `phtmp') if `touse'
            replace `phhigh' = max(`phhigh', `pltmp', `phtmp') if `touse'
            drop `phtmp' `pltmp'
        }
        cap conf v `bicarbhigh'
        if _rc != 0 {
            tempvar bicarbhigh
            gen `bicarbhigh' = `bicarb' if `touse'
        }
        if _rc == 0 {
            tempvar bhtmp bltmp
            replace `bicarb' = `bicarbhigh' if `bicarb' == . & `touse'
            replace `bicarbhigh' = `bicarb' if `bicarbhigh' == . & `touse'
            gen `bltmp' = `bicarbhigh'  ///
                if inrange(`bicarb', `bicarbhigh', .) & `touse'
            gen `bhtmp' = `bicarb'      ///
                if inrange(`bicarbhigh', ., `bicarb') & `touse'
            replace `bicarb' = min(`bicarb', `bltmp', `bhtmp') if `touse'
            replace `bicarbhigh' = max(`bicarbhigh', `bltmp', `bhtmp')  ///
                if `touse'
            drop `bhtmp' `bltmp'
        }
    }
********************************************************************************
// Error Checking

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
            // If 2 both dob and doa exist, if 1 only one exists. If 0, none
        if ag1 == 1 & ag4 == 0 {
            sca agecase = 1 // Only categorical age is specified
        }

        if ag1 == 1 & inrange(ag4, 1, 2) {
            sca agecase = 2 // Both age & DoB DoA are specified
        }

        if ag1 == 0 & ag4 == 0 {
            sca agecase = 3 // Nothing is specified
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


        // Ensures categorical variables are entered in the correct format
        if agecase == 1 {
            cou if !inlist(`age', 0, 1, 2, 3, 4, .)
                if r(N) != 0 {
                    di as err "Age is not in the correct format. `helpme'"
                    err 498
                }
            gen `ageIV' = 0 if `age' == 0
            replace `ageIV' = 1 if `age' == 1
            replace `ageIV' = 2 if `age' == 2
            replace `ageIV' = 3 if inrange(`age', 3,4)
            replace `age' = 0 if inrange(`age',0,1)
            replace `age' = 1 if `age' == 2
            replace `age' = 2 if `age' == 3
            replace `age' = 3 if `age' == 4
        }

        if agecase == 5 {
            gen `calculated_age' = datediff(`dob', `doa', "d")
            cap as `calculated_age' >= 0, fast
            if _rc != 0 {
                di as err "Calculated age is negative. Observations will " ///
                "be ignored."
            }
            tempvar age
            gen `age' = 0 if inrange(`calculated_age', age0, age3)
                replace `age' = 1 if inrange(`calculated_age', age4, age5)
                replace `age' = 2 if inrange(`calculated_age', age6, age7) //12y
                replace `age' = 3 if inrange(`calculated_age', age8, .) //12y
            gen `ageIV' = 0 if inrange(`calculated_age', age0, age1)
            replace `ageIV' = 1 if inrange(`calculated_age', age2, age3)
            replace `ageIV' = 2 if `age' == 1
            replace `ageIV' = 3 if inlist(`age', 2, 3)
        }

    if suppressoption != 2 {    // Checks that either PT or PTT are specified
        sca rc1 = 0             // If either are missing generates empty var
        sca rc2 = 0             // to prevent errors in calculation.
        sca ag1 = 0
        sca ag2 = 0
        sca ag3 = 0
        sca ag4 = 0
        
            cap {
                conf v `pt'
            }
                if _rc != 0 {
                    sca rc1 = 1
                }
                
            cap {
                conf v `ptt'
            }
                if _rc != 0 {
                    sca rc2 = 1
                }
                
            sca rc3 = rc1 + rc2 
            if rc3 == 2 {
                di as err "You must specify either PT or PTT. `helpme'"
                err 102
            }
            else {      
                if rc1 == 1 {   
                    replace `pt' = .
                }
                if rc2 == 1 {
                    replace `ptt' = .
                }
            }

            cou if !inlist(`pupils', 0, 1, 2, .)
            if r(N) != 0 {
                    di as err "Pupils are not in the correct format. `helpme'"
                    err 499
            }

        if prismivoption == 1 {
            cou if !inlist(`source', 0, 1, 2, 3, .) 
            if r(N) != 0 {
                di as err "source is not in the correct format. `helpme'"
                err 499
            }
            if suppressoption == 0 & noimputationoption == 0 {
                cou if `source' == .
                if r(N) != 0 {
                    di as err "source imputed. `helpme'"
                }
            }

            foreach var in cpr cancer risk {
                cou if !inlist(``var'', 0, 1, .)
                if r(N) != 0 {
                    di as err "`var' is not binary. `helpme'"
                    err 450
                }
                if suppressoption == 0 & noimputationoption == 0 {
                    cou if ``var'' == .
                    if r(N) != 0 {
                        di as err "Some `var' values imputed. `helpme'"
                    }
                }
            }
        }
    }   // If errors are suppressed, generates empty vars for missing variables 
    if suppressoption == 2 { 
        foreach var in `l_allvars' {
            cap {
                conf v ``var''
            }
            if _rc != 0 {
                gen ``var'' = .
            }
        }
    }   // Assigns age and source coefficients based on age and source values
    if prismivoption == 1 {
        forvalues x = 0(1)3 {
            replace `source_score' = sourcecoef`x' if `source' == `x'
        }


        forvalues x = 0(1)3 {
            replace `age_score' = agecoef`x' if `ageIV' == `x'
        }
    }

    if validationoption == 1 {
        noi {
            di ""
            di as text "The following lists the number of out-of-range values:"
            di as text "SBP"
        replace `sbp' = . if !inrange(`sbp', sbpoor0, sbpoor1)
            di "HR"
        replace `hr' = . if !inrange(`hr', hroor0, hroor1)
            di "GCS"
        replace `gcs' = . if !inrange(`gcs', gcsoor0, gscoor1)
            di "Temperature High"
        replace `temp' = . if !inrange(`temp', tmpoor0, tmpoor1)
            di "Temperature Low"
        replace `templow' = . if !inrange(`templow', tmpoor0, tmpoor1)
            di "pH Low"
        replace `ph' = . if !inrange(`ph', phoor0, phoor1)
            di "pH High"
        replace `phhigh' = . if !inrange(`phhigh', phoor0, phoor1)
            di "Bicarb Low"
        replace `bicarb' = . if !inrange(`bicarb', co2oor0, co2oor1)
            di "Bicarb High"
        replace `bicarbhigh' = . if !inrange(`bicarbhigh', co2oor0, co2oor1)
            di "PCO2"
        replace `pco2' = . if !inrange(`pco2', pco2oor0, pco2oor1)
            di "PaO2"
        replace `pao2' = . if !inrange(`pao2', pao2oor0, pao2oor1)
            di "Glucose"
        replace `glucose' = . if !inrange(`glucose', gluoor0, gluoor1)
            di "Potassium"
        replace `potassium' = . if !inrange(`potassium', potoor0, potoor1)
            di "Creatinine"
        replace `creatinine' = . if !inrange(`creatinine', croor0, croor1)
            di "BUN"
        replace `bun' = . if !inrange(`bun', bunoor0, bunoor1)
        }
    }
********************************************************************************
// Score Calculation
    replace `sbp_score' = 3 if ((`age' == 0 & inrange(`sbp', sbp0, sbp2)) |  ///
        (`age' == 1 & inrange(`sbp', sbp1, sbp3)) |                          ///
        (`age' == 2 & inrange(`sbp', sbp2, sbp4)) |                          ///
        (`age' == 3 & inrange(`sbp', sbp3, sbp5))) & `sbp' != .
    replace `sbp_score' = 7 if ((`age' == 0 & `sbp' < sbp0) |                ///
        (`age' == 1 & `sbp' < sbp1) | (`age' == 2 & `sbp' < sbp2) |          ///
        (`age' == 3 & `sbp' < sbp3)) & `sbp' != .

    replace `temperature_score' = 3 if (`temp' > tmp1 | `templow' > tmp1 |   ///
        `temp' < tmp0 | `templow' < tmp0) & `temp' != . & `templow' != .

    replace `mentalstatus_score' = 5 if `gcs' < gcs0 & `gcs' != .
    replace `mentalstatus_score' = 0 if `gcs' >= gcs0 & `gcs' != .

    replace `hr_score' = 3 if ((`age' == 0 & inrange(`hr', hr4, hr5)) |      ///
        (`age' == 1 & inrange(`hr', hr4, hr5)) |                             ///
        (`age' == 2 & inrange(`hr', hr2, hr3)) |                             ///
        (`age' == 3 & inrange(`hr', hr0, hr1))) & `hr' != . 
    replace `hr_score' = 4 if ((`age' == 0 & hr > hr5) |                     ///
        (`age' == 1 & `hr' > hr5) | (`age' == 2 & `hr' > hr3) |              ///
        (`age' == 3 & `hr' > hr1)) & `hr' != .

    replace `pupils_score' = 7 if `pupils' == 1
    replace `pupils_score' = 11 if `pupils' == 2 
    replace `pupils_score' = 0 if `pupils' == 0

    replace `acidosis_score' = 2 if (inrange(`ph', ph0, ph1) |               ///
        inrange(`bicarb', bicarb0, bicarb1)) 
    replace `acidosis_score' = 6 if (`ph' < ph0 | `bicarb' < bicarb0 )       ///
        & `ph' != . & `bicarb' != .

    replace `ph_score' = 2 if inrange(`phhigh', ph2, ph3) |                  ///
        inrange(`ph', ph2, ph3)
    replace `ph_score' = 3 if `phhigh' != . & (`phhigh' >ph3)

    replace `pco2_score' = 1 if inrange(`pco2', pco20, pco21)
    replace `pco2_score' = 3 if `pco2' > pco21 & `pco2' != .

    replace `bicarb_score' = 4 if (`bicarbhigh' > bicarb2                    ///
        & `bicarbhigh' != .) | (`bicarb' > bicarb2 & `bicarb' != .)

    replace `pao2_score' = 3 if inrange(`pao2', pao20, pao21) 
    replace `pao2_score' = 6 if `pao2' < pao20 & `pao2' != .    

    replace `wbc_score' = 4 if `wbc' < wbc0 
    replace `coag_score' = 3 if (`age' == 0 & ((inrange(`pt', pt0, .) &      ///
        !inlist(`pt',pt0)) | ((inrange(`ptt', ptt1, .) &                     ///
        !inlist(`ptt',ptt1))))) | (inrange(`age', 1, 3) &                    ///
        ((inrange(`pt', pt0, .) & !inlist(`pt',pt0)) |                       ///
        (inrange(`ptt', ptt0, .) & !inlist(`ptt',ptt0))))

    replace `glucose_score' = 2 if `glucose' > glu0 & `glucose' != .

    replace `potassium_score' = 3 if `potassium' > pot0 & `potassium' != .

    replace `creatinine_score' = 2 if ((`age' == 0 & `creatinine' > cr0) |   ///
        (inrange(`age', 1, 2) & `creatinine' > cr1) |                        ///
        (`age' == 3 & `creatinine' > cr2)) & `creatinine' != . 

    replace `bun_score' = 3 if ((`age' == 0 & `bun' > bun0) |                ///
        (inrange(`age', 1, 3) & `bun' > bun1)) & `bun' != .

    replace `platelet_score' = 2 if inrange(`plt', plt2, plt3)
    replace `platelet_score' = 4 if inrange(`plt', plt0, plt1)
    replace `platelet_score' = 5 if `plt' < plt0 & `plt' != . 

********************************************************************************

    gen `neuroscore' = `pupils_score' + `mentalstatus_score' if `touse'
    gen `nonneuroscore' = `sbp_score' + `temperature_score' +                ///
        `hr_score' + `acidosis_score' + `bicarb_score' + `ph_score' +        ///
        `pao2_score' + `pco2_score' + `glucose_score' + `potassium_score' +  ///
        `creatinine_score' + `bun_score' + `wbc_score' + `coag_score' +      ///
        `platelet_score' if `touse'
    gen `totalscore' = `neuroscore' + `nonneuroscore' if `touse'

        // Places temporary variables into permanent ones
    if noimputationoption == 1 {
        tempvar missingcheck3
        egen `missingcheck3' = rowmiss(`sbp' `gcs' `hr' `pupils'             ///
            `temp' `' `ph' `' `bicarb' `' `pco2' `pao2'                      ///
            `glucose' `potassium' `creatinine' `bun' `wbc' `plt'             ///
            `templow' `phhigh' `bicarbhigh' `pt' `ptt' )
            replace `neuroscore' = . if `missingcheck3' != 0
            replace `nonneuroscore' = . if `missingcheck3' != 0
            replace `totalscore' = . if `missingcheck3' != 0
    }   
    cap {   
        replace `neurovar' = `neuroscore'
        replace `nonneurovar' = `nonneuroscore'
        replace `totalvar' = `totalscore'
    }


    if prismivoption == 1 {
            // Calculates PRISM IV coefficient sum

        gen double `prismintermediate' = intercept + `age_score' +               ///
            `source_score' + (`cpr' * cprcoef) + (`cancer' * cancercoef) +       ///
            (`risk' * riskcoef) + (`neuroscore' * neurocoef) +                   ///
            (`nonneuroscore' * nonneurocoef) if `touse'

            // Applies logistic function to previous result
        gen double `prismfinal' = 100 / (1 + exp(-`prismintermediate')) if `touse'

            // Rounds result to make it look pretty
        replace `prismfinal' = round(`prismfinal', 0.01) 
        if noimputationoption == 1 {
            tempvar missingcheck4
            egen `missingcheck4' = rowmiss(`cpr' `cancer' `risk' `source')
            replace `prismfinal' = . if `missingcheck4' != 0 | `missingcheck3' != 0
        }
            // Places temporary variable into the permanent one
        replace `prismivvar' = `prismfinal' 
    }
********************************************************************************
    if traceoption == 1 {
        set tr off
    }
    if suppressoption == 2 {
        noi: di as text ///
            "This calculation ran with suppressall enabled. "   ///
            "It skipped all data validation and imputed "       ///
            "missing values as normal. You should be using "    ///
            "option suppress if you want to hide imputation "   ///
            "messages while still keeping data validation."     ///
            _newline "`helpme'"
    }
}
}
********************************************************************************
di as text _newline "Calculation completed successfully." _continue
restore, not
end

/*
This program is free software: you can redistribute it and/or modify it under 
the terms of the GNU General Public License as published by the Free Software 
Foundation, either version 3 of the License, or (at your option) any later 
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY 
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with 
this program. If not, see <https://www.gnu.org/licenses/>.
*/ 
