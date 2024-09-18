/**********************************************************************
Name: EDGE_OutletKPITriggerHelperTest
=======================================================================
Req: Test Class for TravelLogTrigger

======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Shahbaz Khan		24/02/2020		  Test class for TravelLogTrigger
***********************************************************************/
@isTest
public class EDGE_TravelLogTriggerTest {
    @isTest
    public static void travelLogTriggerTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Personal_Information__c persInfo = new Personal_Information__c();
        persInfo.Registration_Number__c = '262';
        insert persInfo;
        
        Travel_Log__c travelLog = new Travel_Log__c();
        travelLog.Personal_Information__c = persInfo.id;
        travelLog.Start_Date__c = system.today();
        travelLog.End_Date__c = system.today() + 2;
        insert travelLog;
        system.assert(travelLog.id!=null);
        travelLog.Distance_Traveled__c = 90;
        update travelLog;
        delete travelLog;
        undelete travelLog;
        
    }

}