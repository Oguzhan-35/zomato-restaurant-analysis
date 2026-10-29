# Zomato Restaurants: where is the gap between good and visible?

SQL (SQLite) + Power BI, based on the Zomato restaurant listing dataset from Kaggle (9,551 restaurants, 15 countries).

I wanted a project where I start from a vague business question and end with something a team could act on, instead of just charting columns. The question I made up for myself:

> A food-delivery partnerships team has limited sales capacity. Which restaurants and cities should they approach first, and what should they know about the market before they do?

Nothing here comes from a real engagement. The business question is mine, the data is public.

## What I found

All numbers come from the queries in `sql/02_analysis.sql`; full output is in [docs/03-analysis-results.md](docs/03-analysis-results.md).

1. **The dataset is almost entirely India.** 8,652 of 9,551 restaurants (91%), and 7,947 of those are in the Delhi NCR (Delhi, Gurgaon, Noida, Faridabad, Ghaziabad). Every other Indian city has about 20 restaurants, so I treat those as samples, not as city-level benchmarks.
2. **Online delivery doesn't mean better food, but it means being seen.** Average rating is 3.37 with delivery and 3.34 without, which is nothing. But 33% of Indian restaurants without delivery have no rating at all, against 4% of those with delivery, and delivery restaurants average 218 votes vs 162.
3. **Attention is extremely concentrated.** The top 10% of restaurants hold 65% of all votes. The bottom 10% have none.
4. **Price range tells you what a restaurant needs.** Table booking is 0% in budget places and 56-65% in upscale and fine dining. Delivery peaks in the moderate tier (45%) and falls to 11% for fine dining.
5. **There is a pool of obvious leads.** 430 Indian restaurants rated 4.0+ with at least 100 votes don't offer online delivery. Average rating 4.24, average votes 798. 143 are in New Delhi, 33 in Gurgaon, and the rest are spread out (Lucknow, Goa, Guwahati, Pune, Bangalore each have 11-15).
6. **Some small cuisines rate well above the big ones.** North Indian, Chinese and Fast Food all average about 3.3 in India. Mediterranean averages 3.98 over 89 rated restaurants and 812 votes each. Sushi, Kerala and Seafood also do well. This is correlation only; those restaurants are probably also more expensive.

Recommendations and the reasoning behind them are in [docs/04-findings-and-recommendations.md](docs/04-findings-and-recommendations.md).

## How it's built

```
data/raw/zomato.csv        raw file from Kaggle (not committed, see below)
scripts/build_db.py        cleans the data, loads SQLite, exports CSVs for Power BI
sql/01_views.sql           vw_restaurants (flags, rating bands, price labels)
sql/02_analysis.sql        nine analysis queries
scripts/run_analysis.py    runs them and writes docs/03-analysis-results.md
powerbi/                   CSVs for Power BI + build notes and DAX measures
docs/                      brief, data quality notes, results, recommendations
```

To reproduce it, download the dataset from Kaggle, save it as `data/raw/zomato.csv`, then:

```bash
pip install pandas
python scripts/build_db.py
python scripts/run_analysis.py
```

I didn't commit the raw file or the generated CSVs because I'm not sure about redistribution terms for the dataset.

## Things that tripped me up

- **0.0 ratings are not bad ratings.** The 2,148 restaurants with a rating of 0 are labelled "Not rated". Averaging them in drags the India average down a lot, so I set them to NULL and report "% rated" separately.
- **Only India has meaningful delivery data.** Outside India the delivery flag is 0 for everyone except 28 UAE restaurants. I think the field simply wasn't collected there, so I didn't compare countries on delivery.
- **Cost for two is in local currency.** I didn't convert anything. Cost comparisons are within India, and across countries I use the 1-4 price range.
- **Country names are not in the file.** Only a numeric code. I mapped them using the standard Zomato code list and checked each code against its cities.
- 103 restaurant names have broken characters in the source. I kept them and flagged them (`name_encoding_issue`).

More in [docs/02-data-quality.md](docs/02-data-quality.md).

## Power BI

The report is built on `vw_restaurants` and `restaurant_cuisines`. Model, DAX measures and the page layout are in [powerbi/README.md](powerbi/README.md).

## Limits

This is a one-time snapshot with no dates, so I can't say anything about trends. Votes and ratings come from users and favour places that are already popular. "Lead" in this project just means high rating plus enough votes plus no delivery; I have no information on whether those restaurants actually want it.

---
Oğuzhan Kul · İzmir · [github.com/Oguzhan-35](https://github.com/Oguzhan-35)
