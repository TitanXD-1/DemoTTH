/***
Name: PNR_CaseTriggerHandlerTest
===
Purpose: This Test Class is for PNR_CaseTriggerHandler
===
History                                                            
-----                                                           
VERSION     AUTHOR             DATE              DETAIL
1.0      Saurav Prasad       16/06/2020       Test method for updateEntitlementName
2.0      Pratik Kumar        21/12/2021       Added testValidateOwnerChange method
***/
@isTest
public class PNR_CaseTriggerHandlerTest {
    
    @isTest
    public static void testupdateEntitlementName(){ 
        
        Test.startTest();
        
        //create System Admin User
        User testadminUser = PNR_TestDataUtility.runAsUser('Admin','System Administrator');  
        testadminUser.Available_Countries__c='AU';
        insert testadminUser;
        System.runAs ( testadminUser ) {
            
            // Customer creation
            Id geographyId = EDGE_UtilityTestClass.setupCountry('AD');
            PNR_TestDataUtility.createOrgSettings();
            Account soldToAccObj  = PNR_TestDataUtility.getDirectCustomerRec();
            soldToAccObj.KUNNR__c = '10483';
            soldToAccObj.Country_ISO_Code__c = 'AD';
            insert soldToAccObj;
            
            List<SlaProcess> Pioneer_Sla=new List<SlaProcess>([SELECT Id From SlaProcess where Name ='Pioneer Entitlement Process' AND IsActive = True Limit 1]);
            if(Pioneer_Sla.size()>0){
                Entitlement ent = new Entitlement(Name='Pioneer Entitlement Process', AccountId=soldToAccObj.Id,
                                                  StartDate=Date.valueof(System.now().addDays(-2)), 
                                                  EndDate=Date.valueof(System.now().addYears(2)), 
                                                  slaprocessid=Pioneer_Sla[0].id);
                insert ent;
            }
            
            Case caseRec = PNR_TestDataUtility.getDirectDisputesCase(soldToAccObj.Id);
            
            insert caseRec;
            
            delete caseRec;
            
            Case[] savedCases = [SELECT Id FROM Case WHERE CaseNumber=:caseRec.CaseNumber ALL ROWS]; 
            
            undelete savedCases;
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void testValidateOwnerChange(){
        Test.startTest();
        
        //create System Admin User
        UserRole ur = [SELECT Id FROM UserRole WHERE Name = 'Direct Customer' LIMIT 1];
        User testadminUser = PNR_TestDataUtility.runAsUser('Admin','System Administrator');  
        testadminUser.Available_Countries__c='AU';
        testadminUser.UserRoleId = ur.Id;
        insert testadminUser;
        User testadminUser1 = PNR_TestDataUtility.runAsUser('Tlead','PNR_TeamLead');
        testadminUser1.Available_Countries__c='AU';
        testadminUser1.UserRoleId = ur.Id;
        insert testadminUser1;
        System.debug('User Role:: '+[SELECT Id, Name, UserRole.Name, Profile.Name FROM User WHERE Id = :testadminUser1.Id]);
        User testadminUser2 = PNR_TestDataUtility.runAsUser('CusSerRep','PNR_CustomerServiceRep');  
        testadminUser2.Available_Countries__c='AU';
        testadminUser2.UserRoleId = ur.Id;
        insert testadminUser2;
        User testadminUser3 = PNR_TestDataUtility.runAsUser('CusSer','PNR_CustomerServiceRep');  
        testadminUser3.Available_Countries__c='AU';
        testadminUser3.UserRoleId = ur.Id;
        insert testadminUser3;
        Case caseRec = new Case();
        Account soldToAccObj = new Account();
      System.runAs ( testadminUser1 ) {
            
            // Customer creation
            Id geographyId = EDGE_UtilityTestClass.setupCountry('AD');
            PNR_TestDataUtility.createOrgSettings();
            soldToAccObj  = PNR_TestDataUtility.getDirectCustomerRec();
            soldToAccObj.KUNNR__c = '10483';
            soldToAccObj.Country_ISO_Code__c = 'AD';
            soldToAccObj.Pioneer_Enabled__c = TRUE; 
            soldToAccObj.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
            soldToAccObj.CC_CCC__c=testadminUser2.id;
            soldToAccObj.CC_CSE__c=testadminUser3.id;
            
            insert soldToAccObj;       
             
            List<SlaProcess> Pioneer_Sla=new List<SlaProcess>([SELECT Id From SlaProcess where Name ='Pioneer Entitlement Process' AND IsActive = True Limit 1]);
            if(Pioneer_Sla.size()>0){
                Entitlement ent = new Entitlement(Name='Pioneer Entitlement Process', AccountId=soldToAccObj.Id,
                                                  StartDate=Date.valueof(System.now().addDays(-2)), 
                                                  EndDate=Date.valueof(System.now().addYears(2)), 
                                                  slaprocessid=Pioneer_Sla[0].id);
                insert ent;
            }
            
            System.debug('Account query:: '+[SELECT Id, Pioneer_Enabled__c FROM Account WHERE Id = :soldToAccObj.Id]);
            caseRec = PNR_TestDataUtility.getDirectDisputesCase(soldToAccObj.Id);
            caseRec.OwnerId = testadminUser2.Id;
            caseRec.CC_Market__c= soldToAccObj.Id;
            caseRec.CC_Share_with_Customer_Concerns__c=false;
            caseRec.CC_Is_Customer_Concern_Created__c=true;
          caseRec.Type='Dispute – Delivery';
            
    
            System.runAs(testadminUser){
                insert caseRec;
            }
            
            System.debug('Case query:: '+[SELECT Id, RecordType.DeveloperName, RecordType.Name FROM Case WHERE Id = :caseRec.Id]);
            
            System.debug('QUERY:: '+[SELECT Id, OwnerId FROM Case WHERE Id = :caseRec.Id]);
            //System.runAs ( testadminUser1 ){
            caseRec.OwnerId = testadminUser3.Id;
            
            try{
                
                System.debug('User Profile:: '+UserInfo.getProfileId());
                caseRec.OwnerId = testadminUser3.Id;
                 caseRec.CC_Share_with_Customer_Concerns__c=true; 

                update caseRec;
                
            }catch(Exception e)
            {
                System.debug(e.getMessage());
            }
            
            System.runAs ( testadminUser ){
				testadminUser2.IsActive = false;
				update testadminUser2;
			}
            
            caseRec.OwnerId = testadminUser3.Id;
            try{
                update caseRec;
            }catch(Exception e)
            {
                System.debug(e.getMessage());
            }
            
        }
        
        
        Test.stopTest();
    }
}