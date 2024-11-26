
-- # COVID-19 Data Exploration
-- ### Skills Used:
-- - Joins
-- - Common Table Expressions (CTEs)
-- - Temporary Tables
-- - Window Functions
-- - Aggregate Functions
-- - Creating Views
-- - Data Type Conversion

-- ## 1. Exploring the Dataset
-- Retrieve data from the `coviddeaths` table to understand its structure.

SELECT * 
FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY date, location;

-- ## 2. Total Cases and Deaths Analysis
-- Extract key fields for initial exploration.

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- ## 3. Total Cases vs Total Deaths
-- Calculate the likelihood of dying if you contract COVID-19 in a specific country.

SELECT location, date, total_cases, total_deaths, 
       (total_deaths / total_cases) * 100 AS DeathPercentage
FROM coviddeaths
WHERE location LIKE '%Pakistan%' AND continent IS NOT NULL
ORDER BY location, date;

-- ## 4. Total Cases vs Population
-- Calculate the percentage of the population infected with COVID-19.

SELECT location, date, population, total_cases,  
       (total_cases / population) * 100 AS PercentPopulationInfected
FROM coviddeaths
WHERE location LIKE '%Pakistan%'
ORDER BY location, date;

-- ## 5. Countries with the Highest Infection Rate Compared to Population
-- Identify the countries with the highest infection rate relative to their population.

SELECT location, population, 
       MAX(total_cases) AS HighestInfectionCount,  
       MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM coviddeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- ## 6. Countries with the Highest Death Count per Population
-- Identify the countries with the highest total deaths.

SELECT location, 
       MAX(CAST(total_deaths AS NUMERIC)) AS TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- ## 7. Continent-Level Analysis
-- Showing continents with the highest death count.

SELECT continent, 
       MAX(CAST(total_deaths AS NUMERIC)) AS TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- ## 8. Global Statistics
-- Calculate total cases, deaths, and the global death percentage.

SELECT SUM(new_cases) AS TotalCases, 
       SUM(CAST(new_deaths AS NUMERIC)) AS TotalDeaths, 
       (SUM(CAST(new_deaths AS NUMERIC)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM coviddeaths
WHERE continent IS NOT NULL;

-- ## 9. Total Population vs Vaccinations
-- Calculate the rolling total of vaccinations for each country.

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS DOUBLE PRECISION)) OVER (
           PARTITION BY dea.location ORDER BY dea.date
       ) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations1 vac
    ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

-- ## 10. Using Common Table Expressions (CTEs)
-- Perform calculations using CTEs for readability.

WITH PopvsVac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated) AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CAST(vac.new_vaccinations AS DOUBLE PRECISION)) OVER (
               PARTITION BY dea.location ORDER BY dea.date
           ) AS RollingPeopleVaccinated
    FROM coviddeaths dea
    JOIN covidvaccinations1 vac
        ON dea.location = vac.location AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / population) * 100 AS PercentPopulationVaccinated
FROM PopvsVac;

-- ## 11. Using Temporary Tables
-- Store data in a temporary table for further analysis.

DROP TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATE,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS NUMERIC)) OVER (
           PARTITION BY dea.location ORDER BY dea.date
       ) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations1 vac
    ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, (RollingPeopleVaccinated / population) * 100 AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;

-- ## 12. Creating a View
-- Create a reusable view for rolling vaccination totals.

CREATE OR REPLACE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS NUMERIC)) OVER (
           PARTITION BY dea.location ORDER BY dea.date
       ) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations1 vac
    ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
