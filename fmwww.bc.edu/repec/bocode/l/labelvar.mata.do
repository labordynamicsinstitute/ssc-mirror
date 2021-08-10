version 10
mata:
mata clear
void function Labelvar(string scalar listvar, string scalar listdes)
{

 /* Parsing relevant strings */

 t = tokeninit("", "#", (`""""', `"`""'"'), 0, 0)
 tokenset(t, st_local(listvar))
 listvarT = tokengetall(t)
 tokenset(t, st_local(listdes))
 descriptorT = tokengetall(t)

 /* get variables  */

 for (i=1;i<=cols(listvarT);i++) {
  if (i==1) variables = strtrim(listvarT[i])
  if (i>1 & listvarT[i]!="#") variables = (variables,strtrim(listvarT[i]))  
 }
 // comma = `"""'
 // for (i=1;i<=cols(variables);i++) {
 //  labels[i] = comma+labels[i]+comma
 // }

 /* get descriptors */

 for (i=1;i<=cols(descriptorT);i++) {
  if (i==1) descriptor = strtrim(descriptorT[i])
  if (i>1 & descriptorT[i]!="#") descriptor = (descriptor,strtrim(descriptorT[i]))  
 }
 comma = `"""'
 for (i=1;i<=cols(descriptor);i++) {
  descriptor[i] = comma+descriptor[i]+comma
 }

 /* Create labels definitions in Stata */

 for (i=1;i<=cols(variables);i++) {
  stata("capture su" + " " + variables[i])
  stata("scalar inlist=_rc")
  inlist=st_numscalar("inlist")
  if (inlist==0) {
   stata("label var" +" "+ variables[i]+" "+  descriptor[i])
  }
 }
}
mata mosave Labelvar(), dir(PERSONAL) replace
mata clear
end
