use weakivtest2

loc L = ceil(1.3*200^(1/2))
ivreg2 y X1 X2 (Y1 Y2 = Z1 Z2 Z3 Z4 Z5), robust bw(`L') 
weakivtest2



