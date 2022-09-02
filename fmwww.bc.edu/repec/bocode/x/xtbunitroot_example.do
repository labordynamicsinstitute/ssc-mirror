cscript
version 16
capture log close

log using example_do_file.log, replace

cd

************

use xtbunitroot_example.dta 

xtset fed_rssd time
xtbunitroot roa, known(7) normal csd
xtbunitroot roa, unknown(1) normal csd
xtbunitroot roe, unknown(1) normal csd
xtbunitroot tassets, unknown(1) normal csd trend
xtbunitroot nii, unknown(1) normal csd trend

**********
log close

