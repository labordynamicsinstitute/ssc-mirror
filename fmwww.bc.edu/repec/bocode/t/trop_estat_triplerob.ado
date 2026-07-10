*! Post-estimation diagnostic: triple-robustness bias decomposition (paper
*! Athey, Imbens, Qu & Viviano 2025, Theorem 5.1).
*!
*! Reports the three product terms that bound |E[tauhat - tau | L]|:
*!
*!    | Delta^u( omega, Gamma ) |_2    unit-weight imbalance against the
*!                                     SVD loadings of the factor matrix
*!    | Delta^t( theta, Lambda ) |_2   time-weight imbalance against the
*!                                     SVD factors
*!    | B |_*                          residual nuclear mass discarded by
*!                                     the rank-k truncation
*!
*! The product approximates the Theorem 5.1 bias bound.  For the joint
*! method the global weights delta_time / delta_unit are used and the
*! imbalance is averaged over all treated cells.  For the twostep method
*! only e(theta) / e(omega) for the first treated cell are available in
*! e(); the decomposition is therefore reported for that cell alone.
*!
*! Syntax:
*!   estat triplerob [, rank(#) topk(#)]
*!
*! Options:
*!   rank(#)   truncation rank used for the SVD decomposition of L.  Default
*!             is ceil(e(effective_rank)), capped at min(T, N).
*!   topk(#)   number of leading singular directions to tabulate individually
*!             (default 3).

program define trop_estat_triplerob, rclass
    version 17
    syntax [, RANK(integer 0) TOPk(integer 3)]

    // Require a prior `trop` estimation in e().
    if "`e(cmd)'" != "trop" {
        di as error "last estimates not found or not from trop"
        di as error "Run {bf:trop} command before using {bf:estat triplerob}"
        exit 301
    }

    capture confirm matrix e(factor_matrix)
    if _rc {
        di as error "e(factor_matrix) not found; triplerob needs the estimated L"
        di as error "(this happens when estimation was aborted before the factor "
        di as error " matrix was populated)"
        exit 111
    }

    // Determine method (affects which weight vectors are in e()).
    local method = "`e(method)'"
    if "`method'" == "" local method "twostep"

    // Default rank = round(e(effective_rank)).
    if `rank' <= 0 {
        local er = e(effective_rank)
        if `er' < . {
            local rank = max(1, ceil(`er'))
        }
        else {
            local rank = 1
        }
    }
    if `topk' < 1 local topk = 1

    // Dispatch to Mata for the numerical work.  The Mata routine prints
    // its own formatted block and populates r().
    capture mata: mata which _trop_estat_triplerob()
    if _rc {
        // Mata lib may have been cleared; try to reload.
        capture _trop_load_mata
        if _rc {
            di as error "Mata function _trop_estat_triplerob() not found."
            di as error "Run {cmd:trop} first, or ensure TROP Mata libraries are installed."
            exit 111
        }
    }

    mata: _trop_estat_triplerob("`method'", `rank', `topk')

    // Export r() scalars for programmatic use.
    return scalar rank        = `rank'
    return scalar delta_unit  = __trop_tr_du
    return scalar delta_time  = __trop_tr_dt
    return scalar residual    = __trop_tr_res
    return scalar bias_bound  = __trop_tr_bound
    return local  method      = "`method'"

    // Clean up scratch scalars.
    capture scalar drop __trop_tr_du __trop_tr_dt __trop_tr_res __trop_tr_bound
end
