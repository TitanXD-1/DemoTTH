/**
 * @name : public class D1_UpdateNpsCounterBatchTest 
 * @description : Test class for public class D1_UpdateNpsCounterBatch
 * @history
 * VERSION     	AUTHOR         	   DATE            DETAIL
 * 1.0         D1DEVTeam
**/
@isTest
public class D1_UpdateNpsCounterBatchTest {
	@testSetup
    public static void testSetup(){
        Test.startTest();
        Id countryId = D1_TestDataUtility.setupCountry('GB');
        Geography__c geog = new Geography__c(Id=countryId);
       
        D1_Setting__c d1Setting = D1_TestDataUtility.createD1Settings(geog);
        insert d1Setting;
        
        Account directAcc = D1_TestDataUtility.getDirectCustomer();
        insert directAcc;
        
        Contact primaryCon = D1_TestDataUtility.getContact(directAcc.Id, 'Primary');
        primaryCon.FirstName = 'Primary';
        primaryCon.D1_Login_Reminder_Status__c = 'Compliant';
        insert primaryCon;
        
        List<Contact> secConList = new List<Contact>();
        
        Contact newContact = D1_TestDataUtility.getContact(directAcc.Id, 'Secondary');
        newContact.FirstName = 'Secondary1';
        newContact.Email = 'secondary1@test.com';
        newContact.D1_Contact_Last_Login_Date__c = datetime.newInstance(2020, 12, 28, 12, 00, 0);
        newContact.D1_Login_Reminder_Status__c = 'Compliant';
        newContact.Next_Action_Date__c = System.today();
        secConList.add(newContact);
        
        Contact newContact2 = D1_TestDataUtility.getContact(directAcc.Id, 'Secondary');
        newContact2.FirstName = 'Secondary2';
        newContact2.Email = 'secondary2@test.com';
        newContact2.D1_Contact_Last_Login_Date__c = datetime.newInstance(2020, 12, 14, 12, 00, 0);
        newContact2.D1_Login_Reminder_Status__c = 'First Reminder';
        newContact2.Next_Action_Date__c = System.today();
        secConList.add(newContact2);
        
        Contact newContact3 = D1_TestDataUtility.getContact(directAcc.Id, 'Secondary');
        newContact3.FirstName = 'Secondary2';
        newContact3.Email = 'secondary2@test.com';
        newContact3.D1_Contact_Last_Login_Date__c = datetime.newInstance(2020, 11, 30, 12, 00, 0);
        newContact3.D1_Login_Reminder_Status__c = 'Second Reminder';
        newContact3.Next_Action_Date__c = System.today();
        secConList.add(newContact3);
        
        insert secConList;
        
       /* User secondaryUser2 = D1_TestDataUtility.runAsUser('secondaryUser2','DiageoOne External User');
        secondaryUser2.ContactId = newContact3.Id;
        insert secondaryUser2;*/
        
        List<AccountContactRelation> acrs = [select id,ContactId, D1_Roles__c,D1_Active__c,D1_User_Role__c from AccountContactRelation];
        //List<AccountContactRelation> acrlist = new List<AccountContactRelation>();
        for(AccountContactRelation acr :acrs){
            acr.D1_Roles__c='User Management';
            acr.D1_Active__c = True;
            acr.D1_User_Role__c = 'Member of Staff';
            if(acr.ContactId == primaryCon.Id){
                acr.D1_User_Role__c = 'Primary';
            }
            //acrlist.add(acr);
        }
        update acrs;  
        Test.stopTest(); 
    }

    @isTest
    public static void contactLoginStatusBatchTest(){
        Id recordTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Country').getRecordTypeId();
        List<D1_UpdateNpsCounterBatch.FlowInputs> inputParams = new List<D1_UpdateNpsCounterBatch.FlowInputs>();
        D1_UpdateNpsCounterBatch.FlowInputs fi = new D1_UpdateNpsCounterBatch.FlowInputs();
        Geography__c country = [Select Id from Geography__c where RecordTypeId=:RecordTypeId ];
        fi.countryIds = country.Id;
        fi.countryCode ='GB';
        inputParams.add(fi);

        Test.startTest();
            D1_UpdateNpsCounterBatch.scheduleNpsCounterBatch(inputParams);
        Test.stopTest();
        System.assert(D1_UpdateNpsCounterBatch.scheduleNpsCounterBatch(inputParams) == NULL, 'nps not updated');
    }
}