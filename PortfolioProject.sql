SELECT *
FROM PortfoliaProject ..covidDeath
WHERE continent IS NOT Null
ORDER By 3,4

--SELECT *
--FROM PortfoliaProject ..covidVaccination
--ORDER By 3,4

--Select data we are going to be using
Select Location, date, total_cases, new_cases, total_deaths, population
From covidDeath
Where continent is not null 
order by 1,2

UPDATE covidDeath
SET total_cases = ISNULL(total_cases, 0);

UPDATE covidDeath
SET total_deaths = ISNULL(total_deaths, 0);




--Looking at the Total Cases vs Total Deaths
--not working
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)
FROM covidDeath
WHERE continent IS NOT Null
ORDER By 1,2


--this works
SELECT
    location,
    date,
    total_cases,
    total_deaths,
    CASE 
        WHEN TRY_CAST(total_cases AS float) = 0 THEN 0 -- Handle division by zero
        ELSE TRY_CAST(total_deaths AS float) / TRY_CAST(total_cases AS float) *100
    END AS deathPercentage
FROM
    covidDeath
	WHERE continent IS NOT Null
ORDER BY
    1, 2


	SELECT
    location,
    date,
    total_cases,
    total_deaths,
    CASE 
        WHEN TRY_CAST(total_cases AS float) = 0 THEN 0 -- Handle division by zero
        ELSE TRY_CAST(total_deaths AS float) / TRY_CAST(total_cases AS float) *100
    END AS deathPercentage
FROM
    covidDeath
	WHERE location like '%states%' AND continent IS NOT Null
ORDER BY
    1, 2

--Looking at Total Cases vs Population
--Shows % of population that affected by Covid

SELECT
    location,
    date,
    total_cases,
    population,
    CASE 
        WHEN TRY_CAST(total_cases AS float) = 0 THEN 0 -- Handle division by zero
        ELSE TRY_CAST(total_cases AS float) / TRY_CAST(population AS float) *100
    END AS PercentPopulationInfected
FROM
    covidDeath
	WHERE location = 'Latvia' and continent IS NOT Null
ORDER BY
    1, 2

--Looking at Countries with Highest Infection Rate compared to Population

SELECT
    location,
    population,
	MAX(total_cases) as HighestInfectionCount,
    CASE 
        WHEN TRY_CAST(MAX(total_cases) AS float) = 0 THEN 0 
        ELSE MAX(TRY_CAST(total_cases AS float) / TRY_CAST(population AS float) *100)
    END AS PercentPopulationInfected
FROM
    covidDeath
	--WHERE location = 'Latvia'
	GROUP BY population, location
WHERE continent IS NOT Null
ORDER BY
    PercentPopulationInfected DESC

--Looking at Countries with Highest Death Count compared to Population

SELECT
    location,
	MAX(total_deaths) as TotalDeathCount,
    CASE 
        WHEN TRY_CAST(MAX(total_deaths) AS float) = 0 THEN 0 
        ELSE MAX(TRY_CAST(total_deaths AS float) / TRY_CAST(population AS float))
    END AS HighestDeathCount
FROM
    covidDeath
	--WHERE location = 'Latvia'
	WHERE continent IS NOT Null
	GROUP BY location
ORDER BY
    HighestDeathCount DESC

	---not working because location is still messed up---
SELECT
    location,
	MAX(CAST(total_deaths AS float )) as TotalDeathCount
FROM
    covidDeath
	--WHERE location = 'Latvia'
	WHERE continent is not null
	GROUP BY location
ORDER BY
    TotalDeathCount DESC

	---working----
SELECT
    location,
    MAX(CAST(total_deaths AS float)) as TotalDeathCount
FROM
    covidDeath
WHERE
    continent IS NOT NULL
    AND continent <> ''  --  to handle empty strings if necessary
GROUP BY
    location
ORDER BY
    TotalDeathCount DESC;

--let's break down by continent
--Showing continents with the highest death count per population

SELECT
    continent,
    MAX(CAST(total_deaths AS float)) as TotalDeathCount
FROM
    covidDeath
WHERE
    continent IS NOT NULL
    AND continent <> ''  --  to handle empty strings if necessary
GROUP BY
    continent
ORDER BY
    TotalDeathCount DESC;

--global numbers
--not working without 0 division check up
SELECT
    date,
    SUM(TRY_CAST(new_cases AS float)),
	SUM(TRY_CAST(new_deaths AS float)),
	SUM(TRY_CAST(new_deaths AS float))/SUM(TRY_CAST(new_cases AS float)) *100 as DeathPercentage
    --total_deaths,
    --CASE 
    --    WHEN TRY_CAST(total_cases AS float) = 0 THEN 0 -- Handle division by zero
    --    ELSE TRY_CAST(total_deaths AS float) / TRY_CAST(total_cases AS float) *100
    --END AS deathPercentage
FROM
    covidDeath
	WHERE continent IS NOT Null
GROUP BY date
ORDER BY
    1, 2
--this works
SELECT
    --date,
    SUM(TRY_CAST(new_cases AS float)) AS TotalNewCases,
    SUM(TRY_CAST(new_deaths AS float)) AS TotalNewDeaths,
    CASE 
        WHEN SUM(TRY_CAST(new_cases AS float)) = 0 THEN 0
        ELSE (SUM(TRY_CAST(new_deaths AS float)) / SUM(TRY_CAST(new_cases AS float))) * 100
    END AS DeathPercentage
FROM
    covidDeath
WHERE
    continent IS NOT NULL
--GROUP BY
--    date
ORDER BY
    1,2

--Looking at the Total Population vs Total Vaccination
SELECT *
FROM covidDeath dea
JOIN covidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION by dea.location
ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
	--(RollingPeopleVaccinated/CONVERT(float, population) * 100
FROM covidDeath dea
JOIN covidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
	AND dea.continent <> ''
	ORDER BY 2,3

--Using STE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION by dea.location
ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
	--(RollingPeopleVaccinated/CONVERT(float, population) * 100
FROM covidDeath dea
JOIN covidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
	AND dea.continent <> ''
	--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/CONVERT(float, population)) * 100
FROM PopvsVac


--TEMP Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated (
continent nvarchar(255),
location nvarchar(255),
date datetime,
population nvarchar(255),
new_vaccinations nvarchar(255),
RollingPeopleVaccinated nvarchar(255)
)


INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION by dea.location
ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
	--(RollingPeopleVaccinated/CONVERT(float, population) * 100
FROM covidDeath dea
JOIN covidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
	AND dea.continent <> ''
	--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/CONVERT(float, population)) * 100
FROM #PercentPopulationVaccinated

--Selecting view to store data for later visualization

CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION by dea.location
ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
	--(RollingPeopleVaccinated/CONVERT(float, population) * 100
FROM covidDeath dea
JOIN covidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
	AND dea.continent <> ''
	--ORDER BY 2,3

SELECT * from PercentPopulationVaccinated