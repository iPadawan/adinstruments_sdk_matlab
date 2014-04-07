classdef file < sl.obj.handle_light
    %
    %   Class:
    %   adinstruments.file
    
    properties
       file_path
    end
    
    properties
       n_records
       n_channels
       records
    end
    
    properties
       %These will be changed ...
       temp_secs_per_tick
       temp_n_samples
    end
    
    %Make read only?
    properties
       file_handle %int32 or int64 - depends on bits ... 
    end
    
    methods
        function obj = file(file_path,file_handle)
           %
           %    Created by the sdk
           
           obj.file_path   = file_path;
           obj.file_handle = file_handle;
           
           obj.n_records  = adinstruments.sdk.getNumberOfRecords(file_handle);
           obj.n_channels = adinstruments.sdk.getNumberOfChannels(file_handle);
           
           temp = cell(1,obj.n_records);
           
           for iRec = 1:obj.n_records
              %NOTE: pass in id as 0 based 
              temp{iRec} = adinstruments.record(iRec-1,file_handle); 
           end
           
           obj.records = [temp{:}];
           
           
           %Some more random testing, this will be moved ...
           obj.temp_secs_per_tick = adinstruments.sdk.getTickPeriod(file_handle,0,0);
           obj.temp_n_samples     = adinstruments.sdk.getNSamplesInRecord(file_handle,0,0);
           
        end
    end
    methods
          %This is causing a prog crash for some reason
%         function delete(obj)
%            %TODO: On delete, close file in mex
%            adinstruments.sdk.closeFile(obj.file_handle);
%         end
    end
    
end
