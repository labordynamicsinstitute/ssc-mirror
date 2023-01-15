program t2t2innerw2
version 13
args lnf theta lsigma
tempvar sigma 
quietly gen double `sigma' = exp(`lsigma')
quietly replace `lnf' = ln(-(cosh((`theta') + asinh((-1 + 2*$ML_y1)/(sqrt(2)* ///
   sqrt(-((-1 + $ML_y1)*$ML_y1)))))/(2*(-1 + $ML_y1)*$ML_y1*sqrt(1 - 2*$ML_y1 + 2*$ML_y1^2)* ///
   (`sigma')*(2 + sinh((`theta') + asinh((-1 + 2*$ML_y1)/(sqrt(2)*sqrt(-((-1 + $ML_y1)* ///
   $ML_y1)))))^2/(`sigma')^2)^(3/2)))) /// 
   if $ML_y1 > 0 & $ML_y1 < 1
quietly replace `lnf' = ln(`sigma'^2*exp(2*`theta')) if $ML_y1 ==0
quietly replace `lnf' = ln(`sigma'^2/exp(2*`theta')) if $ML_y1 ==1
end
