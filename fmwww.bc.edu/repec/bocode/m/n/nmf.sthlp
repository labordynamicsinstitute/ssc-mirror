{smcl}
{* *! version 1.0  16sep2022}{...}
{viewerjumpto "Syntax" "nmf##syntax"}{...}
{viewerjumpto "Description" "nmf##description"}{...}
{viewerjumpto "Options" "nmf##options"}{...}
{viewerjumpto "Remarks" "nmf##remarks"}{...}
{viewerjumpto "References" "nmf##references"}{...}
{viewerjumpto "Examples" "nmf##examples"}{...}
{viewerjumpto "Acknowledgements" "nmf##acknowledgements"}{...}
{viewerjumpto "Citation" "nmf##citation"}{...}
{title:Title}

{phang}
{bf:nmf} {hline 2} matrix decomposition using non-negative matrix factorization (NMF).


{marker syntax}{...}
{title:Syntax}

Perform matrix decomposition using NMF:

{p 8 17 2}
{cmdab:nmf}
[{varlist}]
{cmd:,} {bf: k(#)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{p2coldent:* {opt k(#)}}specifes the rank, {bf: k}, of the factorisation.{p_end}
{synopt:{opt epoch(#)}}maximum number of iterations over which to minimise the error function.{p_end}
{synopt:{opt initial(string)}}declares the matrix initialisation method.{p_end}
{synopt:{opt loss(string)}}declares the loss function used to calculate {c |}{c |}A - WH{c |}{c |}.{p_end}
{synopt:{opt stop(#)}}declares the early stopping delta threshold for convergence.{p_end}
{synopt:{opt nograph}}suppress graph of epoch vs. loss function.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {opt k(#)} is required.

{p 4 6 2}
{cmd:by} is not allowed. {cmd:fweight}s are not allowed.


{marker description}{...}
{title:Description}

{pstd}
The aim of {cmd:nmf} is to decompose matrix A into a lower-rank matrix approximation such that 
X ≈ WH, where A, W and H are made up of non-negative, real numbers. Missing values are 
permitted. If X is an n x m matrix, the dimensions of W and H will be n x k and k x m, 
respectively, whereby k represents the rank of the decomposition. In many cases, a good 
approximatation for A may be achieved with k << rank(A). 

{pstd}
NMF is a NP-hard problem. As such, multiplicative updates of matrices W and H are iteratively  
performed in order to minimise the generalized error function, {c |}{c |}A - WH{c |}{c |}. This 
implements the methods first reported by Paatero and Tapper[1] and later popularised by Lee and 
Seung[2, 3].

{pstd}
Running NMF results in the generation of three new frames, {bf:W}, {bf:H} and {bf:error} that 
store the basis and coefficient matrices and a summary of the error over each epoch, respectively.
These can be accessed using:{cmd: frame change W}, {cmd: frame change H} and {cmd: frame change error}.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt k(#)} is required and specifies the rank for the decomposition. The value of k must be greater 
than or equal to 2, and must be less than the minimum of the number of columns and rows of the initial 
matrix to be factorised.

{dlgtab:Options}

{phang}
{opt epoch(#)} sets the maximum number of epochs (iterations) over which the decomposition is optimized. 
If this is not specified, NMF runs for 200 epochs by default. If convergence has not been reached by the
number of epochs specified in epoch() (or by 200 epochs, if no value is specified), an error message will
advise that a greater number of epochs should be used.

{marker initial()}{...}
{phang}
{opt initial(option)}
indicates how matrices {it: W} and {it: H} are initialized.  The available {it:option}s are:

{phang2}
{opt randomu},
the default, specifies that W and H are initialised by sampling values from a {bf:uniform} distribution, in the range [min(A), max(A)].

{phang2}
{opt randomn},
specifies that W and H are initialised by sampling values from a {bf:normal} distribution, in the range [1, 2].

{phang2}
{opt nndsvd},
specifies that W and H are initialised using non-negative double singular value decomposition (NNDSVD)[4]. This is deterministic (non-random) and was designed
to ehance the initialisation stage of NMF. 

{phang2}
{opt nndsvda},
specifies that W and H are initialised using NNDSVD, in which zeroes are filled with the average of A. It is suggested that this may be better when sparsity is not desired.

{phang2}
{opt nndsvdar},
specifies that W and H are initialised using NNDSVD, in which zeroes are filled with small random values.

{marker loss()}{...}
{phang}
{opt loss(option)}
indicates the loss function that will be minimised during the matrix decomposition. This is the error function for {c |}{c |}A - WH{c |}{c |}. 
Options include: eu, is and kl. Note that the Itakura-Saito divergence (is) requires no missing data to be present in A.

{phang2}
{opt eu},
the default, specifies the Frobenius (Euclidean) distance. This may be preferred when matrix A contains continous data.

{phang2}
{opt kl},
specifies specifies the generalized Kullback-Leibler divergence. This may be preferred when matrix A contains binary or count data.

{phang2}
{opt is},
specifies the Itakura-Saito divergence.

{marker stop()}{...}
{phang}
{opt stop(#)}
sets the early stopping threshold for convergence; if {cmd: stop(0)} is set, optimisation will continue for the set number of epochs without early stopping. 
If ((previous error - current error) / error at initiation) < stop tolerance, convergence has occured and nmf terminates. 
The default value is 1.0e-4.

{marker nograph}{...}
{phang}
{opt nograph}
suppresses plotting of a line graph to depict the loss function decreasing with each successive epoch.

{marker remarks}{...}
{title:Remarks}

{pstd}
A number of demonstration .do files are available, complete with sample data. These are metagenes.do, imputation.do, faces.do and trajectories.do and can be found at: https://github.com/jonathanbatty/stata-nmf/tree/main/examples

{marker references}{...}
{title:References}

{pstd}
[1] Paatero, P. and Tapper U (1994). Positive matrix factorization: A non-negative factor model with optimal utilization of error estimates of data values. Environmetrics, 5: pp. 111-126.
{p_end}

{pstd}
[2] Lee, D. and Seung, H (1999). Learning the parts of objects by non-negative matrix factorization. Nature, 401, pp. 788–791.
{p_end}

{pstd}
[3] Lee, D. and Seung, H (2000). Algorithms for Non-negative Matrix Factorization. Advances in Neural Information Processing Systems 13: Proceedings of the 2000 Conference, MIT Press. pp. 556–562.
{p_end}

{pstd}
[4] Boutsidis, C. and Gallopoulos, E (2008). SVD-based initialization: A head start for nonnegative matrix factorization. Pattern Recognition, 41(4): pp. 1350-1362, .

{marker examples}{...}
{title:Examples}

{phang}{cmd:. nmf p*, k(5) epoch(100)}{p_end}

{phang}{cmd:. nmf k*,	k(15) epoch(100) initial(randomu) stop(1.0e-4) loss(kl) nograph	}{p_end}

{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}
This project was funded by the AI for Science and Government Fund, via the Alan Turing Institute Health Programme (TU/ASG/R-SPEH-114). 
Jonathan Batty received funding from the Wellcome Trust 4ward North Clinical Research Training Fellowship (227498/Z/23/Z; R127002).

{marker citation}{...}
{title:Suggested citation}

{pstd}
Batty, J. A. (2024). Stata package ``nmf'': an implementation of non-negative matrix factorisation in Stata (Version 1.0) [Computer software]. https://github.com/jonathanbatty/stata-nmf