function proxy_op = ProxyOpLinSimpComb(x,ret,T,tol,t_dr)
u = zeros(T,1)/T;
t = 1;
g_t_u =1;
while(g_t_u>=tol)
    grad_g = u - (x + t_dr*ret);
    proxy_operator = SimplexProj(u - t*grad_g);
    g_t_u = (u - proxy_operator)/t;
    beta=0.5;
    t=1;
    while (funcVal(proxy_operator,x,ret,t_dr) - funcVal(u,x,ret,t_dr) + t*grad_g'*g_t_u - (0.5*t*norm(g_t_u,2)^2)>tol)
        t = beta*t;
        fprintf('t = %f\n',t)
    end
    u = proxy_operator;
end
proxy_op = u;