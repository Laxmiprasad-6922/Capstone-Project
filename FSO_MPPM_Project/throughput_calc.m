function thr = throughput_calc(bitsPerSym, BER)
% throughput_calc - effective throughput measure (bits per symbol)
% bitsPerSym: bits encoded per symbol (scalar)
% BER: bit error rate (scalar or vector)
% Output thr: effective correct bits per symbol (same size as BER)
thr = bitsPerSym .* (1 - BER);
end
