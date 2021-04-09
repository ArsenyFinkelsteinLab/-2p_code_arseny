%{
# Pairwise correlation as a function of distance
-> EXP2.SessionEpoch
threshold_for_event             : double     # threshold in deltaf_overf
num_svd_components_removed      : int     # how many of the first svd components were removed
---
corr_histogram                        :blob        # histogram of all pairwise correlations
corr_histogram_bins                   :blob        # corresponding bins
distance_corr_all                     :blob        # average pairwise pearson coeff, binned according to lateral distance between neurons
distance_corr_positive                :blob        # average positive pairwise pearson coeff, binned according to lateral distance between neurons
distance_corr_negative                :blob        # average negative pairwise pearson coeff, binned according to lateral distance between neurons
distance_bins                         :blob        # corresponding bins
corr_histogram_per_distance           :longblob    # a matrix containing, for each distance bin, the histogram of correlations in this distance bin, binned into corr_histogram_bins
variance_explained_components         :blob        # by the SVD components
%}


classdef CorrPairwiseDistanceSVDNeuropilSubtract < dj.Computed
    properties
        keySource = ((EXP2.SessionEpoch  & IMG.ROI & IMG.ROIdeltaFNeuropilSubtr) - EXP2.SessionEpochSomatotopy)& IMG.PlaneCoordinates & IMG.Mesoscope;
    end
    methods(Access=protected)
        function makeTuples(self, key)
            
            rel_roi = IMG.ROI - IMG.ROIBad;
            
            close all;
            %Graphics
            %---------------------------------
            figure;
            set(gcf,'DefaultAxesFontName','helvetica');
            set(gcf,'PaperUnits','centimeters','PaperPosition',[0 0 23 30]);
            set(gcf,'PaperOrientation','portrait');
            set(gcf,'Units','centimeters','Position',get(gcf,'paperPosition')+[3 0 0 0]);
            set(gcf,'color',[1 1 1]);
            
            dir_base = fetch1(IMG.Parameters & 'parameter_name="dir_root_save"', 'parameter_value');
            dir_save_fig = [dir_base  '\POP\corr_distance\neuropil_subtracted\'];
            
            
            time_bin=1.5; %s
            threshold_for_event_vector = [0];
            num_svd_components_removed_vector = [0, 1, 10, 100, 500];
            %              num_svd_components_removed_vector = [1000];
            
            
            corr_histogram_bins=[-0.5:0.01:0.5];
            %             distance_bins=[0:50:100,200:100:1000,1250:250:5000]; % in microns
            %             distance_bins=[0:50:450,500:250:2750,3000:1000:6000]; % in microns
            distance_bins=[0:25:200,250:50:450,500:250:4000]; % in microns
            
            key.corr_histogram_bins=corr_histogram_bins;
            key.distance_bins=distance_bins;
            
            
            %             min_num_events = 20; %per hour
            try
                imaging_frame_rate= fetch1(IMG.FOVEpoch & key, 'imaging_frame_rate');
            catch
                imaging_frame_rate = fetch1(IMG.FOV & key, 'imaging_frame_rate');
            end
            
            
            %% Loading Data
            rel_temp = IMG.Mesoscope & key;
            rel_data = IMG.ROIdeltaFNeuropilSubtr;

           roi_list=fetchn(rel_data &key,'roi_number','ORDER BY roi_number');
            chunk_size=500;
            counter=0;
            for i_chunk=1:chunk_size:roi_list(end)
                roi_interval = [i_chunk, i_chunk+chunk_size];
                temp_F=cell2mat(fetchn(rel_data & key & sprintf('roi_number>=%d',roi_interval(1)) & sprintf('roi_number<%d',roi_interval(2)),'dff_trace','ORDER BY roi_number'));
                temp_count=(counter+1):1: (counter + size(temp_F,1));
                Fall(temp_count,:)=temp_F;
                counter = counter + size(temp_F,1);
            end
            
            
            %% binning in time
            bin_size_in_frame=ceil(time_bin*imaging_frame_rate);
            
            bins_vector=1:bin_size_in_frame:size(Fall,2);
            bins_vector=bins_vector(2:1:end);
            for  i= 1:1:numel(bins_vector)
                ix1=(bins_vector(i)-bin_size_in_frame):1:(bins_vector(i)-1);
                F(:,i)=mean(Fall(:,ix1),2);
            end
            clear Fall temp_Fall
            
            
            %% Distance between all pairs
            
            x_all=fetchn(rel_roi &key,'roi_centroid_x','ORDER BY roi_number');
            y_all=fetchn(rel_roi &key,'roi_centroid_y','ORDER BY roi_number');
            z_all=fetchn(rel_roi*IMG.PlaneCoordinates & key,'z_pos_relative','ORDER BY roi_number');
            
            x_pos_relative=fetchn(rel_roi*IMG.PlaneCoordinates &key,'x_pos_relative','ORDER BY roi_number');
            y_pos_relative=fetchn(rel_roi*IMG.PlaneCoordinates &key,'y_pos_relative','ORDER BY roi_number');
            
            x_all = x_all + x_pos_relative; x_all = x_all/0.75;
            y_all = y_all + y_pos_relative; y_all = y_all/0.5;
            
            
            
            dXY=zeros(numel(x_all),numel(x_all));
            %             d3D=zeros(numel(x_all),numel(x_all));
            parfor iROI=1:1:numel(x_all)
                x=x_all(iROI);
                y=y_all(iROI);
                z=z_all(iROI);
                dXY(iROI,:)= sqrt((x_all-x).^2 + (y_all-y).^2); % in um
                %                 d3D(iROI,:) = sqrt((x_all-x).^2 + (y_all-y).^2 + (z_all-z).^2); % in um
            end
            
            
            %% Thresholding activity and computing SVD and correlations
            
            for i_th = 1:1:numel(threshold_for_event_vector)
                threshold= threshold_for_event_vector(i_th);
                
                for i_c = 1:1:numel(num_svd_components_removed_vector)
                    
                    %% We take neurons with enough events during spont + behav session combined
                    %                     if threshold==0
                    % %                         idx_enough_events=ones(size(F,1),1);
                    %                     else
                    
                    %                         kkk=key;
                    %                         kkk.session_epoch_type='spont_only';
                    %                         kkk.threshold_for_event=threshold;
                    %                         epoch_spont_duration = fetchn(IMG.SessionEpochFrame & kkk, 'session_epoch_end_frame');
                    %                         events_spont = fetchn((IMG.ROIdeltaFPeak-EXP2.SessionEpochSomatotopy) & kkk, 'number_of_events','ORDER BY roi_number');
                    %
                    %
                    %                         kkk=key;
                    %                         kkk.session_epoch_type='behav_only';
                    %                         kkk.threshold_for_event=threshold;
                    %                         epoch_behav_duration = fetchn(IMG.SessionEpochFrame & kkk, 'session_epoch_end_frame');
                    %                         events_behav = fetchn((IMG.ROIdeltaFPeak-EXP2.SessionEpochSomatotopy) & kkk, 'number_of_events','ORDER BY roi_number');
                    %
                    %                         if isempty(events_behav)
                    %                             events=events_spont;
                    %                             duration = epoch_spont_duration;
                    %                         elseif isempty(events_spont)
                    %                             events=events_behav;
                    %                             duration = epoch_behav_duration;
                    %                         else
                    %                             events = events_behav + events_spont;
                    %                             duration = epoch_spont_duration + epoch_behav_duration;
                    %                         end
                    %                         duration_hours=(duration/imaging_frame_rate)/3600;
                    %                         idx_enough_events = events>=(duration_hours*min_num_events);
                    %                     end
                    
                    F_thresholded=F;
                    if threshold>0
                        F_thresholded(F<=threshold)=0;
                    end
                    %                     F_thresholded = F_thresholded(idx_enough_events,:);
                    rho=[];
                    F_thresholded = gpuArray((F_thresholded));
                    if num_svd_components_removed_vector(i_c)>0
                        num_comp = num_svd_components_removed_vector(i_c);
                        %                         F_thresholded = F_thresholded-mean(F_thresholded,2);
                        F_thresholded=zscore(F_thresholded,[],2);
                        
                        [U,S,V]=svd(F_thresholded); % S time X neurons; % U time X time;  V neurons x neurons
                        
                        singular_values =diag(S);
                        
                        variance_explained=singular_values.^2/sum(singular_values.^2); % a feature of SVD. proportion of variance explained by each component
                        %                         cumulative_variance_explained=cumsum(variance_explained);
                        
                        U=U(:,(1+num_comp):end);
                        %             S=S(1:num_comp,1:num_comp);
                        V=V(:,(1+num_comp):end);
                        S = S((1+num_comp):end, (1+num_comp):end);
                        
                        
                        F_reconstruct = U*S*V';
                        clear U S V F_thresholded
                        
                        try
                            rho=corrcoef(F_reconstruct');
                            rho=gather(rho);
                        catch
                            F_reconstruct=gather(F_reconstruct);
                            rho=corrcoef(F_reconstruct');
                        end
                        key.variance_explained_components=gather(variance_explained);
                    else
                        try
                            rho=corrcoef(F_thresholded');
                            rho=gather(rho);
                        catch
                            F_thresholded=gather(F_thresholded);
                            rho=corrcoef(F_thresholded');
                        end
                        key.variance_explained_components=NaN;
                    end
                    
                    
                    key.threshold_for_event = threshold;
                    key.num_svd_components_removed = num_svd_components_removed_vector(i_c);
                    % Bin correlation by distance
                    kk=fn_POP_bin_pairwise_corr_by_distance(key, rho, dXY, threshold_for_event_vector, i_th,i_c, corr_histogram_bins, distance_bins, num_svd_components_removed_vector);
                    
                    insert(self,kk);
                end
            end
            
            
            session_date = fetch1(EXP2.Session & key,'session_date');
            session_epoch_type = fetch1(EXP2.SessionEpoch & key, 'session_epoch_type');
            if strcmp(session_epoch_type,'spont_only')
                session_epoch_label = 'Spontaneous';
            elseif strcmp(session_epoch_type,'behav_only')
                session_epoch_label = 'Behavior';
                      elseif strcmp(session_epoch_type,'spont_photo')
                session_epoch_label = 'SpontaneousPhotosim';
            end
            
            filename = ['anm' num2str(key.subject_id) '_s' num2str(key.session) '_' session_date '_' session_epoch_label num2str(key.session_epoch_number)];
            if isempty(dir(dir_save_fig))
                mkdir (dir_save_fig)
            end
            %
            figure_name_out=[ dir_save_fig filename];
            eval(['print ', figure_name_out, ' -dtiff  -r150']);
            % eval(['print ', figure_name_out, ' -dpdf -r200']);
            
            
            
        end
    end
end

