*! ovbdc.ado Version 1.0.0 JRC 2024-07-07
program define ovbdc
    version 18.0
    syntax , Means(name) Corr(name) [Verbose ITERate(string) TOLerance(string)]

    mata: ovbdc()
end

version 18.0

mata:
mata set matastrict on

//# Input

real rowvector function Means() {

    real matrix Means
    Means = st_matrix(st_local("means"))

    string scalar orgtype
    orgtype = orgtype(Means)
    if (orgtype == "rowvector") {}
    else if (orgtype == "colvector") Means = Means'
    else {
        errprintf("means must be a vector\n")
        exit(error(503))
    }

    if (rowmissing(Means)) {
        errprintf("elements of means must not be missing\n")
        exit(error(416))
    }
    if (max(Means) >= 1 || min(Means) <= 0) {        
        errprintf("elements of means must be between 0 and 1\n")
        exit(error(125))
    }
    return(Means)
}
real matrix function Corr() {

    real matrix Corr
    Corr = st_matrix(st_local("corr"))

    if (orgtype(Corr) != "matrix") {
        errprintf("corr must be a matrix\n")
        exit(error(503))
    }
    if (missing(Corr)) {
        errprintf("elements of the correlation matrix must not be missing\n")
        exit(error(416))
    }
    if (!issymmetric(Corr)) {
        errprintf("corr must be symmetric\n")
        exit(error(505))
    }
    if (max(abs(lowertriangle(Corr, 0))) >= 1) {
        errprintf("elements of corr must be between -1 and 1\n")
        exit(error(125))
    }
    if (!allof(diagonal(Corr), 1)) {
        errprintf("diagonal elements of the correlation matrix must be 1\n")
        exit(508) // exit(error(508))
    }
    return(Corr)
}
void function checkMeansCorr(real vector Means, real matrix Corr) {
    if (length(Means) != rows(Corr)) {
        errprintf("dimensions of means and corr unequal\n")
        exit(error(503))
    }
}

//# Ridders

class Ridders {
    private:
        real scalar tolerance, iterate, converged, iteration
        void new()
        real scalar z0, z1, target
        real scalar f()
        real scalar xl, xm, xh, fl, fm, fh, result, fn
        void initiate(), evaluate(), rebracket(), loop()
    public:
        final real scalar root()
}
void function Ridders::new() {

    string scalar option
    
    option = st_local("iterate")
    if (strlen(option) > 0) {
        iterate = strtoreal(option)
        if (missing(iterate) | iterate != floor(iterate) | iterate <= 0) {
            printf("option iterate(" + option + ") misspecified; " + 
                "using default\n")
            iterate = 30
        }
    }
    else iterate = 30

    option = st_local("tolerance")
    if (strlen(option) > 0) {
        tolerance = strtoreal(option)
        if (missing(tolerance) | tolerance > 1e-6 | tolerance < 1e-10) {
            printf("option tolerance(" + option + ") misspecified; " + 
                "using default\n")
            tolerance = 1e-10
        }
    }
    else tolerance = 1e-10
}
real scalar function Ridders::f(real scalar rho) {
    return(binormal(z0, z1, rho) - target)
}
real scalar function Ridders::root(
    real scalar z0,
    real scalar z1,
    real scalar target) {

    this.z0 = z0; this.z1 = z1; this.target = target

    initiate()

    if (converged | missing(result)) return(result)
    else {

        loop()

        if (converged) return(result)
        else return(.c) // Convergence not achieved
    }    
}
void function Ridders::initiate() {

    xl = 0.001; xh = 0.999

    converged = iteration = 0

    fl = f(xl)
    if (fl == 0) {
        result = xl
        converged = 1
    }
    else {
        fh = f(xh)
        if (fh == 0) {
            result = xh
            converged = 1
        }
        else if (fl * fh > 0) result = .b // Range does not bound solution
        else {
            result = .n
            evaluate()    
        }
    }
}
void function Ridders::evaluate() {

    xm = (xl + xh) / 2
    fm = f(xm)

    real scalar xn
    xn = xm + (xm - xl) * dsign(1, fl - fh) * fm / sqrt(fm * fm - fl * fh)

    if (abs(xn - result) <= tolerance) converged = 1
    else {
        result = xn
    
        fn = f(xn)
        if (fn == 0) converged = 1
    }
}
void function Ridders::rebracket() {

    if (dsign(fm, fn) != fm) {
        xl = xm
        fl = fm
        xh = result
        fh = fn
    }
    else if (dsign(fl, fn) != fl) {
        xh = result
        fh = fn
    }
    else /* if (dsign(fh, fn) != fh) */ {
        xl = result
        fl = fn
    }
}
void function Ridders::loop() {

    while (!converged & iteration < iterate) {
        rebracket()
        evaluate()
        if (abs(xh - xl) <= tolerance) converged = 1
        iteration++
    }
}

//# PSD

void function warn(real rowvector D) {
    // Uses same tolerance as official Stata _checkpd.ado
    real scalar tolerance
    tolerance =  abs(1e-8 * D[1])

    string scalar warning
    if (rowmin(D) < -tolerance) warning = "indefinite"
    else warning = "not positive definite"

    warning = "Transformed correlation matrix is " + warning + 
        "; forcing to positive semidefinite matrix.\n" +
        "Exercise caution in relying upon results.\n"
    printf(warning)
}

real matrix function psd(real matrix C) {

    real matrix Q, D
    symeigensystem(C, Q=(.), D=(.))

    if (strlen(st_local("verbose")) > 0) warn(D)

    D = sqrt(colmax(D \ J(1, cols(D), 0)))
    real matrix A
    A = Q * diag(D)
    return(A')
}

//# Main

void function stripeEm(real scalar size) {

    string vector Names
    Names = "A", "Z"

    real scalar index
    for (index=1; index<=length(Names); index++) {
        st_matrixcolstripe("r(" + Names[index] + ")", 
            (J(size, 1, Names[index]) , J(1, 1, strofreal(1::size))))
    }

}

void function ovbdc() {

    real matrix Corr
    Corr = Corr()

    real rowvector Means
    Means = Means()

    checkMeansCorr(Means, Corr)

    class Ridders scalar r

    real matrix C
    C = I(rows(Corr))

    real rowvector Z
    Z = invnormal(Means)

    real scalar row, col, a, b, target, rho, corr
    for (row=2; row<=length(Z); row++) {

        a = Means[row]

        for (col=1; col<=row-1; col++) {

            b = Means[col]

            corr = Corr[row, col]
            if (corr == 0) rho = 0
            else {
                target = a * (1 - a) * b * (1 - b)
                target = sqrt(target)
                target = target * abs(corr)
                target = target + a * b

                rho = r.root(Z[row], Z[col], target)

                if (rho == .b) {
                    printf("failure Ridders to bracket root with proportion " + 
                        "pair %1.0f, %1.0f (%04.2f, %04.2f), correlation " + 
                        "coefficient %04.2f\n", col, row, b, a, Corr[row, col])
                }
                else if (rho == .c) {
                    printf("failure of Ridders to converge with proportion " + 
                        "pair %1.0f, %1.0f (%04.2f, %04.2f), correlation " + 
                        "coefficient %04.2f\n", col, row, b, a, Corr[row, col])
                }
                else rho = sign(Corr[row, col]) * abs(rho)
            }

            C[row, col] = rho
        }
    }

    if (hasmissing(lowertriangle(C))) exit(error(504))

    _makesymmetric(C)

    real matrix A
    A = cholesky(C)'

    if (missing(A)) A = psd(C)

    st_matrix("r(A)", A)
    st_matrix("r(Z)", Z)
    stripeEm(cols(Z))
}

end
