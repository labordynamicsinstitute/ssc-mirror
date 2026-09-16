*! version 1.3.1  14sep2026  Ben Adarkwa Dwamena
*! bayesinits: Automated chain-specific initialization for bayesmh
program bayesinits, rclass
    version 15

    // syntax: no varlist; all options declared explicitly
    syntax , NCHAINS(integer) ///
        [ UNCONstrained(string asis) ///
          POSitive(string asis) ///
          CORR(string asis) ///
          FISHERZ(string asis) ///
          PHI(string asis) ///
          SIMPLEX(string asis) ///
          CENTER(string asis) ///
          SCALE(string asis) ///
          SEED(integer 12345) ///
          RNGStream(integer 0) ///
          FMT(string) ///
          COMPACT ]

    if `nchains' < 1 {
        di as err "nchains() must be a positive integer"
        exit 198
    }

    if "`fmt'" == "" local fmt "%9.5f"

    local L_u   "`unconstrained'"
    local L_p   "`positive'"
    local L_r   "`corr'"
    local L_z   "`fisherz'"
    local L_phi "`phi'"
    local L_s   "`simplex'"

    local center_map "`center'"
    local scale_map  "`scale'"

    quietly set seed `seed'
    local space " "
    if "`compact'" != "" local space ""

    local all ""
    local allwrap ""
    local NL = char(10)

    // ------------------------ LOOP OVER CHAINS ------------------------
    forvalues k = 1/`nchains' {
        local spec ""

        if `rngstream' > 0 {
            if "`c(rng_current)'" != "mt64s" quietly set rng mt64s
            quietly set rngstream `= `rngstream' + `k' - 1'
        }

        // --- Unconstrained ---
        foreach nm of local L_u {
            quietly _getcs `nm' u "`center_map'" "`scale_map'"
            local v = r(c) + r(s)*rnormal()
            local spec "`spec'`space'{`nm'} `=strofreal(`v',"`fmt'")'"
        }

        // --- Positive (log) ---
        foreach nm of local L_p {
            quietly _getcs `nm' p "`center_map'" "`scale_map'"
            local lv = ln(r(c)) + r(s)*rnormal()
            local v = exp(`lv')
            if `v' <= 1e-10 local v = 1e-6
            if `v' >= 1e+10 local v = 1e+6
            local spec "`spec'`space'{`nm'} `=strofreal(`v',"`fmt'")'"
        }

        // --- Correlation (Fisher-z) ---
        foreach nm of local L_r {
            quietly _getcs `nm' r "`center_map'" "`scale_map'"
            local z   = atanh(r(c)) + r(s)*rnormal()
            local rho = tanh(`z')
            if abs(`rho') >= 0.995 local rho = 0.995*sign(`rho')
            local spec "`spec'`space'{`nm'} `=strofreal(`rho',"`fmt'")'"
        }

        // --- Fisher-z ---
        foreach nm of local L_z {
            quietly _getcs `nm' z "`center_map'" "`scale_map'"
            local v = r(c) + r(s)*rnormal()
            local spec "`spec'`space'{`nm'} `=strofreal(`v',"`fmt'")'"
        }

        // --- Angular phi ---
        foreach nm of local L_phi {
            quietly _getcs `nm' phi "`center_map'" "`scale_map'"
            local ph = r(c) + r(s)*rnormal()
            if `ph' < 0.001 local ph = 0.001
            if `ph' > c(pi)-0.001 local ph = c(pi)-0.001
            local spec "`spec'`space'{`nm'} `=strofreal(`ph',"`fmt'")'"
        }

        // --- Simplex ---
        if "`L_s'" != "" {
            local G : word count `L_s'
            if `G' == 1 {
                local nm : word 1 of `L_s'
                local spec "`spec'`space'{`nm'} 1"
            }
            else {
                local first : word 1 of `L_s'
                quietly _getcs `first' s "`center_map'" "`scale_map'"
                local ssd = r(s)

                tempname SUM
                scalar `SUM' = 0

                forvalues j = 1/`G' {
                    tempname w`j'
                    scalar `w`j'' = exp(`ssd'*rnormal())
                    scalar `SUM' = `SUM' + `w`j''
                }

                forvalues j = 1/`G' {
                    local pj = scalar(`w`j'')/scalar(`SUM')
                    local nm : word `j' of `L_s'
                    local spec "`spec'`space'{`nm'} `=strofreal(`pj',"`fmt'")'"
                }
            }
        }

        return local init`k' "`spec'"

        // composite one-line
        local all "`all' init`k'(`spec')"

        // composite wrapped
        if `k' == 1 {
            local allwrap "init`k'(`spec') ///"
        }
        else if `k' < `nchains' {
            local allwrap "`allwrap'`NL'init`k'(`spec') ///"
        }
        else {
            local allwrap "`allwrap'`NL'init`k'(`spec')"
        }
    }

    return local init_all "`all'"
    return local init_all_wrap "`allwrap'"
end


program _getcs, rclass
    version 15
    // Syntax: _getcs name domain center_map scale_map
    args name domain center_map scale_map

    tempname c s
    scalar `c' = .
    scalar `s' = .

    // Default centers by domain
    if "`domain'" == "u"   scalar `c' = 0
    if "`domain'" == "p"   scalar `c' = 1
    if "`domain'" == "r"   scalar `c' = 0
    if "`domain'" == "z"   scalar `c' = 0
    if "`domain'" == "phi" scalar `c' = c(pi)/2
    if "`domain'" == "s"   scalar `c' = 0

    // Default scales by domain
    if "`domain'" == "u"   scalar `s' = 1
    if "`domain'" == "p"   scalar `s' = 0.5
    if "`domain'" == "r"   scalar `s' = 0.5
    if "`domain'" == "z"   scalar `s' = 0.5
    if "`domain'" == "phi" scalar `s' = 0.7
    if "`domain'" == "s"   scalar `s' = 0.3

    // ---- Center overrides: parse "name=expr" tokens ----
    if "`center_map'" != "" {
        local tmp `center_map'
        while "`tmp'" != "" {
            gettoken pair tmp : tmp
            if strpos("`pair'","=") {
                gettoken lhs rhs : pair, parse("=")

                // Strip leading "=" if present
                if substr("`rhs'",1,1) == "=" {
                    local rhs = substr("`rhs'",2,.)
                }

                // Remove spaces from rhs (e.g. "  1.23 " -> "1.23")
                local rhs = subinstr("`rhs'"," ","",.)

                if "`lhs'" == "`name'" {
                    capture scalar `c' = `rhs'
                    if _rc scalar `c' = real("`rhs'")
                }
            }
        }
    }

    // ---- Scale overrides: parse "name=#" tokens ----
    if "`scale_map'" != "" {
        local tmp2 `scale_map'
        while "`tmp2'" != "" {
            gettoken pair tmp2 : tmp2
            if strpos("`pair'","=") {
                gettoken lhs rhs : pair, parse("=")

                if substr("`rhs'",1,1) == "=" {
                    local rhs = substr("`rhs'",2,.)
                }

                local rhs = subinstr("`rhs'"," ","",.)

                if "`lhs'" == "`name'" {
                    capture scalar `s' = `rhs'
                    if _rc scalar `s' = real("`rhs'")
                }
            }
        }
    }

    return scalar c = scalar(`c')
    return scalar s = scalar(`s')
end
