/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/
--Continent null if for making query give us just countries
Select *
From Deaths$
Where continent is not NULL 
ORDER BY 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Deaths$
WHERE continent is not NULL
ORDER BY 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (cast(total_deaths as float)/CONVERT(float, total_cases))*100 as DeathPercentageDeath
FROM Deaths$	
WHERE location = 'Azerbaijan' and total_cases is not NULL
ORDER BY 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT Location, date, Population, total_cases,  (total_cases/population)*100 as PopulationInfectedPercentage
FROM Deaths$
WHERE location = 'Azerbaijan' and total_cases is not NULL
ORDER BY 1,2


-- Countries with Highest Daily Infection Rate compared to Population
SELECT location, population,  MAX(new_cases) as HighestInfectionCount,  Max((new_cases/population))*100 as DailyPopulationInfectedPercentage
FROM Deaths$
--WHERE location like 'Aze%'
WHERE continent is not NULL
GROUP BY Location, Population
ORDER BY HighestInfectionCount desc


--Global Variables
SELECT GETDATE() AS 'Today''s Date and Time',
@@CONNECTIONS AS 'Login Attempts'


--Worldwide
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM Deaths$
WHERE continent is not null 
--Group By date
ORDER BY 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.Date) as RollingPeopleVaccinated
FROM Deaths$ dea
JOIN Vaccination$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL 
ORDER BY 1, 2

--CTE 
WITH forRolling (location, date, population, new_vac, rolling_vac)
as
(
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.Date) as RollingPeopleVaccinated
FROM Deaths$ dea
JOIN Vaccination$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL 
)

SELECT *, rolling_vac/population*100 as RollinPercentage
FROM forRolling
WHERE rolling_vac is not NULL
--ORDER BY 1, 2


--Temp table
DROP Table if exists #tempone
CREATE TABLE #tempone
(
continent nvarchar(255),
loc nvarchar(255),
date date,
pop float,
rolling int,
total_vaccinated bigint
)

INSERT INTO #tempone
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.Date) as RollingPeopleVaccinated
FROM Deaths$ dea
JOIN Vaccination$ vac
	ON dea.location = vac.location
	and dea.date = vac.date

DROP TABLE if exists #second
CREATE TABLE #second
(
continent nvarchar(255),
loc nvarchar(255),
date date,
pop float,
rolling int,
total_vaccinated bigint,
total_vaccinated_percent float
)

INSERT INTO #second
SELECT *, total_vaccinated/pop*100 as total_vaccinated_percent
FROM #tempone
ORDER BY 2, 3

--Print values when total vaccination percent less than 100% in countries which population was vaccinated
SELECT *
FROM #second
WHERE total_vaccinated is not NULL and continent is not NULL and total_vaccinated_percent < 100
ORDER BY 2, 3


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated
as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM Deaths$ dea
JOIN Vaccination$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
