function [bb] = impartition(imsize, tilesize)
% Compute bounding boxes of tiles which evenly partition an image or matrix
% of any size and dimensionality. If the tile sizes are not even multiples
% of the image size, then the last row/column/page/etc of tiles will be
% rounded to perfectly fill the image.
%
% TO DO: 
% (see lines 118 and 119 for implementations) Add 3rd input argument to
% allow specification of how to handle tile rounding at image edges.
% Option 1 - underfill the image with tiles and grow the last dimension of
% tiles to fill remainder of image; Option 2 - overfill the image with
% tiles and truncate the last dimension of tiles to match total image
% size.
%
%
% INPUTS:
%
% 1. imsize - size of image to be partitioned, formatted as a 1-by-D array
%             of positive integers, where D is the dimensionality of the
%             image. The first element should specify how many rows compose
%             the image, the second element should specify the number of
%             columns that compose the image, and so on.
%
% 2. tilesize - size of the tiles you wish to partition the image with,
%               formatted as a 1-by-D array of positive integers where D is
%               the dimensionality of the tile. The first element should
%               specify how many rows will compose each tile, the second
%               element should specify how many columns will compose each
%               tile, and so on.
%
%
% OUTPUTS:
%
% 1. bb - bounding boxes that define the position and size of each tile,
%         formatted as an N-by-2*D matrix of positive integers, where N is
%         the total number of tiles and D is the dimensionality of the
%         input image and requested tile size. Each row defines the
%         bounding box or hyperrectangle of a tile, where the first
%         D-elements specify the minumum bounds of a tile along each
%         dimension (subscript ordering) and the last D-elements specify
%         the tile's length along each dimension, like the input of imcrop
%         or imcrop3. For example, given a 3D input image, each row of the
%         output matrix BB will look like
%         [rowMin,columnMin,pageMin,rowLength,columnLength,pageLength].
%         Rounding error of tile positions or sizes near the image edge is
%         handled by truncating the tiles in the last row/column/page/etc
%         to fit the remaining elements, so that all elements are
%         guaranteed to be captured within the set of all tiles, without
%         repeat.
%
% 
% AUTHORSHIP:
%
% Name: Andrew M. Soltisz
% Email: andysoltisz@gmail.com
%

    % -------------- INPUT VALIDATION --------------

    % Check for propper formatting of input IMSIZE
    imsize_errorMessage = "Input IMSIZE must be a row vector of positive integers.";
    if ~isnumeric(imsize)
        error(imsize_errorMessage);
    end
    if any(imsize < 1)
        error(imsize_errorMessage);
    end
    if ~isrow(imsize)
        error(imsize_errorMessage);
    end
    if any((round(imsize) - imsize) ~= 0) 
        error(imsize_errorMessage);
    end

    % Check for propper formatting of input TILESIZE
    tilesize_errorMessage = "Input TILESIZE must be a row vector of positive integers.";
    if ~isnumeric(tilesize)
        error(tilesize_errorMessage);
    end
    if any(tilesize < 1)
        error(tilesize_errorMessage);
    end
    if ~isrow(tilesize)
        error(tilesize_errorMessage);
    end
    if any((round(tilesize) - tilesize) ~= 0)
        error(tilesize_errorMessage);
    end


   % -------------- ALGORITHM --------------

    % Check dimensionality
    nDimensions = sum(imsize > 1);
    allDimensions = 1:nDimensions;
    if nDimensions == 1
        imsize(imsize == 1) = []; % enable tiling of 1D images
    end
    if any(size(tilesize) ~= size(imsize))
        error("Inputs IMSZIE and TILESIZE must have the same dimensionality.");
    end
    
    % Compute all options for tile minimum indices (tileMinOptions) and
    % tile lengths (tileLengthOptions) for each dimension, formatted as
    % N-by-D matrices, where 'N' is the max number of tiles along any
    % dimension and 'D' is the input image dimensionality. Each column
    % specfies an option for a tile's min/length along each dimension. For
    % example, given a 2D input image, the element at (1,1) specifies the
    % min-row/row-length for the first row of tiles; the element at (1,2)
    % specifies the min-column/column-length for the first column of tiles;
    % and element (2,1) specificies the min-row/row-length of the second
    % row of tiles; etc. Since tile size is arbitrary, the number of tiles
    % along each dimension can be different. Thus, the number of tile
    % options along each dimension is allowed to grow beyond what is needed
    % so that options for all dimensions can be stored in a simple 2D
    % matrix. The true last option along each dimension is tracked in
    % 'lastTile' so extra options can be ignored.
    % nTiles = round(imsize ./ tilesize, 'tiebreaker','tozero'); % compute number of tiles along each dimension. 'round' grows last tiles.
    nTiles = ceil(imsize ./ tilesize); % compute number of tiles along each dimension. 'ceil' truncates last tiles.
    nTilesMax = max(nTiles); % max number of tiles in any dimension
    tileIndices = 1:nTilesMax; % assign an index to each tile along a dimension
    optionSize = [nTilesMax, nDimensions]; % grab size of the tile option variables
    lastTiles = sub2ind(optionSize, nTiles, allDimensions); % find linear index of last tile option along each dimension
    tileSizeSeries =  tilesize .* repmat((tileIndices-1)', 1, nDimensions); % tile min/max subscripts are integer multiples of the tile size
    tileMinOptions = tileSizeSeries + 1; % compute min subscripts options
    tileMaxOptions = tileSizeSeries + tilesize; % compute max subscripts options
    tileMaxOptions(lastTiles) = imsize; % fit last tiles to image edges
    tileLengthOptions = tileMaxOptions - tileMinOptions + 1; % compute tile length options

    % Sample tile options to generate bounding boxes for all unique tiles
    optionCombinations = nchoosek(repmat(tileIndices,1,nDimensions), nDimensions); % compute all dimension-combinations of tile options
    optionCombinations(any(optionCombinations > nTiles, 2), :) = []; % remove combinations that exceed each dimension's tile count
    optionCombinations = unique(optionCombinations, 'rows'); % find all unique combinations of tile options
    optionCombinations = optionCombinations + ((0:nDimensions-1) .* nTilesMax); % convert subscripts to linear indices
    bb = [tileMinOptions(optionCombinations), tileLengthOptions(optionCombinations)]; % assemble tile bounds
    % bb = [tileMinOptions(optionCombinations), tileMaxOptions(optionCombinations)]; alternative output with max subscripts instead of lengths


end
