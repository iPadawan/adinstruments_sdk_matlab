classdef sdk
    %
    %   Class:
    %   adinstruments.sdk
    %
    %   This class is meant to be the singular access point for getting
    %   data from a LabChart file. Methods in this class call a mex
    %   interface which makes calls to the C API provided by ADInstruments
    %
    %   Some definitions:
    %   =================================================
    %   tick   : sampling rate of fastest channel
    %   record : Records can be somewhat equivalent to trials or blocks
    %       in other experimental setups. Each file can consist of 1 or
    %       more records. Each time the start/stop button is pressed a new
    %       record is created. Additionally, changes to the channel setup
    %       warrant creation of a new record (such as a change in the
    %       sampling rate)
    %
    %   NOTE:
    %   Since Matlab's importing is subpar, but since it allows calling
    %   static methods from an instance of a class, one can instiate this
    %   class to allow shorter calling of the static methods of the class.
    
    properties
    end
    
    methods (Static,Hidden)
        function makeMex()
            %
            %   adinstruments.sdk.makeMex
            
            %TODO: allow unlocking - this would require reference counting.
            
            base_path = sl.dir.getMyBasePath;
            mex_path  = fullfile(base_path,private);
            
            wd = cd; %wd - working directory
            cd(mex_path)
            try
                
                mex('sdk_mex.cpp','ADIDatIOWin.lib')
                
                %Extra files:
                %------------------------
                
                file_names = cell(1,3);
                file_names{1} = 'ADIDatIOWin_thunk_pcwin64.exp';
                file_names{2} = 'ADIDatIOWin_thunk_pcwin64.lib';
                file_names{3} = 'ADIDatIOWin_thunk_pcwin64.obj';
                
                for iFile = 1:3
                    cur_file_path = fullfile(base_path,file_names{iFile});
                    %Let's avoid a warning by checking first (delete throws
                    %a warning when the file is not present)
                    if exist(cur_file_path,'file')
                        delete(cur_file_path)
                    end
                end
                
                %Go back to where we started.
                cd(wd)
            catch ME
                cd(wd)
                fprintf(2,'%s',ME.message);
            end
            
        end
    end
    
    %NOTE: In Matlab the functions can be easily visualized by folding all
    %the code and then expanding this methods block
    methods (Static)
        %File specific functions
        %------------------------------------------------------------------
        function file_h = openFile(file_path)
            %
            %   file = adinstruments.sdk.openFile(file_path)
            %
            %   NOTE: Only reading is supported.
            %
            %   Inputs
            %   ===============================================
            %   file_path : char
            %       Full path to the file.
            %
            %   Outputs
            %   ===============================================
            %   file : adinstruments.file_handle
            
            %NOTE: I had trouble with the unicode string conversion so per
            %some Mathworks forum post I am just using a null terminated
            %array of int16s
            [result_code,pointer_value] = sdk_mex(0,[int16(file_path) 0]);
            
            file_h = adinstruments.file_handle(pointer_value);
            
            adinstruments.sdk.handleErrorCode(result_code)
            
        end
        function closeFile(pointer_value)
            %
            %   adinstruments.sdk.closeFile(pointer_value)
            %
            %   Since this method should only be called by:
            %    adinstruments.file_handle.delete()
            %
            %   and since that is the deconstructor method of that object
            %   it seemed weird to pass in that object ot this method, so
            %   instead the pointer value is passed in directly.
            
            result_code = sdk_mex(13,pointer_value);
            adinstruments.sdk.handleErrorCode(result_code)
        end
        function n_records  = getNumberOfRecords(file_h)
            %getNumberOfRecords  Get the number of records for a file.
            %
            %   n_records = adinstruments.sdk.getNumberOfRecords(file_h)
            %
            %   See definition of the "records" in the definition section.
            
            [result_code,n_records] = sdk_mex(1,file_h.pointer_value);
            adinstruments.sdk.handleErrorCode(result_code)
            n_records = double(n_records);
        end
        function n_channels = getNumberOfChannels(file_h)
            %getNumberOfChannels  Get # of channels for a file.
            %
            %   n_channels = adinstruments.sdk.getNumberOfChannels(file_h)
            %
            %   Outputs:
            %   ===========================================================
            %   n_channels : The # of physical channels of recorded data
            %   across all records. For some records some channels may not
            %   have any data. A channel is identified by (??? name ??,
            %   hardware id????, i.e. what makes channel unique?)
            %
            %   Status: DONE
            
            [result_code,n_channels] = sdk_mex(2,file_h.pointer_value);
            adinstruments.sdk.handleErrorCode(result_code)
            n_channels = double(n_channels);
        end
        %Record specific functions
        %------------------------------------------------------------------
        function n_ticks_in_record = getNTicksInRecord(file_h,record)
            %
            %
            %   n_ticks_in_record = adinstruments.sdk.getNTicksInRecord(file_h,record)
            %
            %   Returns the # of samples of channels with the highest data
            %   rate.
            %
            %   Inputs:
            %   =====================================
            %   record : double
            %       Record #, 1 based.
            %
            %   Outputs:
            %   ===========================================================
            %   n_ticks_in_record : This is equivalent to asking how many
            %       samples were obtained from the channels with the highest
            %       sampling rate
            %
            %   Status: DONE

            [result_code,n_ticks_in_record] = sdk_mex(3,file_h.pointer_value,c0(record));
            adinstruments.sdk.handleErrorCode(result_code)
            n_ticks_in_record = double(n_ticks_in_record);
            
        end
        function dt_tick = getTickPeriod(file_h,record,channel)
            %
            %
            %   dt_tick = adinstruments.sdk.getTickPeriod(file_handle,record,channel)
            %
            %   Outputs:
            %   ===========================================================
            %   dt_tick :
            %
            %   STATUS: DONE
            
            [result_code,dt_tick] = sdk_mex(4,file_h.pointer_value,c0(record),c0(channel));
            adinstruments.sdk.handleErrorCode(result_code)
        end
        %Comment specific functions
        %------------------------------------------------------------------
        function comments_h = getCommentAccessor(file_h,record,tick_dt)
            %
            %
            %   comments_h = adinstruments.sdk.getCommentAccessor(file_handle,record_idx_0b)
            %
            %   comments_h :adinstruments.comment_handle
            
            [result_code,comment_pointer] = sdk_mex(6,file_h.pointer_value,c0(record));
            if adinstruments.sdk.isMissingCommentError(result_code)
                comments_h  = adinstruments.comment_handle(0,false,record,tick_dt);
            else
                adinstruments.sdk.handleErrorCode(result_code)
                comments_h  = adinstruments.comment_handle(comment_pointer,true,record,tick_dt);
            end
        end
        function closeCommentAccessor(pointer_value)
            %
            %
            %   adinstruments.sdk.closeCommentAccessor(pointer_value);
            %
            %   This should only be called by:
            %   adinstruments.comment_handle
            
            result_code = sdk_mex(7,pointer_value);
            adinstruments.sdk.handleErrorCode(result_code);
        end
        function has_another_comment  = advanceComments(comments_h)
            %
            %
            %   has_another_comment = adinstruments.sdk.advanceComments(comments_h);
            
            result_code = sdk_mex(9,comments_h.pointer_value);
            
            if adinstruments.sdk.isMissingCommentError(result_code)
                has_another_comment = false;
            else
                adinstruments.sdk.handleErrorCode(result_code);
                has_another_comment = true;
            end
            
        end
        function comment_info = getCommentInfo(comments_h)
            %
            %
            %   comment_info = adinstruments.sdk.getCommentInfo(comments_h)
            
            [result_code,comment_string_data,comment_length,tick_pos,channel,comment_num] = sdk_mex(8,comments_h.pointer_value);
            
            d = @double;
            
            if result_code == 0
                comment_string = adinstruments.sdk.getStringFromOutput(comment_string_data,comment_length);
                comment_info   = adinstruments.comment(comment_string,d(tick_pos),d(channel),d(comment_num),comments_h.record,comments_h.tick_dt);
            else
                adinstruments.sdk.handleErrorCode(result_code);
                comment_info = [];
            end
        end
        %Channel specific functions
        %------------------------------------------------------------------
        function n_samples    = getNSamplesInRecord(file_h,record,channel)
            %
            %
            %   n_samples  = adinstruments.sdk.getNSamplesInRecord(file_h,record,channel)
            %
            %   INPUTS
            %   ===========================================
            %   record  : (0 based)
            %   channel : (0 based)
            %
            %   Status: DONE

            [result_code,n_samples] = sdk_mex(5,file_h.pointer_value,c0(record),c0(channel));
            adinstruments.sdk.handleErrorCode(result_code)
            n_samples = double(n_samples);
        end
        function output_data  = getChannelData(file_h,record,channel,start_sample,n_samples_get,get_samples)
            %
            %
            %   output_data  = adinstruments.sdk.getChannelData(...
            %                       file_h,record,channel,start_sample,n_samples_get,get_samples)
            %
            %   INPUTS
            %   ========================================
            %   channel_0b : channel to get the data from, 0 based, i.e.
            %                first channel is channel 0
            %   record_0b  : record to get the data from
            %   start_sample_0b : first sample to get
            %   n_samples :
            %   get_samples : If true data is returned as samples, if
            %   false, the data are upsampled (sample & hold) to the
            %   highest rate ...
            %
            
            data_type = c(0);
            if ~get_samples
                %get in tick units
                data_type = bitset(data_type,32);
            end
            
            [result_code,data,n_returned] = sdk_mex(10,...
                file_h.pointer_value,c0(channel),...
                c0(record),c0(start_sample),...
                c(n_samples_get),data_type);
            
            adinstruments.sdk.handleErrorCode(result_code)
            
            if n_returned ~= n_samples_get
                %TODO: truncate data
                error('Why was this truncated???')
            end
            
            output_data = double(data); %Matlab can get finicky working with singles
            
        end
        function units        = getUnits(file_h,record,channel)
            %getUnits
            %
            %   units = adinstruments.sdk.getUnits(file_h,record,channel)

            
            [result_code,str_data,str_length] = sdk_mex(11,file_h.pointer_value,c0(record),c0(channel));
            
            %TODO: Replace with function call to isGoodResultCode
            if result_code == 0 || result_code == 1
                units = adinstruments.sdk.getStringFromOutput(str_data,str_length);
            else
                adinstruments.sdk.handleErrorCode(result_code);
                units = '';
            end
            
        end
        function channel_name = getChannelName(file_h,channel)
            %
            %
            %   channel_name = adinstruments.sdk.getChannelName(file_h,channel)
            %
            %   Status: DONE
            
            [result_code,str_data,str_length] = sdk_mex(12,file_h.pointer_value,c0(channel));
            
            if result_code == 0
                channel_name = adinstruments.sdk.getStringFromOutput(str_data,str_length);
            else
                adinstruments.sdk.handleErrorCode(result_code);
                channel_name = '';
            end
            
        end
        function dt_channel   = getSamplePeriod(file_h,record,channel)
            %
            %
            %   dt_channel   = getSamplePeriod(file_h,channel,record)
            %
            %   This should return the sample period, the inverse of the
            %   sampling rate, for a single channel.
            %
            %   For channels with NO SAMPLES, the dt returned is NaN
            %
            %   Alternatively, I can ask:
            %   A) # of ticks in record
            %   B) tick period
            %   C) # of samples in record
            %
            %   sample period = 
            
            n_samples_in_record = adinstruments.sdk.getNSamplesInRecord(file_h,record,channel);
            if n_samples_in_record == 0
                dt_channel = NaN;
                return
            end
            
%             n_ticks_in_record   = adinstruments.sdk.getNTicksInRecord(file_h,record);
%             tick_dt             = adinstruments.sdk.getTickPeriod(file_h,record,channel);
%             dt_channel_temp = tick_dt * n_ticks_in_record/n_samples_in_record;
            
            [result_code,dt_channel] = sdk_mex(15,file_h.pointer_value,c0(record),c0(channel));

            adinstruments.sdk.handleErrorCode(result_code)
        end
        %Helper functions
        %------------------------------------------------------------------
        function is_ok = checkNullChannelErrorCodes(result_code)
            %
            %
            %    is_ok = adinstruments.sdk.checkNullChannelErrorCodes(result_code)
            %
            %    For some reason there is a non-zero error code when
            %    retrieving information about a channel during a record in
            %    which there is no data for that channel. The error message
            %    is: "the operation completed successfully"
            
            is_ok = result_code == 0 || result_code == 1;
            %result_code == 1
            %"the operation completed successfully"
        end
        function hex_value = resultCodeToHex(result_code)
            %
            %   hex_value = adinstruments.sdk.handleErrorCode(result_code)
            %
            %   Returns the hex_value of the result code for comparision
            %   with the values in the C header.
            
            temp      = typecast(result_code,'uint32');
            hex_value = dec2hex(temp);
        end
        function is_missing_comment_code = isMissingCommentError(result_code)
            %
            %
            %   is_missing_comment_code = adinstruments.sdk.isMissingCommentError(result_code)
            
            
            %TODO: Do I want to do the literal error check here instead
            %of the mod????
            
            %Relevant Link:
            %http://forum.adinstruments.com/viewtopic.php?f=7&t=551
            
            %If there are no comments, the result_code is:
            %-1610313723 - data requested not present => xA0049005
            
            is_missing_comment_code = mod(result_code,16) == 5;
            
        end
        function handleErrorCode(result_code)
            %
            %
            %   adinstruments.sdk.handleErrorCode(result_code)
            %
            %   If there is an error this function will throw an error
            %   and display the relevant error string given the error code
            
            %Relevant forum post:
            %http://forum.adinstruments.com/viewtopic.php?f=7&t=551
            
            if ~adinstruments.sdk.checkNullChannelErrorCodes(result_code)
            %if result_code ~= 0
                temp      = sl.stack.calling_function_info;
                errorID   = sprintf('ADINSTRUMENTS:SDK:%s',temp.name);
                error_msg = adinstruments.sdk.getErrorMessage(result_code);
                
                
                %TODO: Create a clean id - move to a function
                %The ID is not allowed to have periods in it
                %Also, the calling function info isn't a clean name
                %(I think it includes SDK, but what if I only wanted the
                %name, not the full path ...???)
                %
                errorID = regexprep(errorID,'\.',':');
                
                error(errorID,[errorID '  ' error_msg]);
            end
            
            %Copied from ADIDatCAPI_mex.h 5/6/2014
% % %                typedef enum ADIResultCode
% % %       {
% % %       //Win32 error codes (HRESULTs)
% % %       kResultSuccess = 0,                             // operation succeeded
% % %       kResultErrorFlagBit        = 0x80000000L,       // high bit set if operation failed
% % %       kResultInvalidArg          = 0x80070057L,       // invalid argument. One (or more) of the arguments is invalid
% % %       kResultFail                = 0x80004005L,       // Unspecified error
% % %       kResultFileNotFound        = 0x80030002L,       // failure to find the specified file (check the path)
% % % 
% % % 
% % %       //Start of error codes specific to this API      
% % %       kResultADICAPIMsgBase        = 0xA0049000L,
% % % 
% % %       kResultFileIOError  = kResultADICAPIMsgBase,    // file IO error - could not read/write file
% % %       kResultFileOpenFail,                            // file failed to open
% % %       kResultInvalidFileHandle,                       // file handle is invalid
% % %       kResultInvalidPosition,                         // pos specified is outside the bounds of the record or file
% % %       kResultInvalidCommentNum,                       // invalid commentNum. Comment could not be found
% % %       kResultNoData,                                  // the data requested was not present (e.g. no more comments in the record).
% % %       kResultBufferTooSmall                          // the buffer passed to a function to receive data (e.g. comment text) was not big enough to receive all the data.
% % %       
% % %                                                       // new result codes must be added at the end
% % %       } ADIResultCode;
            
        end
        function error_msg = getErrorMessage(result_code)
            %
            %
            %   error_msg = adinstruments.sdk.getErrorMessage(result_code)
            
            [~,err_msg_data,err_msg_len] = sdk_mex(14,int32(result_code));
            error_msg = adinstruments.sdk.getStringFromOutput(err_msg_data,err_msg_len);
        end
        function str = getStringFromOutput(int16_data,str_length)
            %
            %   This is a helper function for whenever we get a string out.
            %
            %   str = adinstruments.sdk.getStringFromOutput(int16_data,str_length)
            %
            %   TODO: Make hidden
            %
            
            %str_length - apparently contains the null character, we'll
            %ignore the null character here ...
            str = char(int16_data(1:str_length-1));
        end
    end
    
end

