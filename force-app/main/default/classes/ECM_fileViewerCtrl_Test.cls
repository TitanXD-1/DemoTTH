@istest
public class ECM_fileViewerCtrl_Test {

@isTest static void testNegative() {
    Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
    outletAccount.Person_Responsible__c= UserInfo.getUserId();
    outletAccount.OwnerId = UserInfo.getUserId();
    //outletAccount.Operator__c=contractType.id;
    insert outletAccount;
    System.assert(outletAccount!=null,'outletAccount should not be null');
    
    String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
    Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
    Insert objContract;
    objContract.status='Approved';
    update objContract;
            
    ECM_Addendum__c addendum= new ECM_Addendum__c();
    addendum.ECM_Addendum_Type__c='T&C (Terms & Conditions)';
    addendum.ECM_Contract__c=objContract.Id;
    addendum.ECM_Status__c='Approved';
    insert addendum;
    ECM_Addendum__c addendumSpain = new ECM_Addendum__c();
    addendumSpain.ECM_Addendum_Type__c='Add New Product';
    addendumSpain.ECM_Contract__c=objContract.Id;
    addendumSpain.ECM_Status__c='Draft';
    insert addendumSpain;
    
    contentVersion cv= new contentversion();
    cv.Title='File Preview';
    cv.versionData=blob.valueOf(String.valueOf('File Preview'));
    cv.PathOnClient='S';
    insert cv;
    
    List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
    
    ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (addendum.Id,documents[0].Id);
    insert conDocLnkRec;
    ContentDocumentLink conDocLnkRecSpain = EDGE_UtilityTestClass.getConDocLink (addendumSpain.Id,documents[0].Id);
    insert conDocLnkRecSpain;
    //Newly added
    List<ECM_Technical_Market_Setting__mdt> mktSetList =  new List<ECM_Technical_Market_Setting__mdt>();
    mktSetList = [SELECT masterlabel,ECM_Country__c,Render_PDF__c 
                    FROM ECM_Technical_Market_Setting__mdt 
                    WHERE ECM_Country__c ='AUS'];
    //Newly Added
    Test.startTest();
    PageReference pageref= Page.ECM_filePreview;
    Test.setCurrentPage(pageref);
    pageRef.getParameters().put('id',objContract.id);
    ApexPages.StandardController sc = new ApexPages.standardController(objContract);
    ECM_fileViewerCtrl  controller;
        controller = new ECM_fileViewerCtrl(sc);
    PageReference pagerefSpain= Page.ECM_filePreview;
    Test.setCurrentPage(pagerefSpain);
    pagerefSpain.getParameters().put('Id',addendumSpain.id);
    //pageRef.getParameters().put('addendumId',addendumSpain.id);
    ApexPages.StandardController scSpain = new ApexPages.standardController(objContract);
    ECM_AddendumPDFGenerationController  controllerSpain;
        controllerSpain = new ECM_AddendumPDFGenerationController(scSpain);//Test Class for ECM_AddendumPDFGenerationController.apxc
    
    
    Test.stopTest();
}

}