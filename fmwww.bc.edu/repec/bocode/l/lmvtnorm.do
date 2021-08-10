version 12.1
mata:
mata clear
 
real scalar mvnormalden_mata(real vector x, real vector mean, real matrix Sigma)
{
  // Perform checks on input variables
  if (rows(Sigma) ~= cols(Sigma)) {
    "{error} Covariance matrix Sigma (Sigma) must be square."
    exit(198)
  }
  if (length(x) ~= length(mean)) {
    "{error} Vector of quantiles (x) and mean vector (mean) must be of equal length."
    exit(198)
  }
  if (length(mean) ~= cols(Sigma)) {
    "{error} Mean vector (mean) must be the same length as the dimension of covariance matrix Sigma (sigma)."
    exit(198)
  }
  // Initialise all required variables
  C          = cholesky(Sigma)
  k          = rows(C)
  // Compute density
  tmp        = lusolve(C, (x :- mean)')
  rss        = colsum(tmp:^2)
  logdensity = -sum(log(diagonal(C))) - 0.5*k*log(2*pi()) - 0.5*rss
  density    = exp(logdensity)
  // Return result
  return(density)
}

real scalar mvtden_mata(real vector x, real vector delta, real matrix Sigma, real scalar df)
{
  // Perform checks on input variables
  if (rows(Sigma) ~= cols(Sigma)) {
    "{error} Scale matrix Sigma (Sigma) must be square."
    exit(198)
  }
  if (length(x) ~= length(delta)) {
    "{error} Vector of quantiles (x) and vector of non-centrality parameters (delta) must be of equal length."
    exit(198)
  }
  if (length(delta) ~= cols(Sigma)) {
    "{error} Vector of non-centrality parameters (delta) must be the same length as the dimension of scale matrix Sigma (Sigma)."
    exit(198)
  }
  if ((df < 1) | (mod(df, 1) ~= 0)) {
    "{error} Degree of freedom (df) must be a positive integer."
    exit(198)
  }
  // Initialise all required variables
  C          = cholesky(Sigma)
  k          = rows(C)
  // Compute density
  tmp        = lusolve(C, (x :- delta)')
  rss        = colsum(tmp:^2)
  logdensity = lngamma((df + k)/2) - (lngamma(df/2) + sum(log(diagonal(C))) +
                 (k/2)*log(pi()*df)) - 0.5*(df + k)*log(1 + (rss/df))
  density    = exp(logdensity)
  // Return result
  return(density)
}

real matrix rmvnormal_mata(real scalar n, real vector mean, real matrix Sigma)
{
  // Perform checks on input variables
  if (rows(Sigma) ~= cols(Sigma)) {
    "{error} Covariance matrix Sigma (Sigma) must be square."
    exit(198)
  }
  if (length(mean) ~= cols(Sigma)) {
    "{error} Mean vector (mean) must be the same length as the dimension of covariance matrix Sigma (sigma)."
    exit(198)
  }
  if ((n < 1) | (mod(n, 1) ~= 0)) {
    "{error} Number of random vectors to generate (n) must be a strictly positive integer."
    exit(198)
  }
  // Initialise all required variables
  C                  = cholesky(Sigma)
  k                  = rows(C)
  // Initialise a matrix with each row the vector mean
  meanmat            = J(n, k, 0)
  for (i = 1; i <= n; i++) {
    meanmat[i, 1::k] = mean
  }
  // Create a matrix of random N(0,1) variables
  z                  = J(k, n, 0)
  for (i = 1; i <= k; i++) {
    for (j = 1; j <= n; j++) {
	  z[i, j]        = rnormal(1, 1, 0, 1)
    }
  }
  // Create a matrix of random MVN vectors with distirbution MVN(mean, Sigma)
  rmvnormal          = (C*z)' + meanmat
  // Return result
  return(rmvnormal)
}

real matrix rmvt_mata(real scalar n, real vector delta, real matrix Sigma, real scalar df)
{
  // Perform checks on input variables
  if (rows(Sigma) ~= cols(Sigma)) {
    "{error} Scale matrix Sigma (Sigma) must be square."
    exit(198)
  }
  if (length(delta) ~= cols(Sigma)) {
    "{error} Vector of non-centrality parameters (delta) must be the same length as the dimension of scale matrix Sigma (Sigma)."
    exit(198)
  }
  if ((n < 1) | (mod(n, 1) ~= 0)) {
    "{error} Number of random vectors to generate (n) must be a strictly positive integer."
    exit(198)
  }
  if ((df < 1) | (mod(df, 1) ~= 0)) {
    "{error} Degree of freedom (df) must be a positive integer."
    exit(198)
  }
  // Initialise all required variables
  C                   = cholesky(Sigma)
  k                   = rows(C)
  // Initialise a matrix with each row the vector delta
  deltamat            = J(n, k, 0)
  for (i = 1; i <= n; i++) {
    deltamat[i, 1::k] = delta
  }
  // Create a matrix of random normal variables and a vector of random chi2
  // variables
  z                   = J(k, n, 0)
  rchi2               = J(n, 1, 0)
  for (i = 1; i <= n; i++) {
    for (j = 1; j <= k; j++) {
	  z[j, i]         = rnormal(1, 1, 0, 1)
	}
	rchi2[i]          = rchi2(1, 1, df)
  }
  // Create a matrix of random multivariate normal vectors with distribution
  // MVN(0, Sigma)
  rmvnormal           = (C*z)'
  // Create a matrix of the desired multivariate t vectors with distribution
  // MVT(delta, Sigma)
  rmvt                = rmvnormal:/sqrt(rchi2/df) + deltamat
  // Return result
  return(rmvt)
}

real vector mvnormal_mata(real vector lower, real vector upper, real vector mean, real matrix Sigma,| real scalar M, real scalar N, real scalar alpha)
{
  // Check if optional arguments have been specified
  if (args() < 7) {
    M     = 12
    N     = 1000
    alpha = 3
  }
  // Perform checks on input variables
  if (cols(Sigma) ~= rows(Sigma)) {
    "{error} Covariance matrix Sigma (Sigma) must be square."
    exit(198)
  }
  if (length(lower) ~= length(upper)) {
    "{error} Vector of lower limits (lower) and vector of upper limits (upper) must be of equal length."
    exit(198)
  }
  if (length(lower) ~= length(mean)) {
    "{error} Mean vector (mean) and vector of lower limits (lower) must be of equal length."
    exit(198)
  }
  if (length(mean) ~= cols(Sigma)) {
    "{error} Mean vector (mean) must be the same length as the dimension of covariance matrix Sigma (Sigma)."
    exit(198)
  }
  if (length(mean) > 100) {
    "{error} Only multivariate normal distributions of dimension up to 100 are supported."
    exit(198)
  }
  for (i = 1; i <= length(lower); i++) {
    if ((lower[i] ~= .) & (upper[i] ~= .)) {
      if (lower[i] > upper[i]) {
        "{error} Each lower integration limit (in lower) must be strictly less than the corresponding upper limit (in upper)."
        exit(198)
      }
    }
  }
  if ((M < 1) | (mod(M, 1) ~= 0)) {
    "{error} Number of shifts of the Quasi-Monte-Carlo integration algorithm to use (M) must be a strictly positive integer."
    exit(198)
  }
  if ((N < 1) | (mod(N, 1) ~= 0)) {
    "{error} Number of samples to use in each shift of the Quasi-Monte-Carlo integration algorithm (N) must be a strictly positive integer."
    exit(198)
  }
  if (alpha <= 0) {
    "{error} Chosen Monte-Carlo confidence factor (alpha) must be strictly positive."
    exit(198)
  }
  // Initialise all required variables
  k = rows(Sigma)
  // If we're dealing with the univariate or bivariate normal case use the
  // standard functions
  if (k == 1) {
    if (lower == .) {
	  lower = -8e+307
	}
	if (upper == .) {
	  upper = 8e+307
	}
    I = normal((upper - mean)/sqrt(Sigma)) - normal((lower - mean)/sqrt(Sigma))
    E = 0
  }
  else if (k == 2) {
    for (i = 1; i <= 2; i++) {
	  if (lower[i] == .) {
	    lower[i] = -8e+307
	  }
	  if (upper[i] == .) {
	    upper[i] = 8e+307
	  }
	}
	I = binormal((upper[1] - mean[1])/sqrt(Sigma[1, 1]),
	             (upper[2] - mean[2])/sqrt(Sigma[2, 2]),
	             Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2])) +
		  binormal((lower[1] - mean[1])/sqrt(Sigma[1, 1]),
				   (lower[2] - mean[2])/sqrt(Sigma[2, 2]),
				   Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2])) -
		    binormal((upper[1] - mean[1])/sqrt(Sigma[1, 1]),
			  	     (lower[2] - mean[2])/sqrt(Sigma[2, 2]),
				     Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2])) -
			  binormal((lower[1] - mean[1])/sqrt(Sigma[1, 1]),
				       (upper[2] - mean[2])/sqrt(Sigma[2, 2]),
				       Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2]))	   
	E = 0
  }
  // If we're dealing with an actual multivariate case then use the
  // Quasi-Monte-Carlo Randomised-Lattice Separation-Of-Variables method
  else if (k > 2) {
    // Algorithm is for the case with 0 means, so adjust lower and upper
    // and then re-order variables for maximum efficiency
    a         = lower - mean
    b         = upper - mean
    C         = J(k, k, 0)
    y         = J(1, k - 1, 0)  
    atilde    = J(1, k - 1, 0)
    btilde    = J(1, k - 1, 0)
    atilde[1] = a[1]
    btilde[1] = b[1]
    // Loop over each column of Sigma
    for (i = 1; i <= k - 1; i++) {
      // Determine variate with minimum expectation
	  args = J(1, k - i + 1, 0)
      for (j = 1; j <= k - i + 1; j++){
        s = j + i - 1
	    if (i > 1) {
	      if ((a[s] ~= .) & (b[s] ~= .)) {
		    args[j] = normal((b[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                               sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2))) -
                        normal((a[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                                 sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2)))
          }
          else if ((a[s] == .) & (b[s] ~= .)) {
	        args[j] = normal((b[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                               sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2))) 
          }
          else if ((b[s] == .) & (a[s] ~= .)) {
  	        args[j] = 1 - normal((a[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                                   sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2)))
          }
          else if ((a[s] == .) & (b[s] == .)) {
	        args[j] = 1
          }
        } 
        else {
          if ((a[s] ~= .) & (b[s] ~= .)) {
            args[j] = normal(b[s]/sqrt(Sigma[1, 1])) -
                        normal(a[s]/sqrt(Sigma[1, 1])) 
          }
          else if ((a[s] == .) & (b[s] ~= .)) {
            args[j] = normal(b[s]/sqrt(Sigma[1, 1])) 
          }
          else if ((b[s] == .) & (a[s] ~= .)) {
            args[j] = 1 - normal(a[s]/sqrt(Sigma[1, 1])) 
          }
          else if ((a[s] == .) & (b[s] == .)) {
            args[j] = 1
          }
        }
      }
      minindex(args, 1, ii, ww)
      m = i - 1 + ii[1]
      // Change elements m and i of a, b, Sigma and C
      tempa    = a
      tempb    = b
      tempa[i] = a[m]
      tempa[m] = a[i]
      a        = tempa
      tempb[i] = b[m]
      tempb[m] = b[i]
      b        = tempb
      tempSigma          = Sigma
      tempSigma[i, 1::k] = Sigma[m, 1::k]
      tempSigma[m, 1::k] = Sigma[i, 1::k]
      Sigma              = tempSigma
      Sigma[1::k, i]     = tempSigma[1::k, m]
      Sigma[1::k, m]     = tempSigma[1::k, i]
      if (i > 1){
        tempC          = C
        tempC[i, 1::k] = C[m, 1::k]
        tempC[m, 1::k] = C[i, 1::k]
        C              = tempC
        C[1::k, i]     = tempC[1::k, m]
        C[1::k, m]     = tempC[1::k, i]
        // Compute next column of C and next value of atilda and btilda
        C[i, i]        = sqrt(Sigma[i, i] - sum(C[i, 1::(i - 1)]:^2))
        for (s = i + 1; s <= k; s++){
          C[s, i]      = (Sigma[s, i] - sum(C[i, 1::(i - 1)]:*C[s, 1::(i - 1)]))/
                           C[i, i]
        }
        atilde[i]      = (a[i] - sum(C[i, 1::(i - 1)]:*y[1::(i - 1)]))/C[i, i]
        btilde[i]      = (b[i] - sum(C[i, 1::(i - 1)]:*y[1::(i - 1)]))/C[i, i]
      } else {
        C[i, i]        = sqrt(Sigma[i, i])
        C[2::k, i]     = Sigma[2::k, i]/C[i, i]
      }
      // Compute next value of y using normalden
      y[i]  = (normalden(atilde[i]) - normalden(btilde[i]))/
                (normal(btilde[i]) - normal(atilde[i]))
    }
    // Set the final element of C
    C[k, k] = sqrt(Sigma[k, k] - sum(C[k, 1::(k - 1)]:^2))
    // List of the first 100 primes to use in the integration algorithm
    p = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67,
         71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139,
         149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223,
         227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293,
         307, 311, 313, 317, 331, 337, 347, 349, 353, 359, 367, 373, 379, 383,
         389, 397, 401, 409, 419, 421, 431, 433, 439, 443, 449, 457, 461, 463,
         467, 479, 487, 491, 499, 503, 509, 521, 523, 541)
    // Initialise all required variables
    I   = 0
    V   = 0 
    sqp = p[1::(k - 1)]:^0.5
    d   = J(1, k, 0)
    e   = J(1, k, 1)
    f   = J(1, k, 0)
    // First elements of d, e and f are always the same
    if (a[1] ~= .) {
      d[1] = normal(a[1]/C[1, 1])
    }
    if (b[1] ~= .) {
      e[1] = normal(b[1]/C[1, 1])
    }
    f[1] = e[1] - d[1]
    // Perform M shifts of the Quasi-Monte-Carlo integration algorithm
    for (i = 1; i <= M; i++) {
      Ii = 0
      // We require k - 1 random uniform numbers
      Delta = runiform(1, k - 1)
      // Use N samples in each shift
      for (j = 1; j <= N; j++) {
        // Loop to compute other values of d, e and f
        for (l = 2; l <= k; l++) {
          y[l - 1] = invnormal(d[l - 1] +
                       abs(2*(mod(j*sqp[l - 1] + Delta[l - 1], 1)) - 1)*
                         (e[l - 1] - d[l - 1]))
          if (a[l] ~= .) {
            d[l]   = normal((a[l] - sum(C[l, 1::(l - 1)]:*y[1::(l - 1)]))/C[l, l])
          }
          if (b[l] ~= .) {
            e[l]   = normal((b[l] - sum(C[l, 1::(l - 1)]:*y[1::(l - 1)]))/C[l, l])
          }
          f[l]     = (e[l] - d[l])*f[l - 1]
        }
        Ii         = Ii + (f[k] - Ii)/j
      }
      // Update the values of the variables
      delta = (Ii - I)/i
      I     = I + delta
      V     = (i - 2)*V/i + delta^2
      E     = alpha*sqrt(V)
    }
  }
  // Return result
  return((I, E))
}

real vector mvt_mata(real vector lower, real vector upper, real vector delta, real matrix Sigma, real scalar df,| real scalar M, real scalar N, real scalar alpha)
{
  // Check if optional arguments have been specified
  if (args() < 8) {
    M     = 12
    N     = 1000
    alpha = 3
  }
  // Perform checks on input variables
  if (cols(Sigma) ~= rows(Sigma)) {
    "{error} Scale matrix Sigma (Sigma) must be square."
    exit(198)
  }
  if (length(lower) ~= length(upper)) {
    "{error} Vector of lower limits (lower) and vector of upper limits (upper) must be of equal length."
    exit(198)
  }
  if (length(lower) ~= length(delta)) {
    "{error} Vector of lower limits (lower) and vector of non-centrality parameters (delta) must be of equal length."
    exit(198)
  }
  if (length(delta) ~= cols(Sigma)) {
    "{error} Vector of non-centrality parameters (delta) must be the same length as the dimension of scale matrix Sigma (sigma)."
    exit(198)
  }
  if (length(delta) > 100) {
    "{error} Only multivariate t distributions of dimension up to 100 are supported."
    exit(198)
  }
  for (i = 1; i <= length(lower); i++) {
    if ((lower[i] ~= .) & (upper[i] ~= .)) {
      if (lower[i] > upper[i]) {
        "{error} Each lower integration limit (in lower) must be strictly less than the corresponding upper limit (in upper)."
        exit(198)
      }
    }
  }
  if ((df < 1) | (mod(df, 1) ~= 0)) {
    "{error} Degree of freedom (df) must be a positive integer."
    exit(198)
  }
  if ((M < 1) | (mod(M, 1) ~= 0)) {
    "{error} Number of shifts of the Quasi-Monte-Carlo integration algorithm to use (M) must be a strictly positive integer."
    exit(198)
  }
  if ((N < 1) | (mod(N, 1) ~= 0)) {
    "{error} Number of samples to use in each shift of the Quasi-Monte-Carlo integration algorithm (N) must be a strictly positive integer."
    exit(198)
  }
  if (alpha <= 0) {
    "{error} Chosen Monte-Carlo confidence factor (alpha) must be strictly positive."
    exit(198)
  }
  // Initialise all required variables
  k = rows(Sigma)
  // If we're dealing with a univariate t variable use standard functions
  if (k == 1) {
    I = (1 - ttail(df, upper - delta)) - (1 - ttail(df, lower - delta))
    E = 0
  }
  // If we're dealing with an actual multivariate case then use the
  // Quasi-Monte-Carlo Randomised-Lattice Separation-Of-Variables method
  else {
    // Algorithm is for the case with 0 non-centrality parameters, so adjust
    // lower and upper and then re-order variables for maximum efficiency
    a         = lower - delta
    b         = upper - delta
    C         = J(k, k, 0)
    u         = J(1, k - 1, 0)
    y         = J(1, k - 1, 0)
    atilde    = J(1, k - 1, 0)
    btilde    = J(1, k - 1, 0)
    atilde[1] = a[1]
    btilde[1] = b[1]
    // Loop over each column of Sigma
    for (i = 1; i <= k - 1; i++) {
      // Determine variate with minimum expectation
      args = J(1, k - i + 1, 0)
      for (j = 1; j <= k - i + 1; j++){
        s = j + i - 1
        if (i > 1) {
          if ((a[s] ~= .) & (b[s] ~= .)) {
            args[j] = (1 - ttail(df + i - 1, sqrt((df + i - 1)/
                                                    (df + sum(y[1::(i - 1)]:^2)))*
                                               ((b[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                                                  sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2))))) -
                        (1 - ttail(df + i - 1, sqrt((df + i - 1)/
                                                      (df + sum(y[1::(i - 1)]:^2)))*
                                                 ((a[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                                                    sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2)))))
          }
          else if ((a[s] == .) & (b[s] ~= .)) {
            args[j] = 1 - ttail(df + i - 1, sqrt((df + i - 1)/
                                                   (df + sum(y[1::(i - 1)]:^2)))*
                                              ((b[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                                                 sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2))))
          }
          else if ((b[s] == .) & (a[s] ~= .)) {
            args[j] = 1 - (1 - ttail(df + i - 1, sqrt((df + i - 1)/
                                                        (df + sum(y[1::(i - 1)]:^2)))*
                                                   ((a[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                                                      sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2)))))
          }
          else if ((a[s] == .) & (b[s] == .)) {
            args[j] = 1
          }
        } 
        else {
          if ((a[s] ~= .) & (b[s] ~= .)) {
            args[j] = (1 - ttail(df, b[s]/sqrt(diag(Sigma[1, 1])))) -
                        (1 - ttail(df, a[s]/sqrt(diag(Sigma[1, 1]))))
          }
          else if ((a[s] == .) & (b[s] ~= .)) {
            args[j] = 1 - ttail(df, b[s]/sqrt(diag(Sigma[1, 1])))
          }
          else if ((b[s] == .) & (a[s] ~= .)) {
            args[j] = 1 - (1 - ttail(df, a[s]/sqrt(diag(Sigma[1, 1]))))
          }
          else if ((a[s] == .) & (b[s] == .)) {
            args[j] = 1
          }
        }
      }
      minindex(args, 1, ii, ww)
      m = i - 1 + ii[1]
      // Change elements m and i of a, b, Sigma and C
      tempa    = a
      tempb    = b
      tempa[i] = a[m]
      tempa[m] = a[i]
      a        = tempa
      tempb[i] = b[m]
      tempb[m] = b[i]
      b        = tempb
      tempSigma          = Sigma
      tempSigma[i, 1::k] = Sigma[m, 1::k]
      tempSigma[m, 1::k] = Sigma[i, 1::k]
      Sigma              = tempSigma
      Sigma[1::k, i]     = tempSigma[1::k, m]
      Sigma[1::k, m]     = tempSigma[1::k, i]
      if (i > 1){
        tempC          = C
        tempC[i, 1::k] = C[m, 1::k]
        tempC[m, 1::k] = C[i, 1::k]
        C              = tempC
        C[1::k, i]     = tempC[1::k, m]
        C[1::k, m]     = tempC[1::k, i]
        // Compute next column of C and next value of atilde and btilde
        C[i, i]        = sqrt(Sigma[i, i] - sum(C[i, 1::(i - 1)]:^2))
        for (s = i + 1; s <= k; s++){
          C[s, i]      = (Sigma[s, i] -
                           sum(C[i, 1::(i - 1)]:*C[s, 1::(i - 1)]))/C[i, i]
        }
        atilde[i]      = (a[i] - sum(C[i, 1::(i - 1)]:*y[1::(i - 1)]))/C[i, i]
        btilde[i]      = (b[i] - sum(C[i, 1::(i - 1)]:*y[1::(i - 1)]))/C[i, i]
      } else {
        C[i, i]        = sqrt(Sigma[i, i])
        C[2::k, i]     = Sigma[2::k, i]/C[i, i]
      }
      // Compute next value of u using integrate
      arg    = (df, i)
      u[i]   = (gamma((df + 1)/2)/(gamma((df + i - 1)/2)*((df + i - 1)*pi())^0.5))*
                 integrate_MVTNORM(atilde[i], btilde[i], arg)/
                   ((1 - ttail(df + i - 1, btilde[i])) -
                      (1 - ttail(df + i - 1, atilde[i])))
      if (i == 1) {
        y[i] = u[i]
      }
      else {
        y[i] = u[i]*sqrt((df + sum(y[1::(i - 1)]:^2))/(df + i - 1))
      }
    }
    // Set the final element of C
    C[k, k]  = sqrt(Sigma[k, k] - sum(C[k, 1::(k - 1)]:^2))
    // List of the first 100 primes to use in randomised lattice algorithm
    p = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67,
         71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139,
         149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223,
         227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293,
         307, 311, 313, 317, 331, 337, 347, 349, 353, 359, 367, 373, 379, 383,
         389, 397, 401, 409, 419, 421, 431, 433, 439, 443, 449, 457, 461, 463,
         467, 479, 487, 491, 499, 503, 509, 521, 523, 541)
    // Initialise all required variables
    I   = 0
    V   = 0 
    sqp = p[1::(k - 1)]:^0.5
    d   = J(1, k, 0)
    e   = J(1, k, 1)
    f   = J(1, k, 0)
    // First elements of d, e and f are always the same
    if (a[1] ~= .){
       d[1] = 1 - ttail(df, a[1]/C[1, 1])
    }
    if (b[1] ~= .){
       e[1] = 1 - ttail(df, b[1]/C[1, 1])
    }
    f[1] = e[1] - d[1]
        
    // Perform M shifts of the Quasi-Monte-Carlo integration algorithm
    for (i = 1; i <= M; i++) {
      Ii = 0
      // We require k - 1 random uniform numbers
      Delta = runiform(1, k - 1)
      // Use N samples in each shift
      for (j = 1; j <= N; j++) {
        u[1] = invttail(df, 1 - (d[1] + abs(2*(mod(j*sqp[1] + Delta[1], 1)) - 1)*(e[1] - d[1]))) 
        y[1] = u[1]
        // Loop to compute other values of d, e and f
        for (l = 2; l <= k; l++) {
          if (a[l] ~= .) {
            d[l] = 1 - ttail(df + l - 1, sqrt((df + l - 1)/
                                                (df + sum(y[1::(l - 1)]:^2)))*
                                           ((a[l] - sum(C[l, 1::(l - 1)]:*y[1::(l - 1)]))/C[l, l]))
          }
          if (b[l] ~= .){
            e[l] = 1 - ttail(df + l - 1, sqrt((df + l - 1)/
                                                (df + sum(y[1::(l - 1)]:^2)))*
                                           ((b[l] - sum(C[l, 1::(l - 1)]:*y[1::(l - 1)]))/C[l, l]))
          }
          f[l]   = (e[l] - d[l])*f[l - 1]
          if (l < k) {
            u[l] = invttail(df + l - 1, 1 - (d[l] + abs(2*(mod(j*sqp[l] + Delta[l], 1)) - 1)*(e[l] - d[l])))
            y[l] = u[l]*sqrt((df + sum(y[1::(l - 1)]:^2))/(df + l - 1))
          }
        }
        Ii = Ii + (f[k] - Ii)/j
      }
      // Update the values of the variables
      delta = (Ii - I)/i
      I     = I + delta
      V     = (i - 2)*V/i + delta^2
      E     = alpha*sqrt(V)
    }
  }
  // Return result
  return((I, E))
}

real vector invmvnormal_mata(real scalar p, real vector mean, real matrix Sigma, string tail,| real scalar M, real scalar N, real scalar alpha, real scalar itermax, real scalar tol)
{
  // Check if optional arguments have been specified
  if (args() < 9) {
    M       = 12
    N       = 1000
    alpha   = 3
    itermax = 1000000
    tol     = 0.000001
  }
  // Perform checks on input variables
  if ((p <= 0) | (p >= 1)) {
    "{error} Probability (p) must be between 0 and 1."
    exit(198)
  }
  if (cols(Sigma) ~= rows(Sigma)) {
    "{error} Covariance matrix Sigma (Sigma) must be square."
    exit(198)
  }
  if (length(mean) ~= cols(Sigma)) {
    "{error} Mean vector (mean) must be the same length as the dimension of covariance matrix Sigma (Sigma)."
    exit(198)
  }
  if (length(mean) > 100) {
    "{error} Only multivariate normal distributions of dimension up to 100 are supported."
    exit(198)
  }
  if ((tail ~= "lower") & (tail ~= "upper") & (tail ~= "both")) {
    "{error} tail must be set to one of lower, upper or both."
    exit(198)
  }
  if ((M < 1) | (mod(M, 1) ~= 0)) {
    "{error} Number of shifts of the Quasi-Monte-Carlo integration algorithm to use (M) must be a strictly positive integer."
    exit(198)
  }
  if ((N < 1) | (mod(N, 1) ~= 0)) {
    "{error} Number of samples to use in each shift of the Quasi-Monte-Carlo integration algorithm (N) must be a strictly positive integer."
    exit(198)
  }
  if (alpha <= 0) {
    "{error} Chosen Monte-Carlo confidence factor (alpha) must be strictly positive."
    exit(198)
  }
  if ((itermax < 1) | (mod(itermax, 1) ~= 0)) {
    "{error} Number of allowed iterations in the interval bisection quantile finding algorithm (itermax) must be a strictly positive integer."
    exit(198)
  }
  if (tol < 0) {
    "{error} The tolerance in the interval bisection quantile finding algorithm (tol) must be strictly positive."
    exit(198)
  }
  // Determine if trivial case is desired
  if ((p == 0) | (p == 1)) {
    q     = .
    error = 0
    flag  = 0
    fq    = 0
    iter  = 0
  }
  else {
    // Initialise all required variables
    C = cholesky(Sigma)
    k = rows(Sigma)
    // If we're dealing with the univariate normal case use the standard
    // function
    if (k == 1) {
      if (tail == "upper") {
        p   = 1 - p
      }
      else if (tail == "both") {
        p   = 0.5 + 0.5*p
      }
      q     = invnormal(p) + mean
      error = 0
      flag  = 0
      fq    = 0
      iter  = 0
    }
    // If we're dealing with an actual multivariate case then use the
    // Quasi-Monte-Carlo Randomised-Lattice Separation-Of-Variables method,
    // along with modified interval bisection
    else {
      // List of the first 100 primes to use in randomised lattice algorithm
      primes = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59,
                61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127,
                131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193,
                197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269,
                271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349,
                353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431,
                433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503,
                509, 521, 523, 541)
      sqp = primes[1::(k - 1)]:^0.5
      // Determine sensible starting interval to bisect over
      b   = 10
	  if (tail == "both") {
	    a = 10^-6
	  }
	  else {
	    a = -10
	  }
	  fa  = qFinder_mvnormal(a, p, k, tail, M, N, alpha, mean, Sigma, sqp)
	  fb  = qFinder_mvnormal(b, p, k, tail, M, N, alpha, mean, Sigma, sqp)
	  if (fa == 0) {
	    q     = a
        error = 0
        flag  = 0
        fq    = 0
        iter  = 0
	  }
	  else if (fb == 0) {
	    q     = b
        error = 0
        flag  = 0
        fq    = 0
        iter  = 0
	  }
	  else {
	    if (tail == "both") {
	      while ((fa > 0) & (a >= 10^-20)) {
	        a  = a/2
	        fa = qFinder_mvnormal(a, p, k, tail, M, N, alpha, mean, Sigma, sqp)
	      }
	      while ((fb < 0) & (b <= 10^6)) {
	        b  = 2*b
	        fb = qFinder_mvnormal(b, p, k, tail, M, N, alpha, mean, Sigma, sqp)
	      }
	    }
	    else {
	      while (((fa > 0 & fb > 0) | (fa < 0 & fb < 0)) & (a >= -10^6)) {
	        a  = 2*a
	        b  = 2*b
	        fa = qFinder_mvnormal(a, p, k, tail, M, N, alpha, mean, Sigma, sqp)
	        fb = qFinder_mvnormal(b, p, k, tail, M, N, alpha, mean, Sigma, sqp)
	      }
	    }
	    if (fa == 0) {
	      q     = a
          error = 0
          flag  = 0
          fq    = 0
          iter  = 0
	    }
	    else if (fb == 0) {
	      q     = b
          error = 0
          flag  = 0
          fq    = 0
          iter  = 0
	    }
	    // Perform modified interval bisection
	    else if ((fa < 0 & fb > 0) | (fa > 0 & fb < 0)) {
          iter = 1
          while (iter <= itermax) {
            c  = a - ((b - a)/(fb - fa))*fa
            fc = qFinder_mvnormal(c, p, k, tail, M, N, alpha, mean, Sigma, sqp)
            if ((fc == 0) | ((b - a)/2 < tol)) {
              break
            }
            else {
              if (((fa < 0) & (fc < 0)) | ((fa > 0) & (fc > 0))) {
                a  = c
                fa = fc
              }
              else {
                b  = c
			    fb = fc
              }
              iter = iter + 1
            }
          }
          q     = c
          error = (b - a)/2
          fq    = fc
          if (iter == itermax + 1) {
            flag  = 1
          }
          else {
            flag  = 0
          }
	    }
	    else {
	      q     = .
          error = .
          flag  = 2
          fq    = .
          iter  = .
	    }
	  }
    }
  }
  // Return result
  return((q, error, flag, fq, iter))
}

function qFinder_mvnormal(q, p, k, tail, M, N, alpha, mean, Sigma, sqp)
{
  // Initialise all required variables
  if (tail == "lower") {
    a = J(1, k, .)
    b = J(1, k, q)
  }
  else if (tail == "upper") {
    a = J(1, k, q)
    b = J(1, k, .)
  }
  else {
    a = J(1, k, -q)
    b = J(1, k, q)
  }
  if (k == 2) {
    for (i = 1; i <= 2; i++) {
	  if (a[i] == .) {
	    a[i] = -8e+307
	  }
	  if (b[i] == .) {
	    b[i] = 8e+307
	  }
	}
	I = binormal((b[1] - mean[1])/sqrt(Sigma[1, 1]),
	             (b[2] - mean[2])/sqrt(Sigma[2, 2]),
	             Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2])) +
		  binormal((a[1] - mean[1])/sqrt(Sigma[1, 1]),
				   (a[2] - mean[2])/sqrt(Sigma[2, 2]),
				   Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2])) -
		    binormal((b[1] - mean[1])/sqrt(Sigma[1, 1]),
			  	     (a[2] - mean[2])/sqrt(Sigma[2, 2]),
				     Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2])) -
			  binormal((a[1] - mean[1])/sqrt(Sigma[1, 1]),
				       (b[2] - mean[2])/sqrt(Sigma[2, 2]),
				       Sigma[1,2]/sqrt(Sigma[1,1]*Sigma[2,2]))	
  }
  else {
    // Algorithm is for the case with 0 means, so adjust lower and upper
    // and then re-order variables for maximum efficiency
    a = a - mean
    b = b - mean
    C         = J(k, k, 0)
    y         = J(1, k - 1, 0)  
    atilde    = J(1, k - 1, 0)
    btilde    = J(1, k - 1, 0)
    atilde[1] = a[1]
    btilde[1] = b[1]
    // Loop over each column of Sigma
    for (i = 1; i <= k - 1; i++) {
      // Determine variate with minimum expectation
	  args = J(1, k - i + 1, 0)
      for (j = 1; j <= k - i + 1; j++){
        s = j + i - 1
	    if (i > 1) {
          if ((a[s] ~= .) & (b[s] ~= .)) {
		    args[j] = normal((b[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                               sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2))) -
                        normal((a[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                                 sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2)))
          }
          else if ((a[s] == .) & (b[s] ~= .)) {
	        args[j] = normal((b[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                               sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2))) 
          }
          else if ((b[s] == .) & (a[s] ~= .)) {
     	    args[j] = 1 - normal((a[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                                   sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2)))
          }
          else if ((a[s] == .) & (b[s] == .)) {
            args[j] = 1
          }
        } 
        else {
          if ((a[s] ~= .) & (b[s] ~= .)) {
            args[j] = normal(b[s]/sqrt(Sigma[1, 1])) -
                        normal(a[s]/sqrt(Sigma[1, 1])) 
          }
          else if ((a[s] == .) & (b[s] ~= .)) {
            args[j] = normal(b[s]/sqrt(Sigma[1, 1])) 
          }
          else if ((b[s] == .) & (a[s] ~= .)) {
            args[j] = 1 - normal(a[s]/sqrt(Sigma[1, 1])) 
          }
          else if ((a[s] == .) & (b[s] == .)) {
            args[j] = 1
          }
        }
      }
      minindex(args, 1, ii, ww)
      m = i - 1 + ii[1]
      // Change elements m and i of a, b, Sigma and C
      tempa    = a
      tempb    = b
      tempa[i] = a[m]
      tempa[m] = a[i]
      a        = tempa
      tempb[i] = b[m]
      tempb[m] = b[i]
      b        = tempb
      tempSigma          = Sigma
      tempSigma[i, 1::k] = Sigma[m, 1::k]
      tempSigma[m, 1::k] = Sigma[i, 1::k]
      Sigma              = tempSigma
      Sigma[1::k, i]     = tempSigma[1::k, m]
      Sigma[1::k, m]     = tempSigma[1::k, i]
      if (i > 1){
        tempC          = C
        tempC[i, 1::k] = C[m, 1::k]
        tempC[m, 1::k] = C[i, 1::k]
        C              = tempC
        C[1::k, i]     = tempC[1::k, m]
        C[1::k, m]     = tempC[1::k, i]
        // Compute next column of C and next value of atilda and btilda
        C[i, i]        = sqrt(Sigma[i, i] - sum(C[i, 1::(i - 1)]:^2))
        for (s = i + 1; s <= k; s++){
          C[s, i]      = (Sigma[s, i] - sum(C[i, 1::(i - 1)]:*C[s, 1::(i - 1)]))/
                           C[i, i]
        }
        atilde[i]      = (a[i] - sum(C[i, 1::(i - 1)]:*y[1::(i - 1)]))/C[i, i]
        btilde[i]      = (b[i] - sum(C[i, 1::(i - 1)]:*y[1::(i - 1)]))/C[i, i]
      } else {
        C[i, i]        = sqrt(Sigma[i, i])
        C[2::k, i]     = Sigma[2::k, i]/C[i, i]
      }
      // Compute next value of y using normalden
      y[i]  = (normalden(atilde[i]) - normalden(btilde[i]))/
                (normal(btilde[i]) - normal(atilde[i]))
    }
    // Set the final element of C
    C[k, k] = sqrt(Sigma[k, k] - sum(C[k, 1::(k - 1)]:^2))
    I = 0
    d = J(1, k, 0)
    e = J(1, k, 1)
    f = J(1, k, 0)
    w = J(1, k - 1, 0)
    // First elements of d, e and f are always the same
    if (a[1] ~= .) {
      d[1] = normal(a[1]/C[1, 1])
    }
    if (b[1] ~= .) {
      e[1] = normal(b[1]/C[1, 1])
    }
    f[1] = e[1] - d[1]
    // Perform M shifts of the Quasi-Monte-Carlo integration algorithm
    for (i = 1; i <= M; i++) {
      Ii = 0
      // We require k - 1 random uniform numbers
      Delta = runiform(1, k - 1)
      // Use N samples in each shift
      for (j = 1; j <= N; j++) {
        // Loop to compute other values of d, e and f
        for (l = 2; l <= k; l++) {
          y[l - 1] = invnormal(d[l - 1] +
                       abs(2*(mod(j*sqp[l - 1] + Delta[l - 1], 1)) - 1)*
                         (e[l - 1] - d[l - 1]))
          if (a[l] ~= .) {
            d[l]   = normal((a[l] - sum(C[l, 1::(l - 1)]:*y[1::(l - 1)]))/C[l, l])
          }
          if (b[l] ~= .) {
            e[l]   = normal((b[l] - sum(C[l, 1::(l - 1)]:*y[1::(l - 1)]))/C[l, l])
          }
          f[l]     = (e[l] - d[l])*f[l - 1]
        }
        Ii         = Ii + (f[k] - Ii)/j
      }
      // Update the values of the variables
      I     = I + (Ii - I)/i
    }
  }
  return(I - p)
}

real vector invmvt_mata(real scalar p, real vector delta, real matrix Sigma, real scalar df, string tail,| real scalar M, real scalar N, real scalar alpha, real scalar itermax, real scalar tol)
{
  // Check if optional arguments have been specified
  if (args() < 9) {
    M       = 12
    N       = 1000
    alpha   = 3
    itermax = 1000000
    tol     = 0.000001
  }
  // Perform checks on input variables
  if ((p <= 0) | (p >= 1)) {
    "{error} Probability (p) must be between 0 and 1."
    exit(198)
  }
  if (cols(Sigma) ~= rows(Sigma)) {
    "{error} Scale matrix Sigma (Sigma) must be square."
    exit(198)
  }
  if (length(delta) ~= cols(Sigma)) {
    "{error} Vector of non-centrality parameters (delta) must be the same length as the dimension of scale matrix Sigma (sigma)."
    exit(198)
  }
  if (length(delta) > 100) {
    "{error} Only multivariate t distributions of dimension up to 100 are supported."
    exit(198)
  }
  if ((df < 1) | (mod(df, 1) ~= 0)) {
    "{error} Degree of freedom (df) must be a positive integer."
    exit(198)
  }
  if ((tail ~= "lower") & (tail ~= "upper") & (tail ~= "both")) {
    "{error} tail must be set to one of lower, upper or both."
    exit(198)
  }
  if ((M < 1) | (mod(M, 1) ~= 0)) {
    "{error} Number of shifts of the Quasi-Monte-Carlo integration algorithm to use (M) must be a strictly positive integer."
    exit(198)
  }
  if ((N < 1) | (mod(N, 1) ~= 0)) {
    "{error} Number of samples to use in each shift of the Quasi-Monte-Carlo integration algorithm (N) must be a strictly positive integer."
    exit(198)
  }
  if (alpha <= 0) {
    "{error} Chosen Monte-Carlo confidence factor (alpha) must be strictly positive."
    exit(198)
  }
  if ((itermax < 1) | (mod(itermax, 1) ~= 0)) {
    "{error} Number of allowed iterations in the interval bisection quantile finding algorithm (itermax) must be a strictly positive integer."
    exit(198)
  }
  if (tol < 0) {
    "{error} The tolerance in the interval bisection quantile finding algorithm (tol) must be strictly positive."
    exit(198)
  }
  // Determine if trivial case is desired
  if ((p == 0) | (p == 1)) {
    q     = .
    error = 0
    flag  = 0
    fq    = 0
    iter  = 0
  }
  else {
    // Initialise all required variables
    k = rows(Sigma)
    // If we're dealing with the univariate normal case use the standard
    // function
    if (k == 1) {
      if (tail == "upper") {
        p = 1 - p
      }
      else if (tail == "both") {
        p = 0.5 + 0.5*p
      }
      q     = invttail(df, 1 - p) + delta
      error = 0
      flag  = 0
      fq    = 0
      iter  = 0
    }
    // If we're dealing with an actual multivariate case then use the
    // Quasi-Monte-Carlo Randomised-Lattice Separation-Of-Variables method,
    // along with optimize
    else {
      // List of the first 100 primes to use in randomised lattice algorithm
      primes = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59,
                61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127,
                131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193,
                197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269,
                271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349,
                353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431,
                433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503,
                509, 521, 523, 541)
      sqp = primes[1::(k - 1)]:^0.5
      // Determine sensible starting interval to bisect over
      b    = 20
	  if (tail == "both") {
	    a  = 10^-6
	  }
	  else {
	    a  = -20
	  }
	  fa = qFinder_mvt(a, p, k, df, tail, M, N, alpha, delta, Sigma, sqp)
	  fb = qFinder_mvt(b, p, k, df, tail, M, N, alpha, delta, Sigma, sqp)
	  if (fa == 0) {
	    q     = a
        error = 0
        flag  = 0
        fq    = 0
        iter  = 0
	  }
	  else if (fb == 0) {
	    q     = b
        error = 0
        flag  = 0
        fq    = 0
        iter  = 0
	  }
	  else {
	    if (tail == "both") {
	      while ((fa > 0) & (a >= 10^-20)) {
	        a  = a/2
	        fa = qFinder_mvt(a, p, k, df, tail, M, N, alpha, delta, Sigma, sqp)
	      }
	      while ((fb < 0) & (b <= 10^6)) {
	        b  = 2*b
	        fb = qFinder_mvt(b, p, k, df, tail, M, N, alpha, delta, Sigma, sqp)
	      }
	    }
	    else {
	      while (((fa > 0 & fb > 0) | (fa < 0 & fb < 0)) & (a >= -10^6)) {
	        a  = 2*a
	        b  = 2*b
	        fa = qFinder_mvt(a, p, k, df, tail, M, N, alpha, delta, Sigma, sqp)
	        fb = qFinder_mvt(b, p, k, df, tail, M, N, alpha, delta, Sigma, sqp)
	      }
	    }
	    if (fa == 0) {
	      q     = a
          error = 0
          flag  = 0
          fq    = 0
          iter  = 0
	    }
	    else if (fb == 0) {
	      q     = b
          error = 0
          flag  = 0
          fq    = 0
          iter  = 0
	    }
	    // Perform modified interval bisection
	    else if ((fa < 0 & fb > 0) | (fa > 0 & fb < 0)) {
          iter = 1
          while (iter <= itermax) {
            c  = a - ((b - a)/(fb - fa))*fa
            fc = qFinder_mvt(c, p, k, df, tail, M, N, alpha, delta, Sigma, sqp)
            if ((fc == 0) | ((b - a)/2 < tol)) {
              break
            }
            else {
              if (((fa < 0) & (fc < 0)) | ((fa > 0) & (fc > 0))) {
                a  = c
                fa = fc
              }
              else {
                b  = c
			    fb = fc
              }
              iter = iter + 1
            }
          }
          q     = c
          error = (b - a)/2
          fq    = fc
          if (iter == itermax + 1) {
            flag  = 1
          }
          else {
            flag  = 0
          }
	    }
	    else {
	      q     = .
          error = .
          flag  = 2
          fq    = .
          iter  = .
	    }
	  }
    }
  }
  // Return result
  return((q, error, flag, fq, iter))
}

function qFinder_mvt(q, p, k, df, tail, M, N, alpha, delta, Sigma, sqp)
{
  // Algorithm is for the case with 0 non-centrality parameters, so adjust
  // lower and upper and then re-order variables for maximum efficiency
  if (tail == "lower") {
    a = J(1, k, .)
    b = J(1, k, q) - delta
  }
  else if (tail == "upper") {
    a = J(1, k, q) - delta
    b = J(1, k, .)
  }
  else {
    a = J(1, k, -q) - delta
    b = J(1, k, q) - delta
  }
  C         = J(k, k, 0)
  u         = J(1, k - 1, 0)
  y         = J(1, k - 1, 0)
  atilde    = J(1, k - 1, 0)
  btilde    = J(1, k - 1, 0)
  atilde[1] = a[1]
  btilde[1] = b[1]
  // Loop over each column of Sigma
  for (i = 1; i <= k - 1; i++) {
    // Determine variate with minimum expectation
    args = J(1, k - i + 1, 0)
    for (j = 1; j <= k - i + 1; j++){
      s = j + i - 1
      if (i > 1) {
        if ((a[s] ~= .) & (b[s] ~= .)) {
          args[j] = (1 - ttail(df + i - 1, sqrt((df + i - 1)/
                                                  (df + sum(y[1::(i - 1)]:^2)))*
                                             ((b[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                                                sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2))))) -
                      (1 - ttail(df + i - 1, sqrt((df + i - 1)/
                                                    (df + sum(y[1::(i - 1)]:^2)))*
                                               ((a[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                                                  sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2)))))
        }
        else if ((a[s] == .) & (b[s] ~= .)) {
          args[j] = 1 - ttail(df + i - 1, sqrt((df + i - 1)/
                                                 (df + sum(y[1::(i - 1)]:^2)))*
                                            ((b[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                                               sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2))))
        }
        else if ((b[s] == .) & (a[s] ~= .)) {
          args[j] = 1 - (1 - ttail(df + i - 1, sqrt((df + i - 1)/
                                                      (df + sum(y[1::(i - 1)]:^2)))*
                                                 ((a[s] - sum(C[s, 1::(i - 1)]:*y[1::(i - 1)]))/
                                                    sqrt(Sigma[s, s] - sum(C[s, 1::(i - 1)]:^2)))))
        }
        else if ((a[s] == .) & (b[s] == .)) {
          args[j] = 1
        }
      } 
      else {
        if ((a[s] ~= .) & (b[s] ~= .)) {
          args[j] = (1 - ttail(df, b[s]/sqrt(diag(Sigma[1, 1])))) -
                      (1 - ttail(df, a[s]/sqrt(diag(Sigma[1, 1]))))
        }
        else if ((a[s] == .) & (b[s] ~= .)) {
          args[j] = 1 - ttail(df, b[s]/sqrt(diag(Sigma[1, 1])))
        }
        else if ((b[s] == .) & (a[s] ~= .)) {
          args[j] = 1 - (1 - ttail(df, a[s]/sqrt(diag(Sigma[1, 1]))))
        }
        else if ((a[s] == .) & (b[s] == .)) {
          args[j] = 1
        }
      }
    }
    minindex(args, 1, ii, ww)
    m = i - 1 + ii[1]
    // Change elements m and i of a, b, Sigma and C
    tempa    = a
    tempb    = b
    tempa[i] = a[m]
    tempa[m] = a[i]
    a        = tempa
    tempb[i] = b[m]
    tempb[m] = b[i]
    b        = tempb
    tempSigma          = Sigma
    tempSigma[i, 1::k] = Sigma[m, 1::k]
    tempSigma[m, 1::k] = Sigma[i, 1::k]
    Sigma              = tempSigma
    Sigma[1::k, i]     = tempSigma[1::k, m]
    Sigma[1::k, m]     = tempSigma[1::k, i]
    if (i > 1){
      tempC          = C
      tempC[i, 1::k] = C[m, 1::k]
      tempC[m, 1::k] = C[i, 1::k]
      C              = tempC
      C[1::k, i]     = tempC[1::k, m]
      C[1::k, m]     = tempC[1::k, i]
      // Compute next column of C and next value of atilde and btilde
      C[i, i]        = sqrt(Sigma[i, i] - sum(C[i, 1::(i - 1)]:^2))
      for (s = i + 1; s <= k; s++){
        C[s, i]      = (Sigma[s, i] -
                         sum(C[i, 1::(i - 1)]:*C[s, 1::(i - 1)]))/C[i, i]
      }
      atilde[i]      = (a[i] - sum(C[i, 1::(i - 1)]:*y[1::(i - 1)]))/C[i, i]
      btilde[i]      = (b[i] - sum(C[i, 1::(i - 1)]:*y[1::(i - 1)]))/C[i, i]
    } else {
      C[i, i]        = sqrt(Sigma[i, i])
      C[2::k, i]     = Sigma[2::k, i]/C[i, i]
    }
    // Compute next value of u using integrate
    arg    = (df, i)
    u[i]   = (gamma((df + 1)/2)/(gamma((df + i - 1)/2)*((df + i - 1)*pi())^0.5))*
               integrate_MVTNORM(atilde[i], btilde[i], arg)/
                 ((1 - ttail(df + i - 1, btilde[i])) -
                    (1 - ttail(df + i - 1, atilde[i])))
    if (i == 1) {
      y[i] = u[i]
    }
    else {
      y[i] = u[i]*sqrt((df + sum(y[1::(i - 1)]:^2))/(df + i - 1))
    }
  }
  // Set the final element of C
  C[k, k]  = sqrt(Sigma[k, k] - sum(C[k, 1::(k - 1)]:^2))
  // Initialise all required variables
  I = 0
  d = J(1, k, 0)
  e = J(1, k, 1)
  f = J(1, k, 0)
  // First elements of d, e and f are always the same
  if (a[1] ~= .){
    d[1] = 1 - ttail(df, a[1]/C[1, 1])
  }
  if (b[1] ~= .){
    e[1] = 1 - ttail(df, b[1]/C[1, 1])
  }
  f[1] = e[1] - d[1]    
  // Perform M shifts of the Quasi-Monte-Carlo integration algorithm
  for (i = 1; i <= M; i++) {
    Ii = 0
    // We require k - 1 random uniform numbers
    Delta = runiform(1, k - 1)
    // Use N samples in each shift
    for (j = 1; j <= N; j++) {
      u[1] = invttail(df, 1 - (d[1] + abs(2*(mod(j*sqp[1] + Delta[1], 1)) - 1)*(e[1] - d[1]))) 
      y[1] = u[1]
      // Loop to compute other values of d, e and f
      for (l = 2; l <= k; l++) {
        if (a[l] ~= .) {
          d[l] = 1 - ttail(df + l - 1, sqrt((df + l - 1)/
                                              (df + sum(y[1::(l - 1)]:^2)))*
                                         ((a[l] - sum(C[l, 1::(l - 1)]:*y[1::(l - 1)]))/C[l, l]))
        }
        if (b[l] ~= .){
          e[l] = 1 - ttail(df + l - 1, sqrt((df + l - 1)/
                                              (df + sum(y[1::(l - 1)]:^2)))*
                                         ((b[l] - sum(C[l, 1::(l - 1)]:*y[1::(l - 1)]))/C[l, l]))
        }
        f[l]   = (e[l] - d[l])*f[l - 1]
        if (l < k) {
          u[l] = invttail(df + l - 1, 1 - (d[l] + abs(2*(mod(j*sqp[l] + Delta[l], 1)) - 1)*(e[l] - d[l])))
          y[l] = u[l]*sqrt((df + sum(y[1::(l - 1)]:^2))/(df + l - 1))
        }
      }
      Ii = Ii + (f[k] - Ii)/j
    }
    // Update the values of the variables
    I    = I + (Ii - I)/i
  }
  return(I - p)
}

real scalar integrate_MVTNORM(real scalar lower, real scalar upper, real vector arg)
{
  if ((lower == . & upper == .) | (lower == 0 & upper == .) |(lower ~= . & upper ~= .)) {
    return(integrate_main_MVTNORM(lower, upper, arg))
  }
  else if (lower == . & upper ~= .) {
    return(integrate_main_MVTNORM(0, upper, arg) + integrate_main_MVTNORM(0, ., arg))
  }
  else if (lower ~= 0 & upper == .) {
    return(integrate_main_MVTNORM(lower, 0, arg) + integrate_main_MVTNORM(0, ., arg))
  }
  else {
    return(integrate_main_MVTNORM(lower, upper, arg))
  }  
}

real matrix integrate_main_MVTNORM(real lower, real upper, real vector arg)
{
  if (lower ~= . & upper ~= .) {
      rw = (.9997137268, .9984919506, .9962951347, .993124937, .9889843952, .9838775407,
               .9778093585, .9707857758, .9628136543, .9539007829, .9440558701, .933288535,
               .9216092981, .909029571, .895561645, .8812186794, .8660146885, .8499645279,
               .8330838799, .8153892383, .7968978924, .7776279096, .7575981185, .7368280898,
               .7153381176, .6931491994, .6702830156, .6467619085, .6226088602, .5978474702,
               .5725019326, .5465970121, .5201580199, .4932107892, .4657816498, .4378974022,
               .4095852917, .3808729816, .3517885264, .3223603439, .292617188, .2625881204,
               .2323024818, .2017898641, .1710800805, .1402031372, .1091892036, .0780685828,
               .0468716824, .0156289844, -.0156289844, -.0468716824, -.0780685828, -.1091892036,
              -.1402031372, -.1710800805, -.2017898641, -.2323024818, -.2625881204, -.292617188,
              -.3223603439, -.3517885264, -.3808729816, -.4095852917, -.4378974022, -.4657816498,
              -.4932107892, -.5201580199, -.5465970121, -.5725019326, -.5978474702, -.6226088602,
              -.6467619085, -.6702830156, -.6931491994, -.7153381176, -.7368280898, -.7575981185,
              -.7776279096, -.7968978924, -.8153892383, -.8330838799, -.8499645279, -.8660146885,
              -.8812186794, -.895561645, -.909029571, -.9216092981, -.933288535, -.9440558701,
              -.9539007829, -.9628136543, -.9707857758, -.9778093585, -.9838775407, -.9889843952,
              -.993124937, -.9962951347, -.9984919506, -.9997137268 \ .0007346345, .0017093927,
               .0026839254, .0036559612, .0046244501, .005588428, .0065469485, .0074990733,
               .0084438715, .0093804197, .0103078026, .011225114, .0121314577, .0130259479,
               .0139077107, .0147758845, .0156296211, .0164680862, .0172904606, .0180959407,
               .0188837396, .0196530875, .0204032326, .0211334421, .0218430024, .0225312203,
               .0231974232, .0238409603, .0244612027, .0250575445, .0256294029, .0261762192,
               .0266974592, .0271926134, .0276611982, .0281027557, .0285168543, .0289030896,
               .0292610841, .0295904881, .0298909796, .0301622651, .0304040795, .0306161866,
               .030798379, .0309504789, .0310723374, .0311638357, .0312248843, .0312554235,
               .0312554235, .0312248843, .0311638357, .0310723374, .0309504789, .030798379,
               .0306161866, .0304040795, .0301622651, .0298909796, .0295904881, .0292610841,
               .0289030896, .0285168543, .0281027557, .0276611982, .0271926134, .0266974592,
               .0261762192, .0256294029, .0250575445, .0244612027, .0238409603, .0231974232,
               .0225312203, .0218430024, .0211334421, .0204032326, .0196530875, .0188837396,
               .0180959407, .0172904606, .0164680862, .0156296211, .0147758845, .0139077107,
               .0130259479, .0121314577, .011225114, .0103078026, .0093804197, .0084438715,
               .0074990733, .0065469485, .005588428, .0046244501, .0036559612, .0026839254,
               .0017093927, .0007346345)
      sum = rw[2, ]:*sf((upper - lower)/2*rw[1, ] :+ (upper + lower)/2, arg)
      return((upper - lower)/2*quadrowsum(sum))
  }
  else if (lower == 0 & upper == .) {
      rw = (374.9841128, 355.2613119, 339.4351019, 325.6912634, 313.329534, 301.9858553,
          291.4401336, 281.5463283, 272.20117, 263.3281685, 254.8686293, 246.776241, 
          239.0136298, 231.550068, 224.3598948, 217.4213933, 210.7159729, 204.2275596, 
          197.9421331, 191.8473694, 185.9323602, 180.1873909, 174.6037612, 169.1736398,
          163.8899456, 158.7462485, 153.7366875, 148.8559014, 144.09897, 139.4613646,
          134.938905, 130.5277232, 126.2242308, 122.0250921, 117.9271991, 113.9276512,
          110.0237356, 106.2129115, 102.4927949, 98.86114605, 95.31585735, 91.85494326,
          88.47653082, 85.17885121, 81.96023222, 78.81909132, 75.75392947, 72.76332543,
          69.84593064, 67.00046452, 64.22571012, 61.52051029, 58.88376398, 56.31442299,
          53.81148892, 51.37401033, 49.00108021, 46.69183354, 44.44544511, 42.26112748,
          40.13812906, 38.07573237, 36.07325241, 34.13003512, 32.245456, 30.41891877,
          28.64985415, 26.93771873, 25.28199387, 23.68218476, 22.13781945, 20.64844797,
          19.21364158, 17.83299195, 16.50611047, 15.2326276, 14.01219225, 12.84447118,
          11.72914849, 10.66592509, 9.654518244, 8.694661114, 7.786102378, 6.928605829,
          6.121950031, 5.365927986, 4.660346836, 4.005027582, 3.399804827, 2.844526543,
          2.33905385, 1.883260826, 1.47703433, 1.120273835, .8128912841, .5548109376,
          .345969181, .1863141021, .075803612, .014386147 \ 7.59641e-96, 3.14629e-94,
          9.41175e-96, 7.0997e-106, 3.8299e-102, 2.95362e-97, 2.13367e-97, 2.22822e-97,
          1.32643e-95, 5.93228e-99, 1.29153e-99, 1.1580e-100, 1.65794e-95, 4.5382e-100,
          1.81558e-90, 1.43778e-93, 2.02036e-91, 1.27976e-88, 6.70480e-86, 2.88488e-83,
          1.03790e-80, 3.15247e-78, 8.15375e-76, 1.80986e-73, 3.47185e-71, 5.79263e-69,
          8.45496e-67, 1.08537e-64, 1.23138e-62, 1.24024e-60, 1.11357e-58, 8.94734e-57,
          6.45627e-55, 4.19775e-53, 2.46681e-51, 1.31398e-49, 6.36127e-48, 2.80604e-46,
          1.13048e-44, 4.16886e-43, 1.41014e-41, 4.38379e-40, 1.25483e-38, 3.31306e-37,
          8.08163e-36, 1.82420e-34, 3.81586e-33, 7.40743e-32, 1.33621e-30, 2.24265e-29,
          3.50627e-28, 5.11237e-27, 6.95920e-26, 8.85323e-25, 1.05359e-23, 1.17402e-22,
          1.22601e-21, 1.20085e-20, 1.10409e-19, 9.53625e-19, 7.74309e-18, 5.91443e-17,
          4.25261e-16, 2.88012e-15, 1.83835e-14, 1.10650e-13, 6.28352e-13, 3.36821e-12,
          1.70506e-11, 8.15480e-11, 3.68633e-10, 1.57560e-09, 6.36971e-09, 2.43643e-08,
          8.82006e-08, 3.02264e-07, 9.80834e-07, 3.01427e-06, 8.77431e-06, .0000241958,
          .0000632109, .0001564521, .0003668548, .0008148716, .0017143197, .00341498,
          .006438951, .0114854424, .0193678281, .0308463086, .0463401336, .0655510093,
          .0870966385, .1083141121, .1254070908, .1340433397, .130356613, .1121151033,
          .0796767462, .0363926059)
      sum = rw[2, ]:*exp(rw[1, ]):*sf(rw[1, ], arg)
      return(quadrowsum(sum))
  }
  else if (lower == . & upper == .) {
      rw = (13.40648734, 12.82379975, 12.34296422, 11.91506194, 11.5214154, 11.15240439,
          10.80226075, 10.46718542, 10.14450994, 9.832269808, 9.528965823, 9.23342089,
          8.944689217, 8.661996168, 8.38469694, 8.112247311, 7.844182384, 7.580100808,
          7.319652822, 7.06253106, 6.808463353, 6.557207032, 6.308544361, 6.062278833,
          5.818232135, 5.576241649, 5.33615836, 5.097845105, 4.861175092, 4.626030636,
          4.392302079, 4.159886855, 3.928688683, 3.698616859, 3.469585636, 3.24151368,
          3.01432358, 2.787941424, 2.562296402, 2.337320464, 2.112947996, 1.889115537,
          1.665761509, 1.44282597, 1.220250391, .9979774361, .7759507615, .5541148236,
          .3324146923, .1107958724, -.1107958724, -.3324146923, -.5541148236, -.7759507615,
          -.9979774361, -1.220250391, -1.44282597, -1.665761509, -1.889115537, -2.112947996,
          -2.337320464, -2.562296402, -2.787941424, -3.01432358, -3.24151368, -3.469585636,
          -3.698616859, -3.928688683, -4.159886855, -4.392302079, -4.626030636, -4.861175092,
          -5.097845105, -5.33615836, -5.576241649, -5.818232135, -6.062278833, -6.308544361,
          -6.557207032, -6.808463353, -7.06253106, -7.319652822, -7.580100808, -7.844182384,
          -8.112247311, -8.38469694, -8.661996168, -8.944689217, -9.23342089, -9.528965823,
          -9.832269808, -10.14450994, -10.46718542, -10.80226075, -11.15240439, -11.5214154,
          -11.91506194, -12.34296422, -12.82379975, -13.40648734 \ 5.90807e-79, 1.97286e-72,
          3.08303e-67, 9.01922e-63, 8.51888e-59, 3.45948e-55, 7.19153e-52, 8.59756e-49,
          6.42073e-46, 3.18522e-43, 1.10047e-40, 2.74878e-38, 5.11623e-36, 7.27457e-34,
          8.06743e-32, 7.10181e-30, 5.03779e-28, 2.91735e-26, 1.39484e-24, 5.56103e-23,
          1.86500e-21, 5.30232e-20, 1.28683e-18, 2.68249e-17, 4.82984e-16, 7.54890e-15,
          1.02887e-13, 1.22788e-12, 1.28790e-11, 1.19130e-10, 9.74792e-10, 7.07586e-09,
          4.56813e-08, 2.62910e-07, 1.35180e-06, 6.22152e-06, .0000256762, .0000951716,
          .000317292, .0009526922, .0025792733, .0063030003, .0139156652, .0277791274,
          .0501758127, .0820518274, .1215379868, .1631300305, .1984628503, .2188926296,
          .2188926296, .1984628503, .1631300305, .1215379868, .0820518274, .0501758127,
          .0277791274, .0139156652, .0063030003, .0025792733, .0009526922, .000317292,
          .0000951716, .0000256762, 6.22152e-06, 1.35180e-06, 2.62910e-07, 4.56813e-08,
          7.07586e-09, 9.74792e-10, 1.19130e-10, 1.28790e-11, 1.22788e-12, 1.02887e-13,
          7.54890e-15, 4.82984e-16, 2.68249e-17, 1.28683e-18, 5.30232e-20, 1.86500e-21,
          5.56103e-23, 1.39484e-24, 2.91735e-26, 5.03779e-28, 7.10181e-30, 8.06743e-32,
          7.27457e-34, 5.11623e-36, 2.74878e-38, 1.10047e-40, 3.18522e-43, 6.42073e-46,
          8.59756e-49, 7.19153e-52, 3.45948e-55, 8.51888e-59, 9.01922e-63, 3.08303e-67,
          1.97286e-72, 5.90807e-79)
      sum = rw[2, ]:*exp(rw[1, ]:^2):*sf(rw[1, ], arg)
      return(quadrowsum(sum))
  }
}

real sf(real rowvector s, real vector arg)
{
  return(s:*(1 :+ (s:^2)/(arg[1] + arg[2] - 1)):^(-(arg[1] + arg[2])/2))
}

mata mlib create lmvtnorm, replace
mata mlib add lmvtnorm *()
mata mlib index

end
