from jax.ops import segment_sum
import jax.numpy as jnp 
import jax.lax as lax
from jax import jit, vmap, pmap
from scipy.special import roots_legendre, roots_hermitenorm, roots_hermite
from jax.numpy.linalg import inv
from jax.config import config
config.update("jax_enable_x64", True)

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
vrcsgen = vmap(rcsgen,(0,None,None))
vdrcsgen = vmap(drcsgen,(0,None,None))

  
  
## weibull survival function  
def weibsurv(t,lam,gam):
  return(jnp.exp(-lam*t**gam))
  
## weibull density function  
def weibdens(t,lam,gam):
  return(lam*gam*t**(gam-1)*jnp.exp(-lam*t**gam))

## extract liner predictor  (adds offset)
def linpred(beta,X,eq):
  return(jnp.dot(X[eq], beta[eq-1])[:,None] + X[0][eq-1])  

##  return((X[eq] @ beta[eq-1])[:,None] + X[0][eq-1])  

## sum over ids
def sumoverid(id,X,Nid):
  return(segment_sum(X,id,Nid))  
  
sumoverid = vmap(sumoverid,(None,1,None),1)
  
## mlvecsum equivalent
def mlvecsum(Z,X,eq):
  return(jnp.sum(Z*X[eq],axis=0))

## mlmatsum equivalent
def mlmatsum(Z,X,eq1,eq2):
  return((Z*X[eq1]).T@X[eq2])
  
