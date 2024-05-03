import jax
jax.config.update("jax_enable_x64", True)

from jax.ops import segment_sum
import jax.numpy as jnp 
import jax.lax as lax
from scipy.special import roots_legendre, roots_hermitenorm, roots_hermite
from jax.numpy.linalg import inv
from jax import jit, vmap

## beta to list
def beta_tolist(beta,X):
  Neq = len(X) - 1
  beta1 = []
  start = 0

  for i in range(Neq):
    Np = X[i+1].shape[1]
    beta1.append(beta[start:start+Np])
    start = start + Np
  return(beta1)

## Inverse logit function
def invlogit(z):  
  return(1/(1+jnp.exp(-z)))

## Gauss-Legendre quadrature over a vector
def vecquad_gl(fn,a,b,Nnodes,arglist): 
  nodes, weights = jnp.asarray(roots_legendre(Nnodes))
  return((0.5*(b-a))*jnp.sum(weights*fn(0.5*(b-a)*nodes+0.5*(a+b),*arglist),axis=1,keepdims=True))

## Gauss-Hermite  quadrature over a vector
def vecquad_gh(fn,Nnodes,arglist): 
  nodes, weights = jnp.asarray(roots_hermite(Nnodes))
  return(jnp.sum(weights*fn(nodes,*arglist),axis=1,keepdims=True))
  
## tanhsinh quadrature 2
def tanhsinh_quad(Nnodes,N):
  delta=jnp.linspace(-N,N,Nnodes)  
  h = delta[1] - delta[0]
  tj = jnp.exp(jnp.abs(delta))
  uj = jnp.exp(1/tj-tj)
  rj = 2*uj/(1+uj)  
  weights = h*((tj+1/tj)*rj/(1+uj))  
  nodes = jnp.where(delta<=0,(-1 + rj), (1 - rj))
  return(nodes,weights)  
  
  
## generate splines with betas
def rcsgen_beta(x,knots,beta,rmatrix=jnp.zeros(1)):
  hasrmatrix = rmatrix.shape[0]>1 
  Nknots   = knots.shape[0]
  Nobs     = x.shape[0]
  Nparams  = Nknots - 1
  kmin     = knots[0]
  kmax     = knots[Nknots]
  intknots = knots[1:Nparams,None]
  lam      = (kmax - intknots)/(kmax-kmin)
  ##spline matrix
  rcsX     = ((x>intknots)*(x - intknots)**3 - lam*((x>kmin)*(x-kmin)**3) - (x>kmax)*(1-lam)*(x-kmax)**3)
  rcsX     = jnp.hstack((x[:,None],rcsX.T))
  if hasrmatrix: rcsX = jnp.hstack((rcsX,jnp.ones((Nobs,1))))@(inv(rmatrix)[:,:-1])
  return((jnp.hstack((rcsX,jnp.ones((Nobs,1)))) @ beta.T))

## resticted cubic splines   
def rcsgen(x,knots,rmatrix=jnp.zeros(1)):
  hasrmatrix = rmatrix.shape[0]>1 
  Nknots   = knots.shape[0]
  Nobs     = x.shape[0]
  Nparams  = Nknots - 1
  kmin     = knots[0]
  kmax     = knots[Nknots]
  intknots = knots[1:Nparams,None]
  lam      = (kmax - intknots)/(kmax-kmin)
  ##spline matrix
  rcsX =  (x>intknots)*(x - intknots)**3 - lam*((x>kmin)*(x-kmin)**3) - (x>kmax)*(1-lam)*(x-kmax)**3
  rcsX = jnp.hstack((x[:,None],rcsX.T))
               
  if hasrmatrix: rcsX = jnp.hstack((rcsX,jnp.ones((Nobs,1))))@(inv(rmatrix)[:,:-1])
  
  return(rcsX)  

## derivative of resticted cubic splines   
def drcsgen(x,knots,rmatrix=jnp.zeros(1)):
  hasrmatrix = rmatrix.shape[0]>1 
  Nknots   = knots.shape[0]
  Nobs     = x.shape[0]
  Nparams  = Nknots - 1
  kmin     = knots[0]
  kmax     = knots[Nknots]
  intknots = knots[1:Nparams,None]
  lam      = (kmax - intknots)/(kmax-kmin)
  ##spline matrix
  rcsX = 3*(x>intknots)*(x - intknots)**2 - 3*lam*((x>kmin)*(x-kmin)**2) - 3*(x>kmax)*(1-lam)*(x-kmax)**2
  rcsX = jnp.hstack((jnp.ones((Nobs,1)),rcsX.T))
                   
  if hasrmatrix: rmatrix = rcsX = rcsX@(inv(rmatrix)[:-1,:-1]) 
  return(rcsX)  

## vectorise  
vrcsgen = jax.vmap(rcsgen,(0,None,None))
vdrcsgen = jax.vmap(drcsgen,(0,None,None))

## weibull survival function  
def weibsurv(t,lam,gam):
  return(jnp.exp(-lam*t**gam))
  
## weibull density function  
def weibdens(t,lam,gam):
  return(lam*gam*t**(gam-1)*jnp.exp(-lam*t**gam))

## extract liner predictor  (adds offset)
def linpred(beta,X,eq):
  return(jnp.dot(X[eq], beta[eq-1])[:,None] + X[0][eq-1])  

## sum over ids
def sumoverid(id,X,Nid):
  return(segment_sum(X,id,Nid))  
  
sumoverid = jax.vmap(sumoverid,(None,1,None),1)
  
## mlvecsum equivalent
def mlvecsum(Z,X,eq):
  return(jnp.sum(Z*X[eq],axis=0))

## mlmatsum equivalent
def mlmatsum(Z,X,eq1,eq2):
  return((Z*X[eq1]).T@X[eq2])

## NEWTON-RAPHSON   
jitinv=jit(inv)
jitdot=jit(jnp.dot)

def NewtonRaphson(mlad):
  error = 10
  i = 0
  oldbeta = mlad.like_fn_args[0]
  newbeta = oldbeta

  largs = mlad.like_fn_args[1:]
  if mlad.verbose: print("Optimizing in Python")
  while jnp.any(error > mlad.tol) and i < mlad.pymax_iter:
    Hinv = jitinv(mlad.H_fn(newbeta,*largs))
    g = mlad.grad_fn(newbeta,*largs)
    betachange =  jitdot(Hinv,g)
    newbeta = oldbeta - betachange
    #error = jnp.abs(newbeta-oldbeta)/(jnp.abs(oldbeta)+1)
    error = jnp.abs(jitdot(g,betachange))
    oldbeta = newbeta
    if mlad.verbose:print("   Python Iteration:", i+1, (jnp.max(error)))
    i += 1 
  return(newbeta)  


  
#NewtonRaphson = jit(NewtonRaphson)  
  

# H matrix for Natural Spines
def ns_getH(knots):
  Nintk = knots.shape[1] - 8

  C11 = 6/((knots[1,4]-knots[1,1])*(knots[1,4]-knots[1,2]))
  C31 = 6/((knots[1,5]-knots[1,2])*(knots[1,4]-knots[1,2]))
  C21 = -C11 - C31  
  
  Cp22 = 6/((knots[1,Nintk+5]-knots[1,Nintk+2])*(knots[1,Nintk+5]-knots[1,Nintk+3]))
  Cp2 =  6/((knots[1,Nintk+6]-knots[1,Nintk+3])*(knots[1,Nintk+5]-knots[1,Nintk+3]))
  Cp12 = -Cp22 - Cp2  
  
  if Nintk==0:
    H = jnp.array([[3,2,1,0],
                  [0,1,2,3]])
  elif Nintk==1:
    H = jnp.array([[-C21/C11,        1, 0,          0,         0],
                   [0,        -C31/C21, 1, -Cp22/Cp12,         0],
                   [0,               0, 0,          1, -Cp12/Cp2]])
  else:
    H1 = jnp.vstack((jnp.ones((1,3)),
                   jnp.array([[0,1,-C21/C31]]),
                   jnp.zeros((Nintk-2,3)),
                   jnp.zeros((2,3))))
    H2 = jnp.vstack((jnp.zeros((2,Nintk-2)),
                   jnp.identity(Nintk-2),
                   jnp.zeros((2,Nintk-2))))
      
    H3 = jnp.vstack((jnp.zeros((2,3)),
                   jnp.zeros((Nintk-2,3)),
                   jnp.array([-Cp12/Cp22,1,0]),
                   jnp.ones((1,3))))
    H = jnp.hstack((H1,H2,H3))

  sumH = jnp.sum(H,axis=1)[:,None]
  H = H/sumH

  return(jnp.transpose(H))

# bs - Bsplines
def bs(x,degree,knots,bknots,calcintercept,calcderiv):
  fullknots = jnp.concatenate((jnp.repeat(bknots[0],degree+1),
                               jnp.asarray(knots)*jnp.ones(1),
                               jnp.repeat(bknots[1],degree+1)))[None,:]
  Nintervals = fullknots.shape[1] - 1
  Z = jnp.hstack((jnp.zeros((1,Nintervals-degree-1)),jnp.ones((1,degree+1))))
  Nobs = x.shape[0]
  x = x[:,None] 
  M1 = (fullknots[1,:-1]<=x)*(x<fullknots[1,1:]) + Z*(fullknots[1,1:]==x)
  
  for pindex in range(degree):
    p = pindex + 1
    C1 = jnp.where(fullknots[1,p:-1]==fullknots[1,:-(p+1)],
                   0,
                   (x-fullknots[1,:-(p+1)])/(fullknots[1,p:-1]-fullknots[1,:-(p+1)]))
    C2 = jnp.where(fullknots[1,(p+1):]==fullknots[1,1:-(p)],
                   0,
                   (fullknots[1,(p+1):]-x)/(fullknots[1,(p+1):] - fullknots[1,1:-(p)]))
    splinevars = C1*M1[:,:-1] + C2*M1[:,1:]
    if p!=degree:
      M1 = splinevars   
      
  if not calcintercept:
    splinevars = splinevars[:,1:]      
    
  if calcderiv:
    C1 = jnp.where(fullknots[1,degree:-1]==fullknots[1,:-(degree+1)],
                   0,
                   degree/(fullknots[1,degree:-1]-fullknots[1,:-(degree+1)]))
    C2 = jnp.where(fullknots[1,(degree+1):]==fullknots[1,1:-(degree)],
                   0,
                   degree/(fullknots[1,(degree+1):]-fullknots[1,1:-(degree)]))
    dsplinevars = C1*M1[:,:-1] - C2*M1[:,1:]
    
    if not calcintercept:
      dsplinevars = dsplinevars[:,1:]       
   
  if calcderiv:
    return(splinevars,dsplinevars)
  else:
    return(splinevars) 

# ns - natural splines
def ns(x,knots,bknots,calcintercept,calcderiv):
  Nintk = len(knots)
  Nk = Nintk + 2
  allknots = jnp.hstack((jnp.repeat(bknots[0],4)[None,:],
                              jnp.array(knots)[None,:],
                              jnp.repeat(bknots[1],4)[None,:]))
 
  if calcderiv:
    bsplines, dbsplines = bs(x,3,knots,bknots,1,1) 
  else:
    bsplines = bs(x,3,knots,bknots,1,0)

  # deal with boundaries 
  bs_bknots, dbs_bknots = bs(jnp.array(bknots),3,knots,bknots,1,1)
  Nobs = x.shape[0]
  x = x[:,None] 
  bsplines = jnp.where(x<bknots[0],
                       bs_bknots[0,:] + dbs_bknots[0,:][None]*(x - bknots[0]),
                      bsplines)  
  bsplines = jnp.where(x>bknots[1],
                       bs_bknots[1,:] + dbs_bknots[1,:][None]*(x - bknots[1]),
                      bsplines)

  # get H
  H = ns_getH(allknots)
  bsplines = jnp.matmul(bsplines,H)
  
  if not calcintercept: bsplines = bsplines[:,:-1]
  
  if calcderiv:
    dbsplines = jnp.where(x<bknots[0],
                          dbs_bknots[0,:],
                          dbsplines)
    dbsplines = jnp.where(x>bknots[1],
                          dbs_bknots[1,:],
                          dbsplines)  
    dbsplines = jnp.matmul(dbsplines,H)
    if not calcintercept: dbsplines = dbsplines[:,:-1]
    
  # return
  if calcderiv: return(bsplines, dbsplines)
  else: return(bsplines)
    
    
# vectorized bsplines and natural splines
vbs = jit(jax.vmap(bs,(0,None,None,None,None,None)) ,static_argnums=(1,4,5))
vns = jit(jax.vmap(ns,(0,None,None,None,None)), static_argnums=(3,4))
