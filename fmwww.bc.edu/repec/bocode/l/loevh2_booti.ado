*! Version 3.2, Dirk Enzmann (13-Jul-2026)
*!
*! New immediate command (amalogous to rioci version 1.0.0 by Daniel Klein)

program define loevh2_booti, rclass

   version 14.0

   syntax anything(id="integer") [ , noTAB Table Reps(integer 100) ///
      Level(real 95) Seed(integer 0) Progress Maxtries(integer 50) ]

   if ("`tab'"=="notab" & "`table'"=="table") {
      di as error "options notab and table may not be combined"
      exit 198
   }

   foreach x in a b c d {
      gettoken `x' anything : anything , parse(" \")
   }
   if ("`c'" == "\") {
      local c `d'
      gettoken d anything : anything
   }
   if (`"`anything'"' != "") error 198

   capture confirm integer number `a'
   if _rc {
      di as error "#a must be an integer"
      exit 198
   }
   capture confirm integer number `b'
   if _rc {
      di as error "#b must be an integer"
      exit 198
   }
   capture confirm integer number `c'
   if _rc {
      di as error "#c must be an integer"
      exit 198
   }
   capture confirm integer number `d'
   if _rc {
      di as error "#d must be an integer"
      exit 198
   }
   if (`a'<0 | `b'<0 | `c'<0 | `d'<0) {
      di as error "cell frequencies must be nonnegative"
      exit 198
   }

   preserve

      quietly {
         drop _all
         tabi `a' `b' \ `c' `d' , replace
         rename row rowvar
         rename col colvar
         replace rowvar = rowvar - 1
         replace colvar = colvar - 1
         rename pop freq
         label variable rowvar "rowvar"
         label variable colvar "colvar"
      }
      
      // Default (neither notab nor table specified): show the simple
      // frequency-only cross-tabulation. If table is specified, this
      // simple table is skipped in favor of loevh2's own, more detailed
      // table (passed through below, via loevh2_boot). If notab is
      // specified, no table is shown at all.
      if ("`tab'" != "notab" & "`table'" == "") tabi `a' `b' \ `c' `d', nokey
      
      loevh2_boot rowvar colvar [fweight=freq] , reps(`reps') level(`level') ///
         seed(`seed') maxtries(`maxtries') `progress' `table'
      return add

   restore
end
exit
