*! ksmmd.ado v0.5 - 18sep2026
*! Test k-muestras, ponderado, que combina en UN SOLO remuestreo:
*!   - T de Kiefer (KS generalizado a k grupos -- mismo estadistico que
*!     kstest de Ariel Linden, SSC s459801, pero reimplementado aca:
*!     kstest ordena y por permutacion (O(reps*N log N)); aca se ordena
*!     y UNA sola vez y solo se permuta la etiqueta de grupo adosada a
*!     cada posicion ordenada -- equivalente matematico, mas rapido).
*!   - MMD generalizado a k grupos via Random Fourier Features (RFF,
*!     Rahimi & Recht 2007) del kernel RBF -- mmd_2s (Boston College
*!     SSC s459820) solo compara 2 grupos con kernel exacto O(N^2),
*!     inviable a N~10^5; RFF aproxima el kernel en O(N*D), D=nfeatures().
*!
*! Origen: construido a pedido explicito del usuario en esta sesion,
*! despues de que tsvy's mmd_2s (2 grupos, O(N^2)) resultara demasiado
*! lento en produccion (N~127mil, ver conversacion) incluso reduciendo
*! reps(). Diseno confirmado en conversacion, punto por punto:
*!   1. Comando STANDALONE, no una opcion de tsvy -- no tiene
*!      caida()/cruce() propios; se corre una vez por universo que el
*!      usuario ya acoto con [if]/subpop(), igual que kstest hoy.
*!      Integrarlo a tsvy (si hace falta) es un paso POSTERIOR y aparte.
*!   2. Autocontenido en Mata (no depende de kstest.ado ni mmd_2s.ado
*!      estando cargados) -- mismo criterio que tsvy_core() en tsvy.ado
*!      para no depender de que otro comando haya corrido antes.
*!   3. MMD via RFF (no kernel exacto, no k-NN graphs) -- unica forma de
*!      mantener el costo en O(reps*N*D) en vez de O(reps*N^2) o
*!      requerir una estructura de busqueda de vecinos que Mata no trae
*!      de fabrica.
*!   4. mmdtype(vspool) (default) o mmdtype(maxpairwise):
*!        vspool:      T_MMD = sum_j Wsum_j * ||mu_j - mu_pool||^2 --
*!                     patron "cada grupo contra el pool", igual que usa
*!                     Kiefer para generalizar D (2 muestras) a T (k
*!                     muestras). NO es una formula inventada sin
*!                     respaldo (version v0.1 lo decia asi por
*!                     precaucion, antes de revisar la literatura
*!                     indexada completa con el usuario): es
*!                     ALGEBRAICAMENTE IDENTICA (verificado a mano,
*!                     identidad tipo Huygens/ANOVA en espacio de
*!                     Hilbert: sum_j n_j||mu_j-mu_pool||^2 =
*!                     (1/N)*sum_{i<j} n_i n_j ||mu_i-mu_j||^2) a la
*!                     forma pairwise-ponderada con kernel RBF que usan
*!                     Ong, Chen, Zhu & Zhang (2023, Mathematics 11(20),
*!                     MDPI) y, en el marco general de k muestras con
*!                     tamanos desiguales, Zhang, Guo & Zhou (2022, J.
*!                     Econometrics) -- son el mismo estadistico salvo
*!                     una constante positiva (Wtot), que no cambia el
*!                     p-valor de permutacion (Wtot es fijo, no depende
*!                     de la asignacion de etiquetas). La equivalencia
*!                     formal distancia-de-energia <-> RKHS/MMD la
*!                     establecen Sejdinovic et al. (2013, Ann.
*!                     Statist.), puente hacia DISCO (Rizzo & Szekely
*!                     2010, Ann. Appl. Stat.) para quien prefiera
*!                     pensarlo como energy statistics.
*!        maxpairwise: T_MMD = max_{k<l} [Wsum_k*Wsum_l/(Wsum_k+Wsum_l)]
*!                     * ||mu_k-mu_l||^2 -- Kim (2021, Bernoulli 27(1)),
*!                     forma ponderada para tamanos desiguales (su
*!                     Remark 3.3, adaptada aca con Wsum en vez de n
*!                     para pesos de encuesta continuos). A diferencia
*!                     de vspool (que promedia la discrepancia entre
*!                     TODOS los grupos), maxpairwise es sensible a que
*!                     UN SOLO par de anios difiera mucho aunque el
*!                     resto sean iguales -- alternativas dispersas,
*!                     distribucion limite Gumbel en el paper original
*!                     (aca se usa permutacion, no la asintotica, mismo
*!                     criterio que el resto del comando).
*!      (v0.1 tenia una tercera opcion, mmdtype(pairwise), sin el peso
*!      Wsum_k*Wsum_l/Wtot -- SE ELIMINA en esta version: agregado el
*!      peso correcto, pairwise queda ALGEBRAICAMENTE IDENTICO a vspool
*!      (mismo p-valor exacto), asi que ofrecerlo aparte era redundante,
*!      no una alternativa real.
*!   4b. mmdtype(fuse) (agregada en v0.4, a pedido explicito del
*!      usuario, tras evaluar mejoras posibles a MMD en la literatura
*!      ya revisada en esta sesion): MMD-FUSE (Biggs, Schrab & Gretton
*!      2023, NeurIPS, arXiv:2306.08777, PDF leido completo). En vez
*!      de un solo bandwidth (heuristica de mediana), combina el
*!      T_MMD "vspool" de una GRILLA fija de bandwidths (todos >=
*!      heuristica: 1x, 1.5x, 2x, 3x) via un soft-max regularizado por
*!      KL (log-sum-exp con lambda), sin pagar el costo de correccion
*!      de Bonferroni ni partir la muestra:
*!        T_FUSE = (1/lambda) * log( mean_g[ exp(lambda*T_g) ] ),
*!        T_g = T_MMD_vspool(bw_g) / sqrt(Nhat(bw_g))
*!      La normalizacion por Nhat (ver ksmmd_nhat() en Mata) pone en
*!      la misma escala el T_MMD de cada bandwidth antes de
*!      combinarlos. El teorema de calibracion por permutacion
*!      (Hemerik & Goeman 2018) es valido para CUALQUIER estadistico
*!      fijo, asi que la grilla/lambda no necesitan estar en la
*!      literatura para que el p-valor de permutacion siga siendo
*!      exacto bajo H0 -- lo que si hay que declarar con honestidad es
*!      que la grilla {1x,1.5x,2x,3x}*heuristica y lambda=0.1 salen de
*!      una busqueda sistematica en Python/numpy sobre datos
*!      simulados en ESTA sesion (sim/prototipo_mmd_fuse.py,
*!      sim/prototipo_mmd_fuse_sistematico.py,
*!      sim/prototipo_mmd_fuse_escala.py), no de un valor recomendado
*!      por el paper. Motivo de la busqueda: una primera prueba con
*!      datos reales de produccion (un outcome de encuesta continuo,
*!      agrupado por anio, ponderado) mostro que un solo bandwidth es
*!      sensible al TIPO de alternativa
*!      (bw() grande diluye corrimientos de ubicacion, bw() chico se
*!      ahoga en ruido de permutacion) -- la grilla probada busco una
*!      combinacion que no dependiera de adivinar de antemano que tipo
*!      de diferencia hay entre anios. Validacion (ver
*!      sim/resultados_ksmmd_mmd_fuse_2muestras_tipo1.txt y
*!      sim/resultados_ksmmd_mmd_fuse_4muestras_tipo1.txt, R=20000):
*!      tasa de error Tipo I controlada, sin inflacion, en los mismos
*!      3 escenarios de peso "adversos" que el resto de este comando,
*!      para k=2 Y k=4 (el uso real con by() agrupando por anio).
*!      Evidencia
*!      de potencia (R=300, kernel exacto en Python, no RFF):
*!      {1x,1.5x,2x,3x} fue la UNICA configuracion, de 8 grillas x 6
*!      lambdas probadas, robusta a la vez contra un corrimiento de
*!      ubicacion (50-53% de potencia) Y una diferencia de escala
*!      (89.7-91.3%) -- grillas que ganaban en un escenario (p.ej. solo
*!      bandwidths grandes) se derrumbaban en el otro. NO configurable
*!      via opciones del .ado (grilla y lambda quedan fijas en Mata,
*!      ver ksmmd_run()): exponerlas como opciones multiplicaria la
*!      superficie de validacion sin que exista todavia evidencia de
*!      que otra combinacion sea mejor. bw() del usuario se ignora con
*!      mmdtype(fuse) (el .ado avisa si se paso uno) -- la grilla
*!      siempre se ancla en la heuristica de mediana interna, unica
*!      version validada. Costo: nfeatures() features POR CADA uno de
*!      los 4 puntos de grilla (4x la memoria de Phi que un solo
*!      mmdtype(vspool)/(maxpairwise) con el mismo nfeatures()).
*!      ESTADO DE VALIDACION EN STATA REAL de mmdtype(fuse): la
*!      integracion de FUSE a Mata se escribio SIN Stata real
*!      disponible (mismo entorno que reescribio v0.3), pero el
*!      usuario CONFIRMO en esta misma sesion, corriendo el Ejemplo 5
*!      del help (auto.dta, mpg by(g) mmdtype(fuse) reps(500)) contra
*!      Stata real, que corre SIN ERROR y da T_MMD=0.4980 p=0.7126,
*!      mismo orden de magnitud que mmdtype(vspool) sobre el mismo
*!      dataset/pesos (Ejemplo 2: T_MMD=0.7422 p=0.5629) -- confirma
*!      que la traduccion a Mata (bloques de columnas
*!      Phi_grid_sorted/mu_pool_grid, ksmmd_nhat(),
*!      ksmmd_mmd_fuse_T_batch()) no tiene errores de sintaxis/indexado
*!      que la revision estatica no hubiera detectado. CONFIRMADO
*!      TAMBIEN a escala de produccion, en la misma sesion: sobre un
*!      outcome de encuesta real agrupado por anio (N=141,151, 4
*!      grupos), reps(200) nfeatures(500) (2000 columnas de
*!      Phi_grid_sorted en total, 4x
*!      nfeatures() por los 4 puntos de grilla -- sin problema de
*!      memoria en la practica), corrio en 364.97s (~6.1 min) SIN
*!      ERROR: KS T=1705.5730 p=0.4279 (consistente con las corridas
*!      previas de esta sesion), MMD fuse T=1848.9130 p=0.6617 --
*!      practicamente igual al p=0.6667 de mmdtype(vspool) sobre el
*!      mismo dataset con la misma seed, y el post-hoc de MMD (fuse)
*!      da el mismo patron cualitativo que el de vspool: ningun par
*!      de anios significativo despues de corregir por comparaciones
*!      multiples (a diferencia del post-hoc de KS, que si encuentra a
*!      2026 distinto de los otros 3 anios). mmdtype(fuse) queda
*!      confirmado en Stata real tanto en escala chica (auto.dta) como
*!      de produccion (N~137mil).
*!      Se evaluo tambien KMD (Huang & Sen 2024, JASA -- "A Kernel
*!      Measure of Dissimilarity between M Distributions", arXiv
*!      2210.00634) como tercera opcion: leido el paper completo (el
*!      usuario lo subio dado que arxiv.org esta bloqueado en este
*!      entorno). CONCLUSION: KMD queda AFUERA de este comando por
*!      decision explicita del usuario -- su estimador publicado (ec. 4
*!      del paper) es un grafo de k-vecinos-mas-cercanos SIN version
*!      ponderada (nada en el paper trata pesos de encuesta), lo que
*!      choca con el requisito que motivo todo este diseno ("que
*!      respete el diseno muestral o use pesos, como kstest"). Ademas
*!      construir el grafo de k-NN rapido en Mata (sin una estructura
*!      tipo KD-tree) es un problema de rendimiento aparte, del mismo
*!      calibre que el que motivo usar RFF para MMD -- no se resuelve
*!      "de yapa" en esta version.
*!      Se evaluo tambien la familia de tests via informacion mutua/
*!      teoria de la informacion (busqueda bibliografica exhaustiva,
*!      sept-2026, PDFs leidos completos): Drake, R. & Guha, A. (2014).
*!      "A mutual information-based k-sample test for discrete
*!      distributions". Journal of Applied Statistics, 41(9), 2011-2027,
*!      DOI: 10.1080/02664763.2014.899325 -- unico test k-muestral
*!      EXPLICITO de esta familia encontrado, pero solo para variables
*!      DISCRETAS (tablas de contingencia); una variable continua como
*!      edad requeriria discretizar (binning), decision de diseno que
*!      afecta la potencia y que el paper no cubre. Berrett, T.B. &
*!      Samworth, R.J. (2019). "Nonparametric independence testing via
*!      mutual information". Biometrika, 106(3), 547-566, DOI:
*!      10.1093/biomet/asz024 -- reformula "k distribuciones iguales"
*!      como test de independencia entre la variable y la etiqueta de
*!      grupo, si soporta variables continuas y generaliza a k grupos,
*!      pero NINGUNO de los dos soporta pesos de encuesta/diseno
*!      muestral (mismo vacio de literatura que con KMD y con MMD bajo
*!      pesos). CONCLUSION: fuera de este comando por el mismo motivo
*!      que KMD -- ninguna via de esta familia resuelve el requisito
*!      central de pesos, y construirla desde cero (discretizar +
*!      pesos, o extender el estimador de Berrett-Samworth a pesos)
*!      seria una contribucion metodologica nueva, no una adopcion de
*!      literatura existente.
*!   5. graph: ECDFs ponderadas por grupo, mismo tipo de grafico que
*!      kstest ..., graph -- es la visual natural para el T de Kiefer;
*!      MMD no tiene una curva 1-D propia (vive en el espacio de
*!      features), pero la misma ECDF sigue siendo la referencia visual
*!      util para las dos, dado que operan sobre la misma variable.
*!   6. posthoc: tabla de a pares para AMBOS estadisticos (T_KS y
*!      T_MMD), con las mismas 4 correcciones de comparaciones
*!      multiples que ya usa kstest (Bonferroni/Sidak/Holm/FDR).
*!
*! v0.5 -- la salida de consola ahora muestra la Ho de cada prueba (a
*! pedido explicito del usuario, tras confundir varias veces en esta
*! sesion que KS y MMD prueban formalmente cantidades distintas -- KS:
*! igualdad de CDFs, F_j(x)=F_pool(x) para todo x,j; MMD vspool/fuse:
*! igualdad de mean embeddings en RKHS, mu_j=mu_pool; MMD maxpairwise:
*! igualdad de a pares, mu_a=mu_b (sin pool, por eso Kim 2021 es
*! sensible a un solo par divergente y vspool/fuse no -- ver la
*! discusion de "dilucion por el pool" en el remarks_mmdtype del
*! help). Ho tambien se agrego a cada tabla post-hoc (una linea, la
*! misma para cualquier mmdtype ahi porque una comparacion de a pares
*! no tiene pool que diluya). Sin cambios de algebra ni de Mata --
*! solo texto de display en el .ado, no afecta T_KS/T_MMD/p-valores.
*!
*! v0.4 -- agrega mmdtype(fuse) (MMD-FUSE, Biggs/Schrab/Gretton 2023),
*! ver el punto 4b mas arriba para el diseno completo, la validacion y
*! la advertencia honesta especifica de esta opcion (no corrida contra
*! Stata real todavia). Ademas, refactor interno sin cambio de
*! comportamiento: la heuristica de mediana que antes vivia inline
*! dentro de ksmmd_rff_features() se extrajo a su propia funcion
*! (ksmmd_bw_heuristic()) para que mmdtype(fuse) la reuse como ancla
*! de su grilla -- mismo orden de sorteos aleatorios que v0.3, asi que
*! mmdtype(vspool)/mmdtype(maxpairwise) dan el mismo resultado con la
*! misma seed que antes de este cambio.
*!
*! v0.3 -- motor de remuestreo VECTORIZADO (a pedido del usuario, tras
*! confirmar en Stata real sobre datos reales de produccion, N~127mil, que la
*! version v0.2 solo ganaba ~4-5x contra mmd_2s en vez del ~N/D=~636x
*! esperado de O(N^2)->O(N*D)). Causa raiz: v0.2 llamaba
*! ksmmd_ks_T()/ksmmd_mmd_T() UNA permutacion a la vez dentro de un
*! for(r=1;r<=reps;r++) en Mata (interpretado, sin BLAS) -- cada
*! llamada hacia varios select() sobre vectores de largo N y su propio
*! loop escalar for(i=1;i<=n-1;i++). v0.3 procesa un BLOQUE de
*! `chunk` permutaciones a la vez como una matriz (chunk x N): arma un
*! indicador de grupo (chunk x N) por grupo j, lo multiplica por el
*! peso (broadcast) y para MMD la media de grupo via multiplicacion de
*! matrices (BLAS, Wmat*Phi). Para KS, la suma acumulada ponderada por
*! grupo (runningsum) NO tiene version matricial nativa en Mata --
*! runningsum() solo acepta un vector (esto se detecto recien en Stata
*! real: con B=1, en el calculo del observado, SI es un vector y no
*! fallaba; con reps(200) de verdad, error 3201 "vector required") --
*! asi que ksmmd_rowcumsum() sigue iterando sobre las N posiciones, pero
*! UNA vez por BLOQUE de `chunk` permutaciones (acumulando un vector de
*! largo `chunk` por paso) en vez de una vez por PERMUTACION individual
*! como hacia v0.2 -- esa reduccion de N*reps a N*(reps/chunk)
*! iteraciones del loop interpretado de Mata es la que explica la
*! mejora de tiempos, no BLAS. El loop for(i=1;...) que queda (para el
*! jump-mask de y_sorted, y Fcum, que NO dependen de la permutacion) se
*! calcula UNA SOLA VEZ en ksmmd_run(), no por permutacion ni por
*! bloque. mu_pool
*! (para mmdtype(vspool)) tambien es fijo por dataset -- se calcula una
*! vez, no en cada permutacion, misma logica que ya usaba
*! sim/simulacion_ksmmd_mmd_tipo1.py (validado en Python antes de
*! llevarlo a Mata). `chunk` se ajusta para que chunk*N no supere ~60
*! millones de celdas por matriz de trabajo (~480MB, entre 10 y 1000
*! permutaciones por bloque) -- acota la memoria a N grande sin perder
*! el beneficio de procesar varias permutaciones de una vez a N chico.
*! (Este presupuesto se subio de ~5M a ~60M celdas tras la primera
*! corrida real: con el presupuesto chico, N=127mil daba chunk=39 y
*! ksonly casi no mejoraba (~1.3x) porque el loop de N iteraciones
*! dentro de ksmmd_rowcumsum() -- el costo dominante para KS -- se
*! repetia una vez POR BLOQUE, y con chunk chico salian muchos bloques.
*! Con reps(200) y N~127mil, este presupuesto nuevo entra en UN solo
*! bloque -- pendiente reconfirmar el tiempo real.)
*! Los dots de progreso (dots) ahora marcan UN bloque procesado, no una
*! permutacion individual (mostrar progreso por permutacion volveria a
*! forzar un loop de a una, que es justo lo que se elimino). Requiere
*! reconfirmar en Stata real: (a) los mismos 4 ejemplos del help
*! (mismos valores de T_KS/T_MMD que v0.2, dentro del ruido de
*! permutacion), (b) el script de tiempos sobre datos reales de
*! produccion (se espera una mejora sustancialmente mayor al ~4-5x de
*! v0.2).
*!
*! ADVERTENCIA HONESTA (mismo criterio que el resto de este repo):
*!   - v0.2 (motor no vectorizado) SI se corrio en Stata real, en esta
*!     misma sesion: los 4 ejemplos del help, y sobre datos reales de
*!     produccion (N~127mil) -- T_KS coincidio con el de kstest
*!     ya confirmado, y se encontro/corrigio un bug real (N=0 en el
*!     encabezado, ver abajo) que la revision estatica sola no hubiera
*!     encontrado. v0.3 (este archivo) REESCRIBE el motor de remuestreo
*!     para vectorizar -- incluido no hay entorno Stata en esta sesion
*!     para correrlo. El calculo de cada estadistico (T de Kiefer,
*!     T_MMD vspool/maxpairwise) es el MISMO algebra que v0.2, solo
*!     reorganizado en operaciones matriciales por bloque en vez de un
*!     loop escalar -- pero una reescritura de este tamano puede tener
*!     errores de sintaxis Mata o de indexado que la revision estatica
*!     no capture. Antes de usar en produccion: (a) correr los mismos 4
*!     ejemplos de mas abajo en Stata real y confirmar que no tiran
*!     error y dan valores de T_KS/T_MMD consistentes con los de v0.2:
*!     sysuse auto, clear / gen byte g=1+mod(_n,3) / gen double w=1 /
*!     ksmmd mpg [aweight=w], by(g) reps(50) graph posthoc; (b) repetir
*!     el script de tiempos sobre datos reales de produccion (N~127mil)
*!     y confirmar que la mejora es sustancialmente mayor al ~4-5x que
*!     dio v0.2 (el objetivo teorico de RFF es ~N/D). La simulacion de
*!     tasa de error Tipo I para T_MMD YA se corrio para LOS 2
*!     mmdtype(): vspool (sim/simulacion_ksmmd_mmd_tipo1.py /
*!     resultados_ksmmd_mmd_tipo1.txt) y maxpairwise
*!     (sim/simulacion_ksmmd_mmd_maxpairwise_tipo1.py /
*!     resultados_ksmmd_mmd_maxpairwise_tipo1.txt) -- ambas sobre una
*!     reimplementacion vectorizada en Python/numpy del MISMO algebra
*!     que tiene v0.3 en Mata, mismo diseno de 3 escenarios de peso que
*!     sim/simulacion_kstest_tipo1.py. Resultado consistente entre los
*!     3 estadisticos (T de Kiefer, T_MMD vspool, T_MMD maxpairwise):
*!     peor caso ~6% de tasa de rechazo vs 5% nominal, ningun escenario
*!     se dispara -- no queda pendiente ninguna simulacion de tasa de
*!     error Tipo I para este comando.
*!   - T_MMD (cualquiera de los 2 mmdtype()) es una APROXIMACION via RFF
*!     -- con mas nfeatures() la aproximacion mejora pero nunca es
*!     exacta; el kernel bandwidth bw() por default usa la heuristica de
*!     mediana (Garreau, Jitkrittum & Kanagawa 2017, arXiv:1707.07269)
*!     sobre una submuestra, no el dataset completo (por costo). Cota de
*!     error conocida (Sutherland & Schneider 2015, UAI, Theorem 1,
*!     sobre el estadistico MMD en si, no solo sobre el kernel):
*!     P(|MMD_RFF - MMD| >= eps) <= 2*exp(-D*eps^2/128), error absoluto
*!     esperado <= 8*sqrt(2*pi/D) -- para bajar el error esperado a la
*!     mitad hace falta CUADRUPLICAR nfeatures(). Ademas, Choi & Kim
*!     (2024, arXiv:2407.08976) muestran que la potencia del test con
*!     RFF fijo NO es consistente en general -- D chico (nfeatures()
*!     bajo) puede perder potencia frente al MMD exacto, mismo patron
*!     agil->final que reps(): nfeatures() bajo para explorar, alto
*!     para el resultado que se va a reportar.
*!   - PESOS DE ENCUESTA (diseno muestral, probabilidad desigual): no
*!     existe, hasta donde se pudo revisar (busqueda indexada por el
*!     usuario, sept-2026), ningun test MMD/energy-statistics peer-
*!     reviewed que trate especificamente pesos de diseno muestral --
*!     lo que existe es "importance weighting" (Bellot & van der Schaar
*!     2021, UAI, WMMD; Bharti et al. 2023, ICML; Diesendruck et al.
*!     2018/19), un concepto DISTINTO (corrige sesgo de seleccion entre
*!     2 distribuciones, no representa una poblacion via factor de
*!     expansion). La construccion de este archivo (insertar Wsum_j
*!     como en un promedio tipo Horvitz-Thompson dentro del estimador
*!     plug-in de MMD) es razonable pero NO tiene respaldo de un paper
*!     que pruebe su validez bajo pesos de encuesta -- exactamente
*!     porque no existe ese paper, la unica forma honesta de confiar en
*!     ella es la simulacion de tasa de error Tipo I pendiente (ver
*!     arriba), no una cita.
*!
*! Referencias completas:
*!   Kiefer, J. (1959). K-sample analogues of the Kolmogorov-Smirnov and
*!     Cramer-v. Mises tests. Ann. Math. Statist. 30(2), 420-447.
*!   Gretton, A., Borgwardt, K.M., Rasch, M.J., Scholkopf, B., Smola, A.
*!     (2012). A Kernel Two-Sample Test. JMLR 13(25), 723-773.
*!   Rahimi, A., Recht, B. (2007). Random Features for Large-Scale
*!     Kernel Machines. NeurIPS 20.
*!   Biggs, F., Schrab, A., Gretton, A. (2023). MMD-FUSE: Learning and
*!     Combining Kernels for Two-Sample Testing Without Data Splitting.
*!     NeurIPS 36. arXiv:2306.08777.
*!   Hemerik, J., Goeman, J.J. (2018). Exact testing with random
*!     permutations. Test 27(4), 811-825.
*!   Sutherland, D.J., Schneider, J. (2015). On the Error of Random
*!     Fourier Features. UAI 2015.
*!   Ong, C.S., Chen, X., Zhu, D., Zhang, Y. (2023). Testing Equality of
*!     Several Distributions at High Dimensions: A Maximum Mean
*!     Discrepancy-Based Approach. Mathematics 11(20), 4272.
*!   Zhang, Y., Guo, X., Zhou, W. (2022). Testing equality of several
*!     distributions in separable metric spaces: a maximum mean
*!     discrepancy based approach. J. Econometrics.
*!   Kim, I. (2021). Comparing a large number of multivariate
*!     distributions. Bernoulli 27(1), 419-441.
*!   Sejdinovic, D., Sriperumbudur, B., Gretton, A., Fukumizu, K.
*!     (2013). Equivalence of distance-based and RKHS-based statistics
*!     in hypothesis testing. Ann. Statist. 41(5), 2263-2291.
*!   Rizzo, M.L., Szekely, G.J. (2010). DISCO analysis: a nonparametric
*!     extension of analysis of variance. Ann. Appl. Stat. 4(2), 1034-1055.
*!   Garreau, D., Jitkrittum, W., Kanagawa, M. (2017). Large sample
*!     analysis of the median heuristic. arXiv:1707.07269.
*!   Szekely, G.J., Rizzo, M.L. (2004). Testing for Equal Distributions
*!     in High Dimension. InterStat, Nov(5).
*!   Rizzo, M.L., Szekely, G.J. (2016). Energy distance. WIREs
*!     Computational Statistics 8(1), 27-38.
*!   Huang, Z., Sen, B. (2024). A Kernel Measure of Dissimilarity
*!     between M Distributions. JASA 119(548), 3020-3032 (evaluada,
*!     NO incorporada -- ver punto 4 arriba).
*!
*! Author: Andres Talavera Cuya. Afiliacion indicada solo para fines de
*! identificacion -- este software no es un producto oficial de INEI y
*! INEI no es responsable por el. Distribuido bajo GNU GPL v3
*! (https://www.gnu.org/licenses/gpl-3.0.txt).

capture program drop ksmmd
program define ksmmd, rclass
    version 11.0

    syntax varname [pweight aweight iweight] [if] [in], ///
        BY(varname) ///
        [                                ///
        Reps(integer 1000)               ///
        SEED(string)                     ///
        DOts                             ///
        GRaph                            ///
        POSThoc                          ///
        BW(real -1)                      /// -1 = heuristica de mediana
        NFeatures(integer 200)           ///
        MMDTYPE(string)                  /// vspool (default), maxpairwise o fuse
        KSONLY                           ///
        MMDONLY                          ///
        ]

    if "`mmdtype'" == "" local mmdtype "vspool"
    local mmdtype = lower("`mmdtype'")
    if !inlist("`mmdtype'", "vspool", "maxpairwise", "fuse") {
        di as err "ksmmd: mmdtype() debe ser vspool, maxpairwise o fuse"
        exit 198
    }
    if "`mmdtype'" == "fuse" & `bw' != -1 {
        di as txt "ksmmd: mmdtype(fuse) ignora bw() -- usa una grilla de 4 " ///
            "bandwidths anclada en la heuristica de mediana calculada " ///
            "internamente (ver {help ksmmd##remarks_mmdtype:help ksmmd})"
    }
    if "`ksonly'" != "" & "`mmdonly'" != "" {
        di as err "ksmmd: ksonly y mmdonly son mutuamente excluyentes"
        exit 198
    }
    local do_ks  = cond("`mmdonly'" != "", 0, 1)
    local do_mmd = cond("`ksonly'"  != "", 0, 1)

    tempvar touse
    marksample touse, novarlist
    markout `touse' `varlist'

    local depvar `varlist'
    local origby "`by'"
    qui replace `touse' = 0 if missing(`by')

    tempvar w
    local hasweight = ("`weight'" != "")
    if `hasweight' {
        local wexp = trim(`"`exp'"')
        if substr(`"`wexp'"', 1, 1) == "=" {
            local wexp = trim(substr(`"`wexp'"', 2, .))
        }
        quietly gen double `w' = `wexp' if `touse'
        quietly replace `touse' = 0 if `touse' & (`w' <= 0 | missing(`w'))
    }
    else {
        quietly gen double `w' = 1 if `touse'
    }

    qui count if `touse'
    if r(N) == 0 {
        di as error "ksmmd: no observations in the sample"
        exit 2000
    }

    qui levelsof `by' if `touse', local(by_vals)
    local num_groups : word count `by_vals'
    if `num_groups' < 2 {
        di as error "{bf:by()} variable must have at least 2 distinct values"
        exit 420
    }

    capture confirm numeric variable `by'
    local needrecode = _rc != 0
    tempvar numby
    if `needrecode' {
        qui gen `numby' = .
    }
    local i = 0
    foreach lv of local by_vals {
        local ++i
        if `needrecode' {
            qui replace `numby' = `i' if `origby' == "`lv'" & `touse'
            local grouplabel`i' "`lv'"
            local grpval`i' "`i'"
        }
        else {
            capture local lbl : label (`by') `lv'
            if "`lbl'" == "" local lbl "`lv'"
            local grouplabel`i' "`lbl'"
            local grpval`i' "`lv'"
        }
    }
    if `needrecode' local by "`numby'"

    if "`seed'" != "" {
        set seed `seed'
    }
    local inis `=c(seed)'

    local showdots = ("`dots'" != "")
    if `reps' > 0 & `showdots' == 1 {
        di _n
        _dots 0
    }

    tempname RES
    mata: ksmmd_run("`depvar'", "`by'", "`w'", "`touse'", `reps', `showdots', ///
        `bw', `nfeatures', "`mmdtype'", `do_ks', `do_mmd', "`RES'")

    local T_KS   = `RES'[1,1]
    local P_KS   = `RES'[1,2]
    local T_MMD  = `RES'[1,3]
    local P_MMD  = `RES'[1,4]

    if `hasweight' {
        di as txt _n "Weighted `num_groups'-sample KS + MMD test (ksmmd)"
        di "{hline 78}"
    }
    else {
        di as txt _n "`num_groups'-sample KS + MMD test (ksmmd)"
        di "{hline 68}"
    }
    di as txt "Outcome:  `depvar'"
    di as txt "Groups:   `origby'"
    forvalues j = 1/`num_groups' {
        qui count if `by' == `grpval`j'' & `touse'
        di as txt "  `j'. `grouplabel`j''" _col(35) "N = " as res r(N)
    }
    di "{hline 55}"
    if `do_ks' {
        di as txt "KS (Kiefer T):"
        di as txt "  Ho: F_j(x) = F_pool(x) for all x, all j   (equal CDFs -- " ///
            "sensitive to shape/location)"
        di as txt "  Stat = " as res %9.4f `T_KS' as txt "   p = " as res %6.4f `P_KS'
    }
    if `do_mmd' {
        di as txt _n "MMD (`mmdtype', RFF):"
        if "`mmdtype'" == "maxpairwise" {
            di as txt "  Ho: mu_a = mu_b in RKHS, all pairs (a,b)   (equal kernel " ///
                "embeddings -- sensitive to a single divergent pair)"
        }
        else {
            di as txt "  Ho: mu_j = mu_pool in RKHS, all j          (equal kernel " ///
                "embeddings -- sensitive to moment differences)"
        }
        di as txt "  Stat = " as res %9.4f `T_MMD' as txt "   p = " as res %6.4f `P_MMD'
    }
    di as txt _n "  (basado en " as res `reps' as txt " permutaciones, " ///
        "nfeatures=" as res `nfeatures' as txt ")"
    di "{hline 55}"

    return scalar T_KS  = `T_KS'
    return scalar P_KS  = `P_KS'
    return scalar T_MMD = `T_MMD'
    return scalar P_MMD = `P_MMD'
    return scalar reps  = `reps'
    return scalar k     = `num_groups'
    return local by     = "`origby'"
    return local mmdtype = "`mmdtype'"

    * ------------------------------------------------------------
    * posthoc: mismo patron de kstest -- una llamada por par, con
    * las 4 correcciones de comparaciones multiples. El chequeo de
    * ksonly/mmdonly va ANTES de calcular/imprimir cada tabla (no
    * despues -- si va despues, con ksonly igual se intenta armar e
    * imprimir la tabla de MMD, llena de missing). Cada estadistico
    * guarda su PROPIA matriz de retorno (pairwise_ks / pairwise_mmd)
    * -- una sola return matrix compartida entre los dos se pisaria
    * a si misma en la segunda vuelta del loop.
    * ------------------------------------------------------------
    if "`posthoc'" != "" {
        local npairs = `num_groups' * (`num_groups' - 1) / 2
        tempname PHraw
        matrix `PHraw' = J(`npairs', 4, .)
        tempvar touse2
        qui gen byte `touse2' = .

        local pr = 0
        forvalues a = 1/`=`num_groups'-1' {
            forvalues b = `=`a'+1'/`num_groups' {
                local ++pr
                qui replace `touse2' = `touse' & inlist(`by', `grpval`a'', `grpval`b'')
                tempname RES2
                mata: ksmmd_run("`depvar'", "`by'", "`w'", "`touse2'", `reps', ///
                    0, `bw', `nfeatures', "`mmdtype'", `do_ks', `do_mmd', "`RES2'")
                matrix `PHraw'[`pr',1] = `RES2'[1,1]
                matrix `PHraw'[`pr',2] = `RES2'[1,2]
                matrix `PHraw'[`pr',3] = `RES2'[1,3]
                matrix `PHraw'[`pr',4] = `RES2'[1,4]
                local rn`pr' "`grouplabel`a'' vs `grouplabel`b''"
                local rownames `"`rownames' "`rn`pr''""'
            }
        }

        foreach cual in KS MMD {
            if "`cual'"=="KS"  & !`do_ks'  continue
            if "`cual'"=="MMD" & !`do_mmd' continue

            local col = cond("`cual'"=="KS", 2, 4)
            tempname PH_`cual'
            mata: st_matrix("`PH_`cual''", (st_matrix("`PHraw'")[.,`=`col'-1'], ///
                st_matrix("`PHraw'")[.,`col'], ///
                ksmmd_padjust(st_matrix("`PHraw'")[.,`col'])))
            matrix colnames `PH_`cual'' = Stat P_raw P_bonf P_sidak P_holm P_fdr
            matrix rownames `PH_`cual'' = `rownames'

            local maxlen = strlen("Groups")
            forvalues pr = 1/`npairs' {
                local len = strlen("`rn`pr''")
                if `len' > `maxlen' local maxlen = `len'
            }
            local maxlen = `maxlen' + 2
            local tablewidth = `maxlen' + 60

            di as txt _n "Post-hoc pairwise -- `cual' (" as res `npairs' as txt " pares)"
            if "`cual'" == "KS" {
                di as txt "Ho: F_a(x) = F_b(x) for all x   (per pair below)"
            }
            else {
                di as txt "Ho: mu_a = mu_b in RKHS   (per pair below)"
            }
            di "{hline `tablewidth'}"
            di as txt %-`maxlen's "Groups" "     Stat     {it:P}_raw    {it:P}_bonf   {it:P}_sidak    {it:P}_holm     {it:P}_fdr"
            di "{hline `tablewidth'}"
            forvalues pr = 1/`npairs' {
                di as txt %-`maxlen's "`rn`pr''" as res ///
                    %9.4f `PH_`cual''[`pr',1] " " %9.4f `PH_`cual''[`pr',2] " " %9.4f `PH_`cual''[`pr',3] " " ///
                    %9.4f `PH_`cual''[`pr',4] " " %9.4f `PH_`cual''[`pr',5] " " %9.4f `PH_`cual''[`pr',6]
            }
            di "{hline `tablewidth'}"
            if "`cual'"=="KS"  return matrix pairwise_ks  = `PH_`cual''
            if "`cual'"=="MMD" return matrix pairwise_mmd = `PH_`cual''
        }
        return scalar npairs = `npairs'
    }

    * ------------------------------------------------------------
    * graph: ECDFs ponderadas por grupo -- mismo tipo de grafico
    * que kstest ..., graph (reimplementado aca, no llama a kstest).
    * ------------------------------------------------------------
    if "`graph'" != "" {
        tempname M
        mata: ksmmd_ecdf_wrap("`depvar'", "`by'", "`w'", "`touse'", "`M'")

        preserve
        quietly drop _all
        quietly svmat `M', names(col)
        quietly rename c1 x
        forvalues j = 1/`num_groups' {
            local jj = `j' + 1
            quietly rename c`jj' S`j'
        }
        local sbarcol = `num_groups' + 2
        quietly rename c`sbarcol' Sbar

        local plotcmd ""
        local legendorder ""
        forvalues j = 1/`num_groups' {
            local plotcmd `"`plotcmd' (line S`j' x, sort connect(stairstep))"'
            local legendorder `"`legendorder' `j' "`grouplabel`j''""'
        }
        local plotcmd `"`plotcmd' (line Sbar x, sort connect(stairstep) lpattern(dash) lcolor(black) lwidth(medthick))"'
        local sbarnum = `num_groups' + 1
        local legendorder `"`legendorder' `sbarnum' "Pooled""'

        local cdftitle "Empirical CDFs"
        local cdfytitle "Cumulative proportion"
        if `hasweight' {
            local cdftitle "Weighted empirical CDFs"
            local cdfytitle "Weighted cumulative proportion"
        }

        local subt "KS T=`: display %5.3f `T_KS''"
        if `do_mmd' local subt "`subt', MMD(`mmdtype')=`: display %5.3f `T_MMD''"

        quietly twoway `plotcmd',                    ///
            legend(order(`legendorder'))              ///
            ytitle("`cdfytitle'")                     ///
            xtitle("`depvar'")                        ///
            title("`cdftitle'")                       ///
            subtitle("`num_groups'-sample ksmmd -- `subt'") ///
            name(ksmmd_ecdf, replace)
        restore
    }

    if `needrecode' {
        capture drop `numby'
    }
end

version 11.0
mata:

// ---------------------------------------------------------------
// Punto de entrada: ordena y UNA vez, calcula todo lo que NO depende
// de la permutacion de etiquetas una sola vez (jump-mask y Fcum para
// KS; mu_pool para MMD vspool), y procesa las permutaciones en
// BLOQUES (chunk x N) via ksmmd_ks_T_batch()/ksmmd_mmd_T_batch(), en
// vez de una permutacion a la vez -- ver nota v0.3 en el encabezado
// del .ado (motivo: v0.2 solo ganaba ~4-5x contra mmd_2s en vez del
// ~N/D esperado, porque el loop for(r=1;r<=reps;r++) llamaba a
// ksmmd_ks_T()/ksmmd_mmd_T() UNA permutacion a la vez, sin aprovechar
// BLAS). Devuelve una matriz Stata 1x4: T_KS P_KS T_MMD P_MMD (missing
// en la posicion que no se pidio via do_ks/do_mmd).
// ---------------------------------------------------------------
void ksmmd_run(string scalar depvar, string scalar byvar, string scalar wvar,
    string scalar touse, real scalar reps, real scalar showdots,
    real scalar bw, real scalar nfeatures, string scalar mmdtype,
    real scalar do_ks, real scalar do_mmd, string scalar resname)
{
    real vector y, g, w, nonmiss, idx, y_sorted, w_sorted, g_sorted, groups
    real matrix Phi, Phi_sorted, label_matrix, mu_pool
    real scalar N, T_KS_obs, T_MMD_obs, count_ks, count_mmd
    real scalar chunk, done, thisB, Wtot, i
    real rowvector Fcumrow, jumpmask
    real vector T_KS_perm, T_MMD_perm
    real matrix RES
    // -- solo para mmdtype(fuse): grilla de bandwidths ancladas en la
    // heuristica de mediana. Phi/mu_pool de LOS G puntos de grilla se
    // guardan uno al lado del otro en una sola matriz (N x G*nfeatures /
    // 1 x G*nfeatures), mismo patron de "bloques de columnas" que ya usa
    // ksmmd_mmd_T_batch() para mu_all (ver mas abajo) -- se prefiere a
    // un vector de punteros por ser el mismo idioma que el resto de este
    // archivo ya usa y prueba. Fijos, no dependen de la permutacion: se
    // calculan una sola vez aca, igual que Phi_sorted/mu_pool para
    // vspool/maxpairwise.
    real scalar is_fuse, bw_heur, G, gi, fuse_lam, c0, c1
    real vector fuse_mult, nhatG
    real matrix Phi_grid_sorted, mu_pool_grid

    st_view(y = ., ., depvar, touse)
    st_view(g = ., ., byvar, touse)
    st_view(w = ., ., wvar, touse)

    nonmiss = (y :!= . :& g :!= .)
    y = select(y, nonmiss)
    g = select(g, nonmiss)
    w = select(w, nonmiss)
    N = rows(y)

    idx = order(y, 1)
    y_sorted = y[idx]
    w_sorted = w[idx]
    g_sorted = g[idx]
    groups = uniqrows(g_sorted)

    is_fuse = (do_mmd & mmdtype == "fuse")
    if (do_mmd & !is_fuse) {
        Phi = ksmmd_rff_features(y, nfeatures, bw)
        Phi_sorted = Phi[idx, .]
        Wtot = sum(w_sorted)
        mu_pool = (w_sorted' * Phi_sorted) / Wtot
    }
    else if (is_fuse) {
        // grilla validada por simulacion (Tipo I, R=20000, k=2 y k=4 --
        // ver sim/resultados_ksmmd_mmd_fuse_2muestras_tipo1.txt y
        // sim/resultados_ksmmd_mmd_fuse_4muestras_tipo1.txt) y robusta a
        // dos tipos de alternativa distintos, corrimiento de ubicacion y
        // diferencia de escala (sim/prototipo_mmd_fuse_sistematico.py,
        // sim/prototipo_mmd_fuse_escala.py) -- NO configurable via
        // opciones del .ado, ver nota en el encabezado del archivo.
        // bw() del usuario se IGNORA aca (el .ado avisa si se paso uno):
        // la grilla siempre se ancla en la heuristica de mediana interna,
        // que es lo unico que se valido.
        fuse_mult = (1.0, 1.5, 2.0, 3.0)
        fuse_lam = 0.1
        G = cols(fuse_mult)
        bw_heur = ksmmd_bw_heuristic(y)
        Wtot = sum(w_sorted)
        Phi_grid_sorted = J(N, G*nfeatures, .)
        mu_pool_grid = J(1, G*nfeatures, .)
        nhatG = J(1, G, .)
        for (gi=1; gi<=G; gi++) {
            c0 = (gi-1)*nfeatures + 1
            c1 = gi*nfeatures
            Phi = ksmmd_rff_features(y, nfeatures, bw_heur * fuse_mult[gi])
            Phi_grid_sorted[., c0::c1] = Phi[idx, .]
            mu_pool_grid[1, c0::c1] = (w_sorted' * Phi_grid_sorted[., c0::c1]) / Wtot
            nhatG[gi] = ksmmd_nhat(Phi_grid_sorted[., c0::c1])
        }
    }

    // Fcum (peso pooled acumulado hasta cada posicion) y el jump-mask
    // (que posiciones son puntos de salto de y_sorted, mas la ultima
    // posicion, siempre excluida) NO dependen de la etiqueta de grupo
    // -- se calculan UNA sola vez, no por permutacion ni por bloque.
    if (do_ks) {
        Fcumrow = runningsum(w_sorted)' :/ sum(w_sorted)
        jumpmask = J(1, N, 0)
        jumpmask[N] = -1e300
        for (i=1; i<=N-1; i++) {
            if (y_sorted[i] == y_sorted[i+1]) jumpmask[i] = -1e300
        }
    }

    // observado -- se calcula con la matriz de UNA sola "permutacion"
    // (la asignacion real, sin permutar), reusando el mismo codigo
    // vectorizado que el remuestreo.
    if (do_ks) {
        T_KS_obs = ksmmd_ks_T_batch(w_sorted, g_sorted', groups, Fcumrow, jumpmask)[1]
    }
    if (do_mmd & !is_fuse) {
        T_MMD_obs = ksmmd_mmd_T_batch(Phi_sorted, w_sorted, g_sorted', mmdtype, groups, mu_pool)[1]
    }
    else if (is_fuse) {
        T_MMD_obs = ksmmd_mmd_fuse_T_batch(Phi_grid_sorted, w_sorted, g_sorted', groups, mu_pool_grid, nhatG, fuse_lam)[1]
    }

    // Tamano de bloque: acota memoria (permutaciones simultaneas x N)
    // a ~60 millones de celdas (~480MB) por matriz de trabajo, entre 10
    // y 1000 permutaciones por bloque -- ver nota v0.3 en el encabezado.
    // (El presupuesto original de ~5M celdas / max 200 por bloque era
    // demasiado chico: en Stata real, sobre datos reales de produccion
    // N=127,274 con reps(200), dio chunk=39, o sea ceil(200/39)=6 bloques -- 6 pasadas
    // completas del loop de N iteraciones en ksmmd_rowcumsum() por cada
    // uno de los k grupos, en vez de 1 sola si entra todo en un bloque.
    // Eso explico por que ksonly mejoro mucho menos (~1.3x) que mmdonly
    // (~3.4x) en la primera corrida real de v0.3: para KS, el costo
    // dominante es justamente ese loop de N iteraciones, que se repite
    // una vez por bloque -- menos bloques, menos repeticiones.)
    chunk = floor(60000000 / N)
    if (chunk < 10) chunk = 10
    if (chunk > 1000) chunk = 1000

    count_ks = 0
    count_mmd = 0
    done = 0
    while (done < reps) {
        thisB = min((chunk, reps - done))
        label_matrix = ksmmd_permute_labels_batch(g_sorted, thisB)
        if (do_ks) {
            T_KS_perm = ksmmd_ks_T_batch(w_sorted, label_matrix, groups, Fcumrow, jumpmask)
            count_ks = count_ks + sum(T_KS_perm :>= T_KS_obs)
        }
        if (do_mmd & !is_fuse) {
            T_MMD_perm = ksmmd_mmd_T_batch(Phi_sorted, w_sorted, label_matrix, mmdtype, groups, mu_pool)
            count_mmd = count_mmd + sum(T_MMD_perm :>= T_MMD_obs)
        }
        else if (is_fuse) {
            T_MMD_perm = ksmmd_mmd_fuse_T_batch(Phi_grid_sorted, w_sorted, label_matrix, groups, mu_pool_grid, nhatG, fuse_lam)
            count_mmd = count_mmd + sum(T_MMD_perm :>= T_MMD_obs)
        }
        done = done + thisB
        // un dot = un BLOQUE de (hasta) `chunk` permutaciones procesado,
        // no una permutacion individual -- mostrar progreso por
        // permutacion forzaria a volver al loop de a una que se elimino.
        if (showdots == 1) ksmmd_dots_tick(done, reps)
    }

    RES = J(1, 4, .)
    if (do_ks) {
        RES[1,1] = T_KS_obs
        RES[1,2] = (count_ks + 1) / (reps + 1)
    }
    if (do_mmd) {
        RES[1,3] = T_MMD_obs
        RES[1,4] = (count_mmd + 1) / (reps + 1)
    }
    st_matrix(resname, RES)
}

// ---------------------------------------------------------------
// Genera B permutaciones independientes de la etiqueta de grupo
// (fijas por multiset -- mismos tamanos de grupo que g_sorted) a lo
// largo de las N posiciones ORDENADAS por y, devueltas como matriz
// (B x N) -- una fila por permutacion. Cada fila usa la misma
// equivalencia matematica que v0.2 (order()+g[idx], ver encabezado
// del .ado): lo unico que cambia es que arma B de una vez en vez de
// una por llamada. El propio sorteo de cada permutacion (order() por
// fila) sigue siendo O(N log N) por fila -- no hay forma de
// vectorizarlo sin perder independencia entre permutaciones -- pero
// eso nunca fue el cuello de botella; lo que se vectoriza es el
// calculo de los estadisticos sobre el bloque completo (ver
// ksmmd_ks_T_batch()/ksmmd_mmd_T_batch()).
// ---------------------------------------------------------------
real matrix ksmmd_permute_labels_batch(real vector g_sorted, real scalar B)
{
    real scalar N, r
    real matrix keys, out

    N = rows(g_sorted)
    keys = runiform(B, N)
    out = J(B, N, .)
    for (r=1; r<=B; r++) {
        out[r,.] = g_sorted[order(keys[r,.]', 1)]'
    }
    return(out)
}

// ---------------------------------------------------------------
// Suma acumulada A LO LARGO DE LAS COLUMNAS (dimension N) de una
// matriz (B x N), fila por fila -- equivalente a runningsum() aplicado
// a cada fila por separado, pero runningsum() NATIVO DE MATA SOLO
// ACEPTA UN VECTOR (error 3201 "vector required" si se le pasa una
// matriz de B>1 filas: esto se detecto recien en Stata real, con
// reps(200) -- con B=1 en el calculo del observado no fallaba, porque
// ahi la matriz transpuesta SI es un vector, lo que oculto el error
// hasta correrlo con permutaciones de verdad). No existe una version
// matricial de runningsum() en Mata base ni una forma de vectorizarla
// por columnas de una sola vez sin materializar una matriz triangular
// N x N (inviable en memoria a N~127mil) -- asi que esto SIGUE
// iterando sobre las N posiciones, pero UNA vez por bloque (no una vez
// por permutacion): cada paso acumula un vector de largo B de una
// sola operacion vectorizada, en vez de un escalar. Es el mismo motivo
// que ya hace mas rapido a v0.3 que v0.2 (loop de N iteraciones por
// BLOQUE de `chunk` permutaciones, no de N iteraciones por
// PERMUTACION).
// ---------------------------------------------------------------
real matrix ksmmd_rowcumsum(real matrix M)
{
    real scalar B, N, i
    real matrix out
    real vector running

    B = rows(M)
    N = cols(M)
    out = J(B, N, .)
    running = J(B, 1, 0)
    for (i=1; i<=N; i++) {
        running = running :+ M[.,i]
        out[.,i] = running
    }
    return(out)
}

// ---------------------------------------------------------------
// T de Kiefer para un BLOQUE de B asignaciones de etiqueta a la vez
// (label_matrix: B x N, cada fila una asignacion -- permutada o la
// real). Mismo algebra que ksmmd_ks_T() de v0.2 (identico en espiritu
// a ksk_compute() de kstest.ado), reorganizada: para cada grupo j se
// arma el indicador (B x N) de "posicion i pertenece al grupo j en la
// permutacion b", se multiplica por el peso (broadcast) y se usa
// ksmmd_rowcumsum() para obtener, para las B filas a la vez, la suma
// acumulada que v0.2 hacia con un for(i=1;...) escalar por permutacion
// (una llamada por bloque en vez de una por permutacion). Fcumrow/
// jumpmask (fijos, no dependen de la permutacion) se calculan UNA vez
// en ksmmd_run() y se pasan como parametro. Preserva el caso especial
// k==2 (val = |Ecum_1-Ecum_2|) frente al caso general k>2 (val =
// sum_j Wsum_j*(Ecum_j-Fcum)^2) exactamente como v0.2 -- confirmado
// que NO son formas equivalentes bajo pesos que varian por permutacion.
// ---------------------------------------------------------------
real vector ksmmd_ks_T_batch(real vector w_sorted, real matrix label_matrix,
    real vector groups, real rowvector Fcumrow, real rowvector jumpmask)
{
    real scalar N, k, j, B
    real rowvector wrow
    real vector Wsum_j
    real matrix Ind, Wmat, Ecum_j, Ecum1, Ecum2, Val, T_accum

    N = cols(label_matrix)
    k = rows(groups)
    B = rows(label_matrix)
    wrow = w_sorted'

    if (k == 2) {
        Ind = (label_matrix :== groups[1])
        Wmat = Ind :* wrow
        Wsum_j = rowsum(Wmat)
        Ecum1 = ksmmd_rowcumsum(Wmat) :/ Wsum_j

        Ind = (label_matrix :== groups[2])
        Wmat = Ind :* wrow
        Wsum_j = rowsum(Wmat)
        Ecum2 = ksmmd_rowcumsum(Wmat) :/ Wsum_j

        Val = abs(Ecum1 :- Ecum2)
    }
    else {
        T_accum = J(B, N, 0)
        for (j=1; j<=k; j++) {
            Ind = (label_matrix :== groups[j])
            Wmat = Ind :* wrow
            Wsum_j = rowsum(Wmat)
            Ecum_j = ksmmd_rowcumsum(Wmat) :/ Wsum_j
            T_accum = T_accum :+ Wsum_j :* (Ecum_j :- Fcumrow):^2
        }
        Val = T_accum
    }

    Val = Val :+ jumpmask
    // v0.2 arrancaba Dmax=0 y solo lo actualizaba en puntos de salto
    // -- si y_sorted no tiene NINGUN punto de salto (todos los valores
    // empatados), Dmax quedaba en 0. Aca equivale a agregar una
    // columna de ceros antes del maximo (si todas las columnas reales
    // quedaron enmascaradas en -1e300, el maximo cae en esa columna).
    return(rowmax((Val, J(B,1,0))))
}

// ---------------------------------------------------------------
// Heuristica de mediana (Garreau, Jitkrittum & Kanagawa 2017) para el
// bandwidth del kernel RBF, sobre una submuestra de hasta 2000
// observaciones (evita el costo O(n^2) de la mediana exacta de
// distancias par-a-par en el dataset completo). Extraida a funcion
// propia (antes vivia inline dentro de ksmmd_rff_features) para que
// mmdtype(fuse) pueda calcularla UNA vez y reusarla como ancla de su
// grilla de bandwidths -- el resto del codigo (orden de los sorteos
// aleatorios) queda identico, asi que no cambia el resultado de
// mmdtype(vspool)/mmdtype(maxpairwise) con la misma seed.
// ---------------------------------------------------------------
real scalar ksmmd_bw_heuristic(real vector y)
{
    real scalar n, nsub, i, med, p, q
    real vector ysub, dif

    n = rows(y)
    nsub = min((n, 2000))
    ysub = y[order(runiform(n,1),1)[1::nsub]]
    dif = J(nsub*(nsub-1)/2, 1, .)
    i = 0
    for (p=1; p<=nsub-1; p++) {
        for (q=p+1; q<=nsub; q++) {
            i++
            dif[i] = abs(ysub[p] - ysub[q])
        }
    }
    med = ksmmd_median(dif)
    if (med <= 0) med = 1
    return(med)
}

// ---------------------------------------------------------------
// Random Fourier Features para el kernel RBF exp(-(x-y)^2/(2*bw^2)):
// phi(x) = sqrt(2/D) * cos(omega*x + b), omega ~ N(0, 1/bw^2),
// b ~ Uniform(0, 2*pi) -- Rahimi & Recht (2007). bw<=0 dispara
// ksmmd_bw_heuristic() arriba.
// ---------------------------------------------------------------
real matrix ksmmd_rff_features(real vector y, real scalar D, real scalar bw)
{
    real vector omega, b
    real matrix Phi

    if (bw <= 0) bw = ksmmd_bw_heuristic(y)

    omega = rnormal(D, 1, 0, 1/bw)
    b = runiform(D, 1) :* (2*pi())

    Phi = sqrt(2/D) :* cos(y * omega' :+ b')
    return(Phi)
}

real scalar ksmmd_median(real vector x)
{
    real vector xs
    real scalar n, mid
    xs = sort(x, 1)
    n = rows(xs)
    mid = ceil(n/2)
    if (mod(n,2) == 0) return((xs[mid] + xs[mid+1])/2)
    else return(xs[mid])
}

// ---------------------------------------------------------------
// T_MMD para un BLOQUE de B asignaciones de etiqueta a la vez
// (label_matrix: B x N). Mismo algebra que ksmmd_mmd_T() de v0.2 --
// "vspool" (default) o "maxpairwise", ver encabezado del .ado para
// las citas -- reorganizada para las B permutaciones a la vez: para
// cada grupo j se arma el indicador (B x N), se multiplica por Phi
// (multiplicacion de matrices B x N por N x D, BLAS) para obtener de
// una sola vez la media ponderada mu_j de cada una de las B
// permutaciones, guardadas una al lado de la otra en mu_all (B x
// k*D) e indexadas por bloque de columnas via rango (j-1)*D+1::j*D.
// mu_pool (fijo, no depende de la permutacion) se calcula UNA vez en
// ksmmd_run() y se pasa como parametro -- misma logica que ya se
// valido en Python/numpy en sim/simulacion_ksmmd_mmd_tipo1.py.
// ---------------------------------------------------------------
real vector ksmmd_mmd_T_batch(real matrix Phi, real vector w, real matrix label_matrix,
    string scalar mmdtype, real vector groups, real matrix mu_pool)
{
    real scalar k, j, l, D, B, c0, c1, c0l, c1l
    real matrix Ind, Wmat, mu_all, Wsum_all
    real vector T, dist2, wjl

    k = rows(groups)
    B = rows(label_matrix)
    D = cols(Phi)

    mu_all = J(B, k*D, .)
    Wsum_all = J(B, k, .)
    for (j=1; j<=k; j++) {
        Ind = (label_matrix :== groups[j])
        Wmat = Ind :* w'
        Wsum_all[.,j] = rowsum(Wmat)
        c0 = (j-1)*D+1
        c1 = j*D
        mu_all[., c0::c1] = (Wmat * Phi) :/ Wsum_all[.,j]
    }

    T = J(B, 1, 0)
    if (mmdtype == "vspool") {
        for (j=1; j<=k; j++) {
            c0 = (j-1)*D+1
            c1 = j*D
            T = T :+ Wsum_all[.,j] :* rowsum((mu_all[.,c0::c1] :- mu_pool):^2)
        }
    }
    else {
        // maxpairwise (Kim 2021, forma ponderada -- Remark 3.3):
        // max_{k<l} [Wsum_k*Wsum_l/(Wsum_k+Wsum_l)] * ||mu_k-mu_l||^2
        for (j=1; j<=k-1; j++) {
            c0 = (j-1)*D+1
            c1 = j*D
            for (l=j+1; l<=k; l++) {
                c0l = (l-1)*D+1
                c1l = l*D
                dist2 = rowsum((mu_all[.,c0::c1] :- mu_all[.,c0l::c1l]):^2)
                wjl = (Wsum_all[.,j] :* Wsum_all[.,l]) :/ (Wsum_all[.,j] :+ Wsum_all[.,l])
                T = rowmax((T, wjl :* dist2))
            }
        }
    }
    return(T)
}

// ---------------------------------------------------------------
// N-hat(bw): normalizador invariante a la permutacion que usa
// mmdtype(fuse) para poner en la misma escala el T_MMD de cada
// bandwidth de la grilla antes de combinarlos (si no se normaliza,
// el bandwidth con features de mayor varianza domina el
// log-sum-exp sin que eso refleje mas evidencia real -- Biggs,
// Schrab & Gretton 2023, seccion 3.2). Definicion (su N_hat(Z)):
// promedio de k(Zi,Zj)^2 sobre los pares i<j de una submuestra de
// hasta 300 observaciones -- aca aproximado via RFF (Phi*Phi' en
// vez del kernel exacto, mismo criterio de aproximacion que el
// resto del comando). Version vectorizada de
// sim/*_fuse_*.py:nhat_of_kernel() (que usaba un loop sobre indices
// triangulares en numpy): sum(K^2) sobre TODA la matriz incluye la
// diagonal y cada par fuera de la diagonal DOS veces (K es
// simetrica), asi que restar la diagonal y dividir por 2 en vez de
// por 1 dosifica exactamente el promedio sobre los pares i<j.
// ---------------------------------------------------------------
real scalar ksmmd_nhat(real matrix Phi)
{
    real scalar N, nsub, cnt, s
    real vector idx
    real matrix Phisub, Ksub

    N = rows(Phi)
    nsub = min((N, 300))
    idx = order(runiform(N,1), 1)[1::nsub]
    Phisub = Phi[idx, .]
    Ksub = Phisub * Phisub'
    cnt = nsub * (nsub - 1) / 2
    s = (sum(Ksub:^2) - sum(diagonal(Ksub):^2)) / (2 * cnt)
    if (s < 1e-12) s = 1e-12
    return(s)
}

// ---------------------------------------------------------------
// T_MMD-FUSE para un BLOQUE de B asignaciones de etiqueta a la vez
// -- MMD-FUSE (Biggs, Schrab & Gretton 2023, NeurIPS,
// arXiv:2306.08777): combina el T_MMD "vspool" (mmdtype(vspool),
// nunca maxpairwise -- la grilla/lambda de abajo solo se valido
// contra vspool) de VARIOS bandwidths via un soft-max regularizado
// por KL en vez de un solo bandwidth elegido por heuristica de
// mediana, evitando tanto la correccion de Bonferroni como partir
// la muestra:
//   T_FUSE = (1/lambda) * log( mean_g[ exp(lambda * T_g) ] )
// con T_g = T_MMD_vspool(bandwidth_g) / sqrt(Nhat(bandwidth_g)) --
// la normalizacion por Nhat es la que hace que el resultado no
// dependa de la escala arbitraria de cada bandwidth (ver
// ksmmd_nhat() arriba). Phi_grid/mu_pool_grid traen los G puntos de
// grilla uno al lado del otro en bloques de nfeatures() columnas
// (mismo patron "c0::c1" que mu_all en ksmmd_mmd_T_batch), calculados
// una sola vez en ksmmd_run() -- ni Phi ni mu_pool dependen de la
// permutacion. El teorema de calibracion por permutacion (Hemerik &
// Goeman 2018) vale para CUALQUIER estadistico fijo, asi que corregir
// por la grilla/lambda elegidas de antemano no hace falta -- lo que
// si hay que declarar con honestidad es que esa grilla ({1x,1.5x,
// 2x,3x} * heuristica de mediana) y lambda=0.1 salen de una busqueda
// en Python/numpy sobre datos simulados (sim/prototipo_mmd_fuse*.py),
// no de la literatura -- ver la nota en el encabezado del .ado.
// ---------------------------------------------------------------
real vector ksmmd_mmd_fuse_T_batch(real matrix Phi_grid, real vector w,
    real matrix label_matrix, real vector groups, real matrix mu_pool_grid,
    real vector nhatG, real scalar lam)
{
    real scalar G, D, gi, c0, c1
    real matrix Tg
    real vector m, fused

    G = cols(nhatG)
    D = cols(Phi_grid) / G
    Tg = J(rows(label_matrix), G, .)
    for (gi=1; gi<=G; gi++) {
        c0 = (gi-1)*D + 1
        c1 = gi*D
        Tg[.,gi] = ksmmd_mmd_T_batch(Phi_grid[.,c0::c1], w, label_matrix, "vspool", groups, mu_pool_grid[1,c0::c1]) :/ sqrt(nhatG[gi])
    }
    m = rowmax(Tg)
    fused = m :+ ln(rowsum(exp(lam :* (Tg :- m))) :/ G) :/ lam
    return(fused)
}

// ---------------------------------------------------------------
// ECDF ponderada por grupo -- misma logica que kk_ecdf() de
// kstest.ado, reimplementada aca para no depender de ese archivo.
// ---------------------------------------------------------------
void ksmmd_ecdf_wrap(string scalar depvar, string scalar byvar, string scalar wvar,
    string scalar touse, string scalar matname)
{
    real vector y, g, w, groups
    y = st_data(., depvar, touse)
    g = st_data(., byvar, touse)
    w = st_data(., wvar, touse)
    groups = uniqrows(g)
    st_matrix(matname, ksmmd_ecdf(y, g, w, groups))
}

real matrix ksmmd_ecdf(real vector y, real vector g, real vector w, real vector groups)
{
    real scalar n, k, j, i, Wtot, Fcum, m
    real vector idx, ys, gs, ws, Wsum, Ecum, ux_v, Sbar_v
    real matrix S_v

    n = rows(y)
    k = rows(groups)
    idx = order(y, 1)
    ys = y[idx]; gs = g[idx]; ws = w[idx]

    Wsum = J(k, 1, 0)
    for (j=1; j<=k; j++) Wsum[j] = sum(select(w, g :== groups[j]))
    Wtot = sum(w)

    Ecum = J(k, 1, 0)
    Fcum = 0
    ux_v   = J(n-1, 1, .)
    S_v    = J(n-1, k, .)
    Sbar_v = J(n-1, 1, .)
    m = 0

    for (i=1; i<=n-1; i++) {
        j = selectindex(groups :== gs[i])
        Ecum[j] = Ecum[j] + ws[i] / Wsum[j]
        Fcum = Fcum + ws[i] / Wtot
        if (ys[i] != ys[i+1]) {
            m = m + 1
            ux_v[m] = ys[i]
            S_v[m,.] = Ecum'
            Sbar_v[m] = Fcum
        }
    }
    ux_v   = ux_v[1::m]
    S_v    = S_v[1::m,.]
    Sbar_v = Sbar_v[1::m]
    return((ux_v, S_v, Sbar_v))
}

// ---------------------------------------------------------------
// Ajustes por comparaciones multiples (Bonferroni, Sidak, Holm,
// Benjamini-Hochberg FDR) -- misma logica que kstestk_padjust() en
// kstest.ado, reimplementada con nombre propio (ksmmd_padjust) para
// no depender de ese archivo ni colisionar si los dos estan cargados
// en la misma sesion.
// ---------------------------------------------------------------
real matrix ksmmd_padjust(real vector p)
{
    real scalar m, i, val, runmax, runmin
    real vector bonf, idx, ps, adjs, holm, idxa, psa, adja, fdr, sidak

    m = rows(p)

    // Bonferroni
    bonf = p :* m
    for (i=1; i<=m; i++) if (bonf[i] > 1) bonf[i] = 1

    // Sidak
    sidak = 1 :- (1 :- p):^m

    // Holm step-down
    idx = order(p, 1)
    ps  = p[idx]
    adjs = J(m, 1, .)
    runmax = 0
    for (i=1; i<=m; i++) {
        val = (m - i + 1) * ps[i]
        if (val > 1) val = 1
        if (val < runmax) val = runmax
        runmax = val
        adjs[i] = val
    }
    holm = J(m, 1, .)
    for (i=1; i<=m; i++) holm[idx[i]] = adjs[i]

    // Benjamini-Hochberg FDR step-up
    idxa = order(p, 1)
    psa  = p[idxa]
    adja = J(m, 1, .)
    runmin = 1
    for (i=m; i>=1; i--) {
        val = (m / i) * psa[i]
        if (val > 1) val = 1
        if (val > runmin) val = runmin
        runmin = val
        adja[i] = val
    }
    fdr = J(m, 1, .)
    for (i=1; i<=m; i++) fdr[idxa[i]] = adja[i]

    return((bonf, sidak, holm, fdr))
}

// dots -- identico a kstest.ado
void ksmmd_dots_tick(real scalar b, real scalar B)
{
    real scalar pad
    string scalar fmt
    printf(".")
    if (mod(b,50)==0) {
        printf("%5.0f\n", b)
    }
    else if (b==B) {
        pad = 50 - mod(B,50)
        fmt = "%" + strofreal(5*pad+5) + ".0f\n"
        printf(fmt, b)
    }
    displayflush()
}

end
