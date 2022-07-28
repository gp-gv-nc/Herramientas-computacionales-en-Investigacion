/************************************************************************************
* Tutorial basado 
"Econometría Espacial usando Stata. Guía Teórico-Aplicada"	 					 
Autor: Marcos Herrera (CONICET-IELDE, UNSa, Argentina)
e-mail: mherreragomez@gmail.com
  
* El tutorial presenta los comandos para generar las siguientes acciones:

1. Análisis exploratorio de datos espaciales:  
	- Representación por medio de Mapas.
	- Creación de matrices de pesos espaciales.
*/
	
global DATA = "/Users/Downloads/videos 2 y 3/data" 
cd "$DATA"

********************************************************************************************
/* 					  INSTALACIÓN DE LOS PAQUETES NECESARIOS    						  */
********************************************************************************************

ssc install spmap
ssc install shp2dta
*net install sg162, from(http://www.stata.com/stb/stb60)
*net install st0292, from(http://www.stata-journal.com/software/sj13-2)
net install spwmatrix, from(http://fmwww.bc.edu/RePEc/bocode/s)
*net install splagvar, from(http://fmwww.bc.edu/RePEc/bocode/s)
*ssc install xsmle.pkg
*ssc install xtcsd
*net install st0446.pkg

************************************************************************************
************************************************************************************
/*            CHAPTER 2: ANÁLISIS EXPLORATORIO DE DATOS ESPACIALES  		   	  */
************************************************************************************
************************************************************************************

************************************************************************************
/*                      (1) LECTURA Y MAPAS DE DATOS  	  		                  */
************************************************************************************

* Leer la información shape en Stata

shp2dta using london_sport.shp, database(ls) coord(coord_ls) genc(c) genid(id) replace

/* El comando anterior genera dos nuevos archivos: datos_shp.dta y coord.dta
El primero contiene los atributos (variables) del shape. 
El segundo contiene la información sobre la formas geográficas. 
Se generan en el archivo de datos tres variables:
id: identifica a la región. 
c: genera el centroide por medio de las variables: x_c: longitud, y_c: latitud
*/

use ls, clear
describe

use coord_ls, clear
describe

/* Importamos y transformamos los datos de Excel a formato Stata */
import delimited "$DATA/mps-recordedcrime-borough.csv", clear 
* En Stata necesitamos que la variable tenga el mismo nombre en ambas bases para juntarlas
rename borough name
* preserve
collapse (sum) crimecount, by(name)
save "crime.dta", replace

describe

/* Uniremos ambas bases: london_sport y crime. Su usa la función merge con la variable name que se encuentra en ambas bases  */

use ls, clear
merge 1:1 name using crime.dta
*merge 1:1 name using crime.dta, keep(3) nogen
*keep if _m==3
drop _m

save london_crime_shp.dta, replace

************************************************************************************
* Representación por medio de mapas

use london_crime_shp.dta, clear

* Mapa de cuantiles:
spmap crimecount using coord_ls, id(id) clmethod(q) cln(6)

spmap crimecount using coord_ls, id(id) clmethod(q) cln(6) title("Número de crímenes") legend(size(medium) position(5) xoffset(15.05)) fcolor(Blues2) plotregion(margin(b+15)) ndfcolor(gray) name(g1,replace)  

spmap crimecount using coord_ls, id(id) clmethod(q) cln(6) title("Número de crímenes") legend(size(medium) position(5) xoffset(15.05)) fcolor(Blues) plotregion(margin(b+15)) ndfcolor(gray) name(g2,replace)  

* Mapa de intervalos iguales
spmap crimecount using coord_ls, id(id) clmethod(e) cln(6) title("Número de crímenes") legend(size(medium) position(5) xoffset(17.05)) fcolor(BuRd) plotregion(margin(b+15)) ndfcolor(gray)           

* Mapa de diagrama de cajas
spmap crimecount using coord_ls, id(id) clmethod(boxplot) title("Número de crímenes") legend(size(medium) position(5) xoffset(17.05)) fcolor(Heat) plotregion(margin(b+15)) ndfcolor(gray)           

* Mapa de desvios
spmap crimecount using coord_ls, id(id) clmethod(s) title("Número de crímenes") legend(size(medium) position(5) xoffset(14.05)) fcolor(Purples) plotregion(margin(b+15)) ndfcolor(gray)                  

* Puede combinarse la información de ambas variables por ejemplo: 
spmap crimecount using coord_ls, title("Crimenes y Población") id(id) fcolor(Blues) cln(6) ndfcolor(gray) point(data(london_crime_shp) xcoord(x_c) ycoord(y_c) deviation(Pop) fcolor(red) size(*.6) legenda(on) leglabel(Pop)) legend(size(medium) position(5) xoffset(15.05)) plotregion(margin(b+15)) name(g1,replace)  
  
spmap Pop using coord_ls, id(id) clmethod(q) cln(10) title("Población") legend(size(medium) position(5) xoffset(15.05)) fcolor(Blues2) plotregion(margin(b+15)) ndfcolor(gray) name(g2, replace)            

spmap Pop using coord_ls, id(id) fcolor(Blues) cln(6) diagram(var(crimecount) legenda(on) legtitle(" ") xcoord(x_c) ycoord(y_c) fcolor(green) size(1.5)) legend(size(medium) position(5) xoffset(14.05) title("Population", size(medium))) plotregion(margin(b+15)) note("El máximo nivel de crimen representado por el tamaño de la barra" "La línea representa el promedio") 

label var crimecount "Crímenes total"

gen no_p=100-Partic_Per
label var Partic "Sports"
label var no_p "No Sports"

spmap crimecount using coord_ls, id(id) fcolor(Blues) cln(6) diagram(var(Partic no_p) legenda(on) legtitle(" ") xcoord(x_c) ycoord(y_c) fcolor(green) size(1)) legend(size(medium) position(5) xoffset(14.05) yoffset(-1.5) title("Crime", size(medium))) plotregion(margin(b+15)) ndfcolor(gray) 

spmap crime using coord_ls, id(id) fcolor(Purples) point(xcoord(x_c) ycoord(y_c) proportional(Part) fcolor(navy) ocolor(white) size(4) legenda(on) legl(Sports)) label(xcoord(x_c) ycoord(y_c) label(Part) color(yellow) size(*0.8)) legend(size(medium) position(5) xoffset(14.05) title("Crime", size(medium))) plotregion(margin(b+15)) ndfcolor(gray) 
