function writeTriangleMeshPly(outputFile, xyz, faces, varargin)
%% Write a PLY mesh file with optional normals, UVs, and colors.
%
% writeTriangleMeshPly(outputFile, xyz, faces) writes a new Stanford
% Polygon file, aka PLY, at the given outputFile.  The given xyz must
% be a 3xn matrix of XYZ positions for n vertices.  The given faces must
% be a 3xm matrix of 1-based triangle indices, where each index indicates a
% column of the given positions.
%
% Here's a simple example with 4 vertices arranged like the corners of a
% square in the XY-plane, and two triangle faces that join the vertices
% into a planar mesh:
%   xyz = [0 0 0; 0 0 1; 0 1 1; 0 1 0]';
%   faces = [0 1 3; 1 2 3]';
%   writeTriangleMeshPly('mySquare.ply', xyz, faces);
%
% The output would look like this:
%     ply
%     format ascii 1.0
%     element vertex 4
%     property float32 x
%     property float32 y
%     property float32 z
%     element face 2
%     property list uint8 int32 vertex_index
%     end_header
%     0 0 0
%     0 1 0
%     1 1 0
%     1 0 0
%     3 0 1 3
%     3 1 2 3
%
% writeTriangleMeshPly( ... 'normals', normals) specifies a 3xn matrix of
% XYZ normals for each vertex, to include along with the xyz position data.
%
% writeTriangleMeshPly( ... 'uvs', uvs) specifies a 2xn matrix of
% UV texture coordinates for each vertex, to include along with the xyz
% position data.  UV values should be provided in the range [0 1].
%
% writeTriangleMeshPly( ... 'colors', colors) specifies a 3xn matrix of
% RGB color values for each vertex, to include along with the xyz position
% data.  RGB values should be provided in the range [0 1].
%
% writeTriangleMeshPly( ... 'format', format) specifies the encoding of the
% output file.  The default is 'ascii', which produces a human-readable
% ASCII text file.  There are two alternative encodings:
% 'binary_little_endian' and 'binary_big_endian'.  The binary encodings are
% not human-readable but should enjoy higher floating point precision,
% smaller file size, and faster writing and loading times.
%
% Here's a full example with the same square geometry as above, plus
% normals facing up the z-axis, simple UV mapping, and colorful corners:
%   xyz = [0 0 0; 0 1 0; 1 1 0; 1 0 0]';
%   faces = [0 1 3; 1 2 3]';
%   normals = [1 1 1; 1 1 1; 1 1 1;]';
%   uvs = [0 0; 0 1; 1 1; 1 0];
%   colors = [1 0 0; 0 1 0; 0 0 1; 0.5 0.5 0.5]';
%   writeTriangleMeshPly('mySquare.ply', xyz, faces, ...
%       'normals', normals, ...
%       'uvs', uvs, ...
%       'colors', colors, ...
%       'format', 'ascii', ...);
%
% The output would look like this:
%     ply
%     format ascii 1.0
%     element vertex 4
%     property float32 x
%     property float32 y
%     property float32 z
%     property float32 nx
%     property float32 ny
%     property float32 nz
%     property float32 u
%     property float32 v
%     property float32 red
%     property float32 green
%     property float32 blue
%     element face 2
%     property list uint8 int32 vertex_index
%     end_header
%     0 0 0     1 1 1   0 0     1 0 0
%     0 1 0     1 1 1   0 1     0 1 0
%     1 1 0     1 1 1   1 1     0 0 1
%     1 0 0     1 1 1   1 0     0.5 0.5 0.5
%     3 0 1 3
%     3 1 2 3
%
%   writeTriangleMeshPly(outputFile, xyz, faces, varargin)
%
% BSH

parser = inputParser();
parser.addRequired('outputFile', @ischar);
parser.addRequired('xyz', @(n) isnumeric(n) && 3 == size(n, 1));
parser.addRequired('faces', @(n) isnumeric(n) && 3 == size(n, 1));
parser.addParameter('normals', zeros(3,0), @(n) isnumeric(n) && 3 == size(n, 1));
parser.addParameter('uvs', zeros(3,0), @(n) isnumeric(n) && 2 == size(n, 1));
parser.addParameter('colors', zeros(3,0), @(n) isnumeric(n) && 3 == size(n, 1));
parser.addParameter('format', 'ascii', ...
    @(s) ischar(s) && any(strcmp({'ascii', 'binary_little_endian', 'binary_big_endian'}, s)));
parser.parse(outputFile, xyz, faces, varargin{:});
outputFile = parser.Results.outputFile;
xyz = parser.Results.xyz;
faces = parser.Results.faces;
normals = parser.Results.normals;
uvs = parser.Results.uvs;
colors = parser.Results.colors;
format = parser.Results.format;

%% Try to close the file even if there's an error.
fid = [];
try
    if isnumeric(outputFile)
        fid = outputFile;
    else
        fid = fopen(outputFile, 'w', 'ieee-le', 'UTF-8');
    end
    
    % go write the file
    printPly(fid, xyz, faces, normals, uvs, colors, format);
    
catch err
    % close the file, even if there's an error
    %   too bad we can't have a try/catch/finally block!
    if isscalar(fid) && fid > 2
        fclose(fid);
    end
    rethrow(err);
end

% close the file on success
if isscalar(fid) && fid > 2
    fclose(fid);
end

%% Print our a PLY file to the given file.
function printPly(fid, xyz, faces, normals, uvs, colors, format)

nVertices = size(xyz, 2);
nFaces = size(faces, 2);

%% Write the PLY header, which is always text.
fprintf(fid, 'ply\n');
fprintf(fid, 'format %s 1.0\n', format);

fprintf(fid, 'element vertex %d\n', nVertices);
fprintf(fid, 'property float32 x\n');
fprintf(fid, 'property float32 y\n');
fprintf(fid, 'property float32 z\n');

hasNormals = nVertices == size(normals, 2);
if hasNormals
    fprintf(fid, 'property float32 nx\n');
    fprintf(fid, 'property float32 ny\n');
    fprintf(fid, 'property float32 nz\n');
end

hasUVs = nVertices == size(uvs, 2);
if hasUVs
    fprintf(fid, 'property float32 u\n');
    fprintf(fid, 'property float32 v\n');
end

hasColors = nVertices == size(colors, 2);
if hasColors
    fprintf(fid, 'property float32 red\n');
    fprintf(fid, 'property float32 green\n');
    fprintf(fid, 'property float32 blue\n');
end

fprintf(fid, 'element face %d\n', nFaces);
fprintf(fid, 'property list uint32 uint32 vertex_index\n');
fprintf(fid, 'end_header\n');

%% Organize the data into a big array we can march through.
vertexData = xyz;
asciiFormat = '%f %f %f';

if hasNormals
    vertexData = [vertexData; normals];
    asciiFormat = [asciiFormat, '\t%f %f %f'];
end

if hasUVs
    vertexData = [vertexData; uvs];
    asciiFormat = [asciiFormat, '\t%f %f'];
end

if hasColors
    vertexData = [vertexData; colors];
    asciiFormat = [asciiFormat, '\t%f %f %f'];
end

asciiFormat = [asciiFormat, '\n'];

%% Write the PLY body.

% human-readable formatted text
if strcmp('ascii', format)
    % vertices
    for vv = 1:nVertices
        fprintf(fid, asciiFormat, vertexData(:, vv));
    end
    
    % faces
    for ff = 1:nFaces
        fprintf(fid, '3 %d %d %d\n', faces(:, ff));
    end
    fprintf(fid, '\n');
    return;
end

% compact binary data
if strcmp(format, 'binary_big_endian');
    machineFormat = 'ieee-be';
else
    machineFormat = 'ieee-le';
end

% vertices
fwrite(fid, vertexData, 'float32', 0, machineFormat);

% faces
indexCounts = 3 + zeros(1, nFaces);
paddedFaces = [indexCounts; faces];
fwrite(fid, paddedFaces, 'uint32', 0, machineFormat);
