
% This is an example of how to import a mexximp sceene and convert to mMitsuba.
%
% This example uses the Assimp tool to load a 3D model of the millenium
% falcon obtained from the web.
%   http://www.assimp.org/
%
% It uses the mexximp tool to get the loaded 3D model into Matlab.
%   https://github.com/RenderToolbox3/mexximp
%
% It usees utilities in import/mexximp to convert the mexximp struct
% representation of the scene to an MMitsuba object graph.
%
% Finally, it dumps out a Mitsuba scene file.  If Mitsuba is found,
% it tries to get the scene file rendered.
%
% 2016 benjamin.heasly@gmail.com

clear;
clc;

sourceFile = which('millenium-falcon.obj');
outputFolder = fullfile(tempdir(), 'mexximpImportExample');

%% Load the 3D scene.
[mexximpScene, mexximpElements] = mexximpCleanImport(sourceFile, ...
    'workingFolder', outputFolder, ...
    'toReplace', {'png', 'jpg'}, ...
    'targetFormat', 'exr', ...
    'flipUvs', true);

% add missing camera and lights
mexximpScene = mexximpCentralizeCamera(mexximpScene, 'viewAxis', [.25 .25 1]);
mexximpScene = mexximpAddLanterns(mexximpScene, 'lanternRgb', [10 11 12]);

%% Convert the mexximp scene struct to an mMitsuba object graph.
materialDefault = MMitsubaElement('', 'bsdf', 'diffuse');
materialDefault.append(MMitsubaProperty.withValue('reflectance', 'spectrum', '300:0.5 800:0.5'));

mitsubaScene = mMitsubaImportMexximp(mexximpScene, ...
    'workingFolder', outputFolder, ...
    'materialDefault', materialDefault, ...
    'materialDiffuseParameter', 'reflectance');

integrator = MMitsubaElement('integrator', 'integrator', 'direct');
integrator.append(MMitsubaProperty.withValue('shadingSamples', 'integer', 32));
mitsubaScene.prepend(integrator);

film = mitsubaScene.find('film');
film.pluginType = 'hdrfilm';
film.append(MMitsubaProperty.withValue('width', 'integer', 640));
film.append(MMitsubaProperty.withValue('height', 'integer', 480));
film.append(MMitsubaProperty.withValue('banner', 'boolean', 'false'));

%% Print out a Mitsuba scene file.
sceneFile = fullfile(outputFolder, 'mexximpImportExample.xml');
mitsubaScene.printToFile(sceneFile);

%% Try to render with Mitsuba.

% locate a mitsuba executable?
mitsuba = 'mitsuba';

% render
imageFile = fullfile(outputFolder, 'mexximpImportExample.exr');
mitsubaCommand = sprintf('LD_LIBRARY_PATH="%s" %s -o "%s" "%s"', ...
    fileparts(mitsuba), mitsuba, imageFile, sceneFile);
status = system(mitsubaCommand);

if status ~= 0
    return;
end

%% Convert exr to png for viewing.
% see exrtools: http://scanline.ca/exrtools/
normalized = mexximpExrTools(imageFile, ...
    'operation', 'exrnormalize', ...
    'outFile', fullfile(outputFolder, 'normalized.exr'));
toneMapped = mexximpExrTools(normalized, ...
    'operation', 'exrpptm', ...
    'outFile', fullfile(outputFolder, 'toneMapped.exr'));
renormalized = mexximpExrTools(toneMapped, ...
    'operation', 'exrnormalize', ...
    'outFile', fullfile(outputFolder, 'renormalized.exr'));
pngFile = mexximpExrTools(renormalized);
imshow(pngFile)
