{smcl}
{* 17jan2025}
{hline}
help for {hi:povguide2}
{hline}

{title:Generate the U.S. Poverty Guideline value for a given family size and year}

{p 8 17 2}
{cmd:povguide2, gen(}{it:newvar}{cmd:)}
{cmd:famsize(}{it:famsize}{cmd:)}
{cmd:year(}{it:year}{cmd:)}
[{cmd:fips(}{it:fips}{cmd:)}]


{title:Description}

{p 4 4 2}
{cmd:povguide2} generates a numeric variable representing the official
U.S. poverty guideline. This is an update to the original {cmd:povguide} by David Kantor. Supports years 1973-2025, plus guideline values for Alaska and Hawaii.

{p 4 4 2}
Important: this is one of two official poverty levels
in use by the United States government. See more on this matter below,
under Remarks.


{title:Options}
{p 4 4 2}
{cmd:gen(}{it:newvar}{cmd:)} specifies the name of a new variable to be generated,
which will contain the poverty guideline (in U.S. dollars). By default is will be of an integer
type, typically int.

{p 4 4 2}
{cmd:famsize(}{it:famsize}{cmd:)} specifies an expression representing the
family size. It will be truncated to an integer and bottom-coded at 1 (values
below 1 will be coerced to 1).

{p 4 4 2}
{cmd:year(}{it:year}{cmd:)} specifies an expression representing the year
for which the computation is to be made. It will be truncated to an integer.
Presently, the acceptable values
are 1973-2025. Out-of-bounds values will result in a warning and missing
values in the result.

{p 4 4 2}
[{cmd:fips(}{it:fips}{cmd:)}] optionally specifies the FIPS code for the state. When omitted, the command defaults to the poverty guideline for the 48 contiguous states only. When specified, poverty guidelines for Alaska and Hawaii are generated for FIPS codes 2 and 15, with the standard poverty guidelines for all others.


{title:Remarks}

{p 4 4 2}
The poverty guideline is a "base value" for the first person in the family,
plus an increment for each additional person; the base value and increment vary, depending on the
year. For example, in 2005, it is 9570 + 3260 for each additional
person. To be concise, it is,{p_end}
{p 8 8 2}basevalue + (familysize - 1) * increment{p_end}

{p 4 4 2}
Poverty guideline values exist prior to 1973, however the increment is not
uniform in those early years, so this scheme does not apply.

{p 4 4 2}
These values are valid for all U.S. states and the District of Columbia. Alaska and Hawaii have their own distinct standards which are only used when the appropriate FIPS code is specified.

{p 4 4 2}
Official standards are issued by the U.S. Department of Health and Human
Services, and can be found at such locations as{p_end}
{p 8 8 2}https://aspe.hhs.gov/topics/poverty-economic-mobility/poverty-guidelines{p_end}

{p 4 4 2}
The 1982 standards are for nonfarm families.

{p 4 4 2}
Pre-1980 values are identical for the 48 contiguous states, Alaska, and Hawaii.

{p 4 4 2}
The Poverty Guideline is one of two standards in use; the other is the Poverty
Threshold, a more complex calculation, involving
the number of children and elderly. The Poverty Threshold is the original
standard, based on the work of Mollie Orshansky; the Poverty Guideline is
regarded as a simplified alternative. Also, the Threshold is used for statistical
purposes (e.g., by the U.S. Census Bureau), whereas the Guideline is used for
program eligibility.


{title:Examples}

{p 4 8 2}
{cmd:. povguide2, gen(povguide) famsize(num_persons) year(2002)}

{p 4 8 2}
{cmd:. povguide2, gen(povguide) famsize(num_persons) year(year)}

{p 4 8 2}
{cmd:. povguide2, gen(povguide) famsize(num_persons) year(year) fips(state_fips)}

{p 4 4 2}
Typically, you would follow this with something like...{p_end}
{p 4 8 2}
{cmd:. gen byte pov = faminc < povguide if ~mi(povguide) & ~mi(faminc)}


{title:Author}
{pstd}Original author: David Kantor. {p_end}
{pstd}Updated by Reginald Hebert to include guidelines through 2025, along with Alaska and Hawaii tables.{p_end}

{marker contact}{...}
{title:Contact}
{pstd}Reginald Hebert{break}
Yale University{break}
reginald.hebert@yale.edu{p_end}
