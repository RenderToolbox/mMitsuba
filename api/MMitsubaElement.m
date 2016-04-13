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
        
        function property = setProperty(self, name, type, value)
            % Add or update a nested property with the given name.
            %   If this element already contains a nested property with the
            %   given name, it will be updated with the given type and
            %   value. Otherwise, a new nested property will be added.
            %
            %   By default the given value will have the attribute name
            %   "value".  If the given type is not string nor boolean, and
            %   the given value doesn't start with a number, then the
            %   attribute name "filename" will be used instead.  This is a
            %   hack so that callers can treat spectrum strings ('400:1
            %   410:1 420:2 ...') and spectrum file names
            %   ('my-spectrum.spd') interchangeably.
            property = self.find(name, ...
                'type', type);
            
            if ischar(value) ...
                    && ~strcmp('string', type) ...
                    && ~strcmp('boolean', type) ...
                    && 0 == numel(sscanf(value, '%f'))
                attributeName = 'filename';
            else
                attributeName = 'value';
            end
            
            if isempty(property)
                property = MMitsubaProperty.withData(name, type, ...
                    attributeName, value);
                self.append(property);
                return;
            end
            
            property.setData(attributeName, value);
            property.type = type;
        end
        
        function [value, type] = getProperty(self, name)
            % Locate a nested property with the given name.
            %   If a nested property with the given name exists, finds and
            %   returns its "value" data and type.  Otherwise returns [].
            
            property = self.find(name);
            
            if isempty(property)
                value = [];
                type = [];
                return;
            end
            
            value = property.getData('value');
            type = property.type;
        end
    end
    
    methods (Static)
        function scene = scene()
            % Helper method to make the top-level scene element.
            scene = MMitsubaElement('', 'scene', '');
        end
    end
end