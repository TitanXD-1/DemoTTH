/**

* @description : EDGE_TerritoryHierarchyMemberHelper

* @purpose : To Implement TerritoryHierarchyMemberHandler - ES20-3184

* @history

* Version   Developer        Date            User Story/Purpose

*  1.1    Shahbaz Khan       25/07/2019      Initial Development
*  1.2    Dinesh Sharma      04/06/2021      checkTerritoryHierarchyMemberBusinessRole(ES20-10205),territoryHierarchyCountryCheck(ES20-10205)(ES20-10208)
*  1.3    Sudipta Nandi      20/07/2021      checkTerritoryHierarchyMemberBusinessRole(ES20-10660),territoryHierarchyCountryCheck(ES20-10660)
*  1.4    Supriya Galinde    20/12/2021		 checkOverlappingTerritoryHierarchyMember(ES20-10996)
*  1.5	  Swaraj Samanta	 07/03/2022	 	 Removal of validation for Heirarchy(ES20-12265)

*/

public with sharing class EDGE_TerritoryHierarchyMemberHelper {
    
    final static String QualityHierarchyRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory Hierarchy').getRecordTypeId();
    final static String ActivationHierarchyRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();         
    final static String RegionHierarchyRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Region').getRecordTypeId();     
    
    
    /**

* @description : checkOverlappingTerritoryHierarchyMember - This method is used to check there is No Overlapping territory Hierarchy Member.

* @return : void

* @param : List<Territory_Hierarchy_Member__c>

*/
    public static void checkOverlappingTerritoryHierarchyMember(List<Territory_Hierarchy_Member__c> newItems){
        
        Set<Id> territoryHierarchyIdset = new Set<Id>();
        Set<Id> territoryHierarchyMemberId = new Set<Id>();
        Set<Id> businessRoleId = new Set<Id>();
        Map<Id,Id> businessRoleCountryIdMap = new Map<Id,Id> ();
        Map<Id, String> businessRoleCountryMap = new Map<Id, String>();
        Map<Id,Territory_Hierarchy__c> territoryHierarchyTypeMap = new Map<Id,Territory_Hierarchy__c>();
        Map<Id,String> userBusinessRole = new Map<Id,String>();
        Map<Id,String> userGloablEquivalentRole = new Map<Id,String>();// Modification for ES20-10660
        Map<String,List<String>> mapCompareUserRole = new Map<String,List<String>>();
        Map<Id,List<Territory_Hierarchy_Member__c >> existingTerritoryHierarchyMap = new Map<Id,List<Territory_Hierarchy_Member__c >>();
        Map<string,Edge_Territory_Member_Validation_Check__mdt> terrHierarchyMemberValidationMap = new Map<string,Edge_Territory_Member_Validation_Check__mdt> ();
        Set<Id> allRelatedTerritoryHierarchyId = new Set<Id>();
        
        // Get Metadata for Validation Check ES20-10208
        if(Schema.SObjectType.Edge_Territory_Member_Validation_Check__mdt.isAccessible()){
            for(Edge_Territory_Member_Validation_Check__mdt territoryHierarchyCheckMtd : [SELECT Territory_Hierarchy_Type__c ,Restrict_Duplicate_Users_In_Different_TH__c, Restrict_Users_Replacing_Active_In_TH__c, Restrict_Users_Using_Time_Frame_In_TH__c FROM Edge_Territory_Member_Validation_Check__mdt]){
                if(!terrHierarchyMemberValidationMap.containsKey(territoryHierarchyCheckMtd.Territory_Hierarchy_Type__c)){
                    terrHierarchyMemberValidationMap.put(territoryHierarchyCheckMtd.Territory_Hierarchy_Type__c,territoryHierarchyCheckMtd);

                }
            } 
         
        } 
        
        for(Territory_Hierarchy_Member__c newMember :newItems ){
            territoryHierarchyIdset.add(newMember.Territory_Hierarchy__c);
            territoryHierarchyMemberId.add(newMember.User__c);
        }
        
        if(Schema.SObjectType.Territory_Hierarchy_Member__c.isAccessible() && Schema.SObjectType.Territory_Hierarchy__c.isAccessible() && Schema.SObjectType.User.isAccessible()){
            List<Territory_Hierarchy_Member__c> existingmember =[select id , user__c,Territory_Hierarchy__c , Start_Date__c,End_Date__c,Status__c from Territory_Hierarchy_Member__c where 
                                                                 Territory_Hierarchy__c=:territoryHierarchyIdset or user__c=:territoryHierarchyMemberId]; 
            for(Territory_Hierarchy_Member__c existing :existingmember ){
                allRelatedTerritoryHierarchyId.add(existing.Territory_Hierarchy__c);
                if(existingTerritoryHierarchyMap.get(existing.Territory_Hierarchy__c )!=null){
                    
                    existingTerritoryHierarchyMap.get(existing.Territory_Hierarchy__c ).add(existing);
                }
                else{
                    existingTerritoryHierarchyMap.put(existing.Territory_Hierarchy__c , new List<Territory_Hierarchy_Member__c> {existing});
                }       
            }
        }
        
        //get Map for Territory Hierarchy Id and Territory Hierarchy record ES20-10205
        if(Schema.sObjectType.Territory_Hierarchy__c.isAccessible()){
            for(Territory_Hierarchy__c terrHier : [Select Id, Name, Territory_Hierarchy_Type__c,Geography__c,RecordTypeId, RecordType.Name from Territory_Hierarchy__c where id in:territoryHierarchyIdset or id in :allRelatedTerritoryHierarchyId]){ 
                if(terrHier.RecordTypeId == QualityHierarchyRecordTypeId ||terrHier.RecordTypeId == RegionHierarchyRecordTypeId || terrHier.RecordTypeId == ActivationHierarchyRecordTypeId  ){
                    
                    if(!territoryHierarchyTypeMap.containsKey(terrHier.Id)){
                        territoryHierarchyTypeMap.put(terrHier.Id,terrHier);
                    }
                }
            }
        }  
         
        //get Map for User and User Business Role ES20-10205 // Modification for ES20-10660
        if(Schema.sObjectType.User_Business_role__c.isAccessible() && territoryHierarchyMemberId.size() > 0) {
            
            for(User_Business_role__c userRole : [Select Id,Business_Role__c,User__c,Business_Role__r.Global_Equivalent__c from User_Business_role__c WHERE User__c IN :territoryHierarchyMemberId]){
                businessRoleId.add(userRole.Business_Role__c);
                if(userRole.Business_Role__c != null){
                    
                    if(!userBusinessRole.containsKey(userRole.User__c)){
                        
                        userGloablEquivalentRole.put(userRole.User__c, userRole.Business_Role__r.Global_Equivalent__c);
                        userBusinessRole.put(userRole.User__c, userRole.Business_Role__c);
                        
                    }
                }
            }
        }
        
        //get Map for User and Business Role ES20-10205
        if(Schema.sObjectType.Business_role__c.isAccessible() && businessRoleId.size() >0) {
            for(Business_role__c businessRole : [Select Id,Country__c from Business_role__c WHERE Id IN :businessRoleId]){
                
                if(!businessRoleCountryIdMap.containsKey(businessRole.id)){
                    businessRoleCountryIdMap.put(businessRole.id,businessRole.Country__c);
                    
                }
            }
        }
        
        //get MAP of Custom Metadata for Validation of Quality Territory Hierarchy Member ES20-10205
        if(Schema.sObjectType.Business_Role_to_Quality_Territory_Map__mdt.isAccessible()) { 
            
            for (Business_Role_to_Quality_Territory_Map__mdt cM_Obj: [SELECT Business_Role__c,TERRITORY_TERRITORY_HIERARCHY_TYPE__c FROM Business_Role_to_Quality_Territory_Map__mdt] ){     
                
                if(mapCompareUserRole.containskey(cM_Obj.TERRITORY_TERRITORY_HIERARCHY_TYPE__c)){
                    mapCompareUserRole.get(cM_Obj.TERRITORY_TERRITORY_HIERARCHY_TYPE__c).add(cM_Obj.Business_Role__c); 
                
                }  else{
                    mapCompareUserRole.put(cM_Obj.TERRITORY_TERRITORY_HIERARCHY_TYPE__c,new List<string> {cM_Obj.Business_Role__c});
                
                }
            }
        }     
        for(Territory_Hierarchy_Member__c newMember :newItems ){
            //ES20-10205 Business Role and country check  // Modification for ES20-10660
            boolean toValidate =  checkTerritoryHierarchyMemberBusinessRole(newMember,territoryHierarchyTypeMap,mapCompareUserRole,userBusinessRole,businessRoleCountryIdMap,userGloablEquivalentRole);
          
            if(toValidate){
                
                String terriHierarchyRecTypeId = territoryHierarchyTypeMap.get(newMember.Territory_Hierarchy__c).RecordTypeId;
                
                for(Id territoryHierarchyId : existingTerritoryHierarchyMap.keyset()){
                    
                    for(Territory_Hierarchy_Member__c existingTM : existingTerritoryHierarchyMap.get(territoryHierarchyId)){
                        
                        if (existingTM.End_Date__c==null ||
                             
                              ((existingTM.Status__c== 'Active' && newMember.start_date__c>=existingTM.Start_Date__c && newMember.Start_Date__c <= existingTM.End_Date__c)
                             || (existingTM.Status__c== 'Active' && newMember.End_Date__c >= existingTM.Start_Date__c && newMember.End_Date__c <= existingTM.End_Date__c))){
                               
                                 if(existingTM.territory_Hierarchy__c==newMember.territory_Hierarchy__c && ((newMember.id!=null && newMember.id!=existingTM.id) || newMember.id==null) &&  territoryHierarchyTypeMap.get(newMember.Territory_Hierarchy__c) != null) {
                                     
                                     //ES20-10208 Metadata check for Validation - New Member added into Already present Member time frame in Same Terr. Hierarchy Validation
                                     Boolean isRestrictUserinsameTerriHierar = terrHierarchyMemberValidationMap.get(territoryHierarchyTypeMap.get(newMember.Territory_Hierarchy__c).RecordType.Name).Restrict_Users_Using_Time_Frame_In_TH__c;
                                   
                                     if((terriHierarchyRecTypeId  == QualityHierarchyRecordTypeId  && isRestrictUserinsameTerriHierar )|| (terriHierarchyRecTypeId  == ActivationHierarchyRecordTypeId &&  isRestrictUserinsameTerriHierar)|| (terriHierarchyRecTypeId  == RegionHierarchyRecordTypeId &&  isRestrictUserinsameTerriHierar)){
                                         newMember.addError(label.Start_and_End_Date_are_Overlapping);
                                     }
                                 }
                                 
                                 else if( (existingTM.Status__c== 'Active' && existingTM.End_Date__c!=null && newMember.Start_Date__c <= existingTM.End_Date__c ) || (existingTM.End_Date__c== null)){
                                     if(existingTM.territory_Hierarchy__c!=newMember.territory_Hierarchy__c && ((newMember.id!=null && newMember.id==existingTM.id) || newMember.id==null) &&  territoryHierarchyTypeMap.get(newMember.Territory_Hierarchy__c) != null) {
                                         
                                         //ES20-10208 Metadata check for Validation - New Member added to Different Terr. Hierarchy but the member is already assigned for same time frame Validation
                                         Boolean isRestrictUserinDiffTerriHierar = terrHierarchyMemberValidationMap.get(territoryHierarchyTypeMap.get(newMember.Territory_Hierarchy__c).RecordType.Name).Restrict_Duplicate_Users_In_Different_TH__c;
                                     	// Removal of validation for Heirarchy(ES20-12265) - Removed RegionRecordTypeId check
                                         if((terriHierarchyRecTypeId  == QualityHierarchyRecordTypeId  && isRestrictUserinDiffTerriHierar)|| (terriHierarchyRecTypeId  == ActivationHierarchyRecordTypeId &&  isRestrictUserinDiffTerriHierar)){
                                             // ES20-10209 Same User different Territory check
                                             newMember.addError(label.EDGE_Territory_Hierarchy_Duplicate_User_Check);
                                         }
                                     }  
                                 }
                             }
                    }
                } 
            }
        }
    }
    
    /**

* @description : checkTerritoryHierarchyMemberBusinessRole - The method allows only particular business Role user to be added as Territory Hierarchy Member for particular type of Quality Territory Hierarchy.

* @return : boolean

* @param : Territory_Hierarchy_Member__c, Map<Id,Territory_Hierarchy__c>, Map<String,List<String>>, Map<Id,String>, Map<Id,Id>, Map<Id,String>

*/
    
    public static boolean checkTerritoryHierarchyMemberBusinessRole(Territory_Hierarchy_Member__c newMember,Map<Id,Territory_Hierarchy__c> territoryHierarchyTypeMap, Map<String,List<String>> mapCompareUserRole,Map<Id,String> userBusinessRole,Map<Id,Id> businessRoleCountryIdMap,Map<Id,String> userGloablEquivalentRole){
        
        Boolean toValidate = false;
        
        //allow particular business role user to be added to particular Territory type ES20-10205
        if((territoryHierarchyTypeMap != null && territoryHierarchyTypeMap.size() > 0) 
           && (mapCompareUserRole != null && mapCompareUserRole.size() > 0 ) 
           && (userBusinessRole != null && userBusinessRole.size() > 0) 
           && (userGloablEquivalentRole != null && userGloablEquivalentRole.size() > 0)
           && (businessRoleCountryIdMap != null && businessRoleCountryIdMap.size() > 0)
           && territoryHierarchyTypeMap.get(newMember.Territory_Hierarchy__c) != null)
        {
            
            String terrHierarchyType = territoryHierarchyTypeMap.get(newMember.Territory_Hierarchy__c).Territory_Hierarchy_Type__c;
            
            if(territoryHierarchyTypeMap.get(newMember.Territory_Hierarchy__c).RecordTypeId == QualityHierarchyRecordTypeId && terrHierarchyType != null){
                list<String> terrTypeBusinessRoleList = mapCompareUserRole.get(terrHierarchyType);
               
                String userRole = userGloablEquivalentRole.get(newMember.User__c);
                if(terrTypeBusinessRoleList != null && !terrTypeBusinessRoleList.contains(userRole)){
                    newMember.addError(label.EDGE_Territory_Hierarchy_Type_Business_Role_Check);
                }else{
                    toValidate = true;  // if  business role check is passed set the value to true
                }
            } else{
                toValidate = true; // if Territory Hierarchy record type in not of Quality
            }
            if(toValidate){
                boolean  toValidateCountry =  checkterritoryHierarchyCountry(newMember,territoryHierarchyTypeMap,businessRoleCountryIdMap,userBusinessRole);
                toValidate = toValidateCountry;
                
            }
        }
        return toValidate;
        
    }
    
    /**

* @description : checkterritoryHierarchyCountry - This Method check if the Territory Hierarchy Member business Role has the Same country as that of the Territory Hierarchy record.

* @return : boolean

* @param : Territory_Hierarchy_Member__c, Map<Id,Territory_Hierarchy__c>, Map<Id,Id>, Map<Id,String>

*/
    
    public static boolean checkterritoryHierarchyCountry(Territory_Hierarchy_Member__c newMember, Map<Id,Territory_Hierarchy__c> territoryHierarchyTypeMap,Map<Id,Id> businessRoleCountryIdMap,Map<Id,String> userBusinessRole){
        
        Boolean toValidateCountry = false;
        
        if((territoryHierarchyTypeMap != null && territoryHierarchyTypeMap.size() > 0)  
           && (userBusinessRole != null && userBusinessRole.size() > 0) 
           && (businessRoleCountryIdMap != null && businessRoleCountryIdMap.size() > 0)
           && territoryHierarchyTypeMap.get(newMember.Territory_Hierarchy__c) != null){
               
               String  terrHieRecTypeId = territoryHierarchyTypeMap.get(newMember.Territory_Hierarchy__c).RecordTypeId;
               
               if(terrHieRecTypeId == QualityHierarchyRecordTypeId || terrHieRecTypeId == RegionHierarchyRecordTypeId || terrHieRecTypeId == ActivationHierarchyRecordTypeId ){
                   if(territoryHierarchyTypeMap.get(newMember.Territory_Hierarchy__c).Geography__c != businessRoleCountryIdMap.get(userBusinessRole.get(newMember.User__c)) ){
                       newMember.addError(label.EDGE_Territory_Hierarchy_Country_Check);
                   }else{
                       toValidateCountry = true; // if country check is passed set the value to true
                       
                   }
               }else{
                   toValidateCountry = true;
                   
               }
           }
        
        return toValidateCountry;
    }
}