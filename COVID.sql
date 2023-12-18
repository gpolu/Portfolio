SELECT * 
FROM PortfolioProject..CovidDeaths
order by 3,4

SELECT * 
FROM PortfolioProject..CovidVaccincations
order by 3,4

-- Select data we will be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
order by 1,2

-- Look at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in the US
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
SELECT location, date, total_cases, population, (total_cases/population)*100 as CovidPercentage
FROM PortfolioProject..CovidDeaths
order by 1,2

-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
Group by location, population
order by PercentPopulationInfected DESC

-- Showing Countries with Highest Death Count per Population
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
Group by location
order by TotalDeathCount DESC


-- Comparing Death Count by Continent
-- Showing continents with highest death count per population
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
Group by continent
order by TotalDeathCount DESC


-- Global numbers
SELECT date,
SUM(new_cases) AS total_cases,
SUM(cast(new_deaths as int)) AS total_deaths,
CASE WHEN SUM(new_cases) = 0 THEN 0 ELSE SUM(CAST(new_deaths AS INT)) / SUM(new_cases) END * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
order by 1,2


-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, SUM(convert(bigint, vac.new_vaccinations))
OVER (Partition by dea.location ORDER by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccincations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 1,2

-- Use CTE
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as 
(
    SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, SUM(convert(bigint, vac.new_vaccinations))
OVER (Partition by dea.location ORDER by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccincations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent is not NULL
--ORDER BY 1,2
)
Select *, (convert(float,RollingPeopleVaccinated)/Population) * 100
FROM PopvsVac 


-- Temp Table
DROP TABLE if EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    new_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, SUM(convert(bigint, vac.new_vaccinations))
OVER (Partition by dea.location ORDER by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccincations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 1,2

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated



-- Creating Vew to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, SUM(convert(bigint, vac.new_vaccinations))
OVER (Partition by dea.location ORDER by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccincations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent is not NULL

