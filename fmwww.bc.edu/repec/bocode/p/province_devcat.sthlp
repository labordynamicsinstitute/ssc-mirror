{smcl}
{* *! version 1.5 26Nov2025}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "province_devcat##syntax"}{...}
{viewerjumpto "Description" "province_devcat##description"}{...}
{viewerjumpto "Options" "province_devcat##options"}{...}
{viewerjumpto "Examples" "province_devcat##examples"}{...}
{viewerjumpto "Stored results" "province_devcat##results"}{...}
{viewerjumpto "Authors" "province_devcat##authors"}{...}
{title:Title}

{phang}
{bf:province_devcat} {hline 2} Generate development level variable for Chinese A-share listed companies based on provincial GDP per capita


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:province_devcat} [{cmd:using} {it:filename}] [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt using}}specify the dataset to analyze (default: asure.dta){p_end}
{synopt:{opt save(filename)}}save the processed dataset to {it:filename}{p_end}
{synopt:{opt replace}}overwrite existing file when using {cmd:save()}{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:province_devcat} is a specialized Stata program designed to analyze the development level of Chinese A-share listed companies based on provincial GDP per capita data. The program performs the following operations:

{pmore}
1. Loads and validates the A-share listed company dataset (default: {bf:asure.dta}) and provincial GDP per capita dataset ({bf:pcgdp2010-2024.dta})

{pmore}
2. Standardizes province names across datasets by creating unified province codes

{pmore}
3. Merges the datasets using province_code and year as matching variables

{pmore}
4. Generates an ordinal development level variable ({bf:province_devcat}) with values 1, 2, 3 representing "developed", "less developed", and "underdeveloped" respectively

{pmore}
5. Provides comprehensive descriptive statistics and distribution analysis

{pstd}
The classification is based on terciles (33rd and 66th percentiles) of GDP per capita within each year, ensuring dynamic classification standards over time.

{marker important_notes}{...}
{title:Important Notes}

{pstd}
{bf:Data Source Disclaimer:}{p_end}
{pmore}The datasets used in this program contain {bf:simulated/synthetic data} for demonstration and testing purposes only.{p_end}
{pmore}{bf:asure.dta} (or user-specified listed company dataset) contains {bf:simulated data} of Chinese A-share listed companies.{p_end}
{pmore}{bf:pcgdp2010-2024.dta} contains {bf:simulated provincial GDP per capita data}.{p_end}
{pmore}These are {bf:NOT real datasets} and should not be used for actual economic analysis, investment decisions, or policy recommendations.{p_end}
{pmore}For research applications, users should replace these datasets with actual data from official sources.{p_end}


{marker options}{...}
{title:Options}

{phang}
{opt using} specifies an alternative dataset to analyze. If not specified, the default dataset "asure.dta" will be used.

{phang}
{opt save(filename)} specifies the filename to save the processed dataset containing the development level variable.

{phang}
{opt replace} allows overwriting an existing file when used with the {cmd:save()} option.


{marker examples}{...}
{title:Examples}

{pstd}Basic usage (using default dataset){p_end}
{phang2}{cmd:. province_devcat}{p_end}

{pstd}Using a custom dataset{p_end}
{phang2}{cmd:. province_devcat using "my_companies.dta"}{p_end}

{pstd}Save results to a new dataset{p_end}
{phang2}{cmd:. province_devcat, save("listed_companies_development.dta") replace}{p_end}

{pstd}Using custom dataset and saving results{p_end}
{phang2}{cmd:. province_devcat using "custom_data.dta", save("results.dta") replace}{p_end}

{pstd}Expected output:{p_end}
{phang2}- Data quality checks and validation results{p_end}
{phang2}- Province name standardization process{p_end}
{phang2}- Merge statistics showing matched observations{p_end}
{phang2}- Distribution of development level variable by year and province{p_end}
{phang2}- Descriptive statistics for each development category{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:province_devcat} does not store formal results in {cmd:r()} but generates the following variables in the dataset:

{synoptset 20 tabbed}{...}
{synopt:{bf:province_devcat}}Development level ordinal variable:{p_end}
{synoptline}
{synopt:1}Developed (top 33% of GDP per capita within year){p_end}
{synopt:2}Less developed (middle 33% of GDP per capita within year){p_end}
{synopt:3}Underdeveloped (bottom 33% of GDP per capita within year){p_end}
{synoptline}

{pstd}
Variable labels and value labels are applied for clarity in output tables.


{marker authors}{...}
{title:Authors}

{pstd}
{bf:Wu Lianghai}{p_end}
{pstd}
School of Business, Anhui University of Technology (AHUT){p_end}
{pstd}
Ma'anshan, China{p_end}
{pstd}
{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}

{pstd}
{bf:Chen Liwen}{p_end}
{pstd}
School of Business, Anhui University of Technology (AHUT){p_end}
{pstd}
Ma'anshan, China{p_end}
{pstd}
{browse "mailto:2184844526@qq.com":2184844526@qq.com}{p_end}

{pstd}
{bf:Wu Hanyan}{p_end}
{pstd}
School of Economics and Management{p_end}
{pstd}
Nanjing University of Aeronautics and Astronautics (NUAA){p_end}
{pstd}
Nanjing, China{p_end}
{pstd}
{browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{pstd}
Development date: 26 November 2025{p_end}
{pstd}
Last updated: Version 1.5 - Added comprehensive data source disclaimers for both datasets{p_end}


{marker also_see}{...}
{title:Also see}

{pstd}
{help merge}, {help egen}, {help tabulate}, {help tabstat}, {help area}


{title:Technical notes}

{pstd}
{bf:Required data files:}{p_end}
{pmore}{bf:asure.dta} (or user-specified dataset): {bf:Simulated} Chinese A-share listed company annual panel dataset with province variable (string){p_end}
{pmore}{bf:pcgdp2010-2024.dta}: {bf:Simulated} provincial GDP per capita dataset with province (string), year, and pcgdp variables{p_end}

{pstd}
{bf:Data validation:}{p_end}
{pmore}- Checks for missing values in key variables{p_end}
{pmore}- Standardizes province names by creating unified province codes{p_end}
{pmore}- Verifies variable types and dataset compatibility{p_end}

{pstd}
{bf:Province name standardization:}{p_end}
{pmore}- Converts province names to standardized full administrative names (e.g., "北京" to "北京市"){p_end}
{pmore}- Handles both complete administrative names and abbreviated forms{p_end}
{pmore}- Ensures consistent matching across datasets with different naming conventions{p_end}

{pstd}
{bf:Merging strategy:}{p_end}
{pmore}- Uses many-to-one merge (m:1) matching on province_code and year{p_end}
{pmore}- Keeps all observations from the master dataset{p_end}
{pmore}- Includes only matching observations from the using dataset (pcgdp2010-2024.dta){p_end}

{pstd}
{bf:Classification methodology:}{p_end}
{pmore}- Development levels are calculated dynamically by year{p_end}
{pmore}- Uses tercile cutoffs (33rd and 66th percentiles) within each year{p_end}
{pmore}- Relative classification ensures comparability across time periods{p_end}

{hline}

{pstd}
{it:This help file was updated for version 1.5 on 26 November 2025.}
{*}