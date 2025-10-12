function [Aest, x, FF] = area_reconstruction_from_irf(Hvirf, ttm, A0, a0, g)
% AREA_RECONSTRUCTION_FROM_IRF Reconstructs pipe area from Impulse Response Function (IRF)
% 
% Inputs:
%   Hvirf: Impulse Response Function at the valve (vector)
%   ttm: Time of measurement of the IRF (vector)
%   A0: Area of the pipe at the valve (scalar, m²)
%   a0: Wave speed (scalar, m/s)
%   g: Gravitational acceleration (scalar, m/s², e.g., 9.81)
%
% Outputs:
%   Aest: Estimated pipe area (vector, m²)
%   x: Spatial range over which the area was estimated (vector, m)
%   FF: Optional matrix storing intermediate solutions (for debugging)
%
% Example:
%   % Sample data
%   ttm = (0:0.01:0.99)'; % 100 time points
%   Hvirf = sin(2*pi*5*ttm) + 0.1*randn(size(ttm)); % Simulated IRF
%   A0 = 0.01; % Pipe area at valve (m²)
%   a0 = 1000; % Wave speed (m/s)
%   g = 9.81;  % Gravity (m/s²)
%   [Aest, x, FF] = area_reconstruction_from_irf(Hvirf, ttm, A0, a0, g);
%   % Plot results
%   plot(x, Aest, 'b-', 'LineWidth', 2); xlabel('Position (m)'); ylabel('Area (m²)');

% Input validation
if size(Hvirf, 2) ~= 1
    Hvirf = Hvirf';
end
if size(ttm, 2) ~= 1
    ttm = ttm';
end
if length(Hvirf) ~= length(ttm)
    error('Error: Dimensions of Hvirf and ttm must be the same.')
end
if ~isscalar(A0) || ~isscalar(a0) || ~isscalar(g)
    error('Error: A0, a0, and g must be scalars.')
end
if g <= 0 || A0 <= 0 || a0 <= 0
    error('Error: g, A0, and a0 must be positive.')
end

% Parameters
Z0 = a0 / (g * A0);
dtm = ttm(2) - ttm(1);

% Compute h from IRF
h = Hvirf / Z0;

% Discretize integral operator kernel
smax = length(h) - 1;
Hm = zeros(1+smax, 1+smax); % Preallocate for efficiency
for s = 0:smax
    for t = 0:smax
        Hm(1+t, 1+s) = h(1+abs(t-s));
    end
end

% Solve inverse problem for V(t)
if nargout > 2
    FF = NaN(1+2*floor(smax/2), floor(smax/2)+1); % Optional output
end
V = NaN(1+smax, 1);
t_start = cputime;

for r = 0:smax
    M = Hm(1:1+r, 1:1+r) * dtm / 2;
    f = (eye(1+r) + M) \ ones(1+r, 1) / Z0;
    if nargout > 2
        FF(1:1+r, 1+r) = f;
    end
    V(1+r) = sum(f) * dtm / 2;
    
    % Progress display (optional, can be commented out)
    % fprintf('Progress: %d%%\n', round(100 * r / smax));
end

% Compute estimated area and spatial range
dxm = dtm * a0;
Aest = (a0 / g) * (V(2:1+smax) - V(1:smax)) * (2 / dtm);
x = (dxm / 2) * (2:smax+1)';
end
