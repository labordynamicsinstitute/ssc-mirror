*! A program to form all possible combinations of levels of the input varlist
*! v.1.0 by Stas Kolenikov
program define FormXLevels, sclass
   syntax varlist(min=1 numeric) [if] [in], [valuemask(string) missing]
   unab varlist : `varlist'

   local nvar : word count `varlist'

   tempvar first

   marksample touse

   qui bysort `varlist' : gen byte `first' = (_n==1) & `touse'

   if "`missing'" == "" markout `first' `varlist'

   if "`valuemask'" == "" local valuemask $value_mask

   mata : FormXLevels( "`varlist'", "`first'", "`valuemask'" )

   sreturn clear

   forvalues k=1/`nc' {
      sreturn local combo`k' `combo`k''
      sreturn local if`k'    `if`k''
      sreturn local lab`k'   `lab`k''
      if "`vlab`k''"!= "" sreturn local vmlab`k'  `vlab`k''
      else                sreturn local vmlab`k'  `lab`k''
   }
   sreturn local ncombos `nc'

end

* s(lab`k') will be used to get the standard errors
* s(vmlab`k') will be used for my own formatting
* s(if`k') will be used in the if conditions
* s(combo`k') are for reference only

mata

void FormXLevels( string scalar varlist, string scalar selectvar,
     | string scalar valuemask ) {

   string vector levels, ifs, varl, label, vlabel;
   string scalar Xs, vm;
   real scalar nvar, i, j, nc;

   varl = tokens(varlist)

   st_view(X=.,.,varl,selectvar )

   nvar = length( varl )
   nc = rows( X )

   levels = J(nc,1,"")
   ifs = J(nc,1,"")
   label = J(nc,1,"")
   vlabel = J(nc,1,"")
   for( i=1; i<=nc; i++ ) {
     for( j=1; j<=nvar; j++ ) {
        Xs = strofreal( X[i,j] )
        levels[i] = levels[i] + " " + Xs
        ifs[i]    = ifs[i] + " & " + varl[j] + " == " + Xs
        if (label[i]=="") label[i] = Xs
        else              label[i] = label[i] + "_" + Xs
        if (valuemask!="") {
          vm = valuemask
          _substr(vm,Xs,strlen(vm)-strlen(Xs)+1)
          if (vlabel[i]=="") vlabel[i] = vm
          else              vlabel[i] = vlabel[i] + "_" + vm
        }
        else {
          if (vlabel[i]=="") vlabel[i] = Xs
          else              vlabel[i] = vlabel[i] + "_" + Xs
        }
        if (nvar>1) label[i] = "_subpop_" + strofreal(i)
     }
     st_local( "combo"+strofreal(i), levels[i] )
     st_local( "if"+strofreal(i), ifs[i] )
     st_local( "lab"+strofreal(i), label[i] )
     st_local( "vlab"+strofreal(i), vlabel[i] )
   }
   st_local( "nc", strofreal(nc) )
}

end
// of mata

exit


History:
v.1.0   29 Feb 2010 -- the basic functionality of forming the levels
        27 Mar 2010 -- if condition added