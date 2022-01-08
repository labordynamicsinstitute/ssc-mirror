#delim ;
program robit9;
version 16.0;
/*
 Robit link function with 9 degrees of freedom.
*!Author: Roger Newson
*!Date: 06 January 2022
*/

args todo eta mu return;

if `todo' == -1 {;
  /* Set global macros for output */
  global SGLM_lt "Robit with 9 d.f.";
  global SGLM_lf "invt(9,u)";
  exit;
};
if `todo' == 0 {;
  /* set eta(mu) */
  generate double `eta' = invt(9,`mu');
  exit;
};
if `todo' == 1 {;
  /* set mu(eta) */
  generate double `mu' = t(9,`eta');
  exit;
};
if `todo' == 2 {;
  /* set return = dmu/deta */
  generate double `return' = tden(9,`eta');
  exit;
};
if `todo' == 3 {;
  /* set return = d2mu/deta2 */
  generate double `return' = exp( lngamma((9+1)/2)  - lngamma(9/2) )/sqrt(9*_pi) ;
  replace `return' = `return' * (-(9+1)/2) * (1 + (`eta'*`eta')/9)^(-(9+3)/2) ;
  replace `return' = `return' * 2*`eta'/9 ;
  exit;
};
display as error "Unknown call to glm link function";
exit 198;
end;
