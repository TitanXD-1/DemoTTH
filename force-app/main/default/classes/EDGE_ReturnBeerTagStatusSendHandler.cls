/**

* @description :  EDGE_ReturnBeerTagStatusSendHandler

* @history :

* Version   Developer      Date        User Story	  Purpose
* 1.1       Prasanth T   20/08/2021    ES20-10373     New Return Beer Tags with Status-New is sent to SAP and The Status is updated based on the response.
* 1.2		Mayukh SRoy  13/01/2022    ES20-13728     UAT_EDGE_ReturnBeerTagStatusSendBatch failing
* 1.3		Rajarshi L   08/03/2023	   ES20-13880     SAP Password Storage in Salesforce_SFDC_Technical Debt
*/
public with sharing class EDGE_ReturnBeerTagStatusSendHandler {
    
    final static String salesTerritoryType = System.Label.EDGE_Return_Beer_Tag_Sales_Territory;
    final static String serviceTerritoryType =System.Label.EDGE_Return_Beer_Tag_Service_Territory;
    final static String qualityDispenseTerritoryType = System.Label.EDGE_Return_Beer_Tag_Quality_Dispense_Territory;
    final static String serviceLeadTerritoryType = System.Label.EDGE_Return_Beer_Tag_Service_Lead_Territory;
    final static String rqmIeTerritoryType = System.Label.EDGE_Return_Beer_Tag_RQM_IE_Territory	;
    /*
    final static String endPointURL = System.Label.EDGE_Return_Beer_Tag_SAP_End_Point_Url;
    final static String endPointPassword = System.Label.EDGE_Return_Beer_Tag_SAP_End_Point_Password;
    final static String endPointUsername = System.Label.EDGE_Return_Beer_Tag_SAP_End_Point_Username;
*/
    String request = '';
    String response = '';
    
    private RB_SapReturnBeerWebCallout.HTTPS_Port RB_StubClass;
    
    public EDGE_ReturnBeerTagStatusSendHandler(){
        RB_StubClass = new RB_SapReturnBeerWebCallout.HTTPS_Port();
    }
    
    // Handler function to send tag details to sap interface.
    public void sendTagsDetails(List<Return_Beer_Tag__c> newReturnBeerTagsList){
        List<RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_CreateTag_D1> returnBeerTagCalloutList =   new List<RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_CreateTag_D1>();
        
        if(newReturnBeerTagsList != null && newReturnBeerTagsList.Size()>0){
            
            //createSapConnection();--ES20-13880 Commented this out
            
            set<string> accountIdSet = new set<string>();
            Map<Id,String> returnBeerAccountMap= new Map<Id,String>();
            
            for(Return_Beer_Tag__c returnBeerObj : newReturnBeerTagsList){
                if(returnBeerObj.Case_Task__c != null && (returnBeerObj.Case_Task__r).Account__c != null){
                    accountIdSet.add((returnBeerObj.Case_Task__r).Account__c);
                    returnBeerAccountMap.put(returnBeerObj.id,(returnBeerObj.Case_Task__r).Account__c);
                }
            }
            Map<Id,list<Outlet_Territory__c>> accountOutletTerritoryMap  = new Map<Id,list<Outlet_Territory__c> >();
            
            if(accountIdSet !=null && accountIdSet.Size()>0){
                for(Outlet_Territory__c outletTerritoryId : [SELECT Id,
                                                             Outlet__c,
                                                             Outlet__r.Country__r.Code__c,
                                                             Outlet__r.SAP_Ship_to__c,
                                                             Outlet__r.SAP_Sold_to__c,
                                                             Outlet__r.Primary_Sales_Territory__r.Name,
                                                             Outlet__r.Primary_Sales_Territory_Region__r.Name,
                                                             Territory__c,
                                                             Territory__r.Name,
                                                             Territory__r.Territory_Type__c,
                                                             Territory__r.Region__c,
                                                             Territory__r.Region__r.Name
                                                             FROM Outlet_Territory__c
                                                             WHERE Outlet__c IN:accountIdSet
                                                             AND Territory__r.Territory_Type__c != Null])
                {
                    if(accountOutletTerritoryMap.containsKey(outletTerritoryId.Outlet__c)){
                        accountOutletTerritoryMap.get(outletTerritoryId.Outlet__c).add(outletTerritoryId);
                    }else{
                        accountOutletTerritoryMap.put(outletTerritoryId.Outlet__c,new List<Outlet_Territory__c>{outletTerritoryId});
                    }
                }
                
            }
            
            for(Return_Beer_Tag__c returnBeerObj : newReturnBeerTagsList){
                 // create RB wsdl records 
               	 RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_CreateTag_D1 wsdlReturnBeerTag = new RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_CreateTag_D1();
                // SAP's wsdl stub class 

                // salesforce ID
                wsdlReturnBeerTag.sfdcid = returnBeerObj.Id;
                
                // create date time
                wsdlReturnBeerTag.create_date = returnBeerObj.CreatedDate;
                
                // keg number
                if(returnBeerObj.Keg_number__c != null){
                    wsdlReturnBeerTag.kegnum = returnBeerObj.Keg_number__c;
                }
                
                
                // sap material number
                if(returnBeerObj.Product__c !=null && (returnBeerObj.Product__r).Product__r.SAP_SKU_Code__c!= null){
                    wsdlReturnBeerTag.matnr = (returnBeerObj.Product__r).Product__r.SAP_SKU_Code__c ;
                }
                
                // volume
                if(string.valueof(returnBeerObj.Volume__c) != null){
                    wsdlReturnBeerTag.out_vol = string.valueof(returnBeerObj.Volume__c);
                }
                
                // Reason Code
                if(returnBeerObj.Reason_Code__c != null && (returnBeerObj.Reason_Code__r).Reason_Code_Name__c != null){
                    wsdlReturnBeerTag.reason = (returnBeerObj.Reason_Code__r).Reason_Code_Name__c;
                }
                
                // Reason Category
                if(returnBeerObj.Reason_Category__c != null && (returnBeerObj.Reason_Category__r).Reason_Category_Name__c != null){
                    wsdlReturnBeerTag.reason_cat = returnBeerObj.Reason_Category__r.Reason_Category_Name__c;
                }
                
                // the barcode tag number
                if(returnBeerObj.Tag_Number__c != null){
                    wsdlReturnBeerTag.tagnum = returnBeerObj.Tag_Number__c;
                }
                
                // whether sample is taken or not
                if(returnBeerObj.Sample_Taken__c == 'Yes' ){
                    wsdlReturnBeerTag.sampled = true;
                }else if(returnBeerObj.Sample_Taken__c == 'No' ){
                    wsdlReturnBeerTag.sampled = false;
                }
                
                // whether keg is broached
                if(returnBeerObj.Broached_Keg__c == 'Yes' ){
                    wsdlReturnBeerTag.broached = true;
                }else if(returnBeerObj.Broached_Keg__c == 'No' ){
                    wsdlReturnBeerTag.broached = false;
                } 
                
                if((returnBeerObj.Case_Task__r).Account__c != null){
                    if(accountOutletTerritoryMap != null && accountOutletTerritoryMap.Size()>0 && accountOutletTerritoryMap.get((returnBeerObj.Case_Task__r).Account__c) !=  null){
                        
                        // country code of the record
                        if(accountOutletTerritoryMap.get((returnBeerObj.Case_Task__r).Account__c)[0].Outlet__r.Country__r.Code__c != null){                                
                            wsdlReturnBeerTag.country = accountOutletTerritoryMap.get((returnBeerObj.Case_Task__r).Account__c)[0].Outlet__r.Country__r.Code__c;
                        }
                        
                        // SAP Ship to of Outlet
                        if(accountOutletTerritoryMap.get((returnBeerObj.Case_Task__r).Account__c)[0].Outlet__r.SAP_Ship_to__c != null){
                            wsdlReturnBeerTag.ship_to =  accountOutletTerritoryMap.get((returnBeerObj.Case_Task__r).Account__c)[0].Outlet__r.SAP_Ship_to__c;
                            
                        }
                        
                        // SAP Ship to of Outlet
                        if(accountOutletTerritoryMap.get((returnBeerObj.Case_Task__r).Account__c)[0].Outlet__r.SAP_Sold_to__c != null){
                            wsdlReturnBeerTag.sold_to =  accountOutletTerritoryMap.get((returnBeerObj.Case_Task__r).Account__c)[0].Outlet__r.SAP_Sold_to__c;
                        }
                        
                        for(Outlet_Territory__c outletTerritoryObj : accountOutletTerritoryMap.get((returnBeerObj.Case_Task__r).Account__c)){
                            // If there is a territory associated with this outlet which is Service type 
                            if(outletTerritoryObj.Territory__r.Territory_Type__c == serviceTerritoryType){
                                if(outletTerritoryObj.Territory__r.Name != null){
                                    wsdlReturnBeerTag.srvcrep = outletTerritoryObj.Territory__r.Name;
                                    
                                }
                                if(outletTerritoryObj.Territory__r.Region__r.Name != null){
                                    wsdlReturnBeerTag.srvcrep_reg   = outletTerritoryObj.Territory__r.Region__r.Name;
                                    
                                }
                                
                            }
                            // If there is a territory associated with this outlet which is Quality Dispense type
                            else if(outletTerritoryObj.Territory__r.Territory_Type__c == qualityDispenseTerritoryType){
                                if(outletTerritoryObj.Territory__r.Name != null){
                                    wsdlReturnBeerTag.disrep = outletTerritoryObj.Territory__r.Name;
                                }
                                if(outletTerritoryObj.Territory__r.Region__r.Name != null){
                                    wsdlReturnBeerTag.disprep_reg   = outletTerritoryObj.Territory__r.Region__r.Name;
                                }
                                
                            }// If there is a territory associated with this outlet which is Sales type
                            else if(outletTerritoryObj.Territory__r.Territory_Type__c == salesTerritoryType){
                                
                                if(outletTerritoryObj.Outlet__r.Primary_Sales_Territory__r.Name!= null){
                                    wsdlReturnBeerTag.salesrep = outletTerritoryObj.Outlet__r.Primary_Sales_Territory__r.Name;
                                }
                                if(outletTerritoryObj.Outlet__r.Primary_Sales_Territory_Region__r.Name != null){
                                    wsdlReturnBeerTag.salerep_reg = outletTerritoryObj.Outlet__r.Primary_Sales_Territory_Region__r.Name;
                                }
                                // If there is a territory associated with this outlet which is Service Lead type
                            }else if(outletTerritoryObj.Territory__r.Territory_Type__c == serviceLeadTerritoryType){
                                if(outletTerritoryObj.Territory__r.Name != null){
                                    wsdlReturnBeerTag.lead_srvcrep_terr = outletTerritoryObj.Territory__r.Name;
                                    
                                }
                                // If there is a territory associated with this outlet which is RQM IE type
                            }else if(outletTerritoryObj.Territory__r.Territory_Type__c == rqmIeTerritoryType){
                                if(outletTerritoryObj.Territory__r.Name != null){
                                    wsdlReturnBeerTag.rqm_terr = outletTerritoryObj.Territory__r.Name;
                                    
                                }
                            }                        
                        }
                    }else{
                        wsdlReturnBeerTag.country = '';
                        wsdlReturnBeerTag.ship_to = '';
                        wsdlReturnBeerTag.sold_to = '';
                        wsdlReturnBeerTag.srvcrep = '';
                        wsdlReturnBeerTag.srvcrep_reg = '';
                        wsdlReturnBeerTag.disrep = '';
                        wsdlReturnBeerTag.disprep_reg = '';
                        wsdlReturnBeerTag.salesrep = '';
                        wsdlReturnBeerTag.salerep_reg = '';
                        wsdlReturnBeerTag.qrep = '';
                        wsdlReturnBeerTag.qualrep_reg = '';
                        wsdlReturnBeerTag.lead_srvcrep_terr = '';
                        wsdlReturnBeerTag.rqm_terr = '';
                    }     
                }
                returnBeerTagCalloutList.add(wsdlReturnBeerTag);
            }
            
            // if there are any records
            if(returnBeerTagCalloutList != null && returnBeerTagCalloutList.size()>0){
                
                // add details to tag method
                if(!system.Test.isRunningTest()){
                    request = fetchReturnBeerTagRequestLog(returnBeerTagCalloutList,returnBeerAccountMap);
                    system.debug('request check '+request);
                    try{
                        String sapStatus;
                        boolean status= RB_StubClass.SI_ReturnBeerTags_Sync_Out_D1(returnBeerTagCalloutList);
                        response = status == null? '' : '\''+status+'\'';
                        if(status){
                            for(Return_Beer_Tag__c rbTag : newReturnBeerTagsList){
                                rbTag.Status__c = EDGE_Constant.SAP_Success;
                                sapStatus = 'SAP Success';
                                //D1_CustomLoggingUtility.logMessage('EDGE_ReturnBeerTagStatusSendHandler', 'sendTagsDetails', 'SAP Success','','', request != null ? request : '', response);//ES20-13728
                            }
                        }else if(!status){
                            for(Return_Beer_Tag__c rbTag : newReturnBeerTagsList){
                                rbTag.Status__c = EDGE_Constant.SAP_Failure;
                                sapStatus = 'SAP Failure';
                                //D1_CustomLoggingUtility.logMessage('EDGE_ReturnBeerTagStatusSendHandler', 'sendTagsDetails', 'SAP Failure','','', request != null ? request : '', response);//ES20-13728
                            }
                        }
                        Database.update(newReturnBeerTagsList,false);
                        //ES20-13728
                        D1_CustomLoggingUtility.logMessage('EDGE_ReturnBeerTagStatusSendHandler', 'sendTagsDetails', sapStatus,'','', request != null ? request : '', response);
                        // Call out exception
                    }catch(CalloutException callexception){
                        for(Return_Beer_Tag__c rbTag : newReturnBeerTagsList){
                            rbTag.Status__c = EDGE_Constant.SAP_Failure; 
                        }
                        Database.update(newReturnBeerTagsList,false);                             
                        D1_CustomLoggingUtility.logMessage('EDGE_ReturnBeerTagStatusSendHandler', 'sendTagsDetails', callexception.getCause()+';'+callexception.getLineNumber()+';'+callexception.getMessage(), callexception.getStackTraceString(), callexception.getTypeName(), request != NULL ? request:'', response != NULL ? response:'');
                        // General Exception
                    }catch(exception genExcep){
                        for(Return_Beer_Tag__c rbTag : newReturnBeerTagsList){
                            rbTag.Status__c = EDGE_Constant.Salesforce_Failure;
                        }
                        Database.update(newReturnBeerTagsList,false);
                        //logging code- Status will SFDC failure
                        D1_CustomLoggingUtility.logMessage('EDGE_ReturnBeerTagStatusSendHandler', 'sendTagsDetails', genExcep.getCause()+';'+genExcep.getLineNumber()+';'+genExcep.getMessage(),genExcep.getStackTraceString(), genExcep.getTypeName(), request != NULL ? request:'', response != NULL ? response:'');
                    }
                } 
            }   
        }
    }
    //ES20-13880-Commented this method out
    /**
      // internal method to create sap login
    private void createSapConnection(){
        try{
            // base url to sap 
            String end_point = endPointURL;
            // username to login to sap box
            String sf_username = endPointUsername;
            // password to login
            String sf_password = endPointPassword;
            Blob headerValue = Blob.valueOf(sf_username + ':' + sf_password);
            // create authorization  
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            // initailize the map  
            RB_StubClass.inputHttpHeaders_x = new Map<String, String>();
            // add authoriztion to header
            RB_StubClass.inputHttpHeaders_x.put('Authorization', authorizationHeader);
            // specify the endpoint to sap wsdl.
            RB_StubClass.endpoint_x = end_point; 
        }catch(Exception e){
            D1_CustomLoggingUtility.logMessage('EDGE_ReturnBeerTagStatusSendHandler', 'createSapConnection', e.getCause()+';'+e.getLineNumber()+';'+e.getMessage(), e.getStackTraceString(), e.getTypeName(), request != NULL ? request:'', response != NULL ? response:'');
            
        }
        
    }
**/
      
    public string fetchReturnBeerTagRequestLog(List<RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_CreateTag_D1> returnBeerTagCalloutList,Map<Id,String> returnBeerAccountMap){


        List<RequestLog> requestLogList = new List<RequestLog>();
        for (RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_CreateTag_D1 requestLog : returnBeerTagCalloutList ){
             RequestLog wrpperRqstLog = new RequestLog();
             wrpperRqstLog.sfdcId = requestLog.sfdcid;
             wrpperRqstLog.tagnum = requestLog.tagnum;
             wrpperRqstLog.out_vol = requestLog.out_vol;
             wrpperRqstLog.reason = requestLog.reason;
             wrpperRqstLog.reason_cat = requestLog.reason_cat;
             wrpperRqstLog.accountId = returnBeerAccountMap.get(requestLog.sfdcid);
             requestLogList.add(wrpperRqstLog);
        }
         return JSON.serialize(requestLogList);
    }
   
    public class RequestLog{
         public String sfdcId;
         public String tagnum;
         public String out_vol;
         public String reason;
         public String reason_cat;
         public String accountId;
    }
    
}