function proxy_op = ProxyOpLinCombL2(tau,x,T,t_inner)
proj = ProjectOnEllipse(tau,T,x/t_inner);
proxy_op = x - t_inner*proj;
% [V,D] = eig(tau);
% cvx_begin quiet
% variables u(T,1)
% minimize (norm(D*u,2) + 0.5*u'*u - u'*x + 0.5*x'*x);
% cvx_end
% proxy_op = u;