*! version 1.2 Nov 2023
*! author Daniele Spinelli (daniele.spinelli@unimib.it)

pro def _get_elements, sclass // parser of rows and column numbers, it is used simmetrically in submatrix to return the permutation vector of the rows (columns) set by the subusetting options 
syntax namelist (min=1 max=1 name=mat id="matrix"), keepnum(numlist >0 integer  missingokay) [keepname(string asis) dropnum(numlist >0 integer  missingokay) dropname(string asis)  row col ignore namesfirst varlist]
version 15
if (missing(`keepnum') & missing(`dropnum') & `"`keepname'"'==`""' & `"`dropname'"'==`""' )	{
	sreturn local keep="."
	exit 
}
if ("`varlist'"!="") { // expand the varlist in keepname and drop name (if the user specifies varlist)
	foreach opt in keepname dropname {
	cap fvexpand ``opt''
	if _rc {
		if ("`opt'"=="keepname") display as error "option {bf: `row'`col'names:} ", _continue 
		else display as error "option {bf: drop`row'`col'names:} ", _continue 
		fvexpand ``opt''
		}
	else local `opt' "`r(varlist)'"
	}
}
local num_elements=`row'`col'sof(`mat')

///parsing numbers to keep
if ("`keepnum'"!=".") {
	if ("`ignore'"=="") {
	cap numlist "`keepnum'", range(<=`num_elements') missingokay
	if (_rc) {
		di as error "{bf: `row'`col'num} has elements outside of allowed range. members of {bf: `row'`col'num} must be <= `num_elements'"
		exit _rc
		}
	}
	else foreach n of numlist `:copy local keepnum' {
		if (`n'>`num_elements') {
			di in red "WARNING: `row'`col' `n' is outside of allowed range. ignoring it"
			local keepnum:  subinstr local keepnum "`n'" "", all
			}
		}
	
}

///parsing names to keep
if ("`varlist'"!="") local ignore ignore
foreach name of local keepname {
	*local cn=`row'`col'numb(`mat' , "`name'")
	mata:  st_local("cn", `row'`col'numb2("`mat'",`"`name'"'))


	if ("`cn'"==""){ //aborting the execution of there are non-existing elements in keepname (unless ignore is specified)
	if ("`ignore'"=="")  { 
		di in red "error in option {bf: `row'`col'name}: `name' not found in `row'`col's of `mat'."
		exit 125
		}
	else if ("`varlist'"=="") di in red "WARNING: `name' not found in `row'`col's of `mat'. ignoring it"
	
	}
	else local _keepnames `_keepnames' `cn'	
}


foreach name of local dropname {
	*local cn=`row'`col'numb(`mat' , "`name'")
		mata:  st_local("cn", `row'`col'numb2("`mat'",`"`name'"'))

	if ("`cn'"==""){ //aborting the execution of there are non-existing elements in dropname (unless ignore is specified)
	if ("`ignore'"=="")  { 
		di in red "error in option {bf: drop`row'`col'name}: `name' not found in `row'`col's of `mat'."
		exit 125
		}
	else if ("`varlist'"=="") di in red "WARNING: `name' not found in `row'`col's of `mat'. ignoring it from {bf: drop`row'`col'name}"
	
	}
	else local _dropnames `_dropnames' `cn'	
}
local todrop `dropnum' `_dropnames' //final list of row (or column number to be dropped)

if ("`namesfirst'"!="") local tokeep `_keepnames' `keepnum' //final list of row (or column number to be kept)
else local tokeep `keepnum' `_keepnames' 
if ("`tokeep'"=="." & "`todrop'"!="") {
	numlist "1(1)`num_elements'"
	local tokeep `r(numlist)' 
}
else  local tokeep: subinstr local tokeep "." "", all	
local tokeep:  list tokeep - todrop

sreturn local keep="`tokeep'"
end


pro def submatrix, rclass
syntax namelist (min=1 max=1 name=mat id="matrix"), [rownames(string asis) colnames(string asis) rownum(numlist >0 integer) colnum(numlist >0 integer) dropcolnum(numlist >0 integer) droprownum(numlist >0 integer) droprownames(string asis) dropcolnames(string asis) NAMesfirst IGNore ROWVarlist COLVarlist]
version 17
confirm matrix `mat'
if ("`colnum'"=="") local colnum . //numeric missing value means that all column (rows) must be kept in colnum and rownum
if ("`rownum'"=="") local rownum .
if ("`dropcolnum'"=="") local dropcolnum . //numeric missing value means that none of the column (rows) must be kept in dropcolnum and droprownum
if ("`droprownum'"=="") local droprownum .
 local colvarlist: subinstr local colvarlist "col" "", all	
 local rowvarlist: subinstr local rowvarlist "row" "", all

 _get_elements `mat', keepnum(`colnum') dropnum(`dropcolnum') keepname(`colnames') dropname(`dropcolnames') col `namesfirst' `ignore' `colvarlist'
local cols `s(keep)'

_get_elements `mat', keepnum(`rownum') dropnum(`droprownum') keepname(`rownames') dropname(`droprownames') row `namesfirst' `ignore' `rowvarlist'
local rows `s(keep)'

if (missing(`rows') & missing(`cols')) { //in case rows and columns are missing (meaning that all rows and column must be selected) return an error and exit
	di in red "WARNING: command specification results in no subsetting"
	exit 
}
local rows: subinstr local rows " " ",", all // changeing rows and column to be comma-separated so that it can be read as vectors by Mata
local cols: subinstr local cols " " ",", all
 
 tempname _return
mata: _sub_mat("`_return'", "`mat'", (`rows'),(`cols'))

return matrix mat=`_return'

end


//Mata function that return matrix out from string in (name of the Stata matrix to be subset) using permutation vectors _cols _rows
mata:
void _sub_mat(string scalar out, string scalar in, real vector _rows , real vector _cols ) {
string matrix rowstripe, colstripe
rowstripe=st_matrixrowstripe(in)[_rows,.]
colstripe=st_matrixcolstripe(in)[_cols,.]
st_matrix( out , st_matrix(in)[_rows,_cols] )	
st_matrixrowstripe(out, rowstripe  )
st_matrixcolstripe(out, colstripe  )
 
}

 
 string scalar colnumb2(string scalar mat, string scalar names) {
 	 real vector v
	 v=.
	 real vector condition
	if (length(tokens(names, ":"))==3) { //equations + names
	string vector stripe
 	stripe=st_matrixcolstripe(mat)[.,1]:+":":+st_matrixcolstripe(mat)[.,2]
	condition=stripe:==names
	if (all(!condition)) return("")
	v=selectindex(condition)
	if (v==0) return("")
	return( invtokens(strofreal(v')))
	}	
	 
names=tokens(names, ":") 	 
if (length(names)==1) { //names
 	 names=names[1]
	condition=(st_matrixcolstripe(mat):==names)[.,2]
	if (all(!condition)) return("")
	v=selectindex(condition)
	return( invtokens(strofreal(v')))
	}
 if (length(names)==2) { //eqs
	names=names[1]
	condition=(st_matrixcolstripe(mat):==names)[.,1]
	if (all(!condition)) return("")
	v=selectindex(condition)	
	return( invtokens(strofreal(v')))
 }
 }
 
 string scalar rownumb2(string scalar mat, string scalar names) {
 	 real vector v
	 v=.
	 real vector condition
	if (length(tokens(names, ":"))==3) { //equations + names
	string vector stripe
 	stripe=st_matrixrowstripe(mat)[.,1]:+":":+st_matrixrowstripe(mat)[.,2]
	condition=stripe:==names
	if (all(!condition)) return("")
	v=selectindex(condition)
	return( invtokens(strofreal(v')))
	}	
	 
names=tokens(names, ":") 	 
if (length(names)==1) { //names
 	 names=names[1]
	condition=(st_matrixrowstripe(mat):==names)[.,2]
	if (all(!condition)) return("")
		v=selectindex(condition)
	return( invtokens(strofreal(v')))
	}
 if (length(names)==2) { //eqs
	names=names[1]
	condition=(st_matrixrowstripe(mat):==names)[.,1]
	if (all(!condition)) return("")
	v=selectindex(condition)	
	return( invtokens(strofreal(v')))
 }

 }
end

