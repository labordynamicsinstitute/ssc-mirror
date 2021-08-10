*! aaniv 1.1.0 24Feb2021 austinnichols@gmail.com
*! switch to using -sureg- instead of -ivreg2- with partial option
* aaniv 1.0.2 12July2019 still used ivreg2 which failed to save 1st and 2nd stage estimates system in some cases for no obvious reason
* aaniv 1.0.1 10July2019 also had some typos
* aaniv 1.0.0 3July2019 had some typos
prog def aaniv, eclass
version 11.2
if replay() {
  syntax [anything] [, EForm(string) Level(real 95) ]
  eret di, eform(`eform') level(`level')
  }
else {
 syntax [anything(name=0)] [if] [in] [aw fw pw iw/] [, deltase ivreg2 IVOptions(string asis) * ]
		ivparse `0'
		local y	`s(lhs)'
		local endo `s(endo)'
		local x `s(inexog)'
		local exexog `s(exexog)'
 cap assert wordcount(`"`y'"')==1
 if _rc!=0 {
  error 198
  }
 cap assert wordcount(`"`endo'"')==1
 if _rc!=0 {
  di as err "current version only supports one endogenous treatment variable"
  error 198
  }
 cap assert wordcount(`"`exexog'"')==1
 if _rc!=0 {
  di as err "current version only supports one excluded exogenous variable (i.e. one instrument)"
  error 198
  }
 if "`ivreg2'"!="" {
  cap which ivreg2
  if _rc!=0 {
   cap ssc inst ivreg2
   }
  }
 if "`x'"=="" loc partial "_cons"
 else loc partial `x'
 if "`exp'"=="" loc wtexp
 else loc wtexp "[`weight'=`exp']"
 if "`ivreg2'"!="" {
  tempvar yy
  qui g double `yy'=`y'
  qui ivreg2 `yy' (`endo'=`exexog') `x' `wtexp' `if' `in', partial(`partial') noid savesfirst savesfprefix(S) `ivoptions'
  tempname iv se b v delta x2 tau beta B V 
  tempvar touse
  g byte `touse'=e(sample)
  scalar `iv'=_b[`endo']
  scalar `se'=_se[`endo']
  qui est rest Ssfirst_`yy'
  mat `b'=e(b)
  mat `v'=e(V)
  }
 else {
  if "`ivoptions'"=="" loc ivoptions "vce(robust)"
  tempname iv se b v delta x2 tau beta B V yp xp zp inuse
  qui reg `y' `x' `endo' `exexog' `exp'  `if' `in'
  g byte `inuse'=e(sample)
  qui reg `y' `x' `wtexp' if (`inuse'==1)
  predict double `yp' if (`inuse'==1), res  
  qui reg `endo' `x' `wtexp' if (`inuse'==1)
  predict double `xp' if (`inuse'==1), res  
  qui reg `exexog' `x' `wtexp' if (`inuse'==1)
  predict double `zp' if (`inuse'==1), res  
  qui ivregress 2sls `yp' (`xp'=`zp') `wtexp' if (`inuse'==1), `ivoptions'
  scalar `iv'=_b[`xp']
  scalar `se'=_se[`xp']
  qui sureg (`yp' `zp', nocons) (`xp' `zp', nocons) `wtexp', `options'
  tempvar touse
  g byte `touse'=e(sample)
  mat `b'=e(b)
  mat `v'=e(V)
  }
 if !("`deltase'"=="") {
   scalar `se'=sqrt(`v'[1,1]/`b'[1,2]^2+`v'[2,2]*`b'[1,1]^2*`b'[1,2]^(-4)-`v'[1,2]*`b'[1,1]*`b'[1,2]^(-3))
   }
 else scalar `delta'=.
 scalar `delta'=`b'[1,1]-`b'[1,2]*`v'[1,2]/`v'[2,2]
 scalar `x2'=-abs(`b'[1,2]/sqrt(`v'[2,2]))
 scalar `tau'=normal(`x2')/normalden(`x2')/sqrt(`v'[2,2])
 if mi(`=normal(`x2')/normalden(`x2')') {
  di as err "inverse Mills ratio out of bounds; substituting unity for estimated Mills ratio"
  scalar `tau'=(`v'[2,2]^(-1/2))
  loc converged=0
  }
 else loc converged=1
 scalar `beta'=(`delta')*(`tau')+`v'[1,2]/`v'[2,2]
 mat `B'=scalar(`beta')
 mat `V'=scalar(`se')^2
 mat rownames `B'=y1
 mat colnames `B'=`endo'
 mat rownames `V'=`endo'
 mat colnames `V'=`endo'
 qui count if `touse'
 loc N = r(N)
 eret post `B' `V', esample(`touse')
 ereturn scalar N = `N'
 ereturn local depvar "`y'"
 ereturn scalar converged=`converged'
 ereturn local version "1.1.0"
 ereturn local cmd "aaniv"
 ereturn local properties "b V"
 eret di, eform(`eform') level(`level')
 }
end

* below adapted from -ivreg2- on SSC (itself adapted from official Stata -ivreg-):
program define ivparse, sclass
	version 11.2
		syntax [anything(name=0)]	
		local n 0
		gettoken lhs 0 : 0, parse(" ,[") match(paren)
		IsStop `lhs'
		while `s(stop)'==0 {
			if "`paren'"=="(" {
				local ++n
				if `n'>1 { 
di as err `"syntax is "(all instrumented variables = instrument variables)""'
					exit 198
				}
				gettoken p lhs : lhs, parse(" =")
				while "`p'"!="=" {
					if "`p'"=="" {
di as err `"syntax is "(all instrumented variables = instrument variables)""'
di as err `"the equal sign "=" is required"'
						exit 198
					}
					local endo `endo' `p'
					gettoken p lhs : lhs, parse(" =")
				}
				local exexog `lhs'
			}
			else {
				local inexog `inexog' `lhs'
			}
			gettoken lhs 0 : 0, parse(" ,[") match(paren)
			IsStop `lhs'
		}
// lhs attached to front of inexog
		gettoken lhs inexog	: inexog
		local endo			: list retokenize endo
		local inexog		: list retokenize inexog
		local exexog		: list retokenize exexog
		sreturn local lhs			`lhs'
		sreturn local endo			`endo'
		sreturn local inexog		`inexog'
		sreturn local exexog 		`exexog'
		sreturn local partial		`partial'

end
program define IsStop, sclass
				/* sic, must do tests one-at-a-time, 
				 * 0, may be very large */
	version 11.2
	if `"`0'"' == "[" {		
		sret local stop 1
		exit
	}
	if `"`0'"' == "," {
		sret local stop 1
		exit
	}
	if `"`0'"' == "if" {
		sret local stop 1
		exit
	}
* per official ivreg 5.1.3
	if substr(`"`0'"',1,3) == "if(" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "in" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "" {
		sret local stop 1
		exit
	}
	else sret local stop 0
end
