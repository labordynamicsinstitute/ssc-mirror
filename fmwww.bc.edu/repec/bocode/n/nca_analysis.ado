*! nca_analysis v1.0 09/09/2025
program define nca_analysis, eclass
syntax [anything] [if] [in] [, *]
version 17
if !replay() {
	nca_estimate `0' 
	if (e(testrep)>0)  nca_perm,reps(`e(testrep)')
}
else { // replay
	if "`e(cmd)'"!="nca_analysis" error 301
}
ereturn hidden local est_cmd=	"nca_estimate `0' "
nca_display, `options' 
end

