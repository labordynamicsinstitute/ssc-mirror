program cauchitasinhouterw2
version 13
args lnf theta lsigma
tempvar sigma 
quietly gen double `sigma' = exp(`lsigma')
quietly replace `lnf' = ln(((1 - 2*$ML_y1 + 2*$ML_y1^2)*(1/cosh((`theta') - asinh((1 - ///
   2*$ML_y1)/(2*$ML_y1*(`sigma') - 2*$ML_y1^2*(`sigma'))))))/(_pi*(-1 + $ML_y1)^2* ///
   $ML_y1^2*(`sigma')*sqrt((1 - 4*$ML_y1 - 8*$ML_y1^3*(`sigma')^2 + 4*$ML_y1^4* ///
   (`sigma')^2 + 4*$ML_y1^2*(1 + (`sigma')^2))/((-1 + $ML_y1)^2*$ML_y1^2*(`sigma')^2)))) /// 
   if $ML_y1 > 0 & $ML_y1 < 1
quietly replace `lnf' = ln(2*`sigma'*exp(`theta')/_pi) if $ML_y1 ==0
quietly replace `lnf' = ln(2*`sigma'/(_pi*exp(`theta'))) if $ML_y1 ==1
end