/**
  * @name D1_NotificationTriggerHelperTest
  * @purpose This is the test class for D1_NotificationTriggerHelper
  * @history                                                                                                                       
  * @VERSION  	AUTHOR            DATE              DETAIL
  * 1.0         Narayana    22/04/2022      Initial Development [NCP-6450]
  **/
  @isTest
  public  class D1_NotificationTriggerHelperTest {
      @TestSetup
      public static void setup(){
        Test.startTest();
          Id countryId = D1_TestDataUtility.setupCountry('GB');
          D1_TestDataUtility.createOrgSettings();   
          Geography__c geog = new Geography__c(Id =countryId);
          
          D1_Setting__c d1setting = D1_TestDataUtility.createD1Settings(geog);
          insert d1setting;
          Id diageoOneAnnouncementRecordTypeId = Schema.SObjectType.Notification__c.getRecordTypeInfosByName().get('Diageo One Announcements').getRecordTypeId();
          Notification__c notificationRecord = new Notification__c();
          notificationRecord.Group_Name__c = 'GB_Indirect';
          notificationRecord.Short_Description__c='Test';
          notificationRecord.Start_Date__c=Date.Today();
          notificationRecord.End_Date__c=Date.Today()+1;
          notificationRecord.Language__c = 'en_GB';
          notificationRecord.Country__c = countryId;
          notificationRecord.Status__c ='Draft';
          notificationRecord.RecordTypeId =diageoOneAnnouncementRecordTypeId;
          insert notificationRecord;
        Test.stopTest();
      }
      /**
       * @description testValidatePreferredLanguage method
       **/
      @isTest
      public static void testValidatePreferredLanguage(){//NCP-6450
          
            Notification__c notificationRecord = [SELECT Group_Name__c, Short_Description__c, Start_Date__c, End_Date__c, Language__c, Country__c from Notification__c where Language__c = 'en_GB' Limit 1];
  
          List<Notification__c> notificationList = new List<Notification__c>();
          try
          {            
              Test.startTest();
              notificationRecord.Language__c='en_IE';
              notificationList.add(notificationRecord);
              update notificationList;
              Test.stopTest();	 
          }
          catch(exception e)
          {
              System.assert(e.getMessage()!=null, 'notification language not updated');
          }  
          
          
      }
  }