*! mixi12_sim 1.0.0  21may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*  Simulate an I(1) or I(2) data-generating process following the Formula
*  I(1) / I(2) racing circuits of Doornik-Mosconi-Paruolo (2017).
*
*  Syntax:
*     mixi12_sim , [ N(integer 200) DGP(string) P(integer 6)
*                    Rho1(real 0.0) Omega(real 0.0)
*                    SEED(integer 12345) CLEAR ]
*
*  DGPs:
*     dgp(i1) :  pure I(1) DGP with rho0 controlling near-I(0) and rho1
*               controlling near-I(2) ; p/2 random-walks plus p/2 AR(1).
*     dgp(i2) :  three-block I(2) DGP : X1 cumulated random walk (I(2)),
*               X2 random walk (I(1) — near-I(2) if rho1=0.9), X3
*               polynomial-cointegrated levels reacting via (ω-1).
*     dgp(km) :  Kurita / monetary multiplier DGP: m2, mb share an I(2)
*               trend, p has its own I(2) trend, rd is I(1).  Useful for
*               testing the I(2)-to-I(1) transformation machinery.

program define mixi12_sim
    version 14
    syntax , [ N(integer 200) DGP(string) P(integer 6)         ///
        Rho1(real 0.0) Omega(real 0.0) SEED(integer 12345) CLEAR ]

    if "`dgp'" == "" local dgp "i2"
    if "`clear'" != "" {
        clear
    }
    else {
        qui describe, varlist
        if r(N) > 0 {
            di as err "data in memory; specify clear to overwrite"
            exit 4
        }
    }

    set seed `seed'
    qui set obs `n'
    qui gen t = _n
    qui tsset t

    if "`dgp'" == "i1" {
        forvalues i = 1/`p' {
            qui gen double e`i' = rnormal()
        }
        local half = `p'/2
        // first half: AR(2)-like near-I(2) if rho1=0.9
        forvalues i = 1/`half' {
            qui gen double x`i' = 0
            qui replace x`i' = `rho1'*L.x`i' + e`i' if t > 1
            qui replace x`i' = x`i' + L.x`i'        if t > 1
        }
        // second half: AR(1) near-stationary
        local k = `half' + 1
        forvalues i = `k'/`p' {
            qui gen double x`i' = 0
            qui replace x`i' = 0.8*L.x`i' + e`i' if t > 1
        }
    }
    else if "`dgp'" == "i2" {
        local half = `p'/3
        if `half' < 1 local half = 1
        forvalues i = 1/`p' {
            qui gen double e`i' = rnormal()
        }
        // X1 block: pure I(2) (cumulate twice)
        forvalues i = 1/`half' {
            qui gen double dX`i' = 0
            qui replace dX`i' = L.dX`i' + e`i' if t > 1
            qui gen double x`i' = 0
            qui replace x`i' = L.x`i' + dX`i' if t > 1
        }
        // X2 block: I(1) — near-I(2) if rho1=0.9
        local lo = `half' + 1
        local hi = 2*`half'
        forvalues i = `lo'/`hi' {
            qui gen double x`i' = 0
            qui replace x`i' = `rho1'*L.x`i' + e`i' if t > 1
            qui replace x`i' = x`i' + L.x`i'        if t > 1
        }
        // X3 block: polynomial-cointegrated with X2
        local lo = 2*`half' + 1
        forvalues i = `lo'/`p' {
            qui gen double x`i' = 0
            local j = `i' - 2*`half'
            qui replace x`i' = `omega'*L.x`i' + L.x`j' - x`j' + e`i' if t > 1
        }
    }
    else if "`dgp'" == "km" {
        // Kurita money-multiplier DGP
        qui gen double e1 = rnormal()         // shock to mb
        qui gen double e2 = rnormal()         // shock to multiplier
        qui gen double e3 = rnormal()         // shock to price
        qui gen double e4 = rnormal()*0.5     // shock to rd

        // monetary base mb is I(2)
        qui gen double d_mb = 0
        qui replace d_mb = L.d_mb + e1 if t > 1
        qui gen double mb = 0
        qui replace mb = L.mb + d_mb if t > 1
        // money multiplier mm = m2 - mb is I(1)
        qui gen double mm = 0
        qui replace mm = 0.9*L.mm + e2 if t > 1
        qui gen double m2 = mb + mm
        // price index p is I(2) (own trend)
        qui gen double d_p = 0
        qui replace d_p = L.d_p + e3 if t > 1
        qui gen double p_lev = 0
        qui replace p_lev = L.p_lev + d_p if t > 1
        // interest-rate diff rd is I(1)
        qui gen double rd = 0
        qui replace rd = 0.95*L.rd + e4 if t > 1

        drop e1 e2 e3 e4 d_mb mm d_p
        rename p_lev p
        label var m2 "Broad money (I(2))"
        label var mb "Monetary base (I(2))"
        label var p  "Price index (I(2))"
        label var rd "Interest-rate differential (I(1))"
    }
    else {
        di as err "mixi12_sim: unknown DGP '`dgp''.  Use i1, i2 or km."
        exit 198
    }

    cap drop e?
    di as text "Generated DGP " as result "'`dgp''" as text " with N = `n', " ///
        "seed = `seed', rho1 = `rho1', omega = `omega'"
end
