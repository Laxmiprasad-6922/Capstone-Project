% main_FSO_MPPM.m - Day 1 starter: generate bits and print sample
clear; close all; clc;

% For reproducible results
rng(0);

% Basic parameters
Nbits = 1e4;            % total number of random bits to generate
bits = randi([0 1], Nbits, 1);  % column vector of bits

% Display some basic info and the first 20 bits
fprintf('Generated %d random bits.\n', Nbits);
fprintf('First 20 bits (row vector):\n');
disp(bits(1:20)');

% Quick check: basic stats
numOnes = sum(bits);
numZeros = Nbits - numOnes;
fprintf('Number of ones: %d, Number of zeros: %d (ratio ones/N = %.3f)\n', numOnes, numZeros, numOnes/Nbits);

% Show variable list in workspace
whos bits;
