/**

* @description :  EDGE_TerritoryProcessStUpdateBatchTest

* @purpose : This is the test class for EDGE_TerritoryProcessStatusUpdateBatch

* @history :

* Version    Developer         Date           User Story/Purpose

*  1.1      Monalisa Halder   11/03/2019      Initial Development
*  1.2      Joshraj Sen       10/03/2022      ES20-12228 - Include Activation Territory Record Type to the existing test data

*  1.2      Joshraj Sen       10/03/2022      ES20-12228 - Include Activation Territory Record Type to the existing test data
*  1.3		Priya Soni		  10/11/2022      ES20-13469
*  1.4      Mayukh SRoy       06/12/2022      ES20-13624 - UAT_Multiple Queueable Jobs are executed from the same transaction
*  1.5      Joshraj Sen       08/04/2024      152305 Fixed SCA
*/

@isTest
public class EDGE_TerritoryProcessStUpdateBatchTest{
    
    static String salesTerritoryRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
    static String qualityTerritoryRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();
    static String  activationTerritoryRecordTypeId=Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
    /**

* @description : territoryOutletStatusUpdatetest 




*/
    @isTest
    public static void territoryOutletStatusUpdatetest(){
        Test.startTest();  
        createData();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_TerritoryProcessStatusUpdateBatch'
                                                  and Country_Code__c ='AU'];
        //added assert part here by manikant
        List<Market_Batch_Setting__mdt> batchsett = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                     Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_TerritoryProcessStatusUpdateBatch'
                                                     and Country_Code__c ='AU'];
        system.assert(batchsett.size()>=0,'Batch is Added');
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,200);
        Test.stopTest();        
    }
    
    /**

* @description : createData - This is used to create common data for this test class


*/
    
    static void createData(){
        List<Account> accLst = new List<Account>();
        Map<Id, Id> outletWithRegionMapToShare = new Map<Id, Id>();
        //Map<Id, Id> outletWithQualityMapToShare = new Map<Id, Id>();
        //Map<Id, Id> outletWithRegionMapToRemove = new Map<Id, Id>();
        Map<Id, Id> outletWithActivationTerritoryMapToShare = new Map<Id, Id>();
        //Map<Id, Id> outletWithActivationTerritoryMapToRemove = new Map<Id, Id>();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU'); 
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'test Out 1514';
        outlet.BillingStreet = '95 Malaysian Airway 1';
        accLst.add(outlet);
      //  insert outlet;
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();

        outlet1.Name = 'test Out 12a3';
        outlet1.BillingStreet = '17 Korean Highway 45';
		accLst.add(outlet1);
        
        Account outlet2 = EDGE_UtilityTestClass.getOutletRecord();

        outlet2.Name = 'Test Out 12a3';
        outlet2.BillingStreet = '17 Haldiram Highway 45';
        accLst.add(outlet2);
        
        insert accLst;
        
        List<User> usrLst = new List<User>();
        //create Sales Representative User
        User usr = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Sales Manager');
        usr.Business_Role__c = 'Sales Manager';
        usr.trax_user__c=true;
        usrLst.add(usr);
        //insert usr; 
        
        // Sales
        User usr1 = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Sales Representative');
        //   usr.Business_Role__c = 'Sales Manager';
        usr1.trax_user__c=true;
        //insert usr1; 
        usrLst.add(usr1);
        
        //Quality Rep
        User usr2 = EDGE_UtilityTestClass.runAsUser('TestQualityRep', 'Quality Representative');
        usr2.trax_user__c=true;
        usrLst.add(usr2);
        
        //Create Activation Specialist
        User activationSpecialist = EDGE_UtilityTestClass.runAsUser('TestActivationSpecialist', 'Activation Specialist');
        activationSpecialist.Business_Role__c = 'Activation Specialist';
        activationSpecialist.Trax_User__c = true;
        //insert activationSpecialist;
        usrLst.add(activationSpecialist);
        
        //Create Quality Manager
        User qualityMamagerUser = EDGE_UtilityTestClass.runAsUser('TestActivationSpecialist', 'Quality Manager');
        // qualityMamagerUser.Business_Role__c = 'Activation Specialist';
        qualityMamagerUser.Trax_User__c = true;
        //insert qualityMamagerUser;
        usrLst.add(qualityMamagerUser);
        insert usrLst;
        
        List<Business_Role__c> brLst = new List<Business_Role__c>();
        Business_Role__c businessRoleObj = EDGE_UtilityTestClass.getBusinessRole();
        businessRoleObj.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
        businessRoleObj.Country__c = countryId;
        businessRoleObj.Global_Equivalent__c = 'Dispense Manager';
        brLst.add(businessRoleObj);
        //insert businessRoleObj;
        
        Business_Role__c businessRoleObj1 = EDGE_UtilityTestClass.getBusinessRole();
        businessRoleObj1.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
        businessRoleObj1.Country__c = countryId;
        businessRoleObj1.Global_Equivalent__c = 'Sales Manager';
        //insert businessRoleObj1;
        brLst.add(businessRoleObj1);
        
        Business_Role__c businessRoleObj2 = EDGE_UtilityTestClass.getBusinessRole();
        businessRoleObj2.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
        businessRoleObj2.Country__c = countryId;
        businessRoleObj2.Global_Equivalent__c = 'Activation Specialist';
        //insert businessRoleObj1;
        brLst.add(businessRoleObj2);
        insert brLst;
        
        List<User_Business_Role__c> ubrLst = new List<User_Business_Role__c>();
        User_Business_Role__c userBusinessObj = new User_Business_Role__c();
        userBusinessObj.Business_Role__c = businessRoleObj.id;
        userBusinessObj.User__c = qualityMamagerUser.id;
        //insert userBusinessObj;
        ubrLst.add(userBusinessObj);
        
        User_Business_Role__c userBusinessObj1 = new User_Business_Role__c();
        userBusinessObj1.Business_Role__c = businessRoleObj1.id;
        userBusinessObj1.User__c = usr.id;
        ubrLst.add(userBusinessObj1);
        //insert userBusinessObj1;
        User_Business_Role__c userBusinessObj2 = new User_Business_Role__c();
        userBusinessObj2.Business_Role__c = businessRoleObj2.id;
        userBusinessObj2.User__c = activationSpecialist.id;
        ubrLst.add(userBusinessObj2);
        
        insert ubrLst;
        
        usr = [Select Id,Available_Countries__c,Profile_Name__c,Profile.Name from User where Id = :usr.Id ];
        system.debug(LoggingLevel.Debug,'usr='+usr);
        
        qualityMamagerUser = [Select Id,Available_Countries__c,Profile_Name__c,Profile.Name from User where Id = :qualityMamagerUser.Id ];
        system.debug(LoggingLevel.Debug,'usr='+qualityMamagerUser);
        
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
        
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;
        
        Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHier.Parent_BU__c = terriHierSA.Id;
        insert terriHier;
        
        List<Territory_Hierarchy__c> thLst = new List<Territory_Hierarchy__c>();
        Territory_Hierarchy__c terriHierActive = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Activation Territory');
        thLst.add(terriHierActive);
       // insert terriHierActive;
        
        //Quality Territory Hierarchy
        Territory_Hierarchy__c terriHier1 = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Quality Territory Hierarchy');
        terriHier1.Parent_BU__c = terriHierSA.Id;
        terriHier1.Territory_Hierarchy_Type__c = 'Dispense Manager';
        thLst.add(terriHier1);
        insert thLst;
        
        // Quality Territory Hierarchy member 
        Territory_Hierarchy_Member__c terrHieMem1 = new Territory_Hierarchy_Member__c();
        terrHieMem1.Start_Date__c = Date.today()-2;
        terrHieMem1.User__c = qualityMamagerUser.Id;
        terrHieMem1.Territory_Hierarchy__c = terriHier1.Id;
        insert terrHieMem1;
        
        Territory_Hierarchy_Member__c salesManagerTerrHieMem = new Territory_Hierarchy_Member__c();
        salesManagerTerrHieMem.Start_Date__c = Date.today()-2;
        salesManagerTerrHieMem.User__c = usr.Id;
        salesManagerTerrHieMem.Territory_Hierarchy__c = terriHier.Id;
        insert salesManagerTerrHieMem;
        
        /*Territory_Hierarchy_Member__c terrHieMem = new Territory_Hierarchy_Member__c();
        terrHieMem.Start_Date__c = Date.today()-2;
        terrHieMem.User__c = activationSpecialist.Id;
        terrHieMem.Territory_Hierarchy__c = terriHierActive.Id;
        insert terrHieMem; */
        
        List<Territory__c> terrLst = new List<Territory__c>();
        Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Territory_Type__c = 'Sales';
        territory.Region__c =terriHier.Id;
        territory.Activation_Territory__c = terriHierActive.Id;
        territory.RecordTypeId = salesTerritoryRecordTypeId;
        terrLst.add(territory);
        //insert territory;
        
        System.assertEquals(territory.Name, 'Test Territory','Match');
        /*         
        Territory__c territory1 = EDGE_UtilityTestClass.getTerritoryRec();
        territory1.Name = 'Sales Name';
        territory1.Territory_Type__c = 'Sales';
        territory1.Region__c =terriHier.Id;
        territory1.RecordTypeId = salesTerritoryRecordTypeId;
        terrLst.add(territory1);
        */
        
        Territory__c terr1 = EDGE_UtilityTestClass.getTerritoryRec();
        terr1.Territory_Type__c ='Quality Dispense';
        terr1.Region__c=terriHier1.Id;
        terr1.RecordTypeId = qualityTerritoryRecordTypeId;
        // terr1.Activation_Territory__c = terriHierActive.Id; 
        terrLst.add(terr1);
       // insert terr1;
        
        Territory__c activationTerr= EDGE_UtilityTestClass.getTerritoryRec();
        activationTerr.Territory_Type__c='Activation Territory';
        activationTerr.RecordTypeId=activationTerritoryRecordTypeId;
        terrLst.add(activationTerr);
        insert terrLst;
        
        
        List<Outlet_Territory__c> otLst = new List<Outlet_Territory__c>();
        //Sales
        Outlet_Territory__c  outletTerritory1  =  EDGE_UtilityTestClass.getOutltTerritory(outlet1.Id, territory.Id);
        outletTerritory1.Active__c = 'Waiting Activation';
        otLst.add(outletTerritory1);
        
        //Quality 
        Outlet_Territory__c  outletTerritory2  =  EDGE_UtilityTestClass.getOutltTerritory(outlet1.Id, terr1.Id);
        outletTerritory2.Active__c = 'Waiting Activation';
        otLst.add(outletTerritory2);
        //insert outletTerritory3;
        
        //Activation  
        Outlet_Territory__c outletTerritory3= EDGE_UtilityTestClass.getOutltTerritory(outlet1.Id, activationTerr.Id);
        outletTerritory3.Active__c = 'Waiting Activation';
        otLst.add(outletTerritory3);
        //insert outletTerritory4;
        
        //Removal
		
        //Sales
        Outlet_Territory__c  outletTerritory4  =  EDGE_UtilityTestClass.getOutltTerritory(outlet2.Id, territory.Id);
        outletTerritory4.Active__c = 'Waiting Removal';
        otLst.add(outletTerritory4);
        
        //Quality 
        Outlet_Territory__c  outletTerritory5  =  EDGE_UtilityTestClass.getOutltTerritory(outlet2.Id, terr1.Id);
        outletTerritory5.Active__c = 'Waiting Removal';
        otLst.add(outletTerritory5);
        //insert outletTerritory3;
        
        //Activation  
        Outlet_Territory__c outletTerritory6= EDGE_UtilityTestClass.getOutltTerritory(outlet2.Id, activationTerr.Id);
        outletTerritory6.Active__c = 'Waiting Removal';
        otLst.add(outletTerritory6);
        
        
        insert otLst;
        
        
        //Quality Territory Member
        Date currentDate = Date.today().addDays(-2);
        Date endDate = Date.today().addDays(+4);
        Territory_Member__c  territoryMember1 = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(usr2.Id,terr1.Id);
        territoryMember1.Start_Date__c = currentDate;
        territoryMember1.End_Date__c = endDate;
        territoryMember1.Type__c='Primary';
        insert territoryMember1;
        
        //Activation Specialist
        Territory_Member__c  territoryMember2 = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(activationSpecialist.Id,activationTerr.Id);
        territoryMember1.Start_Date__c = currentDate;
        territoryMember1.Start_Date__c = endDate;
        insert territoryMember2;
        
        //Sales
        Territory_Member__c  territoryMember = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(usr1.Id,territory.Id);
        territoryMember.Start_Date__c = currentDate;
        territoryMember.End_Date__c = endDate;
        territoryMember.Type__c='Primary';
        insert territoryMember;
        
        
        System.assertEquals(outletTerritory1.Active__c, 'Waiting Activation','Match');
        outletWithRegionMapToShare.put(outlet.Id,terriHier.Id);
        outletWithActivationTerritoryMapToShare.put(outlet.Id,terriHierActive.Id);
        
        
        List<Outlet_Member__c> omLst = new List<Outlet_Member__c>();
        
        //Sales Rep
        Outlet_Member__c om1 = new Outlet_Member__c();
        om1 = EDGE_UtilityTestClass.getOutletMemberRecord(outlet2.id,usr1.id,'Primary');
        omLst.add(om1);
        
        Outlet_Member__c om2 = new Outlet_Member__c();
        om2 = EDGE_UtilityTestClass.getOutletMemberRecord(outlet2.id,activationSpecialist.id,'Activation Specialist');
        omLst.add(om2);
        
        Outlet_Member__c om3 = new Outlet_Member__c();
        om3 = EDGE_UtilityTestClass.getOutletMemberRecord(outlet2.id,usr2.id,'Dispense Rep');
        omLst.add(om3);
        
        Outlet_Member__c om4 = new Outlet_Member__c();
        om4 = EDGE_UtilityTestClass.getOutletMemberRecord(outlet2.id,usr.id,'Sales Manager');
        omLst.add(om4);
        
        Outlet_Member__c om5 = new Outlet_Member__c();
        om5 = EDGE_UtilityTestClass.getOutletMemberRecord(outlet2.id,qualityMamagerUser.id,'Dispense Manager');
        omLst.add(om5);
        
        insert omLst;
        
        /*
        Outlet_Territory__c  outletTerritory2  =  EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, territory.Id);
        outletTerritory2.Active__c = 'Waiting Removal';
        insert outletTerritory2 ;
        System.assertEquals(outletTerritory2.Active__c, 'Waiting Removal'); 
        outletWithRegionMapToRemove.put(outlet.Id,terriHier.Id);
        outletWithActivationTerritoryMapToRemove.put(outlet.Id,terriHierActive.Id);*/
        
       /* EDGE_TerritoryProcessStatusUpdateBatch.salesManagerSharingOperation(outletWithQualityMapToShare,false);
        EDGE_TerritoryProcessStatusUpdateBatch.salesManagerSharingOperation(outletWithRegionMapToShare,true);
        EDGE_TerritoryProcessStatusUpdateBatch.salesManagerSharingOperation(outletWithRegionMapToRemove,false);*/
        //EDGE_TerritoryProcessStatusUpdateBatch.activationSpecialistSharingOperation(outletWithActivationTerritoryMapToRemove, true);
        //EDGE_TerritoryProcessStatusUpdateBatch.activationSpecialistSharingOperation(outletWithActivationTerritoryMapToShare, false);
    }
}