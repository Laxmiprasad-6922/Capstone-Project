% Day3_sweep_visibility_correct.m
clear; close all; clc;
rng(0);

% ---------- PARAMETERS ----------
vis_list = [2 1 0.5 0.2];    % visibility values
Nbits = 30000;               % bits
M = 8; K = 2;                % modulation
Ptx = 1;                     % transmit power
distance_km = 1;
noiseSigma = 0.02;           % noise
useGammaGamma = false;       % stable results

BERs = zeros(size(vis_list));

% ---------- MAIN LOOP ----------
for vi = 1:length(vis_list)

    visibility = vis_list(vi);

    % generate bits
    bits = randi([0 1], Nbits, 1);

    % modulate
    [txSymbols, bitsPerSym] = mppm_mod(bits, M, K);

    % channel
    rxSymbols = channel_fso(txSymbols, visibility, distance_km, Ptx, noiseSigma, useGammaGamma);

    % demodulate
    rxBits = mppm_demod(rxSymbols, M, K, bitsPerSym);

    % trim lengths
    L = min(length(rxBits), length(bits));

    BERs(vi) = mean(bits(1:L) ~= rxBits(1:L));

    fprintf("Visibility %.2f km → BER = %.6f\n", visibility, BERs(vi));
end

% ---------- PLOT (same style as your FIRST graph) ----------
figure;
semilogy(vis_list, BERs, "-o", "LineWidth", 1.4, "MarkerSize", 8);
grid on;
xlabel("Visibility (km)");
ylabel("BER");
title(sprintf("BER vs Visibility (M=%d,K=%d, noise=%.3f)", M, K, noiseSigma));
set(gca,"XDir","reverse");   % makes low visibility (fog) on the right



