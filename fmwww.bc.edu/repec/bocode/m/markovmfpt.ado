*! 1.0.0 Ariel Linden 01Jul2025 

* Markov chain mean first passage time (MFPT)
program markovmfpt, rclass
		version 11.0
		
		syntax anything [ , DESTination(string)  FORmat(string) ]
		
			local title "Mean First Passage Time"
			
			if "`destination'" != "" {
				markovmfpt_ind `anything', dest(`destination') format(`format') title(`title')
			}
			else {
				markovmfpt_all `anything', format(`format') title(`title')
			}

			// save matrix
			matrix mfpt = r(mfpt)
			return matrix mfpt = mfpt		
			
end			