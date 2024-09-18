/**
* @description C360_ForecastVolumeKpiCalculation. This class is needed to build Custom API to send back calculated all 4 attributes to Mobile
*
* @history
* Version  Developer              Date               Purpose
* 1.0      Anamika             10/16/2023      Initial Development
* 2.0	   Shivam Chauhan	   07/02/2024	   150059
*/
@RestResource(urlMapping='/ForecastVolumeKpiCalculation/*')
global with sharing class C360_ForecastVolumeKpiCalculation {
    @HttpPost
    global static C360_ForecastVolumeCalcWrapper doPost(){
        RestRequest request = RestContext.request;
        C360_ForecastVolumeCalcWrapper forecastWrapper = new C360_ForecastVolumeCalcWrapper();
         try{
            if (request.requestBody != null){
                C360_ForcastVolumeInputWrapper inputData = (C360_ForcastVolumeInputWrapper) JSON.deserialize(request.requestBody.toString(),C360_ForcastVolumeInputWrapper.class);
                forecastWrapper = C360_ForecastVolumeKpiCalculationHelper.forecastVolumeKpiCalculation(inputData);
            }
         }
        catch(Exception forecastException){
			System.debug(LoggingLevel.DEBUG, 'Exception details = '+ forecastException.getMessage());
            forecastWrapper.isSuccess = false;
            forecastWrapper.status = 'An Error occurred';
        }
        return forecastWrapper;
    }
    
}