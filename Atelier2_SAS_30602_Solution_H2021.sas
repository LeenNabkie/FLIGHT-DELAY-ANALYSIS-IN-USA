
*****************************************************************************************************;
*Étape 1: importer les donner et les nettoyer un peu                                                 ;
*****************************************************************************************************;

proc import 
		datafile= "C:\Users\gita\Desktop\HEC_COURS\ZCH21\ATL2021\BD\flights.csv"
        out=flights
		DBMS=CSV
        REPLACE;
		/*DELIMITER=";";*/
		GETNAMES=yes;
RUN;

proc import 
		datafile= "C:\Users\gita\Desktop\HEC_COURS\ZCH21\ATL2021\BD\airports.csv"
        out=airports
		DBMS=CSV
        REPLACE;
		/*DELIMITER=";";*/
		GETNAMES=yes;
RUN;

proc import 
		datafile= "C:\Users\gita\Desktop\HEC_COURS\ZCH21\ATL2021\BD\airlines.csv"
        out=airlines
		DBMS=CSV
        REPLACE;
		/*DELIMITER=";";*/
		GETNAMES=yes;
RUN;




********************************************************************************************************************************************************************************************************************************;
* Avec SAS;
********************************************************************************************************************************************************************************************************************************;

*****************************************************************************************************;
*Enlever les colonnes qui ne sont pas necessaire                                                     ;
*****************************************************************************************************;
proc print data=flights (obs=3);run;

proc print data=airports (obs=3);run;

data flights0_SAS ;
set flights 
(drop= 
FLIGHT_NUMBER 
TAIL_NUMBER 
TAXI_OUT 
WHEELS_OFF 
SCHEDULED_TIME 
ELAPSED_TIME 
AIR_TIME 
DISTANCE 
WHEELS_ON 
TAXI_IN
);
run;



*****************************************************************************************************;
*0.1:Filter les deux aeroports                                                                       ;
*****************************************************************************************************;
proc print data=airports ;where city="Boston" or city="Los Angeles";run;


data flights1_SAS;
set flights0_SAS;
where origin_airport ="BOS" and destination_airport="LAX";
run;

proc freq data=flights1_SAS;
tables month day DAY_OF_WEEK;
run;
*****************************************************************************************************;
*0.2 un peu de Statistique descriptive                                                               ;
*****************************************************************************************************;

proc means data=flights1_SAS mean var n median;
var _numeric_;
run;

proc freq data=flights1_SAS;
table airline airline_delay;
run;
proc freq data=flights1_SAS;
table airline airline*cancellation_reason destination_airport origin_airport  airline_delay airline*airline_delay;
run; 
* Notez, si on met une variable numerique dans proc freq comme "airline_delay", il le trait comme
une variable categoriele;

*****************************************************************************************************;
*0.3: remplacer les NA                                                                               ;
*****************************************************************************************************;


data flights1_SAS  ;set flights1_SAS;
if WEATHER_DELAY=. then WEATHER_DELAY_2=0; 
else WEATHER_DELAY_2=WEATHER_DELAY;
run;


data flights1_SAS (drop=WEATHER_DELAY );set flights1_SAS;run;

data flights1_SAS (rename=(WEATHER_DELAY_2=WEATHER_DELAY));set flights1_SAS;run;


* solution plus rapide;

data flights1_SAS (drop=WEATHER_DELAY rename=(WEATHER_DELAY_2=WEATHER_DELAY) );set flights1_SAS;
if WEATHER_DELAY=. then WEATHER_DELAY_2=0; 
else WEATHER_DELAY_2=WEATHER_DELAY;
run;

proc freq data=flights1_SAS;

tables WEATHER_DELAY; run;

*****************************************************************************************************;
*Q1:Quel jour de semaine on a plus et moins de délais de départ? Est-ce que c'est raisonnable cette  *
*question? Pour quoi?                                                                                *
*Q1.1:Creer un colonne pour les noms de jours                                                        *
*****************************************************************************************************;
data flights1_SAS;
	set flights1_SAS;
	if  DAY_OF_WEEK = 1 then Day_NAME="Sunday        ";
	else if DAY_OF_WEEK = 2 then Day_NAME="Monday";
	else if DAY_OF_WEEK = 3 then Day_NAME="Tuesday";
	else if DAY_OF_WEEK = 4 then Day_NAME="Wednesday";
	else if DAY_OF_WEEK = 5 then Day_NAME="Thursday";
	else if DAY_OF_WEEK = 6 then Day_NAME="Friday";
	else  Day_NAME="Saterday";
run;

*****************************************************************************************************;
*Q1.2. aggreger les donnees                                                                          ;
*****************************************************************************************************;
proc sort data=flights1_SAS ; by Day_NAME;run;
proc means data=flights1_SAS sum;
var departure_delay;
by Day_NAME;
run;

* d'autre option plus belle comme sortie;
proc sort data=flights1_SAS ; by Day_NAME;run;
proc means data=flights1_SAS sum;
var departure_delay;
class Day_NAME;
run;
* le pire jour est le samedi et meilleur jour est le vendredi, 
  mais somme de retard n'est pas uu bon facon de repondre à cette question;



* la reponse c'est la meme chose, le pire jour est le samedi et meilleur jour est le vendredi, 


*****************************************************************************************************;
*Q 2. Quel mois on a moins et plus d'annulations en moyenne:                                         * 
*on veut que votre table soit permanent                                                              *
*****************************************************************************************************;


libname Atelier2 "C:\Users\gita\Desktop\HEC_COURS\ZCH21\ATL2021\BD";


proc sort data=flights1_SAS ; by MONTH ;run;
proc freq data=flights1_SAS; tables cancelled; run;

proc means data=flights1_SAS mean ;
output out=Atelier2.AVG_Cancelation_SAS ;
var cancelled ;
by MONTH;
run; 

proc means data=flights1_SAS mean ;
output out=Atelier2.AVG_Cancelation_SAS ;
var cancelled ;
class MONTH;
run; 
*cancelled=1 par mois;
proc means data=flights1_SAS mean ;
var cancelled ;
class MONTH;
where cancelled=1;
run; 

proc means data=flights1_SAS mean;var cancelled;run;
proc freq data=flights1_SAS;table month;run;

*En Mai on a moins et au mois de Février on a plus d'annulations en moyenne;
********************************************************************************************************;
*Q 3.Quel est le meilleur et le pir compagnie aérienne en fonction d'annulation et en fonction de delais*
********************************************************************************************************;

/*Proc datasets lib=work;delete airlines;run;*/


proc print data=airlines (obs=1);run;


/*Attention à ne pas oublier de trier les données*/

proc sort data=flights1_SAS; by airline; run;
proc sort data=airlines; by iata_code; run;




data flights2_SAS;

merge flights1_SAS(rename=(airline=IATA_CODE))  airlines ;
by IATA_CODE;

run;


data flights2_SAS;
set flights2_SAS;
where year <> .;
Run;

********************************************************************************************************;
*Q 3.2. aggreger les donnees                                                                            *
********************************************************************************************************;

proc sort data=flights2_SAS; by airline;run;

proc means data= flights2_SAS mean nway;
var cancelled;
class airline;
run;


proc means data= flights2_SAS mean /*nway*/;
var cancelled;
class airline Day_NAME;
run;

* facultative;


proc means data= flights2_SAS mean;
var cancelled;
class IATA_CODE ;
run;

proc freq data=flights2_SAS; 
tables IATA_CODE;
run;


* Reponse: le meilleur est "Delta Air Lines Inc." et le pir est "Virgin America" en fonction d'annulation; 



********************************************************************************************************;
*Q 4:Quel est la raison d'annulation plus fréquent                                                      *
********************************************************************************************************;

 
proc freq data=flights2_SAS;
table cancellation_reason;
run;


********************************************************************************************************;
*Q 5:Présentez graphiquement le délai moyen au départ en fonction du mois                               *
********************************************************************************************************;
              
proc format;
value MonthName   
	1 = "January"
	2="February"
	3="March"
	4="April"
	5="May"
	6="Jun"
	7="July"
	8="Augest"
	9="September"
	10="October"
	11="November"
	12="December";
RUN;

DATA flights2_SAS;
SET flights2_SAS;
FORMAT month MonthName.;
RUN;
* NOTE: utilisation de "proc format" est facultative;


proc sort data=flights2_SAS;by month;run;

proc boxplot data=flights2_SAS;
	plot (departure_delay)*month/cboxes=crimson cboxfill=aquamarine haxis=axis1 vaxis=axis2  ;
	where departure_delay <30;
	title "Délai de Départ en fonction de Mois";
	axis1 label = ( 'Mois')minor = none; 
	axis2 label = ('Délai de Départ')minor = none; 
run;



********************************************************************************************************;
*Q 6:Créez une colonne de date;                                                                         *
********************************************************************************************************;
 
data flights3_SAS;
set flights2_SAS;
date=mdy(month,day,year);
format date yymmdd10.;
run;



********************************************************************************************************;
*Q 7:Créez un échantillon aléatoire de 100000 du fichier "Flights"                                      *
********************************************************************************************************;
 


proc surveyselect data=Flights
     out=othersamp
     sampsize=100000     ;
   *seed=123;
run;

proc freq data=othersamp;
table CANCELLATION_REASON;run;






********************************************************************************************************************************************************************************************************************************;
* Avec SQL;
********************************************************************************************************************************************************************************************************************************;

*****************************************************************************************************;
*Enlever les colonnes qui ne sont pas necessaire                                                     ;
*****************************************************************************************************;


proc sql;
create table flights0_SQL  as 
select*
from flights 
(drop= 
FLIGHT_NUMBER 
TAIL_NUMBER 
TAXI_OUT 
WHEELS_OFF 
SCHEDULED_TIME 
ELAPSED_TIME 
AIR_TIME 
DISTANCE 
WHEELS_ON TAXI_IN
);
quit;



*****************************************************************************************************;
*0.1: Filter les deux aeroports                                                                      ;
*****************************************************************************************************;

proc sql;
create table flights1_SQL as
select *
from flights0_SQL
where origin_airport ="BOS" and destination_airport="LAX";
quit; 


*****************************************************************************************************;
*0.2. un peu de Statistique descriptive                                                              ;
*****************************************************************************************************;

* Avec SQl: Imposible :( ;



*****************************************************************************************************;
*0.3: remplacer les NA                                                                               ;
*****************************************************************************************************;


proc sql;
create table flights1_SQL as
select *,
case when WEATHER_DELAY ='' then 0 
else WEATHER_DELAY end as WEATHER_DELAY_2
from flights1_SQL;
quit;

proc sql;
create table flights1_SQL (drop=WEATHER_DELAY_2)as
select *, WEATHER_DELAY_2 as WEATHER_DELAY 
from flights1_SQL (drop=WEATHER_DELAY);
quit;


*****************************************************************************************************;
*Q1:Quel jour de semaine on a plus et moins de délais de départ? Est-ce que c'est raisonnable cette  *
*question? Pour quoi?                                                                                *
*Q1.1:Creer un colonne pour les noms de jours                                                        *
*****************************************************************************************************;


proc sql ;
  create table flights1_SQL as
   select *,
		case
 			when DAY_OF_WEEK = 1 then "Sunday   "
			when DAY_OF_WEEK = 2 then "Monday   "
			when DAY_OF_WEEK = 3 then "Tuesday"
			when DAY_OF_WEEK = 4 then "Wednesday"
			when DAY_OF_WEEK = 5 then "Thursday"
			when DAY_OF_WEEK = 6 then "Friday"
			else  "Saterday"
		end as Day_NAME
   from flights1_SQL;
quit;


*****************************************************************************************************;
*Q1.2. aggreger les donnees                                                                          ;
*****************************************************************************************************;
proc sql;
	select 
			day_name, 
			sum(departure_delay)as Total_departure_Delay, 
			AVG(departure_delay) as Average_departure_Delay
	from flights1_SQL
	group by Day_NAME
	order by 
			Total_departure_Delay,
			Average_departure_Delay;
quit;

*****************************************************************************************************;
*Q 2. Quel mois on a moins et plus d'annulations en moyenne:                                         * 
*on veut que votre table soit permanent                                                              *
*****************************************************************************************************;

proc sql;
	create table Atelier2.AVG_Cancelation_SQL as
	select 
			MONTH,  
			AVG(cancelled) as Average_Cancelation
	from flights1_SQL
	group by Month
	order by 
			Average_Cancelation;
quit;



********************************************************************************************************;
*Q 3.Quel est le meilleur et le pir compagnie aérienne en fonction d'annulation et en fonction de delais*
********************************************************************************************************;
proc sql;
	create table flights2_SQL as
		select A.* ,B.IATA_Code, B.Airline as Airline_Name
		from flights1_SQL as A
		left join airlines as B
			on A.airline=B.Iata_Code;
Quit; 


********************************************************************************************************;
*Q 3.2. aggreger les donnees                                                                            *
********************************************************************************************************;


proc sql;
	select airline_Name, avg(cancelled) as average_cancelation
	from flights2_SQL
	group by airline_Name
	order by average_cancelation;
quit;


********************************************************************************************************;
*Q 4:Quel est la raison d'annulation plus fréquent                                                      *
********************************************************************************************************;


proc sql;
 select 
		cancellation_reason,
		count(year) as Frequency,
		(count(year)/(select count(year) from df2_SQl where cancellation_reason in ("A","B","C")))*100 as Percent
 from  flights2_SQL
 
 group by cancellation_reason
 having cancellation_reason in ("A","B","C");
quit;



********************************************************************************************************;
*Q 5:Présentez graphiquement le délai moyen au départ en fonction du mois                               *
********************************************************************************************************;

* pas possible :(   ;


********************************************************************************************************;
*Q 6:Créez une colonne de date;                                                                         *
********************************************************************************************************;

proc sql;
	create table flights3_SQL as
		select  * , mdy(month,day,year) format ddmmyy8. as date
		from flights2_SQL;
quit;
