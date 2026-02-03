*! version 2.2.1  Jonathan Dries  01Feb2026
* Helper to post bandwidth scalars to e()
program define rddid_post_bw, eclass
    syntax, ht(string) hc(string)

    * Parse Treated
    local n_ht : word count `ht'
    tokenize `ht'
    if `n_ht' == 1 {
        ereturn scalar h_t_l = `1'
        ereturn scalar h_t_r = `1'
    }
    else {
        ereturn scalar h_t_l = `1'
        ereturn scalar h_t_r = `2'
    }

    * Parse Control
    local n_hc : word count `hc'
    tokenize `hc'
    if `n_hc' == 1 {
        ereturn scalar h_c_l = `1'
        ereturn scalar h_c_r = `1'
    }
    else {
        ereturn scalar h_c_l = `1'
        ereturn scalar h_c_r = `2'
    }
end
