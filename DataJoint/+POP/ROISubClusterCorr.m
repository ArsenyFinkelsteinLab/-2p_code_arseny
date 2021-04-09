%{
#
-> EXP2.SessionEpoch
-> IMG.ROI
n_clust                         : int
heirar_cluster_id               : int            # cluster to which this cell belongs. Note that this id is not unique, because clustering is done independently for different combinations of the primary keys, and the cluster_id would change accordingly
n_sub_clust                     : int
---
heirar_sub_cluster_id           : int            # sub cluster to which this cell belongs. Note that this id is not unique, because clustering is done independently for different combinations of the primary keys, and the cluster_id would change accordingly
heirar_sub_cluster_percent      : double         # percentage of cells belonging to this cluster
%}

classdef ROISubClusterCorr < dj.Computed
    properties
        
        keySource = (EXP2.SessionEpoch & IMG.ROIdeltaF & IMG.Mesoscope)- EXP2.SessionEpochSomatotopy;
        
    end
    methods(Access=protected)
        function makeTuples(self, key)
            
            dir_base =fetch1(IMG.Parameters & 'parameter_name="dir_root_save"', 'parameter_value');
            dir_save_figure = [dir_base 'Lick2D\Clusters\Corr\SubCluster\'];
            
            n_clust_vector = [100, 500, 1000];
            n_sub_clust_vector = [100,500];
            heirar_cluster_id_vector=1:1:5;
            clusterparam.metric='correlation'; %euclidean or correlation
            
            clusterparam.agregate_clusters_flag = 0; %itiratively agregate clusters smaller than min_cluster_percent by merging them to clusters with higest correlation to them
            
            clusterparam.corr_thresh_across_clusters_for_merging = 0.8; %won't merge clusters that has correlation value below that
            clusterparam.corr_thresh_within_cluster_origin = 0.8; %won't merge clusters that has correlation value below that
            clusterparam.corr_thresh_within_cluster_target = 0.8;
            
            
            
            roi_list=fetchn(IMG.ROIdeltaF & key,'roi_number','ORDER BY roi_number');
            chunk_size=500;
            for i_chunk=1:chunk_size:numel(roi_list)
                roi_interval = [i_chunk, i_chunk+chunk_size];
                if roi_interval(end)>numel(roi_list)
                    roi_interval(end) = numel(roi_list)+1;
                end
                temp_Fall=cell2mat(fetchn(IMG.ROIdeltaF & key & sprintf('roi_number>=%d',roi_interval(1)) & sprintf('roi_number<%d',roi_interval(2)),'dff_trace','ORDER BY roi_number'));
                temp_roi_num=fetchn(IMG.ROIdeltaF & key & sprintf('roi_number>=%d',roi_interval(1)) & sprintf('roi_number<%d',roi_interval(2)),'roi_number','ORDER BY roi_number');
                Fall(temp_roi_num,:)=temp_Fall;
            end
            
            
            [rho,~]=corr(Fall');
                        
            key_ROIs_all= fetch(IMG.ROIdeltaF & key, 'ORDER BY roi_number');
            key_original = key;
            for in = 1:1:numel(n_clust_vector)
                key = key_original;
                key.n_clust = n_clust_vector(in);
                heirar_cluster_id = fetchn(POP.ROIClusterCorr & key,'heirar_cluster_id', 'ORDER BY roi_number');
                
                for ic=1:1:numel(heirar_cluster_id_vector)
                    idx_cluster = (heirar_cluster_id==heirar_cluster_id_vector(ic));
                    key.heirar_cluster_id = heirar_cluster_id_vector(ic);
                    r_cluster = rho(idx_cluster,idx_cluster);
                    key_ROIs = key_ROIs_all(idx_cluster);
                    
                    for in_sub=1:1:numel(n_sub_clust_vector)
                        if sum(idx_cluster)<n_sub_clust_vector(in_sub)
                            continue
                        end
                        clusterparam.n_clust=n_sub_clust_vector(in_sub);
                        if in_sub==1
                            flag_plot =1;
                        else
                                                        flag_plot =0;
                        end
                        [sub_cl_id, sub_cluster_percent] = fn_ClusterROI_corr(r_cluster, key, clusterparam, dir_save_figure, flag_plot);
                        k = key;
                        % Insert
                        for i=1:1:size(key_ROIs,1)
                            k(i).subject_id=key_ROIs(i).subject_id;
                            k(i).session=key_ROIs(i).session;
                            k(i).session_epoch_type=key_ROIs(i).session_epoch_type;
                            k(i).session_epoch_number=key_ROIs(i).session_epoch_number;
                            k(i).fov_num=key_ROIs(i).fov_num;
                            k(i).plane_num=key_ROIs(i).plane_num;
                            k(i).channel_num=key_ROIs(i).channel_num;
                            k(i).roi_number=key_ROIs(i).roi_number;
                            
                            k(i).n_clust=n_clust_vector(in);
                            k(i).n_sub_clust=n_sub_clust_vector(in_sub);
                            
                            k(i).heirar_cluster_id = heirar_cluster_id_vector(ic);
                            k(i).heirar_sub_cluster_id = sub_cl_id(i);
                            k(i).heirar_sub_cluster_percent = sub_cluster_percent(sub_cl_id(i));
                            
                        end
                        insert(self,k);
                    end
                end
            end
            
        end
    end
end
