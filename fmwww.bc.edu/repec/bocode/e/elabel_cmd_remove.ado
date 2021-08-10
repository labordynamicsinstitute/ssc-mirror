*! version 1.2.0 15oct2020 daniel klein
program elabel_cmd_remove
    version 11.2
    
    elabel parse [ anything ] [ , NOT noMEMory noDROP ] : `0'
    elabel parse elblnamelist(`memory') : `anything'
    local lblnamelist : list uniq lblnamelist
    
    if ("`not'"=="not") {
        elabel protectr
        quietly elabel dir , `memory'
        local alllbl `r(names)' `r(undefined)'
        local lblnamelist : list alllbl - lblnamelist
    }
    
    if ( mi("`lblnamelist'") ) exit
    
    preserve
    
    elabel swap (`lblnamelist') (.)
    
    if ( mi("`drop'") ) {
        foreach lbl of local lblnamelist {
            capture elabel drop `lbl'
            if ( !inlist(_rc, 0, 111) ) error _rc
        }
    }
    
    restore , not
end
exit

/* ---------------------------------------
1.2.0 15oct2020 new option -nodrop-
                rewrite code in terms of -elabel swap-
1.1.1 02apr2019 fix bug with lblname _all
1.1.0 09feb2019 new options -not- and -nomemory-
1.0.0 02nov2018 first version
