/**********************************************************************
Name: EDGE_SearchTerritoryForBHTest
=======================================================================
Req: 
ES20-5027
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0                       
***********************************************************************/
@isTest
public class EDGE_SearchTerritoryForBHTest {
    @isTest
    public static void searchTerritoryDetails(){
        List<Id> terrListId = new List<Id>();
        
        String queryString=null;
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(countryId != null); 
        
        //Creating Sales Manager
        User salesManager=EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;
        System.assert(salesManager.Id!=null);
        //Creating Sales Rep 
        User salesRep= EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.Id;
        insert salesRep;
        System.assert(salesRep.Id!=null);
        List<Id> salesRepId = new List<Id>();
        salesRepId.add(salesRep.Id);
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        
        //Insert Pick_Up_Options__c
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Survey KPI');
        pickupOption.Name = 'Gold[AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        //Insert Territory_Hierarchy__c
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
        
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;
        
        Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHier.Parent_BU__c = terriHierSA.Id;
        terriHier.Pending_For_Batch__c = false;
        insert terriHier;
        system.assert(terriHier!=null);
        test.startTest();
        //Insert Territory__c
        Territory__c terr= EDGE_UtilityTestClass.getTerritoryRec();
        terr.Territory_Type__c = 'Sales';
        terr.Region__c = terriHier.Id;
        terr.Country__c = countryId;
        terr.Pending_For_Batch__c = false;
        insert terr;
        Territory__c terr1= EDGE_UtilityTestClass.getTerritoryRec();
        terr1.Territory_Type__c = 'Sales';
        terr1.Country__c = countryId;
        terr1.Region__c = terriHier.Id; 
        terr1.Pending_For_Batch__c = false;
        insert terr1;
        terrListId.add(terr.Id);
        terrListId.add(terr1.Id);
        
        
        /* Bonus_Detail__c bonDetailRecordTYpe =Bonus_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Survey').getRecordTypeId();
Bonus_Detail__c bonusDetail =new Bonus_Detail__c();
insert bonusDetail;*/
        
        Bonus_Header__c bonusHeader = new Bonus_Header__c();
        bonusHeader.Country__c = countryId;
        insert bonusHeader;
        
        String surveyRecordtype = Bonus_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Survey').getRecordTypeId();
        Bonus_detail__c bonDet = new Bonus_detail__c();
        bonDet.Bonus_Header__c = bonusHeader.Id;
        bonDet.RecordTypeId = surveyRecordtype;
        bonDet.KPI_Type__c = 'Survey';
        bonDet.Weight__c = 15;
        insert bonDet;
        
        //Inserting Notification
        Notification__c notification = new Notification__c();
        notification.Priority__c = 'Medium';
        notification.Country__c = countryId;
        notification.Start_Date__c = Date.newInstance(2020,03,24);
        notification.End_Date__c = Date.newInstance(2020,04,24);
        notification.Status__c = 'Active';
        notification.Short_Description__c = 'XYZ';
        insert notification;
        
        //Inserting User Notification
        User_Notification__c userNotification = new User_Notification__c();
        userNotification.Status__c = 'Active';
        userNotification.User__c = salesRep.Id;
        userNotification.IsRead__c = true;
        userNotification.Notification__c = notification.Id;
        insert userNotification;    
        
        //calling the methods
        queryString= ' AND Pending_For_Batch__c = false';
        EDGE_SearchTerritoryForBH.searchTerritoryDetails(queryString, bonusHeader.Id, 'Territory_Hierarchy__c');
        EDGE_SearchTerritoryForBH.searchTerritoryDetails(queryString, bonDet.Id, 'Territory_Hierarchy__c');
        EDGE_SearchTerritoryForBH.searchTerritoryDetails(queryString, bonDet.Id, 'Territory__c');
        EDGE_SearchTerritoryForBH.searchTerritoryDetails(queryString, bonusHeader.Id, 'Territory__c');
        EDGE_SearchTerritoryForBH.insertBonusAssignment(bonusHeader.Id, terrListId);
        EDGE_SearchTerritoryForBH.insertBonusAssignment(bonDet.Id, terrListId);
        EDGE_SearchTerritoryForBH.getBonusHeaderDetails(bonusHeader.Id);
        EDGE_SearchTerritoryForBH.getBonusHeaderDetails(bonDet.Id);
        EDGE_SearchTerritoryForBH.createUserNotification(notification.Id, salesRepId);
        
        test.stopTest();
        
        
        
    }
}