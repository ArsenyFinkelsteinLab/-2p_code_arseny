function DELETE_FROM_PIPELINE()
% Relvar - disable user-promt in this script for fast deletion
key.subject_id = 464724;
EXP2.Session & key% & EXP2.BehaviorTrial
key.session = 1;

del (IMG.ROITrace & key)
del (IMG.ROISpikes & key)
del (IMG.ROIdeltaF & key)
del (IMG.ROIdeltaFPeak & key)
del (IMG.ROIdeltaFMean	 & key)
del (IMG.ROIFMean & key)

del (IMG.ROITraceNeuropil & key)
del (IMG.ROIdeltaFNeuropil & key)


del (POP.ROIClusterCorr & key)
del (POP.ROIClusterCorr2 & key)
del (POP.ROICorrLocal & key)
del (POP.ROIPCA	 & key)
del (POP.ROISubClusterCorr	 & key)

del(EXP2.Session & key);

