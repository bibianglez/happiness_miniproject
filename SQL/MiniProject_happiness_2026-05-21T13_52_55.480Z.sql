CREATE SCHEMA IF NOT EXISTS happy_population;
USE happy_population;

CREATE TABLE IF NOT EXISTS `region` (
    `region_id` INTEGER UNSIGNED NOT NULL UNIQUE,
    `region_name` VARCHAR(255) NOT NULL,
    PRIMARY KEY(`region_id`)
);
CREATE TABLE IF NOT EXISTS `country` (
    `country_id` INTEGER UNSIGNED NOT NULL UNIQUE,
    `country_name` VARCHAR(255) NOT NULL,
    `region_id` INTEGER UNSIGNED NOT NULL,
    PRIMARY KEY(`country_id`)
);
CREATE TABLE IF NOT EXISTS `year` (
    `year_id` INTEGER UNSIGNED NOT NULL UNIQUE,
    `year` INTEGER NOT NULL,
    PRIMARY KEY(`year_id`)
);
CREATE TABLE IF NOT EXISTS `year_country` (
    `year_country_id` INTEGER UNSIGNED NOT NULL UNIQUE,
    `country_id` INTEGER UNSIGNED NOT NULL,
    `year_id` INTEGER UNSIGNED NOT NULL,
    `total_pop` FLOAT NOT NULL,
    `pop_density` FLOAT NOT NULL,
    `age_pop` FLOAT NOT NULL,
    PRIMARY KEY(`year_country_id`)
);
CREATE TABLE IF NOT EXISTS `happiness` (
    `hapiness_id` BIGINT UNSIGNED NOT NULL UNIQUE,
    `year_country_id` INTEGER UNSIGNED NOT NULL,
    `happiness_rank` FLOAT NOT NULL,
    `happiness_score` FLOAT NOT NULL,
    `gdp_percapita` FLOAT NOT NULL,
    `life_expectancy` FLOAT NOT NULL,
    `family` FLOAT NOT NULL,
    `freedom` FLOAT NOT NULL,
    `generosity` FLOAT NOT NULL,
    `government_corruption` FLOAT NOT NULL,
    PRIMARY KEY(`hapiness_id`)
);

ALTER TABLE `year_country`
ADD FOREIGN KEY(`year_id`) REFERENCES `year`(`year_id`)
ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE `year_country`
ADD FOREIGN KEY(`country_id`) REFERENCES `country`(`country_id`)
ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE `happiness`
ADD FOREIGN KEY(`year_country_id`) REFERENCES `year_country`(`year_country_id`)
ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE `country`
ADD FOREIGN KEY(`region_id`) REFERENCES `region`(`region_id`)
ON UPDATE CASCADE ON DELETE CASCADE;

-- AVERAGE HAPPINESS SCORE BY REGION (2015-2019):
SELECT r.region_name, avg(h.happiness_score) as avg_happiness from happiness h
JOIN year_country yc on h.year_country_id=yc.year_country_id
JOIN country c on yc.country_id=c.country_id
JOIN region r on c.region_id=r.region_id
GROUP BY r.region_name
ORDER BY avg_happiness desc;

-- TOP COUNTRY PER REGION (2015-2019):
WITH country_avg AS (
    SELECT r.region_name,c.country_name,AVG(h.happiness_score) AS avg_happiness,
	ROW_NUMBER() OVER (PARTITION BY r.region_name
	ORDER BY AVG(h.happiness_score) DESC) AS rn
    FROM happiness h
    JOIN year_country yc ON h.year_country_id = yc.year_country_id
    JOIN country c ON yc.country_id = c.country_id
    JOIN region r ON c.region_id = r.region_id
    GROUP BY r.region_name, c.country_name)
SELECT region_name, country_name, avg_happiness FROM country_avg
WHERE rn = 1
ORDER BY avg_happiness DESC;

-- TOP 10 HAPPIEST COUNTRIES ON AVERAGE (2015-2019):
SELECT c.country_name, avg(h.happiness_score) as avg_happiness from happiness h
JOIN year_country yc on h.year_country_id=yc.year_country_id
JOIN country c on yc.country_id=c.country_id
GROUP BY c.country_name
ORDER BY avg_happiness desc
LIMIT 10;


-- COUNTRIES ABOVE AVERAGE FOR THEIR REGION:
WITH country_avg AS (
    SELECT c.country_name,r.region_name,c.region_id,ROUND(AVG(h.happiness_score), 2) AS avg_happiness
    FROM happiness h
    JOIN year_country yc ON h.year_country_id = yc.year_country_id
    JOIN country c ON yc.country_id = c.country_id
    JOIN Region r ON c.region_id = r.region_id
    GROUP BY c.country_name, r.region_name, c.region_id
)
SELECT country_name, region_name, avg_happiness,
       (SELECT ROUND(AVG(ca2.avg_happiness), 2)
        FROM country_avg ca2
        WHERE ca2.region_id = ca.region_id) AS region_avg
FROM country_avg ca
WHERE avg_happiness > (
    SELECT AVG(avg_happiness)
    FROM country_avg ca2
    WHERE ca2.region_id = ca.region_id
)
ORDER BY region_name, avg_happiness DESC;

-- RELATIONSHIP BETWEEN POPULATION DENSITY AND HAPPINESS SCORES:
CREATE TEMPORARY TABLE pop_happy_classification AS
SELECT c.country_id, c.country_name,r.region_name,y.year, h.happiness_score,yc.pop_density,

    CASE
        WHEN h.happiness_score >= 6.5 THEN 'High'
        WHEN h.happiness_score >= 5.0 THEN 'Medium'
        WHEN h.happiness_score >= 3.5 THEN 'Low'
        ELSE 'Very Low'
    END AS happiness_level,

    CASE
        WHEN yc.pop_density >= 300 THEN 'Very Dense'
        WHEN yc.pop_density >= 100 THEN 'Dense'
        WHEN yc.pop_density >= 30 THEN 'Medium'
        ELSE 'Sparse'
    END AS density_level

FROM happiness h
JOIN year_country yc ON h.year_country_id = yc.year_country_id
JOIN country c ON yc.country_id = c.country_id
JOIN region r ON c.region_id = r.region_id
JOIN year y ON yc.year_id = y.year_id;

SELECT
    happiness_level,
    density_level,
    COUNT(*) AS combination_count
FROM pop_happy_classification
GROUP BY happiness_level, density_level
ORDER BY combination_count DESC;

-- IS HAPPINESS GROWING/ IMPROVING?: average happiness score by year (2015-2019):
SELECT y.year, avg(h.happiness_score) as avg_happiness from happiness h
JOIN year_country yc on h.year_country_id=yc.year_country_id
JOIN year y on yc.year_id=y.year_id
GROUP BY year
ORDER BY avg_happiness desc;

-- DO RICHER COUNTRIES LIVE LONGER? Obviously!!
SELECT
    CASE
        WHEN h.gdp_percapita >= 1.4
        THEN 'High'
        WHEN h.gdp_percapita >= 0.9
        THEN 'Medium'
        WHEN h.gdp_percapita >= 0.4
        THEN 'Low'
        ELSE 'very_low'
    END
    AS wealth_level,
    COUNT(DISTINCT c.country_id)
    AS num_country,
    ROUND(AVG(h.life_expectancy), 2)
    AS avg_expectancy,
    MAX(h.life_expectancy)
    AS max_expectancy,
    MIN(h.life_expectancy)
    AS min_expectancy
FROM
happiness h
INNER JOIN year_country yc
ON h.year_country_id = yc.year_country_id
INNER JOIN country c
ON yc.country_id = c.country_id
GROUP BY wealth_level
ORDER BY avg_expectancy DESC;