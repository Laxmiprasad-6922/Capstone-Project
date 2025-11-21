function [symbols, bitsPerSym] = mppm_mod(bits, M, K)
% mppm_mod - simple MPPM modulator (no toolboxes required)
% [symbols, bitsPerSym] = mppm_mod(bits, M, K)
% bits: column vector of 0/1
% M: number of time slots per symbol
% K: number of pulses per symbol (K <= M)
% symbols: numSymbols x M matrix of 0/1
% bitsPerSym: how many bits are encoded per MPPM symbol

if K > M
    error('K must be <= M');
end

nComb = nchoosek(M, K);
bitsPerSym = floor(log2(nComb));
if bitsPerSym < 1
    error('Too few combinations: increase M or K');
end

numSymbols = floor(length(bits) / bitsPerSym);
symbols = zeros(numSymbols, M);

% list all combinations (each row: indices of pulses)
combs = nchoosek(1:M, K);
nCombsAvail = size(combs,1);

% weight vector for left-msb conversion
weights = 2.^(bitsPerSym-1:-1:0);

for i = 1:numSymbols
    chunk = bits((i-1)*bitsPerSym+1 : i*bitsPerSym)'; % row vector
    idx0 = sum(double(chunk) .* weights); % 0 .. 2^B-1
    idx = idx0 + 1; % convert to 1-based index
    if idx > nCombsAvail
        idx = mod(idx-1, nCombsAvail) + 1; % wrap if exceeds
    end
    symbols(i, combs(idx,:)) = 1;
end
end
