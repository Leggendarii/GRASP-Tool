figs = findall(0, 'Type', 'figure');

% Se ci sono più di 4, prendi le ultime 4
if numel(figs) > 4
    figs = figs(end-3:end);
end

figs = sort(figs);  % ordina per numero di figura

screenSize = get(0, 'ScreenSize');

w = floor(screenSize(3) / 2);
h = floor(screenSize(4) / 2);

positions = [
    0,  h, w, h;  
    w,  h, w, h;  
    0,  0, w, h;  
    w,  0, w, h;  
];

n = numel(figs);
for i = 1:n
    set(figs(i), 'Units', 'pixels', 'OuterPosition', positions(i,:));
end
