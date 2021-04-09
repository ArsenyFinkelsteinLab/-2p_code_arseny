%{
# Flourescent trace
-> EXP2.SessionEpoch
-> IMG.ROI
---
dff_trace      : longblob   # (s) delta f over f
%}


classdef ROIdeltaF < dj.Imported
    properties
        keySource = EXP2.SessionEpoch  & IMG.ROITrace;
    end
    methods(Access=protected)
        function makeTuples(self, key)
            
            running_window=60; %seconds
            
            try
                frame_rate= fetch1(IMG.FOVEpoch & key, 'imaging_frame_rate');
            catch
                frame_rate= fetch1(IMG.FOV & key, 'imaging_frame_rate');
            end
            
            % Will affect the baseline estimation for delfta/F calculation. Will require more fine adjustment for different frame rates
            if frame_rate>10
                smooth_window_multiply_factor =5;
            else
                smooth_window_multiply_factor =1;
            end
            
            
            key_ROITrace=fetch(IMG.ROI&key,'ORDER BY roi_number');
            
            key_mean_dff = key_ROITrace;
            key_mean_f = key_ROITrace;

            Fall=fetchn(IMG.ROITrace &key,'f_trace','ORDER BY roi_number');
            
            for iROI=1:1:size(Fall,1)
                iROI;
                F=Fall{iROI};
                Fs=smoothdata(F,'gaussian',running_window*smooth_window_multiply_factor); % for baseline estimation only
                
                running_min=movmin(Fs,[running_window*frame_rate running_window*frame_rate],'Endpoints','fill');
                baseline=movmax(running_min,[running_window*frame_rate running_window*frame_rate],'Endpoints','fill'); %running max of the running min
                baseline2=smoothdata(baseline,'gaussian',running_window*frame_rate);
                dFF = (F-baseline2)./baseline2; %deltaF over F
                
                
                k2=key_ROITrace(iROI);
                k2.dff_trace = dFF;
                k2.session_epoch_type = key.session_epoch_type;
                k2.session_epoch_number = key.session_epoch_number;
                
                insert(self,k2);
                
                key_mean_dff(iROI).session_epoch_type = key.session_epoch_type;
                key_mean_dff(iROI).session_epoch_number = key.session_epoch_number;
                key_mean_dff(iROI).mean_dff = mean(dFF);
                
                key_mean_f(iROI).session_epoch_type = key.session_epoch_type;
                key_mean_f(iROI).session_epoch_number = key.session_epoch_number;
                key_mean_f(iROI).mean_f = mean(F);

                
            end
            insert(IMG.ROIdeltaFMean , key_mean_dff);
            insert(IMG.ROIFMean , key_mean_f);
          
        end
    end
end