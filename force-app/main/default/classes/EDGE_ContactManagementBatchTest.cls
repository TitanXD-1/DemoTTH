/**
* @Description :  EDGE_ContactManagementBatchTest

* @Purpose: Test class for EDGE_ContactManagementBatch

* @History :

* @Version   Developer      Date       User Story	  Purpose
*   1.1      Aparajita    27/04/2022   ES20-12476     Test EDGE_ContactManagementBatch

*/

@isTest
public class EDGE_ContactManagementBatchTest {
    
    public static void executeBatch(){
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c,Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c,Frequency__c from Market_Batch_Setting__mdt
                                                  where Batch_Class__c = 'EDGE_ContactManagementBatch' AND Country_Code__c = 'AU'];
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
    }
    
    @isTest
    public static void testOwnerChange(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        User admin1 = EDGE_UtilityTestClass.runAsUser('admin1','System Administrator'); 
        admin1.Available_Countries__c = 'AU';
        
        User admin2 = EDGE_UtilityTestClass.runAsUser('admin2','System Administrator'); 
        admin2.Available_Countries__c = 'AU';
        
        User usr = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Sales Representative');
        usr.Business_Role__c = 'Sales Representative';
        
        List<User> usrList = new List<User>();
        usrList.add(admin1);
        usrList.add(admin2);
        usrList.add(usr);
        insert usrList;

        System.runAs(admin1) {
            
            //insert Business Role
            Business_Role__c brtest = EDGE_UtilityTestClass.getBusinessRole();
            brtest.Global_Equivalent__c='Sales Rep';
            brtest.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;OPPS OPEN;OPPS CLOSED;WPA__c';
            brtest.Country__c = countryId;            
            insert brtest;
            
            Test.startTest();
        	User_Business_Role__c ubrtest1 = EDGE_UtilityTestClass.getuserBusinessRole(usr, brtest);
            insert ubrtest1;    
            
            Org_Setting__c org = Org_Setting__c.getOrgDefaults();
            org.Run_Triggers__c = false;
            update org;
            
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            org.Run_Triggers__c = true;
            update org;

            Account outlet1=EDGE_UtilityTestClass.getOutletRecord();
            outlet1.Country__c=countryId;
            outlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            
            Account outlet2 =EDGE_UtilityTestClass.getOutletRecord();
            outlet2.Country__c=countryId;
            outlet2.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            
            List<Account> outletList = new List<Account>();
            outletList.add(outlet1);
            outletList.add(outlet2);
            insert outletList;
            
            Contact dirCon=new Contact(FirstName='fname1',
                                       LastName = 'lname1',
                                       Email = 'email1@gmail.com',
                                       Phone = '1234567890',
                                       AccountID=outlet1.Id,
                                       OwnerId=admin1.Id,
                                       Owner_Changed__c = false); 
            
            Contact indirCon=new Contact(FirstName='fname2',
                                         LastName = 'lname2',
                                         Email = 'email2@gmail.com',
                                         Phone = '9876543210',
                                         AccountID=outlet2.Id,
                                         Contact_Shared__c=TRUE,
                                         OwnerId=admin1.Id,
                                         Owner_Changed__c = false); 
            
            List<Contact> conList = new List<Contact>();
            conList.add(dirCon);
            conList.add(indirCon);
            insert conList;
			

            //List<AccountContactRelation> acrs=new List<AccountContactRelation>();
            AccountContactRelation indirACR = new AccountContactRelation();
            indirACR.AccountId = outlet1.Id;
            indirACR.ContactId = indirCon.Id;
            indirACR.Contact_Type__c = 'Primary';
            indirACR.IsActive = true;
            indirACR.D1_Active__c=true;
            insert indirACR;
            Test.stopTest();
            
            Outlet_Member__c om = new Outlet_Member__c();
            om.Outlet__c = outlet1.id;
            om.User__c = usr.id;
            om.Outlet_Role__c = 'Primary';
            insert om;            
          

            //List<ContactShare> conShareInserted = [SELECT ContactId, Contact.AccountId, UserOrGroupId FROM ContactShare WHERE RowCause = 'Manual'
            //                                      AND UserOrGroupId =: usr.Id];            
            indirCon.OwnerId = admin2.Id;
            indirCon.Owner_Changed__c = true;
            update indirCon;
                        
            List<ContactShare> conShareDeleted = [SELECT ContactId, Contact.AccountId, UserOrGroupId FROM ContactShare WHERE RowCause = 'Manual'
                                                   AND UserOrGroupId =: usr.Id];
            
            System.assert(conShareDeleted.isEmpty(),'conShareDeleted is Empty');
            System.assert(indirCon.Owner_Changed__c==TRUE,'indirCon Inserted');
            System.assert(indirCon.Contact_Shared__c==TRUE,'indirCon Inserted');
            
            /*Contact con = [SELECT Id, AccountId, Contact_Type__c, OwnerId, Owner_Changed__c, Contact_Shared__c FROM Contact WHERE Account.Country_Code__c = 'AU'
			 	           AND Owner_Changed__c = TRUE AND Contact_Shared__c = TRUE AND Id IN 
                            (SELECT ContactId FROM AccountContactRelation WHERE IsDirect = FALSE AND IsDeleted = FALSE AND IsActive = TRUE) 
			 				AND Id NOT IN (SELECT ContactId FROM ContactShare WHERE RowCause = 'Manual')];*/

            executeBatch();


        }
    }     
}