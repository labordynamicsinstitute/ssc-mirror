* clean_name 7/31/2025 Bouguen Adrien
cap program drop clean_name
program clean_name
version 16.0
syntax varname, gen(string) [case(string)]

capture confirm variable `gen'
    if !_rc {
        di as error "Variable `gen' already exists."
        exit 198
    }
quiet {
dis "`varlist'"
	gen strL `gen'=lower(`varlist')
	* a
	replace `gen'=subinstr(`gen',"à","a",.)
	replace `gen'=subinstr(`gen',"À","a",.)
	replace `gen'=subinstr(`gen',"Á","a",.)
	replace `gen'=subinstr(`gen',"á","a",.)
	replace `gen'=subinstr(`gen',"â","a",.)
	replace `gen'=subinstr(`gen',"Â","a",.)
	replace `gen'=subinstr(`gen',"Á","A",.)
	replace `gen'=subinstr(`gen',"Â","A",.)
	replace `gen'= subinstr(`gen', "`=char(224)'","a",. )

	* u
	replace `gen'=subinstr(`gen',"Ù","u",.)
	replace `gen'=subinstr(`gen',"Ú","u",.)
	replace `gen'=subinstr(`gen',"Ü","u",.)
	replace `gen'=subinstr(`gen',"ü","u",.)
	replace `gen'=subinstr(`gen',"Ù","u",.)
	replace `gen'=subinstr(`gen',"Ú","u",.)
	replace `gen'=subinstr(`gen',"Ü","u",.)
	
	* e
	replace `gen'=subinstr(`gen',"È","e",.)
	replace `gen'=subinstr(`gen',"Ê","e",.)
	replace `gen'=subinstr(`gen',"É","e",.)
	replace `gen'=subinstr(`gen',"Ë","e",.)
	replace `gen'=subinstr(`gen',"è","e",.)
	replace `gen'=subinstr(`gen',"ê","e",.)
	replace `gen'=subinstr(`gen',"é","e",.)
	replace `gen'=subinstr(`gen',"ç","c",.)
	replace `gen'=subinstr(`gen',"è","e",.)
	replace `gen'=subinstr(`gen',"ê","e",.)
	replace `gen'=subinstr(`gen',"é","e",.)
	replace `gen'=subinstr(`gen',"ë","e",.)
	replace `gen'=subinstr(`gen',"Ê","e",.)
	replace `gen'=subinstr(`gen',"Ë","e",.)
	replace `gen'=subinstr(`gen',"É","e",.)
	replace `gen'=subinstr(`gen',"È","e",.)
 	replace `gen'=subinstr(`gen', "`=char(234)'","e",. )
	replace `gen'=subinstr(`gen', "`=char(233)'","e",. )
	replace `gen'=subinstr(`gen', "`=char(232)'","e",. )
	* i 
	replace `gen'=subinstr(`gen',"Ï","i",.)
	replace `gen'=subinstr(`gen',"Ï","i",.)
	replace `gen'=subinstr(`gen',"ï","i",.)
	
	* o
	replace `gen'=subinstr(`gen',"ô","o",.)
	replace `gen'= subinstr(`gen', "`=char(244)'","o",. )
	replace `gen'=subinstr(`gen',"ñ","n",.)
	replace `gen'=subinstr(`gen',"ç","c",.)
	replace `gen'= subinstr(`gen', "`=char(231)'","c",. )	
		
	* space 
	replace `gen'=ustrtrim(`gen')
	replace `gen'=subinstr(`gen',"`=char(160)'","",.)
	replace `gen'=subinstr(`gen',"'"," ",.)
	replace `gen'=subinstr(`gen',"-"," ",.)
	replace `gen'=trim(`gen') 
	replace `gen'=subinstr(`gen',"    "," ",.)
	replace `gen'=subinstr(`gen',"   "," ",.)
	replace `gen'=subinstr(`gen',"  "," ",.)
	replace `gen'=subinstr(`gen',"-"," ",.)
	replace `gen'="" if `gen'=="."
	* labels

	local l: variable label  `varlist'
	label var `gen' "`l' (cleaned)"

	* case
	if "`case'"=="proper" {
		replace `gen'=proper(`gen')
	}
	if "`case'"=="upper" {
		replace `gen'=upper(`gen')
	}
}	

end