*! ovbd.ado Version 2.0.0 JRC 2024-07-07
program define ovbd
    version 18.0
    syntax [anything], Means(name) Corr(name) ///
        [n(integer `=_N') STub(string) SEED(string) ///
        Verbose ITERate(passthru) TOLerance(passthru) clear]

    mata: setC()

    ovbdc , m(`means') c(`corr') `verbose' `iterate' `tolerance'

    mata: setR()

    ovbdr `varlist', z(`Z') a(`A')
end

version 18.0

mata:
mata set matastrict on

//# setC

void function setVarlist() {

    string scalar varlist, stub
    varlist = st_local("anything")
    stub = st_local("stub")

    real scalar mean_tally, index
    // Defers checking Means
    mean_tally = max( (rows(st_matrix(st_local("means"))), 
        cols(st_matrix(st_local("means")))) )

    if (!strlen(varlist + stub)) {
        errprintf("one of newvarlist or stub() must be specified\n")
        exit(error(198))
    }
    else {
        if (strlen(varlist) > 0) {
            if (strlen(stub) > 0) {
                errprintf("only one of newvarlist or stub() may be specified\n")
                exit(error(198))
            }
            else {
                if (cols(tokens(varlist)) != mean_tally) {
                    errprintf("number of newvarlist is not equal to length of mean vector\n")
                    exit(error(198))
                }
                else st_local("varlist", varlist)
            }
        }
        else {
            for (index=1; index<=mean_tally; index++) {
                varlist = varlist + " " + stub + strofreal(index)
            }
            st_local("varlist", strtrim(varlist))
        }
    }
}

void function checkNewvarlist() {

    real rowvector Varindices
    Varindices = _st_varindex(tokens(st_local("varlist")))

    if (!allof(Varindices, .)) {
        errprintf("%s already defined\n", invtokens(st_varname(
            select(Varindices, Varindices :!= .))))
        exit(110)
    }
}

void function setC() {
    setVarlist()
    if (st_local("clear") == "") checkNewvarlist()
}

//# setR

void function setN() {

    real scalar n
    n = strtoreal(st_local("n"))

    if (n <= 0) exit(error(2000))
    else {
        if (!strlen(st_local("clear"))) {
            if (!st_nobs()) st_addobs(n)
            else if (n != st_nobs()) exit(error(4))
            else {}
        }
        else {
            st_dropvar(.)
            st_addobs(n)
        }
    }
}

void function transferMatrices() {

    string matrix Transfer
    Transfer = st_tempname(2) \ ("r(Z)", "r(A)") \ ("Z", "A")

    real scalar column
    for (column=1; column<=cols(Transfer); column++) {
        st_matrix(Transfer[1, column], st_matrix(Transfer[2, column]))
        st_matrixcolstripe(Transfer[1, column], 
            st_matrixcolstripe(Transfer[2, column]))
        st_local(Transfer[3, column], Transfer[1, column])
    }
}

void function setSeed() {

    string scalar seed_string
    seed_string = st_local("seed")

    real scalar seed

    if (strlen(seed_string) == 0) exit(0)
    else {
        seed = strtoreal(seed_string)
        if (missing(seed) | ceil(abs(seed)) >= 2e31) {
            errprintf(seed_string + " found where integer < 2^31 expected\n")
            exit(error(198))
        }
        else rseed(seed)
    }
}

void function setR() {
    setN()
    transferMatrices()
    setSeed()
}

end
