#delim ;
program robit4;
version 16.0;
/*
 Robit link function with 4 degrees of freedom.
*!Author: Roger Newson
*!Date: 17 October 2021
*/

args todo eta mu return;

if `todo' == -1 {;
  /* Set global macros for output */
  global SGLM_lt "Robit with 4 d.f.";
  global SGLM_lf "invt(4,u)";
  exit;
};
if `todo' == 0 {;
  /* set eta(mu) */
  generate double `eta' = invt(4,`mu');
  exit;
};
if `todo' == 1 {;
  /* set mu(eta) */
  generate double `mu' = t(4,`eta');
  exit;
};
if `todo' == 2 {;
  /* set return = dmu/deta */
  generate double `return' = tden(4,`eta');
  exit;
};
if `todo' == 3 {;
  /* set return = d2mu/deta2 */
  generate double `return' = exp( lngamma((4+1)/2)  - lngamma(4/2) )/sqrt(4*_pi) ;
  replace `return' = `return' * (-(4+1)/2) * (1 + (`eta'*`eta')/4)^(-(4+3)/2) ;
  replace `return' = `return' * 2*`eta'/4 ;
  exit;
};
display as error "Unknown call to glm link function";
exit 198;
end;
