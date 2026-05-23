*! version 1.0.0 22may2026

prog _upsetlabfetch, sclass
	
	version 18.5
	
	sreturn clear
	
	syntax [anything], varmax(real) [ format(string) ]
	
	if ("`format'" != "") confirm format `format'
	
	if regexm(`"`anything'"', "^##[0-9]+$") {
		di as err `"Minor ticks not supported: {bf:`anything'} was ignored"'
		local anything ""
	}
	
	if (`"`anything'"' != "none") {
		
		if (`"`anything'"' == "") {
			
			_upsettickplace `varmax'
			local ticks = s(ticks)
			local tickmax = s(tickmax)
			local labs = s(ticks)
			
		}
		
		else if (`"`anything'"' == "minmax") {
			
			local ticks 0 `varmax'
			local tickmax = `varmax'
			local labs 0 `varmax'
			
		}
		
		else if regexm(`"`anything'"', "^#([0-9]+)$") {
			
			_upsettickplace `varmax', want(`=regexs(1)')
			local ticks = s(ticks)
			local tickmax = s(tickmax)
			local labs = s(ticks)
			
		}
		
		else {
			
			cap numlist `"`anything'"'
			
			if _rc {
				di as err `"invalid label `anything'"'
				exit 198
			}
			
			_upsetruleparse `r(numlist)'
			local ticks = s(ticks)
			local tickmax = s(tickmax)
			local labs = s(labs)
			
		}
		
		sreturn clear
		
		sreturn local ticks "`ticks'"
		sreturn local tickmax = `tickmax'
		sreturn local labs `"`labs'"'
		
	}
	
end

prog _upsettickplace, sclass
	
	sreturn clear
	
	syntax anything, [ want(integer 5) ]
	
	local rawstep = `anything' / `want'
	
	local magnitude = floor(log10(`rawstep'))
	
	local bestscore = -1
	local bases "1 2 3 4 5"
	
	foreach base of local bases {
		
		forvalues mag_adj = -1 / 1 {
			
			local step = `base' * 10 ^ (`magnitude' + `mag_adj')
			
			local end = ceil(`anything' / `step') * `step'
			
			local nticks = ceil(`end' / `step') + 1
			
			if !inrange(`nticks', 3, max(`want', 10)) continue
			
			local endgap = (`end' - `anything') / `end'
			
			// Tick separation
			if `base' == 1 local score1 = 1
			else if `base' == 5 local score1 = 0.9
			else if `base' == 2 local score1 = 0.8
			else local score1 = 0.6
			
			// Margin
			local score2 = max(0, 1 - abs(`endgap' - 0.1))
			
			// Tick number
			local score3 = max(0, 1 - abs(`nticks' - `want') / `want')
			
			local scoretotal = `score1' + `score2' + `score3'
			
			if `scoretotal' > `bestscore' {
				
				local bestscore = `scoretotal'
				local bestend = `end'
				local beststep = `step'
				local bestnticks = `nticks'
				
			}
			
		}
		
	}
	
	if (`bestscore' == -1) {
		di as err "internal error: please specify tick placement manually"
		exit 197
	}
	
	forvalues i = 1 / `bestnticks' {
		local ticks `ticks' `= (`i' - 1) * `beststep''
	}
	
	sreturn local tickmax `bestend'
	sreturn local ticks `ticks'
		
end
