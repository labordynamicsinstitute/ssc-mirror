cap program drop ecollapse
program define ecollapse, rclass
version 12.0
syntax anything, by(string) [sorted(string) delim(string)]

// lcollapse 
qui {
    local TEMP "`anything'"
    local VARS ""
    while strpos("`TEMP'", "(") > 0 {
        local TEMP = substr("`TEMP'", strpos("`TEMP'","(")+1, .)
        if strpos("`TEMP'", "(") > 0 local ADD = substr("`TEMP'", strpos("`TEMP'", ")") + 1, strpos("`TEMP'", "(") - strpos("`TEMP'", ")") - 1)    
        else local ADD = substr("`TEMP'", strpos("`TEMP'", ")") + 1, .)
        local VARS "`VARS' `ADD'"
    }
    foreach v of varlist `VARS' {
        local l_`v': var label `v'
    }

    ds
    local df_vars = r(varlist)
}

qui {

    if strpos("`anything'","(concat)") == 0 & ("`sorted'" != "" | "`delim'" != "") {
        di as err "sorted() option only allowed with (concat)"
        exit
    }

    if strpos("`anything'","(concat)") + strpos("`anything'","(bin") == 0 collapse `anything', by(`by')

    else {

    local parsestr "`anything'"
    local c = 1
    while strpos("`parsestr'", "(") > 0 {
        local s1 = strpos("`parsestr'", "(")
        local s2 = strpos("`parsestr'", ")")
        local f`c' = substr("`parsestr'", `s1' + 1, `s2' - `s1' - 1)

        local parsestr = substr("`parsestr'", `s2' + 1, .)

        if strpos("`parsestr'", "(") > 0 local v`c' = substr("`parsestr'", 1, strpos("`parsestr'", "(")-1)
        else local v`c' = strtrim("`parsestr'")
        local c = `c' + 1
    }
    local tc = `c' - 1

    local vconcat ""
    local vunion ""
    forv j = 1/`tc' {
        if "`f`j''" == "concat" local vconcat "`v`j''"
        if "`f`j''" == "union" local vunion "`v`j''"
    }

    if strpos("`anything'","(concat)") != 0 {

        if "`delim'" == "" {
            local delim = ","
        }

        egen by_gr = group(`by')
        bys by_gr: gen N_gr = _N
        sum N_gr 
        local max_it = r(max)
        drop N_gr

        sort by_gr `sorted'
        foreach v of varlist `vconcat' {
            gen `v'_c = `v'
            forv j=1/`=`max_it'-1' {
                replace `v'_c = `v'_c[_n] + "`delim'" + `v'[_n+`j'] if by_gr[_n] == by_gr[_n+`j'] & !missing(`v'[_n+`j']) & !missing(`v'[_n])
            }

            gen l_check = length(`v'_c)
            bys by_gr: egen ml_check = max(l_check)
            replace `v'_c = "" if l_check != ml_check
            drop l_check ml_check
        }

        drop by_gr
    }

    if strpos("`anything'", "(union)") {
        foreach v in `vunion' {
            levelsof `v', local(bn_`v')
            if r(r) > 25 {
                keep `df_vars'
                noi di as err "`v' has more than 25 levels."
                exit
            }
            to_binary `v', ids(`bn_`v'') gen(`v'_bit)
            sum `v'_bit
            local bm_`v' = ceil(log(r(max))/log(2))
            forv j = 0/`bm_`v'' {
                gen byte `v'bin`j' = mod(floor(`v'_bit/(2^`j')), 2)
            }
        }
    }

    local cmd ""
    forv j = 1/`tc' {
        if !inlist("`f`j''", "concat", "union") local cmd "`cmd' (`f`j'') `v`j''"
        else if "`f`j''" == "concat" {
            local cmd "`cmd' (firstnm)"
            foreach v in `v`j'' {
                local cmd "`cmd' `v'_c"
            }
        }
        else if "`f`j''" == "union" {
            local cmd "`cmd' (max)"
            foreach v in `v`j'' {
                local cmd "`cmd' `v'bin*"
            }
        }
    }
    
    collapse `cmd', by(`by')

    forv j = 1/`tc' {
        foreach v in `v`j'' {
            if "`f`j''" == "concat" {
                cap rename `v'_c `v'
            }
            if "`f`j''" == "union" {
                foreach v in `vunion' {
                    gen double `v'_BIN = 0
                    local k = strtrim("`v`j''")
                    forv j = 0/`bm_`k'' {
                        replace `v'_BIN = `v'_BIN + `v'bin`j' * 2^(`j')
                        drop `v'bin`j'
                    }
                    from_binary `v'_BIN, ids(`bn_`k'') gen(`v`j'') delim(`delim')
                    drop `v'_BIN
                }
            }
        }
    }
    }
}

// lcollapse
qui {
    foreach v of varlist `VARS' {
        label var `v' "`l_`v''"
    }
}
end

cap program drop to_binary
program define to_binary, rclass 
version 12.0
syntax varlist(max = 1 min = 1), ids(string) gen(string)
qui {
    gen long `gen' = 0
    local j = 0
    foreach word in `ids' {
        replace `gen' = `gen' + 2^`j' if strpos(`varlist', "`word'") > 0
        local j = `j' + 1
    }
}
end

cap program drop from_binary
program define from_binary, rclass
syntax varlist(max = 1 min = 1), ids(string) gen(string) delim(string)
version 12.0
qui {
    if "`delim'" == "" local delim ","
    gen `gen' = ""
    local j = 0
    foreach word in `ids' {
        replace `gen' = `gen' + "`delim'" + "`word'" if mod(floor(`varlist'/(2^`j')), 2) & !missing(`gen')
        replace `gen' = `gen' + "`word'" if mod(floor(`varlist'/(2^`j')), 2) & missing(`gen')
        local j = `j' + 1
    }
}
end