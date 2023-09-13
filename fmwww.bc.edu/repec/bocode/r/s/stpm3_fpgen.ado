version 16.1
program define stpm3_fpgen, rclass
  syntax varname [if][in], POWers(numlist sort)          ///
                           [                             ///
                           CENTer                        /// 
                           CENTerv(numlist min=1 max=1)  ///
                           SCAle                         ///
                           SCAlev(numlist min=2 max=2)   ///
                           REPLACE                       ///
                           stub(string)                  ///
                           ]
  marksample touse                                   
 
  if "`stub'" == "" local stub `varlist'_fp
  mata stpm3_fp()
  return local varname `varlist'
  
end
