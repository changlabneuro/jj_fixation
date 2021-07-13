function status = EyelinkFillRect(varargin)
% EyelinkFillRect  Draw rectangles on the Eyelink screen
% status = EyelinkFillRect(colorCode)
%     Clear the Eyelink screen and set the background color to <colorCode>.
% status = EyelinkFillRect(rect, colorCode)
%     Draw a rectangle defined by the four-element vector <rect>, in color
%     <colorCode>.
% status = EyelinkFillRect(position, halfSide, colorCode)
%     Draw a rectangle centered at <position>, a two-element [x y] vector,
%     which is 2*<halfSide> pixels to a side.
%
% Color codes:
% 0: Black
% 1: Dark blue
% 2: Dark green
% 3: Teal
% 4: Dark red
% 5: Magenta
% 6: Dark yellow
% 7: Neutral grey
% 8: Dark grey
% 9: Periwinkle
% 10: Spring green
% 11: Cyan-grey
% 12: Salmon
% 13: Light purple
% 14: Light yellow
% 15: Light grey

switch nargin
    case 1
        status = Eyelink('Command', 'clear_screen %d', varargin{1});
        return
    case 2
        rect = varargin{1};
        colorCode = varargin{2};
    case 3
        position = varargin{1};
        halfSide = varargin{2};
        colorCode = varargin{3};
        rect = [position - halfSide, position + halfSide];
    otherwise
        error('Invalid usage of EyelinkFillRect');
end

status = Eyelink('Command', 'draw_filled_box %d %d %d %d %d', ...
    rect(1), rect(2), rect(3), rect(4), colorCode);
