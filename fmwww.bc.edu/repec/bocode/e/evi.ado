*! evi.ado
*! Epidemic Volatility Index version 1.0 - 11 October 2021
*! Authors: Luis Furuya-Kanamori (l.furuya@uq.edu.au) & Polychronis Kostoulas
*! Modified by Leonelo Bautista 10/28/2023. Main purpose: improve graph, output file, and documentation.


program define eviup, rclass
    version 14

    syntax varlist(min=2 max=2 numeric) [if] [in] ///
        , [Lag(numlist min=2 max=2)] [C(numlist min=2 max=2)] [R(numlist max=1)] ///
          [MOV(numlist max=1)] [CUMulative] ///
          [SEnsitivity(numlist max=1)] [SPecificity(numlist max=1)] [Youden] ///
          [NORSample] [noGraph] [LOGarithmic] ///
          [GRTittle(string asis)] [GRSAve(string asis)]

    tokenize `varlist'

    * Dummy ID + preserve
    capture quietly gen __dummy_id = _n
    preserve

    marksample touse, novarlist
    quietly keep if `touse'

    * Check required packages
    foreach package in rangestat diagt {
        capture which `package'
        if _rc==111 ssc install `package'
    }

    * Error specification: Combine Youden's J, Sens, Spec (Error)
    if "`youden'"!="" & ("`sensitivity'"!="" | "`specificity'"!="")  {
        di as error "Select only one: Youden's J, Sens, or Spec"
        restore
        drop __dummy_id
        exit 198
    }
    if "`sensitivity'"!="" & ("`youden'"!="" | "`specificity'"!="")  {
        di as error "Select only one: Youden's J, Sens, or Spec"
        restore
        drop __dummy_id
        exit 198
    }
    if "`specificity'"!="" & ("`sensitivity'"!="" | "`youden'"!="")  {
        di as error "Select only one: Youden's J, Sens, or Spec"
        restore
        drop __dummy_id
        exit 198
    }
    if "`specificity'"!="" & "`sensitivity'"!="" & "`youden'"!=""  {
        di as error "Select only one: Youden's J, Sens, or Spec"
        restore
        drop __dummy_id
        exit 198
    }

    * Range Se and Sp (user-specified constraints)
    if "`sensitivity'"!="" {
        local sens = `sensitivity'
        cap assert `sens'>=0 & `sens'<=1
        if _rc!=0{
            di as error "Sens should be between 0 and 1"
            restore
            drop __dummy_id
            exit 198
        }
    }
    if "`specificity'"!="" {
        local spec = `specificity'
        cap assert `spec'>=0 & `spec'<=1
        if _rc!=0{
            di as error "Spec should be between 0 and 1"
            restore
            drop __dummy_id
            exit 198
        }
    }

    * ---- Data input for analysis + error/warning messages ----
    if "`1'" != "" & "`2'" != "" {
        quietly {

            * Days (time variable)
            gen double __day = `2'
            gen strL __day_label = "`:var lab `2''"

            * Repeated days (Error)
            gen __n_day = __day[_n] - __day[_n-1]
            cap assert __n_day != 0
            if _rc!=0{
                di as error "Variable {bf:`2'} contains repeated values"
                restore
                drop __*
                exit _rc
            }

            * Sort days (Error)
            cap assert __n_day > 0
            if _rc!=0{
                di as error "Variable {bf:`2'} not sorted: {bf:`2'}[_n-1] > {bf:`2'}[_n]"
                restore
                drop __*
                exit _rc
            }

            * Missing values days (Error)
            cap assert `2' != .
            if _rc!=0{
                di as error "Variable {bf:`2'} contains missing values"
                restore
                drop __*
                exit _rc
            }

            sort __day
            drop if __day==.
            local day_min = __day[1]
            local day_max = __day[_N]

            * ---- Cases ----
            * mov()
            if "`mov'"=="" {
                local mova1 = 7
                local mova2 = `mova1'-1
            }
            else {
                local mova1 = `mov'
                local mova2 = `mova1'-1
                if `mova1' >= 14 {
                    di as error "Warning: Rolling window size = 14 is not recommended"
                }
            }

            * cumulative vs incident
            if "`cumulative'"=="" {
                gen double __n_case = `1'
                gen strL __cases_label = "`:var lab `1''"
            }
            else {
                gen double __cases = `1'
                gen strL __cases_label = "`:var lab `1''"
                gen double __n_case = __cases[_n] - __cases[_n-1]
                qui replace __n_case = __cases in 1
                cap assert __n_case >= 0
                if _rc!=0{
                    di as error "Warning: variable {bf:`1'} not in ascending order: {bf:`1'}[_n-1] > {bf:`1'}[_n]"
                }
            }

            * Non-integers cases (Warning)
            cap assert int(`1')==`1'
            if _rc!=0 di as error "Warning: variable {bf:`1'} contains non-integers"

            * Missing values cases (Warning)
            cap assert `1'!=.
            if _rc!=0 di as error "Warning: variable {bf:`1'} contains missing values"

            * ---- lag() ----
            if "`lag'"=="" {
                local lag_min = 7
                local lag_max = 10
            }
            else {
                tokenize `lag'
                local lag_min = `1'
                local lag_max = `2'
                if `lag_min' <= 6 di as error "Warning: Lag = 6 is not recommended"
            }

            * ---- c() ----
            if "`c'"=="" {
                local c_min = 0.01
                local c_max = 0.05
            }
            else {
                tokenize `c'
                local c_min = `1'
                local c_max = `2'
            }

            * ---- r() ----
            if "`r'"=="" {
                local r1 = 1.2
                local r2 = 1/`r1'
            }
            else {
                local r1 = `r'
                local r2 = 1/`r1'
            }
            * ---- r() ----
            if "`r'"=="" {
                local r1 = 1.2
                local r2 = 1/`r1'
            }
            else {
                local r1 = `r'
                local r2 = 1/`r1'
            }

            * ---- NEW: store tuning parameters for output ----
            gen int    __mov = `mova1'
            gen double __r   = `r1'


            * ---- Moving average ----
            tsset __day
            tssmooth ma __mova_case = __n_case, window(`mova2' 1 0)

            * ---- Status (relative rise in mean cases) ----
            tssmooth ma __avg_mova1 = __mova_case, window(`mova2' 1 0)
            tssmooth ma __avg_mova2 = __mova_case, window(0 0 `mova1')
            gen double __status = __avg_mova1/__avg_mova2 if __day >= `mova1'
            cap gen byte __status_cat = 0 if __status > `r2'
            qui replace __status_cat = 1 if __status <= `r2'
            qui replace __status_cat = . if __day < `mova1'

            * ---- Empty cells ----
            gen double __eviup = .
            gen byte   __eviup_cat = .
            gen double __se = .
            gen double __sp = .
            gen double __y  = .

            gen double __d = .
            gen double __l = .
            gen double __c = .

            cap gen double __l_max = .
            cap gen double __c_max = .
            cap gen double __se_max = 0
            cap gen double __sp_max = 0
            cap gen double __y_max  = 0
            gen byte __fixed_val = 0

            gen double __eviup_max = .
            cap gen byte __eviup_cat_max = .

            * ---- Loop by days ----
            forvalues d_i = `day_min'(1)`day_max' {

                forvalues lag_i = `lag_min'(1)`lag_max' {
                    forvalues c_i = `c_min'(0.01)`c_max' {

                        qui replace __d = `d_i'
                        qui replace __l = `lag_i'
                        qui replace __c = `c_i'

                        * Roll SD (use internal time variable)
                        local lag2 = 1-`lag_i'
                        rangestat (sd)__mova_case, interval(__day `lag2' 0)
                        rename __mova_case_sd __roll_sd

                        * eviup
                        qui replace __eviup = (__roll_sd[_n] - __roll_sd[_n-1]) / __roll_sd[_n-1]
                        qui replace __eviup = 0   if __roll_sd==.
                        qui replace __eviup = 0   if (__roll_sd[_n-1]==0 | __roll_sd[_n-1]==.) & (__roll_sd[_n]==0)
                        qui replace __eviup = 999 if __roll_sd[_n-1]==0 & __roll_sd[_n]!=0
                        drop __roll_sd

                        * eviup_cat
                        qui replace __eviup_cat = 0
                        qui replace __eviup_cat = 1 if __eviup >= `c_i'
                        qui replace __eviup_cat = 0 if (__mova_case[_n] < __mova_case[_n-`mova1'])

                        * Sens/Spec/Y (retrospective, up to d_i-7)
                        if `d_i' > 7 {
                            local w = `d_i'-7
                            cap diagt __status_cat __eviup_cat in 1/`w'
                            qui replace __se = r(sens)/100 in `d_i'
                            qui replace __sp = r(spec)/100 in `d_i'
                            qui replace __y  = __se+__sp-1 in `d_i'
                        }

                        * Select Lag/C based on criterion
                        * Youden's J (default)
                        if ("`specificity'"=="" & "`sensitivity'"=="" & "`youden'"=="") | ("`youden'"!="") {
                            if __y[`d_i'] > __y_max[`d_i'] {
                                qui replace __y_max        = __y[`d_i']        in `d_i'
                                qui replace __se_max       = __se[`d_i']       in `d_i'
                                qui replace __sp_max       = __sp[`d_i']       in `d_i'
                                qui replace __l_max        = __l[`d_i']        in `d_i'
                                qui replace __c_max        = __c[`d_i']        in `d_i'
                                qui replace __eviup_max    = __eviup[`d_i']    in `d_i'
                                qui replace __eviup_cat_max= __eviup_cat[`d_i'] in `d_i'
                            }
                        }

                        * Sens constraint
                        if "`sensitivity'"!="" {
                            if (__se[`d_i'] <= `sens') & (__se[`d_i'] > __se_max[`d_i']) {
                                qui replace __y_max        = __y[`d_i']        in `d_i'
                                qui replace __se_max       = __se[`d_i']       in `d_i'
                                qui replace __sp_max       = __sp[`d_i']       in `d_i'
                                qui replace __l_max        = __l[`d_i']        in `d_i'
                                qui replace __c_max        = __c[`d_i']        in `d_i'
                                qui replace __eviup_max    = __eviup[`d_i']    in `d_i'
                                qui replace __eviup_cat_max= __eviup_cat[`d_i'] in `d_i'
                                qui replace __fixed_val    = 1                in `d_i'
                            }
                            else if (__se[`d_i'] > `sens') & (__y[`d_i'] > __y_max[`d_i']) & (__fixed_val[`d_i'] != 1) {
                                qui replace __y_max        = __y[`d_i']        in `d_i'
                                qui replace __se_max       = __se[`d_i']       in `d_i'
                                qui replace __sp_max       = __sp[`d_i']       in `d_i'
                                qui replace __l_max        = __l[`d_i']        in `d_i'
                                qui replace __c_max        = __c[`d_i']        in `d_i'
                                qui replace __eviup_max    = __eviup[`d_i']    in `d_i'
                                qui replace __eviup_cat_max= __eviup_cat[`d_i'] in `d_i'
                                qui replace __fixed_val    = 0                in `d_i'
                            }
                        }

                        * Spec constraint
                        if "`specificity'"!="" {
                            if (__sp[`d_i'] <= `spec') & (__sp[`d_i'] > __sp_max[`d_i']) {
                                qui replace __y_max        = __y[`d_i']        in `d_i'
                                qui replace __se_max       = __se[`d_i']       in `d_i'
                                qui replace __sp_max       = __sp[`d_i']       in `d_i'
                                qui replace __l_max        = __l[`d_i']        in `d_i'
                                qui replace __c_max        = __c[`d_i']        in `d_i'
                                qui replace __eviup_max    = __eviup[`d_i']    in `d_i'
                                qui replace __eviup_cat_max= __eviup_cat[`d_i'] in `d_i'
                                qui replace __fixed_val    = 1                in `d_i'
                            }
                            else if (__sp[`d_i'] > `spec') & (__y[`d_i'] > __y_max[`d_i']) & (__fixed_val[`d_i'] != 1) {
                                qui replace __y_max        = __y[`d_i']        in `d_i'
                                qui replace __se_max       = __se[`d_i']       in `d_i'
                                qui replace __sp_max       = __sp[`d_i']       in `d_i'
                                qui replace __l_max        = __l[`d_i']        in `d_i'
                                qui replace __c_max        = __c[`d_i']        in `d_i'
                                qui replace __eviup_max    = __eviup[`d_i']    in `d_i'
                                qui replace __eviup_cat_max= __eviup_cat[`d_i'] in `d_i'
                                qui replace __fixed_val    = 0                in `d_i'
                            }
                        }

                    } // loop c
                } // loop lag
            } // loop day

            * Burn-in
            qui replace __l_max = `lag_min' in 1/14
            qui replace __c_max = `c_min'   in 1/14
            qui replace __se_max = .        in 1/14
            qui replace __sp_max = .        in 1/14
            qui replace __y_max  = .        in 1/14
            qui replace __eviup_cat_max = . in 1/2

            * ---- Graph options: defaults ----
            local __default_title "Epidemic Volatility Index"
            local __grtitle `"`grtittle'"'
            if `"`__grtitle'"'=="" local __grtitle `"`__default_title'"'

            if "`graph'"=="nograph" & `"`grsave'"'!="" {
                noi di as txt "note: grsave() ignored because nograph was specified"
            }

            * ---- Graph ----
            local y_label = __cases_label[1]
            local x_label = __day_label[1]

            if "`graph'" != "nograph" {
                if "`logarithmic'"!="" {
                    qui replace __mova_case = 1 if __mova_case <= 1
                    gen double __log_mova_case = log10(__mova_case)
                    twoway (scatter __log_mova_case __day, sort mcolor(blue) msymbol(smcircle) msize(vsmall)) ///
                        (scatter __log_mova_case __day if __eviup_cat_max==1, sort mcolor(red) msymbol(smcircle) msize(vsmall)) ///
                        , ytitle(`"`y_label'"', margin(small)) ylabel(, angle(horizontal)) ///
                        xtitle(`"`x_label'"', margin(small)) ti(`"`__grtitle'"', size(small)) ///
                        legend(off) scale(1.3) graphregion(fcolor(white))

                    if `"`grsave'"' != "" {
                        quietly graph save `grsave', replace
                    }
                }

                if "`logarithmic'"=="" {
                    twoway (scatter __mova_case __day                      , sort mcolor(blue) msymbol(smcircle) msize(vsmall)) ///
                        (scatter __mova_case __day if __eviup_cat_max==1   , sort mcolor(red)  msymbol(smcircle) msize(vsmall)) ///
                        , ytitle(`"`y_label'"', margin(small)) ylabel(, angle(horizontal)) ///
                        xtitle(`"`x_label'"', margin(small)) ti(`"`__grtitle'"', size(small)) ///
                        legend(off) scale(1.3) graphregion(fcolor(white))
    
                    if `"`grsave'"' != "" {
                        quietly graph save `grsave', replace
                    }
                }
            }

            * ---- Restore + Keep variables ----
            if "`norsample'" != "" {
                restore
                drop __dummy_id
                exit
            }

            * Keep what we want from the preserved dataset, merge back to original
            keep __dummy_id __status_cat __eviup_cat_max __l_max __c_max __se_max __sp_max __y_max __mova_case __mov __r __day

            tempfile formerge
            save `formerge', replace
            restore 
            cap merge 1:m __dummy_id using `formerge', nogenerate
            drop __dummy_id
            cap drop _status _lag _c _sens _spec _youden _eviup _mov _r
            cap rename __status_cat    _status
            cap rename __eviup_cat_max _eviup
            cap rename __l_max         _lag
            cap rename __c_max         _c
            cap rename __se_max        _sens
            cap rename __sp_max        _spec
            cap rename __y_max         _youden
            cap rename __mov           _mov
            cap rename __r             _r

            cap drop __status_cat __eviup_cat_max __l_max __c_max __se_max __sp_max __y_max __mov __r

            * ---- Runs of high volatility (>=3 consecutive _eviup==1) ----
            sort __day
            tempvar runstart runid runlen
            gen byte __hv = (_eviup==1) if !missing(_eviup)
            gen byte `runstart' = (__hv==1 & (_n==1 | __hv[_n-1]!=1))
            gen long `runid' = sum(`runstart')
            replace `runid' = . if __hv != 1
            bysort `runid': gen int `runlen' = _N if `runid' < .
            bysort `runid': egen double __sens_run = mean(_sens) if `runid' < .
            bysort `runid': egen double __spec_run = mean(_spec) if `runid' < .
            cap drop _sens_run _spec_run _eviup_runlen
            gen double _sens_run = __sens_run
            gen double _spec_run = __spec_run
            gen int    _eviup_runlen = `runlen'
            replace _sens_run     = . if `runid'==. | `runlen' < 3
            replace _spec_run     = . if `runid'==. | `runlen' < 3
            replace _eviup_runlen = . if `runid'==. | `runlen' < 3

            * Cleanup temp run means
            cap drop __sens_run
            cap drop __spec_run
            cap drop __hv
            //cap drop _eviup /*it's the same as __hv*/
           
            * ---- Variable labels ----
            rename __mova_case _mov_average
            label var _mov_average "Moving-average–smoothed case counts used for EVI calculation"
            label var _status     "Indicator of relative increase in mean cases exceeding r threshold"
            label var _mov       "Moving-average window size (time units) used for smoothing"
            label var _r         "Rise-threshold parameter r used to define the mean-increase indicator"
            label var _lag        "Selected lag (time units) for EVI volatility comparison"
            label var _c          "Selected volatility threshold (c) for EVI detection"
            label var _sens       "Sensitivity of EVI to detect user-defined increases in mean cases"
            label var _spec       "Specificity of EVI to identify periods without such increases"
            label var _youden     "Youden's J statistic (sensitivity + specificity - 1)"
            label var _eviup      "EVI high-volatility indicator (1 = elevated volatility)"
            label var _sens_run   "Mean sensitivity over runs of =3 consecutive high-volatility periods"
            label var _spec_run   "Mean specificity over runs of =3 consecutive high-volatility periods"
            label var _eviup_runlen "Length of consecutive high-volatility run (number of time units)"
            
            * ---- Value labels ----
            cap label drop evilb
            label define evilb 0 "No signal" 1 "High volatility signal"
            label values _eviup  evilb
            
            * ---- Print start of each positive EVI run (>=3) ----
            tempvar __runstart2
            sort __day
            gen byte `__runstart2' = (_eviup_runlen < .) & (_n==1 | missing(_eviup_runlen[_n-1]))

            noi di as txt "Positive EVI runs (>=3 consecutive high-volatility periods):"
            noi list __day _eviup_runlen _sens_run _spec_run if `__runstart2', noobs abbrev(20)
            cap drop __day
           

        } // quietly
    } // data input

end
