function save_path = convert(file_path,varargin)
%
%   adinstruments.convert(*file_path,varargin)
%
%   This function will save a .adicht file's contents into a .mat file 
%   (v7.3) or a hdf5 file
%
%   Current Status:
%   ---------------
%   Things are working however the HDF5 format will likely change soon as I
%   develop my HDF5 Matlab library:
%       https://github.com/JimHokanson/hdf5_matlab
%
%   Optional Inputs:
%   ----------------
%   file_path : str (default: prompts user)
%       Path to the file. If omitted a prompt will ask the user to select
%       the file to convert.
%   format : {'h5','mat'} (default 'h5')
%       The format to convert the file to.
%   conversion_options: {.h5_conversion_options,.mat_conversion_options}
%       These classes provide access to the conversion options. The main 
%       point of these options (at least initially) was to have control
%       over options that impact how fast the data is written (and then
%       subsequently written)

in.conversion_options = [];
in.format = 'h5'; %or 'mat'
in.save_path = '';
in = sl.in.processVarargin(in,varargin);

if in.format(1) == '.'
    in.format(1) = [];
end
   
if nargin == 0 || isempty(file_path)
   [file_name,file_root] = uigetfile({'*.adicht'},'Pick a file to convert'); 

    if isnumeric(file_name)
        return
    end
    file_path = fullfile(file_root,file_name);
end


file_obj = adinstruments.readFile(file_path);

switch in.format
    case 'h5'
        %adinstruments.file.exportToMatFile
        save_path = file_obj.exportToHDF5File(in.save_path,in.conversion_options);
    case 'mat'
        %adinstruments.file.exportToMatFile
        save_path = file_obj.exportToMatFile(in.save_path,in.conversion_options);
    otherwise
        error('Unrecognized format option: %s',in.format);
end