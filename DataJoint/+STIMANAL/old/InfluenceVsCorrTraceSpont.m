%{
# Correlation versus influence, and Influence versus Correlation. Binned
-> EXP2.SessionEpoch
neurons_or_control     :boolean              # 1 - neurons, 0 control
response_p_val                  : double      # response p-value of influence cell pairs for inclusion. 1 means we take all pairs
num_svd_components_removed_corr : int     # how many of the first svd components were removed for computing correlations
---
influence_binned_by_corr                        :blob    # Influence versus Correlation.
corr_binned_by_influence                        :blob    # Correlation versus Iinfluence.
bins_influence_edges                            :blob    # bin-edges for binning influence
bins_corr_edges                                 :blob    # bin-edges for binning correlation
num_targets                                     :int     # num targets included
num_pairs                                       :int     # num pairs included
%} 


classdef InfluenceVsCorrTraceSpont < dj.Computed
    properties
        keySource = EXP2.SessionEpoch & STIMANAL.Target2AllCorrTraceSpont & (EXP2.Session & STIM.ROIInfluence);
    end
    methods(Access=protected)
        function makeTuples(self, key)
            close all;
            
            neurons_or_control_flag = [1,0]; % 1 neurons, 0 control sites
            neurons_or_control_label = { 'Neurons','Controls'};
            p_val=[1]; % for influence significance %making it for more significant values requires debugging of the shuffling method
            num_svd_components_removed_vector_corr = [0,1,2,3,4,5,10,20,50,100];
            minimal_distance=25; %um exlude all cells within minimal distance from target
            % bins
            bins_corr{1} = linspace(-0.1,0.2,16); % if there is no SVD component/s subtraction
            bins_corr{2} = linspace(-0.1,0.1,16); % if there is  SVD component/s subtraction
            bins_influence = linspace(-0.3,0.3,16);
%             bins_influence=bins_influence(4:end);
            
            dir_base = fetch1(IMG.Parameters & 'parameter_name="dir_root_save"', 'parameter_value');
            dir_fig = [dir_base  '\Photostim\influence_vs_corr\corr_trace_behav\'];
            session_date = fetch1(EXP2.Session & key,'session_date');
            
            
            
            
            
            colormap=viridis(numel(num_svd_components_removed_vector_corr));
            
            for i_n = 1:1:numel(neurons_or_control_flag)
                key.neurons_or_control = neurons_or_control_flag(i_n);
                rel_target = IMG.PhotostimGroup & (STIMANAL.NeuronOrControl & key);
                rel_data_influence=STIM.ROIInfluence   & rel_target & 'num_svd_components_removed=0';
                
                group_list = fetchn(rel_target,'photostim_group_num','ORDER BY photostim_group_num');
                if numel(group_list)<1
                    return
                end
                
                DataStim=cell(numel(group_list),1);
                DataStim_pval=cell(numel(group_list),1);
                DataStim_num_of_baseline_trials_used=cell(numel(group_list),1);
                DataStim_num_of_target_trials_used=cell(numel(group_list),1);
                DataStim_distance_lateral=cell(numel(group_list),1);

                for i_g = 1:1:numel(group_list)
                    rel_data_influence_current = [rel_data_influence & ['photostim_group_num=' num2str(group_list(i_g))]];
                    DataStim{i_g} = fetchn(rel_data_influence_current,'response_mean', 'ORDER BY roi_number')';
                    DataStim_pval{i_g} = fetchn(rel_data_influence_current,'response_p_value1', 'ORDER BY roi_number')';
                    DataStim_num_of_baseline_trials_used{i_g} = fetchn(rel_data_influence_current,'num_of_baseline_trials_used', 'ORDER BY roi_number')';
                    DataStim_num_of_target_trials_used{i_g} = fetchn(rel_data_influence_current,'num_of_target_trials_used', 'ORDER BY roi_number')';
                    DataStim_distance_lateral{i_g}=fetchn(rel_data_influence_current,'response_distance_lateral_um', 'ORDER BY roi_number')';
                end
                DataStim = cell2mat(DataStim);
                DataStim_distance_lateral = cell2mat(DataStim_distance_lateral);
                DataStim_num_of_baseline_trials_used = cell2mat(DataStim_num_of_baseline_trials_used);
                DataStim_num_of_target_trials_used = cell2mat(DataStim_num_of_target_trials_used);

                idx_include = true(size(DataStim_distance_lateral));
                idx_include(DataStim_distance_lateral<=minimal_distance  )=false; %exlude all cells within minimal distance from target
                idx_include(DataStim_num_of_baseline_trials_used==0  )=false; %exlude all cells within minimal distance from target
                idx_include(DataStim_num_of_target_trials_used==0  )=false; %exlude all cells within minimal distance from target

                
                DataStim(~idx_include)=NaN;
                
                
                for i_p=1:1:numel(p_val)
                    
                    idx_DataStim_pval=cell(numel(group_list),1);
                    parfor i_g = 1:1:numel(group_list)
                        idx_DataStim_pval{i_g} = DataStim_pval{i_g}<=p_val(i_p);
                    end
                    idx_DataStim_pval = cell2mat(idx_DataStim_pval);
                    
                    for i_c = 1:1:numel(num_svd_components_removed_vector_corr)
                        num_comp = num_svd_components_removed_vector_corr(i_c);
                        key_component_corr.num_svd_components_removed_corr = num_comp;
                        
                        if num_svd_components_removed_vector_corr(i_c)==0
                            bins_corr_to_use = bins_corr{1};
                        else
                            bins_corr_to_use = bins_corr{2};
                        end
                        
                        rel_data_corr=STIMANAL.Target2AllCorrTraceSpont & rel_target & 'threshold_for_event=0' & key_component_corr;
                        DataCorr = cell2mat(fetchn(rel_data_corr,'rois_corr', 'ORDER BY photostim_group_num'));
                        
                        if numel(DataCorr(:)) ~= numel(DataStim(:))
                            a=1
                        end
                        
                        DataCorr(~idx_include)=NaN;

                        % influence as a funciton of correlation
                        x=DataCorr(idx_DataStim_pval);
                        y=DataStim(idx_DataStim_pval);
                        [influence_binned_by_corr]= fn_bin_data(x,y,bins_corr_to_use);
                        
                        
                        x=DataStim(idx_DataStim_pval);
                        y=DataCorr(idx_DataStim_pval);
                        [corr_binned_by_influence]= fn_bin_data(x,y,bins_influence);
                        
                        
                        if num_svd_components_removed_vector_corr(i_c)==0
                            idx_subplot = 0;
                        else
                            idx_subplot = 2;
                        end
                        subplot(2,2,idx_subplot+1)
                        bins_influence_centers = bins_influence(1:end-1) + diff(bins_influence)/2;
                        hold on
                        plot(bins_influence_centers,corr_binned_by_influence,'-','Color',colormap(i_c,:))
                        xlabel ('Influence (dff)');
                        ylabel('Correlation, r');
                        if i_c==1
                            title(sprintf('Target: %s pval %.3f\n  anm%d session%d %s epoch%d ',neurons_or_control_label{i_n},p_val(i_p), key.subject_id,key.session,session_date, key.session_epoch_number));
                        end
                        
                        
                        subplot(2,2,idx_subplot+2)
                        hold on
                        bins_corr_centers = bins_corr_to_use(1:end-1) + diff(bins_corr_to_use)/2;
                        plot(bins_corr_centers,influence_binned_by_corr,'-','Color',colormap(i_c,:))
                        xlabel('Correlation, r');
                        ylabel ('Influence (dff)');
                        if i_c==1
                            title(sprintf('\n\nSVD removed %d',num_svd_components_removed_vector_corr(i_c)));
                        elseif i_c>=2
                            title(sprintf('\n\nSVD removed >=1'));
                        end
                        
                        
                        
                        
                        key_insert = key;
                        key_insert.num_svd_components_removed_corr = num_svd_components_removed_vector_corr(i_c);
                        key_insert.influence_binned_by_corr=influence_binned_by_corr;
                        key_insert.corr_binned_by_influence=corr_binned_by_influence;
                        key_insert.bins_corr_edges=bins_corr_to_use;
                        key_insert.bins_influence_edges=bins_influence;
                        key_insert.response_p_val=p_val(i_p);
                        key_insert.num_targets= numel(group_list);
                        key_insert.num_pairs=sum(~isnan(x));

                        insert(self, key_insert);
                    end
                    
                    
                    dir_current_fig = [dir_fig '\' neurons_or_control_label{i_n} '\pval_' num2str(p_val(i_p)) '\'];
                    if isempty(dir(dir_current_fig))
                        mkdir (dir_current_fig)
                    end
                    filename = ['anm' num2str(key.subject_id) 's' num2str(key.session) '_' session_date '_' 'epoch' num2str(key.session_epoch_number)];
                    figure_name_out=[ dir_current_fig filename];
                    eval(['print ', figure_name_out, ' -dtiff  -r100']);
                    % eval(['print ', figure_name_out, ' -dpdf -r200']);
                    
                    clf;
                end
            end
        end
    end
end

