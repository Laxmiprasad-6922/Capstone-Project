% Day5_adaptive_visibility.m
% Open-loop adaptation: choose (M,K) based on visibility (no feedback)
clear; close all; clc;
rng(0);

% Simulation parameters
visibility = 2;            % km (set this to test)
distance_km = 1;
Ptx = 1;
noiseSigma = 0.08;
useGG = true;              % true => gamma-gamma in channel_fso

% Frame parameters
frameBits = 2000;         % bits per frame
Nframes = 40;             % number of frames to send
Nbits = frameBits * Nframes;
bits = randi([0 1], Nbits, 1);

% Logs
chosenM = zeros(Nframes,1);
chosenK = zeros(Nframes,1);
BER_frame = zeros(Nframes,1);
throughput_frame = zeros(Nframes,1);

ptr = 1;
for f = 1:Nframes
    % choose M,K from visibility-based policy
    [M,K] = adapt_policy(visibility);
    chosenM(f) = M; chosenK(f) = K;

    % frame bits
    frameBitsVec = bits(ptr:ptr+frameBits-1);
    ptr = ptr + frameBits;

    % modulate
    [txSymbols, bitsPerSym] = mppm_mod(frameBitsVec, M, K);

    % channel
    rxSymbols = channel_fso(txSymbols, visibility, distance_km, Ptx, noiseSigma, useGG);

    % demodulate
    rxBits = mppm_demod(rxSymbols, M, K, bitsPerSym);

    % compute BER for frame and throughput
    txTrim = frameBitsVec(1:length(rxBits));
    ber = mean(txTrim ~= rxBits);
    BER_frame(f) = ber;
    throughput_frame(f) = bitsPerSym * (1 - ber);

    fprintf('Frame %2d: M=%2d K=%d bitsPerSym=%d BER=%.5f throughput=%.3f\n', ...
        f, M, K, bitsPerSym, ber, throughput_frame(f));
end

% Summary
fprintf('\nAverage BER = %.6f, Average throughput(bits/sym) = %.3f\n', mean(BER_frame), mean(throughput_frame));

% Plot adaptation trace and per-frame BER/throughput
figure;
subplot(3,1,1); plot(chosenM,'-o'); ylabel('M'); title(sprintf('Adaptation trace (visibility=%.2fkm)',visibility)); grid on;
subplot(3,1,2); plot(chosenK,'-x'); ylabel('K'); grid on;
subplot(3,1,3); semilogy(BER_frame,'-o'); ylabel('BER per frame'); xlabel('Frame index'); grid on;
saveas(gcf,'Day5_adapt_visibility_trace.png');

figure; plot(throughput_frame,'-o'); xlabel('Frame index'); ylabel('Throughput (bits/sym)'); grid on;
title('Throughput per frame'); saveas(gcf,'Day5_throughput_visibility.png');
