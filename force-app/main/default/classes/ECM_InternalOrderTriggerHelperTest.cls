/*
 @Name: ECM_InternalOrderTriggerHelperTest
 @Description: This is the Test class for ECM_InternalOrderTriggerHelper
 @History                                                            
                                                        
 VERSION    AUTHOR       DATE                 DETAIL
  1.0     CM DEV Team                     INITIAL DEVELOPMENT              
  2.0     Pratap Sen  24-12-2021  Technical Debt Changes against ECM-4994
*/ 
@isTest
public class ECM_InternalOrderTriggerHelperTest
{
   /**
    * @Name : insertInternalOrderActionCheck
	* @description : It tests the updateIOFasicalYear() & the checkAndGenerateSharing() method of the ECM_RoleAgreementTriggerHelper class
	*/
    @isTest
    public static void insertInternalOrderActionCheck()
    {
        Test.startTest();
        try
        {
            WrapperInst wrapObj = createData();
            system.assert(wrapObj.listIOObj[0].id != null,'insertion successful');
        }
        catch(exception ex)
        {
            System.debug(LoggingLevel.WARN,'Exception caught '+ex);
        }
        Test.stopTest();
    }
   /**
    * @Name : updateInternalOrderActionCheck
	* @description : It tests the updateIOFasicalYearOnBefore & the validateAndReGenerateSharing() method of the ECM_RoleAgreementTriggerHelper class
	*/
    @isTest
    public static void updateInternalOrderActionCheck()
    {
        Test.startTest();
        try
        {
            WrapperInst wrapObj = createData();
            for(ECM_Internal_Order__c ioRec : wrapObj.listIOObj)
            {
                ioRec.ECM_End_Date__c = ioRec.ECM_End_Date__c.addYears(1);//start year + 1 = end year
            }
            update wrapObj.listIOObj;
			System.assertEquals(wrapObj.listIOObj[0].ECM_End_Date__c.Year(),wrapObj.listIOObj[0].ECM_Start_Date__c.Year()+1,'update successful');
            
            for(ECM_Internal_Order__c ioRec : wrapObj.listIOObj)
            {
                ioRec.ECM_End_Date__c = ioRec.ECM_End_Date__c.addYears(1);//start year + 2 = end year;
                ioRec.ECM_Geography__c = wrapObj.countrytoUpdate;
            }
            update wrapObj.listIOObj;
        }
        catch(exception ex)
        {
            System.debug(LoggingLevel.WARN,'Exception caught '+ex);
        }
        Test.stopTest();
    }   
   /**
    * @Name : createData()
	* @description : This method is used to create test data to test methods of the ECM_InternalOrderTriggerHelper class
    * @return : returns Wrapper with a List of Internal Orders and one geography Id
	*/   
    public static WrapperInst createData()
    {
        EDGE_UtilityTestClass.createOrgSettings();
        
        //setting up two geography contry
        Id countryId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Geography__c countrytoUpdate ;
        Id parentGeography = [SELECT Parent_Geography__c FROM Geography__c WHERE Id=:countryId].Parent_Geography__c;
        if(parentGeography != NULL)
        {
            countrytoUpdate = EDGE_UtilityTestClass.createGeography('Country');
            countrytoUpdate.Name = 'ES1_Country';
            countrytoUpdate.Code__c = 'ES1';
            countrytoUpdate.Parent_Geography__c = parentGeography;
            countrytoUpdate.RecordTypeId = EDGE_UtilityTestClass.CountryRecTypeId;
            countrytoUpdate.Extended_Country_Code__c = 'ES1-ES';
            insert countrytoUpdate;
        }
        
        //Setting up product record - mandatory field for non-AU Internal Orders
        Product__c product = ECM_UtilityTestClass.createProduct(countryId,'Test-Product');
        product.Product_Full_Name__c = 'Test-Product-ES';
        insert product;
        
        //setting up Internal Order Record List with start and end period of same year
        List<ECM_Internal_Order__c> listIO = new List<ECM_Internal_Order__c>();
        Date startDateIO = Date.newInstance(System.today().year(),1,1);
        for(Integer ioIt = 0; ioIt < 12; ioIt++)
        {
        	ECM_Internal_Order__c ioRec = ECM_UtilityTestClass.getInternalOrder(countryId);
            ioRec.ECM_Start_Date__c = startDateIO;
            ioRec.ECM_End_Date__c = startDateIO.addMonths(1);
            ioRec.ECM_Product__c = product.Id;
            listIO.add(ioRec);
            startDateIO = startDateIO.addMonths(1);
        }
        insert listIO;
        
        //wrapping up all the data
        WrapperInst wrapObj = new WrapperInst();
        wrapObj.listIOObj = listIO;
        wrapObj.countrytoUpdate = countrytoUpdate.Id;
        return wrapObj;
    }
    class WrapperInst
    {
        List<ECM_Internal_Order__c> listIOObj{get;set;}
        String countrytoUpdate{get;set;}
    }
}