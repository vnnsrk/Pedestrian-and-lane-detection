% Histogram generator
% By Srinath

function H = getHistogram(magnitudes, angles, numBins)

% GETHISTOGRAM Computes a histogram for the supplied gradient vectors.
%   Parameters:
%     magnitudes - A column vector storing the magnitudes of the gradient
%                  vectors.
%     angles     - A column vector storing the angles in radians of the
%                  gradient vectors (ranging from -pi to pi)
%     numBins    - The number of bins to place the gradients into.
%   Returns:
%     A row vector of length 'numBins' containing the histogram.

binSize = pi / numBins;
minAngle = 0;
angles(angles < 0) = angles(angles < 0) + pi;

leftBinIndex = round((angles - minAngle) / binSize);
rightBinIndex = leftBinIndex + 1;

leftBinCenter = ((leftBinIndex - 0.5) * binSize) - minAngle;

rightPortions = angles - leftBinCenter;
leftPortions = binSize - rightPortions;
rightPortions = rightPortions / binSize;
leftPortions = leftPortions / binSize;

leftBinIndex(leftBinIndex == 0) = numBins;
rightBinIndex(rightBinIndex == (numBins + 1)) = 1;

H = zeros(1, numBins);

% For each bin, do
for (i = 1:numBins)
    pixels = (leftBinIndex == i);

    H(1, i) = H(1, i) + sum(leftPortions(pixels)' * magnitudes(pixels));

    pixels = (rightBinIndex == i);

    H(1, i) = H(1, i) + sum(rightPortions(pixels)' * magnitudes(pixels));
end

end
