/**
* @Description : C360_ForeCastRebateHelperTest

* @History : Test class for C360_ForecastVolumeKpiCalculationHelper                                                        

* @VERSION       AUTHOR           		DATE            	DETAIL
*  1.0        	 Priyanka Vinumarthi   16/10/2023    Initial Development 
*  2.0           Anamika Shulka        18/10/2023    146159 
*  3.0			 Shivam Chauhan		   07/02/2024	 150059
*  4.0			 Sudipta Nandy		   17/09/2024	 154937 -- Formula changes_Ranging Bonus in Forecast Rebate_SFDC
*/
@isTest
public class C360_ForeCastRebateHelperTest {
 
    @isTest
    public static void forecastRebateTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('NIR');       
        
        
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.KUNNR__c = '1234';
        insert acc;
        system.assert(acc.id != null,'acc should not be null');
        
        Account dirAcc = EDGE_UtilityTestClass.getDirectCustomer();
        dirAcc.country__c = geographyId;
        dirAcc.KUNNR__c = '87654';
        insert dirAcc;
         
        Account_Rebate__c accRebate = new Account_Rebate__c();
        accRebate.Ship_To_Account__c = acc.Id;
        accRebate.Sold_To_Account__c = dirAcc.Id;
       	accRebate.Product_Sub_Category__c = 'Ale';
        accRebate.Forecast_volume__c = 61.00;
        accRebate.Forecast_Rebate__c = 948.75;
        accRebate.Rebate_Cal_ID__c = '87654_1234_Ale';
        insert accRebate;
        
        //154937
        Account_Rebate__c accRebate2 = new Account_Rebate__c();
        accRebate2.Ship_To_Account__c = acc.Id;
        accRebate2.Sold_To_Account__c = dirAcc.Id;
       	accRebate2.Product_Sub_Category__c = 'Lager/Cider';
        accRebate2.Avg_Keg_Month_Current__c = 10;
        accRebate2.Forecast_volume__c = 50.00;
        accRebate2.Forecast_Rebate__c = 950.75;
        //accRebate2.Rebate_Cal_ID__c = '87654_1234_Lager/Cider';
        insert accRebate2;
        
        
        List<Trade_Term_Band_Detail__c> tbList = new List<Trade_Term_Band_Detail__c>();
        Trade_Term_Band_Detail__c tb = new Trade_Term_Band_Detail__c();
        tb.Unit_Min__c = 51;
        tb.Unit_Max__c = 3.00;
        tb.Product_Sub_Category__c = 'Ale';
        tb.Band_Number__c= 2;
        tb.Rebate__c= 67;
        tb.Calcuation_Logic__c='Progressive';
        tb.Country__c = geographyId;
        tbList.add(tb);
        insert tbList;
        
        List<Ranging_Bonus_Details__c> rbdList = new List<Ranging_Bonus_Details__c>();
        
        Ranging_Bonus_Details__c rbd1 = new Ranging_Bonus_Details__c();
        rbd1.Country__c = geographyId;
        rbd1.Bonus_Rate__c = 2;
        rbd1.Number_Of_Brands__c = 1;
        rbd1.Product_Sub_Category__c = 'Lager/Cider';
        rbd1.Average_List_Price__c = 10;
        rbdList.add(rbd1);
        insert rbdList;
        
        String reqBody = '{'+
                                '"forecastVolume" : "275",'+
            					'"rebateUniqueId" : "87654_1234_Ale"'+
                            '}';
                           
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
    	req.requestBody = Blob.valueof(reqBody);
    	RestContext.request = req;
        C360_ForecastVolumeKpiCalculation.doPost();
        
        C360_ForecastVolumeCalcWrapper wrapperVal = new C360_ForecastVolumeCalcWrapper();
        wrapperVal.isSuccess = false;
        //154937
        String reqBody1 = '{'+
                                '"forecastVolume" : "275",'+
            					'"rebateUniqueId" : "87654_1234_Lager/Cider",'+
            					'"rangingVolumeKegs" : "100",'+
								'"numberOfBrandsStocked" : "1"' +
                            '}';
                           
        RestRequest req1 = new RestRequest();
        req1.httpMethod = 'POST';
    	req1.requestBody = Blob.valueof(reqBody1);
    	RestContext.request = req1;
        C360_ForecastVolumeKpiCalculation.doPost();
        
        C360_ForecastVolumeCalcWrapper wrapperVal1 = new C360_ForecastVolumeCalcWrapper();
        wrapperVal1.isSuccess = false;
        
        String reqBody2 = '{'+
                                '"forecastVolume" : "275"'+
            					'"rebateUniqueId" : "87654_123_Ale"'+
                            '}';//Bad Value to cover catch method
                           
        req1.httpMethod = 'POST';
    	req1.requestBody = Blob.valueof(reqBody2);
    	RestContext.request = req1;
        C360_ForecastVolumeKpiCalculation.doPost();
        
        C360_ForecastVolumeCalcWrapper wrapperVal2 = new C360_ForecastVolumeCalcWrapper();
        wrapperVal2.isSuccess = false;
        
    }
}