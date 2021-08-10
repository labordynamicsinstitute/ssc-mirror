version 10
mata:
mata clear
void function Labels_v2(string scalar labelsS, string scalar valuesS, string scalar lname, string scalar vtype)
{

 /* declarations */

 string matrix labels, values
 string scalar comma

 /* Parsing relevant strings */

 t = tokeninit("", "#", (`""""', `"`""'"'), 0, 0)
 tokenset(t, st_local(labelsS))
 labelsT = tokengetall(t)
 tokenset(t, st_local(valuesS))
 valuesT = tokengetall(t)

 /* get labels */

 labels = J(1,1,"")
 for (i=1;i<=cols(labelsT);i++) {
  if (i==2) labels = strtrim(labelsT[i])
  if (i>2 & labelsT[i]!="#") labels = (labels,strtrim(labelsT[i]))  
 }
 comma = `"""'
 for (i=1;i<=cols(labels);i++) {
  labels[i] = comma+labels[i]+comma
 }

 /* get values */

 valuesR = J(1,1,"")
 for (i=1;i<=cols(valuesT);i++) {
  if (i==2) valuesR = strtrim(valuesT[i])
  if (i>2 & valuesT[i]!="#") valuesR = (valuesR,strtrim(valuesT[i])) 
 }
 values = strtoreal(valuesR)
 for (i=1;i<=cols(valuesR);i++) {
 if (values[i]==.) values[i] = J(1,1,8800)+J(1,1,i)
 }
 for (i=1;i<=cols(valuesR);i++) {
  valuesR[i] = comma+valuesR[i]+comma
 }

 /* Create a verctor with new values as strings */

 valuesNS = strofreal(values)
  for (i=1;i<=cols(valuesNS);i++) {
  valuesNS[i] = comma+valuesNS[i]+comma
 }

 /* Replace values in data */ 
 
 if (vtype=="s") {
  /* trim string values in data */
  stata("qui replace "+lname+" = "+"rtrim("+lname+")")
  /* deal with blank records */
  stata("qui replace "+lname+" = "+comma+"9985"+comma+" if "+lname+"=="+comma+comma)
  stata("label def "+" "+lname+" "+"9985"+" "+comma+"Blank in data"+comma+", add") 
  /* replace new values in data */
  for (i=1;i<=cols(valuesR);i++) {
   stata("qui replace"+" "+lname+"="+valuesNS[i]+" if "+" "+lname+"=="+valuesR[i])
  }
  stata("qui destring "+lname+ ", replace")
 }

 /* reverse substitution --- variable is writen in data as label string description */ 

if (vtype=="rev") {
  /* trim string values in data */
  stata("qui replace "+lname+" = "+"rtrim("+lname+")")
  /* deal with blank records */
  stata("qui replace "+lname+" = "+comma+"9985"+comma+" if "+lname+"=="+comma+comma)
  stata("label def "+" "+lname+" "+"9985"+" "+comma+"Blank in data"+comma+", add") 
  /* replace new values in data */
  for (i=1;i<=cols(valuesR);i++) {
   stata("qui replace"+" "+lname+"="+valuesNS[i]+" if "+" "+lname+"=="+labels[i])
  }
  stata("qui destring "+lname+ ", replace")
 }

 /* Create labels definitions in Stata */

 for (i=1;i<=cols(labels);i++) {
  stata("label def" +" "+lname+" "+strofreal(values[i])+" "+ labels[i]+", add")
 }
 /* label values */
 stata("label val "+lname+" "+lname)
}
mata mosave Labels_v2(), dir(PERSONAL) replace
mata clear
end
