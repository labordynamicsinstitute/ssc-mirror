*! lmztest v1.1 CMUrzua 27 May 2022

program lmztest

	version 14
	syntax varname [in] [, mu(real 1)]
	scalar lm = 0
	scalar pv = 0
	mata: lmztest("`varlist'",`mu')
	display as txt " LMZ statistic = " as res lm
	display as txt " p-value = " as res pv

end
 
mata: 
void lmztest(string scalar varname, real scalar mu)
{
	st_view(y=.,.,varname)
	p = (y:-mu):>=0 
	st_select(x,y,p)
	n = rows(x)
	t = x:/min(x)
	z1 = 1-mean(log(t))
	z2 = .5-mean(1:/t)
	lmz = 4*n*((z1^2)+6*(z1*z2)+12*(z2^2))
	pva = 1-chi2(2,lmz)
	st_numscalar("lm",lmz)
	st_numscalar("pv",pva)
}

end

