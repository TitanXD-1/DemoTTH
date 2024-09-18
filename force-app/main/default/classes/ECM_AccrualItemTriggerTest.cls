/*
 * @Name: ECM_AccrualItemTriggerTest
 * @Purpose: This class is used to cover testclass for the - AccrualItemTrigger, AccrualItemTriggerHandler & ECM_AccrualItemTriggerHelper
 * @History
 *
 * VERSION    	AUTHOR       		DATE                DETAIL
 * 1.0     		Nidhi && Sagnik		27/10/2022			ECM-6256 to populate country from account's country
 * 2.0          Sakshi Shah         16/05/2024          PMD Fix
*/ 

@isTest
public class ECM_AccrualItemTriggerTest 
{
  @isTest
    public static void testInsert()
    {
        ECM_Accrual__c accrualRec = createdata();
        ECM_Accrual_Item__c accrualItem = new ECM_Accrual_Item__c(ECM_Accrual__c = accrualRec.id);
        EDGE_UtilityTestClass.createOrgSettings();
        insert accrualItem;
        system.assert(accrualItem.Id != null, 'accrualItem Id should not be null');
        
        Assert.isNotNull(accrualItem.id,'Accrual Item Id should not be null.');
        ECM_Accrual_Item__c accItem=[SELECT ID,CurrencyIsoCode FROM ECM_Accrual_Item__c WHERE ECM_Accrual__c=:accrualRec.id  ];
        Assert.areEqual(accrualRec.CurrencyIsoCode, accItem.CurrencyIsoCode,'Currency ISO codes do not match.');
    }
    
    @isTest
    public static void testUpdate()
    {
        ECM_Accrual__c accrualRec = createdata();
        ECM_Accrual_Item__c accrualItem = new ECM_Accrual_Item__c(ECM_Accrual__c = accrualRec.id);
        EDGE_UtilityTestClass.createOrgSettings();
        insert accrualItem;
        system.assert(accrualItem.Id != null, 'accrualItem Id should not be null');
        
        accrualitem.CurrencyIsoCode= 'EUR';
        update accrualItem;
        Assert.areNotEqual(accrualRec.CurrencyIsoCode, accrualitem.CurrencyIsoCode,'Currency ISO codes do not match.');
    }
    @isTest
    public static void testDelete()
    {
        ECM_Accrual__c accrualRec = createdata();
        ECM_Accrual_Item__c accrualItem = new ECM_Accrual_Item__c(ECM_Accrual__c = accrualRec.id);
        EDGE_UtilityTestClass.createOrgSettings();
        insert accrualItem;
        system.assert(accrualItem.Id != null, 'accrualItem Id should not be null');
        
        delete accrualItem;
        List<ECM_Accrual_Item__c> accList= new List<ECM_Accrual_Item__c>();
        accList=[SELECT ID FROM ECM_Accrual_Item__c];
        Assert.isTrue(accList.isEmpty(),'The account list should be empty.');
        
        undelete accrualItem;
    }
    /** 
     *@description Create Data for Testing 
     *@return ECM_Accrual__c
    **/
    public static ECM_Accrual__c createdata()
    {
        //Set up geography & User records
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        
        User salesRep = ECM_UtilityTestClass.createUser('sr',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'srUsr@test.com';
        salesRep.isActive = true;
        salesRep.Available_Countries__c = 'ES';
        insert salesRep;
        
        //Mandatory Record to create contract : agreement type & account
        ECM_Contract_Type__c conType = ECM_UtilityTestClass.createContractType(geographyId);
        conType.Name='Promotional';
        conType.ECM_Volume_UoM_for_Beer__c = 'EU';
        conType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;UoM;Rate Per UoM;Investment';
        insert conType;
        
        Account accRec = EDGE_UtilityTestClass.getOutletRecord();
        accRec.Person_Responsible__c= salesRep.Id;
        accRec.OwnerId = salesRep.Id;
        insert accRec;
        
        //Create Contract
        String recType = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objCon = EDGE_UtilityTestClass.getContract(accRec.Id, recType);
        objCon.Status = 'Draft';
        objCon.Contract_End_Date__c = System.today();
        objCon.ECM_Agreement_Type__c = conType.Id;
        objCon.StartDate = system.today();
        objCon.ECM_Duration__c = 12;
        objCon.Contract_End_Date__c = system.today()+360;
        objCon.ECM_Overall_Investment_Amount__c=30.00;
        insert objCon;
        
        ECM_Accrual__c accrualRec=new  ECM_Accrual__c();
        accrualRec.ECM_Contract__c=objCon.id;
        accrualRec.CurrencyIsoCode='GBP';
        insert accrualRec;
        return accrualRec;
    }
}