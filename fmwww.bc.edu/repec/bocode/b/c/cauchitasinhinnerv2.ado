program cauchitasinhinnerv2
version 13
args lnf theta lsigma
tempvar sigma 
quietly gen double `sigma' = exp(`lsigma')
quietly replace `lnf' = ln((2*exp(`theta')*(1 - 2*$ML_y1 + (1 + exp(2*(`theta')))*$ML_y1^2)* ///
   (`sigma'))/(_pi*(1 - 4*$ML_y1 + $ML_y1^3*(-4 + exp(2*(`theta'))*(4 - 8*(`sigma')^2)) + ///
   $ML_y1^2*(6 + exp(2*(`theta'))*(-2 + 4*(`sigma')^2)) + $ML_y1^4*(1 + exp(4*(`theta')) + ///
   exp(2*(`theta'))*(-2 + 4*(`sigma')^2))))) /// 
   if $ML_y1 > 0 & $ML_y1 < 1
quietly replace `lnf' = ln(2*`sigma'*exp(`theta')/_pi) if $ML_y1 ==0
quietly replace `lnf' = ln(2*`sigma'/(_pi*exp(`theta'))) if $ML_y1 ==1
end
