function idx = closest_to_left_semicircle(Eigvec)
% Indice nel vettore complesso E più vicino alla semicirconferenza 
% sinistra unitaria (da -i a i via -1).

theta = linspace(2*pi/3, 4*pi/3, 1000);  % Alta risoluzione
semicircle = exp(1i * theta);

dists_to_semi = min(abs(Eigvec(:) - semicircle), [], 2);
[~, idx] = min(dists_to_semi);

end

