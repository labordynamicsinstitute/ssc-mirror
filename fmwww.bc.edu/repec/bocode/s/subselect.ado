*! Part of package matrixtools v. 0.28
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
* 2018-08-21 > Added
program define subselect
	syntax varname [if] [in], GENerate(name) [Negate]
	
	mata: nhb_sae_subselect(`"`varlist'"', `"`generate'"', `"`if'"', `"`in'"')
    if "`negate'" != "" replace `generate' = !`generate'
end
