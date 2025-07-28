{smcl}
{* *! version 1.0.0 21Jul2025}{...}

{title:Title}

{p2colset 5 20 21 2}{...}
{p2col:{hi:distprobmat} {hline 2}} distance/similarity measures between two probability density matrices{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 17 2}
{cmd:distprobmat}
{it:matrix_A}
{it:matrix_B}
{cmd:,}
{opt dist:ance}({help distprobmat##measure:measure})
[ {opt eps:ilon}{opt (#)}
{opt ord:er}{opt (#)}
{opt for:mat}({help format:%fmt}) ]


{pstd}
{it:matrix_A} and {it:matrix_B} are the names of the two matrices containing the probability distributions to be compared. Each row must add up to 1.0 and 
both matrices must have the same number of rows and columns{p_end}


{synoptset 23 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opth dist:ance(distprobmat##measure:measure)}}the distance measure to be computed; {cmd:distance() is required} {p_end}
{synopt :{opt eps:ilon(#)}}replace zeros with a small value to address cases in the distance computation where division by zero occurs; default is {cmd:epsilon(0.0001)}{p_end}
{synopt :{opt ord:er(#)}}specify the order (exponent) for the Minkowski distance; default is {cmd:order(2)} (which is equal to the Euclidean distance){p_end}
{synopt :{opth for:mat(%fmt)}}display format for numeric values in the output table; default is {cmd:format(%6.3g)}{p_end}
{synoptline}
{p 4 6 2}
{p2colreset}{...}				


{marker measure}{...}
{synoptset 23 tabbed}{...}
{synopthdr :measure}
{synoptline}
{syntab:{it:Lp} Minkowski family}
{synopt :{opt euclidean}}Euclidean {it:L2} distance {p_end}
{synopt :{opt manhattan}}Manhattan {it:L1} distance {p_end}
{synopt :{opt minkowski}}Minkowski {it:Lp} distance {p_end}
{synopt :{opt chebyshev}}Chebyshev {it:L∞} distance {p_end}

{syntab:{it:L1} family}
{synopt :{opt sorensen}}Sørensen distance {p_end}
{synopt :{opt gower}}Gower distance {p_end}
{synopt :{opt soergel}}Soergel distance {p_end}
{synopt :{opt kulczynski_d}}Kulczynski distance {p_end}
{synopt :{opt canberra}}Canberra distance {p_end}
{synopt :{opt lorentzian}}Lorentzian distance {p_end}

{syntab: Intersection family}
{synopt :{opt intersection}}Intersection similarity {p_end}
{synopt :{opt non_intersection}}Non-intersection distance {p_end}
{synopt :{opt wave_hedges}}Wave-Hedges distance {p_end}
{synopt :{opt czekanowski}}Czekanowski distance {p_end}
{synopt :{opt motyka}}Motyka distance {p_end}
{synopt :{opt kulczynski_s}}Kulczynski similarity {p_end}
{synopt :{opt ruzicka}}Ruzicka distance {p_end}
{synopt :{opt tanimoto}}Tanimoto distance {p_end}

{syntab: Inner-Product family}
{synopt :{opt inner_product}}Inner-product distance {p_end}
{synopt :{opt harmonic_mean}}Harmonic mean distance {p_end}
{synopt :{opt cosine}}Cosine distance {p_end}
{synopt :{opt kumar_hassebrook}}Kumar-Hassebrook distance {p_end}
{synopt :{opt jaccard}}Jaccard distance {p_end}
{synopt :{opt dice}}Dice distance {p_end}

{syntab: Fidelity family or Squared-chord family}
{synopt :{opt fidelity}}Fidelity distance {p_end}
{synopt :{opt bhattacharyya}}Bhattacharyya distance {p_end}
{synopt :{opt hellinger}}Hellinger distance {p_end}
{synopt :{opt matusita}}Matusita distance {p_end}
{synopt :{opt squared_chord}}Squared-chord distance {p_end}

{syntab: Squared {it:L2} family or {it:χ2} family}
{synopt :{opt squared_euclidean}}Squared Euclidean distance {p_end}
{synopt :{opt pearson_chi2}}Pearson {it:χ2} distance {p_end}
{synopt :{opt neyman_chi2}}Neyman {it:χ2} distance {p_end}
{synopt :{opt squared_chi2}}Squared {it:χ2} distance {p_end}
{synopt :{opt prob_symm_chi2}}Probabilistic Symmetric {it:χ2} distance {p_end}
{synopt :{opt divergence}}Divergence distance {p_end}
{synopt :{opt clark}}Clark distance {p_end}
{synopt :{opt add_symm_chi2}}Additive Symmetric {it:χ2} distance {p_end}

{syntab: Shannon's entropy family}
{synopt :{opt kullback_leibler}}Kullback–Leibler distance {p_end}
{synopt :{opt jeffreys}}Jeffreys distance {p_end}
{synopt :{opt k_diverge}}K-divergence distance {p_end}
{synopt :{opt topsoe}}Topsøe distance {p_end}
{synopt :{opt jensen_shannon}}Jensen-Shannon distance {p_end}
{synopt :{opt jensen_diff}}Jensen difference distance {p_end}

{syntab: Combinations}
{synopt :{opt taneja}}Taneja distance {p_end}
{synopt :{opt kumar_johnson}}Kumar-Johnson distance {p_end}
{synopt :{opt avg}}Avg({it:L1},{it:L∞}) distance {p_end}
{synoptline}
{p2colreset}{...}



{title:Description}

{pstd}
{cmd:distprobmat} computes 46 different distance/similarity measures between probability density functions, as surveyed in Cha (2007). {cmd:distprobmat} requires 
that the probability densities to be compared are stored in two matrices with the same number of rows and columns. Given that the distances are computed for each
row separately, each row in the two matrices must sum to 1.0. {cmd:distprobmat} produces the same results as those of the R package 
{browse "https://cran.r-project.org/web/packages/philentropy/readme/README.html":philentropy}.



{title:Options}

{p 4 8 2}
{opth dist:ance(distprobmat##measure:measure)} is the measure to be used to compute the distance between row {it:i} of matrix 1 to row {it:i} of matrix 2; 
{cmd:distance()} is required.

{p 4 8 2}
{opt eps:ilon(#)} replace zeros with a small value to address cases in the distance computation where division by zero occurs; default is {cmd:epsilon(0.0001)}  

{p 4 8 2}
{opt ord:er(#)} specifies the order (exponent) for the Minkowski distance. Specifying {cmd:order(1)} is equal to the Manhattan (L1) distance, specifying
{cmd:order(2)} is equal to the Euclidean (L2) distance,and specifying higher orders place more emphasis on larger differences. The default is {cmd:order(2)}.

{p 4 8 2}
{opth format(%fmt)} specifies the format for displaying the numeric results in the table. The default is {cmd:format(%6.3g)}.


		
{title:Examples}

{pstd}We generate two matrices with one row and 10 columns: {p_end}

{phang2}{cmd:. matrix A = (0.093, 0.036, 0.065, 0.077, 0.124, 0.144, 0.078, 0.072, 0.137, 0.174)} {p_end}
{phang2}{cmd:. matrix B = (0.146, 0.063, 0.099, 0.112, 0.085, 0.059, 0.092, 0.111, 0.114, 0.119)} {p_end}

{pstd}We specify {cmd:distance(euclidean)} to compute the Euclidean distance between matrix A and matrix B{p_end}

{phang2}{cmd:. distprobmat A B, dist(euclidean)} {p_end}

{pstd}We now generate two matrices with 3 rows and 3 columns: {p_end}

{phang2}{cmd:. matrix P = (0.729, 0.157, 0.114 \ 0.231, 0.596, 0.173 \ 0.222, 0.407, 0.371)} {p_end}
{phang2}{cmd:. matrix Q = (0.625, 0.250, 0.125 \ 0.250, 0.500, 0.250 \ 0.250, 0.375, 0.375)} {p_end}

{pstd}We now compute the Bhattacharyya distance for each row comparison {p_end}

{phang2}{cmd:. distprobmat P Q, dist(bhattacharyya)} {p_end}



{title:Stored results}

{pstd}
{cmd:distprobmat} stores the following in {cmd:r()}:

{synoptset 14 tabbed}{...}
{p2col 5 18 19 2: Matrices}{p_end}
{synopt:{cmd:r(distance)}}the distance(s) between row {it:i} of matrix_A and row {it:i} of matrix_B{p_end}




{marker references}{title:References}

{p 4 8 2}
Sung-Hyuk, Cha (2007). Comprehensive Survey on Distance/Similarity Measures between Probability Density Functions.
{it:International Journal of Mathematical Models and Methods in Applied Sciences} 4: 300-307.



{marker citation}{title:Citation of {cmd:distprobmat}}

{p 4 8 2}{cmd:distprobmat} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2025). DISTPROBMAT: Stata module to compute distance/similarity measures between two probability density matrices {p_end}



{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}   alinden@lindenconsulting.org{p_end}



{title:Also see}

{p 4 8 2} Online: {helpb cluster}, {helpb mds}, {helpb discrim knn}, {helpb matrix dissimilarity}. {p_end}

