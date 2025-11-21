function fading = gamma_gamma_fading(visibility_km, distance_km, wavelength_m)
% Robust gamma-gamma fading generator for simulation
% Returns a positive scalar fading factor with mean ~1 and bounded tails.
% Usage: f = gamma_gamma_fading(vis_km, dist_km, wavelength_m)
if nargin < 3
    wavelength_m = 1550e-9;
end

% --- 1) Map visibility -> approximate Cn2 (heuristic) ---
if visibility_km >= 10
    Cn2 = 1e-15;
elseif visibility_km >= 2
    Cn2 = 5e-14;
elseif visibility_km >= 0.5
    Cn2 = 5e-13;
else
    Cn2 = 2e-12;
end

% meters
L = max(distance_km * 1000, 1);

% --- 2) Conservative Rytov variance approx ---
k = 2*pi / wavelength_m;
sigmaR2 = 0.5 * (k^(7/6)) * Cn2 * (L^(11/6));
sigmaR2 = max(min(sigmaR2, 10), 1e-6);

% --- 3) Map sigmaR2 -> alpha,beta but enforce reasonable minimums ---
alpha = (exp(0.49 * sigmaR2)) / (1 + 0.18 * sigmaR2);
beta  = (exp(0.51 * sigmaR2)) / (1 + 0.20 * sigmaR2);

% enforce minimum shape to avoid heavy tails
alpha = max(alpha, 1.0);
beta  = max(beta, 1.0);

% --- 4) Sample two gamma RVs with mean 1 ---
% Use gamrnd if available (Statistics Toolbox). If not, use a numerically stable fallback.
useGamrnd = exist('gamrnd','file') == 2;

if useGamrnd
    % gamma(shape, scale) with scale = 1/shape gives mean 1
    x = gamrnd(alpha, 1/alpha);
    y = gamrnd(beta, 1/beta);
else
    % Fallback: draw gamma by summing exponentials using shape as integer + fractional handling
    % This fallback is approximate but robust.
    x = sample_gamma_fallback(alpha);
    y = sample_gamma_fallback(beta);
end

fading_raw = x .* y;

% --- 5) Clip extreme outliers and (optionally) renormalize ---
% Clip to a reasonable maximum (e.g., 10). You can lower this if desired.
MAX_FADING = 10;
fading = min(fading_raw, MAX_FADING);

% Optional: small renormalization to make mean ~1 across repeated draws is left out here
% because sampling with shapes >=1 already provides mean near 1.
end

function g = sample_gamma_fallback(shape)
% Simple, robust gamma sampler (approximate) for non-integer shape
% Uses Marsaglia and Tsang method when shape >= 1, otherwise uses boost
if shape >= 1
    % Marsaglia & Tsang (standard method)
    d = shape - 1/3;
    c = 1 / sqrt(9*d);
    while true
        x = randn();
        v = (1 + c*x)^3;
        if v <= 0
            continue;
        end
        u = rand();
        if u < 1 - 0.0331*(x^4)
            g = d * v; break;
        end
        if log(u) < 0.5*x^2 + d*(1-v+log(v))
            g = d * v; break;
        end
    end
    % scale to mean 1 -> divide by shape
    g = g / shape;
else
    % shape < 1 -> use method based on boosting to shape+1 then multiply by U^(1/shape)
    % but our code enforces shape>=1 above, so this branch is unlikely.
    g = 1; % fallback safe value
end
end

