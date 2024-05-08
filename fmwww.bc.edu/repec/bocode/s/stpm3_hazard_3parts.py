import jax.numpy as jnp   
import mladutil as mu

def python_ll(beta,X,wt,M,hasvarlist,hasconstant,ttrans_log):
  lli = python_lli(beta,X,wt,M,hasvarlist,hasconstant,ttrans_log)
  return(-jnp.sum(lli))

def python_lli(beta,X,wt,M,hasvarlist,hasconstant,ttrans_log):
  hasconstant = int(hasconstant)
  hasvarlist  = int(hasvarlist)
  ttrans_log  = int(ttrans_log)

  ## Parameters
  beta   = mu.beta_tolist(beta,X)
  if hasvarlist: xb =  mu.linpred(beta,X,1)
  else: xb=0
  splineeq = int(hasvarlist + 1)

  ## Linear predictor
  xbtime = mu.linpred(beta,X,splineeq)
  beta_time = beta[splineeq-1][M["betatime_idx"]]

  ## constant
  cons = hasconstant*beta_time[-1]
  if(hasconstant): beta_time = beta_time[:-1]  

  ## calculatate intecept and slope at boundaries
  b1_first = jnp.matmul(M["dsplines_P1"],beta_time[:,None])
  b0_first = jnp.matmul(M["splines_P1"],beta_time[:,None]) + \
                        cons + xb - b1_first*M["P1_upper_trans"]

  b1_last = jnp.matmul(M["dsplines_P3"],beta_time[:,None]) 
  b0_last = jnp.matmul(M["splines_P3"],beta_time[:,None]) + \
                         cons + xb - b1_last*M["P3_lower_trans"]  
  
  ## Part 1 (analytical) - depends on whether log transform
  if ttrans_log: 
    ch_p1 = jnp.where(M["includefirstint"],
                     (jnp.exp(b0_first)/(b1_first + 1)) *
                             (M["P1_upper"]**(b1_first + 1) - M["P1_lower"]**(b1_first + 1)),
                    0)
  else:
    ch_p1 = jnp.where(M["includefirstint"],
                     (jnp.exp(b0_first)/(b1_first)) *
                             (jnp.exp(b1_first*M["P1_upper"]) - jnp.exp(b1_first*M["P1_lower"])),
                     0)  
                     
  ## Part2 (numeric)
  haz_at_nodes1 = jnp.exp(jnp.matmul(M["allnodes1"],beta_time) + cons + xb)
  ch_p2 = jnp.where(M["includesecondint"],
                    M["ghmult1"]*jnp.sum(M["nodeweights"]*haz_at_nodes1,axis=1,keepdims=True),
                    0)
                     
  ## Part3 (analytical) - depends on whether log transform
  if ttrans_log:   
    ch_p3 = jnp.where(M["includethirdint"],
                     jnp.exp(b0_last)/(b1_last + 1) *
                            (M["P3_upper"]**(b1_last + 1) - M["P3_lower"]**(b1_last + 1)),
                     0)
  else:
    ch_p3 = jnp.where(M["includethirdint"],
                     jnp.exp(b0_last)/(b1_last) *
                            (jnp.exp(b1_last*M["P3_upper"]) - jnp.exp(b1_last*M["P3_lower"])),
                     0)    
  # print(jnp.hstack((M["t"],ch_p3))[0:100],)                
  # return log-likelhood
  return(wt*(M["d"]*jnp.log(M["bh"] + jnp.exp(xb + xbtime + jnp.log(M["t"]))) - 
                   (ch_p1 + ch_p2 + ch_p3)))  



  
