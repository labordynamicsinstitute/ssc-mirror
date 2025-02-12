{smcl}
{* *! version 1.0.0 Feb2025}{...}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col : symbionet {hline 2} Builds a symbiotic (or symmetric) correlation network from a list of variables. }
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: symbionet}
[{it:{help varlist}}]
[{cmd:,}
{opt slevel()}
{opt sym:metric}
{opt strict}
{opt keepsignchange}
{opt keepall}
{opt dag} 
{opt output()}
{opt plot}
]

{pstd}
 [{it:{help varlist}}] Indicates the variables to add to the network. {it: _all} is accepted. Something is required.


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}

{synopt:{opt slevel()}} Indicates the significance threshold to keep correlations. Could be 1, 5, 10 (default), or all(100) (no threshold).

{synopt:{opt symmetric}} Indicates if the network has to be symetric. If absent the (default) analysis runs an asymmetric correlation network following Von Jacobi (2018) quantile regression analysis. 

{synopt:{opt strict}} (Only for asymmetric analysis) Restrict the network to strictly commensalit edges (monotonic increase).

{synopt:{opt keepsignchange}} (Only for asymmetric analysis) Do not drop edges with changing tie sign.

{synopt:{opt keepall}} (Only for asymmetric analysis) Keep all edges. Do not restrict network to dominant and commensalist edges.

{synopt:{opt dag}} (Only for asymmetric analysis) Indicates whether the resulting network is a Directed Acyclic Graph.

{synopt:{opt output()}} Output desired. Could be the network {it: edgelist} (default), {it: initial} restores the initial dataset, {it: matrix}* creates the adjacency matrix as Stata variables, and {it: detail} shows the intermediate variables (only debug/development purposes)

{synopt:{opt plot}} Plots the network. Requires nwcommands from Thomas Grund.
{synoptline}
{p2colreset}{...}



{title:Description}

{pstd}
Builds a symbiotic (or symmetric) correlation network from a variable list. Keeps only correlations significant at the level set in slevel()
Returns the edgelsit of correlation network in Stata and its the adjacency matrix in Mata (unless specified otherwise).
Previous dataset is deleted, unless {it: output(intial)} option is chosen.

Two correlations networks can be computed :

- symetric correlation networks computes the bilateral correlation coefficient between variables.

- asymmetric (default) correlation network identifies the directionality of the relationships, building a symbiotic network and only displays dominant and comensalist edges between variables. (See Horvath (2011) ;  Von Jacobi (2018)) 


Note : the {cmd: symbionet} command does not require any additional user written package to run properly. 
However, some options (plot and output(matrix)) require Thomas Grund nwcommands package. 
Similarly, if nwcommands is installed, additional results are stored as Stata networks (see below).


{pstd}
Any nonnumeric variables in the {it: varlist} will be ignored. 


{pstd}
{title:Example}

{cmd:. 	sysuse auto.dta,clear}
{cmd:. netsymmetric _all ,slevel(5)  }

{cmd:. 	sysuse auto.dta,clear}
{cmd:. symbionet price p mpg rep78 headroom trunk ,  dag } 




{title:Saved results}
{pstd}
{cmd: In Mata}
{cmd: Mat} : The adjacency matrix of the correlation network.

{cmd: if nwcommands is installed}
{cmd: symbionetwork}: The correlation network
{cmd: signimat}: The network of significance level of each edge.



{title:See also}	
For a deeper presentation of symbiotic (asymmetric) correlation network, please see:
Von Jacobi, N. 2018. "Institutional Interconnections: Understanding Symbiotic Relationships." Journal of Institutional Economics 14(5): 853–76. doi: 10.1017/S1744137417000558.
Horvath, S. (2011). Weighted network analysis: applications in genomics and systems biology. Springer Science & Business Media.


{title: Cite as}
Please, cite the command as:

{title:Author}
Nadia Von Jacobi, University of Trento
Charlie Joyez, Universite Cote d'Azur
contact : charlie.joyez[@]univ-cotedazur.fr

