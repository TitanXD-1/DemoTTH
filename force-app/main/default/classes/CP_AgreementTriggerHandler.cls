/***********************************************************************************
Apex Class Name  :  CP_AgreementTriggerHandler 
Version          :  1.0
Created Date     :  07/08/2019
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Hernan Arakaki			07/08/2019				ECOM 3408: EDGE - Agreements versioning
******************************************************************************/
public with sharing class CP_AgreementTriggerHandler extends TriggersHandler {

    public Set<String> clustersId = new Set<String>();
    public Map<Id, DiageoCMS__Cluster__c> clustersMap = new  Map<Id, DiageoCMS__Cluster__c>();

    /*****************************************************************/
    /************************ CONSTRUCTOR ****************************/
    
    public CP_AgreementTriggerHandler(List<SObject> p_triggerNew, List<SObject> p_triggerOld){
        super(p_triggerNew, p_triggerOld);
        
        allow_masterLoop_BeforeInsert = true;
        allow_masterLoop_BeforeUpdate = true;
        allow_masterLoop_AfterInsert = true;
        allow_masterLoop_AfterUpdate = true;
        allow_masterLoop_AfterDelete = true;

        allow_dataPreparing = true;
        
        allow_finalLoop_BeforeInsert = true;
        allow_finalLoop_BeforeUpdate = true;
        allow_finalLoop_AfterInsert = true;
        allow_finalLoop_AfterUpdate = true;
        allow_finalLoop_AfterDelete = true;
        
        allow_triggerFinish = true;

        allow_executeDMLs = true;
    }
    
    /*****************************************************************/
    /*********************** TRIGGER METHODS *************************/

    //Master loops
    public override void masterLoop_BeforeInsert(SObject recNew) {
        fillClustersIdList((CP_Agreement__c) recNew, null);
        validateEnabledAgreementType((CP_Agreement__c)recNew, null, TriggersHandler.TriggersHandlerStepType.MASTER_LOOP);
    }

    public override void masterLoop_BeforeUpdate(SObject recNew, SObject recOld) {
        fillClustersIdList((CP_Agreement__c) recNew, (CP_Agreement__c) recOld);
        validateEnabledAgreementType((CP_Agreement__c)recNew, (CP_Agreement__c)recOld, TriggersHandler.TriggersHandlerStepType.MASTER_LOOP);
    }

    public override void masterLoop_AfterInsert(SObject recNew) {
        fillClustersIdList((CP_Agreement__c) recNew, null);
        updateClusterJsonField((CP_Agreement__c) recNew, null, TriggersHandler.TriggersHandlerStepType.MASTER_LOOP);
        createSharingRecords((CP_Agreement__c) recNew, TriggersHandler.TriggersHandlerStepType.MASTER_LOOP);
    }

    public override void masterLoop_AfterUpdate(SObject recNew, SObject recOld) {
        fillClustersIdList((CP_Agreement__c) recNew, (CP_Agreement__c) recOld);
        updateClusterJsonField((CP_Agreement__c) recNew, (CP_Agreement__c) recOld, TriggersHandler.TriggersHandlerStepType.MASTER_LOOP);
    }

    public override void masterLoop_AfterDelete(SObject recOld) {
        fillClustersIdList(null, (CP_Agreement__c) recOld);
        updateClusterJsonField(null, (CP_Agreement__c) recOld, TriggersHandler.TriggersHandlerStepType.MASTER_LOOP);
    }

    //Data Preparing
    public override void dataPreparing() {
        retrieveClusters(null, null, TriggersHandler.TriggersHandlerStepType.DATA_PREPARING);
        validateEnabledAgreementType(null, null, TriggersHandler.TriggersHandlerStepType.DATA_PREPARING);
        updateClusterJsonField(null, null, TriggersHandler.TriggersHandlerStepType.DATA_PREPARING);
        createSharingRecords(null, TriggersHandler.TriggersHandlerStepType.DATA_PREPARING);
    }

    //Final Loops
    public override void finalLoop_BeforeInsert(SObject recNew) {
        checkForRequiredFields((CP_Agreement__c)recNew, null, TriggersHandler.TriggersHandlerStepType.FINAL_LOOP);
        generateAgreementName((CP_Agreement__c)recNew, null, TriggersHandler.TriggersHandlerStepType.FINAL_LOOP);
        validateEnabledAgreementType((CP_Agreement__c)recNew, null, TriggersHandler.TriggersHandlerStepType.FINAL_LOOP);
    }

    public override void finalLoop_AfterInsert(SObject recNew) {
        
    }

    public override void finalLoop_AfterUpdate(SObject recNew, SObject recOld) {
        
    }

    public override void finalLoop_AfterDelete(SObject recOld) {
        updateClusterJsonField(null, (CP_Agreement__c) recOld, TriggersHandler.TriggersHandlerStepType.FINAL_LOOP);
    }
    
    public override void executeDMLs() {
        updateClusterJsonField(null, null, TriggersHandler.TriggersHandlerStepType.EXECUTE_DMLS);
    }

    //Trigger Finish
    public override void triggerFinish() {
        createSharingRecords(null, TriggersHandler.TriggersHandlerStepType.TRIGGER_FINISH);
    }
    
    /*****************************************************************/
    /********************** USE CASE METHODS *************************/

    public void fillClustersIdList(CP_Agreement__c recNew, CP_Agreement__c recOld) {
        CP_Agreement__c rec = recNew == null ? recOld : recNew;
        clustersId.add(rec.Cluster__c);
    }

    public void retrieveClusters(CP_Agreement__c recNew, CP_Agreement__c recOld, TriggersHandler.TriggersHandlerStepType step) {
        if(step == TriggersHandler.TriggersHandlerStepType.DATA_PREPARING) {
            clustersMap = new Map<Id, DiageoCMS__Cluster__c>([SELECT Id, Name FROM DiageoCMS__Cluster__c WHERE Id IN :clustersId]);

            System.debug('CP - in CP_AgreementTriggerHandler.retrieveClusters() - DATA_PREPARING - clustersMap: ' + clustersId);
        }
    }

    /** No se puede crear un agreement de un tipo que no esta habilitado en el cluster. 
    *   on BeforeInsert / BeforeUpdate
    */
    public Map<String, String> clustersAvailableAgreements = new Map<String, String>();

    public void generateAgreementName(CP_Agreement__c recNew, CP_Agreement__c recOld, TriggersHandler.TriggersHandlerStepType step) {
        
        if(step == TriggersHandler.TriggersHandlerStepType.FINAL_LOOP) {
            /** BeforeInsert action */
            if(String.isNotEmpty(recNew.Portal__c) || String.isNotEmpty(recNew.Type__c) || String.isNotEmpty(recNew.Cluster__c)) {
                System.debug('CP - in CP_AgreementTriggerHandler.generateAgreementName() - FINAL_LOOP - recNew.Id: ' + recNew.Id + ' - clustersMap: ' + clustersMap);
                recNew.Name = recNew.Portal__c + ' - ' + clustersMap.get(recNew.Cluster__c).Name + ' - ' + recNew.Type__c + ' - ' + 'Draft';
            }
            
        }
    }

    public void validateEnabledAgreementType(CP_Agreement__c recNew, CP_Agreement__c recOld, TriggersHandler.TriggersHandlerStepType step) {

        if(step == TriggersHandler.TriggersHandlerStepType.DATA_PREPARING) {
            for(DiageoCMS__Cluster__c c : [SELECT Id, CP_AvailableAgreements__c FROM DiageoCMS__Cluster__c WHERE Id IN :clustersId]) {
                clustersAvailableAgreements.put(c.Id, c.CP_AvailableAgreements__c);
            }
            System.debug('CP - in CP_AgreementTriggerHandler.validateEnabledAgreementType() - DATA_PREPARING - clustersAvailableAgreements: ' + clustersAvailableAgreements);
        }

        if(step == TriggersHandler.TriggersHandlerStepType.FINAL_LOOP) {

            if(String.isNotEmpty(recNew.Cluster__c)) {
                String c = clustersAvailableAgreements.get(recNew.Cluster__c);
                System.debug('CP - in CP_AgreementTriggerHandler.validateEnabledAgreementType() - FINAL_LOOP - c: ' + c + ' - recNew.Type__c: ' + recNew.Type__c);
                if(c == null) {
                    recNew.addError(Label.CP_AgreementEmptyClusterTypesError);
                }else if(!c.contains(recNew.Type__c)) {
                    recNew.addError(Label.CP_AgreementNoValidTypeError);
                }
            }
        }
    }

    /** Al Cambio status/borrar de un agreement tengo que actualizar el campo JSON del cluster para que quede consistente 
    *   on AfterUpdate/AfterDelete
    */
    public List<DiageoCMS__Cluster__c> clustersToUpdate = new List<DiageoCMS__Cluster__c>();

    public void updateClusterJsonField(CP_Agreement__c recNew, CP_Agreement__c recOld, TriggersHandler.TriggersHandlerStepType step) {

        if(step == TriggersHandler.TriggersHandlerStepType.DATA_PREPARING) {
			
            Id activeAgreementRTId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Active').getRecordTypeId();
            
            for(DiageoCMS__Cluster__c c : [SELECT Id, (SELECT Id, Type__c, Version__c, Portal__c FROM ClusterAgreements__r WHERE RecordTypeId = :activeAgreementRTId) 
                                           	FROM DiageoCMS__Cluster__c 
                                           	WHERE Id IN :clustersId]) {
                                                
				List<CP_AgreementUtil.AgreementWrapper> clusterActiveAgreements = new List<CP_AgreementUtil.AgreementWrapper>();
            	System.debug('CP - in CP_AgreementTriggerHandler.updateClusterJsonField() - MASTER_LOOP - clustersId: ' + clustersId);
                                                
                for(CP_Agreement__c ag : c.ClusterAgreements__r) {
                    CP_AgreementUtil.AgreementWrapper agw = new CP_AgreementUtil.AgreementWrapper();
                    agw.agreementId = ag.Id;
                    agw.type = ag.Type__c;
                    agw.portal = ag.Portal__c;
                    agw.version = ag.Version__c;
        
                    clusterActiveAgreements.add(agw);
                }
				
                c.CP_ActiveAgreements__c = clusterActiveAgreements != null ? JSON.serialize(clusterActiveAgreements) : '';
                clustersToUpdate.add(c);
            }

            System.debug('CP - in CP_AgreementTriggerHandler.updateClusterJsonField() - DATA_PREPARING - clustersToUpdate: ' + clustersToUpdate);
        }

        if(step == TriggersHandler.TriggersHandlerStepType.EXECUTE_DMLS) {
            update clustersToUpdate;

            System.debug('CP - in CP_AgreementTriggerHandler.updateClusterJsonField() - EXECUTE_DMLS - clustersToUpdate: ' + clustersToUpdate);
        }
    }

    /** Create Sharing records */
    List<SObject> newRecordsToCreate = new List<SObject>();
    List<SObject> sharingRecordsToInsert = new List<SObject>();
    private void createSharingRecords(CP_Agreement__c recNew, TriggersHandler.TriggersHandlerStepType step){
		
        if(step == TriggersHandler.TriggersHandlerStepType.MASTER_LOOP){
            newRecordsToCreate.add(recNew);
        }
        
        if(step == TriggersHandler.TriggersHandlerStepType.DATA_PREPARING){
            if(! newRecordsToCreate.isEmpty()){ 
                sharingRecordsToInsert = MD_SharingUtil.generateSharingForRecordsOnCluster(newRecordsToCreate, 'Cluster__c');
            }
        }
        
        if(step == TriggersHandler.TriggersHandlerStepType.TRIGGER_FINISH){           
            if(! sharingRecordsToInsert.isEmpty()){
                try{
                    insert sharingRecordsToInsert;
                } catch(Exception e){
                    system.debug('CP - MD_AgreementTriggerHandler.createSharingRecords() error while creating sharing records: ' + e.getMessage());
                }
            }
        }
    }

    private void checkForRequiredFields(CP_Agreement__c recNew, CP_Agreement__c recOld, TriggersHandler.TriggersHandlerStepType step) {
        
        if(step == TriggersHandler.TriggersHandlerStepType.FINAL_LOOP) {
            if(String.isEmpty(recNew.Portal__c) || String.isEmpty(recNew.Type__c) || String.isEmpty(recNew.Cluster__c)) {
                recNew.addError(Label.CP_AgreementEmptyRequiredFields);
            }
        }
    }
}