spex ordwarm2
quietly ologit warm yr89 male white age ed prst, nolog
estadd prvalue, x(yr89=0 male=1 prst=20 age=64 ed=16) ///
    brief label(type1)
estadd prvalue, x(yr89=1 male=0 prst=80 age=30 ed=24) ///
    brief label(type2)
estadd prvalue, x(yr89=0) brief label(type3)
estadd prvalue, x(yr89=1) brief label(type4)
estadd prvalue post
esttab, nostar unstack ///
    coeflabels(type1 "old working class men 1977"   ///
               type2 "young prestigious women 1989" ///
               type3 "average individual 1977" ///
               type4 "average individual 1989") ///
    wrap varwidth(18)
