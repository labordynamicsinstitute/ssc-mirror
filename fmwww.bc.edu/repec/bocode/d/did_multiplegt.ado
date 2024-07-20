cap program drop did_multiplegt
program define did_multiplegt, eclass
version 12.0
syntax anything [if] [in] [, *]

    local cmd_list did_multiplegt_old did_multiplegt_dyn did_had did_multiplegt_stat

    qui {
        foreach p in  `cmd_list' {
            cap which `p'
            if _rc != 0 {
                noi di as text "Installing `p' ..."
                ssc install `p', replace
            }
        }

        if uniform() < 0.01 & strpos("`options'", "no_updates") == 0{
            foreach p in `cmd_list' {
                noi ssc install `p', replace
            }
        }

        local cmd_old "did_multiplegt_old"
        local cmd_dyn "did_multiplegt_dyn"
        local cmd_had "did_had"
        local cmd_stat "did_multiplegt_stat"

        local fp = strpos("`anything'", "(")
        local lp = strpos("`anything'", ")")
        local mod = substr("`anything'",`fp'+1,`lp'-`fp'-1)
        local vars = substr("`anything'", `lp'+1, .)
        local options = subinstr("`options'", "no_updates", "", .)
    }   

    if missing("`mod'") | !inlist("`mod'", "old", "dyn", "had", "stat") {
        di as err "Invalid syntax."
        di as input _continue "" _newline

        di as text "did_multiplegt is now a library and it follows a new syntax:"
        di as text "       {cmd:did_multiplegt (mode) varlist [, options]}"
        di as text ""
        di as text "Depending on the mode argument, did_multiplegt can be used to call"
        di as text "     - {stata help did_multiplegt_dyn:did_multiplegt_dyn} with the {it:dyn} mode;"
        di as text "     - {stata help did_multiplegt_stat:did_multiplegt_stat} with the {it:stat} mode;"
        di as text "     - {stata help did_had:did_had} with the {it:had} mode;"
        di as text "     - {stata help did_multiplegt_old:did_multiplegt_old}, i.e. the older version of this command, with the {it:old} mode;"
        exit
    }
    else {
        `cmd_`mod'' `vars' `if' `in', `options'
    }
end