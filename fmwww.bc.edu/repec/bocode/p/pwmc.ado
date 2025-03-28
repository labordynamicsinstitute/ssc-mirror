*! version 3.0.0  24mar2025
program pwmc
    
    version 12.1 , born(25nov2013)
    
    if ( replay() ) {
        
        pwmc_report `0'
        exit
        
    }
    
    pwmc_estimate_and_report `0'
    
end


/*  _________________________________________________________________________
                                                      estimate and report  */

program pwmc_estimate_and_report
    
    syntax varname(numeric) [ if ] [ in ]           ///
        [ fweight iweight ]                         /// not documented
        , Over(varname numeric)                     /// required
    [                                               ///
        MCOMPare(passthru)                          ///
        PROCedure(passthru) /// synonym for mcompare(); no longer documented
        noADJust     /// synonym for mcompare(noadjust)
        SEtype(passthru)                            ///
        hc3                /// synonym for setype(hc3); no longer documented
        df(passthru)                                ///
        Welch                /// synonym for df(welch); no longer documented
        legacydefault  /// for backwards compatibility; not documented
        Level(cilevel)                              ///
        CIeffects                                   ///
        PVEffects                                   ///
        PValues              /// synonym for pveffects; no longer documented
        EFFects                                     ///
        VARLabels                                   ///
        noVALLabels                                 ///        
        cformat(passthru)                           ///
        pformat(passthru)                           ///
        sformat(passthru)                           ///
        SUmmarize                                   ///
        zstd                                        ///
        noTABle                                     ///
    ]
    
    return_stats `varlist' `if' `in' [`weight' `exp'] , over(`over')
    
    mata : pwmc_estimate()
    
    pwmc_report ,                                     ///
        `mcompare' `procedure' `adjust'               ///
        `setype' `hc3' `df' `welch' level(`level')    ///
        `legacydefault'                               ///
        `cieffects' `pveffects' `pvalues' `effects'   ///
        `varlabels' `vallabels'                       ///
        `cformat' `pformat' `sformat'                 ///
        `summarize'                                   ///
        `zstd'                                        ///
        `table'
    
end


/*  _________________________________________________________________________
                                                                   report  */

program pwmc_report
    
    if ( !inlist("`r(cmd)'","pwmc","pwmci") ) {
        
        display as err "last command not pwmc"
        exit 301
        
    }
    
    if ("`r(cmd)'" == "pwmci") ///
        mata : pwmc_estimate()
    
    if ("`r(cmd2)'" != "pwmci") {
        
        local VARLabels   VARlabels
        local noVALLabels noVALLabels
        local zstd        zstd
        
    }
    
    syntax                   ///
    [ ,                      ///
        MCOMPare(passthru)   ///
        PROCedure(passthru)  /// 
        noADJust             ///
        SEtype(name)         ///
        hc3                  ///
        df(passthru)         ///
        Welch                ///
        legacydefault        ///
        Level(cilevel)       ///
        CIeffects            ///
        PVEffects            ///
        PValues              ///
        EFFects              ///
        `VARLabels'          ///
        `noVALLabels'        ///        
        cformat(string asis) ///
        pformat(string asis) ///
        sformat(string asis) ///
        SUmmarize            ///
        `zstd'               ///
        noTABle              ///
        unequal              ///
    ]
    
    parse_mcompare , `mcompare' `procedure' `adjust' `legacydefault'
    
    parse_setype , `setype' `hc3'
    
    parse_df , `df' `welch'
    
    if ( ("`vallabels'"!="novallabels") & ("`r(cmd2)'"!="pwmci") ) ///
        local vallabels vallabels
    
    confirm_variable , `varlabels' `vallabels'
    
    mata : pwmc_mctables("`mcompare'","`setype'","df",`level')
    
    if ( !c(noisily) ) ///
        exit
    
    return_labels , `varlabels' `vallabels'
    
    return_fmt c %9.7g `cformat'
    return_fmt p %5.3f `pformat'
    return_fmt s %8.2f `sformat'
    
    if ("`summarize'" == "summarize") ///
        pwmc_summarize , `vallabels' `zstd'
    
    if ("`table'" == "notable") ///
        exit
    
    return_effects , `pveffects' `pvalues' `cieffects' `effects'
    
    return_table_layout , `adjust' `varlabels' `vallabels'
    
    tempname table
    
    pwmc_report_title , `zstd'
    
    pwmc_report_table_header , `adjust'
    
    if ("`adjust'" == "noadjust") {
        
        matrix `table' = r(table_vs)
        matrix `table' = `table'[1..6,1...]'
        
        pwmc_report_table `table' , noadjust `zstd'
        
        if ("`r(mcmethod_vs)'" == "") ///
            exit
        
        display
        
        return_table_layout , `varlabels' `vallabels'
        
        pwmc_report_table_header
        
    }
    
    matrix `table' = r(table_mc_d)
    
    pwmc_report_table `table' , `zstd'
    
end


program pwmc_summarize
    
    syntax [ , VALLabels zstd ]
    
    if (c(stata_version) >= 14) ///
        local u u
    
    local col_1_width 14
    
    foreach var in depvar over {
        
        local T_`var'_label `r(T_`var'_label)'
        local col_1_width = max(`col_1_width',`u'strlen(`"`T_`var'_label'"')+2)
        
    }
    
    local k = r(k)
    
    forvalues j = 1/`k' {
        
        local over`j'_label `j'
        
        if ("`r(levels_over)'" != "matrix") ///
            continue
        
        local over`j'_label = el(r(levels_over),`j',1)
        
        if ("`vallabels'" == "vallabels") ///
            local over`j'_label : label (`r(over)') `over`j'_label'
        
        local col_1_width = max(`col_1_width',`u'strlen(`"`over`j'_label'"'))
        
    }
    
    local col_mean = `col_1_width' +  3
    local col_sd   = `col_1_width' + 14
    local col_n    = `col_1_width' + 25
    
    local t_width = `col_1_width' + 34
    
    local h1 = `col_1_width'-1
    local h2 = `t_width'-`col_1_width'-1
    
    tempname table
    matrix `table' = r(stats)'
    
    if ("`zstd'" == "zstd") {
        
        matrix `table' = (                                           ///
            (`table'[1...,1]-J(r(k),1,r(grand_mean)))/r(sd_overall), ///
            `table'[1...,2]/r(sd_overall),                           ///
            `table'[1...,3]                                          ///
            )
        
        local display_as_txt_z_standardized display as txt "(z-standardized)"
        
    }
    
    display
    display as txt "Summary statistics"
    `display_as_txt_z_standardized'
    display
    
    display as txt "{hline `h1'}{c TT}{hline `h2'}"
    display as txt %`=`col_1_width'-2's `"`T_depvar_label'"' _continue
    display as txt _col(`col_1_width') "{c |}" ///
        _col(`=`col_1_width'+8')  "Mean"       ///
        _col(`=`col_1_width'+15') "Std. dev."  ///
        _col(`=`col_1_width'+31') "Obs"
    display as txt "{hline `h1'}{c +}{hline `h2'}"
    
    if (`"`T_over_label'"' != "") ///
        display as txt %`=`col_1_width'-2's `"`T_over_label'"' ///
            _col(`col_1_width') "{c |}" 
    
    forvalues j = 1/`k' {
        
        display                                              ///
            as txt %`=`col_1_width'-3's `"`over`j'_label'"'  ///
            _col(`col_1_width') "{c |}"                      ///
            _col(`col_mean') `r(cfmt)' as res `table'[`j',1] ///
            _col(`col_sd')   `r(cfmt)' as res `table'[`j',2] ///
            _col(`col_n')    `r(cfmt)' as res `table'[`j',3]
        
    }
    
    if ("`zstd'" != "zstd") {
        
        display as txt "{hline `h1'}{c +}{hline `h2'}"
        
        display as txt %`=`col_1_width'-2's "Total"     ///
        _col(`col_1_width') "{c |}"                     ///
        _col(`col_mean') `r(cfmt)' as res r(grand_mean) ///
        _col(`col_sd')   `r(cfmt)' as res r(sd_overall) ///
        _col(`col_n')    `r(cfmt)' as res r(N)
        
    }
    
    display as txt "{hline `h1'}{c BT}{hline `h2'}"
    
    display as txt _col(`=`col_1_width'+3') ///
            "Max. variance ratio = "   as res `r(cfmt)' r(max_variance_ratio)
    
    if ("`zstd'" == "zstd") ///
        display as txt _col(`=`col_1_width'+1') ///
            "Std. dev. (Std. dev.) = " as res `r(cfmt)' r(sd_of_sd)
    
end


program pwmc_report_title
    
    syntax [ , zstd ]
    
    if ( ("`r(setype)'"!="ols") | inlist("`r(dfname)'","satterthwaite","welch") ) ///
        local with_unequal_variances "with unequal variances"
    
    display
    
    if (r(k)<3) ///
        display as txt "Two-sample t test `with_unequal_variances'"
    else ///
        display as txt "Pairwise comparisons of means `with_unequal_variances'"
    
    if ("`zstd'" == "zstd") ///
        display as txt "(z-standardized)"
    
    display
    
end


program pwmc_report_table_header
    
    syntax [ , noADJust ]
    
    line TT , `adjust'
    
    if (`"`r(T_se_title2)'`r(T_p_title2)'`r(T_ci_title2)'"' != "") ///
        display as txt _col(`r(T_col_1_width)') ///
            "{c |}" `r(T_se_title2)' `r(T_p_title2)' `r(T_ci_title2)'
    display as txt %`=`r(T_col_1_width)'-2's `"`r(T_depvar_label)'"' _continue
    display as txt _col(`r(T_col_1_width)') ///
        "{c |}" `r(T_diff_title)' `r(T_se_title)' `r(T_t_title)' `r(T_p_title)' `r(T_ci_title)'
    
    line + , `adjust'
    
end


program pwmc_report_table
    
    syntax name(name = table) [ , noADJust zstd ]
    
    if ("`adjust'" == "noadjust") ///
        local method noadjust
    else ///
        local method `r(mcmethod_vs)'
    
    local nmethods : word count `method'
    
    if (`nmethods' > 1) {
        
        local gh         GH
        local            GH Games and Howell
        local cochran    C
        local            C Dunnett C
        local tamhane    T2
        local            T2 Tamhane T2
        local bonferroni BON
        local            BON Bonferroni
        local sidak      SID
        local            SID Sidak
        local scheffe    SCH
        local            SCH Scheffe
        local tukey      TUK
        local            TUK Tukey
        
    }
    
    if ("`zstd'" == "zstd") & ( !missing(r(sd_overall)) ) {
        
        matrix `table' = (                    ///
            `table'[1...,1..2]/r(sd_overall), ///
            `table'[1...,3..4],               ///
            `table'[1...,5..6]/r(sd_overall)  ///
            )
        
    }
    
    local strfmt = 4 + regexm("`method'","(bonferroni|sidak|scheffe|tukey)")
    
    local kstar = r(ks)
    
    local row = 1
    
    if (`"`r(T_over_label)'"' != "") {
        
        display as txt %`=`r(T_col_1_width)'-2's ///
            `"`r(T_over_label)'"' _continue
        display as txt _col(`r(T_col_1_width)') "{c |}"
        
    }
    
    forvalues i = 1/`kstar' {
        
        display as txt %`=`r(T_col_1_width)'-3's `"`r(T_vs_label`i')'"' _continue
        display as txt _col(`r(T_col_1_width)') "{c |}" _continue
        
        display as res `r(T_diff_fmt)' `table'[`row',1] _continue // Contrast
        display as res `r(T_se_fmt)'   `table'[`row',2] _continue // Std. err.
        
        if ("`r(pveffects)'" == "pveffects") ///
            display as res `r(T_t_fmt)' `table'[`row',3] _continue // t
        
        foreach m of local method {
            
            display as res `BAR' _continue
            
            if ("`r(pveffects)'" == "pveffects") ///
                display as res `r(T_p_fmt)' `table'[`row',4] _continue // P>|t|
            
            if ("`r(cieffects)'" == "cieffects") {
                
                display as res ///
                    `r(T_ci_ll_fmt)' `table'[`row',5] /// CI ll
                    `r(T_ci_ul_fmt)' `table'[`row',6] /// CI ul
                _continue
                
            }
            
            if (`nmethods' > 1) ///
                display as txt _col(`=`r(T_col_last)'+2') ///
                    %`strfmt's "(``m'')" _continue
            
            display // end of line
            
            local ++row
            
            local BAR _col(`r(T_col_1_width)') "{c |}"
            
        }
        
        local BAR // void
        
    }
    
    line BT , `adjust'
    
    if (`"`r(T_df_title)'"' != "") ///
        display as txt `r(T_df_title)' 
    
    if (`nmethods' < 2) ///
        exit
    
    display as txt "Key: " _continue
    foreach m of local method {
        display as txt _col(`=9-strlen("``m''")') "``m'': ```m'''"
    }
    
    exit
    
    gettoken m method : method
    
    if (`nmethods' > 1) ///
        display as txt "Key: " _col(`=9-strlen("``m''")') "``m'': ```m'''"
    
    foreach m of local method {
        display as txt _col(`=9-strlen("``m''")') "``m'': ```m'''"
    }
    
end


/*  _________________________________________________________________________
                                                                utilities  */

program return_stats , rclass
    
    syntax varlist [ if ] [ in ] [ fweight iweight ] , over(varname numeric)
    
    marksample touse
    markout `touse' `over'
    quietly count if `touse'
    if ( !r(N) ) ///
        error 2000
    
    capture assert `over' == trunc(`over') if `touse' , fast
    if ( _rc ) {
        
        display as err "`over' may not contain noninteger values"
        exit 498
        
    }
    
    tempname L
    quietly tabulate `over' if `touse' , matrow(`L')
    local k = r(r)
    if (`k' < 2) {
        
        display as err "`over' has too few levels"
        exit 498
        
    }
    
    tempname stats
    matrix `stats' = J(3,`k',.)
    matrix rownames `stats' = mean sd n
    forvalues i = 1/`k' {
        
        quietly summarize `varlist' ///
            if `touse' & (`over' == `L'[`i',1]) [`weight' `exp']
        
        matrix `stats'[1,`i'] = r(mean)
        matrix `stats'[2,`i'] = r(sd)
        matrix `stats'[3,`i'] = r(N)
        
        local colnames `colnames' `i'.`over'
        
    }
    matrix colnames `stats' = `colnames'
    
    tempname grand_mean sd_overall
    quietly summarize `varlist' if `touse' [`weight' `exp']
    scalar `grand_mean' = r(mean)
    scalar `sd_overall' = r(sd)
    
    tempname sd_of_sd
    mata : st_numscalar(                          ///
        "`sd_of_sd'",                             ///
        sqrt(variance(st_matrix("`stats'")[2,]')) ///
        /                                         ///
        st_numscalar("`sd_overall'")              ///
        )
    
    tempname max_variance_ratio
    mata : st_numscalar(                              ///
        "`max_variance_ratio'",                       ///
        max(                                          ///
            sort(st_matrix("`stats'")[2,]',-1)[1]     ///
            :/                                        ///
            sort(st_matrix("`stats'")[2,]',-1)[|2\.|] ///
            ):^2                                      ///
        )
    
    return visible scalar ks                 = `k'*(`k'-1)/2
    return visible scalar k                  = `k'
    return visible local  wtype                "`weight'"
    return visible local  wexp                 `"`exp'"'
    return visible local  over                 `over'
    return visible local  depvar               `varlist'
    return hidden  scalar grand_mean         = `grand_mean'
    return hidden  scalar sd_overall         = `sd_overall'
    return hidden  scalar sd_of_sd           = `sd_of_sd'
    return hidden  scalar max_variance_ratio = `max_variance_ratio'
    return hidden  matrix levels_over        = `L'
    return hidden  matrix stats              = `stats'
    
end


program parse_mcompare
    
    syntax                     ///
    [ ,                        ///
        MCOMPare(string asis)  ///
        PROCedure(string asis) ///
        noADJust               ///
        legacydefault          ///
    ]
    
    if (`"`mcompare'`procedure'"' != "") {
        
        parse_mcompare_procedure , mcompare(`mcompare') procedure(`procedure')
        
        local posof_noadjust : list posof "noadjust" in mcompare
        if ( `posof_noadjust' ) {
            
            local mcompare : subinstr local mcompare "noadjust" ""
            local mcompare `mcompare' // strip whitespaces
            local adjust noadjust
            
        }
        
        if ("`procedure'" != "") ///
            local option_name procedure()
        else ///
            local option_name mcompare()
        
    }
    
    if ( ("`mcompare'"=="") & ("`adjust'"=="") ) ///
        local mcompare "gh" // default
    
    return_default_setype_and_df `mcompare' , `legacydefault'
    
    if (r(k) < 3) {
        
        if ("`option_name'" != "")  ///
            display as txt "too few levels; option `option_name' ignored"
        
        local mcompare // void
        local adjust noadjust
        
    }
    
    c_local adjust   : copy local adjust
    c_local mcompare : copy local mcompare
    
end


program parse_mcompare_procedure
    
    syntax                     ///
    [ ,                        ///
        MCOMPare(string asis)  ///
        PROCedure(string asis) ///
    ]
    
    if (`"`procedure'"' != "") {
        
        if ( !inlist(`"`mcompare'"',"",`"`procedure'"') ) {
            
            display as err "invalid option procedure()"
            exit 198
            
        }
        
        local mcompare : copy local procedure
        local method procedure
        
    }
    
    foreach m of local mcompare {
        
        local 0 , `m'
        capture syntax ///
        [ ,            ///
            gh         ///
            GAMes      ///
            HOWell     ///
            Cochran    ///
            TAMhane    ///
            NOADJust   ///
            BONferroni /// not documented
            SIDak      /// not documented
            SCHeffe    /// not documented
            TUKey      /// not documented
        ]
        if ( _rc ) {
            
            // backwards compatibility: case does not matter
            
            local lower_m = strlower(`"`m'"')
            
            if (`"`lower_m'"' == "gh") ///
                local gh gh
            else if (`"`lower_m'"' == "c")  ///
                local cochran cochran
            else if (`"`lower_m'"' == "t2") ///
                local tamhane tamhane
            else {
                
                if ("`method'" != "procedure") {
                    display as err "option mcompare() invalid"
                    local method method
                }
                
                display as err `"unknown `method' {bf:`m'}"'
                exit 198
                
            }
            
        }
        
        if ("`games'" == "games") ///
            local gh gh
        
        if ("`howell'" == "howell") ///
            local gh gh
        
        local mcmethod_vs ///
            `mcmethod_vs' ///
            `gh'          ///
            `cochran'     ///
            `tamhane'     ///
            `noadjust'    ///
            `bonferroni'  ///
            `sidak'       ///
            `scheffe'     ///
            `tukey'
            
    }
    
    c_local mcompare : list uniq mcmethod_vs
    
end


program return_default_setype_and_df
    
    syntax [ namelist(name=mcompare) ] [ , legacydefault ]
    
    local gh_cochran_tamhane gh cochran tamhane
    local mcompare_rest : list mcompare - gh_cochran_tamhane
    
    if ("`mcompare_rest'" == "") ///
        local legacydefault legacydefault
    
    if ("`legacydefault'" == "legacydefault") {
        
        mata : st_global("r(default_df)",     "satterthwaite", "hidden")
        mata : st_global("r(default_setype)", "hc2",           "hidden")
        
        exit
        
    }
    
    local bonferroni_sidak_scheffe_tukey bonferroni sidak scheffe tukey
    local mcompare_rest : list mcompare - bonferroni_sidak_scheffe_tukey
    
    if ("`mcompare_rest'" == "") {
        
        mata : st_numscalar("r(default_df)",  st_numscalar("r(df_r)"), "hidden")
        mata : st_global("r(default_setype)", "ols",                   "hidden")
        
    }
    
end


program parse_setype
    
    syntax     ///
    [ ,        ///
        hc0    /// not documented
        hc1    /// not documented; equivalent to vce(robust)
        Robust /// not documented; synonym for hc1
        hc2    ///
        hc3    ///
        hc4    /// not documented
        hc4m   /// not documented
        hc5    /// not documented
        ols    ///
    ]
    
    if ("`hc'" == "hc") {
        
        display as err "setype {bf:hc} not allowed"
        exit 198
        
    }
    
    if ("`robust'" == "robust") ///
        local hc1 hc1
    
    local setype `hc0' `hc1' `hc2' `hc3' `hc4' `hc4m' `hc5' `ols'
    
    if (`: word count `setype'' > 1) {
        
        // -se(name)- and -hc3- specified together
        
        display as err "option hc3 not allowed"
        exit 198
        
    }
    
    if ("`setype'" == "") /// default
        local setype `r(default_setype)'
    
    if ("`setype'" == "") {
        
        display as err "option se() required"
        exit 198
        
    }
    
    c_local setype `setype'
    
end


program parse_df
    
    capture syntax [ , df(passthru) /* Welch */ ]
    if ( _rc ) {
        
        // old syntax
        
        syntax , Welch
        local 0 , df(welch)
        
    }
    
    capture syntax [ , df(name) ]
    if ( !_rc ) {
        
        local 0 , `df'
        syntax                        ///
        [ ,                           ///
            SATterthwaite             ///
            Welch                     ///
            bm                        ///
            bell      /// synonym for bm; not documented
            mccaffrey /// synonym for bm; not documented
            Residuals                 ///
            *                         /// invalid
        ]
        
        if (`"`options'"' != "") {
            
            display as err "option df() invalid"
            display as err "{bf:`options'} not allowed"
            exit 198
            
        }
        
        if ("`bell'" == "bell") ///
            local bm bm
        
        if ("`mccaffrey'"=="mccaffrey") ) ///
            local bm bm
        
        if ("`residuals'" == "residuals") ///
            local residuals = r(df_r) 
        
        local df `satterthwaite' `welch' `bm' `residuals'
        
    }
    else syntax , DF(numlist max=1 >0)
    
    if ("`df'" == "") /// default
        local df `r(default_df)'
    
    if ("`df'" == "") {
        
        display as err "option df() required"
        exit 198
        
    }
    
    c_local df : copy local df
    
end


program confirm_variable
    
    syntax        ///
    [ ,           ///
        VARLabels ///
        VALLabels ///
    ]
    
    if ("`varlabels'" == "varlabels") {
        
        novarabbrev confirm variable `r(depvar)'
        novarabbrev confirm variable `r(over)'
        
    }
    else if ("`vallabels'" == "vallabels") ///
        novarabbrev confirm variable `r(over)'
    
end


program return_labels
    
    syntax        ///
    [ ,           ///
        VARLABELs ///
        VALLABELs ///
    ]
    
    if (c(stata_version) >= 14) ///
        local u u
    
    local col_1_width 14 // default
    
    foreach var in depvar over {
        
        if ("`varlabels'" == "varlabels") ///
            local `var'_label : variable label `r(`var')'
        
        if (`"``var'_label'"' == "") ///
            local `var'_label `r(`var')'
        
        mata : st_global("r(T_`var'_label)",st_local("`var'_label"),"hidden")
        
        local col_1_width = max(`col_1_width',`u'strlen(`"``var'_label'"')+2)
        mata : st_global("r(T_col_1_width)","`col_1_width'","hidden")
        
    }
    
    local vs_names `r(vs_names)'
    local i 0
    
    foreach vs of local vs_names {
        
        assert regexm("`vs'","^([0-9]+)vs([0-9]+)$")
        
        local vs_1 = regexs(1)
        local vs_2 = regexs(2)
        
        if ("`r(levels_over)'" == "matrix") {
            
            local vs_1 = el(r(levels_over),`vs_1',1)
            local vs_2 = el(r(levels_over),`vs_2',1)
            
            if ("`vallabels'" == "vallabels") {
                
                local vs_1 : label (`r(over)') `vs_1'
                local vs_2 : label (`r(over)') `vs_2'
                
            }
            
        }
        
        local label `"`vs_1' vs `vs_2'"'
        
        mata : st_global("r(T_vs_label`++i')",st_local("label"),"hidden")
        
        local col_1_width = max(`col_1_width',`u'strlen(`"`label'"')+3)
        mata : st_global("r(T_col_1_width)","`col_1_width'","hidden")
        
    }
    
end


program return_fmt
    
    args letter fmt fmt2
    
    if ("`c(`letter'format)'" != "") ///
        local fmt `c(`letter'format)'
    
    if ("`fmt2'" != "") {
        
        if (fmtwidth(`"`fmt2'"') <= fmtwidth("`fmt'")) ///
            local fmt `fmt2'
        else ///
            display as txt "note: invalid `letter'ormat(), using default"
        
    }
    
    mata : st_global("r(`letter'fmt)","`fmt'","hidden")
    
end


program return_effects
    
    syntax        ///
    [ ,           ///
        pveffects ///
        pvalues   ///
        cieffects ///
        effects   ///
    ]
    
    if ("`effects'" == "effects") {
        
        local cieffects cieffects
        local pveffects pveffects
        
    }
    else {
        
        if ("`pvalues'" == "pvalues") ///
            local pveffects pveffects
        else if ("`pveffects'" == "") ///
            local cieffects cieffects
        
    }
    
    mata : st_global("r(pveffects)",st_local("pveffects"),"hidden")
    mata : st_global("r(cieffects)",st_local("cieffects"),"hidden")
    
end


program return_table_layout
    
    syntax           ///
    [ ,              ///
        noADJust     ///
        VARLabels    ///
        VALLabels    ///
    ]
    
    if ("`adjust'" == "noadjust") ///
        local method noadjust
    else ///
        local method `r(mcmethod_vs)'
    
    local nmethods : word count `method'
    
    local diff_title _col(`=`r(T_col_1_width)'+4') "Contrast"
    local diff_fmt   _col(`=`r(T_col_1_width)'+3') `r(cfmt)'
    
    local se_title _col(`=`r(T_col_1_width)'+15') "Std. err." 
    local se_fmt   _col(`=`r(T_col_1_width)'+14') `r(cfmt)'
    
    if (`"`r(setype)'"' != "ols") {
        
        local se_title _col(`=`r(T_col_1_width)'+15') "std. err."
        
        local setype = "Robust HC"+substr("`r(setype)'",3,.)
        local se_title2 _col(`=`r(T_col_1_width)'+14') "`setype'"
        
    }
    
    if ("`r(pveffects)'" == "pveffects") {
        
        local t_title _col(`=`r(T_col_1_width)'+30') "t"
        local t_fmt   _col(`=`r(T_col_1_width)'+24') `r(sfmt)'
        
        local p_title _col(`=`r(T_col_1_width)'+35') "P>|t|"
        local p_fmt   _col(`=`r(T_col_1_width)'+35') `r(pfmt)'
        
        if (`nmethods' == 1) {
            
            if ("`method'" == "noadjust") ///
                local p_title2 _col(`=`r(T_col_1_width)'+30') "Unadjusted"
            else if ("`method'" == "cochran") ///
                local p_title2 _col(`=`r(T_col_1_width)'+31') "Dunnett C"
            else if ("`method'" == "gh") ///
                local p_title2 _col(`=`r(T_col_1_width)'+28') "Games Howell"
            else if ("`method'" == "tamhane") ///
                local p_title2 _col(`=`r(T_col_1_width)'+30') "Tamhane T2"
            else if ("`method'" == "bonferroni") ///
                local p_title2 _col(`=`r(T_col_1_width)'+30') "Bonferroni"
            else if ("`method'" == "sidak") ///
                local p_title2 _col(`=`r(T_col_1_width)'+33') "Sidak"
            else if ("`method'" == "scheffe") ///
                local p_title2 _col(`=`r(T_col_1_width)'+32') "Scheffe"
            else if ("`method'" == "tukey") ///
                local p_title2 _col(`=`r(T_col_1_width)'+33') "Tukey"
            
        }
        
        local col_last = `r(T_col_1_width)' + 35 + fmtwidth("`r(pfmt)'")
        
    }
    
    if ("`r(cieffects)'" == "cieffects") {
        
        if ("`r(pveffects)'" == "pveffects") {
            
            local col_ci_title = `r(T_col_1_width)' + 45 - (strlen("`r(level)'")-2)
            local ci_ll_fmt _col(`=`r(T_col_1_width)'+44') `r(cfmt)'
            local ci_ul_fmt _col(`=`r(T_col_1_width)'+56') `r(cfmt)'
            
            local col_last = `r(T_col_1_width)' + 56 + fmtwidth("`r(cfmt)'")
            
        }
        else {
            
            local col_ci_title = `r(T_col_1_width)' + 28 - (strlen("`r(level)'")-2)
            local ci_ll_fmt _col(`=`r(T_col_1_width)'+27') `r(cfmt)'
            local ci_ul_fmt _col(`=`r(T_col_1_width)'+39') `r(cfmt)'
            
            local col_last = `r(T_col_1_width)' + 39 + fmtwidth("`r(cfmt)'")
            
        }
        
        local ci_title  _col(`col_ci_title') "[`r(level)'% conf. interval]"
        
        if (`nmethods' == 1) {
            
            if ("`method'" == "noadjust") ///
                local ci_title2 _col(`=`col_ci_title'+6') "Unadjusted"
            else if ("`method'" == "cochran") ///
                local ci_title2 _col(`=`col_ci_title'+7') "Dunnett C"
            else if ("`method'" == "gh") ///
                local ci_title2 _col(`=`col_ci_title'+2') "Games and Howell"
            else if ("`method'" == "tamhane") ///
                local ci_title2 _col(`=`col_ci_title'+6') "Tamhane T2"
            else if ("`method'" == "bonferroni") ///
                local ci_title2 _col(`=`col_ci_title'+6') "Bonferroni"
            else if ("`method'" == "sidak") ///
                local ci_title2 _col(`=`col_ci_title'+8') "Sidak"
            else if ("`method'" == "scheffe") ///
                local ci_title2 _col(`=`col_ci_title'+8') "Scheffe"
            else if ("`method'" == "tukey") ///
                local ci_title2 _col(`=`col_ci_title'+8') "Tukey"
            
        }
        
    }
    
    local col_df_title = `col_last'
    
    if (`nmethods' > 1) ///
        local col_df_title = `col_last' + 6 ///
            + regexm("`method'","(bonferroni|sidak|scheffe|tukey)")
    
    if ("`r(dfname)'" == "satterthwaite") ///
        local df_title _col(`=`col_df_title'-34') "Satterthwaite's degrees of freedom"
    else if ("`r(dfname)'" == "welch") ///
        local df_title _col(`=`col_df_title'-26') "Welch's degrees of freedom"
    else if ("`r(dfname)'"=="bm") ///
        local df_title _col(`=`col_df_title'-39') "Bell and McCaffrey's degrees of freedom"
    else ///
        local df_title _col(`=`col_df_title'-28') "Degrees of freedom = " as res %7.0g r(dof)
    
    mata : st_global("r(T_diff_title)", st_local("diff_title"), "hidden")
    mata : st_global("r(T_se_title)",   st_local("se_title"),   "hidden")
    mata : st_global("r(T_t_title)",    st_local("t_title"),    "hidden")
    mata : st_global("r(T_p_title)",    st_local("p_title"),    "hidden")
    mata : st_global("r(T_ci_title)",   st_local("ci_title"),   "hidden")
    
    mata : st_global("r(T_se_title2)",  st_local("se_title2"),  "hidden")
    mata : st_global("r(T_p_title2)",   st_local("p_title2"),   "hidden")
    mata : st_global("r(T_ci_title2)",  st_local("ci_title2"),  "hidden")
    
    mata : st_global("r(T_diff_fmt)",   st_local("diff_fmt"),   "hidden")
    mata : st_global("r(T_se_fmt)",     st_local("se_fmt"),     "hidden")
    mata : st_global("r(T_t_fmt)",      st_local("t_fmt"),      "hidden")
    mata : st_global("r(T_p_fmt)",      st_local("p_fmt"),      "hidden")
    mata : st_global("r(T_ci_ll_fmt)",  st_local("ci_ll_fmt"),  "hidden")
    mata : st_global("r(T_ci_ul_fmt)",  st_local("ci_ul_fmt"),  "hidden")
    
    mata : st_global("r(T_col_last)",   st_local("col_last"),   "hidden")
    
    mata : st_global("r(T_df_title)",   st_local("df_title"),   "hidden")
    
end


program line
    
    syntax anything(name = separator) [ , noADJust ]
    args separator
    
    local w_1 = `r(T_col_1_width)' - 1
    local w_2 = `r(T_col_last)' - `r(T_col_1_width)' - 1
    
    if ("`adjust'" != "noadjust") ///
        if (`: word count `r(mcmethod_vs)'' > 1) ///
            local w_2 = `w_2' + 6 ///
                + regexm("`r(mcmethod_vs)'","(bonferroni|sidak|scheffe|tukey)")
    
    display as txt "{hline `w_1'}{c `separator'}{hline `w_2'}"
    
end


/*  _________________________________________________________________________
                                                                     Mata  */

version 12.1


mata :


mata set matastrict   on
mata set mataoptimize on


class pwmc_ado
{ 
    public :
        
        void get_st_r()
        void estimate()
        void set_st_r()
        
    protected :
        
        real   rowvector hc_delta()
        void             vs_names()
        void             st_r_mat()
        
        real   scalar    k
        real   scalar    kstar
        real   rowvector xbar
        real   rowvector sd
        real   rowvector n
        
        real   scalar    N
        real   rowvector nu
        
        real   matrix    V
        
        real   rowvector b_vs
        real   matrix    V_vs
        real   matrix    df_vs
        
        string matrix    vs_names
}


void pwmc_ado::get_st_r()
{
    k     = st_numscalar("r(k)")
    kstar = st_numscalar("r(ks)")
    xbar  = st_matrix("r(stats)")[1,]
    sd    = st_matrix("r(stats)")[2,]
    n     = st_matrix("r(stats)")[3,]
}


void pwmc_ado::estimate()
{
    real rowvector np1, Nnk, delta_hc4, delta_hc5, delta_hc4m
    real scalar    i, j
    real rowvector ij
    
    
    N   = sum(n)
    nu  = n:-1
    np1 = n:+1
    
    Nnk        = (N:/n)/k
    delta_hc4  = colmin(J(1,k,4)\Nnk)
    delta_hc5  = colmin(J(1,k,max((4,(.7*N/rowmin(n))/k)))\Nnk)/2
    delta_hc4m = colmin(J(1,k,1)\Nnk):+colmin(J(1,k,1.5)\Nnk)
    
    V = (
        
        hc_delta(0) * (N/(N-k)) \ // HC1; equivalent to vce(robust)
        hc_delta(1)             \ // HC2
        hc_delta(2)             \ // HC3
        hc_delta(delta_hc4)     \ // HC4
        hc_delta(delta_hc5)     \ // HC5
        hc_delta(delta_hc4m)    \ // HC4m
        hc_delta(0)             \ // HC0
        (sum(sd:^2:*nu)/(N-k)):/n // OLS
        
        )
    
    b_vs  = J(1,kstar,.z)
    V_vs  = J(8,kstar,.z)
    df_vs = J(3,kstar,.z)
    
    np1 = n:+1
    
    for (i=j=1; i<k; i++) {
        
        ij = (j..(k-i)+(j-1))
        
        b_vs[ij] = xbar[|i+1\k|]:-xbar[i]
        
        V_vs[,ij] = (V[|.,i+1\.,k|]:+V[,i])
        
        df_vs[1,ij] = (
            
            V_vs[2,ij]:^2
            :/
            ( V[|2,i+1\2,k|]:^2:/nu[|i+1\k|] :+ V[2,i]:^2:/nu[i] )
            
            ) // Satterthwaite
        
        df_vs[2,ij] = -2 :+ (
            
            V_vs[2,ij]:^2
            :/
            ( V[|2,i+1\2,k|]:^2:/np1[|i+1\k|] :+ V[2,i]:^2:/np1[i] )
            
            ) // Welch
            
        df_vs[3,ij] = (
            
            ( (n[|i+1\k|]:+n[i]):^2:*nu[|i+1\k|]:*nu[i] )
            :/
            ( n[|i+1\k|]:^2:*nu[|i+1\k|] :+ n[i]:^2:*nu[i] )
            
            ) // Bell & McCaffrey
        
        j = j + (k-i)
        
    }
}


void pwmc_ado::set_st_r()
{
    string matrix colstripe
    
    
    if (st_global("r(over)") != "")
        colstripe = (J(k,1,""),strofreal(1::k):+".":+st_global("r(over)"))
    else 
        colstripe = ""
    
    vs_names()
    
    st_numscalar("r(N)",N)
    st_numscalar("r(df_r)",(N-k),"hidden")
    
    st_global("r(cmd2)",st_global("r(cmd)"))
    st_global("r(cmd)","pwmc")
    
    st_r_mat("se_hc0",  sqrt(V[7,]), ("","se_hc0"),  colstripe, "hidden")
    st_r_mat("se_hc1",  sqrt(V[1,]), ("","se_hc1"),  colstripe, "hidden")
    st_r_mat("se_hc2",  sqrt(V[2,]), ("","se_hc2"),  colstripe, "hidden")
    st_r_mat("se_hc3",  sqrt(V[3,]), ("","se_hc3"),  colstripe, "hidden")
    st_r_mat("se_hc4",  sqrt(V[4,]), ("","se_hc4"),  colstripe, "hidden")
    st_r_mat("se_hc5",  sqrt(V[5,]), ("","se_hc5"),  colstripe, "hidden")
    st_r_mat("se_hc4m", sqrt(V[6,]), ("","se_hc4m"), colstripe, "hidden")
    st_r_mat("se_ols",  sqrt(V[8,]), ("","se_ols"),  colstripe, "hidden")
    
    st_r_mat("b_vs", b_vs, "", vs_names, "hidden")
    
    st_r_mat("se_hc0_vs",  sqrt(V_vs[7,]), "", vs_names, "hidden")
    st_r_mat("se_hc1_vs",  sqrt(V_vs[1,]), "", vs_names, "hidden")
    st_r_mat("se_hc2_vs",  sqrt(V_vs[2,]), "", vs_names, "hidden")
    st_r_mat("se_hc3_vs",  sqrt(V_vs[3,]), "", vs_names, "hidden")
    st_r_mat("se_hc4_vs",  sqrt(V_vs[4,]), "", vs_names, "hidden")
    st_r_mat("se_hc5_vs",  sqrt(V_vs[5,]), "", vs_names, "hidden")
    st_r_mat("se_hc4m_vs", sqrt(V_vs[6,]), "", vs_names, "hidden")
    st_r_mat("se_ols_vs",  sqrt(V_vs[8,]), "", vs_names, "hidden")
    
    
    st_r_mat("df_satterthwaite_vs", df_vs[1,], "", vs_names, "hidden")
    st_r_mat("df_welch_vs",         df_vs[2,], "", vs_names, "hidden")
    st_r_mat("df_bm_vs",            df_vs[3,], "", vs_names, "hidden")
    
    // double store historical defaults in r()
    
    st_r_mat("se_vs", sqrt(V_vs[2,]), "", vs_names, "hidden")
    st_r_mat("df_vs", df_vs[1,],      "", vs_names, "hidden")
}


real rowvector pwmc_ado::hc_delta(real rowvector delta)
{
    return( sd:^2 :/ (nu:^(delta:-1):*n:^(2:-delta)) )
}


void pwmc_ado::vs_names()
{
    string colvector vs_level
    real   scalar    i, j
    real   rowvector ij
    
    
    vs_names = J(kstar,1,"")
    vs_level = strofreal((1::k))
    
    for (i=j=1; i<k; i++) {
        
        ij = (j::(k-i)+(j-1))
        vs_names[ij] = vs_level[|i+1\k|]:+"vs":+vs_level[i]:+vs_names[ij]
        j  = j + (k-i)
        
    }
    
    if (st_global("r(over)") != "")
        vs_names = vs_names:+("."+st_global("r(over)"))
    
    vs_names = (J(kstar,1,""),vs_names)
}


void pwmc_ado::st_r_mat(
    
    string scalar matname, 
    real   matrix Matrix,
  | string matrix rownames,
    string matrix colnames,
    string scalar hcat
    
    )
{
    string scalar rmatname
    
    
    rmatname = sprintf("r(%s)",matname)
    
    if (args() < 5) 
        st_matrix(rmatname,Matrix)
    else 
        st_matrix(rmatname,Matrix,hcat)
    
    if ( (args()<3) | (length(Matrix)==0) ) 
        return
    
    if (rownames != "") 
        st_matrixrowstripe(rmatname,rownames)
    
    if (colnames != "")
        st_matrixcolstripe(rmatname,colnames)
}


    /*  _________________________________  tables  */

class pwmc_tables extends pwmc_ado
{
    public :
        
        void settings()
        void table_vs()
        void mcompare()
        void set_st_r() // re-define
        
    private :
        
        void  dunnett_c()
        void  set_r_table()
        void  set_r_table_vs_mc()
        void  r_historical()
        
        string rowvector mcmethod
        string scalar    setype
        string scalar    dfname
        
        real   rowvector se
        real   rowvector se_vs
        real   scalar    alpha
        
        real   matrix    table_vs
        real   matrix    table_mc   // by methods
        real   matrix    table_mc_d // by differences
        
        real   matrix    pvalue_adj
        real   matrix    crit_adj
        real   matrix    ll_adj
        real   matrix    ul_adj
        
        string matrix    mc_names
}


void pwmc_tables::settings(
    
    string scalar mcompare,
    string scalar st_setype,
    string scalar st_dfname,
    real   scalar level
    
    )
{
    get_st_r()
    
    mcmethod = tokens(mcompare)
    
    setype = st_setype
    se     = st_matrix("r(se_"+setype+")")
    se_vs  = st_matrix("r(se_"+setype+"_vs)")
    
    dfname = st_local(st_dfname)*(_strtoreal(st_local(st_dfname),df_vs))
    df_vs  = (dfname!="") ? st_matrix("r(df_"+dfname+"_vs)") : J(1,kstar,df_vs)
    
    alpha = level/100
}


void pwmc_tables::table_vs()
{
    table_vs = J(9,kstar,0)
    
    table_vs[1,] = st_matrix("r(b_vs)")              // b
    table_vs[2,] = se_vs                             // se
    table_vs[3,] = table_vs[1,]:/table_vs[2,]        // t
    table_vs[7,] = df_vs                             // df
    table_vs[4,] = 2*ttail(df_vs,abs(table_vs[3,]))  // pvalue
    table_vs[8,] = invttail(df_vs,(1-alpha)/2)       // crit
    table_vs[5,] = table_vs[1,]:-table_vs[8,]:*se_vs // ll
    table_vs[6,] = table_vs[1,]:+table_vs[8,]:*se_vs // ll
}


void pwmc_tables::mcompare()
{
    real rowvector abst, pvalue
    real scalar    row
    
    
    if ( !cols(mcmethod) )
        return
    
    abst   = abs(table_vs[3,])
    pvalue = table_vs[4,]
    
    pvalue_adj = crit_adj = J(cols(mcmethod),kstar,.z)
    
    if ( any(row=select((1..cols(mcmethod)),(mcmethod:=="cochran"))) ) {
        dunnett_c(row)
    }
    
    if ( any(row=select((1..cols(mcmethod)),(mcmethod:=="gh"))) ) {
        pvalue_adj[row,] = 1:-tukeyprob(k,df_vs,abst*sqrt(2))
        crit_adj[row,]   = invtukeyprob(k,df_vs,alpha)/sqrt(2)
    }
    
    if ( any(row=select((1..cols(mcmethod)),(mcmethod:=="tamhane"))) ) {
        pvalue_adj[row,] = 1 :- (1:-pvalue):^kstar
        crit_adj[row,]   = invttail(df_vs,(1-alpha^(1/kstar))/2)
    }
    
    if ( any(row=select((1..cols(mcmethod)),(mcmethod:=="bonferroni"))) ) {
        pvalue_adj[row,] = colmin(J(1,kstar,1)\pvalue*kstar)
        crit_adj[row,]   = invttail(df_vs,((1-alpha)/kstar)/2) 
    }
    
    if ( any(row=select((1..cols(mcmethod)),(mcmethod:=="sidak"))) ) {
        pvalue_adj[row,] = 1 :- (1:-pvalue):^kstar
        crit_adj[row,]   = invttail(df_vs,(1-alpha^(1/kstar))/2)
    }
    
    if ( any(row=select((1..cols(mcmethod)),(mcmethod:=="scheffe"))) ) {
        pvalue_adj[row,] = Ftail(k-1,df_vs,abst:^2/(k-1))
        crit_adj[row,]   = sqrt(invFtail(k-1,df_vs,(1-alpha))*(k-1))
    }
    
    if ( any(row=select((1..cols(mcmethod)),(mcmethod:=="tukey"))) ) {
        pvalue_adj[row,] = 1:-tukeyprob(k,df_vs,abst*sqrt(2))
        crit_adj[row,]   = invtukeyprob(k,df_vs,alpha)/sqrt(2)
    }
    
    ll_adj = table_vs[1,]:-crit_adj:*se_vs
    ul_adj = table_vs[1,]:+crit_adj:*se_vs
    
    table_mc = J(cols(mcmethod),1,table_vs[(1::3),]')
    table_mc = (table_mc,vec(pvalue_adj'),vec(ll_adj'),vec(ul_adj'))
    
    table_mc_d = colshape(J(1,cols(mcmethod),table_vs[(1::3),]'),3)
    table_mc_d = (table_mc_d,vec(pvalue_adj),vec(ll_adj),vec(ul_adj))
}


void pwmc_tables::dunnett_c(real scalar row)
{
    real rowvector abst, SR
    real scalar    i, j
    real rowvector ij
    
    
    nu   = (dfname=="") ? df_vs[1..k] : (n:-1)
    V    = se:^2    // ols, hc0, hc1, hc2, hc3, hc4, hc4m, or hc5
    V_vs = se_vs:^2 // ols, hc0, hc1, hc2, hc3, hc4, hc4m, or hc5
    abst = abs(table_vs[3,])*sqrt(2)
    SR   = invtukeyprob(k,nu,alpha):*V
    
    for (i=j=1; i<k; i++) {
        
        ij = (j..(k-i)+(j-1))
        
        pvalue_adj[row,ij] = 1 :- (
            tukeyprob(k,nu[|i+1\k|],abst[ij]):*V[|i+1\k|]
            :+
            tukeyprob(k,nu[i],abst[ij]):*V[i]
            ) :/ V_vs[ij]
        
        crit_adj[row,ij] = ( (SR[|i+1\k|]:+SR[i]):/V_vs[ij] ) / sqrt(2)
        
        j  = j + (k-i)
        
    }
}


void pwmc_tables::set_st_r()
{
    string matrix rowstripe, rowstripe_adj, mc_names
    
    
    rowstripe = (J(9,1,""),("b"\"se"\"t"\"pvalue"\"ll"\"ul"\"df"\"crit"\"eform"))
    rowstripe_adj = (J(6,1,""),("b"\"se"\"t"\"pvalue_adj"\"ll_adj"\"ul_adj"))
    
    vs_names()
    mc_names = (J(cols(mcmethod),1,""),mcmethod')
    
    st_numscalar("r(level)",alpha*100)
    
    if (dfname == "")
        st_numscalar("r(dof)",df_vs[1],"hidden")
    
    st_global("r(dfname)",dfname)
    st_global("r(setype)",setype)
    st_global("r(mcmethod_vs)",invtokens(mcmethod))
    
    set_r_table(rowstripe)
    
    st_r_mat("table_vs",table_vs,rowstripe,vs_names)
    
    set_r_table_vs_mc(rowstripe)
    
    st_r_mat("table_mc",table_mc, 
        (
         colshape(J(1,kstar,mc_names[,2]),1), 
         J(cols(mcmethod),1,vs_names[,2])
        ),
        rowstripe_adj,
        "hidden"
    )
    
    st_r_mat("table_mc_d",table_mc_d, 
        (
         colshape(J(1,cols(mcmethod),vs_names[,2]),1), 
         J(kstar,1,mc_names[,2])
        ),
        rowstripe_adj,
        "hidden"
    )
    
    if (st_global("r(over)") != "")
        st_global(
            "r(vs_names)",
            invtokens(substr(vs_names[,2],1,strpos(vs_names[,2],"."):-1)'),
            "hidden"
            )
    else
        st_global("r(vs_names)",invtokens(vs_names[,2]'),"hidden")
    
    r_historical()
}


void pwmc_tables::set_r_table(string matrix rowstripe)
{
    real   matrix table
    string matrix colstripe
    
    
    table = J(9,k,0)
    
    table[1,] = xbar                              // mean
    table[2,] = se                                // se
    table[3,] = table[1,]:/table[2,]              // t
    table[7,] = J(1,k,st_numscalar("r(df_r)"))    // df
    table[4,] = 2*ttail(table[7,],abs(table[3,])) // pvalue
    table[8,] = invttail(table[7,],(1-alpha)/2)   // crit
    table[5,] = table[1,]:-table[8,]:*table[2,]   // ll
    table[6,] = table[1,]:+table[8,]:*table[2,]   // ul
    
    if (st_global("r(over)") != "")
        colstripe = (J(k,1,""),strofreal(1::k):+".":+st_global("r(over)"))
    else
        colstripe = ""
    
    st_r_mat("table",table,rowstripe,colstripe,"hidden")
}


void pwmc_tables::set_r_table_vs_mc(string matrix rowstripe)
{
    real scalar i, j
    
    
    for (i=j=1; i<=cols(mcmethod); i++)
        st_r_mat("table_vs_"+mcmethod[i],
            (table_mc[|j,1\(j=j+kstar)-1,.|]'\df_vs\crit_adj[i,]\J(1,kstar,0)),
            rowstripe, vs_names
            )
}


void pwmc_tables::r_historical()
{
    string matrix proc_names
    real   scalar i
    
    
    proc_names = mcmethod
    if ( length(proc_names) ) {
        proc_names = subinstr(proc_names,"cochran","c")
        proc_names = subinstr(proc_names,"tamhane","t2")
        proc_names = subinstr(proc_names,"bonferroni","bon")
        proc_names = subinstr(proc_names,"scheffe","sch")
    }
    
    st_global("r(procedure)",invtokens(proc_names),"hidden")
    
    proc_names = (J(cols(mcmethod),1,""),proc_names')
    
    st_r_mat("t",     table_vs[3,],    "", vs_names, "hidden")
    st_r_mat("nuhat", table_vs[7,],    "", vs_names, "hidden")
    st_r_mat("Var",   table_vs[2,]:^2, "", vs_names, "hidden")
    st_r_mat("diff",  table_vs[1,],    "", vs_names, "hidden")
    
    st_r_mat("A",     crit_adj',   vs_names, proc_names, "hidden")
    st_r_mat("p_adj", pvalue_adj', vs_names, proc_names, "hidden")
    
    st_r_mat("ci",(vec(ll_adj'),vec(ul_adj')), 
        (
         colshape(J(1,kstar,proc_names[,2]),1), 
         J(cols(mcmethod),1,vs_names[,2])
        ),
        ((""\""), ("ll"\"ul")),
        "hidden"
    )
    
    for (i=1; i<=rows(proc_names); i++) {
        
        st_r_mat("A_" +proc_names[i, 2], crit_adj[i,], "", vs_names, "hidden")
        st_r_mat("ll_"+proc_names[i, 2], ll_adj[i,],   "", vs_names, "hidden")
        st_r_mat("ul_"+proc_names[i, 2], ul_adj[i,],   "", vs_names, "hidden")
        
    }
}


/*  _________________________________________________________________________
                                                          entry point ado  */

void pwmc_estimate()
{
    class pwmc_ado scalar pwmc
    
    
    pwmc.get_st_r()
    
    pwmc.estimate()
    
    pwmc.set_st_r()
}


void pwmc_mctables(
    
    string scalar mcompare,
    string scalar st_setype,
    string scalar st_dfname,
    real   scalar level
    
    )
{
    class pwmc_tables scalar T
    
    
    T.settings(mcompare,st_setype,st_dfname,level)
    
    T.table_vs()
    
    T.mcompare()
    
    T.set_st_r()
}


end


exit


/*  _________________________________________________________________________
                                                              version history

3.0.0   24mar2025   new -mcompare()- method -sidak-; not documented
                    new -mcompare()- method -tukey-; not documented
                    new option -legacydefault-; not documented
                    mcompare() bonferroni, sidak, scheffe, and tukey
                        imply se(ols) and df(residuals); breaking change
                    option -vallabels- now default
                    revised output
                    first release since 2.1.0  19jul2024
                    GitHub and SSC
3.0.0-8 31oct2024   bug fix: -summarize- ignored -vallabels-
                    -summarize- displays grand mean and overall sd
                    -summarize- and -zstd- now documented
3.0.0-7 29oct2024   -summarize- only displays r(sd_of_sd) with -zstd-
3.0.0-6 28oct2024   new option -zstd-; not documented
                    new r(grand_mean)
3.0.0-5 28oct2024   new r(sd_of_sd)
                    upload to private GitHub repository
3.0.0-4 25oct2024   bug fix: markout -over()-; but would not affect results
                    must be born after 25nov2013
                    new r(sd_overall)
                    option -summarize- now reports sd of (standardized) sd
3.0.0-3 10oct2024   bug fix: Dunnett's C wrong df for equal sample sizes
                        with df(bm) or equal variances
                    bug fix: mcompare(cochran) df(bm) failed to display df
3.0.0-2 05oct2024   Dunnett's C uses weighted se(); breaking change
                    Dunnett's C affected by df(residual|<#>); breaking change
                    changed r(mcmethod_vs) to full names; breaking change
                    new returned results; potentially breaking change
                    remove option -returnold- (breaks 3.0.0-1)
                    return all results again (might break 3.0.0-1)
                    may be born before 25nov2013
                    option se() documented; hc3 undocumented
                    new se(hc#); # := 0, 1, 4, 4m, 5; not documented
                    new option -summarize-; not documented
                    changed title of results table
                    revised output
3.0.0-1 19sep2024   bug fix: Dunnett's C now ignores hc3 for weights
                    bug fix: correct Scheffe critical value for k>3
                    bug fix: option -hc- no longer allowed
                    new default mcompare(gh); breaking change
                    new name for Dunnett's C: mcompare(cochran)
                    no longer allow alias mcompare(dunnett)
                    compute adjusted p-value for Dunnett's C
                    revised and extended option df()
                    -welch- no longer documented; now df(welch)
                    new df(bm)
                    new df(residual)
                    revised output
                    major refactoring of Mata code
                    fewer returned results; breaking change
                    new option se(); not documented
                    new se(ols); not documented
                    new option -returnold-; not documented
                    allow iweights; not documneted
                    new returned results; not documented
2.2.0   30jul2024   new alias mcompare(dunnett)
                    new aliases mcompare(games), mcompare(howell) 
                    new alias mcompare(tamhane)
                    never released
2.1.0   19jul2024   new -mcompare()- method -bonferroni-; not documented
                    new -mcompare()- method -scheffe-; not documented
                    new option -df()-; not documented
                    released on GitHub; not on SSC
2.0.2   18jul2024   revised output
                    released on GitHub; not on SSC
2.0.1   18jul2024   must be born 25nov2013 or later
                    revised output
                    released on GitHub; not on SSC
2.0.0   17jul2024   complete rewrite
                    bug fix Linux: no longer rely on external Mata function
                    new options -noadjust-, -hc3-, and -welch-
                    allow k=2 groups
                    changed returned results; old results hidden
                    fweights are allowed (not documented)
                    revised output
1.1.0   07jan2014   new option -pvalues-
                    calculate adjusted p-values (except for Dunnett's C)
                    new options -pformat()-, -sformat()-, -notable-
                    option -mcompare()- as synonym for -procedure()-
                    replay() results
                    revised output
                    changed returned results; old results hidden
                    new external Mata function mPwmc.mo
1.0.0   28jan2013   first release on SSC
