*! Part of package matrixtools v. 0.31
*> 2023-09-13 > bug in IF fixed
*> 2023-08-14 > IF added
program define _gmarktop
	version 13
	gettoken type 0 : 0
	gettoken vn   0 : 0
	gettoken eqs  0 : 0    /* known to be = */
	syntax varlist (min=1 max=1 numeric) [if/], /*
    */[ /*
      */Top(integer 5) /*
      */Singles(numlist) /*
      */Other(string) /*
      */Replace /*
    */]

    capture drop __marktopvar
    capture label drop __marktoplbl
    if "`if'" != "" local if & `if'
    if "`other'" == "" local other other
    mata: __singles = J(1, 0, .)
    if "`top'" != "" & `top' > 0 mata: __singles = __singles, nhb_sae_outliers("`varlist'", `top')'
    if "`singles'" != ""  mata: __singles = __singles, strtoreal(tokens("`singles'"))
    mata: select_singles("$EGEN_Varname", "`varlist'", "`other'", __singles)
    quietly generate double __marktopvar = cond(inlist(`varlist', `__marktop'), `varlist', .r) if !missing(`varlist') `if'
    label copy `:value label `varlist'' __marktoplbl
    label define  __marktoplbl .r "`other'", modify
    label values __marktopvar __marktoplbl
    strofnum __marktopvar
    strtonum __marktopvar, label($EGEN_Varname)
    quietly generate `vn' = __marktopvar
    label values `vn' $EGEN_Varname
    drop __marktopvar
    label drop __marktoplbl
end

mata:
    void select_singles(
        string scalar nvar, 
        string scalar var, 
        string scalar other, 
        real rowvector singles
        )
    {
    	rowvector lbls
        
        lbls = nhb_sae_labelsof(var, singles)' \ other
        st_local("__marktop", invtokens(strofreal(singles), ", "))
        if ( st_vlexists(nvar) ) st_vldrop(nvar)
        st_vlmodify(nvar, 1::(abs(cols(singles))+1),  lbls)
    }
end
