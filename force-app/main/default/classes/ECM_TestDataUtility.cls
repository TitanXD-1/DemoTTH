/*
* @ClassName : ECM_TestDataUtility
* @Description : creating test data
* @history
VERSION    AUTHOR                DATE              DETAIL
* 1.1      Saurav Paul       	 21/07/2021		   Create agreement type record
* 1.2      Saurav Paul       	 16/08/2021		   Added method getTerritoryHierarchy,getTerritory,getExtraApproval,getAgrmntApproval
*/
@isTest
public class ECM_TestDataUtility {
    
    String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId(); 
    /*
	* @description : Create Contract Type(Agreement Type)
	* @return : ECM_Contract_Type__c
	* @param : Country Id
	*/
    public static ECM_Contract_Type__c getAgreementType(Id contId){
        ECM_Contract_Type__c agreementType = new ECM_Contract_Type__c();
        agreementType.Name ='Promotional';
        agreementType.Geography__c = contId;
        agreementType.ECM_Abbreviation__c = 'POM';
        agreementType.Volume_UoM_for_Spirits__c = 'BTL';
        agreementType.ECM_Volume_UoM_for_Beer__c = 'Not Applicable';
        agreementType.ECM_Automatic_approval_amount_threshold__c = 40.00;
        agreementType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        agreementType.ECM_Mandatory_Fields_Check__c ='Prior To Submitting Contract For Approval';
        agreementType.Enable_Default_Payment_Frequency__c = true;
        agreementType.ECM_Prepayment_Reminder__c = 5;
        return agreementType;
    } 
    /*
	* @description : Create Territory Hierarchy
	* @return : Territory_Hierarchy__c
	* @param : Country Id, Parent Territory Hierarchy Id
	*/
    public static Territory_Hierarchy__c getTerritoryHierarchy(Id recId,Id conId, Id parBUId){
        Territory_Hierarchy__c hierObj = new Territory_Hierarchy__c();
        hierObj.Name = 'Test Spain BU';
        hierObj.RecordTypeId = recId;
        hierObj.Geography__c = conId;
        if(String.isNotBlank(parBUId)){
            hierObj.Parent_BU__c = parBUId;
        }
        return hierObj;
    }
    /*
	* @description : Create Territory
	* @return : Territory__c
	* @param : Country Id, Hierarcy Region Id
	*/
    public static Territory__c getTerritory(Id contId, Id hierRegionId){
        Territory__c territoryObj = New Territory__c();
        territoryObj.Name='Testterriotory';
        territoryObj.Territory_Type__c='Sales';
        territoryObj.Country__c = contId;
        territoryObj.Status__c ='Active';
        territoryObj.Region__c = hierRegionId;
        return territoryObj;
    }
    /*
	* @description : Create Extra Approval
	* @return : ECM_Extra_Approval__c
	* @param : Country Id, Territory Hierarchy Id
	*/
    public static ECM_Extra_Approval__c  getExtraApproval(Id contId, Id terrHierId){
        ECM_Extra_Approval__c extraAppObj = new ECM_Extra_Approval__c ();
        extraAppObj.ECM_Approver_Position_Name__c = 'Spain Extra Approver';
        extraAppObj.ECM_Approver_s_Email_Address__c = 'test@diageo.com';
        extraAppObj.ECM_Automatic_Approval_if_Total_Amount__c = false;
        extraAppObj.ECM_Delegated_Approver_Email_Address__c = 'test@diageo.com';
        extraAppObj.ECM_Enable_Delegation__c = true;
        extraAppObj.ECM_Geography__c = contId;
        extraAppObj.ECM_Legal_Related__c = false;
        extraAppObj.ECM_Lower_Limit_Amount__c = 100;
        extraAppObj.ECM_Re_Investment_Rate_Lower_Limit__c = 20;
        extraAppObj.ECM_Re_Investment_Rate_Upper_Limit__c =50;
        extraAppObj.ECM_Territory_Hierarchy__c = terrHierId;
        extraAppObj.ECM_Upper_Limit_Amount__c = 100;
        extraAppObj.ECM_Active__c = true;
        return extraAppObj;
    }
    /*
	* @description : Create Agreement Approval
	* @return : ECM_Agreement_Approval__c
	* @param : Agreement Type Id, Extra Approval Id
	*/
    public static ECM_Agreement_Approval__c getAgrmntApproval(Id agmntType , Id xtraApproval){
        ECM_Agreement_Approval__c aggApproObj = new ECM_Agreement_Approval__c();
        aggApproObj.ECM_Agreement_Type__c = agmntType;
        aggApproObj.ECM_Extra_Approval__c = xtraApproval;
        return aggApproObj;
    }
    
    /*
	* @description : Create Account
	* @return : Account
	* @param : User Id, Country Id
	*/
    public static Account getAccount(Id userId, Id countryId){
        Account outletAccount = new Account();
        outletAccount.Person_Responsible__c = userId;
        outletAccount.Name = 'TestAccount';
        outletAccount.OwnerId = userId;
        outletAccount.SAP_Sold_to__c = '3984021';
        outletAccount.VAT_Number__c = 'TAXID123';
        outletAccount.ECM_Legal_Name__c = 'Legal';
        outletAccount.Email_for_contracts_payments__c = 'manikandan.t@diageo.com.test';
        outletAccount.Country__c = countryId;
        outletAccount.IsOperator__c = true;
        return outletAccount;
    }
    
   
    
    public static Pick_Up_Options__c getPickupOptions(Id countryId, String type, Id pickupRecordTypeId){
        Pick_Up_Options__c banner = new Pick_Up_Options__c();
        banner.Name = 'Range[ES]';
        banner.Geography__c = countryId;
        banner.RecordTypeId = pickupRecordTypeId;
        banner.Type__c = type;
        return banner;
    }
    /*
	* @description : Create Contract
	* @return : Contract
	* @param : Territory Id, Agreement Type Id, Contract RecordType Id, User Id
	*/
    public static Contract getContract(Id territoryId, Id agmntType, Id contractRecordTypeId, Id userId){
        Contract conObj = new Contract();
        conObj.Status = 'Draft';
        conObj.Contract_End_Date__c = System.today()+29;
        conObj.ECM_Territory__c = territoryId;
        conObj.ECM_Agreement_Type__c = agmntType;
        conObj.RecordTypeId = contractRecordTypeId;
        conObj.ECM_Channel__c = 'On-Premise';
        conObj.StartDate = system.today();
        //conObj.ECM_Payment_Frequency__c = paymfreq;
        conObj.Contract_End_Date__c = system.today()+360;
        conObj.OwnerId = userId;
        return conObj;
    }
}