#delim ;
program robit1;
version 16.0;
/*
 Robit link function with 1 degrees of freedom.
*!Author: Roger Newson
*!Date: 20 October 2021
*/

args todo eta mu return;

if `todo' == -1 {;
  /* Set global macros for output */
  global SGLM_lt "Robit with 1 d.f.";
  global SGLM_lf "invt(1,u)";
  exit;
};
if `todo' == 0 {;
  /* set eta(mu) */
  generate double `eta' = invt(1,`mu');
  exit;
};
if `todo' == 1 {;
  /* set mu(eta) */
  generate double `mu' = t(1,`eta');
  exit;
};
if `todo' == 2 {;
  /* set return = dmu/deta */
  generate double `return' = tden(1,`eta');
  exit;
};
if `todo' == 3 {;
  /* set return = d2mu/deta2 */
  generate double `return' = exp( lngamma((1+1)/2)  - lngamma(1/2) )/sqrt(1*_pi) ;
  replace `return' = `return' * (-(1+1)/2) * (1 + (`eta'*`eta')/1)^(-(1+3)/2) ;
  replace `return' = `return' * 2*`eta'/1 ;
  exit;
};
display as error "Unknown call to glm link function";
exit 198;
end;
