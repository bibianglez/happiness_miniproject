# 🌍 World Happiness Report — Data Cleaning, EDA & Analysis

> **HappyMaxx Consulting** helps governments understand what makes people happier and which policies improve quality of life. Using global happiness data, we identify key factors — such as healthcare, economic stability, and social support — linked to higher wellbeing. Our goal is to help countries make data-driven decisions that create happier and healthier societies.
>
> *Maximising Happiness, One Data Point at a Time.*

---

## 📌 Project Overview

This project performs a full end-to-end data pipeline on the **World Happiness Report** dataset (2015–2019), sourced from Kaggle, enriched with UN World Population data. It covers data cleaning and preparation, exploratory data analysis (EDA) in both Python and SQL, and a final presentation of insights for a consulting context.

The analysis spans **782 observations**, **156 countries**, and **10 world regions** across five years.

---

## 🗂️ Repository Structure — How to Navigate This Repo

```
happiness_miniproject/
│
├── README.md                          ← You are here
│
├── data/
│   ├── HAPPINESS.csv                  ← Raw happiness data (2015–2019, concatenated from Kaggle)
│   ├── population_df.csv              ← UN population data (total pop, density, median age)
│   └── HAPPY_POPULATION.csv           ← ✅ Final clean dataset — start here for analysis
│
├── notebooks/
│   ├── readme_happiness.ipynb         ← Project overview and pipeline documentation
│   ├── FINAL_clean.ipynb              ← Data cleaning pipeline: merges happiness + population data
│   └── FINAL_clean_with_graphs.ipynb  ← EDA notebook: all final visualizations and statistical analysis
│
├── sql/
   └── MiniProject_happiness.sql      ← MySQL schema + exploratory SQL queries

```

> **New to the repo?** Start with `HAPPY_POPULATION.csv` if you just want the clean data, or `FINAL_clean_with_graphs.ipynb` if you want to explore the full analysis interactively.

---

## 📁 File Descriptions

### Data Files

| File | Description |
|------|-------------|
| `HAPPINESS.csv` | Raw concatenated happiness data from Kaggle's World Happiness Report CSVs (2015–2019). Contains one row per country per year with happiness score, GDP, life expectancy, freedom, generosity, and corruption scores. Column names are inconsistent across years — see cleaning notebook. |
| `population_df.csv` | Population data sourced from UN World Population Prospects. Contains total population, population density (per km²), and median age per country per year. |
| `HAPPY_POPULATION.csv` | **The final analysis-ready dataset.** Result of merging the two sources above after cleaning. 782 rows × 14 columns, zero nulls. This is the file used for all EDA and visualizations. |

### Notebooks

| File | Description |
|------|-------------|
| `readme_happiness.ipynb` | Project documentation notebook. Describes the full data pipeline, column standardization logic, region reconstruction steps, and the final DataFrame schema. Good entry point to understand what was done before touching any code. |
| `FINAL_clean.ipynb` | **Data cleaning and merging pipeline.** Loads `HAPPINESS.csv` and `population_df.csv`, applies country name aliases (e.g. `North Cyprus → Cyprus`, `Somaliland Region → Somalia`), merges on `country_key + year`, handles the single remaining null (UAE 2018 corruption filled with country median), and exports `HAPPY_POPULATION.csv`. |
| `FINAL_clean_with_graphs.ipynb` | **Full EDA and visualization notebook.** Contains all final graphs produced for the analysis: correlation heatmap, GDP vs happiness scatter, life expectancy vs happiness scatter, freedom vs happiness scatter, corruption vs happiness scatter, happiness distribution by region (bar chart), happiness score evolution by region (line chart, 2015–2019), and top 10 happiest and saddest countries (horizontal bar charts). All charts are colored by region and include trend lines. |

### SQL File

| File | Description |
|------|-------------|
| `MiniProject_happiness.sql` | MySQL schema definition and exploratory SQL queries. Creates the normalized relational schema (`region → country → year → year_country → happiness`) with foreign keys and cascade rules. Includes queries for: average happiness by region, top country per region (using `ROW_NUMBER` window function), top 10 happiest countries overall, countries above their regional average, happiness–density cross-classification (using `CASE` buckets), global happiness trend by year, and the relationship between GDP wealth level and life expectancy. |

---

## 📦 Requirements

```bash
pip install pandas numpy matplotlib seaborn pycountry
```

For the SQL component:
- MySQL Workbench or any MySQL-compatible client
- Run `MiniProject_happiness.sql` to create the schema and execute the exploratory queries

---

## 🔄 Pipeline Overview

### Step 1 — Load the raw data
Five annual Kaggle CSVs (2015–2019) are loaded individually. Each year has between 155 and 158 country records.

### Step 2 — Standardize column names
A `clean_column_names()` function strips whitespace, converts to lowercase, and replaces spaces/dots with underscores. A `rename_columns()` function unifies field names across years using keyword matching:

| Normalized name | Examples of raw names |
|---|---|
| `happiness_score` | `Score`, `Happiness Score` |
| `happiness_rank` | `Rank`, `Happiness Rank` |
| `gdp_percapita` | `Economy (GDP per Capita)`, `GDP per capita` |
| `life_expectancy` | `Health (Life Expectancy)` |
| `family` | `Social support`, `Family` |
| `government_corruption` | `Trust (Government Corruption)` |
| `freedom` | `Freedom to make life choices` |

### Step 3 — Data quality checks
- **Duplicates**: checked across all five DataFrames — none found.
- **Null values**: only one null detected — `government_corruption` for UAE in 2018, filled with the country's own median across all years (preferred over mean due to an outlier 2019 value).

### Step 4 — Clean and standardize country names
The `pycountry` library resolves country names to their official ISO forms. Edge cases are handled with a `country_name_fixes` dictionary. A `country_clean` column is created alongside the original.

### Step 5 — Reconstruct the `region` column
The `region` column only exists in 2015 and 2016 data. A `country_region_dict` is built from those years and mapped onto 2017–2019. Countries still missing a region are assigned one via `manual_region_fixes`. A final null check confirms all rows have a region.

### Step 6 — Merge with population data
`HAPPINESS.csv` is merged with `population_df.csv` on `[country_key, year]` using a left join. Country name mismatches between the two sources are resolved with aliases:

```python
country_aliases = {
    "North Cyprus":      "Cyprus",
    "Macedonia":         "North Macedonia",
    "Somaliland Region": "Somalia",
    "Somaliland region": "Somalia",
}
```

### Step 7 — Export final dataset
The cleaned, merged DataFrame (`happy_population_df`) is saved as `HAPPY_POPULATION.csv`. Final shape: **782 rows × 14 columns**, zero nulls.

---

## 📊 Final Dataset: `HAPPY_POPULATION.csv`

| Column | Type | Description |
|--------|------|-------------|
| `happiness_rank` | int | Country ranking by happiness score for that year |
| `year` | int | Survey year (2015–2019) |
| `country` | str | Standardized country name (ISO via pycountry) |
| `region` | str | World region (10 categories) |
| `happiness_score` | float | Overall happiness score (scale 0–10) |
| `gdp_percapita` | float | GDP per capita contribution to happiness score |
| `life_expectancy` | float | Healthy life expectancy contribution |
| `family` | float | Social support / family contribution |
| `freedom` | float | Freedom to make life choices contribution |
| `generosity` | float | Generosity contribution |
| `government_corruption` | float | Perceived absence of corruption contribution |
| `total_pop` | float | Total population |
| `pop_density` | float | Population density (people per km²) |
| `age_pop` | float | Median age of the population |

**Key stats:**

| Metric | Value |
|--------|-------|
| Global mean happiness | 5.41 |
| Global median happiness | 5.37 |
| Std deviation | 1.11 |
| Highest score | 7.63 — Finland |
| Lowest score | 2.69 — South Sudan |
| Countries | 156 |
| Regions | 10 |
| Years | 2015–2019 |

---

## 🔬 EDA — Exploratory Data Analysis

The EDA was conducted in parallel through three tools: Python (notebook + scripts) and MySQL.

### Python EDA (`FINAL_clean_with_graphs.ipynb`)

**Descriptive statistics** were computed for all 10 numeric variables, including mean, median, mode, standard deviation, min, max, skewness, and kurtosis.

**Correlation analysis** (Pearson r with happiness score):

| Variable | r | Strength |
|---|---|---|
| GDP per capita | 0.79 | Strong |
| Life expectancy | 0.74 | Strong |
| Median age | 0.68 | Moderate–Strong |
| Family / social support | 0.65 | Moderate |
| Freedom | 0.55 | Moderate |
| Government trust | 0.40 | Moderate |
| Generosity | 0.14 | Weak |
| Population density | 0.08 | Negligible |
| Total population | −0.04 | Negligible |

**Visualizations produced:**
1. Correlation heatmap — all happiness variables (lower-triangle, `RdYlGn` palette)
2. GDP per capita vs happiness score — scatter colored by region with trend line
3. Life expectancy vs happiness score — scatter by region with trend line
4. Freedom vs happiness score — scatter by region with trend line
5. Corruption vs happiness score — scatter by region with trend line
6. Average happiness score by region — bar chart sorted descending
7. Happiness score evolution by region — line chart 2015–2019
8. Top 10 happiest countries — horizontal bar chart
9. Top 10 saddest countries — horizontal bar chart

### SQL EDA (`MiniProject_happiness.sql`)

SQL queries explored the same data from a relational perspective:

- **Average happiness by region** — simple aggregate ranking confirming Python results
- **Top country per region** — window function (`ROW_NUMBER OVER PARTITION BY region`) to identify each region's best performer
- **Top 10 happiest countries overall** — aggregated across all years
- **Countries above their regional average** — correlated subquery to find overperformers within each region
- **Happiness × density cross-classification** — `CASE` bucketing of both happiness level (Very Low / Low / Medium / High) and population density (Sparse / Medium / Dense / Very Dense) to look for patterns
- **Global happiness trend by year** — yearly average to check whether happiness improved 2015–2019
- **GDP wealth level vs life expectancy** — `CASE` buckets on GDP show a striking 3× gap in life expectancy scores between the wealthiest and poorest country groups

---

## 🔬 Hypotheses & Conclusions

### Hypothesis 1 — Economic and Social Development & Happiness ✅ Confirmed

**Hypothesis:** Countries with higher GDP per capita, stronger social support systems, and higher life expectancy will report higher happiness scores, suggesting that both economic prosperity and social wellbeing contribute positively to national happiness levels.

**Result: Confirmed.** GDP per capita (r = 0.79) is the single strongest predictor of happiness in the dataset, followed closely by life expectancy (r = 0.74) and family support (r = 0.65). Countries in the highest GDP tier average a score of 6.81 versus 4.00 for the lowest tier — a 1.7× gap. Western Europe, North America, and Australia/New Zealand dominate the top rankings. One notable outlier: Latin American countries consistently score above their GDP level, driven by strong family and social support scores.

---

### Hypothesis 2 — Demographics & Happiness ⚠️ Partially Rejected

**Hypothesis:** Population characteristics such as total population size, population density, and median age may influence national happiness levels, with more demographically stable and developed populations expected to show higher average happiness scores.

**Result: Partially rejected.** Total population (r = −0.04) and population density (r = 0.08) show virtually no linear relationship with happiness — large countries are not happier, and dense countries are not sadder (Singapore and the Netherlands rank highly despite extreme density). However, **median age (r = 0.68) is a meaningful predictor**: countries with older populations score substantially higher on average. This is because median age is a strong proxy for demographic maturity — nations with older populations have typically sustained decades of investment in healthcare, nutrition, and institutional stability.

---

### Hypothesis 3 — Profile of High-Happiness Countries ✅ Confirmed

**Hypothesis:** Countries with high happiness scores are expected to share common structural characteristics, including strong economic performance, low perceived corruption, high personal freedom, and strong institutional trust.

**Result: Confirmed.** The top 10% of happiest countries share a clear and consistent profile compared to the bottom 10%:

| Variable | Top 10% | Bottom 10% | Ratio |
|---|---|---|---|
| GDP per capita | 1.37 | 0.37 | 3.7× |
| Life expectancy | 0.89 | 0.29 | 3.0× |
| Government trust | 0.28 | 0.12 | 2.4× |
| Freedom | 0.58 | 0.28 | 2.0× |
| Family support | 1.38 | 0.65 | 2.1× |
| Generosity | 0.33 | 0.23 | 1.4× |

The **"dream country" formula** is: wealthy + healthy + free + trustworthy institutions. Generosity shows the weakest gap, suggesting it is more a by-product of happiness than a driver of it.

---

## 🗺️ Regions Covered

10 world regions are represented:

| Region | Mean Happiness (2015–2019) |
|--------|---------------------------|
| Australia and New Zealand | 7.30 |
| North America | 7.18 |
| Western Europe | 6.76 |
| Latin America and Caribbean | 6.02 |
| Eastern Asia | 5.65 |
| Central and Eastern Europe | 5.43 |
| Middle East and Northern Africa | 5.35 |
| Southeastern Asia | 5.34 |
| Southern Asia | 4.58 |
| Sub-Saharan Africa | 4.19 |

---

## 📈 Technologies Used

| Tool | Purpose |
|------|---------|
| **Python 3** | Primary analysis language |
| **Pandas** | Data cleaning, merging, and manipulation |
| **NumPy** | Numerical operations and correlation calculations |
| **Matplotlib & Seaborn** | Data visualization and statistical graphics |
| **pycountry** | ISO country name standardization |
| **Jupyter Notebook** | Interactive development environment |
| **MySQL Workbench** | Relational schema design and SQL-based EDA |


---

## ✒️ Authors

**Irene Fafián** and **Bibian González**
