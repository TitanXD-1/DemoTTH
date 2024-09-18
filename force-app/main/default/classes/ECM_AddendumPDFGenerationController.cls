/*
Name: ECM_AddendumPDFGenerationController
Purpose: This is Class for validating generate PDF for Addendum
PDF file in the linked Addendum Type = Add new Products 
Test Class:ECM_fileViewerCtrl_Test
History     

VERSION    AUTHOR                   DATE              DETAIL
1.0      Vinay Tummala            30/08/2022       Initial Developmemt-ECM-5954 
2.0      Joshraj Sen              01/04/2024       152305
*/
public with sharing  class ECM_AddendumPDFGenerationController {
    /*public ECM_AddendumPDFGenerationController() {
        
    }*/
    public String contractId{get; set;}
    public String country{get; set;}
    public String addendumId{get; set;}
    public ECM_AddendumPDFGenerationController(ApexPages.StandardController controller){
        fileViewerCtrls();
    }
      public void fileViewerCtrls(){
        String profileName='';
        //list<ContentDocumentLink> ContentDocscheck= new list<ContentDocumentLink>();
        string paramid= System.currentPageReference().getParameters().get('Id');       
        addendumId = paramid;
        List<Profile> profileList = [SELECT Id,Name FROM Profile WHERE Id =:UserInfo.getProfileId() WITH SECURITY_ENFORCED];
        profileName= profileList[0].Name;
        ECM_Addendum__c addendum = [SELECT Id,ECM_Contract__c,ECM_Status__c from ECM_Addendum__c WHERE id=:addendumId WITH SECURITY_ENFORCED];  
        //contract con = [select id,status from contract where id=:addendum.ECM_Contract__c ];
        contractId = addendum.ECM_Contract__c;
        country = getallowedCountry(contractId);
        
    }
    public String getallowedCountry(String contractId){  
        //variables
        //List<ECM_Technical_Market_Setting__mdt> mktSetList =  new List<ECM_Technical_Market_Setting__mdt>();
        String countryCode = [SELECT Id, Account.Country_Code__c FROM Contract WHERE Id = :contractId].Account.Country_Code__c;
        return countryCode;
    }
}