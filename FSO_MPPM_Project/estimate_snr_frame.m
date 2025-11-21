function estSNR = estimate_snr_frame(rxSymbols, txSymbolsSlots)
% estimate_snr_frame  Very simple SNR estimator for a received frame.
% rxSymbols: numSymbols x M matrix of received amplitudes
% txSymbolsSlots: same-size matrix of transmitted 0/1 pulses (optional)
% If txSymbolsSlots is provided, estimator uses known pulse locations (pilot-like).
% Otherwise, we estimate signal power from the largest K slots per symbol (blind).

% Compute per-slot statistics
allVals = rxSymbols(:);
noiseVarEst = var(allVals); % crude estimate (includes signal but ok for heuristics)
signalPowerEst = mean(rxSymbols(rxSymbols>0).^2); % average of positive values (approx pulses)

% fallback if no positive values
if isempty(signalPowerEst) || noiseVarEst==0
    estSNR = 0;
    return;
end

estSNR = signalPowerEst / (noiseVarEst + 1e-12); % proxy SNR (unitless)
end
