SELect *
from ProjectPortfolioCovid..CovidVacctination
order by 3,4

--SELect *
--from ProjectPortfolioCovid..coviddeaths
--order by 3,4

-- select data that we are going to be using 
SELect location, date, total_cases, new_cases, total_deaths, population
from ProjectPortfolioCovid..coviddeaths
order by 1,2

-- Looking at Total cases vs Total deaths (How many cases are there in this country 
-- and how many deaths do they have for the entire cases )

SELect location, date, total_cases, total_deaths, total_deaths/total_cases
from ProjectPortfolioCovid..coviddeaths
order by 1,2

-- because we get error massages 'Operand data type nvarchar is invalid for divided"
-- we must change datatype column 'total_case' and 'total_deaths' to numeric data type category except the 
-- date time and smalldatetime data types
Alter table projectportfoliocovid..Coviddeaths
alter column total_cases float

Alter table projectportfoliocovid..Coviddeaths
alter column total_deaths float

-- Looking the Data type of columns 
select table_catalog, Table_schema,
column_name,data_type 
from INFORMATION_SCHEMA.COLUMNS 
where  TABLE_NAME = 'CovidDeaths'

-- then looking at total cases vs total deaths 
-- shows likelihood of dying if you contact covid in your country 
SELect location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from ProjectPortfolioCovid..coviddeaths
where location like '%state%'
order by 1,2

-- Looking at Total cases vs Population 
-- Shows what percentage of population got covid 

SELect location, date,  Population, total_cases, (total_cases/population)*100 as PercentageofPopulationInfected
from ProjectPortfolioCovid..coviddeaths
--where location like '%state%'
order by 1,2

-- Looking at countries with highest infection rate compared to population 

SELect location,  Population, Max(total_cases) as HighestInfectionCountry, Max ((total_cases/population))*100 as 
PercentageofPopulationInfected
from ProjectPortfolioCovid..coviddeaths
--where location like '%state%'
where continent is not null
Group by Location, Population
order by PercentageofPopulationInfected desc

-- Showing Countries with highest Death Count per Population
SELect location, Max(total_deaths) as TotalDeathCount
from ProjectPortfolioCovid..coviddeaths
--where location like '%state%'
where continent is not null
Group by Location
order by TotalDeathCount desc

-- Delete unique data like World, High Income and Upper middle income 
-- in column Location 

delete from ProjectPortfolioCovid..CovidDeaths
where location in ('World','High income','Upper middle income' )

-- Showing Countries with highest Death Count per Population
SELect location, Max(total_deaths) as TotalDeathCount
from ProjectPortfolioCovid..coviddeaths
--where location like '%state%'
where continent is not null
Group by Location
order by TotalDeathCount desc


-- LET'S BREAK THINGS DOWN CONTINENT



-- Showing continents with the highest death count per population 

SELect continent, Max(total_deaths) as TotalDeathCount
from ProjectPortfolioCovid..coviddeaths
--where location like '%state%'
where continent is not null
Group by Continent
order by TotalDeathCount desc

--GLOBAL NUMBERS

SELect  date, Sum (new_cases), total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from ProjectPortfolioCovid..coviddeaths
--where location like '%state%'
where continent is not null 
group by date
order by 1,2

SELect   Sum (new_cases) as Total_cases, sum(new_deaths) as total_deaths, 
(sum(cast(new_deaths as int))/nullif (sum(new_cases),0))*100 
as DeathPercentage --	NULLIF dipakai karena error"Divide by zero error encountered"
from ProjectPortfolioCovid..coviddeaths
--where location like '%state%'
where new_cases is not null 
--group by date
order by 1,2

-- Looking at Total Population vs Vaccination 


select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert (float,vac.new_vaccinations)) over (partition by dea.Location Order by dea.Location,
dea.Date) as RollingPeopleVaccinated 
--, (RollingPeopleVaccinated/population)*100
from ProjectPortfolioCovid..CovidDeaths dea
Join ProjectPortfolioCovid..CovidVacctination vac
on dea.Location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USING CTE 

with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert (float,vac.new_vaccinations)) over (partition by dea.Location Order by dea.Location,
dea.Date) as RollingPeopleVaccinated 
--, (RollingPeopleVaccinated/population)*100
from ProjectPortfolioCovid..CovidDeaths dea
Join ProjectPortfolioCovid..CovidVacctination vac
on dea.Location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

--TEMP TABLE 

DROP Table if Exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccination numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert (float,vac.new_vaccinations)) over (partition by dea.Location Order by dea.Location,
dea.Date) as RollingPeopleVaccinated 
--, (RollingPeopleVaccinated/population)*100
from ProjectPortfolioCovid..CovidDeaths dea
Join ProjectPortfolioCovid..CovidVacctination vac
on dea.Location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

select*
from #PercentPopulationVaccinated

-- USE CTE deleting Duplicated row 

With cte (continent, Location, Date, Population, new_vaccination, RollingPeopleVaccinated
, DuplicateCount )
as
(
Select continent, Location, Date, Population, new_vaccination, RollingPeopleVaccinated
, ROW_NUMBER() over(Partition by 
continent, Location, Date, Population, new_vaccination, RollingPeopleVaccinated 
order by Date) as DuplicateCount
from #PercentPopulationVaccinated)

Delete from cte 
where DuplicateCount>1

select*
from #PercentPopulationVaccinated


-- Creating View to store Data for Later Visualization 

create view PercentPopulationVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert (float,vac.new_vaccinations)) over (partition by dea.Location Order by dea.Location,
dea.Date) as RollingPeopleVaccinated 
--, (RollingPeopleVaccinated/population)*100
from ProjectPortfolioCovid..CovidDeaths dea
Join ProjectPortfolioCovid..CovidVacctination vac
on dea.Location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select top (1000) [continent],
[location],
[Date],
[Population],
[new_vaccination],
[RollingPeopleVaccinated]
from [ProjectPortfolioCovid]..[PercentPopulationVaccinated]