# World Life Expectancy Project (Data cleaning) 
use world_life_expectancy;

select *
from world_life_expectancy;

# Want to see if there are duplicates in the dataset (duplication of the years - each year should be unique for each country)

select Country, Year, concat(Country, Year) as country_year, count(concat(Country, Year)) as number_of_duplicates
from world_life_expectancy
group by Country, Year, concat(Country, Year)
having count(concat(Country, Year))> 1;

# Here is another way to select those same columns 
select *
from (
	select Row_ID,
    concat(Country, Year),
    ROW_NUMBER() OVER(partition by concat(Country, Year) order by concat(Country, Year)) as Rown_Num
    from world_life_expectancy
	) as Row_Table
where Rown_Num > 1;

# Disable Safe Update Mode
SET SQL_SAFE_UPDATES = 0;

# Delete the duplicates 

delete from world_life_expectancy
where 
	Row_ID in (
    select Row_ID
from (
	select Row_ID,
    concat(Country, Year),
    row_number() over(partition by concat(Country, Year) order by concat(Country, Year)) as Row_Num
    from world_life_expectancy
	) as Row_table
where Row_Num > 1
);

# Re-enable Safe Update Mode
SET SQL_SAFE_UPDATES = 1;

# We need to identify the nulls/blanks in the status column

select *
from world_life_expectancy
where Status ='';

select distinct(Status)
from world_life_expectancy
where Status <> '';

# List of the developing countries 

select distinct(Country)
from world_life_expectancy
where Status = 'Developing';

# need to fill the blanks with their respective status 
# We will first fill in the status of the developing countries 
update world_life_expectancy t1
join world_life_expectancy t2
	on t1.Country = t2.Country
set t1.Status = 'Developing'
where t1.Status = ''
and t2.Status <> ''
and t2.Status = 'Developing'
;

# Second we will fill in the status of the developed countries 

update world_life_expectancy t1
join world_life_expectancy t2
	on t1.Country = t2.Country
set t1.Status = 'Developed'
where t1.Status = ''
and t2.Status <> ''
and t2.Status = 'Developed'
;

# There are some blanks in the life expectancy column 

select Country, Year, `Life expectancy`
from  world_life_expectancy
where 'Life expectancy' = '';


# Solution to fill the life expectancy - we took an average of the previous and the one after of the missing value to be able to fill a that value
SELECT t1.Country, 
       t1.Year, 
       t1.`Life expectancy`, 
       t2.Country, 
       t2.Year, 
       t2.`Life expectancy`, 
       t3.Country, 
       t3.Year, 
       t3.`Life expectancy`, 
       ROUND((t2.`Life expectancy` + t3.`Life expectancy`) / 2, 1) AS Average_Life_Expectancy
FROM world_life_expectancy t1
JOIN world_life_expectancy t2  
    ON t1.Country = t2.Country 
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3  
    ON t1.Country = t3.Country 
    AND t1.Year = t3.Year + 1
WHERE t1.`Life expectancy` = '';

# We need to actually fill it by using the update function 

update world_life_expectancy t1
JOIN world_life_expectancy t2  
    ON t1.Country = t2.Country 
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3  
    ON t1.Country = t3.Country 
    AND t1.Year = t3.Year + 1
set t1.`Life expectancy` = round((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
WHERE t1.`Life expectancy` = '';

#check the final results 

select Country, Year, `Life expectancy`
from  world_life_expectancy;




# World Life Expectancy Project (Exploratory Data Analysis)

 
select *
from world_life_expectancy;

# Measured the life increase over 15 years 

select Country, 
min(`Life expectancy`), 
max(`Life expectancy`),
round(max(`Life expectancy`) - min(`Life expectancy`), 1) as life_increase_over_15_years
from world_life_expectancy
group by Country
having min(`Life expectancy`) <> 0 and max(`Life expectancy`) <> 0
order by life_increase_over_15_years asc;

# Measure the average Life expectancy over the years 

select Year, round(avg(`Life expectancy`),2)
from world_life_expectancy
where `Life expectancy` <> 0
and `Life expectancy` <> 0
group by Year 
order by Year 
;

# We want to see if GDP is correlated to the life expectancy 

select Country, round(avg(`Life expectancy`),1) as avg_life_exp, round(avg(GDP),1) as GDP
from world_life_expectancy
group by Country
having avg_life_exp > 0 and GDP > 0
order by GDP desc
;

# Numer of rows that have a value of GDP that is higher than 1500

select 
sum(
case 
	when GDP >= 1500 then 1
    else 0
end) high_GDP_Count
from world_life_expectancy
;

# We need to calculate the average life expectancy for rows where the GDP is 1500 or higher, and separately, for rows where the GDP is less than 1500 

select 
sum(case when GDP >= 1500 then 1 else 0 end) high_GDP_Count,
round(avg(case when GDP >= 1500 then `Life expectancy` else null end),2) high_GDP_Life_expectancy,
sum(case when GDP <= 1500 then 1 else 0 end) low_GDP_Count,
round(avg(case when GDP <= 1500 then `Life expectancy` else null end),2) low_GDP_Life_expectancy
from world_life_expectancy
;

# Study the corelation between the average life expectancy and the Status of the countries 
 
select Status, round(avg(`Life expectancy`), 1) avg_life_exp
from world_life_expectancy
group by Status;

-- We need to see if the output of the previous query shows skewed numbers - and it turned out that it is skewed because there is a huge difference between the number 
-- of developed and developing countries
# This query shows the number of developing and developed countries respectively 

select Status, count(distinct Country) nb_country, round(avg(`Life expectancy`), 1) avg_life_exp
from world_life_expectancy
group by Status;

# Study the correlation between average lide expectancy and BMI

select Country, round(avg(`Life expectancy`),1) as avg_life_exp, round(avg(BMI),1) as BMI
from world_life_expectancy
group by Country
having avg_life_exp > 0 and BMI > 0
order by BMI desc
;
# Through the previous query we found that in general the lower the BMI the lower the average life expectancy 

# We will fcus on adult mortality and see its correlation over life expectancy. Besides, we will calculate the rolling_total 

select Country,
Year,
`Life expectancy`, 
`Adult Mortality`,
sum(`Adult Mortality`) over(partition by Country order by Year) as Rolling_Total
from world_life_expectancy
where Country like 'Lebanon';


