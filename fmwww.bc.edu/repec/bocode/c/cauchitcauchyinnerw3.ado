program cauchitcauchyinnerw3
version 13
args lnf mu theta lsigma
tempvar sigma 
quietly gen double `sigma' = exp(`lsigma')
quietly replace `lnf' = ln(((`sigma')*cosh((`theta') - asinh((1/tan(_pi*$ML_y1))))*sqrt((1/sin(_pi*$ML_y1))^2))/((`mu')^2 + (`sigma')^2 - 2*(`mu')*sinh((`theta') - asinh((1/tan(_pi*$ML_y1)))) + sinh((`theta') - asinh((1/tan(_pi*$ML_y1))))^2)) /// 
   if $ML_y1 > 0 & $ML_y1 < 1
quietly replace `lnf' = ln(`sigma'*exp(`theta')) if $ML_y1 ==0
quietly replace `lnf' = ln(`sigma'/(exp(`theta'))) if $ML_y1 ==1
end
