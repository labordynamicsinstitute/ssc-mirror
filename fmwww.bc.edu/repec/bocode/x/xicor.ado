*! version 1.0.1  22jun2026
program xicor , rclass
    
    version 16.1
    
    syntax varlist(min=2 numeric) [ if ] [ in ] ///
    [ ,                                         ///
        PValue                                  ///
        NORMALIZE                               /// sic!
        SYMmetric                               ///
        rseed(string asis)                      ///
        FORmat(string)                          ///
    ]
    
    if ("`pvalue'"=="pvalue") {
        
        if ( ("`normalize'"=="normalize") | ("`symmetric'"=="symmetric") ) {
            
            display as err "option {bf:pvalue}" ///
                " may not be combined with {bf:normalize} or {bf:symmetric}"
            
            exit 198
            
        }
        
    }
    
    if ("`format'" != "") ///
        confirm numeric format `format'
    
    marksample touse
    
    quietly count if `touse'
    if (r(N) < 2) ///
        error 2000+r(N)
    
    if (`"`rseed'"' != "") ///
        set seed `rseed'
    
    local c_rngstate = c(rngstate)
    
    mata : xicor_estimate()
    
    Matlist , `pvalue' `normalize' `symmetric' format(`format')
    
    return add // Mata's r()
    
    return local rngstate `c_rngstate'
    
end


program Matlist
    
    syntax [ , pvalue NORMALIZE symmetric FORmat(string) ]
    
    if ("`pvalue'" != "pvalue") {
        
        if ("`normalize'" == "normalize") ///
            local matname _normalized
        
        if ("`symmetric'" == "symmetric") ///
            local matname `matname'_sym
        
    }
    else    local matname _pvalue
    
    if ("`format'" == "") ///
        local format %8.4f
    
    display as txt "(Obs=" r(N) ")"
    
    /*
        We need the `version 10` statement below
        to work around a possible bug in `matlist`:
        It seems more recent versions of `matlist`
        mess up the alignment with option `underscore`.
    */
    
    version 10 : matlist r(xi`matname') , format(`format') nodotz underscore
    
end


/*  _________________________________________________________________________
                                                                     Mata  */


version 16.1


mata :


mata set matastrict   on
mata set mataoptimize on


    /*  _____________________________________________________________________
                                                        class declaration  */

class xicor_u {
    
    public :
    
        void                fetch_stata()
        void                setup()
        void                estimate()
        void                return_r()
    
    private :
    
        string  rowvector   varlist
        string  scalar      selectvar
        real    scalar      option_pvalue
        real    scalar      option_normalize
        real    scalar      option_symmetric
        
        real    matrix      XY
        real    scalar      n
        real    scalar      k
        
        real    matrix      P
        real    matrix      R
        real    matrix      L
        real    matrix      U
        real    matrix      V
        
        real    matrix      xi
        real    rowvector   tau2
        
        void                compute_ranks()
        real    matrix      runiform_uniq()
        real    colvector   rank_highest()
        void                estimate_b_se()
        real    scalar      xi_coef()
        void                return_normalize()
        void                return_symmetric()
        void                return_pvalue()
        void                return_xi_pvalue()
}


    /*  _____________________________________________________________________
                                                         member functions  */

void xicor_u::fetch_stata()
{
    varlist             = tokens(st_local("varlist"))
    selectvar           = st_local("touse")
    
    option_pvalue       = (st_local("pvalue")=="pvalue")
    option_normalize    = (st_local("normalize")=="normalize")
    option_symmetric    = (st_local("symmetric")=="symmetric")
}


void xicor_u::setup()
{
    st_view(XY,.,varlist,selectvar)
    
    n = rows(XY)
    k = cols(XY)
    
    P = J(n,k,.)
    R = J(n,k,.)
    L = J(n,k,.)
    U = J(n,k,.)
    V = option_pvalue ? J(n,k,.) : J(0,0,.)
    
    xi      = J(k,k,.)
    tau2    = option_pvalue ? J(1,k,.) : J(1,0,.)
}


void xicor_u::estimate()
{
    compute_ranks()
    estimate_b_se()
}


void xicor_u::compute_ranks()
{
    real matrix T
    real scalar j
    
    
    /*
        We break ties randomly but reproducible
        conditional on c(rngstate), not c(sortseed).
    */
    
    T = runiform_uniq(n,2)
    
    /*
        We rank all variables just once,
        then simply re-index the matrices.
        
        This approach is hopefully fast;
        consumes lots of memory, though.
    */
    
    for (j=k; j; j--) {
        
        P[,j] = order((XY[,j],T),(1..3))                // ties broken randomly
        
        R[P[,j],j] = U[,j] = rank_highest(XY[P[,j],j])  // Y(j) <= Y(i)
        
        L[P[,j],j] = rank_highest(XY[P[n::1,j],j])      // Y(j) >= Y(i)
        
        if ( option_pvalue ) 
            V[,j] = quadrunningsum(U[,j])
        
    }
}


real matrix xicor_u::runiform_uniq(
    
    real scalar r,
    real scalar c
    
    )
{
    real matrix T
    
    
    T = runiform(r,c)
    
    if (rows(uniqrows(T)) != n) {
        
        errprintf("sort order not uniquely determined\n")
        errprintf("try another random seed;  see {helpb seed:[R] set seed}\n")
        
        exit(error(498))
        
    }
    
    return(T)
}


real colvector xicor_u::rank_highest(real colvector Yj)
{
    real colvector uniqrows
    real colvector rank
    
    
    /*
        see StataCorp. uniqrows() 
        *! version 2.0.0  01sep2017
    */
    
    uniqrows    = (1\(Yj[2::n]:!=Yj[1::n-1]))
    rank        = (select((0::n-1),uniqrows)\n)[|2\.|]
    rank        = rank[quadrunningsum(uniqrows),] // sic!; expand to n x 1
    
    return(rank)
}


void xicor_u::estimate_b_se()
{
    real rowvector  a
    real rowvector  b
    real rowvector  c
    real rowvector  d
    real scalar     i, j
    
    
    d = quadcolsum(L:*(n:-L)) // not scaled
    
    for (i=k; i; i--) {
        
        xi[i,i] = xi_coef(R[P[,i],i],d[i])
        
        for (j=(i-1); j; j--) {
            
            xi[i,j] = xi_coef(R[P[,i],j],d[j])  // rows are Xs
            xi[j,i] = xi_coef(R[P[,j],i],d[i])  // cols are Ys
            
        }
        
    }
    
    if ( !option_pvalue )
        return
    
    // Chatterjee (2021, 2011)
    
    a = quadcolsum((2*n :- 2*(1::n) :+ 1) :* U:^2) / n^4
    b = quadcolsum((V :+ (n :- (1::n)) :* U):^2) / n^5
    c = quadcolsum((2*n :- 2*(1::n) :+ 1) :* U) / n^3
    
    tau2 = (a :- 2*b :+ c:^2) :/ (d/n^3):^2
}


real scalar xicor_u::xi_coef(
    
    real colvector Ri, 
    real rowvector di
    
    )
{
   // Chatterjee (2021, 2010)
   
   return( 1 - ((n*quadcolsum(abs(Ri[2::n]-Ri[1::n-1]))) / (2*di)) )
}


void xicor_u::return_r()
{
    st_rclear()
    
    st_numscalar("r(xi_coef)",xi[k-1,k])
    st_numscalar("r(N)",n)
    
    if ( option_pvalue )
        return_pvalue()
    
    if ( option_normalize )
        return_normalize()
    
    if ( option_symmetric )
        return_symmetric()
    
    st_matrix("r(xi)",xi)
    st_matrixcolstripe("r(xi)",(J(k,1,""),varlist'))
    st_matrixrowstripe("r(xi)",(J(k,1,""),varlist'))
}


void xicor_u::return_pvalue()
{
    real rowvector  se0
    real matrix     z
    real matrix     pvalue
    
    
    se0     = sqrt(tau2/n)
    z       = xi:/se0
    pvalue  = 2*normal(-abs(z))
    
    st_matrix("r(z)",z)
    st_matrixcolstripe("r(z)",(J(k,1,""),varlist'))
    st_matrixrowstripe("r(z)",(J(k,1,""),varlist'))
    
    st_matrix("r(pvalue)",pvalue)
    st_matrixcolstripe("r(pvalue)",(J(k,1,""),varlist'))
    st_matrixrowstripe("r(pvalue)",(J(k,1,""),varlist'))
    
    st_matrix("r(xi_pvalue)",colshape((xi,pvalue,J(k,k,.z)),k),"hidden")
    st_matrixcolstripe("r(xi_pvalue)",(J(k,1,""),varlist'))
    st_matrixrowstripe("r(xi_pvalue)",(J(3*k,1,""),colshape((varlist',J(k,2,"_")),1)))
    
    st_matrix("r(tau2)",tau2,"hidden")
    st_matrixcolstripe("r(tau2)",(J(k,1,""),varlist'))
    
    st_matrix("r(se0)",se0,"hidden")
    st_matrixcolstripe("r(se0)",(J(k,1,""),varlist'))
}


void xicor_u::return_normalize()
{   
    real matrix xi_normalized
    
    
    // Dalitz et al. (2024, 551)
    
    xi_normalized = xi:/diagonal(xi)'
    xi_normalized = xi_normalized:*(xi_normalized:>=-1) - (xi_normalized:<-1)
    
    st_matrix("r(xi_normalized)",xi_normalized)
    st_matrixcolstripe("r(xi_normalized)",(J(k,1,""),varlist'))
    st_matrixrowstripe("r(xi_normalized)",(J(k,1,""),varlist'))
}


void xicor_u::return_symmetric()
{
    real    matrix  xi_sym
    string  scalar  r_matname
    real    scalar  i, j
    
    
    /*
        Take the maximum of xi(X,Y) and xi(Y,X)
        (Chatterjee, 2021, 2010)
    */
    
    xi_sym      = option_normalize ? st_matrix("r(xi_normalized)") : xi
    r_matname   = option_normalize ? "r(xi_normalized_sym)" : "r(xi_sym)"
    
    for (i=2; i<=rows(xi_sym); i++) 
        for (j=1; j<i; j++) 
            xi_sym[i,j] = xi_sym[j,i] = max((xi_sym[i,j],xi_sym[j,i]))
    
    st_matrix(r_matname,xi_sym)
    st_matrixcolstripe(r_matname,(J(k,1,""),varlist'))
    st_matrixrowstripe(r_matname,(J(k,1,""),varlist'))
}


    /*  _____________________________________________________________________
                                                          entry point ado  */

void xicor_estimate()
{
    class xicor_u scalar xicor
    
    
    xicor.fetch_stata()
    xicor.setup()
    xicor.estimate()
    xicor.return_r()
}


end


exit


/*  _________________________________________________________________________
                                                              version history

1.0.1   22jun2026   bug fix: option p-value with more than two variables
1.0.0   19may2026   complete rewrite
                    reproducible results, conditional on c(rngstate)
                    new options `pvalue`, `normalize`, `rseed()`, `format()`
                    option `symmetric` now documented
                    addtional returned results
0.3.0   12aug2025   cancel out n^2 in final computation
0.2.0   09aug2024   new option -symmetric-; not documented
0.1.0   30apr2024   bug fix when y is constant
                    change order of results matrix; rows are xs, cols are ys
                    change returned results name: r(Xi) now r(xi)
                    minor refactoring
                    add comments throughout the code
0.0.1   29apr2024   upload to Statalist
                    (https://www.statalist.org/forums/forum/general-stata-discussion/general/1751355-xicor-a-new-coefficient-of-correlation?p=1751606#post1751606)
