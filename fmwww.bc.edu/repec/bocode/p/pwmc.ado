*! version 2.0.0  17jul2024
program pwmc
    
    version 12.1
    
    if ( replay() ) {
        
        pwmc_display `0'
        exit
        
    }
    
    pwmc_estimate_and_display `0'
    
end


/*  _________________________________________________________________________
                                                                 estimate  */

program pwmc_estimate_and_display
    
    syntax varname(numeric) [ if ] [ in ] [ fweight ] ///
        , Over(varname numeric)                       /// required
    [                                                 ///
        MCOMPare(passthru)                            ///
        PROCedure(passthru)       /// synonym mcompare(); no longer documented
        noADJust       /// synonym for mcompare(noadjust)
        HC3                                           ///
        Welch                                         ///
        Level(cilevel)                                ///
        CIeffects                                     ///
        PVEffects                                     ///
        PValues       /// retained synonym for pveffects; no longer documented
        EFFects                                       ///
        VARLabels                                     ///
        VALLabels                                     ///        
        CFORMAT(passthru)                             ///
        PFORMAT(passthru)                             ///
        SFORMAT(passthru)                             ///
        noTABle                                       ///
    ]
    
    return_stats `varlist' `if' `in' [`weight' `exp'] , over(`over')
    
    mata : pwmc_estimate()
    
    pwmc_display ,                                    ///
        `mcompare' `procedure' `adjust'               ///
        `hc3' `welch' level(`level')                  ///
        `cieffects' `pveffects' `pvalues' `effects'   ///
        `varlabels' `vallabels'                       ///
        `cformat' `pformat' `sformat'                 ///
        `table'
    
end


/*  _________________________________________________________________________
                                                                  display  */

program pwmc_display
    
    if ( !inlist("`r(cmd)'","pwmc","pwmci") ) {
        
        display as err "last command not pwmc"
        exit 301
        
    }
    
    if ("`r(cmd)'" == "pwmci") ///
        mata : pwmc_estimate()
    
    if ("`r(cmd2)'" != "pwmci") {
        
        local VARLabels VARlabels
        local VALLabels VALLabels
        
    }
    
    syntax                   ///
    [ ,                      ///
        MCOMPare(passthru)   ///
        PROCedure(passthru)  /// 
        noADJust             ///
        HC3                  ///
        Welch                ///
        Level(cilevel)       ///
        CIeffects            ///
        PVEffects            ///
        PValues              ///
        EFFects              ///
        `VARLabels'          ///
        `VALLabels'          ///        
        CFORMAT(string asis) ///
        PFORMAT(string asis) ///
        SFORMAT(string asis) ///
        noTABle              ///
    ]
    
    parse_mcompare , `mcompare' `procedure' `adjust'
    
    confirm_variable , `varlabels' `vallabels'
    
    mata : pwmc_mctables(`level',"`hc3'","`welch'","`mcompare'")
    
    if ( ("`table'"=="notable") | (!c(noisily)) ) ///
        exit
    
    return_effects , `pveffects' `pvalues' `cieffects' `effects'
    
    return_fmt c %9.7g `cformat'
    return_fmt p %5.3f `pformat'
    return_fmt s %8.2f `sformat'
    
    return_table_layout , `hc3' `adjust' `varlabels' `vallabels'
    
    tempname table
    
    pwmc_display_title
    
    pwmc_display_table_header , `adjust'
    
    if ("`adjust'" == "noadjust") {
        
        matrix `table' = r(table_vs)
        matrix `table' = `table'[1..6,1...]'
        
        pwmc_display_table `table' , noadjust
        
        if ("`r(mcmethod_vs)'" == "") ///
            exit
        
        display
        
        return_table_layout , `hc3' `varlabels' `vallabels'
        
        pwmc_display_table_header
        
    }
    
    matrix `table' = r(table_mc_d)
    
    pwmc_display_table `table'
    
end


program pwmc_display_title
    
    display
    
    if (r(k)<3) ///
        display as txt "Two-sample t test with unequal variances"
    else ///
        display as txt "Pairwise comparisons of means with unequal variances"
    
end


program pwmc_display_table_header
    
    syntax [ , noADJust ]
    
    line TT , `adjust'
    display as txt _col(`r(T_col_1_width)') ///
        "{c |}" `r(T_se_title2)' `r(T_p_title2)' `r(T_ci_title2)'
    display as txt %`=`r(T_col_1_width)'-2's `"`r(T_depvar_label)'"' _continue
    display as txt _col(`r(T_col_1_width)') ///
        "{c |}" `r(T_diff_title)' `r(T_se_title)' `r(T_t_title)' `r(T_p_title)' `r(T_ci_title)'
    
    line + , `adjust'
    
end

program pwmc_display_table
    
    syntax name(name = table) [ , noADJust ]
    
    if ("`adjust'" == "noadjust") ///
        local method noadjust
    else ///
        local method = strupper("`r(mcmethod_vs)'")
    
    local nmethods : word count `method'
    
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
        
        *display as txt _col(`r(T_col_1_width)') "{c |}" _continue
        
        display as res `r(T_diff_fmt)' `table'[`row',1] _continue // Diff.
        display as res `r(T_se_fmt)'   `table'[`row',2] _continue // Std. Err.
        
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
                display as txt _col(`=`r(T_col_last)'+2') %4s "(`m')" _continue
            
            display // end of line
            
            local ++row
            
            local BAR _col(`r(T_col_1_width)') "{c |}"
            
        }
        
        local BAR // void
        
    }
    
    line BT , `adjust'
    
    if (`nmethods' == 1) ///
        exit
    
    local C  Dunnett C
    local GH Games and Howell
    local T2 Tamhane T2
    
    display as txt "Key:" _continue
    foreach m of local method {
        display as txt _col(`=8-strlen("`m'")') "`m': ``m''"
    }
    
end


/*  _________________________________________________________________________
                                                                utilities  */

program return_stats , rclass
    
    syntax varlist [ if ] [ in ] [ fweight ] , OVER(string)
    
    marksample touse
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
        
    }
    
    return visible scalar ks          = `k'*(`k'-1)/2
    return visible scalar k           = `k'
    return visible local  wtype         "`weight'"
    return visible local  wexp          `"`exp'"'
    return visible local  over          `over'
    return visible local  depvar        `varlist'
    return hidden  matrix levels_over = `L'
    return hidden  matrix stats       = `stats'
    
end


program parse_mcompare
    
    syntax                     ///
    [ ,                        ///
        MCOMPare(string asis)  ///
        PROCedure(string asis) ///
        noADJust               ///
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
        local mcompare "c gh t2" // default
    
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
        
        if ( !inlist(strlower(`"`m'"'),"c","gh","t2") ) {
            
            local 0 , `m'
            capture syntax , NOADJust
            if ( _rc ) {
                
                if (`"`procedure'"' == "") {
                    
                    display as err "option mcompare() invalid"
                    local method method
                    
                }
                
                display as err "unknown `method' `m'"
                exit 198
                
            }
            
            local m noadjust
            
        }
        
        local mcmethod_vs `mcmethod_vs' `= strlower("`m'")'
        
    }
    
    c_local mcompare : list uniq mcmethod_vs
    
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


program return_effects
    
    syntax        ///
    [ ,           ///
        PVEFFECTS ///
        PVALUES   ///
        CIEFFECTS ///
        EFFECTS   ///
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


program return_table_layout
    
    syntax        ///
    [ ,           ///
        HC3       ///
        noADJust  ///
        VARLabels ///
        VALLabels ///
    ]
    
    if ("`adjust'" == "noadjust") ///
        local method noadjust
    else ///
        local method `r(mcmethod_vs)'
    
    local nmethods : word count `method'
    
    return_labels , `varlabels' `vallabels'
    
    local diff_title _col(`=`r(T_col_1_width)'+8') "Diff."
    local diff_fmt   _col(`=`r(T_col_1_width)'+3') `r(cfmt)'
    
    local se_title _col(`=`r(T_col_1_width)'+15') "Std. Err." 
    local se_fmt   _col(`=`r(T_col_1_width)'+14') `r(cfmt)'
    
    if ("`hc3'" == "hc3") ///
        local se_title2 _col(`=`r(T_col_1_width)'+14') "Robust HC3"
    else ///
        local se_title2 _col(`=`r(T_col_1_width)'+16') "Robust"
    
    if ("`r(pveffects)'" == "pveffects") {
        
        local t_title _col(`=`r(T_col_1_width)'+30') "t"
        local t_fmt   _col(`=`r(T_col_1_width)'+24') `r(sfmt)'
        
        local p_title _col(`=`r(T_col_1_width)'+35') "P>|t|"
        local p_fmt   _col(`=`r(T_col_1_width)'+35') `r(pfmt)'
        
        if (`nmethods' == 1) {
            
            if ("`method'" == "noadjust") ///
                local p_title2 _col(`=`r(T_col_1_width)'+30') "Unadjusted"
            else if ("`method'" == "c") ///
                local p_title2 _col(`=`r(T_col_1_width)'+29') "Dunnett's C"
            else if ("`method'" == "gh") ///
                local p_title2 _col(`=`r(T_col_1_width)'+26') "Games / Howell"
            else if ("`method'" == "t2") ///
                local p_title2 _col(`=`r(T_col_1_width)'+28') "Tamhane's T2"
            
        }
        
        local col_last = `r(T_col_1_width)' + 35 + fmtwidth("`r(pfmt)'")
        
    }
    
    if ("`r(cieffects)'" == "cieffects") {
        
        if ("`r(pveffects)'" == "pveffects") {
            
            if (`nmethods' == 1) {
                
                if ("`method'" == "noadjust") ///
                    local p_title2 // void
                else ///    
                    local p_title2 _col(`=`r(T_col_1_width)'+32') "Adjusted"
                
            }
            else local p_title2 // void
            
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
        
        local ci_title  _col(`col_ci_title') "[`r(level)'% Conf. Interval]"
        
        if (`nmethods' == 1) {
            
            if ("`method'" == "noadjust") ///
                local ci_title2 _col(`=`col_ci_title'+6') "Unadjusted"
            else if ("`method'" == "c") ///
                local ci_title2 _col(`=`col_ci_title'+5') "Dunnett's C"
            else if ("`method'" == "gh") ///
                local ci_title2 _col(`=`col_ci_title'+2') "Games and Howell"
            else if ("`method'" == "t2") ///
                local ci_title2 _col(`=`col_ci_title'+4') "Tamhane's T2"
            
        }
        
    }
    
    mata : st_global("r(T_diff_title)", st_local("diff_title"),   "hidden")
    mata : st_global("r(T_se_title)",   st_local("se_title"),     "hidden")
    mata : st_global("r(T_t_title)",    st_local("t_title"),      "hidden")
    mata : st_global("r(T_p_title)",    st_local("p_title"),      "hidden")
    mata : st_global("r(T_ci_title)",   st_local("ci_title"),     "hidden")
    
    mata : st_global("r(T_se_title2)",  st_local("se_title2"),    "hidden")
    mata : st_global("r(T_p_title2)",   st_local("p_title2"),     "hidden")
    mata : st_global("r(T_ci_title2)",  st_local("ci_title2"),    "hidden")
    
    mata : st_global("r(T_diff_fmt)",   st_local("diff_fmt"),     "hidden")
    mata : st_global("r(T_se_fmt)",     st_local("se_fmt"),       "hidden")
    mata : st_global("r(T_t_fmt)",      st_local("t_fmt"),        "hidden")
    mata : st_global("r(T_p_fmt)",      st_local("p_fmt"),        "hidden")
    mata : st_global("r(T_ci_ll_fmt)",  st_local("ci_ll_fmt"),    "hidden")
    mata : st_global("r(T_ci_ul_fmt)",  st_local("ci_ul_fmt"),    "hidden")
    
    mata : st_global("r(T_col_last)",   st_local("col_last"),     "hidden")
    
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


program line
    
    syntax anything(name = separator) [ , noADJust ]
    args separator
    
    local w_1 = `r(T_col_1_width)' - 1
    local w_2 = `r(T_col_last)' - `r(T_col_1_width)' - 1
    
    if ("`adjust'" != "noadjust") ///
        if (`: word count `r(mcmethod_vs)'' > 1) ///
            local w_2 = `w_2' + 6
    
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
        void st_r_mat()
        
    protected :
        
        void vs_names()
        
        real   scalar    k
        real   scalar    kstar
        real   rowvector xbar
        real   rowvector sd
        real   rowvector n
        
        real   rowvector b_vs
        real   rowvector se_vs
        real   rowvector df_vs
        real   rowvector se_hc3_vs
        real   rowvector df_welch_vs
        
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
    real rowvector nm1, np1, sd2n, sd2nm1
    real scalar    i, j
    real rowvector jj
    
    
    nm1    = n:-1
    np1    = n:+1
    sd2n   = (sd:^2):/n   // equivalent to vce(hc2)
    sd2nm1 = (sd:^2):/nm1 // equivalent to vce(hc3)
    
    b_vs        = J(1,kstar,.z)
    se_vs       = J(1,kstar,.z)
    df_vs       = J(1,kstar,.z)
    se_hc3_vs   = J(1,kstar,.z)
    df_welch_vs = J(1,kstar,.z)
    
    for (i=j=1; i<k; i++) {
        
        jj = (j..(k-i)+(j-1))
        
        b_vs[jj] = xbar[|i+1\ k|] :- xbar[i]
        
        se_vs[jj] = sqrt(sd2n[|i+1\ k|] :+ sd2n[i])
        
        df_vs[jj] =
            (se_vs[jj]:^4) :/
            ( 
                (sd[|i+1\ k|]:^4 :/ (n[|i+1\ k|]:^2:*nm1[|i+1\ k|])) 
                :+ (sd[i]:^4:/(n[i]:^2*nm1[i]))
            )
        
        se_hc3_vs[jj] = sqrt(sd2nm1[|i+1\ k|] :+ sd2nm1[i])
        
        df_welch_vs[jj] =
            (se_vs[jj]:^4) :/
            ( 
                (sd[|i+1\ k|]:^4 :/ (n[|i+1\ k|]:^2:*np1[|i+1\ k|])) 
                :+ (sd[i]:^4:/(n[i]:^2*np1[i]))
            ) :- 2
        
        j = j + (k-i)
        
    }
}


void pwmc_ado::set_st_r()
{
    vs_names()
    
    st_global("r(cmd2)", st_global("r(cmd)"))
    st_global("r(cmd)", "pwmc")
    
    st_r_mat("b_vs",        b_vs,        "", vs_names, "hidden")
    st_r_mat("se_vs",       se_vs,       "", vs_names, "hidden")
    st_r_mat("df_vs",       df_vs,       "", vs_names, "hidden")
    st_r_mat("se_hc3_vs",   se_hc3_vs,   "", vs_names, "hidden")
    st_r_mat("df_welch_vs", df_welch_vs, "", vs_names, "hidden")
}


void pwmc_ado::vs_names()
{
    string colvector vs_level
    real   scalar    i, j
    real   rowvector jj
    
    
    vs_names = J(kstar,1,"")
    vs_level = strofreal((1::k))
    
    for (i=j=1; i<k; i++) {
        
        jj = (j::(k-i)+(j-1))
        vs_names[jj] = vs_level[i+1::k]:+"vs":+vs_level[i]:+vs_names[jj]
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
        
        void ci_level()
        void table_vs()
        void mcompare()
        void set_st_r()
        
    private :
        
        real   matrix dunnett_c()
        
        real   scalar alpha
        
        real   matrix table_vs
        real   matrix table_mc   // by methods
        real   matrix table_mc_d // by differences
        
        real   matrix pvalue_adj
        real   matrix crit_adj
        real   matrix ll_adj
        real   matrix ul_adj
        
        string matrix mc_names
}


void pwmc_tables::ci_level(real scalar level) alpha = level/100


void pwmc_tables::table_vs(

    real scalar hc3,
    real scalar welch
    
    )
{
    table_vs = J(9,kstar,0)
    
    table_vs[1,] = st_matrix("r(b_vs)")
    table_vs[2,] = st_matrix((hc3   ? "r(se_hc3_vs)"   : "r(se_vs)"))
    table_vs[7,] = st_matrix((welch ? "r(df_welch_vs)" : "r(df_vs)"))
    
    table_vs[3,] = table_vs[1,]:/table_vs[2,]
    table_vs[4,] = 2*ttail(table_vs[7,],abs(table_vs[3,]))
    table_vs[8,] = invttail(table_vs[7,],(1-alpha)/2)
    table_vs[5,] = table_vs[1,]:-table_vs[8,]:*table_vs[2,]
    table_vs[6,] = table_vs[1,]:+table_vs[8,]:*table_vs[2,]
}


void pwmc_tables::mcompare(string rowvector mcompare)
{
    real rowvector df
    real colvector row
    
    
    if ( !cols(mcompare) ) 
        return
    
    pvalue_adj = crit_adj = J(cols(mcompare),kstar,.z)
    
    df = table_vs[7,]
    
    if ( any(row=select((1..cols(mcompare)), (mcompare:=="c"))) ) {
       crit_adj[row,] = dunnett_c(invtukeyprob(k,(n:-1),alpha) :* (sd:^2):/n)
    }
    
    if ( any(row=select((1..cols(mcompare)), (mcompare:=="gh"))) ) {
        pvalue_adj[row,] = 1:-tukeyprob(k,df,abs(table_vs[3,])*sqrt(2))
        pvalue_adj[row,] = colmin(J(1, kstar, 1)\ pvalue_adj[row,])
        crit_adj[row,] = invtukeyprob(k,df,alpha)/sqrt(2)
    }
    
    if ( any(row=select((1..cols(mcompare)), (mcompare:=="t2"))) ) {
        pvalue_adj[row,] = 1 :- (1:-table_vs[4,]):^kstar
        pvalue_adj[row,] = colmin(J(1, kstar, 1)\ pvalue_adj[row,])
        crit_adj[row,] = invttail(df,(1-alpha^(1/kstar))/2)
    }
    
    ll_adj = table_vs[1,]:-crit_adj:*table_vs[2,]
    ul_adj = table_vs[1,]:+crit_adj:*table_vs[2,]
    
    table_mc = J(cols(mcompare),1,table_vs[(1::3),]')
    table_mc = (table_mc,vec(pvalue_adj'),vec(ll_adj'),vec(ul_adj'))
    
    table_mc_d = colshape(J(1,cols(mcompare),table_vs[(1::3),]'),3)
    table_mc_d = (table_mc_d,vec(pvalue_adj),vec(ll_adj),vec(ul_adj))
}


real matrix pwmc_tables::dunnett_c(real rowvector SR)
{
    real rowvector V, C
    real rowvector jj
    real scalar    i, j
    
    
    V = table_vs[2,]:^2  
    C = J(1, kstar, .z)
    
    for (i=j=1; i<k; i++) {
        
        jj = (j..(k-i)+(j-1))
        C[jj] = ((SR[|i+1\ k|]:+SR[i]):/V[jj])/sqrt(2)
        j  = j + (k-i)
        
    }
    
    return(C)
}


void pwmc_tables::set_st_r(string rowvector mcompare)
{
    real scalar i
    
    
    vs_names()
    mc_names = (J(cols(mcompare),1,""), mcompare')
    
    st_numscalar("r(level)", alpha*100)
    
    st_global("r(mcmethod_vs)", invtokens(mc_names[,2]'))
    
    st_r_mat("table_vs", table_vs, 
        (J(9,1,""), ("b"\"se"\"t"\"pvalue"\"ll"\"ul"\"df"\"crit"\"eform")), 
        vs_names
    )
    
    st_r_mat("table_mc", table_mc, 
        (
         colshape(J(1,kstar,mc_names[,2]),1), 
         J(cols(mcompare),1,vs_names[,2])
        ),
        (J(6,1,""),("b"\"se"\"t"\"pvalue_adj"\"ll_adj"\"ul_adj")),
        "hidden"
    )
    
    st_r_mat("table_mc_d", table_mc_d, 
        (
         colshape(J(1,cols(mcompare),vs_names[,2]),1), 
         J(kstar,1,mc_names[,2])
        ),
        (J(6,1,""),("b"\"se"\"t"\"pvalue_adj"\"ll_adj"\"ul_adj")),
        "hidden"
    )
    
    st_global("r(procedure)", st_global("r(mcmethod_vs)"), "hidden")
    
    st_r_mat("t",     table_vs[3,],    "", vs_names, "hidden")
    st_r_mat("nuhat", table_vs[7,],    "", vs_names, "hidden")
    st_r_mat("Var",   table_vs[2,]:^2, "", vs_names, "hidden")
    st_r_mat("diff",  table_vs[1,],    "", vs_names, "hidden")
    
    st_r_mat("A",     crit_adj',   vs_names, mc_names, "hidden")
    st_r_mat("p_adj", pvalue_adj', vs_names, mc_names, "hidden")
    
    st_r_mat("ci", (vec(ll_adj'), vec(ul_adj')), 
        (
         colshape(J(1,kstar,mc_names[,2]), 1), 
         J(cols(mcompare),1,vs_names[,2])
        ),
        ((""\""), ("ll"\"ul")),
        "hidden"
    )
    
    for (i=1; i<=rows(mc_names); i++) {
        
        st_r_mat("A_"+mc_names[i, 2],  crit_adj[i,], "", vs_names, "hidden")
        st_r_mat("ll_"+mc_names[i, 2], ll_adj[i,],   "", vs_names, "hidden")
        st_r_mat("ul_"+mc_names[i, 2], ul_adj[i,],   "", vs_names, "hidden")
        
    }
    
    if (st_global("r(over)") != "")
        st_global(
            "r(vs_names)",
            invtokens(substr(vs_names[,2],1,strpos(vs_names[,2],"."):-1)'),
            "hidden"
            )
    else
        st_global("r(vs_names)",invtokens(vs_names[,2]'),"hidden")
    
}


/*  _________________________________________________________________________
                                                          entry point ado  */

void pwmc_estimate()
{
    class pwmc_ado scalar P
    
    
    P.get_st_r()
    
    P.estimate()
    
    P.set_st_r()
}


void pwmc_mctables(
    
    real   scalar level,
    string scalar hc3,
    string scalar welch,
    string scalar mcompare
    
    )
{
    class pwmc_tables scalar T
    
    
    T.get_st_r()
    
    T.ci_level(level)
    
    T.table_vs((hc3=="hc3"),(welch=="welch"))
    
    T.mcompare(tokens(mcompare))
    
    T.set_st_r(tokens(mcompare))
}


end


exit


/*  _________________________________________________________________________
                                                              version history

2.0.0   17jul2024   complete rewrite
                    new options -noadjust-, -hc3-, and -welch-
                    fweights allowed (not documented)
                    no longer requires external Mata function 
                        (bug fix under Linux)
                    new output (again)
                    changed returned results; old results hidden
1.1.0   07jan2014   new external Mata function mPwmc.mo
                    calculate adjusted p-values
                    changed returned results (old results hidden)
                    new output (new code)
                    -replay()- results
                    new option -pvalues-
                    new options -pformat()-, -sformat()-, -notable-
                    option -mcompare- as synonym for -procedure-
1.0.0   28jan2013   first release on SSC
