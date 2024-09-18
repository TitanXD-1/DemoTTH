/**
* @description EDGE_GenerateStoreAdditionalAttribute
* @history                                                            
                                                           
VERSION     AUTHOR                  DATE              DETAIL
1.0         Monalisa Halder       31/05/2019         ES20-1583
1.1         Monalisa Halder       17/08/2020         ES20-8424 - Adding the field as additional attribute
1.2         Joshraj Sen           13/08/2023         GT-140- Pickup option value shall always have a value even if they don't have a country code in [] and Supplier will show up in the JSON for GTH Markets and as blank for Non-GTH Markets,

**/

Public Class EDGE_GenerateStoreAdditionalAttribute{

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
    public EDGE_GenerateStoreAdditionalAttribute(String attribute_1, String attribute_2, String attribute_3, String attribute_4, String attribute_5, String attribute_6, String attribute_7, String attribute_8,String attribute_9, String attribute_10, String attribute_16, String countryCode){

        if(attribute_1 != null){
            this.additional_attribute_1 = attribute_1;    
        }else{
            this.additional_attribute_1 = '';
       }
        if(attribute_2 != null){
            this.additional_attribute_2 = attribute_2;    
        }else{
            this.additional_attribute_2 = '';
       }  
        if(attribute_3 != null){
            this.additional_attribute_3 = attribute_3.substring(0,attribute_3.indexof('[')!=-1? attribute_3.indexof('['):attribute_3.length());
        }else{
            this.additional_attribute_3 = '';
       }   
        if(attribute_4 != null){
			this.additional_attribute_4 = attribute_4.substring(0,attribute_4.indexof('[')!=-1 ? attribute_4.indexof('['):attribute_4.length());
        }else{
            this.additional_attribute_4 = '';
        }
        if(attribute_5 != null){
            this.additional_attribute_5 = attribute_5;
        }else{
            this.additional_attribute_5 = '';
        }
        if(attribute_6 != null){
            this.additional_attribute_6 = attribute_6.substring(0,attribute_6.indexof('[')!=-1 ? attribute_6.indexof('['):attribute_6.length());
        }else{
            this.additional_attribute_6 = '';
        }
        if(attribute_7 != null){
            this.additional_attribute_7 = attribute_7;
        }else{
            this.additional_attribute_7 = '';
        }
        if(attribute_8 != null){
            this.additional_attribute_8 = attribute_8.substring(0,attribute_8.indexof('[')!=-1 ? attribute_8.indexof('['):attribute_8.length());
        }else{
            this.additional_attribute_8 = '';
        }
        if(attribute_9 != null){
            this.additional_attribute_9 = attribute_9.substring(0,attribute_9.indexof('[')!=-1 ? attribute_9.indexof('['):attribute_9.length());
            
        }else{
            this.additional_attribute_9 = '';
        }
        this.additional_attribute_10 = attribute_10;       
        if(attribute_16 != null){
            this.additional_attribute_16 = attribute_16;    
        }else{
            this.additional_attribute_16 = '';
       }
        
    }
}