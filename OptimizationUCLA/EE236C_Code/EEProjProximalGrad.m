clc;
clear all;
close all;
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
i=1;
%%%%%%%%%%%%%%%%%%%%% Generating the Data %%%%%%%%%%%%%%%%%%%%%%%%%%
for T = 500
    A = randn(T,T);
    tau = A'*A;
    [V,D] = eig(tau);
    ret = randn(T,1);
    t = 1/eigs(tau,1);
    P=tau;
    tol=1e-08;
    d =0.02;
    tic;
    cvx_begin
    variable u(T,1)
    minimize (k_e_d*u'*tau*u - ret'*u)
    subject to
    u>=0;
    sum(u)==1;
    cvx_end
    time_cvx(i,1) = toc;
    x = ones(T,1);
    g_t_old =1;
    g_t_u = 1;
    g_t_u_norm = 2;
    k=1;
    err =1;
    tic;
   for k=1:200
        fprintf('Iteration = %d with err = %d\n ',k,err)
        grad_g = 2*k_e_d*tau*x-ret;
        prox_op = projsplx(x - t*grad_g);
        g_t_u = (x -prox_op)/t;
        beta=0.5;
%         t=1;    
%         while (funcValProxOp(prox_op,ret,D,k_e_d) - funcValProxOp(u,ret,D,k_e_d) + t*grad_g'*g_t_u - (0.5*t*norm(g_t_u,2)^2) -tol >0 && t>tol )
%             t = beta*t;
%             %fprintf('t = %d\n',t);
%         end
        x = prox_op;
        obj_val = x'*tau*x - ret'*x;
        err = (obj_val- cvx_optval);
        err_vec_prox(k,1) = (obj_val- cvx_optval)/cvx_optval;
    end
    time_proxy(i,1) = toc;
    i=i+1;
end
%%
T = 100:100:1500;
plot(T,time_proxy);
hold on;
plot(T,time_cvx);
legend('Proximal Gradient  Method','CVX')
xlabel('$$ n  $$ ','Interpreter','Latex')
ylabel('Time (seconds)')
save('time_proxy.mat','time_proxy')
%%
semilogy(abs(err_vec_prox));
xlabel('$$ k (\mathrm{Iterations})$$','Interpreter', 'Latex');
str = '$$ \frac{f(x) - f(x^{\ast)}}{f(x^{\ast)}} $$';
ylabel(str,'Interpreter','Latex');
title('Error Convergence for Proximal Gradient  for N = 500');
err_vec_prox=abs(err_vec_prox);
save('err_vec_prox.mat','err_vec_prox')