/**
* @description :  EDGE_CoverageOutletKPIAchivHelperTest
* @purpose : Test Class for EDGE_CoverageOutletKPIAchivHelperTest
* @history :
* Version   Developer         Date         User Story/Purpose
*  1.1     Prasanth T       30/11/2021     ES20-10678
*/
@isTest
public class EDGE_CoverageOutletKPIAchivHelperTest {
    
    public static void createDataforOutletKPiAchievement(){
        
        User testAdminUserGB = EDGE_UtilityTestClass.runAsUser('AdminuserGB','System Administrator');
        testAdminUserGB.Available_Countries__c = 'GB';
        insert testAdminUserGB;
        ID geographyIdGB = EDGE_UtilityTestClass.setupCountryGB('GB');
        
        System.runAs(testAdminUserGB) {
            
            List<User_Business_Role__c> usrbrole=new List<User_Business_Role__c>();
            
            Business_Role__c brtest1 = EDGE_UtilityTestClass.getBusinessRole();
            brtest1.Name='Sales Representative';
            brtest1.Country__c = geographyIdGB;
            brtest1.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
            Insert brtest1;
            Business_Role__c brtest2 = EDGE_UtilityTestClass.getBusinessRole();
            brtest2.Name='Quality Representative';
            brtest2.Country__c = geographyIdGB;
            brtest2.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
            Insert brtest2;
            Business_Role__c brtest3 = EDGE_UtilityTestClass.getBusinessRole();
            brtest3.Name='On Trade Activation Specialist';
            brtest3.Country__c = geographyIdGB;
            brtest3.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
            Insert brtest3;           
            
            User testSalesManagerUser = EDGE_UtilityTestClass.runAsUser('SalesManager','Sales Manager');    
            insert testSalesManagerUser;
            
            User salesRepUser = EDGE_UtilityTestClass.runAsUser('SalesRep01','Sales Representative'); 
            salesRepUser.ManagerId = testSalesManagerUser.id;
            salesRepUser.Available_Countries__c = 'GB';
            salesRepUser.Business_Role_Id__c = brtest1.Id;
            insert salesRepUser;
            User qualityRepUser = EDGE_UtilityTestClass.runAsUser('QualityRep01','Quality Representative'); 
            qualityRepUser.ManagerId = testSalesManagerUser.id;
            qualityRepUser.Available_Countries__c = 'GB';
            qualityRepUser.Business_Role_Id__c = brtest2.Id;
            insert qualityRepUser;
            User activationSplUser = EDGE_UtilityTestClass.runAsUser('ActivationSpecialist01','Activation Specialist'); 
            activationSplUser.ManagerId = testSalesManagerUser.id;
            activationSplUser.Available_Countries__c = 'GB';
            activationSplUser.Business_Role_Id__c = brtest3.Id;
            insert activationSplUser;
            
            User salesRepUser2 = EDGE_UtilityTestClass.runAsUser('SalesRep02','Sales Representative'); 
            salesRepUser2.ManagerId = testSalesManagerUser.id;
            salesRepUser2.Available_Countries__c = 'GB';
            insert salesRepUser2;
            
            User qualityRepUser2 = EDGE_UtilityTestClass.runAsUser('QualityRep02','Quality Representative'); 
            qualityRepUser2.ManagerId = testSalesManagerUser.id;
            qualityRepUser2.Available_Countries__c = 'GB';
            insert qualityRepUser2;
            
            User_Business_Role__c ubrtest1 = EDGE_UtilityTestClass.getuserBusinessRole(salesRepUser, brtest1);
            //ubrtest1.Business_Role__c = brtest1.Id;
            usrbrole.add(ubrtest1);
            User_Business_Role__c ubrtest2 = EDGE_UtilityTestClass.getuserBusinessRole(qualityRepUser, brtest2);
            //ubrtest2.Business_Role__c = brtest2.Id;
            usrbrole.add(ubrtest2);
            User_Business_Role__c ubrtest3 = EDGE_UtilityTestClass.getuserBusinessRole(activationSplUser, brtest3);
            //ubrtest3.Business_Role__c = brtest3.Id;
            usrbrole.add(ubrtest3);
            insert usrbrole;
            
            Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyIdGB, 'Business Unit');
            insert terriHierBU;
            
            Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyIdGB, 'Sales Area');
            terriHierSA.Parent_BU__c = terriHierBU.Id;
            insert terriHierSA;
            
            Territory_Hierarchy__c terriHierRegion = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyIdGB, 'Region');
            terriHierRegion.Parent_BU__c = terriHierSA.Id;
            insert terriHierRegion;
            
            Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyIdGB, 'Region');
            terriHier.Parent_BU__c = terriHierSA.Id;
            Id qualityTerritoryHierarchyRecType = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Quality Territory Hierarchy').getRecordTypeId();
            terriHier.RecordTypeId = qualityTerritoryHierarchyRecType;
            terriHier.Territory_Hierarchy_Type__c ='Regional Quality Manager (GB)';
            insert terriHier;
            
            // create Sales Territory 
            Territory__c sterritory =  EDGE_UtilityTestClass.getTerritoryRec();
            sterritory.Country__c = geographyIdGB;
            sterritory.Sales_Area__c = terriHierSA.Id;
            sterritory.Region__c = terriHierRegion.Id;
            sterritory.Territory_Type__c = 'Sales';
            insert sterritory;
            
            Territory__c sterritory1 =  EDGE_UtilityTestClass.getTerritoryRec();
            sterritory1.Country__c = geographyIdGB;
            sterritory1.Sales_Area__c = terriHierSA.Id;
            sterritory1.Region__c = terriHierRegion.Id;
            sterritory1.Territory_Type__c = 'Sales';
            insert sterritory1;
            
            Territory__c qterritory =  EDGE_UtilityTestClass.getTerritoryRec();
            qterritory.RecordTypeId=Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();
            qterritory.Country__c = geographyIdGB;
            qterritory.Sales_Area__c = terriHierSA.Id;
            qterritory.Region__c = terriHier.Id;
            qterritory.Territory_Type__c = 'Quality Service / Executive';
            insert qterritory;
            
            Territory__c qterritory2 =  EDGE_UtilityTestClass.getTerritoryRec();
            qterritory2.RecordTypeId=Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();
            qterritory2.Country__c = geographyIdGB;
            qterritory2.Sales_Area__c = terriHierSA.Id;
            qterritory2.Region__c = terriHier.Id;
            qterritory2.Territory_Type__c = 'Quality Service / Executive';
            insert qterritory2;
            
            Territory__c asterritory =  EDGE_UtilityTestClass.getTerritoryRec();
            asterritory.Country__c = geographyIdGB;
            asterritory.Sales_Area__c = terriHierSA.Id;
            asterritory.Region__c = terriHierRegion.Id;
            asterritory.Territory_Type__c = 'Sales';
            insert asterritory;
            
            Territory_Member__c territoryMember = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(salesRepUser.Id,sterritory.Id);
            territoryMember.Start_Date__c = system.today();
            insert territoryMember;
            
            Territory_Member__c territoryMember1 = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(qualityRepUser.Id,qterritory.Id);
            territoryMember1.Start_Date__c = system.today();
            insert territoryMember1;
            
            Territory_Member__c territoryMember2 = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(activationSplUser.Id,asterritory.Id);
            territoryMember2.Start_Date__c = system.today();
            insert territoryMember2;
            
            Territory_Member__c territoryMember3 = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(salesRepUser.Id,sterritory1.Id);
            territoryMember3.Start_Date__c = system.today();
            insert territoryMember3;
            
            Territory_Member__c territoryMember4 = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(qualityRepUser2.Id,qterritory2.Id);
            territoryMember4.Start_Date__c = system.today();
            territoryMember4.Type__c='Primary';
            insert territoryMember4;
            
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyIdGB,'Outlet Visit Prioritization');
            pickupOption.Name = 'GOLD[GB]';
            insert pickupOption;
            
            Market_Cycle__c  marketCycle=EDGE_UtilityTestClass.getMarketCycle(geographyIdGB);
            marketCycle.Start_Date__c = Date.Today();
            marketCycle.End_Date__c = Date.Today().addDays(30);
            marketCycle.Geography__c = geographyIdGB;
            insert marketCycle;
            
            //create outlet record 
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outletAccount.Global_Channel__c = 'Off Trade';
            outletAccount.Global_Sub_Channel__c ='Retailer';
            outletAccount.Global_Segment__c = 'Discounter';
            outletAccount.Global_Sub_Segment__c = 'Modern Discounter'; 
            outletAccount.Independent_of_Operator__c = true;
            outletAccount.Independent_of_Owner__c = true;
            outletAccount.Primary_Sales_Rep__c=salesRepUser.Id;
            //outletAccount.Operator__c = operator.Id;
            //outletAccount.ParentId = owner.Id;
            outletAccount.Primary_Sales_Territory__c = sterritory.id;
            insert outletAccount;                
            
            Account outletAccount1 = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outletAccount1.Name='TestOutlet';
            outletAccount1.Global_Channel__c = 'Off Trade';
            outletAccount1.Global_Sub_Channel__c ='Retailer';
            outletAccount1.Global_Segment__c = 'Discounter';
            outletAccount1.Global_Sub_Segment__c = 'Modern Discounter'; 
            outletAccount1.Independent_of_Operator__c = true;
            outletAccount1.Independent_of_Owner__c = true;
            outletAccount1.Primary_Sales_Rep__c=activationSplUser.Id;
            outletAccount1.Activation_Specialist__c=activationSplUser.Id;
            //outletAccount.Operator__c = operator.Id;
            //outletAccount.ParentId = owner.Id;
            outletAccount1.Primary_Sales_Territory__c = asterritory.id;
            insert outletAccount1;                
            
            List<Outlet_Territory__c> outTerlist=new List<Outlet_Territory__c>();
            Outlet_Territory__c outlTer = EDGE_UtilityTestClass.getOutltTerritory(outletAccount.Id, sterritory.Id);
            outTerlist.add(outlTer);
            
            Outlet_Territory__c outlTer1 = EDGE_UtilityTestClass.getOutltTerritory(outletAccount.Id, qterritory.Id);
            outTerlist.add(outlTer1);
            
            Outlet_Territory__c outlTer2 = EDGE_UtilityTestClass.getOutltTerritory(outletAccount1.Id, asterritory.Id);
            outTerlist.add(outlTer2);
            
            Outlet_Territory__c outlTer3 = EDGE_UtilityTestClass.getOutltTerritory(outletAccount.Id, qterritory2.Id);
            outTerlist.add(outlTer3);
            insert outTerlist;
            
            List<Call_Type__c> callType=new List<Call_Type__c>();
            Call_Type__c callType1 = EDGE_UtilityTestClass.getCallType(geographyIdGB);
            callType1.Global_Equivalent_Call_Type__c = 'Physical';
            callType1.Name = 'Call Type for Sales Rep';
            callType.add(callType1);
            
            Call_Type__c callType2 = EDGE_UtilityTestClass.getCallType(geographyIdGB);
            callType2.Global_Equivalent_Call_Type__c = 'Physical';
            callType2.Name = 'Call Type for Quality Rep';
            callType.add(callType2);
            
            Call_Type__c callType3 = EDGE_UtilityTestClass.getCallType(geographyIdGB);
            callType3.Global_Equivalent_Call_Type__c = 'Physical';
            callType3.Name = 'Call Type for Activation Specialist';
            callType.add(callType3);
            insert callType;
            
            List<Role_Call__c> roleCall=new List<Role_Call__c>();
            Role_Call__c roleCall1 = new Role_Call__c();
            roleCall1.Call_Type__c = callType[0].Id;
            roleCall1.KPIs_Active__c = 'Calls Per Day;Days In Trade;Coverage Compliance;Planned Call Compliance;Outlet Visit Compliance';
            roleCall1.Business_Role__c = brtest1.Id;
            roleCall.add(roleCall1);
            
            Role_Call__c roleCall2 = new Role_Call__c();
            roleCall2.Call_Type__c = callType[1].Id;
            roleCall2.KPIs_Active__c = 'Calls Per Day;Days In Trade;Coverage Compliance;Planned Call Compliance;Outlet Visit Compliance';
            roleCall2.Business_Role__c = brtest2.Id;
            roleCall.add(roleCall2);
            
            Role_Call__c roleCall3 = new Role_Call__c();
            roleCall3.Call_Type__c = callType[2].Id;
            roleCall3.KPIs_Active__c = 'Calls Per Day;Days In Trade;Coverage Compliance;Planned Call Compliance;Outlet Visit Compliance';
            roleCall3.Business_Role__c = brtest3.Id;
            roleCall.add(roleCall3);
            insert roleCall;
            
            List<Call__c> calls=new List<Call__c>();
            Call__c call1 = new Call__c();
            call1.Account__c = outletAccount.Id;
            call1.Planned_Call_Type__c=calltype[0].Id;
            call1.Start_Date__c = System.today();
            call1.End_Date__c = System.now().addDays(1);
            call1.Status__c = 'Completed';
            call1.Call_Performed_By__c=salesRepUser.Id;
            call1.Type_of_Call__c=callType[0].Id;
            call1.Last_Visit_from_Mobile__c = true;
            calls.add(call1);
            
            Call__c call2 = new Call__c();
            call2.Account__c = outletAccount.Id;
            call2.Planned_Call_Type__c=calltype[1].Id;
            call2.Start_Date__c = System.today();
            call2.End_Date__c = System.now().addDays(2);
            call2.Status__c = 'Completed';
            call2.Call_Performed_By__c=qualityRepUser.Id;
            call2.Type_of_Call__c=callType[1].Id;
            call2.Last_Visit_from_Mobile__c = true;
            calls.add(call2);
            
            Call__c call3 = new Call__c();
            call3.Account__c = outletAccount1.Id;
            call3.Planned_Call_Type__c=calltype[2].Id;
            call3.Start_Date__c = System.today();
            call3.End_Date__c = System.now().addDays(2);
            call3.Status__c = 'Completed';
            call3.Call_Performed_By__c=activationSplUser.Id;
            call3.Last_Visit_from_Mobile__c = true;
            call3.Type_of_Call__c=callType[2].Id;
            calls.add(call3);
            
            Call__c call4 = new Call__c();
            call4.Account__c = outletAccount.Id;
            call4.Planned_Call_Type__c=calltype[0].Id;
            call4.Start_Date__c = System.today();
            call4.End_Date__c = System.now().addDays(2);
            call4.Status__c = 'Completed';
            call4.Call_Performed_By__c=salesRepUser2.Id;
            call4.Last_Visit_from_Mobile__c = true;
            call4.Type_of_Call__c=callType[0].Id;
            calls.add(call4);
            
            Call__c call5 = new Call__c();
            call5.Account__c = outletAccount.Id;
            call5.Planned_Call_Type__c=calltype[1].Id;
            call5.Start_Date__c = System.today();
            call5.End_Date__c = System.now().addDays(1);
            call5.Status__c = 'Completed';
            call5.Call_Performed_By__c=qualityRepUser2.Id;
            call5.Last_Visit_from_Mobile__c = true;
            call5.Type_of_Call__c=callType[1].Id;
            calls.add(call5);
            insert calls;
            
            Outlet_KPI_Achievement__c outKPIAch = new Outlet_KPI_Achievement__c();
            outKPIAch.Target__c=90;
            outKPIAch.KPI_Type__c = 'Coverage for Activation Specialist';
            outKPIAch.Actual_Numerator__c = 400;
            outKPIAch.Total_Denominator__c = 20;
            outKPIAch.Date_Of_Execution__c = Date.newInstance(2020, 04, 14);
            outKPIAch.Last_Compliant_Call_Date__c = Date.newInstance(2020, 04, 14);
            outKPIAch.Valid__c = true;
            outKPIAch.Volume_Category__c = 'Deluxe';
            outKPIAch.Outlet__c = outletAccount1.id;
            outKPIAch.Achievement__c = 70 ;
            outKPIAch.Previous_Achievement__c =65 ;
            outKPIAch.Unique_Id__c=calls[2].Account__c +'_'+'Coverage for Activation Specialist';
            insert outKPIAch;
        }
    }
    @isTest
    public static void coverageComplianceOutletKPIBatchTest(){
        Test.startTest();
        createDataforOutletKPiAchievement();
        Test.stopTest();
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_UserVisitsKPIBatch'
                                                  and Country_Code__c ='GB'];
        system.assert(batchSetting.Id != null,'batchSetting should not be null');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
    }
}