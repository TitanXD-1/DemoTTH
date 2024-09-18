public with sharing class MD_AgreementTriggerHandler extends TriggersHandler {  // Migration Completed

    /*****************************************************************/
    /************************ CONSTRUCTOR ****************************/
    /*****************************************************************/
    
    public MD_AgreementTriggerHandler(List<SObject> p_triggerNew, List<SObject> p_triggerOld){
        super(p_triggerNew, p_triggerOld);

        allow_masterLoop_BeforeInsert = true;
        allow_masterLoop_AfterInsert = true;
        allow_masterLoop_BeforeUpdate = true;
        allow_masterLoop_AfterUpdate = true;
        
        allow_dataPreparing = true;
        
        allow_finalLoop_BeforeInsert = true;
        allow_finalLoop_AfterInsert = true;
        
        allow_triggerFinish = true;

    }
    
    /*****************************************************************/
    /*********************** TRIGGER METHODS *************************/
    /*****************************************************************/
    
    //Master loops
    public override void masterLoop_BeforeInsert(SObject recNew) {
        validatesPermissionOnSelectedCluster((MD_Agreement__c) recNew, 'MasterLoop');
    }
    public override void masterLoop_BeforeUpdate(SObject recNew, SObject recOld) {
        validatesPermissionOnSelectedCluster((MD_Agreement__c) recNew, 'MasterLoop');
    }
    public override void masterLoop_AfterInsert(SObject recNew) {
        createSharingRecords((MD_Agreement__c) recNew, 'MasterLoop');
    }
    public override void masterLoop_AfterUpdate(SObject recNew, SObject recOld) {
        updateSharingRecords((MD_Agreement__c) recNew, 'MasterLoop');
    }

    //Data Preparing
    public override void dataPreparing(){        
        validatesPermissionOnSelectedCluster(null, 'DataPreparing');
        createSharingRecords(null, 'DataPreparing');
        updateSharingRecords(null, 'DataPreparing');
    }

    //Final Loops
    public override void finalLoop_BeforeInsert(SObject recNew) {
        validatesPermissionOnSelectedCluster((MD_Agreement__c) recNew, 'FinalLoop');
    }
    public override void finalLoop_BeforeUpdate(SObject recNew, SObject recOld) {
        validatesPermissionOnSelectedCluster((MD_Agreement__c) recNew, 'FinalLoop');
    }
    
    //Trigger Finish
    public override void triggerFinish() {
        createSharingRecords(null, 'TriggerFinish');
        updateSharingRecords(null, 'TriggerFinish');
    }
    
    /*****************************************************************/
    /********************** USE CASE METHODS *************************/
    /*****************************************************************/
    
    List<SObject> newRecordsToCreate = new List<SObject>();
    List<SObject> sharingRecordsToInsert = new List<SObject>();
    private void createSharingRecords(MD_Agreement__c recNew, String mode){
		
        if(mode == 'MasterLoop'){
            newRecordsToCreate.add(recNew);
        }
        
        if(mode == 'DataPreparing'){
            if(! newRecordsToCreate.isEmpty()){ 
                sharingRecordsToInsert = MD_SharingUtil.generateSharingForRecordsOnCluster(newRecordsToCreate, 'Cluster__c');
            }
        }
        
        if(mode == 'TriggerFinish'){           
            if(! sharingRecordsToInsert.isEmpty()){
                try{
                    insert sharingRecordsToInsert;
                } catch(Exception e){
                    system.debug('MD - MD_AgreementTriggerHandler.createSharingRecords() error while creating sharing records: ' + e.getMessage());
                }
            }
        }
        
    }
    
    List<SObject> newRecordsToUpdate = new List<SObject>();
    List<SObject> sharingRecordsToDelete = new List<SObject>();
    private void updateSharingRecords(MD_Agreement__c recNew, String mode){
		
        if(mode == 'MasterLoop'){
            newRecordsToUpdate.add(recNew);
        }
        
        if(mode == 'DataPreparing'){
            if(! newRecordsToUpdate.isEmpty()){
                sharingRecordsToDelete = MD_SharingUtil.removeSharingForRecords('Cluster__c');
                sharingRecordsToInsert = MD_SharingUtil.generateSharingForRecordsOnCluster(newRecordsToUpdate, 'Cluster__c');
            }
        }
        
        if(mode == 'TriggerFinish'){
            if(! sharingRecordsToDelete.isEmpty()){
                try{
                    delete sharingRecordsToDelete;
                } catch(Exception e){
                    system.debug('MD - MD_AgreementTriggerHandler.updateSharingRecords() error while removing sharing records: ' + e.getMessage());
                }
            }
            
            if(! sharingRecordsToInsert.isEmpty()){
                try{
                    insert sharingRecordsToInsert;
                } catch(Exception e){
                    system.debug('MD - MD_AgreementTriggerHandler.updateSharingRecords() error while creating sharing records: ' + e.getMessage());
                }
            }
        }
        
    }
    
    Set<Id> validateWriteClusterIds = new Set<Id>();
    Set<Id> validateAccessClusterIds = new Set<Id>();
    private void validatesPermissionOnSelectedCluster(MD_Agreement__c recNew, String mode){
		// TODO:

        if(mode == 'MasterLoop'){
            if(recNew.Cluster__c != null){
                validateWriteClusterIds.add(recNew.Cluster__c);
            }
        }
        
        if(mode == 'DataPreparing'){
            if(! validateWriteClusterIds.isEmpty()){
                Map<Id,Boolean> mapAccess = MD_ClusterUtil.getsClusterWriteAccess(validateWriteClusterIds);
                if(mapAccess.values().contains(false)){
                    for(Id clusterId: mapAccess.keySet()){
                        if(!mapAccess.get(clusterId)){
                            validateAccessClusterIds.add(clusterId);
                        }
                    }
                }
            }
        }
        
        if(mode == 'FinalLoop'){
            if(! validateAccessClusterIds.isEmpty()){
                Map<Id,Boolean> mapAccess = MD_ClusterUtil.getClusterAccess(validateAccessClusterIds);                
                if(recNew.Cluster__c != null && !mapAccess.get(recNew.Cluster__c)){
                    recNew.Cluster__c.addError(label.MD_ClusterPermissionErrorMessage);
                }  
            }
        }
        
    }
    
}