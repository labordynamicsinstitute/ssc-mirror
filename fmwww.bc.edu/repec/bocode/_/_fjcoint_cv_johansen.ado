*! _fjcoint_cv_johansen.ado
*! 5% critical values for standard Johansen Trace test
*! Source: Johansen (1991), Johansen & Juselius (1990)
*! Part of fjcoint package

program define _fjcoint_cv_johansen, rclass
  version 14.0
  
  args model m
  
  * model: 1=None, 2=RC, 3=Unrestricted constant, 4=RT, 5=Unrestricted trend
  * m: number of variables
  
  if `m' < 1 | `m' > 6 {
    di as err "number of variables must be between 1 and 6"
    exit 198
  }
  
  if `model' < 1 | `model' > 5 {
    di as err "model must be between 1 and 5"
    exit 198
  }
  
  tempname cv_trace
  
  * 5% critical values of Trace test
  * Columns: r=1 to r=6
  * Rows: model 1 to 5
  matrix `cv_trace' = ( ///
    4.157,  12.271,  24.116,  39.977,  59.682,  83.424 \ ///
    9.133,  20.264,  35.060,  53.750,  76.447, 103.126 \ ///
    3.860,  15.465,  29.701,  47.559,  69.362,  94.989 \ ///
   12.500,  25.760,  42.682,  63.455,  87.999, 116.611 \ ///
    3.852,  18.223,  34.825,  54.812,  78.599, 106.395 )
  
  * Extract values for this model (reversed order: m, m-1, ..., 1)
  tempname cv_out
  matrix `cv_out' = J(1, `m', .)
  forvalues i = 1/`m' {
    matrix `cv_out'[1, `i'] = `cv_trace'[`model', `m' - `i' + 1]
  }
  
  return matrix cv_trace = `cv_out'
  
end
