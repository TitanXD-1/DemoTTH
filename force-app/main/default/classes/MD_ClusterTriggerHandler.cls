public with sharing class MD_ClusterTriggerHandler extends TriggersHandler {

	public Map<Id, List<String>> clustersIdWithDisabledAgreements;
    public Set<Id> clustersWithActiveAgreements;

    public MD_ClusterTriggerHandler(List<SObject> p_triggerNew, List<SObject> p_triggerOld) {
        super(p_triggerNew, p_triggerOld);

        clustersIdWithDisabledAgreements = new Map<Id, List<String>>();
        clustersWithActiveAgreements = new Set<Id>();

        allow_masterLoop_BeforeUpdate = true;

        allow_dataPreparing = true;

        allow_finalLoop_BeforeUpdate = true;
    }

    public override void masterLoop_BeforeUpdate(SObject recNew, SObject recOld) {
        validateExistingAgreements(recNew, recOld, 'masterLoop');
    }

    public override void dataPreparing() {
        validateExistingAgreements(null, null, 'dataPreparing');
    }

    public override void finalLoop_BeforeUpdate(SObject recNew, SObject recOld) {
        validateExistingAgreements(recNew, recOld, 'finalMasterLoop');
    }

    public void validateExistingAgreements(SObject recNew, SObject recOld, String step) {
        
        if(step == 'masterLoop') {
            System.debug('MD - in MD_ClusterTriggerHandler.validateExistingAgreements() method. - masterLoop');

            DiageoCMS__Cluster__c newCluster = (DiageoCMS__Cluster__c)recNew;
            DiageoCMS__Cluster__c oldCluster = (DiageoCMS__Cluster__c)recOld;

            List<String> newClusterAgreements = newCluster.CP_AvailableAgreements__c != null ? newCluster.CP_AvailableAgreements__c.split(';') : new List<String>();
            List<String> oldClusterAgreements = oldCluster.CP_AvailableAgreements__c != null ? oldCluster.CP_AvailableAgreements__c.split(';') : new List<String>();

            clustersIdWithDisabledAgreements.put(newCluster.Id, new List<String>());

            for(String s : oldClusterAgreements) {
                if(!newClusterAgreements.contains(s)) {
                    clustersIdWithDisabledAgreements.get(newCluster.Id).add(s);
                }
            }

        }else if(step == 'dataPreparing') {
            System.debug('MD - in MD_ClusterTriggerHandler.validateExistingAgreements() method. - dataPreparing');
            Id activeAgreementRtId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Active').getRecordTypeId();

            Map<Id, DiageoCMS__Cluster__c> clustersMap = new Map<Id, DiageoCMS__Cluster__c>([SELECT Id, (SELECT Id, Type__c, Cluster__c 
                                                                                                        FROM ClusterAgreements__r 
                                                                                                        WHERE RecordTypeId = :activeAgreementRtId)
                                                                                            FROM DiageoCMS__Cluster__c 
                                                                                            WHERE Id IN :clustersIdWithDisabledAgreements.keySet()]);
			
            for(Id cId : clustersMap.keySet()) {
                DiageoCMS__Cluster__c c = clustersMap.get(cId);

                for(CP_Agreement__c ag : c.ClusterAgreements__r) {
                    if(clustersIdWithDisabledAgreements.get(cId).contains(ag.Type__c)) {
                        clustersWithActiveAgreements.add(ag.Cluster__c);
                    }
                }
            }

            System.debug('MD - in MD_ClusterTriggerHandler.validateExistingAgreements() method. - dataPreparing - clustersWithActiveAgreements: ' + clustersWithActiveAgreements);
        }else if(step == 'finalMasterLoop') {
            System.debug('MD - in MD_ClusterTriggerHandler.validateExistingAgreements() method. - finalMasterLoop');

            if(clustersWithActiveAgreements.contains(recNew.Id)) {
                recNew.addError('Cannot remove a Cluster active Agreement if there are Agreements in use.');
            }

            System.debug('MD - in MD_ClusterTriggerHandler.validateExistingAgreements() method. - clustersWithActiveAgreements: ' + clustersWithActiveAgreements.size());
        }
    }
}