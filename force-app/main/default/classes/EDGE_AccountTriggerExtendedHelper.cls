/*
* @description EDGE_AccountTriggerExtendedHelper
* @history
                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0      Sagar Barman       28/11/2019       ES20-5716 - When an outlet is closed, all its associations from other 
											objects / attributes should be removed for keeping the data clean and 
										    consistent, and configurable at market level. 
1.0      Sagar Barman       28/11/2019       createFieldChangeRequest
1.1      Manikant Prasad    24/12/2019       ES20-6592 (updateLastModMasterFld)
1.2      Amar Deep          20/12/2019       ES20-6587 - enableForPendingBatch Method added
1.3     Sagar Barman        01/01/2020       ES20-6108  Updated the FCR creation logic with Parent child creation
                                                        for the dedendent fields
1.4     Amar Deep           13/05/2020       ES20-8029 - productEnableUpdate Method added
1.5     Shahbaz Khan        18/08/2020       ES20-8490 - method ->setPhysicalAndVirtualFreq()[To calculate Physical and Virtual 
                                                                   Visit Frequency].

1.6     Monalisa Halder     31/01/2021       ES20-9212
1.7     Monalisa Halder     27/07/2021       ES20-10866
1.8     Monalisa Halder     24/02/2022       ES20-11303
1.9     Monalisa Halder     12/03/2022       ES20-12274

1.10 	Swaraj Samanta		20/03/2022		 ES20-12236

1.11	Rajarshi Lahiri		20/04/2022		 ES20-12530
1.12	Rajarshi Lahiri		20/09/2022		 ES20-12998
1.13    Monalisa Halder     24/07/2023       142553
1.14	Shivam Chauhan		11/08/2023		 144504

**/
public with sharing class EDGE_AccountTriggerExtendedHelper {
    static MAP<String,Outlet_Attributes_for_Approval__mdt> metaDataApprovalMap; 
    //Static variable to get Market Settings for 
    static Map<Id, Market_Setting__c> accountMarketSettingsMap;
    static MAP<String,String> marketSettingApprovalMap;
    static Map<String,Field_Change_Request__c> mapParentFCR;
    static Map<String,String> mapParentFields;
    static Map<String,List<String>> mapDependentFields;
    final static String OUTLETRECORDTYPEID = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  
    final static String OPERATORRECORDTYPEID = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();    
    
    
    /**
    * @description getMarketSetting
    * @Purpose : Static Method to get Market Settings
    * @return  map
	* @param Id
    */
    
    public static Map<Id, Market_Setting__c> getMarketSetting(Set<Id> setCountryId){        
       // List<Market_Setting__c> marketSettingList = new List<Market_Setting__c>();
        accountMarketSettingsMap =  new Map<Id, Market_Setting__c>();
        if(accountMarketSettingsMap != null && !accountMarketSettingsMap.isEmpty()){
            return accountMarketSettingsMap;
        }else if(accountMarketSettingsMap.isEmpty() && Schema.sObjectType.Market_Setting__c.isAccessible()){ 
            for(Market_Setting__c ms : [SELECT Id,Name,Outlet_Closed_Status_Check__c,Geography__c, Geography__r.Code__c,Local_Segmentation_Validation__c FROM Market_Setting__c WHERE Geography__c IN :setCountryId]){
              accountMarketSettingsMap.put(ms.Geography__c, ms);        
            }  
            
          
        }
        return accountMarketSettingsMap;
    }
    
     /**
    * @description CleanClosedOutlet
    * @Purpose : This method checks if the account in the trigger context has 
                Outlet_Closed_Status_Check__c as true in market setting, if true 
                it makes the outlet's Called_on__c and Send_To_Trax__c false 
    * @param list, Map
    */
    public static void cleanClosedOutlet(List<Account> newitems , Map<Id,SObject> oldItems){        
        
        Map<Id,Account> oldItemsmap = new Map<Id,Account>();
        Set<Id> setCountryId = new Set<Id>();
        Set<Id> outletIdset = new Set<Id>();
        List<Account> outletsToProcess = new List<Account>();   
       
        //putting oldItems in oldItemsmap
        if(oldItems!= null){
            oldItemsmap = (Map<Id,Account>)oldItems;
        }
        //populating the setCountryId set
        for(Account acc: newitems){
            if(acc.RecordTypeId == OUTLETRECORDTYPEID && acc.Status__c == 'Closed' && oldItemsmap.get(acc.Id).Status__c != 'Closed'){ 
                outletsToProcess.add(acc);
                setCountryId.add(acc.Country__c);
                outletIdset.add(acc.Id);
            }
        } 
        
        if(outletsToProcess.size() > 0){
            
            //call the getMarketSetting method to get the Market Setting
            Map<Id, Market_Setting__c> accountMarketSettingsMap = getMarketSetting(setCountryId);
            
            //updating Called_on__c and Send_To_Trax__c fields to false
            for(Account acc : outletsToProcess){
                if(accountMarketSettingsMap != null){
                    Market_Setting__c marketSetting = accountMarketSettingsMap.get(acc.Country__c);
                    if(marketSetting !=null && marketSetting.Outlet_Closed_Status_Check__c){	//144504
                        acc.Called_on__c = false;
                        acc.Send_To_Trax__c = false;    
                    }
                }
            }        
            // call the RemoveClosedOutlet method for
            removeClosedOutlet(setCountryId,outletIdset);           
        }
        
        
    }  
    
     /**
    * @description RemoveClosedOutlet
    * @Purpose : Make the related Outlet territory and Target list member 'Waiting Removal' 
    * @param Set
    */
     
    public static void removeClosedOutlet( Set<Id> setCountryId, Set<Id> outletIdset ){
        
        List<Outlet_Territory__c> listTerritoryToUpdate = new List<Outlet_Territory__c>(); 
        List<Target_List_Member__c> listTargetMemberToUpdate = new List<Target_List_Member__c>();
        //call the getMarketSetting method to get the Market Setting
        Map<Id, Market_Setting__c> accountMarketSettingsMap = new Map<Id, Market_Setting__c>();
        if(setCountryId.size() > 0){ // sagar added this line not to query if setCountryId is empty
            accountMarketSettingsMap = getMarketSetting(setCountryId);    
        }
        
        if(Schema.sObjectType.Outlet_Territory__c.isAccessible()){
            for(Outlet_Territory__c ot : [Select Id, Outlet__c,Outlet__r.Country__c, Territory__c, Active__c From Outlet_Territory__c where Outlet__c IN : outletIdset ]){
                if(accountMarketSettingsMap != null){
                    Market_Setting__c marketSetting = accountMarketSettingsMap.get(ot.Outlet__r.Country__c);
                    if(marketSetting != null && marketSetting.Outlet_Closed_Status_Check__c){	//144504
                        ot.Active__c = 'Waiting Removal'; 
                        listTerritoryToUpdate.add(ot);
                        
                    }    
                }    
            }
        }            
        
        //make outlet territory waiting Removal        
        if(listTerritoryToUpdate.size() >0 ){
            List<Database.SaveResult> dsrList = Database.update(listTerritoryToUpdate,false);
            System.debug(LoggingLevel.DEBUG,'dsrList : '+ dsrList);
        }
        
        if(Schema.sObjectType.Target_List_Member__c.isAccessible()){
            for(Target_List_Member__c tm : [Select Id, Outlet__c,Outlet__r.Country__c,Assignment_Status__c From Target_List_Member__c where Outlet__c IN : outletIdset]){
                if(accountMarketSettingsMap != null && accountMarketSettingsMap.containsKey(tm.Outlet__r.Country__c)){
                    Market_Setting__c marketSetting = accountMarketSettingsMap.get(tm.Outlet__r.Country__c);
                    if(marketSetting!= null && marketSetting.Outlet_Closed_Status_Check__c == true){
                        tm.Assignment_Status__c = 'Waiting Removal';   
                        listTargetMemberToUpdate.add(tm);    
                    }    
                }    
            }
        }
        
        //make Target List Member waiting Removal        
        if(listTargetMemberToUpdate.size() > 0){
            Database.update(listTargetMemberToUpdate,false);
        } 
    }
    
    /**
    * @description updateLastModMasterFld
    * @Purpose if the value of the feilds containing in the FieldSet is
    		changed then the Last Modify Master Data field will be updated with current date and time .
    * @param Map
    */
       
    public static void updateLastModMasterFld(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Set<String> fieldsSet = new Set<String>();
        Map<Id,Account> oldAccountMap,newAccountMap;
        if(oldItems !=null){
            oldAccountMap = (Map<Id,Account>) oldItems;            
        }
        if(newItems != null){
            newAccountMap= (Map<Id,Account>) newItems;
        }        
        for(Schema.FieldSetMember fld : SObjectType.Account.fieldSets.getMap().get('Master_data_change_fields_of_Account').getFields()){
            fieldsSet.add(fld.fieldpath);
        }                
        for( Id accId : newAccountMap.keySet()){
            for(String fieldName : fieldsSet){
                if(newAccountMap.get(accId).get(fieldName) != oldAccountMap.get(accId).get(fieldName)){
                    newAccountMap.get(accId).Last_Modify_Data_Master__c = system.now();
                    break;   
                }
                
            }
            
        }  
    }
    /**
    * @description enableForPendingBatch
    * @Purpose This method used to enable the Pending for Batch field in territory and territory hierarchy when Last update trax field changed
    * @param List , Map
    */
     
    public static void enableForPendingBatch(List<Account> newItems,Map<Id,SObject> oldItems){
        set<Id> primarySalesTerritoryIds = new set<Id>();
        set<Id> primarySalesTerritoryHierarchyIds = new set<Id>();
        Set<Id> accRecAlreadyExecutedSet = new Set<Id>();
        Map<Id,Account> oldAccountMap= (Map<Id,Account>) oldItems;
        List<Territory__c> territoryList = new List<Territory__c>();
        List<Territory_Hierarchy__c> territoryHierarchyList = new List<Territory_Hierarchy__c>();
        //ES20-8272 changes: create list of KPI Related fields 
        List<Schema.FieldSetMember> fieldSetMemberList=SObjectType.Account.FieldSets.KPI_Related_Fields.getFields();
        if(newItems!=null){
            for(Account accRec : newItems){
                Account oldAccRec = OldAccountMap.get(accRec.id); 
                for(Schema.FieldSetMember fsm : fieldSetMemberList){                    
                    if(OldAccountMap != null && oldAccRec!=null && !accRecAlreadyExecutedSet.contains(accRec.id) 
                       && accRec.get(fsm.getFieldPath()) != oldAccRec.get(fsm.getFieldPath())){ //changed the conditions as per ES20-8272
                        if(accRec.Primary_Sales_Territory__c != null){
                            primarySalesTerritoryIds.add(accRec.Primary_Sales_Territory__c); 
                        }



                        if (accRec.Activation_Territory_LT__c  != null){ //added the conditions as per ES20-12236
                          
                            primarySalesTerritoryIds.add(accRec.Activation_Territory_LT__c ); 
                        }



                        if(accRec.Primary_Sales_Territory_Region__c != null){
                            primarySalesTerritoryHierarchyIds.add(accRec.Primary_Sales_Territory_Region__c);
                        }
                        accRecAlreadyExecutedSet.add(accRec.Id); // added as part of ES20-8272
                    }
                }    
            }
            //Fetching respective Territory data
            System.debug(LoggingLevel.DEBUG,'primarySalesTerritoryIds '+primarySalesTerritoryIds);
            if(Schema.sObjectType.Territory__c.isAccessible()){
                If(primarySalesTerritoryIds != null && primarySalesTerritoryIds.size() > 0 ){
                    for(Territory__c terr : [SELECT Id, Country__c,Pending_for_Batch__c FROM Territory__c WHERE Id IN : primarySalesTerritoryIds]){
                        terr.Pending_for_Batch__c = true;
                        territoryList.add(terr);
                    }
                }
            }
            //Fetching respective Territory Hierarchy data
            if(Schema.sObjectType.Territory_Hierarchy__c.isAccessible()){
                If(primarySalesTerritoryHierarchyIds != null && primarySalesTerritoryHierarchyIds.size() > 0 ){
                    for(Territory_Hierarchy__c terrHie : [SELECT Id, Geography__c,Pending_for_Batch__c FROM Territory_Hierarchy__c WHERE Id IN : primarySalesTerritoryHierarchyIds]){
                        terrHie.Pending_for_Batch__c = true;
                        territoryHierarchyList.add(terrHie);
                        
                    }
                }
            }
            
        }
        if(Schema.sObjectType.Territory__c.isUpdateable() && territoryList.size() > 0){
            Database.update(territoryList); 
        }
        if(Schema.sObjectType.Territory_Hierarchy__c.isUpdateable() && territoryHierarchyList.size() > 0){
            Database.update(territoryHierarchyList);
        }
    } 
    

    /**
    * @description createFieldChangeRequest
    * @Purpose : This method is to create Field Change Request object and
    				submit for Approval 
    * @param map, Map
    */
    
    public static void createFieldChangeRequest(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<String,Boolean> eligibleForApprovalMap = new Map<String,Boolean>();
        Map<String,Field_Permission__c> fieldPermissionOutletMap = new Map<String,Field_Permission__c>();
        Map<String,Field_Permission__c> fieldPermissionProspectMap = new Map<String,Field_Permission__c>();
        Map<String,String> mapParentFieldsReturned = new Map<String,String>();
        Map<String,List<String>> mapDependentFieldsReturned = new Map<String,List<String>>();
        List<String> salesRepList = new List<String>();
        String salesRepProfiles = label.EDGE_Rep_Profiles;
        Id UserId = UserInfo.getUserId();
        Id managerID = [SELECT Id,ManagerId FROM User WHERE Id=: UserInfo.getUserId()].ManagerId;
        Id profileId= Userinfo.getProfileId();
        String profileName=[SELECT Id,Name FROM Profile WHERE Id=:profileId].Name;
        if(String.isNotBlank(salesRepProfiles)){
            salesRepList = salesRepProfiles.split(';');
                        
        }
        if(!EDGE_UtilityClass.stopTriggerToRun && salesRepList.contains(profileName)){
            List<Field_Change_Request__c> childFCRInsertList = new List<Field_Change_Request__c>();
            List<Field_Change_Request__c> singleFCRInsertList = new List<Field_Change_Request__c>();
            mapParentFCR = new Map<String,Field_Change_Request__c>();    
            EDGE_UtilityClass.populateFieldPermissionMaps('Account', fieldPermissionOutletMap,fieldPermissionProspectMap,null, mapParentFieldsReturned, mapDependentFieldsReturned);
            if(mapParentFieldsReturned != null){
                mapParentFields = mapParentFieldsReturned;
            }
            if(mapDependentFieldsReturned != null){
                mapDependentFields = mapDependentFieldsReturned;
            }
            System.debug(LoggingLevel.DEBUG,'@mapParentFieldsReturned'+mapParentFieldsReturned);
            System.debug(LoggingLevel.DEBUG,'@mapDependentFieldsReturned'+mapDependentFieldsReturned);
            for(SObject sObj : newItems.values()){
                Account newAccount = (Account)sObj;
                Account oldAccount;
                if(oldItems!= null && oldItems.containsKey(newAccount.Id)){
                    oldAccount = (Account)oldItems.get(newAccount.Id);
                }
                
                if(newAccount.recordtypeid == OUTLETRECORDTYPEID){ //outlet check 
                    for(String field: fieldPermissionOutletMap.keySet()){
                        
                         if(newAccount.get(field) != oldAccount.get(field)){
                            if((fieldPermissionOutletMap.get(field)!=null && fieldPermissionOutletMap.get(field).Permission__c.containsIgnoreCase(System.Label.EDGE_Sales_Manager_Required)) || 
                               (fieldPermissionOutletMap.get(field)!=null && fieldPermissionOutletMap.get(field).Permission__c.containsIgnoreCase(System.Label.EDGE_MDM_Approval_Required)))
                            {
                                eligibleForApprovalMap.put(field,true); 
                            }else{
                                eligibleForApprovalMap.put(field,false);    
                            }                            
                             System.debug(LoggingLevel.DEBUG,'eligibleForApprovalMap'+eligibleForApprovalMap);
                            if(eligibleForApprovalMap.get(field)){
                                
                                if(!mapDependentFields.isEmpty() && mapDependentFields.containsKey(field) 
                                   && !mapParentFields.containsKey(field)){ //this loop is for parent fields
                                       String subKey = newAccount.Id+'_'+field;
                                       if(!mapParentFCR.isEmpty() && mapParentFCR.containsKey(subKey)){
                                           String tempDesc = mapParentFCR.get(subKey).Approval_Description__c;
                                           mapParentFCR.get(subKey).Approval_Description__c = tempDesc+' '+field + ':'+'Old Value = '+String.valueOf(oldAccount.get(field))+' New Value = '+String.valueOf(newAccount.get(field));      
                                           System.debug(LoggingLevel.DEBUG,'mapParentFCR.get(subKey).Approval_Description__c'+mapParentFCR.get(subKey).Approval_Description__c);
                                       }else{
                                           Field_Change_Request__c pfcr = new Field_Change_Request__c(); 
                                           pfcr =  getParentFCRBody(field,newAccount,oldAccount,managerID,fieldPermissionOutletMap);
                                           pfcr.Approval_Description__c= ' '+field + ':'+'Old Value = '+String.valueOf(oldAccount.get(field))+' New Value = '+String.valueOf(newAccount.get(field));   
                                           System.debug(LoggingLevel.DEBUG,'@@pfcr'+pfcr);
                                           mapParentFCR.put(subKey,pfcr);
                                       }
                                       String tempDesc = '';
                                       tempDesc = mapParentFCR.get(subKey).Approval_Description__c;                                       
                                       for(String cField : mapDependentFields.get(field)){                                           
                                           String containsDesc = ', '+cField + ':'+'Old Value = '+String.valueOf(oldAccount.get(cField))+' New Value = '+String.valueOf(newAccount.get(cField));
                                           if(!tempDesc.contains(containsDesc)){
                                               tempDesc = tempDesc+' '+containsDesc;            
                                           }
                                       }
                                       if(field != 'Status__c'){
                                           mapParentFCR.get(subKey).Approval_Description__c = tempDesc;
                                       }else if(field == 'Status__c' && newAccount.get(field) == 'Temporarily Closed'){
                                           mapParentFCR.get(subKey).Approval_Description__c = tempDesc;    
                                       }    
                                   }else if(!mapDependentFields.containsKey(field) && mapParentFields.containsKey(field) && (newAccount.get(mapParentFields.get(field))!=oldAccount.get(mapParentFields.get(field)))){//Added Parent field change check for ES20-12530
                                       //this loop is for child fields
                                       //set the approver required fields, it will override approver required fields if dependent fields require more approval
                                       setApproverFields(field, newAccount, oldAccount, managerID,fieldPermissionOutletMap);
                                       String subKey = newAccount.Id+'_'+mapParentFields.get(field);
                                       String tempDesc = '';
                                       tempDesc = mapParentFCR.get(subKey).Approval_Description__c;                                       
                                       for(String cField : mapDependentFields.get(mapParentFields.get(field))){
                                           String containsDesc = ', '+cField + ':'+'Old Value = '+String.valueOf(oldAccount.get(cField))+' New Value = '+String.valueOf(newAccount.get(cField));
                                           if(!tempDesc.contains(containsDesc)){
                                               tempDesc = tempDesc+' '+containsDesc;                
                                           }
                                       } 
                                       mapParentFCR.get(subKey).Approval_Description__c = tempDesc;
                                       system.debug(LoggingLevel.DEBUG,'@@tempDesc339' +tempDesc);
                                   }else{
                                       //single fcr where the field has no dependency
                                       Field_Change_Request__c sfcr = getParentFCRBody(field,newAccount,oldAccount,managerID,fieldPermissionOutletMap);
                                       singleFCRInsertList.add(sfcr);
                                      
                                   }
                            }
                        }   
                        
                        // old value new vlaue check if end                        
                    }//2nd for
                    
                }//big if    
            }//big for end here
            //insert the parent fcr list first            
            if(null != mapParentFCR && mapParentFCR.values().size() > 0){
               // updateFCRRequest('Pick_Up_Options__c');
                system.debug(LoggingLevel.DEBUG,'@@ParentFCR' +mapParentFCR.values());
                insert mapParentFCR.values();
                
            }
            //create child fcr
            if(mapParentFCR != null && mapParentFCR.size()>0){
                for(Field_Change_Request__c pfcr : mapParentFCR.values()){
                    List<String> tempList = new List<String>();
                    tempList = mapDependentFields.get(pfcr.Field_Name__c);
                    if(pfcr.Field_Name__c != 'Status__c'){
                        for(String temp : tempList){
                            Field_Change_Request__c cfcr = getChildFCRBody(pfcr,newItems,oldItems,temp);
                            childFCRInsertList.add(cfcr);    
                        }              
                    }else if(pfcr.Field_Name__c == 'Status__c' && pfcr.New_Value__c == 'Temporarily Closed'){
                        for(String temp : tempList){
                            Field_Change_Request__c cfcr = getChildFCRBody(pfcr,newItems,oldItems,temp);
                            childFCRInsertList.add(cfcr);   
                           
                        }       
                    }
                } 
            }
            //reset to old values            
            for(SObject sObj : newItems.values()){
                Account newAccount = (Account)sObj;
                Account oldAccount;
                if(oldItems!= null && oldItems.containsKey(newAccount.Id)){
                    oldAccount = (Account)oldItems.get(newAccount.Id);
                }
                if(newAccount.recordtypeid == OUTLETRECORDTYPEID){ //outlet check 
                    for(String field: fieldPermissionOutletMap.keySet()){                        
                        if(newAccount.get(field) != oldAccount.get(field)){
                            // String key = newAccount.Country__c+'_'+metaDataApprovalMap.get(field).Market_Setting_Field_Name__c;                                       
                            if(eligibleForApprovalMap.get(field) && (mapParentFields.containsKey(field)) && (null != mapDependentFields.get(mapParentFields.get(field)))){
                                for(String cfield : mapDependentFields.get(mapParentFields.get(field))){
                                    newAccount.put(cfield,oldAccount.get(cfield)); // reassign the old value        
                                }
                                newAccount.put(mapParentFields.get(field),oldAccount.get(mapParentFields.get(field)));
                            }else if(eligibleForApprovalMap.get(field) && (!mapParentFields.containsKey(field)) && (mapDependentFields.containsKey(field))){
                                newAccount.put(field,oldAccount.get(field)); // reassign the old value
                                for(String cfield : mapDependentFields.get(field)){
                                    newAccount.put(cfield,oldAccount.get(cfield)); // reassign the old value        
                                }
                            }else if(eligibleForApprovalMap.get(field) && (!mapParentFields.containsKey(field)) && (!mapDependentFields.containsKey(field))){
                                newAccount.put(field,oldAccount.get(field)); // reassign the old value      
                            }       
                        }                        
                    }
                    
                } 
                
            }          
            
            //add all from singleFCRInsertList
            if(singleFCRInsertList.size()>0){
                childFCRInsertList.addAll(singleFCRInsertList);
            }
            //having one dml for child FCR and not dependent field single FCR
            if(childFCRInsertList.size()>0 && Schema.sObjectType.Field_Change_Request__c.isCreateable()){
               system.debug(LoggingLevel.DEBUG,'@@childFCRInsertList' +childFCRInsertList);
                insert childFCRInsertList;  
                
                
            }
        
        }
        //}
    }
    
   
   
     //RECORD FORMATION of Paret FCR
    public static Field_Change_Request__c getParentFCRBody(String field,Account newAccount,Account oldAccount,Id managerID,Map<String,Field_Permission__c> fieldPermissionOutletMap){    
        Field_Change_Request__c fcr = new Field_Change_Request__c();
        if(null != field){
            fcr.MDM_Approval_required__c = false;
            fcr.Sales_manager_approval_required__c = false;
            if(fieldPermissionOutletMap.get(field) !=null && (fieldPermissionOutletMap.get(field).Permission__c.containsIgnoreCase(System.Label.EDGE_Sales_Manager_Required))){
                fcr.Sales_manager_approval_required__c = true;
            }else if(fieldPermissionOutletMap.get(field) !=null && fieldPermissionOutletMap.get(field).Permission__c.containsIgnoreCase(System.Label.EDGE_MDM_Sales_Manager_Required)){
                fcr.MDM_Approval_required__c = true;
                fcr.Sales_manager_approval_required__c = true;
            }else if(fieldPermissionOutletMap.get(field) !=null && fieldPermissionOutletMap.get(field).Permission__c.containsIgnoreCase(System.Label.EDGE_MDM_Approval_Required)){
                fcr.MDM_Approval_required__c = true;
            }                              
            fcr.Geography__c = newAccount.Country__c;                                 
            fcr.Approver__c = managerID;
            fcr.Field_Name__c = field;
            fcr.New_Value__c = String.valueOf(newAccount.get(field));
            fcr.Old_Value__c = String.valueOf(oldAccount.get(field)); 
            fcr.Changed_By__c = UserInfo.getUserId();
            fcr.Outlet__c = newAccount.Id;
            //fcr.Status__c = 'New';
            fcr.Object_Type__c = 'Account';
            fcr.Approval_Header__c = true;
            if(EDGE_UtilityClass.getFieldType(fcr.Object_Type__c,field)!= null){                           
                fcr.Field_Type__c = EDGE_UtilityClass.getFieldType(fcr.Object_Type__c,field);    
            }
            //ES20-12274
            if(fcr.Field_Type__c == 'REFERENCE'){
            String objectName = '';
            Id newId = (Id)newAccount.get(field);
            Id oldId = (Id)oldAccount.get(field);  
            if(newId != null){
              objectName = newId.getSObjectType().getDescribe().getName();     
            }else if(oldId != null){
              objectName = oldId.getSObjectType().getDescribe().getName(); 
            }
            /*if(fcr.Field_Type__c == 'REFERENCE'){
            Id newId = (Id)newAccount.get(field);
            String objectName = newId.getSObjectType().getDescribe().getName();*/
            //25-Feb
            system.debug(LoggingLevel.DEBUG,'@@objectName' +objectName);
            fcr.Lookup_Object_Type__c = objectName;
           

            }
        }    

        
        return fcr;
        
    }
    
    //get child FCR Body
    public static Field_Change_Request__c getChildFCRBody(Field_Change_Request__c pfcr,Map<Id, SObject> newItems, Map<Id, SObject> oldItems,String temp){
        Field_Change_Request__c cfcr = new Field_Change_Request__c();
        cfcr.Geography__c = pfcr.Geography__c;                                 
        cfcr.Approver__c = pfcr.Approver__c;
        cfcr.Field_Name__c = temp;
        Account newAccount = (Account)newItems.get(pfcr.Outlet__c);
        cfcr.New_Value__c = String.valueOf(newAccount.get(temp));
        Account oldAccount = (Account)oldItems.get(pfcr.Outlet__c);
        cfcr.Old_Value__c = String.valueOf(oldAccount.get(temp));
        cfcr.Changed_By__c = UserInfo.getUserId();
        cfcr.Outlet__c = pfcr.Outlet__c;
        //cfcr.Status__c = 'New';
        cfcr.Object_Type__c = 'Account';
        cfcr.Parent_Approval__c = pfcr.Id;
        if(EDGE_UtilityClass.getFieldType(cfcr.Object_Type__c,temp)!= null){                           
            cfcr.Field_Type__c = EDGE_UtilityClass.getFieldType(cfcr.Object_Type__c,temp);    
        }
        //ES20-12274
        if(cfcr.Field_Type__c == 'REFERENCE'){
            String objectName = '';
            Id newId = (Id)newAccount.get(temp);
            Id oldId = (Id)oldAccount.get(temp);  
            if(newId != null){
              objectName = newId.getSObjectType().getDescribe().getName();     
            }else if(oldId != null){
              objectName = oldId.getSObjectType().getDescribe().getName(); 
            }
       
            //25-Feb
            cfcr.Lookup_Object_Type__c = objectName;
            
            }
        system.debug(LoggingLevel.DEBUG,'@@cfcr'+cfcr);
        return cfcr;
        
    }
    
    //method to check the Approval required values for child
    public static void setApproverFields(String field,Account newAccount,Account oldAccount,Id managerID,Map<String,Field_Permission__c> fieldPermissionOutletMap){
        String subKey = newAccount.Id+'_'+mapParentFields.get(field);
        
        if(fieldPermissionOutletMap.get(field) !=null && fieldPermissionOutletMap.get(field).Permission__c.containsIgnoreCase(System.Label.EDGE_Sales_Manager_Required)){                                       
            system.debug(LoggingLevel.DEBUG,'@@field558' +field);
            System.debug(LoggingLevel.DEBUG,'474 - mapParentFCR = '+ mapParentFCR);
            if(!mapParentFCR.isEmpty() && mapParentFCR.containsKey(subKey)){
                mapParentFCR.get(subKey).Sales_manager_approval_required__c = true;         
            }else{
                
                Field_Change_Request__c pfcr = new Field_Change_Request__c(); 
                pfcr =  getParentFCRBody(mapParentFields.get(field),newAccount,oldAccount,managerID,fieldPermissionOutletMap);
                pfcr.Sales_manager_approval_required__c = true;
                pfcr.Approval_Description__c= ' '+field + ':'+'Old Value = '+String.valueOf(oldAccount.get(field))+' New Value = '+String.valueOf(newAccount.get(field));    
                mapParentFCR.put(subKey,pfcr);  
                System.debug(LoggingLevel.DEBUG,'@@590 - pfcr = '+ pfcr);

            }
        }else if(fieldPermissionOutletMap.get(field) !=null && fieldPermissionOutletMap.get(field).Permission__c.containsIgnoreCase(System.Label.EDGE_MDM_Sales_Manager_Required)){
            system.debug(LoggingLevel.DEBUG,'@@field573' +field);
            if(!mapParentFCR.isEmpty() && mapParentFCR.containsKey(subKey)){
                mapParentFCR.get(subKey).MDM_Approval_required__c = true;                                       
                mapParentFCR.get(subKey).Sales_manager_approval_required__c = true;     
            }else{
                Field_Change_Request__c pfcr = new Field_Change_Request__c(); 
                pfcr =  getParentFCRBody(mapParentFields.get(field),newAccount,oldAccount,managerID,fieldPermissionOutletMap);
                pfcr.Sales_manager_approval_required__c = true;
                pfcr.MDM_Approval_required__c = true;
                pfcr.Approval_Description__c= ' '+field + ':'+'Old Value = '+String.valueOf(oldAccount.get(field))+' New Value = '+String.valueOf(newAccount.get(field));    
                mapParentFCR.put(subKey,pfcr);
                System.debug(LoggingLevel.DEBUG,'@@604 - pfcr = '+ pfcr);

            }
        }else if(fieldPermissionOutletMap.get(field) !=null && fieldPermissionOutletMap.get(field).Permission__c.containsIgnoreCase(System.Label.EDGE_MDM_Approval_Required)){                                       
            system.debug(LoggingLevel.DEBUG,'@@field588' +field);
            if(!mapParentFCR.isEmpty() && mapParentFCR.containsKey(subKey)){
                mapParentFCR.get(subKey).MDM_Approval_required__c = true;                                    
                String tempDesc = mapParentFCR.get(subKey).Approval_Description__c;
                System.debug(LoggingLevel.DEBUG,'@@589 - tempDesc = '+ tempDesc);
                //mapParentFCR.get(subKey).Approval_Description__c = tempDesc+' '+field + ':'+'Old Value = '+String.valueOf(oldAccount.get(field))+' New Value = '+String.valueOf(newAccount.get(field));
                mapParentFCR.get(subKey).Approval_Description__c = tempDesc; //142553
                System.debug(LoggingLevel.DEBUG,'@@591 - approDesc = '+ mapParentFCR.get(subKey).Approval_Description__c);
            }else{
                Field_Change_Request__c pfcr = new Field_Change_Request__c(); 
                pfcr =  getParentFCRBody(mapParentFields.get(field),newAccount,oldAccount,managerID,fieldPermissionOutletMap);
                pfcr.MDM_Approval_required__c = true;
                pfcr.Approval_Description__c= ' '+field + ':'+'Old Value = '+String.valueOf(oldAccount.get(field))+' New Value = '+String.valueOf(newAccount.get(field));    
                mapParentFCR.put(subKey,pfcr);
                System.debug(LoggingLevel.DEBUG,'@@618 - pfcr = '+ pfcr);

            }
        } 
        system.debug(LoggingLevel.DEBUG,'@@622mapParentFCR'+mapParentFCR);
    }

    
    /*******************************************************************
Method  : productEnableUpdate
Purpose : This method used to update the Products Enabled field to EDGE365 when the Primary Sales Territory is not null
********************************************************************/  
    public static void productEnableUpdate(List<Account> newItems,Map<Id,SObject> oldItems){
        Map<Id,Account> oldAccountMap= new Map<Id,Account>();
        
        if(oldItems != null){
             oldAccountMap= (Map<Id,Account>) oldItems;
        }
        
        if(newItems!=null){
            if(oldItems == null){ //Insert Scenraio
                for(Account accRec : newItems){
                    if(accRec.Primary_Sales_Territory__c != null && accRec.recordtypeid == OUTLETRECORDTYPEID){
                        accRec.Products_Enabled__c = label.EDGE_ProductsEnablePicklist;  
                    }
                }
            }else{ //Update Scenario               
                for(Account accRec : newItems){
                    String picklist = '';
                    
                    if(accRec.Products_Enabled__c != null && accRec.recordtypeid == OUTLETRECORDTYPEID){
                        picklist = accRec.Products_Enabled__c;
                    }
                    
                    if(oldAccountMap != null && oldAccountMap.get(accRec.Id).Primary_Sales_Territory__c != accRec.Primary_Sales_Territory__c && accRec.recordtypeid == OUTLETRECORDTYPEID){
                        if(accRec.Primary_Sales_Territory__c !=null ){
                            if( picklist.contains(label.EDGE_ProductsEnablePicklist)){
                                accRec.Products_Enabled__c = picklist;
                            }else{
                                accRec.Products_Enabled__c = picklist + ';'+label.EDGE_ProductsEnablePicklist;
                            }
                            
                        }else if(accRec.Products_Enabled__c != null){
                            accRec.Products_Enabled__c = accRec.Products_Enabled__c.replaceAll(';?'+label.EDGE_ProductsEnablePicklist+';?','');
                        }
                    }
                }
            }
        }
        
        
    }
/*******************************************************************
Name : setPhysicalAndVirtualFreq
Description : To calculate & populate Physical and Virtual Visit Frequency
********************************************************************/
    public static void setPhysicalAndVirtualFreq(List<Account> newItems, Map<Id, SObject> oldItems){
        Set<Id> countryIdSet = new Set<Id>();
        Set<Id> outletPriorOptionSet = new Set<Id>();
        List<Account> accountListToExecute = new List<Account>();
        Map<Id,Decimal> countryWithMarketDaysMap = new Map<Id,Decimal>();
        Map<Id,Decimal> outVistWithMinPhy = new Map<Id,Decimal>();
        Map<Id,Decimal> outVistWithMinVir = new Map<Id,Decimal>();
        Map<Id,Account> oldItemMap = (Map<Id,Account>)oldItems;
      
        for(Account outRec : newItems){
            if((oldItemMap!=null && oldItemMap.get(outRec.Id).Outlet_Visit_Prioritisation_Grade__c != outRec.Outlet_Visit_Prioritisation_Grade__c) 
               || (oldItemMap == null && outRec.RecordTypeId == OUTLETRECORDTYPEID && outRec.Outlet_Visit_Prioritisation_Grade__c != null)){
                countryIdSet.add(outRec.Country__c);
                outletPriorOptionSet.add(outRec.Outlet_Visit_Prioritisation_Grade__c);
                accountListToExecute.add(outRec);
            }
        }
            if(accountListToExecute.size() > 0){
                for(Market_Cycle__c marketCycle : [SELECT Id,Active__c,Geography__c,Number_Of_Working_Day__c FROM Market_Cycle__c WHERE Geography__c IN : 
                                                   countryIdSet AND Active__c = TRUE]){
                                                       countryWithMarketDaysMap.put(marketCycle.Geography__c,marketCycle.Number_Of_Working_Day__c);                         
                                                   }
                
                for(Pick_Up_Options__c outVisitPriot : [SELECT Id,Geography__c,Min_Physical_Call_Per_Market_Cycle__c,Min_Virtual_Call_Per_Market_Cycle__c
                                                        FROM Pick_Up_Options__c WHERE Id IN : outletPriorOptionSet]){
                                                            outVistWithMinPhy.put(outVisitPriot.Id,outVisitPriot.Min_Physical_Call_Per_Market_Cycle__c);
                                                            outVistWithMinVir.put(outVisitPriot.Id,outVisitPriot.Min_Virtual_Call_Per_Market_Cycle__c);
                                                        }
                
                
                for(Account outRec : accountListToExecute){
                    Account accObj = (Account)outRec;
                    if(countryWithMarketDaysMap.get(accObj.Country__c) != null){
                            Decimal noOfWorkingDays = countryWithMarketDaysMap.get(accObj.Country__c);
                            Decimal minPhysCall = EDGE_UtilityClass.checkForNull(outVistWithMinPhy.get(accObj.Outlet_Visit_Prioritisation_Grade__c))
                                                  != 0 ? outVistWithMinPhy.get(accObj.Outlet_Visit_Prioritisation_Grade__c) : 1;
                            accObj.Physical_Visit_Frequency__c = Integer.valueOf(noOfWorkingDays/minPhysCall);
                        
                            Decimal minVirCall = EDGE_UtilityClass.checkForNull(outVistWithMinVir.get(accObj.Outlet_Visit_Prioritisation_Grade__c))
                                                 !=0 ? outVistWithMinVir.get(accObj.Outlet_Visit_Prioritisation_Grade__c) : 1;
                            accObj.Virtual_Visit_Frequency__c = Integer.valueOf(noOfWorkingDays/minVirCall);
                        
                    }
                }
            }
    }

    
/*******************************************************************
Name : sendPushNotifRejectProspects
Description : To send push notification when Prospect is Approved or Rejected.(ES20-12998)
********************************************************************/
    public static void sendPushNotifRejectProspects(List<Account> newItems, Map<Id, SObject> oldItems){
        
        final String EDGE_Connected_App = System.Label.EDGE_ConnectedApp;
        List<Account> prospectList=new List<Account>();
        Map<Account,String> prosToUsersMap = new Map<Account,String>();
        Map<String,Object> custom = new Map<String,Object>();
        Map<Id,Boolean> prospectStatusMap=new Map<Id,Boolean>();//to store the status of approval
        Map<Id,Account> oldItemMap = (Map<Id,Account>)oldItems;
        
        for(Account outRec : newItems){
            if(outRec.Record_Type_Name__c=='Prospect' && oldItemMap.get(outRec.Id).Status__c=='Approval In Progress'){
                if(outRec.Status__c=='Approved'){
                    prospectList.add(outRec);
                    prosToUsersMap.put(outRec,outRec.CreatedById);
                    prospectStatusMap.put(outRec.Id,true);
                }
                if(outRec.Status__c=='Rejected'){
                    prospectList.add(outRec);
                    prosToUsersMap.put(outRec,outRec.CreatedById);
                    prospectStatusMap.put(outRec.Id,false);
                }
            }
       }
        
        String messageAppr=System.Label.EDGE_MsgForApprovedProspectPushNotif;
        String messageRej=System.Label.EDGE_MsgForRejectedProspectPushNotif;
        

            if(prosToUsersMap!=null && prosToUsersMap.size()>0)
         	{                
                for(Account acc:prosToUsersMap.keySet()){
                    String beforeMsg='';
                    String msgAfter='';
                    //Add prospect name between the message
                    if(prospectStatusMap.get(acc.Id)){// Approved Prospects
                         beforeMsg = messageAppr.substringBefore('.') != null ? messageAppr.substringBefore('.')+acc.Name: acc.Name;
                         msgAfter  = messageAppr.substringAfter('.') != null ? messageAppr.substringAfter('.'): msgAfter; 
                    }
                    else{// Rejected Prospects
                        beforeMsg = messageRej.substringBefore('.') != null ? messageRej.substringBefore('.')+acc.Name: acc.Name;
                        msgAfter  = messageRej.substringAfter('.') != null ? messageRej.substringAfter('.'): msgAfter; 
                    }
                   	
                    
                    String userToNotify = prosToUsersMap.get(acc);
                    Set<String> usersList = new Set<String>();
                    usersList.add(userToNotify);
                    
                    String pushNotifMsg= (beforeMsg != null ? beforeMsg : '') + (msgAfter != null ? msgAfter : '');
                    String msgBody = pushNotifMsg.stripHtmlTags();
                    
                    custom.put('AccountID',acc.Id);
                    custom.put('Type','Account');
                    
                    Messaging.PushNotification msg = new Messaging.PushNotification();
                    if(msgBody != null){
                    	Map<String, Object> payload = Messaging.PushNotificationPayload.apple(msgBody,null,null,custom);
                    	msg.setPayload(payload);
                    }
                    
                    if(!Test.isRunningTest()){
                        msg.send(EDGE_Connected_App, usersList);  
                    }                   
                }
         	}
                
       }
        
}