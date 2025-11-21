% Day2_test_mppm.m - Test MPPM mod/demod without channel
clear; close all; clc;
rng(0);

% Parameters
Nbits = 1e4;            % number of random bits
bits = randi([0 1], Nbits, 1);

% Modulation settings
M = 8;     % number of slots
K = 2;     % number of pulses per symbol

% Modulate
[txSymbols, bitsPerSym] = mppm_mod(bits, M, K);
fprintf('MPPM: M=%d, K=%d, bitsPerSym=%d, numSymbols=%d\n', M, K, bitsPerSym, size(txSymbols,1));

% Demodulate (direct, no channel)
rxBits = mppm_demod(txSymbols, M, K, bitsPerSym);

% Trim transmitted bits to match demodulated length
txBitsTrim = bits(1:length(rxBits));

% Compute BER
BER = mean(txBitsTrim ~= rxBits);
fprintf('BER (no channel) = %g (expected 0)\n', BER);
