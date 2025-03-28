*! version 1.0.0  24mar2025
program pwmc_version
    
    version 12.1
    
    
    local most_recent_version 3
    
    
    capture confirm existence `0'
    if ( _rc ) {
        
        display as txt "pwmc version " `most_recent_version'
        exit
        
    }
    
    gettoken version 0 : 0 , parse(":") quotes
    gettoken colon   0 : 0 , parse(":") quotes
    
    if (`"`colon'"' != ":") ///
        error 198
    
    capture noisily confirm integer number `version'
    if ( _rc ) ///
        error 198
    
    if ( !inrange(`version',1,`most_recent_version') ) {
        
        display as err "version must be between 1 and `most_recent_version'"
        exit 198
        
    }
    
    if (`version' < `most_recent_version') ///
        local _version _`version'
    
    gettoken obs1 : 0 , match(open_parenthesis)
    if ("`open_parenthesis'" == "(") ///
        gettoken obs1 : obs1
    
    capture confirm number `obs1'
    if ( !_rc ) ///
        local i "i"
    
    version `=_caller()' : pwmc`i'`_version' `0'
    
end


/*  _________________________________________________________________________
                                                                version 2  */

program pwmc_2
    
    version 12.1
    
    if ( !replay() ) {
        
        syntax varname(numeric) [ if ] [ in ] [ fweight ] [ , * ]
        
        local depvar `varlist'
        local ifin   `if' `in'
        local wgt    [`weight' `exp']
        local 0      , `options'
        
    }
    
    syntax                  ///
    [ ,                     ///
        Over(passthru)      ///
        MCOMPare(passthru)  ///
        PROCedure(passthru) ///
        hc3                 ///
        Welch               ///
        DF(passthru)        ///
        *                   ///
    ]
    
    if (`"`mcompare'`procedure'"' != "") {
        
        local verbatim `mcompare' `procedure'
        
        local bonferroni : list posof "bon" in verbatim
        local scheffe    : list posof "sch" in verbatim
        
        if ( `bonferroni' | `scheffe' ) {
            
            if ("`hc3'" == "") ///
                local hc3 se(hc2)
            
            if (`"`welch'`df'"'=="") ///
                local df df(satterthwaite)
            
        }
        
    }
    else    local mcompare mcompare(c gh t2)  // legacy defaut
    
    local options `over' `mcompare' `procedure' `hc3' `welch' `df' `options'
    
    version `=_caller()' : ///
        pwmc_version 3 : `depvar' `ifin' `wgt' , `options' legacydefault
    
    mata {
        
        st_global("r(mcmethod_vs)",st_global("r(procedure)"))
        st_matrix("r(stats)",st_matrix("r(stats)")) // wipe column stripes
        st_matrixrowstripe("r(stats)",(J(3,1,""),("mean"\"sd"\"n")))
        pwmc_2_rownames("r(table_mc)")
        pwmc_2_rownames("r(table_mc_d)")
        
    }
    
end


program pwmci_2
    
    version 12.1
    
    syntax anything [ , MCOMPare(passthru) PROCedure(passthru) * ]
    
    if (`"`mcompare'`procedure'"' == "") ///
        local mcompare mcompare(c gh t2)  // legacy default
    
    version `=_caller()' : ///
        pwmc_version 3 : `anything' , `mcompare' `procedure' `options'
    
    mata {
        
        st_global("r(mcmethod_vs)",st_global("r(procedure)"))
        pwmc_2_rownames("r(table_mc)")
        pwmc_2_rownames("r(table_mc_d)")
        
    }
    
end


/*  _________________________________________________________________________
                                                                version 1  */

program pwmc_1
    
    // version intentionally omitted 
    
    pwmc_version 2 : `0'
    
end


program pwmci_1
    
    // version intentionally omitted
    
    pwmc_version 2 : `0'
    
end


/*  _________________________________________________________________________
                                                                     Mata  */

version 12.1


mata :


mata set matastrict   on
mata set mataoptimize on


    /*  _____________________________________________________________________
                                                                version 2  */

void pwmc_2_rownames(string scalar r_matrix_name)
{
    string matrix rownames
    
    
    if (st_numscalar("r(ks)") < 3)
        return
    
    rownames = st_matrixrowstripe(r_matrix_name)
    rownames = subinstr(rownames,"cochran","c")
    rownames = subinstr(rownames,"tamhane","t2")
    rownames = subinstr(rownames,"bonferroni","bon")
    rownames = subinstr(rownames,"scheffe","sch")
    st_matrixrowstripe(r_matrix_name,rownames)
}


end


exit


/*  _________________________________________________________________________
                                                              version history

1.0.0   24mar2025   initial release