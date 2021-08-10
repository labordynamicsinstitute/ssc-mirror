*! Part of package matrixtools v. 0.27
*! Support: Niels Henrik Bruun, nbru@rn.dk

capture program drop filaby
program define filaby, sortpreserve
    syntax varlist(min=2 max=2), MAXdist(integer) [Stub(string)]
    tokenize `"`varlist'"'

    mata: st_local("is_str", strofreal(st_isstrvar(`"`2'"')))
    if  `is_str'  mata: _error("Second variable must be numeric")

    sort `varlist'
    
    mata: st_local("is_str", strofreal(st_isstrvar(`"`1'"')))
    if `is_str' {
        tempvar num`1' 
        encode `1', generate(`num`1'')
        local 1 `num`1''
    }
    
    mata: filaby(`"`1' `2'"', `maxdist', "`stub'")
end

mata:
    void filaby(string scalar varlist, real scalar maxdist, string scalar stub)
    {
        data = st_data(., varlist)
        R = rows(data)
        first_last = J(R,2,0)
        for(r=1;r<=R;r++) {
            // Finding block start (r) and end (r2)
            for(r2=r;r2<R;r2++){
                if ( data[r2+1,1] != data[r2,1] ) break
                if ( data[r2+1,2] - data[r,2] > maxdist ) break
            }
            first_last[r, 1] = 1
            first_last[r2, 2] = 1
            r = r2
        }
        nhb_sae_addvars((stub + "_first", stub + "_last"), first_last)
    }
end
