from scipy.special import roots_legendre 
import jax.numpy as jnp
from jax import vmap, jit
import mladutil as mu

def mlad_setup(M):
## setup
  Nobs = M["t"].shape[0]
  M["betatime_idx"] = M["betatime_idx"][1,].astype(int)
  M["Nnodes"] = int(M["Nnodes"])
  M["ttrans_log"] = int(M["ttrans_log"])
 
## different types of quadrature  
  if M["hastanhsinh"]:
    nodes, M["nodeweights"] = mu.tanhsinh_quad(M["Nnodes"],M["tanhsinh_N"])
  else:
    nodes, M["nodeweights"] = roots_legendre(M["Nnodes"])

## nodes
  if(M["pyallnumint"]):
    nodes1 = 0.5*(M["t"] - M["t0"])*nodes + 0.5*(M["t"] + M["t0"])
    M["ghmult1"] = (0.5*(M["t"]-M["t0"]))
  else:
    nodes1 = 0.5*(M["P2_upper"] - M["P2_lower"])*nodes + 0.5*(M["P2_upper"] + M["P2_lower"])
    M["ghmult1"] = (0.5*(M["P2_upper"]-M["P2_lower"]))	
	
## Transform to log if necessary
  if M["ttrans_log"]: 
    nodes1 = jnp.log(nodes1)

## Generate splines    
  intknots = M["knots"][0,1:-1]
  bknots = jnp.hstack((M["knots"][0,0],M["knots"][0,-1]))
  
  if M["spline_ns"]:
    M["allnodes1"] = mu.vns(nodes1,intknots,bknots,False,False)
  elif M["spline_bs"]:
    degree = int(M["bs_degree"])
    M["allnodes1"] = mu.vbs(nodes1,degree,intknots,bknots,False,False)
  # NEED TO ADDRCS

  ## add time dependent effects
  for i in range(1,int(M["Ntvc"])+1):
    tvcintknots = M["tvcknots"+str(i)][0,1:-1]
    tvcbknots = jnp.hstack((M["tvcknots"+str(i)][0,0],M["tvcknots"+str(i)][0,-1]))  
    if M["spline_ns"]:
      tvcsplines1 = mu.vns(nodes1,tvcintknots,tvcbknots,False,False)
    elif M["spline_bs"]:
      tvcsplines1 = mu.vbs(nodes2,degree,tvcintknots,tvcbknots,False,False)
      
    M["allnodes1"] = jnp.concatenate((M["allnodes1"],M["tvc"+str(i)][:,:,None]*
                             tvcsplines1),axis=2)  
                             
## Additional info needed for 3 part method before/after boundary knots
  if not M["pyallnumint"]:
    ## jit ns2??
    if M["ttrans_log"]: 
      M["P1_upper_trans"] = jnp.log(M["P1_upper"])
      M["P3_lower_trans"] = jnp.log(M["P3_lower"])
    else:  
      M["P1_upper_trans"] = M["P1_upper"]
      M["P3_lower_trans"] = M["P3_lower"]
    
    M["splines_P1"],M["dsplines_P1"] = mu.ns(M["P1_upper_trans"][:,0],intknots,bknots,False,True) 
    M["splines_P3"],M["dsplines_P3"] = mu.ns(M["P3_lower_trans"][:,0],intknots,bknots,False,True) 

    # add tvc variables
    for i in range(1,int(M["Ntvc"])+1):
      tvcintknots = M["tvcknots"+str(i)][0,1:-1]  
      tvcbknots = jnp.hstack((M["tvcknots"+str(i)][0,0],M["tvcknots"+str(i)][0,-1]))
      if M["spline_ns"]:
        tvcsplines, dtvcsplines = mu.ns(M["P1_upper_trans"][:,0],tvcintknots,tvcbknots,False,True)
      ## add rcs here      
      
      M["splines_P1"]  = jnp.hstack((M["splines_P1"],M["tvc"+str(i)]*tvcsplines))  
      M["dsplines_P1"] = jnp.hstack((M["dsplines_P1"],M["tvc"+str(i)]*dtvcsplines)) 
                             
                             
      if M["spline_ns"]:
        tvcsplines, dtvcsplines = mu.ns(M["P3_lower_trans"][:,0],tvcintknots,tvcbknots,False,True)
      M["splines_P3"]  = jnp.hstack((M["splines_P3"],M["tvc"+str(i)]*tvcsplines))  
      M["dsplines_P3"] = jnp.hstack((M["dsplines_P3"],M["tvc"+str(i)]*dtvcsplines)) 
  
  return(M)

    
