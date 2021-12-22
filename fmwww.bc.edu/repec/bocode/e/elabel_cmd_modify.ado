*! version 1.0.0 15oct2020 daniel klein
program elabel_cmd_modify
    version 11.2
    
    elabel parse elblnamelist [ mappings ] ///
    [ ,                                    ///
        DEfine(string asis)                ///
        PREfix(name)                       ///
        REPLACE                            ///
        noFIX                              ///
        *                         /// Dryrun *
    ] : `0'
    
    if ( mi("`replace'") ) local replace modify
    
    if ( mi(`"`define'`prefix'"') ) {
        elabel define `lblnamelist' `mappings' , `replace' `fix' `options'
        exit
    }
    
    if ( (`"`define'"' != "") & ("`prefix'" != "") ) {
        display as err "option prefix() may not be combined with define()"
        exit 198
    }
    
    local lblnamelist : list uniq lblnamelist
    
    if ("`define'" != "") {
        capture noisily elabel parse newlblnamelist(varvaluelabel) : `define'
        if ( _rc ) {
            display as err "option define() invalid"
            exit _rc
        }
        local nold : word count `lblnamelist'
    }
    else {
        local newlblnamelist : subinstr local lblnamelist " " " `prefix'" , all
        local newlblnamelist `prefix'`newlblnamelist'
    }
    
    elabel confirm `nold' new lblnames `newlblnamelist'
    
    preserve
    
    local i 0
    foreach lbl of local lblnamelist {
        _label copy `lbl' `: word `++i' of `newlblnamelist''
    }
    
    capture confirm existence `mappings'
    if ( !_rc ) {
        elabel parse [ , Dryrun * ] : , `options'
        elabel define `newlblnamelist' `mappings' , `fix' `replace' `options'
    }
    else elabel parse [ , OPTIONS ] : , `options' options
    
    elabel varvaluelabel `varvaluelabel' , `fix'
    
    if ("`dryrun'" == "dryrun") {
        elabel protectr
        _label list `newlblnamelist'
    }
    else local not , not
    
    restore `not'
end
exit
