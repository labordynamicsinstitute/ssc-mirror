* tsgraph_X.do    24jun2004 CFBaum
* Program illustrating use of tsgraph v tsline
webuse invest2, clear
tsset company time
drop if company>4
set rmsg on
tsgraph invest market stock if company==1
tsline invest market stock if company==1
* illustrate automatic use on panel
tsgraph invest, ti("Investment expenditures by firm")
set rmsg off
