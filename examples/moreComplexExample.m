% This is an example of how to build and write a Mitsuba scene with MMitsuba.
%
% This example recreates the "more complex example" Mitsuba file
% from section 6 of the Mitsuba pdf (verision 0.5.0).
%   https://www.mitsuba-renderer.org/docs.html
%
% The example scene refers to two geometry files that we don't have:
%   dragon.obj
%   lightsource.serialzied
%
% To make our scene testable, we will substitute a dragon file that we do
% have, included with this script:
%   dragon/dragon_vrip_res4.ply
% and we will make the light source a sphere instead of a serialized mesh.
%
% We will also make the camera "lookat" the dragon, instead of pointing off
% into space.
% 
% Here's what the original looks like:
%
% <scene version="0.5.0">
%   <integrator type="path">
%     <!--  Path  trace  with  a  max.  path  length  of  8  -->
%     <integer name="maxDepth" value="8"/>
%   </integrator>
%
%   <!--  Instantiate  a  perspective  camera  with  45  degrees  field  of  view  -->
%   <sensor type="perspective">
%     <!--  Rotate  the  camera  around  the  Y  axis  by  180  degrees  -->
%     <transform name="toWorld">
%       <rotate y="1" angle="180"/>
%     </transform>
%
%     <float name="fov" value="45"/>
%
%     <!--  Render  with  32  samples  per  pixel  using  a  basic independent  sampling  strategy  -->
%     <sampler type="independent">
%       <integer name="sampleCount" value="32"/>
%     </sampler>
%
%     <!--  Generate  an  EXR  image  at  HD  resolution  -->
%     <film type="hdrfilm">
%       <integer name="width" value="1920"/>
%       <integer name="height" value="1080"/>
%     </film>
%   </sensor>
%
%   <!--  Add  a  dragon  mesh  made  of  rough  glass  (stored  as  OBJ  file)  -->
%   <shape type="obj">
%     <string name="filename" value="dragon.obj"/>
%     <bsdf type="roughdielectric">
%       <!--  Tweak  the  roughness  parameter  of  the  material  -->
%       <float name="alpha" value="0.01"/>
%     </bsdf>
%   </shape>
%
%   <!--  Add  another  mesh -- this  time,  stored  using  Mitsuba's  own (compact)  binary  representation  -->
%   <shape type="serialized">
%     <string name="filename" value="lightsource.serialized"/>
%
%     <transform name="toWorld">
%       <translate x="5" y="-3" z="1"/>
%     </transform>
%
%     <!--  This  mesh  is  an  area  emitter  -->
%     <emitter type="area">
%       <rgb name="radiance" value="100,400,100"/>
%     </emitter>
%   </shape>
% </scene>
%
% Now let's build it!

%% Start with a blank scene.
clear;
clc;

scene = MMitsubaElement.scene();

%% Add the integrator.
integrator = MMitsubaElement('integrator', 'integrator', 'path');
integrator.append(MMitsubaProperty.withValue('maxDepth', 'integer', 8));
scene.append(integrator);

%% Add the camera, with nested sampler and film.
sensor = MMitsubaElement('camera', 'sensor', 'perspective');

sensor.append(MMitsubaProperty.withNested('toWorld', 'transform', 'lookat', ...
    'origin', 0.1 * [-1 1 4], ...
    'target', [0 .1 0], ...
    'up', [0 1 0]));
sensor.append(MMitsubaProperty.withValue('fov', 'float', 45));

sampler = MMitsubaElement('sampler', 'sampler', 'independent');
sampler.append(MMitsubaProperty.withValue('sampleCount', 'integer', 32));

film = MMitsubaElement('film', 'film', 'hdrfilm');
film.append(MMitsubaProperty.withValue('width', 'integer', 1920));
film.append(MMitsubaProperty.withValue('height', 'integer', 1080));

scene.append(sensor);

%% Add a reflective dragon shape.
dragon = MMitsubaElement('dragon', 'shape', 'ply');
dragon.append(MMitsubaProperty.withValue('filename', 'string', 'dragon/dragon_vrip_res4.ply'));

bsdf = MMitsubaElement('dragon-material', 'bsdf', 'roughdielectric');
bsdf.append(MMitsubaProperty.withValue('alpha', 'float', 0.01));

scene.append(dragon);

%% Add a light-emitting shape.
lightSource = MMitsubaElement('light', 'shape', 'sphere');
lightSource.append(MMitsubaProperty.withValue('radius', 'float', 2));

lightSource.append(MMitsubaProperty.withNested('toWorld', 'transform', 'translate', ...
    'x', 5, ...
    'y', -3, ...
    'z', 1));

emitter = MMitsubaElement('light-emitter', 'emitter', 'area');
emitter.append(MMitsubaProperty.withValue('radiance', 'rgb', '100, 400, 100'));
lightSource.append(emitter);

scene.append(lightSource);

%% Print the scene to a file.
%   how did it come out?

pathHere = fileparts(which('moreComplexExample.m'));
outputFile = fullfile(pathHere, 'moreComplexExample.xml');
scene.printToFile(outputFile);
