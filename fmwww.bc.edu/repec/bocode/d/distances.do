// Apr  2 2014
// Brendan Halpin brendan.halpin@ul.ie

/* This file runs through most of the functionality of the SADI package
for Stata, to demonstrate some of its uses. 

It uses the McVicar/Anyadike-Danes data, representing 72 months of the
labour market history of young people in Northern Ireland. Thanks guys.

Duncan McVicar and Michael Anyadike-Danes (2002), Predicting Successful
and Unsuccessful Transitions from School to Work Using Sequence Methods,
Journal of the Royal Statistical Society (Series A), 165, pp317-334.

*/


use mvad

sort id

// Use the substitution matrix from the MVAD paper
#delimit ;
matrix mvdanes = (0,1,1,2,1,3 \
                  1,0,1,2,1,3 \
                  1,1,0,2,1,2 \
                  2,2,2,0,1,1 \
                  1,1,1,1,0,2 \
                  3,3,2,1,2,0 );
#delimit cr

set matsize 4000

// Get pairwise distance matrices for a range of different distance measures

oma         state1-state72, subsmat(mvdanes) pwd(omd) length(72) indel(1.5)
omav        state1-state72, subsmat(mvdanes) pwd(omv) length(72) indel(1.5)
sdhollister state1-state72, subsmat(mvdanes) pwd(hol) length(72) timecost(0.5) localcost(0.5)
twed        state1-state72, subsmat(mvdanes) pwd(twd) length(72) lambda(0.5) nu(0.04) 
sdhamming   state1-state72, subsmat(mvdanes) pwd(ham) 
dynhamming  state1-state72,                  pwd(dyn) 

// Prepare the data in X/t spell format and get duration-weighted combinatorial (Elzinga) distance:
cal2spell, state(state) spell(sp) length(len) nsp(nspells)
local spmax = r(maxspells)
combinadd sp1-len`spmax', pwsim(xts) nspells(nspells) nstates(6) rtype(d)

// Rather than use MVAD's substitution matrix, generate one from transition probabilities
// Note the one without the diagonal has more variation
preserve
reshape long state, i(id) j(m)
trans2subs state, id(id) subs(tpr1)
matrix list tpr1
trans2subs state, id(id) subs(tpr2) diag
matrix list tpr2
restore

// Get OMA distance with the transition probability substitution matrix
oma        state1-state72, subsmat(tpr1) pwd(tpr) length(72) indel(1.5)


// Compare all distance matrices with OMA
// corrsqm with the nodiag option gives the correlation between the distances
// between all pairs, excluding the zero distances on the diagonal
foreach dist in dyn ham twd hol omv xts tpr {
  corrsqm omd `dist', nodiag
}

// Test all the distance matrices to ensure they obey the triangle inequality
// (omv and hol do not)

foreach dist in dyn ham oma twd hol omv xts tpr {
  metricp `dist'
}

// Do cluster analysis on OMA and TWED distances
// Generate 8 and 12 cluster solutions for each
clustermat wards omd, name(oma) add
cluster generate o=groups(8 12)

clustermat wards twd, name(twd) add
cluster generate t=groups(8 12)

// Compare clusterings using Adjusted Rand Index
ari o8 t8

// Compare clusterings using permtab
// gen(pt8) creates a permuted version of t8 so that it matches o8
// as closely as possible

permtab o8 t8, gen(pt8)
tab o8 pt8


// For 12 clusters, permutation takes 9*10*11*12=11880 times as long as for 8
// To deal with this, permtab with the option algorithm(hc) yields an approximate-best permutation using
// a fast hill-climb algorithm
permtab o12 t12, gen(pt18) algo(hc)
// See also -algo(ga)- which uses a (slow) genetic algorithm

// Studer et al's discrepancy measure
// See M Studer, G Ritschard, A Gabadinho and NS Müller, Discrepancy
//  analysis of state sequences, Sociological Methods and Research,
//  40(3):471-510

sddiscrep o8, dist(omd) id(id)
sddiscrep o12, dist(omd) id(id)
sddiscrep grammar, dist(omd) id(id)
sddiscrep grammar, dist(omd) id(id) niter(1000)

// Descriptive summaries of sequences

//  - string representation of sequences
sdstripe state1-state72, gen(seqstr) symbols("EFHSTU")
list seqstr in 1/5, clean

//  - string representation of sequences: condensed format
sdstripe state1-state72, gen(seqstrxt) symbols("EFHSTU") xt xtsp("/") xtdur(":")
list seqstrxt in 1/5, clean

// Use sddiscrep to identify medoids
sddiscrep o8, dist(omd) id(id) dcg(dx) niter(1) // niter(1) since p-value not needed
sort o8 dx
by o8: gen medoid = _n==1
list o8 dx seqstrxt if medoid, clean
sort id

// - cumulated duration in each state
cumuldur state1-state72, cd(dur) nstates(6)

su dur*
table o8, c(mean dur1 mean dur2 mean dur3) format(%5.2f)
table o8, c(mean dur4 mean dur5 mean dur6) format(%5.2f)

drop dur1-dur6

// - sdentropy: A simple measure of Shannon entropy
sdentropy state1-state72, gen(ent) cd(dur) nstates(6)
table o8, c(mean ent)

// - nspells, number of spells
nspells state1-state72, gen(nsp)
tab nsp

// Graphics

// 1: Chronogram

sdchronogram state*, by(o8, legend(off)) name(chronogram, replace)

// 2: indexplot (uses sqindexplot from SQOM package)

//    Generate a maximal clustering (as many clusters as distinct sequences)
//    This allows us to order sequences within clusters such that 
//    subcluster-structure is preserved
cluster generate o999 = groups(750), name(oma) ties(fewer)

// Reshape long and register it as an SQ-structured data set
preserve
reshape long state, i(id) j(m)
sqset state id m
sqindexplot, by(o8, note("") legend(off)) order(o999) name(indexplot, replace)
restore

// 3: Transition pattern
trprgr state*, gmax(485)

// A matrix of transition rates: maketrpr generates the matrix of transition rates
// that is used by dynhamming and trprgr, using tssmooth to average over a moving
// window of successive transitions. 

maketrpr state*, mat(mkt) ma(5)

matlist mkt[1..6,.]
matlist mkt[25..30,.]

// Comparison to "reference" or "ideal type" sequences
// oma, twed and dynhamming are set up to calculate distances to
// specific sequences, as an alternative to all pairwise distances
// It creates an N by M distance matrix where distances to the first M
// sequences are calculated

// Example: Begin by creating 3 ideal sequences in 3 extra rows at the start
expand 4 in 1
sort id
forvalues x = 1/72 {
  qui {
    // Seq 1: school:university:employment
    replace state`x' = 4 in 1 if inrange(`x',1,24)  // 2 years' school
    replace state`x' = 3 in 1 if inrange(`x',25,60) // 3 years' university
    replace state`x' = 1 in 1 if inrange(`x',61,72) // 1 year's employment
    // Seq 2: school:FE:unemployment:employment
    replace state`x' = 4 in 2 if inrange(`x',1,12)  // 1 year's school
    replace state`x' = 2 in 2 if inrange(`x',13,24) // 1 year's further education
    replace state`x' = 6 in 2 if inrange(`x',25,36) // 1 year's unemployment
    replace state`x' = 1 in 2 if inrange(`x',37,72) // 3 years' employment
    // Seq 3: ue:training:employment:ue:employment
    replace state`x' = 6 in 3 if inrange(`x',1,12)  // 1 year's unemployment
    replace state`x' = 5 in 3 if inrange(`x',13,24) // 1 year's training
    replace state`x' = 1 in 3 if inrange(`x',25,36) // 1 year's employment
    replace state`x' = 6 in 3 if inrange(`x',37,48) // 1 year's unemployment
    replace state`x' = 1 in 3 if inrange(`x',49,60) // 1 year's employment
    replace state`x' = 6 in 3 if inrange(`x',61,72) // 1 year's unemployment
  }
}

// View reference sequences
drop seqstr
sdstripe state1-state72, gen(seqstr) symbols("EFHSTU")
list seqstr in 1/3, clean

// For OMA, TWED and Dynamic Hamming, the commands take a "ref(n)" option
// which creates an _N*n matrix of distances to the first n sequences in the data

// For Hamming distances, use =oma= with a large indel

oma        state1-state72, subsmat(mvdanes) pwd(ham3) ref(3) length(72) indel(999)
oma        state1-state72, subsmat(mvdanes) pwd(omd3) ref(3) length(72) indel(1.5)
twed       state1-state72, subsmat(mvdanes) pwd(twd3) ref(3) length(72) lambda(0.5) nu(0.04) 
dynhamming state1-state72,                  pwd(dyn3) ref(3)

// Transfer one _N*3 matrix to variables and see how it compares with clusters based on
// all pairwise distances. 
svmat omd3
table o8, c(mean omd31 mean omd32 mean omd33) f(%6.3f)
list o8 seqstrxt omd3* if medoid, clean
