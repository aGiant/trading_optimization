/*
Date: 07.Sep.2020
Auto: Longfei.Lu@live.com

- 目标产品， DAX30， US30， NAS100， SPX500
- 使用L3级别的Deep Learning找到最相似的当前状态，提出之后未来7个交易日的价格走势
- 计算每天的PnL，单位百分比，变量记录为 r
- 计算产品之间的协方差cov矩阵，变量记录为 cov
- 求解：最佳的资产分配比例， 标记为 w
- 优化目标：平均绝对离散度
- 理论方法： https://github.com/jckantor/MathProg-Solver/blob/master/examples/PortfolioMAD.mod

*/

set S;                                    # Set of stocks /*:= {"DAX30", "US30", "NAS100", "SPX500"};*/
# param r{S};                               # Means of projected returns
param cov{S,S};                           # Covariance of projected returns
param r_portfolio default 1.85;

/* Generate sample data */

/* Normal random variates */
param N default 6;
set T := 0..N;

param rt{S, T};               # predicted returns of targets
param r{S};                   # average return of targets
param p{S};                   # prices of index
param capital >= 0, default 1000*20;           # total capital of trading account
param min_w >=0, default 0.618;

/* MAD Optimization */

var w{S} >= 0;                   	# Portfolio Weights with Bounds
var y{T} >= 0;                          # Positive deviations (non-negative)
var z{T} >= 0;                          # Negative deviations (non-negative)
var v{S} >=0, <= 10000, integer;   # Volumen of positions for opening market orders
var dummy_more{S} >=0;                  # Dummy variable to check the capital issue

minimize MAD: (1/card(T))*sum {t in T} (y[t] + z[t]) - sum {s in S, t in T} w[s]*r[s]*capital + sum {s in S}p[s] * dummy_more[s]
- sum {s in S, t in T} v[s]*r[s]*p[s] ;


# deviation should be controlled
s.t. C3 {t in T}: (y[t] - z[t]) = sum{s in S} (rt[s, t]-r[s])*w[s];

# allocation should be summarized as one
s.t. C12 : sum {s in S} w[s] = 1;
# weights relations
s.t. C15 {s in S}: w[s] >= v[s]*p[s]/capital;

solve;

/* Input Data */
printf "Stock Data\n\n";
printf "         Return   Variance\n";
printf {i in S} "%5s   %7.2f   %7.4f\n", i, r[i], cov[i,i];

printf "\nCovariance Matrix\n\n";
printf "     ";
printf {j in S} " %7s ", j;
printf "\n";
for {i in S} {
    printf "%5s  " ,i;
    printf {j in S} " %7.4f ", cov[i,j];
    printf "\n";
}

/* MAD Optimal Portfolio */
printf "\nMinimum Absolute Deviation (MAD) Portfolio\n\n";
printf "capital issue, need more for minimal positive reutrn: %.3f\n", sum{s in S} dummy_more[s];
printf "  Return in $ = %.2f$, percnetage = %.2f\n", sum {s in S} p[s]*r[s]*v[s], sum{s in S} p[s]*r[s]*v[s]/capital * 100;
printf "  Variance = %7.4f\n\n", sum {i in S, j in S} w[i]*w[j]*cov[i,j];
printf "optimal execution at time %s:\n", time2str(gmtime(), '%Y-%m-%d %H:%M:%S');
printf "                  Weight,  Unit,   Price,   Action, Money\n";
printf {s in S} "%15s  %7.4f, %4.0f, %10.2f, %s,  %10.2f, \n", s, w[s], v[s], p[s], if p[s]*v[s]>0 then "buy" else if p[s]*v[s]< 0 then "sell" else "NaN", abs(p[s]*v[s]);
printf "\n";
printf "%10.3f", capital;
/**/
data;

param: S: r:=
AAPL   -0.012442
AMZN    0.004449
DIS     0.000118 
FB     -0.006926
MSFT   -0.004118 
NFLX   -0.005388
NVDA   -0.003030
TSLA    0.011533;


param: p:=
AAPL    112 
AMZN    3116.22
DIS     131.75
FB      266.61
MSFT    204.03
NFLX    482.03
NVDA    485.58
TSLA    372.72;


param capital := 5000;

param cov :
         AAPL      AMZN       DIS        FB      MSFT      NFLX      NVDA      TSLA :=
AAPL  1.000000 -0.608218 -0.030496  0.543258 -0.427374 -0.171627 -0.480293  0.621938
AMZN -0.608218  1.000000  0.623838 -0.066996  0.656847  0.161119  0.563934  0.090485
DIS  -0.030496  0.623838  1.000000  0.672228  0.775838 -0.241778  0.131534  0.450874
FB    0.543258 -0.066996  0.672228  1.000000  0.437704 -0.367863 -0.459847  0.673474
MSFT -0.427374  0.656847  0.775838  0.437704  1.000000 -0.354913  0.327825  0.127534
NFLX -0.171627  0.161119 -0.241778 -0.367863 -0.354913  1.000000 -0.329259 -0.321399
NVDA -0.480293  0.563934  0.131534 -0.459847  0.327825 -0.329259  1.000000 -0.122562
TSLA  0.621938  0.090485  0.450874  0.673474  0.127534 -0.321399 -0.122562  1.000000;

param rt :
         0     1     2     3     4     5     6 :=
AAPL -0.007981  0.001936 -0.021302 -0.008945  0.002963 -0.031566 -0.022195
AMZN -0.005319  0.002789  0.007565 -0.000543  0.003020  0.024969 -0.001336
DIS  -0.039967  0.009209  0.013048 -0.002101  0.018085  0.014268 -0.011717
FB   -0.023288 -0.004508 -0.002925  0.002681  0.012112 -0.016453 -0.016101
MSFT -0.034485 -0.012596  0.024434  0.004044 -0.004256  0.011959 -0.017926
NFLX  0.009799 -0.020714 -0.013611 -0.027348  0.008762  0.005916 -0.000518
NVDA -0.008194  0.022889  0.012403 -0.009803 -0.050802  0.030323 -0.018028
TSLA  0.004760  0.020372  0.001932  0.022148  0.022097  0.012435 -0.003013;




end;
