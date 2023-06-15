
-- simple syntax to view column names and basic info for CovidDeaths table and CovidVaccinations table
sp_columns 'CovidDeaths';
sp_columns 'CovidVaccinations';

-- syntax to view column names and detailed info related to each column for CovidDeaths Table
select * from sys.tables where name='CovidDeaths';
select * from sys.columns where object_id = 1109578991;


-- syntax to view column names and detailed info related to each column for CovidVaccinations Table
select * from sys.tables where name='CovidVaccinations';
select * from sys.columns where object_id = 1317579732;

-- Exploring both CovidDeaths & CovidVaccinations tables by ordering them by Location & Date 
select * from SQLProj1..CovidDeaths
order by 2,3;

select * from SQLProj1..CovidVaccinations
order by 2,3;

select location, date, total_deaths, total_Cases, population
from SQLProj1..CovidDeaths
order by 1,2

select location, date, total_Cases, new_cases, total_deaths, population
from SQLProj1..CovidDeaths
order by 1,2

-- Part 1
-- Calculating the percentage of deaths vs cases
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Daily_Mortality_Percentage
from SQLProj1..CovidDeaths
where continent is not null
order by 1,2

-- -- Calculating the percentage of total deaths vs total cases in the United States
select location, date, total_deaths, total_cases, (total_deaths/total_cases)*100 as Daily_Mortality_Percentage
from SQLProj1..CovidDeaths
where location = 'United States' and continent is not null
order by 1,2

-- -- Calculating the percentage of total cases vs population overall
select location, date, total_cases, population, (total_cases/population)*100 as Daily_Infection_Rate
from SQLProj1..CovidDeaths
order by 1,2

-- -- Calculating the percentage of total cases vs population in the United States
select location, date, total_cases, population, (total_cases/population)*100 as Daily_Infection_Rate
from SQLProj1..CovidDeaths
where location = 'United States'
order by 1,2

-- Countries with highest infection rate
select location, max(total_cases) as Highest_Infection_Count, population, max(total_cases/population)*100 as Highest_Infection_Rate
from SQLProj1..CovidDeaths
where continent is not null
group by location, population
order by Daily_Infection_Rate desc

-- Countries with highest Death rate
select location, max(cast(total_deaths as int)) as Highest_Death_Count, max((total_deaths/population))*100 as Daily_Death_Rate
from SQLProj1..CovidDeaths
where continent is not null
group by location
order by Daily_Death_Rate desc

-- Cases and Deaths by Continent/location
select continent, 
       max(total_cases) as Highest_Infection_Count, 
	   max((total_cases/population))*100 as Highest_Infection_Rate, 
       max(total_deaths) as Highest_Death_Count, 
	   max((total_deaths/population))*100 as Highest_Death_Rate
from SQLProj1..CovidDeaths
where continent is not null
group by continent
order by Highest_Infection_Count desc, Highest_Death_Count desc

-- Inconsistency with the data that gives us other metrics apart from continents when we use 'location' column instead of 'continent'
-- using 'is not null' instead of 'is null will give us the results of highest/infection rate by countries
select location, 
       max(total_cases) as Highest_Infection_Count, 
	   max((total_cases/population))*100 as Highest_Infection_Rate, 
       max(total_deaths) as Highest_Death_Count, 
	   max((total_deaths/population))*100 as Highest_Death_Rate
from SQLProj1..CovidDeaths
where continent is null
group by location
order by Highest_Infection_Count desc


--Part 2
-- quick overview on the second table 'CovidVaccinations'
select * from
SQLProj1..CovidVaccinations

-- JoinIng both the Deaths and Vaccinations tables
select *
from SQLProj1..CovidDeaths cd join SQLProj1..CovidVaccinations cv
on cd.location=cv.location
and cd.date = cv.date

-- total population vs vaccinations
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
from SQLProj1..CovidDeaths cd join SQLProj1..CovidVaccinations cv
on cd.location=cv.location
and cd.date = cv.date
where cd.continent is not null
order by 1,2

-- rolling count for vaccinations
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
sum(convert(bigint,cv.new_vaccinations)) over (partition by cd.location order by cd.location, cd.date) as Rolling_Vaccination_Count
from SQLProj1..CovidDeaths cd join SQLProj1..CovidVaccinations cv
on cd.location=cv.location
and cd.date = cv.date
where cd.continent is not null
order by 1,2

-- max vaccination per country using CTE
with PopvsVac (Continent, location, date, population, new_vaccinations, Rolling_Vaccination_Count) 
as
(
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
sum(convert(bigint,cv.new_vaccinations)) over (partition by cd.location order by cd.location, cd.date) as Rolling_Vaccination_Count
from SQLProj1..CovidDeaths cd 
join SQLProj1..CovidVaccinations cv
on cd.location=cv.location
and cd.date = cv.date
where cd.continent is not null
)
select *, (Rolling_Vaccination_Count/population)*100 as Vaccination_Percentage
from PopvsVac

-- Creating a View
use SQLProj1
go
create view 
PercentPopulationVaccinated1 as
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
sum(convert(bigint,cv.new_vaccinations)) over (partition by cd.location order by cd.location, cd.date) as Rolling_Vaccination_Count
from SQLProj1..CovidDeaths cd 
join SQLProj1..CovidVaccinations cv
on cd.location=cv.location
and cd.date = cv.date
where cd.continent is not null

--calling the view
select * from
SQLProj1..PercentPopulationVaccinated

-- The End ---