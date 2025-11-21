% Day5_adaptive_snr_closedloop.m
% Closed-loop frame adaptation: receiver estimates SNR and transmitter adjusts M/K
clear; close all; clc;
rng(0);

% Basic sim params
visibility = 2;        % km; initial environmental condition (can change across frames)
distance_km = 1;
Ptx = 1;
noiseSigma = 0.08;
useGG = true;

% Frame params
frameBits = 2000;
Nframes = 60;
Nbits = frameBits * Nframes;
bits = randi([0 1], Nbits, 1);

% Adaptation thresholds (experiment / tune)
% Decide target SNR ranges (proxy values) where different M/K are allowed
% These thresholds are on the estSNR metric produced by estimate_snr_frame.
SNR_thresh_high = 1.5;   % > -> try higher M
SNR_thresh_low  = 0.3;   % < -> reduce M or increase K

% Starting mode
curM = 8; curK = 2;

% Logs
chosenM = zeros(Nframes,1);
chosenK = zeros(Nframes,1);
BER_frame = zeros(Nframes,1);
throughput_frame = zeros(Nframes,1);
estSNR_log = zeros(Nframes,1);

ptr = 1;
for f = 1:Nframes
    chosenM(f) = curM; chosenK(f) = curK;

    % frame bits
    frameBitsVec = bits(ptr:ptr+frameBits-1);
    ptr = ptr + frameBits;

    % modulate
    [txSymbols, bitsPerSym] = mppm_mod(frameBitsVec, curM, curK);

    % channel
    rxSymbols = channel_fso(txSymbols, visibility, distance_km, Ptx, noiseSigma, useGG);

    % receiver estimates SNR from rxSymbols (blind estimator)
    estSNR = estimate_snr_frame(rxSymbols);
    estSNR_log(f) = estSNR;

    % demodulate and compute BER
    rxBits = mppm_demod(rxSymbols, curM, curK, bitsPerSym);
    txTrim = frameBitsVec(1:length(rxBits));
    ber = mean(txTrim ~= rxBits);
    BER_frame(f) = ber;
    throughput_frame(f) = bitsPerSym * (1 - ber);

    fprintf('Frame %2d: M=%2d K=%d estSNR=%.3f BER=%.5f thrpt=%.3f\n', f, curM, curK, estSNR, ber, throughput_frame(f));

    % CLOSED-LOOP ADAPTATION RULE (simple hysteresis)
    % If estSNR is high -> try to increase M (higher bitsPerSym) for next frame
    if estSNR > SNR_thresh_high
        % increase spectral efficiency: attempt doubling M up to 32, keep K small
        if curM < 32
            curM = min(32, curM*2);
            curK = max(1, curK); % prefer fewer pulses
        end
    elseif estSNR < SNR_thresh_low
        % poor channel -> reduce M or increase K to add energy
        if curK < curM-1
            curK = min(curM-1, curK+1); % add pulses to boost energy
        else
            curM = max(4, curM/2);
            curK = min(curK, curM-1);
        end
    else
        % stable region: keep current mode (or minor up/down adjustments)
        % optional: small upward adjustment if below target BER
    end
    % enforce valid integer values
    curM = round(curM); curK = round(curK);
    if curK >= curM; curK = max(1, curM-1); end
end

% Summary
fprintf('\nAvg BER = %.6f, Avg throughput(bits/sym) = %.3f\n', mean(BER_frame), mean(throughput_frame));

% Plots
figure;
subplot(3,1,1); plot(chosenM,'-o'); ylabel('M'); title('Closed-loop adaptation trace'); grid on;
subplot(3,1,2); plot(chosenK,'-x'); ylabel('K'); grid on;
subplot(3,1,3); semilogy(BER_frame,'-o'); ylabel('BER'); xlabel('Frame'); grid on;
saveas(gcf,'Day5_adapt_snr_trace.png');

figure; plot(estSNR_log,'-o'); xlabel('Frame'); ylabel('Estimated SNR (proxy)'); grid on;
title('Estimated SNR per frame'); saveas(gcf,'Day5_estSNR_trace.png');

figure; plot(throughput_frame,'-o'); xlabel('Frame'); ylabel('Throughput (bits/sym)'); grid on;
title('Throughput per frame'); saveas(gcf,'Day5_throughput_snr.png');
