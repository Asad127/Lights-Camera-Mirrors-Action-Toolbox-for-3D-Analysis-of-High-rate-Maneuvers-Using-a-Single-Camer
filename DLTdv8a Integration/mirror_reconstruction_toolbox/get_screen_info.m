% ! THIS FUNCTION IS UNUSED ! %
function [x_res, y_res, x_ppi, y_ppi, dpi] = get_screen_info()
% Extract information on the user screen like the x and y resolution and
% dpi. This information lets us define the plots in proportion to the user 
% screen space.

% 0 is the root figure representing the full screen.
set(0,'units','pixels')
pixsize = get(0,'screensize');
set(0,'units','inches')
inchsize = get(0,'screensize');
ppi = pixsize ./ inchsize;

x_res = pixsize(3);
y_res = pixsize(4);
x_ppi = ppi(3);
y_ppi = ppi(4);

% In most displays, x_ppi = y_ppi (square pixels)
if x_ppi == y_ppi
    dpi = x_ppi;
else
    dpi = nan;
end

end

