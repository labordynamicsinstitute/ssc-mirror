*! ksmmd.ado v0.7 - 20sep2026
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
*!                     tamanos desiguales, Zhang, Guo & Zhou (2024, J.
*!                     Econometrics 239(2)) -- son el mismo estadistico salvo
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
*!      sim/prototipo_mmd_fuse_escala.py). [CORREGIDO sep2026, tras leer
*!      el PDF completo de Biggs, Schrab & Gretton: el paper SI da una
*!      recomendacion concreta para lambda -- sus Teoremas 2-3 exigen
*!      lambda asintoticamente proporcional a n para potencia optima, y
*!      en TODOS sus experimentos usa lambda=sqrt(n(n-1)) (n=tamano de
*!      la muestra mas chica). Para un survey con n en cientos/miles eso
*!      da lambda del orden de cientos/miles, muy distinto de lambda=0.1
*!      fijo. ksmmd se APARTA DELIBERADAMENTE de esa recomendacion (no
*!      es que no exista una): el paper solo la valida en el caso exacto
*!      (kernel completo, no RFF) y no ponderado, mientras que lambda=0.1
*!      sale de la busqueda propia descrita abajo, en el contexto
*!      ponderado/RFF real de este comando. Probar lambda~n en ese
*!      contexto queda como mejora futura sujeta a nueva simulacion de
*!      potencia antes de reemplazar el valor fijo actual.]
*!      Motivo de la busqueda original: una primera prueba con
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
*!      bandwidths grandes) se derrumbaban en el otro (mecanismo: Reddi,
*!      Ramdas, Poczos, Singh & Wasserman 2015, AISTATS/PMLR v38, Lemma
*!      1, PDF leido completo -- MMD^2 poblacional con kernel Gaussiano
*!      escala como 2*shift^2/bandwidth^2 (1+o(1)): un bandwidth grande
*!      respecto al corrimiento de ubicacion diluye la senal de forma
*!      CUADRATICA, no exponencial [CORREGIDO sep2026: la version
*!      anterior de este parrafo decia "exponencialmente chico", frase
*!      que no esta respaldada por el paper -- el propio Teorema 1 de
*!      potencia del paper es ademas un resultado explicito de ALTA
*!      DIMENSION (n,d -> infinito conjuntamente, bandwidth
*!      gamma=Omega(sqrt(d))), que no aplica literalmente a una variable
*!      escalar como edad (d=1); lo que si generaliza por analogia
*!      algebraica a cualquier dimension, incluido d=1, es el mecanismo
*!      del Lemma 1 citado arriba]. Eso explica por que un bandwidth mal
*!      elegido puede no ver una diferencia real que KS si detecta).
*!      NO configurable
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
*!      Se evaluaron tambien 3 papers 2025-2026 (busqueda bibliografica
*!      sep-2026, a pedido explicito del usuario, que pregunto si habia
*!      literatura nueva que mejorara el test de Ho: distribuciones
*!      iguales; el usuario subio los 3 PDFs completos, leidos por
*!      agentes en paralelo):
*!        - Mukherjee, S., Sriperumbudur, B.K. (2025). "Minimax Optimal
*!          Kernel Two-Sample Tests with Random Features." arXiv:
*!          2502.20755v2. AFUERA: estrictamente 2 muestras (sin
*!          generalizacion k-muestral en el paper), sin pesos de
*!          encuesta (grep de texto completo: "weight"/"survey" no
*!          aparecen), y costo CUBICO en nfeatures() (O(l^3), Teorema 14)
*!          en vez del O(N*D) lineal que usa este comando. Su ganancia
*!          (detectar diferencias de forma/varianza con media igual, via
*!          un operador de covarianza espectral-regularizado) ya la
*!          cubre en buena medida el componente KS de este comando.
*!        - Domingo-Enrich, C., Dwivedi, R., Mackey, L. (2025). "Cheap
*!          Permutation Testing." arXiv:2502.07672v3. PROMETEDOR A
*!          FUTURO, no incorporado ahora: agrupa las N unidades en s
*!          bloques y permuta solo los bloques (no las N unidades),
*!          reduciendo el costo de permutacion de O(reps*N^2) a
*!          O(reps*s^2) para estadisticos "cuadraticos" -- 100x-1000x
*!          mas rapido en sus experimentos (validado solo hasta N~33mil,
*!          no a escala de produccion de ksmmd). PERO: grep de texto
*!          completo confirma CERO menciones a pesos de encuesta (el
*!          marco asume medidas empiricas SIN ponderar); la extension a
*!          k>2 grupos es solo un boceto en la seccion de discusion, sin
*!          algoritmo ni prueba de potencia; y el componente KS de este
*!          comando NO es un "quadratic test statistic" en el sentido
*!          del paper (esta basado en el supremo de diferencias de CDFs,
*!          no en una forma cuadratica de medidas empiricas), asi que el
*!          mecanismo de binning solo cubriria la parte MMD/RFF, no KS.
*!          Aplicarlo exigiria: (a) extender su prueba de exactitud bajo
*!          permutacion de bloques al caso ponderado (no trivial -- la
*!          intercambiabilidad bajo H0 con pesos desiguales viajando con
*!          cada unidad no esta resuelta en el paper), y (b) derivar la
*!          version k-muestral. Candidato solido para una futura version
*!          del motor de remuestreo, pendiente de ese trabajo propio.
*!        - Wei, A., Jalali, M., Sutherland, D.J. (2026, TMLR). "Maximum
*!          Mean Discrepancy with Unequal Sample Sizes via Generalized
*!          U-Statistics." arXiv:2512.13997v2 (mismo Sutherland de
*!          Sutherland & Schneider 2015, ya citado arriba). AFUERA en lo
*!          sustantivo: aunque la maquinaria general (Definicion 3.1,
*!          Teorema E.5) esta enunciada para c muestras generico, el
*!          paper nunca la instancia ni la ejemplifica para c>2 -- todos
*!          los resultados con contenido MMD y el experimento (CIFAR-10)
*!          son c=2. Mas importante: grep de texto completo confirma
*!          CERO menciones a "weight"/"survey" -- el paper solo trata
*!          desigualdad de TAMANOS DE MUESTRA (conteos enteros n_j), no
*!          PESOS CONTINUOS w_i dentro de cada grupo. La formula S_j que
*!          ya usa ksmmd_mmd_T_batch() (excluir parejas i=i' ponderadas
*!          por w_i^2 para des-sesgar el termino propio de cada grupo)
*!          NO es un caso particular de este paper -- es una
*!          generalizacion genuina adicional (pesos continuos
*!          intra-grupo) que el paper no cubre; el paper si confirma el
*!          PRINCIPIO general de excluir parejas propias para lograr
*!          insesgadez, ya verificado por cuenta propia en v0.7 (ver
*!          arriba). Idea transferible pero NO citable como resultado
*!          literal del paper: si en el futuro se deriva una calibracion
*!          asintotica (en vez de por permutacion), usar el MINIMO de
*!          los tamanos EFECTIVOS por grupo (tipo Kish, (sum w_i)^2/
*!          sum(w_i^2)) como escala de normalizacion, en vez de la suma
*!          -- es la leccion empirica central del paper (sus Teoremas
*!          3.7/3.9), pero no aplica directamente porque este comando
*!          calibra por permutacion, no por asintotica.
*!      CONCLUSION GENERAL de esta ronda: ninguno de los 3 papers ofrece
*!      una mejora lista para incorporar tal cual a este comando
*!      (k-muestral, ponderado por encuesta, calibrado por permutacion).
*!      El de permutacion barata es el mas prometedor a mediano plazo
*!      para el costo computacional en produccion, pero exige extender
*!      su prueba de validez al caso ponderado antes de confiar en el
*!      control de Tipo I -- trabajo de investigacion propio, no
*!      pendiente de implementarse en esta version.
*!   5. graph: ECDFs ponderadas por grupo, mismo tipo de grafico que
*!      kstest ..., graph -- es la visual natural para el T de Kiefer;
*!      MMD no tiene una curva 1-D propia (vive en el espacio de
*!      features), pero la misma ECDF sigue siendo la referencia visual
*!      util para las dos, dado que operan sobre la misma variable.
*!   6. posthoc: tabla de a pares para AMBOS estadisticos (T_KS y
*!      T_MMD), con las mismas 4 correcciones de comparaciones
*!      multiples que ya usa kstest (Bonferroni/Sidak/Holm/FDR).
*!
*! v0.6 -- revision de la bibliografia contra los PDF completos (el
*! usuario los compartio via Google Drive; 15 de 16 documentos leidos de
*! punta a punta por agentes en paralelo -- falta solo Zhang/Guo/Zhou
*! 2024, detras de paywall de ScienceDirect, no obtenido -- ver NOTA DE
*! VERIFICACION, segunda ronda, al final del bloque de referencias mas
*! abajo). SIN CAMBIOS DE ALGEBRA NI DE MATA -- ningun T_KS/T_MMD/
*! p-valor cambia con esta version, solo texto de documentacion:
*!   - 3 correcciones OBLIGATORIAS de contenido/cita, ya aplicadas
*!     inline en los parrafos correspondientes mas arriba/abajo: la
*!     cota de Sutherland&Schneider (revertida a MMD sin elevar al
*!     cuadrado, cita corregida de "Theorem 1" a "Seccion 3.3" -- mi
*!     propio "arreglo" del 19sep2026, hecho sin el PDF completo, habia
*!     ido en la direccion equivocada), la motivacion de mmdtype(fuse)
*!     (el mecanismo de Reddi et al. es escala CUADRATICA, no
*!     "exponencialmente chico"), y la atribucion de Choi&Kim ("Choi,
*!     I.", no "Choi, S." -- tercer error real de atribucion en esta
*!     bibliografia) -- mas la aclaracion de que el paper MMD-FUSE SI
*!     recomienda un valor de lambda (lambda~n), del que ksmmd se aparta
*!     deliberadamente (no que "no exista recomendacion").
*!   - Mejoras de documentacion agregadas, todas respaldadas por texto
*!     primario (PDF leido completo), sin cambiar codigo:
*!     * Kiefer (1959), Sec. 6: los tests tipo sup (T de Kiefer, KS)
*!       tienen garantia de potencia minima contra CUALQUIER alternativa
*!       puntual; los tests tipo integral (MMD, omega^2) no la tienen --
*!       son complementarios por diseno, cita primaria legitima para el
*!       combo KS+MMD de este comando. El mismo paper tampoco exige que
*!       n_j/N converja -- tranquiliza sobre grupos desbalanceados. El
*!       jumpmask/manejo de empates de este comando ya es coherente con
*!       lo que el propio Kiefer dice sobre F no continua (conservador,
*!       nunca anti-conservador).
*!     * Ong, Chen, Zhu & Zhang (2023) recomiendan textualmente correr
*!       un test tipo MMD Y uno tipo energy-distance juntos, porque en
*!       la practica no se sabe de antemano si la diferencia entre
*!       grupos esta en la media o en la covarianza -- respalda con cita
*!       directa (no solo diseno propio) el combo KS+MMD de este comando.
*!     * Kim (2021), Remark 3.3: guia explicita sobre cuando preferir
*!       maxpairwise (alternativas DISPERSAS -- un solo grupo distinto
*!       de los demas) sobre vspool/fuse (alternativas DENSAS -- varios
*!       grupos difieren): la potencia de estadisticos tipo-promedio cae
*!       con k creciente bajo alternativas dispersas, maxpairwise la
*!       mantiene. La optimalidad minimax de maxpairwise (Sec. 6 del
*!       paper) esta condicionada a supuestos tecnicos de kernel
*!       acotado/subgaussiano y NO se transfiere automaticamente a la
*!       version ponderada por pesos de encuesta que usa este comando.
*!     * Garreau, Jitkrittum & Kanagawa (2017): bw() de este comando usa
*!       la convencion sqrt(Hn) (Hn=mediana de distancias al cuadrado),
*!       que el propio paper reconoce en su nota al pie 1 como variante
*!       real de la literatura (la formula principal del paper es
*!       sqrt(Hn/2)). Su Sec. 4 muestra ademas, empiricamente, que la
*!       heuristica de mediana elige un bandwidth demasiado grande
*!       especificamente cuando la diferencia entre grupos es de
*!       VARIANZA/ESCALA (no de ubicacion) -- respaldo primario adicional
*!       (mas alla de la simulacion propia) para usar mmdtype(fuse)
*!       cuando se sospecha una diferencia de dispersion.
*!     * Rizzo & Szekely (2010, DISCO), Corolario 2: la identidad "cada
*!       grupo contra el pool" (que generaliza el T de Kiefer y la
*!       identidad vspool de este comando) SOLO existe para una forma
*!       CUADRATICA/tipo-RKHS (alpha=2 en su notacion) -- para la energy
*!       distance original de Szekely&Rizzo (2004, alpha=1) no hay tal
*!       forma, solo suma pareada. Confirma formalmente por que vspool
*!       necesita especificamente un kernel (forma cuadratica), no
*!       cualquier distancia.
*!     * Sejdinovic, Sriperumbudur, Gretton & Fukumizu (2013): el
*!       "puente a DISCO/energy distance" de este comando (ver punto 4
*!       arriba) es correcto en espiritu (mismo marco teorico), pero con
*!       una precision: el kernel que hace MMD = energy distance
*!       EUCLIDEA de Rizzo-Szekely no es RBF (es k1(z,z')=0.5*(||z||+
*!       ||z'||-||z-z'||), no acotado). El RBF que usa este comando SI
*!       genera una semimetrica de tipo negativo (rho_RBF=2-2*exp(-
*!       ||z-z'||^2/gamma^2)), pero es una version ACOTADA/saturada de
*!       la euclidea, no la euclidea misma.
*!     * Hemerik & Goeman (2018): la validez exacta de mmdtype(fuse) por
*!       permutacion descansa en 2 condiciones concretas que este
*!       comando ya cumple: (a) el estadistico observado se incluye
*!       como una evaluacion mas (el "+1" en (count+1)/(reps+1)); (b) la
*!       grilla de bandwidths y lambda quedan fijos ANTES de ver las
*!       permutaciones de cada corrida. Nota honesta menor: la exactitud
*!       ESTRICTA (nivel = alpha exacto) requiere ademas ausencia de
*!       empates en la distribucion de T bajo H0 -- con variables de
*!       encuesta con empates (edad en anios, montos redondeados) el
*!       test puede ser LIGERAMENTE CONSERVADOR frente al nominal, nunca
*!       anti-conservador.
*!     * MMD-FUSE (Biggs, Schrab & Gretton 2023): ademas de lambda (ver
*!       correccion obligatoria arriba), la constante de normalizacion
*!       Nhat y la grilla de bandwidths de este comando difieren por
*!       diseno de la Definicion 1 / Apendice A.2 del paper: Nhat aca se
*!       calcula sobre una submuestra de hasta 300 observaciones (no el
*!       dataset agrupado completo, por costo), y la grilla usa 4 puntos
*!       de un solo kernel Gaussiano (vs. 10-20 puntos de 2 familias,
*!       Gaussiano y Laplace, en el paper). Ninguna de las dos
*!       diferencias pone en riesgo la tasa de error Tipo I (eso lo
*!       garantiza el teorema de permutacion para cualquier estadistico
*!       fijo, ver Hemerik&Goeman arriba) -- son posibles perdidas de
*!       POTENCIA, no de validez, ya cubiertas por la simulacion propia.
*!   - Mejoras de DISENO identificadas en la misma lectura: en esta
*!     version (v0.6) quedaron documentadas como trabajo futuro,
*!     pendientes de una nueva simulacion de tasa de error Tipo I antes
*!     de implementarse. Las 5 se implementaron y se validaron en la
*!     version SIGUIENTE (v0.7, ver el bloque de arriba) -- el detalle
*!     de cada una vive ahora en ese changelog.
*!
*! v0.7 -- implementa las 5 mejoras de diseno que v0.6 habia dejado
*! como trabajo futuro (leidas en los PDF completos, ver v0.6 arriba),
*! todas re-validadas por una simulacion Monte Carlo de tasa de error
*! Tipo I propia antes de aplicarse (R=2000, k=4 -- el uso real de
*! produccion, by(anio) --, los mismos 3 escenarios de peso "adversos"
*! que el resto de este comando: sim/simulacion_ksmmd_v07_tipo1.py /
*! resultados_ksmmd_v07_tipo1.txt -- tasa de rechazo entre 3.6% y 5.8%
*! en los 3 escenarios para vspool, maxpairwise Y fuse, sin inflacion
*! frente al 5% nominal; numeros de la corrida RE-VALIDADA tras el fix
*! del bug de mmdtype(maxpairwise), ver mas abajo -- la corrida
*! original, previa al bug, dio un rango similar, 4.3%-5.6%). Un sanity
*! check algebraico previo (misma
*! corrida) confirma que la reescritura de vspool via suma par-a-par
*! coincide, hasta error de punto flotante (~1e-13), con la formula
*! "cada grupo contra el pool" de v0.6 cuando NO se aplica el de-bias
*! de mas abajo -- descarta un error de reescritura antes de agregar el
*! cambio real. SIN cambios en la interfaz de Stata (mismas opciones,
*! mismos nombres) salvo que {opt nfeatures()} impar ahora se ajusta a
*! par automaticamente (con aviso), y el mensaje de {cmd:mmdtype(fuse)}
*! sobre bw() ignorado refleja la nueva grilla:
*!   1. U-estadistico insesgado (Gretton et al. 2012 dan ambas formas
*!      para 2 muestras) en vez del V-estadistico sesgado de v0.6 y
*!      anteriores, para AMBOS mmdtype(vspool) y mmdtype(maxpairwise)
*!      (comparten la misma estructura par-a-par ||mu_a-mu_b||^2, asi
*!      que el mismo de-bias aplica a los dos, no solo a vspool como
*!      pedia el hallazgo original -- extension propia por consistencia
*!      de diseno). Ver ksmmd_mmd_T_batch() en Mata para el algebra
*!      exacta (termino S_j que excluye las parejas i=i' de la misma
*!      unidad, con una salvaguarda que vuelve al V-estadistico solo si
*!      el denominador de un grupo es numericamente inseguro).
*!   2. Variante RFF "z-tilde" (Sutherland & Schneider 2015, ecs. 5-7:
*!      sin fase aleatoria, pares seno/coseno, D/2 frecuencias) en vez
*!      de la "z-breve" (coseno con fase aleatoria, D frecuencias) --
*!      mismo costo computacional, varianza estrictamente menor para el
*!      kernel Gaussiano. {opt nfeatures()} se fuerza a PAR (ver arriba)
*!      para que la variante siempre devuelva exactamente D columnas.
*!   3. lambda~n_min (formula del paper MMD-FUSE, lambda=sqrt(n(n-1)))
*!      para mmdtype(fuse), en vez de lambda=0.1 fijo -- generalizada a
*!      k grupos usando n=tamano del grupo MAS CHICO (coincide
*!      exactamente con la formula del paper cuando k=2; la extension a
*!      k>2 es una decision propia de diseno, no del paper).
*!   4. Grilla de bandwidths de mmdtype(fuse) por cuantiles 5%/95%
*!      (discretizacion uniforme entre 0.5x el cuantil 5% y 2x el
*!      cuantil 95% de las distancias inter-muestra) mas la familia de
*!      kernel Laplace ademas de la Gaussiana (MMD-FUSE, Apendice
*!      A.2/A.4) -- 5 puntos por familia (10 en total) en vez de los
*!      4 puntos Gaussianos anclados en la heuristica de mediana de
*!      v0.6. El paper valida 10-20 puntos por familia; aca se usan 5
*!      por el costo de memoria en produccion (N~10^5): con
*!      {opt nfeatures(200)} default, 10 puntos de grilla dan 2,000
*!      columnas de Phi por unidad, el mismo orden de magnitud que la
*!      configuracion reps(200)/nfeatures(500) (2,000 columnas con la
*!      grilla vieja de 4 puntos) ya confirmada sin problemas de
*!      memoria en produccion en v0.4 (ver esa nota mas abajo) -- una
*!      decision practica propia, no del paper.
*!   5. Heuristica de mediana PONDERADA: el subsample usado para la
*!      mediana (y, en mmdtype(fuse), para los cuantiles 5%/95% de la
*!      grilla) ahora se arma con muestreo ponderado por probabilidad
*!      proporcional al peso de encuesta (clave de Efraimidis-Spirakis,
*!      logkey=ln(u)/w, tomar las N mayores) en vez de un subsample SIN
*!      ponderar como en v0.6 y anteriores -- consistente con que el
*!      resto del estimador si es ponderado.
*! CONFIRMADO EN STATA REAL (21sep2026, escala chica, auto.dta, el
*! usuario corrio los 5 casos de sintaxis contra Stata real): sysuse
*! auto / gen byte g=1+mod(_n,3) / gen double wgt=1, despues:
*!   ksmmd mpg, by(g) reps(200)
*!     -> KS T=0.5953 p=0.7164; MMD(vspool) T=-0.1721 p=0.5323
*!   ksmmd mpg [aweight=wgt], by(g) reps(500) seed(20260916) graph posthoc
*!     -> KS T=0.5953 p=0.7106; MMD(vspool) T=-0.1989 p=0.5269; posthoc
*!        KS y MMD (3 pares) sin error
*!   ksmmd mpg [aweight=wgt], by(g) mmdtype(maxpairwise) reps(500)
*!     -> KS T=0.5953 p=0.7126; MMD(maxpairwise) T=0.1994 p=0.4471
*!   ksmmd mpg [aweight=wgt], by(g) ksonly reps(200)
*!     -> KS T=0.5953 p=0.7214
*!   ksmmd mpg [aweight=wgt], by(g) mmdtype(fuse) reps(500)
*!     -> KS T=0.5953 p=0.6966; MMD(fuse) T=-0.1188 p=0.9142
*! Los 5 corrieron SIN ERROR -- confirma que la reescritura de
*! ksmmd_run()/ksmmd_mmd_T_batch()/ksmmd_rff_features() y las 2 funciones
*! nuevas (ksmmd_rff_laplace_features(), ksmmd_bw_quantile_range()) no
*! tienen errores de sintaxis/indexado Mata que la revision estatica no
*! hubiera detectado, en los 3 mmdtype() y con posthoc/graph. T_KS queda
*! identico en las 5 corridas (0.5953 -- no depende de mmdtype ni cambio
*! en v0.7, como se esperaba).
*! PRECISION (agregada tras el bug de maxpairwise documentado mas
*! abajo): esta corrida de mmdtype(maxpairwise) tambien uso codigo con
*! el bug todavia presente (fue ANTES del fix), y solo probo el
*! omnibus (T=0.1994, un valor positivo, no floreado -- consistente con
*! no haber pisado el bug esa vez) sin posthoc -- el posthoc (k=2) es
*! donde el bug se manifestaba con mas claridad, y este ejemplo de
*! auto.dta no lo incluyo para maxpairwise. No hay razon para sospechar
*! que T=0.1994 este mal, pero "confirmado sin error" no es lo mismo
*! que "confirmado con el fix aplicado" -- esa confirmacion realmente
*! limpia (fix + posthoc) ya se hizo despues, a escala de produccion,
*! ver el bloque de confirmacion de produccion mas abajo.
*!
*! CONFIRMADO TAMBIEN A ESCALA DE PRODUCCION (21sep2026, mismo dia, el
*! usuario corrio contra Stata real sobre un outcome real de encuesta,
*! agrupado en 4 grupos por una variable ordinal (p.ej. periodo/anio),
*! N~141mil, con un peso de encuesta continuo -- nombres de variables y
*! comandos exactos omitidos aca por pedido explicito del usuario):
*!     -> KS T=1705.5730 p=0.4378; MMD(vspool) T=54.6242 p=0.4478;
*!        155.42s (timer), posthoc KS y MMD (6 pares) sin error, con
*!        reps(200) nfeatures(500) graph posthoc
*!   ... mismo comando con bw() fijo (sin heuristica) mmdonly posthoc
*!       -> MMD T=265.2266 p=0.3582, sin error
*!   ... ksonly reps(200) -> KS T=1705.5730 p=0.4179; 23.50s
*!   ... nfeatures(200) mmdonly reps(200) -> MMD T=77.1512 p=0.3781; 25.20s
*!   ... reps(50) nfeatures(50) (corrida agil) -> KS T=1705.5730
*!       p=0.3725, MMD T=139.5582 p=0.2157; 9.56s
*! Las 5 corridas terminaron SIN ERROR a N~141mil -- confirma que la
*! reescritura de v0.7 funciona en produccion, con pesos de encuesta
*! reales, [if], posthoc y graph juntos. T_KS = 1705.5730 identico en
*! las 3 corridas que lo calculan (no depende de nfeatures()/mmdtype
*! ni de v0.7, como se esperaba). Chequeo cruzado de consistencia
*! interna: los 2 pares donde el post-hoc de KS NO encuentra diferencia
*! (p=0.6020 y p=0.7662) son EXACTAMENTE los mismos 2 pares donde el
*! post-hoc de MMD da un T NEGATIVO (-174.9475 y -361.6898
*! respectivamente, ver nota abajo sobre por que eso es lo esperado) --
*! ambos estadisticos, calculados de forma completamente independiente,
*! coinciden en que grupos no difieren.
*! Esta primera tanda de 5 corridas de produccion uso todas
*! mmdtype(vspool) (el default) -- ninguna paso mmdtype(maxpairwise) ni
*! mmdtype(fuse). Ver el bloque de abajo para esas dos.
*!
*! mmdtype(maxpairwise) Y mmdtype(fuse) CONFIRMADOS TAMBIEN A ESCALA DE
*! PRODUCCION (21sep2026, mismo dia, DESPUES del fix del bug de
*! maxpairwise -- ver el bloque "BUG ENCONTRADO Y CORREGIDO" abajo --
*! con el .ado ya corregido, mismo dataset/variables que arriba):
*!     -> KS T=1705.5730 p=0.4726; MMD(maxpairwise) T=298.8540 p=0.6119;
*!        141.17s, con reps(200) nfeatures(500) posthoc. Posthoc: los
*!        mismos 2 pares de arriba dan T=-174.9475 p=0.5970 y
*!        T=-361.6898 p=0.7861 -- VALORES NEGATIVOS REALES, no
*!        0.0000/1.0000 como en la corrida pre-fix -- fix CONFIRMADO en
*!        produccion. Ademas, estos 2 valores coinciden casi exactos
*!        con el posthoc de vspool para los mismos 2 pares (ver arriba)
*!        -- consistente con que, a k=2, vspool y maxpairwise son
*!        algebraicamente el mismo estadistico (ya documentado en el
*!        punto 4 de mas arriba).
*!   ... mmdtype(fuse) reps(200) nfeatures(200) posthoc
*!     -> KS T=1705.5730 p=0.4279; MMD(fuse) T=1692.7238 p=0.3682;
*!        387.02s (~6.5 min); posthoc sin error (6 pares)
*!   ... mmdtype(fuse) reps(200) nfeatures(500) posthoc
*!     -> KS T=1705.5730 p=0.4328; MMD(fuse) T=1166.0802 p=0.3930;
*!        832.45s (~13.9 min); posthoc sin error (6 pares) -- 10x500=
*!        5.000 columnas de Phi_grid_sorted, el territorio de memoria
*!        NO confirmado que se senalaba arriba -- CONFIRMADO SIN
*!        PROBLEMA DE MEMORIA NI ERROR a N~141mil.
*! Con esto, los 3 mmdtype() (vspool, maxpairwise, fuse) Y KS quedan
*! CONFIRMADOS en ambas escalas (chica via auto.dta, produccion via
*! estos runs) -- no queda ningun mmdtype() ni ninguna combinacion de
*! opciones pendiente de confirmar contra Stata real para v0.7.
*!
*! Nota menor: T_KS=1705.5730 es identico en TODAS las corridas de
*! produccion (5+3=8 en total), pero el p-valor de KS varia levemente
*! entre corridas (0.4378, 0.4179, 0.3725, 0.4726, 0.4279, 0.4328) --
*! es el ruido esperado de permutacion (T_KS es deterministico dado el
*! dato, pero su p-valor depende de que permutaciones se sortearon esa
*! corrida en particular). Los posthoc de pares POSITIVOS tampoco
*! coinciden exactamente entre corridas distintas (un mismo par dio
*! 258.3331, 265.7532 y 265.2266 en tres corridas distintas) -- mismo
*! motivo, mas el hecho de que bw() por heuristica de mediana (default)
*! se recalcula con su propio sorteo aleatorio dentro de cada corrida.
*! Ninguna de estas variaciones es un problema: son fluctuaciones de
*! Monte Carlo normales entre corridas independientes con distinto
*! estado de las variables aleatorias de Stata/Mata al momento de
*! invocar el comando (aunque se pase el mismo seed() a ksmmd, otros
*! comandos ejecutados antes en la misma sesion pueden haber consumido
*! numeros aleatorios de forma distinta entre sesiones distintas de
*! Stata).
*!
*! BUG ENCONTRADO Y CORREGIDO (21sep2026, en la MISMA sesion de
*! produccion real de arriba): el usuario corrio mmdtype(maxpairwise) a
*! escala de produccion (mismos datos, N~141mil) ANTES de que este bug
*! se detectara y corrigiera -- esa corrida especifica (Stat=298.8540
*! p=0.6119 en el omnibus; posthoc con 2 de los pares dando Stat=0.0000
*! EXACTO y p=1.0000 EXACTO) uso codigo con el bug todavia presente,
*! asi que esa corrida especifica NUNCA sirvio como
*! confirmacion valida de mmdtype(maxpairwise) en produccion -- se
*! repitio con el .ado corregido el mismo dia (ver el bloque de
*! confirmacion de produccion mas abajo: valores negativos reales
*! confirmados, esa confirmacion ya quedo cerrada).
*! Causa raiz: en ksmmd_mmd_T_batch(), tanto vspool (suma) como
*! maxpairwise (maximo via rowmax()) arrancaban su acumulador T en
*! J(B,1,0). Para vspool, 0 es la identidad aditiva correcta. Para
*! maxpairwise, 0 actuaba como un PISO artificial: con el V-estadistico
*! sesgado de v0.6 y anteriores (siempre >=0) esto era inofensivo,
*! porque el maximo real nunca podia ser menor que 0. Con el
*! U-estadistico insesgado de v0.7 (dist2U puede ser negativo, ver la
*! nota que sigue), si TODOS los pares de una permutacion -- o, en un
*! posthoc con k=2, el UNICO par -- daban negativo, el rowmax contra un
*! piso de 0 devolvia 0 en vez del valor real, y como el mismo piso se
*! aplicaba tambien a cada permutacion, el conteo del p-valor quedaba
*! sesgado (mas conservador, no anti-conservador, pero con un valor
*! reportado literalmente incorrecto: 0.0000 exacto no era el
*! estadistico real). Fix: T arranca en -1e300 (mismo centinela que ya
*! usa el jumpmask de KS) SOLO en la rama maxpairwise -- vspool sigue
*! arrancando en 0. Mismo bug y mismo fix aplicados al prototipo Python
*! (sim/simulacion_ksmmd_v07_tipo1.py). Re-validado por una nueva
*! corrida de la simulacion de Tipo I (R=2000, k=4, 3 escenarios --
*! rango 3.6%-5.8%, sin inflacion, ver arriba y
*! resultados_ksmmd_v07_tipo1.txt) mas un sanity check dedicado (k=2,
*! bandwidth grande, confirma que el estadistico puede devolver un
*! valor no floreado en 0). Este bug NO afectaba a vspool ni a fuse
*! (fuse solo usa la rama vspool internamente, nunca la de
*! maxpairwise) -- estaba aislado a mmdtype(maxpairwise).
*!
*! NOTA IMPORTANTE sobre los valores NEGATIVOS de T_MMD (ej. -0.1721,
*! -0.1989, -0.1188 en los ejemplos de vspool/fuse de arriba, y ahora
*! tambien posible en maxpairwise tras el fix de arriba): esto NO es un
*! error, es la firma esperada del U-estadistico insesgado agregado en
*! v0.7. El V-estadistico de v0.6 y anteriores (biased, incluye las
*! parejas i=i' de la misma unidad) es una suma/maximo de cuadrados y
*! por construccion nunca podia dar negativo. El U-estadistico
*! insesgado (v0.7) es distinto: al ser insesgado para una cantidad
*! poblacional (MMD^2) que tiene un piso en 0 (H0: MMD^2=0), un
*! estimador insesgado de un valor en el piso de su propio rango DEBE
*! poder tomar valores en ambas direcciones para no estar sesgado hacia
*! arriba -- Gretton et al. (2012) ya documentan exactamente esto para
*! el caso de 2 muestras. Con g=1+mod(_n,3) (una particion arbitraria
*! de mpg en auto.dta, sin diferencia real entre grupos) el MMD^2
*! poblacional verdadero es ~0, asi que el estimador insesgado fluctua
*! alrededor de 0 -- valores negativos moderados son el comportamiento
*! correcto, no un bug. El p-valor sigue siendo valido (calibrado por
*! permutacion contra la MISMA distribucion nula, que tambien fluctua
*! alrededor de 0): un T_MMD observado muy negativo naturalmente da un
*! p-valor ALTO (ej. p=0.9142 en el ejemplo de fuse arriba), exactamente
*! como se espera bajo H0.
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
*!     error conocida (Sutherland & Schneider 2015, UAI, Seccion 3.3,
*!     sobre el estadistico MMD en si -- NO su cuadrado, no solo sobre
*!     el kernel):
*!     P(|MMD_RFF - MMD| >= eps) <= 2*exp(-D*eps^2/128), error absoluto
*!     esperado <= 8*sqrt(2*pi/D) -- para bajar el error esperado a la
*!     mitad hace falta CUADRUPLICAR nfeatures().
*!     [CORREGIDO sep2026, tras leer el PDF completo (con verificacion
*!     cruzada via pdftotext sobre el PDF crudo, caracter por caracter):
*!     el "CORREGIDO 19sep2026" que tenia esta version antes (que habia
*!     cambiado "MMD" por "MMD^2" a partir de busqueda bibliografica sin
*!     acceso al texto completo) estaba EQUIVOCADO -- el propio texto
*!     primario (pagina 7: "Pr(|MMDz(X,Y) - MMD(X,Y)|) <= 2*exp(-D*
*!     eps^2/128) and expected absolute error of at most 8*sqrt(2*pi/D)")
*!     confirma que la cota es sobre MMD sin elevar al cuadrado, tal
*!     como decia la version ORIGINAL de este parrafo. Se revierte aca a
*!     esa forma. Ademas, el paper no tiene ningun "Theorem 1" numerado
*!     (solo Proposiciones 1-10) -- el resultado es un parrafo en prosa
*!     dentro de la Seccion 3.3, de ahi la cita corregida arriba.]
*!     Ademas, Choi, I. & Kim, I. (2024, arXiv:2407.08976, PDF leido
*!     completo) prueban algo MAS FUERTE que "puede perder potencia":
*!     su Teorema 3 muestra INCONSISTENCIA GENUINA del test con D fijo
*!     -- existen infinitos pares de distribuciones distintas donde la
*!     potencia asintotica queda acotada por alpha, sin importar el
*!     tamano de muestra, si D no crece con N. No hay una tasa universal
*!     D=O(sqrt(N)); la tasa necesaria depende de la suavidad de la
*!     alternativa (sus Teoremas 6-7, Prop. 8). Evidencia empirica a
*!     favor del default: en su caso univariado (d=1, el mismo caso de
*!     ksmmd) D=200 ya iguala la potencia del MMD exacto en sus
*!     simulaciones -- respalda nfeatures(200) por default. Su Teorema 7
*!     tambien advierte que subir D hasta ~n (tamano del grupo minimo)
*!     recupera la tasa optima pero el costo vuelve a ser esencialmente
*!     O(N^2) -- "D grande para el resultado final" no es gratis, mismo
*!     patron agil->final que reps(): nfeatures() bajo para explorar,
*!     alto (pero no arbitrariamente alto) para el resultado que se va a
*!     reportar.
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
*! Referencias completas (DOI agregado donde se pudo confirmar por
*! busqueda -- ver nota de verificacion al final de este bloque):
*!   Kiefer, J. (1959). K-sample analogues of the Kolmogorov-Smirnov and
*!     Cramer-v. Mises tests. Ann. Math. Statist. 30(2), 420-447. DOI:
*!     10.1214/aoms/1177706261.
*!   Gretton, A., Borgwardt, K.M., Rasch, M.J., Scholkopf, B., Smola, A.
*!     (2012). A Kernel Two-Sample Test. JMLR 13(25), 723-773.
*!   Rahimi, A., Recht, B. (2007). Random Features for Large-Scale
*!     Kernel Machines. NeurIPS 20.
*!   Biggs, F., Schrab, A., Gretton, A. (2023). MMD-FUSE: Learning and
*!     Combining Kernels for Two-Sample Testing Without Data Splitting.
*!     NeurIPS 36. arXiv:2306.08777.
*!   Hemerik, J., Goeman, J.J. (2018). Exact testing with random
*!     permutations. Test 27(4), 811-825. DOI: 10.1007/s11749-017-0571-1.
*!   Sutherland, D.J., Schneider, J. (2015). On the Error of Random
*!     Fourier Features. UAI 2015.
*!   Choi, I., Kim, I. (2024). Computational-Statistical Trade-off in
*!     Kernel Two-Sample Testing with Random Fourier Features.
*!     arXiv:2407.08976. [CORREGIDO sep2026, tras leer el PDF completo:
*!     la version anterior de esta cita decia "Choi, S." -- el primer
*!     autor es Ikjun Choi, inicial correcta "I.", no "S." -- tercer
*!     error real de atribucion detectado en esta bibliografia, mismo
*!     tipo que las 2 correcciones de Ong et al. y Zhang/Guo/Zhou de
*!     abajo, esta vez encontrado por lectura de texto completo, no por
*!     busqueda de metadatos.]
*!   Reddi, S.J., Ramdas, A., Poczos, B., Singh, A., Wasserman, L.
*!     (2015). On the High Dimensional Power of a Linear-Time Two
*!     Sample Test under Mean-shift Alternatives. Proc. AISTATS 2015,
*!     PMLR v38. arXiv:1411.6314.
*!   Ong, Z.P., Chen, A.A., Zhu, T., Zhang, J.-T. (2023). Testing
*!     Equality of Several Distributions at High Dimensions: A
*!     Maximum-Mean-Discrepancy-Based Approach. Mathematics 11(20),
*!     4374. DOI: 10.3390/math11204374. [CORREGIDO 19sep2026: la
*!     version anterior de esta cita tenia autores mal atribuidos
*!     ("Ong, C.S., Chen, X., Zhu, D., Zhang, Y.") y el numero de
*!     articulo equivocado (4272) -- error real, no solo un DOI
*!     faltante, detectado al verificar la bibliografia a pedido
*!     explicito del usuario.]
*!   Zhang, J.-T., Guo, J., Zhou, B. (2024). Testing equality of
*!     several distributions in separable metric spaces: a maximum
*!     mean discrepancy based approach. J. Econometrics 239(2).
*!     [CORREGIDO 19sep2026: autores mal atribuidos ("Zhang, Y., Guo,
*!     X., Zhou, W.") y anio de publicacion equivocado (se cito 2022,
*!     el paper se publico en 2024 aunque circulo como working paper
*!     antes) -- mismo motivo que la correccion anterior.]
*!   Kim, I. (2021). Comparing a large number of multivariate
*!     distributions. Bernoulli 27(1), 419-441. DOI: 10.3150/20-BEJ1244.
*!   Sejdinovic, D., Sriperumbudur, B., Gretton, A., Fukumizu, K.
*!     (2013). Equivalence of distance-based and RKHS-based statistics
*!     in hypothesis testing. Ann. Statist. 41(5), 2263-2291. DOI:
*!     10.1214/13-AOS1140.
*!   Rizzo, M.L., Szekely, G.J. (2010). DISCO analysis: a nonparametric
*!     extension of analysis of variance. Ann. Appl. Stat. 4(2),
*!     1034-1055. DOI: 10.1214/09-AOAS245.
*!   Garreau, D., Jitkrittum, W., Kanagawa, M. (2017). Large sample
*!     analysis of the median heuristic. arXiv:1707.07269.
*!   Szekely, G.J., Rizzo, M.L. (2004). Testing for Equal Distributions
*!     in High Dimension. InterStat, Nov(5).
*!   Rizzo, M.L., Szekely, G.J. (2016). Energy distance. WIREs
*!     Computational Statistics 8(1), 27-38. DOI: 10.1002/wics.1375.
*!   Huang, Z., Sen, B. (2024). A Kernel Measure of Dissimilarity
*!     between M Distributions. JASA 119(548), 3020-3032 (evaluada,
*!     NO incorporada -- ver punto 4 arriba).
*!
*!   NOTA DE VERIFICACION (19sep2026, a pedido explicito del usuario,
*!   que pregunto directamente si estas citas se habian verificado
*!   contra el documento original antes de incorporar sus formulas):
*!   en una primera ronda NINGUNA de las citas de este bloque (salvo las
*!   marcadas "PDF leido completo" en el punto 4b y en las secciones de
*!   KMD/informacion mutua mas arriba) se habia leido como documento
*!   primario en esta sesion -- las formulas venian de conocimiento
*!   general/entrenamiento sobre resultados clasicos y muy citados en
*!   estadistica/ML, no de abrir el PDF. Se verifico autor/anio/
*!   revista/paginas/DOI de las 14 citas de este bloque via busqueda
*!   web (no lectura del texto completo): 12 de 14 coincidian
*!   exactamente; 2 tenian errores reales de atribucion (Ong et al. y
*!   Zhang/Guo/Zhou, ver correcciones arriba) que NO se habrian
*!   detectado sin ese chequeo.
*!
*!   SEGUNDA RONDA (sep2026): el usuario compartio los PDF completos via
*!   Google Drive y se leyeron los 15 disponibles de punta a punta (8
*!   agentes en paralelo, uno queda sin PDF: Zhang/Guo/Zhou 2024,
*!   detras de paywall de ScienceDirect, no obtenido). Esa lectura
*!   completa encontro 3 correcciones OBLIGATORIAS adicionales que la
*!   verificacion de metadatos de la primera ronda no podia detectar
*!   (porque son errores de CONTENIDO/formula, no de autor/anio/DOI):
*!   la cota de Sutherland&Schneider (revertida de MMD^2 a MMD, cita
*!   "Theorem 1" corregida a "Seccion 3.3"), la motivacion de
*!   mmdtype(fuse) (escala cuadratica de Reddi et al., no exponencial),
*!   y un TERCER error de atribucion (Choi, S. -> Choi, I.) que la
*!   busqueda de metadatos de la primera ronda tampoco habia detectado.
*!   Tambien confirmo/reforzo con texto primario buena parte de las
*!   justificaciones de diseno que antes descansaban solo en
*!   conocimiento general (ver remarks_mmdtype en el help para el
*!   detalle citado por papel). El algebra de la identidad vspool
*!   (Huygens/ANOVA) fue verificada directamente por calculo propio
*!   desde el inicio, independiente de esta bibliografia.
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
        di as txt "ksmmd: mmdtype(fuse) ignora bw() -- usa una grilla de 10 " ///
            "bandwidths por cuantiles 5%/95% (kernel Gaussiano y Laplace) " ///
            "calculada internamente (ver {help ksmmd##remarks_mmdtype:help ksmmd})"
    }
    if "`ksonly'" != "" & "`mmdonly'" != "" {
        di as err "ksmmd: ksonly y mmdonly son mutuamente excluyentes"
        exit 198
    }
    local do_ks  = cond("`mmdonly'" != "", 0, 1)
    local do_mmd = cond("`ksonly'"  != "", 0, 1)

    * v0.7: la variante RFF "z-tilde" (Sutherland & Schneider 2015) arma
    * pares seno/coseno a partir de D/2 frecuencias -- nfeatures() debe
    * ser PAR para que devuelva exactamente nfeatures() columnas.
    if `do_mmd' & mod(`nfeatures', 2) != 0 {
        local nfeatures = `nfeatures' + 1
        di as txt "ksmmd: nfeatures() debe ser par para la variante RFF " ///
            "z-tilde (v0.7) -- ajustado a " as res `nfeatures'
    }

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
// KS; Phi/Phi_grid para MMD, ver mas abajo), y procesa las permutaciones en
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
    real matrix Phi, Phi_sorted, label_matrix
    real scalar N, T_KS_obs, T_MMD_obs, count_ks, count_mmd
    real scalar chunk, done, thisB, i
    real rowvector Fcumrow, jumpmask
    real vector T_KS_perm, T_MMD_perm
    real matrix RES
    // -- solo para mmdtype(fuse), v0.7: grilla por cuantiles 5%/95% de
    // las distancias inter-muestra (submuestra ponderada), dos familias
    // de kernel (Gaussiano y Laplace, NPERFAM puntos cada una). Phi de
    // LOS G=2*NPERFAM puntos de grilla se guarda uno al lado del otro en
    // una sola matriz (N x G*nfeatures), mismo patron de "bloques de
    // columnas" que ya usa ksmmd_mmd_T_batch() para mu_all (ver mas
    // abajo). Fijos, no dependen de la permutacion: se calculan una sola
    // vez aca, igual que Phi_sorted para vspool/maxpairwise. Ya no se
    // necesita mu_pool/mu_pool_grid en ningun camino -- ksmmd_mmd_T_batch()
    // (v0.7) calcula el U-estadistico via suma/maximo par-a-par, sin
    // pasar por un "pool" explicito.
    real scalar is_fuse, G, NPERFAM, gi, fuse_lam, c0, c1, gridlo, gridhi, n_min, jg
    real vector nhatG, grid_bw, qrange, n_por_grupo
    real matrix Phi_grid_sorted

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
        Phi = ksmmd_rff_features(y, nfeatures, bw, w)
        Phi_sorted = Phi[idx, .]
    }
    else if (is_fuse) {
        // v0.7: grilla por cuantiles 5%/95% (0.5x el cuantil 5%, 2x el
        // cuantil 95% de las distancias |y_i-y_j| en una submuestra
        // PONDERADA, discretizacion uniforme -- MMD-FUSE, Apendice
        // A.2/A.4) + familias Gaussiana Y Laplace (NPERFAM puntos cada
        // una -- el paper valida 10-20 por familia; aca se usan 5 por
        // costo de memoria en produccion, ver nota en el encabezado del
        // .ado), y lambda~n_min (formula del paper, lambda=sqrt(n(n-1)),
        // generalizada al grupo MAS CHICO -- coincide exactamente con la
        // formula del paper cuando k=2). Validado por simulacion propia
        // (Tipo I, R=2000, k=4, 3 escenarios de peso -- ver
        // sim/simulacion_ksmmd_v07_tipo1.py /
        // resultados_ksmmd_v07_tipo1.txt). bw() del usuario se IGNORA
        // aca (el .ado avisa si se paso uno).
        NPERFAM = 5
        G = 2*NPERFAM
        qrange = ksmmd_bw_quantile_range(y, w, 0.05, 0.95)
        gridlo = 0.5*qrange[1]
        gridhi = 2*qrange[2]
        if (gridhi <= gridlo) gridhi = gridlo + 1

        grid_bw = J(1, NPERFAM, .)
        for (gi=1; gi<=NPERFAM; gi++) {
            if (NPERFAM == 1) grid_bw[gi] = gridlo
            else grid_bw[gi] = gridlo + (gi-1)*(gridhi-gridlo)/(NPERFAM-1)
        }

        Phi_grid_sorted = J(N, G*nfeatures, .)
        nhatG = J(1, G, .)
        for (gi=1; gi<=NPERFAM; gi++) {
            c0 = (gi-1)*nfeatures + 1
            c1 = gi*nfeatures
            Phi = ksmmd_rff_features(y, nfeatures, grid_bw[gi], w)
            Phi_grid_sorted[., c0::c1] = Phi[idx, .]
            nhatG[gi] = ksmmd_nhat(Phi_grid_sorted[., c0::c1])
        }
        for (gi=1; gi<=NPERFAM; gi++) {
            c0 = (NPERFAM+gi-1)*nfeatures + 1
            c1 = (NPERFAM+gi)*nfeatures
            Phi = ksmmd_rff_laplace_features(y, nfeatures, grid_bw[gi])
            Phi_grid_sorted[., c0::c1] = Phi[idx, .]
            nhatG[NPERFAM+gi] = ksmmd_nhat(Phi_grid_sorted[., c0::c1])
        }

        n_por_grupo = J(1, rows(groups), .)
        for (jg=1; jg<=rows(groups); jg++) {
            n_por_grupo[jg] = sum(g_sorted :== groups[jg])
        }
        n_min = min(n_por_grupo)
        fuse_lam = sqrt(n_min*(n_min-1))
        if (fuse_lam <= 0) fuse_lam = 0.1
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
        T_MMD_obs = ksmmd_mmd_T_batch(Phi_sorted, w_sorted, g_sorted', mmdtype, groups)[1]
    }
    else if (is_fuse) {
        T_MMD_obs = ksmmd_mmd_fuse_T_batch(Phi_grid_sorted, w_sorted, g_sorted', groups, nhatG, fuse_lam)[1]
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
            T_MMD_perm = ksmmd_mmd_T_batch(Phi_sorted, w_sorted, label_matrix, mmdtype, groups)
            count_mmd = count_mmd + sum(T_MMD_perm :>= T_MMD_obs)
        }
        else if (is_fuse) {
            T_MMD_perm = ksmmd_mmd_fuse_T_batch(Phi_grid_sorted, w_sorted, label_matrix, groups, nhatG, fuse_lam)
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
// v0.7: submuestra PONDERADA (hasta 2000 obs) de distancias par-a-par
// |y_i-y_j|, usada tanto por la heuristica de mediana como por la
// grilla de cuantiles de mmdtype(fuse). Antes (v0.6 y anteriores) el
// subsample era UNIFORME (sin usar w), inconsistencia de diseno frente
// al resto del estimador, que si es ponderado -- corregida aca via la
// clave de Efraimidis-Spirakis (logkey=ln(u)/w, u~Uniform(0,1) iid):
// tomar las nsub observaciones con MAYOR logkey es equivalente a un
// muestreo sin reemplazo con probabilidad proporcional a w (PPS), sin
// necesitar una suma acumulada de pesos de largo N -- mismo costo que
// el order() sobre runiform(n,1) que ya se usaba (un sort de N
// elementos), solo cambia la clave que se ordena.
// ---------------------------------------------------------------
real vector ksmmd_weighted_subsample_pdiffs(real vector y, real vector w)
{
    real scalar n, nsub, i, p, q
    real vector ysub, dif, logkey, idx

    n = rows(y)
    nsub = min((n, 2000))
    logkey = ln(runiform(n,1)) :/ w
    idx = order(logkey, -1)[1::nsub]
    ysub = y[idx]
    dif = J(nsub*(nsub-1)/2, 1, .)
    i = 0
    for (p=1; p<=nsub-1; p++) {
        for (q=p+1; q<=nsub; q++) {
            i++
            dif[i] = abs(ysub[p] - ysub[q])
        }
    }
    return(dif)
}

// ---------------------------------------------------------------
// Heuristica de mediana (Garreau, Jitkrittum & Kanagawa 2017) para el
// bandwidth del kernel RBF, ahora sobre la submuestra PONDERADA de
// arriba (v0.7 -- antes sin ponderar). Extraida a funcion propia (antes
// vivia inline dentro de ksmmd_rff_features) para que mmdtype(fuse)
// pueda reusar la misma logica de submuestreo para su grilla de
// cuantiles.
// ---------------------------------------------------------------
real scalar ksmmd_bw_heuristic(real vector y, real vector w)
{
    real scalar med
    med = ksmmd_median(ksmmd_weighted_subsample_pdiffs(y, w))
    if (med <= 0) med = 1
    return(med)
}

// ---------------------------------------------------------------
// v0.7: rango [lo,hi] = [cuantil q_lo, cuantil q_hi] de las distancias
// par-a-par en la MISMA submuestra ponderada de arriba -- ancla la
// grilla de bandwidths de mmdtype(fuse) (MMD-FUSE, Apendice A.2:
// discretizacion uniforme entre 0.5x el cuantil 5% y 2x el cuantil 95%
// de las distancias inter-muestra).
// ---------------------------------------------------------------
real rowvector ksmmd_bw_quantile_range(real vector y, real vector w,
    real scalar q_lo, real scalar q_hi)
{
    real vector dif
    real scalar lo, hi

    dif = ksmmd_weighted_subsample_pdiffs(y, w)
    lo = ksmmd_quantile(dif, q_lo)
    hi = ksmmd_quantile(dif, q_hi)
    if (lo <= 0) lo = 1e-6
    if (hi <= lo) hi = lo*1.001
    return((lo,hi))
}

real scalar ksmmd_quantile(real vector x, real scalar q)
{
    real vector xs
    real scalar n, pos
    xs = sort(x, 1)
    n = rows(xs)
    pos = ceil(q*n)
    if (pos < 1) pos = 1
    if (pos > n) pos = n
    return(xs[pos])
}

// ---------------------------------------------------------------
// v0.7: Random Fourier Features, variante "z-tilde" (Sutherland &
// Schneider 2015, ecs. 5-7: sin fase aleatoria b, pares seno/coseno,
// D/2 frecuencias) para el kernel RBF exp(-(x-y)^2/(2*bw^2)):
// phi(x) = sqrt(1/(D/2)) * [cos(omega_1*x),sin(omega_1*x),...],
// omega_m ~ N(0, 1/bw^2), m=1..D/2 -- varianza ESTRICTAMENTE MENOR que
// la variante "z-breve" (v0.6 y anteriores: coseno con fase aleatoria,
// D frecuencias) al mismo costo computacional O(N*D); ver la nota en
// el encabezado del .ado. D se fuerza a ser PAR en el .ado (ver
// validacion de nfeatures() en el programa Stata) para que esta
// funcion siempre devuelva exactamente D columnas. bw<=0 dispara
// ksmmd_bw_heuristic() arriba (ponderada, v0.7).
// ---------------------------------------------------------------
real matrix ksmmd_rff_features(real vector y, real scalar D, real scalar bw,
    real vector w)
{
    real scalar nfreq
    real vector omega
    real matrix Arg, Phi

    if (bw <= 0) bw = ksmmd_bw_heuristic(y, w)

    nfreq = D/2
    omega = rnormal(nfreq, 1, 0, 1/bw)
    Arg = y * omega'
    Phi = sqrt(1/nfreq) :* (cos(Arg), sin(Arg))
    return(Phi)
}

// ---------------------------------------------------------------
// v0.7: Random Fourier Features, mismo estilo "z-tilde" de arriba,
// para el kernel LAPLACE exp(-|x-y|/bw) -- segunda familia de kernel
// de la grilla de mmdtype(fuse) (MMD-FUSE, Apendice A.2/A.4: el paper
// valida empiricamente Gaussiano Y Laplace juntos). Por el teorema de
// Bochner, la densidad espectral del kernel Laplace es una Cauchy(0,
// 1/bw) (no Normal, como para el Gaussiano) -- Mata no trae un
// generador Cauchy nativo, asi que se usa la transformada inversa
// estandar: omega = (1/bw) * tan(pi*(u-0.5)), u~Uniform(0,1). Nunca se
// dispara sobre bw<=0: mmdtype(fuse) siempre pasa un bandwidth positivo
// concreto de su propia grilla (ver ksmmd_run()).
// ---------------------------------------------------------------
real matrix ksmmd_rff_laplace_features(real vector y, real scalar D, real scalar bw)
{
    real scalar nfreq
    real vector u, omega
    real matrix Arg, Phi

    nfreq = D/2
    u = runiform(nfreq, 1)
    omega = (1/bw) :* tan(pi() :* (u :- 0.5))
    Arg = y * omega'
    Phi = sqrt(1/nfreq) :* (cos(Arg), sin(Arg))
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
// (label_matrix: B x N) -- "vspool" (default) o "maxpairwise", ver
// encabezado del .ado para las citas. v0.7: U-ESTADISTICO INSESGADO
// (Gretton et al. 2012 dan ambas formas, biased/unbiased, para el caso
// de 2 muestras; aca se generaliza a k grupos ponderados) en vez del
// V-estadistico sesgado de v0.6 y anteriores. El V-estadistico incluye,
// dentro de cada mu_j.mu_j, las parejas i=i' de la MISMA unidad
// (autoproducto phi(x_i).phi(x_i), aprox RFF de k(x_i,x_i)=1) -- sin
// pesos esa contribucion es una constante aditiva por grupo que no
// cambia el ranking de permutacion, pero CON pesos de encuesta
// desiguales deja de serlo (depende de que unidades caen en cada grupo
// bajo cada permutacion), lo que puede restar potencia sutilmente. El
// U-estadistico reemplaza mu_j.mu_j por S_j, que excluye esas parejas
// i=i':
//   S_j = [Wsum_j^2*(mu_j.mu_j) - sum_i w_i^2*s_i] / [Wsum_j^2 - sum_i w_i^2]
// (s_i = ||phi(x_i)||^2, suma restringida a las unidades del grupo j
// bajo la permutacion en curso), y arma
// ||mu_a-mu_b||^2_U = S_a - 2*mu_a.mu_b + S_b para cada par de grupos.
// Para vspool esto se suma sobre TODOS los pares a<b (dividido por
// Wtot, constante fija que no cambia el p-valor pero preserva la
// escala de la formula "cada grupo contra el pool" ya documentada --
// via la identidad de Huygens/ANOVA, este formula pairwise coincide
// EXACTAMENTE con esa formula cuando S_j=mu_j.mu_j, es decir sin
// de-bias -- verificado numericamente en
// sim/simulacion_ksmmd_v07_tipo1.py, funcion
// sanity_check_V_equivale_a_pairwise()); para maxpairwise, igual que
// antes, se toma el maximo par a par con el peso de Kim (2021).
// Si Wsum_j^2-sum(w_i^2) es numericamente inseguro (grupo muy chico o
// pesos muy concentrados en pocas unidades), se cae de vuelta al
// V-estadistico SOLO para ese grupo/permutacion (evita dividir por un
// denominador casi nulo) -- nunca invalida el p-valor de permutacion
// (Hemerik & Goeman 2018 vale para CUALQUIER estadistico fijo), solo
// podria diluir levemente la ganancia de potencia esperada en ese caso
// extremo. Validado por simulacion propia (Tipo I, R=2000, k=4, 3
// escenarios de peso -- sim/simulacion_ksmmd_v07_tipo1.py /
// resultados_ksmmd_v07_tipo1.txt).
// ---------------------------------------------------------------
real vector ksmmd_mmd_T_batch(real matrix Phi, real vector w, real matrix label_matrix,
    string scalar mmdtype, real vector groups)
{
    real scalar k, j, l, D, B, c0, c1, c0l, c1l, Wtot
    real matrix Ind, Wmat, mu_all, Wsum_all, SW2_all, SW2S_all, S_all
    real vector T, dist2U, wjl, s, ws2, ws2s, selfdotj, denomj, maskj, Sj

    k = rows(groups)
    B = rows(label_matrix)
    D = cols(Phi)
    Wtot = sum(w)

    s = rowsum(Phi:^2)
    ws2 = w:^2
    ws2s = ws2 :* s

    mu_all = J(B, k*D, .)
    Wsum_all = J(B, k, .)
    SW2_all = J(B, k, .)
    SW2S_all = J(B, k, .)
    for (j=1; j<=k; j++) {
        Ind = (label_matrix :== groups[j])
        Wmat = Ind :* w'
        Wsum_all[.,j] = rowsum(Wmat)
        c0 = (j-1)*D+1
        c1 = j*D
        mu_all[., c0::c1] = (Wmat * Phi) :/ Wsum_all[.,j]
        SW2_all[.,j] = rowsum(Ind :* ws2')
        SW2S_all[.,j] = rowsum(Ind :* ws2s')
    }

    S_all = J(B, k, .)
    for (j=1; j<=k; j++) {
        c0 = (j-1)*D+1
        c1 = j*D
        selfdotj = rowsum(mu_all[.,c0::c1]:^2)
        denomj = Wsum_all[.,j]:^2 :- SW2_all[.,j]
        maskj = (denomj :<= (1e-8 :* Wsum_all[.,j]:^2))
        Sj = (Wsum_all[.,j]:^2 :* selfdotj :- SW2S_all[.,j]) :/ (denomj :+ maskj)
        S_all[.,j] = maskj :* selfdotj :+ (1 :- maskj) :* Sj
    }

    if (mmdtype == "vspool") {
        // T empieza en 0: identidad aditiva correcta para una SUMA --
        // cada termino puede ser negativo (dist2U insesgado, v0.7) sin
        // que eso rompa nada, porque se van sumando, no comparando
        // contra un piso.
        T = J(B, 1, 0)
        for (j=1; j<=k-1; j++) {
            c0 = (j-1)*D+1
            c1 = j*D
            for (l=j+1; l<=k; l++) {
                c0l = (l-1)*D+1
                c1l = l*D
                dist2U = S_all[.,j] :- 2:*rowsum(mu_all[.,c0::c1] :* mu_all[.,c0l::c1l]) :+ S_all[.,l]
                T = T :+ (Wsum_all[.,j] :* Wsum_all[.,l] :* dist2U) :/ Wtot
            }
        }
    }
    else {
        // maxpairwise (Kim 2021, forma ponderada -- Remark 3.3):
        // max_{k<l} [Wsum_k*Wsum_l/(Wsum_k+Wsum_l)] * ||mu_k-mu_l||^2_U
        // T tiene que arrancar en -infinito (no en 0): con el
        // V-estadistico de v0.6 y anteriores, cada termino era >=0, asi
        // que arrancar en 0 era inofensivo (el maximo real nunca podia
        // ser menor que 0). Con el U-estadistico insesgado de v0.7,
        // dist2U SI puede ser negativo (ver nota en el encabezado del
        // .ado) -- si TODOS los pares de una permutacion dan negativo,
        // arrancar en 0 pisaba el maximo real con un 0 artificial
        // [BUG detectado 21sep2026 en produccion real: posthoc con
        // k=2 (un solo par) daba Stat=0.0000 exacto y p=1.0000 exacto
        // cada vez que ese unico par salia negativo, en vez de reportar
        // el valor negativo real -- y como el mismo piso aplicaba
        // tambien a CADA permutacion, el conteo del p-valor quedaba
        // sesgado hacia arriba en vez de solo el display]. Arrancar en
        // -1e300 (mismo centinela que ya usa jumpmask en KS) asegura
        // que el primer par siempre "gana" el rowmax y el resultado
        // final es el maximo GENUINO, positivo o negativo.
        T = J(B, 1, -1e300)
        for (j=1; j<=k-1; j++) {
            c0 = (j-1)*D+1
            c1 = j*D
            for (l=j+1; l<=k; l++) {
                c0l = (l-1)*D+1
                c1l = l*D
                dist2U = S_all[.,j] :- 2:*rowsum(mu_all[.,c0::c1] :* mu_all[.,c0l::c1l]) :+ S_all[.,l]
                wjl = (Wsum_all[.,j] :* Wsum_all[.,l]) :/ (Wsum_all[.,j] :+ Wsum_all[.,l])
                T = rowmax((T, wjl :* dist2U))
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
// T_MMD-FUSE para un BLOQUE de B asignaciones de etiqueta a la vez --
// MMD-FUSE (Biggs, Schrab & Gretton 2023, NeurIPS, arXiv:2306.08777):
// combina el T_MMD "vspool" U-estadistico (mmdtype(vspool), nunca
// maxpairwise) de VARIOS bandwidths/kernels via un soft-max
// regularizado por KL en vez de un solo bandwidth elegido por
// heuristica de mediana, evitando tanto la correccion de Bonferroni
// como partir la muestra:
//   T_FUSE = (1/lambda) * log( mean_g[ exp(lambda * T_g) ] )
// con T_g = T_MMD_vspool_U(bandwidth_g/kernel_g) / sqrt(Nhat(g)) -- la
// normalizacion por Nhat es la que hace que el resultado no dependa de
// la escala arbitraria de cada punto de grilla (ver ksmmd_nhat()
// arriba). Phi_grid trae los G puntos de grilla (v0.7: Gaussianos Y
// Laplace, ver ksmmd_run()) uno al lado del otro en bloques de
// nfeatures() columnas (mismo patron "c0::c1" que mu_all en
// ksmmd_mmd_T_batch), calculados una sola vez en ksmmd_run() -- Phi no
// depende de la permutacion. El teorema de calibracion por permutacion
// (Hemerik & Goeman 2018) vale para CUALQUIER estadistico fijo, asi
// que la grilla/lambda elegidas de antemano no ponen en riesgo la tasa
// de error Tipo I -- sus 2 condiciones concretas (el estadistico
// observado se evalua como una permutacion mas, y la grilla/lambda
// quedan fijas antes de ver las permutaciones de cada corrida) ya se
// cumplen aca. v0.7: la grilla (cuantiles 5%/95%, familias Gaussiana y
// Laplace) y lambda~n_min salen del propio paper MMD-FUSE, generalizado
// a k grupos ponderados -- ver la nota en ksmmd_run() y en el
// encabezado del .ado.
// ---------------------------------------------------------------
real vector ksmmd_mmd_fuse_T_batch(real matrix Phi_grid, real vector w,
    real matrix label_matrix, real vector groups, real vector nhatG,
    real scalar lam)
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
        Tg[.,gi] = ksmmd_mmd_T_batch(Phi_grid[.,c0::c1], w, label_matrix, "vspool", groups) :/ sqrt(nhatG[gi])
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
