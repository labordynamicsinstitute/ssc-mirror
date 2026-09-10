*! emlink_engine.mata  version 1.0.15
*! Mata computational engine for emlink.
*! Implements the Fellegi-Sunter record-linkage model with unsupervised
*! EM estimation of agreement weights. Loaded automatically by emlink.ado.

version 17.0
mata:
mata set matastrict on

/* ================================================================= */
/* 1. String comparison                                              */
/* ================================================================= */

/* Bigram overlap similarity (0..1). */
real scalar emlink_jaccard(string scalar a, string scalar b)
{
    real scalar i, na, nb, inter, uni
    string rowvector ga, gb
    string scalar sa, sb

    sa = subinstr(a, " ", "", .)
    sb = subinstr(b, " ", "", .)
    na = strlen(sa) - 1
    nb = strlen(sb) - 1
    if (na < 1 | nb < 1) return(a == b ? 1 : 0)

    ga = J(1, na, ""); gb = J(1, nb, "")
    for (i=1; i<=na; i++) ga[1,i] = substr(sa, i, 2)
    for (i=1; i<=nb; i++) gb[1,i] = substr(sb, i, 2)

    inter = 0
    for (i=1; i<=na; i++) if (anyof(gb, ga[1,i])) inter++
    uni = na + nb - inter
    return(uni > 0 ? inter/uni : 0)
}

/* token_set-style similarity: order-free comparison of token sets. */
real scalar emlink_tokenset(string scalar a, string scalar b)
{
    string rowvector ta, tb, inter, ra, rb
    real scalar i, j, na, nb
    string scalar s1, s2, s3

    if (a == b) return(1)
    ta = tokens(a); tb = tokens(b)
    na = cols(ta); nb = cols(tb)
    if (na == 0 | nb == 0) return(0)

    inter = J(1,0,""); ra = J(1,0,""); rb = J(1,0,"")
    for (i=1; i<=na; i++) {
        if (anyof(tb, ta[1,i])) {
            inter = (inter, ta[1,i])
        }
        else {
            ra = (ra, ta[1,i])
        }
    }
    for (j=1; j<=nb; j++) if (!anyof(ta, tb[1,j])) rb = (rb, tb[1,j])

    /* no shared token at all -> fall back to whole-string overlap */
    if (cols(inter) == 0) return(emlink_jaccard(a, b))

    s1 = invtokens(inter, " ")
    s2 = strtrim(s1 + " " + ((cols(ra)>0) ? invtokens(ra, " ") : ""))
    s3 = strtrim(s1 + " " + ((cols(rb)>0) ? invtokens(rb, " ") : ""))

    return(max(( emlink_jaccard(s1, s2),
                 emlink_jaccard(s1, s3),
                 emlink_jaccard(s2, s3) )))
}

/* Damerau-Levenshtein similarity (0..1). Bigram overlap is harsh on
   transpositions -- QUISPE vs QIUSPE loses two bigrams out of five,
   which can push a common typo to full disagreement. */
real scalar emlink_editsim(string scalar a, string scalar b)
{
    real scalar la, lb, i, j, cost, mx
    real matrix d

    la = strlen(a); lb = strlen(b)
    if (la == 0 | lb == 0) return(la == lb ? 1 : 0)
    d = J(la+1, lb+1, 0)
    for (i=0; i<=la; i++) d[i+1,1] = i
    for (j=0; j<=lb; j++) d[1,j+1] = j
    for (i=1; i<=la; i++) {
        for (j=1; j<=lb; j++) {
            cost = (substr(a,i,1) == substr(b,j,1)) ? 0 : 1
            d[i+1,j+1] = min(( d[i,j+1]+1, d[i+1,j]+1, d[i,j]+cost ))
            if (i>1 & j>1) {
                if (substr(a,i,1)==substr(b,j-1,1) &
                    substr(a,i-1,1)==substr(b,j,1))
                    d[i+1,j+1] = min(( d[i+1,j+1], d[i-1,j-1]+cost ))
            }
        }
    }
    mx = max((la, lb))
    return(1 - d[la+1,lb+1]/mx)
}

/* Agreement level: -1 missing, 0 disagree, 1 partial, 2 agree. */
real scalar emlink_level(string scalar a, string scalar b,
                         real scalar locut, real scalar hicut)
{
    real scalar s, la, lb
    string scalar shrt, lng

    if (a == "" | b == "") return(-1)
    if (a == b) return(2)

    la = strlen(a); lb = strlen(b)
    if (la == 1 | lb == 1) {                 /* initials -> partial */
        if (la < lb) {
            shrt = a; lng = b
        }
        else {
            shrt = b; lng = a
        }
        if (substr(lng, 1, strlen(shrt)) == shrt) return(1)
    }

    s = max(( emlink_tokenset(a, b), emlink_editsim(a, b) ))
    if (s >= hicut) return(2)
    if (s >= locut) return(1)
    return(0)
}

/* Compare one record pair over K fields, optionally testing the swapped
   alignment of the two surname fields (positions 2 and 3). */
real rowvector emlink_compare(string rowvector A, string rowvector B,
                              real scalar K, real scalar swapnames,
                              real scalar locut, real scalar hicut)
{
    real rowvector d, c
    real scalar k, sd, sc

    d = J(1, K, -1)
    for (k=1; k<=K; k++) d[1,k] = emlink_level(A[1,k], B[1,k], locut, hicut)

    if (swapnames & K >= 3) {
        c = d
        c[1,2] = emlink_level(A[1,2], B[1,3], locut, hicut)
        c[1,3] = emlink_level(A[1,3], B[1,2], locut, hicut)
        sd = 0; sc = 0
        for (k=1; k<=K; k++) {
            if (d[1,k] > 0) sd = sd + d[1,k]
            if (c[1,k] > 0) sc = sc + c[1,k]
        }
        if (sc > sd) return(c)
    }
    return(d)
}

/* ================================================================= */
/* 2. EM core -- iterates over UNIQUE agreement patterns             */
/* ================================================================= */

/* Likelihood contribution of field k (1.0 when missing, so a missing
   field contributes no evidence either way). */
real colvector emlink_contrib(real matrix probs, real scalar k,
                              real colvector col)
{
    real scalar i, P
    real colvector out
    P = rows(col)
    out = J(P, 1, 1)
    for (i=1; i<=P; i++) if (col[i] >= 0) out[i] = probs[k, col[i]+1]
    return(out)
}

/* u-probabilities estimated CONDITIONAL ON BLOCKING. Blocked pairs are
   overwhelmingly non-matches, so their level frequencies approximate u.
   Estimating u from a global random sample and applying it to blocked
   pairs is a methodological error: blocking already forces agreement on
   the blocking key, so global u understates agreement among the pairs
   actually compared, so u is estimated from the blocked set. */
real matrix emlink_estimate_u(real matrix patterns, real scalar K,
                              real colvector counts)
{
    real scalar k, l, i, n, tot
    real matrix u
    u = J(K, 3, 0)
    for (k=1; k<=K; k++) {
        tot = 0
        for (i=1; i<=rows(patterns); i++)
            if (patterns[i,k] >= 0) tot = tot + counts[i]
        for (l=0; l<=2; l++) {
            n = 0
            for (i=1; i<=rows(patterns); i++)
                if (patterns[i,k]==l) n = n + counts[i]
            u[k, l+1] = tot > 0 ? n/tot : 1/3
        }
        for (l=1; l<=3; l++) if (u[k,l] < 1e-6) u[k,l] = 1e-6
        u[k,.] = u[k,.] :/ rowsum(u[k,.])
    }
    return(u)
}

/* DETERMINISTIC SEED (fastLink-style). Pairs agreeing on >= seedagree
   fields are near-certain matches; their level frequencies anchor the M
   class from the first iteration. Without this the EM converges to the
   inverted solution (m[agree] < u[agree]). nseed is returned by reference. */
real matrix emlink_seed(real matrix patterns, real colvector counts,
                        real scalar K, real scalar seedagree,
                        real scalar nseed)
{
    real scalar i, k, l, n, tot, nagree, minagree
    real colvector keep
    real matrix m

    minagree = seedagree
    keep = J(rows(patterns), 1, 0)
    nseed = 0
    while (minagree >= 1) {
        nseed = 0
        for (i=1; i<=rows(patterns); i++) {
            nagree = 0
            for (k=1; k<=K; k++) if (patterns[i,k]==2) nagree++
            keep[i] = (nagree >= minagree)
            if (keep[i]) nseed = nseed + counts[i]
        }
        if (nseed >= 20) break
        minagree--
    }

    m = J(K, 3, 0)
    for (k=1; k<=K; k++) {
        tot = 0
        for (i=1; i<=rows(patterns); i++)
            if (keep[i] & patterns[i,k] >= 0) tot = tot + counts[i]
        for (l=0; l<=2; l++) {
            n = 0
            for (i=1; i<=rows(patterns); i++)
                if (keep[i] & patterns[i,k]==l) n = n + counts[i]
            m[k, l+1] = tot > 0 ? n/tot : 1/3
        }
        for (l=1; l<=3; l++) if (m[k,l] < 1e-4) m[k,l] = 1e-4
        m[k,.] = m[k,.] :/ rowsum(m[k,.])
    }
    return(m)
}

/* EM: estimates m and p with u FIXED, subject to
     - upper bound p <= min(nA,nB)/n_pairs  (a record matches at most once)
     - Beta(alpha,beta) prior on p          (MAP; prevents p -> 1)
     - monotonicity guard m[agree] >= u[agree]
   Each guards a known failure mode: without the cap p collapses
   to 1 and every pair links; without seed+guard the class labels switch
   and nothing links; with u free the mixture is unidentified. */
void emlink_em(real matrix uniq, real colvector counts, real matrix u,
               real matrix m_init, real scalar p_cap,
               real scalar tol, real scalar maxiter,
               real matrix m_out, real scalar p_out, real scalar iters_out)
{
    real scalar P, K, it, i, k, l, p, pnew, chg, tg, num
    real scalar alpha, beta, guarded
    real colvector lm, lu, g
    real matrix m, mnew

    P = rows(uniq); K = cols(uniq)
    m = m_init
    p = min((0.02, p_cap))
    alpha = 1.5; beta = 50

    for (it=1; it<=maxiter; it++) {
        lm = J(P,1,p); lu = J(P,1,1-p)
        for (k=1; k<=K; k++) {
            lm = lm :* emlink_contrib(m, k, uniq[.,k])
            lu = lu :* emlink_contrib(u, k, uniq[.,k])
        }
        g = lm :/ (lm + lu)

        pnew = (colsum(g :* counts) + alpha - 1) /
               (colsum(counts) + alpha + beta - 2)
        if (pnew > p_cap) pnew = p_cap
        if (pnew < 1e-8)  pnew = 1e-8

        mnew = J(K, 3, 0)
        guarded = 0
        for (k=1; k<=K; k++) {
            tg = 0
            for (i=1; i<=P; i++) if (uniq[i,k] >= 0) tg = tg + g[i]*counts[i]
            for (l=0; l<=2; l++) {
                num = 0
                for (i=1; i<=P; i++) if (uniq[i,k]==l) num = num + g[i]*counts[i]
                mnew[k, l+1] = (tg > 1e-12) ? num/tg : m[k, l+1]
            }
            for (l=1; l<=3; l++) if (mnew[k,l] < 1e-6) mnew[k,l] = 1e-6
            mnew[k,.] = mnew[k,.] :/ rowsum(mnew[k,.])
            if (mnew[k,3] < u[k,3]) {          /* reject inverting update */
                mnew[k,.] = m[k,.]
                guarded = 1
            }
        }

        chg = max(( abs(pnew-p), max(abs(rowshape(mnew - m, 1))) ))
        m = mnew; p = pnew
        /* a guarded iteration can look converged while p still moves */
        if (chg < tol & !guarded) break
    }
    m_out = m; p_out = p; iters_out = it
}

/* Posterior P(match | pattern) for each unique pattern. */
real colvector emlink_posterior(real matrix uniq, real matrix m,
                                real matrix u, real scalar p)
{
    real scalar P, K, k
    real colvector lm, lu
    P = rows(uniq); K = cols(uniq)
    lm = J(P,1,p); lu = J(P,1,1-p)
    for (k=1; k<=K; k++) {
        lm = lm :* emlink_contrib(m, k, uniq[.,k])
        lu = lu :* emlink_contrib(u, k, uniq[.,k])
    }
    return(lm :/ (lm + lu))
}

/* Match weight on the classical Fellegi-Sunter log2 scale. Missing
   fields contribute exactly zero, so weights stay comparable across
   pairs with different missingness.
   Reported alongside the posterior because a FIXED posterior cutoff
   such as 0.90 is unreachable when p(M) is small, hence the calibrated
   cutoff used by default. */
real colvector emlink_weight(real matrix uniq, real matrix m, real matrix u)
{
    real scalar P, K, k, i
    real colvector w
    P = rows(uniq); K = cols(uniq)
    w = J(P,1,0)
    for (k=1; k<=K; k++) {
        for (i=1; i<=P; i++) {
            if (uniq[i,k] >= 0)
                w[i] = w[i] +
                       log(m[k, uniq[i,k]+1] / u[k, uniq[i,k]+1]) / log(2)
        }
    }
    return(w)
}

/* Calibrated posterior cutoff: the widest gap in the sorted posteriors.
   Used when threshold() is not supplied. */
real scalar emlink_calibrate(real colvector post)
{
    real scalar i, n, bestgap, cut
    real colvector s

    n = rows(post)
    if (n < 2) return(0.5)
    s = sort(post, 1)
    bestgap = 0; cut = 0.5
    for (i=1; i<n; i++) {
        if ((s[i+1] - s[i]) > bestgap & s[i+1] > 0.05) {
            bestgap = s[i+1] - s[i]
            cut = (s[i] + s[i+1]) / 2
        }
    }
    return(cut)
}

/* Read an id variable as a numeric column whether it is stored numeric
   or string. When the CSV was imported with stringcols(_all), st_data()
   on a string variable returns missing; here we detect that and convert
   with strtoreal, falling back to the row number if conversion fails. */
real colvector emlink_readid(string scalar idvar, real scalar n)
{
    real colvector v
    string colvector sv
    real scalar i, vidx

    vidx = st_varindex(idvar)
    if (vidx == .) {
        /* should not happen: caller validated the id exists */
        return((1::n))
    }
    if (st_isnumvar(vidx)) {
        return(st_data(., vidx))
    }
    /* string id (e.g. imported with stringcols): convert */
    sv = st_sdata(., vidx)
    v = J(n, 1, .)
    for (i=1; i<=n; i++) {
        v[i] = strtoreal(sv[i])
        if (v[i] == .) v[i] = i          /* non-numeric id -> row index */
    }
    return(v)
}

/* ================================================================= */
/* 3. Driver: load, block, compare, estimate, write back             */
/* ================================================================= */

void emlink_run(string scalar masterfile, string scalar usingfile,
                string scalar mvars,    string scalar uvars,
                string scalar idmaster, string scalar idusing,
                string scalar blockM,   string scalar blockU,
                real scalar K,
                real scalar tol, real scalar maxiter,
                real scalar thr_opt, real scalar cler_opt,
                real scalar swapnames, real scalar seedagree,
                string scalar genprefix)
{
    real scalar nA, nB, i, j, k, np, P, p, iters, thr, cler, nseed
    real scalar nlinks, ncler, locut, hicut, p_cap, ci, c, nb_
    real scalar cap_, code, idx0
    string rowvector mv, uv, bvM, bvU
    string matrix SA, SB, KA, KB
    real colvector idA, idB, counts, post, wgt, rowid, cand
    real colvector codes, ucodes
    real matrix pats, uniq, m, u, m_init
    real rowvector lev
    real colvector outA, outB, outPost, outW, outStat, outBest
    class AssociativeArray scalar blk, cmap, bestp, bestflag
    string scalar key, idkey

    locut = 0.70; hicut = 0.90
    mv = tokens(mvars); uv = tokens(uvars)
    bvM = tokens(blockM); bvU = tokens(blockU)
    nb_ = cols(bvM)

    /* ---- load master ---- */
    stata("use " + char(34) + masterfile + char(34) + ", clear")
    nA = st_nobs()
    SA = st_sdata(., mv)
    idA = emlink_readid(idmaster, nA)
    KA = (nb_ > 0) ? st_sdata(., bvM) : J(nA, 1, "")

    /* ---- load using ---- */
    stata("use " + char(34) + usingfile + char(34) + ", clear")
    nB = st_nobs()
    SB = st_sdata(., uv)
    idB = emlink_readid(idusing, nB)
    KB = (nb_ > 0) ? st_sdata(., bvU) : J(nB, 1, "")

    /* ---- blocking index over the using file ---- */
    blk.reinit("string", 1)
    blk.notfound(J(0,1,.))
    for (j=1; j<=nB; j++) {
        if (nb_ > 0) {
            for (k=1; k<=nb_; k++) {
                key = strofreal(k) + "|" + KB[j,k]
                blk.put(key, (blk.get(key) \ j))
            }
        }
        else {
            blk.put("ALL", (blk.get("ALL") \ j))
        }
    }

    /* ---- compare candidate pairs ----
       Preallocated with doubling growth. Appending row by row
       (pats = (pats \ lev)) reallocates the whole matrix on every pair,
       which is O(n^2) and becomes unusable in the millions of pairs. */
    cap_ = 100000
    pats = J(cap_, K, .); outA = J(cap_,1,.); outB = J(cap_,1,.)
    np = 0
    for (i=1; i<=nA; i++) {
        cand = J(0,1,.)
        if (nb_ > 0) {
            for (k=1; k<=nb_; k++)
                cand = (cand \ blk.get(strofreal(k) + "|" + KA[i,k]))
        }
        else {
            cand = blk.get("ALL")
        }
        if (rows(cand) == 0) continue
        if (rows(cand) > 1) cand = uniqrows(cand)
        for (ci=1; ci<=rows(cand); ci++) {
            j = cand[ci]
            lev = emlink_compare(SA[i,.], SB[j,.], K, swapnames, locut, hicut)
            np++
            if (np > cap_) {                    /* grow by doubling */
                cap_ = cap_ * 2
                pats = (pats \ J(rows(pats), K, .))
                outA = (outA \ J(rows(outA), 1, .))
                outB = (outB \ J(rows(outB), 1, .))
            }
            pats[np,.] = lev
            outA[np] = idA[i]; outB[np] = idB[j]
        }
    }
    if (np == 0) {
        errprintf("no candidate pairs generated; check block()\n")
        exit(2000)
    }
    if (np < rows(pats)) {                      /* trim to size */
        pats = pats[1..np,.]
        outA = outA[1..np]; outB = outB[1..np]
    }

    /* ---- unique patterns ----
       Each pattern is mapped to an integer code in base 4 (levels are
       -1,0,1,2 -> 0..3), so pattern lookup is arithmetic rather than a
       scan over the pattern table for every pair. */
    codes = J(np, 1, 0)
    for (i=1; i<=np; i++) {
        code = 0
        for (k=1; k<=K; k++) code = code*4 + (pats[i,k] + 1)
        codes[i] = code
    }
    ucodes = uniqrows(codes)
    P = rows(ucodes)
    cmap.reinit("real", 1)
    cmap.notfound(.)
    uniq = J(P, K, .)
    for (c=1; c<=P; c++) cmap.put(ucodes[c], c)
    counts = J(P,1,0)
    rowid  = J(np,1,.)
    for (i=1; i<=np; i++) {
        c = cmap.get(codes[i])
        rowid[i] = c
        counts[c] = counts[c] + 1
        if (counts[c] == 1) uniq[c,.] = pats[i,.]
    }

    /* ---- estimate ---- */
    p = 0; iters = 0; nseed = 0
    u = emlink_estimate_u(uniq, K, counts)
    m_init = emlink_seed(uniq, counts, K, seedagree, nseed)
    p_cap = min((nA, nB)) / np
    m = J(K, 3, .)
    emlink_em(uniq, counts, u, m_init, p_cap, tol, maxiter, m, p, iters)

    post = emlink_posterior(uniq, m, u, p)
    wgt  = emlink_weight(uniq, m, u)

    thr  = (thr_opt  >= 0) ? thr_opt  : emlink_calibrate(post)
    cler = (cler_opt >= 0) ? cler_opt : thr/3

    /* ---- classify ---- */
    outPost = J(np,1,.); outW = J(np,1,.); outStat = J(np,1,.)
    nlinks = 0; ncler = 0
    for (i=1; i<=np; i++) {
        outPost[i] = post[rowid[i]]
        outW[i]    = wgt[rowid[i]]
        if (outPost[i] >= thr) {
            outStat[i] = 2; nlinks++
        }
        else if (outPost[i] >= cler) {
            outStat[i] = 1; ncler++
        }
        else {
            outStat[i] = 0
        }
    }

    /* ---- best match per master record ----
       Fellegi-Sunter scores pairs independently, so one master record can
       exceed the cutoff against several using records. Flag the
       highest-posterior pair per master id (keep if _ml_best==1 for 1:1).
       Two-pass max by id: first record each id's best posterior in an
       AssociativeArray keyed by the id string, then flag the row that
       matches it. Keying on the id as a STRING avoids real-hash issues. */
    bestp.reinit("string", 1)
    bestp.notfound(-1e300)
    for (i=1; i<=np; i++) {
        idkey = strofreal(outA[i])
        if (outPost[i] > bestp.get(idkey)) bestp.put(idkey, outPost[i])
    }
    outBest = J(np, 1, 0)
    bestflag.reinit("string", 1)
    bestflag.notfound(0)
    for (i=1; i<=np; i++) {
        idkey = strofreal(outA[i])
        if (outPost[i] >= bestp.get(idkey) & bestflag.get(idkey) == 0) {
            outBest[i] = 1
            bestflag.put(idkey, 1)       /* only the first max per id */
        }
    }

    /* ---- report ---- */
    printf("{txt}EM iterations: {res}%g{txt}   seed pairs: {res}%g\n", iters, nseed)
    printf("{txt}Estimated p(match) among candidate pairs: {res}%9.6f\n", p)
    printf("{txt}Posterior cutoff: {res}%6.4f{txt}   clerical floor: {res}%6.4f\n", thr, cler)
    printf("\n{txt}Agreement-level probabilities (disagree / partial / agree)\n")
    for (k=1; k<=K; k++) {
        printf("{txt}  field %g  m: %6.3f %6.3f %6.3f   u: %6.3f %6.3f %6.3f\n", k, m[k,1], m[k,2], m[k,3], u[k,1], u[k,2], u[k,3])
    }
    printf("\n{txt}Candidate pairs: {res}%g\n", np)
    printf("{txt}  links:         {res}%g\n", nlinks)
    printf("{txt}  clerical:      {res}%g\n", ncler)
    printf("{txt}  non-links:     {res}%g\n", np - nlinks - ncler)
    if (ncler > 0) {
        printf("\n{txt}Review the clerical zone before using the links.\n")
    }

    /* ---- results dataset ---- */
    stata("clear")
    st_addobs(np)
    idx0 = st_addvar("double", genprefix + "_idmaster")
    idx0 = st_addvar("double", genprefix + "_idusing")
    idx0 = st_addvar("double", genprefix + "_post")
    idx0 = st_addvar("double", genprefix + "_weight")
    idx0 = st_addvar("byte",   genprefix + "_status")
    idx0 = st_addvar("byte",   genprefix + "_best")
    st_store(., genprefix + "_idmaster", outA)
    st_store(., genprefix + "_idusing",  outB)
    st_store(., genprefix + "_post",     outPost)
    st_store(., genprefix + "_weight",   outW)
    st_store(., genprefix + "_status",   outStat)
    st_store(., genprefix + "_best",     outBest)
    stata("label define " + genprefix + "_st 0 " + char(34) + "non-link" + char(34) + " 1 " + char(34) + "clerical" + char(34) + " 2 " + char(34) + "link" + char(34) + ", replace")
    stata("label values " + genprefix + "_status " + genprefix + "_st")

    /* ---- returns ---- */
    st_numscalar("r(n_pairs)",    np)
    st_numscalar("r(n_patterns)", P)
    st_numscalar("r(n_links)",    nlinks)
    st_numscalar("r(n_clerical)", ncler)
    st_numscalar("r(n_seed)",     nseed)
    st_numscalar("r(p_match)",    p)
    st_numscalar("r(threshold)",  thr)
    st_numscalar("r(iters)",      iters)
    st_matrix("r(m_probs)", m)
    st_matrix("r(u_probs)", u)
}

end
