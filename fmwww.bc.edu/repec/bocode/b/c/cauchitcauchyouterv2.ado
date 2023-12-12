program cauchitcauchyouterv2
version 13
args lnf theta lsigma
tempvar sigma 
quietly gen double `sigma' = exp(`lsigma')
quietly replace `lnf' = ln((4*exp(`theta')*_pi^2*(`sigma')*(1/sin(_pi*$ML_y1))^2)/(((1 + ///
   exp(`theta'))*_pi - 2*(-1 + exp(`theta'))*atan(1/((`sigma')*tan(_pi*$ML_y1))))^2* ///
   ((`sigma')^2 + (1/tan(_pi*$ML_y1))^2))) /// 
   if $ML_y1 > 0 & $ML_y1 < 1
quietly replace `lnf' = ln(`sigma'*exp(`theta')) if $ML_y1 ==0
quietly replace `lnf' = ln(`sigma'/exp(`theta')) if $ML_y1 ==1
end
