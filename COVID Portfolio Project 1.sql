
Select *
From PortfolioProject..COVID_Deaths$
Where continent is not null 
order by 3,4


--Select *
--From PortfolioProject..COVID_Vaccinations$
--order by 3,4

--Select Data that we are going to be using 

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..COVID_Deaths$
Where continent is not null
order by 1,2


--Looking at the total cases vs total deaths
--Shows the likelihood of dying from COVID in your country 

Select location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
From PortfolioProject..COVID_Deaths$
Where location like 'Lebanon' and continent is not null
order by 1,2


--Looking at the total cases vs the population 
--Shows what percentage of population got COVID 

Select location, date, population, total_cases, (CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100 AS PercentPopulationInfected
From PortfolioProject..COVID_Deaths$
Where location like 'Lebanon'
order by 1,2

--Looking at Countries with Highest Infection Rate compared to Population

Select location, population, MAX(total_cases), MAX((CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0))) * 100 AS PercentPopulationInfected
From PortfolioProject..COVID_Deaths$
--Where location like 'Lebanon'
Group by location, population
order by PercentPopulationInfected desc

--Showing countries with Highest death count per population 

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..COVID_Deaths$
--Where location like 'Lebanon'
Where continent is not null
Group by location
order by TotalDeathCount desc

-- Let's break down ny continent



-- Showing continents with the highest death count per population

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..COVID_Deaths$
--Where location like 'Lebanon'
Where continent is not null
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

Select date, SUM(new_cases) as total_cases, SUM(Cast(new_deaths as int)) as total_deaths, SUM(Cast(new_deaths as int))/NULLIF(SUM(new_cases),0) *100 AS Deathpercentage
From PortfolioProject..COVID_Deaths$
--Where location like 'Lebanon' 
Where continent is not null
Group by date
Order by 1,2

-- To get the total cases

Select SUM(new_cases) as total_cases, SUM(Cast(new_deaths as int)) as total_deaths, SUM(Cast(new_deaths as int))/NULLIF(SUM(new_cases),0) *100 AS Deathpercentage
From PortfolioProject..COVID_Deaths$
--Where location like 'Lebanon' 
Where continent is not null
--Group by date
Order by 1,2

-- Table of the vaccination 

Select *
From PortfolioProject..COVID_Vaccinations$

-- Joining both tables the death and the vaccination

Select *
From PortfolioProject..COVID_Deaths$ death
Join PortfolioProject..COVID_Vaccinations$ vaccination
	On death.location = vaccination.location
	and death.date = vaccination.date

-- Looking at Total Population vs Vaccinations

Select death.continent, death.location, death.date, death.population, vaccination.new_vaccinations
, SUM(Convert(float, vaccination.new_vaccinations)) OVER (Partition by death.location Order by death.location, death.date) as CumulationPeopleVaccinated
From PortfolioProject..COVID_Deaths$ death
Join PortfolioProject..COVID_Vaccinations$ vaccination
	On death.location = vaccination.location
	and death.date = vaccination.date
Where death.continent is not null
Order by 2, 3

-- Use a CTE

With PopvsVac (Continent, location, date, population, new_vaccinations, CumulationPeopleVaccinated)
as
(
Select death.continent, death.location, death.date, death.population, vaccination.new_vaccinations
, SUM(Convert(float, vaccination.new_vaccinations)) OVER (Partition by death.location Order by death.location, death.date) as CumulationPeopleVaccinated
From PortfolioProject..COVID_Deaths$ death
Join PortfolioProject..COVID_Vaccinations$ vaccination
	On death.location = vaccination.location
	and death.date = vaccination.date
Where death.continent is not null
--Order by 2, 3
)
Select *, (CumulationPeopleVaccinated/population)*100
From PopvsVac

-- TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
CumulationPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select death.continent, death.location, death.date, death.population, vaccination.new_vaccinations
, SUM(Convert(float, vaccination.new_vaccinations)) OVER (Partition by death.location Order by death.location, death.date) as CumulationPeopleVaccinated
From PortfolioProject..COVID_Deaths$ death
Join PortfolioProject..COVID_Vaccinations$ vaccination
	On death.location = vaccination.location
	and death.date = vaccination.date
--Where death.continent is not null
--Order by 2, 3

Select *, (CumulationPeopleVaccinated/population)*100
From #PercentPopulationVaccinated

-- Creating view to store data for later visualizations

Create View PercentPopulationVaccinated as
Select death.continent, death.location, death.date, death.population, vaccination.new_vaccinations
, SUM(Convert(float, vaccination.new_vaccinations)) OVER (Partition by death.location Order by death.location, death.date) as CumulationPeopleVaccinated
From PortfolioProject..COVID_Deaths$ death
Join PortfolioProject..COVID_Vaccinations$ vaccination
	On death.location = vaccination.location
	and death.date = vaccination.date
Where death.continent is not null
--Order by 2, 3

Select *
From PercentPopulationVaccinated