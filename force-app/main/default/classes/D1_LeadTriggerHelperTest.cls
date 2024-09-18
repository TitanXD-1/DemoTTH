/**
  * @name D1_LeadTriggerHelperTest
  * @purpose This is the test class for D1_LeadTriggerHelper
  * @history                                                                                                                       
  * @VERSION  	AUTHOR            DATE              DETAIL
  * @1.0      	Sayan			13/08/2021         NCP-4081
  **/
@isTest
public class D1_LeadTriggerHelperTest {
    /**
     * @description Test data setup for D1_LeadTriggerHelperTest
     **/
    
    @testSetup
    public static void setup(){

        //Create Geography
        D1_TestDataUtility.setupCountry('GB');
        D1_TestDataUtility.createOrgSettings();   
        Lead newLead = D1_TestDataUtility.createLead();
        newLead.Country_ISO_Code__c = 'GB';

        insert newLead;
    }
    /**
     * @description testValidatePhoneNumber method
     **/
    @isTest
    public static void testValidatePhoneNumber(){//NCP-4081
        
  		Lead newLead = [SELECT company, status, firstname, lastname, Email, MobilePrefix__c, Mobile__c, PhonePrefix__c, Phone__c, 
                        MobilePhone, Phone from Lead where Email = 'email2@gmail.com' Limit 1];
        System.assertEquals('+441512123452', newLead.MobilePhone, 'phone number does not match');
        Test.startTest();
        newLead.Status  = 'Closed';
        update newLead;
        delete newLead;
        undelete newLead;
        Test.stopTest();	 
    }
}