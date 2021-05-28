# trading_optimization
Operation Research Solver GLPK to optimize the trading process taking predicted stock prices as inputs.

Updated Files:
- trading_optimization_hedger.mod: long and short 
- trading_optimization_buyer.mod  : long only
- input_data_stocks.data
  - prepared data using predicted stock prices for next 7 days
  - correlation matrix was caculated
  - return per day 

Example under Linux using GLPK:
```
glpsol -m trading_optimization_hedger.mod -d input_data_stocks.dat
```
Results under Ubuntu:
```
optimal execution at time 2021-05-28 11:43:12:
                  Weight,  Unit,   Price,   Action, Money, check_n
           SPOT  -0.0900,   -6,     311.00, sell,     1866.00, -0.093 // sell 6 units SPOT 
            MRK   0.0000,    0,      80.96, NaN,        0.00, 0.000
            CAT   0.0000,    0,     182.15, NaN,        0.00, 0.000
            MCD   0.0000,    0,     210.22, NaN,        0.00, 0.000
             PG   0.0000,    0,     137.82, NaN,        0.00, 0.000
           TSLA   0.5800,   16,     729.77, buy,    11676.32, 0.000   // buy 16 units Tesla
             VZ   0.0000,    0,      58.85, NaN,        0.00, 0.000
           INTC   0.0000,    0,      49.67, NaN,        0.00, 0.000
            CVX   0.0000,   -1,      84.71, sell,       84.71, -0.004 // sell 1 unit CVX
            JPM   0.1600,   26,     125.87, buy,     3272.62, 0.000
            IBM   0.0000,    0,     123.94, NaN,        0.00, 0.000
            DIS   0.0000,    0,     177.68, NaN,        0.00, 0.000
             BA   0.0000,    0,     202.72, NaN,        0.00, 0.000
              V   0.0000,    0,     217.76, NaN,        0.00, 0.000
            WMT   0.1500,   21,     146.53, buy,     3077.13, 0.000   // buy 21 units WMT
```

GLPK is available as a Debian package. The Debian package system is used by Ubuntu. If you have administrator rights, the following call should install GLPK in its entirety:

$ sudo apt-get install glpk

If you only want GLPSOL, the following call is sufficient:

$ sudo apt-get install glpk-utils
