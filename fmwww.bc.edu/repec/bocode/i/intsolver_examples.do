/*******************************/
/* Examples from the help file */
/*******************************/

/* Help example one */

mata:
mata clear

/* Regular function */
real matrix func(real matrix x,real scalar i)
{
	if (i==1) return(1:-2*x[,1]:*x[,2]:-3:*x[,1]:^2)
	if (i==2) return(1:-x[,1]:^2:-3:*x[,2]:^2)
}

/* Regular jacobian */
real matrix jac(real matrix x,real scalar i, real scalar j)
{
	if (i==1 & j==1) return(-2*x[,2]-6*x[,1])	
	if (i==1 & j==2) return(-2*x[,1])
	if (i==2 & j==1) return(-2*x[,1])	
	if (i==2 & j==2) return(-6*x[,2])	
}

/* Interval version of function */
real matrix func_I(real matrix x,real scalar i, real scalar d)
{
	real matrix X1, X2, A, I, B, C, D
	X1=x[,1::2]
	X2=x[,3::4]
if (i==1) {
	A=2*int_mult(X1,X2,d)
	I=J(rows(A),2,1)
	B=int_sub(I,A,d)
	C=3*int_mult(X1,X1)
	D=int_sub(B,C,d)
	return(D)
}
if (i==2) {
	A=int_mult(X1,X1)
	B=3*int_mult(X2,X2)
	I=J(rows(A),2,1)
	C=int_sub(I,A,d)
	D=int_sub(C,B,d)
	return(D)
}
}

/* Interval version of jacobian */

real matrix jac_I(real matrix x,real scalar i,real scalar j, real scalar d)
{
	real matrix X1, X2, A, B, C
	real scalar r

	X1=x[,1::2]
	X2=x[,3::4]
	r=rows(X1)

	if (i==1 & j==1) {
	A=int_mult(J(r,2,-2),X2,d)
	B=int_mult(J(r,2,-6),X1,d)
	C=int_add(A,B,d)
	return(C)
}
if (i==1 & j==2) {
	A=int_mult(J(r,2,-2),X1,d)
	return(A)
}
if (i==2 & j==1) {
	A=int_mult(J(r,2,-2),X1,d)
	return(A)

}
if (i==2 & j==2) {
	A=J(r,2,-6)
	B=int_mult(A,X2,d)
	return(B)
}
}

/* Initialize the problem */

Prob=int_prob_init()
int_prob_args(Prob,2)
int_prob_f_Iform(Prob,&func_I())
int_prob_jac_Iform(Prob,&jac_I())
int_prob_f(Prob,&func())
int_prob_jac(Prob,&jac())
int_prob_ival(Prob,(-100,100) \ (-100,100))

/* Solve the problem */

int_solve(Prob)
int_prob_ints_vals(Prob)
int_newton_iter(Prob)
int_prob_pts_vals(Prob)
end

/* Extending the example a little bit            */
/* Using routines with random start points       */
/* And then just using parallel newton iteration */


mata
Prob2=int_prob_init()
int_prob_args(Prob2,2)
int_prob_f(Prob2,&func())
int_prob_jac(Prob2,&jac())
int_prob_ival(Prob2,(-100,100) \ (-100,100))

/* Different steps from this point on */
randpoints=-1:+2*runiform(10,2)	/* Random points */
int_prob_init_pts(Prob2,randpoints)
int_prob_method(Prob2,"newton")

/* Solution */
int_newton_iter(Prob2)
int_prob_pts_vals(Prob2)
end


/***********************************************/
/* Second problem from the help file           */
/* Numerical solution of Diamond's (1982, JPE) */
/* Search model of unemployment                */
/***********************************************/


mata

/* For the required density function, use a pareto distribution. */
/* Hence: */
/* CDF is           F(x)=1-x^alpha,          a<0, x>1 */
/* PDF is           f(x)= -alphax^(alpha-1), a<0, x>1 */
/* Cond. exp is  E[x|x<X]=-alpha/(alpha+1)X^(alpha+1) */

/* The two equilibrium conditions are */

real matrix eqconds(real matrix X, real scalar i, transmorphic Z)
{
	real scalar a,alpha,b,r,y
	real matrix eq,CE,Gc,e,c

	a    =Z[1]
	alpha=Z[2]
	b     =Z[3]
	r     =Z[4]
	y	  =Z[5]
	
	e=X[,1]
	c=X[,2]

	Gc=1:-c:^alpha
	if (i==1) {
		eq=a*(1:-e):*Gc:-e:*b*e				    /* Equilibrium employment */
	}
	if (i==2) {
		CE=(-alpha/(alpha+1)):*c:^(alpha+1)
		eq=c*r:+b:*e*r:+a*c:*Gc-b:*e*y:-a:*CE	/* Equilibrium project adoption */
	}
	return(eq)
}

/* Jacobian of the equilibrium conditions */

real matrix eqjac(real matrix X, real scalar i, real scalar j, transmorphic Z)
{
	real scalar a,alpha,b,r
	real matrix eq,y,e,c,Gc,dGc,dCE
	a    =Z[1]
	alpha=Z[2]
	b     =Z[3]
	r     =Z[4]
	y	  =Z[5]
	
	e=X[,1]
	c=X[,2]

	
	if (i==1 & j==1) {
		Gc=1:-c:^alpha	
		eq=-a*Gc:-2*e:*b
	}
	if (i==1 & j==2) {
		dGc=-alpha*c:^(alpha-1)
		eq=a*(1:-e):*dGc
	}	
	if (i==2 & j==1) {
		eq=J(rows(X),1,b*r:-b*y)
	}
	if (i==2 & j==2) {
		Gc=1:-c:^alpha
		dGc=-alpha*c:^(alpha-1)
		dCE=-alpha:*c:^alpha	
		eq=r:+a*Gc:+a*c:*dGc:-a:*dCE
	}
	return(eq)
}

/* Interval version of equilibrium conditions */
real matrix eqconds_I(real matrix X, real scalar i, real scalar digits, transmorphic Z)
{
	real scalar a,alpha,b,r
	real matrix eq,Gc,A,B,C,D,CE,Alphas,y,e,c,Ones
	
	a    =Z[1]
	alpha=Z[2]
	b     =Z[3]
	r     =Z[4]
	y	  =Z[5]
	
	e=X[,1::2]
	c=X[,3::4]
	
	Ones=J(rows(X),2,1)
	A=int_pow(c,alpha,digits)
	Gc=int_sub(Ones,A,digits)
	if (i==1) {
		A=a*int_sub(Ones,e,digits)
		B=b*int_mult(e,e,digits)
		C=int_mult(A,Gc,digits)
		eq=int_sub(C,B)
	}
	else if (i==2) {
		Alphas=J(rows(X),2,-alpha/(alpha+1))
		CE=int_mult(Alphas,int_pow(c,alpha+1,digits),digits)
		A=r*int_add(c,b*e,digits)
		B=a*int_mult(c,Gc,digits)
		C=int_add(b*y*e,a*CE,digits)
		D=int_sub(B,C,digits)
		eq=int_add(A,D,digits)
	}
	return(eq)
}

/* Interval version of jacobian of equilibrium conditions */
real matrix eqjac_I(real matrix X, real scalar i, real scalar j, real scalar digits, transmorphic Z)
{
	real scalar a,alpha,b,r
	real matrix eq,Ones,A,Gc,dGc,dCE,e,c,y

	a    =Z[1]
	alpha=Z[2]
	b     =Z[3]
	r     =Z[4]
	y	  =Z[5]
	
	e=X[,1::2]
	c=X[,3::4]

	Ones=J(rows(X),2,1)
	A=int_pow(c,alpha,digits)
	Gc=int_sub(Ones,A,digits)	
	if (i==1 & j==1) {
		eq=int_sub(-a*Gc,2*e:*b,digits)
	}
	if (i==1 & j==2) {
		dGc=-alpha*int_pow(c,alpha-1,digits)
		eq=a*int_mult(int_sub(Ones,e),dGc,digits)
	}	
	if (i==2 & j==1) {
		eq=J(rows(X),2,b*r:-b*y)
	}
	if (i==2 & j==2) {
		dGc=-alpha*int_pow(c,alpha-1,digits)
		dCE=-alpha*int_pow(c,alpha,digits)	
		eq=r:+a*int_sub(int_add(Gc,int_mult(c,dGc,digits),digits),dCE,digits)
	}
	return(eq)
}

Diamond=int_prob_init()
int_prob_args(Diamond,2)
int_prob_f(Diamond,&eqconds())
int_prob_jac(Diamond,&eqjac())
int_prob_f_Iform(Diamond,&eqconds_I())
int_prob_jac_Iform(Diamond,&eqjac_I())

/* Just bound solutions away from zero */

bounds=0.000001,1 \ 0.000001,10
int_prob_ival(Diamond,bounds)

Z=2,-.12,3,.4,2	/* Parameter values */

int_prob_addinfo(Diamond,Z)
int_solve(Diamond)
int_prob_ints_vals(Diamond)
int_newton_iter(Diamond)
int_prob_pts_vals(Diamond)
end

/*********************************************************/
/*********************************************************/

/*  Additional examples and test problems */

/**********************************************************/
/*                    Example One                         */ 
/* A simple example: with function x^2+1/2*x*y+y^2        */
/**********************************************************/

mata
/* Interval gradient or f */
 
real matrix myfunc_grad_I(real matrix Ps,i,dgs)
{
	real scalar r,C11,C21,C22
	real matrix X
	r=rows(Ps)
	C11=1.4
	C21=2
	C22=1.8
	C21=J(r,2,C21)
	if (i==1) {
		C11=J(r,2,C11)
		X=int_add(int_mult(C11,Ps[,1::2],dgs),int_mult(C21,Ps[,3::4],dgs),dgs)
		return(X)
			}
	if (i==2) {
		C22=J(r,2,C22)
		X=int_add(int_mult(C21,Ps[,1::2],dgs),int_mult(C22,Ps[,3::4],dgs),dgs)
		return(X)
			}
}

/* Regular gradient */

real matrix myfunc_grad(real matrix Ps,i)
{
	real scalar r,C11,C21,C22
	real matrix X
	
	r=rows(Ps)
	C11=1.4
	C21=2
	C22=1.8
	C21=J(r,1,C21)
	if (i==1) {
		C11=J(r,1,C11)
		X=C11:*Ps[,1]:+C21:*Ps[,2]
		return(X)
			}
	if (i==2) {
		C22=J(r,1,C22)
		X=C21:*Ps[,1]:+C22:*Ps[,2]
		return(X)
			}
}

/* Interval Jacobian */

real matrix myfunc_jac_I(real matrix Ps,i,j,d)
{
	real scalar r
	r=rows(Ps)
	if (i==1 & j==1) return(J(r,2,1.4))
	if (i==1 & j==2) return(J(r,2,2))
	if (i==2 & j==1) return(J(r,2,2))
	if (i==2 & j==2) return(J(r,2,1.8))
}

/* Regular Jacobian */

real matrix myfunc_jac(real matrix Ps,i,j)
{
	real scalar r
	r=rows(Ps)
	if (i==1 & j==1) return(J(r,1,1.4))
	if (i==1 & j==2) return(J(r,1,2))
	if (i==2 & j==1) return(J(r,1,2))
	if (i==2 & j==2) return(J(r,1,1.8))
}

/* Full solution method */
/* Initialization       */

Prob=int_prob_init()
int_prob_f_Iform(Prob,&myfunc_grad_I())
int_prob_jac_Iform(Prob,&myfunc_jac_I())
int_prob_f(Prob,&myfunc_grad())
int_prob_jac(Prob,&myfunc_jac())
int_prob_args(Prob,2)

/* Solution interval and solving the problem */

Ival=(-100,100) \ (-100,100)
int_prob_ival(Prob,Ival)
int_solve(Prob)
int_newton_iter(Prob)
int_prob_pts_vals(Prob)

/* Alternative solution method - just newton iteration */
/* Initialization                                      */

Prob2=int_prob_init()
int_prob_f(Prob2,&myfunc_grad())
int_prob_jac(Prob2,&myfunc_jac())
int_prob_args(Prob2,2)

/* Solution - just iterate from           */
/* 100 random points between -100 and 100 */

Pts=-100:+200*runiform(100,2)
int_prob_init_pts(Prob2,Pts)
int_prob_ival(Prob2,(-100,100 \ -100,100))
int_prob_method(Prob2,"newton")
int_newton_iter(Prob2)
int_prob_pts_vals(Prob2)

end

/**********************************************************/
/*                    Example Two                         */ 
/*                The Rosenbrock problem                  */
/**********************************************************/

mata:

/* Function is {10(x2-x1^2), 1-x1} */

real matrix rosenbrock_g(real matrix X,real scalar i)
{
	if (i==1) return(10*(X[,2]:-X[,1]:^2))
	if (i==2) return(1:-X[,1])
}

/* Regular Jacobian */

real matrix rosenbrock_J(real matrix X,real scalar i,real scalar j)
{
	if (i==1 & j==1) return(-2*10*X[,1])
	if (i==1 & j==2) return(J(rows(X),1,10))
	if (i==2 & j==1) return(J(rows(X),1,-1))
	if (i==2 & j==2) return(J(rows(X),1,0))
}

/* Interval version of the gradient */

real matrix rosenbrock_gI(real matrix X,real scalar i,d)
{
	if (i==1) return(int_mult(J(rows(X),2,10),int_sub(X[,3::4],int_mult(X[,1::2],X[,1::2],d),d),d))
	if (i==2) return(int_sub(J(rows(X),2,1),X[,1::2],d))	
}

/* Interval version of the jacobian */

real matrix rosenbrock_JI(real matrix X, real scalar i,real scalar j,d)
{
	if (i==1 & j==1) return(int_mult(J(rows(X),2,-20),X[,1::2],d))
	if (i==1 & j==2) return(J(rows(X),2,10))
	if (i==2 & j==1) return(J(rows(X),2,-1))
	if (i==2 & j==2) return(J(rows(X),2,0))
}

/* Initialization of the problem */

Rosenbrock=int_prob_init()
int_prob_f_Iform(Rosenbrock,&rosenbrock_gI())
int_prob_jac_Iform(Rosenbrock,&rosenbrock_JI())
int_prob_f(Rosenbrock,&rosenbrock_g())
int_prob_jac(Rosenbrock,&rosenbrock_J())
int_prob_args(Rosenbrock,2)
Ival=(-100,100) \ (-100,100)
int_prob_ival(Rosenbrock,Ival)

/* Solution */
int_solve(Rosenbrock)
int_prob_ints_vals(Rosenbrock)
int_newton_iter(Rosenbrock)
int_prob_pts_vals(Rosenbrock)
end

/**********************************************************/
/*                    Example Three                       */ 
/*                The Freudenstein and Roth function      */
/**********************************************************/

mata:

/* Interval gradient of function */

real matrix freudroth_g(real matrix X,real scalar i)
{
	if (i==1) return(-13:+X[,1]:+((5:-X[,2]):*X[,2]:-2):*X[,2])
	if (i==2) return(-29:+X[,1]:+((1:+X[,2]):*X[,2]:-14):*X[,2])
}

/* Interval Jacobian */

real matrix freudroth_J(real matrix X,real scalar i,real scalar j)
{
	if (i==1 & j==1) return(J(rows(X),1,1))
	if (i==1 & j==2) return(10*X[,2]:-3*X[,2]:^2:-2)
	if (i==2 & j==1) return(J(rows(X),1,1))
	if (i==2 & j==2) return(3*X[,2]:^2+2:*X[,2]:-14)
}

/* Interval gradient */
real matrix freudroth_gI(real matrix X,real scalar i,d)
{
	real matrix A1,A2,B1,B2,C1,D1
	if (i==1) {
		A1=int_add(J(rows(X),2,-13),X[,1::2],d)
		A2=int_sub(J(rows(X),2,5),X[,3::4],d)
		B1=int_mult(A2,X[,3::4],d)
		B2=int_sub(B1,J(rows(X),2,2),d)
		C1=int_mult(B2,X[,3::4],d)
		D1=int_add(A1,C1,d)
		return(D1)
				}
	if (i==2) {
		A1=int_add(J(rows(X),2,-29),X[,1::2],d)
		A2=int_add(J(rows(X),2,1),X[,3::4],d)
		B1=int_mult(A2,X[,3::4],d)
		B2=int_sub(B1,J(rows(X),2,14),d)
		C1=int_mult(B2,X[,3::4],d)
		D1=int_add(A1,C1,d)
		return(D1)
				}
}

/* Interval Jacobian */
real matrix freudroth_JI(real matrix X, real scalar i,real scalar j,d)
{
	real matrix A1,A2,B1,B2,C1,D1
	if (i==1 & j==1) return(J(rows(X),2,1))
	if (i==1 & j==2) {
		A1=int_mult(J(rows(X),2,10),X[,3::4],d)
		A2=int_mult(X[,3::4],X[,3::4],d)
		A2=int_mult(J(rows(X),2,3),A2,d)
		A2=int_add(A2,J(rows(X),2,2),d)
		A1=int_sub(A1,A2,d)
		return(A1)
					}
	if (i==2 & j==1) return(J(rows(X),2,1))
	if (i==2 & j==2) {
		A1=int_mult(X[,3::4],X[,3::4],d)
		B1=int_mult(J(rows(X),2,3),A1,d)
		B2=int_mult(X[,3::4],J(rows(X),2,2),d)
		C1=int_add(B1,B2,d)
		D1=int_sub(C1,J(rows(X),2,14),d)
		return(D1)
					}
}

/* Initialize the problem */

Freudroth=int_prob_init()
int_prob_f_Iform(Freudroth,&freudroth_gI())
int_prob_jac_Iform(Freudroth,&freudroth_JI())
int_prob_f(Freudroth,&freudroth_g())
int_prob_jac(Freudroth,&freudroth_J())
int_prob_ival(Freudroth,(-100,100,-100,100))
int_prob_args(Freudroth,2)

int_solve(Freudroth)
int_prob_ints_vals(Freudroth)
int_newton_iter(Freudroth)
int_prob_pts_vals(Freudroth)
end

/**********************************************************/
/*                    Example Four                        */ 
/*                Powell's badly scaled function          */
/**********************************************************/

mata:

/* Gradient */
real matrix powellbs_g(X,i)
{
	real matrix a,b,c,d
	if (i==1) {
		a=X[,1]:*X[,2]
		b=10^4*a
		c=b:-1
		return(c)
			}
	if (i==2) {
		a=exp(-X[,1])
		b=exp(-X[,2])
		c=a:+b
		d=c:-1.0001
		return(d)
			  }
}

/* Jacobian */
real matrix powellbs_J(X,i,j)
{
	real matrix a
	if (i==1 & j==1) {
		a=10^4*X[,2]
		return(a)
					}
	if (i==1 & j==2) {
		a=10^4*X[,1]
		return(a)
					}
	if (i==2 & j==1) {
		a=-exp(-X[,1])
		return(a)
					}
	if (i==2 & j==2) {
		a=-exp(-X[,2])
		return(a)
					}
}

/* Ancillary function - interval exponentiation function */

real matrix int_exp(X,|digits)
{
	real matrix A,B
	real scalar i

	if (args()==1) digits=1e-8
	
	A=exp(X)
	B=J(rows(X),0,.)
	for (i=1;i<=cols(X);i=i+2) {
		B=B,r_down(A[,i],digits),
			r_up(A[,i+1],digits)
								}
	return(B)
}

/*Interval Jacobian */
real matrix powellbs_JI(X,i,j,d)
{
	real matrix a,b,c
	if (i==1 & j==1) {
		a=int_mult(J(rows(X),2,10^4),X[,3::4],d)
		return(a)
					}
	if (i==1 & j==2) {
		a=int_mult(J(rows(X),2,10^4),X[,1::2],d)
		return(a)
					}
	if (i==2 & j==1) {
		a=int_mult(J(rows(X),2,-1),X[,1::2],d)
		b=int_exp(a,d)
		c=int_mult(J(rows(X),2,-1),b,d)
		return(c)
					}
	if (i==2 & j==2) {
		a=int_mult(J(rows(X),2,-1),X[,3::4],d)
		b=int_exp(a,d)
		c=int_mult(J(rows(X),2,-1),b,d)
		return(c)
					}
}


/* Interval gradient */
real matrix powellbs_gI(X,i,dgts)
{
	real matrix a,b,c,d,e,f
	if (i==1) {
		a=int_mult(X[,1::2],X[,3::4],dgts)
		b=int_mult(J(rows(X),2,10^4),a,dgts)
		c=int_sub(b,J(rows(X),2,1),dgts)
		return(c)
		}
	if (i==2) {
		a=int_mult(X[,1::2],J(rows(X),2,-1),dgts)
		b=int_mult(X[,3::4],J(rows(X),2,-1),dgts)
		c=int_exp(a,dgts)
		d=int_exp(b,dgts)
		e=int_add(c,d,dgts)
		f=int_sub(e,J(rows(X),2,1.0001),dgts)
		return(f)
			  }
}	

/* Initialization */
Powellbs=int_prob_init()
int_prob_f_Iform(Powellbs,&powellbs_gI())
int_prob_jac_Iform(Powellbs,&powellbs_JI())
int_prob_f(Powellbs,&powellbs_g())
int_prob_jac(Powellbs,&powellbs_J())
int_prob_mbwidth(Powellbs,1e-4)
int_prob_digits(Powellbs,1e-8)
int_prob_ival(Powellbs,(-100,100,-100,100))
int_prob_args(Powellbs,2)

/* Solution */
int_solve(Powellbs)
int_prob_ints_vals(Powellbs)
int_newton_iter(Powellbs)
int_prob_pts_vals(Powellbs)
end
