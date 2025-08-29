**1. open the dataset
use "ncaexample.dta", clear
**2. nca with one condition
nca individualism innovationperformance
**3.	NCA's statistical test (MIGHT TAKE TIME!)
set seed 1234567
nca individualism innovationperformance, testrep(10000) 
**4.	Selection of ceiling lines
nca individualism innovationperformance ,  ceilings(ce_fdh)
**5.	NCA with multiple conditions
  nca individualism risktaking innovationperformance
  graph dir
**6. Displaying the bottleneck table with default values
nca individualism risktaking innovationperformance, nograph nosummaries bottlenecks
**7.	Displaying the bottleneck tables with custom values
nca individualism risktaking innovationperformance, nograph nosummaries bottlenecks(0(5)100)
**8.	Displaying the bottleneck tables with actual values 
nca individualism risktaking innovationperformance, nograph nosummaries xbottlenecks(actual) ybottlenecks(actual) bottlenecks
******the same, but with a customized table
nca individualism risktaking innovationperformance, nograph nosummaries xbottlenecks(actual) ybottlenecks(actual) bottlenecks(50(25)100 180)
**9.	Displaying the bottleneck tables with percentile and actual values 
nca individualism risktaking innovationperformance, nograph nosummaries xbottlenecks(percentile) ybottlenecks(actual) bottlenecks
