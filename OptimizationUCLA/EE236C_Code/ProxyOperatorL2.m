function val = ProxyOperatorL2(u,t)
if(norm(u,2)>=t)
    val=(1 - t/norm(u,2))*u;
else
    val = zeros(length(u),1);
end;