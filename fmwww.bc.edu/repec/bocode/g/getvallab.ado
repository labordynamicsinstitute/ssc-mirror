*!  getvallab.ado 	Version 1.0		RL Kaufman 	06/10/2016

***  	1.0 Get Value labels for a variable (including factor var root) using MATA.
***			Called by DEFINEFM

program getvallab, rclass
version 14.2
args vname vval

mata: vind=st_varindex("`vname'")
mata: valdeflab=st_varvaluelabel(vind)
mata: st_global("vlexst$sfx",valdeflab)

if "${vlexst$sfx}" != "" {
mata: vlab=st_vlmap(valdeflab,`vval')
mata: st_local("vlab", vlab)
return loc vlab `"`vlab'"'
}
if "${vlexst$sfx}" == "" return loc vlab "" 
end
