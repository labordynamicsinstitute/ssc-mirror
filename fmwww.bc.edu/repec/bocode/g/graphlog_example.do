preserve
capture log close examplelog
log using examplelog.log, replace name(examplelog)
sysuse auto, clear
summarize length
scatter length trunk, name(examplegraph)
pwd
graph export examplegraph.pdf, name(examplegraph) replace
graph drop examplegraph
log close examplelog
graphlog using examplelog.log, papersize(letter) fontsize(12) marginsize(0.6) openpdf replace
restore