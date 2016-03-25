# mMitsuba
Matlab tools for constructing and writing Mitsuba scene files.

We want to auto-generate [Mitsuba](https://www.mitsuba-renderer.org/) scene files from Matlab.  We start with an object-oriented Matlab representation of the whole scene.  We can identify objects in the the scene by id, and add/find/update/remove them while working.  When done working, we can write out a Mitsuba scene XML file based on the objects.

For now we can only go from Matlab to Mitsuba.  We can't parse existing Mitsuba files (although this should be doable, since the scene files are XML).

# Get Started
To get started, clone this repository and add it to your Matlab path.

See the example scripts at [examples/simpleScene.m](https://github.com/RenderToolbox3/mMitsuba/blob/master/examples/simpleScene.m) and [examples/moreComplexExample.m](https://github.com/RenderToolbox3/mMitsuba/blob/master/examples/moreComplexExample.m).  You should be able to run these right away and produce Mitsuba scene file like [this simple one](https://github.com/RenderToolbox3/mMitsuba/blob/master/examples/simpleScene.xml) and this [more complex one](https://github.com/RenderToolbox3/mMitsuba/blob/master/examples/moreComplexExample.xml).

These examples reproduce scenes from section 6 of the [Mitsuba documentation](https://www.mitsuba-renderer.org/docs.html) (version 0.5.0). 

# The API
The mMitsuba API is based on Elements and Properties.  These are written as Matlab [Classes](http://www.mathworks.com/help/matlab/object-oriented-programming.html).

In general, you create objects and specify their ids, types, values, etc.  Then the objects take care of writing well-formatted Mitsuba syntax to an XML file.

### Elements
Elements are things like shapes, light sources, the camera, etc.  In terms of scene file syntax, Elements are written as [XML elements](http://www.w3schools.com/xml/xml_elements.asp).  In terms of Mitsuba, each Element invokes a Mitsuba "plugin" which is a chunk of the renderer.

Each Element requires a unique `id`, which can be anything you want.  The `id` lets us find Elements while were working, and lets Elements refer to each other.

Each Element also requires a `type` and a `pluginType`, which tell Mitsuba how to use the Element, and which "plugin" to load into memory. 

Here is an example of creating a `shape` element:
```
shape = MMitsubaElement('my-shape', 'shape', 'sphere');
```

This produces the following XML in the output file:
```
<shape id="my-shape" type="sphere" />
```

### Nesting Elements
By itself, the sphere shape above would not be very useful.  But Elements can be nested to make them more interesting.

Here is an example of nesting a reflectance model within a shape.  This would give the shape an interesting surface appearance:
```
shape = MMitsubaElement('my-shape', 'shape', 'sphere');
bsdf = MMitsubaElement('my-material', 'bsdf', 'roughdielectric');
shape.append(bsdf);
```

This produces the following XML in the output file:
```
<shape id="my-shape" type="sphere">
  <bsdf id="my-material" type="roughdielectric" />
</shape>
```

### Properties
Another way to make elements more interesting is to given them Properties.  Properties are things like "width", "sampleCount", and "roughness".  In terms of scene file syntax, Properties are written as [XML elements](http://www.w3schools.com/xml/xml_elements.asp), just like Elements.  In terms of Mitsuba, properties configure plugins that have already been loaded.

Each Property requires a `name`, which must be one of the named parameters expected by a Mitsuba plugin.

Each Property also requires a `type`, which is the type of the Property's value, such as `integer` or `spectrum`.


Here is an example of adding some Properties to Elements.  These would refine the example above by setting the `radius` of the sphere shape and the `roughness` of the surface reflectance model. 
```
shape = MMitsubaElement('my-shape', 'shape', 'sphere');
shape.append(MMitsubaProperty.withValue('radius', 'float', 10));

bsdf = MMitsubaElement('my-material', 'bsdf', 'roughdielectric');
bsdf.append(MMitsubaProperty.withValue('alpha', 'float', 0.01));

shape.append(bsdf);
```

This produces the following XML in the output file:
```
<shape id="my-shape" type="sphere">
  <float name="radius" value="10"/>
  <bsdf id="my-material" type="roughdielectric">
    <float name="alpha" value="0.01"/>
  </bsdf>
</shape>
```

### Transformations
Some elements like shapes, lights, and the camera, can move about the scene as specified by spatial transformations.  We can specify transformations using Properties.

The trick is that transformations can have multiple nested parts, so we have a utility method for making nested Properties: [MMitsubaProperty.withNested()](https://github.com/RenderToolbox3/mMitsuba/blob/master/api/MMitsubaProperty.m#L96).

Here is an example of adding a `toWorld` transformation, with nested translation, to a shape:
```
shape = MMitsubaElement('my-shape', 'shape', 'sphere');
shape.append(MMitsubaProperty.withNested('toWorld', 'transform', 'translate', ...
  'x', 5, ...
  'y', -3, ...
  'z', 1));
```

This produces the following XML in the output file:
```
<shape id="my-shape" type="sphere">
  <transform name="toWorld">
    <translate x="5" y="-3" z="1"/>
  </transform>
</shape>
```

### Add, Find, and Delete from a Scene
All Elements and Properties go in a top-level `scene` Element.  You can search the Scene (or any Element or Property) for existing nested Elements and Properties.  You can also remove find-and-remove Elements and Properties from the scene.  In one programmer's humble opinion, these abilities make mMitsuba more fun than a plain Mitsuba XML file!

Here's an example that adds several elements and properties to a scene:
```
scene = MMitsubaElement.scene();

integrator = MMitsubaElement('integrator', 'integrator', 'path');
integrator.append(MMitsubaProperty.withValue('maxDepth', 'integer', 8));
scene.append(integrator);

sensor = MMitsubaElement('camera', 'sensor', 'perspective');
sensor.append(MMitsubaProperty.withNested('toWorld', 'transform', 'lookat', ...
    'origin', 0.1 * [-1 1 4], ...
    'target', [0 .1 0], ...
    'up', [0 1 0]));
sensor.append(MMitsubaProperty.withValue('fov', 'float', 45));
scene.append(sensor);
```

We can find the integrator by `id` and change the type of plugin that it will load:
```
integrator = scene.find('integrator');
integrator.pluginType = 'bdpt';
```

We can find the camera's `fov` Property and remove it altogether:
```
removedFov = scene.find('fov', ...
    'type', 'float', ...
    'remove', true);

removedFov = 
  MMitsubaProperty with properties:

       data: [1x1 struct]
         id: 'fov'
       type: 'float'
     nested: {}
    version: '0.5.0'
```

Once removed, we can no longer find the fov.
```
shouldBeEmpty = scene.find('fov', 'type', 'float');

shouldBeEmpty =
     []
```

See a similar example script at [examples/addFindRemoveFromScene.m](https://github.com/RenderToolbox3/mMitsuba/blob/master/examples/addFindRemoveFromScene.m).
