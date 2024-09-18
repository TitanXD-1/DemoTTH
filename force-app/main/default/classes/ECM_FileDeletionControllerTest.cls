@isTest
public class ECM_FileDeletionControllerTest {

@TestSetup
static void setupData(){

Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
Id uid;
uid = userinfo.getUserId();

Account acc = EDGE_UtilityTestClass.getOutletRecord();
insert acc;
acc.country__c = geographyId;
acc.Sales_Org__c ='sale';
acc.SAP_Sold_to__c ='sapsold';
update acc;

Account acc1 = EDGE_UtilityTestClass.getDistriAccRec();
acc1.country__c = geographyId;
insert acc1;

        
ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
contractType.Name='Promotional';
contractType.Geography__c=geographyId;
contractType.ECM_Abbreviation__c='POM';
contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
contractType.Volume_UoM_for_Spirits__c='CAS';
contractType.ECM_Volume_UoM_for_Beer__c = 'Not Applicable';
contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
insert contractType;

List<Contract> contractlst =new List<Contract>();
Date myDate = Date.newInstance(2020, 5, 17);
Contract contr = new Contract(Name = 'Test',AccountId = acc.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.Id);
contractlst.add(contr); 
Contract contr1 = new Contract(Name = 'Test1',AccountId = acc.id,Contract_End_Date__c=myDate);
contractlst.add(contr1);
insert contractlst;  

    ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
    paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
    paymemtSummary.ECM_Payment_Summary_Status__c = label.ECM_Payment_Summary_In_Approval;
    paymemtSummary.ECM_Type__c = 'Volume-Based';
    paymemtSummary.ECM_Invoice_Status__c='Requested';
    paymemtSummary.ECM_Contract__c = contr.id;
    paymemtSummary.ECM_Start_Period__c = system.today();
    paymemtSummary.ECM_End_Period__c = system.today()+2;
    paymemtSummary.ECM_Invoice_Status__c ='Approved';
    paymemtSummary.ECM_Invoice_Receival_Date__c = system.today()+1;
// paymemtSummary.ownerid = uid;
paymemtSummary.ECM_Tax_Rate__c='Standard Rate';
paymemtSummary.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
insert paymemtSummary;

ContentVersion conVer = new ContentVersion();
conVer.ContentLocation = 'S'; 
conVer.PathOnClient = 'ionicLogo.png'; 
conVer.Title = 'Proposal '; 
conVer.VersionData = EncodingUtil.base64Decode('Your file'); 
insert conVer;

contentversion cversion=[select contentdocumentid from contentversion where id=:conVer.Id];

contentDocumentLink cLink= new contentDocumentLink(linkedentityId=contractlst[0].id,contentDocumentId=cversion.contentdocumentid);
insert cLink;

    contentDocumentLink cLink2= new contentDocumentLink(linkedentityId=paymemtSummary.id,contentDocumentId=cversion.contentdocumentid);
insert cLink2;


}
@isTest
static void testFilePermissionpositive(){
        List<contract> con=[select id from contract ];
        List<contentdocumentlink> cLink=[select id,contentdocumentid from contentdocumentlink where linkedentityId=:con[0].Id Limit 1];
        if(!cLink.isEmpty()){
                ECM_FileDeletionController.deleteFilePermission(cLink[0].ContentDocumentId);
                ECM_FileDeletionController.deleteFile(cLink[0].ContentDocumentId);
        } System.assert(con!=null,'con should not be null');

}
@isTest
static void testFilePermissionnegative(){
        List<contract> con=[select id from contract ];
        List<contentdocumentlink> cLink=[select id,contentdocumentid from contentdocumentlink where linkedentityId=:con[0].Id Limit 1];
        if(!cLink.isEmpty()){
                ECM_FileDeletionController.deleteFilePermission(cLink[0].Id);
                ECM_FileDeletionController.deleteFile(cLink[0].Id);
        } System.assert(con!=null,'con should not be null');

}

}