


program define titebeta, rclass

* Titbeta, v1.1
* Varlist: Toxicity events (0/1) first, and then elapsed time from 0 to maximum time

* Stata v 16 is the earliest with MATA quadrature
version 16.0

syntax varlist(min=2 max=2 numeric) [, MAXTime(real 180) TOXmax(real 0.3)  /// 
 a(real 1) b(real 2) PPRBound(real 0.9) userwt(string ) wtpwr(numlist max=1 >0 )] 
 

 
 if "`wtpwr'"=="" {
 	local wtpwr=1
 }
 
qui{
	
preserve

local 2 : subinstr local 2 "," "", all
di "`2'"

if "`userwt'" > "" {
	gen _wt=`userwt'
	return local user_weight_var "`userwt'"

}
else {
gen _wt=(`2' / `maxtime')^`wtpwr'

*replace _wt=_wt //`maxtime' 

replace _wt =1 if `1'==1
replace _wt =1 if _wt>1

}

* Pull the toxicity and _wt data vectors in to Mata
mata mata clear
putmata `1' _wt, replace

* Call the quadrature function in mata, and calculate the posterior tail probability
mata qden=Integrate_bppdf(0,1)
mata qnum=Integrate_bppdf(`toxmax',1)
mata: spprob=strofreal(qnum/qden)

mata: st_global("pprob",spprob)

}


di
di
di "sample = " _N "   a=`a'    b=`b'   target toxicity rate="`toxmax'*100 "%"
di "Posterior probability of exceeding " `toxmax'*100 "% toxicity is " $pprob

if $pprob <`pprbound' {
di "Posterior probability does not exceed limit of " `pprbound' ", continue accrual"
return local decision "Continue Accrual"

}
else {
di "Posterior probability exceeds limit of " `pprbound' ", stop accrual"
return local decision "Pause or Halt Study"

}
di


return local toxvar "`1'"
return local timevar "`2'"

return scalar beta_a = `a'
return scalar beta_b = `b'
return scalar maxtime = `maxtime'
return scalar toxmax = `toxmax'
return scalar ppr_bound = `pprbound'
return scalar weight_power = `wtpwr'


return scalar pprob = $pprob
ma drop pprob


end
 
* Function to be integrated.
* "external" makes data vectors visible from inside the function.
mata:
 real scalar bppdf(real scalar x)
 { 	
 	external _wt
 	external toxicity

 ones=J(length(_wt), 1,1)
 omtox=1:-toxicity
 toxouts=exp(ones'*(log(x:^toxicity)))
 omwtstarx=1:-(_wt:*x)
 notox=exp(ones'*(log(omwtstarx:^omtox)))
 
 a=strtoreal(st_local("a"))
 ax=x^(a-1)
 b=strtoreal(st_local("b"))
 bx=(1-x)^(b-1)

	    return(toxouts*notox*ax*bx)
 }
end


* Call the quadrature function, integrating from x0 to x1
* Variable x represents the toxicity probability.

mata:
real scalar Integrate_bppdf(real scalar x0, real scalar x1)
{
    class Quadrature scalar q
    q.setEvaluator(&bppdf())
    q.setLimits((x0, x1))
    return(q.integrate())
}
end

/*
