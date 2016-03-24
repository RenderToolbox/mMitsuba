# mMitusba
Matlab tools for constructing and writing Mitsuba scene files.

We want to auto-generate [Mitsuba](https://www.mitsuba-renderer.org/) scene files from Matlab.  We start with an object-oriented Matlab representation of the whole scene.  We can identify objects in the the scene by id, and add/find/update/remove them while working.  When done working, we can write out a Mitsuba scene XML file based on the objects.

For now we can only go from Matlab to Mitsuba.  We can't parse existing Mitsuba files (although this should be doable, since the scene files are XML).

# Get Started
To get started, clone this repository and add it to your Matlab path.


# TODO: update the rest
The rest of this document was copied from our mPbrt documentation.  BSH is planning to keep the outline the same, but update the content for mMitusba...as soon as he writes it!

See the example script at [examples/exampleOfAPbrtFile.m](https://github.com/RenderToolbox3/mPbrt/blob/master/examples/exampleOfAPbrtFile.m).  You should be able to run this script right away and produce a PBRT scene file like [this one](https://github.com/RenderToolbox3/mPbrt/blob/master/examples/exampleOfAPbrtFile.pbrt).

The idea of this example script is to reproduce the "official" example scene file from the [pber-v2 file format documentation](http://www.pbrt.org/fileformat.html).

# The API
The mPbrt API is based on a Scene which contains Elements and Containers.  These are written as Matlab [Classes](http://www.mathworks.com/help/matlab/object-oriented-programming.html).

In general, you create objects and specify their names, types, values, etc.  Then the objects take care of writing well-formatted PBRT syntax to a text file.

### Elements
Elements are things like shapes, light sources, the camera, etc.  Each one has a declaration line followed by zero or more parameter lines.

Here is an example of creating a `LightSource` element:
```
lightSource = MPbrtElement('LightSource', 'type', 'distant');
lightSource.setParameter('from', 'point', [0 0 0]);
lightSource.setParameter('to', 'point', [0 0 1]);
lightSource.setParameter('L', 'rgb', [3 3 3]);
```

This produces the following PBRT syntax in the output file:
```
LightSource "distant"   
  "point from" [0 0 0] 
  "point to" [0 0 1] 
  "rgb L" [3 3 3] 
```

You can write generic Elements as in this example.  There are also utility methods for creating some common or complex elements.  These include:
  * [`MPbrtElement.comment()`](https://github.com/RenderToolbox3/mPbrt/blob/master/api/MPbrtElement.m#L128)
  * [`MPbrtElement.transformation()`](https://github.com/RenderToolbox3/mPbrt/blob/master/api/MPbrtElement.m#L133)
  * [`MPbrtElement.texture()`](https://github.com/RenderToolbox3/mPbrt/blob/master/api/MPbrtElement.m#L148)
  * [`MPbrtElement.makeNamedMaterial()`](https://github.com/RenderToolbox3/mPbrt/blob/master/api/MPbrtElement.m#L157)
  * [`MPbrtElement.namedMaterial()`](https://github.com/RenderToolbox3/mPbrt/blob/master/api/MPbrtElement.m#L165)

### Containers
Containers are holders for nested elements.  For example the stuff that goes between `WorldBegin` and `WorldEnd` goes in a "World" container.  Likewise, stuff you want to put in an `AttributeBegin`/`AttributeEnd` section would go in an "Attribute" container, and so on for other `Begin`/`End` sections.

Here is an example of creating an `AttributeBegin`/`AttributeEnd` section that holds a coordinate transformation and a light source:
```
lightAttrib = MPbrtContainer('Attribute');

coordXForm = MPbrtElement.transformation('CoordSysTransform', 'camera');
lightAttrib.append(coordXForm);

lightSource = MPbrtElement('LightSource', 'type', 'distant');
lightSource.setParameter('from', 'point', [0 0 0]);
lightSource.setParameter('to', 'point', [0 0 1]);
lightSource.setParameter('L', 'rgb', [3 3 3]);
lightAttrib.append(lightSource);
```

This produces the following PBRT syntax in the output file:
```
AttributeBegin
  CoordSysTransform "camera"   
  LightSource "distant"   
    "point from" [0 0 0] 
    "point to" [0 0 1] 
    "rgb L" [3 3 3] 
AttributeEnd
```

### Comments
Elements and Containers have the optional properties `name` and `comment`.  When these properties are provided, the objects will print extra comment lines.

Here is an example of adding a `name` and `comment` to a coordinate transform:
```
coordXForm = MPbrtElement.transformation('CoordSysTransform', 'camera', ...
    'name', 'camera-transform', ...
    'comment', 'Move the coordinate system to match the camera.');
```

This produces the following PBRT syntax in the output file:
```
# camera-transform
# Move the coordinate system to match the camera.
CoordSysTransform "camera"   
```

### Add, Find, and Delete from a Scene
All your Elements and Containers go in a Scene.  The scene has an "overall" part for things that come before the `WorldBegin` line, like the camera.  The scene also has a "world" part for everything else, inluding shapes, light sources, etc.

The Scene does more than organize you objects.  You can add objects to the Scene, search the Scene for existing objects, and remove objects from the Scene.  In one programmer's humble opinion, these abilities make mPath more fun than a plain PBRT text file!

Here's an example that adds two elements to a scene.
```
scene = MPbrtScene();

% add the camera at the "overall" level
scene.overall.append(MPbrtElement('Camera', 'type', 'perspective'));

% add a light to the "world", nested in an Attribute section
lightAttrib = MPbrtContainer('Attribute');
scene.world.append(lightAttrib);
lightAttrib.append(MPbrtElement('LightSource', 'type', 'distant', 'name', 'the-light'));
```

We can find the camera and update it.
```
camera = scene.overall.find('Camera');
camera.setParameter('fov', 'float', 30);
```

We can find the light and remove it altogether.
```
removedlight = scene.world.find('LightSource', 'name', 'the-light', 'remove', true);
removedLight = 
  MPbrtElement with properties:

          value: []
      valueType: ''
           type: 'distant'
     parameters: []
           name: 'the-light'
     identifier: 'LightSource'
        comment: ''
         indent: '  '
    floatFormat: '%f'
      intFormat: '%d'
     scanFormat: '%f'
```

Once removed, we can no longer find the light.
```
shouldBeEmpty = scene.world.find('LightSource', 'name', 'the-light');
shouldBeEmpty =
     []
```

See a similar example script at [examples/addFindRemoveFromScene.m](https://github.com/RenderToolbox3/mPbrt/blob/master/examples/addFindRemoveFromScene.m).
