/*
Enunciado 1.  
Explora el fichero flights y analiza: 
1. Cuántos registros hay en total 
2. Cuántos vuelos distintos hay 
3. Cuántos vuelos tienen más de un registro
*/ 
--1
select 
	count(*) as total_record
from flights;
--2
select 
	count(distinct unique_identifier) as total_flights
from flights;
--3
with repeated_flights as (
select 
	unique_identifier,
	count(unique_identifier) as total_flights
from flights
group by unique_identifier
having count(unique_identifier) > 1
)
select 
	sum(distinct total_flights) as repeated_flights
from repeated_flights
;
----------------------------------------------------------------------------
/*
Enunciado 2. 
Por qué hay registro duplicados para un mismo vuelo. Para ello, selecciona varios vuelos y 
analiza la evolución temporal de cada vuelo. 
1. Qué información cambia de un registro a otro
*/
with repeated_flights as (
select 
	unique_identifier,
	count(unique_identifier) as total_flights
from flights
group by unique_identifier
having count(unique_identifier) > 1
)
select *
from repeated_flights;

select 
	unique_identifier,
	departure_airport,
	arrival_airport,
	local_departure,
	local_arrival,
	local_actual_departure,
	local_actual_arrival,
	created_at,
	updated_at
from flights
where unique_identifier = 'IB-6824-20220714-GRU-MAD';

----Analisis aeropuertos 

with diferent_airports as(
select
	departure_airport as total_airports
from flights
union 
select
	arrival_airport
from flights
), all_airports as (

select 
	dai.total_airports,
	air.airport_name
from diferent_airports as dai 
left join airports as air 
on dai.total_airports = air.airport_code
)
select 
	*
from all_airports
where airport_name  is not null;

/*
Despues de coger los vuelos que se repiten y analizar diferentes casos de vuelos repetidos he 
llegado a la conclusión que existen dos casos diferentes.

1.- El primer caso son los vuelos cuyo aeropuerto de salida o de llegada no se encuentra registrado
	en la tabla de aeropuertos por ejemplo el vuelo con identificador: 'IB-6824-20220714-GRU-MAD', no 
	existe ningun aeropuerto con codigo 'GRU'. El patron que se repite en estos vuelos es que sus valores
	en 'created_at' y 'updated_at' son nulos para todos ellos.
2.- El segundo caso los dos aeropuertos se encuentran en la tabla de datos de airports. Primero hay que 
	recalcar que las dos columnas que en el primer caso son nulas, en el segundo caso tienen contenido, la
	diferencia entre los diferentes registros del mismo vuelo se encuentran en en la columna 'updated_at'. Esta
	va cambiando cambiando en cada registro.
	
Además luego de analizar los aeropuertos, ya que me llamo la etención el primer caso, despues de analizar el
total de los aeropuertos, puedo afirmar, de los 39 diferentes codigos de aeropuertos, solo hay 8 registrados
en la tabla 'airport'. 


-----------------------------------------------------
Enunciado 3. 
Evalúa la calidad del dato. La calidad del dato nos indica si la información es consistente, 
completa, coherente y representa una realidad verosímil. Para ello debemos establecer 
unos criterios: 
1. La información de created_at debe ser única para cada vuelo aunque tenga más de 
un registro. 
2. La información de updated_at deber ser igual o más que la información de 
created_at, lo que nos indica coherencia y consistencia	
*/ 

with diferent_flights as (
select 
	unique_identifier,
	created_at,
	updated_at
from flights
)
select 
	count(*) as total
from diferent_flights
where created_at is  not null
and created_at <= updated_at;

/* 
De los 1209 registros totales, 569 tienen registros null en las columnas 'created_at' y 'updated_at'. Como cabe
de esperar 640 si tienen contenido en ambas columnas. Además de esos 640 registros, todos son válidos ya que la
columna 'created_at' es menor o igual a 'updated_at'.

En cuanto al analisis del dato, teniendo en cuenta que casi la  mitad de los registros de las columnas analizadas
tienen valores nulos, añadiendo también el problema antes mencionado con los aeropuertos, puede verse que la calidad
del dato en este caso no sería la mas optima.


------------------------------------------------------
Enunciado 4. 
El último estado de cada vuelo. Cada vuelo puede aparecer varias veces en el dataset, para 
avanzar con nuestro análisis necesitamos quedarnos solo con el último registro de cada 
vuelo.  
Puedes crear una tabla o vista resultante de esta query en tu base de datos local, la 
utilizaremos en los siguientes enunciados. Si prefieres no guardar la última información, 
tendrás que hacer uso de esa query como una CTE en los enunciados siguientes. 
*/ 
with last_register as (
select 
	*,
	row_number() over ( 
		partition by unique_identifier
		order by updated_at desc
	) as rn 
from flights
)
select *
from last_register
where rn =1;

------------------------------------------------------
/*
Enunciado 5. 
Considerando que los campos local_departure y local_actual_departure son necesarios 
para el análisis, valida y reconstruye estos valores siguiendo estas reglas: 
1. Si local_departure es nulo, utiliza created_at. 
2. Si local_actual_departure es nulo, utiliza local_departure. Si este también es nulo, 
utiliza created_at. 
Crea dos nuevos campos: 
● effective_local_departure 
● effective_local_actual_departure 
Extra: 
Realiza las validaciones para los campos local_arrival y local_actual_arrival.

*/ 

with effective_departure as(
select 
	unique_identifier,
	local_departure,
	local_actual_departure,
	local_arrival,
	local_actual_arrival,
	created_at,
	case 
		when local_departure is null then created_at
		else local_departure
	end as effective_local_departure,
	case 
		when local_actual_departure is null then local_departure
		when local_departure is null and local_departure is null then created_at
		else local_actual_departure
	end as effective_local_actual_departure,
	case 
		when local_arrival is null then created_at
		else local_arrival
	end as effective_local_arrival,
	case 
		when local_actual_arrival is null then local_arrival
		else local_actual_arrival
	end as effective_local_actual_arrival
from flights
)
select 
	unique_identifier,
	effective_local_departure,
	effective_local_arrival,
	effective_local_actual_departure,
	effective_local_actual_arrival
from effective_departure;

/*
En la columna effective_local_actual siguen existiendo 10 valores NULL, doy por echo que se deben a los vuelos
con valor nulos en 'created_at' y las otras columnas de la que depende.
------------------------------------------------------------------

Enunciado 6. 
Análisis del estado del vuelo. Haciendo uso del resultado del enunciado 4, analiza los 
estados de los vuelos.  
1. Qué estados de vuelo existen 
2. Cuántos vuelos hay por cada estado 
¿Podrías decir qué significa las siglas de cada estado
*/ 

with last_register as (
select 
	*,
	row_number() over ( 
		partition by unique_identifier
		order by updated_at desc
	) as rn 
from flights
), 
last_register_flights as(
select 
	*
from last_register
where rn =1
)
select 
	arrival_status,
	count(arrival_status) as flight_state
from last_register_flights
group by arrival_status;
/* 
CX ->  Cancelled,
DY -> Delayed,
EY ->  Early,
NS ->  No Show,
OT -> On Time,
---------------------------------------------------------------------

Enunciado 7. 
País de salida de cada vuelo. Tienes disponible un csv. con información de aeropuertos 
airports.csv. Haciendo uso del resultado del enunciado 4, analiza los aeropuertos de salida. 
1. De qué país despegan los vuelos 
2. Cuántos vuelos despegan por país
*/

with last_register as (
select 
	*,
	row_number() over ( 
		partition by unique_identifier
		order by updated_at desc
	) as rn 
	
from flights
), 
last_register_flights as(
select 
	*
from last_register
where rn =1
), 
airport_flights as (
select 
	lrg.departure_airport,
	aip.country,
	count(lrg.departure_airport) as total_flights,
	
from last_register as lrg
left join airports as  aip 
on lrg.departure_airport = aip.airport_code
group by 1,2
)
select 
	country,
	sum(total_flights) as flights_per_country
from airport_flights
group by 1;
/*
Con el problema mencionado en el ejercisio 2, muchos de los aeropuertos no contienen pais ya que estos
no estan registrados dentro de la tabla airport. En cuanto a vuelos por pais es dificil de decir por ejemplo
en vuelos en España salen un total de 484, pero doy por hecho que hay aeropuertos con valor en 'country' null
que podria pertenecer a España, por ejemplo doy por hecho que el codigo LPA, se refiere al codigo del aeropuerto
de Las Palmas.
--------------------------------------------------------

Enunciado 8. 
Delay medio y estado de vuelo por país de salida. Haciendo uso del resultado del enunciado 
4, analiza el estado y el delay/retraso medio con el objetivo de identificar si existen países 
que pueden presentar problemas operativos en los aeropuertos de salida. 
1. Cuál es el delay medio por país 
2. Cuál es la distribución de estados de vuelos por país.
*/
--1.-
with last_register as (
select 
	*,
	row_number() over ( 
		partition by unique_identifier
		order by updated_at desc
	) as rn 
from flights
), 
last_register_flights as(
select 
	*
from last_register
where rn =1 21
), 
delay_analisis as (
select 
	lrf.departure_airport,
	lrf.delay_mins,
	aip.country
from last_register_flights as lrf
left join airports as aip 
on lrf.departure_airport = aip.airport_code
)
select 
	country,
	round(avg(delay_mins),2) as avg_delay_mins
from delay_analisis
group by 1;

--2.-
with last_register as (
select 
	*,
	row_number() over ( 
		partition by unique_identifier
		order by updated_at desc
	) as rn 
from flights
), 
last_register_flights as(
select 
	*
from last_register
where rn =1
), 
status_per_country as (

select 
	aip.country,
	lrg.arrival_status,
	count(lrg.arrival_status) as total
	
from last_register_flights as lrg
left join airports as  aip 
on lrg.departure_airport = aip.airport_code
group by 1,2
)

select 
	*
from status_per_country;
/*

Enunciado 9. 
El estado de vuelo por país y por época del año. Dado que no en todas las épocas del año 
las condiciones climatólogicas son iguales, analiza si la estaciones del año impactan en el 
delay medio por país. Considera la siguiente clasificación de meses del año por época: 
● Invierno: diciembre, enero, febrero 
● Primavera: marzo, abril, mayo 
● Verano: junio, julio, agosto 
● Otoño: septiembre, octubre, noviembre

*/ 

with last_register as (
select 
	*,
	row_number() over ( 
		partition by unique_identifier
		order by updated_at desc
	) as rn,
	case 
		when local_departure is null then created_at
		else local_departure
	end as effective_local_departure
from flights
), 
last_register_flights as(
select 
	*,
	case 
        when extract(month from effective_local_departure) = any(array[12,1,2]) then 'Winter'
        when extract(month from effective_local_departure) = any(array[3,4,5]) then 'Spring'
        when extract(month from  effective_local_departure) = any(array[6,7,8]) then 'Summer'
        else 'Autumn'
    end as season
from last_register
where rn =1 
and delay_mins is not null
), 
delay_analysis as (

select 
	aip.country,
	lrg.season,
	round(avg(delay_mins),2) as avg_delays
	
from last_register_flights as lrg
left join airports as  aip 
on lrg.departure_airport = aip.airport_code
group by 1,2
)
select 
	season,
	avg_delays
from delay_analysis;

/* 
En cuanto a los resultados la unica estación que podriamos ver que impacta en cuanto a los delays
seria otoño ya que es la que mas delays tiene en general y la que tiene los valores mas altos de delay
de promedio. De resto varian bastante siendo lo esperado que verano y primavera fueron los meses con menos delays
pero los resultados nos muestran que verano sería la segunda con más delay, detras de otoño por lo que no 
lo vería como un buen indicador.

---------------------------------------------------

Enunciado 10. 
Frecuencia de actualización de los vuelos. Volviendo al análisis de la calidad del dataset, 
explora con qué frecuencia se registran actualizaciones de cada vuelo y calcula la 
frecuencia media de actualización por aeropuerto de salida.
*/ 

with frecuency_data as (
select 
	unique_identifier,
	departure_airport,
	updated_at - lag(updated_at)  over (
		partition by unique_identifier
		order by updated_at
		) as updating_frecuency,
	updated_at
from flights
where updated_at is not null
)
select 
	departure_airport,
	round(avg(extract(hour from updating_frecuency)),2) as avg_frecuency
from frecuency_data
group by departure_airport
;
/* El updating_frecuency en todos son 6 horas
-----------------------------------------------------------------------


Consistencia del dato. El campo unique_identifier identifica el vuelo y se construye con: 
aerolínea, número de vuelo, fecha y aeropuertos. Para cada vuelo (último snapshot), 
comprueba si la información del unique_identifier es consistente con las columnas del 
dataset. 
1. Crea un flag is_consistent. 
2. Calcula cuántos vuelos no son consistentes. 
3. Usando la tabla airlines, muestra el nombre de la aerolínea y cuántos vuelos no 
consistentes tiene.
*/

with last_register as (
select 
	*,
		case 
		when local_departure is null then created_at
		else local_departure
	end as effective_local_departure,
	row_number() over ( 
		partition by unique_identifier
		order by updated_at desc
	) as rn 
from flights
), consistency_analysis as (
select 
	unique_identifier,
	airline_code,
	effective_local_departure,
	departure_airport,
	arrival_airport,
	case 
	when split_part(unique_identifier,'-',1) = airline_code
	and split_part(unique_identifier,'-',3) = to_char(effective_local_departure, 'YYYYMMDD')
	and split_part(unique_identifier,'-',4) = departure_airport
	and split_part(unique_identifier,'-',5) = arrival_airport then True 
	else False 
	end as is_consistent
from last_register
where rn = 1
)
select 
	aln.airline_code,
	aln.name,
	cta.is_consistent,
	count(unique_identifier) as total
from consistency_analysis as cta 
left join airlines as aln 
on cta.airline_code = aln.airline_code
group by 1,2,3 ;

with info_cleaned as (
select 
	*,
	row_number() over ( 
		partition by unique_identifier
		order by updated_at desc
	) as rn 
from flights
where airline_code = 'IB' 
), info_iberia as (
select 
	unique_identifier,
	airline_code,
	local_departure,
	departure_airport,
	arrival_airport
from info_cleaned
where rn = 1
)
select 
	*
from info_iberia;



/* 
Hay un total de 251 vuelos consistentes y unos 15 no consistentes. Estos 15 vuelos pertenecen todos a 
una misma aerolinea, 'Iberia'. En ellos hay fallos en cada una de las 4 particiones, hay vuelos con uno
de los aeropuertos erroneos, otros tiene mal el 'airline_code' y existen vuelos con la fecha equivocada, por tanto
es dificl encontrar un patron que nos pueda indicar a que se deben los fallos en los identidicadores, pero todos
vienen de iberia
*/

	
	



