*! qnardl_showall v1.0.0  28may2026
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! Display ALL qnardl graphs that are currently in memory.
*!
*! Convenient for reviewing every saved graph from one or more qnardl runs.
*! Each graph opens in its own tab (sets autotabgraphs on).

program define qnardl_showall
    version 14.0

    capture set autotabgraphs on

    local known qnardl_all qnardl_beta qnardl_ect qnardl_asym ///
                qnardl_mult qnardl_cusum_both _qncg_c _qncg_cs

    local found ""
    foreach g of local known {
        capture graph dir `g'
        if !_rc {
            capture noisily graph display `g'
            if !_rc local found "`found' `g'"
        }
    }

    if "`found'" == "" {
        di as txt "qnardl_showall: no qnardl graphs found in memory."
        di as txt "  Re-run qnardl with the {bf:graph} option, or call:"
        di as txt "    {bf:qnardl_graph}, {bf:qnardl_mgraph}, {bf:qnardl_cgraph}"
    }
    else {
        di as txt _n "qnardl_showall: displayed " as res `: word count `found'' ///
                  as txt " graph(s):" as res "`found'"
        di as txt "  (each opens in its own tab of the Graph window)"
    }
end
