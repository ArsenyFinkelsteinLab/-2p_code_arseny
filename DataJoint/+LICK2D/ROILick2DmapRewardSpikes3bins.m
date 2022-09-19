%{
# Delta 2D tuning maps between different reward conditions, and corresponding stats
-> EXP2.SessionEpoch
-> IMG.ROI
number_of_bins                          : int   #
---
delta_lickmap_fr_regular_vs_large             : blob   # Delta 2D tuning map, between regular and large reward
delta_lickmap_fr_regular_vs_large_odd         : blob   # Delta 2D tuning map, between regular and large odd reward  trials
delta_lickmap_fr_regular_vs_large_even        : blob   # Delta 2D tuning map, between regular and large even reward  trials
delta_lickmap_fr_regular_vs_small             : blob   # Delta 2D tuning map, between regular and small reward
delta_lickmap_fr_regular_vs_small_odd         : blob   # Delta 2D tuning map, between regular and small odd reward  trials
delta_lickmap_fr_regular_vs_small_even        : blob   # Delta 2D tuning map, between regular and small even reward  trials
%}


classdef ROILick2DmapRewardSpikes3bins < dj.Computed
    properties
        keySource = (EXP2.SessionEpoch*IMG.FOV) & LICK2D.ROILick2DmapPSTHSpikes3bins - IMG.Mesoscope;
    end
    methods(Access=protected)
        function makeTuples(self, key)
            
            min_modulation = 0.25; %every PSTH below this modulation is ignored
            min_percent_coverage=50; % minimal coverage needed for 2D map calculation
            
            rel_meso = IMG.Mesoscope & key;
            if rel_meso.count>0 % if its mesoscope data
                fr_interval = [-2, 5]; % used it for the mesoscope
                fr_interval_limit= [-2, 5]; % for comparing firing rates between conditions and computing firing-rate maps
            else  % if its not mesoscope data
                fr_interval = [-1, 4];
                fr_interval_limit= [0, 3]; % for comparing firing rates between conditions and computing firing-rate maps
            end
            
            key_roi = fetch(LICK2D.ROILick2DmapPSTHSpikes3bins & key);
            rel=LICK2D.ROILick2DmapPSTHSpikes3bins*LICK2D.ROILick2DmapSpikes3bins*LICK2D.ROILick2DmapPSTHStabilitySpikes3bins*LICK2D.ROILick2DPSTHStatsSpikes;
            D = fetch(rel & key,'psth_per_position_regular','psth_per_position_large','psth_per_position_small',...
                'psth_per_position_first','psth_per_position_begin','psth_per_position_mid','psth_per_position_end',...
                'psth_per_position_regular_odd', 'psth_per_position_regular_even', ...
                'psth_per_position_small_odd', 'psth_per_position_small_even',...
                'psth_per_position_large_odd','psth_per_position_large_even',...,
                'lickmap_fr_regular','lickmap_fr_small','lickmap_fr_large','reward_mean_small',...
                'reward_mean_regular','reward_mean_large','reward_mean_small');
            
            psthmap_time = fetch1(rel,'psthmap_time','LIMIT 1');
            for i_roi = 1:1:numel(key_roi)
                PSTH_bins1 = D(i_roi).psth_per_position_regular;
                PSTH_bins2 = D(i_roi).psth_per_position_large;
                reward_mean_regular = D(i_roi).reward_mean_regular;
                reward_mean_large = D(i_roi).reward_mean_large;
                reward_mean_small = D(i_roi).reward_mean_small;
                
                delta_MAP = fn_compute_delta_map_from_PSTH_per_bin_difference(PSTH_bins1, PSTH_bins2, psthmap_time, fr_interval_limit,reward_mean_regular,reward_mean_large );
                [information_per_spike_,field_size, field_size_without_baseline, centroid, centroid_without_baseline, percent_coverage, preferred_bin] ...
                    = fn_compute_generic_2D_field_stats (delta_MAP, min_percent_coverage);
                
                
                %                 delta_lickmap_fr_regular_vs_large             : blob   # Delta 2D tuning map, between regular and large reward
                % delta_lickmap_fr_regular_vs_large_odd         : blob   # Delta 2D tuning map, between regular and large odd reward  trials
                % delta_lickmap_fr_regular_vs_large_even        : blob   # Delta 2D tuning map, between regular and large even reward  trials
                %
                %                 corr_deltamap_regular_vs_large_odd_even=null                     : double   #
                % corr_deltamap_regular_vs_small_odd_even=null                     : double   #
                %
                % corr_deltamap_regular_vs_large_with_map_regular=null             : double   #
                % corr_deltamap_regular_vs_small_with_map_regular=null             : double   #
                %
                % information_per_spike_deltamap_regular_vs_large=null             : double   #
                % information_per_spike_deltamap_regular_vs_small=null             : double   #
                %
                % preferred_bin_deltamap_regular_vs_large=null                     : double   #
                % preferred_bin_deltamap_regular_vs_small=null                     : double   #
                %
                % centroid_without_baseline_deltamap_regular_vs_large=null         : blob     #
                % centroid_without_baseline_deltamap_regular_vs_small=null         : blob     #
                %
                % field_size_deltamap_regular_vs_large=null                        : double   # 2D Field size at half max, expressed as percentage
                % field_size_deltamap_regular_vs_small=null                        : double   # 2D Field size at half max, expressed as percentage
                %
                % modulation_percent_regular_vs_large=null                         : double   # modulation percentage 100*regular/large
                % modulation_percent_regular_vs_small=null                         : double   # modulation percentage 100*regular/small
                
                
            end
            insert(self,key_roi);
        end
        % % also populates
        %     self2=LICK2D.ROILick2DmapRewardStatsSpikes3bins;
        
        
    end
end
