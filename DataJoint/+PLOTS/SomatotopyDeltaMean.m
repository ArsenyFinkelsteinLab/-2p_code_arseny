%{
# Projection of the neural acitivity on a mode (neuron weights vector)
-> EXP2.SessionEpoch
%}


classdef SomatotopyDeltaMean < dj.Computed
    properties
        
        keySource = EXP2.SessionEpoch*EXP2.SessionEpochSomatotopy & IMG.ROIdeltaFMean;
        
    end
    methods(Access=protected)
        function makeTuples(self, key)
            dir_base = fetch1(IMG.Parameters & 'parameter_name="dir_root_save"', 'parameter_value');
            dir_current_fig = [dir_base  '\Lick2D\brain_maps\somatotopy\deltamean\'];
            rel_data = IMG.ROIdeltaFMean;
            k=key;
            if ~strcmp(fetch1(EXP2.SessionEpochSomatotopy & k,'sensory_stimulation_area'),'control')
            PLOTS_SomatotopyDeltaMean(k, dir_current_fig, rel_data);
            insert(self,key);
            end
        end
    end
end