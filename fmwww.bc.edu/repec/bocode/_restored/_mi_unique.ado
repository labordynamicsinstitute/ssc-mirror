*! version 1.1  Thursday, July 3, 2003 at 12:21

program define _mi_unique, rclass
    version 7
    local res abc
    local keep

    tokenize `0'
    local 0
    while "`1'"!=""{
        local 0 `0' `1'
        mac shift
    }
    while "`res'"~="" {
        local res
        gettoken first rest: 0
        tokenize `rest'
        while "`1'"!="" {
            cap assert "`first'"=="`1'"
            if _rc {  local res `res' `1'  }
            mac shift
        }
        local keep `keep' `first'
        local 0 `res'
    }

    ret local unique `keep'
end
/*
    Get rid of repeated variable names.
*/
