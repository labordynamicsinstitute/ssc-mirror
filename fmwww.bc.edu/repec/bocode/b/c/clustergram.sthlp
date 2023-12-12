{smcl}
{hline}
help for {hi:clustergram}{right:{hi: Matthias Schonlau}}
{hline}


{title:Title}

{p2colset 5 23 25 2}{...}
{p2col :{cmd:clustergram} {hline 2}} Graph for visualizing hierarchical and non-hierarchical cluster analyses {p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 16 2}
{cmd:clustergram} {varlist} {ifin} {cmd:,} [ {it:options} ]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt cl:uster(varlist)}} Variable list with the cluster assignments {p_end}
{synopt :{opt fr:action(real)}} Increase/decrease thickness of graph elements {p_end}
{synopt :{opt color(str)}} Specify color of graph elements {p_end}
{synopt :graph_options} Specify additional options passed to {it:graph, twoway} {p_end}

{title:Description}

{pstd}{cmd:clustergram} draws a graph to examine how cluster members are assigned
to clusters as the number of clusters increases in a cluster analysis. This is
similar in spirit to the dendrograms (tree graphs) used for hierarchical
cluster analyses. The graph is useful for non-hierarchical
clustering algorithms, such as {it:k}-means, and for hierarchical cluster
algorithms, including when the number of observations is too large for dendrograms to be
practical.

{pstd} The width of the graph boxes is proportional to the number of observations in it.
Width is defined here as vertical width, i.e. the difference between the upper and lower y-value.

{pstd}{it:varlist} usually contains the variables with which the cluster algorithm was
run. These variables are only used to compute the value of the vertical axis for each
cluster. The vertical axis gives the cluster means, where the cluster means are computed over 
all cluster variables and over all observations in a given cluster.

{pstd} It is also possible to specify a single variable to examine the 
cluster assignments w.r.t that variable. It is also possible to specify a variable
that was not among the variables that was used for the cluster analysis. 


{title:Options}

{phang} {opt cluster} specifies the variables
containing cluster assignments. 
The examples below show how to generate such variables using {cmd:cluster}. 
 Typically, the cluster variables will be named something like {it:cluster1-cluster}{it:max}, 
 where {it:max} is the maximum number of clusters identified. 
If so, variable {it: cluster1} will contain {it:1} for all observations to indicate the single cluster. 
Variable {it: cluster2} will contain {it:1}'s and {it:2}'s 
depending on whether the observation belongs to cluster 1 or cluster 2. This option is required. 

{phang}{opt fraction} specifies a fudge factor controlling the
width of graph boxes. This fudge factor is applied to all graph boxes. 
This option is specified as needed to reduce visual clutter. 
The value should be between 0 and 1. The default is 0.2.

{phang}{opt color} specifies the color for the box elements. 
Color names are explained in {it:{help colorstyle}}.
By default, the color is black. 

{phang}
{it:graph_options} are options of {cmd:graph, twoway} other than 
{cmd:symbol()} and {cmd:connect()}. 

{title:Examples}

{dlgtab:Fisher's Iris data}

{pstd}Plot the clustergram for up to 5 clusters for Fisher's Iris data. 
We would usually standardize the Iris variables but omit this here for brevity.
{p_end}

{phang2}{cmd:. use https://www.stata-press.com/data/r17/iris, clear} {p_end}
{phang2}{cmd:. set seed 10} {p_end}
{phang2}{cmd:. local max=5} {p_end}
{phang2}{cmd:. foreach i of numlist 1/`max'  {c -(}  } {p_end}
{phang2}{cmd:.      cluster kmeans seplen-petwid, k(`i') L2 name("cluster`i'")} {p_end}
{phang2}{cmd:. {c )-}  } {p_end}
{phang2}{cmd:. clustergram seplen-petwid, cluster(cluster1-cluster`max')} {p_end}

{pstd}{it:({stata clustergram_examples iris1:click to run})}{p_end}


{pstd}Changing color (with 50% translucency) and specifying narrower width to reduce visual clutter: {p_end}
{phang2}{cmd:. clustergram seplen-petwid, cluster(cluster1-cluster`max'), color(blue%50) frac(.1) } {p_end}

{pstd}{it:({stata clustergram_examples iris2:click to run})}{p_end}


{pstd}Instead of displaying the cluster mean over all variables, we only display the cluster mean for petal length. 
This shows that the first split results into a cluster with large and a cluster with small petal length. {p_end}

{phang2}{cmd:. clustergram petlen, cluster(cluster1-cluster`max') ytitle("Average Petal Length") } {p_end}

{pstd}{it:({stata clustergram_examples iris3:click to run})}{p_end}


{dlgtab:Women's club data}

{pstd}The women's club data consists of 35 indicator variables (which take values 0 and 1) about women's interests.
The purpose was to seat women with common interest at the same lunch table. 
Using kmeans, we find that early on one cluster forms where all women are interested in fiction books and 
later on a cluster where no women is interested in fiction books.

{phang2}{cmd:. use https://www.stata-press.com/data/r17/wclub.dta, clear} {p_end}
{phang2}{cmd:. set seed 10} {p_end}
{phang2}{cmd:. local max=5} {p_end}
{phang2}{cmd:. foreach i of numlist 1/`max'  {c -(}  } {p_end}
{phang2}{cmd:.      cluster kmeans bike-fish, k(`i') L2 name("cluster`i'")} {p_end}
{phang2}{cmd:. {c )-}  } {p_end}
{phang2}{cmd:. clustergram fict, cluster(cluster1-cluster`max'), ytitle(Av. Fiction Books)} {p_end}

{pstd}{it:({stata clustergram_examples wclub:click to run})}{p_end}



{title:References}

{phang}
Schonlau, M. The clustergram: a graph for visualizing hierarchical and non-hierarchical cluster analyses. 
The Stata Journal, 2002; 2 (4):391-402.

{phang}Schonlau, M. Visualizing Hierarchical and Non-Hierarchical 
Cluster Analyses with Clustergrams. Computational Statistics. 2004; 19(1): 95-111.

{title:Author}

{pstd}Matthias Schonlau, University of Waterloo {p_end}
{pstd}schonlau at uwaterloo dot ca {p_end}
{pstd}{browse "http://www.schonlau.net":www.schonlau.net}

{title:Also see}

{pstd}help for {help cluster}, hammock plots ({stata ssc install hammock:click to install from SSC}) {p_end}
