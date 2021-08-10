*! version 1.0.0 11Apr2016 MLB
program define stdtable_ex
if `1' == 1 {
	Msg preserve
	preserve
	Xeq use "http://www.maartenbuis.nl/software/mob.dta", clear
	Xeq tab row col [fw=pop]
	restore
	Msg restore
}
else if `1' == 2 {
	Msg preserve
	preserve
	Xeq use "http://www.maartenbuis.nl/software/mob.dta", clear
	Xeq stdtable row col [fw=pop]
	restore
	Msg restore
}
else if `1' == 3 {
	Msg preserve
	preserve
	Xeq use "http://www.maartenbuis.nl/software/interracial.dta", clear
	Xeq stdtable hrace wrace [fw=_freq], by(coh)
	restore
	Msg restore
}
else if `1' == 4 {
	Msg preserve
	preserve
	Xeq use "http://www.maartenbuis.nl/software/interracial.dta", clear
	Xeq stdtable hrace wrace [fw=_freq], by(coh) replace
	Xeq tabplot hrace coh [iw=std],                ///
    by(wrace, compact cols(3) note(""))     ///
	xtitle("husband's birth cohort" "wife's race") ///
    xlab(1(2)18,angle(35) labsize(vsmall))
	restore
	Msg restore
}

else if `1' == 5 {
	Msg preserve
	preserve
	Xeq use "http://www.maartenbuis.nl/software/interracial.dta", clear
	Xeq stdtable hrace wrace [fw=_freq], by(coh, baseline(1980))
}
end

program Msg
    di as txt
    di as txt "-> " as res `"`macval(0)'"'
end

program Xeq
    di as txt
    di as txt `"-> "' as res `"`0'"'
    `0'
end
