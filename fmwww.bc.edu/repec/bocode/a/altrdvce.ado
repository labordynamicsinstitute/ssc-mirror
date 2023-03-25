
capture mata mata drop altrdvce()
version 15.0
mata
real matrix altrdvce(real matrix X, real matrix y, real matrix z, real scalar p, real scalar h, real scalar matches, string vce, string kernel)
{
n = length(X)
p1 = p+1
if (vce=="resid") {
mu0_phat_y = mu0_phat_z = J(n,1, .)
sigma    = J(n,1, .)
	for (k=1; k<=n; k++) {
		cutoff = X[k]
		W = kweight(X,cutoff,h,kernel)
		W_p = select(W, W:> 0)
		X_p = select(X, W:> 0)
		y_p = select(y, W:> 0)
		z_p = select(z, W:> 0)
		XX  = J(length(W_p),p1,.)
		for (j=1; j<=p1; j++) {
			XX[.,j] = (X_p:-cutoff):^(j-1)
		}
	m_p_y = invsym(cross(XX,W_p,XX))*cross(XX,W_p,y_p)
	m_p_z = invsym(cross(XX,W_p,XX))*cross(XX,W_p,z_p)
	mu0_phat_y[k] = m_p_y[1]
	mu0_phat_z[k] = m_p_z[1]
	sigma[k] = (y[k] - mu0_phat_y[k])*(z[k] - mu0_phat_z[k])
	}
}
else  {

X_range = abs(X[n]-X[1])

X_shift_mat = J(n,(2*matches),.)
y_shift_mat = J(n,(2*matches),.)
z_shift_mat = J(n,(2*matches),.)

X_shift_mat[,1] = .\X[1::(n-1)]
X_shift_mat[,(matches+1)] = X[2::n]\.

y_shift_mat[,1] = .\y[1::(n-1)]
y_shift_mat[,(matches+1)] = y[2::n]\.

z_shift_mat[,1] = .\z[1::(n-1)]
z_shift_mat[,(matches+1)] = z[2::n]\.

for (k=2; k<=matches; k++) {

	X_shift_mat[,k] = .\X_shift_mat[1::(n-1),(k-1)]
	y_shift_mat[,k] = .\y_shift_mat[1::(n-1),(k-1)]
	z_shift_mat[,k] = .\z_shift_mat[1::(n-1),(k-1)]	

							}
							
for (k=(matches+2); k<=(2*matches); k++) {

	X_shift_mat[,k] = X_shift_mat[2::n,(k-1)]\.
	y_shift_mat[,k] = y_shift_mat[2::n,(k-1)]\.
	z_shift_mat[,k] = z_shift_mat[2::n,(k-1)]\.

							}

ones = J(1,(2*matches),1)

X_mat = X * ones							
							
X_diff = abs(X_mat-X_shift_mat)							
							
num_matches = J(n,1,0)

y_match = J(n,matches,.)
z_match = J(n,matches,.)
							
for (k=1; k<=matches; k++)	{

	min_ind = (X_diff:==(rowmin(X_diff)*ones))
	
	num_matches_lt3 = num_matches:<3
	
	min_ind = (num_matches_lt3*ones):*min_ind
	
	y_match[,k] = rowsum(min_ind:*y_shift_mat)
	z_match[,k] = rowsum(min_ind:*z_shift_mat)
	
	X_diff = min_ind*(X_range+1) + (1:-min_ind):*X_diff 
	
	num_matches = num_matches + rowsum(min_ind)

							}

y_match_ave = rowsum(y_match):/num_matches
z_match_ave = rowsum(z_match):/num_matches

							
sigma = (num_matches:/(num_matches:+1)):*(y - y_match_ave):*(z - z_match_ave)

}
return(sigma)
}
mata mosave altrdvce(), replace
end
