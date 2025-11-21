function rxBits = mppm_demod(rxSymbols, M, K, bitsPerSym)
% mppm_demod - robust MPPM demodulator (toolbox-free)
% rxSymbols: numSymbols x M (real amplitudes)
% M, K: modulation params
% bitsPerSym: number of bits per symbol (floor(log2(nchoosek(M,K))))
%
% Returns:
%  rxBits : column vector of recovered bits (length = numSymbols * bitsPerSym)

[numSymbols, Mchk] = size(rxSymbols);
if Mchk ~= M
    error('rxSymbols columns do not match M');
end

rxBits = zeros(numSymbols * bitsPerSym, 1);
combs = nchoosek(1:M, K);

% Number of bit patterns that are actually encoded per symbol
B = bitsPerSym;
twoPowB = 2^B;

for i = 1:numSymbols
    % select K largest slots (using sort for compatibility)
    [~, idxsSorted] = sort(rxSymbols(i,:), 'descend');
    selected = sort(idxsSorted(1:K)); % sorted indices of chosen slots

    % Find matching combination row
    match = ismember(combs, selected, 'rows');
    matchIdx = find(match, 1);
    if isempty(matchIdx)
        matchIdx = 1; % fallback (shouldn't happen under normal operation)
    end

    % Map matchIdx into 0..2^B-1 range so binary string is exactly B bits
    decVal = mod(matchIdx - 1, twoPowB);  % ensures 0 <= decVal < 2^B

    % Convert to B-bit binary (left-msb)
    bStr = dec2bin(decVal, B);   % string of length B
    bVec = bStr - '0';           % row vector of 0/1 length B

    rxBits((i-1)*B+1 : i*B) = bVec';  % assign column vector of length B
end
end

