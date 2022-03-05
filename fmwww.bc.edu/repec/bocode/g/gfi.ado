*!  gfi.ado 	Version 5.0	RL Kaufman 		10/4/2017

***  	1.0 Work with standard MAIN INT2 INT3 option specification 
***			MAIN string contains (varlist1, name(word) range(numlist)) (varlist2, name(word)  range(numlist))
***			Pass all this information to definefm.ado to define focal & moderator variables and their properties
***		1.1 Added option for two different path diagrams, full shows all paths/coeff default isolates focal var
***		1.2	Added option to pick model equation name for ceofficients if not default EQName
***		1.3 Added specifying 3way present for calling SCMOD2 or sign change table
***		1.4 Added processing of options witihn PATH(ptype , pathopt)  PTYPE= all or focal.
***			PATHOPTS are  TItle(string asis) name(string) BOXWidth(real 1.25) ygap(real .625) xgap(real 1.25) BFORM(%fmt)
***		2.0 Added preserve, removed checking code and generally cleaned up code.  
***			UNDOCUMENTED OPTION: MYGLOB(KEEP) so I can check easily. Added SUMWGT(no) option so user can requested use of unweighted summary statistics.
***		3.0  ADapted to use intspec.ado to set-up and save the globals for the interaction specication for re-use. dropped MYGLOB(Keep) option. SUMWGT now INTSPEC option
***		3.1  Added option for GFI formula for factor change when applicable
***		4.0  Added  functionality for mlogit. 
***		4.1	 Factor expression converted to numbers ( value of exp(b)^Mod instaed of e^b*Mod)
***		4.2	 Fixed saved matrices problem when focal var has moultple effects/categories, adapted to order prob models setup
***		4.3  Added survuval models as allowable for factor change effect (check existence e(t0) = _t0)
***		5.0  Use numdigits globals for setting predictor display formats , change tabf() to ndigit( ) option for consistenvy

program gfi, rclass sortpreserve
version 14.2
syntax  ,[ FACTorchg	NDIGits(integer 4)   path(string asis) ] 
tempname bb estint


***		check if globsave file created by instspec.ado & definefm.ado

if  fileexists("`c(tmpdir)'/globsaveeq1$sfx2.do") ==0 {
	noi disp "{err: Must run intspec.ado to setup and save interaction specification first}"
	exit
}

*** PRESERVE DATA & CURRENT ESTIMATES ON EXIT

preserve
est store `estint' 

loc lsz=`c(linesize)'
qui set linesize 106


***  Loop over # of Equations  (=1 except for mlogit & others TBD)
loc eqitot = ${eqnum$sfx2} 

forvalues eqi=1/ `eqitot' {
loc eqnow: word `eqi' of ${eqlist$sfx2}
if "`eqnow'" == "${eqbase$sfx2}" & ${eqnum$sfx2} > 1 continue

***		load globals created by instspec.ado & definefm.ado
capture drop esamp$sfx
qui run `c(tmpdir)'/globsaveeq`eqi'$sfx2.do

***  Check factorchg option validity
loc fcc "no"
loc bfocfc ""
loc bfocfc2 ""

if "`factorchg'" != "" {
	if inlist("`e(cmd)'","logit","logistic","ologit","mlogit","poisson","nbreg","zip","zinb")==1 | "`e(t0)'" == "_t0" loc fcc "yes"
	if "`fcc'" == "no" 	noi disp _newline "{err: factor change not valid option for {txt: `e(cmd)'}. Option ignored.}"
}

***		Header for GFI results
qui  {
noi disp _newline(2)  as txt "GFI Information from Interaction Specification of"  _newline /// 
	"Effect of " as res "${fvldisp$sfx} on g(${dvname$sfx})" as txt " from `=strproper("`e(title)'")'" _newline "{hline 70}" _newlin
}
** Gather equation for effect of F (bfoc) option factor change (bfocfc),  loop over # cats of F (=1 if interval or single dummy)
mat `bb'=e(b)
forvalues fci=1/${fcnum$sfx} {
	getb, mat(`bb') vn(${fvarc`fci'$sfx}) eqn(${eqname$sfx}) bf(%9.`ndigits'f)
	loc bfoc "`r(bstr)'"
	if "`fcc'" == "yes" { 
		loc bfocfc "e^`r(bstr)'"
		loc bfocfc2 "`=strofreal(exp(`r(bstr)'),"%9.`ndigits'f")'"
	}
	
		forvalues mi=1/${mvarn$sfx} {
		forvalues mci=1/${mcnum`mi'$sfx} {
			getb, mat(`bb') vn(${f`fci'm`mi'c`mci'$sfx}) eqn(${eqname$sfx}) bf(%9.`ndigits'f)
			loc sgn= sign(`r(bstr)')
			if `sgn' >= 0 {
				loc bfoc "`bfoc' + `r(bstr)'*${mvname`mi'c`mci'$sfx}"
				if "`fcc'" == "yes" {
					loc bfocfc  "`bfocfc' * e^(`r(bstr)'*${mvname`mi'c`mci'$sfx})"
					loc bfocfc2  "`bfocfc2' * `=strofreal(exp(`r(bstr)'),"%9.`ndigits'f")'^${mvname`mi'c`mci'$sfx}"
				}
			}
			if `sgn' < 0{
				loc bneg=subinstr("`r(bstr)'","-","",1)
				loc bfoc "`bfoc' - `bneg'*${mvname`mi'c`mci'$sfx}"
				if "`fcc'" == "yes" {
					loc bfocfc 	"`bfocfc' * e^(- `bneg'*${mvname`mi'c`mci'$sfx})"
					loc bfocfc2  "`bfocfc2' * `=strofreal(exp(`r(bstr)'),"%9.`ndigits'f")'^${mvname`mi'c`mci'$sfx}"
				}
			}
		}
	}
	if "${int3way$sfx}" == "y" {
		forvalues mc1i=1/${mcnum1$sfx} {
		forvalues mc2i=1/${mcnum2$sfx} {
			getb, mat(`bb') vn(${f`fci'm1c`mc1i'm2c`mc2i'$sfx}) eqn(${eqname$sfx}) bf(%9.`ndigits'f)
			loc sgn= sign(`r(bstr)')
			if `sgn' >= 0 {
				loc bfoc "`bfoc' + `r(bstr)'*${mvname1c`mc1i'$sfx}*${mvname2c`mc2i'$sfx}"
				if "`fcc'" == "yes" {
					loc bfocfc  "`bfocfc' * e^(`r(bstr)'*${mvname1c`mc1i'$sfx}*${mvname2c`mc2i'$sfx})"
					loc bfocfc2  "`bfocfc2' * `=strofreal(exp(`r(bstr)'),"%9.`ndigits'f")'^(${mvname1c`mc1i'$sfx}*${mvname2c`mc2i'$sfx})"
				}
			}
			if `sgn' < 0 {
				loc bneg=subinstr("`r(bstr)'","-","",1)
				loc bfoc "`bfoc' - `bneg'*${mvname1c`mc1i'$sfx}*${mvname2c`mc2i'$sfx}"
				if "`fcc'" == "yes" {
					loc bfocfc 	"`bfocfc' * e^(- `bneg'*${mvname1c`mc1i'$sfx}*${mvname2c`mc2i'$sfx})"			
					loc bfocfc2  "`bfocfc2' * `=strofreal(exp(`r(bstr)'),"%9.`ndigits'f")'^(${mvname1c`mc1i'$sfx}*${mvname2c`mc2i'$sfx})"
					}
			}
		}
		}
	}

disp as txt "Effect of ${fvnamec`fci'$sfx} = " _newline as res "{p 3 6} `bfoc'" _newline
if "`fcc'" == "yes" disp as txt _newline "   Factor Change Effect (1 unit change in) ${fvnamec`fci'$sfx} = " _newline as res "{p 6 6} `bfocfc'  = " _newline ///
	 _newline as res "{p 6 6} `bfocfc2'   " _newline
}
}

forvalues eqi=1/ `eqitot' {
loc eqnow: word `eqi' of ${eqlist$sfx2}
if "`eqnow'" == "${eqbase$sfx2}" & ${eqnum$sfx2} > 1 continue
***		load globals created by instspec.ado & definefm.ado
capture drop esamp$sfx
qui run `c(tmpdir)'/globsaveeq`eqi'$sfx2.do

***		Create Sign Change Table
if ${mvarn$sfx} ==1	scmod1 , modn(1) eqn(${eqname$sfx}) bf(%9.`ndigits'f)

if ${mvarn$sfx} ==2  scmod2 , mod1(1) mod2(2) int3("${int3way$sfx}") bf(%9.`ndigits'f) 
}

***		Create path diagram if requested ***********************************

if `"`path'"' != "" {
forvalues eqi=1/ `eqitot' {
loc eqnow: word `eqi' of ${eqlist$sfx2}
if "`eqnow'" == "${eqbase$sfx2}" & ${eqnum$sfx2} > 1 continue
***		load globals created by instspec.ado & definefm.ado
capture drop esamp$sfx
qui run `c(tmpdir)'/globsaveeq`eqi'$sfx2.do

*** DETEMINE WHAT g(DV) IS FOR EACH MODEL AND INCOPORATE INTO PROGRAM

gettoken ptype pathopt : path , parse(",")
gettoken garb pathopt : pathopt , parse(",")

if "`ptype'" == "focal" pathdiag , eqnow(`eqnow') eqn(${eqname$sfx}) `pathopt'
if "`ptype'" == "all" pathdiagfull , eqnow(`eqnow') eqn(${eqname$sfx}) `pathopt'
}
}

qui set linesize `lsz'
*if ${fcnum$sfx} > 1 {
forvalues fci=1/${fcnum$sfx} {
	mat sc=r(scf`fci')
	return mat SCf`fci'=sc
	mat SCcol=r(SCcolf`fci')
	return mat SCcolf`fci' = SCcol
	mat SCrow=r(SCrowf`fci')
	return mat SCrowf`fci' = SCrow
}
*}
loc mygloblist:  all globals "*$sfx"
mac drop `mygloblist'

*
qui est restore `estint'

end

