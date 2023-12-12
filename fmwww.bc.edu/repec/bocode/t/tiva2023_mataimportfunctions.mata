mata:
	// Import matrices as pointers
	pointer(matrix) vector tiva2023::_import_asPointer(string scalar myMMAT) {
		fh = fopen(myMMAT, "r")
		names = fgetmatrix(fh)
		p = J(length(names)+1, 1, NULL)
		p[1] = &names
		for(i=2; i<=length(names)+1; i++){
			p[i] = &fgetmatrix(fh)
			}
		
		fclose(fh)
		return(p)
		}
	
	// Import matrices as global variables usable in mata
	void tiva2023::_import_asExternal(pointer vector p) {
		transmorphic matrix isnew
		for (i = 2; i<= length(p); i++) {
			rmexternal((*p[1])[i-1])
			isnew = crexternal((*p[1])[i-1])
			swap(*isnew, *p[i])
			printf("%s: %s %s of size [%g, %g] \n",	///
			  (*p[1])[i-1],									///
			  eltype(*isnew),									///
			  orgtype(*isnew),								///
			  rows(*isnew),									///
			  cols(*isnew))
			}
		}
	
	// function that uses the function _import_asExternal to load
	// all matrices
	void tiva2023::load(string scalar path) {
		_import_asExternal(_import_asPointer(path+"_dimensions.mmat"))
		_import_asExternal(_import_asPointer(path+"_descriptions.mmat"))
		_import_asExternal(_import_asPointer(path+"_ICIO.mmat"))
		_import_asExternal(_import_asPointer(path+"_index.mmat"))
		_import_asExternal(_import_asPointer(path+"_transitions.mmat"))
		_import_asExternal(_import_asPointer(path+"_ew_multiplications.mmat"))
		}
	
end
