# povguide2
Federal Poverty Guidelines by family size and year, 1973-2025

This is an extension of the original Stata module POVGUIDE by David Kantor written to include guideline data from 1973-2025, whereas the original module stopped at 2008. Moreover, I have added the official guideline data for Alaska and Hawaii. The FIPS code argument is optional. When omitted, the command defaults to the poverty guideline for the 48 contiguous states only. When specified, poverty guidelines for Alaska and Hawaii are generated for FIPS codes 2 and 15, with the standard poverty guidelines for all others.

Original module: 
https://econpapers.repec.org/software/bocbocode/s456935.htm

Data from: 
https://aspe.hhs.gov/topics/poverty-economic-mobility/poverty-guidelines

Data for pre-1983 comes from Annual Statistical Supplement to the Social 
Security Bulletin, table 3.E8
e.g. https://www.ssa.gov/policy/docs/statcomps/supplement/2014/supplement14.pdf

For additional details see:
Fisher, Gordon M. "Poverty Guidlines for 1992." Soc. Sec. Bull. 55 (1992): 43.
