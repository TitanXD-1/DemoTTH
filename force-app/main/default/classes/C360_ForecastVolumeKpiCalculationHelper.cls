/**

* @description : C360_ForecastVolumeKpiCalculationHelper
* @purpose : Calculation logic for Forecast Rebate

* @history
*  VERSION   		AUTHOR           		 DATE              DETAIL
*  	1.0	       	Priyanka Vinumarthi         16/10/2023    	Initial Development   
*  	2.0	       	Joshraj Sen                 05/12/2023    	149005
*  	3.0	       	Joshraj Sen                 19/12/2023    	149423
*  	4.0	       	Joshraj Sen/Sudipta Nandi   26/12/2023    	149578
*  	5.0		   	Shivam Chauhan				07/02/2024		150059
*  	6.1			Suvendu Roy					17/09/2024		154937 -- Formula changes_Ranging Bonus in Forecast Rebate_SFDC
*	6.2			Sudipta Nandy				17/09/2024		154937 -- Formula changes_Ranging Bonus in Forecast Rebate_SFDC
* 	6.3			Dipanjan Das				17/09/2024		154937 -- Formula changes_Ranging Bonus in Forecast Rebate_SFDC
*/

public  with sharing class C360_ForecastVolumeKpiCalculationHelper {
    
    /** 
* @description  Taking Input Wrapper From Mobile and Send Data to Output Wrapper
* @return  C360_ForecastVolumeCalcWrapper
* @param inputData
**/
    
    public static C360_ForecastVolumeCalcWrapper forecastVolumeKpiCalculation(C360_ForcastVolumeInputWrapper inputData){
        
        C360_ForecastVolumeCalcWrapper forecastWrapper = new C360_ForecastVolumeCalcWrapper();
        String rebateUniqueId = inputData.rebateUniqueId;
        Decimal forecastVolume = decimal.valueOf(inputData.forecastVolume);
        
        List<Trade_Term_Band_Detail__c> listTradeTermBand;
        List<Account_Rebate__c> accrRec = new List<Account_Rebate__c>();
        integer remainingMonths = 12 - System.today().month();
        if( Schema.sObjectType.Account_Rebate__c.isAccessible() || Schema.sObjectType.Trade_Term_Band_Detail__c.isAccessible() ){
            accrRec = [SELECT Id,Ship_To_Account__r.Country_Code__c,Current_volume__c,Forecast_Rebate__c,Forecast_volume__c,Incrementalkegs_PM__c,Forecast_Band__c,Product_Sub_Category__c,Avg_Keg_Month_Current__c FROM Account_Rebate__c 
                       WHERE Rebate_Cal_ID__c =:rebateUniqueId]; //154937 -- Added Avg_Keg_Month_Current__c in the query
            
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
            
            Decimal avgKegperMonthCurrent = checkIfNull(accrRec[0].Avg_Keg_Month_Current__c); //154937
            accrRec[0].Forecast_volume__c = forecastVolume;
            if(remainingMonths != 0 && accrRec[0].Current_volume__c != null){
                accrRec[0].Incrementalkegs_PM__c = (accrRec[0].Forecast_volume__c - accrRec[0].Current_volume__c)/remainingMonths;
            }else{
                accrRec[0].Incrementalkegs_PM__c =null;
            }
            Account_Rebate__c accRebateVal = populateRebateKPIValue(listTradeTermBand,accrRec[0], inputData);
            Decimal avgKegperMonthForecast = (accRebateVal.Forecast_volume__c/12).setScale(2); //154937
            accRebateVal.Incrementalkegs_PM__c = avgKegperMonthForecast - avgKegperMonthCurrent; //154937
            forecastWrapper.forecastBand = string.valueof(accRebateVal.Forecast_Band__c);
            forecastWrapper.forecastRebate = string.valueof(accRebateVal.Forecast_Rebate__c);
            forecastWrapper.forecastVolume = string.valueof(accRebateVal.Forecast_volume__c);
            forecastWrapper.volumeRebate =  string.valueof(accRebateVal.Forecast_Volume_Rebate__c);
            forecastWrapper.settlementDiscount =  string.valueof(accRebateVal.Forecast_Settlement_Discount__c); //154937
            forecastWrapper.rangingBonus =  string.valueof(accRebateVal.Forecast_Ranging_Bonus__c); //154937
            forecastWrapper.avgKegperMonthForecast = string.valueof(avgKegperMonthForecast); //154937
            forecastWrapper.incrementalKEGPerMonth =  string.valueof(accRebateVal.Incrementalkegs_PM__c); //154937
            forecastWrapper.status = 'Success';
            forecastWrapper.isSuccess = true;
            
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
    
    /** 
* @description  Caluclate Forecast Rebate
* @return  Decimal
* @param listTradeTermBand, bandNumberValue
**/
    
    public static Decimal calculateForecastRebate(List<Trade_Term_Band_Detail__c> listTradeTermBand, Decimal bandNumberValue){
        Decimal calcultaedValueNew = 0;
        for (Trade_Term_Band_Detail__c termBrandRec : listTradeTermBand) {
            if (termBrandRec.Band_Number__c < bandNumberValue) {
                calcultaedValueNew = calcultaedValueNew + ((termBrandRec.Unit_Max__c - termBrandRec.Unit_Min__c)*termBrandRec.Rebate__c);
            }
        }
        return calcultaedValueNew;
    }
    
    /** 
* @description  Populate Rebate KPI Value in Account Rebate Record
* @return  Account_Rebate__c
* @param listTradeTermBand, accrRec, inputData
**/
    
    public static Account_Rebate__c populateRebateKPIValue(List<Trade_Term_Band_Detail__c> listTradeTermBand, Account_Rebate__c accrRec,C360_ForcastVolumeInputWrapper inputData){
        
        Decimal forecastVolume = decimal.valueOf(inputData.forecastVolume);        
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
        if (bandNumberValue != null && isCalculationProgressive == true) {
            calcultaedValue = calcultaedValue + calculateForecastRebate(listTradeTermBand,bandNumberValue);
        }
        
        /*154937 - Calculation of Forecast_Volume_Rebate__c,Forecast_Settlement_Discount__c,
        Forecast_Ranging_Bonus__c,Forecast_Rebate__c in Account Rebate*/
        accrRec.No_of_Brands_Stocked__c = checkIfBlankString(inputData.numberOfBrandsStocked); //154937
        accrRec.Forecast_Ranging_Bonus_Volume__c = checkIfBlankString(inputData.rangingVolumeKegs); //154937
        accrRec.Forecast_Volume_Rebate__c = (isCalculationProgressive == true ? calcultaedValue : nonProgressiveValue);        
        accrRec.Forecast_Settlement_Discount__c= getSettlementDiscount(accrRec,forecastVolume);        
        accrRec.Forecast_Ranging_Bonus__c = getRangingBonus(accrRec,integer.valueOf(checkIfBlankString(inputData.numberOfBrandsStocked)),checkIfBlankString(inputData.rangingVolumeKegs));        
        accrRec.Forecast_Rebate__c = accrRec.Forecast_Volume_Rebate__c + accrRec.Forecast_Settlement_Discount__c + accrRec.Forecast_Ranging_Bonus__c;
        
        return accrRec;
    }
    
    
    
    /** 
* @description 154937 -- Calculate Ranging Bonus
* @return  Decimal
* @param accrRec, numberOfBrandsStocked, rangingVolumeKegs
**/
    public static Decimal getRangingBonus(Account_Rebate__c accrRec, Integer numberOfBrandsStocked,Decimal rangingVolumeKegs ){
        if(numberOfBrandsStocked!= 0 && rangingVolumeKegs != 0){
            List<Ranging_Bonus_Details__c> rbdRec = [SELECT Id, Bonus_Rate__c, Average_List_Price__c,Country__r.Code__c,Product_Sub_Category__c 
                                                     FROM Ranging_Bonus_Details__c 
                                                     WHERE Country__r.Code__c =: accrRec.Ship_To_Account__r.Country_Code__c 
                                                     AND Product_Sub_Category__c =:accrRec.Product_Sub_Category__c  
                                                     AND Number_Of_Brands__c =: numberOfBrandsStocked 
                                                     AND Bonus_Rate__c != null with SECURITY_ENFORCED LIMIT 1];
            if(!rbdRec.isEmpty()){
                return rbdRec[0].Bonus_Rate__c*rangingVolumeKegs;
            }
        }
        return 0;
    }
    
    /** 
* @description  154937 -- Calculate Settlement Discount
* @return  Decimal
* @param accrRec, forecastVolume
**/
    
    public static Decimal getSettlementDiscount(Account_Rebate__c accrRec, Decimal forecastVolume){
        
        List<Market_Setting__c> marketSetting = [SELECT Id,Settlement_Discount__c 
                                                 FROM Market_Setting__c WHERE Geography__r.Code__c =: accrRec.Ship_To_Account__r.Country_Code__c
                                                 AND Settlement_Discount__c != null with SECURITY_ENFORCED LIMIT 1];
        
        List<Ranging_Bonus_Details__c> rbdRec =  [SELECT Id, Bonus_Rate__c, Average_List_Price__c,Country__r.Code__c,Product_Sub_Category__c 
                                                 FROM Ranging_Bonus_Details__c 
                                                 WHERE Country__r.Code__c =: accrRec.Ship_To_Account__r.Country_Code__c 
                                                 AND Product_Sub_Category__c =:accrRec.Product_Sub_Category__c  
                                                 AND Average_List_Price__c != null with SECURITY_ENFORCED ORDER BY LastModifiedDate DESC LIMIT 1];
        
        if(!rbdRec.isEmpty() && !marketSetting.isEmpty()){
            return rbdRec[0].Average_List_Price__c*forecastVolume*(marketSetting[0].Settlement_Discount__c/100);
        }
        return 0;
    }
    
    /** 
* @description  154937 -- To check if the value is null or not
* @return  Decimal
* @param chkVal
**/    
    public static Decimal checkIfNull(Decimal chkVal){
        return chkVal != null ? chkVal : 0;
    }
    
    /** 
* @description  154937 -- To check if the String is null or not
* @return  Decimal
* @param chkString
**/      
     public static Decimal checkIfBlankString (String chkString){
        return String.isNotBlank(chkString) ? Decimal.valueof(chkString) : 0;
    }
}