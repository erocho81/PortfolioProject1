--I have been altering the data type for some of the fields. However this will also be done in a different way later.

ALTER TABLE PortfolioProject..Covid_Deaths 
	ALTER COLUMN population decimal
ALTER TABLE PortfolioProject..Covid_Deaths 
	ALTER COLUMN total_cases decimal
ALTER TABLE PortfolioProject..Covid_Deaths 
	ALTER COLUMN new_cases decimal
ALTER TABLE PortfolioProject..Covid_Deaths 
	ALTER COLUMN total_deaths decimal
ALTER TABLE PortfolioProject..Covid_Deaths 
	ALTER COLUMN new_deaths decimal
GO  

-- My default language is Spanish so...:

SET LANGUAGE ENGLISH

-- First try to check if all data from this table is ok:

SELECT *
FROM PortfolioProject..Covid_Deaths
ORDER BY 3,4


---Select data we are going to be using:

SELECT
	Location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM PortfolioProject..Covid_Deaths
ORDER BY 1,2



--Total Cases Vs Total Deaths:


SELECT
	Location, 
	date, 
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..Covid_Deaths
WHERE LOCATION = 'Spain' 
--or Location like '%States%'
ORDER BY 1,2


--Total Cases Vs Population 
--Shows Percentaje of Pop with Covid

SELECT
	Location, 
	date, 
	Population, 
	total_cases,
	(total_cases/Population)*100 as InfectedPercentage
FROM PortfolioProject..Covid_Deaths
WHERE LOCATION = 'Spain' 
--or Location like '%States%'
ORDER BY 1,2


--Countries higher infection rate
--Changed the original code from the tutorial for the Max selection with Isnull to avoid a 0 division error I was finding:

SELECT 
	Location,
	date, 
	Population,
	total_cases, 
	total_deaths
FROM PortfolioProject..Covid_Deaths
ORDER BY 1,2


SELECT
	Location, 
	Population, 
	MAX(total_cases) as HighestInfectionCount, 
	MAX(ISNULL(total_cases/nullif (population,0),0))*100 AS PercentPopulationInfected
FROM PortfolioProject..Covid_Deaths
GROUP BY
		Location,
		Population
ORDER BY PercentPopulationInfected DESC


--Countries with highest Death Count per Population

SELECT
	Location, 
	MAX(cast(total_deaths AS Int)) AS TotalDeathCount
FROM PortfolioProject..Covid_Deaths
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount DESC



-- Checking info by continent and removing income "Location" fields. Using "Where continent is null".
-- I also removed "Income" locations. This didn't seem to appear in the tutorial either:

SELECT
	Location, 
	MAX(CAST(total_deaths AS Int)) AS TotalDeathCount
FROM PortfolioProject..Covid_Deaths
WHERE continent is null
	   and location not like '%income%'
GROUP BY location
ORDER BY TotalDeathCount DESC


--Showing continents higher death count per population. Using "where continent is not null".

SELECT
	continent, 
	MAX(CAST(total_deaths AS Int)) AS TotalDeathCount
FROM PortfolioProject..Covid_Deaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- Global numbers

SELECT
	date, 
	SUM (new_cases) AS total_cases, 
	SUM (CAST(new_deaths AS int)) AS total_deaths,  
	SUM (CAST(new_deaths AS decimal))/SUM (CAST(New_cases AS decimal))*100 AS DeathPercentage
FROM PortfolioProject..Covid_Deaths
WHERE continent is not null
GROUP BY Date
ORDER BY 1,2


--Total global

SELECT 
	SUM (new_cases) AS total_cases, 
	SUM (CAST(new_deaths AS int)) AS total_deaths,  
	SUM (CAST(new_deaths AS decimal))/SUM (CAST(New_cases AS decimal))*100 AS DeathPercentage
FROM PortfolioProject..Covid_Deaths
WHERE continent is not null
ORDER BY 1,2



--Checking Total Pop vs Vaccinations
SELECT
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BigInt)) 
			OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingPeopleVaccinated

FROM PortfolioProject..Covid_Deaths dea
JOIN PortfolioProject..Covid_Vaccinations vac
ON dea.location=vac.location
AND dea.date=vac.date

WHERE dea.continent is not null
ORDER BY 2,3




-- Use CTE
-- Percentage more than 100% seems to be due to extra vaccinations
-- I also included ISNULL & NULL IF code to avoid errors

WITH PopvsVac 
	(Continent,
	 Location, 
	 Date, 
	 Population, 
	 new_Vaccinations, 
	 RollingPeopleVaccinated)
AS
(
SELECT
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	nullif(vac.new_vaccinations,0),
	SUM(CONVERT (Bigint,NULLIF(vac.new_vaccinations,0))) 
			OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingPeopleVaccinated

FROM PortfolioProject..Covid_Deaths dea
JOIN PortfolioProject..Covid_Vaccinations vac
ON dea.location=vac.location
AND dea.date=vac.date

WHERE dea.continent is not null
)

SELECT *, 
	   ISNULL(RollingPeopleVaccinated/NULLIF (Population,0),0)*100 AS Percentage_Of_Vaccinations
FROM PopvsVac
ORDER BY 2,3


-- TEMP TABLE


DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
	(Continent NVARCHAR (255),
	 Location NVARCHAR (255),
	 Date DATETIME,
	 Population NUMERIC,
	 New_vaccinations NUMERIC,
	 RollingPeopleVaccinated NUMERIC)

INSERT INTO #PercentPopulationVaccinated

SELECT
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population,  
	NULLIF(vac.new_vaccinations,0),
	SUM(CONVERT (BIGINT,NULLIF(vac.new_vaccinations,0))) 
				OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingPeopleVaccinated

FROM PortfolioProject..Covid_Deaths dea
JOIN PortfolioProject..Covid_Vaccinations vac
ON dea.location=vac.location
AND dea.date=vac.date

WHERE dea.continent is not null

SELECT *, 
	   ISNULL(RollingPeopleVaccinated/NULLIF (Population,0),0)*100 AS PercentageOfVaccinations
FROM #PercentPopulationVaccinated

ORDER BY 2,3


-- CREATE A VIEW TO STORE DATA FOR VISUALIZATIONS

CREATE VIEW PercentPopulationVaccinated AS
SELECT
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BigInt)) 
			OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingPeopleVaccinated


FROM PortfolioProject..Covid_Deaths dea
JOIN PortfolioProject..Covid_Vaccinations vac
ON dea.location=vac.location
AND dea.date=vac.date

WHERE dea.continent is not null


SELECT * FROM PercentPopulationVaccinated
