/**
 
* @description : EDGE_TerritoryMemberTriggerHelper

* @purpose : The Territory Member have same country as the territory - ES20-261

* @history

* Version   Developer        Date            User Story	          Purpose

*  1.1    Monalisa Halder   22/02/2019      Initial Development  Initial Development
*  1.2    Dinesh Sharma     10/05/2021      ES20-10206           Validation present for Sales Territories has been extended to Quality Territories
*  1.3    Prasanth T        25/05/2021		ES20-10204 		     Validation on user's Business Role and Territory Types for Quality Territories. Added Business Role Country into Country Validation.
*  1.4    Supriya Galinde	7/03/2022		ES20-12212			 Validations for Activation Territory record type in Territory_SFDC_Activation Specialist Enhancements
*/

public with sharing class EDGE_TerritoryMemberTriggerHelper {
    
    final static String QualityRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();     
    final static String SalesRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();     
    final static String ActivationRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId(); 
/**
* @description This methods used to check country of the territory member and user's Business Role country is same  
as the territory country code on inserting Territory Member
* @return void
* @param newItems (List<SObject>)
*/
    public static void checkTerritoryMemberCountryInsert(List<SObject> newItems){
        Set<Id> territoryIdset = new Set<Id>();
        Set<Id> userIdset = new Set<Id>();
        Map<Id, List<String>> userMap = new Map<Id, List<String>>();
        Map<Id, String> userRoleMap = new Map<Id, String>();
        Map<Id, String> territoryMap = new Map<Id, String>();
        Map<Id, String> bRoleAndCountryMap = new Map<Id, String>();
        
        
        for(SObject obj :newItems){
            Territory_Member__c terrMemObj = (Territory_Member__c)obj; 
            territoryIdset.add(terrMemObj.Territory__c);
            userIdset.add(terrMemObj.User__c);
        }
        
        if(Schema.sObjectType.User.isAccessible()) {
            for(User u : [Select Id,Available_Countries__c from User where Id IN:userIdset]){
                if(u.Available_Countries__c != null && u.Available_Countries__c != '' ){
                    userMap.put(u.Id, u.Available_Countries__c.split(';'));
                                        
                }
            }
        }
        //ES20-10204 : start
        if(Schema.sObjectType.User_Business_role__c.isAccessible()) {
            for(User_Business_role__c bR : [Select Id,Business_Role__c,User__c from User_Business_role__c WHERE User__c IN: userIdset]){
                if(bR.Business_Role__c != null){
                	userRoleMap.put(bR.User__c, bR.Business_Role__c);
                }
            }
        }
        
        if(userRoleMap.size() > 0){
            
            List<String> bRoleList = userRoleMap.values();
            for (Business_Role__c bRoleAndCountry: [SELECT Id,Name,Country__c,Country__r.Code__c FROM Business_Role__c WHERE Id IN: bRoleList] ){
                if(bRoleAndCountry.Country__r.Code__c!= null && bRoleAndCountry.Country__r.Code__c != '' ){      
                    bRoleAndCountryMap.put(bRoleAndCountry.id,bRoleAndCountry.Country__r.Code__c);
                }             
            }
        }
        //ES20-10204 : End         
        if(Schema.sObjectType.Territory__c.isAccessible() && territoryIdset.size() > 0) {
            for(Territory__c territory : [SELECT Id,Country__c,Country__r.Code__c FROM Territory__c WHERE Id IN:territoryIdset]){
                territoryMap.put(territory.Id, territory.Country__r.Code__c);                
            }
        }
        
        if(userMap.size()>0 && territoryMap.size()>0){
            for(SObject obj :newItems){
                Territory_Member__c terrMemObj = (Territory_Member__c)obj;
                List<string> usrConList = userMap.get(terrMemObj.User__c);
                string userBrole = userRoleMap.get(terrMemObj.User__c);
                if(usrConList != null){
                    if(!usrConList.contains(territoryMap.get(terrMemObj.Territory__c))){
                        terrMemObj.addError(label.TerritoryMemberCountry);
                    }
                    if(userBrole != null && !usrConList.contains(bRoleAndCountryMap.get(userBrole))){
                        terrMemObj.addError(label.TerritoryMemberBusinessRoleCountryCheck);
                    }
                }
            }
        }
        
    }
/**
* @description This methods used to check the below conditions :
1) One user should be present once as member for a particular territory at a time frame
2) Same Rep will not be marked primary for two territories at same time frame
3) A primary territory ie, type except Auxiliary territory will have only
one primary rep at a time frame
4) Another rep can be added as Primary only after the previous user after the end date 
of the previous primary rep 
* @return void
* @param newItems (List<Territory_Member__c>)
*/
    public static void territoryMemberInsertUpdateCheck(List<Territory_Member__c> newItems){
        set<Id> userset= new set<Id>();
        set<Id> territoryIdset= new set<Id>();
        Map<String,List<Territory_Member__c>> newTerritoryMemberMap = new Map<String,List<Territory_Member__c>>();
        List<Territory_Member__c> terrMemInsertList = new List<Territory_Member__c>();
        List<Territory_Member__c> newTerrMemInsertList = new List<Territory_Member__c>();
        Map<Id,List<Territory_Member__c >> existinguserTerritoryMap = new Map<Id,List<Territory_Member__c >>();
        Map<Id,List<Territory_Member__c >> newUserTerritoryMap = new Map<Id,List<Territory_Member__c >>();
        Map<Id,Territory__c> territoryMap = new Map<id,Territory__c>();
        Set<Id> allRelatedTerritoryId = new Set<Id>();
        //ES204
        Map<Id,String> userBusinessRoleMap = new Map<Id,String>();//User and Business_role Map
        Map<String,List<String>> mapCompareUserRole = new Map<String,List<String>>();
        
        
        Map<string,Edge_Territory_Member_Validation_Check__mdt> terrMemValidationMap = new Map<string,Edge_Territory_Member_Validation_Check__mdt> ();
        
        // Get Metadata for Validation Check ES20-10206
        if(Schema.SObjectType.Edge_Territory_Member_Validation_Check__mdt.isAccessible()){
            for(Edge_Territory_Member_Validation_Check__mdt territoryCheckMtd : [SELECT Territory_Type__c , Duplicate_User_in_Same_Territory__c, Duplicate_User_in_Different_Territory__c, Different_User_in_Same_Territory__c FROM Edge_Territory_Member_Validation_Check__mdt]){
                if(!terrMemValidationMap.containsKey(territoryCheckMtd.Territory_Type__c)){
                    terrMemValidationMap.put(territoryCheckMtd.Territory_Type__c,territoryCheckMtd);
                }
            }
            
           
        }
        
        //ES20-10204 MAP of Custom Metadata for Validation of Quality Territory Member   
        for (Business_Role_to_Quality_Territory_Map__mdt cM_Obj: [SELECT Business_Role__c,TERRITORY_TERRITORY_HIERARCHY_TYPE__c FROM Business_Role_to_Quality_Territory_Map__mdt] ){     
            if(mapCompareUserRole.containskey(cM_Obj.TERRITORY_TERRITORY_HIERARCHY_TYPE__c))
            {  
                mapCompareUserRole.get(cM_Obj.TERRITORY_TERRITORY_HIERARCHY_TYPE__c).add(cM_Obj.Business_Role__c); 
            }
            else{
                mapCompareUserRole.put(cM_Obj.TERRITORY_TERRITORY_HIERARCHY_TYPE__c,new List<string> {cM_Obj.Business_Role__c});
            }
        }
        
        // Get Territory id and User for New Items
        for(Territory_Member__c newMember : newItems){
            userset.add(newMember.User__c);
            territoryIdset.add(newMember.territory__c);
            
        }
        
        //ES20-10204 Extracting Business_Role__c for users // Modification ES20-10660
        if(Schema.sObjectType.User.isAccessible()) {
            for(User_Business_Role__c userBusinessRoleObj : [SELECT id,User__c, Business_Role__c,Business_Role__r.Global_Equivalent__c FROM User_Business_Role__c WHERE user__c IN: userSet ])  {       
                userBusinessRoleMap.put(userBusinessRoleObj.User__c,userBusinessRoleObj.Business_Role__r.Global_Equivalent__c);           
            }
        }
        
        
        if(userset.size() > 0 || territoryIdset.size() > 0 ){
            if(Schema.SObjectType.Territory_Member__c.isAccessible()){
                for(Territory_Member__c existing :[select id , user__c,territory__c , Start_Date__c,End_Date__c,Type__c from Territory_Member__c where 
                                                   user__c=:userset or territory__c=:territoryIdset])
                {
                    allRelatedTerritoryId.add(existing.territory__c);
                    if(existinguserTerritoryMap.get(existing.territory__c )!=null){
                        existinguserTerritoryMap.get(existing.territory__c ).add(existing);
                    }else{
                        existinguserTerritoryMap.put(existing.territory__c , new List<Territory_Member__c> {existing});
                    }       
                }
            }
            
            if(Schema.SObjectType.Territory__c.isAccessible()){
                for(Territory__c terrRec : [select Id, RecordTypeId, RecordType.Name,Territory_Type__c  
                                            from Territory__c where id in :allRelatedTerritoryId or id in:territoryIdset]){
                                                if(!territoryMap.containsKey(terrRec.id)){
                                                    territoryMap.put(terrRec.id, terrRec);
                                                }
                                            }
            }
            
            
            
            // Checking bulk inserts per user
            if(Schema.SObjectType.Territory_Member__c.isAccessible()){
                for(Territory_Member__c newMember : newItems){
                    if(newTerritoryMemberMap.containsKey(newMember.User__c)){
                        List<Territory_Member__c> lstTerritoryMember = newTerritoryMemberMap.get(newMember.User__c);
                        for(Territory_Member__c existingTM : lstTerritoryMember){
                            if(newMember != existingTM){// Updating an existing territory member
                                boolean validateBusinessRole = checkTerritoryMemberBusinessRoleInsert (newMember,mapCompareUserRole,territoryMap,userBusinessRoleMap);
                                boolean isValidate = validateterritoryMember(newMember,existingTM,terrMemValidationMap,territoryMap);  
                                if (isValidate ){
                                    terrMemInsertList.add(newMember) ;
                                    newTerritoryMemberMap.get(newMember.User__c).add(newMember);
                                    
                                }               
                            } 
                        }
                    } else{
                        //Inserting new territory member records
                        newTerritoryMemberMap.put(newMember.User__c,new List<Territory_Member__c>{newMember}); 
                        terrMemInsertList.add(newMember) ;
						boolean validateBusinessRole = checkTerritoryMemberBusinessRoleInsert (newMember,mapCompareUserRole,territoryMap,userBusinessRoleMap);
                    }
                }
                
                
                // Checking bulk inserts per territory
                for(Territory_Member__c newMember : newItems){
                    if(newUserTerritoryMap.containsKey(newMember.Territory__c)){
                        List<Territory_Member__c> newTerrMemList = newUserTerritoryMap.get(newMember.Territory__c);
                        for(Territory_Member__c existingTM : newTerrMemList){
                            if(newMember != existingTM){
                                // Updating an existing territory member
                                boolean validateBusinessRole = checkTerritoryMemberBusinessRoleInsert (newMember,mapCompareUserRole,territoryMap,userBusinessRoleMap);
                                boolean isValidate = validateterritoryMember(newMember,existingTM,terrMemValidationMap,territoryMap);  
                                if (isValidate ){
                                    newTerrMemInsertList.add(newMember) ;
                                    newUserTerritoryMap.get(newMember.Territory__c).add(newMember);                                
                                }               
                            } 
                        }
                    } else{
                        //Inserting new territory member records
                        newUserTerritoryMap.put(newMember.Territory__c,new List<Territory_Member__c>{newMember}); 
                        newTerrMemInsertList.add(newMember) ;
						boolean validateBusinessRole = checkTerritoryMemberBusinessRoleInsert (newMember,mapCompareUserRole,territoryMap,userBusinessRoleMap);
                        
                        
                    }
                }      
                
                for(Territory_Member__c newMember :terrMemInsertList ){    
                    for(Id territoryId : existinguserTerritoryMap.keyset()){
                        for(Territory_Member__c existingTM : existinguserTerritoryMap.get(territoryId)){
                            checkTerritoryMemberBusinessRoleInsert(newMember,mapCompareUserRole,territoryMap,userBusinessRoleMap);
                            validateterritoryMember(newMember,existingTM,terrMemValidationMap,territoryMap);
                            
                        }
                    }
                }
            }
        }
    }
    
    /*******************************************************************
Method  : validateterritoryMembero
Purpose : This method is used to write the validations, so that it can be reused
for both bulk load and single record creation
***********************************************************************/     
    public static boolean validateterritoryMember(Territory_Member__c newMember,Territory_Member__c existingTM,Map<string,Edge_Territory_Member_Validation_Check__mdt> terrMemValidationMap,Map<Id,Territory__c> territoryMap ){
        

        boolean isValidate = false;
        if (existingTM.End_Date__c==null ||
            ((newMember.start_date__c>=existingTM.Start_Date__c && newMember.Start_Date__c <= existingTM.End_Date__c)
             || (newMember.End_Date__c >= existingTM.Start_Date__c && newMember.End_Date__c <= existingTM.End_Date__c))){
                 
                
                 if(existingTM.territory__c==newMember.territory__c && newMember.user__c==existingTM.user__c  
                    && ((newMember.id!=null && newMember.id!=existingTM.id) || newMember.id==null) ) 
                 {
                     
                     if((territoryMap.get(newMember.Territory__c).RecordTypeId == SalesRecordTypeId && terrMemValidationMap.get(territoryMap.get(newMember.Territory__c).RecordType.Name).Duplicate_User_in_Same_Territory__c == true)
                        || (territoryMap.get(newMember.Territory__c).RecordTypeId  == QualityRecordTypeId && terrMemValidationMap.get(territoryMap.get(newMember.Territory__c).RecordType.Name).Duplicate_User_in_Same_Territory__c == true)
                        || (territoryMap.get(newMember.Territory__c).RecordTypeId  == ActivationRecordTypeId && terrMemValidationMap.get(territoryMap.get(newMember.Territory__c).RecordType.Name).Duplicate_User_in_Same_Territory__c == true))
                         
                         
                     {
                         newMember.addError(label.DuplicateUserInSameTerritory);
                     }
                 }
                 else if( existingTM.territory__c!=newMember.territory__c && newMember.type__c=='Primary' && existingTM.type__c=='Primary' 
                         && newMember.user__c==existingTM.user__c )
                 {
                     
                     if((territoryMap.get(newMember.Territory__c).RecordTypeId  == SalesRecordTypeId  && terrMemValidationMap.get(territoryMap.get(newMember.Territory__c).RecordType.Name).Duplicate_User_in_Different_Territory__c == true)
                        || (territoryMap.get(newMember.Territory__c).RecordTypeId  == QualityRecordTypeId &&  terrMemValidationMap.get(territoryMap.get(newMember.Territory__c).RecordType.Name).Duplicate_User_in_Different_Territory__c == true/*terrMemValidationMap.get(Schema.SObjectType.Territory__c.getRecordTypeInfosById().get(territoryMap.get(newMember.Territory__c).RecordTypeId).getname()).Duplicate_User_in_Different_Territory__c == true*/ )
                        ||(territoryMap.get(newMember.Territory__c).RecordTypeId  == ActivationRecordTypeId  && terrMemValidationMap.get(territoryMap.get(newMember.Territory__c).RecordType.Name).Duplicate_User_in_Different_Territory__c == true))
                     {
                         newMember.addError(label.SameUserDuplicatePrimaryMember);
                     }
                 }
                 else if(existingTM.territory__c==newMember.territory__c && newMember.type__c=='Primary' && existingTM.type__c=='Primary' 
                         && newMember.user__c!=existingTM.user__c  )
                 { 
                     
                     if((territoryMap.get(newMember.Territory__c).RecordTypeId  == SalesRecordTypeId && terrMemValidationMap.get(territoryMap.get(newMember.Territory__c).RecordType.Name).Different_User_in_Same_Territory__c == true)
                        || (territoryMap.get(newMember.Territory__c).RecordTypeId  == QualityRecordTypeId && terrMemValidationMap.get(territoryMap.get(newMember.Territory__c).RecordType.Name).Different_User_in_Same_Territory__c == true )
                        ||(territoryMap.get(newMember.Territory__c).RecordTypeId  == ActivationRecordTypeId  && terrMemValidationMap.get(territoryMap.get(newMember.Territory__c).RecordType.Name).Different_User_in_Same_Territory__c == true))
                     {
                         newMember.addError(label.DuplicatePrimaryMember);
                     }
                 }
                 else{
                     isValidate = true;
                 }
             }else{
                 isValidate = true;
             }
        
        
        return isValidate;
    }
  
/*******************************************************************
Method  : checkTerritoryMemberBusinessRoleInsert
Purpose : This method is used to compare Quality business role and territory type metadata with the new Quality territory member, whose Business role and Territory Type
of Quality territory should match with the custom metadata on inserting Qualtiy Territory Member
***********************************************************************/
    public static Boolean checkTerritoryMemberBusinessRoleInsert(Territory_Member__c newMember , Map<String,List<String>> mapCompareUserRole, Map<Id,Territory__c> territoryMap, Map<Id,String> userBusinessRoleMap){
        
        Boolean validateBusinessRole = false;
        Id territoryId = newMember.Territory__c;
        Id userId = newMember.User__c;
        String terrType = '';
        if(territoryMap.get(territoryId) != null){
            
            terrType = territoryMap.get(territoryId).Territory_Type__c ;
            String businessRole = userBusinessRoleMap.get(userId);    
            
            if (territoryMap.get(territoryId).RecordTypeId == QualityRecordTypeId){//for Quality type of Territory
                if(businessRole != null && mapCompareUserRole.get(terrType) != null 
                   	&& !mapCompareUserRole.get(terrType).contains(businessRole)){
                    newMember.adderror(label.EDGE_QualtiyUserBusinessRoleError);
                }
                else{
                    validateBusinessRole = true;
                }
            }else if(territoryMap.get(territoryId).RecordTypeId == SalesRecordTypeId){
                //for Sales type of Territory we will not allow Quality Reps to be added to it 
                for (List<String> meObj  : mapCompareUserRole.values()){
                    if(meObj.contains(businessRole)){
                        newMember.adderror(label.EDGE_SalesUserBusinessRoleError);
                    }
                }
            }else if(territoryMap.get(territoryId).RecordTypeId == ActivationRecordTypeId){
                //for Activation type of Territory we will not allow Quality, Sales Reps to be added to it - ES20-12212
                for (List<String> meObj  : mapCompareUserRole.values()){
                    if(meObj.contains(businessRole)){
                        newMember.adderror(label.EDGE_ActivationUserBusinessRoleError);
                    }
                }
            }
        }
                
        return validateBusinessRole;   
    }
}