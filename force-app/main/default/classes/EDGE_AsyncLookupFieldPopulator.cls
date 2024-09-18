/*
* @description EDGE_AsyncLookupFieldPopulator
* @history
                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0     Sandip Ghosh      25/02/2022        ES20-11303
2.0     Monalisa Halder   02/03/2022        ES20-12246
3.0     Monalisa Halder   12/03/2022        ES20-12274
4.0     Monalisa Halder   04/04/2022        ES20-12462
5.0     Monalisa Halder   14/04/2022        ES20-12526
**/
public class EDGE_AsyncLookupFieldPopulator implements Queueable {
    
    private List<SObject> newItems;
    public static Map<String,String> valueIdNameMap = new Map<String,String>();
    
    public EDGE_AsyncLookupFieldPopulator(List<SObject> newItems) {
        this.newItems = newItems;
    }
    
    public void execute(QueueableContext context) {       
        populateLookupNameFields(this.newItems);
    }
    
    
    @TestVisible
    // Populate Lookup Field Values 
    private static void populateLookupNameFields(List<SObject> newItems){

        Map<String,String> lookupObjToSueryStringMap = new Map<String,String>();
        Map<Id,Field_Change_Request__c> finalFCRMap = new Map<Id,Field_Change_Request__c>();
        Set<Id> fcrIdsSet = new Set<Id>();
        Map<Id, Set<Id>> oldLookupRecordIdsToFCRs = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> newLookupRecordIdsToFCRs = new Map<Id, Set<Id>>();
        Map<Id,Set<Id>> parentApprovalRecordMap = new Map<Id,Set<Id>>();
        Set<Id> lookupRecordIds = new Set<Id>();
        Set<Id> recordIds = new Set<Id>();
        //ES20-12462
        Map<Id,Set<String>> parentApprovalRecordNonRefFieldMap = new Map<Id,Set<String>>();
        Set<String> textValueSet = new Set<String>();
        
        Map<String,String> mapFieldDependentField = new Map<String,String>();
        Set<String> allDependentFields = new Set<String>();
        string allDependentStr = '';
        
        for(Field_Permission_Dependency__mdt fieldDependencySetting : [SELECT Id, MasterLabel,Field_Permission_Type__c , Object__c,Parent_Field__c, 
                                                                       Field__c, Dependent_Fields__c, Permission__c, Show_in_Custom_Screen__c       
                                                                       FROM Field_Permission_Dependency__mdt where Show_in_Custom_Screen__c  = true ORDER BY Field__c ASC])
        {
            
            if(fieldDependencySetting.Dependent_Fields__c != null){
                mapFieldDependentField.put(fieldDependencySetting.Field__c,fieldDependencySetting.Dependent_Fields__c);
                allDependentFields.add(fieldDependencySetting.Dependent_Fields__c);
                allDependentStr += fieldDependencySetting.Dependent_Fields__c;
            }                                                             
            
        }
        
        
        for(SObject sObj : newItems){
            Field_Change_Request__c newFCR = (Field_Change_Request__c)sObj;
            Field_Change_Request__c fcrRecord = null;
           
            if(!finalFCRMap.containsKey(newFCR.Id)){
                fcrRecord = new Field_Change_Request__c(Id=newFCR.Id,Old_Value__c=newFCR.Old_Value__c,
                                                        New_Value__c=newFCR.New_Value__c,
                                                        Approval_Description__c = newFCR.Approval_Description__c,
                                                        Field_Name__c = newFCR.Field_Name__c);
                finalFCRMap.put(fcrRecord.Id,fcrRecord);
            }
            if(newFCR.Field_Type__c == 'REFERENCE' && newFCR.Lookup_Object_Type__c != null){
               // Set<Id> lookupRecordIds = new Set<Id>();
                lookupRecordIds.add(newFCR.New_Value__c);
                lookupRecordIds.add(newFCR.Old_Value__c);
                //Set<Id> recordIds = new Set<Id>();
                recordIds.add(newFCR.New_Value__c);
                recordIds.add(newFCR.Old_Value__c);
                //ES20-12526
                //if(allDependentStr != null && allDependentStr.contains(newFCR.Field_Name__c)){
                if(newFCR.Parent_Approval__c != null){
                    parentApprovalRecordMap.put(newFCR.Parent_Approval__c,recordIds);
                }
                String queryString = 'Select Id,Name from '+ newFCR.Lookup_Object_Type__c +' where Id in :lookupRecordIds';
                lookupObjToSueryStringMap.put(newFCR.Lookup_Object_Type__c, queryString);
                if(!oldLookupRecordIdsToFCRs.containsKey(newFCR.Old_Value__c)){
                    oldLookupRecordIdsToFCRs.put(newFCR.Old_Value__c,new Set<Id>{newFCR.Id});
                }else{
                    oldLookupRecordIdsToFCRs.get(newFCR.Old_Value__c).add(newFCR.Id);  
                }
                if(!newLookupRecordIdsToFCRs.containsKey(newFCR.New_Value__c)){
                    newLookupRecordIdsToFCRs.put(newFCR.New_Value__c,new Set<Id>{newFCR.Id});
                }else{
                    newLookupRecordIdsToFCRs.get(newFCR.New_Value__c).add(newFCR.Id);  
                }
            }else if(newFCR.Field_Type__c != 'REFERENCE'){//Field not reference
                if(fcrRecord != null){
                    fcrRecord.Old_Value_Name__c = fcrRecord.Old_Value__c;
                    fcrRecord.New_Value_Name__c = fcrRecord.New_Value__c;
                    //ES20-12462 Start
                    textValueSet.add(fcrRecord.Old_Value_Name__c);
                    textValueSet.add(fcrRecord.New_Value_Name__c);
                    if(newFCR.Parent_Approval__c != null){
                        parentApprovalRecordNonRefFieldMap.put(newFCR.Parent_Approval__c,textValueSet);
                    }
                    //ES20-12462 End
                    finalFCRMap.put(fcrRecord.Id,fcrRecord);
                    
                }
            }
            
        }

        for(String lookupObjectName : lookupObjToSueryStringMap.keySet()){
            String queryString = lookupObjToSueryStringMap.get(lookupObjectName);
            for(SObject lookupObject : Database.query(queryString)){
                
                if(oldLookupRecordIdsToFCRs.containsKey(lookupObject.Id)){
                    for(Id fcrId : oldLookupRecordIdsToFCRs.get(lookupObject.Id)){
                        Field_Change_Request__c fcrRecord = null;
                        if(!finalFCRMap.containsKey(fcrId)){
                            fcrRecord = new Field_Change_Request__c(Id=fcrId);
                            finalFCRMap.put(fcrRecord.Id,fcrRecord);
                        }else{
                           fcrRecord = finalFCRMap.get(fcrId); 
                        }
                        if(fcrRecord != null){
                            fcrRecord.Old_Value_Name__c = (String)lookupObject.get('Name');
                            valueIdNameMap.put((String)lookupObject.get('Id'),fcrRecord.Old_Value_Name__c);
                            
                        }
                    }
                }
                if(newLookupRecordIdsToFCRs.containsKey(lookupObject.Id)){
                    for(Id fcrId : newLookupRecordIdsToFCRs.get(lookupObject.Id)){
                        Field_Change_Request__c fcrRecord = null;
                        if(!finalFCRMap.containsKey(fcrId)){
                            fcrRecord = new Field_Change_Request__c(Id=fcrId);
                            finalFCRMap.put(fcrRecord.Id,fcrRecord);
                        }else{
                            fcrRecord = finalFCRMap.get(fcrId); 
                        }
                        if(fcrRecord != null){
                            fcrRecord.New_Value_Name__c = (String)lookupObject.get('Name');
                            valueIdNameMap.put((String)lookupObject.get('Id'),fcrRecord.New_Value_Name__c);
                            fcrRecord.Status__c = 'New';
                        }                
                    }
                }
            }
        }
        
        if(parentApprovalRecordMap != null && parentApprovalRecordMap.size()>0 ){
             for(Field_Change_Request__c childFCR :[Select Id,Parent_Approval__c,Parent_Approval__r.Approval_Description__c,
                                                   Parent_Approval__r.Old_Value__c,Parent_Approval__r.New_Value__c,Field_Type__c 
                                                   from Field_Change_Request__c 
                                                   where Field_Type__c = 'REFERENCE' and Parent_Approval__c IN :parentApprovalRecordMap.keyset()])
            {
                Set<Id> records = parentApprovalRecordMap.get(childFCR.Parent_Approval__c); 
                if(childFCR.Parent_Approval__r.Approval_Description__c !=null){
                    String approvalDesc = childFCR.Parent_Approval__r.Approval_Description__c;
                    for(Id id :records){
                        if(valueIdNameMap.get(id) != null){
                            approvalDesc = approvalDesc.replace(id, valueIdNameMap.get(id)); 
                        }
                    }
                    childFCR.Parent_Approval__r.Approval_Description__c = approvalDesc;
                    Field_Change_Request__c parenFCR = new Field_Change_Request__c(Id=childFCR.Parent_Approval__c,
                                                                                    Approval_Description__c = approvalDesc,
                                                                                    Old_Value_Name__c=childFCR.Parent_Approval__r.Old_Value__c,
                                                                                    New_Value_Name__c=childFCR.Parent_Approval__r.New_Value__c);    
                                                              
                    finalFCRMap.put(parenFCR.Id,parenFCR);   
                }
            }
        }else if(parentApprovalRecordNonRefFieldMap != null && parentApprovalRecordNonRefFieldMap.size() >0){ //ES20-12462 start
            
            for(Field_Change_Request__c childFCR :[Select Id,Parent_Approval__c,Parent_Approval__r.Old_Value__c,
                                                   Parent_Approval__r.New_Value__c,Field_Type__c 
                                                   from Field_Change_Request__c 
                                                   where Field_Type__c != 'REFERENCE' and Parent_Approval__c IN :parentApprovalRecordNonRefFieldMap.keyset()])
            {
                
                if(childFCR.Parent_Approval__c !=null){
                    Field_Change_Request__c parenFCR = new Field_Change_Request__c(Id=childFCR.Parent_Approval__c,
                                                                                    Old_Value_Name__c=childFCR.Parent_Approval__r.Old_Value__c,
                                                                                    New_Value_Name__c=childFCR.Parent_Approval__r.New_Value__c);    
                    if(!parentApprovalRecordMap.containsKey(parenFCR.Id)){
                       finalFCRMap.put(parenFCR.Id,parenFCR); 
                    }                                         
                       
                }
            
            }
            
        } //ES20-12462 end
        
        if(finalFCRMap != null && finalFCRMap.size()>0){
            
            List<Field_Change_Request__c> fcrToCommit = new List<Field_Change_Request__c>();
            
            if(parentApprovalRecordMap.size() > 0){// Dependent Fields Scenario, for child records
                for(Field_Change_Request__c fcrRecord : finalFCRMap.values()){
                    //if(allDependentStr != null && fcrRecord.Field_Name__c != null && allDependentStr.contains(fcrRecord.Field_Name__c)){
                        fcrRecord.Status__c = 'New';
                        fcrToCommit.add(fcrRecord);
                   // }
                }
                System.debug('1. fcrToCommit : '+ fcrToCommit);
                
            }else{//Normal Scenario, where a non-dependent field will go
                for(Field_Change_Request__c fcrRecord : finalFCRMap.values()){
                    system.debug('@@fcrRecord199' +fcrRecord);

                    System.debug('@@mapFieldDependentField'+mapFieldDependentField);
                    if(!mapFieldDependentField.containsKey(fcrRecord.Field_Name__c) || fcrRecord.Field_Name__c=='Status__c' ){//fields without having any child

                        fcrRecord.Status__c = 'New';
                        fcrToCommit.add(fcrRecord);
                    }/*else{//for not sending e-mail - scenarios like Global Channel
                        fcrToCommit.add(fcrRecord);
                    }*/ 
                }
                System.debug('2. fcrToCommit : '+ fcrToCommit);
            }
            
            if(fcrToCommit.size() > 0){
                Database.update(fcrToCommit);
            }

        }
        
    }

}