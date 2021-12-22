*******ttestex_time version 1.2-16.12.2021
*******by Annina Hittmeyer

*capture program drop ttestex_time 
program define ttestex_time 
	version 14.2

syntax namelist(min=1) [if], rownum(integer) colnum(integer) [crosscuts(string)] per(integer) time1(string) time2(string) [space(integer 0)] [depvars2(string)] [title(string)] [note(string)] [samw (string)] 

if !missing(`"`samw'"') {
if `colnum'<=0 | `rownum'<=0 {
display "Please pick a number larger 0"
}
*
if `colnum'<=0 & `rownum'<=0 {
display "Please pick a number larger 0"
}
*
if `colnum'>=1 & `rownum'>=1 {
if missing(`"`title'"') {
if missing(`"`crosscuts'"') {
if missing(`"`if'"') {
if missing(`"`depvars2'"') {
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownum' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}
}
*
if !missing(`"`depvars2'"') {
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
* 
foreach emo in `depvars2' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownum' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"


qui sum `varprog'`time1' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`perc2', nformat(0.00) 

qui sum `varprog'`time2' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`perc2', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}
}
}
if !missing(`"`if'"') {
if missing(`"`depvars2'"') {
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownum' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog' 
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog' `if'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1 
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownum' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' `if' &  `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2' `if' &  `varprog'`time1'!=. & `varprog'`time2'!=.  [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'  `if' 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}
}
*
if !missing(`"`depvars2'"') {
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
* 
foreach emo in `depvars2' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownum' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' `if' &  `varprog'`time1'!=. & `varprog'`time2'!=.  [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2' `if' &  `varprog'`time1'!=. & `varprog'`time2'!=.  [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'  `if' 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' `if' &  `varprog'`time1'!=. & `varprog'`time2'!=.  [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`perc2', nformat(0.00) 

qui sum `varprog'`time2' `if' &  `varprog'`time1'!=. & `varprog'`time2'!=.  [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`perc2', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'  `if' 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}
}
}

if missing(`"`note'"') {
if missing(`"`space'"') {
scalar nspace = `moy'
}
*
if !missing(`"`space'"') {
scalar nspace = `moy' + `space'
}
}
if !missing(`"`note'"') {
local noterow = `moy' + 1 
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
} // closes space loop 
} // closes note loop 
} // closes missing crosscuts 
if !missing(`"`crosscuts'"') {
if missing(`"`if'"') {
if missing(`"`depvars2'"') {
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownum' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' if  `varprog'`time1'!=. & `varprog'`time2'!=.  [weight=`samw'] 
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2' if  `varprog'`time1'!=. & `varprog'`time2'!=.  [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here

foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`colnum' - 2 // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1'  if `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=.  [weight=`samw'] 
putexcel `locletterprog'`levelsprog_1'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2'  if `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`levelsprog_1'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'  if `cprog'==`iprog' 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
if !missing(`"`depvars2'"') {
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
* 
foreach emo in `depvars2' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownum' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' if  `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2' if  `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' if  `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`perc2', nformat(0.00) 

qui sum `varprog'`time2' if  `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`perc2', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here

foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`colnum' - 2 // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1'  if `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw'] 
putexcel `locletterprog'`levelsprog_1'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2'  if `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`levelsprog_1'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'  if `cprog'==`iprog' 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
tempvar intermedletter
gen `intermedletter' = `letterprog'
tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here
foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`intermedletter' // can make changes to startproging point here
foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1'  if `cprog'==`iprog'  & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw'] 
putexcel `locletterprog'`levelsprog_1'=`r(mean)'*`perc2', nformat(0.00) 

qui sum `varprog'`time2'  if `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`levelsprog_1'=`r(mean)'*`perc2', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'  if `cprog'==`iprog' 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
}

if !missing(`"`if'"') {
if missing(`"`depvars2'"') {
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownum' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog' 
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog' `if'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1 
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownum' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2' `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2' `if' 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000)  
}

tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here

foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`colnum' - 2 // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1'  `if' & `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw'] 
putexcel `locletterprog'`levelsprog_1'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2'  `if' & `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`levelsprog_1'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2' `if' & `cprog'==`iprog' 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
if !missing(`"`depvars2'"') {
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownum' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog' 
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog' `if'  
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1 
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
* 
foreach emo in `depvars2' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownum' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1'  `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2'  `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2' `if' 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000)  
}

foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1'  `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`perc2', nformat(0.00) 

qui sum `varprog'`time2'  `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`perc2', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2' `if' 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 

}

tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here

foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`colnum' - 2 // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1'  `if' & `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw'] 
putexcel `locletterprog'`levelsprog_1'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2'  `if' & `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`levelsprog_1'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2' `if' & `cprog'==`iprog' 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000)  
}
}
}
tempvar intermedletter
gen `intermedletter' = `letterprog'
tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here
foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`intermedletter' // can make changes to startproging point here
foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1'  `if' & `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw'] 
putexcel `locletterprog'`levelsprog_1'=`r(mean)'*`perc2', nformat(0.00) 

qui sum `varprog'`time2'  `if' & `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`levelsprog_1'=`r(mean)'*`perc2', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2' `if' & `cprog'==`iprog' 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
}

if missing(`"`note'"') {
if missing(`"`space'"') {
scalar nspace = `levelsprog_1'
}
*
if !missing(`"`space'"') {
scalar nspace = `levelsprog_1' + `space'
}
}
if !missing(`"`note'"') {
local noterow = `levelsprog_1' + 1 
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
} // closes spaceloop
} // closes note exist loop 
} // closes crosscut not missing
} // closes does not title loop 
if !missing(`"`title'"') {
local rownumtitle = `rownum' + 1 
local lettertitle = `colnum' 
excelcol `lettertitle'
local loclettertitle = "`r(column)'"
putexcel `loclettertitle'`rownum'="`title'", bold 
if missing(`"`crosscuts'"') {
if missing(`"`if'"') {
if missing(`"`depvars2'"') {
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownumtitle' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}
}
*
if !missing(`"`depvars2'"') {
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
* 
foreach emo in `depvars2' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownumtitle' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`perc2', nformat(0.00) 

qui sum `varprog'`time2' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`perc2', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}
}
}
if !missing(`"`if'"') {
if missing(`"`depvars2'"') {
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownumtitle' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog' 
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog' `if'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1 
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownumtitle' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2' `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'  `if' 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}
}
*
if !missing(`"`depvars2'"') {
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
* 
foreach emo in `depvars2' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownumtitle' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2' `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'  `if' 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`perc2', nformat(0.00) 

qui sum `varprog'`time2' `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`perc2', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'  `if' 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}
}
}

if missing(`"`note'"') {
if missing(`"`space'"') {
scalar nspace = `moy'
}
*
if !missing(`"`space'"') {
scalar nspace = `moy' + `space'
}
}
if !missing(`"`note'"') {
local noterow = `moy' + 1 
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
} // closes space
} // close note
} // close crosscut missing 
if !missing(`"`crosscuts'"') {
if missing(`"`if'"') {
if missing(`"`depvars2'"') {
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownumtitle' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here

foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`colnum' - 2 // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1'  if `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw'] 
putexcel `locletterprog'`levelsprog_1'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2'  if `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`levelsprog_1'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'  if `cprog'==`iprog' 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
if !missing(`"`depvars2'"') {
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
* 
foreach emo in `depvars2' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownumtitle' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`perc2', nformat(0.00) 

qui sum `varprog'`time2' if `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`perc2', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here

foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`colnum' - 2 // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1'  if `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw'] 
putexcel `locletterprog'`levelsprog_1'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2'  if `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`levelsprog_1'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'  if `cprog'==`iprog' 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
tempvar intermedletter
gen `intermedletter' = `letterprog'
tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here
foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`intermedletter' // can make changes to startproging point here
foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1'  if `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw'] 
putexcel `locletterprog'`levelsprog_1'=`r(mean)'*`perc2', nformat(0.00) 

qui sum `varprog'`time2'  if `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`levelsprog_1'=`r(mean)'*`perc2', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2'  if `cprog'==`iprog' 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
} // closes foreach  cprog
} // closes forvalues 
} // closes foreach varprog 
} // closes depvars not missing 
} // closes closes if missing 

if !missing(`"`if'"') {
if missing(`"`depvars2'"') {
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownumtitle' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog' 
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog' `if'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1 
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownumtitle' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"


qui sum `varprog'`time1' `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2' `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2' `if'
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000)  
}

tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here

foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`colnum' - 2 // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1'  `if' & `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw'] 
putexcel `locletterprog'`levelsprog_1'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2'  `if' & `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`levelsprog_1'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2' `if' & `cprog'==`iprog' 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
if !missing(`"`depvars2'"') {
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownumtitle' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog' 
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog' `if'  
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1 
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
* 
foreach emo in `depvars2' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownumtitle' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1' `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2' `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2' `if' 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000)  
}

foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"


qui sum `varprog'`time1' `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog'`moy'=`r(mean)'*`perc2', nformat(0.00) 

qui sum `varprog'`time2' `if' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`moy'=`r(mean)'*`perc2', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2' `if' 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000)  
}

tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here

foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`colnum' - 2 // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1'  `if' & `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw'] 
putexcel `locletterprog'`levelsprog_1'=`r(mean)'*`per', nformat(0.00) 

qui sum `varprog'`time2'  `if' & `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`levelsprog_1'=`r(mean)'*`per', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2' `if' & `cprog'==`iprog' 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
tempvar intermedletter
gen `intermedletter' = `letterprog'
tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here
foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`intermedletter' // can make changes to startproging point here
foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui sum `varprog'`time1'  `if' & `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw'] 
putexcel `locletterprog'`levelsprog_1'=`r(mean)'*`perc2', nformat(0.00) 

qui sum `varprog'`time2'  `if' & `cprog'==`iprog' & `varprog'`time1'!=. & `varprog'`time2'!=. [weight=`samw']
putexcel `locletterprog_2'`levelsprog_1'=`r(mean)'*`perc2', nformat(0.00) 

qui ttest `varprog'`time1'=`varprog'`time2' `if' & `cprog'==`iprog' 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
}

if missing(`"`note'"') {
if missing(`"`space'"') {
scalar nspace = `levelsprog_1'
}
*
if !missing(`"`space'"') {
scalar nspace = `levelsprog_1' + `space'
}
}
if !missing(`"`note'"') {
local noterow = `levelsprog_1' + 1 
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
} // closes space exist loop
} // close note exists loop 
} // closes crosscut loop 
} // closes title exist loop 
scalar lspace = `letterprog' + 2 
} // closes row/colnum loop
} // closes samw loop 
*
if missing(`"`samw'"'){
if `colnum'<=0 | `rownum'<=0 {
display "Please pick a number larger 0"
}
*
if `colnum'<=0 & `rownum'<=0 {
display "Please pick a number larger 0"
}
*
if `colnum'>=1 & `rownum'>=1 {
if missing(`"`title'"') {
if missing(`"`crosscuts'"') {
if missing(`"`if'"') {
if missing(`"`depvars2'"') {
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownum' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprog'`moy'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}
}
*
if !missing(`"`depvars2'"') {
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
* 
foreach emo in `depvars2' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownum' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprog'`moy'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprog'`moy'=`r(mu_1)'*`perc2', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`perc2', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}
}
}
if !missing(`"`if'"') {
if missing(`"`depvars2'"') {
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownum' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog' 
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog' `if'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1 
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownum' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'  `if'
putexcel `locletterprog'`moy'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}
}
*
if !missing(`"`depvars2'"') {
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
* 
foreach emo in `depvars2' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownum' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'  `if'
putexcel `locletterprog'`moy'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'  `if'
putexcel `locletterprog'`moy'=`r(mu_1)'*`perc2', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`perc2', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}
}
}

if missing(`"`note'"') {
if missing(`"`space'"') {
scalar nspace = `moy'
}
*
if !missing(`"`space'"') {
scalar nspace = `moy' + `space'
}
}
if !missing(`"`note'"') {
local noterow = `moy' + 1 
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
} // closes space loop 
} // closes note loop 
} // closes missing crosscuts 
if !missing(`"`crosscuts'"') {
if missing(`"`if'"') {
if missing(`"`depvars2'"') {
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownum' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprog'`moy'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here

foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`colnum' - 2 // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'  if `cprog'==`iprog'
putexcel `locletterprog'`levelsprog_1'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`levelsprog_1'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
if !missing(`"`depvars2'"') {
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
* 
foreach emo in `depvars2' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownum' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2' 
putexcel `locletterprog'`moy'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2' 
putexcel `locletterprog'`moy'=`r(mu_1)'*`perc2', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`perc2', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here

foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`colnum' - 2 // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'  if `cprog'==`iprog'
putexcel `locletterprog'`levelsprog_1'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`levelsprog_1'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
tempvar intermedletter
gen `intermedletter' = `letterprog'
tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here
foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`intermedletter' // can make changes to startproging point here
foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
qui ttest `varprog'`time1'=`varprog'`time2'  if `cprog'==`iprog'
putexcel `locletterprog'`levelsprog_1'=`r(mu_1)'*`perc2', nformat(0.00) 
putexcel `locletterprog_2'`levelsprog_1'=`r(mu_2)'*`perc2', nformat(0.00) 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
}

if !missing(`"`if'"') {
if missing(`"`depvars2'"') {
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownum' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog' 
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog' `if'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1 
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownum' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2' `if'
putexcel `locletterprog'`moy'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here

foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`colnum' - 2 // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2' `if' & `cprog'==`iprog'
putexcel `locletterprog'`levelsprog_1'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`levelsprog_1'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
if !missing(`"`depvars2'"') {
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownum' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog' 
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog' `if'  
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1 
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
* 
foreach emo in `depvars2' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownum'="`a'" 
}
putexcel `locletterprogp'`rownum'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownum' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2' `if' 
putexcel `locletterprog'`moy'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2' `if' 
putexcel `locletterprog'`moy'=`r(mu_1)'*`perc2', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`perc2', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here

foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`colnum' - 2 // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2' `if' & `cprog'==`iprog'
putexcel `locletterprog'`levelsprog_1'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`levelsprog_1'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
tempvar intermedletter
gen `intermedletter' = `letterprog'
tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here
foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`intermedletter' // can make changes to startproging point here
foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
qui ttest `varprog'`time1'=`varprog'`time2' `if' & `cprog'==`iprog'
putexcel `locletterprog'`levelsprog_1'=`r(mu_1)'*`perc2', nformat(0.00) 
putexcel `locletterprog_2'`levelsprog_1'=`r(mu_2)'*`perc2', nformat(0.00) 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
}

if missing(`"`note'"') {
if missing(`"`space'"') {
scalar nspace = `levelsprog_1'
}
*
if !missing(`"`space'"') {
scalar nspace = `levelsprog_1' + `space'
}
}
if !missing(`"`note'"') {
local noterow = `levelsprog_1' + 1 
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
} // closes spaceloop
} // closes note exist loop 
} // closes crosscut not missing
} // closes does not title loop 
if !missing(`"`title'"') {
local rownumtitle = `rownum' + 1 
local lettertitle = `colnum' 
excelcol `lettertitle'
local loclettertitle = "`r(column)'"
putexcel `loclettertitle'`rownum'="`title'", bold 
if missing(`"`crosscuts'"') {
if missing(`"`if'"') {
if missing(`"`depvars2'"') {
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownumtitle' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprog'`moy'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}
}
*
if !missing(`"`depvars2'"') {
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
* 
foreach emo in `depvars2' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownumtitle' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprog'`moy'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprog'`moy'=`r(mu_1)'*`perc2', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`perc2', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}
}
}
if !missing(`"`if'"') {
if missing(`"`depvars2'"') {
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownumtitle' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog' 
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog' `if'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1 
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownumtitle' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'  `if'
putexcel `locletterprog'`moy'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}
}
*
if !missing(`"`depvars2'"') {
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
* 
foreach emo in `depvars2' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownumtitle' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'  `if'
putexcel `locletterprog'`moy'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'  `if'
putexcel `locletterprog'`moy'=`r(mu_1)'*`perc2', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`perc2', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}
}
}

if missing(`"`note'"') {
if missing(`"`space'"') {
scalar nspace = `moy'
}
*
if !missing(`"`space'"') {
scalar nspace = `moy' + `space'
}
}
if !missing(`"`note'"') {
local noterow = `moy' + 1 
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
} // closes space
} // close note
} // close crosscut missing 
if !missing(`"`crosscuts'"') {
if missing(`"`if'"') {
if missing(`"`depvars2'"') {
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownumtitle' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'
putexcel `locletterprog'`moy'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here

foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`colnum' - 2 // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'  if `cprog'==`iprog'
putexcel `locletterprog'`levelsprog_1'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`levelsprog_1'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
if !missing(`"`depvars2'"') {
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
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
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
* 
foreach emo in `depvars2' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownumtitle' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2' 
putexcel `locletterprog'`moy'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2' 
putexcel `locletterprog'`moy'=`r(mu_1)'*`perc2', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`perc2', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here

foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`colnum' - 2 // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2'  if `cprog'==`iprog'
putexcel `locletterprog'`levelsprog_1'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`levelsprog_1'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
tempvar intermedletter
gen `intermedletter' = `letterprog'
tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here
foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`intermedletter' // can make changes to startproging point here
foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
qui ttest `varprog'`time1'=`varprog'`time2'  if `cprog'==`iprog'
putexcel `locletterprog'`levelsprog_1'=`r(mu_1)'*`perc2', nformat(0.00) 
putexcel `locletterprog_2'`levelsprog_1'=`r(mu_2)'*`perc2', nformat(0.00) 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
} // closes foreach  cprog
} // closes forvalues 
} // closes foreach varprog 
} // closes depvars not missing 
} // closes closes if missing 

if !missing(`"`if'"') {
if missing(`"`depvars2'"') {
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownumtitle' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog' 
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog' `if'
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1 
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownumtitle' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2' `if'
putexcel `locletterprog'`moy'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here

foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`colnum' - 2 // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2' `if' & `cprog'==`iprog'
putexcel `locletterprog'`levelsprog_1'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`levelsprog_1'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
if !missing(`"`depvars2'"') {
if `per'==1 {
local perc2=100 
}
if `per'==100 {
local perc2=1 
}
excelcol `colnum'
local locletterprogA = "`r(column)'"
***PUT TOTAL  
local beginprog = `rownumtitle' + 1 
putexcel `locletterprogA'`beginprog'="Total"
***PUT CROSSCUT VAR LABELS 
tempvar startprog
gen `startprog'=`beginprog' 
foreach varprog in `crosscuts' { // cross cut variables, must have same order as and ttests!!!
qui sum `varprog' `if'  
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog' =`startprog'+ 1 
levelsof `startprog', local(levelsprog)
putexcel `locletterprogA'`levelsprog'=`"`:label (`varprog') `iprog''"' 
}

}
*****PUT LABELS******************
tempvar letterprog
gen `letterprog'=`colnum'  
foreach emo in `namelist' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
* 
foreach emo in `depvars2' {
local locletterprogp = `letterprog' + 3 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
foreach varprog in `time1' `time2' {
replace `letterprog' = `letterprog' + 1 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"
local a : variable label `emo'`varprog' 
putexcel `locletterprog'`rownumtitle'="`a'" 
}
putexcel `locletterprogp'`rownumtitle'="p-value"
replace `letterprog' = `letterprog' + 1 
}
*
local moy = `rownumtitle' + 1 
***TOTALS****
tempvar letterprog
gen `letterprog'=`colnum' - 2  // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2' `if' 
putexcel `locletterprog'`moy'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2' `if' 
putexcel `locletterprog'`moy'=`r(mu_1)'*`perc2', nformat(0.00) 
putexcel `locletterprog_2'`moy'=`r(mu_2)'*`perc2', nformat(0.00) 
putexcel `locletterprogp'`moy'=`r(p)', nformat(0.000) 
}

tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here

foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`colnum' - 2 // can make changes to startproging point here
foreach varprog in `namelist' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"

qui ttest `varprog'`time1'=`varprog'`time2' `if' & `cprog'==`iprog'
putexcel `locletterprog'`levelsprog_1'=`r(mu_1)'*`per', nformat(0.00) 
putexcel `locletterprog_2'`levelsprog_1'=`r(mu_2)'*`per', nformat(0.00) 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
tempvar intermedletter
gen `intermedletter' = `letterprog'
tempvar startprog_1
gen `startprog_1'=`moy' // can make changes to startproging point here
foreach cprog in `crosscuts' {
qui sum `cprog' 
forvalues iprog=`r(min)'/`r(max)' {
replace `startprog_1'= `startprog_1' + 1 
levelsof `startprog_1', local(levelsprog_1)
tempvar letterprog
gen `letterprog'=`intermedletter' // can make changes to startproging point here
foreach varprog in `depvars2' { 
replace `letterprog' = `letterprog' + 3 
levelsof `letterprog', local(locletterprog)
excelcol `locletterprog' 
local locletterprog = "`r(column)'"

local locletterprog_2 = `letterprog' + 1  
excelcol `locletterprog_2' 
local locletterprog_2 = "`r(column)'"

local locletterprogp = `letterprog' + 2 
excelcol `locletterprogp' 
local locletterprogp = "`r(column)'"
qui ttest `varprog'`time1'=`varprog'`time2' `if' & `cprog'==`iprog'
putexcel `locletterprog'`levelsprog_1'=`r(mu_1)'*`perc2', nformat(0.00) 
putexcel `locletterprog_2'`levelsprog_1'=`r(mu_2)'*`perc2', nformat(0.00) 
putexcel `locletterprogp'`levelsprog_1'=`r(p)', nformat(0.000) 
}
}
}
}
}

if missing(`"`note'"') {
if missing(`"`space'"') {
scalar nspace = `levelsprog_1'
}
*
if !missing(`"`space'"') {
scalar nspace = `levelsprog_1' + `space'
}
}
if !missing(`"`note'"') {
local noterow = `levelsprog_1' + 1 
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
} // closes space exist loop
} // close note exists loop 
} // closes crosscut loop 
} // closes title exist loop 
scalar lspace = `letterprog' + 2 
} // closes row/colnum loop
} //closes no samw
end 


