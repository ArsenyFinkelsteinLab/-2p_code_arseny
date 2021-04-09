%{
# Projection of the neural acitivity on a mode (neuron weights vector)
-> EXP2.SessionEpoch
%}


classdef MapsClusterCorr < dj.Computed
    properties
        
        keySource = EXP2.SessionEpoch  & IMG.Mesoscope & POP.ROIClusterCorr;
        
    end
    methods(Access=protected)
        function makeTuples(self, key)
            %             n_clust_vector = [20, 100, 500, 1000, 2000, 5000];
            %                         n_clust_vector = [100, 500, 1000, 2000];
            n_clust_vector = [100, 500];
            
            dir_base =fetch1(IMG.Parameters & 'parameter_name="dir_root_save"', 'parameter_value');
            dir_current_fig = [dir_base  '\Lick2D\brain_maps\CorrClusters\clusters_corr\'];
            
            rel_all = IMG.ROI*IMG.PlaneCoordinates  & IMG.ROIGood & key;
            M_all=fetch(rel_all ,'*');
            
            
            for ic = 1:1:numel(n_clust_vector)
                n_clust = n_clust_vector(ic);
                flag_plot_clusters_individually=0;
                lick2D_map_onFOV_clusters_corr_meso(key, flag_plot_clusters_individually, n_clust, M_all, dir_current_fig);
                %                   flag_plot_clusters_individually=1;
                %                 lick2D_map_onFOV_clusters_corr_meso(key, flag_plot_clusters_individually, n_clust);
            end
            
            insert(self,key);
            
            
        end
    end
end