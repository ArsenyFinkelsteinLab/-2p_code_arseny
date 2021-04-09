%{
# Session epoch frames
-> EXP2.SessionEpoch
---
session_epoch_start_frame    : double   # (s) session epoch start frame relative to the beginning of  the session
session_epoch_end_frame      : double   # (s) session epoch start frame relative to the beginning of  the session
%}


classdef SessionEpochFrame < dj.Imported
    methods(Access=protected)
        function makeTuples(self, key)
            
             dir_data2 = [dir_data '\' DirNames{iDir}];
        temp = dir(dir_data2); %gets  the names of all files and nested directories in this folder
        subDirNames = {temp([temp.isdir]).name}; %gets only the names of all files
        subDirNames = subDirNames(3:end);
        subDirNames = subDirNames(contains(subDirNames,'data'));
        
        key=rmfield(key,'session_date');
        k=key;
        
        session_start_time = 0;
        session_start_frame = 0;
        session_frames_timestamps =[];
        for jDir = 1:1:numel (subDirNames)
            dir_data3 = [dir_data2 '\' subDirNames{jDir} '\'];
            if contains(subDirNames{jDir},'spont')
                k.session_epoch_type = 'spontaneous only';
            elseif contains(subDirNames{jDir},'photo')
                k.session_epoch_type = 'spontaneous photostim';
            elseif contains(subDirNames{jDir},'behav')
                k.session_epoch_type = 'behavior only';
            end
            k.session_epoch_number = jDir;
            k2=k;
            k3=k;
            
            allFiles = dir(dir_data3); %gets  the names of all files and nested directories in this folder
            allFileNames = {allFiles(~[allFiles.isdir]).name}; %gets only the names of all files
            allFileNames =allFileNames(contains(allFileNames,'.tif'))';
            
            
            %initialzing
            frames_timestamps=cell(numel(allFileNames),1);
            parfor ifile=1:1:numel(allFileNames)
                [header]=scanimage.util.opentif([dir_data3,allFileNames{ifile}]);
                frames_timestamps{ifile} = header.frameTimestamps_sec;
            end
            
            frames_timestamps=cell2mat(frames_timestamps') + session_start_time;
            session_frames_timestamps = [session_frames_timestamps, frames_timestamps];
            
            k2.session_epoch_start_time =  frames_timestamps(1) ;
            k3.session_epoch_start_frame = 1 + session_start_frame;
            
            k2.session_epoch_end_time = frames_timestamps(end);
            k3.session_epoch_end_frame = numel(frames_timestamps) + session_start_frame;
            
            insert(EXP2.SessionEpoch, k2 );
            session_start_time = k2.session_epoch_end_time + 100;
            
            insert(IMG.SessionEpochFrame, k3 );
            session_start_frame = k3.session_epoch_end_frame;
            
        end
        k4=key;
        k4.frame_timestamps = session_frames_timestamps;
        insert(IMG.FrameTime, k4);
        
        
        [header]=scanimage.util.opentif([dir_data3,allFileNames{1}]);
        k5=key;
        k5.fov_num=1;
        k5.fov_name='fov';
        k5.fov_x_size = header.SI.hRoiManager.pixelsPerLine;
        k5.fov_y_size = header.SI.hRoiManager.pixelsPerLine;
        k5.imaging_frame_rate = header.SI.hRoiManager.scanFrameRate  ;
        insert(IMG.FOV, k5);
        
        k6=key;
        k6.fov_num=1;
        k6.plane_num=1;
        k6.channel_num=1;
        
        insert(IMG.Plane, k6);
        
            
            
            insert(self, key);
        end
    end
end