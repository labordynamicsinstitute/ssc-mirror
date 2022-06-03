*! pwlaw v1.2 CMUrzua 27 May 2022

program pwlaw

	version 14
	syntax varname [in] [, mu(real 1)]
	scalar pw = 0
	scalar pv = 0
	mata: pwlaw("`varlist'",`mu')
	display as txt " PWL statistic = " as res pw
	display as txt " p-value = " as res pv
	display as txt " alpha_hat = " as res al

end

mata: 
void pwlaw(string scalar varname, real scalar mu)
{
	st_view(y=.,.,varname)
	p = (y:-mu):>0 
	st_select(x,y,p)
	n = rows(x)
	t = x:/mu
	u = log(t:-1)
	alpha = 1/mean(log(t))
	d1 = n*alpha/mu-(alpha+1)*sum(1:/x)
	d2 = -n+alpha*sum(u)-(alpha+1)*sum(u:/t)
	d = d1\d2\0
	p = digamma(alpha)-digamma(1)-1
	q = trigamma(alpha)+trigamma(1)
	i1 = alpha/(mu^2*(alpha+2))
	i2 = -(alpha*p+1)/(mu*(alpha+2))
	i3 = -1/(mu*(alpha+1))
	j2 = (alpha*(p^2+q)+2*(p+1))/(alpha+2)
	j3 = p/(alpha+1)
	k3 = 1/(alpha^2)
	h = (i1,i2,i3\i2,j2,j3\i3,j3,k3)
	pwl = d'*cholsolve(h,d)/n
	pva = 1-chi2(2,pwl)
	st_numscalar("pw",pwl)
	st_numscalar("pv",pva)
	st_numscalar("al",alpha)
}

end

