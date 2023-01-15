program t2t2innerv2
version 13
args lnf theta lsigma
tempvar sigma 
quietly gen double `sigma' = exp(`lsigma')
quietly replace `lnf' = ln(-((exp(`theta')*sqrt((-1 + $ML_y1 + exp(`theta')*$ML_y1)^2/(1 + (-1 + exp(`theta'))*$ML_y1)^2)*(1 + (-1 + exp(`theta'))*$ML_y1)*(`sigma'))/((-1 + $ML_y1 + exp(`theta')*$ML_y1)*sqrt(-((exp(`theta')*(-1 + $ML_y1)*$ML_y1)/(1 + (-1 + exp(`theta'))*$ML_y1)^2))*sqrt((-1 + $ML_y1*(2 + exp(`theta')*(2 - 4*(`sigma')^2)) - $ML_y1^2*(1 + exp(2*(`theta')) + exp(`theta')*(2 - 4*(`sigma')^2)))/(exp(`theta')*((-1 + $ML_y1)*$ML_y1*(`sigma')^2)))*(1 + $ML_y1^2*(1 + exp(2*(`theta')) + exp(`theta')*(2 - 4*(`sigma')^2)) + $ML_y1*(-2 + exp(`theta')*(-2 + 4*(`sigma')^2)))))) /// 
   if (exp(`theta')*$ML_y1)/(1 + (-1 + exp(`theta'))*$ML_y1) > 0 & (exp(`theta')*$ML_y1)/(1 + (-1 + exp(`theta'))*$ML_y1) < 0.5
quietly replace `lnf' = ln((exp(`theta')*sqrt((-1 + $ML_y1 + exp(`theta')*$ML_y1)^2/(1 + (-1 + exp(`theta'))*$ML_y1)^2)*(1 + (-1 + exp(`theta'))*$ML_y1)*(`sigma'))/((-1 + $ML_y1 + exp(`theta')*$ML_y1)*sqrt(-((exp(`theta')*(-1 + $ML_y1)*$ML_y1)/(1 + (-1 + exp(`theta'))*$ML_y1)^2))*sqrt((-1 + $ML_y1*(2 + exp(`theta')*(2 - 4*(`sigma')^2)) - $ML_y1^2*(1 + exp(2*(`theta')) + exp(`theta')*(2 - 4*(`sigma')^2)))/(exp(`theta')*((-1 + $ML_y1)*$ML_y1*(`sigma')^2)))*(1 + $ML_y1^2*(1 + exp(2*(`theta')) + exp(`theta')*(2 - 4*(`sigma')^2)) + $ML_y1*(-2 + exp(`theta')*(-2 + 4*(`sigma')^2))))) /// 
   if (exp(`theta')*$ML_y1)/(1 + (-1 + exp(`theta'))*$ML_y1) >= 0.5 & (exp(`theta')*$ML_y1)/(1 + (-1 + exp(`theta'))*$ML_y1) < 1
quietly replace `lnf' = ln(`sigma'^2*exp(`theta')) if $ML_y1 ==0
quietly replace `lnf' = ln(`sigma'^2/exp(`theta')) if $ML_y1 ==1
end
