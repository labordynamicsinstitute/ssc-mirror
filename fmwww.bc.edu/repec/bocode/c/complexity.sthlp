{smcl}
{* *! version 4.0  21juin2021}{...}

{title:Title}

{p2colset 9 18 22 2}{...}
{cmdab: complexity} computes several metrics of Complexity of specialization pattern (See ECI/PCI from Hidalgo et al. 2009, 20017, or fitness Tachela et al 2017).
For generalization purposes, we refer to individuals (rather than countries), and nodes (from any network rather than goods from product space). 
{cmdab: complexity} only requires a matrix of individuals' specialization over nodes as input - either expressed in raw performance or in Revealed Comparative Advantage (RCA) (see Haussman & Hidalgo, 2012).
This input can be either specified as Stata varlist, Stata matrix or mata matrix, with inidividuals in row and nodes in columns.
Three alternative methodologies are available. By default, the eigenvalue method is followed as detailed at the {browse "https://oec.world/fr/resources/methodology/": OEC methodology} webpage.
The alternative methods are the inital Method of Reflection (MR, Hidalgo & Hausmann, 2009), and the Fitness index (Tacchela et al, 2012).
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
{opt rca}
{opt iter:ations()}
{opt p:rojection()}
{opt t:ranspose}
{opt x:var}



{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}

{it:Required}
{synopt:{opt var:list()}  } Varlist indicating the "nodes" or activities of specialization.

OR

{synopt:{opt m:atrix()}  }  Name of input matrix.


{synopt:{opt mats:ource()}} Indicates the input matrix type. Can be {cmd: matrix} for a matrix stored in Stata or {cmd: mata} for a mata matrix (default). 

{it:Optional}

{synopt:{opt met:hod()}} Indicates the algorithm followed. Can be {cmd:eigenvalue} (default if empty).
Alternative methods are {cmd:mr} to follow instead the Method of Reflection as in {browse "https://www.pnas.org/content/106/26/10570.short":Hidalgo & Hausmann, 2009},
 or {cmd:fitness} to follow the Fitness Complexity Method as detailed in {browse "https://www.nature.com/articles/srep00723":Tacchella et al.(2012)}. Note that fitness at the node level is the reverse of its complexity.

{synopt:{opt rca}} To be specified if varlist() or matsource() correspond to Revealed Comparative Advantage matrix. 
 
{synopt:{opt iter:ations}} Sets the number of iterations (for MR or fitness methods). If reached, the optimal level of iteration (i.e. when the final ranking doesn't vary anymore) is chosen. Iterations must be of even order.
 
{synopt:{opt p:rojection()}} Indicates which complexity index to return. {cmd: indiv} would return the individuals' complexity (e.g. countries ECI), while {cmd:nodes} returns the nodes' complexity (e.g. product PCI). 
In any case both are computed. If none are indicated, individuals' complexity is returned by default.

{synopt:{opt t:ranspose}} Transpose initial matrix if individuals were in columns and nodes in rows.

{synopt:{opt x:var}} Doesn't return a Stata variable (only Stata and mata matrices are stored).



{title:Stored result}
{cmd: complexity} saves the following in {cmd:r()}:

Vectors
{cmd:  r(Complexity_individual)} Column vector of Individuals' complexity values
{cmd:  r(Complexity_node)} Column vector of nodes' complexity values
{cmd:  r(Diversity)} Column vector of Individuals' diversity (nb of nodes with RCA>=1 for each indiv)
{cmd:  r(Ubiquity)} Column vector of nodes' Ubiquity (nb of individuals with RCA>=1 in this node)

The same vectors are stored in Mata, respectively under the names:
{cmd: comp_i}
{cmd: comp_n}
{cmd: Diversity}
{cmd: Ubiquity}

if the {cmd: fitness} method is specified the vectors returned are 
{cmd:  r(fitness_individual)} Column vector of Individuals' complexity values
{cmd:  r(fitness_node)} Column vector of nodes' fitness values
{cmd:  r(complexity_node)} Column vector of nodes' fitness values
and respective mata vectors are
{cmd: fitness_i}
{cmd: fitness_n}
{cmd: complexity_n}

Scalars
{cmd:  r(iterations)} : Number of iterations used in MR or fitness method


{marker examples}{...}
{title:Examples}

To compute complexity index on a real set of data, please see this link:
{browse "https://www.statalist.org/forums/forum/general-stata-discussion/general/1517977-new-on-ssc-complexity-computes-complexity-indexes-similar-to-eci-pci": This Statalist thread}

Otherwise, on random example values:

{it:Using varlist() input}
{phang}{cmd:. set obs 15}{p_end}
{phang}{cmd:. gen n1=runiform()*10}{p_end}
{phang}{cmd:. gen n2=runiform()*10}{p_end}
{phang}{cmd:. gen n3=runiform()*10}{p_end}
{phang}{cmd:. gen n4=runiform()*10}{p_end}

{phang}{cmd:. complexity, varlist(n*) }{p_end}
{phang}{cmd:. complexity, varlist(n*) rca method(mr) }{p_end}


{it:Using matsource() input}
{phang}{cmd:. mata mat=(0.1,0.2,3,1.2 \ 0.5, 1, 1.5 , 1 \ 2.1 , 0 , 5, 0.5)}{p_end}
{phang}{cmd:. mata st_matrix("Smat", mat)}{p_end}

{phang}{cmd:. complexity, matsource(matrix) mat(Smat)}{p_end}
{phang}{cmd:. complexity,  matrix(mat) pro(nodes)}{p_end}
{phang}{cmd:. complexity,  matrix(mat) method(mr)}{p_end}



{marker Notes}{...}
{title:Notes}
Requires moremata (available on SSC) package to run.

{marker References}{...}
{title:References}
On the Method of Reflection for ECI/PCI indexes: {browse "https://www.pnas.org/content/106/26/10570.short":Hidalgo & Hausmann, 2009}
On the Eigenvector Method for ECI/PCI indexes: {browse "https://oec.world/fr/resources/methodology/": OEC methodology}
On the Fitness index: {browse "https://www.nature.com/articles/srep00723":Tacchella et al.(2012)}


{marker Author}{...}
{title:Author}
Charlie Joyez, Université Côte d'Azur, France
charlie.joyez@univ-cotedazur.fr

{marker Acknowledgment}{...}
{title:Acknowledgment}
This program benefited from fruitful discussions with Mauricio Vargas.




