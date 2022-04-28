capture program drop pzms_custom
program define pzms_custom, eclass
syntax anything, [COVS(varlist) KERNEL(string) WEIGHT(varname)]
tokenize "`anything'"

ereturn local custom_covs "`covs'"
ereturn local custom_kernel "`kernel'"
ereturn local custom_weight "`weight'"
ereturn scalar lp = `1'
ereturn scalar rp = `2' 
end
