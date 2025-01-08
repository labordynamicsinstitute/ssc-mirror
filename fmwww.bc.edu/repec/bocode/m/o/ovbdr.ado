*! ovbdr.ado Version 1.0.0 JRC 2024-07-07
program define ovbdr
    version 18.0
    syntax newvarlist, z(name) a(name)

    mata: ovbdr()
end

version 18.0

mata:
mata set matastrict on

void function ovbdr() {

    if (!st_nobs()) exit(error(2000))

    real rowvector Z
    Z = st_matrix(st_local("z"))

    if (cols(tokens(st_local("varlist"))) != cols(Z)) {
        errprintf("number of newvarlist is not equal to length of mean vector\n")
        exit(error(198))
    }

    if ( st_matrixcolstripe(st_local("z")) != 
        ( J(cols(Z), 1, "Z"), J(1, 1, strofreal(1::cols(Z))) ) ) {
            errprintf("rowvector Z did not come from ovbdc\n")
            exit(error(198))
    }

    real matrix A
    A = st_matrix(st_local("a"))

    if ( st_matrixcolstripe(st_local("a")) != 
        ( J(cols(A), 1, "A"), J(1, 1, strofreal(1::cols(A))) ) ) {
            errprintf("matrix A did not come from ovbdc\n")
            exit(error(198))
    }

    real matrix X
    X = rnormal(st_nobs(), cols(Z), 0, 1)

    X = X * A
    X = X :<= Z

    st_store(., st_addvar("byte", tokens(st_local("varlist"))), X)
}

end
