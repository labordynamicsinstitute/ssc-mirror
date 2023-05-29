version 16.1
program define stpm3_polygen, rclass
  syntax varname [if][in], DEGree(numlist max=1)         ///
                           [                             ///
                           CENTer                        /// 
                           CENTerv(numlist min=1 max=1)  ///
                           REPLACE                       ///
                           stub(string)                  ///
                           ]
  marksample touse                                   
 
  if "`stub'" == "" local stub `varlist'_poly
  mata stpm3_polygen()
  return local varname `varlist'
end
