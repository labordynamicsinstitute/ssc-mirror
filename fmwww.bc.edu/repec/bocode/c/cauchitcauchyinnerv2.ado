program cauchitcauchyinnerv2
version 13
args lnf theta lsigma
tempvar sigma 
quietly gen double `sigma' = exp(`lsigma')
quietly replace `lnf' = ln((exp(`theta')*(`sigma')*(1/sin((exp(`theta')* ///
   _pi*$ML_y1)/(1 + (-1 + exp(`theta'))*$ML_y1)))^2)/((1 + (-1 + exp(`theta'))*$ML_y1)^2* ///
   ((`sigma')^2 + (1/tan((exp(`theta')*_pi*$ML_y1)/(1 + (-1 + exp(`theta'))*$ML_y1)))^2))) /// 
   if $ML_y1 > 0 & $ML_y1 < 1
quietly replace `lnf' = ln(`sigma'*exp(`theta')) if $ML_y1 ==0
quietly replace `lnf' = ln(`sigma'/exp(`theta')) if $ML_y1 ==1
end
