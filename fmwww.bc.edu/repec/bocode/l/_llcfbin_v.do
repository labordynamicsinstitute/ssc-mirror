** BUILD EVALUATOR FUNCTION TO BE USED BY deriv()
cap mata : mata drop _D 
cap mata : mata drop llcfbin_v()
cap mata : mata drop llcflogit_v()
cap mata : mata drop llcfprobit_v()
cap mata : mata drop llcfcloglog_v()
mata
: void llcfbin_v(c, _Y, _EXOGVARS, _XVARS, nfirststage, order, string link, lnf)
{
	if (link == "logit") return(llcflogit_v(c, _Y, _EXOGVARS, _XVARS, nfirststage, order, lnf))
	if (link == "probit") return(llcfprobit_v(c, _Y, _EXOGVARS, _XVARS, nfirststage, order, lnf))
	if (link == "cloglog") return(llcfcloglog_v(c, _Y, _EXOGVARS, _XVARS, nfirststage, order, lnf))
}
void llcflogit_v(c, _Y, _EXOGVARS, _XVARS, nfirststage, order, lnf)
{
	cols2s = cols(_XVARS) + order*nfirststage
	cols2sorg = cols2s - order*nfirststage
	const2s = c[1,cols2s] 
	_betacoefsorg = c[1,(1::(cols2sorg-1))] 
	_betacoefsorg = (_betacoefsorg,const2s)
	_betacoefsres = c[1,(cols2sorg::(cols2sorg+order*nfirststage))]
	_alfacoefs = c[1,((cols2s+1)::cols(c))]
	${cflist}
	lnf = _Y :* ln(logistic(_XVARS*_betacoefsorg' ${cfll})) :+ (1 :- _Y) :* ln(1 :- (logistic(_XVARS*_betacoefsorg' ${cfll}))) 
 }
void llcfprobit_v(c, _Y, _EXOGVARS, _XVARS, nfirststage, order, lnf)
{
	cols2s = cols(_XVARS) + order*nfirststage
	cols2sorg = cols2s - order*nfirststage
	const2s = c[1,cols2s] 
	_betacoefsorg = c[1,(1::(cols2sorg-1))] 
	_betacoefsorg = (_betacoefsorg,const2s)
	_betacoefsres = c[1,(cols2sorg::(cols2sorg+order*nfirststage))]
	_alfacoefs = c[1,((cols2s+1)::cols(c))]
	${cflist}
	lnf = _Y :* ln(normal(_XVARS*_betacoefsorg' ${cfll})) :+ (1 :- _Y) :* ln(1 :- (normal(_XVARS*_betacoefsorg' ${cfll}))) 
 }
void llcfcloglog_v(c, _Y, _EXOGVARS, _XVARS, nfirststage, order, lnf)
{
	cols2s = cols(_XVARS) + order*nfirststage
	cols2sorg = cols2s - order*nfirststage
	const2s = c[1,cols2s] 
	_betacoefsorg = c[1,(1::(cols2sorg-1))] 
	_betacoefsorg = (_betacoefsorg,const2s)
	_betacoefsres = c[1,(cols2sorg::(cols2sorg+order*nfirststage))]
	_alfacoefs = c[1,((cols2s+1)::cols(c))]
	${cflist}
	lnf = _Y :* ln(1 :-exp(-exp(_XVARS*_betacoefsorg' ${cfll}))) :+ (1 :- _Y) :* ln(exp(-exp(_XVARS*_betacoefsorg' ${cfll}))) 
 }
end 
