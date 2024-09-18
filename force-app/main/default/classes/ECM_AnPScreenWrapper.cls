/*
*@Name: ECM_AnPScreenWrapper
*@Description: This is a wrapper class used to show records in A&P Forecast Screen.
*@History                                                            
*
*VERSION		AUTHOR					DATE				DETAIL
*1.0			Rajarshi Lahiri		 03/08/2023			Initial Development
*1.1			Saurav Prasad		 07/08/2023			143956 : A&P table Data Fetch
*
*/
 public class ECM_AnPScreenWrapper {
    
    @AuraEnabled
    public Decimal plannedAPTotal{get; set;}//	ECM_TotalAnP_incl_Indirect__c
    @AuraEnabled
    public Decimal phasingForeCastTotal{get; set;}
    @AuraEnabled
    public Decimal paidAPTotal{get; set;}
    @AuraEnabled
    public Decimal difference{get; set;}
    @AuraEnabled
    public List<MonthWrapper> paidAndForecast{get; set;}
    @AuraEnabled
    public String productName{get; set;}
    //143956
    @AuraEnabled
    public List<ECM_A_P_Planning__c> listOfAnp{get;set;}
    @AuraEnabled
    public String conItemId{get;set;}

    //143956
    public ecm_AnPScreenWrapper(){
        this.plannedAPTotal	= 0;
        this.phasingForeCastTotal=0;
        this.paidAPTotal = 0;
        this.difference = 0;
        this.paidAndForecast = new List<MonthWrapper>();
        this.productName ='';
        this.listOfAnp = new List<ECM_A_P_Planning__c>();
        this.conItemId = '';
   }

   public class MonthWrapper {
    @AuraEnabled
    public string paidColumn{get; set;}
    @AuraEnabled
    public string forecastColumn{get; set;}
    @AuraEnabled
	public Decimal paidValue{get; set;}
    @AuraEnabled
	public Decimal forecastValue{get; set;}
    @AuraEnabled
	public String uniqueId{get; set;}	//<Paid API Name>_<Forecast Field API Name>_Year_CIId_APScreenRecordId

    //143956
    public MonthWrapper(){
            this.paidColumn = '';
            this.forecastColumn = '';
            this.paidValue = 0;
            this.forecastValue = 0;
            this.uniqueId ='';
        }
	}

}