/// Derivative of cdf

version 14

mata: mata clear
mata: mata set matastrict on
mata:

real vector mvnxpb(real colvector b,
				   real colvector mean,
				   real matrix V,
				   | real scalar dfdx)
{
	real vector ret
	real vector x
	x = b - mean
	
	if (args()==3) ret = _mvnxpb(x, V)
	else if(args()==4) ret = partiald(x, V)
	return(ret)
}



/// multivariate normal CDF by genz biv.conditioning
real scalar _mvnxpb(real colvector b,
				   real matrix r)
{
// define variables
real scalar n, ep, i, k, p, pb, ckk, dem, de, s, im, cii, u, w, v, am, bm, _ha, _hb, t
real matrix c, D
real colvector ap, bp, d, y, ai, bi, E, ab, bb, cb, sg, _hc1, _hc2, _hhc1, ina, inb

n=rows(r)
c = r
//ap = a
bp = b
d = sqrt(diagonal(c))

for (i=1; i<=n; i++){
	//ap[i,1] = ap[i,1]/d[i,1]
	bp[i,1] = bp[i,1]/d[i,1]
}
c = corr(c)

y = J(n,1,0)
p = 1
pb = 1
D = I(n)

for (k=1; k<=n; k++){

im = k
ckk = 0
dem = 1
s = 0
/// find minimum outer value for integration
for (i=k; i<=n; i++){
	cii = sqrt(c[i,i])
	if (i>1){
		if (k==1) s = s
		if (k>1)  s = c[|i,1\i,(k-1)|]*y[|1\(k-1)|]
	}
	//ai = (ap[i]-s)/cii
	bi = (bp[i]-s)/cii
	de = normal(bi)-0
	if (de<=dem){
		ckk = cii
		dem = de
		//am = ai
		bm = bi
		im = i
	}
}

if (im>k){
	//_ha = ap[im,1]
	//ap[im,1] = ap[k,1]
	//ap[k,1] = _ha
	
	_hb = bp[im,1]
	bp[im,1] = bp[k,1]
	bp[k,1] = _hb
	
	if (k>1){
		_hc1 = c[|im,1\im,(k-1)|]
		c[|im,1\im,(k-1)|] = c[|k,1\k,(k-1)|]
		c[|k,1\k,(k-1)|] = _hc1
	}
	
	if ((im+1)<=n){
		_hc2 = c[|(im+1),im\n,im|]
		c[|(im+1),im\n,im|] = c[|(im+1),k\n,k|]
		c[|(im+1),k\n,k|] = _hc2
	}
	
	if ((k+1)<=(im-1)){
		t = c[|(k+1),k\(im-1),k|]
		c[|(k+1),k\(im-1),k|] = c[|im,(k+1)\im,(im-1)|]'
		c[|im,(k+1)\im,(im-1)|] = t'
		c[im,im] = c[k,k]		
	}
	else if ((k+1)>(im-1)){
		c[im,im] = c[k,k]
	}
}

if (ckk>0){
c[k,k] = ckk

if ((k+1)<=n){
	c[|k,(k+1)\k,n|] = J(1,(n-k),0)
	for (i=(k+1); i<=n; i++){
		c[i,k] = c[i,k]/ckk
		c[|i,(k+1)\i,i|] =  c[|i,(k+1)\i,i|] - c[i,k]*c[|(k+1),k\i,k|]'
	}
}

if (abs(dem)>0){
	y[k] = (0-normalden(bm))/dem
}

}

p = p*dem

////bivariate product
if (mod(k,2)==0){
	u = c[(k-1),(k-1)]
	v = c[k,k]
	w = c[k,(k-1)]
	c[|(k-1),(k-1)\n,k|] = c[|(k-1),(k-1)\n,k|]*(1/u, 0\-w/(u*v), 1/v)
	//ab = ap[|(k-1),1\k,1|]
	bb = bp[|(k-1),1\k,1|]
	cb = J(rows(bb),1,0)
	if (k>2){
		cb = c[|(k-1),1\k,(k-2)|]*y[|1,1\(k-2),1|]
	}
	sg = (u^2, u*w\u*w, (w^2+v^2))
	D[|(k-1),(k-1)\k,k|] = sg
	//ina = ab - cb
	inb = bb - cb
	E = bvnmmg(inb,sg)
	pb = pb*E[3,1]
	y[|(k-1),1\k,1|] = (E[1,1], E[2,1])'
	
}

}
if (mod(n,2)==1) pb = pb*dem


return(pb)

/// function end
}


/// partial derivative of Phi(ss;vv,L)
real colvector partiald(real colvector s,
                        real matrix L)			           
{
real scalar n, i
real colvector part, s_no_i, colll, v_i, at_vec
real matrix L_no_i

n = rows(L)
part = J(n,1,.)

for (i=1; i<=n; i++){
	L_no_i = elimmat(L,i)
	s_no_i = elimvec(s,i)
	colll = collvec(L,i)
	v_i = colll*L[i,i]^(-1)*s[i]
	at_vec = s_no_i - v_i
	part[i] = normalden(s[i],0,sqrt(L[i,i]))*_mvnxpb(at_vec,L_no_i)	
	
}
return(part)
}

/// Eliminate t-th row and column of matrix M
real matrix elimmat(real matrix M,
		            real scalar t)
{
real scalar n
real matrix m1, m
n = rows(M)

if (t>1 & t<n) {
     m1 = J(n,(n-1),.)
     m = J((n-1),(n-1),.)
     m1[|1,1\n,(t-1)|] = M[|1,1\n,(t-1)|]
     m1[|1,t\n,(n-1)|] = M[|1,(t+1)\n,n|]
     m[|1,1\(t-1),(n-1)|] = m1[|1,1\(t-1),(n-1)|] 
     m[|t,1\(n-1),(n-1)|] = m1[|(t+1),1\n,(n-1)|]
}
else if (t == 1){
	m = J((n-1),(n-1),.)
	m[|1,1\(n-1),(n-1)|] = M[|2,2\n,n|]
}
else if (t == n){
	m = J((n-1),(n-1),.)
	m[|1,1\(n-1),(n-1)|] = M[|1,1\(n-1),(n-1)|]	
}
return(m)
}

/// Eliminate t-th element in vector S
real colvector elimvec(real colvector S,
		               real scalar t)
{
real scalar n
real colvector s
n = rows(S)

if (t>1 & t<n) {
    s = J((n-1),1,.)
    s[|1\(t-1)|] = S[|1\(t-1)|] 
    s[|t\(n-1)|] = S[|(t+1)\n|] 
}
else if (t == 1){
	s = J((n-1),1,.)
	s = S[|2\n|]
}
else if (t == n){
	s = J((n-1),1,.)
	s = S[|1\(n-1)|]
}
return(s)
}

/// (n-1)-vector = t-th column of matrix Lambda, without t-th element
real colvector collvec(real matrix M,
		               real scalar t)
{
real colvector collv, collvt
real scalar n
n= rows(M)
collvt = M[.,t]
collv = J((n-1),1,.)
if (t>1 & t<n) {
     collv[|1\(t-1)|] = collvt[|1\(t-1)|]
	 collv[|t\(n-1)|] = collvt[|(t+1)\n|] 
}
else if (t == 1){
	collv = collvt[|2\n|]
}
else if (t == n){
	collv = collvt[|1\(n-1)|]
}

return(collv)
}

real colvector bvnmmg(real colvector b,
		      real matrix sg)
{
/// compute bivariate normal probability moments
/// expected values Ex, Ey, and probabiluty p for bivariate normal
/// vector [x y], with [x y]<[xu yu] and covar. matrix sg

real scalar cx,cy, r, xu, yu
real colvector E

cx = sqrt(sg[1,1])
cy = sqrt(sg[2,2])
r = sg[2,1]/(cy*cx)
xu = b[1]/cx
yu = b[2]/cy

E = bvnmom(xu,yu,r)
E[1] = E[1]*cx
E[2] = E[2]*cy

return(E)

/// function end
}

real colvector bvnmom(real scalar xu,
		      real scalar yu,
		      real scalar r)
{
/// compute bivariate normal probability moments
/// expected values Ex, Ey, and probabiluty p for bivariate normal
/// x, with a<x<b and covar. matrix sg
/// NO INFTY

real scalar p, rs, Phiyxl, Phiyxu, pPhixy, Phixyl, Phixyu, pPhiyx, Ex_, Ey_, Ex, Ey
real colvector E

rs = 1/sqrt(1-r^2)
p = binormal(8e+307,8e+307,r) - binormal(-xu,8e+307,r) - binormal(8e+307,-yu,r) + binormal(-xu,-yu,r)
/*
Phiyxl = normal((yu-r*xl)*rs) - normal((yl-r*xl)*rs)
Phiyxu = normal((yu-r*xu)*rs) - normal((yl-r*xu)*rs)
pPhixy = normalden(xl)*Phiyxl - normalden(xu)*Phiyxu
Phixyl = normal((xu-r*yl)*rs) - normal((xl-r*yl)*rs)
Phixyu = normal((xu-r*yu)*rs) - normal((xl-r*yu)*rs)
pPhiyx = normalden(yl)*Phixyl - normalden(yu)*Phixyu;
*/
Phiyxu = normal((yu-r*xu)*rs)
pPhixy = - normalden(xu)*Phiyxu
Phixyu = normal((xu-r*yu)*rs)
pPhiyx = -normalden(yu)*Phixyu

Ex_ = pPhixy + r*pPhiyx
Ey_ = r*pPhixy + pPhiyx

Ex = Ex_/p
Ey = Ey_/p

E = (Ex,Ey,p)'
return(E)


/// end function
}


mata mlib create lmvnxpb, replace dir(PERSONAL)
mata mlib add lmvnxpb _mvnxpb() partiald() elimmat() elimvec() collvec() bvnmmg() bvnmom() mvnxpb()
				
mata mlib index

end




exit








