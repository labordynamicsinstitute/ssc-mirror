*stndzxage tutorial
*by Sarah Reynolds
*2-27-19

*The file checks how the command stndzxage differs from zscore
*The file illustrates how to use the command

clear all
set more off
cd "C:\Users\saris\Dropbox\ado\plus\s\stndzxage additional files"
use "stndzxage_sample_data.dta", clear

count
*1,429 children in the data

count if TestScore~=.
*1,420 were tested

hist AgeMonth
*ages concentrated in the center

stndzxage TestScore AgeMonth
sum stx_TestScore
*mean about 0 & standard deviation about 1, as expected
*however, there are fewer observations

*Do a loop to check standardization with stata command
levelsof AgeMonth, local(ages)
gen Z_TestScore=.
foreach age of local ages {
	zscore TestScore if AgeMonth==`age'
	replace Z_TestScore=z_TestScore if AgeMonth==`age'
	drop z_TestScore
	}	
sum Z_TestScore
*mean about 0 & standard deviation about 1, as expected
*however, there are more observations, equal to the 
*number of children who took the test - 1

sum AgeMonth if Z_TestScore==. & TestScore~=.
*The - 1 corresponds to the child who was the only one of thier age

*Check to see how well they line up if there are both standardization variables
scatter Z_TestScore stx_TestScore

tab AgeMonth if stx_TestScore~=.
tab AgeMonth if Z_TestScore~=.
*mismatch in missings because stndzxage has 30 observations minimum

*find out how many are in each month to re-standardize the 
*using the smallest number of observations!
tab AgeMonth
stndzxage TestScore AgeMonth, minbinsize(12)
assert stx_TestScore==Z_TestScore
*This error turns out to be from rounding
gen stx_round=round(stx_TestScore, 0.0001)
gen Z_round=round(Z_TestScore, 0.0001)
assert stx_round==Z_round

*****Validation complete********


****Exploring options****

*GRAPHING
stndzxage TestScore AgeMonth, graph
*Notice there are more ages with raw data points than have means
*These ages had too few observations (default minbinsize is 30)

*BIN WIDTH
*let's widen the age bins so more ages are grouped together, resulting in 
*a larger number of observations in each bin
stndzxage TestScore AgeMonth, binwidth(6) graph
*the waves in the standardized data indicate bins are probably too wide
stndzxage TestScore AgeMonth, binwidth(3) graph
*still some age dependency but not so much
*note the last bin included 4 ages (see help file chart about bin grouping)

*MININIMUM BIN SIZE
*let's increase the minimum number of observations allowed in each bin
stndzxage TestScore AgeMonth, binwidth(3) minbinsize(150) graph

*CONTINUOUS
*continuous standardization is a good option when data density has gaps (in tails)
stndzxage TestScore AgeMonth, continuous graph
sum stx_TestScore
*note all observations are standardized
stndzxage TestScore AgeMonth, continuous poly(1) graph // linear
stndzxage TestScore AgeMonth, continuous poly(5) graph // a bit more curvature

*STANDARDIZING OVER ADDITIONAL VARIABLES
*you can use if to standardize a single subgroup
stndzxage TestScore AgeMonth if Male==1, binwidth(3)
tab Male, sum(stx_TestScore)
stndzxage TestScore AgeMonth if Male==0, binwidth(3) 
tab Male, sum(stx_TestScore)
*but below is more efficient

*standardize by age & gender
stndzxage TestScore AgeMonth Male, binwidth(3) graph
tab Male, sum(stx_TestScore)
*note means & s.d. are 0 in both cases

*standardize by age, gender, and urban
stndzxage TestScore AgeMonth Male Urban, continuous graph
tab Male Urban, sum(stx_TestScore)

*STANDARDIZING WTIH REGARDS TO A REFERENCE GROUP
stndzxage TestScore AgeMonth, binwidth(3) reference(Male) graph
*The graph only illustrates the data for the reference group, which was used
*for standardizing
tab Male, sum(stx_TestScore)
*note here the mean & s.d. is ~0 & ~1 for the reference group, but different for 
*the non reference group

*USING A REFERENCE GROUP & A SUBGROUP
*can you do it both reference group
stndzxage TestScore AgeMonth Urban, binwidth(3) minbinsize(30) reference(Male) graph
tab Male Urban, sum(stx_TestScore)

*USING A DIFFERENT RUNNING VARIABLE
*Suppose the test was administered with different questions to different ages
*Cut the data at the ages for each group
egen testgroups=cut(AgeMonth), at(10, 13, 16, 19, 25, 30)
tostring testgroups, replace
encode testgroups, gen(TestGroups)
label values TestGroups // remove label from TestGroup2
stndzxage TestScore TestGroups, graph
rename stx_TestScore testgroups_z
*This graph has the test groups all lumped together
*If you want to see the ages graphed also, use the if option.
*Select the binwidth to be the widest number of ages in a bin.
levelsof TestGroups, local(groups)
gen testgroups_if_z=.
foreach i of local groups {
	stndzxage TestScore AgeMonth if TestGroups==`i', binwidth(6) graph
	replace testgroups_if_z=stx_TestScore if TestGroups==`i'
	}
assert testgroups_z==testgroups_if_z
*Though the syntax below is appealing, it does not work because
*the ages are divided up by binwidth before the TestGroups 
*	stndzxage TestScore AgeMonth TestGroups, binwidth(6) graph
*don't use this code!


*FLOORS & CEILINGS
*let's make an artificial floor in this data 
replace TestScore=35 if TestScore<35
hist TestScore
scatter TestScore AgeMonth
*If your data actually looked like this, you might be ok with the test ceiling, but 
*you might want to rethink the appropriateness of the test for the younger kids:
*the test best discriminates after about 15 months.
stndzxage TestScore AgeMonth, continuous graph
sum stx_TestScore
stndzxage TestScore AgeMonth, continuous floor graph
sum stx_TestScore
*The floor option uses a Tobit adjustment, which assumes a spread farther below 
*that which is censored.  Censoring pushes the mean up. Without the adjustment,
*the mean used to standardize is higher than the mean used to standardize with a 
*Tobit adjustment. Average standadrdized scores are higher in the Tobit adjustment

*We can take ceilings into account as well.
replace TestScore=60 if TestScore>60 & TestScore~=.
stndzxage TestScore AgeMonth, floor ceiling minbinsize(30) reference(Male) graph

*USING THE MEDIAN & RESCALING
*The median can be used for standardizing instead of the mean.
*A different standard mean/median & standard deviation can be selected  
stndzxage TestScore AgeMonth, sd(15) mean(100) binw(3)
sum stx_TestScore
stndzxage TestScore AgeMonth, median sd(15) mean(100) binw(3)
sum stx_TestScore
