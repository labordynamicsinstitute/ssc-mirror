#delim ;
program robit7;
version 16.0;
/*
 Robit link function with 7 degrees of freedom.
*!Author: Roger Newson
*!Date: 28 September 2021
*/

args todo eta mu return;

if `todo' == -1 {;
  /* Set global macros for output */
  global SGLM_lt "Robit with 7 d.f.";
  global SGLM_lf "invt(7,u)";
  exit;
};
if `todo' == 0 {;
  /* set eta(mu) */
  generate double `eta' = invt(7,`mu');
  exit;
};
if `todo' == 1 {;
  /* set mu(eta) */
  generate double `mu' = t(7,`eta');
  exit;
};
if `todo' == 2 {;
  /* set return = dmu/deta */
  generate double `return' = tden(7,`eta');
  exit;
};
if `todo' == 3 {;
  /* set return = d2mu/deta2 */
  generate double `return' = exp( lngamma((7+1)/2)  - lngamma(7/2) )/sqrt(7*_pi) ;
  replace `return' = `return' * (-(7+1)/2) * (1 + (`eta'*`eta')/7)^(-(7+3)/2) ;
  replace `return' = `return' * 2*`eta'/7 ;
  exit;
};
display as error "Unknown call to glm link function";
exit 198;
end;
