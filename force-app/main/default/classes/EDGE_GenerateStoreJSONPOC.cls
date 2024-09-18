/**
* @description EDGE_GenerateStoreJSON
* @history                                                            
**/
public with sharing class  EDGE_GenerateStoreJSONPOC{
    
    public String street;
    public String store_type_name;
    public String store_number;
    public String store_name;
    public String store_display_name;
    public String state_name;
    public String retailer_name;
    public String region_name;
    public String postal_code;
    public Double longitude;
    public Double latitude;
    public Boolean is_active;
    public String city;
    public String additional_attribute_1;
    public String additional_attribute_2;
    public String additional_attribute_3;
    public String additional_attribute_4;
    public String additional_attribute_5;
    public String additional_attribute_6;
    public String additional_attribute_7;
    public String additional_attribute_8;
    public String additional_attribute_9;
    public String additional_attribute_10;
    public String additional_attribute_16;
    
    public EDGE_GenerateStoreJSONPOC(Account outlet, String countryCode){
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
        this.state_name = outlet.Area__r.Name;
        this.retailer_name = outlet.Parent.Name;
        //this.country_code = outlet.Country_Code__c;
        this.street = outlet.BillingStreet;
        this.city = outlet.BillingCity;
        this.is_active = (outlet.Status__c == 'Active');
        this.postal_code = outlet.BillingPostalCode;   
        this.latitude = outlet.BillingLatitude;
        this.longitude = outlet.BillingLongitude;
        if(countryCode != gthString && outlet.Supplier_Outlets1__r != null && outlet.Supplier_Outlets1__r.size()>0){
            for(Supplier_Outlet__c so :outlet.Supplier_Outlets1__r){
                distributorName = outlet.Supplier_Outlets1__r[0].Distributor_Wholesaler__r.Name; 
            } 
        }
        if(outlet.Global_Sub_channel__c != null){
            this.additional_attribute_1 = outlet.Global_Sub_channel__c;    
        }else{
            this.additional_attribute_1 = '';
       }
        if(outlet.Global_Segment__c != null){
            this.additional_attribute_2 = outlet.Global_Segment__c;    
        }else{
            this.additional_attribute_2 = '';
       }  
        if(outlet.Consumer_Segmentation__r.Name != null){
            this.additional_attribute_3 = outlet.Consumer_Segmentation__r.Name.substring(0,outlet.Consumer_Segmentation__r.Name.indexof('[')!=-1? outlet.Consumer_Segmentation__r.Name.indexof('['):outlet.Consumer_Segmentation__r.Name.length());
        }else{
            this.additional_attribute_3 = '';
       }   
        if(outlet.Outlet_Visit_Prioritisation_Grade__r.Name != null){
			this.additional_attribute_4 = outlet.Outlet_Visit_Prioritisation_Grade__r.Name.substring(0,outlet.Outlet_Visit_Prioritisation_Grade__r.Name.indexof('[')!=-1 ? outlet.Outlet_Visit_Prioritisation_Grade__r.Name.indexof('['):outlet.Outlet_Visit_Prioritisation_Grade__r.Name.length());
        }else{
            this.additional_attribute_4 = '';
        }
        if(outlet.Fascia__r.Name != null){
            this.additional_attribute_5 = outlet.Fascia__r.Name;
        }else{
            this.additional_attribute_5 = '';
        }
        if(outlet.Local_Segment2__r.Name != null){
            this.additional_attribute_6 = outlet.Local_Segment2__r.Name.substring(0,outlet.Local_Segment2__r.Name.indexof('[')!=-1 ? outlet.Local_Segment2__r.Name.indexof('['):outlet.Local_Segment2__r.Name.length());
        }else{
            this.additional_attribute_6 = '';
        }
        if(distributorName != null){
            this.additional_attribute_7 = distributorName;
        }else{
            this.additional_attribute_7 = '';
        }
        if(outlet.Local_Segment1__r.Name != null){
            this.additional_attribute_8 = outlet.Local_Segment1__r.Name.substring(0,outlet.Local_Segment1__r.Name.indexof('[')!=-1 ? outlet.Local_Segment1__r.Name.indexof('['):outlet.Local_Segment1__r.Name.length());
        }else{
            this.additional_attribute_8 = '';
        }
        if(outlet.Store_Size__r.name != null){
            this.additional_attribute_9 = outlet.Store_Size__r.name.substring(0,outlet.Store_Size__r.name.indexof('[')!=-1 ? outlet.Store_Size__r.name.indexof('['):outlet.Store_Size__r.name.length());
            
        }else{
            this.additional_attribute_9 = '';
        }
        this.additional_attribute_10 = outlet.Global_Sub_Segment__c;       
        if(outlet.Local_Segment_Advanced_Analytics__c != null){
            this.additional_attribute_16 = outlet.Local_Segment_Advanced_Analytics__c;    
        }else{
            this.additional_attribute_16 = '';
       }
    }
}