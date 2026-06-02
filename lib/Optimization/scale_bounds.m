function [us, ls, u0s, scaleFcn, unscaleFcn] = scale_bounds(u, l, u0)

    u  = u(:);
    l  = l(:);
    u0 = u0(:);

    if any(u <= l)
        error('Ogni elemento di u deve essere > di l.');
    end

    if any(u0 < l) || any(u0 > u)
        error('u0 deve stare dentro i bound fisici.');
    end

    span = u - l;

    scaleFcn   = @(x) (x - l) ./ span;
    unscaleFcn = @(xs) l + xs .* span;

    ls  = zeros(size(l));
    us  = ones(size(u));
    u0s = scaleFcn(u0);

end