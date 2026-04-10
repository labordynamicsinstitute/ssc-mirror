*! xtpqcsmc v1.0.1  08apr2026
*! Monte Carlo replication of Section 5 of Chiang, Galvao & Wei (2026)
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>

program define xtpqcsmc, rclass
    version 14.0

    syntax , [N(integer 250) Tperiods(integer 25) Reps(integer 200) ///
             Quantile(real 0.5) BETAcoef(real 1.0) GAMMAcoef(real 0.2) ///
             Seed(integer 20260220) NODOTs SAVing(string)]

    local Tnum = `tperiods'
    local Nnum = `n'
    local nobs = `n'*`tperiods'

    set seed `seed'

    di as txt _n "{hline 78}"
    di as res "  xtpqcsmc - Monte Carlo for xtpqcs"
    di as txt "  Replicates Section 5 of Chiang, Galvao & Wei (2026)"
    di as txt "{hline 78}"
    di as txt "  N = " as res `n' as txt ", T = " as res `tperiods' ///
       as txt ", reps = " as res `reps' as txt ", tau = " as res %4.2f `quantile'
    di as txt "{hline 78}"

    tempname mh
    tempfile mcres
    postfile `mh' rep double(bhat se_rob se_cl reject_rob reject_cl) ///
        using `mcres', replace

    local btau = `betacoef' + `gammacoef'*invnormal(`quantile')
    di as txt "  True beta(tau) = " as res %8.4f `btau'

    forvalues r = 1/`reps' {
        if "`nodots'" == "" {
            if mod(`r',10)==0 di as txt "." _continue
            if mod(`r',500)==0 di as txt " `r'"
        }
        qui {
            clear
            set obs `Nnum'
            gen long id = _n
            gen double alpha = runiform()
            expand `Tnum'
            bys id: gen int t = _n
            gen double X = rchi2(3) + 0.3*alpha
            sort t
            by t: gen double eta = rnormal() if _n==1
            by t: replace eta = eta[1]
            gen double eps = rnormal()
            gen double U = (eps + eta)/sqrt(2)
            gen double y = alpha + `betacoef'*X + (1 + `gammacoef'*X)*U
            xtpqcs y X, id(id) time(t) quantile(`quantile') noheader
        }
        local b = _b[X]
        local sr = sqrt(e(V_robust)["X","X"])
        local sc = sqrt(e(V_classical)["X","X"])
        local rj_r = abs(`b' - `btau') > 1.96*`sr'
        local rj_c = abs(`b' - `btau') > 1.96*`sc'
        post `mh' (`r') (`b') (`sr') (`sc') (`rj_r') (`rj_c')
    }
    postclose `mh'
    di as txt _n "{hline 78}"

    preserve
    qui use `mcres', clear
    qui {
        gen err = bhat - `btau'
        su err, meanonly
        local bias = r(mean)
        gen err2 = err^2
        su err2, meanonly
        local rmse = sqrt(r(mean))
        su reject_rob, meanonly
        local cov_r = 1 - r(mean)
        su reject_cl, meanonly
        local cov_c = 1 - r(mean)
    }

    di as res "  Results"
    di as txt "  ----------------------------------------------"
    di as txt "  Bias              : " as res %9.5f `bias'
    di as txt "  RMSE              : " as res %9.5f `rmse'
    di as txt "  Coverage (Robust) : " as res %9.4f `cov_r'
    di as txt "  Coverage (Classic): " as res %9.4f `cov_c'
    di as txt "{hline 78}"

    return scalar bias = `bias'
    return scalar rmse = `rmse'
    return scalar cov_robust    = `cov_r'
    return scalar cov_classical = `cov_c'

    if `"`saving'"' != "" {
        save `"`saving'"', replace
        di as txt "  Replication-level results saved to " as res `"`saving'"'
    }
    restore
end
