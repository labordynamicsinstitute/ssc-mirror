mata:
void transition_driven_subsmat2(string matrix tabmat, scalar diagincl) {
// Read stata matrix into mata
G=st_matrix(tabmat)

if (rows(G)!=cols(G)) {
_error("Table isn't square")
}

if (diagincl==0) {
  G = G - diag(G)
}

Gr=G:/rowsum(G)
subsmat= trunc(0.5:+(J(rows(G),rows(G),2) - Gr - Gr'):*1000000):/1000000 
subsmat = subsmat - diag(subsmat)
st_matrix(tabmat,subsmat)
}

end

program define trans2subs
syntax varlist(min=1 max=1) [if] [in], IDvar(varname) SUBSmat(string) [DIAgincl]


if ("`diagincl'"=="") {
local diagincl 0
}
else {
local diagincl 1
}


marksample touse
   
local colvar `varlist'
tempvar rowvar

by `idvar': gen `rowvar'=`colvar'[_n-1] if _n>1
   
di "Generating transition-driven substitution matrix"
   
qui tab `rowvar' `colvar' if `touse', matcell(`subsmat')

mata: transition_driven_subsmat2("`subsmat'",`diagincl')
end
