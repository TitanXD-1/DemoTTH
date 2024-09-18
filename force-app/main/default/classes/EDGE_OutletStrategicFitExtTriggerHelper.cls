/**

* @description : EDGE_OutletStrategicFitExtTriggerHelper

* @purpose : 

* @history :                                                           

*VERSION    AUTHOR              DATE              DETAIL

*1.0       Shivam Chauhan		27/12/2023		148622 - Define Approvers in Approval Flow for Strategic Fit updates based on FPS Setting
*/
public with sharing class EDGE_OutletStrategicFitExtTriggerHelper {
	public static void createFieldChangeRequest(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){ 
        Map<String,Field_Permission__c> fieldPermissionOtherMap = new Map<String,Field_Permission__c>();
        Id profileId= Userinfo.getProfileId();
        String profileName=[SELECT Id,Name FROM Profile WHERE Id=:profileId].Name;
        if(profileName== 'Sales Representative' && !EDGE_UtilityClass.stopTriggerToRun){
            Id managerID = [SELECT Id,ManagerId FROM User WHERE Id=: UserInfo.getUserId()].ManagerId;        
            MAP<Id,Account> ouletCountryMap = new MAP<Id,Account>();
            List<Field_Change_Request__c> fcrInsertList = new List<Field_Change_Request__c>();       
            Set<Id> outletIdSet = new Set<Id>();
            
            EDGE_UtilityClass.populateFieldPermissionMaps('Outlet_Strategic_Fit__c', null,null,fieldPermissionOtherMap, null, null);
            
            for(SObject sObj : newItems.values()){
                Outlet_Strategic_Fit__c outletStrategicFit = (Outlet_Strategic_Fit__c)sObj;
                outletIdSet.add(outletStrategicFit.Outlet__c); 
            }
            ouletCountryMap = new Map<Id,Account>([SELECT ID,Country__c FROM Account WHERE Id IN :outletIdSet]);
            
            for(SObject sObj : newItems.values()){
                Outlet_Strategic_Fit__c newOSF = (Outlet_Strategic_Fit__c)sObj;
                Outlet_Strategic_Fit__c oldOSF;
                if(oldItems!= null && oldItems.containsKey(newOSF.Id)){
                    oldOSF = (Outlet_Strategic_Fit__c)oldItems.get(newOSF.Id);
                }
                
                FieldChangerRequestWrapper fcrWrapper = new FieldChangerRequestWrapper();
                fcrWrapper.fieldPermissionOtherMap = fieldPermissionOtherMap;
                fcrWrapper.newOSF = newOSF;
                fcrWrapper.oldOSF = oldOSF;
                fcrWrapper.ouletCountryMap = ouletCountryMap;
                fcrWrapper.managerID = managerID;
                
                //instantiate FieldChangeRequest
                instantiateFCR(fcrWrapper,fcrInsertList);
            }
            
            insertFCR(fcrInsertList);
        }
    }
    
    public static void instantiateFCR(FieldChangerRequestWrapper fcrWrapper,List<Field_Change_Request__c> fcrInsertList){
        
        for(String field: fcrWrapper.fieldPermissionOtherMap.keySet()){
            if(fcrWrapper.newOSF.get(field) != fcrWrapper.oldOSF.get(field)){ //add outlet check                   
                Field_Change_Request__c fcr = new Field_Change_Request__c();
                fcr.MDM_Approval_required__c = false;
                fcr.Sales_manager_approval_required__c = false;
                
                switch on fcrWrapper.fieldPermissionOtherMap.get(field).Permission__c {
                   when 'Editable - Manager Approval Required','Editable & Mandatory - Manager Approval Required'  {
                       fcr.Sales_manager_approval_required__c = true;
                       fcr.Approver__c = fcrWrapper.managerID;
                   }
                   when 'Editable - Manager & MDM Approval Required','Editable & Mandatory - Manager & MDM Approval Required' {
                       fcr.MDM_Approval_required__c = true;
                       fcr.Sales_manager_approval_required__c = true;
                       fcr.Approver__c = fcrWrapper.managerID;
                   }
                   when 'Editable - MDM Approval Required','Editable & Mandatory - MDM Approval Required' {
                       fcr.MDM_Approval_required__c = true;
                   }
                }
                
                fcr.Field_Name__c = field;                    
                fcr.New_Value__c = String.valueOf(fcrWrapper.newOSF.get(field));
                fcr.Old_Value__c = String.valueOf(fcrWrapper.oldOSF.get(field));
                fcr.Changed_By__c = UserInfo.getUserId();
                fcr.Outlet__c = fcrWrapper.newOSF.Outlet__c;
                fcr.Outlet_Strategic_Fit__c = fcrWrapper.newOSF.Id;
                fcr.Object_Type__c = 'Outlet_Strategic_Fit__c';
                
                assignCondtionalFCRFields(fcrWrapper,fcr,field);

                if(fcr.MDM_Approval_required__c == true || fcr.Sales_manager_approval_required__c == true){
                    fcrInsertList.add(fcr);
                    fcrWrapper.newOSF.put(field,fcrWrapper.oldOSF.get(field)); // reassign the old value 
                }
            }
        }
    }
    
    public static void assignCondtionalFCRFields(FieldChangerRequestWrapper fcrWrapper,Field_Change_Request__c fcr,String field){
        if(fcrWrapper.ouletCountryMap.get(fcrWrapper.newOSF.Outlet__c) != null){
                    fcr.Geography__c = fcrWrapper.ouletCountryMap.get(fcrWrapper.newOSF.Outlet__c).Country__c;     
                }
        if(EDGE_UtilityClass.getFieldType(fcr.Object_Type__c,field)!= null){
                    fcr.Field_Type__c = EDGE_UtilityClass.getFieldType(fcr.Object_Type__c,field);    
                }
        if(fcr.Field_Type__c == 'REFERENCE'){
                    String objectName = '';
                    Id newId = (Id)fcrWrapper.newOSF.get(field);
                    Id oldId = (Id)fcrWrapper.oldOSF.get(field);  
                    if(newId != null){
                        objectName = newId.getSObjectType().getDescribe().getName();     
                    }else if(oldId != null){
                        objectName = oldId.getSObjectType().getDescribe().getName(); 
                    }
                    fcr.Lookup_Object_Type__c = objectName;
                    
                }
    }
    
    public static void insertFCR(List<Field_Change_Request__c> fcrInsertList){
        Database.SaveResult[] srList = new Database.SaveResult[]{};
                if(!fcrInsertList.isEmpty() && Schema.sObjectType.Field_Change_Request__c.isCreateable()){
                    srList = Database.insert(fcrInsertList,false); 
                }
            if(!srList.isEmpty()){
                for(Database.saveResult sr : srList){
                    if(sr.isSuccess()){
                        System.debug(LoggingLevel.Debug,'FCR Inserted');    
                    }  
                    else{
                        for(Database.Error err : sr.getErrors()){
                            System.debug(LoggingLevel.Debug,'Error Message-->'+err.getMessage()+'Fields -->'+err.getFields());
                        }
                    }
                }     
            }
    }
    
    public static void validateFieldsPerFS(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
        String relatedObjectName = 'Outlet_Strategic_Fit__c';
        Map<Id, Id> oSFIdToCountryIdMap = new Map<Id, Id>();
        Map<Id, Id> oSFIdToAccRecTypeIdMap = new Map<Id, Id>();
        Schema.DescribeSObjectResult sObjectDescReslt = Schema.SObjectType.Outlet_Strategic_Fit__c ;
        
        for(Outlet_Strategic_Fit__c outletStrategicFitRec: [Select Id , Outlet__r.Country__c , Outlet__r.RecordTypeId from Outlet_Strategic_Fit__c where Id in :newItems.keySet() WITH SECURITY_ENFORCED]){
            oSFIdToCountryIdMap.put(outletStrategicFitRec.Id, outletStrategicFitRec.Outlet__r.Country__c);
            oSFIdToAccRecTypeIdMap.put(outletStrategicFitRec.Id, outletStrategicFitRec.Outlet__r.RecordTypeId);
        }
        
        EDGE_ValidationWrapper edgeValWrapper = new EDGE_ValidationWrapper();
        edgeValWrapper.newItems = newItems;
        edgeValWrapper.oldItems = oldItems;
        edgeValWrapper.sObjectDescReslt = sObjectDescReslt;
        edgeValWrapper.relatedObjectName = relatedObjectName;
        edgeValWrapper.childRecIdToCountryIdMap = oSFIdToCountryIdMap;
        edgeValWrapper.childRecIdToAccRecTypeIdMap = oSFIdToAccRecTypeIdMap;
        
        EDGE_UtilityClass.validateFieldsPerFS(edgeValWrapper); 
    }
    
    public class FieldChangerRequestWrapper {
        @AuraEnabled public Map<String,Field_Permission__c> fieldPermissionOtherMap {get; set;}
        @AuraEnabled public Outlet_Strategic_Fit__c newOSF {get;set;}
        @AuraEnabled public Outlet_Strategic_Fit__c oldOSF {get; set;}
        @AuraEnabled public MAP<Id,Account> ouletCountryMap {get; set;}
        @AuraEnabled public List<Field_Change_Request__c> fcrInsertList {get; set;}
        @AuraEnabled public Id managerID {get; set;}
    }
}