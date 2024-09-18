/**********************************************************************
Name: EDGE_CaseFeedtoCaseCommentTriggerTest
=======================================================================
Req: This is the test class for EDGE_CaseFeedtoCaseCommentTriggerHelper

***********************************************************************/
@IsTest
public class EDGE_CaseFeedtoCaseCommentTriggerTest {
    public static Map <String,Schema.RecordTypeInfo> mapAccountRecordTypes = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
    public static Id caseRecTypeId = mapAccountRecordTypes.get('Diageo One Cases').getRecordTypeId();
	
    
    @isTest
    public static void createTestData(){
        EDGE_UtilityTestClass.createOrgSettings();        
        User activationSpecialist=EDGE_UtilityTestClass.runAsUser('testActivationSpecialist','Activation Specialist');
        activationSpecialist.Available_Countries__c='AU';
        insert activationSpecialist;
        system.assert(activationSpecialist!=null,'activationSpecialist should not be null');
        System.runAs(activationSpecialist){
            Case case1=new Case();
            case1.RecordTypeId=Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical Issue').getRecordTypeId();
            case1.Status='New';
            case1.Origin='Diageo One';
            insert case1;
            FeedItem feed=new FeedItem();
            feed.Body='Text Area';
            feed.parentId=case1.Id;
            feed.Type='TextPost';
            insert feed;
        }           
    }    
}