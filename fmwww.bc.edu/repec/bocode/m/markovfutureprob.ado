*! 1.0.0 Ariel Linden 05Jul2025 

* Markov chain future probabilities
program markovfutureprob, rclass
		version 11.0
		
		syntax anything [ , CURRent(string)  PERiod(real 2) FORmat(string) ]
		
			local title "Probabilities for `period' periods into the future"
			
			if "`current'" != "" {
				markovfutureprob_ind `anything', current(`current') period(`period') format(`format') title(`title')
			}
			else {
				markovfutureprob_all `anything', period(`period') format(`format') title(`title')
			}

			// save matrix
			matrix futureprobs = r(futureprobs)
			return matrix futureprobs = futureprobs		
			
end			
