*! version 2.0.0  Dirk Enzmann  24april2024

program renlabv, rclass
   version 11.2
   cap which elabel
   if _rc {
     di as err "-renlabv- requires -elabels- (available on SSC)" 
     exit 199
   } 
   syntax [varlist] [, NODrop]

   qui {
      ds, has(vall)
      local va "`r(varlist)'"
      foreach v of varlist `va' {
         elabel list (`v')
         local la "`la' `r(name)'"  // all value labels
      }

      ds `varlist', has(vall)
      local vl "`r(varlist)'"
      foreach v of varlist `vl' {
         elabel list (`v'), var
         if "`r(name)'" != "`v'" & {
            local ll "`ll' `r(name)'"  // all renamed value labels
            elabel copy `v':`r(name)' `v', replace
            label val `v' `v'
         }
      }

      local lnl : list la - ll      // all not renamed value labels
      local la : list uniq la
      local lnl : list uniq lnl
      local dropl : list la - lnl   // dropped value labels

      if "`nodrop'" != "nodrop" & "`dropl'" != "" {
         label drop `dropl'
         return local dvl `dropl'
      }
   }
end
