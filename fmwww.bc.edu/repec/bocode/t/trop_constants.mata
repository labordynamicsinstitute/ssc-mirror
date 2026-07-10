/*──────────────────────────────────────────────────────────────────────────────
  trop_constants.mata

  Numerical constants and random-seed management for the TROP estimator.

  The TROP objective function involves three tuning parameters
  (lambda_time, lambda_unit, lambda_nn).  When any parameter is
  effectively infinite the corresponding penalty term vanishes:
  infinite lambda_nn removes the nuclear-norm penalty and reduces the
  model to a two-way fixed-effects specification; infinite lambda_time
  or lambda_unit sets all time or unit weights to zero except the
  treated observation itself.

  This module defines the threshold used to detect such limiting cases
  and provides a shared random-seed facility for bootstrap reproducibility.

  Contents
    _TROP_LAMBDA_INF_THRESHOLD()   infinity threshold for tuning parameters
    _TROP_LAMBDA_NN_INF_VALUE()    large finite proxy for infinite lambda_nn
    GLOBAL_RANDOM_SEED()           retrieve the stored random seed
    set_GLOBAL_RANDOM_SEED()       store or clear the random seed
──────────────────────────────────────────────────────────────────────────────*/

version 17

foreach fn in GLOBAL_RANDOM_SEED set_GLOBAL_RANDOM_SEED ///
    _TROP_LAMBDA_INF_THRESHOLD _TROP_LAMBDA_NN_INF_VALUE {
    capture mata: mata drop `fn'()
}

mata:
mata set matastrict on

/*──────────────────────────────────────────────────────────────────────────────
  _TROP_LAMBDA_INF_THRESHOLD()

  Threshold above which a tuning parameter is treated as infinite.
  Any lambda >= this value, or Stata missing, suppresses the penalty on
  the corresponding component of the objective.

  Returns:  real scalar  (1e99)
──────────────────────────────────────────────────────────────────────────────*/
real scalar _TROP_LAMBDA_INF_THRESHOLD()
{
    return(1e99)
}

/*──────────────────────────────────────────────────────────────────────────────
  _TROP_LAMBDA_NN_INF_VALUE()

  Large finite substitute for an infinite nuclear-norm parameter.
  Drives the low-rank component mu toward zero in the penalized
  least-squares objective while keeping the SVD solver numerically
  tractable.

  Returns:  real scalar  (1e10)
──────────────────────────────────────────────────────────────────────────────*/
real scalar _TROP_LAMBDA_NN_INF_VALUE()
{
    return(1e10)
}

/*──────────────────────────────────────────────────────────────────────────────
  GLOBAL_RANDOM_SEED()

  Retrieves the random seed stored in the Stata scalar TROP_GLOBAL_SEED.
  A shared seed ensures reproducibility of the bootstrap variance
  estimator across the Mata and native-code layers.

  Returns:  real scalar  -- stored seed, or missing (.) if unset
──────────────────────────────────────────────────────────────────────────────*/
real scalar GLOBAL_RANDOM_SEED()
{
    real scalar seed

    if (rows(st_numscalar("TROP_GLOBAL_SEED")) > 0) {
        seed = st_numscalar("TROP_GLOBAL_SEED")
        if (seed < .) return(seed)
    }

    return(.)
}

/*──────────────────────────────────────────────────────────────────────────────
  set_GLOBAL_RANDOM_SEED(seed)

  Stores or clears the random seed in the Stata scalar TROP_GLOBAL_SEED.
  Passing missing (.) clears the stored value.

  Arguments
    seed   real scalar  -- value to store, or missing to clear
──────────────────────────────────────────────────────────────────────────────*/
void set_GLOBAL_RANDOM_SEED(real scalar seed)
{
    if (seed >= .) {
        st_numscalar("TROP_GLOBAL_SEED", .)
    }
    else {
        st_numscalar("TROP_GLOBAL_SEED", seed)
    }
}

end
