program cauchitasinhinnerw3
version 13
args lnf mu theta lsigma
tempvar sigma 
quietly gen double `sigma' = exp(`lsigma')
quietly replace `lnf' = ln((sqrt((1 - 2*$ML_y1 + 2*$ML_y1^2)^2/((-1 + $ML_y1)^2*$ML_y1^2))*(`sigma')*cosh((`theta') + asinh((1 - 2*$ML_y1)/(2*(-1 + $ML_y1)*$ML_y1))))/(_pi*(1 - 2*$ML_y1 + 2*$ML_y1^2)*((`mu')^2 + (`sigma')^2 - 2*(`mu')*sinh((`theta') + asinh((1 - 2*$ML_y1)/(2*(-1 + $ML_y1)*$ML_y1))) + sinh((`theta') + asinh((1 - 2*$ML_y1)/(2*(-1 + $ML_y1)*$ML_y1)))^2))) /// 
   if $ML_y1 > 0 & $ML_y1 < 1
quietly replace `lnf' = ln(2*`sigma'*exp(`theta')/_pi) if $ML_y1 ==0
quietly replace `lnf' = ln(2*`sigma'/(_pi*exp(`theta'))) if $ML_y1 ==1
end
