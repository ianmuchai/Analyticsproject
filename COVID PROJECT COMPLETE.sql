create table covid_deaths("iso_code" varchar(100), "continent" varchar(100), "location" varchar(100), 
						  "DOA" varchar(100), "population" bigint, "total_cases" numeric, "new_cases" numeric, 
						  "new_cases_smoothed" varchar(100), "total_deaths" numeric, "new_deaths" numeric, 
						  "new_deaths_smoothed" varchar(100), "total_cases_per_million" varchar(100), 
						  "new_cases_per_million" varchar(100), "new_cases_smoothed_per_million" varchar(100), 
						  "total_deaths_per_million" varchar(100), "new_deaths_per_million" varchar(100),
						  "new_deaths_smoothed_per_million" varchar(100), "reproduction_rate" varchar(100), 
						  "icu_patients" numeric, "icu_patients_per_million" varchar(100), "hosp_patients" integer, 
						  "hosp_patients_per_million" varchar(100), "weekly_icu_admissions" numeric, 
						  "weekly_icu_admissions_per_million" varchar(100), "weekly_hosp_admissions" numeric,
						  "weekly_hosp_admissions_per_million"varchar(100));
create table covid_vaccinations (iso_code varchar(100), continent varchar(100), location varchar(100), DOA varchar(100),
								total_tests numeric, new_tests numeric, total_tests_per_thousand numeric, new_tests_per_thousand numeric,
								new_tests_smoothed numeric, new_tests_smoothed_per_thousand numeric, positive_rate numeric, tests_per_case numeric,
								tests_units varchar(100), total_vaccinations numeric, people_vaccinated numeric, people_fully_vaccinated numeric,
								total_boosters numeric, new_vaccinations numeric, new_vaccinations_smoothed numeric, total_vaccinations_per_hundred numeric,
								people_vaccinated_per_hundred numeric, people_fully_vaccinated_per_hundred numeric, total_boosters_per_hundred numeric,
								new_vaccinations_smoothed_per_million numeric,  new_people_vaccinated_smoothed numeric, new_people_vaccinated_smoothed_per_hundred numeric,
								stringency_index numeric, population_density numeric, median_age numeric, aged_65_older numeric, aged_70_older numeric, gdp_per_capita numeric,
								extreme_poverty numeric, cardiovasc_death_rate numeric, diabetes_prevalence numeric, female_smokers numeric, male_smokers numeric, handwashing_facilities numeric,
								hospital_beds_per_thousand numeric, life_expectancy numeric, human_development_index numeric, excess_mortality_cumulative_absolute numeric, excess_mortality_cumulative numeric,
								excess_mortality numeric, excess_mortality_cumulative_per_million numeric)
SELECT * FROM public.covid_deaths order by 3,4

-- Select data that we're going to be using
SELECT Location, "DOA", total_cases, new_cases, total_deaths, population FROM public.covid_deaths
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Likelihood of death
SELECT Location, "DOA", total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM public.covid_deaths
where location like '%India%'

-- Total cases vs Population
-- Shows what percentage of population got Covid India
SELECT Location, "DOA", population, total_cases, (total_cases/population)*100 as DeathPercentage
FROM public.covid_deaths
where location like '%India%'
and continent is not null
order by 1,2

-- Shows global percentage of populations that got Covid
SELECT Location, "DOA", population, total_cases, (total_cases/population)*100 as Infectedpopulationpercentage
FROM public.covid_deaths
order by 1,2

-- Highest infection rate versus Population
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, 
MAX((total_cases/population))*100 as Infectedpopulationpercentage
FROM public.covid_deaths
Group by location, population
order by Infectedpopulationpercentage desc

-- Highest death count per location
SELECT Location, MAX(cast(total_deaths as int)) as Totaldeathcount 
FROM public.covid_deaths
Where continent is not null
Group by location
order by Totaldeathcount desc

-- DATA BY CONTINENT AND INCOME STATUS
SELECT location, MAX(cast(total_deaths as int)) as Totaldeathcount 
FROM public.covid_deaths
Where continent is null
Group by location
order by Totaldeathcount desc

-- Highest death count per continent
SELECT continent, MAX(cast(total_deaths as int)) as Totaldeathcount 
FROM public.covid_deaths
Where continent is not null
Group by continent
order by Totaldeathcount desc

-- Global Numbers
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM public.covid_deaths
where continent is not null
--group by "DOA"
order by 1,2

-- CTE
With PopvsVac (Continent, Location, DOA, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea."DOA", dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) 
OVER (partition by dea.location order by dea.location, dea."DOA")as RollingPeopleVaccinated
FROM public.covid_deaths dea
join public.covid_vaccinations vac
on dea.location = vac.location
and dea."DOA" = vac.DOA
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac

-- TEMP
Create table PercentPopulationVaccinated
(continent varchar (250),
 Location varchar (250),
 DOA varchar (250),
 Population numeric,
 New_vaccination numeric,
 RollingPeopleVaccinated numeric 
);
Insert into PercentPopulationVaccinated
Select dea.continent, dea.location, dea."DOA", dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) 
OVER (partition by dea.location order by dea.location, dea."DOA")as RollingPeopleVaccinated
FROM public.covid_deaths dea
join public.covid_vaccinations vac
on dea.location = vac.location
and dea."DOA" = vac.DOA;

Select *, (RollingPeopleVaccinated/Population)*100
from PercentPopulationVaccinated

-- Views for Visualization
Create view Percent_PopulationVaccinated as 
Select dea.continent, dea.location, dea."DOA", dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) 
OVER (partition by dea.location order by dea.location, dea."DOA")as RollingPeopleVaccinated
FROM public.covid_deaths dea
join public.covid_vaccinations vac
on dea.location = vac.location
and dea."DOA" = vac.DOA
where dea.continent is not null

Select * from Percent_PopulationVaccinated