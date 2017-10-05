function H = getHOGDescriptor(img)
{
  numBins = 9;
  cellSize = 8;
  H = [];

  [height, width] = size(img);
  if ((width ~= 66) || (height ~= 130))
      disp("Image size must be 130 x 66 pixels (128x64 with 1px border).\n");
      return;
  end

  numHorizCells = 8;
  numVertCells = 16;

  hx = [-1,0,1];
  hy = hx;

  dx = imfilter(double(img), hx);
  dy = imfilter(double(img), hy);

  dx = dx(2 : (size(dx, 1) - 1), 2 : (size(dx, 2) - 1));
  dy = dy(2 : (size(dy, 1) - 1), 2 : (size(dy, 2) - 1));

  angles = atan2(dy, dx);
  magnit = ((dy.^2) + (dx.^2)).^.5;

  histograms = zeros(numVertCells, numHorizCells, numBins);
  img = double(img);

  for row = 0:(numVertCells - 1)
      rowOffset = (row * cellSize) + 1;
      for col = 0:(numHorizCells - 1)
          colOffset = (col * cellSize) + 1;
          rowIndeces = rowOffset : (rowOffset + cellSize - 1);
          colIndeces = colOffset : (colOffset + cellSize - 1);
          cellAngles = angles(rowIndeces, colIndeces);
          cellMagnitudes = magnit(rowIndeces, colIndeces);
      histograms(row + 1, col + 1, :) = getHistogram(cellMagnitudes(:), cellAngles(:), numBins);
      end
  end

  % BLOCK NORMALISATION
  for row = 1:(numVertCells - 1)
   for col = 1:(numHorizCells - 1)
          blockHists = histograms(row : row + 1, col : col + 1, :);
          magnitude = norm(blockHists(:)) + 0.01;
          normalized = blockHists / magnitude;
          H = [H; normalized(:)];
      end
  end
  end
}
