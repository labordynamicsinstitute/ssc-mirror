* Author Iain Snoddy, 1 October 2021, iainsnoddy@gmail.com


program define pathmaker
  	version 13.0
	syntax anything(name=root),	[Ignore(string) low  ///
									 Back ]		

	if "`root'"==""{
		di as error "Folder must be Provided"
		exit
	}									 							 
	
	if "`back'"=="" local root = subinstr("`root'","\","/",.)
	else local root = subinstr("`root'","/","\",.)
	
	global root "`root'"
	disp `"global root "`root'""'
	
	local dlist : dir "${root}" dirs "*", respectcase
	
	foreach xyz of local dlist {
		local counter = 0
		
		local abc = subinstr("`xyz'"," ","",.)
		local x = strlower("`xyz'")
		local a = strlower("`abc'")
		
		foreach foldern of local ignore{
			local y = strlower("`foldern'")
			if "`x'" == "`y'" local counter = 1
		}
		
		if `counter' == 0 {
			
			if "`low'"!="" & "`back'"=="" {
				cap global `a' "${root}/`xyz'"
				local rc _rc
				if `rc'==0{	
					disp `"global `a' "${root}/`xyz'""'
				}
			}
			else if "`low'"!="" & "`back'"!="" {
				cap global `a' "${root}\\`xyz'"
				local rc _rc
				if `rc'==0{	
					disp `"global `a' "${root}\\`xyz'""'
				}
			}
			else if "`back'"=="" {
				cap global `abc' "${root}/`xyz'" 
				local rc _rc
				if `rc'==0{	
					disp `"global `abc' "${root}/`xyz'""'
				}
			}
			else {
				cap global `abc' "${root}\\`xyz'" 
				local rc _rc
				if `rc'==0{	
					disp `"global `abc' "${root}\\`xyz'""'
				}
			} 
		}
	}
		
end
