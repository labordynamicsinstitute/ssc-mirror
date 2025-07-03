
{smcl}

{title: Ehutchens: Hutchens `square root' segregation index, with decompositions by subgroup, and extended options for supergroups, stored matrices and new datasets}

        {cmdab:ehutchens} {it:unitvar} {it:segvar} [{it:weight}] [{cmdab:if} exp] [{cmdab:in} range] [, {cmdab:by:group}(groupvar) {cmdab:m:issing} {cmdab:f:ormat}(%fmt) {cmdab:su:pergroup}(varname) {cmdab:s:ave}(string) {cmdab:c:lear}]
                  [{cmdab:b:ootstrap} {cmdab:re:ps}(integer 400) {cmdab:se:ed}(integer 12345) {cmdab:cl:uster}(varname)]

        {cmdab:fweights} and {cmdab:aweights} are allowed; see {help weights}.

{title: Description}

	{cmdab:ehutchens} is an extension of {help hutchens} command, which computes the `square root' segregation index proposed by Hutchens (2004) from individual-level data. 
	The Hutchens' segregation index, {it:S}, is an entropy-based index of inequality in the distribution of individuals across social units, defined for the two-group case. The Hutchens segregation index satisfies several desirable 
	properties for a good numerical measure of segregation, it is is additively decomposable by population subgroup as the sum of within-group segregation (a weighted sum of local {it:S} index values across subgroups) plus 
	between-group segregation. The {it:S} is a distributional measure around the marginal distribution of units, defined as the extent of inequality between the social group proportions across social units
	and the proportion of social groups in the entire population ("units given groups" notion). The {it:S} index is normalized in the unit interval, with zero representing complete integration, and one representing 
	complete segregation. Moreover, as an additive index, the {it:S} can written as a sum of the contribution of each non-overlapping subgroup to the total segregation, an unique feature across entropy-based indices. 
	See Hutchens (2001, 2004), Jenkins et al. (2006), Mora & Ruiz-Castillo (2008, 2009), Alonso-Villar & Del Río (2010).
	
	{cmdab:ehutchens} allows the calculation of the S index and its decomposition across supergroups (e.g. countries), it stores results in matrices, which can be saved as a new dataset that replaces the current dataset in memory. 
	The distribution of the main results across subsamples can also be calculated by resampling using the bootstrap option. These extensions are incremental so that they generate results from the original decompositon by 
	subgroup. Similarly, the bootstrap option is an extension of the supergroup option. All options store results in matrices. The save option, in turn, generates new datasets from stored results for either the 
	bygroup option (entire sample) or supergroup option (subsamples). Last, the clear option replaces the current data by the new saved dataset.
	
	{it:unitvar} is the categorical variable that maps social units and {it:segvar} is the categorical binary variable (0/1) defining the social groups membership of individuals who are segregated across social units, where 
	the value 1 is the social group of interest. The decomposition of {it:S} by population subgroup is defined by {it:groupvar}, the categorical variable that cluster the social units. The overall {it:S} and its decomposition 
	can be calculated across the {it:supergroup} categorical variable, which maps especific subsamples. Results are stored as matrices, and the option {it:save} creates the new dataset for the subgroup decomposition for 
	the entire sample and across subsamples, which can replace the original dataset if {it:clear} option is specified. The option {it:bootstrap} calculates the estimates across supergroups by resampling the social units to approximate 
	the distribution of the estimates to deal with sampling variation in survey data. All calculations are based on the subset of observations with valid values on unitvar and segvar.

{title: Options}

        {cmdab:bygroup}({it:groupvar}) specifies the decomposition by population subgroups defined by {it:groupvar}. This option generate the local index values for each subgroup, their additive contribution, and the decompositon of 
	the total segregation as the sum of the within-segregation and between-segregation components.
		
	{cmdab:missing} option treat missing values as a different category in the subgroup ({it:groupvar}) variable. Cases with missing values form a separate subgroup when decompositions are done. It is then a suboption of the bygroup option as
	in the original command. If missing option is not specified, then all calculations (including aggregate statistics) are based on the subset of observations with valid values on unitvar, segvar, and groupvar.

        {cmdab:format}(%fmt) specifies the format to be used to display the results. The default is format(%10.0g).
		
	{cmdab:supergroup}({it:varname}) specifies the abovementioned decomposition across subsamples defined by {it:varname}. The supergroup option generate results if option bygroup is specified, yielding the complete 
	decomposition of {it:S} across subsamples.
		
	{cmdab:save} ({it:string}) save index values and statistics from the stored matrices in a Stata data file {it:string} defined as {it:mydatafile.dta}, in the working directory previously set up by the user.
	
	{cmdab:clear} replaces data in memory with the saved dataset containing index values. 
		
	{cmdab:bootstrap} {cmdab:reps}(integer 400){cmdab:seed}(integer 12345){cmdab:cluster}({it:varname}) sets the number of bootstrap samples in {cmdab:reps} (400 by default), sets the random-number seed in {cmdab:seed} (12345 by default)
	and {cmdab:cluster} specifies the social units defined in {it:unitvar} as resampling clusters. This option is defined from the built-in bootstrap Stata command, allowing sample weights and storing estimations, but its usage is 
	restricted to the three suboptions already mentioned. It runs the original hutchens command slightly modified, as an internal program, for each bootstrap replication after the supergroup calculations are completed. 
	Estimations are stored in a matrix. This option cannot be used with save option.


{title: Examples} 

    Occupational sex segregation:

        . ehutchens isco88 sex

    Sex segregation in schools, with a decomposition by school type (e.g. public/private):

        . ehutchens schoolid sex, by(stype)

    Sex segregation in schools, with a decomposition by school type and region:

        . egen stypeXregion = group(stype region)

        . ehutchens schoolid sex, by(stypeXregion)
		
    Sex segregation in schools, with a decomposition by school type across regions (supergroup option):
	
	. ehutchens schoolid sex, by(stype) supergroup(region)

    Sex segregation in schools, with a decomposition by school type across regions (supergroup option), saving results as new dataset:
	
	. ehutchens schoolid sex, by(stype) supergroup(region) save(mydata.dta)
	
    Sex segregation in schools, with a decomposition by school type across regions (supergroup option), saving results as new dataset and replacing current dataset by the saved results dataset:
	
	. ehutchens schoolid sex, by(stype) supergroup(region) save(mydata.dta) clear

    Sex segregation in schools, with a decomposition by school type across regions (supergroup option) and bootstrap of main results across regions:
	
	. ehutchens schoolid sex, by(stype) supergroup(region) bootstrap reps(500) seed(85774) cluster(schoolid)
	
{title: Stored results}
	
	{cmdab:ehutchens} stores results in r() as matrices. The results comprise index values for the total estimation sample (S), across subgroup id (BG) and/or subsample id (SG), and the following statistics across subgroups: 
	the local index value (local_S), the demographic weight as a geometric mean of the two social groups (weight), the contribution to total segregation (contrib), the social group share across subgroups (soc_g_%) and the 
	subgroup demographic share (demo_%), plus the value of the decomposition components, within and between subgroups, and their percentage (SW, SB, SW_%, SB_%).
	
	Matrices 
	
	 r(M)       Matrix of index values and statistics for the subgroup and supergroup options

	 r(M_B)     Matrix of index values and statistics when bootstrap option is specified to resample the calculations across each subsample defined in supergroup option. It stores S, SW, SB, and 
	            their respective confidence intervals (bias-corrected confidence intervals, BC). 


References

        Chakravarty, S. R., & Silber, J. (2007). A generalized index of employment segregation. Mathematical Social Sciences, 53(2), 185-195.
	
	Hutchens, R. (2001). Numerical measures of segregation: desirable properties and their implications. Mathematical social sciences, 42(1), 13-29.
	
	Hutchens, R. (2004). One measure of segregation. International Economic Review 45(2): 555-578.
	
	Jargowsky, P. A., & Kim, J. (2009). The information theory of segregation: uniting segregation and inequality in a common framework. In Occupational and residential segregation (pp. 3-31). Emerald Group Publishing Limited.
		
        Jenkins, S. P., Micklewright, J., & Schnepf, S. V. (2008). Social segregation in secondary schools: how does England compare with other countries?. Oxford review of education, 34(1), 21-37.
	
	Mora, R., Ruiz-Castillo, J., (2008). A defense of an entropy based index of multigroup segregation. Working Paper 07-76, Economic Series 45. Universidad Carlos III de Madrid.
	
	Mora, R., & Ruiz-Castillo, J. (2009). The invariance properties of the mutual information index of multigroup segregation. In Occupational and residential segregation (pp. 33-53). Emerald Group Publishing Limited.
 

Author

	Francisco I. Ceron, LM2C2, Pontificia Universidad Católica de Chile, Chile. Email: fcerona@uc.cl 

Acknowledgements

	Much of the code for ehutchens is based on {help hutchens} written by prof. S.P.Jenkins (LSE). Ehutchens was developed as part of the project `Private privileges and public consequences: Inequality of educational 
	opportunity and learning dynamics in Chile and Latin America'. This projects was conducted at the Amsterdam Institute for Social Science Research (AISSR), University of Amsterdam, and was supported by grant 72140619, awarded 
	to F. Ceron by the Programme of Advance Human Capital, National Commission of Scientific and Technological Research of Chile (CONICYT PFCHA).

Also see

    {help hutchens}, {help duncan}, {help duncan2}, {help seg} if installed.

