/**
*@ Description Name: EDGE_AccountTriggerHelper

*@ History :                                                            
1.0    Kapil Baliyan    06/02/2019      Initial Development
2.0    Dipanjan Das     22/02/2019      ES20-195
3.0    Dipanjan Das     06/03/2019      ES20-380  
4.0    Monalisa Halder  07/03/2019      ES20-377
5.0    Saurav Paul       12/04/2019     ES20-959
6.0    Sagar Kumar Barman 07/07/2019    ES20-628(createFieldChangeRequest method in Extended Helper Class)   
7.0    Dipanjan Das     16/05/2019      ES20-1268 (updateOutletKPITargets)  
8.0    Saurav Paul      28/06/2019      ES20-1738 
9.0    Saurav Paul      30/06/2019      ES20-1697 
10.0   Preyanka Ghosh   10/06/2019      ES20-715
11.0   Tomas Harte      17/07/2019      (Geography Automation)
12.0   Preyanka Ghosh    22/07/2019     ES20-2023 (Validate Local Segment 1 & 2 versus Global Outlet Segment)
13.0   Anuja Chattopadhyay 11/08/2019   ES20-3820 prospectApprovalProcess method added
14.0   Dipanjan D       20/08/2019      ES20-3382 convertProspectToOutlet
15.0   Preyanka Ghosh  28/08/2019       ES20-3385 Send notification to MDM, Sales Rep Manager and Account Owner
16.0   Srutadeba Chanda  04/11/2019     ES20-4300 updateExpectedVisit Update Expected Visit when Outlet Visit Prioritization changes
17.0   Monalisa Halder   11/11/2019     ES20-1206 SFDC Include Status on Owner/Operator & Distributor and build validation around the status field
18.0   Sagar Barman     12/11/2019      ES20-5361 upsertOutletExHistoric()
18.0   Sagar Barman     12/11/2019      ES20-5914 unlockProspectRecord()
19.0   Juned Khan       06/12/2019      ES20-6222 updated the method autoAddToTerritory and convertProspectToOutlet
20.0   Sandip Ghosh     09/12/2019      ES20-6402 updated the method updateHybridFlag and created the method getPrntToChldAccsMap
21.0   Juned khan       07/02/2020      EIS-71    updated the method    updateExpectedVisit to add country from Account level.  
22.0   Dipanjan Das     07/04/2020      ES20-7489 Account Trigger Code Optimization 
23.0   Monalisa Halder  04/08/2020      ES20-7369 Market Owner Update 
24.0   Monalisa Halder  03/12/2020      ES20-9080- method ->change in convertProspectToOutlet()
25.0   Monalisa Halder  01/02/2020      ES20-9212
26.0   Sayan Mullick	08/12/2021		CST-160 - method -> checkAndGenerateSharing(), validateAndReGenerateSharing()
27.0   Swaraj Samanta   04/07/2022		ES20-12863  Local segment dependency- Spain
28.0   Shivam/Rajarshi	05/02/2022	    ES20-14005,ES20-13960 
29.0   Sneha/Stuti		11/07/2023		142256 -  update currency account
30.0   Shivam/Doman	    19/09/2023		145439
**/

public with sharing class EDGE_AccountTriggerHelper {
    
    final static String SUBMITTED_STR = 'Submitted';
    final static String APPROVED_STR = 'Approved';
    final static String APPROVAL_IN_PROGRESS_STR = 'Approval In Progress';
    final static Map<string, Map<Id,Geography__c>> geoRecordTypeMap = EDGE_UtilityClass.getgeoRecordTypeMap();
    final static String prospectRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Prospect').getRecordTypeId(); 
    final static String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
    final static String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
    final static List<Market_Setting__c> marketSettingsList = [SELECT Id, Geography__c, Geography__r.Code__c, Prospect_Approver__c, Local_Segmentation_Validation__c,Local_Segmentation2_Validation__c, Auto_Add_to_Territory__c, Default_Outlet_Visit_Prioritisation__c,Default_Reserve_Visit_Prioritisation__c,Market_Account_Owner__c FROM Market_Setting__c ];
    //145439
    public static Id profileId = UserInfo.getProfileId();
    public static String profileName = [Select id,Name from Profile where Id=:profileId].Name;
    
    /**
     *@ Method  : updateAccountGeoCodes
     *@ This methods used to overwrite standard geocode fields with custom Geolocation field.
    **/  
    public static void updateAccountGeoCodes(Map<Id, SObject> newItems){
        for(SObject obj :newItems.values()){     
            Account accObj = (Account)obj;  
            if(accObj.Geolocation__Latitude__s != null && accObj.Geolocation__Longitude__s != null){
                accObj.BillingLatitude = accObj.Geolocation__Latitude__s;
                accObj.BillingLongitude = accObj.Geolocation__Longitude__s;
            }
        }
    }
    
    /**
      *@ Method  : updateOutletExecution
      *@ This methods used to calculate Outlet Execution Score.
    **/  
    public static void updateOutletExecutionScore(List<SObject> newItems, Map<Id, sObject> oldItemsMap){
        List<sObject> outletsToProcess = new List<sObject>();
        if(oldItemsMap != null){
            Map<Id, Account> mapOldOutlet = (Map<Id, Account>) oldItemsMap;
            for(SObject obj :newItems){ 
                Account accObj = (Account)obj;
                if(accObj.Minimum_Activation_Standards__c != mapOldOutlet.get(obj.Id).Minimum_Activation_Standards__c || accObj.Minimum_Product_Assortment__c != mapOldOutlet.get(obj.Id).Minimum_Product_Assortment__c){
                    outletsToProcess.add(obj);
                }               
            }
        }else{
            for(SObject obj :newItems){
                Account accObj = (Account)obj;
                if(accObj.Minimum_Activation_Standards__c != null || accObj.Minimum_Product_Assortment__c != null){
                    outletsToProcess.add(obj);
                }
            }
            //outletsToProcess.addAll(newItems);
        }
        
        if(outletsToProcess.size() > 0){            
            for(SObject obj :outletsToProcess){ 
                Account accObj = (Account)obj; 
                Geography__c geo = new Geography__c(); // Sagar Instantiated the geo variable
                if(accObj.recordTypeId == outletRecordTypeId && geoRecordTypeMap.size() > 0){
                    if(geoRecordTypeMap.size()>0){ //Fix null pointer issue where user dont have access to Geography Data
                        if(geoRecordTypeMap.get('Country').containsKey(accObj.Country__c)){
                            geo=geoRecordTypeMap.get('Country').get(accObj.Country__c);
                            if(geo.Minimum_Activation_Standards__c==0 && geo.Minimum_Product_Assortment__c==0 ){
                                geo=geoRecordTypeMap.get('Global').values();    
                            }
                        }
                        else{
                            if(null != geoRecordTypeMap.get('Global')){ // Sagar added this null check
                                geo=geoRecordTypeMap.get('Global').values();    
                            }                
                        }
                        accObj.Outlet_Execution_Score__c = (checkForNull(accObj.Minimum_Activation_Standards__c) * checkForNull(geo.Minimum_Activation_Standards__c) + checkForNull(accObj.Minimum_Product_Assortment__c) * checkForNull(geo.Minimum_Product_Assortment__c))/100;     
                    }                   
                }               
            }           
        }
    }
    
    //Return 0 if KPI value is null
    public static Decimal checkForNull(Decimal kpiValue){
        return EDGE_UtilityClass.checkForNull(kpiValue);
    }
    
    /**
      *@ Method : checkMandatoryFields
      *@  This is used to check mandatory fields
    **/  
    public static void checkMandatoryFields(List<SObject> newItems){
        //Variables
        Map<String,String> mandFeldApiLabelMap = new Map<String,String>();
        //Variables
        //Fetching field set
        List<Schema.FieldSetMember> allFields = 
            Schema.SObjectType.Account.fieldSets.getMap().get('Outlet_Prospect_Mandatory_Fields').getFields();
        if(!allFields.isEmpty()){
            for(Schema.FieldSetMember fieldSetMemberObj : allFields){
                mandFeldApiLabelMap.put(fieldSetMemberObj.getFieldPath(),fieldSetMemberObj.getLabel());
            }
            for(SObject sobj : newItems){
                Account accObj = (Account)sobj;
                if(accObj.recordTypeId == outletRecordTypeId
                   || accObj.recordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId())
                {
                    for (String fieldName : mandFeldApiLabelMap.keySet()){
                        if (accObj.get(fieldName) == null){ 
                            String errorMsgVal = Label.Mandatory_Error_Message;
                            errorMsgVal = errorMsgVal.replace('****',mandFeldApiLabelMap.get(fieldName));
                            accObj.addError(errorMsgVal);
                        }       
                    }
                }
            }
        }   
    }
    
    /**
      *@ Method : validateFieldSetting
      *@ This methods used to validate the account fields as per the market settings.
    **/
    public static void validateFieldsPerFS(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        String relatedObjectName = 'Account';
        Schema.DescribeSObjectResult sObjectDescReslt = Schema.SObjectType.Account;
        
        EDGE_ValidationWrapper edgeValWrapper = new EDGE_ValidationWrapper();
        edgeValWrapper.newItems = newItems;
        edgeValWrapper.oldItems = oldItems;
        edgeValWrapper.sObjectDescReslt = sObjectDescReslt;
        edgeValWrapper.relatedObjectName = relatedObjectName;
        //ES20-9212
        //EDGE_UtilityClass.validateFieldsPerMrktSetting(edgeValWrapper);
        EDGE_UtilityClass.validateFieldsPerFS(edgeValWrapper);
    }
    
    /**
      *@ Method  : flagOutletsForKPITargets
      *@ This methods used to flag Accounts for which SOS KPI Target updates 
        has to be made to the fields in outlet from KPIs Target Object.
   **/  
    public static void flagOutletsForKPITargets(List<SObject> newItems, Map<Id, SObject> oldItems){
        //The method is introduced for ES20-9194
        Map<Id, Account> mapOutlet;
        
        if(oldItems != null){
            mapOutlet = (Map<Id, Account>) oldItems;
        }
        for(SObject sObj : newItems){
            Account outlet = (Account)sObj;
            if(system.isBatch() && mapOutlet != null && mapOutlet.containskey(outlet.Id) && 
               (outlet.Primary_Sales_Territory__c != mapOutlet.get(outlet.Id).Primary_Sales_Territory__c ||
                outlet.Global_Segment__c != mapOutlet.get(outlet.Id).Global_Segment__c))
            {
                outlet.Pending_For_Outlet_KPI_Achievement__c=true;
            }
        }
    }
    
    /**
      *@ Method  : updateOutletKPITargets
      *@This methods used to update SOS KPI Target fields in outlet from KPIs Target Object.
    **/  
    public static void updateOutletKPITargets(List<SObject> newItems, Map<Id, SObject> oldItems){
        Set<Id> territoryIdSet = new Set<Id>();
        Set<Id> outletIdSet = new Set<Id>();
        List<KPIs_Target__c> kpiTargetList = new List<KPIs_Target__c>();
        Map<Id, Account> mapOutlet;
        String mdmStr = 'Master Data Manager';
        
        if(oldItems != null){
            mapOutlet = (Map<Id, Account>) oldItems;
        }
        
        for(SObject sObj : newItems){
            Account outlet = (Account)sObj;
            if(mapOutlet != null && mapOutlet.containskey(outlet.Id) && 
               (outlet.Primary_Sales_Territory__c != mapOutlet.get(outlet.Id).Primary_Sales_Territory__c ||
                outlet.Global_Segment__c != mapOutlet.get(outlet.Id).Global_Segment__c))
            {
                territoryIdSet.add(outlet.Primary_Sales_Territory__c);
                outletIdSet.add(outlet.Id);
            }
        }
        
        //Added by Amar ES20-9194  
        if(!system.isBatch() && territoryIdSet != null && Schema.sObjectType.KPIs_Target__c.isAccessible() && Schema.sObjectType.Outlet_KPI_Achievement__c.isAccessible() && territoryIdSet.size() > 0){
            //ES20-14005,ES20-13960
            kpiTargetList = [SELECT Id, Category__c, Segment__c,Sub_Segment__c, Target__c, Territory__c FROM KPIs_Target__c WHERE Territory__c IN :territoryIdSet];
            List<Outlet_KPI_Achievement__c> lstOutletKPIUpdate = [SELECT Id, Unique_Id__c, Category__c, KPI_Type__c, Target__c, Outlet__c, Target_Override_Not_Allowed__c FROM Outlet_KPI_Achievement__c WHERE Outlet__c IN :outletIdSet AND KPI_Type__c = 'SoS'];
            List<Outlet_KPI_Achievement__c> lstOutletKPI = EDGE_KPITargetOperations.populateOutletKPIs(kpiTargetList, newItems,lstOutletKPIUpdate);
            System.debug(LoggingLevel.Debug,'@@lstOutletKPI'+ lstOutletKPI.size());
            if(lstOutletKPI != null && lstOutletKPI.size()>0 && (Schema.sObjectType.Outlet_KPI_Achievement__c.isCreateable() && Schema.sObjectType.Outlet_KPI_Achievement__c.isUpdateable()) || profileName.contains(mdmStr)){//145439 - bypassing for MDM
                system.debug(LoggingLevel.Debug,'@@lstOutletKPI' +lstOutletKPI);
                Database.upsert(lstOutletKPI,Outlet_KPI_Achievement__c.Unique_Id__c,false);
                
            }
        }
    }
    
    /**
      *@ Method  : updateTemporaryDate (ES20-1738) 
      *@ This methods used to update Temporarily Closed Start and End date 
         to NULL when the status is changed to Active or Closed from Temporarily Closed
    **/
    public static void updateTemporaryDate(List<Account> newItems,Map<Id,SObject>oldMap){
        Map<Id,Account> oldAccMap;
        if(oldMap!= null){
            oldAccMap = (Map<Id,Account>)oldMap;
        }
        for(Account accObj : newItems){
            if(oldAccMap!= null && oldAccMap.containsKey(accObj.Id) 
               && oldAccMap.get(accObj.Id).Status__c != accObj.Status__c 
               && oldAccMap.get(accObj.Id).Status__c == 'Temporarily Closed' 
               && (accObj.Status__c == 'Active' || accObj.Status__c == 'Closed')){
                   accObj.End_Date__c = null;
                   accObj.Start_Date__c = null;
               }
        }
    }
    
    /**
      *@ Method  : updateHybridFlag (ES20-1697), ES20-6402 

    **/
    public static void updateHybridFlag(List<Account> newItems, Map<Id,SObject>oldMap, Boolean isUpdate){
        //Variables
        Map<Id,Account> oldAccMap;
        Set<Id> accParCheckedIdSet = new Set<Id>();
        Set<Id> accParUncheckedIdSet = new Set<Id>();
        List<Account> accountList = new List<Account>();
        List<Account> accUpdateList = new List<Account>();
        Map<Id, Account> accountCheckdMap;
        List<AggregateResult> accAggResultLst = new List<AggregateResult>();
        Map<String, AggregateResult> aggreAccMap = new Map<String, AggregateResult>();
        
        if(oldMap!= null){
            oldAccMap = (Map<Id,Account>)oldMap;
        }
        for(Account accObj : newItems){
            if((isUpdate && oldAccMap!= null && oldAccMap.containsKey(accObj.Id) 
                && oldAccMap.get(accObj.Id).Parent_Outlet__c != accObj.Parent_Outlet__c)
               || (!isUpdate && accObj.Parent_Outlet__c!= null))
            {
                if(isUpdate && String.isBlank(accObj.Parent_Outlet__c)){
                    //Create a set of parent id for those accounts for which parent outlet becomes null
                    accParUncheckedIdSet.add(oldAccMap.get(accObj.Id).Parent_Outlet__c);
                }else{
                    //Create a set of account id for those accounts where parent outlet exist
                    accParCheckedIdSet.add(accObj.Parent_Outlet__c);
                }
                accountList.add(accObj);
            }
        }
        //System.debug('accountList = '+accountList);
        if(!accountList.isEmpty()){
            //Create a map of outlet and count where this outlet is parent of other outlet
            if(!accParUncheckedIdSet.isEmpty() && Schema.sObjectType.Account.isAccessible()){
                accAggResultLst = [SELECT count(Id), Parent_Outlet__c parVal
                                   FROM Account 
                                   WHERE Parent_Outlet__c IN : accParUncheckedIdSet 
                                   AND Parent_Outlet__r.Parent_Outlet__c = null
                                   GROUP BY Parent_Outlet__c 
                                   HAVING count(Id) = 1];
                if(!accAggResultLst.isEmpty()){
                    for(AggregateResult aggResObj : accAggResultLst){
                        aggreAccMap.put((String)aggResObj.get('parVal'),aggResObj);
                    }
                }
            }
            //Create a Map of account
            if(!accParCheckedIdSet.isEmpty()){
                accountCheckdMap = new Map<Id, Account>([SELECT Id, Hybrid__c 
                                                         FROM Account 
                                                         WHERE Id IN :accParCheckedIdSet 
                                                         AND Hybrid__c = false 
                                                         AND Parent_Outlet__c = null]);
            }
            
            for(Account accObj : accountList){
                if(String.isBlank(accObj.Parent_Outlet__c) && oldAccMap!= null && oldAccMap.containsKey(accObj.Id)){
                    Id oldParentId = oldAccMap.get(accObj.Id).Parent_Outlet__c;
                    accObj.Hybrid__c = false;
                    if(aggreAccMap != null && aggreAccMap.containsKey(oldParentId)){
                        Account acc = new Account(Id = oldParentId);
                        acc.Hybrid__c = false;
                        accUpdateList.add(acc);
                    }
                }else if(String.isNotBlank(accObj.Parent_Outlet__c)){
                    accObj.Hybrid__c = true;
                    if(accountCheckdMap != null && accountCheckdMap.containsKey(accObj.Parent_Outlet__c)){
                        Account acc = new Account(Id = accObj.Parent_Outlet__c);
                        acc.Hybrid__c = true;
                        accUpdateList.add(acc);
                    }
                }
            }
        }
        
        //Update Parent Outlet List //Check Recurssion
        if(!accUpdateList.isEmpty() && Schema.sObjectType.Account.isUpdateable()){
            update accUpdateList;
        }
    }
    
    /**
      *@ Method  : updateReportingUnit (ES20-1697)
      *@ This method will update Reporting Unit of an outlet only for Australia
    **/
    public static void updateReportingUnit(List<Account> newItems, Map<Id,SObject> oldMap){
        //Variables
        List<Account> outletsToProcess = new List<Account>();
        Set<Id> ownerIdSet = new Set<Id>();
        List<Account> accList = new List<Account>();
        Map<String,Account> pkupOptnAccMap = new Map<String,Account>();
        Map<String,Pick_Up_Options__c> pkupOptnMap = new Map<String,Pick_Up_Options__c>();
        Map<Id, Account> mapDummyParent = new Map<Id, Account>(); //Added as part of bug ES20-4553
        Id ausGeoId = null;
        
        if(oldMap!= null){
            Map<Id, Account> mapOldOutlet = (Map<Id, Account>) oldMap;
            for(Account accObj :newItems){
                if(accObj.recordTypeId == outletRecordTypeId && geoRecordTypeMap.containsKey('Country') && geoRecordTypeMap.get('Country').containsKey(accObj.Country__c) && geoRecordTypeMap.get('Country').get(accObj.Country__c).Code__c == 'AU' && (accObj.Global_Channel__c != mapOldOutlet.get(accObj.Id).Global_Channel__c || accObj.Hybrid__c != mapOldOutlet.get(accObj.Id).Hybrid__c || accObj.ParentId != mapOldOutlet.get(accObj.Id).ParentId)){
                    outletsToProcess.add(accObj);
                    ownerIdSet.add(accObj.ParentId);
                }
            }
        }else{
            for(Account accObj : newItems){
                if(accObj.recordTypeId == outletRecordTypeId && geoRecordTypeMap.containsKey('Country') && geoRecordTypeMap.get('Country').containsKey(accObj.Country__c) && geoRecordTypeMap.get('Country').get(accObj.Country__c).Code__c == 'AU' && accObj.Global_Channel__c != null){
                    outletsToProcess.add(accObj);
                    ownerIdSet.add(accObj.ParentId);
                }               
            }
        }
        
        if(!ownerIdSet.isEmpty()){
            //Creating map of Responsible Group
            for(Account accPkUpObj : [SELECT Id, Name, Responsible_Group__r.Geography__c FROM Account WHERE Id IN :ownerIdSet])
            {
                String cmpKey = String.valueOf(accPkUpObj.Id) + String.valueOf(accPkUpObj.Responsible_Group__r.Geography__c);
                pkupOptnAccMap.put(cmpKey,accPkUpObj);
                
                //Below if Added as part of Bug ES20-4553
                if((accPkUpObj.Name).containsIgnoreCase(Label.DummyOwnerAccount)){
                    mapDummyParent.put(accPkUpObj.Id, accPkUpObj);
                }
            }
            //Creating map of Pickup Options
            for(Pick_Up_Options__c pkupObj : [SELECT Name,Geography__c FROM Pick_Up_Options__c WHERE Type__c = 'Reporting Unit'])
            {
                String name = String.valueOf(pkupObj.Name).substringBefore('[');
                String cmpKey = String.valueOf(pkupObj.Geography__c)+(name.trim());
                pkupOptnMap.put(cmpKey,pkupObj);
            }
        }
        
        if(!outletsToProcess.isEmpty()){
            for(Account accObj : outletsToProcess){
                if(pkupOptnAccMap!= null){
                    //Populating Reporting Unit
                    //Added mapDummyParent check for bug ES20-4553
                    if(((accObj.Global_Channel__c).containsIgnoreCase('On Trade') && accObj.Hybrid__c && String.isNotBlank(accObj.ParentId) && !mapDummyParent.containsKey(accObj.ParentId))
                       ||((accObj.Global_Channel__c).containsIgnoreCase('Off Trade') && String.isNotBlank(accObj.ParentId) && !mapDummyParent.containsKey(accObj.ParentId)))
                    {
                        String countryCmpKey = String.valueOf(accObj.ParentId)+String.valueOf(accObj.Country__c);
                        String clstrCmpKey = String.valueOf(accObj.ParentId)+String.valueOf(accObj.Cluster__c);
                        String hubCmpKey = String.valueOf(accObj.ParentId)+String.valueOf(accObj.Hub__c);
                        if(pkupOptnAccMap.containsKey(countryCmpKey)){
                            accObj.Reporting_Unit__c = pkupOptnAccMap.get(countryCmpKey).Responsible_Group__c;
                        }else if(pkupOptnAccMap.containsKey(clstrCmpKey)){
                            accObj.Reporting_Unit__c = pkupOptnAccMap.get(countryCmpKey).Responsible_Group__c;
                        }else if(pkupOptnAccMap.containsKey(hubCmpKey)){
                            accObj.Reporting_Unit__c = pkupOptnAccMap.get(countryCmpKey).Responsible_Group__c;
                        }
                    }else{
                        Boolean flag = false;
                        String channelval;
                        if((accObj.Global_Channel__c).containsIgnoreCase('On Trade')){
                            channelval = Label.Reporting_Unit_On_Trade;
                            flag = true;
                        }else if((accObj.Global_Channel__c).containsIgnoreCase('Off Trade')){
                            channelval = Label.Reporting_Unit_Off_Trade;
                            flag = true;
                        }
                        if(flag){
                            String countryCmpKey = String.valueOf(accObj.Country__c)+channelval;
                            String clstrCmpKey = String.valueOf(accObj.Cluster__c)+channelval;
                            String hubCmpKey = String.valueOf(accObj.Hub__c)+channelval;
                            if(pkupOptnMap!= null && pkupOptnMap.containsKey(countryCmpKey)){
                                accObj.Reporting_Unit__c = pkupOptnMap.get(countryCmpKey).Id;
                            }else if (pkupOptnMap!= null && pkupOptnMap.containsKey(clstrCmpKey)){
                                accObj.Reporting_Unit__c = pkupOptnMap.get(clstrCmpKey).Id;
                            }else if (pkupOptnMap!= null && pkupOptnMap.containsKey(hubCmpKey)){
                                accObj.Reporting_Unit__c = pkupOptnMap.get(hubCmpKey).Id;
                            }
                        }
                    }
                }
            }
        }
    }
    
    /**
      *@ Method  : changeContractAssignment (ES20-715)
      *@ This method will create, update or delete Outlet Contract
         based on operator field changed
    **/
    public static void changeContractAssignment(List<Account> newItems, Map<Id, SObject> oldItems){
        Map<Id, Account> mapOldAccount = new Map<Id,Account>();
        Map<Id,List<Id>> mapOperatorId = new Map<Id,List<Id>>();
        Set<Id> setOutletId = new Set<Id>();
        List<Outlet_Contract__c> listUpdateOutletContract = new List<Outlet_Contract__c>();
        List<Outlet_Contract__c> listInActiveOutletContract = new List<Outlet_Contract__c>();
        
        try{
            if(oldItems != null){
                mapOldAccount = (Map<Id,Account>)oldItems;
            }
            
            for(Account objAccount : newItems){
                if(oldItems != null && objAccount.RecordTypeId == outletRecordTypeId && mapOldAccount.containskey(objAccount.Id) && objAccount.Operator__c != null && mapOldAccount.get(objAccount.Id).Operator__c != null && mapOldAccount.get(objAccount.Id).Operator__c != objAccount.Operator__c){
                    setOutletId.add(objAccount.Id);
                    if(mapOperatorId.containsKey(objAccount.Operator__c)){
                        mapOperatorId.get(objAccount.Operator__c).add(objAccount.Id);
                    } else{
                        mapOperatorId.put(objAccount.Operator__c,new List<Id>{objAccount.Id});
                    }
                } else if(oldItems == null  && objAccount.RecordTypeId == outletRecordTypeId && objAccount.Operator__c != null){
                    setOutletId.add(objAccount.Id);
                    if(mapOperatorId.containsKey(objAccount.Operator__c)){
                        mapOperatorId.get(objAccount.Operator__c).add(objAccount.Id);
                    } else{
                        mapOperatorId.put(objAccount.Operator__c,new List<Id>{objAccount.Id});
                    }
                }
            }
            
            if(mapOperatorId != null && mapOperatorId.size()>0 && Schema.sObjectType.Outlet_Contract__c.isAccessible() && Schema.sObjectType.Contract.isAccessible()){
                List<Outlet_Contract__c> lstOutletContract = [SELECT Id, Outlet__c, Contract__c FROM Outlet_Contract__c WHERE Outlet__c IN :setOutletId AND Contract__r.RecordTypeId =:contractRecordTypeId AND Contract__r.Status = 'Active' AND Status__c ='Active'];
                List<Contract> lstContract = [SELECT Id, AccountId FROM Contract WHERE AccountId IN :mapOperatorId.keySet() AND StartDate <= Today AND Contract_End_Date__c >=Today AND RecordTypeId =:contractRecordTypeId AND Status = 'Active'];
                Map<Id,Boolean> mapMultipleContract = new Map<Id,Boolean>();
                if(lstContract != null && lstContract.size()>0){
                    for(Contract objContract : lstContract){
                        //If the key set in mapAccountContract is Owner/Operator than this block will execute
                        if(mapMultipleContract.containsKey(objContract.AccountId)){
                            mapMultipleContract.put(objContract.AccountId,true);
                        } else{
                            mapMultipleContract.put(objContract.AccountId, false);
                        }
                    }
                    
                    for(Contract objContract : lstContract){
                        if(mapOperatorId.containsKey(objContract.AccountId) && mapMultipleContract.containsKey(objContract.AccountId) && !mapMultipleContract.get(objContract.AccountId)){
                            List<Id> lstOutlet = mapOperatorId.get(objContract.AccountId);
                            for(Id outletId : lstOutlet){
                                Outlet_Contract__c outletContract = new Outlet_Contract__c();
                                outletContract.Contract__c = objContract.Id;
                                outletContract.Outlet__c = outletId;
                                outletContract.Status__c = 'Active';
                                listUpdateOutletContract.add(outletContract);
                            }
                            
                            if(lstOutletContract != null && lstOutletContract.size()>0){
                                for(Outlet_Contract__c outletContract : lstOutletContract){
                                    if(mapOperatorId.get(objContract.AccountId).contains(outletContract.Outlet__c)){
                                        outletContract.Status__c = 'Inactive';
                                        listUpdateOutletContract.add(outletContract);
                                    }
                                }
                            }
                        }
                    }
                } else {
                    listInActiveOutletContract = lstOutletContract;
                }            
                
                if(listUpdateOutletContract != null && listUpdateOutletContract.size()>0 && Schema.sObjectType.Outlet_Contract__c.isCreateable() && Schema.sObjectType.Outlet_Contract__c.isUpdateable()){
                    Database.upsert(listUpdateOutletContract);
                }
                
                if(listInActiveOutletContract != null && listInActiveOutletContract.size()>0 && Schema.sObjectType.Outlet_Contract__c.isDeletable()){
                    List<Outlet_Contract__c> lstInActiveOC = new List<Outlet_Contract__c>();
                    for(Outlet_Contract__c oldContract : listInActiveOutletContract){
                        oldContract.Status__c ='Inactive';
                        lstInActiveOC.add(oldContract);
                    }
                    Database.update(lstInActiveOC);
                }
            }
            
        } catch (Exception contractException){
            System.debug('Exception:::'+contractException.getLineNumber()+contractException.getMessage()+contractException.getCause());
            new EDGE_GenericException(contractException, newItems[0]);
        }
    }
    
    /**
      *@ Method : setGeographyTree (EDGE_Global_GeographiesAutomation)
      *@ This method will complete the Geographies Hierarchy of an Account when
         the Country ISO Code is provided.
    **/    
    public static void setGeographyTree(list<Account> recNew, list<Account>  recOld){
        List<String> countryList = new List<String>();
        Map<String, Geography__c> geographyMap = new Map<String, Geography__c>();
        
        for(Integer i=0;i<recNew.size();i++){
            if(Trigger.isInsert || (Trigger.isUpdate && recNew[i].Country_ISO_Code__c != recOld[i].Country_ISO_Code__c)){
                countryList.add(recNew[i].Country_ISO_Code__c);
            }
        }
        
        if(!countryList.isEmpty()){
            for(Geography__c geo: [SELECT Id, Code__c, name, parent_geography__c, parent_geography__r.parent_geography__c, parent_geography__r.parent_geography__r.parent_geography__c
                                   FROM Geography__c WHERE Code__c IN: countryList])
            {
                geographyMap.put(geo.Code__c, geo);
            }
        }
        
        if(!geographyMap.isEmpty()){
            for(Integer i=0;i<recNew.size();i++){
                if((Trigger.isInsert || ((Trigger.isUpdate && recNew[i].Country_ISO_Code__c != recOld[i].Country_ISO_Code__c) &&  
                    (recOld[i].Country__c == null || recOld[i].Cluster__c == null || recOld[i].Market__c == null || recOld[i].Hub__c == null))) && //included hierarchy check as a part of NCP-2869
                   	geographyMap.get(recNew[i].Country_ISO_Code__c) != null){
                       
                    Geography__c geo = geographyMap.get(recNew[i].Country_ISO_Code__c);
                    recNew[i].Hub__c = geo.Parent_Geography__r.Parent_Geography__c;
                    recNew[i].Market__c = geo.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c;
                    recNew[i].Cluster__c = geo.Parent_Geography__c;
                    recNew[i].Country__c = geo.id;
                    recNew[i].BillingCountryCode = geo.Code__c;
                }
            }
        }
    }
    
    /**
      *@ Method  : segmentDependencyValidation
         This methods used to update Local Segmentation 1, Local Segmentation2 
         based on Market settings 
    **/  
    public static void segmentDependencyValidation(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<Id, Account> mapNewAccount, mapOldAccount;
        List<Account> lstValidateAccount = new list<Account>();
        Set<Id> setCountryId = new Set<Id>();
        Map<String,Market_Setting__c> mapCountryCode = new Map<String,Market_Setting__c>();
        Map<String,String> mapSegmentDependency = new Map<String,String>();
        String independentLocalSegment2Values = '';//ES20-12863
        
        try{
            if(oldItems != null){
                mapOldAccount = (Map<Id, Account>) oldItems;
            }
            
            if(newItems != null && newItems.size()>0){
                mapNewAccount = (Map<Id, Account>) newItems;
                Map<String, List<Account>> mapValidAccount = new Map<String, List<Account>>();
                
                //Create map which contains only Outlet Record Type
                for(Account newAccount : mapNewAccount.values()){                    
                    if((newAccount.RecordTypeId == outletRecordTypeId || newAccount.RecordTypeId == prospectRecordTypeId) && 
                       ((oldItems == null && (newAccount.Local_Segment1__c != null || newAccount.Local_Segment2__c != null)) || 
                        (oldItems != null && 
                         (mapOldAccount.get(newAccount.Id).Global_Channel__c != newAccount.Global_Channel__c || 
                          mapOldAccount.get(newAccount.Id).Global_Sub_Channel__c != newAccount.Global_Sub_Channel__c ||
                          mapOldAccount.get(newAccount.Id).Global_Segment__c != newAccount.Global_Segment__c ||
                          mapOldAccount.get(newAccount.Id).Global_Sub_Segment__c != newAccount.Global_Sub_Segment__c ||
                          mapOldAccount.get(newAccount.Id).Local_Segment1__c != newAccount.Local_Segment1__c ||
                          mapOldAccount.get(newAccount.Id).Local_Segment2__c != newAccount.Local_Segment2__c
                         )
                        )
                       )
                      ){
                          if(mapValidAccount.containskey(newAccount.Country__c)){
                              mapValidAccount.get(newAccount.Country__c).add(newAccount);
                          } else {
                              mapValidAccount.put(newAccount.Country__c, new List<Account> {newAccount});
                          }                   
                      }
                }
                
                //Fetch the Market Settings data depend on Country Id
                if(mapValidAccount != null && mapValidAccount.size()>0 && Schema.sObjectType.Market_Setting__c.isAccessible()){                    
                    for(Market_Setting__c marketSetting : marketSettingsList){
                        if(mapValidAccount.containsKey(marketSetting.Geography__c) && (marketSetting.Local_Segmentation_Validation__c)){
                            lstValidateAccount.addAll(mapValidAccount.get(marketSetting.Geography__c));
                            mapCountryCode.put(marketSetting.Geography__r.Code__c, marketSetting);
                        }
                    }
                    mapValidAccount.clear();
                }
                
                if(lstValidateAccount != null && lstValidateAccount.size()>0 && Schema.sObjectType.Outlet_Segment_Dependency__mdt.isAccessible()){
                    //Retrieve all Outlet Segment record from Custom metadata
                    List<Outlet_Segment_Dependency__mdt> lstSegmentDependency = [SELECT Country_Code__c, Global_Channel__c, Global_Segment__c, 
                                                                                 Global_Sub_Channel__c,Global_Sub_Segment__c, Local_Segment_1__c, Local_Segment_2__c,Independent_Local_segment_2__c  
                                                                                 FROM Outlet_Segment_Dependency__mdt 
                                                                                 WHERE Country_Code__c IN :mapCountryCode.keySet()
                                                                                ];//ES20-12863 - new field added
                    Boolean isNotMatch;
                    
                    //Storing all combination within a Map - mapSegmentDependency
                    for(Outlet_Segment_Dependency__mdt outletSegment : lstSegmentDependency){
                        String key = (outletSegment.Country_Code__c+'-'+outletSegment.Global_Channel__c+'-'+outletSegment.Global_Sub_Channel__c+'-'+outletSegment.Global_Segment__c+'-'+outletSegment.Global_Sub_Segment__c).toLowerCase();
                       
                        //If Outlet_Segment_Dependency__mdt combination is part of Independent_Local_segment_2__c then we donot have to store local segment values    
                        if (outletSegment.Independent_Local_segment_2__c != true){
                            if(mapSegmentDependency.containskey(key)){
                                String value = mapSegmentDependency.get(key);
                                if(!value.containsIgnoreCase(outletSegment.Local_Segment_1__c)){
                                    value += ', '+(outletSegment.Local_Segment_1__c).toLowerCase();
                                }                            
                                mapSegmentDependency.put(key, value!=null ? value.toLowerCase() : ''); 
                            } else {
                                mapSegmentDependency.put(key, outletSegment.Local_Segment_1__c!=null ? (outletSegment.Local_Segment_1__c).toLowerCase() : '' );
                            }
                        }
                        
                        //Local Segment 2 Validation will be performed based on Market Setting
                        if(mapCountryCode.containsKey(outletSegment.Country_Code__c) && mapCountryCode.get(outletSegment.Country_Code__c).Local_Segmentation2_Validation__c){
                            //ES20-12863 - extract all Independent local segment2 values to separate List so that we can check it for every Local Segment1
                            if (outletSegment.Independent_Local_segment_2__c == true){
                                independentLocalSegment2Values += ', '+outletSegment.Local_Segment_2__c;
                            }else{
                               //If Independent local segment2 values are false then we will add with key 
                              key += '-'+(outletSegment.Local_Segment_1__c).toLowerCase();

                                if(mapSegmentDependency != null && mapSegmentDependency.containskey(key)){
                                	String value = mapSegmentDependency.get(key);
                               		if(outletSegment.Local_Segment_2__c!= null && !value.containsIgnoreCase(outletSegment.Local_Segment_2__c)){
                                    	value += ', '+outletSegment.Local_Segment_2__c;
                                	 }                                
                               		 	mapSegmentDependency.put(key, value!=null ? value.toLowerCase():'');                            
                            		} else {
                                		mapSegmentDependency.put(key, outletSegment.Local_Segment_2__c!=null ? (outletSegment.Local_Segment_2__c).toLowerCase() : '');                            
                            		}
                            }
                        }
                    }

                    //Query Account to retrieve the Name of local segment 1 and 2
                    for(Account account : [SELECT ID, Country__c, Country__r.Code__c, Global_Channel__c, Global_Sub_Channel__c, Global_Segment__c,
                                           Global_Sub_Segment__c, Local_Segment1__c, Local_Segment1__r.Name, Local_Segment2__c, Local_Segment2__r.Name FROM Account 
                                           WHERE ID IN :lstValidateAccount]){
                        isNotMatch = false;
                        String errorMessage;
                        String key = account.Country__r.Code__c+'-'+account.Global_Channel__c+'-'+account.Global_Sub_Channel__c+'-'+account.Global_Segment__c+'-'+account.Global_Sub_Segment__c;
                        key = key.toLowerCase();
                        
                        if(mapSegmentDependency.containskey(key)){  
                            String value = (mapSegmentDependency.get(key));//.toLowerCase();
                            String independentValue = independentLocalSegment2Values.toLowerCase();
                            
                            //If local segment combination is wrong then following block will trigger
                            if(String.isNotBlank(value) && account.Local_Segment1__c != null && !value.containsIgnoreCase(account.Local_Segment1__r.Name)){
                                errorMessage = Label.OutletSegmentationValidation;
                                errorMessage = errorMessage.replace('Global_Channel__c', account.Global_Channel__c);
                                errorMessage = errorMessage.replace('Global_Sub_Channel__c', account.Global_Sub_Channel__c);
                                errorMessage = errorMessage.replace('Global_Segment__c', account.Global_Segment__c);
                                errorMessage = errorMessage.replace('Global_Sub_Segment__c', account.Global_Sub_Segment__c);
                                errorMessage += ' '+ value;
                                mapNewAccount.get(account.Id).addError(errorMessage);
                            }else if(mapCountryCode.containsKey(account.Country__r.Code__c) && mapCountryCode.get(account.Country__r.Code__c).Local_Segmentation2_Validation__c){
                                
                                key += '-'+account.Local_Segment1__r.Name;
                                key = key.toLowerCase();
                                
                                if(mapSegmentDependency.containskey(key)){
                                    system.debug('key'+key);
                                    //If Local segment2 combination is wrong then foloowing block will trigger
                                    value = (mapSegmentDependency.get(key));//.toLowerCase();
                                    if(String.isNotBlank(value) && account.Local_Segment2__c != null &&  
                                       !(value.containsIgnoreCase(account.Local_Segment2__r.Name.toLowerCase()) || (independentValue.containsIgnoreCase(account.Local_Segment2__r.Name.toLowerCase())) )){
                                           //ES20-12863- checking filtered value and indenpendet value contains selected value or not
                                           
                                           errorMessage = Label.OutletSegmentationValidationAU;
                                           errorMessage = errorMessage.replace('Global_Channel__c', account.Global_Channel__c);
                                           errorMessage = errorMessage.replace('Global_Sub_Channel__c', account.Global_Sub_Channel__c);
                                           errorMessage = errorMessage.replace('Global_Segment__c', account.Global_Segment__c);
                                           errorMessage = errorMessage.replace('Global_Sub_Segment__c', account.Global_Sub_Segment__c);
                                           errorMessage = errorMessage.replace('Local_Segment1__c', account.Local_Segment1__r.Name);
                                           errorMessage += ' '+ value + independentLocalSegment2Values; //ES20-12863- add indepent values
                                           mapNewAccount.get(account.Id).addError(errorMessage);
                                       } else if(String.isBlank(value) && account.Local_Segment2__c != null  && !(independentValue.containsIgnoreCase(account.Local_Segment2__r.Name.toLowerCase()))){
                                           errorMessage = 'Do not select Local Segment 2 for combination '+ account.Global_Channel__c + ', '+account.Global_Sub_Channel__c+', '+account.Global_Segment__c+', '+account.Global_Sub_Segment__c+' and '+account.Local_Segment1__r.Name;
                                           mapNewAccount.get(account.Id).addError(errorMessage);                                        
                                       }
                                }else{
                                    //If Local segment2 combination is correct/wrong but Local segment1 value is blank provided market setting is on then foloowing block will trigger
                                    
                                    if ((account.Local_Segment2__c != null && independentValue != null) && !(independentValue.containsIgnoreCase(account.Local_Segment2__r.Name.toLowerCase()))){
                                        errorMessage = Label.OutletSegmentationValidation;
                                        errorMessage = errorMessage.replace('Global_Channel__c', account.Global_Channel__c);
                                        errorMessage = errorMessage.replace('Global_Sub_Channel__c', account.Global_Sub_Channel__c);
                                        errorMessage = errorMessage.replace('Global_Segment__c', account.Global_Segment__c);
                                        errorMessage = errorMessage.replace('Global_Sub_Segment__c', account.Global_Sub_Segment__c);
                                        errorMessage += ' '+ value;
                                        mapNewAccount.get(account.Id).addError(errorMessage);
                                    }
                                    
                                }//end of else                            
                            }//end of else if
                        }                    
                    }
                }
            }            
        } catch(Exception accountException){
            System.debug('accountException:::'+accountException);
            List<Account> lstAccount = mapNewAccount.values();
            new EDGE_GenericException(accountException, lstAccount[0]);
        }
    }
    
 
    
    /**
      *@ Method  : convertProspectToOutlet
      *@ Convert Prospect to Outlet
    **/  
    public static void convertProspectToOutlet(Map<Id, SObject> newItems, Map<Id, SObject> oldItems,List<AccountTeamMember> exisAccountMembersList){
        Map<Id, Account> mapNewAccount, mapOldAccount;
        Map<Id, Id> countryWithVisitPriMap = new Map<Id, Id>();
        Map<Id,Id> countryWithReservePriMap = new Map<Id ,Id>();
        Map<Id, Boolean> marketsettingTerritoryMap=new Map<Id, Boolean>();
        Map<Id,Id> countryMarketAccOwnerMap = new Map<Id ,Id>();
        List<Account> outletListtoUpdate = new List<Account>();
        //ES20-9080
        Set<Id> prospectIdSet = new Set<Id>();
        
        if(oldItems != null){
            mapOldAccount = (Map<Id, Account>) oldItems;
        }       
        if(newItems != null){
            mapNewAccount = (Map<Id, Account>) newItems;
        } 
        
        for(Id outletId : mapNewAccount.keySet()){
            if(mapOldAccount.get(outletId).recordTypeId == prospectRecordTypeId && mapOldAccount.get(outletId).Status__c != APPROVED_STR && mapNewAccount.get(outletId).Status__c == APPROVED_STR){
                outletListtoUpdate.add(mapNewAccount.get(outletId));
                prospectIdSet.add(outletId);
            }
        }
        //Store the account team member of the prospects in the map accountIdTeamMemberMap - //ES20-9080
        if(prospectIdSet.size() >0 && prospectIdSet != null && Schema.sObjectType.AccountTeamMember.isAccessible()){
            for(AccountTeamMember accTeamMem :[SELECT Id,AccountId,UserId,TeamMemberRole,AccountAccessLevel,OpportunityAccessLevel,ContactAccessLevel,
                                               Title,CaseAccessLevel FROM AccountTeamMember where AccountId IN :prospectIdSet]){
                                                   exisAccountMembersList.add(accTeamMem);
                                               }
            
        }
        
        
        if(outletListtoUpdate != null && outletListtoUpdate.size()> 0){
            
            for(Market_Setting__c marketSetting : marketSettingsList){
                countryWithVisitPriMap.put(marketSetting.Geography__c, marketSetting.Default_Outlet_Visit_Prioritisation__c);
                countryWithReservePriMap.put(marketSetting.Geography__c,marketSetting.Default_Reserve_Visit_Prioritisation__c);
                marketsettingTerritoryMap.put(marketSetting.Geography__c, marketSetting.Auto_Add_to_Territory__c);
                /*Change done as part of ES-7369*/
                if(marketSetting.Market_Account_Owner__c != null){
                    countryMarketAccOwnerMap.put(marketSetting.Geography__c,marketSetting.Market_Account_Owner__c);
                }
            }  
            
            
            for(Account outlet : outletListtoUpdate){
                outlet.recordTypeId = outletRecordTypeId;
                outlet.Status__c = 'Active';
                if(outlet.Global_Sub_Segment__c.contains('Reserve') && countryWithReservePriMap != null){
                    outlet.Outlet_Visit_Prioritisation_Grade__c = countryWithReservePriMap.get(outlet.Country__c);    
                }else{
                    outlet.Outlet_Visit_Prioritisation_Grade__c = countryWithVisitPriMap.get(outlet.Country__c); 
                }
                //outlet.Outlet_Visit_Prioritisation_Grade__c = countryWithVisitPriMap.get(outlet.Country__c); 
                //added new check point for user story ES20-6222
                if(outlet.Add_Outlet_to_Territory__c && marketsettingTerritoryMap.get(outlet.Country__c)){
                    outlet.Send_To_Trax__c =True;
                }
                /*Change done as part of ES-7369*/
                if(countryMarketAccOwnerMap!=null && countryMarketAccOwnerMap.containsKey(outlet.Country__c)){
                    outlet.OwnerId = countryMarketAccOwnerMap.get(outlet.Country__c); 
                }
                
                
            }
        }   
    }
    
    
    /**
     *@ Method  : autoAddToTerritory
     *@ To automatically add outlet to sales rep's Territory.
    **/  
    public static void autoAddToTerritory(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<Id, Boolean> countryWithAutoAddToTerr = new Map<Id, Boolean>();
        Map<Id,String> mapAccountTerritory = new Map<Id,String>();
        Map<Id,String> mapTerritoryUser = new Map<Id,String>();
        Set<Id> salesRepIdSet = new Set<Id>();
        Map<Id,Id> territoryUserMap = new Map<Id,Id>();
        List<Account> prospectToOutletList = new List<Account>();
        List<Account>  updateProspectList = new List<Account>();
        List<Outlet_Territory__c> outletTerrList = new List<Outlet_Territory__c>();
        
        Map<Id, Account> mapNewAccount, mapOldAccount;
        if(oldItems != null){
            mapOldAccount = (Map<Id, Account>) oldItems;
        }       
        if(newItems != null){
            mapNewAccount = (Map<Id, Account>) newItems;
        }   
        
        for(Id accountId : mapNewAccount.keySet()){
            //added new check point for user story ES20-6222
            if(mapOldAccount.get(accountId).recordTypeId == prospectRecordTypeId && mapNewAccount.get(accountId).recordTypeId == outletRecordTypeId && mapNewAccount.get(accountId).Add_Outlet_to_Territory__c){
                prospectToOutletList.add(mapNewAccount.get(accountId));
                salesRepIdSet.add(mapNewAccount.get(accountId).CreatedById);
            }
        }
        
        if(prospectToOutletList.size() > 0){
            for(Market_Setting__c marketSetting : marketSettingsList){
                countryWithAutoAddToTerr.put(marketSetting.Geography__c, marketSetting.Auto_Add_to_Territory__c);
            }
            if(Schema.sObjectType.Territory_Member__c.isAccessible()){
                for(Territory_Member__c terrMem: [SELECT Id,Name,User__c,Territory__c, Territory__r.Name FROM Territory_Member__c WHERE User__c IN : salesRepIdSet AND Type__c = 'Primary' AND Territory__r.Territory_Type__c='Sales' AND (End_Date__c = null OR End_Date__c > Today)]){
                    territoryUserMap.put(terrMem.user__c,terrMem.Territory__c);
                    mapTerritoryUser.put(terrMem.user__c,terrMem.Territory__r.Name);
                }
            }
            
            
            for(Account outlet : prospectToOutletList){
                if(territoryUserMap.size() > 0 && countryWithAutoAddToTerr.get(outlet.Country__c)){
                    Outlet_Territory__c outletTerr = new Outlet_Territory__c();
                    outletTerr.Outlet__c = outlet.Id;
                    outletTerr.Territory__c = territoryUserMap.get(outlet.createdbyId);
                    outletTerr.Active__c = 'Waiting Activation';
                    outletTerrList.add(outletTerr);
                    mapAccountTerritory.put(outlet.Id, mapTerritoryUser.get(outlet.createdbyId));
                }    
            }
            if(Schema.sObjectType.Outlet_Territory__c.isCreateable()){
                if(outletTerrList != null && outletTerrList.size()>0){
                    insert outletTerrList;
                    //Send Notification
                    sendProspectNotification(prospectToOutletList, mapAccountTerritory);
                }
            }           
        }
        
    }
    
    /**
      *@ Method  : sendProspectNotification

    **/
    public static void sendProspectNotification(List<Account> lstProspectOutlet, Map<Id,String> mapAccountTerritory){
        Set<String> setQueueName = new Set<String>();
        Map<string, List<string>> mapActiveQueueMember = new Map<string, List<string>>();
        if(lstProspectOutlet != null && lstProspectOutlet.size()>0){
            List<Account> lstAccountDetails = [SELECT Id, Name, Country__c, Country__r.Code__c, Country__r.MDM_Queue__c, CreatedById, 
                                               CreatedBy.Email, CreatedBy.managerId, CreatedBy.manager.Email , Operator__c, Operator__r.Name, Primary_Distributor__c,
                                               Primary_Distributor__r.Name, Global_Channel__c, Global_Sub_Channel__c, Global_Segment__c,
                                               Global_Sub_Segment__c, Local_Segment1__c, Local_Segment1__r.Name,
                                               Local_Segment2__c, Local_Segment2__r.Name
                                               FROM Account 
                                               WHERE ID IN :lstProspectOutlet];
            
            for(Account outlet : lstAccountDetails){
                setQueueName.add(outlet.Country__r.MDM_Queue__c);
            }
            
            if(setQueueName != null && setQueueName.size()>0 && Schema.sObjectType.GroupMember.isAccessible()){
                List<GroupMember> lstGroupMember = [SELECT Group.Name, UserOrGroupId, GroupId FROM GroupMember WHERE group.name IN :setQueueName and group.type='Queue'];
                mapActiveQueueMember = getActiveQueueMember(lstGroupMember);
            }
            
            List<string> toAddress = new List<string>();
            List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
            for(Account outletAccount : lstAccountDetails){
                if(mapActiveQueueMember.containsKey(outletAccount.Country__r.MDM_Queue__c)){
                    List<String> allMDMEmail = mapActiveQueueMember.get(outletAccount.Country__r.MDM_Queue__c);
                    toAddress.addAll(allMDMEmail);                    
                }
                toAddress.add(outletAccount.CreatedBy.Email);
                if(outletAccount.CreatedBy.managerId != null){
                    toAddress.add(outletAccount.CreatedBy.manager.Email);
                }
                
                String territoryName = mapAccountTerritory.get(outletAccount.Id);
                String emailBody = Label.ProspectConversion;
                emailBody = emailBody.replace('outletAccount.Name', outletAccount.Name);
                emailBody = emailBody.replace('territoryName',territoryName);
                String fieldValue = outletAccount.Operator__c != null ? outletAccount.Operator__r.Name : '';
                emailBody = emailBody.replace('{!Owner__c}',fieldValue);
                fieldValue = outletAccount.Primary_Distributor__c != null ? outletAccount.Primary_Distributor__r.Name : '';
                emailBody = emailBody.replace('{!Primary_Distributor__c}',fieldValue);
                emailBody = emailBody.replace('{!Global_Channel__c}',outletAccount.Global_Channel__c);
                emailBody = emailBody.replace('{!Global_Sub_Channel__c}',outletAccount.Global_Sub_Channel__c);
                emailBody = emailBody.replace('{!Global_Segment__c}',outletAccount.Global_Segment__c);
                emailBody = emailBody.replace('{!Global_Sub_Segment__c}',outletAccount.Global_Sub_Segment__c);
                fieldValue = outletAccount.Local_Segment1__c != null ? outletAccount.Local_Segment1__r.Name : '';
                emailBody = emailBody.replace('{!Local_Segment1__c}',fieldValue);
                fieldValue = outletAccount.Local_Segment2__c != null ? outletAccount.Local_Segment2__r.Name : '';
                emailBody = emailBody.replace('{!Local_Segment2__c}',fieldValue);
                fieldValue = URL.getSalesforceBaseUrl().toExternalForm()+'/'+outletAccount.Id;
                emailBody = emailBody.replace('{!outletAccount.Id}',fieldValue);
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setSubject(Label.ProspectConversionSubject);
                mail.setToAddresses(toAddress);
                mail.setTargetObjectId(outletAccount.CreatedById);
                mail.setSaveAsActivity(false);
                mail.setHtmlBody(emailBody);
                allmsg.add(mail);
            }
            Messaging.sendEmail(allmsg,false);
        }
    }
    
    /**
      *@ Method  : getActiveQueueMember

    **/
    public static Map<string, List<string>> getActiveQueueMember(List<GroupMember> lstGroupMember){
        Map<string, List<string>> mapActiveQueueMember = new Map<string, List<string>>();
        Map<String,List<String>> mapGroupWithMember = new Map<String,List<String>>();
        Map<Id,User> mapActiveUser;
        Set<Id> setUserId = new Set<Id>();
        
        if(lstGroupMember != null && lstGroupMember.size()>0){
            for(GroupMember groupMember : lstGroupMember){
                setUserId.add(groupMember.UserOrGroupId);
                if(mapGroupWithMember.containsKey(groupMember.Group.Name)){
                    mapGroupWithMember.get(groupMember.Group.Name).add(groupMember.UserOrGroupId);
                } else {
                    mapGroupWithMember.put(groupMember.Group.Name, new List<String> {groupMember.UserOrGroupId });
                }
            }
            
            if(setUserId != null && setUserId.size()>0){
                mapActiveUser = new Map<Id,User>([SELECT Id, isActive, Email FROM User WHERE Id IN :setUserId AND isActive = True]);
            }            
            
            //Iterate over mapSalesmembers to get only active member list
            if(mapGroupWithMember.size()>0){
                for(string queueName : mapGroupWithMember.keySet()){
                    List<String> approverList =  mapGroupWithMember.get(queueName);
                    List<String> activeApproverist = new List<String>();
                    if(mapActiveUser != null && mapActiveUser.size()>0){
                        for(String userId : approverList){
                            if(mapActiveUser.containsKey(userId)){
                                activeApproverist.add(mapActiveUser.get(userId).Email);
                            }
                        }
                        mapActiveQueueMember.put(queueName, activeApproverist);
                    }
                }
            }
        }
        return mapActiveQueueMember;
    }
    
    /**
      *@ Method  : validatePhoneNumber
      *@ Validate Phone number depending upon regex set on metadata
   **/
    public static void validatePhoneNumber(List<sObject> newItems, Map<Id,SObject> oldItems){
        Map<Id,Account> mapOldItems;
        List<SObject> lstNewData = new List<SObject>();
        Set<String> setPhonePrefix = new Set<String>();
        List<String> lstFieldName = new List<String>{'MobilePrefix__c','Mobile__c','PhonePrefix__c','Phone__c'};
            List<String> lstFieldToUpdate = new List<String>{'Mobile_Number__c','Phone'};
                
                if(oldItems != null){
                    mapOldItems = (Map<Id,Account>) oldItems;
                }
        
        if(newItems != null && newItems.size()>0){
            for(sObject newObject : newItems){
                Account newAccount = (Account)newObject;
                
                if(((newAccount.MobilePrefix__c != null && newAccount.Mobile__c != null) || (newAccount.PhonePrefix__c != null && newAccount.Phone__c != null)) && 
                   (oldItems == null || 
                    (oldItems != null && mapOldItems.containsKey(newAccount.Id) && 
                     (newAccount.MobilePrefix__c != mapOldItems.get(newAccount.Id).MobilePrefix__c || newAccount.Mobile__c != mapOldItems.get(newAccount.Id).Mobile__c || 
                      newAccount.PhonePrefix__c != mapOldItems.get(newAccount.Id).PhonePrefix__c || newAccount.Phone__c != mapOldItems.get(newAccount.Id).Phone__c)
                    ))
                  ){
                      lstNewData.add(newObject);
                      if(String.isNotBlank(newAccount.MobilePrefix__c)){
                          setPhonePrefix.add(newAccount.MobilePrefix__c);
                      }
                      
                      if(String.isNotBlank(newAccount.PhonePrefix__c)){
                          setPhonePrefix.add(newAccount.PhonePrefix__c);
                      }
                  }
            }
            
            if(lstNewData != null && lstNewData.size()>0){
                EDGE_PhoneFormatting.validatePhoneNumber(lstNewData, setPhonePrefix, lstFieldName, lstFieldToUpdate);
                
            }
        }
    }
    
    /**
      *@ Method  : validateOwner
      *@ Restrict Sales Rep of AU Market not to change Owner of Outlet
    **/
    public static void validateOwner(List<sObject> newItems, Map<Id,SObject> oldItems){
        Map<Id,Account> mapOldItems;    
        if(oldItems != null){
            mapOldItems = (Map<Id,Account>) oldItems;
        }
        String userid= userinfo.getUserId();
        String userProfileType = [select profile.name from User  where Id=:userid limit 1].profile.name;
        if(newItems != null && newItems.size()>0){
            for(sObject newObject : newItems){
                Account newAccount = (Account)newObject;
                if((newAccount.ParentId != null && newAccount.ParentId != mapOldItems.get(newAccount.Id).ParentId) && (newAccount.Country__r.Code__c =='AU') 
                   && (userProfileType == 'Sales Representative'))
                {
                    newAccount.addError('u cant change'); 
                }
            }
        }
    }
    
    /**
      *@ Method  : updateExpectedVisit
      *@ Validate Expected Visit when Outlet Visit Prioritization Chnages
   **/
    public static void updateExpectedVisit(List<sObject> newItems, Map<Id,SObject> oldItems){
        List<Account> newAccountlist= (list<Account>) newItems;
        Map<Id,Account> oldAccountMap= (Map<Id,Account>) oldItems;
        List<Account> outletsToProcess = new List<Account>();
        set<Id> countryset= new set<Id>();
        set<Id> outletVistPriorSet= new set<Id>();
        Map<Id,Decimal> pickupOptionMap= new Map<Id,Decimal>();
        Map<Id,Decimal> marketCycleMap= new Map<Id,Decimal>();
        
        if(oldAccountMap != null){
            for(Account accObj : newAccountlist){
                if(OldAccountMap.get(accObj.id).Outlet_Visit_Prioritisation_Grade__c != accObj.Outlet_Visit_Prioritisation_Grade__c){
                    outletsToProcess.add(accObj);
                    countryset.add(accObj.Country__c);
                    outletVistPriorSet.add(accObj.Outlet_Visit_Prioritisation_Grade__c);
                }
            }
        }else{
            for(Account accObj : newAccountlist){
                if( accObj.RecordTypeId == outletRecordTypeId && accObj.Outlet_Visit_Prioritisation_Grade__c != null){
                    outletsToProcess.add(accObj);
                    countryset.add(accObj.Country__c);
                    outletVistPriorSet.add(accObj.Outlet_Visit_Prioritisation_Grade__c);
                }
            }
        }
        
        if(outletsToProcess.size() > 0){
            for(Pick_Up_Options__c  pickup:[select id ,Geography__c ,Days_between_visit__c from Pick_Up_Options__c where id in : outletVistPriorSet]){
                pickupOptionMap.put(pickup.id,pickup.Days_between_visit__c );
            }
           for(Market_Cycle__c  cycle : [SELECT Id,Start_Date__c,Number_of_Week__c,Number_Of_Working_Day__c,End_Date__c,Geography__c from Market_Cycle__c WHERE Geography__c in :Countryset AND Active__c= True ]){
           
            	marketCycleMap.put(cycle.Geography__c, cycle.Number_Of_Working_Day__c);
            }
            
            for(Account acc: outletsToProcess){
                Account accObj = (Account)acc;  
                if(pickupOptionMap.get(accObj.Outlet_Visit_Prioritisation_Grade__c) != null && marketCycleMap.get(accObj.Country__c) != null){
                    accObj.Expected_Visits__c= Integer.valueOf(marketCycleMap.get(accObj.Country__c)/pickupOptionMap.get(accObj.Outlet_Visit_Prioritisation_Grade__c));
                }
            }           
        }
        
    }
    
    /**
      *@ Method  : updateStatusMarkedForDeletion
      *@ User Story : ES20-1206 -When Status is changed to Marked for Deletion and Date Marked for Deletion is updated with the system date.
    **/
    public static void updateStatusMarkedForDeletion(List<Account> newItems, Map<Id,SObject> oldItems){
        Map<Id,Account> mapOldItems;
        Set<Id> setOwnerOperatorId = new Set<Id>();
        Set<Id> setDistributorId = new Set<Id>(); 
        String ownerRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
        String distributorRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Distributor/Wholesaler').getRecordTypeId();
        Map<Id,Boolean> accountDelMap = new Map<id, boolean>();
        
        if(oldItems != null){
            mapOldItems = (Map<Id,Account>) oldItems;
        }
        
        for(Account objAccount : newItems){
            if(objAccount.Status__c != mapOldItems.get(objAccount.Id).Status__c && objAccount.Status__c =='Marked for Deletion' ){
                if(objAccount.RecordTypeId == ownerRecordTypeId){
                    setOwnerOperatorId.add(objAccount.Id);
                }
                else if(objAccount.RecordTypeId == distributorRecordTypeId){
                    setDistributorId.add(objAccount.Id);
                }
            }
        }
        
        //Call markOwnerOperatorForDeletion Method
        if(setOwnerOperatorId.size()>0){
            if(markOwnerOperatorForDeletion(setOwnerOperatorId, newItems).size()>0){
                accountDelMap=markOwnerOperatorForDeletion(setOwnerOperatorId, newItems);
            }
        }
        
        //Call markOwnerOperatorForDeletion Method
        if(setDistributorId.size()>0){
            if(markDistributorForDeletion(setDistributorId, newItems).size()>0){
                accountDelMap.putall(markDistributorForDeletion(setDistributorId, newItems));
            }    
        } 
        
        for(Account accObj: newItems) {
            if(accountDelMap.containsKey(accObj.Id)){
                accObj.addError(label.EDGE_Status_MarkedForDeletion);
            }else if (setOwnerOperatorId.contains(accObj.id)|| setDistributorId.contains(accObj.id)){
                accObj.Date_marked_for_Deletion__c = Date.today();
                
            }
        }   
    }
    
    /**
      *@ Method  : markOwnerOperatorForDeletion
      *@ Check Owner/Operator exists on Active/Temporarily Closed Outlets/Prospects, status cannot be changed to Mark for Deletion
    **/
    public static Map<id,boolean> markOwnerOperatorForDeletion(Set<Id> setOwnerOperatorId, List<Account> newItems){
        Map<Id, Boolean> mapOwnerOperatorCheck = new Map<Id, Boolean>();
        for(Account accountRec : [Select Id, ParentId, Operator__c from Account 
                                  where (ParentId IN: setOwnerOperatorId 
                                         OR Operator__c IN: setOwnerOperatorId )
                                  AND (RecordType.DeveloperName = 'Prospect' OR RecordType.DeveloperName = 'Outlet')
                                  AND Status__c  IN ('Active','Temporarily Closed')])
        {   
            mapOwnerOperatorCheck.put(accountRec.ParentId, True);
            mapOwnerOperatorCheck.put(accountRec.Operator__c, True);
        }
        
        return mapOwnerOperatorCheck;
    }
    
    //Check Distributor exists on Active/Temporarily Closed Outlets-Supplier Outlets, status cannot be changed to Mark for Deletion
    public static Map<Id,boolean> markDistributorForDeletion(Set<Id> setDistributorId, List<Account> newItems){
        Map<Id, Boolean> mapDistributorCheck = new Map<Id, Boolean>();
        for(Supplier_Outlet__c supplierOutlet : [Select Id, Distributor_Wholesaler__c, Outlet__c, Outlet__r.Status__c from Supplier_Outlet__c 
                                                 where Distributor_Wholesaler__c IN: setDistributorId
                                                 AND Outlet__r.Status__c  IN ('Active','Temporarily Closed')])
        {
            mapDistributorCheck.put(supplierOutlet.Distributor_Wholesaler__c, True);
        }
        
        return mapDistributorCheck;
    }
    
    //the below method will be used to unlock the prospect record from approval in progress
    public static void unlockProspectRecord(Map<Id,SObject> newItems,Map<Id, SObject> oldItems){
        Map<Id, Account> mapNewAccs, mapOldAccs; 
        Set<Id> accountSetId = new Set<Id>();
        if(oldItems != null){
            mapOldAccs = (Map<Id, Account>) oldItems;
        }
        if(newItems != null){
            mapNewAccs = (Map<Id, Account>) newItems;    
        } 
        for(Id accId : mapNewAccs.keySet()){
            if((oldItems != null) && (mapOldAccs.get(accId).Status__c == SUBMITTED_STR) && (mapNewAccs.get(accId).Status__c == APPROVAL_IN_PROGRESS_STR) && mapNewAccs.get(accId).recordtypeid == prospectRecordTypeId ){
                accountSetId.add(accId);        
            }
        } 
        //call record Unlocker method
        if(accountSetId!= null && accountSetId.size() > 0){
            EDGE_RecordUnlocker.unlockProspectRecord(accountSetId);    
        }
    }
    
    /**
      *@ Method  : upsertOutletExHistoric
      *@ insert/update Outlet_Execution_Historic__c if the “last updated by TRAX “ is current date for a particular month (ES20-5361)
    **/  
   /* public static void upsertOutletExHistoric(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
        Map<Id, Account> mapNewAccount, mapOldAccount;
        Map<Id, Outlet_Execution_Historic__c> outletWithExHisMap = new Map<Id, Outlet_Execution_Historic__c>();
        Set<Id> outletSetId = new Set<Id>();
        List<Outlet_Execution_Historic__c> outletExHisListtoUpsert = new List<Outlet_Execution_Historic__c>();
        String outletExHOutletKPIRecordType = Outlet_Execution_Historic__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet KPI').getRecordTypeId();
        Integer currentmonth=system.today().month();
        Integer currentYear=system.today().year();
        
        try{
            if(oldItems != null){
                mapOldAccount = (Map<Id, Account>) oldItems;
            }       
            if(newItems != null){
                mapNewAccount = (Map<Id, Account>) newItems;
            }
            
            for(Id outletId : mapNewAccount.keySet()){
                if(mapOldAccount != null){
                    if(mapNewAccount.get(outletId).Last_Update_TRAX__c != null && outletRecordTypeId == mapNewAccount.get(outletId).recordTypeId && mapOldAccount.get(outletId).Last_Update_TRAX__c != mapNewAccount.get(outletId).Last_Update_TRAX__c && mapNewAccount.get(outletId).Status__c=='Active'){
                        outletSetId.add(mapNewAccount.get(outletId).Id);
                    }
                }else if(mapNewAccount.get(outletId).Last_Update_TRAX__c != null && outletRecordTypeId == mapNewAccount.get(outletId).recordTypeId && mapNewAccount.get(outletId).Status__c=='Active'){
                    outletSetId.add(mapNewAccount.get(outletId).Id);
                }
            }
            if(outletSetId != null && outletSetId.size()> 0){
                for(Outlet_Execution_Historic__c outletEHis : [SELECT Id,Minimum_Activation_Standards__c,Minimum_Product_Assortment__c,New_Product_Distribution__c,
                                                               Outlet_Execution_Score__c,Date_of_Execution__c,Outlet__c,Distribution__c,RecordTypeId 
                                                               FROM Outlet_Execution_Historic__c where Outlet__c IN :outletSetId AND RecordType.Name ='Outlet KPI' 
                                                               and CALENDAR_MONTH(Date_of_Execution__c)=:currentmonth and CALENDAR_YEAR(Date_of_Execution__c)=:currentYear])
                {
                    outletWithExHisMap.put(outletEHis.Outlet__c,outletEHis);
                }
            }
            for(Account outlet : mapNewAccount.values() ){
                if(outlet.Last_Update_TRAX__c != null){
                    Integer traxMonth = outlet.Last_Update_TRAX__c.month();
                    Integer traxYear = outlet.Last_Update_TRAX__c.year();
                    if(outletWithExHisMap.get(outlet.id)!=null && traxMonth == outletWithExHisMap.get(outlet.id).Date_of_Execution__c.month() && traxYear == outletWithExHisMap.get(outlet.id).Date_of_Execution__c.year()){
                        Outlet_Execution_Historic__c  outletExHist = outletWithExHisMap.get(outlet.id);
                        outletExHist.Minimum_Activation_Standards__c = outlet.Minimum_Activation_Standards__c;
                        outletExHist.Minimum_Product_Assortment__c = outlet.Minimum_Product_Assortment__c;
                        outletExHist.New_Product_Distribution__c = outlet.New_Product_Distribution__c;
                        outletExHist.Outlet_Execution_Score__c = outlet.Outlet_Execution_Score__c;
                        outletExHist.Distribution__c = outlet.Distribution__c;
                        outletExHist.Date_of_Execution__c = date.newInstance(traxYear, traxMonth, 1);
                        outletExHisListtoUpsert.add(outletExHist);
                    }
                    else{
                        Outlet_Execution_Historic__c newOutletExHis = new Outlet_Execution_Historic__c();
                        newOutletExHis.RecordTypeId = outletExHOutletKPIRecordType;
                        newOutletExHis.Name = outlet.Name+' - '+traxMonth+'/'+traxYear;
                        newOutletExHis.Outlet__c = outlet.Id;
                        newOutletExHis.Minimum_Activation_Standards__c = outlet.Minimum_Activation_Standards__c;
                        newOutletExHis.Minimum_Product_Assortment__c = outlet.Minimum_Product_Assortment__c;
                        newOutletExHis.New_Product_Distribution__c = outlet.New_Product_Distribution__c;
                        newOutletExHis.Outlet_Execution_Score__c = outlet.Outlet_Execution_Score__c;
                        newOutletExHis.Distribution__c = outlet.Distribution__c;
                        newOutletExHis.Date_of_Execution__c = date.newInstance(traxYear, traxMonth, 1);
                        outletExHisListtoUpsert.add(newOutletExHis);
                    }
                }
            }
            if(outletExHisListtoUpsert != null && outletExHisListtoUpsert.size()>0 && Schema.sObjectType.Outlet_Execution_Historic__c.isCreateable() && Schema.sObjectType.Outlet_Execution_Historic__c.isUpdateable()){
                Database.upsert(outletExHisListtoUpsert);
            } 
        }catch (Exception outletExHiexception){
            System.debug('Exception:::'+outletExHiexception.getLineNumber()+outletExHiexception.getMessage()+outletExHiexception.getCause());
            new EDGE_GenericException(outletExHiexception, newItems.values()[0]);
        }
    }*/
    
    public static void upsertOutletExHistoric(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<Id, Account> mapNewAccount, mapOldAccount;
        List<Outlet_Execution_Historic__c> outletExHisListtoUpsert = new List<Outlet_Execution_Historic__c>();
        String outletExHOutletKPIRecordType = Outlet_Execution_Historic__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet KPI').getRecordTypeId();
        if(oldItems != null){
            mapOldAccount = (Map<Id, Account>) oldItems;
        }       
        if(newItems != null){
            mapNewAccount = (Map<Id, Account>) newItems;
        }
        
        for(Id outletId : mapNewAccount.keySet()){
            
            if(mapNewAccount.get(outletId).Last_Update_TRAX__c != null && outletRecordTypeId == mapNewAccount.get(outletId).recordTypeId && 
               mapNewAccount.get(outletId).Status__c=='Active' && ((mapOldAccount != null && 
                                                                    mapOldAccount.get(outletId).Last_Update_TRAX__c !=mapNewAccount.get(outletId).Last_Update_TRAX__c ) || mapOldAccount==null))
            {
                Account Outlet=mapNewAccount.get(outletId);
                Integer traxMonth = outlet.Last_Update_TRAX__c.month();
                Integer traxYear = outlet.Last_Update_TRAX__c.year();
                string OutletName = Outlet.Name;
                
                Outlet_Execution_Historic__c  outletExHist = new Outlet_Execution_Historic__c();
                outletExHist.Outlet__c = outlet.Id;
                If(OutletName.length()>70){
                    OutletName = OutletName.SubString(0,70);
                }   
                
                outletExHist.Name = OutletName + ' - ' + traxMonth + '/' + traxYear;
                outletExHist.RecordTypeId = outletExHOutletKPIRecordType;
                outletExHist.Unique_Id__c = string.valueOf(traxMonth) + string.valueOf(traxYear) + outletId;
                outletExHist.Minimum_Activation_Standards__c = outlet.Minimum_Activation_Standards__c;
                outletExHist.Minimum_Product_Assortment__c = outlet.Minimum_Product_Assortment__c;
                outletExHist.New_Product_Distribution__c = outlet.New_Product_Distribution__c;
                outletExHist.Outlet_Execution_Score__c = outlet.Outlet_Execution_Score__c;
                outletExHist.Distribution__c = outlet.Distribution__c;
                outletExHist.Date_of_Execution__c = date.newInstance(traxYear, traxMonth, 1);
                outletExHisListtoUpsert.add(outletExHist);
            }
        }
        
        if(outletExHisListtoUpsert.size()>0 && !outletExHisListtoUpsert.isEmpty() && Schema.sObjectType.Outlet_Execution_Historic__c.isCreateable() && Schema.sObjectType.Outlet_Execution_Historic__c.isUpdateable()){
            upsert outletExHisListtoUpsert Unique_Id__c;
        }
    }
    /**
      *@ Method  : updateMarketAccountOwner
      *@ update Owner in Outlet based on Market Settings Account Owner ES20-7369
    **/
    public static void updateMarketAccountOwner(List<Account> newItems, Map<Id,SObject> oldMap){
        List<Account> outletListtoUpdate = new List<Account>();
        Map<Id,Id> countryMarketAccOwnerMap = new Map<Id ,Id>();
        
        for(Account accObj : newItems){
            if(accObj.recordTypeId == outletRecordTypeId ){
                outletListtoUpdate.add(accObj);
            }               
        }
        for(Market_Setting__c marketSetting : marketSettingsList){
            if(marketSetting.Market_Account_Owner__c != null){
                countryMarketAccOwnerMap.put(marketSetting.Geography__c,marketSetting.Market_Account_Owner__c); 
            }
        }  
        
        for(Account outlet : outletListtoUpdate){
            if(countryMarketAccOwnerMap!=null  && countryMarketAccOwnerMap.containsKey(outlet.Country__c)){    
                outlet.ownerId = countryMarketAccOwnerMap.get(outlet.Country__c);
                
            }
            
        }
        
    } 
    /**
    * @description checkAndGenerateSharing
    * To create sharing record on Insert
    * @param List    
	*/

	public static void checkAndGenerateSharing(List<Account> newItems){
    	CST_SharingUtil.validateCreatePermission(newItems, 'Sales_Organisation__c');
    	CST_SharingUtil.generateSharingFromSalesOrg(newItems, 'Sales_Organisation__c', 'Read');  

        CST_SharingUtil.generateSharingFromSalesOrg(newItems, 'Sales_Organisation__c', 'Edit'); 

	}
    
    /**
    * @description validateAndReGenerateSharing
    * Modify, Validate sharing record on update
    * @param List,Map    
	*/
    public static void validateAndReGenerateSharing(List<Account> newItems,Map<Id, SObject> oldItems){
    Map<Id, Account> mapOldItems;
    List<Account> lstNewChangeSalesOrg = new List<Account>();
    List<Account> lstOldChangeSalesOrg = new List<Account>();
    

    //EDGE_SharingUtil.validateEditPermission(newItems);

    
    if(oldItems != null){
        mapOldItems = (Map<Id, Account>)oldItems;
    }
    
    for(Account objSales : newItems){
        if(mapOldItems.containsKey(objSales.Id) && objSales.Sales_Organisation__c != mapOldItems.get(objSales.Id).Sales_Organisation__c){
            lstNewChangeSalesOrg.add(objSales);
            lstOldChangeSalesOrg.add(mapOldItems.get(objSales.Id));
        }
    }
    
    if(lstNewChangeSalesOrg != null && lstNewChangeSalesOrg.size()>0){

        CST_SharingUtil.validateCreatePermission(lstNewChangeSalesOrg, 'Sales_Organisation__c');
        CST_SharingUtil.updateSharingRecords(lstNewChangeSalesOrg, lstOldChangeSalesOrg, 'Sales_Organisation__c');
        CST_SharingUtil.generateSharingFromSalesOrg(lstNewChangeSalesOrg, 'Sales_Organisation__c', 'Read');
        CST_SharingUtil.generateSharingFromSalesOrg(lstNewChangeSalesOrg, 'Sales_Organisation__c', 'Edit');

    }       
}
    
          /**
    * @description updateAcctCurrency
    * Update Currency based on Geography Currency (User Story Numner:142256)
    * @param List    
    */
    
    public static void updateAcctCurrency(List<Account> recNew){
        
        Set<String> countryList = new Set<String>();
        Map<String, String> populateCurrency = new Map<String, String>();
        
        for(Account acc : recNew){
            if(acc.Country__c !=null){
                countryList.add(acc.Country__c);
            }
        }
        if(!countryList.isEmpty()){
            for(Geography__c geographyCurrency: [SELECT CurrencyIsoCode
                                                 FROM Geography__c WHERE Id IN: countryList])
            {
                populateCurrency.put(geographyCurrency.id,geographyCurrency.CurrencyIsoCode);
            } 
        }
        for(Account acc : recNew){
            if(populateCurrency != null &&  populateCurrency.containskey(acc.Country__c)){
                acc.CurrencyIsoCode = populateCurrency.get(acc.Country__c);
            }
        }
    } 
}