log using mcmclinear.log, replace

/* version 1.0, 5 jan 2012 */
/* sam schulhofer-wohl, federal reserve bank of minneapolis */

version 12.0

mata: mata mlib create lmcmclinear, replace

foreach f in mcmclinear_reg mcmclinear_mixed {
  do `f'.mata
  mata: mata mlib add lmcmclinear `f'()
  }

mata: mata mlib index


log close
exit
