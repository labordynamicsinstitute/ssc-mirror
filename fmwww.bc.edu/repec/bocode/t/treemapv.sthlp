{smcl}
{* 09Mar2026}{...}
{hi:help treemapv}
{hline}

{title:Title}

{p 4 4 2}{hi:treemapv} {hline 2} Voronoi treemap visualization (under development)

{pstd}
{bf:Requires Stata 17 or later} (uses frames for data handling)


{title:Syntax}

{p 8 15 2}
{cmd:treemapv} {it:numvar} {ifin} {weight}, {cmdab:by}({it:varlist}) [{it:options}]

{synoptset 36 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Required}
{synopt:{opt by(varlist)}}One to three variables defining the hierarchy (max 3 levels).{p_end}

{syntab:Canvas}
{synopt:{opt xs:ize(num)}}Width of the plot in inches. Default is {it:5}.{p_end}
{synopt:{opt ys:ize(num)}}Height of the plot in inches. Default is {it:3}.{p_end}

{syntab:Algorithm}
{synopt:{opt conv:ergence(num)}}Target convergence ratio for Voronoi iteration. Default is {it:0.01} (1%).{p_end}
{synopt:{opt maxit:er(int)}}Maximum iterations for weighted Voronoi computation. Default is {it:50}.{p_end}
{synopt:{opt minw:eight(num)}}Minimum weight as ratio of maximum. Default is {it:0.01} (1%).{p_end}
{synopt:{opt seed(int)}}Random seed for initial site positions. Default is {it:12345}.{p_end}

{syntab:Data}
{synopt:{opt thresh:old(num)}}Collapse categories smaller than threshold into "Rest of..." Default is {it:0}.{p_end}
{synopt:{opt stat(str)}}Statistic to compute: {bf:sum} (default) or {bf:mean}.{p_end}
{synopt:{opt share}}Display shares/percentages instead of values.{p_end}
{synopt:{opt colorby(var)}}Variable to determine color grouping.{p_end}

{syntab:Styling}
{synopt:{opt palette(str)}}Color palette. See {help colorpalette}.{p_end}
{synopt:{opt pad(numlist)}}Padding between boxes (up to 3 values for each level).{p_end}
{synopt:{opt linew:idth(str)}}Width of boundary lines.{p_end}
{synopt:{opt linec:olor(str)}}Color of boundary lines.{p_end}
{synopt:{opt fade(num)}}Color intensity. Default is {it:10}.{p_end}

{syntab:Labels}
{synopt:{opt nolab:els}}Suppress all labels.{p_end}
{synopt:{opt noval:ues}}Suppress values, show only category names.{p_end}
{synopt:{opt addtitles}}Add variable names as titles.{p_end}
{synopt:{opt labsize(str)}}Size of labels.{p_end}
{synopt:{opt labgap(str)}}Gap between labels.{p_end}
{synopt:{opt labscale(num)}}Label scaling factor. Default is {it:0.3333}.{p_end}
{synopt:{opt labcond(num)}}Conditional display of labels based on area.{p_end}
{synopt:{opt labprop}}Scale labels proportional to box area.{p_end}
{synopt:{opt wrap(numlist)}}Character limits for label wrapping.{p_end}

{synoptline}
{p 4 6 2}
{it:aweights}, {it:fweights}, {it:pweights}, and {it:iweights} are allowed.{p_end}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:treemapv} creates Voronoi treemap visualizations, which display hierarchical data using 
weighted Voronoi tessellations instead of rectangles. This creates organic-looking boundaries 
that can be more aesthetically pleasing than traditional rectangular treemaps.

{pstd}
The algorithm is based on d3-voronoi-treemap by Philippe Rivière, which uses iterative 
weighted Voronoi diagrams to create hierarchical visualizations where each cell's area 
is proportional to its value.

{pstd}
{bf:CURRENT STATUS (v0.2)}: The command integrates with {bf:delaunay.ado} and {bf:voronoi.ado} 
to compute basic Voronoi tessellations. The Lloyd's relaxation framework is implemented but 
weighted iteration (area matching) is not yet complete. Currently falls back to rectangular 
treemap layout.

{pstd}
{bf:Working components}:
{break}- Basic Voronoi diagram computation via delaunay package
{break}- Iteration framework for weighted adjustment
{break}- Polygon area and centroid calculations (Mata functions)
{break}- Initial site positioning

{pstd}
{bf:Not yet implemented}:
{break}- Weighted iteration (adjusting sites to match target areas)
{break}- Convergence checking (requires area calculation integration)
{break}- Hierarchical recursion (nested Voronoi cells)

{pstd}
For production use of true Voronoi treemaps, consider:
{break}- D3.js with d3-voronoi-treemap
{break}- Python with voronoi-treemap package  
{break}- R with treemap package (Voronoi option)


{title:Algorithm Overview}

{pstd}
The Voronoi treemap algorithm works recursively:

{phang}1. Start with a clipping polygon (typically rectangular canvas)

{phang}2. Place random initial "sites" for each data point

{phang}3. Compute weighted Voronoi diagram (Lloyd's relaxation):
{pmore}a. Generate Voronoi tessellation from sites
{pmore}b. Compute centroid of each Voronoi cell
{pmore}c. Weight centroids by target weights (proportional to values)
{pmore}d. Move sites toward weighted centroids
{pmore}e. Repeat until convergence or max iterations

{phang}4. Recursively apply to children using their Voronoi cells as clipping regions


{title:Examples}

{pstd}Single level hierarchy{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. treemapv price, by(rep78)}{p_end}

{pstd}Two level hierarchy{p_end}
{phang2}{cmd:. treemapv price, by(foreign rep78) palette(CET C6)}{p_end}

{pstd}Three level hierarchy with options{p_end}
{phang2}{cmd:. treemapv price, by(foreign rep78 make) threshold(1000) novalues}{p_end}

{pstd}Custom convergence settings{p_end}
{phang2}{cmd:. treemapv price, by(rep78) convergence(0.005) maxiter(100)}{p_end}


{title:Technical Notes}

{pstd}
The Voronoi diagram computation requires:
{break}- Delaunay triangulation
{break}- Voronoi edge computation from Delaunay dual graph
{break}- Polygon clipping operations (Sutherland-Hodgman algorithm)
{break}- Iterative weighted centroidal Voronoi tessellations (WCVT)
{break}- Recursive polygon subdivision

{pstd}
These operations are not available in native Stata and would require either:
{break}1. Mata implementation of computational geometry algorithms
{break}2. Integration with external libraries (C, Python, etc.)
{break}3. Pre-computation in another language and import to Stata


{title:Dependencies}

{pstd}
The command requires the following packages:

{phang}{stata ssc install carryforward} - Data manipulation{p_end}
{phang}{stata ssc install graphfunctions} - Label utilities{p_end}
{phang}{stata ssc install palettes} - Color palettes{p_end}
{phang}{stata ssc install colrspace} - Color space conversions{p_end}

{pstd}
For Voronoi computation (should be in ./voronoi/ folder):

{phang}{bf:delaunay.ado} - Delaunay triangulation and Voronoi tessellation{p_end}
{phang}{bf:voronoi.ado} - Voronoi diagram utilities{p_end}
{phang}Available at: {browse "https://github.com/asjadnaqvi/stata-delaunay"}{p_end}


{title:References}

{pstd}
Voronoi treemaps are described in:

{phang}
Balzer, M. and Deussen, O. (2005). "Voronoi Treemaps". 
IEEE Symposium on Information Visualization (InfoVis 2005).

{phang}
Nocaj, A. and Brandes, U. (2012). "Computing Voronoi Treemaps: Faster, Simpler, and Resolution-independent".
Computer Graphics Forum, 31(3): 855-864.


{title:Author}

{pstd}
Asjad Naqvi (asjadnaqvi@gmail.com)

{pstd}
If you find this useful, please cite:

{phang}
Naqvi, A. (2026). "Stata package for treemap visualizations". 
GitHub repository: {browse "https://github.com/asjadnaqvi/stata-treemap"}


{title:Also see}

{psee}
{help treemap} (standard rectangular treemap)

