capture program drop nmf
*! version 1.00 16 Sep 2022
program define nmf, rclass
    version 17
 
    syntax varlist(numeric), k(integer) [ epoch(integer 200) initial(string) loss(string) stop(numlist max = 1) nograph ]
    
    // Written by Dr Jonathan Batty (J.Batty@leeds.ac.uk),
    // Leeds Institute for Data Analytics (LIDA),
    // University of Leeds.
    //
    // Aim:
    // The aim of NMF is to find W (u x k) and H (k x v) such that A ~ WH, where all 3 matrices contain only non-negative values
    // A good appoximation may be achieved with k << rank(A) NMF is a NP-hard problem; the best that can be done is to find local
    // minima from a set of initialisations.
    //
    // <Inputs>:
    //      varlist: variables that contain columns of data to factorise. All rows of these columns will enter into the factorisation.
    //      
    //      k(): the rank of the factorisation, whereby k must be less than the rank of the number of columns input in varlist.
    //
    //      epoch(): the number of iterations of NMF to repeat to achieve convergence. Dafault = 200.
    //
    //      initial(): initialisation options, specified using the init() parameter, include:
    //          randomu [*default] - random, uniform initialisation of matrix in range [1, 2] 
    //          randomn - random, normally-distributed initialisation of matrix with mean 2 and standard deviation 1
    //          nndsvd - Nonnegative Double Singular Value Decomposition [Boutsidis2007] - suited to sparse factors
    //          nndsvda - NNSVD with zero elements replaced with the input matrix average (not recommended for sparse data)
    //          nndsvdar - NNSVD with zero elements replaced with a random value (nor recommended for sparse data)
    //      Using the random option, multiple runs will be required to identify the factorization that achieves the lowest approximation error. Other options are deterministic and only need to be ran once.
    //      Note: The multiplicative update ('mu') solver cannot update zeros present in the initialization, and so leads to poorer results when used jointly with nndsvd. Co-ordinate descent mitigates this
    //
    //      loss(): divergence function options, specified using the loss() parameter, include:
    //          eu [*default] - Frobenius (Euclidean) norm (equivalent to MSE for matrices)
    //          is - Itakura-Saito divergence 
    //          kl - Generalized Kullback-Leibler divergence
    //
    //      stop(): early stopping options, specified using the stop() parameter, include:
    //          0 - early stopping off; NMF continues for numer of iterations specified in epoch
    //          float value, e.g. 1.0e-4 [*default] - if ((previous error - current error) / error at initiation) < stop tolerance) then further iterations are not performed
    //
    //      nograph suppresses production of the graph of loss divergence at each iteration
    //
    // <Outputs>
    //      W - factor (basis) matrix W
    //      H - factor (encoding or coefficient) matrix H 
    //

    // If a value for initialisation method is not passed, default option is is random initialisation 
    if "`initial'" == "" local initial "randomu"

    // If a value for updating method is not passed, default option is is multiplicative updating (mu) 
    if "`method'" == "" local method "mu"

    // If a value specifying the form of loss divergence normalisation is not passed, default option is is Frobenius normalisation (2) 
    if "`loss'" == "" local loss = "eu"

    // If a value specifying the stopping condition is not passed, default option is is 1.0e-4 (i.e. 0.01%)
    if "`stop'" == "" local stop = 1.0e-4

    // Run NMF
    mata: nmf("`varlist'", `k', `epoch', "`initial'", "`method'", "`loss'", `stop')

    // Store results of NMF using stata matrices
    matrix W = r(W)
    matrix H = r(H)
    matrix error = r(norms)

    // Creates frames containing output matrices: W, H and norms
    display as text "Creating frames W, H and error to hold results."

    // Create empty new frames to hold matrices
    foreach outputFrame in W H error {

        // If a frame with the given name exists - drops and recreates it
        capture confirm frame `outputFrame'
        if !_rc {
            frame drop `outputFrame'
            frame create `outputFrame'
        }
        else {
            frame create `outputFrame'
        }

        // Populate each frame with the returned matrix object
        frame `outputFrame' {
            quietly svmat `outputFrame'
        }
    }

    // Add iteration identifier to norms frame
    frame error {
        rename error1 epoch
        rename error2 total_loss
        rename error3 average_loss
        local ymax = average_loss[2]
    }

    // Plots the normalisation values calculated after each iteration
    if "`graph'" != "nograph" {

        if "`loss'" == "is" local lossString "Itakura-Saito Divergence" 
        if "`loss'" == "kl" local lossString "Generalized Kullback-Leibler Divergence"
        if "`loss'" == "eu" local lossString "Frobenius (Euclidean) Error "

        frame error: graph twoway line average_loss epoch if epoch > 0,                                                                                      ///
                                                      title("Loss Function")                                                                                 ///
                                                      xtitle("Epoch") xlabel(, labsize(*0.75) grid glcolor(gs15))                                            ///
                                                      ytitle("Mean `lossString'") yscale(range(0 .)) ylabel(#5, ang(h) labsize(*0.75) grid glcolor(gs15))    ///
                                                      graphregion(color(white))
    }

    display as text "Returning final matrices in r(W), r(H) and r(error)"

    // Return final results
    return matrix W W
    return matrix H H
    return matrix error error

end

version 17
mata:

void nmf(string scalar varlist, 
         real scalar k, 
         real scalar epoch, 
         string scalar initial,
         string scalar method,
         string scalar loss,
         real scalar stop)
{
    // Declare all variable types
    real matrix A, W, H
    real colvector norm, norms
    real scalar e, i, normResult, stopMeasure, hasMissing
    string scalar lossMethodString

    // Construct mata matrix from input varlist
    A = st_data(., varlist)
    
    // Perform error checking:
    // 1. Ensure that input matrix is non-negative (i.e. no negative values)
    if (min(A) < 0) {
        _error("The input matrix must not contain negative values.")
    }

    // 2. Ensure that there are no missing values in the input matrix
    if (hasmissing(A) == 1) {
        //_error("The input matrix must not contain missing values.")
        hasMissing = 1
    }
    else {
        hasMissing = 0
    }

    // 3. Ensure that specified rank, k,  is valid (i.e. 2 < k < rank(A))
    if (k < 2 | k >= cols(A) | k >= rows(A)) {
        _error("The rank of the output matrix must be at least 2, but less than the number of rows and columns of the input matrix, A.")
    }

    // Warn about use of nndsvd with mu
    if (initial == "nndsvd" & method == "mu") {
        printf("Warning: the matrices H and W initialized by NNDSVD may contain zeroes.\n") 
        printf("These will not be updated duing multiplicative updating.\n")
        printf("For better results, select a different initializstion or update method..\n")
    }

    // Initialisation of matrix
    if (initial == "randomu" | initial == "randomn") {
        randomInit(A, k, W, H, initial)
    }
    else if (initial == "nndsvd" | initial == "nndsvda" | initial == "nndsvdar") {
        nnsvdInit(A, k, W, H, initial)
    }
    else {
        printf("Error - an invalid initialisation type has been set.")
    }
  
    // Create a column matrix (rows = epochs) to store normalisation results from each iteration
    normResult = lossDivergence(A, W, H, loss, hasMissing)
    norms = J(1, 3, .)
    norms[1, 1] = 0
    norms[1, 2] = normResult
    norms[1, 3] = normResult / (length(A) - missing(A))

    // Updating matrices the given number of iterations
    displayas("text")
    printf("\nFactorizing matix...{space 29} Maximum number of epochs set at: %9.0f \n\n", epoch)

    printf("{hline 10}{c TT}{hline 26}{c TT}{hline 17}{c TT}{hline 16}{c TT}{hline 19}\n")
    printf("{txt}{space 4}Epoch {c |}{space 12}Loss Function {c |}{space 5}Total Error {c |}{space 5}Mean Error {c |}{space 5}Relative Error\n")
    printf("{hline 10}{c +}{hline 26}{c +}{hline 17}{c +}{hline 16}{c +}{hline 19}\n")
    //printf("{txt}%12s {c |} {res}%10.0g %10.0g\n", varname[i], coef[i], se[i])


    // Update W and H by chosen update method
    for (i = 1; i <= epoch; i++) {
        if (method == "mu") {

            if (loss == "eu") {
                if (hasMissing == 1) {
                    mu_eu_missing(A, W, H)
                }
                else {
                    mu_eu(A, W, H)
                }
            }
            else if (loss == "kl") {
                if (hasMissing == 1) {
                    mu_kl_missing(A, W, H)
                }
                else {
                    mu_kl(A, W, H)
                }
            }
            else if (loss == "is") {
                if (hasMissing == 1) {
                    _error("The chosen loss function is not supported when values are missing.")
                }
                else {
                    mu_is(A, W, H)
                }              
            }
        }
        else {
            _error("An invalid method has been chosen.")
        }
        
        // Calculate divergence (error) metric
        // This could be done every 5, 10 etc iterations ('trace' parameter)?
        normResult = lossDivergence(A, W, H, loss, hasMissing)

        // Update norms matrix with result of current iteration
        norm = J(1, 3, .)
        norm[1, 1] = i
        norm[1, 2] = normResult
        norm[1, 3] = normResult / (length(A) - missing(A))
        norms = norms \ norm
        
        // Print result of iteration to the screen
        if (loss == "is") lossMethodString = "Itakura-Saito"
        if (loss == "kl") lossMethodString = "Kullback-Leibler"
        if (loss == "eu") lossMethodString = "Frobenius (Euclidean)"

        if (mod(i, 10) == 0 | i == epoch) {
            // Calculate relative error
            relError = (norms[i - 1, 2] - norms[i, 2]) / norms[2, 2]

            // Print results to the screen
            printf("%9.0f {c |} %24s {c |}%16.2f {c |}%15.4f {c |}%19.6f\n", i, lossMethodString, normResult, norm[1, 3], relError)
        }
        
        // Implement stopping rule if one is set (i.e. stop > 0)
        // Checks every 10 iterations whether MU should contine or if it should stop.
        if (stop != 0 & mod(i, 10) == 0){
            // Calculate stopping measure
            // if ((previous error - current error) / error at initiation) < stop tolerance) then stop
            stopMeasure = (norms[i - 1, 2] - norms[i, 2]) / norms[2, 2]
            if (relError < stop)
            {
                printf("{hline 10}{c BT}{hline 26}{c BT}{hline 17}{c BT}{hline 16}{c BT}{hline 19}\n")
                printf("{result}\nStopping at epoch " + strofreal(i) + "...\n")
                printf("{result}Criteria for early stoping have been met. Error reduced to: " + strofreal(stopMeasure) + ", which < the stopping threshold (" + strofreal(stop) +").\n\n")
                break
            }
        }    
        
        // If reach end of set iterations and model has not converged: warn user
        if (i == epoch) {
            printf("{hline 10}{c BT}{hline 26}{c BT}{hline 17}{c BT}{hline 16}{c BT}{hline 19}\n")
            printf("{error}\nMatrix decomposition did not converge within the set number of epochs.\n") 
            printf("Please consider increasing the number of epochs used during decomposition.\n")
        }
    }

    printf("{text}\n")


    // Return results object to stata
    st_matrix("r(W)", W)
    st_matrix("r(H)", H)
    st_matrix("r(norms)", norms)
}


void randomInit(real matrix A, 
                real scalar k, 
                real matrix W, 
                real matrix H,
                string scalar initial)
{
    if (initial == "randomu") {
        // Generate random values for W in the range [min(A), max(A)]
        W = runiform(rows(A), k, min(A), max(A))

        // Generate random values for H in the range [min(A), max(A)]
        H = runiform(k, cols(A), min(A), max(A))

    } 
    else if (initial == "randomn") {
        // Generate random values for W in the range [1 - 2]
        W = rnormal(rows(A), k, 2, 1)

        // Generate random values for H in the range [1 - 2]
        H = rnormal(k, cols(A), 2, 1)
    }
}

void nnsvdInit(real matrix A, 
               real scalar k, 
               real matrix W, 
               real matrix H, 
               string scalar initial)
{
    // Declare all variable types used in this function
    real matrix U, S, V
    real colvector ui, vi, ui_pos, ui_neg, vi_pos, vi_neg, _ui, _vi
    real scalar i, ui_pos_norm, ui_neg_norm, vi_pos_norm, vi_neg_norm, norm_pos, norm_neg, sigma, averageOfInputMatrix

    // Perform SVD and transpose resulting S matrix
    svd(A, U, S, V)
    S = S'

    // Set up empty matrices of the correct size for W and H
    W = J(rows(A), k, 0)
    H = J(k, cols(A), 0)
    
    // Get first column of W values based on SVD results
    W[., 1] = sqrt(S[1, 1]) :* abs(U[., 1])

    // Get first row of H values based on SVD results
    H[1, .] = sqrt(S[1, 1]) :* abs(V[., 1]')

    for (i = 2; i <= k; i++) {

        ui = U[., i]
        vi = V[., i]

        // Divide into positive-only and negative-only matrices
        ui_pos = (ui :>= 0) :* ui
        ui_neg = (ui :< 0) :* -ui
        vi_pos = (vi :>= 0) :* vi
        vi_neg = (vi :< 0) :* -vi

        // Calculate 2-norm of each of the positive and negative columns
        ui_pos_norm = norm(ui_pos, 2)
        ui_neg_norm = norm(ui_neg, 2)
        vi_pos_norm = norm(vi_pos, 2)
        vi_neg_norm = norm(vi_neg, 2)

        // Multiply the positive and negative norms to get overall values
        norm_pos = ui_pos_norm * vi_pos_norm
        norm_neg = ui_neg_norm * vi_neg_norm

        // Check which is larger, norm_pos or norm_neg
        if (norm_pos >= norm_neg) {
            _ui = ui_pos :/ ui_pos_norm
            _vi = vi_pos :/ vi_pos_norm
            sigma = norm_pos
        }
        else {
            _ui = ui_neg :/ ui_neg_norm; 
            _vi = vi_neg :/ vi_neg_norm;
            sigma = norm_neg
        }
        
        // Update rows of W and H
        W[., i] = sqrt(S[1, i] * sigma) * _ui
        H[i, .] = sqrt(S[1, i] * sigma) * _vi'
    }

    // Replaces zero values in initialised matrices with average value of input matrix, A
    if (initial == "nndsvda") {
        
        // Calculate properties of input matrix
        averageOfInputMatrix = matrixMean(A)

        // Update zeros with average values of input matrix
        W = editvalue(W, 0, averageOfInputMatrix)
        H = editvalue(H, 0, averageOfInputMatrix)

    }
    // Replace zeros in initialised matrices with random value in the space [0 : average/100]
    else if (initial == "nndsvdar") {

        // Calculate properties of input matrix
        averageOfInputMatrix = matrixMean(A)

        // Update zeroes in W with averge vales, scaled
        W = editvalue(W, 0, averageOfInputMatrix * runiform(1, 1) / 100)
        H = editvalue(H, 0, averageOfInputMatrix * runiform(1, 1) / 100)
    }
    // Replace zeros in initialised matrices with the smallest possible positive value
    else {
        W = editvalue(W, 0, epsilon(1))
        H = editvalue(H, 0, epsilon(1))
        
    }
}

scalar lossDivergence(real matrix A,
                      real matrix W,
                      real matrix H,
                      string scalar loss,
                      real scalar hasMissing)
{
    // Declare all variable types
    real matrix div, M
    real scalar divergence

    if (hasMissing == 0){

        // Logic flow based on parameter passed to nmf()
        if (loss == "is") {
            // is = Itakura-Saito divergence (only if no zero/missing values)
            div = A :/ (W*H)
            divergence = sum(div) - (rows(A) * cols(A)) - sum(log(div))
        }
        else if (loss == "kl") {
            // kl = Generalized Kullback-Leibler divergence
            divergence = sum(A :* log(A :/ ((W*H)) :+ epsilon(1)) :- A :+ (W*H))
        }
        else if (loss == "eu") {
            // eu = Frobenius (or Euclidean) norm
            divergence = sum((A - W*H) :^ 2)
        }
        else {
            _error("Invalid value of loss function supplied.")
        }
    }

    else if (hasMissing == 1) {
        if (loss == "is") {
            // is = Itakura-Saito divergence (only if no zero/missing values)
            _error("This distance metric is not supported for missing data.")
        }
        else if (loss == "kl") {
            // kl = Generalized Kullback-Leibler divergence
            M = (A :!= .)
            divergence = sum((M :* A) :* log((M :*A) :/ (M :* (W*H)) :+ epsilon(1)) :- (M :* A) :+ (M :* (W*H)))
        }
        else if (loss == "eu") {
            // eu = Frobenius (or Euclidean) norm
            M = (A :!= .)
            divergence = sqrt(sum(( M :* (A - W*H)) :^ 2))
        }
        else {
            _error("This distance metric is not supported for missing data.")
        }

    }

    return(divergence)
}

void mu_eu(real matrix A,
           real matrix W, 
           real matrix H)
{
    // References: 
    // [1]    Lee, D. and Seung, H. Algorithms for Non-negative Matrix Factorization.
    //        Advances in Neural Information Processing Systems 13: Proceedings of the 2000 Conference,
    //        MIT Press. pp. 556–562, 2000.
    // [2]    Lee, D. and Seung, H. Learning the parts of objects by non-negative matrix factorization. 
    //        Nature 401, pp. 788–791 (1999).

    // Update H
    H = H :* ((W' * A) :/ (W' * W * H))

    // Update W
    W = W :* ((A * H') :/ (W * H * H'))
}

void mu_eu_missing(real matrix A,
                   real matrix W, 
                   real matrix H)
{
    real matrix M
    
    M = (A :!= .)
    _editmissing(A, 0)

    // Update H
    H = H :* ((W' * (M :* A)) :/ (W' * (M :* (W * H))))

    // Update W
    W = W :* (((M :* A) * H') :/ ((M :* (W * H)) * H'))
}


void mu_kl(real matrix A,
           real matrix W, 
           real matrix H)
{
    // Update H
    H = H :* ((W' * (A :/ (W*H))) :/ (W' * J(rows(W), cols(H), 1)))
    
    // Update W
    W = W :* (((A :/ (W*H)) * H') :/ (J(rows(W), cols(H) , 1) * H'))
    
}

void mu_kl_missing(real matrix A,
                   real matrix W, 
                   real matrix H)
{
    real matrix M
    
    M = (A :!= .)
    _editmissing(A, 0)

    // Update H
    W = (W :/ (M * H')) :* (((M :* A) :/ (W * H)) * H')

    // Update W
    H = (H :/ (W' * M)) :* (W' * ((M :* A) :/ (W * H)))
}

void mu_is(real matrix A,
           real matrix W, 
           real matrix H)
{
    real matrix WH

    // Update H
    WH = W*H
    H = H :* ((W' * (A :/ ((WH :^ 2) :+ epsilon(1)))) :/ (W' * ((WH :+ epsilon(1)) :^ -1)))
    
    // Update W
    WH = W*H
    W = W :* (((A :/ ((WH :^ 2) :+ epsilon(1))) * H') :/ (((WH :+ epsilon(1)) :^ -1) * H'))
}

real scalar matrixMean(real matrix A)
{
    // Returns mean of matrix (assumes no misisng values)
    return(sum(A) / length(A))
}

end