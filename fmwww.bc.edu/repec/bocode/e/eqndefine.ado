*!  eqndefine.ado Version 1.0	RL Kaufman 	06/01/2016

***  	1.0 Define equation name to be passed to getb or getvb

program eqndefine, rclass
version 14.2
syntax  , [EQNMIN(string asis)]
*** 	Returns EQNM = col/row equation name to strip from e(b) or Var(b)
***			Default if not specified is "e(depvar)" except
*** 	EXCEPT
***     	tobit		`"model"'
***     	regress	  	`"_"'
***     	mlogit user must specify equation number and set to	 # 
if "`eqnmin'" == "" {
	loc eqnm `"`e(depvar)'"'
	if e(cmd)== "regress"  	loc eqnm `"_"'
	if e(cmd)== "tobit"  	loc eqnm `"model"'
	if e(cmd)== "mlogit"  	{
		display as err "Must specify equation number with option eqname(`""#""') since using mlogit"
		error 7
	}
}
return local eqnmout =`"`eqnm'"'
end 
