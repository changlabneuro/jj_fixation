%{

    layeredstruct.m -- function for preallocating / instatiating a
    nested structure with an arbitrary number of levels. <layers> need be a
    cell-array of cell-arrays; each cell in <layers> should contain strings
    corresponding to the fieldnames of the structure at that level. The
    hierarchy is descending, such that cell(i+1) is nested within cell(i),
    ...

    Optionally add a second input <fillwith> to preallocate the inner-most
    structure.

    E.g., say we wish to store the effects of various drugs on peoples' 
    looking behavior to various images. In each drug condition, the same 
    images -- landscapes and cityscapes -- are shown. We might create a 
    structure <data> to hold this information:

    data = layeredstruct(...
            {...
                {'oxytocin','naloxone','saline'},...
                {'landscapes','cityscapes'}...
            },...
            {'dummy data'});

    %%%% --> 
    
    data = 

        oxytocin:   [1x1 struct]
        naloxone:   [1x1 struct]
        saline:     [1x1 struct]

        data.oxytocin = 
    
            landscapes: {'dummy data'}
            cityscapes: {'dummy data'}
        
        data.naloxone = 
            
            landscapes: {'dummy data'}
            cityscapes: {'dummy data'}
        
        ...        
%}

function structure = layeredstruct(layers,fillwith,structure)

if ~iscell(layers)
    error('Layers must be a cell array');
end

if nargin < 3
    structure = struct();
end

if nargin < 2
    fillwith = [];
end

if isempty(layers)
    structure = fillwith; return;
end

current_layer = layers{1};

layers(1) = [];

firstfield = current_layer{1};

structure.(firstfield) = hww_gng.util.layeredstruct(layers, fillwith, structure);
current_layer(1) = [];

if isempty(current_layer)
    return;
end

for i = 1:length(current_layer)
    structure.(current_layer{i}) = structure.(firstfield);
end

end