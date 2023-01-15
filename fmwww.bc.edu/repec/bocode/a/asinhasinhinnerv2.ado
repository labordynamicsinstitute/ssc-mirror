program asinhasinhinnerv2
version 13
args lnf theta lsigma
tempvar sigma 
quietly gen double `sigma' = exp(`lsigma')
quietly replace `lnf' = ln(((-2 - 2*(-1 + exp(2*(`theta')))*$ML_y1)/(exp(`theta')* ///
   (2*(-1 + $ML_y1)*$ML_y1*(`sigma'))) - (1 - 2*$ML_y1 - (-1 + exp(2*(`theta')))* ///
   $ML_y1^2)/(exp(`theta')*(2*(-1 + $ML_y1)*$ML_y1^2*(`sigma'))) - /// 
   (1 - 2*$ML_y1 - (-1 + exp(2*(`theta')))*$ML_y1^2)/(exp(`theta')* ///
   (2*(-1 + $ML_y1)^2*$ML_y1*(`sigma'))))/(exp(asinh((1 - 2*$ML_y1 - ///
   (-1 + exp(2*(`theta')))*$ML_y1^2)/(exp(`theta')*(2*(-1 + $ML_y1)* ///
   $ML_y1*(`sigma')))))*((1 + exp(-asinh((1 - 2*$ML_y1 - (-1 + exp(2* ///
   (`theta')))*$ML_y1^2)/(exp(`theta')*(2*(-1 + $ML_y1)*$ML_y1*(`sigma'))))))^2* ///
   sqrt(1 + (1 - 2*$ML_y1 - (-1 + exp(2*(`theta')))*$ML_y1^2)^2/(exp(2* ///
   (`theta'))*(4*(-1 + $ML_y1)^2*$ML_y1^2*(`sigma')^2)))))) /// 
   if $ML_y1 > 0 & $ML_y1 < 1
quietly replace `lnf' = ln(`sigma'*exp(`theta')) if $ML_y1 ==0
quietly replace `lnf' = ln(`sigma'/exp(`theta')) if $ML_y1 ==1
end
