program define mlad_ll
  version 16.1 
  args todo b lnf g H
  tempname gtmp Htmp
  
// Call after convergence to obtain robust variance estimates 
  if "`todo'" == "robust" {
    GetScores 
    exit
  }

// Call after convergence to drop data from Python  
  if "`todo'" == "tidy" {
    python: tidymlad(mlad)
    exit
  }  
  
// First call need to check for factor variables 
  if ${MLAD_firstcall} {
    Checkfv `b'
    
    if "$MLAD_verbose" != "" di "Setting up in Python"
    forvalues i = 1/${ML_n} {
      tempname b`i' 
      if ${MLAD_hasfv`i'} {
        _ms_eq_info, matrix(`b')
        matrix `b`i'' = `b'[1,"`r(eq`i')':"]
        _ms_extract_varlist ${ML_x`i'}, matrix(`b`i'') noomitted
        fvrevar `r(varlist)'
        global MLAD_X_eq`i' `r(varlist)'
      }    
    }

// Read data etc into Python
    python: GetInfo(mlad)
    global MLAD_firstcall 0
    if "$MLAD_verbose" != "" di "Finishing setting up in Python"
  }
  
// Extract beta matrix for each equation  
  forvalues i = 1/${ML_n} {
    tempname b`i' 
    matrix `b`i'' = `b'[1,${ML_fp`i'}..${ML_lp`i'}]
    if ${MLAD_hasfv`i'} mata: reduceb()
  }
  
// Calculate log-likelihood, gradient and Hessian in Python  
  python: calcAll(mlad,`todo')
  
// Recreate full matrices if factor variables
  if ${MLAD_hasanyfv} {  
    if `todo'>0 mata: zerostog()
    if `todo'>1 mata: zerostoH()
  }

end

// Check whether factor variables
program define Checkfv
  local b `1'
  global MLAD_hasanyfv 0
  forvalues i = 1/${ML_n} {
    tempname b`i' 

    fvexpand ${ML_x`i'}
    global MLAD_hasfv`i' = ("`r(fvops)'" == "true")
    if ${MLAD_hasfv`i'} global MLAD_hasanyfv 1
  }
  global MLAD_gname = cond(${MLAD_hasanyfv},"gtmp","g")
  global MLAD_Hname = cond(${MLAD_hasanyfv},"Htmp","H")
end

// get scores to calculate robust standard errors
program define GetScores
  _ms_eq_info
  forvalues i = 1/`e(k_eq)' {
    tempname b`i'
    tempvar eq`i'
    quietly gen double `eq`i'' = .
    local eqlist `eqlist' `eq`i''
    matrix `b`i'' = e(b)[1,"`r(eq`i')':"]
  }
  tempvar touse
  gen byte `touse' = e(sample)
  python: scores_to_stata()

  if ${MLAD_hasid} local cluster cluster(${MLAD_idvar})
  _robust `eqlist', `cluster'
end

/////////////////
/// MATA CODE ///
/////////////////
version 16.1
mata:
void function reduceb()
{
  eq = st_local("i")
  bname = st_local("b" + eq)
  b  = st_matrix(bname)
  stata("_ms_omit_info " + bname)
  omit = st_matrix("r(omit)")
  st_matrix(bname,select(b,1:-omit))
}

void function zerostog() {
  stata("_ms_omit_info " + st_local("b"))
  omit = st_matrix("r(omit)")
  newg = J(1,strtoreal(st_global("ML_k")),0)
  newg[selectindex(1:-omit)] = st_matrix(st_local("gtmp"))
  st_matrix(st_local("g"),newg)
}

void function zerostoH() {
  omit = st_matrix("r(omit)")
  Nk = strtoreal(st_global("ML_k"))
  newH = J(Nk,Nk,0)
  nonzeros = selectindex(1:-omit)
  newH[nonzeros,nonzeros] = st_matrix(st_local("Htmp"))
  st_matrix(st_local("H"),newH)
}
end

///////////////////
/// PYTHON CODE ///
///////////////////
version 16.1
python:
import importlib
from sfi import Data, Macro, Scalar, Matrix
import numpy as np
import jax.numpy as jnp 
from jax import grad, jit, jacrev, jacfwd, hessian, vmap, jvp
from jax.config import config

import mladutil as mu
## need double precision
config.update("jax_enable_x64", True)

## load likelhood function
ll_filename = Macro.getGlobal("MLAD_llfile")
ll = importlib.import_module(ll_filename)
ll = importlib.reload(ll)

## mlad class
class mlad:
  'mlad class'
  pass
  
###############################
### Load initial infomation ###
###############################
def GetInfo(mlad):
  ## General inform  ation
  mlad.N_equations   = int(Macro.getGlobal("ML_n"))
  N_parameters       = int(Macro.getGlobal("ML_k"))
  Nobs               = int(float(Macro.getGlobal("ML_N")))
  mlad.hasjit        = int(Macro.getGlobal("MLAD_hasjit"))
  mlad.touse         = Macro.getGlobal("ML_sample")
  mlad.hasscalars    = int(Macro.getGlobal("MLAD_hasscalars"))
  mlad.hasmatrices   = int(Macro.getGlobal("MLAD_hasmatrices"))
  mlad.hasstatics    = Macro.getGlobal("MLAD_staticscalars") != ""
  mlad.haspygradient = int(Macro.getGlobal("MLAD_haspygradient")) 
  mlad.haspyhessian  = int(Macro.getGlobal("MLAD_haspyhessian")) 
  matrices           = Macro.getGlobal("MLAD_matrices")
  scalars            = Macro.getGlobal("MLAD_scalars")
  mlad.hasid         = int(Macro.getGlobal("MLAD_hasid"))
  mlad.gname         = Macro.getGlobal("MLAD_gname")
  mlad.Hname         = Macro.getGlobal("MLAD_Hname")
  setupfile          = Macro.getGlobal("MLAD_setupfile")
  hassetup           = setupfile != ""
  hasmatnames        = Macro.getGlobal("MLAD_matnames") != ""
  hessian_adtype     = Macro.getGlobal("MLAD_hessian_adtype") 
  
  if(mlad.hasid): mlad.idvar = (Macro.getGlobal("MLAD_idvar"))
  
  ## Check if has factor variables, nocons or offset
  hasfv     = []
  hascons   = []
  hasoffset = []
  varnames  = []
  mlad.Nvarnames = []

  for i in range(mlad.N_equations):
    hasfv.append(int(Macro.getGlobal("MLAD_hasfv"+str(i+1))))
    hascons.append((Macro.getGlobal("ML_xc"+str(i+1))==""))
    hasoffset.append(((Macro.getGlobal("ML_xo"+str(i+1))!="")))
    if(hasfv[i]): varnames.append(Macro.getGlobal("MLAD_X_eq"+str(i+1)).split()) 
    else: varnames.append(Macro.getGlobal("ML_x"+str(i+1)).split()) 
  
  X = [0]*(mlad.N_equations+1)
  X[0] = []

  for i in range(mlad.N_equations):
    if hasoffset[i]: X[0].append(jnp.asarray(np.asarray(Data.get(Macro.getGlobal("ML_xo"+str(i+1)),selectvar=mlad.touse,missingval=jnp.nan)))[:,None])
    else: X[0].append(0)

    if(len(varnames[i])>0 or not hascons[i]):
      for v in range(len(varnames[i])):
        if v==0: X[i+1] = jnp.asarray(np.asarray([Data.get(varnames[i][v],selectvar=mlad.touse,missingval=jnp.nan)]))
        else: X[i+1] = jnp.vstack((X[i+1],jnp.asarray(np.asarray(Data.get(varnames[i][v],selectvar=mlad.touse,missingval=jnp.nan)))))
      if hascons[i]: X[i+1] = jnp.vstack((X[i+1],jnp.ones((1,X[i+1].shape[1]))))
    else: X[i+1] =  jnp.ones((1,Nobs))
    X[i+1] = X[i+1].T


  ## function arguments (beta,X, wt, M, staticscalars]
  mlad.like_fn_args = [[[0]]*mlad.N_equations]
  mlad.like_fn_args.append(X)
  X = None
  
  ## weights
  mlad.like_fn_args.append(jnp.asarray(np.asarray(Data.get(Macro.getGlobal("ML_w"),selectvar=mlad.touse,missingval=jnp.nan)))[:,None])

  ## Additional variables
  mlad.OtherVars = Macro.getGlobal("MLAD_othervars").split()
  mlad.OtherVarnames  = Macro.getGlobal("MLAD_othervarnames").split()
  mlad.Nothervars = len(mlad.OtherVars)
  M = {}
  for v in range(mlad.Nothervars):
    M[mlad.OtherVarnames[v]] = jnp.asarray(np.asarray(Data.get(mlad.OtherVars[v],selectvar=mlad.touse,missingval=jnp.nan)))[:,None]
  
  ## ID variable  
  if(mlad.hasid):
    ##mlad.like_fn_args.append(jnp.asarray((np.asarray(Data.get(mlad. ,selectvar=mlad.touse,missingval=jnp.nan),dtype='int32'))))
    M["id"] = jnp.asarray((np.asarray(Data.get(mlad.idvar,selectvar=mlad.touse,missingval=jnp.nan),dtype='int32')))

  ## matrices ##
  if(mlad.hasmatrices):
    mlad.MatrixList = Macro.getGlobal("MLAD_matrices").split()
    mlad.matnames = Macro.getGlobal("MLAD_matnames").split()
    for i in range(len(mlad.MatrixList)):
      M[mlad.matnames[i]] = jnp.asarray(np.asarray(Matrix.get(mlad.MatrixList[i])))

  ## scalars
  if(mlad.hasscalars):
    mlad.ScalarList = Macro.getGlobal("MLAD_scalars").split()
    mlad.ScalarNames = Macro.getGlobal("MLAD_scalarnames").split()
    for i in range(len(mlad.ScalarList)):
      M[mlad.ScalarNames[i]] =   (Scalar.getValue(mlad.ScalarList[i]))
  mlad.like_fn_args.append(M)
      
  if(mlad.hasstatics):
    mlad.StaticList = Macro.getGlobal("MLAD_staticscalars").split()
    for i in range(len(mlad.StaticList)):
      mlad.like_fn_args.append((Scalar.getValue(mlad.StaticList[i])))
  
    sa_start = 4
    staticargs = range(sa_start,sa_start+len(mlad.StaticList))
  else: staticargs = []
  

  ## likelihood 
  if(mlad.hasjit): mlad.python_ll = jit(ll.python_ll,static_argnums=(staticargs))  
  else:            mlad.python_ll = ll.python_ll  
  
  ## Obtain gradient of each equation
  if(mlad.haspygradient): mlad.grad_fn = ll.python_grad
  else: mlad.grad_fn = grad(ll.python_ll)
  if(mlad.hasjit): mlad.grad_fn = jit(mlad.grad_fn,static_argnums=(staticargs))

  ## Obtain equation contribution to Hessian
  if(mlad.haspyhessian): 
    mlad.H_fn = ll.python_hessian
  else:
    if(hessian_adtype == "revrev"):   mlad.H_fn = jacrev(jacrev(ll.python_ll))
    elif(hessian_adtype == "revfwd"): mlad.H_fn = jacfwd(jacrev(ll.python_ll))
    elif(hessian_adtype == "fwdfwd"): mlad.H_fn = jacfwd(jacfwd(ll.python_ll))
    elif(hessian_adtype == "fwdrev"): mlad.H_fn = jacrev(jacfwd(ll.python_ll))
  if(mlad.hasjit): mlad.H_fn = jit(mlad.H_fn,static_argnums=(staticargs))

  if(hassetup):
    setup = importlib.import_module(setupfile)
    setup = importlib.reload(setup)
    setup.mlad_setup(M)

#########################################################
### Calculations of likelihood, gradients and Hessian ###
#########################################################

#########################################################
### calcAll                                           ###
#########################################################
def calcAll(mlad,todo):
  loadBetas(mlad)
  lnf = mlad.python_ll(*mlad.like_fn_args)
  if(todo>0):  g = jnp.hstack(mlad.grad_fn(*mlad.like_fn_args))[None,:]
  if(todo==2): 
    if(mlad.haspyhessian): H = mlad.H_fn(*mlad.like_fn_args)
    else: H = StackH(mlad,mlad.H_fn(*mlad.like_fn_args))
    
  ##Store results
  Scalar.setValue(Macro.getLocal("lnf"),lnf)
  if(todo>0):  Matrix.store(Macro.getLocal(mlad.gname),g)
  if(todo==2): Matrix.store(Macro.getLocal(mlad.Hname),H)  

def StackH(mlad,H):
  for i in range(mlad.N_equations):
    if(i==0): retH = jnp.hstack(H[0])
    else: retH=jnp.vstack((retH,jnp.hstack(H[i])))
  return(retH)

##########################################################
### Load betas                                         ###
##########################################################
def loadBetas(mlad):
  for i in range(mlad.N_equations): 
    mlad.like_fn_args[0][i] = jnp.asarray(np.asarray(Matrix.get(Macro.getLocal("b"+str(i+1)),rows=0),dtype="float64"))
 
  
##########################################################
### Scores to Stata                                    ###
##########################################################
def scores_to_stata():
  loadBetas(mlad)
  ## get predicted values for each equation
  
  allxb = [0]*mlad.N_equations

  for i in range(mlad.N_equations): 
    allxb[i] = (mu.linpred(mlad.like_fn_args[0],mlad.like_fn_args[1],i+1))
  
  mlad.like_fn_args[0] = jnp.asarray(allxb)[:,:,-1]

  ## replace X with a 1 for each equation
  for i in range(mlad.N_equations): 
    mlad.like_fn_args[1][i+1] = 1
  
  gradj = grad(ll.python_ll)
  if(mlad.hasjit): gradj = jit(gradj)
  scores = gradj(*mlad.like_fn_args)
  
  #loop over equations to save to Stata
  for i in range(mlad.N_equations): 
    Data.store(Macro.getLocal("eq"+str(i+1)),None,scores[i][:,None],Macro.getLocal("touse"))
  
##########################################################
### delete stuff                                       ###
##########################################################
def tidymlad(mlad):
  mlad.X            = None
  mlad.N_equations  = None
  mlad.Nothervars   = None
  mlad.OtherVars    = None
  mlad.hasid        = None
  mlad.hasscalars   = None
  mlad.hasmatrices  = None
  mlad.hasjit       = None
  mlad.like_fn_args = None
  mlad.Nscalars     = None
  mlad.Nmatrices    = None
  mlad.python_ll    = None
  mlad.grad_fn      = None
  mlad.H_fn         = None
  mlad.gname        = None
  mlad.Hname        = None
  
end






