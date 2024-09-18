/**
* @description EDGE_GenerateStoreJSON
* @history                                                            
                                                          
VERSION     AUTHOR                  DATE              DETAIL
1.0         Monalisa Halder       31/05/2019         ES20-1583
1.1         Monalisa Halder       17/08/2020         ES20-8424 - Adding the field as additional attribute
1.2			Debolina Saha		  04/04/2022         ES20-12406 - Disable IsDeleted Attribute in the Trax Inbound API_SFDC
1.3         Joshraj Sen           12/06/2023         GT-140 Added the Fields BillingCountry,OperatorName for GTH Market
 
**/
public with sharing class  EDGE_GenerateStoreJSON{
    
    public String store_number;
    public String store_name;
    public String store_display_name;
    public String store_type_name;
    public String region_name;
    public String state_code;
    public String retailer_name;
    public String country_code;
    public String street;
    public String city;
    public Boolean is_active; 
  //public Boolean is_deleted;   Commented out the is_deleted field as a part of ES20-12406
    public String postal_code;
    public Double latitude;
    public Double longitude;
        
    public EDGE_GenerateStoreAdditionalAttribute additional_attributes;
    
    public EDGE_GenerateStoreJSON(Account outlet, String countryCode){
        String gthString = Label.GT_Global_Travel_Hub_Code;
        String distributorName = ''; 
        system.debug(LoggingLevel.DEBUG,'@@outlet' +outlet);
        this.store_number = outlet.Id;
        this.store_name = outlet.Name;
        this.store_display_name = outlet.Name;
        this.store_type_name = outlet.Global_Channel__c;
        system.debug(LoggingLevel.DEBUG,'outlet.Region__c@@' +outlet.Region__c);
        if(outlet.Region__c  != null){
            this.region_name = outlet.Region__r.Name;
        }else{
            this.region_name = 'None';
        }  
        this.state_code = outlet.Area__r.Name;
        this.retailer_name = outlet.Parent.Name;
        this.country_code = outlet.Country_Code__c;
        this.street = outlet.BillingStreet;
        this.city = outlet.BillingCity;
        this.is_active = (outlet.Status__c == 'Active');
        //this.is_deleted = (outlet.Status__c == 'Closed');     Commented out as a part of ES20-12406
        this.postal_code = outlet.BillingPostalCode;   
        this.latitude = outlet.BillingLatitude;
        this.longitude = outlet.BillingLongitude;
        if(countryCode != gthString && outlet.Supplier_Outlets1__r != null && outlet.Supplier_Outlets1__r.size()>0){
            for(Supplier_Outlet__c so :outlet.Supplier_Outlets1__r){
                distributorName = outlet.Supplier_Outlets1__r[0].Distributor_Wholesaler__r.Name; 
            } 
        }
        EDGE_GenerateStoreAdditionalAttribute  att = new EDGE_GenerateStoreAdditionalAttribute(outlet.Global_Sub_channel__c, outlet.Global_Segment__c, outlet.Consumer_Segmentation__r.Name, outlet.Outlet_Visit_Prioritisation_Grade__r.Name, outlet.Fascia__r.Name, outlet.Local_Segment2__r.Name, distributorName, outlet.Local_Segment1__r.Name, outlet.Store_Size__r.name,outlet.Global_Sub_Segment__c ,outlet.Local_Segment_Advanced_Analytics__c, countryCode);
        
        this.additional_attributes = att;
    }
}