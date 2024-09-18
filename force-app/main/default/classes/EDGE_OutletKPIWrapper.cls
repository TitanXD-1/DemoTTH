/**
*@Class Name: EDGE_OutletKPIWrapper

*@		Author				Version		Date			Detail
*@		Shivam/Rajarshi		V1.0     	04/05/2023	    ES20-14005,ES20-13960 
*@	 	Shivam/Doman		V2.0		20/09/2023		145439
**/
public class EDGE_OutletKPIWrapper {
    public Map<String, Outlet_KPI_Achievement__c> mapOutletKPI {get;set;}
    public Map<String, Decimal> territoryCategoryKPIs {get;set;}
    public Map<id,String> mapCountryChannel {get;set;}//145439
    
}