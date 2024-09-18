/***
* @Name: EDGE_ProductKPIAchivementBatchTest
* @Req: This is the test class for EDGE_ProductKPIAchivementBatch
* @History                                                            
* @VERSION     AUTHOR              DATE              DETAIL
	1.0         Dipanjan D          12/12/2019        Test Class for EDGE_ProductKPIAchivementBatch
    2.0         Joshraj Sen         08/04/2024        152305
*/

@isTest
public class EDGE_ProductKPIAchivementBatchTest{
    @isTest
    public static void productKPIAchivementBatchTest(){
        createData();
        //negativeScenario();
        system.debug(LoggingLevel.Debug,[select Id from Territory__c]);
        //List<Outlet_Execution__c> listOut = 
        //system.debug([select count(Id),sum(Distribution_Formula__c),sum(NPD_Formula__c), Outlet__r.Primary_Sales_Territory__c, Product__c FROM Outlet_Execution__c WHERE Outlet__r.Status__c = 'Active' AND recordType.Name='Product' GROUP By Outlet__r.Primary_Sales_Territory__c, Product__c]);
        // system.debug('@@@@'+listOut[0]);
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_ProductKPIAchivementBatch'
                                                  and Country_Code__c ='JP' ];
        system.assert(batchSetting.Id != null,'Batch is Added');
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
    }
    @isTest
    public static void createData(){
        
        Test.startTest();
        //EDGE_UtilityTestClass.createOrgSettings();
        // create Geography record
        String prodRecTypeId = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product').getRecordTypeId();
        String prodKPIRecTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product KPI').getRecordTypeId();  
        Id countryID = EDGE_UtilityTestClass.setupCountry('JP'); 
        //insert pickup option
        String pickupRecType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryID,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[JP]';
        pickupOption.RecordTypeId = pickupRecType;
        insert pickupOption;
        system.assert(pickupOption.Id != null,'Pickup Option is Added');
        
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
        
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;
        
        Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHier.Parent_BU__c = terriHierSA.Id;
        insert terriHier;
        
        Territory__c  territory1 = EDGE_UtilityTestClass.getTerritoryRec();
        territory1.Current_OES_Rank__c= 12.0;//+ countOfTerr;
        territory1.Country__c = countryId;
        territory1.Current_OES_Score__c = 10.0;// + countOfTerr;
        territory1.Current_OES_Rank__c = 11.0;// + countOfTerr;
        territory1.Territory_Type__c = 'Sales';
        territory1.Pending_For_Batch__c = true;
        territory1.Sales_Area__c = terriHierSA.Id; 
        territory1.Region__c = terriHier.Id;
        territory1.Status__c = 'Active';
        insert territory1;
        
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();
        outlet1.BillingStreet = 'Ginza 5-5-9 Augio Ginza Building 7F';
        outlet1.BillingCity = 'Chuo-ku';
        outlet1.BillingCountry = 'Japan';
        outlet1.BillingState = 'Tokyo';
        outlet1.BillingPostalCode = '1040061';
        outlet1.BillingCountryCode = 'JP';
        outlet1.Primary_Sales_Territory__c= territory1.Id;
        outlet1.Primary_Sales_Territory_Region__c=terriHier.id;
        outlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outlet1;
        
        Product__c skuProduct = EDGE_UtilityTestClass.getProd();
        skuProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        skuProduct.Start_Date__c = system.today();
        insert skuProduct;
        KPI_Achivement__c kpiRec = new KPI_Achivement__c();
        kpiRec.RecordTypeId=prodKPIRecTypeId;
        kpiRec.Territory__c= territory1.Id;
        kpiRec.Product__c=skuProduct.Id;
        kpiRec.KPI_Type__c = 'NPD';
        kpiRec.Country__c = countryId;
        kpiRec.Achievement__c = 15;
        kpiRec.Total_Denominator__c = 20 ;
        insert kpiRec;
        
        Outlet_Execution__c outExecObj = EDGE_UtilityTestClass.getOutletExecution(outlet1.Id);
        outExecObj.RecordTypeId=prodRecTypeId;
        outExecObj.Product__c = skuProduct.Id; 
        outExecObj.Distribution_TRAX__c='Yes';
        outExecObj.NPA__c='Yes';
        insert outExecObj; 
        Test.stopTest();
    
    
     }
}