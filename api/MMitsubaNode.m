
classdef MMitsubaNode < matlab.mixin.Copyable
    % Common interface and utiltiies for things that print themselves to a Mitsuba file.
    
    properties
        % Name or id used to identify this node.
        id = '';
        
        % Mitsuba plugin or property value type.
        type = '';
        
        % Nested elements or properties.
        nested = {};
        
        % Mitsuba version to target.
        version = '0.5.0';
        
        % any extra data to associate with this node
        extra;
    end
    
    methods (Abstract)
        % Convert this object and nested objects to a struct.
        %   This object must convert its self and any nested to a struct,
        %   suitable for dumping to XML via the struct2xml() utility:
        %     http://www.mathworks.com/matlabcentral/fileexchange/28639-struct2xml
        s = toStruct(self)
    end
    
    methods
        function xml = printToFile(self, outputFile)
            % Write this object and nested objects to a Mitsuba XML file.
            %   If outputFile is omitted, returns a string of xml.
            
            % pack up scene data in a top-level document and root node
            scene.Attributes.version = self.version;
            scene = self.appendEach(scene, self.nested);
            document.(self.type) = scene;
            
            if nargin > 1
                struct2xml(document, outputFile);
                xml = [];
            else
                xml = struct2xml(document);
            end
        end
        
        function isGivenNode = nodePosition(self, node)
            % Check if the given node is nested in this node.
            %   Returns a logical array the same size as self.nested, true
            %   where the given node appears in self.nested, if at all.
            
            % no trick, just compare against each nested object
            nNested = numel(self.nested);
            isGivenNode = false(1, nNested);
            for nn = 1:nNested
                isGivenNode(nn) = node == self.nested{nn};
            end
        end
        
        function index = prepend(self, node)
            % Prepend a node nested under this node.
            %   If the node is already nested in this node, it will be
            %   moved to the front.  Returns the index where the new node
            %   was appended, which will always be 1, or [] if there was an
            %   error.
            
            if ~isa(node, 'MMitsubaNode')
                index = [];
                return;
            end
            
            index = 1;
            isGivenNode = self.nodePosition(node);
            self.nested = cat(2, {node}, self.nested(~isGivenNode));
        end
        
        function index = append(self, node)
            % Append a node nested under this node.
            %   If the node is already nested in this node, it will be
            %   moved to the back.  Returns the index where the new node
            %   was appended, or [] if there was an error.
            
            if ~isa(node, 'MMitsubaNode')
                index = [];
                return;
            end
            
            isGivenNode = self.nodePosition(node);
            self.nested = cat(2, self.nested(~isGivenNode), {node});
            index = numel(self.nested);
        end
        
        function existing = find(self, id, varargin)
            % Find a node nested under this node.
            %   existing = find(self, id) recursively searches this
            %   node and nested nodes for a node that has the given
            %   id.  The first node found is returned, if any.  If
            %   no node was found, returns [].
            %
            %   find( ... 'type', type) restricts the search to nodes that
            %   have the given id and type.
            %
            %   find( ... 'remove', remove) specifies whether to remove the
            %   node that was found from its nesting node (true), or not
            %   (false).  The default is false, don't remove the node.
            
            parser = inputParser();
            parser.addRequired('id', @ischar);
            parser.addParameter('type', '', @ischar);
            parser.addParameter('remove', false, @islogical);
            parser.parse(id, varargin{:});
            id = parser.Results.id;
            nodeType = parser.Results.type;
            remove = parser.Results.remove;
            
            % is it this container?
            if (isempty(id) || ~isempty(regexp(self.id, id, 'once'))) ...
                    && (isempty(nodeType) || strcmp(self.type, nodeType))
                existing = self;
                return;
            end
            
            % depth-first search of nested nodes
            for nn = 1:numel(self.nested)
                node = self.nested{nn};
                
                % look for a direct child [and remove it]
                if (isempty(id) || ~isempty(regexp(node.id, id,'once'))) ...
                        && (isempty(nodeType) || strcmp(node.type, nodeType))
                    existing = node;
                    if remove
                        self.nested(nn) = [];
                    end
                    return;
                end
                
                % look for a deeper descendant
                existing = node.find(id, varargin{:});
                if ~isempty(existing)
                    return;
                end
            end
            
            % never found a match
            existing = [];
        end
    end
    
    methods (Access = protected)
        function copy = copyElement(self)
            % Override from matlab.mixin.Copyable.
            %   Make a recursive "deep" copy of nested objects.
            copy = self.copyElement@matlab.mixin.Copyable();
            for nn = 1:numel(copy.nested)
                copy.nested{nn} = copy.nested{nn}.copyElement();
            end
        end
    end
    
    methods (Static)
        function s = appendToField(s, fieldName, value)
            % Append the given value to a field of the given struct.
            %   Appends value to the fieldName field of the given struct s.
            %   If s doesn't already have such a field, it is initialized
            %   as a cell array.  In all cases, the value is appended to
            %   the cell array.
            
            if isfield(s, fieldName)
                s.(fieldName) = cat(2, s.(fieldName), {value});
            else
                s.(fieldName) = {value};
            end
        end
        
        function s = appendEach(s, nodes)
            % Append each of the given nodes to the given struct.
            %   Appends each MMitsubaNode contained in the given nodes
            %   cell array to an appropriate field of the given struct s.
            %   The field names will be based on the type property of each
            %   node.  The field values will be based on the toStruct()
            %   value of each node.
            for nn = 1:numel(nodes)
                node = nodes{nn};
                s = MMitsubaNode.appendToField(s, node.type, node.toStruct());
            end
        end
    end
end
