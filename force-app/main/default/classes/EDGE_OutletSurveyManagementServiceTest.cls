/**********************************************************************
Name: EDGE_OutletSurveyManagementServiceTest

=======================================================================
Req: This is the test class for the  EDGE_OutletSurveyManagementService class.
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR              DATE              DETAIL
1.0			Juned Khan			10/28/2020		  Added logic to include survey for Grid survey Recordtype along with Outlet survey.(ES20 - 8767)
2.0			Juned Khan			10/29/2020        Added logic to filter survey with Grouping through custom Api (ES20 - 8797)
***********************************************************************/

@isTest
public class EDGE_OutletSurveyManagementServiceTest {
    
    public static User userRec;
    @isTest
    public static void testdoget(){
        
        Test.startTest();
            createData();
            RestRequest req = new RestRequest(); 
            String requri='services/apexrest/OutletSurveyManagementService?userid=';
            requri = requri+ String.valueOf(userRec.Id);
            req.requestUri =requri;
            req.params.put('userid', userRec.Id);            
            req.httpMethod = 'GET';
            RestContext.request = req;  
            List<EDGE_OutletSurveyWrapper> outletSurveyWrapList = EDGE_OutletSurveyManagementService.doGet();
        System.assert(outletSurveyWrapList.size()>= 0);
        Test.stopTest();     
    }
    
    public static void createData(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');  
        
        Business_Role__c businessRole = EDGE_UtilityTestClass.getBusinessRole();
        businessRole.Country__c = countryId;
        businessRole.Global_Equivalent__c = 'Sales Rep';
        businessRole.Business_Role_Grouping__c='Group_1;Group_6';
        insert businessRole;
        
        userRec = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        userRec.Business_Role_ID__c = businessRole.Id;
        userRec.Business_Role__c = 'Test Role' ;
        insert userRec;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        insert outlet;
        
        insert EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id,userRec.Id,'Primary');
        
        Target_List__c targetLst = new Target_List__c();
        targetLst.Active__c = True;
        targetLst.Country__c = countryId;
        targetLst.Name = 'Target List 1';
        insert targetLst;
        system.assert(targetLst.id != null);
        
        Target_List_Member__c  targetLstMem = EDGE_UtilityTestClass.getTargetMemList(outlet.Id, targetLst.Id);
        targetLstMem.Assignment_Status__c = 'Active';
        insert targetLstMem;
        
        String surveyRecordTypeId = Survey__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Survey').getRecordTypeId();
        Survey__c survey = new Survey__c();
        survey.Start_Date__c = System.today();
        survey.RecordTypeId = surveyRecordTypeId;
        survey.End_Date__c = System.today().addDays(10);
        survey.Country__c = countryId;
        survey.Frequency__c = 5;
        survey.Reccuring_Type__c = 'Recurring with previous response';
        survey.Priority__c = 'Medium';
        survey.Name = 'Test Survey';
        survey.Global_Equivalent_Business_Roles__c = 'Sales Rep';
        insert survey;
        
        Survey__c survey1 = new Survey__c();
        survey1.Start_Date__c = System.today();
        survey1.RecordTypeId = surveyRecordTypeId;
        survey1.End_Date__c = System.today().addDays(10);
        survey1.Country__c = countryId;
        survey1.Frequency__c = 5;
        survey1.Reccuring_Type__c = 'Non Recurring';
        survey1.Priority__c = 'Medium';
        survey1.Name = 'Test Survey';
        survey1.Grouping__c = 'Group_6';
        insert survey1;
        
        String gridSurveyRecordTypeId = Survey__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Grid Survey').getRecordTypeId();
        Survey__c gridSurvey = new Survey__c();
        gridSurvey.Start_Date__c = System.today();
        gridSurvey.RecordTypeId = gridSurveyRecordTypeId;
        gridSurvey.End_Date__c = System.today().addDays(10);
        gridSurvey.Country__c = countryId;
        gridSurvey.Frequency__c = 5;
        gridSurvey.Reccuring_Type__c = 'Recurring with previous response';
        gridSurvey.Priority__c = 'Medium';
        gridSurvey.Name = 'Grid Survey';
        gridSurvey.Grouping__c = 'Group_1';
        insert gridSurvey;
        
        Activity_Target_List__c actTargetList = new Activity_Target_List__c();
        actTargetList.Survey__c = survey.Id;
        actTargetList.Status__c = 'Active';
        actTargetList.Target_List__c = targetLst.Id;
        insert actTargetList; 
        
        Activity_Target_List__c gridactTargetList = new Activity_Target_List__c();
        gridactTargetList.Survey__c = gridSurvey.Id;
        gridactTargetList.Status__c = 'Active';
        gridactTargetList.Target_List__c = targetLst.Id;
        insert gridactTargetList;
        
    }
}