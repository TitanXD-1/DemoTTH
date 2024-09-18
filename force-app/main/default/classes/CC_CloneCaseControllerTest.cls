@isTest
public class CC_CloneCaseControllerTest {

    @isTest
    public static void getCloneCaseTest(){
        test.startTest();
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        User u = EDGE_UtilityTestClass.runAsUser('cc_ccc_user','System Administrator');
        insert u;
        
        User u1 = EDGE_UtilityTestClass.runAsUser('cc_cse_user','System Administrator');
        insert u1;
        
        EDGE_UtilityTestClass.setupCountry('AU');
        
        Account a = EDGE_UtilityTestClass.getOutletRecord();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Market').getRecordTypeId();
        a.CC_CCC__c = u.Id;
        a.CC_CSE__c = u1.Id;
        insert a;
        
        Case c = new Case();
        c.CC_Market__c = a.Id;
        insert c;
        
        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        //content.LinkedEntityId=sub.id;
        content.origin = 'H';
        insert content;
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=c.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'V';
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        test.stopTest();
        String result = CC_CloneCaseController.cloneAnySobjet(c.id);
        System.assertNotEquals(c.Id, result);
    }
    
    @isTest
    public static void getCloneCaseNullCheckTest(){
        String result = CC_CloneCaseController.cloneAnySobjet('');
        System.assertEquals('', result);
    }
}