{smcl}
{* *! version 3.1  Oct2020}{...}
{cmd:help dseg}{right:dialog:  {dialog dseg}{space 15}}
{hline}

{p2colset 5 19 21 2}{...}
{p2col:{hi: dseg} {hline 2} Decomposable Multigroup Segregation Indices.}
{p2colreset}{...}

{title:Syntax}

{p 8 14 2}
{cmd:dseg} {it:index} [(]{it:varlist1}[)] {cmd:given} [(]{it:varlist2}[)] {ifin} {weight} [{cmd:,} {it:options}]

{synoptset 33}{...}
{p2coldent:{it:index}}description{p_end}
{synoptline}
{synopt:{opt atkinson}} symmetric Atkinson, A{p_end}
{synopt:{opt theil}} Theil's H (Entropy), H{p_end}
{synopt:{opt mutual}} mutual information, M{p_end}
{synopt:{opt diversity}} relative diversity, R{p_end}
{synoptline}

{synoptset 33 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Model}
{synopt :{opt b:y(varlist)}} identifies the subsamples over which the index is to be calculated{p_end}
{synopt :{opt w:ithin(varlist[,components])}} identifies the partition in the between-within decompositions{p_end}
{synopt :{opt clear}} replaces current data in memory with data with index values{p_end}
{synopt :{opt saving(filename[,opt])}} saves index values in Stata data file {it:filename}{p_end}
{synopt :{opt gen:erate(name)}} sets the name of the variable storing the overall index of segregation{p_end}
{synopt :{opt missing}} treats missing values like other values{p_end}
{synopt :{opt fast}} uses contributed command {cmd:ftools} to speed up computing time with big data; see {search ftools}{p_end}
{synopt :{opt normalized}} chooses the base of the logarithm so that the Mutual Information index is normalized in the unit interval{p_end}

{syntab :Bootstrapping & simulation}
{synopt :{opt boot:straps(#)}} performs # bootstrap replications{p_end}
{synopt :{opt r:andom(#)}} computes the index with # simulated samples under the assumption of no-segregation{p_end}
{synopt :{opt rseed(#)}} specifies the initial value of the random-number seed{p_end}

{syntab :Reporting}
{synopt :{opt nolist}} do not list index values{p_end}
{synopt :{opt f:ormat(%fmt)}} set index display format; default is %9.4f; see {help format}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{cmd:fweight}s are allowed; see {help weight}.{p_end}

{title:Description}

{pstd}
{cmd:dseg} computes all known multigroup indexes of segregation that are additively decomposable into a between and a within term: the symmetric Atkinson index, the Theil's H index, the mutual information index, and the relative diversity index. 
For each index, two versions are available: 
One version captures how groups shares differ across organizational units.
This is the "groups-given-units" notion of segregation. 
The other version captures how groups are distributed along different organizational units.
This is the "units-given-groups" notion of segregation.
The Theil's H index and the relative diversity index described in Reardon and Firebauch (2002) are "groups-given-units" indexes that are unit decomposable.
The symmatric Atkinson index proposed in Frankel and Volij (2011) is a "groups-given-units" index that is also unit decomposable.
The mutual information index proposed by Theil and Finizza (1971) is both a "groups-given-units" and a "groups-given-units" index.
Moreover, it is both unit and group decomposable.

{pstd}
Varlist {it:varlist1} identifies the combinations that define the groups in "groups-given-units" indexes and the combinations that define the units in "units-given-groups" indexes.
Varlist {it:varlist2} identifies the units in "groups-given-units" indexes and the groups in the "units-given-groups" indexes. 
Hence, the user specifies the index to compute by setting the name of the index and by choosing which variables are included in {it:varlist1} and which variables are included in {it:varlist2}.
As the mutual information index is both a "groups-given-units" and a "units-given-groups" index, which varlist is in {it:varlist1} and which is in {it:varlist2} has no effects on the results.
Parentheses are required when there is more than one variable defining the groups and/or the units.
Otherwise, they are optional.
When data is aggregated (i.e., each observation represents several individuals), a variable in the dataset must contain the number of duplicated observations and {opt fweight} must be used. 

{title:Options}

{dlgtab:Model}

{phang}
{opt by(varlist)} identifes the subsamples over which the index is to be calculated. It is useful for computing the same index and its decomposition for different years, countries, etc.{p_end}

{phang}
{opt w:ithin(varlist[,opt])} specifies the partition that defines the between-within decomposition. 
It admits suboption {cmd:components}.
For Theil's H, the relative diversity index, and symmetric Atkinson index, command {cmd:dseg} automatically computes the only posible decomposition available for each of these indexes.
For example, for the decomposition of the symmetric Atkinson index proposed by Frankel and Volij (2011), which is a "units-given-groups" index, {it:varlist} identifies the clusters that partition the organizational units defined by {it:varlist1}. 
In contrast, for the Theil's H index presented in Reardon and Firebauch (2002), {it:varlist} identifies the clusters that partition the organizational units, which are defined by {it:varlist2} as the index is a "groups-given-units" index.
The mutual information index is both a "units-given-groups" and "groups-given-units" index that satisfies both group and unit decomposability. 
Without loss of generality, {it:varlist} when using the mutual information index specifies the partition of {it:varlist2} that defines the between-within decomposition. 
When suboption {cmd:components} is used, the procedure additionally returns the  components of the within term, namely the weights and the segregation indices in the within term.
{p_end}

{phang}
{opt clear} replaces data in memory with the index values.
If neither option {opt by(varlist)} nor suboption {cmd:components} are used, the new dataset has only one observation.
If only option {opt by(varlist)} is used, the new dataset has as many observations as the number of categories defined by {it:varlist}. 
If option {opt within(varlist)} without suboption {cmd:components} is used, the new dataset also includes the between and the within term in the decomposition.
If suboption {cmd:components} is used, the new dataset additionally includes the weights and the individual segregation indices.
In the latter case, the number of observations equals the number of combinations of the categories defined by the varlists of options {opt by()} and {opt within()}.{p_end}

{phang}
{opt saving(filename[,opt])} saves index values in Stata data file {it:filename}.
Saving options are passed through by {it:opt}; see {help save}.{p_end}

{phang}
{opt generate(name)} declares the name for new index values. 
This option can only be used if options {opt clear} and/or {opt saving()} are used.
By default, the names are A, H, M, and R for the symmetric Atkinson, the Theil's H, the mutual information, and the relative diversity index, respectively.
When option {opt within(varlist)} is used, names {it:name}_B and {it:name}_W are used to name the between and the within terms in the decomposition.
If suboption {cmd:components} is used, names {it:name}_weight and {it:name}_within are used to name the weights and the individual segregation indices.
Because {opt generate(name)} is only used to either create a new dataset and/or to clear the current dataset and replace it, most variable names can be used.
The only exceptions to this rule are variable names used in options {opt by(varlist)} and {opt within(varlist,opt)} with suboption {cmd:components}.{p_end}

{phang}
{opt missing} treats missing values as other values.
By default, all observations with missing values are ignored in the computations of the indices.{p_end}

{phang}
{opt fast} uses contributed command {cmd:ftools} to speed up computing time with big data. It requires all variables to be numeric; see {help ftools}.{p_end}

{phang}
{opt normalized} chooses the base of the logarithm so that the Mutual Information index is normalized in the unit interval.{p_end}

{dlgtab:Bootstrapping & simulation}

{phang}
{opt bootstraps(#)} sets the number of bootstrap samples.
This option invokes command {cmd:bsample} to generate a bootstrap sample with replacement with the same number of observations that the original sample.
This option cannot be used with weights.
Using option {opt bootstraps(#)} results in a new dataset with index values for each of the # bootstrap samples.
These are identified with variable {cmd:bsn}, the bootstrap sample number.
The dataset includes an additional observation with the indexes calculated with the original dataset.
This observation is identified with {cmd:bsn = 0}.
The new dataset replaces the current dataset in memory when option {cmd:clear} is used.
It is saved when {opt saving(filename,opt)} is used. 
If none of these two options are used, {cmd:dseg} with option {opt bootstraps(#)} ends with an error message.{p_end}

{phang}
{opt random(#)} computes the index with # simulated samples under the assumption of no-segregation.
Each simulated sample is obtained after randomly reshuffling values of {it: varlist1}. 
Otherwise, option {opt random(#)} closely follows the behavior of option {opt bootstraps(#)}: 
(a) it cannot be directly used with weighted data; 
(b) the output is a new dataset that includes index values for all simulated samples; 
and (c) the new dataset must replace the current dataset and/or be saved.{p_end}

{phang}
{opt rseed(#)} sets the seed for the random number generator.{p_end}

{dlgtab:Reporting}

{phang}
{opt nolist} omits the display of index values.
By default, {cmd:dseg} lists the values of the index. 
Option {opt nolist} surpresses the list.
When used together with option {opt clear}, a description of the new data set is displayed.{p_end}

{phang}
{opt format(%fmt)} sets index output format; default is %9.4f; see {help format}{p_end}

{title:Remarks}

{pstd}
Several papers extensively discuss the properties of the indexes
(Frankel and Volij, 2011, Mora and Ruiz-Castillo, 2011, Reardon and Firebaugh, 2002, and Reardon, Yun, and Eitle, 2000). 

{pstd}
The mutual information index proposed by Theil and Finizza (1971) and the symmetric Atkinson index proposed by Frankel and Volij (2011) are both characterized in terms of ordinal axioms by Frankel and Volij (2011). 
The latter was previously characterized by Hutchens (2004) using an alternative set of axioms for the case when the number of groups equals two.
Reardon and Firebaugh (2002) describe the properties of Theil's H index and of the relative diversity index. 

{pstd}
All indexes have a minimum value of zero. 
The mutual information index has no global maximum. 
For a fixed number of groups and organizational units, its maximum is the minimum between the logarithm of the number of groups and the logarithm of the number of units.
This justifies using this maximum as the base of the logarithms.
In that case, the maximum value is one. 
All other indexes reach a maximum value of one always. 
{p_end}

{pstd}
All indexes are relative indexes of segregation and are invariant to population size.
Only the symmetric Atkinson proposed by Frankel and Volij (2011)  is group composition invariant (i.e., invariant to the groups proportions).
Only the "units-given-groups" version of the Atkinson index is unit composition invariant (i.e., invariant to the units proportions).

{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use dseg.dta}{p_end}

{pstd}
The data are obtained from the Alabama subsample of the 2017 Common-Core of Data compiled by the U.S. National Center for Educational Statistics and contain enrollment counts by school and race.
Variables {cmd:race}, {cmd:white}, {cmd:school}, {cmd:district}, and {cmd:cbsa} identify the racial/ehtnic group, a white dummy, the school, the local educational authority, and the CBSA codes of each observation, respectively.
The variable {cmd:student_count} includes the number of students in each cell. 

{pstd}Displays the normalized Mutual Information index of race segregation in schools{p_end}
{phang2}{cmd:. dseg mutual race given school [fw=student_count], normalized}{p_end}

{pstd}Displays the symmetric Atkinson proposed by Frankel and Volij (2011){p_end}
{phang2}{cmd:. dseg atkinson school given race [fw=student_count]}{p_end}

{pstd}Displays the decomposition of Theil's H index presented by Reardon and Firebough (2002) of race segregation in schools into a between- and a within-districts term{p_end}
{phang2}{cmd:. dseg theil race given school [fw=student_count], within(district)}{p_end}

{pstd}Displays Theil's H index based on the "units-given-groups" notion of segregation{p_end}
{phang2}{cmd:. dseg theil school given race [fw=student_count]}{p_end}

{pstd}Displays the relative diversity index presented by Reardon and Firebough (2002) of race segregation in schools for each Alabama CBSA (and an aggregate of non-CBSA areas){p_end}
{phang2}{cmd:. dseg diversity race given school [fw=student_count], by(cbsa)}{p_end}

{pstd}Displays the group decomposition between white-minority supergroups, and within minority students of the alternative relative diversity index based on the "units-given-groups" notion of segregation{p_end}
{phang2}{cmd:. dseg diversity school given race [fw=student_count], within(white)}{p_end}

{pstd}Displays the mutual information index of race segregation in schools controlling for districts for each Alabama CBSA{p_end}
{phang2}{cmd:. dseg mutual race given school [fw=student_count], by(cbsa) within(district)}{p_end}

{pstd}As before plus it saves (replacing if necessary) dataset Alabama2017.dta with the district indexes and weights used to compute the within term, replaces the current data in memory, and suppresses listing of indexes.
{p_end}
{phang2}{cmd:. dseg mutual race given school [fw=student_count], by(cbsa) within(district,components) saving(Alabama2017.dta,replace) nolist clear}{p_end}

{title:References}

{p 4 8 2}Hutchens, R. (2004). One Measure of Segregation. {it:International Economic Review} 45(2): 555–578. 

{p 4 8 2}Frankel, D. M. and Volij, O. (2011). Measuring school segregation. {it:Journal of Economic Theory} 146(1):1{c -}38.

{p 4 8 2}Mora, R. and Ruiz-Castillo, J. (2011) Entropy-Based Segregation Indices.  {it:Sociological Methodology} 159–194{c -}41.

{p 4 8 2}Reardon, S. F. and Firebaugh, G. (2002). Measures of Multigroup Segregation.
{it:Sociological Methodology} 32:33{c -}67.

{p 4 8 2}Reardon, S.F.; Yun, J.T. and T. M. Eitle (2000). The Changing Structure of School Segregation: Measurement and Evidence of
Multiracial Metropolitan-Area School Segregation, 1989-1995. {it:Demography} 37(3):351{c -}364.

{p 4 8 2}Theil, H., and A. J. Finizza (1971). A Note on the Measurement of Racial Integration of
Schools by Means of Informational Concepts. {it:The Journal of Mathematical Sociology} 1(2): 187–193.

{title:Author}

{p 4 4 2}
Ricardo Mora, Department of Economics, Universidad Carlos III Madrid. Email: ricmora@eco.uc3m.es

{title:Acknowledgements}

{p 4 4 2}I would like to thank Daniel Guinea-Martín for so many comments to improve the syntax and usefulness of the command.

{title:Also see}

{p 4 13 2}
{help duncan}, {help duncan2}, {help hutchens}, {help seg}, {help segregation}, {help ftools} if installed.
