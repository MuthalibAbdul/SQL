-- First we will check both the imported data sets
select * 
from PortfolioProjects..CovidDeaths
order by 3,4 

select * 
from PortfolioProjects..CovidVaccinations
order by 3,4

-- now selecting the variables that we need
Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProjects..CovidDeaths
order by 1,2

-- now we will visualize total cases in contrast to total deaths in that country with a calculated death percentage
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProjects..CovidDeaths
order by 1,2

-- if we want to view country specific data, we can add the where funtion before order by
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProjects..CovidDeaths
where location like '%United States%'
order by 1, 2

--now we will look at cases in contrast to the population
select location, date, total_cases, Population, (total_cases/population)*100 as CaseVsPopulationPercentage
from PortfolioProjects..CovidDeaths
order by 1, 2

--Countries with high infection rate as of 2022
select location, population, max(total_cases) as HighestInfectionCount , max(total_cases/population)*100 as HighestInfectPercentage
from PortfolioProjects..CovidDeaths
group by location, population
order by HighestInfectPercentage desc

--Countries with high death rates as of 2022
-- we are using cast function to reach the values as integer
select location, max(cast(total_deaths as int)) as HighestDeathCount
from PortfolioProjects..CovidDeaths
group by location
order by HighestDeathCount desc

-- however, we see unwanted attrbutes like world, high income and continent names
-- this is because the result is including values from variable continent.
-- we will use "not null" function to separate the variables.
select location, max(cast(total_deaths as int)) as HighestDeathCount
from PortfolioProjects..CovidDeaths
where continent is not null
group by location
order by HighestDeathCount desc

-- now breaking the count by continents
select continent, max(cast(total_deaths as int)) as HighestDeathCount
from PortfolioProjects..CovidDeaths
where continent is not null
group by continent
order by HighestDeathCount desc

--now we will look at some global cases
select date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProjects..CovidDeaths
where continent is not null
group by date
order by 1,2
-- this code will give error because we cannot aggrergate variables by only date
-- hence we will use the aggregate function 

-- here we are taking the sum of new cases by date which is inclusive of all the cases around the world
select date, sum(new_cases) as Total_Cases_by_Date
from PortfolioProjects..CovidDeaths
where continent is not null
group by date
order by 1,2

-- Then we try doing the same with new deaths.
--However here we will use cast function because the data type for new deaths is varchar
select date, sum(new_cases) as Total_Cases_by_Date, sum(cast(new_deaths as int)) as Total_Deaths_by_Date
from PortfolioProjects..CovidDeaths
where continent is not null
group by date
order by 1,2

-- Then we look at the deaths Percentages
select date, sum(new_cases) as Total_Cases_by_Date, sum(cast(new_deaths as int)) as Total_Deaths_by_Date, sum(cast(new_deaths as int))/sum(new_cases) * 100 as PercentageDeaths
from PortfolioProjects..CovidDeaths
where continent is not null
group by date
order by 1,2

-- If we remove the date variable, we get the aggregate number of cases
select sum(new_cases) as Total_Cases_by_Date, sum(cast(new_deaths as int)) as Total_Deaths_by_Date, sum(cast(new_deaths as int))/sum(new_cases) * 100 as PercentageDeaths
from PortfolioProjects..CovidDeaths
where continent is not null
order by 1,2

-- Now we will inner join to merge both the data sets deaths and vaccinations and join them by date and location
select *
from PortfolioProjects..CovidDeaths
join PortfolioProjects..CovidVaccinations
on Coviddeaths.location=CovidVaccinations.location
and CovidDeaths.date=CovidVaccinations.date

-- Now lets see how many peple out of total population are vaccinated to date
select CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations
from PortfolioProjects..CovidDeaths
join PortfolioProjects..CovidVaccinations
on Coviddeaths.location=CovidVaccinations.location
and CovidDeaths.date=CovidVaccinations.date
where CovidDeaths.continent is not null
order by 2, 3

--Now we will sum the new vaccination numbers to give us an estimate of our total vaccinated individual ordered by continent, 
--location, date and lastly giving us the rolling vaccination count
select CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations
, sum(convert(int,CovidVaccinations.New_vaccinations )) over (Partition by CovidDeaths.location order by CovidDeaths.Location, CovidDeaths.date) as RollingVaccinationCount
from PortfolioProjects..CovidDeaths
join PortfolioProjects..CovidVaccinations
on Coviddeaths.location=CovidVaccinations.location
and CovidDeaths.date=CovidVaccinations.date
where CovidDeaths.continent is not null
order by 2, 3

--Now we will see total/max vaccination count versus population using CTE
with PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingVaccinationCount)
as
(
Select CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations
, sum(convert(int,CovidVaccinations.New_vaccinations )) over (Partition by CovidDeaths.Location order by CovidDeaths.Location, CovidDeaths.date) as RollingVaccinationCount
from PortfolioProjects..CovidDeaths
join PortfolioProjects..CovidVaccinations
on Coviddeaths.location=CovidVaccinations.location
and CovidDeaths.date=CovidVaccinations.date
where CovidDeaths.continent is not null) 
select *,(RollingVaccinationCount/Population)*100 as VaccinationPercentage
from PopvsVac

--Using Temp Table

drop table if exists #VaccinationPercentage
create table #VaccinationPercentage
(
Continent nvarchar(225),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingVaccinationCount numeric
)

insert into #VaccinationPercentage
select CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations
, sum(convert(int,CovidVaccinations.New_vaccinations )) over (Partition by CovidDeaths.location order by CovidDeaths.Location, CovidDeaths.date) as RollingVaccinationCount
from PortfolioProjects..CovidDeaths
join PortfolioProjects..CovidVaccinations
on Coviddeaths.location=CovidVaccinations.location
and CovidDeaths.date=CovidVaccinations.date
-- where CovidDeaths.continent is not null
-- order by 2, 3
select *,(RollingVaccinationCount/Population)*100
from #VaccinationPercentage

--Create a View
create view VaccinationPercentage
Select CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations
, sum(convert(int,CovidVaccinations.New_vaccinations )) over (Partition by CovidDeaths.location order by CovidDeaths.Location, CovidDeaths.date) as RollingVaccinationCount
from PortfolioProjects..CovidDeaths
join PortfolioProjects..CovidVaccinations
on Coviddeaths.location=CovidVaccinations.location
and CovidDeaths.date=CovidVaccinations.date
where CovidDeaths.continent is not null