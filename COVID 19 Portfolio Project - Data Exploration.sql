--*Covid 19 Data Exploration
--Covid Death
--Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

select * from [Portfolio Project]..CovidDeathsmain order by 3,4
 
-- Select Data that we are going to be starting with

SELECT 
    location, 
    date, 
    total_cases, 
    new_cases, 
    total_deaths, 
    population
FROM 
    [Portfolio Project]..CovidDeathsmain
WHERE 
    continent IS NOT NULL
ORDER BY 
    1, 2;

--looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in my country BANGLADESH

SELECT 
    location, 
    date, 
    total_cases,
    total_deaths,
    (CAST(total_deaths AS float) / NULLIF(CAST(total_cases AS float), 0)) * 100 AS Death_Percentage
FROM 
    [Portfolio Project]..CovidDeathsmain
WHERE 
    location LIKE '%bangladesh%'
    AND continent IS NOT NULL
ORDER BY 
    1, 2;
--looking at Total Cases vs Population
-- Shows what percentage of population infected with Covid based on my country
SELECT 
    location, 
    date, 
    population, 
    total_cases,  
    (CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100 AS Percent_Population_Infected
FROM 
    [Portfolio Project]..CovidDeathsmain
	Where location like '%bangladesh%'
order by 1,2;

-- Countries with Highest Infection Rate compared to Population
-- The data of Bangladesh will also be availbale if I use the where clause.

SELECT 
    location, 
    population, 
    MAX(CAST(total_cases AS FLOAT)) AS Highest_Infection_Count,
    MAX((CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100) AS Percent_Population_Infected
FROM  
    [Portfolio Project]..CovidDeathsmain
--WHERE 
    --location LIKE '%bangladesh%'
GROUP BY 
    location, population
ORDER BY 
    Percent_Population_Infected DESC;

-- Countries with Highest Death Count per Population
--The data of Bangladesh will also be availbale if I use the where clause with adding ADD.

SELECT 
    location, 
    MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM 
    [Portfolio Project]..CovidDeathsmain
WHERE 
    --location LIKE '%bangladesh%' 
    --AND 
	continent IS NOT NULL
GROUP BY 
    location
ORDER BY 
    TotalDeathCount DESC;

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population(Asia)

SELECT 
    continent, 
    MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM 
    [Portfolio Project]..CovidDeathsmain
WHERE 
    continent IS NOT NULL
  --AND location LIKE '%bangladesh%' -- (optional filter if needed later)
GROUP BY 
    continent
ORDER BY 
    Total_Death_Count DESC;

-- GLOBAL NUMBERS

SELECT 
    SUM(CAST(new_cases AS INT)) AS total_cases, 
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    CASE 
        WHEN SUM(CAST(new_cases AS INT)) > 0 
            THEN (SUM(CAST(new_deaths AS FLOAT)) / SUM(CAST(new_cases AS FLOAT))) * 100
        ELSE 0
    END AS Death_Percentage
FROM  
    [Portfolio Project]..CovidDeathsmain
WHERE 
    continent IS NOT NULL;

--*Covid 19 Data Exploration 2nd Part
-- Covid Vaccinations
-- looking at Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS Rolling_People_Vaccinated
    --, (RollingPeopleVaccinated / population) * 100 AS PercentVaccinated -- Uncomment if needed
FROM 
    [Portfolio Project]..CovidDeathsmain dea
JOIN 
    [Portfolio Project]..CovidVaccinationsmain vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
ORDER BY 
    dea.location, 
    dea.date;

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated) AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(BIGINT, vac.new_vaccinations)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS Rolling_People_Vaccinated
    FROM 
        [Portfolio Project]..CovidDeathsmain dea
    JOIN 
        [Portfolio Project]..CovidVaccinationsmain vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL 
        AND CONVERT(BIGINT, vac.new_vaccinations) IS NOT NULL
)
SELECT 
    *,
    CASE 
        WHEN Population > 0 THEN (CAST(Rolling_People_Vaccinated AS FLOAT) / Population) * 100
        ELSE 0
    END AS Percent_Population_Vaccinated
FROM 
    PopvsVac
ORDER BY
    Location,
    Date;

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #Percent_Population_Vaccinated;

CREATE TABLE #Percent_Population_Vaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC(18,0),
    New_vaccinations NUMERIC(18,0),
    RollingPeopleVaccinated BIGINT
);

INSERT INTO #Percent_Population_Vaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    TRY_CONVERT(NUMERIC(18,0), dea.population) AS population,
    TRY_CONVERT(NUMERIC(18,0), vac.new_vaccinations) AS new_vaccinations,
    SUM(TRY_CONVERT(BIGINT, vac.new_vaccinations)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM 
    [Portfolio Project]..CovidDeathsmain dea
JOIN 
    [Portfolio Project]..CovidVaccinationsmain vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    TRY_CONVERT(NUMERIC(18,0), dea.population) IS NOT NULL
    AND TRY_CONVERT(NUMERIC(18,0), vac.new_vaccinations) IS NOT NULL
-- Optional: AND dea.continent IS NOT NULL

-- Now select with percentage calculation:
SELECT 
    *,
    CASE 
        WHEN Population > 0 THEN (CAST(RollingPeopleVaccinated AS FLOAT) / Population) * 100
        ELSE 0
    END AS Percent_Population_Vaccinated
FROM 
    #Percent_Population_Vaccinated
ORDER BY
    Location,
    Date;


-- Creating View to store data for later visualizations

DROP VIEW IF EXISTS Percent_Population_Vaccinated;
GO

CREATE VIEW Percent_Population_Vaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(TRY_CONVERT(BIGINT, vac.new_vaccinations)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS Rolling_People_Vaccinated
FROM 
    [Portfolio Project]..CovidDeathsmain dea
JOIN 
    [Portfolio Project]..CovidVaccinationsmain vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
    AND TRY_CONVERT(BIGINT, vac.new_vaccinations) IS NOT NULL;




