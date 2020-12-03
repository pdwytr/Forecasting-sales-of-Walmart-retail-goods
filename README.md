# M5CompetitionForecasting-Estimate-the-unit-sales-of-Walmart-retail-goods

## Introduction
Here is my first submission for the M5 accuracy competition conducted by [Makridakis Open Forecasting Center (MOFC) at the University of Nicosia](https://www.kaggle.com/c/m5-forecasting-accuracy)
### Competition
Hierarchical sales data from Walmart, the world’s largest company by revenue, is being used to forecast daily sales for the next 28 days. The data covers stores in three US states (California, Texas, and Wisconsin) and includes item level, department, product categories, and store details. Also, it has explanatory variables such as price, promotions, day of the week, and special events. Together, one may use this robust dataset to improve forecasting accuracy.
### Evaluation
this competition uses a Weighted Root Mean Squared Scaled Error (RMSSE). Extensive details about the metric, scaling, and weighting can be found in the attached Guide
### DataSet
The M5 dataset, generously made available by Walmart, involves the unit sales of various products sold in the USA, organized in grouped time series. More specifically, the dataset involves the unit sales of 3,049 products, classified into 3 product categories (Hobbies, Foods, and Household) and 7 product departments, in which the categories as mentioned earlier are disaggregated.  The products are sold across ten stores located in three states (CA, TX, and WI)
#### Calender.csv
Contains information about the dates the products are sold.
*	date: The date in a “y-m-d” format.
*	wm_yr_wk: The id of the week the date belongs to.
*	weekday: The type of the day (Saturday, Sunday, …, Friday).
*	wday: The id of the weekday, starting from Saturday.
*	month: The month of the date.
*	year: The year of the date.
*	event_name_1: If the date includes an event, the name of this event.
*	event_type_1: If the date includes an event, the type of this event.
*	event_name_2: If the date includes a second event, the name of this event.
*	event_type_2: If the date includes a second event, the type of this event.
*	snap_CA, snap_TX, and snap_WI: A binary variable (0 or 1) indicating whether the stores of CA, TX or WI allow SNAP  purchases on the examined date. 1 indicates that SNAP purchases are allowed.
#### sell_prices
Contains information about the price of the products sold per store and date.
*	store_id: The id of the store where the product is sold. 
*	item_id: The id of the product.
*	wm_yr_wk: The id of the week.
*	sell_price: The price of the product for the given week/store. The price is provided per week (average across seven days). If not available, this means that the product was not sold during the examined week. Note that although prices are constant at weekly basis, they may change through time (both training and test set).  
#### Sales_train
Contains the historical daily unit sales data per product and store.
*	item_id: The id of the product.
*	dept_id: The id of the department the product belongs to.
*	cat_id: The id of the category the product belongs to.
*	store_id: The id of the store where the product is sold.
*	state_id: The State where the store is located.
*	d_1, d_2, …, d_i, … d_1941: The number of units sold at day i, starting from 2011-01-29. 

### Submission
The main idea of the the first submission is to build a basic working model as a starting point. ARIMAX model has been used. The modelling is done on a part of data belonging to CA state and FOOD category. The modelling consists of the following parts
##### Exploratory Data analysis
##### Data Preperation
##### Modelling
##### Predictions
##### Interpretation

