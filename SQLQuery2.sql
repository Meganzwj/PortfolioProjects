Select *
From PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4

--Select *
--From PortfolioProject..Covidvaccinations
--order by 3,4

Select Location,date,total_cases,new_cases,total_deaths,population
From PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you get covid in your country
Select Location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%state%'
and continent is not null
order by 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
Select Location,date,total_cases,population,(total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%state%'
Where continent is not null
order by 1,2

--Looking at Countries with Higest Infection Rate compared to Population
Select Location,MAX(total_cases) as HighestInfectionCount,population
,MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%state%'
Where continent is not null
Group by Location,population
order by 4 desc

--Showing Countries with Higest Death Count per Population
Select Location,MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%state%'
Where continent is not null
Group by Location
order by 2 desc

--Showing Continents with Higest Death Count per Population
Select continent,MAX(cast(total_deaths as int)) as TotalDeathCount--or HighestDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%state%'
Where continent is not null
Group by continent
order by 2 desc


--Global Numbers
--Total Cases and Total Deaths per day over the world
Select date,SUM(new_cases) as TotalCaesCount,SUM(cast(new_deaths as int)) as TotalDeathCount
,SUM(cast(new_deaths as int))/SUM(new_cases)*100 as TotalDeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%state%'
where continent is not null
Group by date
order by 1,2

--Total Cases and Total Deaths over the world
Select SUM(new_cases) as TotalCaesCount,SUM(cast(new_deaths as int)) as TotalDeathCount
,SUM(cast(new_deaths as int))/SUM(new_cases)*100 as TotalDeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%state%'
where continent is not null
order by 1,2

--Join 2 tables to look at Total Population vs Vaccinations
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations--you can add distinct to prevent duplicated rows
,SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--use SUM(cast(vac.new_vaccinations as bigint)): since error(Arithmetic overflow error converting expression to data type int.)
--or use SUM(CONVERT(bigint,vac.new_vaccinations))
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..Covidvaccinations vac
	On dea.location=vac.location
	and dea.date=vac.date
--Where location like '%state%'
Where dea.continent is not null
GROUP BY dea.continent, dea.location, dea.date,dea.population,vac.new_vaccinations
--Adding GROUP BY to prevent duplicate rows caused by Join commend
order by 2,3

--USE CTE
--A Common Table Expression, also called as CTE in short form, is a temporary named result set that 
--you can reference within a SELECT, INSERT, UPDATE, or DELETE statement. The CTE can also be used in a View.
With PopvsVac(continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
as
(
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..Covidvaccinations vac
	On dea.location=vac.location
	and dea.date=vac.date
--Where location like '%state%'
Where dea.continent is not null
GROUP BY dea.location,dea.date,dea.continent,dea.population,vac.new_vaccinations
--order by 1,2
)
Select *, (RollingPeopleVaccinated/population)*100 as TotalVaccinationRate
From PopvsVac

--TEMP TABLE
--A temporary table in SQL Server, as the name suggests, is a database table that exists temporarily on the database server. 
--A temporary table stores a subset of data from a normal table for a certain period of time.
Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..Covidvaccinations vac
	On dea.location=vac.location
	and dea.date=vac.date
--Where location like '%state%'
--Where dea.continent is not null
GROUP BY dea.continent, dea.location, dea.date,dea.population,vac.new_vaccinations
--order by 2,3
Select *, (RollingPeopleVaccinated/population)*100 as TotalVaccinationRate
From #PercentPopulationVaccinated

--Createing View to store data for later visualizations
--Creates a virtual table whose contents (columns and rows) are defined by a query. 
--Use this statement to create a view of the data in one or more tables in the database
Create View PercentPopulationVaccinated1 as
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..Covidvaccinations vac
	On dea.location=vac.location
	and dea.date=vac.date
Where dea.continent is not null
--order by 2,3

Select *
From PercentPopulationVaccinated1
--connect tableau with this view
