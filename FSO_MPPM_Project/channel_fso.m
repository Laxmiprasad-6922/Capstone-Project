function rxSymbols = channel_fso(txSymbols, visibility_km, distance_km, Ptx, noiseSigma, useGammaGamma)
% channel_fso  FSO channel with optional gamma-gamma turbulence
% rxSymbols = channel_fso(txSymbols, visibility_km, distance_km, Ptx, noiseSigma, useGammaGamma)
% useGammaGamma: boolean (true->use gamma-gamma, false->use log-normal)
if nargin < 6
    useGammaGamma = true; % default to gamma-gamma on Day 4
end

% --- 1) Attenuation (Kruse approx) ---
vis = max(visibility_km, 0.01);
alpha_dB_per_km = 3.912 ./ vis;
total_dB_loss = alpha_dB_per_km .* distance_km;
atten_lin = 10.^(-total_dB_loss/10);

[numSym, M] = size(txSymbols);
rxSymbols = zeros(size(txSymbols));

% choose wavelength default for gamma-gamma mapping
wavelength_m = 1550e-9;

for i = 1:numSym
    if useGammaGamma
        % gamma-gamma multiplicative fading scalar
        fading = gamma_gamma_fading(visibility_km, distance_km, wavelength_m);
    else
        % fallback: log-normal small-scale fading (older model)
        if visibility_km >= 10
            sigma_ln = 0.05;
        elseif visibility_km >= 2
            sigma_ln = 0.20;
        elseif visibility_km >= 0.5
            sigma_ln = 0.4;
        else
            sigma_ln = 0.6;
        end
        fading = exp(sigma_ln * randn());
    end

    % apply tx amplitude, attenuation and fading
    rx = (txSymbols(i,:) .* Ptx) * atten_lin * fading;

    % AWGN per slot
    rx = rx + noiseSigma * randn(1, M);

    rxSymbols(i, :) = rx;
end
end

