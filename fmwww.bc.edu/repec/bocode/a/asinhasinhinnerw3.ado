program asinhasinhinnerw3
version 13
args lnf mu theta lsigma
tempvar sigma 
quietly gen double `sigma' = exp(`lsigma')
quietly replace `lnf' = ln((exp(asinh(`mu' - sinh((`theta') + asinh((1 - 2*$ML_y1)/(2* ///
   (-1 + $ML_y1)*$ML_y1)))/(`sigma')))*sqrt((1 - 2*$ML_y1 + 2*$ML_y1^2)^2/((-1 ///
   + $ML_y1)^2*$ML_y1^2))*cosh((`theta') + asinh((1 - 2*$ML_y1)/(2*(-1 + $ML_y1)* ///
   $ML_y1))))/((1 + exp(asinh(`mu' - sinh((`theta') + asinh((1 - 2*$ML_y1)/(2*(-1 + ///
   $ML_y1)*$ML_y1)))/(`sigma'))))^2*(1 - 2*$ML_y1 + 2*$ML_y1^2)*(`sigma')* ///
   sqrt(1 + (`mu' - sinh((`theta') + asinh((1 - 2*$ML_y1)/(2*(-1 + $ML_y1)* /// 
   $ML_y1))))^2/(`sigma')^2))) /// 
   if $ML_y1 > 0 & $ML_y1 < 1
quietly replace `lnf' = ln(`sigma'*exp(`theta')) if $ML_y1 ==0
quietly replace `lnf' = ln(`sigma'/exp(`theta')) if $ML_y1 ==1
end
