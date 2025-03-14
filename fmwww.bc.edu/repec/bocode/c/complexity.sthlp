{smcl}
{* *! version 5.0  March 2025}{...}

{title:Title}
{cmdab: complexity}  {hline 2}  computes indexes of the complexity of specialization patterns.



{title:Description}
{p2colset 9 18 22 2}{...}

{cmdab: complexity} only requires as input the matrix of individuals' specialization over activities - either expressed in raw performance in each activity (e.g. export value or employment) or in Revealed Comparative Advantage (RCA).
This input can be either specified as Stata varlist, Stata matrix or mata matrix, with inidividuals in row and activities in columns.
 
Three alternative methodologies are available. By default, the eigenvalue method is followed as detailed at the {browse "https://oec.world/fr/resources/methodology/": OEC methodology} webpage.
The alternative methods are the inital Method of Reflection (MR, Hidalgo & Hausmann, 2009), and the Fitness index (Tacchela et al, 2012).

Additional metrics can be computed as the Relatedness of the specialization pattern, and the complexity potential for each individual.

For generalization purposes, we refer to individuals and activities, rather than respectively countries and products in the reference literature. 

{p2colreset}{...}


{pstd}


{title:Syntax}

{p 8 17 2}
{cmdab: complexity}
{cmd:,}
{opt var:list()}
{opt m:atrix()}
{opt mats:ource()}
{opt met:hod()}
{opt rel:atedness}
{opt pot:ential}
{opt rca}
{opt iter:ations()}
{opt p:rojection()}
{opt t:ranspose}
{opt x:var}



{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}

{it:Required}
{synopt:{opt var:list()}  } Varlist indicating the "activities" of specialization.

OR

{synopt:{opt m:atrix()}  }  Name of input matrix.


{synopt:{opt mats:ource()}} Indicates the input matrix type. Can be {cmd: matrix} for a matrix stored in Stata or {cmd: mata} for a mata matrix (default). 

{it:Optional}

{synopt:{opt met:hod()}} Indicates the algorithm followed. Can be {cmd:eigenvalue} (default if empty).
Alternative methods are {cmd:mr} to follow instead the Method of Reflection as in {browse "https://www.pnas.org/content/106/26/10570.short":Hidalgo & Hausmann, 2009},
 or {cmd:fitness} to follow the Fitness Complexity Method as detailed in {browse "https://www.nature.com/articles/srep00723":Tacchella et al.(2012)}. Note that fitness at the activity level is the reverse of its complexity.

 {synopt: {opt rel:atedness}} Computes the relatedness of the specialization pattern for each individual (average proximity of specialization area)

 
 {synopt:{opt pot:ential}} Indicates the Complexity Potential (average complexity of neighboring activities), and targets ranked by complexity gains/accessibility.

 
{synopt:{opt rca}} To be specified if varlist() or matsource() correspond to Revealed Comparative Advantage matrix. 
 
{synopt:{opt iter:ations}} Sets the number of iterations (for MR or fitness methods). If reached, the optimal level of iteration (i.e. when the final ranking doesn't vary anymore) is chosen. Iterations must be of even order.
 
{synopt:{opt p:rojection()}} Indicates which complexity index to return. {cmd: indiv} would return the individuals' complexity (e.g. countries ECI), while {cmd:activities} returns the activities' complexity (e.g. product PCI). 
In any case both are computed. If none are indicated, individuals' complexity is returned by default.

{synopt:{opt t:ranspose}} Transpose initial matrix if individuals were in columns and activities in rows.

{synopt:{opt x:var}} Doesn't return a Stata variable (only Stata and mata matrices are stored).


{title:Output}
{cmd: complexity} returns the following variables. Caution: Previous variables with these names will be deleted.
{cmd: Complexity_i} The complexity score of each individual 
Alternatively : 
{cmd: Complexity_MR_i} {it: if option method(MR)}
{cmd: fitness_i} {it: if option method(fitness)}

If option Relatedness is specified:
{cmd: Relatedness_i}: The relatedness score for each individual

If option Potential is specified:
{cmd: CompPotential_i}: The Complexity Potential for each individual
{cmd: target*}: Score of targeting priority for each individual and activity.

Note: with projection(activities) option, the variables created take the _a suffix instead of _i.



{title:Stored result}
{cmd: complexity} saves the following in {cmd:r()}:

Vectors
{cmd:  r(Complexity_individual)} Column vector of Individuals' complexity values
{cmd:  r(Complexity_activity)} Column vector of activities' complexity values
{cmd:  r(Diversity)} Column vector of Individuals' diversity (nb of activities with RCA>=1 for each individual)
{cmd:  r(Ubiquity)} Column vector of activities' Ubiquity (nb of individuals with RCA>=1 in this activity)

The same vectors are stored in Mata, respectively under the names:
{cmd: comp_i}
{cmd: comp_a}
{cmd: Diversity}
{cmd: Ubiquity}

if the {cmd: fitness} method is specified the vectors returned are 
{cmd:  r(fitness_individual)} Column vector of Individuals' complexity values
{cmd:  r(fitness_activity)} Column vector of activities' fitness values
{cmd:  r(complexity_activity)} Column vector of activities' fitness values
and respective mata vectors are
{cmd: fitness_i}
{cmd: fitness_a}
{cmd: complexity_a}

if the {cmd: relatedness} option is specified two matrices are stored in mata.
{cmd: Prox_a}
{cmd: Prox_i}
which are adjacency matrices of the Proximity space of activities and individuals (cf the Product Space from Hidalgo et al. 2007)



Scalars
{cmd:  r(iterations)} : Number of iterations used in MR or fitness method




{marker examples}{...}
{title:Examples}

To compute complexity index on a real set of data, please see this link:
{browse "https://www.statalist.org/forums/forum/general-stata-discussion/general/1517977-new-on-ssc-complexity-computes-complexity-indexes-similar-to-eci-pci": This Statalist thread}

Otherwise, on random example values:
{phang}{cmd:. set obs 15}{p_end}
{phang}{cmd:. gen n1=runiform()*10}{p_end}
{phang}{cmd:. gen n2=runiform()*10}{p_end}
{phang}{cmd:. gen n3=runiform()*10}{p_end}
{phang}{cmd:. gen n4=runiform()*10}{p_end}
{phang}{cmd:. putmata M=(n*)}{p_end}
{phang}{cmd:. mkmat n*,matrix(S) }{p_end}


{it:Using varlist() input}

{phang}{cmd:. complexity, varlist(n*) }{p_end}
{phang}{cmd:. complexity, varlist(n*) rel }{p_end}
{phang}{cmd:. complexity, varlist(n*) rca proj(activities) }{p_end}


{it:Using  a mata matrix as input}
{phang}{cmd:. complexity,  matrix(M) method(fitness)}{p_end}


{it:Using  a Stata matrix as input}
{phang}{cmd:. complexity, matsource(matrix) mat(S) potential rca }{p_end}



{marker Notes}{...}
{title:Notes}
Requires moremata (available on SSC) package to run.
version 5.0  March 2025

{marker References}{...}
{title:References}
On the Method of Reflection for ECI/PCI indexes: {browse "https://www.pnas.org/content/106/26/10570.short": Hidalgo & Hausmann, 2009}
On the Eigenvector Method for ECI/PCI indexes: {browse "https://oec.world/fr/resources/methodology/": OEC methodology}
On the Fitness index: {browse "https://www.nature.com/articles/srep00723":Tacchella et al.(2012)}
On the Product Space and relatedness : {browse "https://arxiv.org/pdf/0708.2090": Hidalgo et al.(2007)}

{marker Author}{...}
{title:Author}
Charlie Joyez, Université Côte d'Azur, France
charlie.joyez@univ-cotedazur.fr

{title: Cite as}
Charlie Joyez, 2019. "COMPLEXITY: Stata module to compute complexity indexes from comparative advantage tables," Statistical Software Components S458689, Boston College Department of Economics, revised March 2025. 

{marker Acknowledgment}{...}
{title:Acknowledgment}
This program benefited from fruitful discussions with Mauricio Vargas.




