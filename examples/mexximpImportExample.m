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
mexximpScene = mexximpCleanImport(sourceFile);

% add missing camera and lights
mexximpScene = mexximpCentralizeCamera(mexximpScene, 'viewAxis', [1 1 -0.5]);
mexximpScene = mexximpAddLanterns(mexximpScene);

%% Convert the mexximp scene struct to an mMitsuba object graph.
mitsubaScene = mMitsubaImportMexximp(mexximpScene, ...
    'workingFolder', outputFolder);

% use the matlab film type
%   which is clunky but easy to load for demo
film = mitsubaScene.find('film');
film.pluginType = 'mfilm';
film.append(MMitsubaProperty.withValue('width', 'integer', 640));
film.append(MMitsubaProperty.withValue('height', 'integer', 480));

%% Print out a Mitsuba scene file.
sceneFile = fullfile(outputFolder, 'milleniumFalcon.xml');
mitsubaScene.printToFile(sceneFile);

%% Try to render with Mitsuba.

% locate a mitsuba executable?
%mitsuba = '/home/ben/render/mitsuba/mitsuba-rgb/mitsuba';
[status, mitsuba] = system('which mitsuba');
if isempty(mitsuba)
    disp('Mitsuba renderer not found.');
    return;
end
mitsuba = regexprep(mitsuba, '[\r\n]*', '');

% render
imageFile = fullfile(outputFolder, 'milleniumFalcon.m');
mitsubaCommand = sprintf('LD_LIBRARY_PATH="%s" %s -o "%s" "%s"\n', ...
    fileparts(mitsuba), mitsuba, imageFile, sceneFile);
system(mitsubaCommand);

% load and display rendering
%   mfilm produces a text script like, "data = [...];"
dataScript = imageFile(1:end-2);
run(dataScript);
imshow(data, []);
