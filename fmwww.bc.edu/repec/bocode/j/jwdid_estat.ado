*! v1.1 FRA. Adds margins event with labels
* v1 8/5/2022 FRA. Adds margins the right way
program jwdid_estat, sortpreserve   
	version 14
    syntax anything, [*]
        if "`e(cmd)'" != "jwdid" {
                error 301
        }
        gettoken key rest : 0, parse(", ")
        if inlist("`key'","simple","group","calendar","event","all") {
			jwdid_`key'  `rest'
        }
		else {
			display in red "Option `key' not recognized"
				error 199
		}

end

program jwdid_simple, rclass
		syntax, [*]
		//tempvar aux
		//qui:bysort `e(ivar)':egen `aux'=min(`e(tvar)') if e(sample)
		margins  ,  subpop(if __etr__==1) at(__tr__=(0 1)) ///
					noestimcheck contrast(atcontrast(r)) `options' 
end

program jwdid_group, rclass
		syntax, [*]
		tempvar aux
		qui:bysort `e(ivar)':egen `aux'=min(`e(tvar)') if e(sample)
		capture drop __group__
		qui:clonevar __group__ =  `e(gvar)' if __etr__==1 & `aux'<`e(gvar)'
		margins , subpop(if __etr__==1) at(__tr__=(0 1)) ///
				  over(__group__) noestimcheck contrast(atcontrast(r)) `options'
		
		capture drop __group__
end

program jwdid_calendar, rclass
syntax, [*]
		capture drop __calendar__
		tempvar aux
		qui:bysort `e(ivar)':egen `aux'=min(`e(tvar)') if e(sample)
		qui:clonevar __calendar__ =  `e(tvar)' if __etr__==1 & `aux'<`e(gvar)'
		margins , subpop(if __etr__==1) at(__tr__=(0 1)) ///
				over(__calendar__) noestimcheck contrast(atcontrast(r)) `options'

		capture drop __calendar__
end

program jwdid_event, rclass
syntax, [*]
		capture drop __event__
		tempvar aux
		qui:bysort `e(ivar)':egen `aux'=min(`e(tvar)') if e(sample)
		qui:sum `e(tvar)' if e(sample), meanonly
		qui:gen __event__ =  `e(tvar)'-`e(gvar)' if `e(gvar)'!=0 & e(sample) & `e(tvar)'>`r(min)'
		qui:replace __event__ =__event__ - 1 if  __event__ <0
		if "`e(type)'"=="notyet" {
		margins , subpop(if __etr__==1) at(__tr__=(0 1)) ///
				over(__event__) noestimcheck contrast(atcontrast(r)) `options'
		}
		else if "`e(type)'"=="never" {
			capture drop __event2__
			qui:sum __event__, meanonly
			local rmin = r(min)
			qui:gen __event2__=__event__-r(min)
			qui:levelsof __event2__, local(lv)
			foreach i of local lv {
				label define __event2__ `i' "`=`i'+`rmin''", modify
			}
			label values __event2__ __event2__
			margins , subpop(if __tr__==1) at(__tr__=(0 1)) ///
				over(__event2__) noestimcheck contrast(atcontrast(r)) `options'
		}
		matrix rr=r(table)
		return matrix table = rr
		capture drop __event__
end