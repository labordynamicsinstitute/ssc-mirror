program asinhcauchyouterv3
version 13
args lnf mu theta lsigma
tempvar sigma 
quietly gen double `sigma' = exp(`lsigma')
quietly replace `lnf' = ln((exp((`theta') + asinh(((`mu') + (1/tan(_pi*$ML_y1)))/(`sigma')))*_pi*(1/sin(_pi*$ML_y1))^2)/((exp(`theta') + exp(asinh(((`mu') + (1/tan(_pi*$ML_y1)))/(`sigma'))))^2*(`sigma')*sqrt(1 + ((`mu') + (1/tan(_pi*$ML_y1)))^2/(`sigma')^2))) /// 
   if $ML_y1 > 0 & $ML_y1 < 1
quietly replace `lnf' = ln(_pi*`sigma'*exp(`theta')/2) if $ML_y1 ==0
quietly replace `lnf' = ln(_pi*`sigma'/(2*exp(`theta'))) if $ML_y1 ==1
end
