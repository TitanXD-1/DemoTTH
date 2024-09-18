/**

* @description :  EDGE_SalesManagerOutletRemoveBatchTest

* @purpose : To test EDGE_SalesManagerOutletRemoveBatch

* @history :

* Version    Developer         Date             User Story/Purpose
*  1.1      Dipanjan D       05/09/2019         ES20-3836 - Sales force Sharing Rules - Technical
*  1.2      Mayukh SRoy      06/12/2022        ES20-13624 - UAT_Multiple Queueable Jobs are executed from the same transaction
*  1.3      Mayukh SRoy      22/02/2023         ES20-13559 - Change in Existing Batch Logic To Remove and Change Sales Manager to region with more than 10000 accounts_ SFDC_ Technical Debt
*/

@istest
public class EDGE_SalesManagerOutletRemoveBatchTest {
    
    
    @istest
    public static void testSalesManagerOutletRemove(){
        
        Test.startTest(); 
        createtestData();
        Test.stopTest();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_SalesManagerOutletRemoveBatch'
                                                  and Country_Code__c ='AU' LIMIT 1];
        //added Assert Statement by Vikas
        System.assert(batchSetting != Null,'Market Batch Settings');
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
    }
    
    @istest
    public static void testNoSalesManagerOutletRemove(){
        EDGE_UtilityTestClass.setupCountry('AU');
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_SalesManagerOutletRemoveBatch'
                                                  and Country_Code__c ='AU' LIMIT 1];
        //added Assert Statement by Vikas
        System.assert(batchSetting != Null,'Market Batch Settings');
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);        
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
    }
    
    public static void createtestData(){
        Date currentDate = Date.today();
        Id countryId;
        
        List<User> usrLst = new List<User>();
        User admin = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        usrLst.add(admin);
        
        User testMDMUser = EDGE_UtilityTestClass.runAsUser('testAdmin','Sales Manager');
        usrLst.add(testMDMUser);
        
        //insert testMDMUser;
        User testREPUser = EDGE_UtilityTestClass.runAsUser('EDGEREP','Sales Representative');    
        usrLst.add(testREPUser);
        insert usrLst;
        
        System.runAs(admin){
			countryId = EDGE_UtilityTestClass.setupCountry('AU');
            
            Business_Role__c businessRoleObj1 = EDGE_UtilityTestClass.getBusinessRole();
            businessRoleObj1.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
            businessRoleObj1.Country__c = countryId;
            businessRoleObj1.Global_Equivalent__c = 'Sales Manager';
            insert businessRoleObj1;
            
            User_Business_Role__c userBusinessObj1 = new User_Business_Role__c();
            userBusinessObj1.Business_Role__c = businessRoleObj1.id;
            userBusinessObj1.User__c = testMDMUser.id;
            insert userBusinessObj1;
            
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AUT]';
            insert pickupOption;
            
            Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
            insert terriHierBU;
            
            Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
            terriHierSA.Parent_BU__c = terriHierBU.Id;
            insert terriHierSA;
            
            Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
            terriHier.Parent_BU__c = terriHierSA.Id;
            insert terriHier;
            system.assert(terriHier!=null,'Territory Hierarchy');
            
            Territory_Hierarchy_member__c terrHierMem = new Territory_Hierarchy_member__c();
            terrHierMem.Territory_Hierarchy__c = terriHier.Id;
            terrHierMem.User__c= testMDMUser.Id;
            terrHierMem.Start_Date__c = currentDate.addDays(-10);
            terrHierMem.End_Date__c = currentDate.addDays(-1);
            insert terrHierMem;
            
            Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
            territory.Territory_Type__c = 'Sales';
            territory.Region__c =terriHier.Id;
            territory.RecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
            insert territory;
            
            
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.BillingStreet = '17 Asian Highway 45';
            outlet.BillingCity = 'Tasmania';
            outlet.BillingCountry = 'Australia';
            outlet.BillingState = 'Tasmania';
            outlet.BillingPostalCode = '5668';
            outlet.BillingCountryCode = 'AU';
            outlet.Primary_Sales_Territory_Region__c=terriHier.id;
            //outlet.Activation_Territory__c = terriHierActive.Id;
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert outlet;
            
            
            Outlet_Territory__c  outletTerritory  =  EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, territory.Id);
            outletTerritory.Active__c = 'Active';
            insert outletTerritory;
            
            EDGE_UtilityTestClass.createOrgSettings();
            
            Outlet_Member__c outletmem = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.id, testMDMUser.id, 'Sales Manager');
            insert outletmem;
        }
    }
}