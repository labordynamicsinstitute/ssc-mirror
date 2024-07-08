*! ovbd_illustrator.do Version 2.0.0 JRC 2007-07-07

version 18.0

clear *

set seed 1774624902

which ovbd.ado
which ovbdc.ado
which ovbdr.ado

*
* Constant means (0.5) and correlation coefficient (0.5)
*
matrix define M50 = J(1, 10, 0.5)
matrix define C50 = J(10, 10, 0.5) + I(10) * 0.5

ovbd , stub(rsp) means(M50) corr(C50) n(250)

generate `c(obs_t)' pid = _n
quietly reshape long rsp, i(pid) j(tim)
xtgee rsp tim, i(pid) family(binomial) link(logit) corr(exchangeable) nolog
margins
xtcorr, compact

*
* Same mean vector, but 0.25 compound symmetric correlation matrix
*
matrix define C25 = J(10, 10, 0.25) + I(10) * 0.75
ovbd , stub(rsp) means(M50) corr(C25) n(250) clear

generate `c(obs_t)' pid = _n
quietly reshape long rsp, i(pid) j(tim)
xtgee rsp tim, i(pid) family(binomial) link(logit) corr(exchangeable) nolog
margins
xtcorr, compact

*
* Varying means with 0.5 constant correlation coefficient
*
matrix define MV = J(1, 10, 0.5)
forvalues i = 1/10 {
    matrix define MV[1,`i'] = MV[1,`i'] - (`i' - 5) / 30
}
matrix list MV

ovbd , stub(rsp) means(MV) corr(C50) n(250) clear

generate `c(obs_t)' pid = _n
quietly reshape long rsp, i(pid) j(tim)
xtgee rsp i.tim, i(pid) family(binomial) link(logit) corr(exchangeable) nolog
margins tim
xtcorr, compact

*
* Varying means and first-order autoregresive correlation coefficient (0.75)
*
matrix define CAR1 = J(10, 10, 0.75)
forvalues i = 2/10 {
    forvalues j = 1/`=`i'-1' {
        matrix define CAR1[`i',`j'] = CAR1[`i',`j']^abs(`i' - `j')
        matrix define CAR1[`j',`i'] = CAR1[`i',`j']
    }
}
forvalues i = 1/10 {
    matrix define CAR1[`i', `i'] = 1
}
matrix list CAR1

ovbd , stub(rsp) means(MV) corr(CAR1) n(250) clear

generate `c(obs_t)' pid = _n
quietly reshape long rsp, i(pid) j(tim)
xtgee rsp i.tim, i(pid) t(tim) family(binomial) link(logit) corr(ar 1) nolog
margins tim
xtcorr, compact

*
* Underdispersion
*
matrix define M50 = J(1, 2, 0.5)
matrix define CU50 = J(2, 2, -0.5)
forvalues i = 1/2 {
    matrix define CU50[`i', `i'] = 1
}

ovbd , stub(rsp) means(M50) corr(CU50) n(250) clear

generate `c(obs_t)' pid = _n
quietly reshape long rsp, i(pid) j(tim)
xtgee rsp tim, i(pid) family(binomial) link(logit) corr(exchangeable) nolog
margins
xtcorr, compact

*
* Imprudent target correlation structure
*
matrix define MI = J(1, 4, 0.5)
matrix define CI = J(4, 4, 0.5) + I(4) * 0.5
matrix define CI[1, 4] = 0
matrix define CI[4, 1] = 0
matrix define CI[2, 3] = 0
matrix define CI[3, 2] = 0
matrix list CI
mata: rank(st_matrix("CI"))

ovbd , stub(rsp) means(MI) corr(CI) n(250) verbose clear
correlate // Undershoots (0.30 to 0.45 for 0.5) when target is ill-considered

exit
