SELECT * FROM Project..[CovidDeaths - Copy]
ORDER BY 3, 4;

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract corona in your country
SELECT 
  location, 
  TRY_PARSE(date AS DATE USING 'en-GB') AS date,
  total_cases, 
  total_deaths,
  (CAST(NULLIF(total_deaths, '') AS FLOAT) / NULLIF(CAST(NULLIF(total_cases, '') AS FLOAT), 0)) * 100 AS death_percentage
FROM Project..[CovidDeaths - Copy]
WHERE location LIKE '%states%'
ORDER BY TRY_PARSE(date AS DATE USING 'en-GB');


-- Looking at Total Cases vs Population
-- Shows what percentage of population contracted covid
SELECT 
  location, 
  TRY_PARSE(date AS DATE USING 'en-GB') AS date,
  total_cases, 
  population,
  (NULLIF(CAST(NULLIF(total_cases, '') AS FLOAT), 0) / NULLIF(CAST(population AS FLOAT), 0)) * 100 AS contract_rate
FROM Project..[CovidDeaths - Copy]
WHERE location LIKE '%states%'
ORDER BY TRY_PARSE(date AS DATE USING 'en-GB');

-- Looking at Countries with highes infection rate compared to population
SELECT 
    location,
    MAX(CAST(total_cases AS FLOAT)) AS HighestInfectionCount,
    CAST(population AS FLOAT) AS population,
    MAX(CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100 AS PercentPopulationInfected
FROM 
    Project..[CovidDeaths - Copy]
GROUP BY 
    location, CAST(population AS FLOAT)
ORDER BY
   PercentPopulationInfected DESC;

SELECT 
    location,
    CAST(population AS FLOAT) AS population,
    TRY_PARSE(date AS DATE USING 'en-GB'),
    MAX(CAST(total_cases AS FLOAT)) AS HighestInfectionCount,
    MAX(CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100 AS PercentPopulationInfected
FROM 
    Project..[CovidDeaths - Copy]
GROUP BY 
    location, CAST(population AS FLOAT), TRY_PARSE(date AS DATE USING 'en-GB')
ORDER BY
   PercentPopulationInfected DESC;

-- Showing Countries with Highest Death Count per Population
SELECT
   location,
   SUM(CAST(new_deaths AS FLOAT)) as TotalDeathCount
FROM Project..[CovidDeaths - Copy]
WHERE continent = ''
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Showing continents with the highest death count per population
SELECT
   continent,
   MAX(CAST(total_deaths AS FLOAT)) as TotalDeathCount
FROM Project..[CovidDeaths - Copy]
WHERE continent != ''
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Correct values
SELECT
   location,
   MAX(CAST(total_deaths AS FLOAT)) as TotalDeathCount
FROM Project..[CovidDeaths - Copy]
WHERE continent = ''
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Global numbers
WITH ParsedData AS (
  SELECT 
    TRY_PARSE(date AS DATE USING 'en-GB') AS parsed_date,
    CAST(new_cases AS FLOAT) AS new_cases,
    CAST(new_deaths AS FLOAT) AS new_deaths,
    continent
  FROM Project..[CovidDeaths - Copy]
  WHERE continent IS NOT NULL AND continent != ''
)
SELECT 
  parsed_date,
  SUM(new_cases) AS total_cases,
  SUM(new_deaths) AS total_deaths,
  (SUM(new_deaths) / NULLIF(SUM(new_cases), 0)) * 100 AS death_percentage
FROM ParsedData
GROUP BY parsed_date
ORDER BY parsed_date;

SELECT 
  SUM(CAST(new_cases AS FLOAT)) AS total_cases,
  SUM(CAST(new_deaths AS FLOAT)) AS total_deaths,
  (SUM(CAST(NULLIF(new_deaths, '') AS FLOAT)) / SUM(NULLIF(CAST(NULLIF(new_cases, '') AS FLOAT), 0))) * 100 AS death_percentage
FROM Project..[CovidDeaths - Copy]
-- WHERE location LIKE '%states%'
WHERE continent != '';

SELECT * FROM Project..[CovidVaccinations - Copy];

-- Looking at Total Population vs Vaccinations CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, running_vaccinations)
AS
(
SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS INT)) 
    OVER (PARTITION BY dea.location ORDER BY dea.location, TRY_PARSE(dea.date AS DATE USING 'en-GB')) 
    AS running_vaccinations
FROM Project..[CovidDeaths - Copy] dea
JOIN Project..[CovidVaccinations - Copy] vac 
  ON dea.location = vac.location 
  AND dea.date = vac.date
WHERE dea.continent != ''
--ORDER BY dea.location, TRY_PARSE(dea.date AS DATE USING 'en-GB');
)
SELECT *, (running_vaccinations / NULLIF(CAST(population AS FLOAT), 0)) * 100
FROM PopvsVac;

-- Alternative: temp table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent varchar(50),
location varchar(50),
date varchar(50),
population varchar(50),
new_vaccinations varchar(50),
running_vaccinations int
)

INSERT INTO #PercentPopulationVaccinated
SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS INT)) 
    OVER (PARTITION BY dea.location ORDER BY dea.location, TRY_PARSE(dea.date AS DATE USING 'en-GB')) 
    AS running_vaccinations
FROM Project..[CovidDeaths - Copy] dea
JOIN Project..[CovidVaccinations - Copy] vac 
  ON dea.location = vac.location 
  AND dea.date = vac.date
--WHERE dea.continent != ''
--ORDER BY dea.location, TRY_PARSE(dea.date AS DATE USING 'en-GB');

SELECT *, (running_vaccinations / NULLIF(CAST(population AS FLOAT), 0)) * 100
FROM #PercentPopulationVaccinated;

-- Create View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS INT)) 
    OVER (PARTITION BY dea.location ORDER BY dea.location, TRY_PARSE(dea.date AS DATE USING 'en-GB')) 
    AS running_vaccinations
FROM Project..[CovidDeaths - Copy] dea
JOIN Project..[CovidVaccinations - Copy] vac 
  ON dea.location = vac.location 
  AND dea.date = vac.date
WHERE dea.continent != '';


