function prox = ProxyOperatorLinearCombL2(D,x,T,t)
cvx_begin quiet
variables u(T,1)
minimize (t*norm(D*u,2) + 0.5*u'*u - u'*x + 0.5*x'*x)
subject to 
u>=0;
sum(u)==1;
cvx_end
prox = u;