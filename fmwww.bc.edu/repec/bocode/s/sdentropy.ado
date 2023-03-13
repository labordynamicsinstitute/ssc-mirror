   // Revision 1.3  2014/04/01 21:44:57  brendan
   // Summary: Made quiet
   //
   // Revision 1.2  2012/06/28 23:11:53  brendan
   // Put log and id in header
   //
   // Jun 28 2012 23:19:37
   // entropy state*, nstates(4) generate(ent) cdstub(cdur)
program define sdentropy
   syntax varlist (min=2), NSTates(int) GENerate(string) CDstub(string)
   tempvar total
   
   cumuldur `varlist', nstates(`nstates') cdstub(`cdstub')
   qui {
     gen `total' = 0
     gen `generate' = 0
     forvalues x = 1/`nstates' {
       replace `total' = `total' + `cdstub'`x'
     }
     forvalues x = 1/`nstates' {
       replace `cdstub'`x' = `cdstub'`x'/`total'
       replace `generate' = `generate' - `cdstub'`x'*log(`cdstub'`x')/log(2) if `cdstub'`x'>0
     }
   }
end
