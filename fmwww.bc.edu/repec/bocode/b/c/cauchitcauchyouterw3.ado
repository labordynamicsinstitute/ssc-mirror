program cauchitcauchyouterw3
version 13
args lnf mu theta lsigma
tempvar sigma 
quietly gen double `sigma' = exp(`lsigma')
quietly replace `lnf' = ln(((1/sin(_pi*$ML_y1))^2*(1/cosh((`theta') - asinh(((`mu') + (1/tan(_pi*$ML_y1)))/(`sigma')))))/((`sigma')*sqrt(1 + ((`mu') + (1/tan(_pi*$ML_y1)))^2/(`sigma')^2))) /// 
   if $ML_y1 > 0 & $ML_y1 < 1
quietly replace `lnf' = ln(`sigma'*exp(`theta')) if $ML_y1 ==0
quietly replace `lnf' = ln(`sigma'/(exp(`theta'))) if $ML_y1 ==1
end
