*! version 1.7.0 20oct2021 daniel klein
program elabel_cmd_recode , rclass
    version 11.2
    
    if (_caller() >= 16) local f f
    elabel parse elblnamelist(varvaluelabel) mappings [ if`f' ] ///
    [ ,                                                         ///
        DEfine(string asis)                                     ///
        PREfix(name)                                            ///
        SEParator(passthru)                                     ///
        COPYrest                                                ///
        RECODEVARlist                                           ///
        VARlist                                                 ///
        Dryrun                                                  ///
    ] : `0'
    
    local lblnamelist : list uniq lblnamelist
    
    if ( mi(`"`define'`prefix'"') ) local define : copy local lblnamelist
    else if ( (`"`define'"' != "") & ("`prefix'" != "") ) {
        display as err "option prefix() may not be combined with define()"
        exit 198
    }
    else if ("`varvaluelabel'" != "") {
        display as err "{it:varname}{bf::}{it:elblname} not allowed"
        exit 101
    }
    else if (`"`define'"' != "") {
        capture noisily elabel parse newlblnamelist(varvaluelabel) : `define'
        if (_rc) {
            display as err "option define() invalid"
            exit _rc
        }
        local define : copy local newlblnamelist
        local old : word count `lblnamelist'
        local new : word count `define'
        if (`old' != `new') {
            local fewmany = cond((`old'>`new'), "few", "many")
            display as err "too `fewmany' new lblnames specified"
            exit 198
        }
    }
    else if ("`prefix'" != "") {
        foreach name of local lblnamelist {
            local define `define' `prefix'`name'
        }
        elabel confirm new lblname `define'
    }
    else assert 0 // NotReached
    
    assert_rules `mappings'
    
    preserve
    
    recode_value_labels (`lblnamelist') (`mappings') (`if`f'') ///
        , define(`define') `separator' `copyrest' `dryrun'
    
    elabel varvaluelabel `varvaluelabel'
    
    if ( ("`varlist'"=="varlist") | ("`recodevarlist'"=="recodevarlist") ) {
        elabel _u_usedby rvarlist : `define'
        if ("`recodevarlist'" == "recodevarlist") ///
            recode_varlist `rvarlist' `rules' , define(`define') `dryrun'
    }
    
    if ( mi("`dryrun'") ) local not not 
    restore , `not'
    
    return local varlist : copy local rvarlist
    return local rules : copy local rules
end

program recode_value_labels
    syntax anything , DEFINE(namelist) ///
    [ SEParator(passthru) COPYREST DRYRUN ]
    
    gettoken lblnamelist anything : anything , match(lpar)
    gettoken mappings    anything : anything , match(lpar)
    gettoken iff         anything : anything , match(lpar)
    
    if ("`copyrest'" == "copyrest") {
        if (`"`iff'"' != "") {
            gettoken iffword iffnot : iff
            local iffnot iff !(`iffnot')
        }
        else local copyrest // void
    }
    
    tempname notlbl tmplbl
    
    local c 0
    foreach lbl of local lblnamelist {
        local newlbl : word `++c' of `define'
        if ("`dryrun'" == "dryrun") {
            display // _newline
            label list `lbl'
        }
        if ("`copyrest'" == "copyrest") {
            elabel copy `lbl' `notlbl' `iffnot' , replace
            quietly elabel list `notlbl'
            local notvalues  `r(values)'
        }
        elabel copy   `lbl'    `newlbl'  `iff' , replace
        elabel copy   `newlbl' `tmplbl'        , replace
        elabel define `newlbl' `mappings'      , modify `separator' noreturn
        elabel define `tmplbl' `mappings'      , replace
        local rules `r(rules)'
        quietly elabel list `newlbl'
        local newvalues `r(values)'
        quietly elabel list `tmplbl'
        local tmpvalues `r(values)'
        local tmpvalues : list tmpvalues - newvalues
        foreach val of local tmpvalues {
            elabel copy `tmplbl' `newlbl' iff (# == `val') , modify
        }
        if ("`copyrest'" == "copyrest") {
            local notvalues : list notvalues - newvalues
            foreach val of local notvalues {
                elabel copy `notlbl' `newlbl' iff (# == `val') , modify
            }
        }
        if ("`dryrun'" == "dryrun") label list `newlbl'
    }
    
    c_local rules : copy local rules
end

program recode_varlist
    syntax anything , DEFINE(namelist) [ DRYRUN ]
    
    gettoken rvarlist : anything , parse("(")
    if ("`rvarlist'" == "(") exit 0
    
    local current_language : char _dta[_lang_c]
    local other_languages  : char _dta[_lang_list]
    local other_languages  : list other_languages - current_language
    
    if ("`other_languages'" != "") {
        foreach var of local rvarlist {
            local lbl : value label `var'
            local OK : list lbl in define
            if (`OK') {
                foreach lang of local other_languages {
                    local lbl : char `var'[_lang_l_`lang']
                    local OK : list lbl in define
                    if (!`OK') {
                        local current_language `lang'
                        break
                    }
                }
            }
            if (!`OK') {
                display as err "variable `var' has value label " ///
                "`lbl' attached in label language `current_language'"
                exit 498
            }
        }
    }
    
    if ("`dryrun'" == "dryrun") local quietly quietly
    
    `quietly' recode `anything'
end

program assert_rules
    gettoken rule : 0 , match(lpar)
    if ("`lpar'" == "(") {
        gettoken ignore equals : rule   , parse("=") quotes
        gettoken equals        : equals , parse("=") quotes
        if (`"`equals'"' != "=") local lpar // void 
    }
    if ("`lpar'" != "(") {
        display as err "invalid recoding rule `rule'"
        exit 198
    }
end
exit

/* ---------------------------------------
1.7.0 20oct2021 option -recodevarlist- now checks for inconsistencies
                option -recodevarlist- is now documented
                option -dryrun- no longer prevents option -recodevarlist-
                code polish: organized in sub-routines
                updated help file
1.6.1 15oct2020 bug fix: -varlist- no longer recodes variables
1.6.0 01sep2020 new option -recodevarlist-; not documented
                added reminder in help file
1.5.0 18jun2020 new option -separator()-
                call _u_usedby only for -varlist-
1.4.0 27may2020 new option -varlist; additional r(varlist)
1.3.1 23oct2019 workaround empty or long list of values
                change display for -dryrun- option
1.3.0 02aug2019 support varname:lblname
1.2.0 15jul2019 assert recoding rules specified
1.1.0 03jun2019 use -iff- in place of -if-
1.0.0 02nov2018 first version
