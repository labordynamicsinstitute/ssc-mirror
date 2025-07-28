*! 1.0.0 Ariel Linden 21Jul2025 

program distprobmat, rclass
		version 11.0
			
		syntax anything , DISTance(string) [ EPSilon(real 0.00001) ORDer(integer 2) FORmat(string) ]

			local matcnt : word count `anything'
			if (`matcnt' > 2) {
				di as err "only two matrices may be specified"
				exit = 103
			}	
			if (`matcnt' < 2) {
				di as err "two matrices must be specified"
				exit = 102
			}	

			gettoken P 0 : 0
			confirm matrix  `P'                   
			gettoken Q 0 : 0, parse(" ,") 
			confirm matrix  `Q'
			
			// check that the two matrices have the same dimensions 
			if rowsof("`P'") != rowsof("`Q'") | colsof("`P'") != colsof("`Q'") {
				di as err "the two matrices must have the same {it:r X c} dimensions"
				exit 198        
			}
			
			local mats P Q
			foreach x of local mats {
				// get row count
				local rows = rowsof(`x')

				// Loop through each row to check if the sum equals 1
				forval i = 1/`rows' {
					* Calculate the row sum
					scalar row_sum = 0
					forval j = 1/`rows' {
						scalar row_sum = row_sum + `x'[`i', `j']
					}
					* Check if the row sum is not equal to 1
					if abs(row_sum - 1) > 1e-6 {
						di as err "row `i' of matrix `x' does not sum to 1. Sum = " row_sum
						exit 198
					}
				}
			} // end foreach
			
			local distname ///
				euclidean manhattan minkowski chebyshev ///
				sorensen gower soergel kulczynski_d canberra lorentzian ///
				intersection non_intersection wave_hedges czekanowski motyka ///
				kulczynski_s ruzicka tanimoto inner_product harmonic_mean ///
				cosine kumar_hassebrook jaccard dice  ///
				fidelity bhattacharyya hellinger matusita squared_chord ///
				squared_euclidean pearson_chi2 neyman_chi2 squared_chi2 ///
				prob_symm_chi2 divergence clark add_symm_chi2 ///
				kullback_leibler jensen_shannon jeffreys k_diverge ///
				topsoe jensen_diff taneja kumar_johnson avg
			
			if !`: list distance in distname' {
				di as err "{bf:`distance'} is not a valid distance measure"
				exit 198
			}	
			
			// choose distance measure
			if "`distance'" == "kullback_leibler" {
				local measure Kulback-Leibler Divergence
				mata: kullback_leibler("`P'", "`Q'", `epsilon')
			}
			
			if "`distance'" == "jensen_shannon" {
				local measure Jensen-Shannon Distance
				mata: jensen_shannon("`P'", "`Q'", `epsilon')
			}
			
			if "`distance'" == "jeffreys" {			
				local measure Jeffreys Distance			
				mata: jeffreys_dist("`P'", "`Q'", `epsilon')
			}
			
			if "`distance'" == "k_diverge" {
				local measure K-Divergence
				mata: k_diverge("`P'", "`Q'", `epsilon')
			}	
			
			if "`distance'" == "topsoe" {
				local measure Topsoe Distance
				mata: topsoe("`P'", "`Q'", `epsilon')
			}		
			
			if "`distance'" == "jensen_diff" {
				local measure Jensen Difference
				mata: jensen_diff("`P'", "`Q'", `epsilon')
			}	
			
			if "`distance'" == "squared_euclidean" {
				local measure Squared-Euclidean Distance
				mata: squared_euclidean("`P'", "`Q'", `epsilon')
			}
			
			if "`distance'" == "pearson_chi2" {
				local measure Pearson chi2 Distance
				mata: pearson_chi2("`P'", "`Q'", `epsilon')
			}			
			
			if "`distance'" == "neyman_chi2" {
				local measure Neyman chi2 Distance
				mata: neyman_chi2("`P'", "`Q'", `epsilon')
			}			
			
			if "`distance'" == "squared_chi2" {
				local measure Squared chi2 Distance
				mata: squared_chi2("`P'", "`Q'", `epsilon')
			}
			
			if "`distance'" == "prob_symm_chi2" {
				local measure Probabilistic Symmetric chi2 Distance
				mata: prob_symm_chi2("`P'", "`Q'", `epsilon')
			}	
			
			if "`distance'" == "divergence" {
				local measure Divergence Distance
				mata: divergence("`P'", "`Q'", `epsilon')
			}		
	
			if "`distance'" == "clark" {
				local measure Clark Distance
				mata: clark("`P'", "`Q'", `epsilon')
			}			

			if "`distance'" == "add_symm_chi2" {
				local measure Additive Symmetric chi2 Distance
				mata: add_symm_chi2("`P'", "`Q'", `epsilon')
			}			

			if "`distance'" == "fidelity" {
				local measure Fidelity Distance
				mata: fidelity("`P'", "`Q'", `epsilon')
			}	
		
			if "`distance'" == "bhattacharyya" {
				local measure Bhattacharyya Distance
				mata: bhattacharyya("`P'", "`Q'", `epsilon')
			}	

			if "`distance'" == "hellinger" {
				local measure Hellinger Distance
				mata: hellinger("`P'", "`Q'", `epsilon')
			}				
			
			if "`distance'" == "matusita" {
				local measure Matusita Distance
				mata: matusita("`P'", "`Q'", `epsilon')
			}						

			if "`distance'" == "squared_chord" {
				local measure Squared-chord Distance
				mata: squared_chord("`P'", "`Q'", `epsilon')
			}						
	
			if "`distance'" == "inner_product" {
				local measure Inner-Product Distance
				mata: inner_product("`P'", "`Q'", `epsilon')
			}			
	
			if "`distance'" == "harmonic_mean" {
				local measure Harmonic-mean Distance
				mata: harmonic_mean("`P'", "`Q'", `epsilon')
			}			
	
			if "`distance'" == "cosine" {
				local measure Cosine Distance
				mata: cosine("`P'", "`Q'", `epsilon')
			}		

			if "`distance'" == "kumar_hassebrook" {
				local measure Kumar-Hassebrook Distance
				mata: kumar_hassebrook("`P'", "`Q'", `epsilon')
			}			

			if "`distance'" == "jaccard" {
				local measure Jaccard Distance
				mata: jaccard("`P'", "`Q'", `epsilon')
			}	
	
			if "`distance'" == "dice" {
				local measure Dice Distance
				mata: dice("`P'", "`Q'", `epsilon')
			}		
	
			if "`distance'" == "euclidean" {
				local measure Euclidean L2 Distance
				mata: euclidean("`P'", "`Q'", `epsilon')
			}			
	
			if "`distance'" == "manhattan" {
				local measure Manhattan (L1) Distance
				mata: manhattan("`P'", "`Q'", `epsilon')
			}			
	
			if "`distance'" == "minkowski" {
				local measure Minkowski Distance of order (`order')
				mata: minkowski("`P'", "`Q'", `order', `epsilon')
			}				

			if "`distance'" == "chebyshev" {
				local measure Chebyshev Distance
				mata: chebyshev("`P'", "`Q'", `epsilon')
			}			
	
			if "`distance'" == "sorensen" {
				local measure Sørensen Distance
				mata: sorensen("`P'", "`Q'", `epsilon')
			}			

			if "`distance'" == "gower" {
				local measure Gower Distance
				mata: gower("`P'", "`Q'", `epsilon')
			}				
	
			if "`distance'" == "soergel" {
				local measure Soergel Distance
				mata: soergel("`P'", "`Q'", `epsilon')
			}		
	
			if "`distance'" == "kulczynski_d" {
				local measure Kulczynski Distance
				mata: kulczynski_d("`P'", "`Q'", `epsilon')
			}
			
			if "`distance'" == "kulczynski_s" {
				local measure Kulczynski Similarity Measure
				mata: kulczynski_s("`P'", "`Q'", `epsilon')
			}
	
			if "`distance'" == "canberra" {
				local measure Canberra Distance
				mata: canberra("`P'", "`Q'", `epsilon')
			}
	
			if "`distance'" == "lorentzian" {
				local measure Lorentzian Distance
				mata: lorentzian("`P'", "`Q'", `epsilon')
			}
	
			if "`distance'" == "intersection" {
				local measure Intersection Distance
				mata: intersection("`P'", "`Q'", `epsilon')
			}	
			
			if "`distance'" == "non_intersection" {
				local measure Non-intersection Distance
				mata: non_intersection("`P'", "`Q'", `epsilon')
			}	
	
			if "`distance'" == "wave_hedges" {
				local measure Wave-Hedges Distance
				mata: wave_hedges("`P'", "`Q'", `epsilon')
			}	

			if "`distance'" == "czekanowski" {
				local measure Czekanowski Distance
				mata: czekanowski("`P'", "`Q'", `epsilon')
			}		
	
			if "`distance'" == "motyka" {
				local measure Motyka Distance
				mata: motyka("`P'", "`Q'", `epsilon')
			}
			
			if "`distance'" == "ruzicka" {
				local measure Ruzicka Distance
				mata: ruzicka("`P'", "`Q'", `epsilon')
			}	
	
			if "`distance'" == "tanimoto" {
				local measure Tanimoto Distance
				mata: tanimoto("`P'", "`Q'", `epsilon')
			}	
	
			if "`distance'" == "taneja" {
				local measure Taneja Distance
				mata: taneja("`P'", "`Q'", `epsilon')
			}		
	
			if "`distance'" == "kumar_johnson" {
				local measure Kumar-Johnson Distance
				mata: kumar_johnson("`P'", "`Q'", `epsilon')
			}			
	
			if "`distance'" == "avg" {
				local measure Average(L1 ,L∞) Distance
				mata: avg("`P'", "`Q'", `epsilon')
			}			

			if "`format'" != "" { 
				confirm numeric format `format' 
			}
			else local format %9.6f 
			
			matrix colnames distance = "distance"
			
			local title title({bf:`measure'} between rows of matrix {bf:`P'} and matrix {bf:`Q'})			
			
			matlist distance,  border(top bottom) lines(oneline) tindent(1) aligncolnames(ralign) twidth(8) format(`format') `title'
			
			// save matrix
			return matrix distance = distance			

			
end			

******************************
// Kulback-Leibler Divergence
*****************************
version 11.0
mata:
mata clear
void function kullback_leibler(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q      
		
		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)

		for (i = 1; i <= rows(P); i++) {
			p = P[i,.]
			q = Q[i,.]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = sum(p :* ln(p :/ q))
		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}	
end

***************************
// Jensen-Shannon distance
***************************
version 11.0
mata:
mata clear
void function jensen_shannon(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  
		
		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)		
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,.]
			q = Q[i,.]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q			

			distance[i] = 0.5 * (sum(p :* ln(2 :* p :/ (p + q))) + sum(q :* ln(2 :* q :/ (p + q))))		
		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}	
end

*********************
// Jeffreys distance 
*********************
version 11.0
mata:
mata clear
void function jeffreys_dist(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)		

		for (i = 1; i <= rows(P); i++) {

			p = P[i,] 
			q = Q[i,]
		
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = sum((p :- q) :* ln(p :/ q))

		}
		
		distance
		// save as Stata matrix
		st_matrix("distance", distance)	
	}
	
end	

****************
// K divergence 
****************
version 11.0
mata:
mata clear
void function k_diverge(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)		
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q			
			
			distance[i] = sum(p :* ln(2 :* p :/ (p + q)))			
		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

*********************
// Topsøe distance 
*********************
version 11.0
mata:
mata clear
void function topsoe(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)		

		for (i = 1; i <= rows(P); i++) {

			p = P[i,] 
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = sum(p :* ln(2 :* p :/ (p + q)) + q :* ln(2 :* q :/ (p + q)))			

		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	


*********************
// Jensen difference 
*********************
version 11.0
mata:
mata clear
void function jensen_diff(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)		

		for (i = 1; i <= rows(P); i++) {

			p = P[i,] 
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = sum(0.5 :* (p :* ln(p) + q :* ln(q)) :- (0.5 :* (p + q) :* ln(0.5 :* (p + q))))
	
		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

******************************
// Squared Euclidean Distance
******************************
version 11.0
mata:
mata clear
void function squared_euclidean(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q			
			
			distance[i] = sum((p :- q):^2)
		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

******************************
// Pearson's Chi2 Distance
******************************
version 11.0
mata:
mata clear
void function pearson_chi2(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]

			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q	

			distance[i] = sum(((p :- q):^2) :/ q)
		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

******************************
// Neyman's Chi2 Distance
******************************
version 11.0
mata:
mata clear
void function neyman_chi2(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	

		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]

			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q	

			distance[i] = sum(((p :- q):^2) :/ p)
		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

******************************
// Squared Chi2 Distance
******************************
version 11.0
mata:
mata clear
void function squared_chi2(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		

		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]

			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q	

			distance[i] = sum(((p :- q):^2) :/ (p + q))
		
		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

**************************************
// Probabilistic Symmetric χ2 Distance
**************************************
version 11.0
mata:
mata clear
void function prob_symm_chi2(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]

			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q	

			distance[i] = 2 * sum(((p :- q):^2) :/ (p + q))
		
		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	


**************************************
// Divergence Distance
**************************************
version 11.0
mata:
mata clear
void function divergence(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q					

			distance[i] = 2 * sum((p :- q):^2 :/ (p + q):^2)
		
		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	


**************************************
// Clark Distance
**************************************
version 11.0
mata:
mata clear
void function clark(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q			
			
			distance[i] = sqrt(sum(((abs(p :- q)) :/ (p + q)) :^ 2))	
		
		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	


**************************************
// Additive Symmetric chi2 Distance
**************************************
version 11.0
mata:
mata clear
void function add_symm_chi2(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]

			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = sum(((p :- q):^2 :* (p + q)) :/ (p :* q))
		
		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	


**************************************
// Fidelity Distance
**************************************
version 11.0
mata:
mata clear
void function fidelity(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]

			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = sum(sqrt(p :* q))
		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	


**************************************
// Bhattacharyya Distance
**************************************
version 11.0
mata:
mata clear
void function bhattacharyya(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]

			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = -ln(sum(sqrt(p :* q)))			
		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	


**********************
// Hellinger Distance
**********************
version 11.0
mata:
mata clear
void function hellinger(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]

			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = 2 * sqrt(1-sum(sqrt(p :* q)))
		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

**********************
// Matusita Distance
**********************
version 11.0
mata:
mata clear
void function matusita(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]

			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = sqrt(sum((sqrt(p) :- sqrt(q)) :^ 2))
		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

**************************
// Squared chord Distance
*************************
version 11.0
mata:
mata clear
void function squared_chord(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]

			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = sum( (sqrt(p) :- sqrt(q)) :^ 2 )
		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

**************************
// Inner product Distance
**************************
version 11.0
mata:
mata clear
void function inner_product(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]

			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = sum(p :* q)
		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

**************************
// Harmonic mean Distance
**************************
version 11.0
mata:
mata clear
void function harmonic_mean(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]

			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = 2 * sum((p :* q) :/ (p + q))
		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

**************************
// Cosine Distance
**************************
version 11.0
mata:
mata clear
void function cosine(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]

			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = sum(p :* q) / (sqrt(sum(p:^2)) * sqrt(sum(q:^2)))
			
		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	


****************************
// Kumar Hassebrook Distance
****************************
version 11.0
mata:
mata clear
void function kumar_hassebrook(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)
		
		epsilon = epsilon
		
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = sum(p :* q) / (sum(p:^2) + sum(q:^2) - sum(p :* q))			
		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

****************************
// Jaccard Distance
****************************
version 11.0
mata:
mata clear
void function jaccard(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon		
			
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = 1 - sum(p :* q) / (sum(p:^2) + sum(q:^2) - sum(p :* q))			
			
		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end		

****************************
// Dice Distance
****************************
version 11.0
mata:
mata clear
void function dice(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = 1 - (2 * sum(p :* q)) / (sum(p:^2) + sum(q:^2))			

		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end		

****************************
// Euclidean L2 Distance
****************************
version 11.0
mata:
mata clear
void function euclidean(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = sqrt(sum((p :- q) :^ 2))
		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

****************************
// Manhattan (L1) Distance
****************************
version 11.0
mata:
mata clear
void function manhattan(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = sum(abs(p :- q))
		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

****************************
// Minkowski Distance
****************************
version 11.0
mata:
mata clear
void function minkowski(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar order, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
		
		p_order = order
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = (sum((abs(p :- q)) :^ p_order))^(1/p_order)
		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

****************************
// Chebyshev Distance
****************************
version 11.0
mata:
mata clear
void function chebyshev(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q

			distance[i] = max(abs(p :- q))
		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

****************************
// Sørensen Distance
****************************
version 11.0
mata:
mata clear
void function sorensen(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = sum(abs(p :- q)) / sum(p + q)
		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

****************************
// Gower Distance
****************************
version 11.0
mata:
mata clear
void function gower(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = sum(abs(p :- q)) / cols(P)

		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

****************************
// Soergel Distance
****************************
version 11.0
mata:
mata clear
void function soergel(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = sum(abs(p :- q)) / sum((p :>= q) :* p + (p :< q) :* q)

		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

****************************
// Kulczynski Distance
****************************
version 11.0
mata:
mata clear
void function kulczynski_d(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = sum(abs(p :- q)) / sum((p :<= q) :* p + (p :> q) :* q)

		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

********************************
// Kulczynski Similarity Measure
********************************
version 11.0
mata:
mata clear
void function kulczynski_s(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = 1 / (sum(abs(p :- q)) / sum((p :<= q) :* p + (p :> q) :* q))

		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	


****************************
// Canberra Distance
****************************
version 11.0
mata:
mata clear
void function canberra(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = sum(abs(p :- q) :/ (p + q))

		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	


****************************
// Lorentzian Distance
****************************
version 11.0
mata:
mata clear
void function lorentzian(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = sum(ln(1 :+ abs(p :- q)))

		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	


****************************
// Intersection Distance
****************************
version 11.0
mata:
mata clear
void function intersection(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = sum((p :<= q) :* p + (p :> q) :* q)

		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

****************************
// Non-intersection Distance
****************************
version 11.0
mata:
mata clear
void function non_intersection(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = 1 - (sum((p :<= q) :* p + (p :> q) :* q))

		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	
****************************
// Wave Hedges Distance
****************************
version 11.0
mata:
mata clear
void function wave_hedges(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = sum(abs(p :- q) :/ ((p :>= q) :* p + (p :< q) :* q))

		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	


****************************
// Czekanowski Distance
****************************
version 11.0
mata:
mata clear
void function czekanowski(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = sum(abs(p :- q)) / sum(p + q)

		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

****************************
// Motyka Distance
****************************
version 11.0
mata:
mata clear
void function motyka(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = 1 - (sum((p :<= q) :* p + (p :> q) :* q) / sum(p + q))

		}
		
		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

****************************
// Ruzicka Distance
****************************
version 11.0
mata:
mata clear
void function ruzicka(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = sum((p :<= q) :* p + (p :> q) :* q) / sum((p :>= q) :* p + (p :< q) :* q)

		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

****************************
// Tanimoto Distance
****************************
version 11.0
mata:
mata clear
void function tanimoto(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = sum(((p :>= q) :* p + (p :< q) :* q) :- ((p :<= q) :* p + (p :> q) :* q)) / sum((p :>= q) :* p + (p :< q) :* q)

		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

****************************
// Taneja Distance
****************************
version 11.0
mata:
mata clear
void function taneja(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = sum(((p + q) :/ 2) :* ln((p + q) :/ (2 :* sqrt(p :* q))))

		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

****************************
// Kumar-Johnson Distance
****************************
version 11.0
mata:
mata clear
void function kumar_johnson(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = sum(((p:^2 :- q:^2):^2) :/ (2 :* (p :* q):^1.5))

		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	

****************************
// Avg(L1 ,L∞) Distance
****************************
version 11.0
mata:
mata clear
void function avg(string scalar stata_matrixnameP, string scalar stata_matrixnameQ, real scalar epsilon)

	{

		real matrix P
  		real matrix Q  

		// Convert matrices to Mata		
		P = st_matrix(stata_matrixnameP)
		Q = st_matrix(stata_matrixnameQ)	
		
		epsilon = epsilon
	
		// Initialize the matrix to store values
		distance = J(rows(P), 1, .)	
		
		for (i = 1; i <= rows(P); i++) {
			p = P[i,]
			q = Q[i,]
			
			// Replace zeros with epsilon
			p = (p :== 0) :* epsilon + (p :!= 0) :* p
			q = (q :== 0) :* epsilon + (q :!= 0) :* q
			
			distance[i] = (sum(abs(p :- q)) + max(abs(p :- q))) / 2

		}

		// save as Stata matrix
		st_matrix("distance", distance)	
		
	}
	
end	