// Author: Federico Belotti
//         Giuseppe Ilardi
// Tor Vergata University
// Faculty of Economics
// Rev. 1.0 - 09/2009

version 10
capture mata: mata drop rtnorm() 

mata

real function rtnorm(real scalar nrow, 
					 real scalar ncol, 
					 real rowvector mean, 
					 real rowvector sd, 
					 real rowvector lower, 
					 real rowvector upper) 
{
   real rowvector  res,u
   real matrix zlower, zupper
   real scalar pseudocol
   	
    if ((cols(mean)!=cols(sd)) |
       (cols(mean)!=cols(lower)) |
       (cols(mean)!=cols(upper)) |
       (cols(sd)!=cols(lower)) |
       (cols(sd)!=cols(upper)) |
       (cols(lower)!=cols(upper))) {
       errprintf("mean, standard deviation, lower or upper parameter vectors nonconform!\n")
       exit(198)
	}
	
	if (nrow<=0) {
       errprintf("row specification must be a nonnegative integer!\n")
       exit(198)
	}
	if (ncol<=0) {
       errprintf("col specification must be a nonnegative integer!\n")
       exit(198)
	}

	zlower = J(nrow,ncol,((lower :- mean) :/ sd))
	zupper = J(nrow,ncol,((upper :- mean) :/ sd))
	
	if ((cols(mean)>1) & (ncol>1)) pseudocol = ncol * cols(mean)
	else pseudocol = ncol
	
	u = normal(zlower) :+ (normal(zupper) :- normal(zlower)) :* runiform(nrow, pseudocol)
	
	res = J(nrow,ncol,mean) :+ J(nrow,ncol,sd) :* invnormal(u)
	return(res)
}

mata mosave rtnorm(), dir(PERSONAL) replace
// mata clear

end



