% This is an example of how to build, search and update an mMitsuba scene.
%
% This example creates a scene that contains a few elements with a few
% properties each.  It searches the scene for one of the elements and
% updates it.  Then it removes one of the properties from the scene.
%
% These operations, add, find, and remove, should make mMitsuba fun!  They
% should also make it possible to integrate mMitsuba with other Matlab
% scripts and toolboxes that wish to generate Mitsuba files.
%

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

scene.append(sensor);

%% Find the integrator and update its pluginType.
integrator = scene.find('integrator');
integrator.pluginType = 'bdpt';

%% Find camera's field of view parameter and remove it.
% remove using the find() method, plus the "remove" flag
removedFov = scene.find('fov', ...
    'type', 'float', ...
    'remove', true);

% since the fov was removed, we can no longer find it in the scene
shouldBeEmpty = scene.find('fov', ...
    'type', 'float');
