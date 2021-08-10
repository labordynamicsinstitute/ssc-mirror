*! 0.1 HS, Feb 22, 2017


pr define wtdpreddur, rclass
version 14.0

syntax newvarlist(max=1) [if] [in], ///
                [ IADPercentile(real 0.8) ]
	qui {
		tokenize `varlist'
		local rxdur `1'
		local disttype = r(disttype)

		if "`disttype'" == "exp" {
			tempname lnbeta
			predict `lnbeta', eq(lnbeta)
			
			gen `rxdur' = - log(1 - `iadpercentile') / exp(`lnbeta')
			}
		
		if "`disttype'" == "lnorm" {
			tempname mu lnsigma
			predict `mu', eq(mu)
			predict `lnsigma', eq(lnsigma)
			
			gen `rxdur' = exp(invnormal(`iadpercentile') * exp(`lnsigma') + `mu')
			}
		
		
		if "`disttype'" == "wei" {
			tempname lnbeta lnalpha
			predict `lnbeta', eq(lnbeta)
			predict `lnalpha', eq(lnalpha)
			
			gen `rxdur' = (- log(1 - `iadpercentile'))^(1 / exp(`lnalpha')) ///
			  / exp(`lnbeta')
			}
		}
end

