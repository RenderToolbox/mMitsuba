% This is an example of how to build and write a Mitsuba scene with MMitsuba.
%
% This example recreates one of the "simple scene" example Mitsuba files
% from section 6 of the Mitsuba pdf (verision 0.5.0).
%   https://www.mitsuba-renderer.org/docs.html
%
% Here's what the original looks like:
%
% <scene version="0.5.0">
%   <shape type="sphere">
%     <float name="radius" value="10"/>
%   </shape>
% </scene>
%
% Now let's build it!

%% Start with a blank scene.
clear;
clc;

scene = MMitsubaElement.scene();

%% Add the shape.
shape = MMitsubaElement('shape', 'shape', 'sphere');
shape.append(MMitsubaProperty.withValue('radius', 'float', 10));
scene.append(shape);

%% Print the scene to a file.
%   how did it come out?

pathHere = fileparts(which('simpleScene.m'));
outputFile = fullfile(pathHere, 'simpleScene.xml');
scene.printToFile(outputFile);
