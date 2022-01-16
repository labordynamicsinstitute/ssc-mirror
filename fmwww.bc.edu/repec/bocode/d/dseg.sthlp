{smcl}
{* *! version 5  Nov2021}{...}
{cmd:help dseg}{right:dialog:  {dialog dseg}{space 15}}
{hline}

{p2colset 5 19 21 2}{...}
{p2col:{hi: dseg} {hline 2} Decomposable Multigroup Segregation Indices}
{p2colreset}{...}

{title:Syntax}

Segregation using index {it:index} of {it:varlist1} given {it:varlist2}

{p 8 14 2}
{cmd:dseg} {it:index} {it:varlist1} {ifin} {weight} {cmd:,} {opt given(varlist2)} [{it:options}]

{synoptset 33}{...}
{p2coldent:{it:index}}description{p_end}
{synoptline}
{synopt:{opt atkinson}, {opt alt_atkinson}} symmetric Atkinson, A{p_end}
{synopt:{opt theil}, {opt alt_theil}} Theil's {it:H} (Entropy), H{p_end}
{synopt:{opt mutual}, {opt n_mutual}} mutual information, M{p_end}
{synopt:{opt diversity}, {opt alt_diversity}} relative diversity, R{p_end}
{synoptline}

{synoptset 33 tabbed}{...}
{synopthdr}
{synoptline}

{syntab :Mandatory option}
{synopt :{opt g:iven(varlist2)}} the units in "groups-given-units" indices; the groups in "units-given-groups" indices{p_end}

{syntab :Model}
{synopt :{opt add:index(namelist)}} additional indices to be calculated{p_end}
{synopt :{opt b:y(varlist)}} subsamples over which the index is to be calculated{p_end}
{synopt :{opt w:ithin(varlist[,components])}} the partition in the between-within decomposition{p_end}
{synopt :{opt missing}} treats missing values like other values{p_end}
{synopt :{opt fast}} uses contributed command {cmd:ftools} to speed up computing time with big data; see {search ftools}{p_end}

{syntab :Bootstrapping & simulation}
{synopt :{opt boot:straps(#[,opt])}} performs # bootstrap replications{p_end}
{synopt :{opt r:andom(#)}} computes the index with # simulated samples under the assumption of no-segregation{p_end}
{synopt :{opt rseed(#)}} initial value of the random-number seed{p_end}

{syntab :Replacing and saving}
{synopt :{opt clear}} replaces current data{p_end}
{synopt :{opt saving(filename[,opt])}} saves index values in Stata data file {it:filename}{p_end}
{synopt :{opt prefix(name)}} sets the prefix for names of new index variables{p_end}

{syntab :Reporting}
{synopt :{opt nolist}} do not list index values{p_end}
{synopt :{opt f:ormat(%fmt)}} set index display format; default is %9.4f; see {help format}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{cmd:fweight}s are allowed; see {help weight}.{p_end}

{title:Description}

{pstd}
The {cmd:dseg} command computes all known multigroup indices of segregation that are additively decomposable into a between and a within term: 
the symmetric Atkinson index (A), the Theil's {it:H} index (H), the mutual information index (M), and the relative diversity index (R). 
For A, H, and R, two versions are available: 
One version captures how groups shares differ across organizational units.
This is the "groups-given-units" notion of segregation. 
The other version captures how groups are distributed along different organizational units.
This is the "units-given-groups" notion of segregation.
The indices H and R described in Reardon and Firebauch (2002) are "groups-given-units" indices that are weakly unit decomposable. 
Alternatively, the "units-given-groups" versions of H (proposed in Mora and Ruiz-Castillo, 2011) and R are weakly group decomposable.
The A index proposed in Frankel and Volij (2011) is a "units-given-groups" index that is also weakly unit decomposable. The "groups-given-units" version is weakly group decomposable.
Index M, proposed by Theil and Finizza (1971), is both a "groups-given-units" and a "groups-given-units" index. Two versions are also available for M: the original index (using natural logarithms) and a normalized version.
The latter uses as base of the logarithm the minimum between the number of groups or the number of units.
This is a normalization of the index in a weak sense as it is the proportion of maximum segregation reached by the original index (see Mora and Ruiz-Castillo 2011).
The original version is both strongly unit and group decomposable. 
The normalized version is strong unit decomposable if normalized with the natural logarithm of the number of groups.
It is strong group decomposable if normalized with the natural logarithm of the number of units.

{pstd}
The variables specified in {it:varlist1} identify the value combinations that define the groups in "groups-given-units" indices and the units in "units-given-groups" indices.
The variables specified in {it:varlist2} identify the units in "groups-given-units" indices and the groups in the "units-given-groups" indices. 
Hence, the user specifies the index to compute by setting the name of the index and by choosing which variables are included in {it:varlist1} and which variables are included in {it:varlist2}.
As the mutual information index is both a "groups-given-units" and a "units-given-groups" index, which variable list is in {it:varlist1} and which is in {it:varlist2} has no effects on the results.

{pstd}
By default, {cmd:dseg} assumes that each observation in the data set represents one individual.
When data is aggregated (i.e., each observation represents several individuals), a variable in the dataset must contain the number of duplicated observations and {opt fweight} must be used. 

{title:Options}

{dlgtab:Model}

{phang}
{opt add:index(namelist)} is a list of additional indices to be computed.
Alternative indices ({opt alt_atkinson, alt_theil, alt_diversity}) refer to the "units-given-groups" versions when {it:varlist2} identifies the units and to the "groups-given-units" versions when {it:varlist2} identifies the groups.
{p_end}

{phang}
{opt by(varlist)} identifes the subsamples over which the index is to be calculated. It is useful for computing the same index and its decomposition for different years, countries, etc.{p_end}

{phang}
{opt w:ithin(varlist[,opt])} specifies the partition that defines the between-within decomposition. 
It admits the {it:components} suboption.
For A, H, and R, {cmd:dseg} automatically computes the only posible decomposition available for each of these indices.
Hence, for the "units-given-groups" version of A, {it:varlist} identifies the clusters that partition the organizational units defined by {it:varlist1}. 
In contrast, for the "groups-given-units" version of H and R, {it:varlist} identifies the clusters that partition the organizational units defined by {it:varlist2}.
Without loss of generality, for M, or its normalized version, {it:varlist} specifies the partition of {it:varlist2} that defines the between-within decomposition. 
When the {it:components} suboption is used, the procedure additionally returns the components of the within term, namely the weights and the local segregation indices in the within term.
{p_end}

{phang}
{opt missing} treats missing values as other values. By default, {cmd:dseg} assumes missing values are instances of random incomplete information. 
Hence, all observations with missing value in at least one of {it:varlist1}, {it:varlist2}, the variables in {opt by(varlist)}, or the variables in {opt within(varlist)}, are dropped before the calculations are made. 
The {cmd:missing} option reverts this behavior and forces {cmd:dseg} to interpret missing values as categories. {p_end}

{phang}
{opt fast} uses contributed command {cmd:ftools} to speed up computing time with big data. It requires all variables to be numeric; see {help ftools}.{p_end}

{dlgtab:Bootstrapping & simulation}

{phang}
{opt bootstraps(#[,opt])} sets the number of bootstrap samples.
This option invokes the {cmd:bsample} command to generate a bootstrap sample with replacement with the same number of observations that the original sample.
Bootstrap options are passed through by {it:opt}; see {help bsample}.
The {opt bootstraps(#)} option cannot be used with weights or simultaneously with {opt random(#)}.
It results in a new dataset with index values for each of the # bootstrap samples.
In the new dataset, the bootstrap samples are identified with variable {cmd:bsn}, the bootstrap sample number.
The new dataset includes an additional observation with the indices calculated with the original dataset.
This observation is identified with {cmd:bsn = 0}.
The new dataset replaces the current dataset in memory when the {cmd:clear} option is used.
It is saved when the {opt saving(filename,opt)} option is used. 
If none of these two options are used, {cmd:dseg} stops and displays an error message before doing the bootstrap.{p_end}

{phang}
{opt random(#)} computes the index with # simulated samples under the assumption of no-segregation.
Each simulated sample is obtained after randomly reshuffling values of {it: varlist1}. 
Otherwise, {opt random(#)} closely follows the behavior of {opt bootstraps(#)}: 
(a) it cannot be used with weighted data or simultaneously with {opt bootstraps(#)}; 
(b) the output is a new dataset that includes index values for all simulated samples; 
and (c) the new dataset must replace the current dataset and/or be saved.{p_end}

{phang}
{opt rseed(#)} sets the seed for the random number generator.{p_end}

{dlgtab:Returning, replacing, and saving}

{phang}
The {cmd:dseg} command internally creates a temporary data set with the results.
If the {opt within(varlist)} option is not used, the new dataset has as variables the indices calculated. 
If the {opt within(varlist)} option is used, the new dataset also includes, for each index calculated, the between and the within term in the decomposition.
If the {it:components} suboption is used, the new dataset additionally includes the weights and the local segregation indices whose weighted average is the within term for each index.
If neither the {opt by(varlist)} option nor the {it:components} suboption are used, the new dataset has only one observation.
If only the {opt by(varlist)} option is used, the new dataset has as many observations as the number of value combinations in {opt by(varlist)}. 
If {opt within(varlist,components)} is also used, the number of observations in the new dataset equals the number of combinations of the categories defined by the varlists of {opt by(varlist)} and {opt within(varlist,components)} together.{p_end}

{phang}
By default {cmd:dseg} lists the indices and returns matrix {cmd:r(S)} with all of them.
(In addition to the number of observations, the command name, the names of the indices, and the notion of segregation defined by {it:varlist1} and {it:varlist2}.) 
There are three cases in which matrix {cmd:r(S)} is not returned:
(a) when either {opt bootstraps(#)} or {opt random(#)} are used;
(b) when the resulting matrix is too large;
(c) in the presence of a string variable in option {opt by(varlist)} or if {it:components} is used as in {opt within(varlist, components)}.
In the last two cases (b) and (c), a warning message is displayed.{p_end}

{phang}
{opt clear} replaces current data in memory with the new dataset.
{p_end}

{phang}
{opt saving(filename[,opt])} saves the new dataset in {it:filename}.
Saving options are passed through by {it:opt}; see {help save}.{p_end}

{phang}
{opt prefix(name)} attaches {it:name} in front of the default name for each index, each between/within term, and each local weight in the new dataset.
This option is useful in the presence of conflicting names in the new dataset.
There are four types of variable names in the new dataset: 
(a) the indices names; 
(b) the variable names in the list of {opt by(varlist)} if {opt by(varlist)} is used;
(c) the variable names in the list of {opt within(varlist,components)} if {it:components} is used; and
(d) {opt bsn} and {opt ssn} if {opt bootstraps(#)} or {opt random(#)} are used.
For the index versions implicit in the notion of segregation defined by {it:varlist1} and {it:varlist2}, the default names are {cmd:A}, {cmd:H}, {cmd:M}, and {cmd:R}.
For the alternative versions of A, H, and R, the names are {cmd:AltA}, {cmd:AltH}, and {cmd:AltR}, respectively.
For the normalized mutual information, the default name is {cmd:NM}.
When the {opt within(varlist)} option is used, postfixes {cmd:_B} and {cmd:_W} are added after the default name for the between and the within term, respectively.
If the {it:components} suboption is used, postfixes {cmd:_w} and {cmd:_l} are used to name the weights and the local segregation indices.
In case of a conflicting name, {cmd:dseg} stops and issues an error message.{p_end}

{dlgtab:Reporting}

{phang}
{opt nolist} omits the display of index values.
By default, {cmd:dseg} lists the values of the index. 
Option {opt nolist} surpresses the list.
When used together with option {opt clear}, a description of the new data set is displayed.{p_end}

{phang}
{opt format(%fmt)} sets index output display format; default is %9.4f; see {help format}{p_end}

{title:Remarks}

{pstd}
Several papers extensively discuss the properties of the indices
(Frankel and Volij, 2011, Mora and Ruiz-Castillo, 2011, Reardon and Firebaugh, 2002, and Reardon, Yun, and Eitle, 2000). 

{pstd}
The mutual information index proposed by Theil and Finizza (1971) and the symmetric Atkinson index proposed by Frankel and Volij (2011) are both characterized in terms of ordinal axioms by Frankel and Volij (2011). 
The latter was previously characterized by Hutchens (2004) using an alternative set of axioms for the case when the number of groups equals two.
Reardon and Firebaugh (2002) describe the properties of the "groups-given-units" versions of H and R. 
Mora and Ruiz-Castillo (2011) propose the "units-given-groups" version of H and the normalized mutual information, and discuss the decomposability properties of M, and the two versions of H.

{pstd}
All indices have a minimum value of zero. 
The mutual information index has no global maximum. 
For a fixed number of groups and organizational units, its maximum is the minimum between the logarithm of the number of groups and the logarithm of the number of units.
This justifies using this maximum as the base of the logarithms.
All other indices reach a maximum value of one. 
{p_end}

{pstd}
All indices are relative indices of segregation and are invariant to population size.
Only the symmetric Atkinson proposed by Frankel and Volij (2011)  is group composition-invariant (i.e., invariant to the groups proportions).
Only the "units-given-groups" version of the Atkinson index is unit composition-invariant (i.e., invariant to the units proportions).

{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use dseg.dta}{p_end}

{pstd}
The data are obtained from the Alabama subsample of the 2017 Common-Core of Data compiled by the U.S. National Center for Educational Statistics and contain enrollment counts by school and race.
Variables {cmd:race}, {cmd:white}, {cmd:school}, {cmd:district}, and {cmd:cbsa} identify the racial/ehtnic group, a white dummy, the school, the local educational authority, and the CBSA codes of each observation, respectively.
The variable {cmd:student_count} includes the number of students in each cell. 

{pstd}Displays the original mutual information index of race segregation in schools proposed by Theil & Finizza (1971){p_end}
{phang2}{cmd:. dseg mutual race [fw=student_count], given(school)}{p_end}

{pstd}Displays both the original and the normalized mutual information indices{p_end}
{phang2}{cmd:. dseg mutual race [fw=student_count], given(school) addindex(n_mutual)}{p_end}

{pstd}Displays the Theil's H index first used in Theil & Finizza (1971), i.e. the one based on the "groups-given-units" notion of segregation{p_end}
{phang2}{cmd:. dseg theil race [fw=student_count], given(school)}{p_end}

{pstd}Displays both versions of the Theil's H index{p_end}
{phang2}{cmd:. dseg theil race [fw=student_count], given(school) addindex(alt_theil)}{p_end}

{pstd}Displays the group decomposition between white-minority supergroups, and within minority students of the relative diversity index based on the "units-given-groups" notion of segregation.
The format display is changed to improve display precision{p_end}
{phang2}{cmd:. dseg diversity school [fw=student_count], given(race) within(white) format(%9.6f)}{p_end}

{pstd}Displays the decomposition of race segregation in schools into a between- and a within-districts term in all unit-decomposable indices.
Note that the normalized mutual is unit-decomposable in this example because the number of units is larger than the number of groups{p_end}
{phang2}{cmd:. dseg theil race [fw=student_count], given(school) within(district) addindex(mutual n_mutual diversity alt_atkinson)}{p_end}

{pstd}Displays the relative diversity index presented by Reardon and Firebough (2002) of race segregation in schools for each Alabama CBSA (and an aggregate of non-CBSA areas). 
Note that cbsa is a string variable and the results cannot be stored in Stata matrix {cmd:r(S)}.{p_end}
{phang2}{cmd:. dseg diversity race [fw=student_count], given(school) by(cbsa)}{p_end}

{pstd}Displays the mutual information index of race segregation in schools controlling for districts for each Alabama CBSA{p_end}
{phang2}{cmd:. dseg mutual race [fw=student_count], given(school) by(cbsa) within(district)}{p_end}

{pstd}As before plus it saves (replacing if necessary) dataset Mutual_Alabama2017.dta with the indices, the terms of the decomposition, and the district indices and weights used to compute the within term.
The call further replaces the current data in memory, and suppresses the automatic display of indices.
{p_end}
{phang2}{cmd:. dseg mutual race [fw=student_count], given(school) by(cbsa) within(district,components) saving(Mutual_Alabama2017.dta,replace) nolist clear}{p_end}

{title:Saved results}

{pstd}
{cmd:dseg} saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}} number of observations{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}} command name{p_end}
{synopt:{cmd:r(index)}} index (indices) name{p_end}
{synopt:{cmd:r(notion)}} notion of segregation{p_end}

Unless {cmd:bootstraps()} or {cmd:random()} are used and whenever is possible (i.e. when the results do not include a string variable and the matrix dimension is not too large):

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(S)}} matrix of indices{p_end}


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
