public with sharing class MD_CaseTriggerHandler extends TriggersHandler { // Migration Missing

    /*****************************************************************/
    /************************ CONSTRUCTOR ****************************/
    /*****************************************************************/
    
    public MD_CaseTriggerHandler(List<SObject> p_triggerNew, List<SObject> p_triggerOld){
        super(p_triggerNew, p_triggerOld);
/*
        allow_masterLoop_BeforeInsert = true;
        allow_masterLoop_AfterInsert = true;
        allow_masterLoop_BeforeUpdate = true;
        allow_masterLoop_AfterUpdate = true;
        
        allow_finalLoop_BeforeInsert = true;
        allow_finalLoop_AfterInsert = true;
        allow_finalLoop_BeforeUpdate = true;
        allow_finalLoop_AfterUpdate = true;
        
        allow_dataPreparing = true;
        allow_executeDMLs = true;
*/
    }
    
    /*****************************************************************/
    /*********************** TRIGGER METHODS *************************/
    /*****************************************************************/
/*    
    //Master loops
    public override void masterLoop_BeforeInsert(SObject recNew) {
        updatesCaseDescription((Case) recNew, null);
    }
    public override void masterLoop_BeforeUpdate(SObject recNew, SObject recOld) {
        updatesCaseDescription((Case) recNew, (Case) recOld);
    }
    public override void masterLoop_AfterInsert(SObject recNew) {
        createCustomCase((Case) recNew, null);
    }
    public override void masterLoop_AfterUpdate(SObject recNew, SObject recOld) {
        caseSolutionsRemoval((Case) recNew, (Case) recOld);
    }

    //Data Preparing
    public override void dataPreparing(){
        
    }

    //Final Loops
    public override void finalLoop_BeforeInsert(SObject recNew) {
        updatesCaseDescription((Case) recNew, null);
    }
    public override void finalLoop_BeforeUpdate(SObject recNew, SObject recOld) {
        updatesCaseDescription((Case) recNew, (Case) recOld);
    }
    public override void finalLoop_AfterInsert(SObject recNew) {
        createCustomCase((Case) recNew, null);
    }    
    public override void finalLoop_AfterUpdate(SObject recNew, SObject recOld){
        createCustomCase((Case) recNew, (Case) recOld);
    }
*/   
    /*****************************************************************/
    /********************** USE CASE METHODS *************************/
    /*****************************************************************/
/*    
    private void caseSolutionsRemoval(Case recNew, Case recOld){
        Set<Id> updatedCasesId = new Set<Id>();        
//        if(recNew.MD_IssueType__c != recOld.MD_IssueType__c && recNew.Status == 'Not Submitted'){
        if(recNew != recOld && recNew.Status == 'Not Submitted'){
            updatedCasesId.add(recNew.Id);
        }        
        if(updatedCasesId.size() > 0) {
            List<MD_CaseSolution__c> caseSolutions = [SELECT Id FROM MD_CaseSolution__c WHERE Case__r.Id IN :updatedCasesId];            
            delete caseSolutions;
        }
    }
    
    private void updatesCaseDescription(Case recNew, Case recOld){
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CustomerPortal').getRecordTypeId();  
        Set<Id> casesIds = new Set<Id>();
        
//        if(recNew.CustomCase__c == null && recNew.RecordTypeId == recordTypeId && recNew.Status == 'Open' && recNew.MD_TroubleshootingModule__c != null){
        if(recNew == null && recNew.RecordTypeId == recordTypeId && recNew.Status == 'Open' && recNew != null){
            casesIds.add(recNew.Id);
        }

        if(!casesIds.isEmpty()){
            
            Map<Id,List<MD_CaseSolution__c>> mapCaseSolutionByCase = new Map<Id, List<MD_CaseSolution__c>>();
            for(MD_CaseSolution__c caseSolution: [SELECT Id, Name, Status__c, Case__c FROM MD_CaseSolution__c WHERE Case__c IN: casesIds ORDER BY CreatedDate DESC]){
                if(!mapCaseSolutionByCase.containsKey(caseSolution.Case__c)){
                    mapCaseSolutionByCase.put(caseSolution.Case__c, new List<MD_CaseSolution__c>{caseSolution});
                }else{
                    mapCaseSolutionByCase.get(caseSolution.Case__c).add(caseSolution);
                }    
            }

//            if(recNew.CustomCase__c == null && recNew.RecordTypeId == recordTypeId && recNew.Status == 'Open' && recNew.MD_TroubleshootingModule__c != null && mapCaseSolutionByCase.containsKey(recNew.Id)){
            if(recNew == null && recNew.RecordTypeId == recordTypeId && recNew.Status == 'Open' && recNew != null && mapCaseSolutionByCase.containsKey(recNew.Id)){
                recNew.Description += '\n\n' + label.MD_CaseTSDescriptionTitle + ': ';
                for(MD_CaseSolution__c caseSolution: mapCaseSolutionByCase.get(recNew.Id)){
                    recNew.Description += '\n' + '- ' + caseSolution.Name + ' - ' + caseSolution.Status__c;
                }
            }
                           
        }   
    }
    
    private void createCustomCase(Case recNew, Case recOld){
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CustomerPortal').getRecordTypeId();  
//        List<Case__c> newCases = new List<Case__c>();
        List<Case> newCases = new List<Case>();
                
        Boolean continueExecuting = false;
        Set<Id> issueTypeIds = new Set<Id>();
        Set<Id> outletIds = new Set<Id>();
        Map<Id,Id> mapAccountAccOutlet = new Map<Id,Id>();
        Map<Id,Id> mapSellingAreas = new Map<Id,Id>();
//        Map<Id,Case__c> mapIdCase = new Map<Id,Case__c>();
        Map<Id,Case> mapIdCase = new Map<Id,Case>();
        
        
//        if(recNew.CustomCase__c == null && recNew.RecordTypeId == recordTypeId && recNew.Status == 'Open' && recNew.MD_TroubleshootingModule__c != null){
        if(recNew == null && recNew.RecordTypeId == recordTypeId && recNew.Status == 'Open' && recNew != null){
            continueExecuting = true;
//            if(recNew.MD_IssueType__c != null){
            if(recNew != null){
//                issueTypeIds.add(recNew.MD_IssueType__c);
                issueTypeIds.add(recNew.Id);
            }
//            if(recNew.Account_Outlet__c != null){
            if(recNew != null){
//                outletIds.add(recNew.Account_Outlet__c);
                outletIds.add(recNew.Id);
            }
        }
        
        if(continueExecuting){
            Map<Id, MD_IssueType__c> mapIssueType; // = new Map<Id,MD_IssueType__c>([SELECT Id, CaseType__c, CaseSubType__c FROM MD_IssueType__c WHERE Id IN: issueTypeIds]);
            
            for(Account acc: [SELECT Id, (SELECT Id FROM Selling_Areas__r WHERE Is_Master_Selling_Area__c = true LIMIT 1) FROM Account WHERE Id IN: outletIds]){
                Id sellingArea = acc.Selling_Areas__r.isEmpty() ? null : acc.Selling_Areas__r[0].Id;
                mapSellingAreas.put(acc.Id,sellingArea);
            }
            
            if(recNew.CustomCase__c == null && recNew.RecordTypeId == recordTypeId && recNew.Status == 'Open' && recNew.MD_TroubleshootingModule__c != null){
                Id sellingArea = mapSellingAreas.containsKey(recNew.Account_Outlet__c) ? mapSellingAreas.get(recNew.Account_Outlet__c) : null;
                Id caseType = mapIssueType.containsKey(recNew.MD_IssueType__c) ? mapIssueType.get(recNew.MD_IssueType__c).CaseType__c : null;
                Id caseSubType = mapIssueType.containsKey(recNew.MD_IssueType__c) ? mapIssueType.get(recNew.MD_IssueType__c).CaseSubType__c : null;
                Case__c newCase = new Case__c(
                    Case__c = recNew.Id,
                    Case_Type__c = caseType,
                    Case_Sub_Type__c = caseSubType,
                    Selling_Area__c = sellingArea,
                    Case_Notes__c = recNew.Description,
                    Country_Code__c = recNew.MD_Country__c,
                    Account__c = recNew.Account_Outlet__c,
                    Status__c = recNew.Status
                );
                newCases.add(newCase);
                mapIdCase.put(recNew.Id, newCase);
            } 
            
        } 
            
        if(!newCases.isEmpty()){
            
            insert newCases;
            
            List<Case> caseUpdate = new List<Case>();
            
//                if(recNew.CustomCase__c == null && recNew.RecordTypeId == recordTypeId && recNew.Status == 'Open' && recNew.MD_TroubleshootingModule__c != null){
                if(recNew == null && recNew.RecordTypeId == recordTypeId && recNew.Status == 'Open' && recNew != null){
//                    caseUpdate.add(new Case(Id = recNew.Id, CustomCase__c = mapIdCase.get(recNew.Id).Id));
                    caseUpdate.add(new Case(Id = recNew.Id));
                }
            
            if(!caseUpdate.isEmpty()){
                update caseUpdate;
            }
            
        }
    }
*/    
}