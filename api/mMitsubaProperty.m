classdef mMitsubaProperty < mMitsubaNode
    % Property configuration for a Mitsuba plugin.s
    %
    % The idea here is to hold a property configuration for a Mitsuba scene
    % element "plugin".  This includes things like setting the radius of a
    % sphere, or setting the output file for the film.
    %
    % Most properties have a name, like "radius", a type, like "float", and
    % a value, like 10.5.  These would produce XML like this:
    %   <float name="radius" value="10.5" />
    %
    % Some put information into attributes besides the "value".  For
    % example,
    %   <point x="1" y="2" z="530" />
    %
    % Some properties like transformations, are nested like this:
    %	<transform  name="toWorld">
    %       <translate  x="-1"  y="3"  z="4"/>
    %       <rotate  y="1"  angle="45"/>
    %   </transform>
    %
    % mMitsubaProperty can handle all of these cases by allowing nested
    % properties and by allowing flexible name-value pairs where data can
    % be stored.  See static methods for utilities that handle common
    % cases.
    %
    
    properties
        % Struct of name-value pairs where property data are stored.
        data;
    end
    
    methods
        function self = mMitsubaProperty(name, type)
            self.id = name;
            self.type = type;
        end
        
        function s = toStruct(self)
            % data fields to attributes
            s = struct();
            if ~isempty(self.data)
                s.Attributes = self.data;
            end
            
            % name is optional
            if ~isempty(self.id)
                s.Attributes.name = self.id;
            end
            
            % optional nested properties
            s = self.appendEach(s, self.nested);
        end
        
        function setData(self, dataName, dataValue)
            % Add or update a data field to this property.
            self.data.(dataName) = dataValue;
        end
        
        function dataValue = getData(self, dataName)
            % Get a data field from this property.
            %   Returns [] of there is no such named field.
            if isfield(self.data, dataName)
                dataValue = self.data.(dataName);
            else
                dataValue = [];
            end
        end
    end
    
    methods (Static)
        function p = withValue(name, type, value)
            % Build a typical name-type-value property.
            p = mMitsubaProperty(name, type);
            p.setData('value', value);
        end
        
        function p = withNamedData(name, type, varargin)
            % Build a property with name, type, and arbitrary data fields.
            %   Requires name and type as first two arguments.  Subsequent
            %   arguments are treated as name-value pairs to add as named
            %   property data.
            
            parser = inputParser();
            parser.addRequired('name', @ischar);
            parser.addRequired('type', @ischar);
            parser.KeepUnmatched = true;
            parser.parse(name, type, varargin{:});
            name = parser.Results.name;
            type = parser.Results.type;
            
            p = mMitsubaProperty(name, type);
            p.data = parser.Unmatched;
        end
        
        function p = anonymous(type, varargin)
            % Build a property with only type, and arbitrary data fields.
            %   Requires type as the first argument.  Subsequent
            %   arguments are treated as name-value pairs to add as named
            %   property data.
            p = mMitsubaProperty.withNamedData('', type, varargin{:});
        end
    end
end