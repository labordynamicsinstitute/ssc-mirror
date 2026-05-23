*! version 1.0.0 22may2026

prog _upsetruleparse, sclass
	
	version 18.5
	
	sreturn clear
	
	syntax anything, [ admit(string) labvar(string) INTeger ]
	
	local raw_rhs `anything'
	
	qui while (`"`raw_rhs'"' != "") {
		
		// Expand out any NUMLISTs
		gettoken raw_lhs raw_rhs : raw_rhs, quotes
		
		cap numlist `"`raw_lhs'"'
		
		if !_rc {
			local cumnum "`cumnum' `r(numlist)'"
			local rhs `"`rhs' `r(numlist)'"'
		}
		
		else local rhs `"`rhs' `raw_lhs'"'
		
	}
	
	if ("`admit'" != "") {
		local appendrhs : list admit - cumnum
		local rhs `"`rhs' `appendrhs'"'
	}
	
	local toExclude = 0 	// Check value validity if ADMIT option specified
	local needNumber = 1 	// Track whether the last value was numeric
	local lhsPrev "" 		// Track last value in case label is not specified
	
	while (`"`rhs'"' != "") {
		
		gettoken lhs rhs : rhs, quotes qed(quoted)
		
		if (`toExclude') & (`quoted') local toExclude = 0
		
		else if (`needNumber') & (`quoted') {
			
			di as err `"Invalid label specification {bf:`anything'}"'
			exit 198
			
		}
		
		else if (`quoted') {
			
			local labs `"`labs' `lhs'"'
			local userLabs `userLabs' 1
			local toExclude = 0
			local needNumber = 1
			local lhsPrev ""
			
		}
		
		else {
			
			confirm `integer' number `lhs'
			
			if ("`: list admit & lhs'" != "") | ("`admit'" == "") {
				
				local ticks `ticks' `lhs'
				local toExclude = 0
				local needNumber = 0
				
				qui cap if ("`lhsPrev'" != "") {
					
					if ("`labvar'" == "") local addlab `"`lhsPrev'"'
					else local addlab `"`: label (`labvar') `lhsPrev''"'
					
					local labs `"`labs' `"`addlab'"'"'
					
					local userLabs `userLabs' 0
					
				}
				
				local lhsPrev `lhs'
				
			}
			
			else local toExclude = 1
			
		}
		
	}
	
	// Add label if omitted from specification
	
	qui cap if !(`quoted' | `toExclude') {
		
		if ("`labvar'" == "") local addlab `"`lhsPrev'"'
		else local addlab `"`: label (`labvar') `lhsPrev''"'
		
		local labs `"`labs' `"`addlab'"'"'
		
		local userLabs `userLabs' 0
		
	}
	
	mata: st_local("tickmax", strofreal(max(strtoreal(tokens("`ticks'")))))
	
	sreturn local labs `"`: list clean labs'"'
	sreturn local userlabs "`userLabs'"
	sreturn local ticks "`: list clean ticks'"
	sreturn local tickmax = `tickmax'
	
end
