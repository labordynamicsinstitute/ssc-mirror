mata:
function totalhf${i}(tnodes,expxb,tdexb,hvars,lt,time0) 
{
	hf = ${totalhazard${i}}
	if (min(hf)<0) {
		errprintf("Negative hazard\n")
		exit(198)
	}
	return(hf)
}
end
