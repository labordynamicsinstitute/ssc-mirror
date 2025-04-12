local scheme = cond(c(version) >= 18, "stcolor", "s1color")
set scheme `scheme'

clear
input float(x y)
1 1
2 2
2 1
3 1
1 2
4 2
1 1
2 1
3 1
1 2
2 2
4 2
1 1
2 1
3 1
4 1
0 2
2 2
3 2
5 2
end

local opts yline(1 2, lc(gs8) lw(thin) lp(solid)) ysc(r(0.5 2.5)) yla(none) xla(none) xtitle("") ytitle("")

scatter y x in 1/2 , `opts'  xsc(r(0.5 2.5)) subtitle(subsamples of 1 indicate level, size(large)) name(sub1, replace)

scatter y x in 3/6 , `opts'  xsc(r(0.5 4.5)) subtitle(subsamples of 2 indicate spread, size(large)) name(sub2, replace)

scatter y x in 7/12 , `opts'  xsc(r(0.5 4.5)) subtitle(subsamples of 3 indicate (a)symmetry, size(large)) name(sub3, replace)

scatter y x in 13/20 , `opts'  xsc(r(-1 6)) subtitle(subsamples of 4 indicate tail weight, size(large)) name(sub4, replace)

graph combine sub1 sub2 sub3 sub4, l1title(different samples) b2title(variable under analysis) name(sub, replace)

graph drop sub1 sub2 sub3 sub4 

local opt xtitle("") ytitle("") xla(0 "0" 1 "1" 0.2(0.2)0.8, format(%02.1f))
twoway function 1, `opt' yla(1) subtitle(1, size(large)) name(qc1, replace)
local opt `opt' yline(0, lp(solid) lc(gs8))
twoway function 2*x - 1, `opt' subtitle(2, size(large)) name(qc2, replace)
twoway function 6*x^2 - 6*x + 1, `opt' subtitle(3, size(large)) name(qc3, replace)
twoway function 20*x^3 - 30*x^2 + 12*x - 1, `opt' subtitle(4, size(large)) name(qc4, replace)
graph combine qc1 qc2 qc3 qc4, l1title(Weights) b2title(Probability {it:p}) name(qc, replace)

graph drop qc1 qc2 qc3 qc4 

mata : 

mata clear 

real matrix bweights (real scalar n, real scalar k) { 
	return(editmissing(comb((0::n-1), (0..k-1)) :/ comb(n-1, (0..k-1)), 0))  
} 	

real matrix pweights(real scalar k) { 
	real matrix w
	real scalar i, j  
	w = J(k, k, .) 

	for(i = 0; i < k; i++) { 
		for(j = 0; j < k; j++) {
			w[i+1,j+1] = (-1)^(j-i) * exp(lnfactorial(j+i) - 2 * lnfactorial(i) - lnfactorial(j-i)) 
		}
	}

	return(editmissing(w, 0))
} 

real matrix lmocoeff(real scalar n, real scalar k) { 
	return(bweights(n, k) * pweights(k)) 
}

end 

mata : coeff = lmocoeff(19, 4)

clear 

getmata (w1 w2 w3 w4) = coeff 

gen i = _n 

local opt yla(0 1)

forval j = 1/4 { 
	twoway dropline w`j' i, `opt' yla(, ang(v)) xla(1 4 7 10 13 16 19) xtitle("") ytitle("") name(qd`j', replace) subtitle(`j', size(large))
	local opt 
}

graph combine qd1 qd2 qd3 qd4, l1title(Weights) b1title(Ranks 1 .. 19) name(qd, replace)

graph drop qd1 qd2 qd3 qd4 
