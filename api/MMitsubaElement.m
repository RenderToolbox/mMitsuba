classdef MMitsubaElement < MMitsubaNode
    % Data for a Mitsuba scene plugin.
    %   The idea here is to hold the data we need in order to print an XML
    %   element that specifies a Mitsuba scene object plugin.  In general,
    %   Mitsuba scene files are organized around "plugins", which include
    %   things like meshes, cameras, light emitters, etc.
    %
    % To specify a plugin element, we need the general type, like
    % "shape', the specific plugin type, like "sphere", and a unique id,
    % like "mySphere".  This would produce XML syntax like this:
    %   <shape id="mySphere" type="sphere">
    %
    % We can extend this by nesting elements within each other, and by
    % letting elements have nested properties (see MMitsubaProperty).  We
    % can pack everything up in one big element called the "scene".  The
    % result is a functional Mitsuba scene file, like this:
    %	<scene  version="0.5.0">
    %       <shape id="mySphere" type="sphere">
    %           <float name="radius"  value="10"/>
    %       </shape>
    %	</scene>
    
    properties
        % Mitsuba plugin type, like "perspective" (camera) or "sphere" (shape).
        pluginType;
    end
    
    methods
        function self = MMitsubaElement(id, type, pluginType)
            self.id = id;
            self.type = type;
            self.pluginType = pluginType;
        end
        
        function s = toStruct(self)
            % required attributes
            s.Attributes.id = self.id;
            s.Attributes.type = self.pluginType;
            
            % optional nested elements
            s = self.appendEach(s, self.nested);
        end        
    end
    
    methods (Static)
        function scene = scene()
            % Helper method to make the top-level scene element.
            scene = MMitsubaElement('', 'scene', '');
        end
    end
end