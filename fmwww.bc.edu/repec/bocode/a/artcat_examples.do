/* 
Do-file to run the examples in section 4 of 
"Sample size calculation for an ordered categorical outcome" 
by White et al
*/

version 14

// Six-level outcome

artcat, pc(.018 .036 .156 .141 .39) or(1/1.77) unfavourable 

artcat, pc(.259 .390 .141 .156 .036 .018) or(1.77) favourable noheader

artcat, pc(.018 .036 .156 .141 .39) or(1/1.77) n(322) noprobtable unf nohead

artcat, pc(.018 .036 .156 .141 .39) or(1/1.77) whitehead noprobt unf nohead

artcat, pc(.010 .021 .099 .103 .384) or(1) margin(1.33) noprobt unf nohead


// Binary outcome and comparison with artbin

artcat, pc(.4) pe(.2) power(.9) unf nohead

artbin, pr(0.4 0.2) power(.9)


// Effect of subdividing the categories

artcat, pc(.01 .4) cum or(.375) power(.9) unf nohead

artcat, pc(.01 .1 .4) cum or(.375) power(.9) unf nohead

artcat, pc(.4 .7) cum or(.375) power(.9) unf nohead
