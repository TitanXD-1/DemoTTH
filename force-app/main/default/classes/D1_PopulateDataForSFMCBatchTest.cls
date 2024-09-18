/**
 * @name D1_PopulateDataForSFMCBatchTest
 * @purpose Test Class for D1_PopulateDataForSFMCBatch
 * @history                                                                                                                       
 * VERSION   AUTHOR             DATE            DETAIL
 * 1.0      Pratap Sen         10/04/23        NCP-8164
**/
@isTest
public class D1_PopulateDataForSFMCBatchTest {
	/**
     * @Name : setup
	 * @Description : This method is used to create dummy data for D1_PopulateDataForSFMCBatchTest class
	 */    
    @testSetup 
    public static void setup(){
        //Setup Admin User - to avoid MixedDML operation errors
        UserRole userRole = [Select Id From UserRole Where Name = 'Global' Limit 1];
        User testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator');        
        testAdminUser.userRoleId = userRole.Id;
        insert testAdminUser;  
        
        //Run test setup method as Admin User
        System.runAs(testAdminUser){
            //Setup Country
            Id countryId = D1_TestDataUtility.setupCountry('IE');
            
            //Setup Pickup Option
            Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[IE]');
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            //Setup D1 Customer Account
            Account accRecord = D1_TestDataUtility.getD1Customer();
            accRecord.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            accRecord.D1_Registration_Status__c = 'AppSubscribed';
            accRecord.D1_Account_Last_Login_Date__c = System.today();
            accRecord.Account_Type__c = 'Sold-To;Ship-To';
            insert accRecord;
            
            //Setup Sales Area
            Sales_Area__c salesArea = D1_TestDataUtility.salesAreaData();
            insert salesArea;

            //Setup Order Split Records
            List<OrderSplit__c> oSplitList = new List<OrderSplit__c>{D1_TestDataUtility.insertOrderSplit(salesArea.Id), D1_TestDataUtility.insertOrderSplitNK(salesArea.Id)};
            oSplitList[0].SAP_OrderSplit_ID__c = 'KEGGB1234';
            oSplitList[1].SAP_OrderSplit_ID__c = 'NONKEGGB1234';
            oSplitList[1].Delivery_Day_Series__c = 1;
            insert oSplitList;

            //Set Up Partner Functions
            PNR_Partner_Function__c pF = D1_TestDataUtility.getPartnerFunction(accRecord, 'Ship-To');
            pF.Sales_Area__c = salesArea.Id;
            insert pF;

            //Set up Order Delivery dates
            List<Order_Delivery_Date__c> orderDeliveryDates = new List<Order_Delivery_Date__c>();
            for(Integer iT =0; iT<10; iT++){
                Order_Delivery_Date__c ordrDate = D1_TestDataUtility.getOrderDeliveryDate( iT < 5 ? oSplitList[0].Id : oSplitList[1].Id);
                ordrDate.Substitue_Delivery_Date__c = System.Today().addDays(iT);
                ordrDate.Delivery_Date_ID__c = 'Test' + String.valueOf(iT);
                orderDeliveryDates.add(ordrDate);
            }
            insert orderDeliveryDates;
        }  
    }
	
    /**
     * @Name : populateDataForSFMCBatchTest
	 * @Description : This method runs the D1_PopulateDataForSFMCBatch class against test data
	 */ 
    @isTest
    public static void populateDataForSFMCBatchTest(){
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c FROM Market_Batch_Setting__mdt 
                                                  WHERE Batch_Class__c = 'D1_PopulateDataForSFMCBatch' 
                                                  AND Country_Code__c = 'IE' LIMIT 1];
                                                  
        System.assert(batchSetting.Id != null, 'Batch setting not found');
        Assert.isTrue(batchSetting.Id != null, 'Batch setting not found');

        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Test.startTest();
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        Test.stopTest();
    }
}