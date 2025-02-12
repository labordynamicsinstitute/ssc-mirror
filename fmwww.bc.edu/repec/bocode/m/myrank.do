capture set scheme stcolor 

sysuse auto, clear

myrank rank1=mpg
scatter mpg rank1, xla(none) xtitle(Values in order) name(G1, replace)

myrank rank2=mpg, over(foreign) gap(2)
scatter mpg rank2, xla(`mid1' "Domestic" `mid2' "Foreign", tlc(none)) ///
xli(`gap1', lp(solid)) xtitle("") name(G2, replace)

myrank rank3=mpg, over(rep78) gap(2)
scatter mpg rank3, xla(`mid1' "1" `mid2' "2" `mid3' "3" `mid4' "4" `mid5' "5", tlength(0)) ///
xli(`gap1' `gap2' `gap3' `gap4', lp(solid)) xtitle(Repair record 1978) name(G3, replace)

egen mean = mean(mpg), by(rep78)
separate mean, by(rep78) veryshortlabel
scatter mpg rank3, xla(`mid1' "1" `mid2' "2" `mid3' "3" `mid4' "4" `mid5' "5", tlength(0)) ///
xli(`gap1' `gap2' `gap3' `gap4', lp(solid)) xtitle(Repair record 1978) ///
|| line mean? rank3, sort lc(stc2 ..) legend(off) note(horizontal lines show means) ///
ytitle("`: var label mpg'") name(G4, replace)

tabstat rank1, s(min max)

tabstat rank2, s(min max) by(foreign)

tabstat rank3, s(min max) by(rep78)

bysort rep78 (mpg) : gen dotrank = _n

graph dot (asis) mpg, over(dotrank, label(nolabels)) over(rep78) ///
linetype(line) lines(lc(gs12) lw(vvthin)) vertical nofill exclude0 ///
b2title(Repair record 1978) name(G5, replace)

. 


