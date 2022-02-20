*! 2.0  16feb2022 Austin Nichols
program define wordy, rclass
version 10 
syntax [anything] [, USEindx(int -1) SUPpresscheck ]
forv j=1/5 {
  wordy`j'
  mata:W`j'=W
  }
mata:allW=W1\W2\W3\W4\W5
if `"`anything'"'!="" {
 loc sw=upper(`"`anything'"')
 cap assert length(`"`sw'"')==5
 if _rc!=0 {
  di as err "You did not type a five-letter word for lookup mode"
  err 198
  }
 forv wi=1/5 {
  loc li=substr(`"`sw'"',`wi',1)
  loc nothere`wi'=1
  foreach w in `c(ALPHA)' ? {
   if "`li'"=="`w'" loc nothere`wi'=0
   }
  }
  if inlist(1,`nothere1',`nothere2',`nothere3',`nothere4',`nothere5') {
   di as err "You must type letters only or ? for a wildcard in a five-letter word"
   err 198
   }
 di as res "Entering lookup mode to search for a 5-letter word matching" _n " the specified pattern `sw'"
 mata:wordyinput=sort(allW,1)
 mata:wordylookit="`sw'"
 mata:wordyres=wordymatch()
 mata:st_global("wordyN",strofreal(rows(wordyres)))
 di as res `"Found `=cond($wordyN!=1,"$wordyN matches","one match")':"'
 mata:wordyshowit()
 }
else {
loc seed=trim("`c(current_date)'")
forv m=1/12 {
 if word("`seed'",2)=="`: word `m' of `c(Mons)''" loc mon=`m'
 }
loc d=mdy(`mon',`=word("`seed'",1)',`=word("`seed'",3)')
loc indx=mod(`d',8938)
if `useindx'>-1 {
 loc useindx=mod(`useindx',8938)
 if `useindx'>8937 {
  di as err "Index must be between 0 and 8937 (highest index possible is 8937)"
  error 198
  }
 loc indx=`useindx'
 }
loc indx=`indx'+1
loc filenum=floor(`indx'/2000)+1
loc filepos=mod(`indx'-1,2000)+1

* initialize correct answer `a'
mata:st_local("a",W[`filepos'])
forv i=1/6 {
 forv j=1/5 {
  glo w_g`i'right`j'=0 
  glo w_g`i'elsew`j'=0
  glo w_g`i'nowhe`j'=0
  glo w_g`i'c`j'=""
  }
 }
loc w_g_left=6
mata:wordyinput=allW
forv g=1/6 {
loc tryagain=1
while `tryagain'==1 {
 di "Type a five-letter word as your guess and hit enter" _request(g`g')
***** check for valid guess; if not valid, return and get another entry
 glo g`g'=upper(`"${g`g'}"')
 cap assert length(`"${g`g'}"')==5
 if _rc!=0 {
  di as err "You did not type a five-letter word"
  continue
  }
 forv wi=1/5 {
  loc li=substr(`"${g`g'}"',`wi',1)
  loc nothere`wi'=1
  foreach w in `c(ALPHA)' {
   if "`li'"=="`w'" loc nothere`wi'=0
   }
  }
  if inlist(1,`nothere1',`nothere2',`nothere3',`nothere4',`nothere5') {
   di as err "You must type letters only in a five-letter word"
   continue
   }
 if "`suppresscheck'"=="" {
  mata:wordylookit="${g`g'}"
  mata:wordyres=wordymatch()
  mata:st_global("wordyN",strofreal(rows(wordyres)))
  if "$wordyN"=="0" {
   di as err "You must guess a legal five-letter word"
   continue
   }
  }
 continue, break
 }
loc cguess "${g`g'}"
loc correct "`a'"
loc row=6-`g'+1
forv j=1/5 {
 glo w_g`row'c`j'=substr(`"${g`g'}"',`j',1)
 }
forv order=1/5 {
 glo w_g`row'right`order'=0
 if substr("`a'",`order',1)==substr("`cguess'",`order',1) {
  glo w_g`row'right`order'=1
  loc cguess=substr("`cguess'",1,`order'-1)+"."+substr("`cguess'",1+`order',5-`order')
  loc correct=substr("`correct'",1,`order'-1)+"."+substr("`correct'",1+`order',5-`order')
  }
 }
forv order=1/5 {
 loc cc=substr("`cguess'",`order',1)
 glo w_g`row'elsew`order'=0
 if "`cc'"!="." {
  loc crepl=strpos("`correct'","`cc'")
  if `crepl'>0 {
   glo w_g`row'elsew`order'=1
   loc cguess=substr("`cguess'",1,`order'-1)+"!"+substr("`cguess'",1+`order',5-`order')
   loc correct=substr("`correct'",1,`crepl'-1)+"!"+substr("`correct'",1+`crepl',5-`crepl')
   }
  }
 }
forv order=1/5 {
 glo w_g`row'nowhe`order'=0
 if !inlist(substr("`cguess'",`order',1),".","!") {
  glo w_g`row'nowhe`order'=1
  }
 }  
loc cx
forv i=1/6 {
 forv j=1/5 {
  loc cx `"`cx'||scatteri `=`i'-.9' `=`j'-.9' `=`i'-.9' `=`j'-.2'  `=`i'-.2' `=`j'-.2'  `=`i'-.2' `=`j'-.9'  `=`i'-.9' `=`j'-.9', recast(area)"'
  if `w_g_left'>`i' {
   loc boxcolor white
   loc lincolor gs0
   }
  else {
   if ${w_g`i'right`j'}==1 {
    loc boxcolor "green"
    loc lincolor "green"
    }
   if ${w_g`i'elsew`j'}==1 {
    loc boxcolor "gold"
    loc lincolor "gold"
    }
   if ${w_g`i'nowhe`j'}==1 {
    loc boxcolor "gray"
    loc lincolor "gray"
    }
   }
  loc cx `"`cx' col(`boxcolor') fi(100) lcol(`lincolor') text(`=`i'-.55' `=`j'-.55' "${w_g`i'c`j'}", place(0))"'
  }
 } 
loc o `"xla(0 " " 5 " ", notick nogrid) yla(-.1 " " 6 " ", notick nogrid) text(6.2 2.5 `"WORDY{&copy} in Stata{&reg}"', place(0)) xsc(off) ysc(off) graphr(fc(white)) aspect(1.2) xsize(4) ysize(5) leg(off)"'
loc w_g_left=`w_g_left'-1
if ${w_g`row'right1}*${w_g`row'right2}*${w_g`row'right3}*${w_g`row'right4}*${w_g`row'right5}==0 {
 if `w_g_left'==0 loc giveaway "The correct answer was `a'"
 tw `cx' `o' `t' text(-.3 2.5 "You have `w_g_left' guess`=cond(`w_g_left'==1,"","es")' remaining" "`giveaway'")
 }
else {
 tw `cx' `o' `t' text(-.3 2.5 "You guessed it with `w_g_left' extra guess`=cond(`w_g_left'==1,"","es")' remaining")
 di as res "You guessed it with `w_g_left' extra guess`=cond(`w_g_left'==1,"","es")' remaining"
 err 42000
 }
}
}
end
version 10
mata: 
string matrix wordymatch()
{
external wordylookit,wordyinput,wordypickit
wordypickit=J(rows(wordyinput),1,0)
for (i=1; i<=rows(wordyinput); i++) {
  wordypickit[i,1] = strmatch(wordyinput[i,1],wordylookit)
 }
return(select(wordyinput,wordypickit))
}
void wordyshowit()
{
external wordyres
for (i=1; i<=rows(wordyres); i++) {
 wordyres[i,1] 
 }
}
real scalar wordyexist()
{
external wordylookit,wordyinput,wordypickit
wordypickit=J(rows(wordyinput),1,0)
for (i=1; i<=rows(wordyinput); i++) {
  wordypickit[i,1] = strmatch(wordyinput[i,1],wordylookit)
 }
return(rows(select(wordyinput,wordypickit)))
}

end

exit

