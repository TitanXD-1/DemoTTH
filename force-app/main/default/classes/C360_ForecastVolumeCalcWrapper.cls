/**
* @description C360_ForecastVolumeCalcWrapper
*
* @history
* Version  	Developer              Date               Purpose
* 1.0      	Anamika            	10/16/2023      	Initial Development
* 2.0	   	Shivam Chauhan	  	07/02/2024	  		150059
* 3.0		Sudipta Nandy		16/09/2024			156152 -- API structure changes_SFDC
*/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class C360_ForecastVolumeCalcWrapper {
    public String forecastRebate{get;set;}
    public String forecastBand{get;set;}
    public String incrementalKEGPerMonth{get;set;}
    public String forecastVolume{get;set;}
    public String volumeRebate{get;set;} //156152
    public String settlementDiscount{get;set;} //156152
    public String rangingBonus{get;set;} //156152
    public String avgKegperMonthForecast{get;set;} //156152
    public String status{get;set;}//150059
    public Boolean isSuccess{get;set;}
    
}