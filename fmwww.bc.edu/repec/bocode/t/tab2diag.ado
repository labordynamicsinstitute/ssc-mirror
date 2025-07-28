*! version 1.2.1  05may2025
program tab2diag , rclass
    
    version 11.2
    
    syntax varlist(numeric min=2 max=2) ///
    [ if ] [ in ] [ fweight ]           ///
    [ ,                                 ///
        COMPlement                      ///
        format(string)                  ///
        percent                         ///
        Level(cilevel)                  ///
        cii(name)                       ///
        csi(name)                       ///
        cci(name)                       ///
        ROCtab(name)                    ///
        noTRANSPOSE                     /// not documented
        noLEGEND                        /// not documented
    ]
    
    set_format `format' , local(fmt) `percent'
    
    unab_option cii WAld Wilson Agresti Jeffreys , ignore(Exact) `cii'
    unab_option csi tb , ignore(Woolf) `csi'
    unab_option cci COrnfield Woolf tb , `cci'
    unab_option roctab BINOmial BAMber HANley , `roctab'
    
    marksample touse
    
    tempvar  refvar   classvar
    gettoken varname1 varname2 : varlist
    
    binarize `varname1' if `touse' , generate(`refvar')   `legend'
    binarize `varname2' if `touse' , generate(`classvar') `legend'
    
    // NB `refvar' and `catvar' are missing if `touse'==0
    
    tempname Freq
    
    Tab2 `refvar' `classvar' [`weight'`exp'] , matcell(`Freq') `transpose' `legend'
    
    local a = `Freq'[1,1]
    local b = cond("`transpose'"=="notranspose",`Freq'[2,1],`Freq'[1,2])
    local c = cond("`transpose'"=="notranspose",`Freq'[1,2],`Freq'[2,1])
    local d = `Freq'[2,2]
    
    local r1 = `a'+`b'
    local r2 = `c'+`d'
    local c1 = `a'+`c'
    local c2 = `b'+`d'
    
    local ad = `a'+`d'
    
    local N = r(N)
    
    local stats ///
        sens    ///
        spec    ///
        ppv     ///
        npv     ///
        acc     ///
        prev    ///
        lrp     ///
        lrn     ///
        or      ///
        roc
    
    tempname `stats'
    
    Cii `c1'  `a' , matname(`sens') level(`level') `cii'
    Cii `c2'  `d' , matname(`spec') level(`level') `cii'
    Cii `r1'  `a' , matname(`ppv')  level(`level') `cii'
    Cii `r2'  `d' , matname(`npv')  level(`level') `cii'
    Cii  `N' `ad' , matname(`acc')  level(`level') `cii'
    Cii  `N' `c1' , matname(`prev') level(`level') `cii'
    
    Csi `a' `b' `c' `d' , matname(`lrp') level(`level') `csi'
    Csi `c' `d' `a' `b' , matname(`lrn') level(`level') `csi'
    
    Cci `a' `b' `c' `d' , matname(`or') `cci'
    
    Roctab `refvar' `classvar' [`weight'`exp'] , matname(`roc') level(`level') `roctab'
    
    if ("`complement'" == "complement") {
        
        local more_stats fnr fpr fdr for
        tempname `more_stats'
        
        complement_matrix `sens' `fnr'
        complement_matrix `spec' `fpr'
        complement_matrix `ppv'  `fdr'
        complement_matrix `npv'  `for'
        
        local stats `stats' `more_stats'
        
    }
    
    return scalar level = `level'
    
    return local cmd "tab2diag"
    
    return matrix ctable = `Freq'
    
    foreach stat of local stats {
    	return matrix `stat' = ``stat'' , copy
    }
    
    if (c(stata_version) >= 12) ///
    	local hidden hidden
    
    return `hidden' local cii_method `cii'
    return `hidden' local csi_method `csi'
    return `hidden' local cci_method `cci'
    return `hidden' local roc_method `roctab'
    
    if ( !c(noisily) ) ///
        exit
    
    if ("`percent'" == "percent") {
    	
        foreach stat in sens spec ppv npv `more_stats' acc prev {
        	matrix ``stat'' = ``stat''*100
        }
        
        local pct "%"
        
    }
    
    display
    display as txt _col(`=62-strlen("`level'")') "[`level'% conf. interval]"
    display as txt "{hline 79}"
    Print "Sensitivity"                        "Pr( +| D)" `fmt' `sens' "`pct'" `cii'
    Print "Specificity"                        "Pr( -|~D)" `fmt' `spec' "`pct'" `cii'
    Print "Positive predictive value"          "Pr( D| +)" `fmt' `ppv'  "`pct'" `cii'
    Print "Negative predictive value"          "Pr(~D| -)" `fmt' `npv'  "`pct'" `cii'
    
    if ("`complement'" == "complement") {
        
        display as txt "{hline 79}"
        
        Print "False negative rate"            "Pr( -| D)" `fmt' `fnr'  "`pct'" `cii'
        Print "False positive rate"            "Pr( +|~D)" `fmt' `fpr'  "`pct'" `cii'
        Print "False discovery rate"           "Pr(~D| +)" `fmt' `fdr'  "`pct'" `cii'
        Print "False omission rate"            "Pr( D| -)" `fmt' `for'  "`pct'" `cii'
        
    }
    
    display as txt "{hline 79}"
    Print "Accuracy"                         "Pr(correct)" `fmt' `acc'  "`pct'" `cii'
    Print "Prevalence"                             "Pr(D)" `fmt' `prev' "`pct'" `cii'
    display as txt "{hline 79}"
    Print "Likelihood ratio (LR+)"    "Pr(+|D) / Pr(+|~D)" `fmt' `lrp'       "" `csi'
    Print "Likelihood ratio (LR-)"    "Pr(-|D) / Pr(-|~D)" `fmt' `lrn'       "" `csi'
    Print "Odds ratio"                     "LR(+) / LR(-)" `fmt' `or'        "" `cci'
    display as txt "{hline 79}"
    Print "ROC area"                "[Pr(+|D)+Pr(-|~D)]/2" `fmt' `roc'       "" `roctab'
    display as txt "{hline 79}"
    
end


program set_format
    
    syntax [ anything(name=format id="format") ] , local(name local) [ percent ]
    
    if (`"`format'"' != "") {
        
        capture noisily confirm numeric format `format'
        if ( _rc ) {
            
            display as err "option {bf:format()} invalid"
            exit 198
        
        }
        
        if (fmtwidth("`format'") > cond("`percent'"=="percent",7,9)) {
            
            display as txt "note: invalid format; using default"
            local format // void
            
        }
        
    }
    
    if ("`format'" == "") {
        
        if ("`percent'" != "percent") {
            
            local format `c(cformat)'
            if ("`format'" == "") ///
                local format %9.0g
            
        }
        else    local format %6.2f
        
    }
    
    if ("`percent'" == "percent") ///
        local format : subinstr local format "-" ""
    
    c_local `local' `format'
    
end


program unab_option
    
    syntax anything [ , ignore(namelist) * ]
    
    gettoken option_name allowed_options : anything , bind
    
    local 0 , `options'
    capture noisily syntax [ , `allowed_options' `ignore' ]
    if ( _rc ) {
        
        display as err "invalid {it:`option_name'_method} in {bf:`option_name'()}"
        exit _rc
        
    }
    
    c_local `option_name' // void
    
    foreach option of local allowed_options {
        
        if (`"``=strlower("`option'")''"' != strlower("`option'")) ///
            continue
        
        c_local `option_name' = strlower("`option'")
        continue , break
        
    }
    
end


program binarize
    
    syntax varname(numeric) if , generate(name) [ noLEGEND ]
    
    marksample touse
    
    quietly generate byte `generate' = (`varlist'!=0) if `touse'
    
    char `generate'[varname] `varlist'
    
    local varlabel : variable label `varlist'
    label variable `generate' `"`macval(varlabel)'"'
    
    if (("`legend'"=="nolegend") | !c(noisily) ) ///
        exit
    
    local label_0 : label (`varlist') 0 , strict
    char `generate'[label_0] `"`macval(label_0)'"'
    
    summarize `varlist' if `generate' & `touse' , meanonly
    if (r(min) == r(max)) {
        
        char `generate'[not_0] `=r(min)'
        
        local label_not_0 : label (`varlist') `=r(min)' , strict
        char `generate'[label_not_0] `"`macval(label_not_0)'"'
        
    }
    
end


program Tab2
    
    syntax varlist [ fweight ] , matcell(name) [ noTRANSPOSE noLEGEND ]
    
    tempvar  refvar   classvar
    gettoken varname1 varname2 : varlist
    
    quietly generate `refvar':`refvar'     = (1 - `varname1')
    quietly generate `classvar':`classvar' = (1 - `varname2')
    
    label define `refvar'   0 "Pos. (D)" 1 "Neg. (~D)"
    label define `classvar' 0 "Pos. (+)" 1 "Neg. (-)"
    
    copy_varlabel `varname1' `refvar'   "True state"
    copy_varlabel `varname2' `classvar' "Classified"
    
    if ("`transpose'" == "notranspose") ///
        tabulate `refvar' `classvar' [`weight'`exp'] , matcell(`matcell')
    else ///
        tabulate `classvar' `refvar' [`weight'`exp'] , matcell(`matcell')
    
    if ( (r(r)!=2) | (r(c)!=2) ) {
        
        display as err "table not 2 by 2"
        exit 459
        
    }
    
    if ("`legend'" != "nolegend") {
        
        Tab2_legend `refvar'   `varname1'
        Tab2_legend `classvar' `varname2'
        
    }
    
    matrix rownames `matcell' = classified:pos classified:neg
    matrix colnames `matcell' = true_state:pos true_state:neg
    
end


program copy_varlabel
    
    args varname1 varname2 label
    
    local varlabel : variable label `varname1'
    if (`"`macval(varlabel)'"' == "") ///
        local varlabel "`label'"
    
    label variable `varname2' `"`macval(varlabel)'"'
    
end


program Tab2_legend
    
    args varname1 varname2
    
    local pos : label `varname1' 0
    local neg : label `varname1' 1
    
    local varname : char `varname2'[varname]
    
    local not_0 : char `varname2'[not_0]
    if ("`not_0'" == "") {
        
        local not_0 "!= 0"
        local label_pos : char `varname2'[label_0]
        local label_pos `"{txt:{it:not}} `macval(label_pos)'"'
        
    }
    else {
        
        local not_0 "== `not_0'"
        local label_pos : char `varname2'[label_not_0]
        
    }
    
    local label_neg : char `varname2'[label_0]
    
    display
    
    Tab2_legend_line "`pos'" "`varname'" "`not_0'" `"`macval(label_pos)'"'
    Tab2_legend_line "`neg'" "`varname'" "== 0"  `"`macval(label_neg)'"'
    
end


program Tab2_legend_line
    
    args posneg varname exp label
    
    if (c(stata_version)>=14) ///
        local u u
    
    local varname = `u'substr("`varname'",1,18)
    
    if (`"`macval(label)'"' != "") ///
        local label as txt "(" as res `"`macval(label)'"' as txt ")"
    
    display as txt %12s "`posneg':" _col(15) "`varname' `exp' " _col(`=15+18+4') `label'
    
end


program Cii
    
    syntax anything , matname(name) [ * ]
    
    quietly cii `anything' , `options'
    
    make_matrix `matname'
    
    matrix `matname'[1,1] = r(mean)
    matrix `matname'[1,2] = r(se)
    matrix `matname'[1,3] = r(lb)
    matrix `matname'[1,4] = r(ub)
    
end


program Csi
    
    syntax anything , matname(name) [ * ]
    
    quietly csi `anything' , `options'
    
    make_matrix `matname'
    
    matrix `matname'[1,1] = r(rr)
    matrix `matname'[1,3] = r(lb_rr)
    matrix `matname'[1,4] = r(ub_rr)
    
end


program Cci
    
    syntax anything , matname(name) [ * ] 
    
    quietly cci `anything' , `options'
    
    make_matrix `matname'
    
    matrix `matname'[1,1] = r(or)
    matrix `matname'[1,3] = r(lb_or)
    matrix `matname'[1,4] = r(ub_or)
    
end


program Roctab
    
    syntax varlist [ fweight ] , matname(name) [ * ]
    
    quietly roctab `varlist' [`weight'`exp'] , `options'
    
    make_matrix `matname'
    
    matrix `matname'[1,1] = r(area)
    matrix `matname'[1,2] = r(se)
    matrix `matname'[1,3] = r(lb)
    matrix `matname'[1,4] = r(ub)
    
end


program make_matrix
    
    args matname
    
    matrix `matname' = J(1,4,.)
    
    matrix colnames `matname' = b se ll ul
    
end


program complement_matrix
    
    args matname1 matname2
    
    matrix `matname2' =     ///
        1-`matname1'[1,1],  ///
          `matname1'[1,2],  ///
        1-`matname1'[1,4],  ///
        1-`matname1'[1,3]
    
end


program Print
    
    args name description fmt result pct option
    
    local fmtwidth = 10 - fmtwidth("`fmt'") - ("`pct'"=="%")
    
    display as txt "`name'" _col(26) %20s "`description'" _continue
    
    display as res _col(`=48+`fmtwidth'') `fmt' `result'[1,1] "`pct'" _continue
    display as res _col(`=59+`fmtwidth'') `fmt' `result'[1,3] "`pct'" _continue
    display as res _col(`=70+`fmtwidth'') `fmt' `result'[1,4] "`pct'" _continue
    
    if ("`option'" != "") {
        
        if ( !inlist("`option'","tb","binomial") ) ///
            local option = strproper("`option'")
        
        local option "(`option')"
        
    }
    
    display as txt " `option'"
    
end


exit


/*  _________________________________________________________________________
                                                              Version history

1.2.1   05may2025   subroutine -binarize- uses -summarize- not -tabulate-
                    subroutine -binarize- with option -nolegend- exits early
                    shift position of subroutine -copy_varlabel- in code
1.2.0   03may2025   bug fix: failed to unabbreviate suboption roctab()
                    ignore cii(exact) and csi(woolf)
                        affects not documented r(cii_method) and r(csi_method)
1.1.1   02may2025   improve error message for invalid -c?i()- methods
1.1.0   30apr2025   improve legend formatting for clarity
1.0.0   30apr2025
