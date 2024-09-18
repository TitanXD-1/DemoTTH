/*
* @name: D1_GeographySharing
* @discription: This class is used to create Public Group for Country Geography
* @history                                                            
*                                                             
* VERSION     AUTHOR            DATE              DETAIL
* 1.0   	  Saurav Paul       21/11/2020       NCP-1262 Initial Development
* 2.0         Narayana          14/04/2022       NCP-6401
* */
public class D1_GeographySharing {
    
    //This method is used to create public Group
    public static void createGroup(Map<Id, SObject> newItems, Map<Id, SObject> oldItems, Boolean isNew){
        Id contryRecTypId = Schema.SObjectType.Geography__c.getRecordTypeInfosByName().get('Country').getRecordTypeId();
        Map<Id,Geography__c> mapOldGeography;
        List<Group> grpLst = new List<Group>();
        Map<Id,Geography__c> d1CountryGeoMap = new Map<Id,Geography__c>();
        Set<String> allGroupNames = new Set<String>();//NCP-6401
        Set<String> existingGroupNames = new Set<String>();//NCP-6401
        if(oldItems != null && !oldItems.isEmpty()){
            mapOldGeography = (Map<Id,Geography__c>)oldItems;                                 
        }
        for(Id idVal : newItems.keySet()){
            Geography__c newGeography = (Geography__c)newItems.get(idVal);
            allGroupNames.add(newGeography.D1_Internal_Group_Name__c);//NCP-6401
            allGroupNames.add(newGeography.D1_External_Group_Name__c);//NCP-6401
        }
        List<Group> grpList = [SELECT Id,Name FROM Group WHERE Name IN :allGroupNames];//store the groups which already exist in system NCP-6401
        for(Group grpRec : grpList){
            existingGroupNames.add(grpRec.Name);//store the group names for further use
        }
        for(Id idVal : newItems.keySet()){
            Geography__c newGeography = (Geography__c)newItems.get(idVal);
            if(newGeography.RecordTypeId.equals(contryRecTypId) &&
               ((isNew && newGeography.isDiageoOneEnabled__c)||
                (!isNew && newGeography.isDiageoOneEnabled__c && mapOldGeography!= null
                 && mapOldGeography.containskey(newGeography.Id)
                 && mapOldGeography.get(newGeography.Id).isDiageoOneEnabled__c!= newGeography.isDiageoOneEnabled__c
                )))
            {
                if(!existingGroupNames.contains(newGeography.D1_External_Group_Name__c)){
                    d1CountryGeoMap.put(idVal,newGeography);
                    Group grpObj = new Group();
                    grpObj.Name = newGeography.D1_External_Group_Name__c;
                    grpObj.DeveloperName = newGeography.D1_External_Group_Name__c;
                    grpLst.add(grpObj);
                }
                if(!existingGroupNames.contains(newGeography.D1_Internal_Group_Name__c)){
                    Group grpInternal = new Group();//NCP-6401
                    grpInternal.Name = newGeography.D1_Internal_Group_Name__c;
                    grpInternal.DeveloperName = newGeography.D1_Internal_Group_Name__c;//NCP-6401
                    grpLst.add(grpInternal);
                }               
            }
        }
        if(!grpLst.isEmpty()){
            insert grpLst;
            if(d1CountryGeoMap!= null && !d1CountryGeoMap.isEmpty()){
                D1_SharingUtil.shareGeography(d1CountryGeoMap);
            }
        }
    }   
}