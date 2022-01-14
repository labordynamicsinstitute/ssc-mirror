#delim ;
program robit10;
version 16.0;
/*
 Robit link function with 10 degrees of freedom.
*!Author: Roger Newson
*!Date: 11 January 2022
*/

args todo eta mu return;

if `todo' == -1 {;
  /* Set global macros for output */
  global SGLM_lt "Robit with 10 d.f.";
  global SGLM_lf "invt(10,u)";
  exit;
};
if `todo' == 0 {;
  /* set eta(mu) */
  generate double `eta' = invt(10,`mu');
  exit;
};
if `todo' == 1 {;
  /* set mu(eta) */
  generate double `mu' = t(10,`eta');
  exit;
};
if `todo' == 2 {;
  /* set return = dmu/deta */
  generate double `return' = tden(10,`eta');
  exit;
};
if `todo' == 3 {;
  /* set return = d2mu/deta2 */
  generate double `return' = exp( lngamma((10+1)/2)  - lngamma(10/2) )/sqrt(10*_pi) ;
  replace `return' = `return' * (-(10+1)/2) * (1 + (`eta'*`eta')/10)^(-(10+3)/2) ;
  replace `return' = `return' * 2*`eta'/10 ;
  exit;
};
display as error "Unknown call to glm link function";
exit 198;
end;
