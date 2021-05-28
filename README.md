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
GLPK is available as a Debian package. The Debian package system is used by Ubuntu. If you have administrator rights, the following call should install GLPK in its entirety:

$ sudo apt-get install glpk
If you only want GLPSOL, the following call is sufficient:

$ sudo apt-get install glpk-utils
