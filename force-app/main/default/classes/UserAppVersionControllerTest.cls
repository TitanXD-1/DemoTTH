@isTest(SeeAllData=False)
public class UserAppVersionControllerTest
{
    static testMethod void NewSyncStats() {
        List <User> userList = new List <User> ();
        User thisSalesRepUser = new User(
            alias               	= 'testd',
            Email               	= 'test.data1@testorg.com',
            EmailEncodingKey    	= 'UTF-8',
            LastName            	= 'Test212',
            FirstName           	= 'Data1',
            LanguageLocaleKey   	= 'en_US',
            LocaleSidKey        	= 'en_US',
            ProfileId           	= [SELECT Id FROM Profile WHERE Name ='Sales Representative' limit 1].Id,
            TimeZoneSidKey      	= 'Europe/London',
            Username            	= 'test.data1@testorg.com.quality',
            UserRoleId          	= null,
            Available_Countries__c	= 'ES',
            Default_Country__c = null
        );
        userList.add(thisSalesRepUser);
        User thisSalesRepUser2 = new User(
            alias               	= 'testq',
            Email               	= 'test.data3@testorg.com',
            EmailEncodingKey    	= 'UTF-8',
            LastName            	= 'Test123',
            FirstName           	= 'Data1',
            LanguageLocaleKey   	= 'en_US',
            LocaleSidKey        	= 'en_US',
            ProfileId           	= [SELECT Id FROM Profile WHERE Name ='Quality Representative' limit 1].Id,
            TimeZoneSidKey      	= 'Europe/London',
            Username            	= 'test.data1@testorg.com.sales',
            UserRoleId          	= null,
            Available_Countries__c	= 'IE',
            Default_Country__c = null
        );
        userList.add(thisSalesRepUser2);
        
        User thisSalesRepUser3 = new User(
            alias               	= 'test1q',
            Email               	= 'test.data3@testorg.com',
            EmailEncodingKey    	= 'UTF-8',
            LastName            	= 'Test1233',
            FirstName           	= 'Data1',
            LanguageLocaleKey   	= 'en_US',
            LocaleSidKey        	= 'en_US',
            ProfileId           	= [SELECT Id FROM Profile WHERE Name ='Sales Representative' limit 1].Id,
            TimeZoneSidKey      	= 'Europe/London',
            Username            	= 'test.data1@testorg.com.salesandroid',
            UserRoleId          	= null,
            Available_Countries__c	= 'CO',
            Default_Country__c = null
        );
        userList.add(thisSalesRepUser3);
        
        User thisSalesRepUser4 = new User(
            alias               	= 'test12q',
            Email               	= 'test.data3@testorg.com',
            EmailEncodingKey    	= 'UTF-8',
            LastName            	= 'Test1233sd',
            FirstName           	= 'Data1',
            LanguageLocaleKey   	= 'en_US',
            LocaleSidKey        	= 'en_US',
            ProfileId           	= [SELECT Id FROM Profile WHERE Name ='Sales Representative' limit 1].Id,
            TimeZoneSidKey      	= 'Europe/London',
            Username            	= 'test.data2@testorg.com.salesandroid',
            UserRoleId          	= null,
            Available_Countries__c	= 'CO',
            Default_Country__c = null
        );
        userList.add(thisSalesRepUser4);
        
        insert userList;
        
        User thisAdminUser = new User(
            alias               	= 'testd2',
            Email               	= 'test.data2@testorg.com',
            EmailEncodingKey    	= 'UTF-8',
            LastName            	= 'Test',
            FirstName           	= 'Data2',
            LanguageLocaleKey   	= 'en_US',
            LocaleSidKey        	= 'en_US',
            ProfileId           	= [SELECT Id FROM Profile WHERE Name ='System Administrator' limit 1].Id,
            TimeZoneSidKey      	= 'Europe/London',
            Username            	= 'test.data2@testorg.com',
            UserRoleId          	= null,
            Available_Countries__c	= 'ES',
            Default_Country__c = null
        );
        
        insert thisAdminUser;
        
        List<Sync_Stat__c> syncStat = new List<Sync_Stat__c>();
        DateTime startTime = system.today().addDays(-5);
        DateTime endTime = system.today().addDays(+5);
        System.runAs(thisAdminUser)
        {
        
        Sync_Stat__c syncData1 = new Sync_Stat__c();
        syncData1.User_OS_App__c='iOS';
        syncData1.Version_Sync__c='EDGE 365 Version1.7.4(2)';
        syncData1.Type__c='Super';
        syncData1.Whether_it_completed_successfully__c='yes';
        syncData1.Local_Start_Time__c=startTime;
        syncData1.Local_End_Time__c=endTime;
        syncData1.OwnerId=thisSalesRepUser.ID;
		syncStat.add(syncData1);
            
        Sync_Stat__c syncData2 = new Sync_Stat__c();
        syncData2.User_OS_App__c='iOS';
        syncData2.Version_Sync__c='EDGE 365 Version1.4.2(8)';
        syncData2.Type__c='Super';
        syncData2.Whether_it_completed_successfully__c='yes';
        syncData2.Local_Start_Time__c=startTime;
        syncData2.Local_End_Time__c=endTime;
        syncData2.OwnerId=thisSalesRepUser.ID;
		syncStat.add(syncData2);
            
        Sync_Stat__c syncData3 = new Sync_Stat__c();
        syncData3.User_OS_App__c='iOS';
        syncData3.Version_Sync__c='EDGE 365 Version1.7.4(1)';
        syncData3.Type__c='Super';
        syncData3.Whether_it_completed_successfully__c='yes';
        syncData3.Local_Start_Time__c=startTime;
        syncData3.Local_End_Time__c=endTime;
        syncData3.OwnerId=thisSalesRepUser2.ID;
		syncStat.add(syncData3);
            
        Sync_Stat__c syncData6 = new Sync_Stat__c();
        syncData6.User_OS_App__c='iOS';
        syncData6.Version_Sync__c='EDGE 365 Version1.7.4(2)';
        syncData6.Type__c='Super';
        syncData6.Whether_it_completed_successfully__c='yes';
        syncData6.Local_Start_Time__c=startTime;
        syncData6.Local_End_Time__c=endTime;
        syncData6.OwnerId=thisSalesRepUser2.ID;
		syncStat.add(syncData6);
            
        Sync_Stat__c syncData4 = new Sync_Stat__c();
        syncData4.User_OS_App__c='Android';
        syncData4.Version_Sync__c='Version 1.1.2';
        syncData4.Type__c='Super';
        syncData4.Whether_it_completed_successfully__c='yes';
        syncData4.Local_Start_Time__c=startTime;
        syncData4.Local_End_Time__c=endTime;
        syncData4.OwnerId=thisSalesRepUser3.ID;
		syncStat.add(syncData4);
        
        Sync_Stat__c syncData5 = new Sync_Stat__c();
        syncData5.User_OS_App__c='Android';
        syncData5.Version_Sync__c='Version 1.1.0';
        syncData5.Type__c='Super';
        syncData5.Whether_it_completed_successfully__c='yes';
        syncData5.Local_Start_Time__c=startTime;
        syncData5.Local_End_Time__c=endTime;
        syncData5.OwnerId=thisSalesRepUser4.ID;
		syncStat.add(syncData5);
        
        insert syncStat;
        
        UserAppVersionSetting__c ua= new UserAppVersionSetting__c();
        ua.Latest_App_Version__c='EDGE 365 Version1.7.4(2)';
        ua.Android_Latest_App_Version__c = 'Version 1.1.2';
        ua.Email__c = 'test@test.com';
        ua.Size__c = 1000;
        insert ua;
        
        System.Test.startTest();
        scheduledUserAppReport   emailBatchSch = new scheduledUserAppReport();
        String ebs = '0 11 18 7 5 ?'; system.schedule('Test App Batch Scheduler Check1', ebs, emailBatchSch);
        scheduledUserAppReport  emailBatch = new scheduledUserAppReport ();
        String eb = '0 11 18 7 5 ?'; system.schedule('Test App Version Check', eb, emailBatch);  
        
        System.Test.stopTest(); 
        }
    }
}