// Apr  2 2018
// Faster algorithm to count distinct subsequences

// Assign each sequence to an interger so you can hash the integers. First,
// hash the null sequence. Then for each element in the sequence, append it
// to each previously existing sequence and hash the result.

// Key efficiency is that we only look at longer sequences based on
// already-observed shorter sequences, whereas ndsub_slow looks at every
// subsequence.

program ndsub
syntax, NSPells(string) STAtevars(string) NSTAtes(real) gen(string)
unab sv : `statevars'
qui gen `gen' = .
mata: ndsub("`sv'", "`nspells'", `nstates', "`gen'")
end

mata

void function ndsub(string states, string nspells, real scalar nstates, string outvar) {
  st_view(seqs = ., ., (states))
  st_view(l=., ., (nspells))
  st_view(result=., ., (outvar))
  // n_tuples is the number of distinct tuples observed
  n_tuples = J(rows(seqs),1,.)

  for (seqno=1; seqno<=rows(seqs); seqno++) {
    // For each sequence, create an asarray, put in the null sequence
    HH = asarray_create("real")
    asarray(HH, 0, 1)
    seq = seqs[seqno, 1..l[seqno]]

    // For each element
    for (i=1; i<=length(seq); i++) {
      keys = asarray_keys(HH)
      // Fill in new subsequences consisting of existing subseqs with
      // the current element appended
      for (j=1; j<=length(keys); j++) {
        asarray(HH, keys[j]*nstates + seq[i],1)
      }
    }
    n_tuples[seqno] = asarray_elements(HH)
  }
  result[.] = n_tuples
}

end
