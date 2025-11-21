% Day4_test_gamma.m - Test gamma-gamma channel model
clear; close all; clc;
rng(0);

% params
Nbits = 2e4;
bits = randi([0 1], Nbits, 1);
M = 8; K = 2;
Ptx = 1;
distance_km = 1;
visibility = 2;   % try 20,10,5,2,1,0.5,0.3
noiseSigma = 0.08;

% modulate
[txSymbols, bitsPerSym] = mppm_mod(bits, M, K);

% channel using gamma-gamma
rxSymbols_gg = channel_fso(txSymbols, visibility, distance_km, Ptx, noiseSigma, true);
rxBits_gg = mppm_demod(rxSymbols_gg, M, K, bitsPerSym);
BER_gg = mean(bits(1:length(rxBits_gg)) ~= rxBits_gg);

% channel using log-normal for comparison
rxSymbols_ln = channel_fso(txSymbols, visibility, distance_km, Ptx, noiseSigma, false);
rxBits_ln = mppm_demod(rxSymbols_ln, M, K, bitsPerSym);
BER_ln = mean(bits(1:length(rxBits_ln)) ~= rxBits_ln);

fprintf('Visibility %.2f km: BER (gamma-gamma)=%.6f, BER (log-normal)=%.6f\n', visibility, BER_gg, BER_ln);

% show a few rows
disp('First 5 rx symbols (gamma-gamma):'); disp(rxSymbols_gg(1:5,:));
disp('First 5 rx symbols (log-normal):'); disp(rxSymbols_ln(1:5,:));
