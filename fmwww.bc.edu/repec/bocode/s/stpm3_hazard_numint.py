import jax.numpy as jnp   
import mladutil as mu

def python_ll(beta,X,wt,M,hasvarlist,hasconstant,ttrans_log):
  lli = python_lli(beta,X,wt,M,hasvarlist,hasconstant,ttrans_log)
  return(-jnp.sum(lli))
  
def python_lli(beta,X,wt,M,hasvarlist,hasconstant,ttrans_log):
  ## Parameters
  beta   = mu.beta_tolist(beta,X)
  
  if hasvarlist: xb =  mu.linpred(beta,X,1)
  else: xb=0
  splineeq = int(hasvarlist + 1)

  xbtime = mu.linpred(beta,X,splineeq)
  beta_time = beta[splineeq-1][M["betatime_idx"]]

  # constant
  cons = hasconstant*beta_time[-1]
  if(hasconstant): 
    beta_time = beta_time[:-1]

  ## cumulative hazard
  haz_at_nodes1 = jnp.exp(jnp.matmul(M["allnodes1"],beta_time) + xb + cons)
  cumhaz = M["ghmult1"]*jnp.sum(M["nodeweights"]*haz_at_nodes1,axis=1,keepdims=True)
  
  # return log-likelhood
  return((wt*(M["d"]*jnp.log(M["bh"] + jnp.exp(xb + xbtime + jnp.log(M["t"]))) - cumhaz)))



  
