{smcl}
{* 17Jun2026}{...}
{hi:help ntwrk}{...}
{right:{browse "https://github.com/asjadnaqvi/stata-ntwrk":ntwrk v1.0 (beta) (GitHub)}}

{hline}

{title:ntwrk}: is a Stata package for network analysis and visualization from edge-list data.


{marker syntax}{title:Syntax}
{p 8 15 2}

{cmd:ntwrk} {it:value} {ifin} {cmd:,} {opt from(varname)} {opt to(varname)} 
	[{help ntwrk##measures:{it:network measures}}] [{help ntwrk##common:{it:parameters}}]
	[{help ntwrk##layout:{it:network layout}}] 
	[{help ntwrk##links:{it:link options}}] [{help ntwrk##arcs:{it:arc options}}]
	[{help ntwrk##nodes:{it:node options}}]
	[{help ntwrk##output:{it:save and export options}}] 



{marker options}{title:Options}

{synoptset 26 tabbed}{...}

{marker required}{dlgtab:Required}

{p2coldent : {opt value}}Numeric link-value variable. Repeated ({it:from}, {it:to}) pairs are collapsed by summing this variable before analysis and plotting.{p_end}

{p2coldent : {opt from(varname)}}Source-node variable. String and numeric identifiers are both supported.{p_end}

{p2coldent : {opt to(varname)}}Target-node variable. String and numeric identifiers are both supported.{p_end}


{marker measures}{dlgtab:Network measures}

{p2coldent : {opt measure(names)}}List of node measures to compute. Valid names are {it:degree}, {it:between}, {it:indegree}, {it:outdegree}, {it:closeness},
{it:harmonic}, {it:clustering}, {it:transitivity}, {it:eccentricity}, {it:eigenval}, {it:eigenvec}, {it:katz}, {it:pagerank}, {it:hits}, {it:core}, {it:reciprocity}, {it:ancestors}, and {it:descendants}.
If multiple measures are generated then it is highly recommended to save the network data.{p_end}

{p2coldent : {opt weighted}}Use weighted links for supported centrality routines. Without this option, statistics are computed on the binary directed graph. Clustering and transitivity remain topology-based.{p_end}

{p2coldent : {opt directedclustering}}Use directed triangle logic for {it:clustering}. If omitted, local clustering is computed with undirected-style neighbor closure (direction ignored for triangle counting).{p_end}


{p2coldent : {it:Measures:}}

{p2coldent : {bf:degree}}Total degree computed as indegree + outdegree on the directed graph. {bf: degree} is calculated by default.{p_end}

{p2coldent : {bf:indegree}}In-degree count on the directed graph (number of incoming neighbors).{p_end}

{p2coldent : {bf:outdegree}}Out-degree count on the directed graph (number of outgoing neighbors).{p_end}

{p2coldent : {bf:between}}Compute normalized betweenness centrality.{p_end}

{p2coldent : {bf:closeness}}Compute inbound-reach closeness centrality (distances are evaluated on the reversed directed graph).{p_end}

{p2coldent : {bf:harmonic}}Compute inbound harmonic centrality (distances are evaluated on the reversed directed graph).{p_end}

{p2coldent : {bf:clustering}}Compute local clustering coefficient. Neighbor links are treated as connected if either direction exists.{p_end}

{p2coldent : {bf:transitivity}}Compute global transitivity. Neighbor links are treated as connected if either direction exists.{p_end}

{p2coldent : {bf:eccentricity}}Compute node eccentricity on a symmetrized topology as the maximum finite path length from each node.{p_end}

{p2coldent : {bf:eigenval}}Compute iterative spectral centrality (power iteration), controlled by {opt iterations()} and {opt tolerance()}.{p_end}

{p2coldent : {bf:eigenvec}}Compute leading-eigenvector centrality.{p_end}

{p2coldent : {bf:katz}}Compute Katz centrality. Use {opt katzalpha()} to set the attenuation parameter; default is {opt katzalpha(0.1)} (beta is fixed at 1).{p_end}

{p2coldent : {bf:pagerank}}Compute PageRank. Current fixed damping is 0.85; {opt iterations()} and {opt tolerance()} govern convergence checks.{p_end}

{p2coldent : {bf:hits}}Compute HITS hub and authority scores. {opt iterations()} and {opt tolerance()} govern convergence checks.{p_end}

{p2coldent : {bf:core}}Compute undirected core number (k-core index) for each node using the symmetrized topology.{p_end}

{p2coldent : {bf:reciprocity}}Compute node-level reciprocity, capturing the share of each node's incident directed ties that are mutual.{p_end}

{p2coldent : {bf:ancestors}}Compute number of nodes that can reach each node via directed paths.{p_end}

{p2coldent : {bf:descendants}}Compute number of nodes reachable from each node via directed paths.{p_end}


{marker common}{dlgtab:Parameters}

{p2coldent : {opt iter:ations(num)}}Maximum iterations for iterative routines. Default is {opt iterations(100)}.{p_end}

{p2coldent : {opt tol:erance(num)}}Convergence tolerance. Default is {opt tolerance(1e-6)}.{p_end}

{p2coldent : {opt katzal:pha(num)}}Katz attenuation parameter used when {it:katz} is requested. Default is {opt katzalpha(0.1)}.{p_end}

{p2coldent : {opt radius(num)}}Radius used by the {opt layout(star)} layout. Default is {opt radius(5)}.{p_end}


{marker layout}{dlgtab:Layout options}

{p2coldent : {opt layout(star)}}Places nodes around a circle. Controlled by {opt radius()} before normalization. Deterministic.{p_end}

{p2coldent : {opt layout(fr)}}Fruchterman-Reingold force layout (spring-electrical). Uses random initialization, {opt iterations()}, {opt width()}, {opt height()}. Use {opt seed()} for reproducibility.{p_end}

{p2coldent : {opt layout(sphere)}}Fibonacci-style sphere sampling projected to 2D. Useful for spreading many nodes; deterministic.{p_end}

{p2coldent : {opt layout(grid)}}Regular row-column placement over the target frame. Deterministic and fast for large node counts.{p_end}

{p2coldent : {opt layout(random)}}Uniform random placement in the target frame. Use {opt seed()} for reproducibility.{p_end}

{p2coldent : {opt layout(spectral)}}Uses Laplacian eigenvectors (2nd/3rd) from a symmetrized adjacency matrix. Often separates weakly connected groups; deterministic for a fixed graph.{p_end}

{p2coldent : {opt layout(kk)}}Kamada-Kawai spring embedder using all-pairs shortest-path distances. Uses {opt iterations()} and {opt tolerance()} for optimization stopping.{p_end}

{p2coldent : {opt layout(bipartite)}}Two-column layout: source-like nodes on the left, pure targets on the right (fallback split by outdegree vs indegree if needed). Good for sender-receiver structures.{p_end}

{p2coldent : {opt layout(shell)}}Two-shell circular layout where higher-degree nodes are placed on the inner shell and remaining nodes on the outer shell. Deterministic.{p_end}

{p2coldent : {opt layout(spiral)}}Nodes placed sequentially along an outward spiral from the center. Deterministic and useful for highlighting node ordering or connectivity patterns.{p_end}


{p2coldent : {opt seed(num)}}Random seed applied before computation. This affects stochastic components such as {opt layout(fr)} and {opt layout(random)}.{p_end}

{p2coldent : {opt width(num)}, {opt height(num)}}Target frame dimensions. Defaults are {opt width(150)} and {opt height(150)}.{p_end}


{marker links}{dlgtab:Link options}

{p2coldent : {opt lquant:ile(num)}}Number of link quantile classes for color/width grouping. Default is {opt lquantile(5)}.{p_end}

{p2coldent : {opt lcolor(str)}}Color for links. If omitted, color is assigned by {opt lpalette()}.{p_end}

{p2coldent : {opt lw:idth(num)}}Base line-width multiplier. Default is {opt lwidth(0.5)}.{p_end}

{p2coldent : {opt llab:size(str)}}Link-label size for edge-value labels. Default is {opt llabsize(1.2)}.{p_end}

{p2coldent : {opt llabc:olor(str)}}Link-label text color. Default is {opt llabcolor(black)}.{p_end}

{p2coldent : {opt la:lpha(num)}}Link transparency. Default is {opt lalpha(80)}.{p_end}

{p2coldent : {opt reduce(num)}}Trim link endpoints by a fixed length before drawing. Default is {opt reduce(0)}.{p_end}

{p2coldent : {opt lscale}}Enable quantile-based link width scaling. Without this option, all links use constant {opt lwidth()}.{p_end}

{p2coldent : {opt lscalefac:tor(num)}}Exponent used in link width scaling when {opt lscale} is on. Default is {opt lscalefactor(0.3333)}.{p_end}

{p2coldent : {opt lprop}}Accepted by the parser for proportional link styling, but currently has no distinct effect beyond the existing quantile-based link scaling options.{p_end}

{p2coldent : {opt lpropfac:tor(num)}}Accepted with {opt lprop}; currently reserved and has no distinct effect in the plotting routine.{p_end}

{p2coldent : {opt lpalette(str)}}Color palette for links via {help colorpalette}. The default is {it:eltblue}.{p_end}


{marker arcs}{dlgtab:Arc options}

{p2coldent : {opt arc}}Draw links as curved arcs instead of straight arrows. Arcs inherit link properties where necessary.{p_end}

{p2coldent : {opt arcn(num)}}Number of sampled points used per arc. Default is {opt arcn(40)}.{p_end}

{p2coldent : {opt arcrad:ius(num)}}Arc radius passed to the arc routine. Controls curvature when {opt arc} is specified. This is an advanced option and should ideally not be touched.{p_end}

{p2coldent : {opt arrow:size(num)}}Arrowhead size. Default is {opt arrowsize(1.2)}.{p_end}


{marker nodes}{dlgtab:Node options}

{p2coldent : {opt mquant:ile(num)}}Number of node quantile classes. Default is {opt mquantile(5)}.{p_end}

{p2coldent : {opt mvar(varname)}}Variable used for node quantile assignment (node color classes). If omitted, node classes are based on the selected node metric, which defaults to {it:degree}.{p_end}

{p2coldent : {opt mcolor(str)}}Fill color for node circles. If omitted, color is assigned by {opt mpalette()}.{p_end}

{p2coldent : {opt ms:ize(num)}}Base node size. Default is {opt msize(5)}.{p_end}

{p2coldent : {opt mlab:size(str)}}Node-label size. Default is {opt mlabsize(1.6)}.{p_end}

{p2coldent : {opt mlabc:olor(str)}}Node-label text color. Default is {opt mlabcolor(black)}.{p_end}

{p2coldent : {opt ma:lpha(num)}}Node fill transparency. Default is {opt malpha(80)}.{p_end}

{p2coldent : {opt mlap:ha(num)}}Node outline transparency. Default is {opt mlalpha(100)}. This lets you control fill and outline alpha separately.{p_end}

{p2coldent : {opt msym:bol(str)}}Reserved marker-symbol option. Node areas are currently drawn as circle polygons and labels are drawn separately.{p_end}

{p2coldent : {opt mscale}}Enable node-size scaling. Without this option, all nodes use constant {opt msize()}.{p_end}

{p2coldent : {opt mscalefac:tor(num)}}Exponent used in node scaling when {opt mscale} is on. Default is {opt mscalefactor(0.3333)}.{p_end}

{p2coldent : {opt mlcolor(str)}}Outline color for node circles. If omitted, the outline follows the node fill color.{p_end}

{p2coldent : {opt mlw:idth(num)}}Outline width for node circles. Default is {opt mlwidth(0.08)}.{p_end}

{p2coldent : {opt mprop}}Accepted by the parser for proportional node styling. In the current plotting routine it primarily affects palette handling; node sizes remain controlled by {opt msize}, {opt mscale}, and {opt mscalefactor()}.{p_end}

{p2coldent : {opt mpropfac:tor(num)}}Accepted with {opt mprop}; currently reserved and has no distinct effect in the plotting routine. Default is {opt mpropfactor(0.3333)}.{p_end}

{p2coldent : {opt mpalette(str)}}Color palette for node fills via {help colorpalette}. Current defaults are {it:gs12} without {opt mprop}, and {it:cividis} with {opt mprop}.{p_end}

{p2coldent : {opt mrotate(num)}}Rotation angle applied to node labels (in degrees). Default is {opt mrotate(0)}.{p_end}

{p2coldent : {opt mpoints(num)}}Number of points used to draw node circles as polygons. Minimum is {opt mpoints(3)}. Controls the smoothness of circular node visualization.{p_end}


{marker output}{dlgtab:Output and export}

{p2coldent : {opt save}}Export generated link/node coordinates and attributes to disk as {it:saveprefix}{cmd:.dta}.{p_end}

{p2coldent : {opt replace}}Allow the exported dataset to overwrite an existing file when {opt save} is specified.{p_end}

{p2coldent : {opt saveprefix(str)}}Prefix for the exported dataset filename. If omitted with {opt save}, the default prefix is {it:_network}.{p_end}

{p2coldent : {opt nogra:ph}}Skip plotting but still allow dataset export when {opt save} is specified.{p_end}

{p2coldent : {opt noval:ues}}Suppress edge-value labels.{p_end}

{p2coldent : {opt valcond:ition(num)}}Suppress edge-value labels for links with values less than or equal to this threshold. Default is {opt valcondition(0)}.{p_end}

{p2coldent : {opt format(str)}}Numeric display format applied to edge-value labels in the graph (including curved labels when {opt arc} is used). Default is {opt format(%9.2f)}.{p_end}



{p2coldent : {opt *}}Pass standard twoway options not elsewhere specified.{p_end}

{synoptline}
{p2colreset}{...}


{title:Dependencies}

{stata ssc install palettes, replace}
{stata ssc install colrspace, replace}
{stata ssc install graphfunctions, replace}


{title:Examples}
See {browse "https://github.com/asjadnaqvi/stata-ntwrk":GitHub} for examples.


{hline}

{title:Feedback}
Please submit bugs, errors, feature requests on {browse "https://github.com/asjadnaqvi/stata-ntwrk/issues":GitHub} by opening a new issue.


{title:Package details}

Version      : {bf:ntwrk} v1.0 (beta)
This release : 17 Jun 2026
First release: 17 Jun 2026
Repository   : {browse "https://github.com/asjadnaqvi/stata-ntwrk":GitHub}
Keywords     : Stata, networks, graphs
License      : {browse "https://opensource.org/licenses/MIT":MIT}

Author       : {browse "https://github.com/asjadnaqvi":Asjad Naqvi}
E-mail       : asjadnaqvi@gmail.com
Twitter      : {browse "https://twitter.com/AsjadNaqvi":@AsjadNaqvi}


{title:Citation guidelines}

Use the package details above and repository URL for software citation until an SSC citation entry is assigned for this package name.


{title:References}

{p 4 8 2}Jann, B. (2018). {browse "https://www.stata-journal.com/article.html?article=gr0075":Color palettes for Stata graphics}. The Stata Journal 18(4): 765-785.

{p 4 8 2}Jann, B. (2022). {browse "https://ideas.repec.org/p/bss/wpaper/43.html":Color palettes for Stata graphics: An update}. University of Bern Social Sciences Working Papers No. 43.

{p 4 8 2}Grund, T. (2014). {browse "https://github.com/THOMASGRUND/NWCOMMANDS":nwcommands}. Social network analysis in Stata.

{p 4 8 2}Aric A. Hagberg, Daniel A. Schult and Pieter J. Swart, "Exploring network structure, dynamics, and function using NetworkX", in Proceedings of the 7th Python in Science Conference (SciPy2008), Gäel Varoquaux, Travis Vaught, and Jarrod Millman (Eds), (Pasadena, CA USA), pp. 11–15, Aug 2008. {browse "https://networkx.org/en/":networkx}.


{title:Other visualization packages}

{psee}
    {helpb arcplot}, {helpb alluvial}, {helpb bimap}, {helpb bumparea}, {helpb bumpline}, {helpb circlebar}, {helpb circlepack}, {helpb clipgeo}, {helpb delaunay}, {helpb graphfunctions},
	{helpb geoboundary}, {helpb geoflow}, {helpb joyplot}, {helpb marimekko}, {helpb ntwrk}, {helpb polarspike}, {helpb sankey}, {helpb schemepack}, {helpb spider}, {helpb splinefit}, {helpb streamplot}, 
	{helpb sunburst}, {helpb ternary}, {helpb tidytuesday}, {helpb treecluster}, {helpb treemap}, {helpb trimap}, {helpb waffle}, {helpb vcontrol}

Visit {browse "https://github.com/asjadnaqvi":GitHub} for further details.	