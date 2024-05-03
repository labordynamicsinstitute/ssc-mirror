*! version 1.2 2024-05-01
program define mlad_ll
  version 16.1 
  args todo b lnf g H
  tempname btmp gtmp Htmp

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
    
    if ($MLAD_verbose) di "Setting up in Python"
    forvalues i = 1/${ML_n} {
      tempname b`i' 
      if ${MLAD_hasfv`i'} {
        _ms_eq_info, matrix(`b')
        matrix `b`i'' = `b'[1,"`r(eq`i')':"]
        _ms_extract_varlist ${ML_x`i'}, matrix(`b`i'') noomitted
        mlad_add_bn "`r(varlist)'"  
        fvrevar `r(varlist)'
        ////global MLAD_Nparams `Nparams' `=wordcount("`r(varlist)'")'
        global MLAD_X_eq`i' `r(varlist)'
      }    
    }
  }
  
// Extract beta matrix for each equation  
  if (!${MLAD_allbetas}) {
    forvalues i = 1/${ML_n} {
      tempname b`i' 
      matrix `b`i'' = `b'[1,${ML_fp`i'}..${ML_lp`i'}]
      if ${MLAD_hasfv`i'} mata: reduceb()
    }
  }
  else {
    matrix `btmp' = `b'
    if ${MLAD_hasanyfv} mata: reduceb()
  }    
  
// Setup on first call 
//  -- optionally run set llsetup
//  --  read data, initial betas, scalaras, matrices etc into Python on first call
  if ${MLAD_firstcall} {
    if "$MLAD_llsetup" != "" {
      mata: ${MLAD_llsetup}()
    }
    python: GetInfo(mlad)
    global MLAD_firstcall 0
    if (${MLAD_pyoptimize}) {
      tempvar btomata
      mata: zerostob()
      mata: _MLM1.S.params = st_matrix(st_local("btomata"))
    }
    if (${MLAD_verbose}) di "Finishing setting up in Python"
    if (${MLAD_verbose}) di "Fitting model"
  }
  
  
// Calculate log-likelihood, gradient and Hessian in Python
  python: calcAll(mlad,`todo')

// Recreate full matrices if factor variables
  if ${MLAD_hasanyfv} {  
    if `todo'>0 mata: zerostog()
    if `todo'>1 mata: zerostoH()
  }

  if $MLAD_minlike {
    scalar `lnf' = -`lnf'
    if `todo'>0 matrix `g' = -`g'
    if `todo'>1 matrix `H' =- `H'
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
  if (!${MLAD_allbetas}) {
    _ms_eq_info
    forvalues i = 1/`e(k_eq)' {
      tempname b`i'
      tempvar eq`i'
      quietly gen double `eq`i'' = .
      local eqlist `eqlist' `eq`i''
      _ms_eq_info
      matrix `b`i'' = e(b)[1,"`r(eq`i')':"]
      if ${MLAD_hasfv`i'} mata: reduceb()
    }
  }
  else {
    tempname btmp
    matrix `btmp' = e(b)
    if ${MLAD_hasanyfv} mata: reduceb()    
  }
  tempvar touse
  gen byte `touse' = e(sample)

  if "$MLAD_scoretype"=="equation" {
    python: scores_to_stata_equation(mlad)
    if ${MLAD_hasid} local cluster cluster(${MLAD_idvar})
    _robust `eqlist', `cluster'    
  }
  else if "$MLAD_scoretype"=="direct" {
    tempname Vreduce
    mata: reduceV()
    python: scores_to_stata_direct(mlad)
    if ${MLAD_hasid} local cluster cluster(${MLAD_idvar})
    RepostV , newv(`Vreduce') `cluster'
  }

end

program define RepostV, eclass
  syntax , newv(string) [cluster(string)]
  tempname vcopy
  matrix `vcopy' = e(V)
  ereturn matrix V_modelbased = `vcopy'
  ereturn repost V = `newv'

  if "`cluster'" != "" {
    ereturn local vce cluster
    ereturn local clustvar ${MLAD_idorig}
    ereturn scalar N_clust = ${MLAD_Nid}
  }
  else ereturn local vce robust
  
  
  
  ereturn local vcetype "Robust"
end

program define mlad_add_bn, rclass
  foreach v in `1' {
    _ms_parse_parts `v'
    if "`r(type)'" == "variable" {
      local varlist `varlist' `v'
      continue
    }
    else if "`r(type)'" == "interaction" {
      local vtmp `v'
      forvalues k = 1/`r(k_names)' {
        
        capture confirm integer number `r(op`k')'
        if !_rc local vtmp = subinstr("`vtmp'","`r(op`k')'.","`r(op`k')'bn.",.)
      }
      local varlist `varlist' `vtmp'
    }
    else {
      local vtmp = subinstr("`v'",".","bn.",.)
      local varlist `varlist' `vtmp'
    }
  }
  return local varlist `varlist' 
end


/////////////////
/// MATA CODE ///
/////////////////
version 16.1
mata:

// remove zeros from beta matrix
void function reduceb()
{
  allbetas = strtoreal(st_global("MLAD_allbetas"))

  if(allbetas) {
    eq = "" 
    bname = st_local("btmp")
  }
  else {
    eq = st_local("i")
    bname = st_local("b" + eq)
  }
  b  = st_matrix(bname)
  stata("_ms_omit_info " + bname)
  omit = st_matrix("r(omit)")
  st_matrix(bname,select(b,1:-omit))
}

// remove zeros from variance matrix
void function reduceV()
{
  V = st_matrix("e(V)")
  stata("_ms_omit_info e(b)")
  omit = st_matrix("r(omit)")
  Vname = st_local("Vreduce")
  inc = selectindex(1 :- omit)
  st_matrix(Vname,V[inc,inc])
}



// Add back zeros to b vector if factor variables
void function zerostob() {
  stata("_ms_omit_info " + st_local("b"))
  omit = st_matrix("r(omit)")
  newb = J(1,strtoreal(st_global("ML_k")),0)
  newb[selectindex(1:-omit)] = st_matrix(st_local("btmp"))
  st_matrix(st_local("btomata"),newb)
}

// Add back zeros to g vector if factor variables
void function zerostog() {
  stata("_ms_omit_info " + st_local("b"))
  omit = st_matrix("r(omit)")
  newg = J(1,strtoreal(st_global("ML_k")),0)
  newg[selectindex(1:-omit)] = st_matrix(st_local("gtmp"))
  st_matrix(st_local("g"),newg)
}

// Add back zeros to H matrix if factor variables
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
## Need double precision
import jax
jax.config.update("jax_enable_x64", True)

## import modules
import importlib
from sfi import Data, Macro, Scalar, Matrix
import numpy as np
import jax.numpy as jnp 
from jax import grad, jit, jacrev, jacfwd, hessian, vmap
from jaxopt import ScipyMinimize, BFGS, LBFGS, GradientDescent
from jax.numpy.linalg import inv
from scipy.optimize import minimize
import mladutil as mu

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
  ## General information
  mlad.N_equations   = int(Macro.getGlobal("ML_n"))

  Nobs               = int(float(Macro.getGlobal("ML_N")))
  mlad.hasjit        = int(Macro.getGlobal("MLAD_hasjit"))
  mlad.touse         = Macro.getGlobal("ML_sample")
  mlad.hasscalars    = int(Macro.getGlobal("MLAD_hasscalars"))
  mlad.hasmatrices   = int(Macro.getGlobal("MLAD_hasmatrices"))
  mlad.hasstatics    = Macro.getGlobal("MLAD_staticscalars") != ""
  mlad.haspygradient = int(Macro.getGlobal("MLAD_haspygradient")) 
  mlad.haspyhessian  = int(Macro.getGlobal("MLAD_haspyhessian")) 
  mlad.pyoptimize    = int(Macro.getGlobal("MLAD_pyoptimize")) 
  mlad.allbetas      = int(Macro.getGlobal("MLAD_allbetas"))
  mlad.verbose       = int(Macro.getGlobal("MLAD_verbose"))
  matrices           = Macro.getGlobal("MLAD_matrices")
  scalars            = Macro.getGlobal("MLAD_scalars")
  mlad.hasid         = int(Macro.getGlobal("MLAD_hasid"))
  mlad.gname         = Macro.getGlobal("MLAD_gname")
  mlad.Hname         = Macro.getGlobal("MLAD_Hname")
  setupfile          = Macro.getGlobal("MLAD_pysetupfile")
  hassetup           = setupfile != ""
  hasmatnames        = Macro.getGlobal("MLAD_matnames") != ""
  hessian_adtype     = Macro.getGlobal("MLAD_hessian_adtype") 
  
  mlad.tol = jnp.array([0.01])
  mlad.pymax_iter = 12
  
  if(mlad.hasid): mlad.idvar = (Macro.getGlobal("MLAD_idvar"))
  
  ## Check if has factor variables, nocons or offset
  hasfv            = []
  hascons          = []
  hasoffset        = []
  varnames         = []
  mlad.Nvarnames   = []

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
  mlad.like_fn_args = []
  if mlad.allbetas:
    mlad.like_fn_args.append(jnp.asarray(np.asarray(Matrix.get(Macro.getLocal("btmp"),rows=0),dtype="float64")))
  else:
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
    mlad.staticargs = range(sa_start,sa_start+len(mlad.StaticList))
  else: mlad.staticargs = []
  
  ## Other info (Number of parameters) - could add
  M["Nparameters"] = []
  for i in range(mlad.N_equations):
    M["Nparameters"].append(int(Macro.getGlobal("ML_k"+str(i+1))))
  mlad.Nparameters = M["Nparameters"]

  ## likelihood 
  if(mlad.hasjit): mlad.python_ll = jit(ll.python_ll,static_argnums=(mlad.staticargs)) 
  else:            mlad.python_ll = ll.python_ll  
  
  ## Obtain gradient of each equation
  if(mlad.haspygradient): mlad.grad_fn = ll.python_grad
  else: mlad.grad_fn = grad(ll.python_ll)
  if(mlad.hasjit): mlad.grad_fn = jit(mlad.grad_fn,static_argnums=(mlad.staticargs))

  ## Obtain Hessian matrix
  if(mlad.haspyhessian): 
    mlad.H_fn = ll.python_hessian
  else:
    if(hessian_adtype   == "revrev"): mlad.H_fn = jacrev(jacrev(ll.python_ll))
    elif(hessian_adtype == "revfwd"): mlad.H_fn = jacfwd(jacrev(ll.python_ll))
    elif(hessian_adtype == "fwdfwd"): mlad.H_fn = jacfwd(jacfwd(ll.python_ll))
    elif(hessian_adtype == "fwdrev"): mlad.H_fn = jacrev(jacfwd(ll.python_ll))
  if(mlad.hasjit): mlad.H_fn = jit(mlad.H_fn,static_argnums=(mlad.staticargs))

  if(hassetup):
    if mlad.verbose: print("Running Python model setup file")
    setup = importlib.import_module(setupfile)
    setup = importlib.reload(setup)
    setup.mlad_setup(M)
    
  if(mlad.pyoptimize):
    #mlad.like_fn_args[0] = mu.NewtonRaphson(mlad)
    #Matrix.store(Macro.getLocal("btmp"),jnp.array(mlad.like_fn_args[0],ndmin=2))
    pysolve = minimize(mlad.python_ll,mlad.like_fn_args[0],
              args=tuple(mlad.like_fn_args[1:]),
              method="BFGS",jac=mlad.grad_fn, hess=mlad.H_fn,
              options={"gtol": 1e-3, "disp": mlad.verbose})
    mlad.like_fn_args[0] = pysolve.x[None,:]
    Matrix.store(Macro.getLocal("btmp"),jnp.array(mlad.like_fn_args[0],ndmin=2))

#########################################################
### Calculations of likelihood, gradients and Hessian ###
#########################################################

#########################################################
### calcAll                                           ###
#########################################################
def calcAll(mlad,todo):
  loadBetas(mlad)
  lnf,g,H = calc_ll_g_H(mlad,todo)

  ## Store results
  Scalar.setValue(Macro.getLocal("lnf"),lnf)
  if(todo>0):  Matrix.store(Macro.getLocal(mlad.gname),g)
  if(todo==2): Matrix.store(Macro.getLocal(mlad.Hname),H)  

##########################################################
### Calculation of lnf, g and H                        ###
##########################################################  
def calc_ll_g_H(mlad,todo):
  lnf = mlad.python_ll(*mlad.like_fn_args)
  if(todo>0):  
    g = jnp.hstack(mlad.grad_fn(*mlad.like_fn_args))[None,:]
  else: g = None
  if(todo==2): 
    if(mlad.haspyhessian): H = mlad.H_fn(*mlad.like_fn_args)
    else: H = StackH(mlad,mlad.H_fn(*mlad.like_fn_args))
  else: H=None
  return(lnf,g,H)

##########################################################
### Stack H                                            ###
##########################################################  
def StackH(mlad,H):
  if mlad.allbetas: return(H)
  for i in range(mlad.N_equations):
    if(i==0): retH = jnp.hstack(H[0])
    else: retH=jnp.vstack((retH,jnp.hstack(H[i])))
  return(retH)  
  
##########################################################
### Load betas from Stata                              ###
##########################################################
def loadBetas(mlad):
  if mlad.allbetas:
    mlad.like_fn_args[0] = jnp.asarray(np.asarray(Matrix.get(Macro.getLocal("btmp"),rows=0),dtype="float64"))
  else:
    for i in range(mlad.N_equations): 
      mlad.like_fn_args[0][i] = jnp.asarray(np.asarray(Matrix.get(Macro.getLocal("b"+str(i+1)),rows=0),dtype="float64"))
 
  
##########################################################
### Scores to Stata - equation level derivatives       ###
##########################################################
def scores_to_stata_equation(mlad):
  loadBetas(mlad)
  ## get predicted values for each equation
  
  if(mlad.allbetas): 
    beta  = mu.beta_tolist(mlad.like_fn_args[0],mlad.like_fn_args[1])
  else: 
    beta = mlad.like_fn_args[0]
  allxb = [0]*mlad.N_equations
  for i in range(mlad.N_equations): 
    allxb[i] = (mu.linpred(beta,mlad.like_fn_args[1],i+1))

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
### Scores to Stata - direct calculation               ###
##########################################################
def scores_to_stata_direct(mlad):
  M = mlad.like_fn_args[3]
  loadBetas(mlad)
  ## get predicted values for each equation
  
  if(mlad.allbetas): 
    beta  = mu.beta_tolist(mlad.like_fn_args[0],mlad.like_fn_args[1])
  else: 
    beta = mlad.like_fn_args[0]
  
  gradfn = jacrev(ll.python_lli)
  if(mlad.hasjit): gradfn = jit(gradfn,static_argnums=(mlad.staticargs))
  
  if(mlad.allbetas):
    gradj = gradfn(*mlad.like_fn_args)[:,0,:]
  else:
    gradj = jnp.concatenate(gradfn(*mlad.like_fn_args),axis=2)[:,0,:]

  V = jnp.asarray(np.asarray(Matrix.get(Macro.getLocal("Vreduce")),dtype="float64"))
  
  if(mlad.hasid):
    uniqueid = jnp.unique(M["id"])
    Np = gradj.shape[1]
    D = jnp.zeros((Np,Np))
    for i in uniqueid:
      U = gradj[M["id"]==i,:]
      Nu = U.shape[0]
      D = D + np.dot(jnp.transpose(U),U)*(Nu/(Nu-1))
    NewV = V@D@V
  else:
    NewV = V@(jnp.dot(jnp.transpose(gradj),gradj))@V
  
  
  N=gradj.shape[0]
  NewV = NewV*(N/(N-1))
  Matrix.store(Macro.getLocal("Vreduce"),NewV)
  
 
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
  mlad.pyupdates    = None
  
end






