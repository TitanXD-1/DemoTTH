/**********************************************************************
Name: EDGE_SearchTerritoryForBH
=======================================================================
Req: 
ES20-5027
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Preyanka			15/01/2020		  ES20-
2.0		  Amar Deep			23/01/2020		  ES20-6810
3.0	      Sagar Barman		23/03/2020		  ES20-3452	
***********************************************************************/
public with sharing class EDGE_SearchTerritoryForBH {
    
    //Method to get Bonus Header
    @AuraEnabled
    public static Bonus_Header__c getBonusHeaderDetails(Id objectId){
        Bonus_Header__c bHeader = new Bonus_Header__c();
        String sObjName = objectId.getSObjectType().getDescribe().getName();
        try{
            switch on sObjName{
                when 'Bonus_Header__c'{
                    bHeader = [SELECT Id, Status__c FROM Bonus_Header__c WHERE Id =:objectId LIMIT 1];
                }
                when 'Bonus_Detail__c'{
                    List<Bonus_Detail__c> bDetailList = [SELECT Id, Bonus_Header__c FROM Bonus_Detail__c WHERE Id =:objectId LIMIT 1];
                    if(bDetailList != null){
                        bHeader = [SELECT Id, Status__c FROM Bonus_Header__c WHERE Id =:bDetailList[0].Bonus_Header__c LIMIT 1];
                    }
                }
            }
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        return bHeader;
    }
    
    /*******************************************************************
Purpose: To fetch the Territory depend on the criteria selected on UI                                                          
********************************************************************/
    @AuraEnabled
    public static List<Territory__c> searchTerritoryDetails(String queryString, ID objectId, String objectName){
        System.debug('==queryString add by sagar=='+queryString);
        List<Territory__c> lstTerritory = new List<Territory__c>();
        try{
            if(String.isNotBlank(queryString) && String.isNotBlank(objectId) && String.isNotBlank(objectName)){                
                //Append AND/OR to create the query properly
                if(queryString.startsWith(' OR')){
                    queryString = queryString.removeStart(' OR');
                    queryString = ' AND ( ' + queryString + ' )';
                }
                if(objectName.equalsIgnoreCase('Territory__c')){
                    lstTerritory = getTerritory(queryString, objectId, objectName);
                } else {
                    lstTerritory = getTerritoryHierarchy(queryString, objectId, objectName);
                }
            }
        } catch(Exception ex){
            System.debug('Exception::::'+ex.getLineNumber()+ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
        return lstTerritory;
    }
    
    /*******************************************************************
Purpose: Get Territory List                                                      
********************************************************************/
    public static List<Territory__c> getTerritory(String queryString, ID objectId, String objectName) {
        List<Territory__c> lstTerritory = new List<Territory__c>();
        Set<Id> setTerritoryIds = new Set<Id>();
        String strQuery = '';
        String sObjName = objectId.getSObjectType().getDescribe().getName();
        
        try{
            if(Schema.sObjectType.Territory__c.isAccessible() && Schema.sObjectType.Bonus_Header__c.isAccessible() && 
               Schema.sObjectType.Bonus_Assignment__c.isAccessible() && Schema.sObjectType.Bonus_Detail__c.isAccessible())
            {
                strQuery = 'SELECT Id, Name,Territory_Type__c,Status__c,Country__r.Name,Primary_Sales_Rep__r.Name FROM ';
                strQuery += objectName;
                strQuery += ' WHERE Status__c = \'Active\' AND Territory_Type__c = \'Sales\'';
                
                //Add Filter Query String
                strQuery += queryString;
                //Filter existing added Bonus Headers
                if(sObjName.equals('Bonus_Header__c')){
                    Id recordTypeId = Schema.SObjectType.Bonus_Assignment__c.getRecordTypeInfosByName().get('Bonus Header').getRecordTypeId();
                    for(Bonus_Assignment__c bonusAssignment : [SELECT Id, Territory__c FROM Bonus_Assignment__c WHERE Bonus_Header__c =:objectId AND RecordTypeId =:recordTypeId LIMIT 5000]){
                        setTerritoryIds.add(bonusAssignment.Territory__c);
                    }
                }else if(sObjName.equals('Bonus_Detail__c')){
                    Id recordTypeId = Schema.SObjectType.Bonus_Assignment__c.getRecordTypeInfosByName().get('Bonus Detail').getRecordTypeId();
                    for(Bonus_Assignment__c bonusAssignment : [SELECT Id, Territory__c FROM Bonus_Assignment__c WHERE Bonus_Detail__c =:objectId AND RecordTypeId =:recordTypeId LIMIT 5000]){
                        setTerritoryIds.add(bonusAssignment.Territory__c);
                    }
                }
                
                if(setTerritoryIds.size()>0){
                    strQuery += ' AND Id NOT IN :setTerritoryIds';
                }  
                //added for 3542 Primary_Sales_Rep__c
                if(sObjName.equals('Notification__c')){
                    strQuery += ' AND Primary_Sales_Rep__c != null AND Primary_Sales_Rep__c NOT IN (SELECT User__c FROM User_Notification__c WHERE Notification__c =:objectId)';
                }
                
                strQuery += ' Order by Name limit 40000';
                lstTerritory = Database.query(strQuery);                   
            }
        }catch(Exception ex){
            System.debug('Exception::::'+ex.getLineNumber()+ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
        
        return  lstTerritory;       
    }
    
    /*******************************************************************
Purpose: Get Territory List depending on Territory Hierarchy List                                                      
********************************************************************/
    public static List<Territory__c> getTerritoryHierarchy(String queryString, ID objectId, String objectName){
        List<Territory__c> lstTerritory = new List<Territory__c>();
        List<Territory_Hierarchy__c> lstTerritoryHierarchy = new List<Territory_Hierarchy__c>();
        Set<Id> setTerritoryIds = new Set<Id>();
        String sObjName = objectId.getSObjectType().getDescribe().getName();
        String strQuery = '';
        
        try{
            if(Schema.sObjectType.Territory__c.isAccessible() && Schema.sObjectType.Bonus_Header__c.isAccessible() && 
               Schema.sObjectType.Bonus_Assignment__c.isAccessible() && Schema.sObjectType.Bonus_Detail__c.isAccessible())
            {
                strQuery = 'SELECT Id, Name FROM ';
                strQuery += objectName;
                strQuery += ' WHERE RecordType.Name = \'Region\'';
                
                //Add Filter Query String
                strQuery += queryString + ' Order by Name limit 40000';
                System.debug('strQuery1:::'+strQuery);
                lstTerritoryHierarchy = Database.query(strQuery);
                
                if(lstTerritoryHierarchy != null && lstTerritoryHierarchy.size()>0){
                    strQuery = 'SELECT Id, Name,Territory_Type__c,Status__c,Country__r.Name,Primary_Sales_Rep__r.Name FROM Territory__c WHERE Status__c = \'Active\' AND Region__c IN :lstTerritoryHierarchy AND Territory_Type__c = \'Sales\'';
                    //Filter existing added Bonus Headers
                    if(sObjName.equals('Bonus_Header__c')){
                        Id recordTypeId = Schema.SObjectType.Bonus_Assignment__c.getRecordTypeInfosByName().get('Bonus Header').getRecordTypeId();
                        for(Bonus_Assignment__c bonusAssignment : [SELECT Id, Territory__c FROM Bonus_Assignment__c WHERE Bonus_Header__c =:objectId AND RecordTypeId =:recordTypeId LIMIT 5000]){
                            setTerritoryIds.add(bonusAssignment.Territory__c);
                        }
                    }else if(sObjName.equals('Bonus_Detail__c')){
                        Id recordTypeId = Schema.SObjectType.Bonus_Assignment__c.getRecordTypeInfosByName().get('Bonus Detail').getRecordTypeId();
                        for(Bonus_Assignment__c bonusAssignment : [SELECT Id, Territory__c FROM Bonus_Assignment__c WHERE Bonus_Detail__c =:objectId AND RecordTypeId =:recordTypeId LIMIT 5000]){
                            setTerritoryIds.add(bonusAssignment.Territory__c);
                        }
                    }
                    
                    if(setTerritoryIds.size() > 0){
                        strQuery += ' AND Id NOT IN :setTerritoryIds';
                    }
                    strQuery += ' Order by Name limit 40000';
                    lstTerritory = Database.query(strQuery);
                }
            }
        }catch(Exception ex){
            System.debug('Exception::::'+ex.getLineNumber()+ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
        return lstTerritory;
    }
    
    /*******************************************************************
Purpose: Create Bonus Assignment object with selected territory 
********************************************************************/
    @AuraEnabled
    public static Map<String,String> insertBonusAssignment(ID objectId, List<Id> lstTerritoryId){
        Map<String,String> mapMessage = new Map<String,String>();
        Map<String,String> bonusHeaderUniquekeyMap = new Map<String,String>();
        List<Bonus_Assignment__c> bonusAssignmentList = new List<Bonus_Assignment__c>();
        set<Id> territoryIds = new set<Id>();
        String sObjName = objectId.getSObjectType().getDescribe().getName();
        
        try{
            if(lstTerritoryId != null && lstTerritoryId.size()>0){                
                if(sObjName.equals('Bonus_Header__c')){
                    for(Id terrObjId : lstTerritoryId){
                        Bonus_Assignment__c newBonusAssignment = new Bonus_Assignment__c();
                        Id recordTypeId = Schema.SObjectType.Bonus_Assignment__c.getRecordTypeInfosByName().get('Bonus Header').getRecordTypeId();
                        newBonusAssignment.Bonus_Header__c = objectId;
                        newBonusAssignment.RecordTypeId = recordTypeId;
                        newBonusAssignment.Territory__c = terrObjId;
                        bonusAssignmentList.add(newBonusAssignment);
                    }
                }else if(sObjName.equals('Bonus_Detail__c')){
                    Bonus_Detail__c bonusDetailObj = [SELECT Bonus_Header__c, Weight__c From Bonus_Detail__c WHERE Id =: objectId LIMIT 1];
                    for(Id terrObjId : lstTerritoryId){
                        Bonus_Assignment__c newBonusAssignment = new Bonus_Assignment__c();
                        Id recordTypeId = Schema.SObjectType.Bonus_Assignment__c.getRecordTypeInfosByName().get('Bonus Detail').getRecordTypeId();
                        newBonusAssignment.Bonus_Detail__c = objectId;
                        newBonusAssignment.Bonus_Header__c = bonusDetailObj.Bonus_Header__c;
                        newBonusAssignment.Territory_Percentage__c = bonusDetailObj.Weight__c;
                        newBonusAssignment.RecordTypeId = recordTypeId;
                        newBonusAssignment.Territory__c = terrObjId;
                        bonusAssignmentList.add(newBonusAssignment);
                    }
                }
            }
            
            if(Schema.sObjectType.Bonus_Assignment__c.isAccessible() && bonusAssignmentList.size() > 0){
                Database.SaveResult[] lstSaveResult = Database.insert(bonusAssignmentList);
                if (lstSaveResult[0].isSuccess()) {
                    mapMessage.put(EDGE_Constant.EDGE_SUCCESS_STATUS, 'Bonus Assignment created successfully');
                } else {
                    List<Database.Error> dbError = lstSaveResult[0].getErrors();
                    mapMessage.put(EDGE_Constant.EDGE_ERROR_STATUS,dbError[0].getMessage());
                }
            }
        }catch(exception exceptionBA){
            throw new AuraHandledException(exceptionBA.getMessage());
        }
        
        return mapMessage;
    }
    
    @AuraEnabled
    public static Map<String,String> createUserNotification(ID objectId, List<Id> lstPrimaryRepId){
        Map<String,String> mapMessage = new Map<String,String>();
        List<User_Notification__c> userNotificationList = new List<User_Notification__c>();
        Set<Id> primarySaleRepSet = new Set<Id>();
        
        if(lstPrimaryRepId != null && lstPrimaryRepId.size()>0){               
            //remove duplicates if any
            for(Id prid : lstPrimaryRepId){
                primarySaleRepSet.add(prid);    
            }
            for(Id pId :primarySaleRepSet){
            	User_Notification__c userNotification = new  User_Notification__c();
                userNotification.Notification__c = objectId;
                userNotification.User__c = pId;
                userNotification.Status__c = 'Active';
                userNotificationList.add(userNotification);
            }
            
            if(Schema.sObjectType.User_Notification__c.isCreateable() && userNotificationList.size() > 0){
                Database.SaveResult[] lstSaveResult = Database.insert(userNotificationList);
                if (lstSaveResult[0].isSuccess()) {
                    mapMessage.put(EDGE_Constant.EDGE_SUCCESS_STATUS, 'User Notification created successfully');
                } else {
                    List<Database.Error> dbError = lstSaveResult[0].getErrors();
                    mapMessage.put(EDGE_Constant.EDGE_ERROR_STATUS,dbError[0].getMessage());
                }
            }
        }    
        return mapMessage;
    }    
}