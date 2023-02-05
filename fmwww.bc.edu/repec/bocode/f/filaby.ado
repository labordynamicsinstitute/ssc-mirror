*! Part of package matrixtools v. 0.30
*! Support: Niels Henrik Bruun, nbru@rn.dk

*capture program drop filaby
program define filaby, sortpreserve
    syntax varlist(min=2 max=2), MAXdist(integer) [Stub(string)]
    tokenize `"`varlist'"'

    mata: st_local("is_str", strofreal(st_isstrvar(`"`2'"')))
    if  `is_str'  mata: _error("Second variable must be numeric")

    sort `varlist'
    
    mata: st_local("is_str", strofreal(st_isstrvar(`"`1'"')))
    if `is_str' {
        tempvar id 
        generate `id' = _n
        bysort `1' (`2'): replace `id' = `id'[1]
        local 1 `id'
    }
    
    mata: filaby(`"`1' `2'"', `maxdist', "`stub'")
end

mata:
    void filaby(string scalar varlist, real scalar maxdist, string scalar stub)
    {
      real scalar R, r, r2, first_last
      real matrix data
      
      
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


exit

capture program drop filaby
clear
set obs 200000
set seed 123
generate id = string(_n, "%06.0f")
generate date1 = runiformint(mdy(1,1,2010), mdy(12,31,2020))
format %tdCCYY-NN-DD date1
generate exp = runiformint(1,10)
expand exp
drop exp
generate time = runiformint(1,6)
bysort id: replace time = sum(time)
*hist time
*su time
generate date = date1 + time
format %tdCCYY-NN-DD date
drop time date1
bysort id (date): generate dieddt = cond(runiform() < 0.10, date[_N] + runiformint(0,5), .)
bysort id (dieddt): replace dieddt = dieddt[1]
format %tdCCYY-NN-DD dieddt

filaby id date, maxdist(5) stub(my)

generate died_within_7_days = dieddt - date < 8 & my_last
bysort id died_within_7_days: generate N = _N if died_within_7_days
sort id date
bysort id (date): generate diedlow = dieddt - date[1] < 8
bysort id (date): generate diedhigh = dieddt - date[_N] < 8
tab N