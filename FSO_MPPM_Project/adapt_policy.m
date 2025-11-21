function [M,K] = adapt_policy(visibility_km)
% adapt_policy  Simple visibility-based adaptation mapping
% Returns M (slots) and K (pulses) for given visibility (km).
% Tweak thresholds to get desired spectral efficiency / robustness tradeoff.

if visibility_km >= 15
    M = 32; K = 1;    % high-order PPM (high throughput)
elseif visibility_km >= 8
    M = 16; K = 1;
elseif visibility_km >= 3
    M = 8;  K = 1;
elseif visibility_km >= 1
    M = 8;  K = 2;    % more pulses -> more energy per symbol (robust)
elseif visibility_km >= 0.5
    M = 4;  K = 2;
else
    M = 4;  K = 3;    % very robust low-modulation mode (low throughput)
end
end
