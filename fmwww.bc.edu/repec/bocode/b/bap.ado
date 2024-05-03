*! version 0.1 2024-04-23 Niels Henrik Bruun	
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2023-12-16 v0.1 created
program define bap, rclass
		version 14.2
		
    syntax varlist(min=2 max=2 numeric) [if], /* 
      */[ /* 
          */noGraph /* 
          */Formatgraph(string) /*
          */Text(string) /*
          */Scatterstyle(string) /*
          */Meanlinestyle(string) /*
          */LOAlinestyle(string) /*
          */Roweq(string) /*
          */LOWess /*
          */Keepvariables /*
          */ * /* 
      */]
    if `"`formatgraph'"' == "" local formatgraph "%4.1f"
    if `"`scatterstyle'"' == "" local scatterstyle jitter(3)
    if `"`meanlinestyle'"' == "" local meanlinestyle lcolor(gs8) lpattern(solid)
    if `"`loalinestyle'"' == "" local loalinestyle lcolor(gs8) lpattern(dash)
    if `"`formatgraph'"' == "" local formatgraph "%4.1f"
    tokenize `"`varlist'"'
    local lbl1 `:var l `1''
    if "`lbl1'" == "" local lbl1 `1'
    local lbl2 `:var l `2''
    if "`lbl2'" == "" local lbl2 `2'
    if `"`text'"' == "" local text `lbl1' vs `lbl2'
		local w = min(max(strlen("`lbl1'"), strlen("`lbl2'"), strlen("`roweq'")) + 2, 32)
    quietly g _d = `1' - `2' `if'
    quietly g _m = (`1' + `2') / 2 `if'
		quietly means `1' `if'
    matrix bap = r(N), r(mean), r(lb), r(ub)
		quietly means `2' `if'
    matrix bap = bap \ r(N), r(mean), r(lb), r(ub)
		quietly means _d `if'
    matrix bap = bap, ((r(mean), r(lb), r(ub), sqrt(r(Var) / r(N))) \ J(1,4,.))
    matrix bap[1,8] = bap[1,8] / sqrt(2)
    quietly summarize _d `if'
    local lb_loa = r(mean) - invnormal(0.975) * r(sd)
    local ub_loa = r(mean) + invnormal(0.975) * r(sd)
    matrix bap = bap, ((`lb_loa', `ub_loa') \ J(1,2,.))
    matrix coleq bap = Measurements Measurements Measurements ///
        Measurements Bias Bias Bias Agreement LOA LOA
    matrix colnames bap = n mean [95% CI] diff [95% CI] SEM [lower upper]
		matrix roweq bap = `roweq'
		matrix rownames bap = "`lbl1'" "`lbl2'"
    if "`graph'" == "" {
				if `"`lowess'"' == "" local lowess function y = `r(mean)', range(_m)
				else local lowess lowess _d _m `if', 
				local grphcmd scatter _d _m `if', `scatterstyle' || `lowess' `meanlinestyle' ///
					|| function y = `lb_loa', `loalinestyle' range(_m) ///
					|| function y = `ub_loa', `loalinestyle' range(_m) ///
					legend(order(1 "`text'" 2 "BIAS = `=string(`=r(mean)', "`formatgraph'")'" ///
            3 `"LOA [`=string(`lb_loa', "`formatgraph'")'; `=string(`ub_loa', "`formatgraph'")']"') ///
						rows(1) position(6)) ///
            yline(0, lcolor(gs8))  `options'
				`grphcmd'
    }
		matlist bap, keepcoleq showcoleq(lcombined) twidth(`w')
    return matrix bap = bap
		return local grphcmd = `"`grphcmd'"'
		if "`keepvariables'" == "" drop _d _m
end
/*
cls
clear
input id w1 w2 mw1 mw2
1 494 490 512 525
2 395 397 430 415
3 516 512 520 508
4 434 401 428 444
5 476 470 500 500
6 557 611 600 625
7 413 415 364 460
8 442 431 380 390
9 650 638 658 642
10 433 429 445 432
11 417 420 432 420
12 656 633 626 605
13 267 275 260 227
14 478 492 477 467
15 178 165 259 268
16 423 372 350 370
17 427 421 451 443
end
label variable w1 "PEFR 1, Wright (l/min)"
label variable w2 "PEFR 2, Wright (l/min)"
label variable mw1 "PEFR 1, mini Wright (l/min)"
label variable mw2 "PEFR 2, mini Wright (l/min)"

bap mw1 mw2, name(g1, replace)
bap mw1 mw2, name(g1, replace) loa(lp(dot) lc(red) lw(thick)) m(lc(green))
bap mw1 mw2, name(g1, replace) loa(lp(dot) lc(red) lw(thick)) m(lc(green)) s(mcolor(red))
*/