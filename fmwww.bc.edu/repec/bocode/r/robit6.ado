#delim ;
program robit6;
version 16.0;
/*
 Robit link function with 6 degrees of freedom.
*!Author: Roger Newson
*!Date: 20 October 2021
*/

args todo eta mu return;

if `todo' == -1 {;
  /* Set global macros for output */
  global SGLM_lt "Robit with 6 d.f.";
  global SGLM_lf "invt(6,u)";
  exit;
};
if `todo' == 0 {;
  /* set eta(mu) */
  generate double `eta' = invt(6,`mu');
  exit;
};
if `todo' == 1 {;
  /* set mu(eta) */
  generate double `mu' = t(6,`eta');
  exit;
};
if `todo' == 2 {;
  /* set return = dmu/deta */
  generate double `return' = tden(6,`eta');
  exit;
};
if `todo' == 3 {;
  /* set return = d2mu/deta2 */
  generate double `return' = exp( lngamma((6+1)/2)  - lngamma(6/2) )/sqrt(6*_pi) ;
  replace `return' = `return' * (-(6+1)/2) * (1 + (`eta'*`eta')/6)^(-(6+3)/2) ;
  replace `return' = `return' * 2*`eta'/6 ;
  exit;
};
display as error "Unknown call to glm link function";
exit 198;
end;
