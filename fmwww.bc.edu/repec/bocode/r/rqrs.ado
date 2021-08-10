*! version 1.2.0 11jan2021 daniel klein
program rqrs
    version 11.2
    
    syntax anything(name = namelist) ///
    [ ,                              ///
        FRom(string asis)            ///
        ALL                          ///
        REPLACE                      ///
        FORCE                        ///        
        INStall                      ///
        SKIP                         /// not documented
    ]
    
    if ( mi(`"`from'"') ) local ssc_net ssc
    else {
        gettoken ssc_net void : from , quotes
        if ( !inlist(`"`ssc_net'"', "ssc", "net") ) {
            if ( regexm(`"`ssc_net'"', "^sj[0-9]+\-[0-9]+$") ) ///
                local from "http://www.stata-journal.com/software/`ssc_net'"
            else if ( regexm(`"`ssc_net'"', "^stb[0-9]+$") )   ///
                local from "http://www.stata.com/stb/`ssc_net'"
            local ssc_net net
            local from    from(`from')
        }
        else if ( mi(strtrim(`"`void'"')) ) local from // void 
        else {
            display as err "option from() incorrectly specified"
            exit 198
        }
    }
    
    gettoken command namelist : namelist
    gettoken pkgname namelist : namelist
    if (`"`namelist'"' != "")  error 198
    
    capture confirm name `command'
    if ( _rc ) {
        if ( !regexm(`"`command'"', "^[^ 0-9][^ \.]*\.[A-Za-z]+$") ) ///
            confirm name `command' // NotReached
    }
    else if ( mi("`pkgname'") ) local pkgname : copy local command
    confirm name `pkgname'
    
    capture noisily which `command'
    if ("`force'" == "force") local replace replace
    else if ( !_rc ) exit
    
    if ( mi("`install'") ) {
        capture window stopbox rusure "Do you want to install `pkgname'?"
        if ( _rc ) exit 111*( mi("`skip'") )
    }
    
    `ssc_net' install `pkgname' , `all' `replace' `from'
end
exit

/* --------------------------------------
1.2.0 11jan2021 allow <command>.<ext>
                -force- still calls -which-
                new return codes for errors
1.1.0 22jul2020 new option -force-
1.0.0 17oct2019 initial release on SSC
