/*Req: The requirement is to build Custom API for mobile to get Bundle Data for the Outlet
User Story : ES20-13610
History                                                            
                                                            
VERSION   AUTHOR                  DATE              DETAIL
1.0      Joshraj Sen           04/12/2022        Custom API for D1 to get Bundle Data For an Outlet
2.0      Monalisa Halder       06/01/2023        ES20-13696 
3.0		 Rajarshi Lahiri	   31/03/2023		 ES20-13945
*/
public class EDGE_OutletBundleWrapper {
    @AuraEnabled
    public string recordId{get;set;}
    @AuraEnabled
    public String name{get;set;}
    @AuraEnabled
    public String description{get;set;}
    @AuraEnabled
    public Datetime installationDate{get;set;}
    @AuraEnabled
    public String contentDocumentId{get;set;} 
    @AuraEnabled
    public String contentVersionId{get;set;} 
    @AuraEnabled
    public String location{get;set;} 
    /*ES20-13696 - start*/
    @AuraEnabled
    public String masterBundleId{get;set;} 
    @AuraEnabled
    public String outletId{get;set;} 
    /*ES20-13696 - end*/
    //ES20-13945
    @AuraEnabled
    public String faultFixer{get;set;} 

}