*!28jun 2015
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program models
version 11

mata: DoIt()
end


version 11
mata:
void DoIt() { //>>def func
	external pointer (class models scalar) scalar el_models //bug:external class creates pointer, for which the declaration is wrong
	if (el_models==NULL) el_models=&(models()) //a null pointer, above, needs an instance...
	
	cmd=expand(tokel(st_local("0"),(" "\","),"",comma,1),2)
	cmd[2]=cut(comma,-1)+cmd[2]
	syntaxl(cmd[2],&(label="anything"),NULL,opts="")

	if (cmd[1]=="clear") el_models=&(models())
	else if (cmd[1]=="add") el_models->add(label)
	else if (cmd[1]=="label") el_models->label(cmd[2])
	else if (cmd[1]=="display") el_models->present(opts)
	else if (cmd[1]=="all") {
		el_models=&(models())
		el_models->add(label)
		el_models->present(opts)
		}
	}
end
