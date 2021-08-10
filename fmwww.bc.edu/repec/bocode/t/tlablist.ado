*! tlablist.ado v 1.0.1 fw 8/3/02 lists tlabels
*! syntax [varlist]
program define tlablist
   version 7.0
   syntax [varlist]
   foreach varname of varlist `varlist' { 
      local tlabel: char `varname'[tlabel]
      if "`tlabel'" != "" {
         di in result "`varname'" ":" _col(20) "`tlabel'"
      }
   }
end
* v 1.0.0 7/6/02
* v 1.0.1 improves output spacing
