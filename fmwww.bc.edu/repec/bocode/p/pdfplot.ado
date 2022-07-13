*! version 1.0 28apr2022
program pdfplot 
	version 17
	syntax name(name=dist), params(numlist) [range(passthru)]

	if "`dist'" == "normal" {
		local mu: word 1 of `params'
		local sigma: word 2 of `params'
		
		twoway function y = normalden(x, `mu', `sigma'), `range'
	}
	
	else if "`dist'" == "lnormal" {
		local mu: word 1 of `params'
		local sigma: word 2 of `params'
		
		twoway function y = [exp(-(ln(x) - `mu')^2 / 2 * `sigma'^2)] ///
							/ [sqrt(2 * c(pi)) * x * `sigma'], `range'
	}
			
	else if inlist("`dist'", "sged", "ged", "slaplace", "laplace", "snormal") {
		local sigma: word 1 of `params'
		if "`dist'" == "sged" {
			local p: word 2 of `params'
			local lambda: word 3 of `params'
		}
		else if "`dist'" == "ged" {
			local p: word 2 of `params'
			local lambda = 0
		}
		else if "`dist'" == "slaplace" {
			local p = 1
			local lambda: word 2 of `params'
		}
		else if "`dist'" == "laplace" {
			local p = 1
			local lambda = 0
		}
		else if "`dist'" == "snormal" {
			local p = 1
			local lambda: word 2 of `params'
		}
		local G = exp(lngamma(1/`p'))
		
		twoway function ///
			y = [`p'*exp(-((x-`mu')^`p'/((1+`lambda'*sign(x-`mu'))^`p'*`sigma'^`p')))] ///
				/ [2 * `sigma' * `G'], `range'
	}
	
	else if inlist("`dist'", "sgt", "st", "gt", "t") {
		local sigma: word 1 of `params'
		if "`dist'" == "sgt" {
			local p: word 2 of `params'
			local q: word 3 of `params'
			local lambda: word 4 of `params'
		}
		else if "`dist'" == "st" {
			local p = 2
			local q: word 2 of `params'
			local lambda: word 3 of `params'
		}
		else if "`dist'" == "gt" {
			local p: word 2 of `params'
			local q: word 3 of `params'
			local lambda = 0
		}
		else if "`dist'" == "t" {
			local p = 2
			local q: word 2 of `params'
			local lambda = 0
		}
		local B = exp(lngamma(1/`p')+lngamma(`q')-lngamma(1/`p'+`q'))
		
		twoway function ///
			y = [`p'] ///
				/ [(2*`sigma'*`q'^(1/`p')*`B')*(1+(abs(x-`mu')^`p') ///
				/ (`q'*`sigma'^`p'*(1+`lambda'*sign(x-`mu'))^`p'))^(`q'+1/`p')], ///
				`range'
		}

	else if inlist("`dist'", "ggamma", "gamma", "weibull") {
		if "`dist'" == "ggamma" {
			local a: word 1 of `params'
			local b: word 2 of `params'
			local p: word 3 of `params'
		}
		else if "`dist'" == "gamma" {
			local a = 1
			local b: word 1 of `params'
			local p: word 2 of `params'
		}
		else if "`dist'" == "weibull" {
			local a: word 1 of `params'
			local b: word 2 of `params'
			local p = 1
		}
		local G = exp(lngamma(`p'))
		
		twoway function y = [abs(`a')*(x/`b')^(`a'*`p')*exp(-(x/`b')^`a')] ///
							/ [x*`G'], `range'
	}
	
	else if inlist("`dist'", "gb2", "br12", "br3") {
		local a: word 1 of `params'
		local b: word 2 of `params'
		if "`dist'" == "gb2" {
			local p: word 3 of `params'
			local q: word 4 of `params'
		}
		else if "`dist'" == "br12" {
			local p = 1
			local q: word 3 of `params'
		}
		else if "`dist'" == "br3" {
			local p: word 3 of `params'
			local q = 1
		}
		local B =  exp(lngamma(`p')+lngamma(`q')-lngamma(`p'+`q'))
		
		twoway function y = [abs(`a') * (x/`b')^(`a'*`p')] ///
							/ [x*(`B') * (1 + (x/`b')^`a')^(`p'+`q')], `range'
	}
	
	else {
		display as error "distribution not recognized; use one of the " ///
			"following: gb2, br12, br3, gamma, ggamma, weibull, sgt, gt, " ///
			"st, sged, ged, laplace, slaplace, t, normal, snormal, lognormal"
		exit 498
	}

end