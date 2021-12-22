*******ttestex version 1.2-16.12.2021
*******by Annina Hittmeyer

*capture program drop ttestex 
program define ttestex 
	version 14.2

syntax namelist(min=1) [if], rownum(integer) colnum(integer) crosscuts(string) per(integer)  [space(integer 0)]  [depvars2(string)] [title(string)] [note(string)] [samw (string)]

if !missing(`"`samw'"'){
if `colnum'<=0 | `rownum'<=0 {
display "Pick a number larger 0"
}
*
if `colnum'<=0 & `rownum'<=0 {
display "Pick a number larger 0"
}
*
if `colnum'>=1 & `rownum'>=1 {
if missing(`"`title'"') {
if missing(`"`if'"') {
if missing(`"`depvars2'"') {
***GEN LETTER 
tempvar letterprog
gen `letterprog'= `colnum' - 1
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownum' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog'
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
***PUT DEPVAR LABELS & p-value title & totals
foreach varprog in `namelist' {
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownum'="`a'" 
putexcel `locletterprogp'`rownum'="p-value" 
local moy = `rownum' + 1 
qui sum `varprog' [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 
}
*
tempvar letterprog
gen `letterprog'= `colnum' - 1

foreach cprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)
qui sum `varprog', detail
qui sum `cprog' if `varprog'==`r(min)' [weight=`samw']
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mean)'*`per', nformat(0.00) 
****MEAN 2 (and CI)
qui sum `varprog', detail
qui sum `cprog' if `varprog'==`r(max)' [weight=`samw']
putexcel `locletterprog'`levelsprog_2'= `r(mean)'*`per', nformat(0.00) 
*** MEAN p-value 
qui ttest `cprog', by(`varprog')
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
*
if !missing(`"`depvars2'"'){
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
***GEN LETTER 
tempvar letterprog
gen `letterprog'= `colnum' - 1
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownum' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog'
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
***BUT DEPVAR LABELS & p-value title & totals
foreach varprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownum'="`a'" 
putexcel `locletterprogp'`rownum'="p-value" 
local moy = `rownum' + 1 
qui sum `varprog' [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 
}
*
foreach varprog in `depvars2'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownum'="`a'" 
putexcel `locletterprogp'`rownum'="p-value" 
local moy = `rownum' + 1 
qui sum `varprog' [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`perc2', nformat(0.00) 
}
*
tempvar letterprog
gen `letterprog'=`colnum' - 1

foreach cprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)

qui sum `varprog', detail
qui sum `cprog' if `varprog'==`r(min)' [weight=`samw']
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mean)'*`per', nformat(0.00) 
****MEAN 2 (and CI)
qui sum `varprog', detail
qui sum `cprog' if `varprog'==`r(max)' [weight=`samw']
putexcel `locletterprog'`levelsprog_2'= `r(mean)'*`per', nformat(0.00) 
*** MEAN p-value 
qui ttest `cprog', by(`varprog')
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
*
foreach cprog in `depvars2'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)

qui sum `varprog', detail
qui sum `cprog' if `varprog'==`r(min)' [weight=`samw']
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mean)'*`perc2', nformat(0.00) 
****MEAN 2 (and CI)
qui sum `varprog', detail
qui sum `cprog' if `varprog'==`r(max)' [weight=`samw']
putexcel `locletterprog'`levelsprog_2'= `r(mean)'*`perc2', nformat(0.00) 
*** MEAN p-value 
qui ttest `cprog', by(`varprog')
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
**************************WITH IF CONDITION*************************************
if !missing(`"`if'"') {
if missing(`"`depvars2'"') {
***GEN LETTER 
tempvar letterprog
gen `letterprog'= `colnum' - 1
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownum' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog'
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog'  `if'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
***BUT DEPVAR LABELS & p-value title & totals
foreach varprog in `namelist' {
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownum'="`a'" 
putexcel `locletterprogp'`rownum'="p-value" 
local moy = `rownum' + 1 
qui sum `varprog'  `if' [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 
}
*
tempvar letterprog
gen `letterprog'= `colnum' - 1

foreach cprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)

qui sum `varprog' `if', detail
qui sum `cprog' `if' & `varprog'==`r(min)' [weight=`samw']
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mean)'*`per', nformat(0.00) 
****MEAN 2 (and CI)
qui sum `varprog' `if', detail
qui sum `cprog' `if' & `varprog'==`r(max)' [weight=`samw']
putexcel `locletterprog'`levelsprog_2'= `r(mean)'*`per', nformat(0.00)
qui ttest `cprog' `if', by(`varprog')
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
*
if !missing(`"`depvars2'"'){
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
***GEN LETTER 
tempvar letterprog
gen `letterprog'= `colnum' - 1
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownum' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog'
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog'  `if'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
***BUT DEPVAR LABELS & p-value title & totals
foreach varprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownum'="`a'" 
putexcel `locletterprogp'`rownum'="p-value" 
local moy = `rownum' + 1 
qui sum `varprog'  `if' [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 
}
*
foreach varprog in `depvars2'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownum'="`a'" 
putexcel `locletterprogp'`rownum'="p-value" 
local moy = `rownum' + 1 
qui sum `varprog'  `if' [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`perc2', nformat(0.00) 
}
*
tempvar letterprog
gen `letterprog'=`colnum' - 1

foreach cprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)

qui sum `varprog' `if', detail
qui sum `cprog' `if' & `varprog'==`r(min)' [weight=`samw']
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mean)'*`per', nformat(0.00) 
****MEAN 2 (and CI)
qui sum `varprog' `if', detail
qui sum `cprog' `if' & `varprog'==`r(max)' [weight=`samw']
putexcel `locletterprog'`levelsprog_2'= `r(mean)'*`per', nformat(0.00)
*** MEAN p-value 
qui ttest `cprog'  `if', by(`varprog')
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
*
foreach cprog in `depvars2'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)

qui sum `varprog' `if', detail
qui sum `cprog' `if' & `varprog'==`r(min)' [weight=`samw']
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mean)'*`perc2', nformat(0.00) 
****MEAN 2 (and CI)
qui sum `varprog' `if', detail
qui sum `cprog' `if' & `varprog'==`r(max)' [weight=`samw']
putexcel `locletterprog'`levelsprog_2'= `r(mean)'*`perc2', nformat(0.00)
*** MEAN p-value 
qui ttest `cprog'  `if', by(`varprog')
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
*
if missing(`"`note'"') {
if missing(`"`space'"') {
scalar nspace = `levelsprog_2'
}
*
if !missing(`"`space'"') {
scalar nspace = `levelsprog_2' + `space'
}
scalar lspace = `letterprog' + 1
}

if !missing(`"`note'"') {
local noterow = `levelsprog_2' + 1 
local letternote = `colnum' 
excelcol `letternote'
local locletternote= "`r(column)'"
putexcel `locletternote'`noterow'="`note'",  italic 

if missing(`"`space'"') {
scalar nspace = `noterow'
}
*
if !missing(`"`space'"') {
scalar nspace = `noterow' + `space'
}
scalar lspace = `letterprog' + 1
}

}


if !missing(`"`title'"') { 
local lettertitle = `colnum' 
excelcol `lettertitle'
local loclettertitle = "`r(column)'"
putexcel `loclettertitle'`rownum'="`title'", bold 
****SET UP A NEW ROWNUMBER FOR THOSE BELOW TITLE 
local rownumtitle = `rownum' + 1 
if missing(`"`if'"') {
if missing(`"`depvars2'"') {
***GEN LETTER 
tempvar letterprog
gen `letterprog'= `colnum' - 1
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownumtitle' + 1
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog'
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
***PUT DEPVAR LABELS & p-value title & totals
foreach varprog in `namelist' {
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
putexcel `locletterprogp'`rownumtitle'="p-value" 
local moy = `rownumtitle' + 1 
qui sum `varprog' [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 
}
*
tempvar letterprog
gen `letterprog'= `colnum' - 1

foreach cprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)

qui sum `varprog', detail
qui sum `cprog' if `varprog'==`r(min)' [weight=`samw']
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mean)'*`per', nformat(0.00) 
****MEAN 2 (and CI)
qui sum `varprog', detail
qui sum `cprog' if `varprog'==`r(max)' [weight=`samw']
putexcel `locletterprog'`levelsprog_2'= `r(mean)'*`per', nformat(0.00) 
*** MEAN p-value 
qui ttest `cprog', by(`varprog')
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
*
if !missing(`"`depvars2'"'){
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
***GEN LETTER 
tempvar letterprog
gen `letterprog'= `colnum' - 1
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownumtitle' + 1
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog'
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
***BUT DEPVAR LABELS & p-value title & totals
foreach varprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
putexcel `locletterprogp'`rownumtitle'="p-value" 
local moy = `rownumtitle' + 1 
qui sum `varprog' [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 
}
*
foreach varprog in `depvars2'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
putexcel `locletterprogp'`rownumtitle'="p-value" 
local moy = `rownumtitle' + 1 
qui sum `varprog' [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`perc2', nformat(0.00) 
}
*
tempvar letterprog
gen `letterprog'=`colnum' - 1

foreach cprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)


qui sum `varprog', detail
qui sum `cprog' if `varprog'==`r(min)' [weight=`samw']
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mean)'*`per', nformat(0.00) 
****MEAN 2 (and CI)
qui sum `varprog', detail
qui sum `cprog' if `varprog'==`r(max)' [weight=`samw']
putexcel `locletterprog'`levelsprog_2'= `r(mean)'*`per', nformat(0.00) 
*** MEAN p-value 
qui ttest `cprog', by(`varprog')
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
*
foreach cprog in `depvars2'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)

qui sum `varprog', detail
qui sum `cprog' if `varprog'==`r(min)' [weight=`samw']
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mean)'*`perc2', nformat(0.00) 
****MEAN 2 (and CI)
qui sum `varprog', detail
qui sum `cprog' if `varprog'==`r(max)' [weight=`samw']
putexcel `locletterprog'`levelsprog_2'= `r(mean)'*`perc2', nformat(0.00) 
*** MEAN p-value 
qui ttest `cprog', by(`varprog')
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000)  
}
}
}
}
**************************WITH IF CONDITION*************************************
if !missing(`"`if'"') {
if missing(`"`depvars2'"') {
***GEN LETTER 
tempvar letterprog
gen `letterprog'= `colnum' - 1
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownumtitle' + 1
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog'
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog'  `if'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
***BUT DEPVAR LABELS & p-value title & totals
foreach varprog in `namelist' {
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
putexcel `locletterprogp'`rownumtitle'="p-value" 
local moy = `rownumtitle' + 1 
qui sum `varprog'  `if' [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 
}
*
tempvar letterprog
gen `letterprog'= `colnum' - 1

foreach cprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)


qui sum `varprog' `if', detail
qui sum `cprog' `if' & `varprog'==`r(min)' [weight=`samw']
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mean)'*`per', nformat(0.00) 
****MEAN 2 (and CI)
qui sum `varprog' `if', detail
qui sum `cprog' `if' & `varprog'==`r(max)' [weight=`samw']
putexcel `locletterprog'`levelsprog_2'= `r(mean)'*`per', nformat(0.00)
qui ttest `cprog' `if', by(`varprog')
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
*
if !missing(`"`depvars2'"'){
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
***GEN LETTER 
tempvar letterprog
gen `letterprog'= `colnum' - 1
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownumtitle' + 1
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog'
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog'  `if'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
***BUT DEPVAR LABELS & p-value title & totals
foreach varprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
putexcel `locletterprogp'`rownumtitle'="p-value" 
local moy = `rownumtitle' + 1 
qui sum `varprog'  `if' [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 
}
*
foreach varprog in `depvars2'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
putexcel `locletterprogp'`rownumtitle'="p-value" 
local moy = `rownumtitle' + 1 
qui sum `varprog'  `if' [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`perc2', nformat(0.00) 
}
*
tempvar letterprog
gen `letterprog'=`colnum' - 1

foreach cprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)

qui sum `varprog' `if', detail
qui sum `cprog' `if' & `varprog'==`r(min)' [weight=`samw']
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mean)'*`per', nformat(0.00) 
****MEAN 2 (and CI)
qui sum `varprog' `if', detail
qui sum `cprog' `if' & `varprog'==`r(max)' [weight=`samw']
putexcel `locletterprog'`levelsprog_2'= `r(mean)'*`per', nformat(0.00)
qui ttest `cprog' `if', by(`varprog')
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
*
foreach cprog in `depvars2'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)

qui sum `varprog' `if', detail
qui sum `cprog' `if' & `varprog'==`r(min)' [weight=`samw']
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mean)'*`perc2', nformat(0.00) 
****MEAN 2 (and CI)
qui sum `varprog' `if', detail
qui sum `cprog' `if' & `varprog'==`r(max)' [weight=`samw']
putexcel `locletterprog'`levelsprog_2'= `r(mean)'*`perc2', nformat(0.00)
qui ttest `cprog' `if', by(`varprog')
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
*
if missing(`"`note'"') {
if missing(`"`space'"') {
scalar nspace = `levelsprog_2'
}
*
if !missing(`"`space'"') {
scalar nspace = `levelsprog_2' + `space'
}
scalar lspace = `letterprog' + 1
}
if !missing(`"`note'"') {
local noterow = `levelsprog_2' + 1 
local letternote = `colnum' 
excelcol `letternote'
local locletternote= "`r(column)'"
putexcel `locletternote'`noterow'="`note'",  italic 

if missing(`"`space'"') {
scalar nspace = `noterow'
}
*
if !missing(`"`space'"') {
scalar nspace = `noterow' + `space'
}
scalar lspace = `letterprog' + 1
}
}
}
}
*
if missing(`"`samw'"'){

if `colnum'<=0 | `rownum'<=0 {
display "Pick a number larger 0"
}
*
if `colnum'<=0 & `rownum'<=0 {
display "Pick a number larger 0"
}
*
if `colnum'>=1 & `rownum'>=1 {
if missing(`"`title'"') {
if missing(`"`if'"') {
if missing(`"`depvars2'"') {
***GEN LETTER 
tempvar letterprog
gen `letterprog'= `colnum' - 1
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownum' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog'
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
***PUT DEPVAR LABELS & p-value title & totals
foreach varprog in `namelist' {
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownum'="`a'" 
putexcel `locletterprogp'`rownum'="p-value" 
local moy = `rownum' + 1 
qui sum `varprog' 
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 
}
*
tempvar letterprog
gen `letterprog'= `colnum' - 1

foreach cprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)
qui ttest `cprog', by(`varprog')
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mu_1)'*`per', nformat(0.00) 
****MEAN 2 (and CI)
putexcel `locletterprog'`levelsprog_2'= `r(mu_2)'*`per', nformat(0.00) 
*** MEAN p-value 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
*
if !missing(`"`depvars2'"'){
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
***GEN LETTER 
tempvar letterprog
gen `letterprog'= `colnum' - 1
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownum' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog'
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
***BUT DEPVAR LABELS & p-value title & totals
foreach varprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownum'="`a'" 
putexcel `locletterprogp'`rownum'="p-value" 
local moy = `rownum' + 1 
qui sum `varprog' 
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 
}
*
foreach varprog in `depvars2'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownum'="`a'" 
putexcel `locletterprogp'`rownum'="p-value" 
local moy = `rownum' + 1 
qui sum `varprog' 
putexcel `locletterprog'`moy'=`r(mean)'*`perc2', nformat(0.00) 
}
*
tempvar letterprog
gen `letterprog'=`colnum' - 1

foreach cprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)
qui ttest `cprog', by(`varprog')
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mu_1)'*`per', nformat(0.00) 
****MEAN 2 (and CI)
putexcel `locletterprog'`levelsprog_2'= `r(mu_2)'*`per', nformat(0.00) 
*** MEAN p-value 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
*
foreach cprog in `depvars2'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)
qui ttest `cprog', by(`varprog')
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mu_1)'*`perc2', nformat(0.00) 
****MEAN 2 (and CI)
putexcel `locletterprog'`levelsprog_2'= `r(mu_2)'*`perc2', nformat(0.00) 
*** MEAN p-value 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
**************************WITH IF CONDITION*************************************
if !missing(`"`if'"') {
if missing(`"`depvars2'"') {
***GEN LETTER 
tempvar letterprog
gen `letterprog'= `colnum' - 1
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownum' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog'
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog'  `if'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
***BUT DEPVAR LABELS & p-value title & totals
foreach varprog in `namelist' {
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownum'="`a'" 
putexcel `locletterprogp'`rownum'="p-value" 
local moy = `rownum' + 1 
qui sum `varprog'  `if' 
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 
}
*
tempvar letterprog
gen `letterprog'= `colnum' - 1

foreach cprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)
qui ttest `cprog'  `if', by(`varprog')
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mu_1)'*`per', nformat(0.00) 
****MEAN 2 (and CI)
putexcel `locletterprog'`levelsprog_2'= `r(mu_2)'*`per', nformat(0.00) 
*** MEAN p-value 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
*
if !missing(`"`depvars2'"'){
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
***GEN LETTER 
tempvar letterprog
gen `letterprog'= `colnum' - 1
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownum' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog'
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog'  `if'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
***BUT DEPVAR LABELS & p-value title & totals
foreach varprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownum'="`a'" 
putexcel `locletterprogp'`rownum'="p-value" 
local moy = `rownum' + 1 
qui sum `varprog'  `if' 
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 
}
*
foreach varprog in `depvars2'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownum'="`a'" 
putexcel `locletterprogp'`rownum'="p-value" 
local moy = `rownum' + 1 
qui sum `varprog'  `if' 
putexcel `locletterprog'`moy'=`r(mean)'*`perc2', nformat(0.00) 
}
*
tempvar letterprog
gen `letterprog'=`colnum' - 1

foreach cprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)
qui ttest `cprog'  `if', by(`varprog')
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mu_1)'*`per', nformat(0.00) 
****MEAN 2 (and CI)
putexcel `locletterprog'`levelsprog_2'= `r(mu_2)'*`per', nformat(0.00) 
*** MEAN p-value 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
*
foreach cprog in `depvars2'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)
qui ttest `cprog'  `if', by(`varprog')
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mu_1)'*`perc2', nformat(0.00) 
****MEAN 2 (and CI)
putexcel `locletterprog'`levelsprog_2'= `r(mu_2)'*`perc2', nformat(0.00) 
*** MEAN p-value 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
*
if missing(`"`note'"') {
if missing(`"`space'"') {
scalar nspace = `levelsprog_2'
}
*
if !missing(`"`space'"') {
scalar nspace = `levelsprog_2' + `space'
}
scalar lspace = `letterprog' + 1
}

if !missing(`"`note'"') {
local noterow = `levelsprog_2' + 1 
local letternote = `colnum' 
excelcol `letternote'
local locletternote= "`r(column)'"
putexcel `locletternote'`noterow'="`note'",  italic 

if missing(`"`space'"') {
scalar nspace = `noterow'
}
*
if !missing(`"`space'"') {
scalar nspace = `noterow' + `space'
}
scalar lspace = `letterprog' + 1
}

}


if !missing(`"`title'"') {
local lettertitle = `colnum' 
excelcol `lettertitle'
local loclettertitle = "`r(column)'"
putexcel `loclettertitle'`rownum'="`title'", bold 
****SET UP A NEW ROWNUMBER FOR THOSE BELOW TITLE 
local rownumtitle = `rownum' + 1 
if missing(`"`if'"') {
if missing(`"`depvars2'"') {
***GEN LETTER 
tempvar letterprog
gen `letterprog'= `colnum' - 1
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownumtitle' + 1
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog'
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
***PUT DEPVAR LABELS & p-value title & totals
foreach varprog in `namelist' {
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
putexcel `locletterprogp'`rownumtitle'="p-value" 
local moy = `rownumtitle' + 1 
qui sum `varprog' 
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 
}
*
tempvar letterprog
gen `letterprog'= `colnum' - 1

foreach cprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)
qui ttest `cprog', by(`varprog')
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mu_1)'*`per', nformat(0.00) 
****MEAN 2 (and CI)
putexcel `locletterprog'`levelsprog_2'= `r(mu_2)'*`per', nformat(0.00) 
*** MEAN p-value 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
*
if !missing(`"`depvars2'"'){
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
***GEN LETTER 
tempvar letterprog
gen `letterprog'= `colnum' - 1
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownumtitle' + 1
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog'
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
***BUT DEPVAR LABELS & p-value title & totals
foreach varprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
putexcel `locletterprogp'`rownumtitle'="p-value" 
local moy = `rownumtitle' + 1 
qui sum `varprog' 
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 
}
*
foreach varprog in `depvars2'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
putexcel `locletterprogp'`rownumtitle'="p-value" 
local moy = `rownumtitle' + 1 
qui sum `varprog' 
putexcel `locletterprog'`moy'=`r(mean)'*`perc2', nformat(0.00) 
}
*
tempvar letterprog
gen `letterprog'=`colnum' - 1

foreach cprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)
qui ttest `cprog', by(`varprog')
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mu_1)'*`per', nformat(0.00) 
****MEAN 2 (and CI)
putexcel `locletterprog'`levelsprog_2'= `r(mu_2)'*`per', nformat(0.00) 
*** MEAN p-value 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
*
foreach cprog in `depvars2'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)
qui ttest `cprog', by(`varprog')
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mu_1)'*`perc2', nformat(0.00) 
****MEAN 2 (and CI)
putexcel `locletterprog'`levelsprog_2'= `r(mu_2)'*`perc2', nformat(0.00) 
*** MEAN p-value 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
**************************WITH IF CONDITION*************************************
if !missing(`"`if'"') {
if missing(`"`depvars2'"') {
***GEN LETTER 
tempvar letterprog
gen `letterprog'= `colnum' - 1
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownumtitle' + 1
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog'
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog'  `if'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
***BUT DEPVAR LABELS & p-value title & totals
foreach varprog in `namelist' {
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
putexcel `locletterprogp'`rownumtitle'="p-value" 
local moy = `rownumtitle' + 1 
qui sum `varprog'  `if' 
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 
}
*
tempvar letterprog
gen `letterprog'= `colnum' - 1

foreach cprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)
qui ttest `cprog'  `if', by(`varprog')
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mu_1)'*`per', nformat(0.00) 
****MEAN 2 (and CI)
putexcel `locletterprog'`levelsprog_2'= `r(mu_2)'*`per', nformat(0.00) 
*** MEAN p-value 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
*
if !missing(`"`depvars2'"'){
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
***GEN LETTER 
tempvar letterprog
gen `letterprog'= `colnum' - 1
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownumtitle' + 1
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog'
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog'  `if'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
***BUT DEPVAR LABELS & p-value title & totals
foreach varprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
putexcel `locletterprogp'`rownumtitle'="p-value" 
local moy = `rownumtitle' + 1 
qui sum `varprog'  `if' 
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 
}
*
foreach varprog in `depvars2'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
local locletterprogp = `letterprog' + 1 
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
local a : variable label `varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
putexcel `locletterprogp'`rownumtitle'="p-value" 
local moy = `rownumtitle' + 1 
qui sum `varprog'  `if' 
putexcel `locletterprog'`moy'=`r(mean)'*`perc2', nformat(0.00) 
}
*
tempvar letterprog
gen `letterprog'=`colnum' - 1

foreach cprog in `namelist'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)
qui ttest `cprog'  `if', by(`varprog')
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mu_1)'*`per', nformat(0.00) 
****MEAN 2 (and CI)
putexcel `locletterprog'`levelsprog_2'= `r(mu_2)'*`per', nformat(0.00) 
*** MEAN p-value 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
*
foreach cprog in `depvars2'{
replace `letterprog' = `letterprog' + 2 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local locletterprogp =  `letterprog' + 1 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
tempvar startprog_1
gen `startprog_1'=`moy'-1 // can make changes to startproging point here
tempvar startprog_2
gen `startprog_2'=`moy' // can make changes to startproging point here
foreach varprog in `crosscuts' { 
replace `startprog_1' =`startprog_1'+2
replace `startprog_2' =`startprog_2'+2
levelsof `startprog_1', local(levelsprog_1)
levelsof `startprog_2', local(levelsprog_2)
qui ttest `cprog'  `if', by(`varprog')
**** MEAN 1 (and CI)
putexcel `locletterprog'`levelsprog_1'= `r(mu_1)'*`perc2', nformat(0.00) 
****MEAN 2 (and CI)
putexcel `locletterprog'`levelsprog_2'= `r(mu_2)'*`perc2', nformat(0.00) 
*** MEAN p-value 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
*
if missing(`"`note'"') {
if missing(`"`space'"') {
scalar nspace = `levelsprog_2'
}
*
if !missing(`"`space'"') {
scalar nspace = `levelsprog_2' + `space'
}
scalar lspace = `letterprog' + 1
}
if !missing(`"`note'"') {
local noterow = `levelsprog_2' + 1 
local letternote = `colnum' 
excelcol `letternote'
local locletternote= "`r(column)'"
putexcel `locletternote'`noterow'="`note'",  italic 

if missing(`"`space'"') {
scalar nspace = `noterow'
}
*
if !missing(`"`space'"') {
scalar nspace = `noterow' + `space'
}
scalar lspace = `letterprog' + 1
}
}
}
}
end 
