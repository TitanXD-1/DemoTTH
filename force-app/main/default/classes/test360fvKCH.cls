/**

* @description : C360_ForecastVolumeKpiCalculationHelper
* @purpose : Calculation logic for Forecast Rebate

* @history
* Version   Developer        Date            User Story           Purpose
*  VERSION   AUTHOR            DATE              DETAIL
*  1.0       Priyanka Vinumarthi          16/10/2023    Initial Development   
*  2.0       Joshraj Sen                  05/12/2023    149005
*  3.0       Joshraj Sen                  19/12/2023    149423
*  4.0       Joshraj Sen/Sudipta Nandi    26/12/2023    149578
*  5.0		 Shivam Chauhan				  07/02/2024	150059
*/
public  with sharing class test360fvKCH {
    public static C360_ForecastVolumeCalcWrapper forecastVolumeKpiCalculation(C360_ForcastVolumeInputWrapper inputData){

        C360_ForecastVolumeCalcWrapper forecastWrapper = new C360_ForecastVolumeCalcWrapper();
        String rebateUniqueId = inputData.rebateUniqueId;
        Decimal forecastVolume = decimal.valueOf(inputData.forecastVolume);
        
        List<Trade_Term_Band_Detail__c> listTradeTermBand;
        List<Account_Rebate__c> accrRec = new List<Account_Rebate__c>();
        integer remainingMonths = 12 - System.today().month();
        if( Schema.sObjectType.Account_Rebate__c.isAccessible() || Schema.sObjectType.Trade_Term_Band_Detail__c.isAccessible() ){
            accrRec = [SELECT Id,Ship_To_Account__r.Country_Code__c,Current_volume__c,Forecast_Rebate__c,Forecast_volume__c,Incrementalkegs_PM__c,Forecast_Band__c,Product_Sub_Category__c,Avg_Keg_Month_Current__c FROM Account_Rebate__c 
                       WHERE Rebate_Cal_ID__c =:rebateUniqueId];

            if(accrRec.isEmpty()){
                forecastWrapper.status = system.label.C360_Forecast_Volume_Not_Found;
                forecastWrapper.isSuccess = false;
                return forecastWrapper;
            }
            listTradeTermBand = [SELECT Id,Name, Band_Number__c, Unit_Max__c, Unit_Min__c, Rebate__c ,Calcuation_Logic__c,Product_Sub_Category__c
                                 FROM Trade_Term_Band_Detail__c WHERE Country__r.Code__c =: accrRec[0].Ship_To_Account__r.Country_Code__c 
                                 AND Product_Sub_Category__c =: accrRec[0].Product_Sub_Category__c order by Unit_Max__c desc];
        }        
        if (!listTradeTermBand.isEmpty() && !accrRec.isEmpty()){

            Decimal avgKegperMonthCurrent = accrRec[0].Avg_Keg_Month_Current__c;
            accrRec[0].Forecast_volume__c = forecastVolume;
            if(remainingMonths != 0 && accrRec[0].Current_volume__c != null){
                accrRec[0].Incrementalkegs_PM__c = (accrRec[0].Forecast_volume__c - accrRec[0].Current_volume__c)/remainingMonths;
            }else{
                accrRec[0].Incrementalkegs_PM__c =null;
            }
            Account_Rebate__c accRebateVal = populateRebateKPIValue(listTradeTermBand,accrRec[0], inputData);
            Decimal avgKegperMonthForecast = (accRebateVal.Forecast_volume__c/12).setScale(2);
            accRebateVal.Incrementalkegs_PM__c = avgKegperMonthForecast - avgKegperMonthCurrent;
            forecastWrapper.forecastBand = string.valueof(accRebateVal.Forecast_Band__c);
            forecastWrapper.forecastRebate = string.valueof(accRebateVal.Forecast_Rebate__c);
            forecastWrapper.forecastVolume = string.valueof(accRebateVal.Forecast_volume__c);
           // forecastWrapper.incrementalKEGPerMonth =  string.valueof(accRebateVal.Incrementalkegs_PM__c);
            //--------
            forecastWrapper.volumeRebate =  string.valueof(accRebateVal.Forecast_Volume_Rebate__c);
            forecastWrapper.settlementDiscount =  string.valueof(accRebateVal.Forecast_Settlement_Discount__c);
            forecastWrapper.rangingBonus =  string.valueof(accRebateVal.Forecast_Ranging_Bonus__c);
            //forecastWrapper.avgKegperMonthForecast =  string.valueof((accRebateVal.Forecast_volume__c/12).setScale(2));
            forecastWrapper.avgKegperMonthForecast = string.valueof(avgKegperMonthForecast);
            forecastWrapper.incrementalKEGPerMonth =  string.valueof(accRebateVal.Incrementalkegs_PM__c);
            forecastWrapper.status = 'Success';
            forecastWrapper.isSuccess = true;
            //accRebateVal.Incrementalkegs_PM__c = Decimal.valueof(forecastWrapper.incrementalKEGPerMonth);
            if (!Schema.sObjectType.Account_Rebate__c.isUpdateable()){
                return null;
            }
            update accRebateVal;
        }else{
        	forecastWrapper.status = system.label.C360_Forecast_An_Error_occurred;
        	forecastWrapper.isSuccess = false;
        }
        return forecastWrapper;
    }
    
    
    public static Decimal calculateForecastRebate(List<Trade_Term_Band_Detail__c> listTradeTermBand, Decimal bandNumberValue){
        Decimal calcultaedValueNew = 0;
        for (Trade_Term_Band_Detail__c termBrandRec : listTradeTermBand) {
            if (termBrandRec.Band_Number__c < bandNumberValue) {
                calcultaedValueNew = calcultaedValueNew + ((termBrandRec.Unit_Max__c - termBrandRec.Unit_Min__c)*termBrandRec.Rebate__c);
            }
        }
        return calcultaedValueNew;
    }
    
    
    public static Account_Rebate__c populateRebateKPIValue(List<Trade_Term_Band_Detail__c> listTradeTermBand, Account_Rebate__c accrRec,C360_ForcastVolumeInputWrapper inputData){
        Decimal forecastVolume = decimal.valueOf(inputData.forecastVolume);
        //String rebateUniqueId = inputData.rebateUniqueId;
        //Decimal rangingVolumeKegs = decimal.valueOf(inputData.rangingVolumeKegs);
        //Integer numberOfBrandsStocked = integer.valueOf(inputData.numberOfBrandsStocked);
        
        Decimal forecastVolForAccountRebate = forecastVolume;
        Decimal bandNumberValue;
        Decimal calcultaedValue = 0;
        Decimal nonProgressiveValue = 0;
        boolean isCalculationProgressive = false;
        boolean isExecuted = false;
        Decimal maximumValue = listTradeTermBand[0].Unit_Max__c;
        for (Trade_Term_Band_Detail__c tradeTermRec : listTradeTermBand) {
            if ((forecastVolume >= tradeTermRec.Unit_Min__c && forecastVolume < tradeTermRec.Unit_Max__c) || (forecastVolume >= maximumValue && !isExecuted) ) {
                accrRec.Forecast_Band__c = string.valueof(tradeTermRec.Band_Number__c);
                bandNumberValue = tradeTermRec.Band_Number__c; 
                calcultaedValue = (forecastVolForAccountRebate - tradeTermRec.Unit_Min__c) * tradeTermRec.Rebate__c;
                nonProgressiveValue = forecastVolForAccountRebate * tradeTermRec.Rebate__c;
                isCalculationProgressive = tradeTermRec.Calcuation_Logic__c == system.Label.C360_Progressive;
                isExecuted = true;
            }
        }
        Decimal calForecastRebate = calculateForecastRebate(listTradeTermBand,bandNumberValue);
        getCalcultaedValue(bandNumberValue,isCalculationProgressive,calcultaedValue,calForecastRebate);
        /*if (bandNumberValue != null && isCalculationProgressive == true) {
            calcultaedValue = calcultaedValue + calculateForecastRebate(listTradeTermBand,bandNumberValue);
        }*/
        accrRec.Forecast_Volume_Rebate__c = (isCalculationProgressive == true ? calcultaedValue : nonProgressiveValue);        
        accrRec.Forecast_Settlement_Discount__c= getSettlementDiscount(accrRec,forecastVolume);
        if(inputData.rangingVolumeKegs!= '' && inputData.numberOfBrandsStocked!=''){
            accrRec.Forecast_Ranging_Bonus__c = getRangingBonus(accrRec,integer.valueOf(inputData.numberOfBrandsStocked),decimal.valueOf(inputData.rangingVolumeKegs));
        }else{
            accrRec.Forecast_Ranging_Bonus__c = 0;
        }
        
        accrRec.Forecast_Rebate__c = accrRec.Forecast_Volume_Rebate__c + accrRec.Forecast_Settlement_Discount__c + accrRec.Forecast_Ranging_Bonus__c;
        //accrRec.Avg_Keg_Month_Forecast__c = forecastVolume/12;
                
        return accrRec;
    }
    
    public static Decimal getRangingBonus(Account_Rebate__c accrRec, Integer numberOfBrandsStocked,Decimal rangingVolumeKegs ){
        
        List<Ranging_Bonus_Details__c> rbdRec = [SELECT Id, Bonus_Rate__c, Average_List_Price__c,Country__r.Code__c,Product_Sub_Category__c 
                                           FROM Ranging_Bonus_Details__c 
                                           WHERE Country__r.Code__c =: accrRec.Ship_To_Account__r.Country_Code__c 
                                           AND Product_Sub_Category__c =:accrRec.Product_Sub_Category__c  
                                           AND Number_Of_Brands__c =: numberOfBrandsStocked 
                                           AND Bonus_Rate__c != null with SECURITY_ENFORCED LIMIT 1];
        if(!rbdRec.isEmpty()){
            return rbdRec[0].Bonus_Rate__c*rangingVolumeKegs;
        }
        
        return 0;
    }
    
    public static Decimal getSettlementDiscount(Account_Rebate__c accrRec, Decimal forecastVolume){
        //Settlement Discount : Average List Price (from field : Average List Price on Object: "Ranging Bonus Details") * Forecast Volume* Settlement Discount % (from Mkt settings)
        
        List<Market_Setting__c> marketSetting = [SELECT Id,Settlement_Discount__c 
                         FROM Market_Setting__c WHERE Geography__r.Code__c =: accrRec.Ship_To_Account__r.Country_Code__c
                         AND Settlement_Discount__c != null with SECURITY_ENFORCED LIMIT 1];
        
        List<Ranging_Bonus_Details__c> rbdRec = [SELECT Id, Bonus_Rate__c, Average_List_Price__c,Country__r.Code__c,Product_Sub_Category__c 
                  FROM Ranging_Bonus_Details__c 
                  WHERE Country__r.Code__c =: accrRec.Ship_To_Account__r.Country_Code__c 
                  AND Product_Sub_Category__c =:accrRec.Product_Sub_Category__c  
                  AND Average_List_Price__c != null with SECURITY_ENFORCED ORDER BY LastModifiedDate DESC LIMIT 1];

        if(!rbdRec.isEmpty() && !marketSetting.isEmpty()){
            return rbdRec[0].Average_List_Price__c*forecastVolume*marketSetting[0].Settlement_Discount__c;
        }
        return 0;
    }
    public static Decimal getCalcultaedValue(Decimal bandNumberValue,boolean isCalculationProgressive, Decimal calcultaedValue,Decimal calForecastRebate){
        if (bandNumberValue != null && isCalculationProgressive == true) {
            calcultaedValue = calcultaedValue + calForecastRebate;
        }
        return calcultaedValue;
    }
    
    
}