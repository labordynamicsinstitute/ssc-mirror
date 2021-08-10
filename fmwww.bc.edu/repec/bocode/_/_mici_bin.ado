*! version 1.1  Thursday, July 3, 2003 at 12:21

program define _mici_bin, rclass
    version 7

    syntax [varlist(max=1)] [if] [in] [, Level(integer $S_level) binomial]

    qui sum `1' `if' `in'
    local n = r(N)
    local k = int(r(mean)*r(N)+.5)
    ret scalar N = `n'
    ret scalar mean = `k'/`n'
    ret scalar se=sqrt((return(mean)*(1-return(mean)))/`n')
    local z=invnorm((100+`level')/200)
    ret scalar lb=return(mean)-`z'*return(se)
    ret scalar ub=return(mean)+`z'*return(se)

    di in ye _col(20) return(N) _col(33) return(mean) _col(40) return(se) /*
    */ _col(56) return(lb) _col(68) return(ub)

end
/*
       - _mici_bin x-  produces the same mean and se as produced
       by - ci x, bin-. But - _mici_bin x- produces a normal distributed
       CI using invnorm(1-(100-`level')/2), while -ci x, bin-
       uses binomial distribution in calculating CI:
          lb = invbinomial(n, k, (100-`level')/200)
      ub = invbinomial(n, k, 1-(100-`level')/200).
*/
