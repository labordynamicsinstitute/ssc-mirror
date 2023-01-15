program t2t2outerw2
version 13
args lnf theta lsigma
tempvar sigma V H1 H0
quietly gen double `sigma' = exp(`lsigma')
quietly replace `lnf' = ln((((1/2)*(1 + sinh((`theta') + asinh(-(sqrt((1 - 2*($ML_y1 + 0.000000001))^2)/(sqrt(2)*sqrt((1 - ($ML_y1 + 0.000000001))*($ML_y1 + 0.000000001)))/(`sigma'))))/sqrt(2 + sinh((`theta') + asinh(-(sqrt((1 - 2*($ML_y1 + 0.000000001))^2)/(sqrt(2)*sqrt((1 - ($ML_y1 + 0.000000001))*($ML_y1 + 0.000000001)))/(`sigma'))))^2))) - ((1/2)*(1 + sinh((`theta') + asinh(-(sqrt((1 - 2*$ML_y1)^2)/(sqrt(2)*sqrt((1 - $ML_y1)*$ML_y1))/(`sigma'))))/sqrt(2 + sinh((`theta') + asinh(-(sqrt((1 - 2*$ML_y1)^2)/(sqrt(2)*sqrt((1 - $ML_y1)*$ML_y1))/(`sigma'))))^2))))/0.000000001) ///
   if $ML_y1 > 0 & $ML_y1 < 0.5
quietly replace `lnf' = ln((((1/2)*(1 + sinh((`theta') + asinh(sqrt((1 - 2*($ML_y1 + 0.000000001))^2)/((sqrt(2)*sqrt((1 - ($ML_y1 + 0.000000001))*($ML_y1 + 0.000000001)))*(`sigma'))))/sqrt(2 + sinh((`theta') + asinh(sqrt((1 - 2*($ML_y1 + 0.000000001))^2)/((sqrt(2)*sqrt((1 - ($ML_y1 + 0.000000001))*($ML_y1 + 0.000000001)))*(`sigma'))))^2))) - ((1/2)*(1 + sinh((`theta') + asinh(sqrt((1 - 2*$ML_y1)^2)/((sqrt(2)*sqrt((1 - $ML_y1)*$ML_y1))*(`sigma'))))/sqrt(2 + sinh((`theta') + asinh(sqrt((1 - 2*$ML_y1)^2)/((sqrt(2)*sqrt((1 - $ML_y1)*$ML_y1))*(`sigma'))))^2))))/0.000000001) ///
   if $ML_y1 >= 0.5 & $ML_y1 < 1
quietly replace `lnf' = ln(`sigma'^2*exp(2*`theta')) if $ML_y1 ==0
quietly replace `lnf' = ln(`sigma'^2/exp(2*`theta')) if $ML_y1 ==1
end
