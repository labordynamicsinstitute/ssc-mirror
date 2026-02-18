clear all
mata

ff=dir(".","files","*")
_sort(ff,1)
nf=rows(ff)
uno=J(nf,1,1)
sd = strlower(substr(ff,uno, uno))
sd,ff

for(i=1;i<=nf;i++) {
	printf("File-URL: http://fmwww.bc.edu/repec/bocode/%s/%s\n",sd[i],ff[i])
}

end
