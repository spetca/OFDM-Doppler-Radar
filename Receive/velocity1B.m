function [OmegaV, disp] = velocity1B(Hrx,k,l)
    N = size(Hrx,1);
    M = size(Hrx,2);
    dd = zeros(l,1);
    OmegaV = zeros(k,1); 
    R = complex(zeros(l,l)); 

    for n = 34
        y = Hrx(n,:); 
        y = y(:);
        for i = l:M
            R=R+y(i:-1:i-l+1)*y(i:-1:i-l+1)';
        end
        R = R/(M-l);
        [U,D,V]=svd(R);
        S=U(:,1:k);

        dd = dd + diag(D) ;
        phi = S(1:l-1,:)\S(2:l,:);

        OmegaV=OmegaV-(angle(eig(phi)));
        R = complex(zeros(l,l)); 

      
    end
 %if second lambda is at least 20% of direct path display
    if( 20*log10(dd(2)) > -30)
        disp = 1;
    else
        disp = 0;
    end
    OmegaV = OmegaV/1;
end