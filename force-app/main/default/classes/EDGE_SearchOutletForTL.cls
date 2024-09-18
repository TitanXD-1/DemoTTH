/**
* @Name: EDGE_SearchOutletForTL

* @Purpose: Controller class of EDGE_SearchResultofOutletCmp

* @History                                                            
                                                          
* @VERSION      AUTHOR           DATE              DETAIL
*  1.0       Preyanka Ghosh   22/02/2019      Initial Development  
*  2.0       Debolina/Mayukh  25/05/2022      ES20-12718 - INTRODUCTION OF MORE SEARCH RESULTS IN STATIC TARGET LIST_SFDC_TECH DEBT
*  3.0       Supriya          7/06/2022       ES20-9743 -Create Distributor for Promotion
*  4.0       Anand            7/06/2022       ES20-12844 - Search and associate Distributor for Promotion
*  5.0		 Doman Murmu	  17/07/2023	  142822
**/
public with sharing class EDGE_SearchOutletForTL {
    
    /*
     
    * @description : searchOutletDetails - To fetch the Outlet depend on the criteria selected on UI   
    * @return : void  
    * @param : String, Id
    
    */
    @AuraEnabled
    public static List<Account> searchOutletDetails(String queryString, ID targetListID){
        List<Account> lstAccount = new List<Account>();
        try{
            if(String.isNotBlank(queryString) && String.isNotBlank(targetListID)){
                String objectName = getObjectName(targetListID);
                //Append AND/OR to create the query properly
                if(queryString.startsWith(' OR')){
                    queryString = queryString.removeStart(' OR');
                    queryString = ' AND ( ' + queryString + ' )';
                }
                
                //Get Account List for Target list and Territory
                if(String.isNotBlank(objectName) && objectName.equalsIgnoreCase('Target_List__c')){
                    lstAccount = getTargetListAccount(queryString, targetListID);
                } else if(String.isNotBlank(objectName) && objectName.equalsIgnoreCase('Territory__c')){
                    lstAccount = getTerritoryAccount(queryString, targetListID);
                }else if(String.isNotBlank(objectName) && objectName.equalsIgnoreCase('Promotion_Master__c')){ //ES20-9743,12844
                    lstAccount = getPromotionAccount(queryString, targetListID);
                }
            }        
        } catch(Exception ex){
            System.debug(LoggingLevel.DEBUG,'Exception::::'+ex.getLineNumber()+ex.getMessage());
            //throw new AuraHandledException(ex.getMessage());
            AuraHandledException ae = new AuraHandledException(ex.getMessage());
            ae.setMessage(ex.getMessage());
            System.debug(LoggingLevel.DEBUG,ae);
            throw ae;
        }
        return lstAccount;
    }
    
    
    /*
     
    * @description : getTerritoryAccount - Get Account List based on Territory      
    * @return : List<Account>  
    * @param : String, Id
    
    */
    Public static List<Account> getTerritoryAccount(String queryString, ID territoryID) {
        String AccountType = 'Outlet';	//NOPMD
        String Status = 'Active';	//NOPMD
        List<Account> lstAccount = new List<Account>();
        Id targetCountryId; //NOPMD
        set<Id> outletIdSet = new set<Id>();
        try{
            if(Schema.sObjectType.Account.isAccessible() && Schema.sObjectType.Territory__c.isAccessible() && 
               Schema.sObjectType.Outlet_Territory__c.isAccessible() && Schema.sObjectType.Account.fields.Name.isAccessible() && 
               Schema.sObjectType.Account.fields.Status__c.isAccessible() && Schema.sObjectType.Account.fields.Ref__c.isAccessible() && 
               Schema.sObjectType.Account.fields.Country__c.isAccessible() &&  Schema.sObjectType.Territory__c.fields.Country__c.isAccessible() &&
               Schema.sObjectType.Outlet_Territory__c.fields.Outlet__c.isAccessible()
            ){
                String strQuery = 'SELECT Id, Ref__c, Name, Status__c, BillingStreet, BillingCity, BillingPostalCode, Country__c, Country__r.Name FROM Account';
                strQuery += ' WHERE RecordType.Name =:AccountType AND Status__c =:Status';
                System.debug('getTerritoryAccount ->'+strQuery);
                strQuery = String.escapeSingleQuotes(strQuery);		//142822 added Single.escapeSingleQuotes
                System.debug('getTerritoryAccount es->'+strQuery);
                //Add Filter Query String
                strQuery += queryString;

                //Filter existing added outlets
                for(Outlet_Territory__c outletTerritory : [SELECT Id, Outlet__c, Territory__c FROM Outlet_Territory__c WHERE Territory__c =:territoryID LIMIT 5000]){
                    outletIdSet.add(outletTerritory.Outlet__c);
                }
                if(outletIdSet.size()>0){
                    strQuery += ' AND Id NOT IN :outletIdSet';
                }
                
                strQuery += ' Order by Name limit 40000';
                lstAccount = Database.query(strQuery);
            }
        } catch(Exception exceptionTerritory){
            System.debug('Exception::::'+exceptionTerritory.getMessage()+exceptionTerritory.getLineNumber());
            //throw new AuraHandledException(exceptionTerritory.getMessage());
            AuraHandledException ae = new AuraHandledException(exceptionTerritory.getMessage());	
            ae.setMessage(exceptionTerritory.getMessage());
            System.debug(LoggingLevel.DEBUG,ae);
            throw ae;
        }
        return lstAccount;
    }
    
     /*    
    * @description : getPromotionAccount - Get Supplier List based on Promotion       
    * @return : List<Account>  
    * @param : String, Id    
    */
    Public static List<Account> getPromotionAccount(String queryString, ID promotionId) {
        String AccountType = 'Distributor/Wholesaler';	//NOPMD
        String Status = 'Active';	//NOPMD
        List<Account> lstAccount = new List<Account>();
        id promotionCountryId;
        set<Id> distributorIds = new set<Id>();
        try{
            if(Schema.sObjectType.Account.isAccessible() && Schema.sObjectType.Promotion_Master__c.isAccessible() && 
               Schema.sObjectType.Promotion_Supplier__c.isAccessible() && Schema.sObjectType.Account.fields.Name.isAccessible() && 
               Schema.sObjectType.Account.fields.Status__c.isAccessible() && Schema.sObjectType.Account.fields.Ref__c.isAccessible() && 
              Schema.sObjectType.Account.fields.Country__c.isAccessible() &&  Schema.sObjectType.Promotion_Master__c.fields.Country__c.isAccessible() &&
               Schema.sObjectType.Promotion_Supplier__c.fields.Supplier__c.isAccessible()
            ){
                String strQuery = 'SELECT Id, Ref__c, Name, Status__c, BillingStreet, BillingCity, BillingPostalCode, Country__c, Country__r.Name FROM Account';
                strQuery += ' WHERE RecordType.Name =:AccountType AND Status__c =:Status';
                  
                
                List<Promotion_Master__c> objPMList = [SELECT Country__c, RecordTypeId FROM Promotion_Master__c WHERE Id =:promotionId LIMIT 1];
                if(objPMList != null && objPMList.size() > 0){
                    promotionCountryId = objPMList[0].Country__c;
                    if(String.isNotBlank(promotionCountryId)){
                        strQuery += ' AND Country__c =:promotionCountryId';
                    }
                }
                System.debug('getPromotionAccount ->'+strQuery);
                strQuery = String.escapeSingleQuotes(strQuery);		//142822 added Single.escapeSingleQuotes
                System.debug('getPromotionAccount es->'+strQuery);
                //Add Filter Query String
                strQuery += queryString;

                //Filter existing added distributors
                for(Promotion_Supplier__c objPromoSupp : [SELECT Id, Supplier__c FROM Promotion_Supplier__c 
                                                          WHERE Promotion__c =:promotionId  LIMIT 5000])
                {
                    distributorIds.add(objPromoSupp.Supplier__c);
                }
                
                if(distributorIds.size()>0){
                    strQuery += ' AND Id NOT IN :distributorIds';
                }
                
                strQuery += ' Order by Name limit 40000';
                System.debug('strQuery : '+ strQuery);
                lstAccount = Database.query(strQuery);
            }
        } catch(Exception exceptionTerritory){
            System.debug('Exception::::'+exceptionTerritory.getMessage()+exceptionTerritory.getLineNumber());
            //throw new AuraHandledException(exceptionTerritory.getMessage());
            AuraHandledException ae = new AuraHandledException(exceptionTerritory.getMessage());	
            ae.setMessage(exceptionTerritory.getMessage());
            System.debug(LoggingLevel.DEBUG,ae);
            throw ae;
        }
        return lstAccount;
    }
       
    /*     
    * @description : getTargetListAccount - Get Account List based on Target List      
    * @return : List<Account>  
    * @param : String, Id    
    */
    public static List<Account> getTargetListAccount(String queryString, ID targetListID) {
        String AccountType = 'Outlet';	//NOPMD
        String Status = 'Active';	//NOPMD
        Id targetCountryId;
        List<Target_List_Member__c> lstTargetMember = new List<Target_List_Member__c>();    //NOPMD
        List<Account> lstAccount = new List<Account>();
        set<Id> outletIdSet = new set<Id>();
        try{
            if(Schema.sObjectType.Account.isAccessible() && Schema.sObjectType.Target_List__c.isAccessible() && 
               Schema.sObjectType.Target_List_Member__c.isAccessible() && Schema.sObjectType.Account.fields.Name.isAccessible() && 
               Schema.sObjectType.Account.fields.Status__c.isAccessible() && Schema.sObjectType.Account.fields.Ref__c.isAccessible() && 
               Schema.sObjectType.Account.fields.Country__c.isAccessible() && Schema.sObjectType.Target_List__c.fields.Country__c.isAccessible() &&
               Schema.sObjectType.Target_List_Member__c.fields.Outlet__c.isAccessible()
			){
                String strQuery = 'SELECT Id, Ref__c, Name, Status__c, BillingStreet, BillingCity, BillingPostalCode, Country__c, Country__r.Name FROM Account';
                strQuery += ' WHERE RecordType.Name =:AccountType AND Status__c =:Status';  
                //Fetch Country from Target List
                  
                Id dynamicRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Dynamic_Target_List'].Id;
                
                Target_List__c objTargetList = [SELECT Country__c, RecordTypeId FROM Target_List__c WHERE Id =:targetListID LIMIT 1];
                targetCountryId = objTargetList.Country__c;
                if(String.isNotBlank(targetCountryId)){
                    strQuery += ' AND Country__c =:targetCountryId';
                }
                System.debug('getTargetListAccount ->'+strQuery);
                strQuery = String.escapeSingleQuotes(strQuery);		//142822 added Single.escapeSingleQuotes
                System.debug('getTargetListAccount es->'+strQuery);
                //Add Filter Query String
                strQuery += queryString;
                
                if(objTargetList.RecordTypeId != dynamicRecordTypeId){
                    //Fetch already added target list member and Create Set for Existing Target List Member and exclude that from query
                    /*lstTargetMember = [SELECT Outlet__c FROM Target_List_Member__c WHERE Target_List__c =:targetListID  LIMIT 5000];
                    if(!lstTargetMember.isEmpty()){
                        strQuery += ' AND ID  Not In (';
                        for(Target_List_Member__c objTarMem : lstTargetMember){
                            strQuery += '\''+objTarMem.Outlet__c+'\',';
                        }
                        strQuery = strQuery.removeEnd(',') ;
                        strQuery+= ') ';
                    }*/
                    //Filter existing added outlets
                    for(Target_List_Member__c objTarMem : [SELECT Id, Outlet__c FROM Target_List_Member__c WHERE Target_List__c =:targetListID  LIMIT 5000]){
                        outletIdSet.add(objTarMem.Outlet__c);
                    }
                    if(outletIdSet.size()>0){
                        strQuery += ' AND Id NOT IN :outletIdSet';
                    }
                  } 
                  
                  strQuery += ' Order by Name limit 40000';                   
                  
                  System.debug('strQuery:::'+strQuery);
                  lstAccount = Database.query(strQuery);
              }            
        } catch(Exception ex){
            System.debug('Exception::::'+ex.getMessage()+ex.getLineNumber());
            //throw new AuraHandledException(ex.getMessage());
            AuraHandledException ae = new AuraHandledException(ex.getMessage());
            ae.setMessage(ex.getMessage());
            System.debug(LoggingLevel.DEBUG,ae);
            throw ae;
        }
        return lstAccount;
    }
    
    /*    
    * @description : updateTLQuery - Update Target List with Dynamic Query in Dynamic_Query__c      
    * @return :  Map<String,String>  
    * @param : Id, String   
    */
    @AuraEnabled
    public static Map<String,String> updateTLQuery(ID targetListID, String dynamicQuery){
        Map<String,String> mapMessage = new Map<String,String>();
        Target_List__c objTargetList = new Target_List__c();
        String strQuery = 'SELECT Id, Ref__c, Name, Status__c, Country__c, Country__r.Name FROM Account';
        strQuery += ' WHERE RecordType.Name = \'Outlet\' AND Status__c = \'Active\'';
        
        if(String.isNotBlank(targetListID) && String.isNotBlank(dynamicQuery)){
            objTargetList = [SELECT Id, Country__c FROM Target_List__c WHERE Id =:targetListID LIMIT 1];
            if(String.isNotBlank(objTargetList.Country__c)){
                strQuery += ' AND Country__c = \'' +objTargetList.Country__c+'\' ';
            }
            
            //HANDLE OR Condition
            if(dynamicQuery.startsWith(' OR')){
                dynamicQuery = dynamicQuery.removeStart(' OR');
                dynamicQuery = ' AND ( ' + dynamicQuery + ' )';
            }
            
            strQuery += dynamicQuery;   
            strQuery += ' Order by Name limit 9999';            
            
            objTargetList.Dynamic_Query__c = strQuery;
        }
        //Update Target List
        try{
            if(Schema.sObjectType.Target_List__c.isUpdateable() && 
               Schema.sObjectType.Target_List__c.fields.Dynamic_Query__c.isUpdateable() && 
               Schema.sObjectType.Target_List__c.fields.Country__c.isUpdateable()
              ){
                  Database.update(objTargetList);
                  mapMessage.put(EDGE_Constant.EDGE_SUCCESS_STATUS, 'Target List Query Updated successfully');
              }
        }catch(Exception e){
            mapMessage.put(EDGE_Constant.EDGE_ERROR_STATUS, e.getMessage());
        }
        return mapMessage;
    }
    
    /*
     
    * @description : createTLMember - Create Target List Member with Outlet selected for particular target list     
    * @return :  Map<String,String>  
    * @param : List, Id
    
    */
    @AuraEnabled
    public static Map<String,String> createTLMember(List<String> lstOutletID, ID targetListID){
        
        Map<String,String> mapMessage = new Map<String,String>();
        List<String> lstErrorMessage = new List<String>();  //NOPMD
        
        //Added two variables - OutletSetIds & errorMessage as a part of ES20-12718
        Set<Id> OutletSetIds = new Set<Id>();               
        String errorMessage = '';                          
                          
        try{
            if(!lstOutletID.isEmpty() && String.isNotBlank(targetListID)){
                List<Target_List_Member__c> lstTerritoryListMember = new List<Target_List_Member__c>();
                for(String outletid : lstOutletID){       //Added as a part of ES20-12718
                    if(outletid != Null){
                        OutletSetIds.add(outletid); 
                    } 
                }
                List<Target_List_Member__c> existingTMList = [Select Id,Outlet__c,Outlet__r.Name from Target_List_Member__c where Outlet__c in: OutletSetIds and Target_List__c =: targetListID];
                //Check whether the user has create access in field and object
                if(Schema.sObjectType.Target_List_Member__c.isCreateable() && 
                   Schema.sObjectType.Target_List_Member__c.fields.Outlet__c.isCreateable() && 
                   Schema.sObjectType.Target_List_Member__c.fields.Assignment_Status__c.isCreateable() && 
                   Schema.sObjectType.Target_List_Member__c.fields.Target_List__c.isCreateable()
                  ){
                      if(existingTMList.size()==0){
                          //Create Target List Member list to insert
                          for(String outletID : lstOutletID){                          
                              Target_List_Member__c objTarget = new Target_List_Member__c(Outlet__c = outletID,
                                                                                          Assignment_Status__c = EDGE_Constant.EDGE_TARGETMEMBER_WAITINGACTIVATION,
                                                                                          Target_List__c = targetListID);
                              lstTerritoryListMember.add(objTarget);  
                          }
                      }
                      //Error message shown through label. Added as a part of ES20-12718 
                      else if (existingTMList!=Null && existingTMList.size()>0){            
                          errorMessage = System.Label.Duplicate_Target_Iist + ' : ';      
                          Integer counter = 1;
                          for(Target_List_Member__c tlm : existingTMList){
                              errorMessage = errorMessage + tlm.Outlet__r.Name;
                              if(counter != existingTMList.size()){
                                  errorMessage = errorMessage+' , ';
                              }
                              counter = counter + 1;
                          }
                      }
                  }
                //Create Target List member
                if(!lstTerritoryListMember.isEmpty()){
                    Database.SaveResult[] lstSaveResult = Database.insert(lstTerritoryListMember);
                    if (lstSaveResult[0].isSuccess()) {
                        mapMessage.put(EDGE_Constant.EDGE_SUCCESS_STATUS,'Target List Member created successfully');
                    } else {
                        List<Database.Error> dbError = lstSaveResult[0].getErrors();
                        mapMessage.put(EDGE_Constant.EDGE_ERROR_STATUS,dbError[0].getMessage());
                    }                    
                }
                else if (existingTMList.size() > 0 && errorMessage != Null){          //Added as a part of ES20-12718
                    mapMessage.put(EDGE_Constant.EDGE_ERROR_STATUS, errorMessage);
                }
            }
        } catch(exception exceptionTL){
            System.debug('exceptionTL:::'+exceptionTL);
            throw new AuraHandledException(exceptionTL.getMessage());
        }
        return mapMessage;        
    } 
    
    /*
     
    * @description : createPromotionSupplier - Create Promotion Supplier with Distributor selected for particular Supplier     
    * @return :  Map<String,String>  
    * @param : List, Id
    
    */
    @AuraEnabled
    public static Map<String,String> createPromotionSupplier(List<String> lstDistributorID, ID promotionId){
        
        Map<String,String> mapMessage = new Map<String,String>();
        List<String> lstErrorMessage = new List<String>();  //NOPMD
        
        //Added two variables - DistributorSetIds & errorMessage as a part of ES20-12718
        Set<Id> DistributorSetIds = new Set<Id>();               
        String errorMessage = '';                          
                          
        try{
            if(!lstDistributorID.isEmpty() && String.isNotBlank(promotionId)){
                List<Promotion_Supplier__c> lstPromotionSupplier = new List<Promotion_Supplier__c>();
                for(String distributorId : lstDistributorID){       //Added as a part of ES20-12718
                    if(distributorId != Null){
                        DistributorSetIds.add(distributorId); 
                    } 
                }
                List<Promotion_Supplier__c> existingPSList = [Select Id,Supplier__c,Supplier__r.Name from Promotion_Supplier__c where Supplier__c in: DistributorSetIds and Promotion__c = :promotionId];
                //Check whether the user has create access in field and object
                if(Schema.sObjectType.Promotion_Supplier__c.isCreateable() && 
                   Schema.sObjectType.Promotion_Supplier__c.fields.Supplier__c.isCreateable() && 
                   Schema.sObjectType.Promotion_Supplier__c.fields.Promotion__c.isCreateable()
                  ){
                      if(existingPSList.size()==0){
                          //Create Promotion Supplier list to insert
                          for(String distributorID : lstDistributorID){                          
                              Promotion_Supplier__c objPS = new Promotion_Supplier__c(Supplier__c = distributorID,
                                                                                          Promotion__c = promotionId);
                              lstPromotionSupplier.add(objPS);  
                          }
                      }
                      //Error message shown through label. Added as a part of ES20-12718 
                      else if (existingPSList!=Null && existingPSList.size()>0){           
                          errorMessage = System.Label.Duplicate_Distrubutor_Iist + ' : ';      
                          Integer counter = 1;
                          for(Promotion_Supplier__c ps : existingPSList){
                              errorMessage = errorMessage + ps.Supplier__r.Name;
                              if(counter != existingPSList.size()){
                                  errorMessage = errorMessage+' , ';
                              }
                              counter = counter + 1;
                          }
                      }
                  }
                //Create Promotion Supplier
                if(!lstPromotionSupplier.isEmpty()){
                    Database.SaveResult[] lstSaveResult = Database.insert(lstPromotionSupplier);
                    if (lstSaveResult[0].isSuccess()) {
                        mapMessage.put(EDGE_Constant.EDGE_SUCCESS_STATUS,'Promotion Supplier Created Successfully');
                    } else {
                        List<Database.Error> dbError = lstSaveResult[0].getErrors();
                        mapMessage.put(EDGE_Constant.EDGE_ERROR_STATUS,dbError[0].getMessage());
                    }                    
                }
                else if (existingPSList.size() > 0 && errorMessage != Null){          //Added as a part of ES20-12718
                    mapMessage.put(EDGE_Constant.EDGE_ERROR_STATUS, errorMessage);
                }
            }
        } catch(exception exceptionTL){
            System.debug(LoggingLevel.DEBUG,'exceptionTL:::'+exceptionTL);
            throw new AuraHandledException(exceptionTL.getMessage());
        }
        return mapMessage;        
    }
    
     /*
     
    * @description : createTerritoryOutlet - Create Territory Outlet with Outlet selected for particular Territory     
    * @return :  Map<String,String>  
    * @param : List, Id
    
    */
    @AuraEnabled
    public static Map<String,List<String>> createTerritoryOutlet(List<String> lstOutletID, Id territoryId){
        Map<String, List<String>> mapMessage = new Map<String, List<String>>();
        List<Outlet_Territory__c> lstTerritoryOutlet = new List<Outlet_Territory__c>();
        List<Outlet_Territory__c> lstSavedTerritoryOutlet = new List<Outlet_Territory__c>();
        List<String> lstErrorMessage = new List<String>();
        Territory__c objTerritory;
        List<Outlet_Territory__c> finalTerritoryOutlet = new List<Outlet_Territory__c>();
        Set<String> outeltTerrSet = new Set<String>();
        
        try{
			//Check whether user has access on objects and field
            if(Schema.sObjectType.Territory__c.isAccessible() && 
               Schema.sObjectType.Territory__c.fields.Territory_Type__c.isAccessible()
			){
                //To get territory type
                objTerritory = [SELECT Territory_Type__c from Territory__c where id =:territoryId];
            }
            
            //Create the list of Outlet Territory object
            for(String strOutlet : lstOutletID){
                Outlet_Territory__c objOutletTerr = new Outlet_Territory__c();
                objOutletTerr.Territory__c = territoryId;
                objOutletTerr.Outlet__c = strOutlet;
                objOutletTerr.Active__c = 'Waiting Activation';
                lstTerritoryOutlet.add(objOutletTerr);
            }
            System.debug(LoggingLevel.DEBUG,'lstTerritoryOutlet:::'+lstTerritoryOutlet);
            //Those Outlet which is already have a territory assign of same type the selcted territoy have then restrict them to insert 
            Map<Id, List<Outlet_Territory__c>> mapOutletTerritory = EDGE_OutletTerritoryTriggerHelper.getOutletTerritoryMap(lstTerritoryOutlet);
            System.debug(LoggingLevel.DEBUG,'mapOutletTerritory:::'+mapOutletTerritory);
            for(Outlet_Territory__c outletTerritory : lstTerritoryOutlet){
                if(mapOutletTerritory != null && mapOutletTerritory.size()>0 && objTerritory != null){
                    if(mapOutletTerritory.containsKey(outletTerritory.Outlet__c)){
                        List<Outlet_Territory__c> mappedOutletTerritoryList = mapOutletTerritory.get(outletTerritory.Outlet__c);            
                        if(mappedOutletTerritoryList != null && mappedOutletTerritoryList.size()>0){
                            for(Outlet_Territory__c objOutletTerritory:mappedOutletTerritoryList){                    
                                if(objOutletTerritory.Territory__r.Territory_Type__c == objTerritory.Territory_Type__c && 
                                   objOutletTerritory.Outlet__c == outletTerritory.Outlet__c){
                                    String errorMessage = objOutletTerritory.Outlet__r.Name + ' ' + System.Label.EDGE_Outlet_To_Territory_Message + objOutletTerritory.Territory__r.Name;
                                    lstErrorMessage.add(errorMessage);
                                    system.debug(LoggingLevel.DEBUG,'@@lstErrorMessage' + lstErrorMessage);
                                } else{
                                    lstSavedTerritoryOutlet.add(outletTerritory);
                                }
                            }
                        } else {
                            lstSavedTerritoryOutlet.add(outletTerritory);
                        }
                    } else {
                        lstSavedTerritoryOutlet.add(outletTerritory);
                    }
                } else {
                    lstSavedTerritoryOutlet.add(outletTerritory);
                }
            }
            
            if(!lstErrorMessage.isEmpty()){
                mapMessage.put(EDGE_Constant.EDGE_ERROR_STATUS, lstErrorMessage);
            }
            System.debug(LoggingLevel.DEBUG,'lstSavedTerritoryOutlet:::::'+lstSavedTerritoryOutlet);
            
            
            if(!lstSavedTerritoryOutlet.isEmpty()){
                for(Outlet_Territory__c outletTerritory : lstSavedTerritoryOutlet){
                    String setKey = outletTerritory.Outlet__c+'_'+outletTerritory.Territory__c;
                    if(!outeltTerrSet.contains(setKey)){
                        finalTerritoryOutlet.add(outletTerritory);
                    }
                    outeltTerrSet.add(setKey);
                }
            }
            //Insert the Outlet territory object list
            //if(!lstSavedTerritoryOutlet.isEmpty()){
            if(!finalTerritoryOutlet.isEmpty()){
                if(Schema.sObjectType.Outlet_Territory__c.isCreateable() &&  
                   Schema.sObjectType.Outlet_Territory__c.fields.Territory__c.isCreateable() && 
                   Schema.sObjectType.Outlet_Territory__c.fields.Outlet__c.isCreateable() &&
                   Schema.sObjectType.Outlet_Territory__c.fields.Active__c.isCreateable()
				){
                    //Database.SaveResult[] lstSaveResult = Database.insert(lstSavedTerritoryOutlet,true);
                    Database.SaveResult[] lstSaveResult = Database.insert(finalTerritoryOutlet,true);
                    if (lstSaveResult[0].isSuccess()) {
                        //mapMessage.put(EDGE_Constant.EDGE_SUCCESS_STATUS,'Target List Member created successfully');
                    } else {
                        List<Database.Error> dbError = lstSaveResult[0].getErrors();
                        lstErrorMessage = mapMessage.get(EDGE_Constant.EDGE_ERROR_STATUS);
                        for(Database.Error dataError : dbError){
                            lstErrorMessage.add(dataError.getMessage());
                        }
                        mapMessage.put(EDGE_Constant.EDGE_ERROR_STATUS, lstErrorMessage);
                    }
                }                
            }
        } catch(exception exceptionTerritory){
            throw new AuraHandledException(exceptionTerritory.getMessage());
        }
        return mapMessage;
    }
    
    
     /*
     
    * @description : getObjectName - Get sobject name depends on target list     
    * @return :  String
    * @param : Id
    
    */
    @AuraEnabled
    public static String getObjectName(ID targetListID){
        String sObjName;        
        //Retrieve the Name of SObject depend on the Id provided
        if(String.isNotBlank(targetListID)){
            sObjName = targetListID.getSObjectType().getDescribe().getName();
        }
        return sObjName;        
    }   
}