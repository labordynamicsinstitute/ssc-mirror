pro def nca_display
syntax [, * noSUMmaries]
 local ceilings=e(ceilings)
gettoken first ceilings:ceilings
local corners `e(corners)'

	cap confirm matrix e(bottlenecks) 
	if (!_rc) nca_display_bottleneck_table
foreach x in `e(indepvars)' {
	

	/*if (!_rc) {
		gettoken corner corners : corners
		local ceilings `e(ceilings)'
		foreach c of local ceilings {
		local c2: subinstr local c  "_" "-"
		local c2=strupper("`c2'")
		matlist (e(bottlenecks)[ 1..rowsof(e(bottlenecks)) , "`x':`e(depvar)'"] ,e(bottlenecks)[ 1..rowsof(e(bottlenecks)) , "`x':`c'"]), twidth(20) title("{bf: Bottlenecks: `x' - `e(depvar)' (`c2') }  (`e(bnecks_subtitle)', corner=`corner')") lines(eq)  names(columns) 
		}
		
	}*/
	
	

	if ("`summaries'"=="nosummaries") continue
	cap confirm matrix e(empirical_scopemat)
	if (_rc) matlist e(results)[1..6,"`x':`first'"],   twidth(25) names(rows)  title("NCA Parameters - condition: {bf: `x'} , outcome: {bf: `e(depvar)'}") format(%10.1f)
	else {
	tempname empirical_summary	
	matrix 	`empirical_summary'= e(results)[1..6,"`x':`first'"]	
	matrix 	`empirical_summary'[3,1]=e(empirical_scopemat)["`x'",1]
	matrix 	`empirical_summary'[4,1]=e(empirical_scopemat)["`x'",2]
	matrix 	`empirical_summary'[5,1]=e(empirical_scopemat)["`e(depvar)'",1]
	matrix 	`empirical_summary'[6,1]=e(empirical_scopemat)["`e(depvar)'",2]
	matrix `empirical_summary'[2,1]=(`empirical_summary'[6,1]-`empirical_summary'[5,1])*(`empirical_summary'[4,1]-`empirical_summary'[3,1])
	matrix `empirical_summary'=(`empirical_summary',e(results)[1..6,"`x':`first'"])
	matrix colnames `empirical_summary'="empirical" "theoretical"
	matlist `empirical_summary' ,   twidth(25)   title("NCA Parameters - condition: {bf: `x'} , outcome: {bf: `e(depvar)'}") format(%10.1f)
	}
	
	
	if (e(testrep)>0) matlist e(results)[7..11, "`x':"]\ e(testres)[1..2,"`x':"],   twidth(20)  names(all)
	else matlist e(results)[7..11, "`x':"],   twidth(25)   names(all)
	matlist e(results)[12..17, "`x':"],  twidth(25)    names(all)
	}
	
if ("`e(memorygraph)'"!="") di _newline(1)"graphs {bf:`e(memorygraph)'} have been saved, check {bf: graph dir}" 

end
