clc;
clear all;
close all;
%%
i =1;
epsilon = 0.02;
iter = 1;
d=0.01;
%for d = 0.01:0.001:0.03;
    func = @(w) (w+1)^(epsilon-1)*(epsilon*w -w -1) + exp(d);
    options = optimoptions('fsolve','Display','iter');
    [w,fval] = fsolve(func,0.5,options);
    pd = makedist('Normal',0,1);
    k_e_d(iter,1) = -1*icdf(pd,fval);
    iter=iter+1;
%end
k_e_d = k_e_d(end,1);
%%
%%%%%%%%%%%%%%%%%%%%% Generating the Data %%%%%%%%%%%%%%%%%%%%%%%%%%
for T = 500
    A = randn(T,T);
    tau = A'*A;
    [V,D] = eig(tau);
    ret = randn(T,1);
    t = 2;
    tol=1e-08;
    d =0.02;
    %%%%%%%%%%%%%%%%%%%  Douglas-Rouchford Splitting  %%%%%%%%%%%%%%%%%%%%
    alpha = 2;
    fprintf('Starting Solving using CVX for T = %d\n',T);
    tic;
    cvx_begin quiet
    variables w(T,1)
    minimize (norm(k_e_d*tau*w,2) - ret'*w)
    subject to
    w>=0;
    sum(w)==1;
    cvx_end
    time_cvx(i,1) = toc;
    fprintf('Starting Solving using Proximal Method using Douglas Rouchford Splitting for T = %d\n',T);
    tic;
    y_old = 6*ones(T,1)/T;
    y = 2*ones(T,1)/T;
    k=1;
    distance=1;
    rho = 1;
    for k=1:200
        y_old = y;
        x = ProxyOpLinCombL2(tau,y,T,t);
        y = y + rho*(ProxyOpLinSimpComb(2*x - y,ret,T,tol,t) - x );
        fprintf('Iteration = %d with err = %d\n',k,distance);
        distance = norm(y_old - y,2);
        obj_val = norm(tau*x,2) - ret'*x;
        err_doug(k,1) = (obj_val - cvx_optval)/cvx_optval;
    end
    time_doug(i,1) = toc;
    
 
    i=i+1;
end
fprintf('Finished.\n')
%%
%obj_val = norm(tau_sqrt*w,2) - ret'*w;
T = 100:100:1500

plot(T,time_doug);
hold on;
plot(T,time_cvx);
legend('Douglas Rouchford Splitting','CVX')
xlabel('Number of Dimensions')
ylabel('Time (seconds)')
save('time_doug.mat','time_doug')
%%
semilogy(abs(err_doug));
xlabel('$$ \boldmath{\mathrm{k} \ (Iterations)} $$','Interpreter','Latex');
str = '$$ \boldmath{\frac{f(x^k) - f(x^{\ast})}{f(x^{\ast})}} $$';
ylabel(str,'Interpreter','Latex');
title('Error Plot for Douglas Rachford for N = 500');
abs_doug=abs(err_doug);
save('err_doug.mat','abs_doug')