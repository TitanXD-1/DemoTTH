/**
* @description EDGE_LicenseTriggerHelper
* @history
                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0     Sagar Barman        05/01/2019      Initial Development
2.0     Preyanka Ghosh      12/07/2019      ES20-2947
3.0     Monalisa Halder     31/01/2020      ES20-9212
1.4     Monalisa Halder     24/02/2022       ES20-11303

1.5    Monalisa Halder      12/03/2022       ES20-12274
1.6    Rajarshi Lahiri		05/04/2022		ES20-13958

**/

public with sharing class EDGE_LicenseTriggerHelper {
    
    /**
    * @description validateFieldsPerFS
    * @Purpose  Static Method to get Field Permission per field
    * @return  
	* @param map
    */
    
    public static void validateFieldsPerFS(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
        String relatedObjectName = 'License__c';
        Map<Id, Id> licIdToCountryIdMap = new Map<Id, Id>();
        Map<Id, Id> licIdToAccRecTypeIdMap = new Map<Id, Id>();
        Schema.DescribeSObjectResult sObjectDescReslt = Schema.SObjectType.License__c;
        for(License__c licenseRec : [Select Id , Outlet_Id__r.Country__c , Outlet_Id__r.RecordTypeId from License__c where Id in :newItems.keySet()]){
           licIdToCountryIdMap.put(licenseRec.Id, licenseRec.Outlet_Id__r.Country__c);
           licIdToAccRecTypeIdMap.put(licenseRec.Id, licenseRec.Outlet_Id__r.RecordTypeId);
        }
        
        EDGE_ValidationWrapper edgeValWrapper = new EDGE_ValidationWrapper();
        edgeValWrapper.newItems = newItems;
        edgeValWrapper.oldItems = oldItems;
        edgeValWrapper.sObjectDescReslt = sObjectDescReslt;
        edgeValWrapper.relatedObjectName = relatedObjectName;
        edgeValWrapper.childRecIdToCountryIdMap = licIdToCountryIdMap;
        edgeValWrapper.childRecIdToAccRecTypeIdMap = licIdToAccRecTypeIdMap;
        //ES20-9212
        EDGE_UtilityClass.validateFieldsPerFS(edgeValWrapper);
       
    } 
	 /**
    * @description createFieldChangeRequest
    * @Purpose  to create FCR records-ES20-9212
    * @return  
	* @param map
    */
     
    public static void createFieldChangeRequest(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){        
        Map<String,Field_Permission__c> fieldPermissionOtherMap = new Map<String,Field_Permission__c>();
        Id profileId= Userinfo.getProfileId();
        String profileName=[SELECT Id,Name FROM Profile WHERE Id=:profileId].Name;
        if(!EDGE_UtilityClass.stopTriggerToRun && profileName == 'Sales Representative'){
            Id managerID = [SELECT Id,ManagerId FROM User WHERE Id=: UserInfo.getUserId()].ManagerId;        
            MAP<Id,Account> ouletCountryMap = new MAP<Id,Account>();
            List<Field_Change_Request__c> fcrInsertList = new List<Field_Change_Request__c>();        
            Set<Id> outletIdSet = new Set<Id>();
            Map<String,String> mapLicenseFieldSet  = new Map<String,String>();
            
            EDGE_UtilityClass.populateFieldPermissionMaps('License__c', null,null,fieldPermissionOtherMap, null, null);
            for(SObject sObj : newItems.values()){
                License__c newLicense = (License__c)sObj;
                outletIdSet.add(newLicense.Outlet_Id__c);            
            }
            ouletCountryMap = new Map<Id,Account>([SELECT ID,Country__c FROM Account WHERE Id IN :outletIdSet]);
           
            for(SObject sObj : newItems.values()){
                License__c newLicense = (License__c)sObj;
                License__c oldLicense;
                if(oldItems!= null && oldItems.containsKey(newLicense.Id)){
                    oldLicense = (License__c)oldItems.get(newLicense.Id);
                } 
                
                //instantiate FieldChangeRequest                
                for(String field: fieldPermissionOtherMap.keySet()){
                    if(newLicense.get(field) != oldLicense.get(field)){   
                        if((fieldPermissionOtherMap.get(field)!=null && fieldPermissionOtherMap.get(field).Permission__c.containsIgnoreCase('Sales Manager Approval Required')) || 
                           (fieldPermissionOtherMap.get(field)!=null && fieldPermissionOtherMap.get(field).Permission__c.containsIgnoreCase('MDM Approval Required'))
                          ){
                             system.debug('@@field' +field);
                              Field_Change_Request__c fcr = new Field_Change_Request__c();
                              fcr.MDM_Approval_required__c = false;
                              fcr.Sales_manager_approval_required__c = false;
                              fcr.Geography__c = ouletCountryMap.get(newLicense.Outlet_Id__c).Country__c;
                              if(fieldPermissionOtherMap.get(field)!=null && fieldPermissionOtherMap.get(field).Permission__c.containsIgnoreCase(System.Label.EDGE_Sales_Manager_Required)){                                                           
                                  fcr.Sales_manager_approval_required__c = true;
                              }else if(fieldPermissionOtherMap.get(field)!=null && fieldPermissionOtherMap.get(field).Permission__c.containsIgnoreCase(System.Label.EDGE_MDM_Sales_Manager_Required)){                           
                                  fcr.MDM_Approval_required__c = true;
                                  fcr.Sales_manager_approval_required__c = true;
                              }else if(fieldPermissionOtherMap.get(field)!=null && fieldPermissionOtherMap.get(field).Permission__c.containsIgnoreCase(System.Label.EDGE_MDM_Approval_Required)){
                                  fcr.MDM_Approval_required__c = true;
                              }
                              fcr.Approver__c = managerID;
                              fcr.Field_Name__c = field;
                              fcr.New_Value__c = String.valueOf(newLicense.get(field));
                              fcr.Old_Value__c = String.valueOf(oldLicense.get(field));
                              fcr.Changed_By__c = UserInfo.getUserId();
                              fcr.License__c = newLicense.Id;
                              //fcr.Status__c = 'New';//ES20-13958
                              fcr.Object_Type__c = 'License__c';
                              if(EDGE_UtilityClass.getFieldType(fcr.Object_Type__c,field)!= null){
                                  fcr.Field_Type__c = EDGE_UtilityClass.getFieldType(fcr.Object_Type__c,field);    
                              }
                              if(fcr.Field_Type__c == 'REFERENCE'){

                                  //ES20-12274
                                  /*Id newId = (Id)newLicense.get(field);
                                  String objectName = newId.getSObjectType().getDescribe().getName();*/
                                  String objectName = '';
                                  Id newId = (Id)newLicense.get(field);
                                  Id oldId = (Id)oldLicense.get(field);  
                                  if(newId != null){
                                      objectName = newId.getSObjectType().getDescribe().getName();     
                                  }else if(oldId != null){
                                      objectName = oldId.getSObjectType().getDescribe().getName(); 
                                  }

                                  //25-Feb
                                  fcr.Lookup_Object_Type__c = objectName;
                                  
                              }
                              fcrInsertList.add(fcr);
                              newLicense.put(field,oldLicense.get(field)); // reassign the old value 
                          }
                    }
                }            
            } 
            Database.SaveResult[] srList = new Database.SaveResult[]{};
                if(!fcrInsertList.isEmpty() && Schema.sObjectType.Field_Change_Request__c.isCreateable()){
                    srList = Database.insert(fcrInsertList,false); 
                }
            if(!srList.isEmpty()){
                for(Database.saveResult sr : srList){
                    if(sr.isSuccess()){
                        System.debug('FCR Inserted');    
                    }  
                    else{
                        for(Database.Error err : sr.getErrors()){
                            System.debug('****error****'+err.getMessage()+'*****'+err.getFields());
                        }
                    }
                }     
            }
        }
    }
    /**
    * @description allowDuplicateLicense
    * @Purpose  Check whether Duplicate License is allowed or not
    * @return  
	* @param map
    */
    
    public static void allowDuplicateLicense(List<License__c> newItems, Map<Id, SObject> oldItems){
        Map<Id,License__c> mapOldLicense;
        Map<Id, String> mapAccountCountry = new Map<Id, String>();
        Map<String, Boolean> mapCountryMarket = new Map<String,Boolean>();
        Map<String, List<License__c>> mapLicenseNumber = new Map<String,List<License__c>>();
        
        List<Id> lstAccountId = new List<Id>();
        List<License__c> lstChangedRecord = new List<License__c>();
        
        try{
            if(oldItems != null){
                mapOldLicense = (Map<Id,License__c>) oldItems;
            }
            
            if(newItems != null && newItems.size()>0){
                //If Licence Number change or if new entry then store the Outlet Id and changed Licence record 
                for(License__c newLicense : newItems){
                    if((oldItems == null && newLicense.License_Number__c != null) || 
                       (newLicense.License_Number__c != null && oldItems != null && oldItems.containskey(newLicense.Id) &&
                        (mapOldLicense.get(newLicense.Id).License_Number__c == null ||
                         (mapOldLicense.get(newLicense.Id).License_Number__c != null && newLicense.License_Number__c != mapOldLicense.get(newLicense.Id).License_Number__c) 
                        ))
                      ){
                          lstAccountId.add(newLicense.Outlet_Id__c);                     
                          lstChangedRecord.add(newLicense);
                      }
                }
                
                //Get the country code from Account object and create a mapping between Account and Country code that can be used
                //to map the Market Setting and License
                if(lstAccountId != null && lstAccountId.size()>0 && Schema.sObjectType.Account.isAccessible()){
                    for(Account existAccount : [SELECT Id, Country__c, Country__r.Code__c FROM Account WHERE Id IN :lstAccountId]){
                        mapAccountCountry.put(existAccount.Id, existAccount.Country__r.Code__c);
                    }
                    lstAccountId.clear();
                    System.debug('mapAccountCountry::'+mapAccountCountry);
                    
                    //Retrieve only those data from Market setting whose country code matched with Account Country code and create a map whether
                    //duplicate is allowed or not
                    if(mapAccountCountry != null && mapAccountCountry.size()>0 && Schema.sObjectType.Market_Setting__c.isAccessible()){
                        for(Market_Setting__c marketSetting : [SELECT Allow_Duplicate_Licence_Number__c, Geography__c, Geography__r.Code__c FROM Market_Setting__c WHERE Geography__r.Code__c =:mapAccountCountry.values()]){
                            if(marketSetting.Allow_Duplicate_Licence_Number__c){
                                mapCountryMarket.put(marketSetting.Geography__r.Code__c,marketSetting.Allow_Duplicate_Licence_Number__c);  
                            } else {
                                mapCountryMarket.put(marketSetting.Geography__r.Code__c,False);
                            }                            
                        }                                       
                    }
                    
                    System.debug('mapCountryMarket::'+mapCountryMarket);
                }
                
                if(lstChangedRecord != null && lstChangedRecord.size()>0){
                    //Depending on Market setting map, Account country code map and changed License List chrck whether dupliacted allowed or not
                    //If duplicate allowed do nothing if not keep it in map with Licence Number as key
                    for(License__c changedLicense : lstChangedRecord){
                        if(mapAccountCountry.containskey(changedLicense.Outlet_Id__c) && 
                           mapCountryMarket.containskey(mapAccountCountry.get(changedLicense.Outlet_Id__c)) && 
                           !mapCountryMarket.get(mapAccountCountry.get(changedLicense.Outlet_Id__c))
                          ){
                              if(mapLicenseNumber.containsKey(changedLicense.License_Number__c)){
                                  mapLicenseNumber.get(changedLicense.License_Number__c).add(changedLicense);
                              } else {
                                  mapLicenseNumber.put(changedLicense.License_Number__c, new List<License__c>{changedLicense});
                              }                          
                          }
                    }
                    lstChangedRecord.clear();
                    System.debug('mapLicenseNumber::'+mapLicenseNumber);
                }
                
                if(mapLicenseNumber != null && mapLicenseNumber.size()>0 && Schema.sObjectType.License__c.isAccessible()){
                    //Retrieve existing license with same License number of changed recordand matched it with previously created map. If exist thow error
                    for(License__c license : [SELECT Id, Name, License_Number__c, Outlet_Id__c FROM License__c WHERE License_Number__c IN :mapLicenseNumber.keySet()]){
                        if(mapLicenseNumber.containskey(license.License_Number__c)){
                            List<License__c> lstLicense = mapLicenseNumber.get(license.License_Number__c);
                            lstLicense[0].addError('Same License Number '+ license.License_Number__c + ' already exists for a different License ' +license.Name);
                        }
                    }
                    
                    //If same number exists in List of New Records
                    for(String licenseNumber : mapLicenseNumber.keySet()){
                        List<License__c> lstLicense = mapLicenseNumber.get(licenseNumber);
                        if(lstLicense != null && lstLicense.size()>1){
                            lstLicense[0].addError('Same License Number '+ lstLicense[0].License_Number__c + ' already exists multiple time in the same file');
                        }
                    }
                }
            }            
        } catch (Exception licenseException){
            System.debug('Exception:::'+licenseException.getLineNumber()+licenseException.getMessage()+licenseException.getCause());
            new EDGE_GenericException(licenseException, newItems[0]);
        }
        
    }
    
}