use portfolio_project ;

--select COUNT(*) as row_count
--from Covid_Deaths ;

--select COUNT(*) as row_count
--from Covid_vaccinations ;

select continent
from Covid_deaths
where continent is not null

select *
from Covid_Deaths
where continent is not null


select continent , location , date , total_cases , new_cases , total_deaths , population
from Covid_Deaths 
where continent is not null;



--looking at total cases vs total deaths

select continent , location , date , total_cases  , total_deaths , (total_deaths/total_cases)*100 as death_percentage
from Covid_Deaths 
where continent is not null;

-- in above query the calculation is not taking place because of null values
--so we should convert them into float

select continent , location , date , total_cases  , total_deaths ,
convert(float,total_deaths)/nullif(convert(float,total_cases),0)*100 
as death_percentage
from Covid_Deaths 
where continent is not null
--where location like '%India%' ;



--looking at total cases vs total population (% of population got covid)

select continent , location , date ,population , total_cases  , 
convert(float,total_cases)/nullif(convert(float,population),0)*100 
as percentPopulationInfected
from Covid_Deaths 
where continent is not null
--where location like '%states%' ;



--countries with highest infection rate compaired to population

select continent , location ,population ,max(total_cases) as HighestInfectionCount, 
max(convert(float,total_cases)/nullif(convert(float,population),0))*100 
as PercentPopulationInfected
from Covid_Deaths 
where continent is not null
--where location like '%states%' ;
group by continent , location ,population
order by PercentPopulationInfected desc    ----perfect till now



--countries with highest death count per population

select continent , location ,sum(cast((total_deaths) as int)) as TotaldeathCount
from Covid_Deaths                       --total deaths column is nvarchar so convert it to int
where continent is not null
--where location like '%states%' ;
group by continent , location 
order by TotaldeathCount desc



--total death count per continent

select continent , sum(cast((total_deaths) as int)) as TotaldeathCount
from Covid_Deaths         
where continent is not null
--where location like '%states%' ;
group by continent 
order by TotaldeathCount desc



--cotinents with highest death count per population

select continent , max(cast((total_deaths) as int)) as TotaldeathCount
from Covid_Deaths                      --total deaths column is nvarchar so convert it to int
where continent is not null
--where location like '%states%' ;
group by continent 
order by TotaldeathCount desc



--golbal no's

select  --date ,
sum(cast(new_cases as int)) as total_cases ,
sum(cast(new_deaths as int)) as total_deaths ,
(sum(cast(new_deaths as int)) / sum(cast(new_cases as int))) * 100 as death_percentage
from Covid_Deaths 
where continent is not null
--group by date
--order by date                       --first we found values for all dates


--lets look the covid_vaccination table

select * 
from Covid_vaccinations


--select *                                       --failed to convert varchar to date 
--from Covid_deaths as cd
--join Covid_vaccinations as cv
--on cd.location = cv.location
--and cd.date = cast(cv.date as date)
--AND cd.continent IS NOT NULL


--SELECT *                                        --failed to convert varchar to date 
--FROM Covid_deaths AS cd
--JOIN Covid_vaccinations AS cv
--ON cd.location = cv.location
--AND cd.date = CONVERT(DATE, cv.date, 120); -- Style 120 for 'YYYY-MM-DD'

--SELECT *                               --try-cast worked but rows are missing
--FROM Covid_deaths AS cd
--JOIN Covid_vaccinations AS cv
--ON cd.location = cv.location
--AND cd.date = TRY_CAST(cv.date AS DATE);

SELECT cv.date
FROM Covid_vaccinations AS cv
WHERE TRY_CAST(cv.date AS DATE) IS NULL;

--SELECT *
--FROM Covid_deaths AS cd
--JOIN Covid_vaccinations AS cv
--ON cd.location = cv.location
--AND cd.date = TRY_CAST(cv.date AS DATE)
--WHERE cv.date IS NOT NULL AND TRY_CAST(cv.date AS DATE) IS NOT NULL;

--total population vs vaccination

SELECT *                                    
FROM Covid_deaths AS cd
JOIN Covid_vaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = TRY_CAST(cv.date AS DATE)
WHERE TRY_CAST(cv.date AS DATE) IS NOT NULL
   OR cv.date IS NULL; -- Includes rows with null or invalid dates

 --lets get the required columns

--select cd.continent , cd.location , cd.population , cast(cv.new_vaccinations as int)                            
--FROM Covid_deaths AS cd
--JOIN Covid_vaccinations AS cv                --new_vaccination is a varchar
--	ON cd.location = cv.location AND                --cast failed to convert into int
--	   cd.date = TRY_CAST(cv.date AS DATE)             
--WHERE (TRY_CAST(cv.date AS DATE) IS NOT NULL OR
--    cv.date IS NULL) and
--	cd.continent is not null;

--SELECT cd.continent,                     ---try cast also failed
--       cd.location, 
--       cd.population, 
--       TRY_CAST(cv.new_vaccinations AS INT) AS new_vaccinations
--FROM Covid_deaths AS cd
--JOIN Covid_vaccinations AS cv
--    ON cd.location = cv.location 
--    AND cd.date = TRY_CAST(cv.date AS DATE)
--WHERE (TRY_CAST(cv.date AS DATE) IS NOT NULL OR cv.date IS NULL)
--  AND cd.continent IS NOT NULL;


ALTER TABLE Covid_vaccinations         --date datatype is string
ADD date1 DATE ;                       --so converting it to date by creating 
                                       --new column just to avoide any data loss
UPDATE Covid_vaccinations
SET date1 = CONVERT(DATE, date, 105);

select date , date1
from Covid_vaccinations

ALTER TABLE Covid_vaccinations
DROP COLUMN date;

EXEC sp_rename 'Covid_vaccinations.Date1', 'Date', 'COLUMN';

--date column was in string format so changed it to date datatype



SELECT cd.continent, 
       cd.location, 
	   cd.date ,
       cd.population, 
	   CONVERT(float,cv.new_vaccinations)  --following is another method
       --ISNULL(TRY_CAST(cv.new_vaccinations AS INT), 0) AS new_vaccinations
FROM Covid_deaths AS cd
JOIN Covid_vaccinations AS cv
    ON cd.location = cv.location 
    AND cd.date = cv.date
--WHERE (TRY_CAST(cv.date AS DATE) IS NOT NULL OR cv.date IS NULL)
  AND cd.continent IS NOT NULL
order by 2, 3;


--lets add few more columns

SELECT cd.continent, 
       cd.location, 
	   cd.date ,
       cd.population, 
	   CONVERT(float,cv.new_vaccinations) as new_vaccinations,  --following is another method
       --ISNULL(TRY_CAST(cv.new_vaccinations AS INT), 0) AS new_vaccinations
	   sum(CONVERT(float,cv.new_vaccinations)) over 
	   (partition by cd.location order by cd.location , cd.date) as RollingPeopleVaccinated
FROM Covid_deaths AS cd
JOIN Covid_vaccinations AS cv
    ON cd.location = cv.location 
    AND cd.date = cv.date
--WHERE (TRY_CAST(cv.date AS DATE) IS NOT NULL OR cv.date IS NULL)
  AND cd.continent IS NOT NULL
order by 2, 3;                --perfect till now
                             
--but we need to add a calculated column 
--(RollingPeopleVaccinated/population)*100
--but we cant use the aslias column in anothe column so lets try CTE




--CTE (common table expressions)

with popVsvac  (continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
as(

SELECT cd.continent, 
       cd.location, 
	   cd.date ,
       cd.population, 
	   CONVERT(float,cv.new_vaccinations) as new_vaccinations,  --following is another method
       --ISNULL(TRY_CAST(cv.new_vaccinations AS INT), 0) AS new_vaccinations
	   sum(CONVERT(float,cv.new_vaccinations)) over 
	   (partition by cd.location order by cd.location , cd.date) as RollingPeopleVaccinated
FROM Covid_deaths AS cd
JOIN Covid_vaccinations AS cv
    ON cd.location = cv.location 
    AND cd.date = cv.date
--WHERE (TRY_CAST(cv.date AS DATE) IS NOT NULL OR cv.date IS NULL)
  AND cd.continent IS NOT NULL
--order by 2, 3         as order by clause is not permited in cte
)

select * , (RollingPeopleVaccinated/population)*100 as RollingPeopleVaccinatedPerPopulation
from popVsvac




--creating temp table


drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated (
continent  nvarchar(255),
location  nvarchar(255),
date  datetime,
population  numeric,
new_vaccinations  numeric,
RollingPeopleVaccinated  numeric
)

insert into #PercentPopulationVaccinated

SELECT cd.continent, 
       cd.location, 
	   cd.date ,
       cd.population, 
	   CONVERT(float,cv.new_vaccinations) as new_vaccinations,  --following is another method
       --ISNULL(TRY_CAST(cv.new_vaccinations AS INT), 0) AS new_vaccinations
	   sum(CONVERT(float,cv.new_vaccinations)) over 
	   (partition by cd.location order by cd.location , cd.date) as RollingPeopleVaccinated
FROM Covid_deaths AS cd
JOIN Covid_vaccinations AS cv
    ON cd.location = cv.location 
    AND cd.date = cv.date
--WHERE (TRY_CAST(cv.date AS DATE) IS NOT NULL OR cv.date IS NULL)
  --AND cd.continent IS NOT NULL
--order by 2, 3  

select * , (RollingPeopleVaccinated/population)*100 as RollingPeopleVaccinatedPerPopulation
from #PercentPopulationVaccinated




--creating views to store data for visualisations


create view PercentPopulationVaccinated as

SELECT cd.continent, 
       cd.location, 
	   cd.date ,
       cd.population, 
	   CONVERT(float,cv.new_vaccinations) as new_vaccinations,  --following is another method
       --ISNULL(TRY_CAST(cv.new_vaccinations AS INT), 0) AS new_vaccinations
	   sum(CONVERT(float,cv.new_vaccinations)) over 
	   (partition by cd.location order by cd.location , cd.date) as RollingPeopleVaccinated
FROM Covid_deaths AS cd
JOIN Covid_vaccinations AS cv
    ON cd.location = cv.location 
    AND cd.date = cv.date
--WHERE (TRY_CAST(cv.date AS DATE) IS NOT NULL OR cv.date IS NULL)
  AND cd.continent IS NOT NULL
--order by 2, 3 


select *
from PercentPopulationVaccinated


