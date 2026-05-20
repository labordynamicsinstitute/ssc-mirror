*! multicoint_sim v1.0.0  18may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Simulate multicointegrated time-series (Granger-Lee stock-flow DGP)
*! ----------------------------------------------------------------------------
*! Generates {y_t, x_t} I(1) flow variables whose cumulated series {Y_t,X_t}
*! are I(2) and multicointegrated in the sense of Granger-Lee (1989, 1990).
*!
*! DGP (default, two-variable case):
*!     u_x,t  iid N(0,1)
*!     u_e,t  iid N(0,1)
*!     x_t   = x_{t-1} + u_x,t            (flow x is I(1))
*!     z_t   = b * x_t + e_t              with e_t iid N(0, sig_e^2)  (level-1 coint err, I(0))
*!     Y_t   = a + b * X_t + g * x_t + e0_t
*!             with X_t = sum(x), Y_t = sum(y);  e0_t I(0) under multicoint, I(1) otherwise.
*!     y_t   = Y_t - Y_{t-1}              (extract flow back from cumulated series)
*!
*! ----------------------------------------------------------------------------

program define multicoint_sim, rclass
    version 14.0
    syntax , [                              ///
        N(integer 200)                      ///
        Beta(real 1.0)                      ///
        Gamma(real 1.0)                     ///
        Alpha(real 0)                       ///
        TREND(real 0)                       ///
        SIGe(real 1.0)                      ///
        SIGx(real 1.0)                      ///
        SIGcoint(real 1.0)                  ///
        REGime(string)                      ///  multicoint (default) | coint | none
        SEED(integer 12345)                 ///
        CLEAR                               ///
        REPLACE                             ///
        ]

    if "`regime'" == "" local regime "multicoint"
    if !inlist("`regime'","multicoint","coint","none") {
        di as err "regime() must be one of: multicoint, coint, none"
        exit 198
    }
    if `n' < 30 {
        di as err "N must be at least 30"
        exit 198
    }
    if "`clear'" != "" {
        clear
    }
    else {
        qui count
        if r(N) > 0 & "`replace'" == "" {
            di as err "data in memory; use option {bf:clear} or {bf:replace}"
            exit 4
        }
        if "`replace'" != "" clear
    }

    set obs `n'
    qui gen double t = _n
    qui tsset t
    set seed `seed'

    * Innovations
    qui gen double _ux  = rnormal(0, `sigx')
    qui gen double _ue  = rnormal(0, `sigcoint')   // level-1 cointegration error innovation
    qui gen double _ue0 = rnormal(0, `sige')       // multicoint error innovation

    * Flow x_t (I(1))
    qui gen double x = .
    qui replace  x = _ux in 1
    qui replace  x = L.x + _ux if _n > 1

    * Cumulated I(2) series
    qui gen double X = sum(x)

    * Construct y_t depending on regime
    *----------------------------------------------------------------------
    * For multicoint: we want Y_t = a + b X_t + g x_t + e0_t with e0 I(0)
    *   so that y_t = Delta Y_t = b * x_t + g * Delta x_t + Delta e0_t
    *
    * For coint only (no multicoint): Y_t has I(1) residual (i.e. Y_t -bX-gx is I(1))
    *   We then build y_t = b * x_t + (random walk increments) so the coint level
    *   between y and x is I(0) (cointegrated) but not multicoint.
    *
    * For "none" (no relation): y_t independent random walk.
    *----------------------------------------------------------------------
    qui gen double _e0 = .   // multicoint err  I(0) (regime=multicoint) or I(1)
    qui gen double y   = .

    if "`regime'" == "multicoint" {
        * e0 iid I(0)
        qui replace _e0 = _ue0
        qui gen double _Y = `alpha' + `beta'*X + `gamma'*x + _e0 + `trend'*t
        qui replace y = _Y       in 1
        qui replace y = _Y - L._Y if _n > 1
    }
    else if "`regime'" == "coint" {
        * Level-1 cointegration only: y = b*x + e1 with e1 ~ I(0).
        qui replace _e0 = _ue
        qui gen double _y_temp = `beta'*x + _e0
        * Add a small trend to mirror flow data
        qui replace y = _y_temp + `trend'
    }
    else {
        * No relation: y is independent random walk
        qui replace _e0 = _ue0
        qui gen double _y_temp = .
        qui replace _y_temp = _ue0 in 1
        qui replace _y_temp = L._y_temp + _ue0 if _n > 1
        qui replace y = _y_temp
    }

    * Cumulated Y (only meaningful in multicoint regime, but always generated for convenience)
    qui gen double Y = sum(y)

    * The cumulated equilibrium error (multicoint candidate)
    qui gen double mc_resid = Y - `alpha' - `beta'*X - `gamma'*x

    * Tidy-up: drop temporary
    cap drop _ux _ue _ue0 _e0 _Y _y_temp

    label var y       "Flow y_t  (I(1))"
    label var x       "Flow x_t  (I(1))"
    label var Y       "Cumulated Y_t = sum(y)  (I(2) under multicoint)"
    label var X       "Cumulated X_t = sum(x)  (I(2))"
    label var mc_resid "Multicoint candidate residual Y - a - b*X - g*x"
    label var t       "Time"

    return scalar N      = `n'
    return scalar beta   = `beta'
    return scalar gamma  = `gamma'
    return scalar alpha  = `alpha'
    return local  regime "`regime'"
    return scalar seed   = `seed'

    di as txt _n "{hline 78}"
    di as txt "{bf:multicoint_sim} - simulated multicointegrated data"
    di as txt "{hline 78}"
    di as txt "  regime    = " as res "`regime'"
    di as txt "  N         = " as res `n'
    di as txt "  beta      = " as res %9.4f `beta'    ///
              "   (cointegration coefficient on x)"
    di as txt "  gamma     = " as res %9.4f `gamma'   ///
              "   (multicointegration coefficient on Delta x)"
    di as txt "  alpha     = " as res %9.4f `alpha'
    di as txt "  seed      = " as res `seed'
    di as txt "{hline 78}"
    di as txt "Variables created:  {bf:y}  {bf:x}  {bf:Y}  {bf:X}  {bf:mc_resid}  {bf:t}"
    di as txt "Run e.g.: " as res "multicoint y x, test(egh) est(taols) graph"
end
