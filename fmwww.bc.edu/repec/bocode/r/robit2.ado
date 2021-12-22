#delim ;
program robit2;
version 16.0;
/*
 Robit link function with 2 degrees of freedom.
*!Author: Roger Newson
*!Date: 20 October 2021
*/

args todo eta mu return;

if `todo' == -1 {;
  /* Set global macros for output */
  global SGLM_lt "Robit with 2 d.f.";
  global SGLM_lf "invt(2,u)";
  exit;
};
if `todo' == 0 {;
  /* set eta(mu) */
  generate double `eta' = invt(2,`mu');
  exit;
};
if `todo' == 1 {;
  /* set mu(eta) */
  generate double `mu' = t(2,`eta');
  exit;
};
if `todo' == 2 {;
  /* set return = dmu/deta */
  generate double `return' = tden(2,`eta');
  exit;
};
if `todo' == 3 {;
  /* set return = d2mu/deta2 */
  generate double `return' = exp( lngamma((2+1)/2)  - lngamma(2/2) )/sqrt(2*_pi) ;
  replace `return' = `return' * (-(2+1)/2) * (1 + (`eta'*`eta')/2)^(-(2+3)/2) ;
  replace `return' = `return' * 2*`eta'/2 ;
  exit;
};
display as error "Unknown call to glm link function";
exit 198;
end;
