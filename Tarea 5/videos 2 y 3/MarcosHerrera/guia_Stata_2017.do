/************************************************************************************
* Tutorial desarrollado para replicar los resultados presentados en el documento
 	 
	      "Econometría Espacial usando Stata. Guía Teórico-Aplicada"
VERSION NOV-2017	 					 
Autor: Marcos Herrera (CONICET-IELDE, UNSa, Argentina)
e-mail: mherreragomez@gmail.com
  
* El tutorial presenta los comandos para generar las siguientes acciones:

1. Análisis exploratorio de datos espaciales:  
	- Representación por medio de Mapas.
	- Creación de matrices de pesos espaciales.
	- Tests espaciales globales: I de Moran, c de Geary y G de Getis y Ord.
2. Econometría Espacial Básica (Corte transversal): SLM, SEM, SARAR, SDM. 
	- Estimación de los parámetros espaciales  por diferentes técnicas: MV y GMM. 
	- Conjunto de contrastes para determinar la especificación  econométrica. 
	- Correcciones a la heterocedasticidad y endogeneidad.
3. Econometría Espacial Avanzada: 
	- Introducción de efectos espaciales en datos de panel.
4. Análisis local
	- LISA: I de Moran Local.
	- G y G* locales de Getis y Ord.
*/
*******************************************************************************************
* IMPORTANTE!
* MODIFICAR: líneas 30,83,84 por el directorio donde se descargaron los archivos 	   
*******************************************************************************************

local DIR = "C:\Users\mherr_000\Documents\Trabajos de Investigacion\Curso Espacial UdeSA 2018" 
cd "`DIR'"

********************************************************************************************
/* 					  INSTALACIÓN DE LOS PAQUETES NECESARIOS    						  */
********************************************************************************************

version 14.2
ssc install spmap
ssc install shp2dta
net install sg162, from(http://www.stata.com/stb/stb60)
net install st0292, from(http://www.stata-journal.com/software/sj13-2)
net install spwmatrix, from(http://fmwww.bc.edu/RePEc/bocode/s)
net install splagvar, from(http://fmwww.bc.edu/RePEc/bocode/s)
ssc install xsmle.pkg
ssc install xtcsd
net install st0446.pkg

************************************************************************************
************************************************************************************
/*            CHAPTER 2: ANÁLISIS EXPLORATORIO DE DATOS ESPACIALES  		   	  */
************************************************************************************
************************************************************************************

************************************************************************************
/*                      (1) LECTURA Y MAPAS DE DATOS  	  		                  */
************************************************************************************

* Leer la información shape en Stata

shp2dta using nuts2_164, database(datos_shp1) coordinates(coord1) genid(id) genc(c)

/* El comando anterior genera dos nuevos archivos: datos_shp.dta y coord.dta
El primero contiene los atributos (variables) del shape. 
El segundo contiene la información sobre la formas geográficas. 
Se generan en el archivo de datos tres variables:
id: identifica a la región. 
c: genera el centroide por medio de las variables: x_c: longitud, y_c: latitud
*/

use datos_shp1, clear
describe

* Mapa mudo (sin información)
spmap using coord, id(id) note("Europa, EU15")

* Ejemplo para eliminar países sin información: Suecia y Finlandia
drop if id==3|id==5|id==6|id==164|id==7|id==8|id==12|id==4|id==2|id==1|id==11|id==12
spmap using coord, id(id) note("Europa sin Finlandia y Suecia, EU15")

/* Ahora se necesita incorporar la información de Eurostat para generar gráficos: */
/* Importamos y transformamos los datos de Excel a formato Stata */
clear all
import excel "C:\Users\mherr_000\Documents\Trabajos de Investigacion\Curso Espacial UdeSA 2018\Practica Stata\migr_unemp.xls", sheet("variables") firstrow
save "C:\Users\mherr_000\Documents\Trabajos de Investigacion\Curso Espacial UdeSA 2018\Practica Stata\migr_unemp.dta", replace

describe

/* Se unirán ambas bases: datos_shp y migr_unemp. Su usa la función merge con la
variable POLY_ID que se encuentra tanto en datos_base como en migr_unemp.dta      */

use datos_shp, clear
merge 1:1 POLY_ID using migr_unemp, gen(union) force
assert union==3 

/* La función assert verifica que la condición sea verdadera. En caso afirmativo no 
genera ningún producto. En caso algún error informará "assertion is false"        */
drop union
save migr_unemp_shp.dta, replace

************************************************************************************
* Representación por medio de mapas

use migr_unemp_shp.dta, clear

* Mapa de cuantiles:
format U2012 %12.1f
spmap U2012 using coord, id(id) clmethod(q) cln(6) title("Tasa de Desempleo") ///
legend(size(medium) position(5)) fcolor(Blues2) note("Europa, 2012" "Fuente: Eurostat")         

format NM2012 %12.1f
spmap NM2012 using coord, id(id) clmethod(q) cln(6) title("Tasa de Migración Neta") ///
legend(size(medium) position(5)) fcolor(BuRd) note("Europa, 2012" "Fuente: Eurostat")           

* Mapa de intervalos iguales
spmap U2012 using coord, id(id) clmethod(e) cln(6) title("Tasa de Desempleo") ///
legend(size(medium) position(5)) fcolor(Blues2) note("Europa, 2012" "Fuente: Eurostat")           

spmap NM2012 using coord, id(id) clmethod(e) cln(6) title("Tasa de Migración Neta") ///
legend(size(medium) position(5)) fcolor(BuRd) note("Europa, 2012" "Fuente: Eurostat")           

* Mapa de diagrama de cajas
spmap U2012 using coord, id(id) clmethod(boxplot) title("Tasa de Desempleo") ///
legend(size(medium) position(5)) fcolor(Heat) note("Europa, 2012" "Fuente: Eurostat")           

spmap NM2012 using coord, id(id) clmethod(boxplot) title("Tasa de Migración Neta") ///
legend(size(medium) position(5)) fcolor(Rainbow) note("Europa, 2012" "Fuente: Eurostat")           

graph hbox U2012, asyvars ytitle("")
graph hbox NM2012, asyvars ytitle("")

* Mapa de desvios
spmap U2012 using coord, id(id) clmethod(s) title("Tasa de Desempleo") ///
legend(size(medium) position(5)) fcolor(Blues2) note("Europa, 2012" "Fuente: Eurostat")           

spmap NM2012 using coord, id(id) clmethod(s) title("Tasa de Migración Neta") ///
legend(size(medium) position(5)) fcolor(BuRd) note("Europa, 2012" "Fuente: Eurostat")           

* Puede combinarse la información de ambas variables por ejemplo: 
spmap U2012 using coord, id(id) fcolor(Blues2) point(data(migr_unemp_shp) xcoord(x_c)  ///
ycoord(y_c) deviation(NM2012) fcolor(red) size(*0.6)) legend(size(medium) position(5)) ///
note("Europa, 2012" "Fuente: Eurostat")                 

spmap NM2012 using coord, id(id) fcolor(BuRd) cln(6) diagram(var(U2012) xcoord(x_c)  ///
ycoord(y_c) fcolor(green) size(1.5)) legend(size(medium) position(5)) ///
note("Europa, 2012" "Fuente: Eurostat")                 

spmap using coord, id(id) fcolor(eggshell) point(xcoord(x_c) ycoord(y_c) ///
proportional(U2012) fcolor(navy) ocolor(white) size(2.5)) legend(size(medium) ///
position(5)) label(xcoord(x_c) ycoord(y_c) label(U2012) color(yellow) size(*0.5)) ///
note("Europa, 2012" "Fuente: Eurostat") 

************************************************************************************
/*      (2) CREACIÓN DE W Y CONTRASTES DE AUTOCORRELACIÓN ESPACIAL  	  		  */
************************************************************************************

spmat contiguity Wcontig using "coord.dta", id(id)
* Problema con el criterio contigüidad: 5 islas.

* Se trabajará con k-nn: 5 vecinos más cercanos estandarizada por filas
spwmatrix gecon y_c x_c, wn(W5st) knn(5) row

* Se necesita la matriz W como objeto SPMAT:
* Para ello se genera 5nn binaria y se exporta a txt

spwmatrix gecon y_c x_c, wn(W5bin) knn(5) xport(W5bin,txt)
* Se lee el archivo y se adapta el formato para SPMAT
insheet using "W5bin.txt", delim(" ") clear
drop in 1
rename v1 id
save "W5bin.dta", replace
* Generamos el objeto SPMAT: W5 estandarizado por filas 
spmat dta W5_st v*, id(id) norm(row)
spmat summarize W5_st, links
spmat graph W5_st
spmat summarize Wcontig, links
************************************************************************************
* TIPS PARA MATRICES

* 1. Convertir una matriz .GAL a formato Stata
*    spwmatrix import using matriz.gal, wname(W_geoda)
* 2. Convertir una matriz .GWT a formato Stata
*    spmat import W_knn using knn.gwt, geoda 
* 3. Pasar de un objeto generado por SPMAT a un objeto SPATWMAT
*    spmat export Wknn using "Wknn_noid.txt", noid replace
*    insheet using "Wknn_noid.txt", delim(" ") clear
*    drop in 1
*    save "Wknn_noid.dta", replace
*    spatwmat using "Wcont_noid.dta", name(Wks) standardize

************************************************************************************
* Contraste I de Moran, c de Geary y G de Getis y Ord.

* Puede usarse una matriz obtenido por el TIP 3:
* use W5bin.dta
* drop id
* save W5bin_noid
* spatwmat using "W5bin_noid.dta", name(W5s) standardize

* Otra forma es usar la matriz ya generada por spwmatrix y compatible con spatgsa
* Se usará esta matríz ya generada

use migr_unemp_shp.dta, clear

spatgsa U2012, w(W5st) moran geary two
spatgsa NM2012, w(W5st) moran geary two

* Para el contraste G de Getis Ord es necesaria una matriz binaria usando:
* spatwmat using "W5bin_noid.dta", name(W5b)
* Nuevamente, ya está generada por spwmatrix
spatgsa U2012, w(W5bin) go two
spatgsa NM2012, w(W5bin) go two

* Diagramas de Dispersión de Moran
splagvar U2012, wname(W5st) wfrom(Stata) ind(U2012) order(1) plot(U2012) moran(U2012)

splagvar NM2012, wname(W5st) wfrom(Stata) ind(NM2012) order(1) plot(NM2012) moran(NM2012)

* Moran bivariado. Diagrama de dispersión cruzado
egen z_U2012 = std(U2012)
egen z_NM2012 = std(NM2012)
splagvar, wname(W5st) ind(z_NM2012) wfrom(Stata) order(1)

reg wx_z_NM2012 z_U2012
twoway (scatter wx_z_NM2012 z_U2012) (lfit wx_z_NM2012 z_U2012, lc(maroon)), xline(0) yline(0) ///
xtitle("U2012") ytitle("Spatially lagged NM2012") title("(Bivariate Moran's I = - 0.447)") legend(off)

************************************************************************************
************************************************************************************
/*                 CHAPTER 3: ECONOMETRÍA ESPACIAL BÁSICA             	  		  */
************************************************************************************
************************************************************************************

************************************************************************************
* Estimación por MCO
************************************************************************************
use ertur_koch_data, clear

* Solow no-restringido
reg lny95 lns lnlgd

* Diagnósticos espaciales
spwmatrix gecon ylat xlong, wname(invdist2_st) wtype(inv) alpha(2) row
spatdiag, weights(invdist2_st)

* Solow restringido
gen lnslgd = lns - lnlgd
reg lny95 lnslgd

* Estimación del parámetro alpha:
display _b[lnslgd]/(1+_b[lnslgd])

spatdiag, weights(invdist2_st)

* Modelo SLX
* Generamos los rezagos espaciales de X's
splagvar, wname(invdist2_st) ind(lns lnlgd) wfrom(Stata) order(1)
reg lny95 lns lnlgd wx_lns wx_lnlgd

* Diagnósticos espaciales
spatdiag, weights(invdist2_st)
 
************************************************************************************
* Modelos Espaciales por Máxima Verosimilitud
************************************************************************************
spwmatrix gecon ylat xlong, wname(invdist2) wtype(inv) alpha(2) xport(Winv2,txt)
insheet using "Winv2.txt", delim(" ") clear
drop in 1
rename v1 id
save "Winv2.dta", replace 
spmat dta Winv2_st v*, id(id) norm(row)

use ertur_koch_data, clear

* Modelo de Rezago Espacial (SLM)
spreg ml lny95 lns lnlgd, id(id) dlmat(Winv2_st)
estimates store modelSLM
* Modelo de Error Espacial (SEM)
spreg ml lny95 lns lnlgd, id(id) elmat(Winv2_st)
estimates store modelSEM
* Modelo SARAR
spreg ml lny95 lns lnlgd, id(id) dlmat(Winv2_st) elmat(Winv2_st)
estimates store modelSARAR

estimates table modelSLM modelSEM modelSARAR, b(%7.3f) star(0.1 0.05 0.01) stats(aic bic)

* Modelo espacial de Durbin (SDM)
spmat lag wx_lns Winv2_st lns
spmat lag wx_lnlgd Winv2_st lnlgd

spreg ml lny95 lns lnlgd wx_lns wx_lnlgd, id(id) dlmat(Winv2_st)
estimates store modelSDM

* Modelo de error espacial de Durbin (SDEM)
spreg ml lny95 lns lnlgd wx_lns wx_lnlgd, id(id) elmat(Winv2_st)
estimates store modelSDEM

* Modelo de Cliff-Ord
spreg ml lny95 lns lnlgd wx_lns wx_lnlgd, id(id) dlmat(Winv2_st) elmat(Winv2_st)
estimates store modelCLIFFORD

estimates table modelSDM modelSDEM modelCLIFFORD, b(%7.3f) star(0.1 0.05 0.01) stats(aic bic)

* Elección entre el SDM y SEM: LR_comfac
lrtest modelSDM modelSEM

* Elección entre el SDM restringido y no-restringido
gen lnslgd = lns - lnlgd
spmat lag wx_lnslgd Winv2_st lnslgd

spreg ml lny95 lnslgd wx_lnslgd, id(id) dlmat(Winv2_st)
estimates store modelSDMr

lrtest modelSDM modelSDMr

* Recuperando los coeficientes estructurales
mata 
b = st_matrix("e(b)") 
beta = b[1,1]
theta = b[1,2]
lambda = b[1,4]
alpha = theta /(theta - lambda)
phi = beta / (1 + beta) - alpha
gamma = - (theta - lambda) / (1 + beta)
alpha
phi
gamma
end

* Comparación SDM vs SDEM restringidos
spreg ml lny95 lnslgd wx_lnslgd, id(id) elmat(Winv2_st)
estimates store modelSDEMr
estimates table modelSDMr modelSDEMr, b(%7.3f) star(0.1 0.05 0.01) stats(aic bic)

* Los modelos más generales "identificados" son SDM y SDEM pero no se encuentran anidados
* entre si. Estrategia Data-driven: La elección entre ambos modelos no es fácil ya que suelen mostrar 
* un similar comportamiento. Los criterios de información pueden ser utilizados para su elección.

* En el paper de Ertur y Koch, el SDEM no es considerado.
* Aquí puede verse que el signo del coeficiente de Wx es contrario a la teoría y puede descartarse.

* COMANDOS ALTERNATIVOS
* Otra alternativas de estimación MV: "spmlreg" de Jeanty o "spatreg" de Pisati
* pero las opciones de subcomandos son menores a "spreg"

************************************************************************************
* Estimación por IV-GMM (NO APLICADA POR ERTUR y KOCH)
************************************************************************************
* Modelo de Rezago Espacial (SLM)
spivreg lny95 lnslgd, id(id) dl(Winv2_st)
estimates store SLMgmm
* La estimación del SLM puede replicarse por comandos habituales en Stata
spmat lag wx2_lnslgd Winv2_st wx_lnslgd
spmat lag wy_lny95 Winv2_st lny95
ivregress 2sls lny95 lnslgd (wy_lny95 = wx_lnslgd wx2_lnslgd)

* SLM asumiendo heteroscedasticidad
spivreg lny95 lnslgd, id(id) dl(Winv2_st) het
estimates store SLMgmm_het

* Modelo de Error Espacial (SEM)
spivreg lny95 lnslgd, id(id) el(Winv2_st)
estimates store SEMgmm
* SEM con heterocedasticidad
spivreg lny95 lnslgd, id(id) el(Winv2_st) het
estimates store SEMgmm_het

* Modelo SARAR
spivreg lny95 lnslgd, id(id) el(Winv2_st) dl(Winv2_st)
estimates store SARARgmm
* Modelo SARAR con heterocedasticidad
spivreg lny95 lnslgd, id(id) el(Winv2_st) dl(Winv2_st) het
estimates store SARARgmm_het

estimates table SLMgmm SEMgmm SARARgmm, b(%7.3f) star(0.1 0.05 0.01)
estimates table SLMgmm_het SEMgmm_het SARARgmm_het, b(%7.3f) star(0.1 0.05 0.01)

* Modelo de Durbin
spivreg lny95 lnslgd wx_lnslgd, id(id) dl(Winv2_st)
estimates store SDMgmm
*ereturn list
spivreg lny95 lnslgd wx_lnslgd, id(id) dl(Winv2_st) het
estimates store SDMgmm_het

* Modelo de error de Durbin
spivreg lny95 lnslgd wx_lnslgd, id(id) el(Winv2_st)
estimates store SDEMgmm
*ereturn list
spivreg lny95 lnslgd wx_lnslgd, id(id) el(Winv2_st) het
estimates store SDEMgmm_het

* Modelo Cliff-Ord
spivreg lny95 lnslgd wx_lnslgd, id(id) dl(Winv2_st) el(Winv2_st)
estimates store CLIFFORDgmm
*ereturn list
spivreg lny95 lnslgd wx_lnslgd, id(id) dl(Winv2_st) el(Winv2_st) het
estimates store CLIFFORDgmm_het

estimates table SDMgmm SDEMgmm CLIFFORDgmm, b(%7.3f) star(0.1 0.05 0.01)
estimates table SDMgmm_het SDEMgmm_het CLIFFORDgmm_het, b(%7.3f) star(0.1 0.05 0.01)

* Otra alternativa con similares resultados es spivreg es: "spreg gs2sls" 

************************************************************************************
************************************************************************************
/*                   CHAPTER 4: ANÁLISIS ESPACIAL LOCAL             	  		  */
************************************************************************************
* En esta parte se utilizarán dos conjuntos de datos simultáneamente

use migr_unemp_shp.dta, clear

************************************************************************************
* 1. CONTRASTES LOCALES
************************************************************************************

spwmatrix gecon y_c x_c, wn(W5bin) knn(5)
spatlsa U2012, w(W5bin) moran sort twotail
spatlsa NM2012, w(W5bin) moran sort twotail

* Contraste I de Moran local
genmspi U2012, w(W5st)
graph twoway (scatter Wstd_U2012 std_U2012 if pval_U2012>=0.05, msymbol(i) mlabel (id)    ///
mlabsize(*0.6) mlabpos(c)) (scatter Wstd_U2012 std_U2012 if pval_U2012<0.05, msymbol(i)   ///
mlabel (id) mlabsize(*0.6) mlabpos(c) mlabcol(red)) (lfit Wstd_U2012 std_U2012), yline(0, ///
lpattern(--)) xline(0, lpattern(--)) xlabel(-2.5(1)4.5, labsize(*0.8)) xtitle("{it:z}")   ///
ylabel(-2.5(1)4.5, angle(0) labsize(*0.8)) ytitle("{it:Wz}") legend(off) scheme(s1color)  ///
title("Diagrama local de Moran") note("En rojo, regiones significativas al 5%")

spmap msp_U2012 using coord, id(id) clmethod(unique) title("Mapa de Clusters según Moran local")   ///
legend(size(medium) position(4)) ndl("No signif.") fcolor(blue red)

genmspi NM2012, w(W5st)
graph twoway (scatter Wstd_NM2012 std_NM2012 if pval_NM2012>=0.05, msymbol(i) mlabel (id)    ///
mlabsize(*0.6) mlabpos(c)) (scatter Wstd_NM2012 std_NM2012 if pval_NM2012<0.05, msymbol(i)   ///
mlabel (id) mlabsize(*0.6) mlabpos(c) mlabcol(red)) (lfit Wstd_NM2012 std_NM2012), yline(0, ///
lpattern(--)) xline(0, lpattern(--)) xlabel(-2.5(1)4.5, labsize(*0.8)) xtitle("{it:z}")   ///
ylabel(-2.5(1)2.5, angle(0) labsize(*0.8)) ytitle("{it:Wz}") legend(off) scheme(s1color)  ///
title("Diagrama local de Moran") note("En rojo, regiones significativas al 5%")

spmap msp_NM2012 using coord, id(id) clmethod(unique) title("Mapa de Clusters según Moran local")   ///
legend(size(medium) position(4)) ndl("No signif.") fcolor(blue blue*0.5 red*0.5 red)  

****************************************
* Cluster por Getis-Ord

* Matriz binaria
getisord U2012, lat(y_c) lon(x_c) swm(bin) dist(300) dunit(km) detail approx
spmap go_z_U2012_b using coord, id(id) clmethod(custom) clb(-100 -1.965 1.965 100) legtitle("{it: z}-value") legend(size(medium) pos(5)) title("Mapa de Clusters según Getis-Ord") legstyle(1) fcolor(ebblue white red) note("Europa, 2012" "Fuente: Eurostat")

getisord NM2012, lat(y_c) lon(x_c) swm(bin) dist(300) dunit(km) detail approx
spmap go_z_NM2012_b using coord, id(id) clmethod(custom) clb(-100 -1.965 1.965 100) legtitle("{it: z}-value") legend(size(medium) pos(5)) title("Mapa de Clusters según Getis-Ord") legstyle(1) fcolor(ebblue white red) note("Europa, 2012" "Fuente: Eurostat")

* Matriz exponencial
getisord U2012, lat(y_c) lon(x_c) swm(exp 2) dist(300) dunit(km) detail approx
spmap go_z_U2012_e using coord, id(id) clmethod(custom) clb(-100 -2.576 -1.965 1.965 2.576 100) legtitle("{it: z}-value") legend(size(medium) pos(5)) legstyle(1) fcolor(ebblue eltblue white orange red) note("Europa, 2012" "Fuente: Eurostat")
* Matriz potencia
getisord U2012, lat(y_c) lon(x_c) swm(pow 1) constant(0.01) dist(300) dunit(km) detail approx
spmap go_z_U2012_p using coord, id(id) clmethod(custom) clb(-100 -2.576 -1.965 1.965 2.576 100) legtitle("{it: z}-value") legend(size(medium) pos(5)) legstyle(1) fcolor(ebblue eltblue white orange red) note("Europa, 2012" "Fuente: Eurostat")

* Usando Getis-Ord para varioas años
getisord U2001, lat(y_c) lon(x_c) swm(bin) dist(300) dunit(km) detail approx
getisord U2004, lat(y_c) lon(x_c) swm(bin) dist(300) dunit(km) detail approx
getisord U2007, lat(y_c) lon(x_c) swm(bin) dist(300) dunit(km) detail approx
getisord U2011, lat(y_c) lon(x_c) swm(bin) dist(300) dunit(km) detail approx
twoway (kdensity go_z_U2001_b) (kdensity go_z_U2004_b) (kdensity go_z_U2007_b) (kdensity go_z_U2011_b)

************************************************************************************
/*                CHAPTER 5: ECONOMETRÍA ESPACIAL AVANZADA             	  		  */
************************************************************************************
* En esta parte se utilizarán dos conjuntos de datos simultáneamente

************************************************************************************
* 5.1 MODELOS ESTÁTICOS
************************************************************************************

* EJEMPLO MIGRACION-DESEMPLEO
use migr_unemp_shp.dta, clear

* Matriz W espacio-temporal
****************************************************
* Modificamos la estructura de la matriz de 5nn usada en el corte transversal:
insheet using "W5bin.txt", delim(" ") clear
drop in 1
drop v1
mkmat v2-v165, mat(W5nn_bin)
save W5nn_bin.dta, replace

* Generamos W spmat, formato requerido por xsmle
spmat dta W5_st v2-v165, norm(row)
drop v2-v165

* Creamos una matriz (T*n)x(T*n)
*set matsize 656
mat TMAT=I(4)
mat W5xt_bin=TMAT#W5nn_bin
svmat W5xt_bin
drop v2-v165
save W5xt_bin.dta, replace

use migr_unemp_shp.dta, clear
reshape long NM U, i(id) j(year)
sort year id
* Utilizamos los últimos 4 años
drop if year<2009

****************************************************
* Modelo Pooled
****************************************************

* Pooled sin efectos fijos
spwmatrix import using W5xt_bin.dta, wname(W5xt_st) row dta conn
reg U NM
spatdiag, weights(W5xt_st)

****************************************************
* Modelo con efectos específicos
****************************************************

* Efectos individuales y temporales fijos
quietly tab id, gen(nut)
quietly tab year, ge(t)
recast float nut*, force
recast float t*, force

quietly reg U NM nut2-nut164 t2-t4
spatdiag, weights(W5xt_st)
testparm nut2-nut164
testparm t2-t4

****************************************************
* Modelo SLX + efectos específicos
****************************************************

splagvar, wname(W5xt_st) ind(NM) wfrom(Stata) order(1)

quietly reg U NM wx_NM nut2-nut164 t2-t4
spatdiag, weights(W5xt_st)
testparm nut2-nut164
testparm t2-t4

* Detección de dependencia espacial genérica
sort id year
tsset id year

xtreg U NM t2-t4, fe
xtcsd, pes abs

xtreg U NM wx_NM t2-t4, re
xtcsd, pes abs

****************************************************
* Modelo SLM
****************************************************

* Efectos fijos
xsmle U NM, fe type(both) wmat(W5_st) mod(sar) hausman
xsmle U NM t2-t4, fe type(both, leeyu) wmat(W5_st) mod(sar)

* Efectos aleatorios
xsmle U NM t2-t4, re type(ind) wmat(W5_st) mod(sar)

****************************************************
* Modelo SEM
****************************************************

* Efectos fijos
xsmle U NM, fe type(both) emat(W5_st) mod(sem) hausman
xsmle U NM t2-t4, fe type(ind, leeyu) emat(W5_st) mod(sem)

* Efectos aleatorios
xsmle U NM, re type(both) emat(W5_st) mod(sem)

****************************************************
* Modelo SARAR
****************************************************

* Efectos fijos
xsmle U NM, fe wmat(W5_st) emat(W5_st) mod(sac)

****************************************************
* Modelo SDM
****************************************************

* Efectos fijos
xsmle U NM, fe type(ind) wmat(W5_st) mod(sdm) noeffects
* Test de factores comunes
testnl ([Wx]NM = -[Spatial]rho*[Main]NM)

* Efectos aleatorios
xsmle U NM, wmat(W5_st) mod(sdm)

****************************************************
* Modelo SDEM
****************************************************

* Efectos fijos
xsmle U NM wx_NM t2-t4, fe type(ind) emat(W5_st) mod(sem)

* Efectos aleatorios
xsmle U NM wx_NM, wmat(W5_st) mod(sdm)

****************************************************
* Modelo CLIFFORD por efectos fijos y previos
****************************************************

* Estimación del modelo CLIFFORD
quietly xsmle U NM wx_NM t2-t4, fe wmat(W5_st) ematrix(W5_st) type(ind, leeyu) model(sac) noeffects nolog r
estimate store CLIFFORD

* Estimación de modelo SDEM
quietly xsmle U NM wx_NM t2-t4, fe ematrix(W5_st) type(ind, leeyu) model(sem) nolog r
estimate store SDEM
*lrtest CLIFFORD SDEM

* Estimación de modelo SDM
quietly xsmle U NM t2-t4, fe type(ind, leeyu) wmat(W5_st) mod(sdm) nolog noeffects r
estimate store SDM

* Estimación de modelo SLM
quietly xsmle U NM t2-t4, fe type(ind, leeyu) wmatrix(W5_st) model(sar) nolog noeffects r
estimate store SLM
*lrtest CLIFFORD SLM

* Estimación de modelo SEM
quietly xsmle U NM t2-t4, fe ematrix(W5_st) type(ind, leeyu) model(sem) nolog r
estimate store SEM

* Estimación del modelo SARAR
quietly xsmle U NM t2-t4, fe wmat(W5_st) ematrix(W5_st) type(ind, leeyu) model(sac) noeffects nolog r
estimate store SARAR
*lrtest CLIFFORD SARAR

estimates table CLIFFORD SARAR, b(%7.3f) star(0.1 0.05 0.01) stats(ll aic bic) stf(%9.0f) drop(t*)

estimates table SDEM SDM SLM SEM, b(%7.3f) star(0.1 0.05 0.01) stats(ll aic bic) stf(%9.0f) drop(t*)

* Interpretación de los resultados
************************************************************************************
* Efectos fijos
quietly xsmle U NM t2-t4, fe type(ind, leeyu) wmat(W5_st) model(sdm) nolog r nsim(999) effects
estimate store SDMef
quietly xsmle U NM t2-t4, fe type(ind, leeyu) wmatrix(W5_st) model(sar) nolog r nsim(999) effects
estimate store SLMef

estimates table SDMef SLMef, b(%7.3f) drop(t*) star(0.1 0.05 0.01) stf(%9.0f)


************************************************************************************
************************************************************************************
************************************************************************************

* EJEMPLO DEMANDA DE TABACO

* Matriz W espacio-temporal
************************************************
* Cargamos la matriz de contactos
infile m1-m46 using spat_sym_us.txt, clear
mkmat m1-m46, mat(Wct_bin)
save Wct_bin.dta, replace

spwmatrix import using Wct_bin.dta, wname(Wct_bin) dta

* Generamos W spmat, formato requerido por xsmle
spmat dta Wst m1-m46, norm(row)
drop m1-m46

set matsize 1380
mat TMAT=I(30)
mat W_xt_bin=TMAT#Wct_bin
svmat W_xt_bin
save W_xt_bin.dta, replace

****************************************************
* Modelo Pooled
****************************************************
use baltagi_cigar.dta, clear

sort year state

spwmatrix import using W_xt_bin.dta, wname(Wxt_st) row dta
reg logc logp logy
spatdiag, weights(Wxt_st)

****************************************************
* Modelo con efectos específicos
****************************************************

* Efectos individuales y temporales fijos
quietly tab state, ge(state)
quietly tab year, ge(t)
recast float state*, force
recast float t*, force

quietly reg logc logp logy state2-state46 t2-t30
spatdiag, weights(Wxt_st)
testparm state2-state46
testparm t2-t30

****************************************************
* Modelo SLX + efectos específicos
****************************************************

splagvar, wname(Wxt_st) ind(logp logy) wfrom(Stata) order(1)

quietly reg logc logp logy wx_logp wx_logy state2-state46 t2-t30
spatdiag, weights(Wxt_st)
testparm state2-state46
testparm t2-t30

* Detección de dependencia espacial genérica
sort state year
tsset state year

quietly xtreg logc logp logy wx_logp wx_logy t2-t30, fe
xtcsd, pes abs

quietly xtreg logc logp logy wx_logp wx_logy t2-t30, re
xtcsd, pes abs

****************************************************
* Modelo SLM
****************************************************

* Efectos fijos
xsmle logc logp logy, fe type(both) wmat(Wst) mod(sar) noeffects nolog hausman

xsmle logc logp logy, fe type(both, leeyu) wmat(Wst) mod(sar) noeffects nolog hausman
* Cuidado con el código que se ejecuta cambiando opciones!
xsmle logc logp logy t2-t30, fe type(ind, leeyu) wmat(Wst) mod(sar) noeffects nolog hausman

* Efectos aleatorios
xsmle logc logp logy, re type(both) wmat(Wst) mod(sar) noeffects nolog

****************************************************
* Modelo SEM
****************************************************

* Efectos fijos
xsmle logc logp logy, fe type(both) emat(Wst) mod(sem) nolog hausman
xsmle logc logp logy t2-t30, fe type(ind, leeyu) emat(Wst) mod(sem) nolog hausman

* Efectos aleatorios
xsmle logc logp logy, re type(both) emat(Wst) nolog mod(sem)

****************************************************
* Modelo SARAR
****************************************************

* Efectos fijos
xsmle logc logp logy, fe wmat(Wst) type(both) emat(Wst) mod(sac) noeffects nolog

xsmle logc logp logy t2-t30, fe wmat(Wst) type(ind, leeyu) emat(Wst) mod(sac) noeffects nolog

****************************************************
* Modelo SDM
****************************************************

* Efectos fijos
xsmle logc logp logy, fe type(both) wmat(Wst) mod(sdm) hausman noeffects nolog
* Test de factores comunes
testnl ([Wx]logp = -[Spatial]rho*[Main]logp) ([Wx]logy = -[Spatial]rho*[Main]logy)
* Test reducción SLM
test ([Wx]logp = 0) ([Wx]logy = 0) 

* Efectos aleatorios
xsmle logc logp logy, re type(both) wmat(Wst) mod(sdm) noeffects nolog

****************************************************
* Modelo SDEM
****************************************************

* Efectos fijos
xsmle logc logp logy wx_logp wx_logy, fe type(both) emat(Wst) mod(sem) hausman nolog

****************************************************
* Modelo CLIFFORD y demás con efectos fijos
****************************************************

* Estimación del modelo CLIFFORD
xsmle logc logp logy wx_logp wx_logy t2-t30, fe wmat(Wst) ematrix(Wst) type(ind) model(sac) noeffects nolog
estimate store CLIFFORD

* Estimación del modelo SARAR, denominado SAC.
quietly xsmle logc logp logy t2-t30, fe wmat(Wst) emat(Wst) type(ind) model(sac) noeffects nolog
estimate store SARAR

* Estimación de modelo SDEM
xsmle logc logp logy wx_logp wx_logy t2-t30, fe emat(Wst) type(ind) model(sem) nolog
estimate store SDEM

* Estimación de modelo SDM
xsmle logc logp logy wx_logp wx_logy t2-t30, fe wmat(Wst) type(ind) mod(sar) noeffects nolog
estimate store SDM

* Estimación de modelo SLM
quietly xsmle logc logp logy t2-t30, fe wmat(Wst) type(ind) model(sar) nolog noeffects
estimate store SLM

* Estimación de modelo SEM
quietly xsmle logc logp logy t2-t30, fe emat(Wst) type(ind) model(sem) nolog
estimate store SEM

estimates table SLM SEM SARAR SDM SDEM CLIFFORD, b(%7.3f) drop(t2-t30) star(0.1 0.05 0.01) stats(ll aic bic) stf(%9.0f)

lrtest CLIFFORD SARAR
lrtest CLIFFORD SDEM
lrtest CLIFFORD SDM

************************************************************************************
* 5.3 Interpretación de los resultados
************************************************************************************
* Efectos fijos
quietly xsmle logc logp logy, fe type(both) wmat(Wst) mod(sdm) effects nsim(999)
estimate store SDMfe2
quietly xsmle logc logp logy, fe type(both, leeyu) wmat(Wst) mod(sdm) effects nsim(999)
estimate store SDMleeyu
estimates table SDMfe2 SDMleeyu, b(%7.3f) star(0.1 0.05 0.01) stf(%9.0f)


************************************************************************************
* 5.4 MODELOS DINÁMICOS
************************************************************************************

************************************************************************************
* EJEMPLO CONSUMO DE TABACO
************************************************************************************

****************************************************
* Detección de dependencia temporal
xtserial logc logp logy

* Modelos SLM espacio-temporales
quietly xsmle logc logp logy, dlag(1) fe wmat(Wst) type(ind) mod(sar) nolog effects nsim(999)
estimate store SLM_simul
quietly xsmle logc logp logy, dlag(2) fe wmat(Wst) type(ind) mod(sar) nolog effects nsim(999)
estimate store SLM_recur
quietly xsmle logc logp logy, dlag(3) fe wmat(Wst) type(ind) mod(sar) nolog effects nsim(999)
estimate store SLM_dinam

estimates table SLM_simul SLM_recur SLM_dinam, b(%7.3f) star(0.1 0.05 0.01) stats(ll aic bic) stf(%9.0f)

* Modelos SDM espacio-temporales
xsmle logc logp logy, dlag(1) fe wmat(Wst) type(ind) mod(sdm) nolog effects nsim(999)
estimate store SDM_simul
*xsmle logc logp logy wx_logp wx_logy, dlag(1) fe wmat(Wst) type(ind) mod(sar) effects
*estimate store SDM_simul

xsmle logc logp logy, dlag(2) fe wmat(Wst) type(ind) mod(sdm) effects nsim(999)
estimate store SDM_recur

xsmle logc logp logy, dlag(3) fe wmat(Wst) type(ind) mod(sdm) effects nsim(999)
estimate store SDM_dinam
*xsmle logc logp logy wx_logp wx_logy, dlag(3) fe wmat(Wst) type(ind) mod(sar) effects
*estimate store SDM_dinam

estimates table SDM_simul SDM_recur SDM_dinam, b(%7.3f) star(0.1 0.05 0.01) stats(ll aic bic) stf(%9.0f)

* Recuperando los modelos dinámicos y comparando predicciones
est restore SLM_simul
predict y_simul
est restore SLM_recur
predict y_recur
est restore SLM_dinam
predict y_dinam

twoway (kdensity logc) (kdensity y_simul) (kdensity y_recur) (kdensity y_dinam)
twoway (scatter logc logc) (scatter y_simul logc)
twoway (scatter logc logc) (scatter y_recur logc)
twoway (scatter logc logc) (scatter y_dinam logc)
