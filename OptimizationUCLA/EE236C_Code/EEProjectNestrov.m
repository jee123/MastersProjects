clc;
clear all;
close all;
i =1;
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
    L=eigs(tau,1);
    t = 1/L;
    eigen_val = eigs(tau,T);
    m = eigen_val(1);
    P=tau;
    tol=1e-08;
    d =0.02;
    x_k_1 = ones(T,1)/T;
    x_k_2 = 0;
    err=1;
    err_old =2 ;
    g_t_old =1;
    k=1;
    tic;
    fprintf('Solving using CVX for T = %d\n',T)
    cvx_begin
    variable u(T,1)
    minimize (norm(tau*u,2) - ret'*u)
    subject to
    u>=0;
    sum(u)==1;
    cvx_end
    time_cvx(i,1) = toc;
    fprintf('Solving using Nestrov for T = %d\n',T)
    tic;
    err=1;
   for k=1:200
        fprintf('Iteration = %d with err = %d\n ',k,err);
        y = x_k_1 + ((1-sqrt(m/L))/(1+sqrt(m/L)))*(x_k_1 - x_k_2);
        grad_g = 2*k_e_d*tau*y-ret;
        prox_op = projsplx(y - t*grad_g);
        x_k_2 = x_k_1;
        x = prox_op;
        x_k_1 = x;
        obj_val = x'*D*x - ret'*x;
        err = (obj_val- cvx_optval);
        err_vec_nestrov(k,1) = (obj_val- cvx_optval)/cvx_optval;
    end
     time_nest(i,1) = toc; 
     i=i+1;
end
%%
T = 100:100:1500;
plot(T,time_nest);
hold on;
plot(T,time_cvx);
legend('Simplest Nestrov Method','CVX')
xlabel('Number of Dimensions')
ylabel('Time (seconds)')
save('time_nest.mat','time_nest')
%%
semilogy(abs(err_vec_nestrov));
xlabel('$$ \textbf{k} $$','Interpreter', 'Latex');
str = '$$ \frac{f(x^k) - f(x^{\ast})}{f(x^{\ast})} $$';
ylabel(str,'Interpreter','Latex');
title('Error Convergence for Simplest Nestrov Method for N = 500');
err_vec_nestrov=abs(err_vec_nestrov);
save('err_vec_nestrov.mat','err_vec_nestrov')
