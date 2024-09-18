public class TraxPOCBatchClassStoreUpload implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    
    // Static list to store importIds across batch transactions
    private List<String> importIdList = new List<String>();
    
    // Implement start method
    public Database.QueryLocator start(Database.BatchableContext bc) {
        system.debug('@@-Inside Start: ');
        String countryCode = 'DE';
        datetime dt = System.now()-1;
        
        String queryString = 'SELECT Id, Name,Global_Channel__c, Country_Code__c, BillingState, BillingStreet, BillingCity, ' +
            'Region__c, Region__r.Name,Area__c, Area__r.Name,Status__c, BillingPostalCode, BillingLatitude, BillingLongitude, Parent.Name,Fascia__r.Name, ' +
            'Local_Segment2__r.Name, Local_Segment1__r.Name, Global_Sub_channel__c, Global_Segment__c,'+
            'Global_Sub_Segment__c, Consumer_Segmentation__r.Name, Outlet_Visit_Prioritisation_Grade__r.Name, Send_To_Trax__c,Store_Size__r.Name,Local_Segment_Advanced_Analytics__c,'+
            '(SELECT Id , Distributor_Wholesaler__c,Distributor_Wholesaler__r.Name, Outlet__c FROM Supplier_Outlets1__r where isPrimary__c = true LIMIT 1) FROM Account '+
            'WHERE Last_Modify_Data_Master__c >=:dt and Country_Code__c =:countryCode and Send_To_Trax__c = true';
        
        return Database.getQueryLocator(queryString);
    }
    
    // Implement execute method
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        system.debug('@@-Inside Execute: ');
        List <Map<String, Object>> dataMapList = new List<Map<String, Object>>();        
        for (Account acc : scope) {
            // Prepare the data for the POST request
            dataMapList.add(createJSONAttachment(acc));
        }
        String fileContent= JSON.serializePretty(dataMapList);
        String entityType = 'store';
        String fileName = 'OutletFile.json';
        String boundary = '--------------------------848953448533366555074091';
        String header='--' + boundary +'\r\nContent-Disposition: form-data; name="entity_type"\r\n\r\n'+entityType+'\r\n'+                 
            '--' + boundary +'\r\nContent-Disposition: form-data; name="file_format"\r\n\r\nJSON\r\n'+
            '--' + boundary +'\r\nContent-Disposition: form-data; name="file"; filename="' + fileName + '"'+
            '\r\nContent-Type: application/json\r\n\r\n';
        
        String footer = '--'+boundary+'--';             
        String bodyEncoded = fileContent +'\r\n';
        String bodyPayload = header + bodyEncoded + footer  ;
        String targetURL = 'https://services.traxretail.com/api/v5/diageoga1-sand/store-import/upload';
        String accessToken = 'mcFlwQHtVIvspk8JdZsjPqfezs2wJOcKLPpaDQ94iLCCc76iHkolQxQPa4haDxqCki0ydtaJ1yPrI8FDVLICL3eQVIG02TuUy3gkKCKRfCfaezyGvoYOsZO6eTMAt4jz9wn5fT7LhfzTAZxYez2vUxBc';
        String responseBody='';
        // Send HTTP request
        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', 'multipart/form-data; boundary='+boundary);
        request.setHeader('Authorization', 'Auth-Token '+accessToken);
        request.setMethod('POST');
        system.debug('@@targetURL' + targetURL);    
        request.setEndpoint(targetURL);
        request.setBody(BodyPayload);
        request.setCompressed(false);
        request.setTimeout(120000); 
        
        
        
        
        try {
            // Get HTTP response
            Http http = new Http();
            HttpResponse res = http.send(request);
            responseBody= res.getBody();
            Integer responseCode = res.getStatusCode();
            system.debug('@@responseBody: ' + responseBody);
            system.debug('@@responseCode: ' + responseCode);
            
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String importId = (String) responseMap.get('importId');
            // Add importId to the static list
            importIdList.add(importId);
        } catch (Exception e) {
            // Handle callout errors
            System.debug('Callout error: ' + e.getMessage());
        }
        
    }
    
    // Implement finish method
    public void finish(Database.BatchableContext bc) {
        system.debug('@@-Inside Finish: ');
        if(importIdList.isEmpty()){
            System.scheduleBatch(new TraxPOCBatchCheckStatus(importIdList), 'SecondBatchJob_' + System.now().getTime(), 1, 100 );
        }
    }
    
    public static Map<String, Object> createJSONAttachment(Account outlet) {
        Map<String, Object> dataMap = new Map<String, Object>();
        dataMap.put('street', outlet.BillingStreet);
        dataMap.put('store_type_name', outlet.Global_Channel__c);
        dataMap.put('store_number', outlet.Id);
        dataMap.put('store_name', outlet.Name);
        dataMap.put('store_display_name', outlet.Name);
        dataMap.put('state_name', outlet.Area__r.Name);
        dataMap.put('retailer_name', outlet.Parent.Name);
        if(outlet.Region__c  != null){
            dataMap.put('region_name', outlet.Region__r.Name);
        }else{
            dataMap.put('region_name', 'None');
        } 
        
        dataMap.put('postal_code', outlet.BillingPostalCode);
        dataMap.put('longitude', outlet.BillingLongitude);
        dataMap.put('latitude', outlet.BillingLatitude);
        dataMap.put('is_active', outlet.Status__c == 'Active');
        dataMap.put('city', outlet.BillingCity);
        //---------------------
        String gthString = Label.GT_Global_Travel_Hub_Code;
        String distributorName = ''; 
        if(outlet.Country_Code__c  != gthString && outlet.Supplier_Outlets1__r != null && outlet.Supplier_Outlets1__r.size()>0){
            for(Supplier_Outlet__c so :outlet.Supplier_Outlets1__r){
                distributorName = outlet.Supplier_Outlets1__r[0].Distributor_Wholesaler__r.Name; 
            } 
        }
        
        String attribute_1 = outlet.Global_Sub_channel__c;
        String attribute_2 =  outlet.Global_Segment__c;
        String attribute_3 =  outlet.Consumer_Segmentation__r.Name;
        String attribute_4 =  outlet.Outlet_Visit_Prioritisation_Grade__r.Name;
        String attribute_5 =  outlet.Fascia__r.Name;
        String attribute_6 =  outlet.Local_Segment2__r.Name;
        String attribute_7 = distributorName;
        String attribute_8 =  outlet.Local_Segment1__r.Name;
        String attribute_9 =  outlet.Store_Size__r.name;
        String attribute_10 = outlet.Global_Sub_Segment__c;
        String attribute_16 = outlet.Local_Segment_Advanced_Analytics__c;
        
        if(attribute_1 != null){
            dataMap.put('additional_attribute_1', attribute_1);    
        }else{
            dataMap.put('additional_attribute_1', '');
       }
        if(attribute_2 != null){
            dataMap.put('additional_attribute_2', attribute_2);    
        }else{
            dataMap.put('additional_attribute_2', '');
       }  
        if(attribute_3 != null){
            dataMap.put('additional_attribute_3', attribute_3.substring(0,attribute_3.indexof('[')!=-1? attribute_3.indexof('['):attribute_3.length()));
        }else{
            dataMap.put('additional_attribute_3', '');
       }   
        if(attribute_4 != null){
			dataMap.put('additional_attribute_4', attribute_4.substring(0,attribute_4.indexof('[')!=-1 ? attribute_4.indexof('['):attribute_4.length()));
        }else{
            dataMap.put('additional_attribute_4', '');
        }
        if(attribute_5 != null){
            dataMap.put('additional_attribute_5', attribute_5);
        }else{
            dataMap.put('additional_attribute_5','');
        }
        if(attribute_6 != null){
            dataMap.put('additional_attribute_6', attribute_6.substring(0,attribute_6.indexof('[')!=-1 ? attribute_6.indexof('['):attribute_6.length()));
        }else{
            dataMap.put('additional_attribute_6', '');
        }
        if(attribute_7 != null){
            dataMap.put('additional_attribute_7', attribute_7);
        }else{
           dataMap.put('additional_attribute_7', '');
        }
        if(attribute_8 != null){
            dataMap.put('additional_attribute_8', attribute_8.substring(0,attribute_8.indexof('[')!=-1 ? attribute_8.indexof('['):attribute_8.length()));
        }else{
            dataMap.put('additional_attribute_8', '');
        }
        if(attribute_9 != null){
            dataMap.put('additional_attribute_9', attribute_9.substring(0,attribute_9.indexof('[')!=-1 ? attribute_9.indexof('['):attribute_9.length()));
            
        }else{
            dataMap.put('additional_attribute_9','');
        }
        dataMap.put('additional_attribute_10', attribute_10);       
        if(attribute_16 != null){
            dataMap.put('additional_attribute_16',attribute_16);    
        }else{
            dataMap.put('additional_attribute_16', '');
       }
        return dataMap;
        
        
        
    }
}