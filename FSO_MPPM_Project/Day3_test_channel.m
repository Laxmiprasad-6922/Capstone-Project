% Day3_test_channel.m - test FSO channel with MPPM (simple model)
clear; close all; clc;
rng(0);

% --- parameters ---
Nbits = 2e4;              % number of bits
bits = randi([0 1], Nbits, 1);

M = 8; K = 1;             % MPPM configuration (slots, pulses)
Ptx = 1;                  % transmit pulse amplitude (arbitrary units)
distance_km = 1;          % link distance in km
visibility = 2;           % km (try 20, 5, 2, 0.3 to compare)
noiseSigma = 0.08;        % AWGN std dev per slot

% --- modulate ---
[txSymbols, bitsPerSym] = mppm_mod(bits, M, K);
numSym = size(txSymbols,1);

% --- channel ---
rxSymbols = channel_fso(txSymbols, visibility, distance_km, Ptx, noiseSigma);

% --- demodulate ---
rxBits = mppm_demod(rxSymbols, M, K, bitsPerSym);

% --- compute BER ---
txBitsTrim = bits(1:length(rxBits));
BER = mean(txBitsTrim ~= rxBits);

fprintf('FSO channel test: visibility=%.2f km, noiseSigma=%.3f\n', visibility, noiseSigma);
fprintf('MPPM M=%d K=%d bitsPerSym=%d numSymbols=%d\n', M, K, bitsPerSym, numSym);
fprintf('BER after channel = %.6f\n', BER);

% Show first 5 rx symbol amplitudes for inspection
disp('First 5 received symbol amplitudes (rows):');
disp(rxSymbols(1:5,:));
