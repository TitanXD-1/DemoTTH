@isTest
public class ECM_EandS_AmplificationControllerTest {
    
    
      @isTest
    public static void setupAU() {
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        //String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        //String contractRecordGroupTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        
        //Territory for outlet
        Territory__c  testTerritory = EDGE_UtilityTestClass.getTerritoryRec();
        insert testTerritory;
        system.assert(testTerritory.Id != null,'testTerritory Id should not be null');
        
        //Contract Mandatory Records : Account
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        
        //Contract Mandatory Records : Agreement Type
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.Name='PromotionalAU';
        contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
        contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment;Product Growth Strategy';
        insert contractType;
        
        //Boolean checkVal = ECM_CreateContractControllerEandS.getAgreementType(contractType.Id);
        
        
        //Setting up three contracts : one with 'min UoM' & another one with '9LC EU' product uoM, one group contract
        Contract objContractAU = EDGE_UtilityTestClass.getContract(acc.Id, contractRecordTypeId);
        objContractAU.Status = 'Draft';
        objContractAU.ECM_Territory__c=testterritory.Id;
        objContractAU.ECM_Agreement_Type__c=contractType.Id;
        objContractAU.ECM_Channel__c='On-Premise';
        objContractAU.StartDate = system.today().addmonths(-6).toStartOfMonth();
        objContractAU.Contract_End_Date__c = system.today().addmonths(6).addDays(-1);
        
        ECM_CreateContractControllerEandS.savecontract(objContractAU);
        //ECM_CreateContractControllerEandS.getListCon(objContractAU);
        
        //ECM-5638
        ECM_EandS_AmplificationController.getData(objContractAU.Id);
        ECM_EandS_AmplificationController.getAmplificationData(objContractAU.Id);
        String json='[{"Name":"Website","sectionData":[{"isDelete":false,"amplification":{"ECM_Logo_Inculsion__c":"Yes","ECM_Brand__c":"new","ECM_Home_Page_Banners__c":"Yes","ECM_Run_of_Site_Banners__c":"Yes","ECM_Asset_Productions__c":"Diageo","ECM_Redirect_Links__c":"https://yahoo.in"}}],"sectionFields":[{"data":"","dataType":"PICKLIST","label":"Logo Inculsion","picklistValues":["Yes","No"],"value":"ECM_Logo_Inculsion__c"},{"data":"","dataType":"STRING","label":"Brand","picklistValues":[],"value":"ECM_Brand__c"},{"data":"","dataType":"PICKLIST","label":"Home Page Banners","picklistValues":["Yes","No"],"value":"ECM_Home_Page_Banners__c"},{"data":"","dataType":"PICKLIST","label":"Run of Site Banners","picklistValues":["Yes","No"],"value":"ECM_Run_of_Site_Banners__c"},{"data":"","dataType":"PICKLIST","label":"Asset Productions","picklistValues":["Diageo","Event Organiser"],"value":"ECM_Asset_Productions__c"},{"data":"","dataType":"URL","label":"Redirect Links","picklistValues":[],"value":"ECM_Redirect_Links__c"}]},{"Name":"App","sectionData":[{"isDelete":false,"amplification":{"ECM_Logo_Inculsion__c":"Yes","ECM_Brand__c":"New","ECM_Home_Page_Banners__c":"Yes","ECM_Run_of_Site_Banners__c":"Yes","ECM_Push_Notifications__c":"Yes","ECM_Asset_Productions__c":"Diageo"}}],"sectionFields":[{"data":"","dataType":"PICKLIST","label":"Logo Inculsion","picklistValues":["Yes","No"],"value":"ECM_Logo_Inculsion__c"},{"data":"","dataType":"STRING","label":"Brand","picklistValues":[],"value":"ECM_Brand__c"},{"data":"","dataType":"PICKLIST","label":"Home Page Banners","picklistValues":["Yes","No"],"value":"ECM_Home_Page_Banners__c"},{"data":"","dataType":"PICKLIST","label":"Run of Site Banners","picklistValues":["Yes","No"],"value":"ECM_Run_of_Site_Banners__c"},{"data":"","dataType":"PICKLIST","label":"Push Notifications","picklistValues":["Yes","No"],"value":"ECM_Push_Notifications__c"},{"data":"","dataType":"PICKLIST","label":"Asset Productions","picklistValues":["Diageo","Event Organiser"],"value":"ECM_Asset_Productions__c"}]},{"Name":"Social","sectionData":[],"sectionFields":[{"data":"","dataType":"PICKLIST","label":"Media Platform","picklistValues":["Facebook","Instagram","Twitter","LinkedIn","YouTube","Pinterest","Snapchat","Tik Tok"],"value":"ECM_Media_Platform__c"},{"data":"","dataType":"STRING","label":"Posts","picklistValues":[],"value":"ECM_Posts__c"},{"data":"","dataType":"PICKLIST","label":"Organic","picklistValues":["Yes","No"],"value":"ECM_Organic__c"},{"data":"","dataType":"PICKLIST","label":"Paid (Boosted)","picklistValues":["Yes","No"],"value":"ECM_Paid_Boosted__c"},{"data":"","dataType":"PICKLIST","label":"If Paid, budget & budget Owner","picklistValues":["Diageo","Event Organiser"],"value":"ECM_If_Paid_budget_budget_Owner__c"},{"data":"","dataType":"PICKLIST","label":"Asset Productions","picklistValues":["Diageo","Event Organiser"],"value":"ECM_Asset_Productions__c"},{"data":"","dataType":"PICKLIST","label":"Asset Format","picklistValues":["Video","Still"],"value":"ECM_Asset_Format__c"},{"data":"","dataType":"STRING","label":"Brand","picklistValues":[],"value":"ECM_Brand__c"},{"data":"","dataType":"STRING","label":"Hashtags","picklistValues":[],"value":"ECM_Hashtags__c"}]},{"Name":"eDM","sectionData":[],"sectionFields":[{"data":"","dataType":"PICKLIST","label":"Logo Inculsion","picklistValues":["Yes","No"],"value":"ECM_Logo_Inculsion__c"},{"data":"","dataType":"PICKLIST","label":"Banners","picklistValues":["Yes","No"],"value":"ECM_Banners__c"},{"data":"","dataType":"PICKLIST","label":"Content Inclusions","picklistValues":["Editorial","Still","Video","Copy"],"value":"ECM_Content_Inclusions__c"},{"data":"","dataType":"URL","label":"Redirect Links","picklistValues":[],"value":"ECM_Redirect_Links__c"},{"data":"","dataType":"PICKLIST","label":"Asset Productions","picklistValues":["Diageo","Event Organiser"],"value":"ECM_Asset_Productions__c"}]},{"Name":"Shared","sectionData":[],"sectionFields":[{"data":"","dataType":"PICKLIST","label":"Diageo Social","picklistValues":["Facebook","Instagram","Snapchat","Tik Tok","Twitter","Other (new to market)"],"value":"ECM_Diageo_Social__c"},{"data":"","dataType":"PICKLIST","label":"Diageo Websites/Apps","picklistValues":["Yes","No"],"value":"ECM_Diageo_Websites_Apps__c"},{"data":"","dataType":"PICKLIST","label":"Diageo Retail Customers","picklistValues":["Yes","No"],"value":"ECM_Diageo_Retail_Customers__c"},{"data":"","dataType":"PICKLIST","label":"Diageo Press Office","picklistValues":["Yes","No"],"value":"ECM_Diageo_Press_Office__c"},{"data":"","dataType":"PICKLIST","label":"Diageo Influencers","picklistValues":["Yes","No"],"value":"ECM_Diageo_Influencers__c"}]}]';
        ECM_EandS_AmplificationController.saveAmplificationData(objContractAU.Id,json);
    }

}