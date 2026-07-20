*! prcoint 1.7.6 18jul2026 Ozan Eruygur
*! Perron and Rodriguez (2016) residuals-based tests for cointegration under endogeneity and serial correlation (GLS-detrended)
*! Port of the official GAUSS/MATLAB code by Rodriguez and Ataurima (PUCP, June 2016)
*! Critical values from Tables 2, 3 and 4 of Perron and Rodriguez (2016, Econometrics Journal 19, 84-111)

program define prcoint, rclass
    version 14.0
    syntax varlist(numeric ts min=2) [if] [in] [, Model(integer 1) MAXlag(string) MINlag(integer 0) CBar(string)]

    * ------------------------------------------------------------------
    * checks on options
    * ------------------------------------------------------------------
    if `model' < 1 | `model' > 3 {
        display as error "model() must be 1, 2 or 3"
        exit 198
    }
    if `minlag' < 0 {
        display as error "minlag() must be a nonnegative integer"
        exit 198
    }

    * ------------------------------------------------------------------
    * time-series settings
    * ------------------------------------------------------------------
    capture tsset
    if _rc {
        display as error "time variable not set; use tsset"
        exit 111
    }
    if "`r(panelvar)'" != "" {
        display as error "prcoint is for single time series; panel data not allowed"
        exit 198
    }

    marksample touse
    quietly tsreport if `touse'
    if r(N_gaps) > 0 {
        display as error "sample may not contain gaps"
        exit 498
    }

    quietly count if `touse'
    local T = r(N)

    tsrevar `varlist'
    local rvars `r(varlist)'
    local ry : word 1 of `rvars'
    local rx : list rvars - ry
    local m : word count `rx'

    local yorig : word 1 of `varlist'
    local xorig : list varlist - yorig

    * ------------------------------------------------------------------
    * optimal cbar from Table 1 of PR (2016), unless supplied by the user
    * rows m=1..5; if m>5 the m=5 row is used, as in the original code
    * ------------------------------------------------------------------
    local mm = min(`m',5)
    tempname cb
    if "`cbar'" == "" {
        local userc = 0
        if `mm' == 1 {
            if `model' == 1 scalar `cb' = -13.75
            if `model' == 2 scalar `cb' = -20.50
            if `model' == 3 scalar `cb' = -13.50
        }
        if `mm' == 2 {
            if `model' == 1 scalar `cb' = -18.25
            if `model' == 2 scalar `cb' = -23.75
            if `model' == 3 scalar `cb' = -18.00
        }
        if `mm' == 3 {
            if `model' == 1 scalar `cb' = -22.25
            if `model' == 2 scalar `cb' = -27.25
            if `model' == 3 scalar `cb' = -23.00
        }
        if `mm' == 4 {
            if `model' == 1 scalar `cb' = -26.25
            if `model' == 2 scalar `cb' = -30.75
            if `model' == 3 scalar `cb' = -26.00
        }
        if `mm' == 5 {
            if `model' == 1 scalar `cb' = -30.00
            if `model' == 2 scalar `cb' = -33.75
            if `model' == 3 scalar `cb' = -29.75
        }
    }
    else {
        local userc = 1
        capture confirm number `cbar'
        if _rc {
            display as error "cbar() must be a number"
            exit 198
        }
        scalar `cb' = `cbar'
        if scalar(`cb') > 0 {
            display as error "cbar() must be nonpositive"
            exit 198
        }
    }

    * ------------------------------------------------------------------
    * lag bounds: default kmax = round(4*(T/100)^(1/4)) as in the source
    * ------------------------------------------------------------------
    if "`maxlag'" == "" {
        local kmax = round(4*(`T'/100)^0.25)
    }
    else {
        capture confirm integer number `maxlag'
        if _rc {
            display as error "maxlag() must be a nonnegative integer"
            exit 198
        }
        local kmax = `maxlag'
    }
    if `kmax' < `minlag' {
        display as error "maxlag() must be at least as large as minlag()"
        exit 198
    }
    if `T' <= 2*`kmax' + 2 {
        display as error "insufficient number of observations for maxlag(`kmax')"
        exit 2001
    }

    * ------------------------------------------------------------------
    * computation in Mata
    * ------------------------------------------------------------------
    tempname RES BETA SE DET
    mata: prcoint_work("`ry'", "`rx'", "`touse'", `model', st_numscalar("`cb'"), `minlag', `kmax', "`RES'", "`BETA'", "`SE'", "`DET'")

    local kbic = `RES'[8,1]

    * ------------------------------------------------------------------
    * asymptotic critical values, Tables 2-4 of PR (2016)
    * rows: 1%, 2.5%, 5%, 7.5%, 10%, 15%, 20%; columns: m=1..5
    * Ho of no cointegration is rejected when the statistic is smaller
    * than the critical value (left-tail rejection for all seven tests)
    * ------------------------------------------------------------------
    tempname CVMPT CVMSB CVZR CVZT
    if `model' == 1 {
        matrix `CVMPT' = (4.352, 5.819, 6.894, 8.272, 9.495 \ 5.260, 6.781, 7.973, 9.430, 10.526 \ 6.325, 7.856, 8.923, 10.556, 11.656 \ 7.195, 8.662, 9.783, 11.311, 12.571 \ 7.877, 9.330, 10.439, 12.031, 13.280 \ 9.161, 10.488, 11.704, 13.364, 14.608 \ 10.388, 11.695, 12.939, 14.405, 15.677)
        matrix `CVMSB' = (0.146, 0.128, 0.114, 0.107, 0.100 \ 0.160, 0.138, 0.122, 0.114, 0.106 \ 0.174, 0.147, 0.131, 0.120, 0.111 \ 0.184, 0.155, 0.136, 0.125, 0.115 \ 0.193, 0.161, 0.141, 0.128, 0.119 \ 0.208, 0.170, 0.149, 0.135, 0.124 \ 0.221, 0.179, 0.156, 0.140, 0.128)
        matrix `CVZR' = (-22.664, -29.949, -37.155, -42.779, -48.839 \ -18.872, -25.425, -32.614, -37.437, -44.034 \ -15.603, -22.011, -28.608, -33.633, -39.529 \ -13.794, -19.913, -26.114, -31.269, -36.765 \ -12.574, -18.496, -24.393, -29.372, -34.642 \ -10.634, -16.412, -21.793, -26.578, -31.603 \ -9.339, -14.683, -19.689, -24.549, -29.437)
        matrix `CVZT' = (-3.322, -3.791, -4.242, -4.576, -4.891 \ -3.011, -3.494, -3.957, -4.268, -4.594 \ -2.736, -3.254, -3.710, -4.028, -4.366 \ -2.552, -3.088, -3.544, -3.887, -4.214 \ -2.424, -2.972, -3.434, -3.770, -4.083 \ -2.229, -2.784, -3.221, -3.572, -3.900 \ -2.082, -2.637, -3.064, -3.427, -3.751)
    }
    if `model' == 2 {
        matrix `CVMPT' = (7.207, 7.888, 8.783, 9.617, 10.281 \ 8.240, 9.011, 9.832, 10.983, 11.721 \ 9.499, 10.162, 11.004, 12.411, 12.892 \ 10.520, 11.064, 11.918, 13.236, 13.711 \ 11.346, 11.885, 12.760, 13.943, 14.449 \ 12.866, 13.200, 14.045, 15.268, 15.745 \ 14.334, 14.465, 15.221, 16.391, 16.875)
        matrix `CVMSB' = (0.127, 0.115, 0.107, 0.099, 0.093 \ 0.137, 0.123, 0.113, 0.106, 0.100 \ 0.147, 0.131, 0.119, 0.112, 0.104 \ 0.154, 0.137, 0.124, 0.116, 0.108 \ 0.160, 0.141, 0.128, 0.119, 0.110 \ 0.170, 0.149, 0.135, 0.124, 0.115 \ 0.179, 0.156, 0.140, 0.129, 0.119)
        matrix `CVZR' = (-29.880, -36.742, -43.298, -50.394, -56.941 \ -26.413, -32.479, -38.714, -43.818, -49.641 \ -22.554, -28.495, -34.482, -38.936, -45.067 \ -20.526, -26.080, -31.855, -36.561, -42.486 \ -18.881, -24.350, -29.769, -34.755, -40.312 \ -16.673, -21.819, -26.974, -31.683, -36.932 \ -14.899, -19.908, -24.851, -29.383, -34.382)
        matrix `CVZT' = (-3.871, -4.318, -4.606, -4.953, -5.199 \ -3.572, -4.001, -4.343, -4.617, -4.939 \ -3.323, -3.734, -4.093, -4.381, -4.690 \ -3.174, -3.567, -3.933, -4.215, -4.529 \ -3.049, -3.457, -3.806, -4.098, -4.404 \ -2.855, -3.261, -3.624, -3.915, -4.223 \ -2.693, -3.105, -3.474, -3.773, -4.068)
    }
    if `model' == 3 {
        matrix `CVMPT' = (4.099, 5.486, 7.310, 7.999, 9.057 \ 4.881, 6.410, 8.438, 9.119, 10.172 \ 5.864, 7.472, 9.542, 10.223, 11.471 \ 6.557, 8.196, 10.412, 11.083, 12.345 \ 7.177, 8.840, 11.139, 11.818, 13.043 \ 8.297, 9.998, 12.384, 12.971, 14.288 \ 9.344, 11.029, 13.541, 14.028, 15.358)
        matrix `CVMSB' = (0.143, 0.125, 0.114, 0.106, 0.099 \ 0.157, 0.135, 0.122, 0.113, 0.105 \ 0.170, 0.146, 0.130, 0.119, 0.111 \ 0.180, 0.153, 0.136, 0.125, 0.115 \ 0.187, 0.158, 0.140, 0.128, 0.118 \ 0.201, 0.168, 0.148, 0.134, 0.124 \ 0.213, 0.177, 0.154, 0.140, 0.128)
        matrix `CVZR' = (-23.553, -31.106, -37.169, -43.597, -50.095 \ -19.506, -26.421, -32.617, -38.190, -44.873 \ -16.509, -22.588, -28.627, -34.184, -39.866 \ -14.569, -20.569, -26.247, -31.299, -36.980 \ -13.452, -19.093, -24.419, -29.618, -34.994 \ -11.531, -16.877, -22.031, -26.804, -31.892 \ -10.119, -15.148, -20.198, -24.704, -29.545)
        matrix `CVZT' = (-3.425, -3.897, -4.256, -4.643, -4.936 \ -3.121, -3.622, -3.967, -4.317, -4.667 \ -2.842, -3.323, -3.729, -4.055, -4.391 \ -2.672, -3.160, -3.561, -3.892, -4.232 \ -2.547, -3.031, -3.451, -3.779, -4.105 \ -2.347, -2.850, -3.251, -3.599, -3.909 \ -2.203, -2.698, -3.098, -3.448, -3.769)
    }

    tempname MPTv MSBv ZRv ZTv CV
    matrix `MPTv' = `CVMPT'[1..., `mm']
    matrix `MSBv' = `CVMSB'[1..., `mm']
    matrix `ZRv' = `CVZR'[1..., `mm']
    matrix `ZTv' = `CVZT'[1..., `mm']
    matrix `MPTv' = `MPTv''
    matrix `MSBv' = `MSBv''
    matrix `ZRv' = `ZRv''
    matrix `ZTv' = `ZTv''
    matrix `CV' = (`ZRv' \ `MSBv' \ `ZTv' \ `ZTv' \ `ZRv' \ `ZTv' \ `MPTv')
    matrix rownames `CV' = mzrho msb mzt adf zrho zt mpt
    matrix colnames `CV' = cv1 cv2_5 cv5 cv7_5 cv10 cv15 cv20

    * ------------------------------------------------------------------
    * display of results
    * ------------------------------------------------------------------
    if `model' == 1 local mtxt "1: constant (p=0), non-trending data (py=0, px=0)"
    if `model' == 2 local mtxt "2: constant and time trend (p=1) (py=1, px=1)"
    if `model' == 3 local mtxt "3: constant (p=0), trending data (py=0, px=1)"

    display as text ""
    display as text "Perron-Rodriguez (2016) residuals-based tests for cointegration"
    display as text "GLS (local to unity) detrended data"
    display as text "{hline 74}"
    display as text "Ho: no cointegration"
    display as text "Deterministic case      : " as result "`mtxt'"
    display as text "Number of X variables   : " as result %8.0f `m'
    display as text "Quasi-diff. parameter   : " as result %8.2f scalar(`cb') as text "  (cbar)"
    display as text "Number of observations  : " as result %8.0f `T'
    display as text "Lag selection           : " as result "BIC" as text ", kmin = " as result `minlag' as text ", kmax = " as result `kmax'
    display as text "Selected lag            : " as result %8.0f `kbic'
    display as text "{hline 74}"
    display as text "Statistic" _col(23) "Value" _col(34) "1% cv" _col(48) "5% cv" _col(61) "10% cv"
    display as text "{hline 74}"
    display as text "MZ_rho(GLS)"  _col(15) as result %13.4f `RES'[1,1] _col(28) %11.3f `CV'[1,1] _col(42) %11.3f `CV'[1,3] _col(56) %11.3f `CV'[1,5]
    display as text "MSB(GLS)"     _col(15) as result %13.4f `RES'[2,1] _col(28) %11.3f `CV'[2,1] _col(42) %11.3f `CV'[2,3] _col(56) %11.3f `CV'[2,5]
    display as text "MZ_t(GLS)"    _col(15) as result %13.4f `RES'[3,1] _col(28) %11.3f `CV'[3,1] _col(42) %11.3f `CV'[3,3] _col(56) %11.3f `CV'[3,5]
    display as text "ADF(GLS)"     _col(15) as result %13.4f `RES'[4,1] _col(28) %11.3f `CV'[4,1] _col(42) %11.3f `CV'[4,3] _col(56) %11.3f `CV'[4,5]
    display as text "Z_rho(GLS)"   _col(15) as result %13.4f `RES'[5,1] _col(28) %11.3f `CV'[5,1] _col(42) %11.3f `CV'[5,3] _col(56) %11.3f `CV'[5,5]
    display as text "Z_t(GLS)"     _col(15) as result %13.4f `RES'[6,1] _col(28) %11.3f `CV'[6,1] _col(42) %11.3f `CV'[6,3] _col(56) %11.3f `CV'[6,5]
    display as text "MPT(GLS)"     _col(15) as result %13.4f `RES'[7,1] _col(28) %11.3f `CV'[7,1] _col(42) %11.3f `CV'[7,3] _col(56) %11.3f `CV'[7,5]
    display as text "{hline 74}"
    display as text "Ho is rejected in the left tail: MZ_rho, MZ_t, ADF, Z_rho and Z_t reject"
    display as text "when more negative than the cv; MSB and MPT when smaller than the cv."
    display as text "Critical values: Perron and Rodriguez (2016), Tables 2-4; asymptotic."
    if `m' > 5 {
        display as text "Note: m>5, cbar and critical values are from the m=5 column, as in the original code."
    }
    if `userc' == 1 {
        display as text "Note: tabulated critical values assume the optimal cbar of Table 1."
    }

    * ------------------------------------------------------------------
    * stored results
    * ------------------------------------------------------------------
    return matrix cv = `CV'
    matrix colnames `BETA' = `xorig'
    matrix colnames `SE' = `xorig'
    return matrix se = `SE'
    return matrix beta = `BETA'
    if `model' == 2 {
        return scalar trend = `DET'[2,1]
    }
    return scalar cons = `DET'[1,1]
    return scalar mpt    = `RES'[7,1]
    return scalar zt     = `RES'[6,1]
    return scalar zrho   = `RES'[5,1]
    return scalar adf    = `RES'[4,1]
    return scalar mzt    = `RES'[3,1]
    return scalar msb    = `RES'[2,1]
    return scalar mzrho  = `RES'[1,1]
    return scalar lag    = `kbic'
    return scalar maxlag = `kmax'
    return scalar minlag = `minlag'
    return scalar cbar   = scalar(`cb')
    return scalar m      = `m'
    return scalar model  = `model'
    return scalar N      = `T'
end

version 14.0
mata:
mata set matastrict on

void prcoint_work(string scalar yname, string scalar xnames, string scalar tousename, real scalar det, real scalar cbar, real scalar kmin, real scalar kmax, string scalar outmat, string scalar bmat, string scalar semat, string scalar dmat)
{
    real colvector y, u, du, lu, dep, b2, e2, ee, yd, bvec, sevec, dcoef
    real matrix X, Xd, Z, Za, W, Wa, Wd, R, reg, psi
    real scalar T, m, ab, a1, ss, aa, talpha, sumu, uT2, minbic, kbic, k, h, s2e2, xx11, sumb, s22, bic, mz, msb, mzt, adf, zr, zt, mpt, s2b

    y = st_data(., yname, tousename)
    X = st_data(., tokens(xnames), tousename)
    T = rows(y)
    m = cols(X)

    // ------------------------------------------------------------
    // GLS detrending: quasi-difference with alphabar = 1 + cbar/T,
    // first observation kept in levels (ERS 1996)
    // ------------------------------------------------------------
    ab = 1 + cbar/T
    if (det == 2) Z = J(T,1,1), (1::T)
    else          Z = J(T,1,1)

    W  = y, X
    Wa = W
    Za = Z
    Wa[|2,1 \ T,.|] = W[|2,1 \ T,.|] - ab:*W[|1,1 \ T-1,.|]
    Za[|2,1 \ T,.|] = Z[|2,1 \ T,.|] - ab:*Z[|1,1 \ T-1,.|]

    psi = qrsolve(Za, Wa)
    Wd = W - Z*psi
    yd = Wd[.,1]
    Xd = Wd[|1,2 \ T,m+1|]

    // ------------------------------------------------------------
    // cointegrating regression on detrended data (no deterministics)
    // ------------------------------------------------------------
    bvec = qrsolve(Xd, yd)
    u = yd - Xd*bvec

    // ------------------------------------------------------------
    // AR(1) regression of u_t on u_{t-1} (no constant)
    // ------------------------------------------------------------
    a1     = qrsolve(u[|1 \ T-1|], u[|2 \ T|])
    ee     = u[|2 \ T|] - u[|1 \ T-1|]*a1
    ss     = (ee'ee)/(T-2)
    aa     = 1/(u[|1 \ T-1|]'u[|1 \ T-1|])
    talpha = (a1-1)/sqrt(ss*aa)
    sumu   = (u[|1 \ T-1|]'u[|1 \ T-1|])/(T-1)^2
    uT2    = u[T]^2/T

    // ------------------------------------------------------------
    // ADF regression with BIC lag selection, as in the source:
    // zero-padded differences and lags, trimmed by k+1 rows on top;
    // BIC = ln(SSR/(T-kmax)) + ln(T-kmax)*k/(T-kmax)
    // ------------------------------------------------------------
    du = 0 \ (u[|2 \ T|] - u[|1 \ T-1|])
    lu = 0 \ u[|1 \ T-1|]

    minbic = 999999999
    kbic   = .
    mz = msb = mzt = adf = zr = zt = mpt = .

    for (k=kmin; k<=kmax; k++) {
        reg = lu
        for (h=1; h<=k; h++) reg = reg, (J(h,1,0) \ du[|1 \ T-h|])
        dep = du[|k+2 \ T|]
        R   = reg[|k+2,1 \ T,.|]

        b2   = qrsolve(R, dep)
        e2   = dep - R*b2
        s2e2 = (e2'e2)/(rows(e2)-cols(R))
        xx11 = invsym(R'R)[1,1]

        sumb = 0
        for (h=1; h<=k; h++) sumb = sumb + b2[h+1]
        s22 = s2e2/(1-sumb)^2

        bic = ln((e2'e2)/(T-kmax)) + ln(T-kmax)*k/(T-kmax)
        if (bic < minbic) {
            minbic = bic
            kbic   = k
            mz  = (uT2 - s22)/(2*sumu)
            msb = sqrt(sumu/s22)
            mzt = mz*msb
            adf = b2[1]/sqrt(s2e2*xx11)
            zr  = (T-1)*(a1-1) - 0.5*(s22-ss)/sumu
            zt  = sqrt(ss/s22)*talpha - (s22-ss)/sqrt(4*s22*sumu)
            if (det == 2) mpt = (cbar^2*sumu + (1-cbar)*uT2)/s22
            else          mpt = (cbar^2*sumu - cbar*uT2)/s22
        }
    }

    s2b = (u'u)/(T-m)
    sevec = sqrt(diagonal(invsym(Xd'Xd)):*s2b)
    dcoef = psi[.,1] - psi[|1,2 \ rows(psi),m+1|]*bvec
    st_matrix(dmat, dcoef)
    st_matrix(bmat, bvec')
    st_matrix(semat, sevec')
    st_matrix(outmat, (mz \ msb \ mzt \ adf \ zr \ zt \ mpt \ kbic))
}

end
