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
param bigM := 10000000000.0;
/* MAD Optimization */

var w{S} >= -1;                   	# Portfolio Weights with Bounds
var y{T} >= 0;                          # Positive deviations (non-negative)
var z{T} >= 0;                          # Negative deviations (non-negative)
var v{S} >=-10000, <= 10000, integer;   # Volumen of positions for opening market orders
var dummy_more{S} >=0;                  # Dummy variable to check the capital issue
var w_abs{S} >= 0;# <= 1-0.618; #0.618/card(S); 			# abs value of weights
var v_abs{S} >= 0; 			# abs value of pieces
var w_negative{S} <=0;
var w_b{S}, binary;

minimize MAD: (1/card(T))*sum {t in T} (y[t] + z[t]) - sum {s in S, t in T} w[s]*r[s]*capital + sum {s in S}p[s] * dummy_more[s];
#- sum {s in S, t in T} v[s]*rt[s, t]*p[s] 
# minimul return control - not needed especially for critical market situation
#s.t. C1 : sum{s in S}w[s]*r[s] >= r_portfolio; 

# deviation should be controlled
s.t. C3 {t in T}: (y[t] - z[t]) = sum{s in S} (rt[s, t]-r[s])*w[s];

# abs weights relations
s.t. C7 {s in S}: w_abs[s] = v_abs[s]*p[s]/capital;
s.t. C10 {s in S}: -w[s] <= w_abs[s];
s.t. C11 {s in S}: w[s] <= w_abs[s];
# allocation should be summarized as one
s.t. C12 : sum {s in S} w_abs[s] <= 1;
s.t. C13 {s in S}: -v[s] <= v_abs[s];
s.t. C14 {s in S}: v[s] <= v_abs[s];
# weights relations
s.t. C15 {s in S}: w[s] = v[s]*p[s]/capital;

s.t. C16 {s in S}: (w[s]-w_abs[s])/2 = w_negative[s];
#s.t. C17 {s in S}: -w[s] >= w_negative[s];

# positive allocation bigger than negative allocation
s.t. C18: sum{s in S}(w[s] - w_negative[s]) >= 0.8 + sum{s in S} -1*w_negative[s];

# get the binary variable of w_abs, means if trade then 1 else 0
s.t. C19 {s in S}: -w_abs[s] - (1-w_b[s])*bigM <= 0;
s.t. C20: sum{s in S} w_b[s] >= 3;
s.t. C21 {s in S}: w_abs[s] + w_b[s]*bigM >= 0;

# min allocation
s.t. C22 {s in S}: w_b[s] * 0.15 <= w_abs[s];
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
printf "  Return in $ = %.2f$, percnetage = %.2f\n", sum {s in S, t in T} p[s]*rt[s, t]*v[s], sum{s in S, t in T} p[s]*rt[s, t]*v[s]/capital * 100;
printf "  Variance = %7.4f\n\n", sum {i in S, j in S} w[i]*w[j]*cov[i,j];
printf "optimal execution at time %s:\n", time2str(gmtime(), '%Y-%m-%d %H:%M:%S');
printf "                  Weight,  Unit,   Price,   Action, Money, check_n\n";
printf {s in S} "%15s  %7.4f, %4.0f, %10.2f, %s,  %10.2f, %.3f\n", s, round(w[s],2), v[s], p[s], if p[s]*v[s]>0 then "buy" else if p[s]*v[s]< 0 then "sell" else "NaN", round(abs(p[s]*v[s]),2), w_negative[s];
printf "\n";
printf "%10.3f \n", capital;

param used_money{s in S} := abs(p[s]*v[s]);
param actions{s in S}:= if p[s]*v[s]>0 then 1 else if p[s]*v[s]< 0 then -1 else 0;
param csv_out{s in S} := w[s] & "," & v[s] & "," & actions[s] & "," & used_money[s];
/* output to csv file */
printf "Target,Weight,Unit,Action,Used_Money,Ret\n" > "./" & time2str(gmtime(), '%Y-%m-%d') &"/" & "results_hedging.csv";
printf{s in S: v[s]>0} "%s\n", s & "," & round(w[s],5) & "," & v[s] & "," & actions[s] & "," & round(used_money[s],2) &  "," & round(r[s],4) >> "./" & time2str(gmtime(), '%Y-%m-%d') &"/" & "results_hedging.csv";

param take_profit_percentage := sum{s in S, t in T} p[s]*r[s]*v[s]/capital;
param take_profit_value := sum {s in S, t in T} p[s]*r[s]*v[s];
printf "%s, %.3f, %.1f, %.1f, %.1f\n", "take_profit", take_profit_percentage, take_profit_value , 0, 0;

printf "%s\n", "take_profit" & "," & round(take_profit_percentage,5) & "," & round(take_profit_value,2) & "," & 0 & "," & 0 & "," & 0>> "./" & time2str(gmtime(), '%Y-%m-%d') &"/" & "results_hedging.csv";

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
