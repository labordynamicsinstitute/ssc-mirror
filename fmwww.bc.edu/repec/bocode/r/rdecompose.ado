/*! rdecompose.ado, 0.4.3 Jinjing Li, 8/1/2022
*----------------------------------------------------------------------
*                                       Revision history :
* 0.4.3: Fix a bug when the variable name contains "_"
* 0.4.2: Corrections in output
* 0.4.1: Minor format updates
* 0.4.0: Baseline selection
* 0.3.0: multi comparisons 
* 0.2.0: with direct effect
* 0.1.2: Add if support
* 0.1.1: Add transform() feature; fixed the bug in function specifications
* 0.1.0: First complete version
* 0.0.2: functional form
* 0.0.1: First development version
*
*----------------------------------------------------------------------

*----------------------------------------------------------------------
*                                       Description :
*
* This program decomposes the rate differences between two population groups using Gupta's method
*
*----------------------------------------------------------------------

*----------------------------------------------------------------------
*                                       Syntax :
*
* rdecompose varlist [if] , group(varname) [sum(varlist)  detail function(string) force reverse TRANSform(varlist)]
*
*----------------------------------------------------------------------*/


/*------------------------------------------------ MAIN -------- */
/*------------------------------------------------ rdecompose */

program define rdecompose , eclass sortpreserve
version 12.0
if replay() {
if (`"`e(cmd)'"'!="rdecompose") {
noi di as error "results for rdecompose not found"
exit 301
}
rDisplay `0'
exit `rc'
}
else Decompose `0'
ereturn local cmdline `"rdecompose `0'"'
end
program define Decompose, eclass
syntax varlist(numeric) [if], Group(varname) [sum(varlist)] [Detail] [FUNCtion(string asis)] [force] [reverse] [TRANSform(varlist numeric)] [multi] [BASEline(real -9999999)] [Outcome(varname)]
tempname grouplevel
qui levelsof `group' `if', local(`grouplevel')
loc i=0
foreach l of local `grouplevel' {
loc ++i
loc group`i'value `l'
if (("`baseline'"!="-9999999") & ("`baseline'"=="`l'")) {
loc matched_base `i'
}
}
if `i'==1 {
di as error "There needs to be 2 groups"
exit 322
}
if (("`baseline'"!="-9999999") & ("`matched_base'"=="")) {
di as error "Baseline value `baseline' not found in `group'"
exit 322
}
else {
if "`matched_base'"!="" {
loc temp "`group1value'"
loc group1value "`group`matched_base'value'"
loc group`matched_base'value "`temp'"
}
}
if "`outcome'"!="" & "`function'"!="" {
di as error "outcome and function options cannot be selected at the same time."
exit 322
}
if `i' >2 {
if "`multi'"=="" {
di as error "option [multi] is required if there are more than two groups"
exit 322
}
forvalues j=2/`i' {
tempname nif
cap confirm numeric variable `group'
if _rc!=0 {
loc subif `"(`group'=="`group1value'"|`group'=="`group`j'value'")"'
}
else {
loc subif "(`group'==`group1value'|`group'==`group`j'value')"
}
if "`if'"=="" {
loc `nif' "if `subif'"
}
else {
loc `nif' "`if' & `subif'"
}
rDecompose `varlist' ``nif'', group(`group') sum(`sum') `detail' function(`function') `force' `reverse' transform(`transform') baseline(`baseline') outcome(`outcome')
}
}
else {
rDecompose `varlist' `if', group(`group') sum(`sum') `detail' function(`function') `force' `reverse' transform(`transform') baseline(`baseline') outcome(`outcome')
}
end
program define rDecompose, eclass
syntax varlist(numeric) [if], Group(varname) [sum(varlist)] [Detail] [FUNCtion(string asis)] [force] [reverse] [TRANSform(varlist numeric)] [BASEline(real -9999999)] [Outcome(varname)]
loc factors "`varlist'"
if "`function'"=="" {
loc i=1
foreach v of local factors {
if `i'==1 {
loc function "`v'"
}
else {
loc function "`function'*`v'"
}
loc ++i
}
}
foreach v of local transform {
tempvar t_sum_`v'
qui bys `group': egen double `t_sum_`v''=sum(`v') `if'
}
tempvar testvar
cap gen `testvar'=`function' `if'
cap count if `testvar'!=.
if (_rc!=0|r(N)==0) {
di as text "The function specified does not appear to be valid"
if length("`force'")==0 {
exit 322
}
}
tempvar original_sum sum_combination
loc `original_sum' "`sum'"
if "`sum'"=="" {
tempvar sum_replacement
gen byte `sum_replacement'=0
loc sum `sum_replacement'
}
loc i=1
foreach sumvar of local sum {
loc sumvar`i'_name "`sumvar'"
qui levelsof `sumvar' `if', local(sumvar_`i')
loc lcount=0
foreach l of local sumvar_`i' {
loc ++lcount
loc sumfactor_`i'_`lcount'_value `l'
}
loc sumvar_`i'_length=`lcount'
loc ++i
}
loc i=1
loc `sum_combination'=1
foreach sumvar of local sum {
loc `sum_combination'=``sum_combination'' * `sumvar_`i'_length'
loc ++i
}
loc num_of_sums=`i' - 1
tempname s_res sum_cond factor_index
forvalues s=1/``sum_combination'' {
loc `s_res'=`s'
loc `sum_cond' ""
forvalues c=1/`num_of_sums' {
loc `factor_index'=mod(``s_res'', `sumvar_`c'_length') + 1
cap confirm numeric variable `sumvar`c'_name'
if _rc!=0 {
loc `sum_cond' ``sum_cond'' & `sumvar`c'_name'=="`sumfactor_`c'_``factor_index''_value'"
}
else {
loc `sum_cond' "``sum_cond'' & `sumvar`c'_name'==`sumfactor_`c'_``factor_index''_value'"
}
loc `s_res'=int(``s_res''/`sumvar_`c'_length') + ``factor_index''
}
tempname nif`s'
if "`if'"=="" {
loc `nif`s'' "if 1 ``sum_cond''"
}
else {
loc `nif`s'' "`if' ``sum_cond''"
}
}
tempname grouplevel
qui levelsof `group' `if', local(`grouplevel')
loc i=0
foreach l of local `grouplevel' {
loc ++i
loc group`i'value `l'
if (("`baseline'"!="-9999999") & ("`baseline'"=="`l'")) {
loc matched_base `i'
}
}
if `i'==1 {
di as error "There needs to be 2 groups"
exit 322
}
if (("`baseline'"!="-9999999") & ("`matched_base'"=="")) {
di as error "Baseline value `baseline' not found in `group'"
exit 322
}
else {
if "`matched_base'"!="" {
loc temp "`group1value'"
loc group1value "`group`matched_base'value'"
loc group`matched_base'value "`temp'"
}
}
if "`reverse'"!="" {
tempname temp_gv
loc `temp_gv'=`group1value'
loc group1value=`group2value'
loc group2value=``temp_gv''
}
tempname final_diff factor_count factor_name total_N b_overall final_rate1 final_rate2
loc `final_diff'=0
loc `total_N'=0
loc `final_rate1'=0
loc `final_rate2'=0
tempname factormat
loc transform_count=0
forvalues s=1/``sum_combination'' {
loc `factor_count'=0
tempname display_name mat_name
foreach v of local factors {
loc extra_name ""
forvalues g=1/2 {
cap confirm numeric variable `group'
if _rc!=0 {
qui sum `v' ``nif`s''' & `group'=="`group`g'value'"
}
else {
qui sum `v' ``nif`s''' & `group'==`group`g'value'
}
if r(mean)==. {
di as error "Missing values in group `group' with value `group`g'value'"
exit 322
}
loc `v'_`g'=r(mean)
capture confirm variable `t_sum_`v''
if _rc==0 {
sum `t_sum_`v'' ``nif`s''' & `group'==`group`g'value', meanonly
loc `v'_`g'=``v'_`g'' / r(mean)
loc extra_name "(*)"
}
loc `total_N'=``total_N'' + r(N)
}
loc ++`factor_count'
tempname factor_name``factor_count''
loc `factor_name``factor_count''' `v'
loc `display_name' "``display_name'' `v'`extra_name'"
if ``factor_count''==1 {
mat input `factormat'=(``v'_1', ``v'_2')
}
else {
mat `factormat'=(`factormat' \ ``v'_1', ``v'_2')
}
}
tempname total_combination
loc `total_combination'=2^``factor_count''
forvalues withheld_factor=1/``factor_count''{
loc q`withheld_factor'=0
forvalues i=1/``total_combination''{
loc res=`i' -1
loc used_factor=0
loc from_group1=0
loc from_group2=0
loc from_group1offset=0
loc from_group2offset=0
while (`res'!=0|`used_factor' <``factor_count'') {
loc ++used_factor
loc resmod=mod(`res',2)
loc ++from_group`=`resmod'+1'
loc factor_value=`factormat'[`used_factor', `resmod'+1]
if `withheld_factor'==`used_factor' {
loc withheld_group=`resmod' + 1
loc ++from_group`=`resmod'+1'offset
}
loc res=int(`res'/2)
tempname factor_value`used_factor'
loc `factor_value`used_factor''=`factor_value'
}
tempname c_rate rexpr newfunc
loc `c_rate'=1
loc `newfunc' " `function' "
forvalues j=1/``factor_count'' {
loc rexpr="[^a-zA-Z0-9_]" +"``factor_name`j'''" +"[^a-zA-Z0-9_]"
loc replaced=0
while (regexm("``newfunc''", "`rexpr'")==1) {
loc sub1=substr(regexs(0),1,1)
loc sub2=substr(regexs(0),-1,1)
loc value_string "``factor_value`j'''"
loc replace_string "`sub1'`value_string'`sub2'"
loc `newfunc'=regexr("``newfunc''", "`rexpr'","`replace_string'")
loc ++replaced
}
if `replaced'==0 {
di "Factor ``factor_name`j''' is not used in the function"
exit 332
}
}
loc `c_rate'=``newfunc''
if "`outcome'"!="" {
di "outcome variable is used"
loc ifcondition "if 1"
forvalues j=1/``factor_count'' {
loc ifcondition "`ifcondition' & ``factor_name`j'''==``factor_value`j'''"
}
set trace on
sum `outcome' `ifcondition', meanonly
set trace off
if r(N)!=1 {
di "Outcome value is missing or ambigious for at least one factor combination"
exit 332
}
loc `c_rate'=r(mean)
}
loc denominator=``factor_count''
forvalues j=1/`=`from_group2'- `from_group2offset'' {
if `j' < ``factor_count''{
loc denominator=`denominator' * (``factor_count''-`j') / `j'
}
}
if `withheld_group'==1 {
loc denominator=- `denominator'
}
else {
if `from_group2'==1 {
loc direct_factor`withheld_factor'=``c_rate''
}
}
loc q`withheld_factor'=`q`withheld_factor'' + ``c_rate'' /`denominator'
}
}
tempname b total_diff
loc total_rate1=1
loc total_rate2=1
forvalues k=1/2{
forvalues i=1/``factor_count'' {
tempname factor_value`i'
loc `factor_value`i''=`factormat'[`i', `k']
}
tempname c_rate rexpr newfunc
loc `c_rate'=1
loc `newfunc' " `function' "
forvalues j=1/``factor_count'' {
loc rexpr="[^a-zA-Z0-9_]" +"``factor_name`j'''" +"[^a-zA-Z0-9_]"
loc replaced=0
while (regexm("``newfunc''", "`rexpr'")==1) {
loc sub1=substr(regexs(0),1,1)
loc sub2=substr(regexs(0),-1,1)
loc value_string "``factor_value`j'''"
loc replace_string "`sub1'`value_string'`sub2'"
loc `newfunc'=regexr("``newfunc''", "`rexpr'","`replace_string'")
loc ++replaced
}
if `replaced'==0 {
di "Factor ``factor_name`j''' is not used in the function"
exit 332
}
loc `c_rate'=``c_rate'' * ``factor_value`j'''
}
loc `c_rate'=``newfunc''
if "`outcome'"!="" {
di "outcome variable is used"
loc ifcondition "if 1"
forvalues j=1/``factor_count'' {
loc ifcondition "`ifcondition' & ``factor_name`j'''==``factor_value`j'''"
}
sum `outcome' `ifcondition', meanonly
if r(N)!=1 {
di "Outcome value is missing or ambigious for at least one factor combination"
exit 332
}
loc `c_rate'=r(mean)
}
loc total_rate`k'=``c_rate''
}
loc `total_diff'=`total_rate2'-`total_rate1'
tempname dfactor
forvalues i=1/``factor_count'' {
loc diff=`q`i''
if `i'==1 {
mat input `b'=(`diff')\
mat input `dfactor'=(`=`direct_factor`i''-`total_rate1'')
}
else {
mat `b'=(`b', `diff')
mat `dfactor'=(`dfactor', `=`direct_factor`i''-`total_rate1'')
}
}
matrix colname `dfactor'=``display_name''
matrix colname `b'=``display_name''
if `s'==1 {
matrix `b_overall'=`b'
matrix colname `b_overall'=``display_name''
}
else {
matrix `b_overall'=(`b_overall' \ `b')
}
if _rc!=0 {
}
loc `s_res'=`s'
loc `sum_cond' ""
forvalues c=1/`num_of_sums' {
loc `factor_index'=mod(``s_res'', `sumvar_`c'_length') + 1
cap matrix `b_sumfactor_`c'_``factor_index'''=(`b_sumfactor_`c'_``factor_index'''\ `b')
if _rc!=0 {
tempname b_sumfactor_`c'_``factor_index''
matrix `b_sumfactor_`c'_``factor_index'''=`b'
matrix colname `b_sumfactor_`c'_``factor_index'''=`factors'
}
loc `s_res'=int(``s_res''/`sumvar_`c'_length') + ``factor_index''
}
loc `final_diff'=``final_diff'' + ``total_diff''
loc `final_rate1'=``final_rate1'' + `total_rate1'
loc `final_rate2'=``final_rate2'' + `total_rate2'
}
mat `b'=J(1,``sum_combination'',1) * `b_overall'
forvalues c=1/`num_of_sums' {
tempname b_sumfactor_`c' next_one temp_mat
loc n=1
while (1) {
cap mat `next_one'=`b_sumfactor_`c'_`n''
if _rc!=0{
continue, break
}
loc nrows rowsof(`next_one')
mat `temp_mat'=J(1,`nrows',1) * `next_one'
cap matrix `b_sumfactor_`c''=(`b_sumfactor_`c'' \ `temp_mat')
if _rc!=0 {
matrix `b_sumfactor_`c''=`temp_mat'
matrix colname `b_sumfactor_`c''=``display_name''
}
loc ++n
}
mat rownames `b_sumfactor_`c''=`sumvar_`c''
}
ereturn post `b' , obs(``total_N'')
ereturn matrix direct_b=`dfactor'
if "``original_sum''"!="" {
forvalues c=1/`num_of_sums' {
ereturn matrix sum_`c'=`b_sumfactor_`c''
}
}
if "`detail'"=="detail" {
ereturn scalar detail_view=1
}
else {
ereturn scalar detail_view=0
}
ereturn scalar diff=``final_diff''
ereturn scalar rate1=``final_rate1''
ereturn scalar rate2=``final_rate2''
ereturn local sum_factor "``original_sum''"
ereturn local cmd "rdecompose"
ereturn local title "Decomposition using Generalised Gupta(1991) Method"
ereturn local group "`group'"
ereturn local basegroup_value "`group1value'"
ereturn local comparison_value "`group2value'"
loc display_r1=trim("`: display %18.2f ``final_rate1'''")
loc display_r2=trim("`: display %18.2f ``final_rate2'''")
ereturn local desc1 `"Decomposition between `group'==`group1value' (`display_r1')"'
ereturn local desc2 `"and `group'==`group2value' (`display_r2')"'
tempname overall_function
loc `overall_function' ""
if "``original_sum''"!="" {
foreach v of local sum {
loc `overall_function' "``overall_function''\sum(`v')"
}
loc `overall_function' "``overall_function''{`function'}"
ereturn local overall_function "``overall_function''"
}
else {
ereturn local overall_function "`function'"
}
ereturn local transformed "`transform'"
ereturn local function "`function'"
rDisplay
end
program define rDisplay
loc diopts "`options'"
loc fmt "%12.3g"
loc fmtprop "%8.2f"
tempname nfactor result_b result_prop factor_name result_df
mat `result_b'=e(b)
mat `result_df'=e(direct_b)
loc `nfactor'=colsof(`result_b')
loc colname: colnames `result_b'
tokenize `colname'
display
di as text e(desc1)
di as text %18s "" _c e(desc2) _newline
di as text "Func Form=`=e(overall_function)'"
di as txt "{hline 72}"
di as text %25s "Component" _c
di as text %28s "Absolute Difference" _c
di as text %18s "Proportion (%)"
di as txt "{hline 72}"
forvalues i=1/ ``nfactor'' {
loc direct_contr=`result_df'[1,`i']
loc contribute=`result_b'[1,`i']
loc prop=`contribute' / e(diff) * 100
loc `factor_name'=abbrev("``i''", 15)
di as result %25s "``factor_name''" _c
di as result %28s `"`:display `fmt' `contribute' '"' _c
di as result %14s `"`:display `fmtprop' `prop' '"'
}
di as txt "{hline 72}"
loc f=0
tempname factor_list subfactor_name
loc factor_list=e(sum_factor)
if ("`factor_list'"!="." & e(detail_view)==1) {
foreach sumfactor of local factor_list {
loc ++f
loc `factor_name'=abbrev("`sumfactor'", 10)
di as text %35s "Value of ``factor_name'' and Components" _c
di as text %32s "Detailed Contributions"
di as txt "{hline 72}"
matrix `result_b'=e(sum_`f')
loc result_row=rowsof(`result_b')
forvalues j=1/ `result_row' {
loc rowname: rownames `result_b'
tokenize `rowname'
loc group_name=abbrev("``j''", 13)
loc colname: colnames `result_b'
tokenize `colname'
forvalues i=1/ ``nfactor'' {
loc contribute=`result_b'[`j',`i']
loc prop=`contribute' / e(diff) * 100
loc `subfactor_name'=abbrev("``i''", 15)
di as result %18s "`group_name' " _c
di as result %17s "``subfactor_name''" _c
di as result %18s `"`:display `fmt' `contribute' '"' _c
di as result %14s `"`:display `fmtprop' `prop' '"'
loc group_name ""
}
}
di as txt "{hline 72}"
}
}
di as text %25s "Overall" _c
di as result %28s `"`:display `fmt' `=e(diff)' '"' _c
di as result %14s `"`:display `fmtprop' 100 '"'
di as txt "{hline 72}"
if "`=e(transformed)'"!="." {
di as text "{lalign 50:(*) indicates transformed variables}" _c
}
else {
di as text "{lalign 50:}" _c
}
end
