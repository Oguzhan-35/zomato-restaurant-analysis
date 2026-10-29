# Power BI report

## Data
Run `python scripts/build_db.py` first. It writes three files into this folder:

| File | Rows | Use |
|---|---|---|
| `vw_restaurants.csv` | 9,551 | main table, one row per restaurant |
| `restaurant_cuisines.csv` | 19,705 | one row per restaurant and cuisine |
| `countries.csv` | 15 | not needed for the report, lookup only |

In Power BI Desktop: Get data > Text/CSV, load the first two files. Check that `has_online_delivery`, `has_table_booking`, `is_rated` are whole numbers and `rating` is a decimal.

## Model
One relationship: `restaurant_cuisines[restaurant_id]` (many) to `vw_restaurants[restaurant_id]` (one), single direction.

Add a page-level or report-level filter `country = India` on pages 2 and 3. The delivery data outside India is unusable (see docs/02-data-quality.md).

## Measures
Create them in `vw_restaurants`.

```dax
Restaurants = COUNTROWS ( vw_restaurants )

Rated Restaurants = CALCULATE ( COUNTROWS ( vw_restaurants ), vw_restaurants[is_rated] = 1 )

% Rated = DIVIDE ( [Rated Restaurants], [Restaurants] )

Avg Rating = AVERAGE ( vw_restaurants[rating] )   -- NULLs are ignored, so unrated places are excluded

Delivery Penetration = DIVIDE ( SUM ( vw_restaurants[has_online_delivery] ), [Restaurants] )

Table Booking Share = DIVIDE ( SUM ( vw_restaurants[has_table_booking] ), [Restaurants] )

Total Votes = SUM ( vw_restaurants[votes] )

Avg Votes = AVERAGE ( vw_restaurants[votes] )

Leads =
CALCULATE (
    COUNTROWS ( vw_restaurants ),
    vw_restaurants[rating] >= 4,
    vw_restaurants[votes] >= 100,
    vw_restaurants[has_online_delivery] = 0
)

Share of Votes (Top 10%) =
VAR cutoff = PERCENTILEX.INC ( ALL ( vw_restaurants ), vw_restaurants[votes], 0.9 )
RETURN
DIVIDE (
    CALCULATE ( [Total Votes], vw_restaurants[votes] >= cutoff ),
    CALCULATE ( [Total Votes], ALL ( vw_restaurants ) )
)
```

The last measure uses a percentile cutoff, so ties at the cutoff can make it differ slightly from the 65.2% in the SQL decile query. Compare them and mention the difference if you publish it.

## Pages
**1. Market overview**
- Cards: Restaurants, % Rated, Avg Rating, Delivery Penetration
- Bar chart: restaurants by country (log scale or top 5 + other, India dominates)
- Table: country, Restaurants, Avg Rating, % Rated

**2. Price and delivery (filter: India)**
- Clustered column: Delivery Penetration and Table Booking Share by `price_label`
- Column: Avg Rating by `price_label`
- Scatter: Avg Votes vs Avg Rating by `city` for cities with > 100 restaurants
- Slicer: `city`

**3. Cuisines and leads (filter: India)**
- Bar: top 12 cuisines by restaurant count, color by Avg Rating
- Table: small cuisines (20-99 restaurants) sorted by Avg Rating
- Card: Leads
- Table of leads: name, city, locality, cuisines, rating, votes, filtered with the Leads conditions
- Map: lead locations from latitude / longitude

## Screenshots
Put exported page images in `powerbi/screenshots/` and link them from the main README. Save the report as `powerbi/zomato-restaurants.pbix` if you want to commit it; the file embeds the data, so check the dataset license before pushing it.
