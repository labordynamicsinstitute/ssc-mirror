program asinhasinhinnerv3
version 13
args lnf mu theta lsigma
tempvar sigma 
quietly gen double `sigma' = exp(`lsigma')
quietly replace `lnf' = ln((exp(-(`theta') + asinh((1 + 2*$ML_y1*(-1 + exp(`theta')*(`mu')) - $ML_y1^2*(-1 + exp(2*(`theta')) + 2*exp(`theta')*(`mu')))/(exp(`theta')*(2*(-1 + $ML_y1)*$ML_y1*(`sigma')))))*(1 - 2*$ML_y1 + (1 + exp(2*(`theta')))*$ML_y1^2))/((1 + exp(asinh((1 + 2*$ML_y1*(-1 + exp(`theta')*(`mu')) - $ML_y1^2*(-1 + exp(2*(`theta')) + 2*exp(`theta')*(`mu')))/(exp(`theta')*(2*(-1 + $ML_y1)*$ML_y1*(`sigma'))))))^2*(-1 + $ML_y1)^2*$ML_y1^2*(`sigma')*sqrt((1/((-1 + $ML_y1)^2*$ML_y1^2*(`sigma')^2))*((1 + 4*$ML_y1*(-1 + exp(`theta')*(`mu')) + 2*$ML_y1^2*(3 - 6*exp(`theta')*(`mu') + exp(2*(`theta'))*(-1 + 2*(`mu')^2 + 2*(`sigma')^2)) - 4*$ML_y1^3*(1 - 3*exp(`theta')*(`mu') + exp(3*(`theta'))*(`mu') + exp(2*(`theta'))*(-1 + 2*(`mu')^2 + 2*(`sigma')^2)) + $ML_y1^4*(1 + exp(4*(`theta')) - 4*exp(`theta')*(`mu') + 4*exp(3*(`theta'))*(`mu') + exp(2*(`theta'))*(-2 + 4*(`mu')^2 + 4*(`sigma')^2)))/exp(2*(`theta')))))) /// 
   if $ML_y1 > 0 & $ML_y1 < 1
quietly replace `lnf' = ln(`sigma'*exp(`theta')) if $ML_y1 ==0
quietly replace `lnf' = ln(`sigma'/exp(`theta')) if $ML_y1 ==1
end
