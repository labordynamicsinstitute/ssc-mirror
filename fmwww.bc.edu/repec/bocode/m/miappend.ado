*! version 2.1  Thursday, July 3, 2003 at 12:22    (SJ3-3: st0000)
* syntax to use:  miappen using <file name prefix> [,nolabels]

program def miappend
    version 7.0

    syntax using/ [, *]

    cap assert "$mimps"!=""&"$mi_sf"!=""
    if _rc {
        display as error "please set up your data with -{help miset}- first"
        exit 198
    }

    local i=1
    forvalues i=1/$mimps {
        qui use $mi_sf`i', clear
        cap noisily confirm file `using'`i'.dta
        if _rc { exit _rc }
    }
    if "`options'"~=""{ local cma "," }
    nobreak {
        local i 1
        forvalues i=1/$mimps {
            qui use $mi_sf`i', clear
            qui append using `using'`i' `cma' `options'
            qui save $mi_sf`i', replace
        }
    }

local this 1
qui use "$mi_sf`this'.dta", clear

end
exit
