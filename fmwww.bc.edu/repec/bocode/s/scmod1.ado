*!  scmod1.ado 	Version 1.3 	RL Kaufman 		10/4/2016

***  	1.0  Creates sign change analysis table for single moderator.  Renamed from defscrow and called Version 1.0.  Called by GFI.ADO.
***		1.1  Made functional for adding columns for categorical focal effects
***			 Only input is MODN = moderator number, typically 1 for a single moderator analysis
***			 Could be other moderator from a mujltiple moderator analysis looking at each mod separately
***		1.2  Switched from using getb.ado to coeff in global macros
***		1.3  Changed from arg to syntax style, added option for reformatting coefficients. Now uses value labels from global macros
***		2.0  Removed checking code and generally cleaned up code. Added SUMWGT(no) option so user can requested use of unweighted summary statistics.

program scmod1, rclass
version 14.2
syntax ,  modn(integer) [ EQNname(string) BForm(string) ]
tempvar predpos 
tempname bb
mat `bb'=e(b)
if "`eqname'" != "" loc eqndisp ":`eqname'"
loc bnowform "%10.0g"
if "`bform'" != "" loc bnowform "`bform'"
***		initialize predpos tempvar so can always use replace command when need to calculate % positive effects
qui gen `predpos'=.

***		rlist = numlist of values of the moderator if interval but =  moderator category # if nominal , 0=base
***		rlab = value labels (=rlist) for interval moderator but = display names for categorires for nominal
loc rlist "${mvrange`modn'$sfx}"
loc nlab: list sizeof global(mvrange`modn'$sfx)
loc rlab ""

forvalues mci=1/`nlab' {
	loc rlab "`rlab' ${mvlabm`modn'c`mci'$sfx}"
}
***		Loop over #of focal var categories in sets of 4 per table, creating additional tables as needed	
***		For each type of table row (Header, B Sign/Value, Sign Changes, %Positive) loop over categories of focal var
qui{
***		Define # of repititions in sets of 4,  repittiion # IREP runs from  FCI= 1+(`irep'-1)*4' to `fcmax' limited to last category FCN
	loc fcn=${fcnum$sfx}
	loc frep=int(`fcn'/4)
	if mod(`fcn',4) != 0 loc frep=`frep'+1
	
forvalues irep=1/`frep' {
	loc fcmax=min(4+(`irep'-1)*4,`fcn')
	
*** 	define last point/position of row and line length for results box
	loc lastpt=17+(`fcmax'-(`irep'-1)*4)*22
	loc linlgth= `lastpt'-15

***		FMTSTR = string formatting a row	RESSTR = string containing row results/content used for mata printf function
***		Print table title then header.  Loop over FCI to create column of results for focal category #= FCI
	loc fmtstr ""
	loc resstr ""
	loc tabnum ""
	if `frep' > 1 loc tabnum ", Panel `irep' of `frep'"

	noi disp _newline  as txt `" Sign Change Analysis of Effect of {bf:${fvldisp$sfx}}"' ///
		_newline `" on g({bf:${dvname$sfx}`eqndisp'}), Moderated by {bf:${mvldisp`modn'$sfx}} (MV)"'"`tabnum'" _newline
	noi mata: printf(" {txt}{hline 13}{c TT}{hline `linlgth'}\n {col 15}{c |}{col 17}%14s\n","${fvldisp$sfx}") 	
	noi mata: printf(" {txt}%4s{col 15}{c |}  {hline `=`linlgth'-4'}\n","When",) 
		loc fmtstr " {txt}%-12s{col 15}{c |}"
		loc resstr `"${mvldisp`modn'$sfx}="'
	forvalues fci=`=1+(`irep'-1)*4'/`fcmax' {
		loc fmtstr "`fmtstr'{col `=17+(`fci'-1-(`irep'-1)*4)*22'}%13s"
		loc fcat `"${fvnamec`fci'$sfx}"'
		if `fcn'==1 loc fcat `" "'
		loc resstr `"`resstr'","`fcat'"'
		loc nneg`fci'=0
		loc predb`fci' "${bfvarc`fci'$sfx}"	
	}
		noi mata: printf("`fmtstr'\n","`resstr'")
		noi mata: printf("%1s{txt}{hline 13}{c +}{hline `linlgth'}\n"," ") 
		
***		Loop over # of display values/categories of moderator, report row label value/name and sign & value of focal effect
		loc rn: list sizeof rlab
		
		forvalues rni=1/`rn' {
			loc rval: word `rni' of `rlist'
			loc rlabi: word `rni' of `rlab'
**			if ${mcnum`modn'$sfx} == 1 {
**				loc rlabi=string(`rval',"%9.0g")
**			}
			loc fmtstr "{txt}%11s{col 15}{c |}"
			loc resstr `""`rlabi'""'
			
			forvalues fci=`=1+(`irep'-1)*4'/`fcmax' {

***		get BBASE_fci = main effect of focal cat fci and BMOD_fci = 2way coef for focal cat fci * moderator
***			2way effect is moderator cat 1 for interval or moderator cat #=`row value'  (0 for base category)
***			define PREDB_fci = moderated effect prediction function accumulated across moderator categories if nominal

				loc bbase`fci'= ${bfvarc`fci'$sfx}
				loc bmod`fci'= ${bf`fci'm`modn'c1$sfx}
				loc bnow=`bbase`fci''+`rval'*`bmod`fci''
				if ${mcnum`modn'$sfx} > 1 & `rni'> 1 {
					loc bmod`fci'= ${bf`fci'm`modn'c`rval'$sfx}
					loc bnow=`bbase`fci''+`bmod`fci''
					loc predb`fci' "`predb`fci'' + ${mvar`modn'c`rval'$sfx}*`bmod`fci''"
				}
				if ${mcnum`modn'$sfx} == 1 loc predb`fci' "`predb`fci'' + ${mvar`modn'c`rval'$sfx}*`bmod`fci''"
				
***		determine sign of moderated effect & count how many negative effects in col, used for nominal moderator
				loc sgnb=sign(`bnow')
				loc stxt= "Pos"
				if `sgnb'< 0 {
					loc stxt="Neg"
					loc ++nneg`fci'
				}
			loc fmtstr "`fmtstr'{col `=17+(`fci'-1-(`irep'-1)*4)*22'}{res}%8s%10s"
			loc resstr "`resstr',"`stxt'  b = ","`=strofreal(`bnow',"`bnowform'")'""
			}
		* end FCI loop
		
***		Print row of results, Sign b= value
			noi mata: printf("`fmtstr'\n",`resstr') 
		}
		*end RNI loop
		
***	  For nominal moderator report if sign changes acrosss categories: never or sometimes
***	  For interval moderator calculate value where sign changes, report value if within mod max/min or Never if not
		loc fmtstr " {txt}{hline 13}{c +}{hline `linlgth'}\n {txt}%12s{col 15}{c |}"
		loc resstr `"Sign Changes"'
		
		forvalues fci=`=1+(`irep'-1)*4'/`fcmax' {
			loc sigchg = "Never      "
			if ${mcnum`modn'$sfx} > 1  & `nneg`fci'' > 0 & `nneg`fci'' < `rn' loc sigchg "Sometimes   "
			if ${mcnum`modn'$sfx} == 1 {
				loc predb`fci' = "`bbase`fci'' +`bmod`fci''*${mvar`modn'c1$sfx}"  
				summ ${mvar`modn'c1$sfx} if esamp$sfx 
				loc chgval=-`bbase`fci''/`bmod`fci''
				if inrange(`chgval',`r(min)',`r(max)')==1 loc sigchg= `"when MV= `=string(`chgval',"%9.0g")'"'
			}
				loc fmtstr "`fmtstr'{col `=17+(`fci'-1-(`irep'-1)*4)*22'}{res}%18s"
				loc resstr `"`resstr'","`sigchg'"'
		}
***		Print sign change results
		noi mata: printf("`fmtstr'\n","`resstr'") 
		
***		Calculate value for each sample case of moderated effect using formula in PREDB_fci
***		Report % of positive values

		loc fmtstr " {txt}{hline 13}{c +}{hline `linlgth'}\n {txt}%-10s{col 15}{c |}"
		loc resstr `""% Positive""'
		forvalues fci=`=1+(`irep'-1)*4'/`fcmax' {
			replace `predpos'= `predb`fci''>0 if esamp$sfx 
			summ `predpos' if esamp$sfx  ${sumwgt$sfx}
			loc pctpos=`r(mean)'*100
			loc fmtstr "`fmtstr'{col `=17+(`fci'-1-(`irep'-1)*4)*22'}{res}%12.1f"
			loc resstr `"`resstr',`pctpos'"'		
		}
***		Print % Positive results and then return to top loop if need additional repetitions of table
		noi mata: printf("`fmtstr'\n",`resstr') 
		noi mata: printf("%1s{txt}{hline 13}{c BT}{hline `linlgth'}\n"," ") 	
	}
}
end
