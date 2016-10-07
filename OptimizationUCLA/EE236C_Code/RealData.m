clc;
clear all;
close all;

%%%%%%%%%%%%%%%%%%%%%%% Load Data %%%%%%%%%%%%%%%%%%%%%%%
load returns.mat
[M,N] = size(ret);
returns = ret(:,1:N-1);
mean_ret = mean(returns)';
covariance = cov(returns);
cov_sqrt = covariance^0.5;

%%%%%%%%%%%%%%%%%%%%%%% Value-at-Risk Model %%%%%%%%%%%%%%%%%%%%%%%
cvx_begin
variables x(N-1,1)
minimize (norm(cov_sqrt*x,2) - mean_ret'*x)
subject to 
x>=0;
sum(x) ==1;
cvx_end

rm_p = mean_ret'*x;
sd_p =  sqrt(x'*covariance*x);
rho = sum(sum(corr(ret)))/(N-1)^2;
x_value_at_risk = x;
cvx_begin
variables x(N-1,1)
minimize (0)
subject to 
x>=0;
sum(x) ==1;
cvx_end

rm_p2 = mean_ret'*x;
sd_p2 =  sqrt(x'*covariance*x);

cov_p_p2 = [sd_p^2 rho*sd_p*sd_p2;rho*sd_p*sd_p2 sd_p2^2];
xa = -3:0.0001:3;
xb = 1-xa;
ret_p_p2 = rm_p*xa + rm_p2*xb;
for i=1:size(xa,2)
    risk(i,1) = [xa(i) xb(i)]*cov_p_p2*[xa(i);xb(i)];
end
figure(1);
plot(risk,ret_p_p2,'b*');
title('Portfolio Curve using Worst Case Value-at-Risk Model')
xlabel('Risk')
ylabel('Return')

%%%%%%%%%%%%%%%%%%%%%%% Markowitz Model %%%%%%%%%%%%%%%%%%%%%%%
cvx_begin
variables x(N-1,1)
minimize (x'*covariance*x)
subject to 
x>=0;
sum(x) ==1;
cvx_end
x_mark = x;
rm_p = mean_ret'*x;
sd_p =  sqrt(x'*covariance*x);
rho = sum(sum(corr(ret)))/(N-1)^2;
cvx_begin
variables x(N-1,1)
minimize (0)
subject to 
x>=0;
sum(x) ==1;
cvx_end

rm_p2 = mean_ret'*x;
sd_p2 =  sqrt(x'*covariance*x);

cov_p_p2 = [sd_p^2 rho*sd_p*sd_p2;rho*sd_p*sd_p2 sd_p2^2];
xa = -3:0.0001:3;
xb = 1-xa;
ret_p_p2_mark = rm_p*xa + rm_p2*xb;
for i=1:size(xa,2)
    risk_mark(i,1) = [xa(i) xb(i)]*cov_p_p2*[xa(i);xb(i)];
end
figure(2);
hold on;
plot(risk,ret_p_p2);
plot(risk_mark,ret_p_p2_mark,'m')
plot(min(risk_mark),ret_p_p2_mark(find(risk_mark==min(risk_mark))),'k*');
plot(min(risk),ret_p_p2(find(risk==min(risk))),'rd');
legend('Worst Case Value-at-Risk Model','Markowitz Model','Optimal Value of Markowitz Model','Optimal Value of Worst Case Value-at-Risk Model')
title('Portfolio Performance')
xlabel('Risk')
ylabel('Return')