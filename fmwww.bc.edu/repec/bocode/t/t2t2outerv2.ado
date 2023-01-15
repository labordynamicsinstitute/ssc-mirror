program t2t2outerv2
version 13
args lnf theta lsigma
tempvar sigma 
quietly gen double `sigma' = exp(`lsigma')
quietly replace `lnf' = ln((4*exp(`theta')*(`sigma')*((1 - 2*$ML_y1 )/(2*sqrt(2)*sqrt((1 - 2*$ML_y1 )^2)*(-((-1 + $ML_y1 )*$ML_y1 ))^(3/2))))/(sqrt(2 + (1 - 2*$ML_y1 )^2/((2*(1 - $ML_y1 )*$ML_y1 )*(`sigma')^2))*((-1 + exp(`theta'))*(-(sqrt((1 - 2*$ML_y1 )^2)/(sqrt(2)*sqrt((1 - $ML_y1 )*$ML_y1 )))) + (1 + exp(`theta'))*(`sigma')*sqrt(2 + (1 - 2*$ML_y1 )^2/((2*(1 - $ML_y1 )*$ML_y1 )*(`sigma')^2)))^2)) /// 
   if $ML_y1 > 0 & $ML_y1 < 0.5
quietly replace `lnf' = ln((4*exp(`theta')*(`sigma')*2*sqrt(2))/(sqrt(2 + (1 - 2*$ML_y1 )^2/((2*(1 - $ML_y1 )*$ML_y1 )*(`sigma')^2))*((-1 + exp(`theta'))*(sqrt((1 - 2*$ML_y1 )^2)/(sqrt(2)*sqrt((1 - $ML_y1 )*$ML_y1 ))) + (1 + exp(`theta'))*(`sigma')*sqrt(2 + (1 - 2*$ML_y1 )^2/((2*(1 - $ML_y1 )*$ML_y1 )*(`sigma')^2)))^2)) /// 
   if $ML_y1 == 0.5
quietly replace `lnf' = ln((4*exp(`theta')*(`sigma')*((-1 + 2*$ML_y1 )/(2*sqrt(2)*sqrt((1 - 2*$ML_y1 )^2)*(-((-1 + $ML_y1 )*$ML_y1 ))^(3/2))))/(sqrt(2 + (1 - 2*$ML_y1 )^2/((2*(1 - $ML_y1 )*$ML_y1 )*(`sigma')^2))*((-1 + exp(`theta'))*(sqrt((1 - 2*$ML_y1 )^2)/(sqrt(2)*sqrt((1 - $ML_y1 )*$ML_y1 ))) + (1 + exp(`theta'))*(`sigma')*sqrt(2 + (1 - 2*$ML_y1 )^2/((2*(1 - $ML_y1 )*$ML_y1 )*(`sigma')^2)))^2)) /// 
   if $ML_y1 > 0.5 & $ML_y1 < 1
quietly replace `lnf' = ln(`sigma'^2*exp(`theta')) if $ML_y1 == 0

quietly replace `lnf' = ln(`sigma'^2/exp(`theta')) if $ML_y1 == 1
end
