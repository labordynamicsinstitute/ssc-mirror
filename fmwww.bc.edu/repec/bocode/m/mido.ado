*! version 2.2  Thursday, July 3, 2003 at 12:22        (SJ3-3: st0000)

program define mido
    version 7.0
    set more off

    cap assert "$mimps"~=""&"$mi_sf"~=""
    if _rc {
        display as error "please set up your data with -{help miset}- first"
        exit 198
    }

    gettoken cmd 0 : 0
    if "`cmd'"=="" {
        di "{help mido} should be used together with other command"
        exit 198
    }
    if "`cmd'"=="adjust" |"`cmd'"=="estimates" |"`cmd'"=="hausman" |"`cmd'"=="lincom" |/*
        */"`cmd'"=="linktest" |"`cmd'"=="lrtest" |"`cmd'"=="mfx" |"`cmd'"=="nlcom" | /*
        */"`cmd'"=="predict" |"`cmd'"=="predictnl" | "`cmd'"=="suest" | "`cmd'"=="test" |/*
        */"`cmd'"=="testparm" | "`cmd'"=="testnl" |"`cmd'"=="vce" |"`cmd'"=="lfit" |"`cmd'"=="lstat" | /*
        */"`cmd'"=="lroc" |"`cmd'"=="lsens" | "`cmd'"=="avplot" | "`cmd'"=="cprplot" |/*
        */ "`cmd'"=="lvr2plot" | "`cmd'"=="rvfplot" | "`cmd'"=="rvpplot" | "`cmd'"=="ovtest" |/*
        */ "`cmd'"=="hettest" | "`cmd'"=="szroeter" | "`cmd'"=="imtest" | "`cmd'"=="dfbeta" | /*
        */"`cmd'"=="vif" | "`cmd'"=="dwstat" | "`cmd'"=="durbina" | "`cmd'"=="bgodfrey" |/*
        */ "`cmd'"=="archlm" | "`cmd'"=="regress" {
        di as error "post-estimation commands not allowed in this context"
        exit 198
    }
    preserve

    forvalues i=1/$mimps {
        qui use $mi_sf`i', clear
        cap noisily qui `cmd' `0'
        if _rc {exit _rc}
    }
    restore

    nobreak {
        forvalues i=1/$mimps {
            qui use $mi_sf`i', clear
            di
            __mydis $mi_sf `i'
            local dis di in gr "-> Applying `cmd' to dataset`i' (`r(this)'.dta)."
            `dis'
            `cmd' `0'
            qui save $mi_sf`i', replace
        }
    }

    local this 1
    qui use $mi_sf`this'.dta, clear

end

program define __mydis, rclass
    args data i
    local short=abbrev("`data'`i'",12)
    return local this "`short'"
end

/*
    Execute (most) non-estimation, non-file-manipulation commands
    to miset datasets. See mimerge, miappen for file manipulation.

    Syntax to use:
           mido <Stata command>

*/
