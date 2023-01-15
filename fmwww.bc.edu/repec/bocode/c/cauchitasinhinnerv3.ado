program cauchitasinhinnerv3
version 13
args lnf mu theta lsigma
tempvar sigma 
quietly gen double `sigma' = exp(`lsigma')
quietly replace `lnf' = ln((2*exp(`theta')*(1 - 2*$ML_y1 + (1 + exp(2*(`theta')))*$ML_y1^2)*(`sigma'))/(_pi*(1 + 4*$ML_y1*(-1 + exp(`theta')*(`mu')) + 2*$ML_y1^2*(3 - 6*exp(`theta')*(`mu') + exp(2*(`theta'))*(-1 + 2*(`mu')^2 + 2*(`sigma')^2)) - 4*$ML_y1^3*(1 - 3*exp(`theta')*(`mu') + exp(3*(`theta'))*(`mu') + exp(2*(`theta'))*(-1 + 2*(`mu')^2 + 2*(`sigma')^2)) + $ML_y1^4*(1 + exp(4*(`theta')) - 4*exp(`theta')*(`mu') + 4*exp(3*(`theta'))*(`mu') + exp(2*(`theta'))*(-2 + 4*(`mu')^2 + 4*(`sigma')^2))))) /// 
   if $ML_y1 > 0 & $ML_y1 < 1
quietly replace `lnf' = ln(2*`sigma'*exp(`theta')/_pi) if $ML_y1 ==0
quietly replace `lnf' = ln(2*`sigma'/(_pi*exp(`theta'))) if $ML_y1 ==1
end
