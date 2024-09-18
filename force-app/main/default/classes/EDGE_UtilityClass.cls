/**
* @description : EDGE_UtilityClass

* @purpose : To Provide various tools for other class to ensure a smooth operation.

* @history :  

*VERSION     AUTHOR            DATE              DETAIL
*1.0     Kapil Baliyan    13/02/2019      Initial Development
*1.1     Anuja            18/03/2019      populateGUID
*1.2     Manikant P                       getAttachment ,translate and getTableBody(Modified)
*1.3     Manohar Burkala  13/12/2019      Transfer Order Email Templete Modified.
*1.4     Ankit Das        27/01/2020      Introduction of two DateTime fields in getTableBody()(ES20-6910)
*1.5     Amar Deep        28/07/2020      Changed Billing country to Geo country in the email template of all types of Order (ES20-7236)
*1.6     Rubeena          02/12/2020      Inclusion of two new fields Legacy Front Office Number and Terrioty Name of Rep for POS order emails[CR-2178] 
*1.7     Monalisa Halder  01/02/2021      ES20-9212
*1.8     Divya Bansal     24/02/2021      ES20-9289 
*1.8     Monalisa Halder  01/02/2021      ES20-10090
*1.9     Amar Deep        11/05/2021      NCP-2677
*2.0     Monalisa Halder  17/06/2021      ES20-9974,9976 - removing getTransferOrderMail,getAdditionalOrderFields,getOverAllCommentsSection methods
*3.0   Monalisa Halder  27/07/2021      ES20-10866
*4.0     Anand Uppalapati 30/12/2021     ES20-11063
*5.0     Joshraj Sen      21/02/2022       ES20-12118
*6.0	Rajarshi Lahiri	  10/05/2022	ES20-12641
*7.0    Joshraj Sen       12/05/2022    ES20-12516(To acccomodate BillingStates and ShippingStates)
*8.0	Rajarshi Lahiri	  13/05/2022	ES20-12728
*9.0	Rajarshi Lahiri	  06/07/2023	142552-QA_EDGE_TransferOrderStatusUpdateBatch is failing
*10.0   Doman/Mayukh      14/07/2023    301950 - Changed label for Sales Rep for Free Goods Order
*10.1	Saurav Prasad		04/09/2023	145098 - Optimize the ContentDocumentTrigger_SFDC_Technical Debt
*10.2   Doman Murmu       04/10/2023    146443 - EDGE Static Code Violation
*10.3	Shivam Chauhan	  27/12/2023	148622
*/

public with sharing class EDGE_UtilityClass {
    //Variable to stop trigger recursion 
    public static boolean stopTriggerToRun=false;
    public static boolean stopSecondTriggerToRun=false;
    public static boolean stopThirdTriggerToRun=false;
    public static boolean stopCallTriggerToRun=false;
    public static boolean stopCallTriggerUpdateToRun=false;
    public static boolean stopTriggerToRunOutlet=false;
    static Id salresRepProfId;
    //static Map<String,String> metaDataReqdMap = new Map<String,String>();
    //static Map<Id, Market_Setting__c> countryIdToMrkStngMap = new Map<Id, Market_Setting__c>();
    static String readOnlyErrorStr = Label.EDGE_Validation_Read_Only_Error_Message ;
    static String mandatoryErrorStr = Label.EDGE_Validation_Mandatory_Error_Message ;
    static Map<String,String> mapParentFields;
    static Map<String,List<String>> mapDependentFields;
    
    //To Check whether Trigger is disabled or not
    public static boolean isTriggerDisabled(string triggerName){
        
        
        //1. Check All Org Trigger is disabled or not
        Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();
        boolean isDisabled = true;
        if(!orgSetting.Run_Triggers__c){
            return true;
        }   
        else{        
            //2. Check whether particular object trigger is disabled or not
            if (Schema.sObjectType.Trigger_Setting__mdt.isAccessible()) {
                //145098
                for(Trigger_Setting__mdt triggerSetting : Trigger_Setting__mdt.getAll().values()){
                    if(triggerSetting.MasterLabel == triggerName){
                        isDisabled = !triggerSetting.IsEnabled__c;
                        break;
                    } 
                }
                //end of 145098
            }
            EDGE_UtilityClass.printGovLimits(61);
            return isDisabled;            
        }
    }
    
    //Return Map of KPI Weightings 
    public static Map<string, Map<Id,Geography__c>> getgeoRecordTypeMap(){
        Map<string, Map<Id,Geography__c>> geoRecordTypeMap = new Map<string, Map<Id,Geography__c>>();
        if (Schema.sObjectType.Geography__c.isAccessible()) {
            for( Geography__c geo : [SELECT Id, Code__c, CFM_Queue__c, MDM_Queue__c, Parent_Geography__c, recordtype.Name, Minimum_Product_Assortment__c, Minimum_Activation_Standards__c FROM Geography__c]){
                if(geoRecordTypeMap.get(geo.recordtype.Name)!=null){
                    
                    geoRecordTypeMap.get(geo.recordtype.Name).put(geo.Id, geo);
                }   
                else{   
                    Map<Id,Geography__c> geoMap=new Map<Id,Geography__c>();
                    geoMap.put(geo.Id, geo);
                    geoRecordTypeMap.put(geo.recordtype.Name,geoMap);
                }               
            }           
        }
        return geoRecordTypeMap;
    }
    
    //Return 0 if value is null
    public static Decimal checkForNull(Decimal val){
        if(val != null){
            return val;
        }else{
            return 0;
        }
    }
    
    //Null check for Id
    public static String checkForNullId(Id val){
        System.debug(LoggingLevel.DEBUG,'val = '+ val);
        return val != null ? val : '';
    }
    
    //Null check for String
    public static String checkForNull(String val){
        return val != null ? val : '';
    }
    
    /**

*@description  : populateGUID - This method populates GUID field (External ID)

*@return : void

*@param : list<Sobject>

*/
    
    public static void populateGUID(list<Sobject> sObjectRecords){
        //populate GUID field (if blank) with unique AES key
        for(Sobject sobj:sObjectRecords){
            //check if external id (GUID)field is blank
            if(sobj.get(EDGE_Constant.EXTERNALID_GUID_FIELD_NAME ) == null){
                //code to generate a new unique key
                sobj.put(EDGE_Constant.EXTERNALID_GUID_FIELD_NAME ,EncodingUtil.convertToHex(Crypto.generateAesKey(128)));
            }
        }
    }
    
    //This method returns Country Code with Market Setting Map
    public static Map<String, Market_Setting__c> getCountryMarketSetting(){
        Map<String, Market_Setting__c> marketSettingMap = new Map<String, Market_Setting__c>();
        for( Market_Setting__c marketSetting : [SELECT Id, Geography__r.Code__c, Distribution__c, Minimum_Activation_Standards__c, Minimum_Product_Assortment__c, New_Product_Distribution__c FROM Market_Setting__c]){
            marketSettingMap.put(marketSetting.Geography__r.Code__c, marketSetting);
        }
        return marketSettingMap;
    }
    
    //method to find the number of weeks with given two dates
    public static Integer getCurrWeekNumberInCycle(Date startDate,Date endDate){
        Integer totalWeekCount = 1;
        DateTime startDt = (DateTime)startDate;
        DateTime endDt  =  (DateTime)endDate;       
        //Get Start Date Week Number
        Integer startDateWeekNumber = Integer.valueOf(startDt.format('u')); 
        
        //Get First Week End Date by adding remaning days of week (Total Days(7) - Start Date WeekDay(3))
        DateTime weekEndDate = startDt.addDays(7-startDateWeekNumber);
        
        //Iterate over till weekEndDate < endDate
        while(weekEndDate < endDt){
            weekEndDate = weekEndDate.addDays(7);
            totalWeekCount++;
        }        
        return totalWeekCount;
    } 
    
    //get fieldtype of a field of an object
    public static String getFieldType(String objectName, String fieldName){    
        SObjectType sObjType = ((SObject)(Type.forName('Schema.'+objectName).newInstance())).getSObjectType();
        DescribeSObjectResult dSobject = sObjType.getDescribe();        
        Schema.DisplayType fieldType = dSobject.fields.getMap().get(fieldName).getDescribe().getType();         
        return String.valueOf(fieldType);
    } 
    //get fieldtype of a field of an object
    /*  public static String getValueName(Id recordId){ 
String sObjName = recordId.getSObjectType().getDescribe().getName();


return String.valueOf(fieldType);
}*/
    
    //get MarketSettingMap with market and fieldset
    public static Map<String,String> getMarketSettingMap(Set<Id> marketIdSet,List<String> metaDataListVal){  
        MAP<String,String> marketSettingMap = new MAP<String,String>(); 
        Set<String> allFieldSet = new Set<String>();
        for(String mStr :metaDataListVal) {           
            allFieldSet.add(mStr); // using this Set to remove dulicates
        }
        //create dynamic query 
        String marketFieldString = '';
        for(String mStr :allFieldSet) {           
            marketFieldString += mStr + ',' ;
        }
        marketFieldString = marketFieldString.removeEnd(',');
        if(marketFieldString != null && !marketFieldString.containsIgnoreCase('Geography__c')){
            marketFieldString += ' , Geography__c,Local_Segmentation_Validation__c '; 
        }
        String queryString = 'SELECT ' + marketFieldString + ' FROM Market_Setting__c WHERE Geography__c IN : marketIdSet' ; //'SELECT Geography__c, '+ 
        //System.debug('--queryString'+queryString);
        List<Market_Setting__c> marketSettingList = Database.query(queryString);
        //System.debug('--@@ marketSettingList--'+marketSettingList);
        for(Market_Setting__c ms : marketSettingList){
            for(String msField : allFieldSet){
                String key = ms.Geography__c+'_'+msField;
                marketSettingMap.put(key, String.valueOf(ms.get(msField)));     
            } 
        }
        return marketSettingMap;
    }
    /**


*@description : translate - this class will be used to translate the language.

*@return : Map<String, String>

*@param : List<String>,String

*/
    
    public static Map<String, String> translate(List<String> labelNames, String language){
        
        String transLatedLabelValues = '';
        //variable name changed from UNIT_TEST_STR to unitTestStr by Vikas
        String unitTestStr = 'Unit.Test';
        Map<String, String> labelToTranslatedStrMap = new Map<String, String> ();
        
        pageReference vfPage = Page.EDGE_LabelTranslator;
        vfPage.getParameters().put('label_lang', language);
        vfPage.getParameters().put('labels', JSON.serialize(labelNames));
        
        if(Test.isRunningTest()) { 
            blob pdfBody;
            pdfBody = blob.valueOf(unitTestStr);   
        } else {
            transLatedLabelValues = vfPage.getContent().toString();
        }
        
        if(!String.isBlank(transLatedLabelValues)){
            System.debug(LoggingLevel.DEBUG,'Values '+transLatedLabelValues);
            labelToTranslatedStrMap = (Map<String, String>)JSON.deserialize(transLatedLabelValues, Map<String, String>.class);
        }
        return labelToTranslatedStrMap;
    }
    
    
    /**


*@description :  getTableBody - To get the Email Table To Be Sent To Delivery Partner with Details.

*@return : String

*@param : List<Order__c>,Map<String,List<Order_Item__c>>,String, Map<String, String>

*/
    
    public static string getTableBody(List<Order__c> orderList,Map<String,List<Order_Item__c>> orderListOrderMap,String languageName, Map<String, String> labelToTranslatedStrMap){
        
        String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
        String shedRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed').getRecordTypeId(); 
        String htmlBody = '';
        
        //open table and prepare the header for batch..
        if(languageName != null){
            htmlBody += '<table style="border: 1px solid black; ">';
            htmlBody += '<tr style="background: #074465; color: white;">';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_ClientCode')+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_OutletID')+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_OutletName')+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_LegacyFrontOfficeNmbr')+'</th>'; // CR-2178
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_TerritoryName')+'</th>'; // CR-2178
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_SalesRepName')+'</th>';    
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_SalesRepMobile')+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_SalesRepEmail')+'</th>';   
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_ToDelivery')+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_Address')+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_City')+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_State')+'</th>'; 
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_PostalCode')+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_Country')+'</th>'; 
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_OrderNumber')+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_DeliveryStartDate')+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_DeliveryEndDate')+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_ProductCode')+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_Quantity')+'</th>'; 
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_Notes')+'</th>'; 
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_TextToPrint')+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_Size')+'</th>'; 
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_Gender')+'</th>'; 
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_Colour')+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_PaperFinish')+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_OrderHeaderNotes')+'</th>';
            htmlBody += '</tr>';
            System.debug(LoggingLevel.DEBUG,'to test salesrep' +labelToTranslatedStrMap.get('EDGE_SalesRepName')); 
        }
        else{ 
            htmlBody += '<table style="border: 1px solid black; ">';
            htmlBody += '<tr style="background: #074465; color: white;">';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_ClientCode+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_OutletID+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_OutletName+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_LegacyFrontOfficeNmbr+'</th>'; //CR-2178
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_TerritoryName+'</th>'; //CR-2178
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_SalesRepName+'</th>';    
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_SalesRepMobile+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_SalesRepEmail+'</th>';   
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_ToDelivery+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_Address+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_City+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_State+'</th>'; 
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_PostalCode+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_Country+'</th>'; 
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_OrderNumber+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_DeliveryStartDate+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_DeliveryEndDate+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_ProductCode+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_Quantity+'</th>'; 
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_Notes+'</th>'; 
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_TextToPrint+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_Size+'</th>'; 
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_Gender+'</th>'; 
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_Colour+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_PaperFinish+'</th>';
            htmlBody += '<th style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_OrderHeaderNotes+'</th>';
            htmlBody += '</tr>'; 
        }
        set<Id> setOrderPOS = new set<Id>();
        //set<Id> setAccIds = new set<Id>();
        
        List<AccountShare> shedAccountList = new List<AccountShare>();
        //Map<Id,Id> shedAccountUserMap = new Map<Id,Id>();
        //Map<Id,Account>  shedIdtoAccountMap = new Map<Id,Account>();
        Map<Id,Account>  salesRepIdtoShedAccountMap = new Map<Id,Account>();
        String posorderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
        
        if(orderList!=null && orderList.size()>0){
            for(Order__c ordObj : orderList){
                if(ordObj.Delivery_Location__c == 'shed' && ordObj.RecordTypeId == posorderRecordTypeId ){
                    setOrderPOS.add(ordObj.Sales_Representative__c);
                    
                }  
            }
            
        }
        //Added isAccessible check for AccountShare by Vikas
        if(setOrderPOS != null && setOrderPOS.size()>0 && Schema.sObjectType.AccountShare.isAccessible()){
            shedAccountList = [SELECT AccountId,Account.BillingStreet, Account.BillingCity, Account.BillingState, 
                               Account.BillingPostalCode,Account.BillingCountry,UserOrGroupId FROM AccountShare WHERE UserOrGroupId IN :setOrderPOS AND Account.RecordTypeId =:shedRecordTypeId];
            for(AccountShare accShare : shedAccountList){
                //shedAccountUserMap.put(accShare.UserOrGroupId, accShare.AccountId); 
                Account accObj= new Account(id=accShare.AccountId,
                                            BillingStreet=accShare.Account.BillingStreet,
                                            BillingCity=accShare.Account.BillingCity,
                                            BillingState=accShare.Account.BillingState,
                                            BillingPostalCode=accShare.Account.BillingPostalCode,
                                            BillingCountry=accShare.Account.BillingCountry);
                
                salesRepIdtoShedAccountMap.put(accShare.UserOrGroupId,accObj);
            }
        }
        
        
        
        //iterate over list and output columns/data into table rows...
        if(orderList!=null && orderList.size()>0){
            for(Order__c ordObj : orderList){
                if(orderListOrderMap.size()>0 && orderListOrderMap.containsKey(ordObj.Id)){
                    List<Order_Item__c> ordItemQuantity = orderListOrderMap.get(ordObj.Id);
                    Integer ordQuantity = ordItemQuantity.size();
                    //Set<String> str = new Set<String>();
                    htmlBody += '<tr><td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + 'DIAGEO' + '</td>';
                    htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ordObj.Account__c + '</td>';
                    htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ordObj.Account__r.name + '</td>';
                    htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ordObj.Sales_Representative__r.name + '</td>';
                    htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((ordObj.Sales_Representative__r.MobilePhone)!=null ? ordObj.Sales_Representative__r.MobilePhone:'') + '</td>';
                    htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ordObj.Sales_Representative__r.Email + '</td>';
                    htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((ordObj.Delivery_Location__c)!=null ? ordObj.Delivery_Location__c:'') + '</td>' ;
                    
                    System.debug(LoggingLevel.DEBUG,'ordObj.Account__r.RecordTypeId = '+ ordObj.Account__r.RecordTypeId);
                    System.debug(LoggingLevel.DEBUG,'ordObj.Delivery_Location__c = ' + ordObj.Delivery_Location__c);
                    System.debug(LoggingLevel.DEBUG,'outletRecordTypeId = '+ outletRecordTypeId);
                    System.debug(LoggingLevel.DEBUG,'ordObj.Sales_Representative__c = '+ ordObj.Sales_Representative__c);
                    System.debug(LoggingLevel.DEBUG,'Account = '+  salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c));
                    
                    
                    if((ordObj.Account__r.RecordTypeId == shedRecordTypeId && ordObj.Delivery_Location__c =='Sales Rep')){
                        htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((ordObj.Sales_Representative__r.Street)!=null ? ordObj.Sales_Representative__r.Street:'') + '</td>';
                        htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((ordObj.Sales_Representative__r.City)!=null ? ordObj.Sales_Representative__r.City:'') + '</td>';
                        htmlBody += '<td rowspan="'+ordQuantity +'"  style="border:1px solid black; border-collapse: separate;">' + ((ordObj.Sales_Representative__r.State)!=null ? ordObj.Sales_Representative__r.State:'') + '</td>';
                        htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((ordObj.Sales_Representative__r.PostalCode)!=null ? ordObj.Sales_Representative__r.PostalCode:'') + '</td>';
                        htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((ordObj.Sales_Representative__r.Country)!=null ? ordObj.Sales_Representative__r.Country:'') + '</td>';  
                    }
                    
                    else if((ordObj.Account__r.RecordTypeId == shedRecordTypeId  && ordObj.Delivery_Location__c =='Shed') || (ordObj.Account__r.RecordTypeId == outletRecordTypeId  && ordObj.Delivery_Location__c =='Outlet')){
                        htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((ordObj.Account__r.BillingStreet)!=null ? ordObj.Account__r.BillingStreet:'') + '</td>';
                        htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((ordObj.Account__r.BillingCity)!=null ? ordObj.Account__r.BillingCity:'') + '</td>';
                        htmlBody += '<td rowspan="'+ordQuantity +'"  style="border:1px solid black; border-collapse: separate;">' + ((ordObj.Account__r.BillingState)!=null ? ordObj.Account__r.BillingState:'') + '</td>';
                        htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((ordObj.Account__r.BillingPostalCode)!=null ? ordObj.Account__r.BillingPostalCode:'') + '</td>';
                        htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((ordObj.Account__r.BillingCountry)!=null ? ordObj.Account__r.BillingCountry:'') + '</td>';  
                    }
                    else if(ordObj.Account__r.RecordTypeId == outletRecordTypeId && ordObj.Delivery_Location__c =='Shed'){
                        if(salesRepIdtoShedAccountMap != null && salesRepIdtoShedAccountMap.size()>0 && salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c) != null){
                            htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingStreet)!=null ? salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingStreet:'') + '</td>';
                            htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingCity)!=null ? salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingCity:'') + '</td>';
                            htmlBody += '<td rowspan="'+ordQuantity +'"  style="border:1px solid black; border-collapse: separate;">' + ((salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingState)!=null ? salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingState:'') + '</td>';
                            htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingPostalCode)!=null ? salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingPostalCode:'') + '</td>';
                            //htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((geoIdToAccountMap.get(salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).Country__c))!=null ? (geoIdToAccountMap.get(salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).Country__c)):'') + '</td>';
                            htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingCountry)!=null ? salesRepIdtoShedAccountMap.get(ordObj.Sales_Representative__c).BillingCountry:'') + '</td>'; 
                        }
                        else{
                            htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + '' + '</td>';
                            htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + '' + '</td>';
                            htmlBody += '<td rowspan="'+ordQuantity +'"  style="border:1px solid black; border-collapse: separate;">' + '' + '</td>';
                            htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + '' + '</td>';
                            htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + '' + '</td>'; 
                        }
                    }
                    
                    htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ordObj.Name + '</td>';
                    htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((ordObj.Delivery_Start_Date__c)!=null ? ordObj.Delivery_Start_Date__c.format('dd/MM/yyyy HH:mm',ordObj.Sales_Representative__r.TimeZoneSidKey):'') + '</td>';
                    htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((ordObj.Delivery_End_Date__c)!=null ? ordObj.Delivery_End_Date__c.format('dd/MM/yyyy HH:mm',ordObj.Sales_Representative__r.TimeZoneSidKey):'') + '</td>';
                    htmlBody += '<td rowspan="'+ordQuantity +'" style="border:1px solid black; border-collapse: separate;">' + ((ordObj.Order_Header_Notes__c)!=null ? ordObj.Order_Header_Notes__c:'') + '</td>';
                    
                    
                    if(orderListOrderMap!=null && orderListOrderMap.ContainsKey(ordObj.Id) && ordItemQuantity.size()>0){
                        
                        htmlBody += '<td height="100" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;">' + ((ordItemQuantity[0].Product__r.Product_Code__c)!=null ? ordItemQuantity[0].Product__r.Product_Code__c:'') + '</td>';
                        htmlBody += '<td height="100" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;">' + ordItemQuantity[0].Quantity__c + '</td>';
                        htmlBody += '<td height="100" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;">' + ((ordItemQuantity[0].Note__c)!=null ? ordItemQuantity[0].Note__c:'') + '</td>';
                        htmlBody += '<td height="100" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;">' + ((ordItemQuantity[0].Text_to_Print__c)!=null ? ordItemQuantity[0].Text_to_Print__c:'') + '</td>';
                        htmlBody += '<td height="100" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;">' + ((ordItemQuantity[0].Product_Variant__r.Size__c)!=null ? ordItemQuantity[0].Product_Variant__r.Size__c:'') + '</td>';
                        htmlBody += '<td height="100" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;">' + ((ordItemQuantity[0].Product_Variant__r.Gender__c)!=null ? ordItemQuantity[0].Product_Variant__r.Gender__c:'') + '</td>';
                        htmlBody += '<td height="100" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;">' + ((ordItemQuantity[0].Product_Variant__r.Colour__c)!=null ? ordItemQuantity[0].Product_Variant__r.Colour__c:'') + '</td>';
                        htmlBody += '<td height="100" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;">' + ((ordItemQuantity[0].Product_Variant__r.Paper_Finish__c)!=null ? ordItemQuantity[0].Product_Variant__r.Paper_Finish__c:'') + '</td>';
                        htmlBody += '</tr>' ; 
                        if(ordItemQuantity.size()>1){
                            for(integer i=1;i<ordItemQuantity.size();i++){
                                htmlBody +='<tr>';
                                htmlBody += '<td height="100" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;">' + ((ordItemQuantity[i].Product__r.Product_Code__c)!=null ? ordItemQuantity[i].Product__r.Product_Code__c:'') + '</td>';
                                htmlBody += '<td height="100" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;">' + ordItemQuantity[i].Quantity__c + '</td>';
                                htmlBody += '<td height="100" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;">' + ((ordItemQuantity[i].Note__c)!=null ? ordItemQuantity[i].Note__c:'') + '</td>';
                                htmlBody += '<td height="100" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;">' + ((ordItemQuantity[i].Text_to_Print__c)!=null ? ordItemQuantity[i].Text_to_Print__c:'') + '</td>';
                                htmlBody += '<td height="100" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;">' + ((ordItemQuantity[i].Product_Variant__r.Size__c)!=null ? ordItemQuantity[i].Product_Variant__r.Size__c:'') + '</td>';
                                htmlBody += '<td height="100" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;">' + ((ordItemQuantity[i].Product_Variant__r.Gender__c)!=null ? ordItemQuantity[i].Product_Variant__r.Gender__c:'') + '</td>';
                                htmlBody += '<td height="100" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;">' + ((ordItemQuantity[i].Product_Variant__r.Colour__c)!=null ? ordItemQuantity[i].Product_Variant__r.Colour__c:'') + '</td>';
                                htmlBody += '<td height="100" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;">' + ((ordItemQuantity[i].Product_Variant__r.Paper_Finish__c)!=null ? ordItemQuantity[i].Product_Variant__r.Paper_Finish__c:'') + '</td>';
                                htmlBody += '</tr>' ; 
                                
                            }
                        }
                    }
                }
            }
            
        }
        htmlBody += '</table>';
        
        return htmlBody;
    }
    
    /**
*@description : getTOAttachments - To get the attachment of order_item__c Object

*@return :  Map<Id,List<Messaging.Emailfileattachment>>

*@param : List<order__c>
*/
    public static Map<Id,List<Messaging.Emailfileattachment>> getTOAttachments(List<order__c> orderList){
        
        Map<Id,Order_item__c> orderItemMap = new Map<Id,Order_item__c>(); 
        List<contentDocumentLink> cdList = new List<contentDocumentLink>();
        Map<Id,List<Messaging.Emailfileattachment>> wholesalerOrderItemAttachmentList 
            = new Map<Id,List<Messaging.Emailfileattachment>>();
        
        
        //List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
        Set<ID> contentDocSet = new Set<ID>();
        Map<Id, Id> orderItemToWholeSalerMap = new Map<Id, Id> ();
        Map<Id, Id> cdToOrderItem = new Map<Id, Id> ();
        
        Map<ID,List<Messaging.Emailfileattachment>> contentAttachmentMap = new Map<ID,List<Messaging.Emailfileattachment>>();
        for(Order_item__c ordItmRec : [Select Id , Name,Order__r.Wholesaler__c,order__c from Order_item__c where Order__c IN :orderList]){
            orderItemMap.put(ordItmRec.id ,ordItmRec);
            orderItemToWholeSalerMap.put(ordItmRec.Id, ordItmRec.Order__r.Wholesaler__c);	
        }
        Set<Id> docIds = orderItemMap.keySet();
        //added isAccessible Check for contentDocumentLink by Vikas
        if(orderItemMap!=null && docIds.size()>0 && Schema.sObjectType.contentDocumentLink.isAccessible()){  //142552- Added a size check
            cdList =  [SELECT LinkedEntityid, ContentDocumentid FROM contentDocumentLink WHERE LinkedEntityid IN:docIds];  
        }
        
        
        for(contentDocumentLink cDLink : cdList ){            
            if(!contentDocSet.Contains(cDLink.LinkedEntityid)){               
                contentDocSet.add(cDLink.ContentDocumentid);
            }else{                
                contentDocSet.add(cDLink.ContentDocumentid);
            }
            cdToOrderItem.put(cDLink.ContentDocumentid,cDLink.LinkedEntityid);
        }
        
        if(contentDocSet.size()>0){
            for ( ContentVersion cversion : [SELECT title,PathOnClient,ContentDocumentId, FileType, versiondata FROM contentversion WHERE ContentDocumentId IN :contentDocSet]){            
                Messaging.Emailfileattachment emailFileAttac = new Messaging.Emailfileattachment();
                emailFileAttac.setFileName( cversion.title+'_'+cversion.FileType);
                emailFileAttac.setBody(cversion.versiondata);             
                if(!contentAttachmentMap.containsKey(cversion.ContentDocumentId)){
                    
                    //fileAttachments.add(emailFileAttac);
                    
                    Id orderItemId = cdToOrderItem.get(cversion.ContentDocumentId);
                    Id wholeSalerId;
                    
                    if(orderItemId != null){
                        wholeSalerId = orderItemToWholeSalerMap.get(orderItemId); 
                    }
                    
                    if(wholeSalerId != null){
                        if(!wholesalerOrderItemAttachmentList.containsKey(wholeSalerId)){
                            wholesalerOrderItemAttachmentList.put(wholeSalerId, new List<Messaging.Emailfileattachment>{emailFileAttac} );
                        }else{
                            wholesalerOrderItemAttachmentList.get(wholeSalerId).add(emailFileAttac);
                        }
                    }
                    //contentAttachmentMap.put(cversion.ContentDocumentId,fileAttachments);
                }
            }
        }
        //return fileAttachments;
        return wholesalerOrderItemAttachmentList;
    }
    
    /**


*@description : getAttachment - To get the attachment of order_item__c Object 

*@return :  List<Messaging.Emailfileattachment>

*@param : List<order__c>
*/
    public static List<Messaging.Emailfileattachment> getAttachment(List<order__c> orderList){
        
        Map<Id,Order_item__c> orderItemMap = new Map<Id,Order_item__c>(); 
        List<contentDocumentLink> cdList = new List<contentDocumentLink>();
        
        List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
        Set<ID> contentDocSet = new Set<ID>();
        
        Map<ID,List<Messaging.Emailfileattachment>> contentAttachmentMap = new Map<ID,List<Messaging.Emailfileattachment>>();
        for(Order_item__c ordItmRec : [Select Id , Name from Order_item__c where Order__c IN :orderList]){
            orderItemMap.put(ordItmRec.id ,ordItmRec);
        }
        //added isAccessible Check for contentDocumentLink by Vikas
        if(orderItemMap!=null && Schema.sObjectType.contentDocumentLink.isAccessible()){
            cdList =  [SELECT LinkedEntityid, ContentDocumentid FROM contentDocumentLink WHERE LinkedEntityid IN: orderItemMap.keySet()];  
        }
        
        
        for(contentDocumentLink cDLink : cdList ){            
            if(!contentDocSet.Contains(cDLink.LinkedEntityid)){               
                contentDocSet.add(cDLink.ContentDocumentid);
            }else{                
                contentDocSet.add(cDLink.ContentDocumentid);
            }  
        }
        
        
        if(contentDocSet.size()>0){
            for ( ContentVersion cversion : [SELECT title,PathOnClient,ContentDocumentId, FileType, versiondata FROM contentversion WHERE ContentDocumentId IN :contentDocSet]){            
                Messaging.Emailfileattachment emailFileAttac = new Messaging.Emailfileattachment();
                emailFileAttac.setFileName( cversion.title+'_'+cversion.FileType);
                emailFileAttac.setBody(cversion.versiondata);             
                if(!contentAttachmentMap.containsKey(cversion.ContentDocumentId)){ 
                    fileAttachments.add(emailFileAttac);
                    contentAttachmentMap.put(cversion.ContentDocumentId,fileAttachments);
                }else{
                    contentAttachmentMap.get(cversion.ContentDocumentId).add(emailFileAttac);
                } 
            }
        }
        return fileAttachments;
    }
    
    /**

*@description :activateProductBySize- Called by the Batch EDGE_ProductInactiveBatch 

*@return : List<Product__c>

*@param : Map<Id, List<Product_Variant__c>> ,Map<Id, Product__c> ,List<Product__c> 
*/
    public static List<Product__c> activateProductBySize(Map<Id, List<Product_Variant__c>> mapProductWithVariant,
                                                         Map<Id, Product__c> mapProductIdToProduct,
                                                         List<Product__c> updateActiveProductList)
    {   
        if(mapProductIdToProduct != null && mapProductIdToProduct.size()>0){
            for(Id prodId : mapProductIdToProduct.keySet()){
                Boolean isActive = false;
                if(mapProductWithVariant != null && mapProductWithVariant.containsKey(prodId)){
                    for(Product_Variant__c pvar : mapProductWithVariant.get(prodId)){
                        if(null != pvar.Unit_Price__c && pvar.Unit_Price__c >= 0){ 
                            isActive = true;
                            break;
                        }
                    }
                }
                
                Product__c productToUpdate = mapProductIdToProduct.get(prodId);
                productToUpdate.isActive__c = isActive;
                updateActiveProductList.add(productToUpdate);
            }
        }
        
        return updateActiveProductList;
    }
    
    /**
* @description : activateProductByQuantity - Called by the Batch EDGE_ProductInactiveBatch

* @ return : List<Product__c>

* @param :Map<Id,List<Product_Pricing__c>> , Map<Id, Product__c> ,List<Product__c> 

*/
    
    public static List<Product__c> activateProductByQuantity(Map<Id,List<Product_Pricing__c>> mapProductWithPricing,
                                                             Map<Id, Product__c> mapProductIdToProduct,
                                                             List<Product__c> updateActiveProductList)
    {    
        if(mapProductIdToProduct != null && mapProductIdToProduct.size()>0){
            for(Id prodId : mapProductIdToProduct.keySet()){
                Boolean isActive = false;
                if(mapProductWithPricing != null && mapProductWithPricing.containsKey(prodId)){
                    for(Product_Pricing__c ppr : mapProductWithPricing.get(prodId)){
                        if(null != ppr.Range_Price__c && ppr.Range_Price__c >= 0){ 
                            isActive = true;
                            break;
                        }
                    }
                }
                
                Product__c productToUpdate = mapProductIdToProduct.get(prodId);
                productToUpdate.isActive__c = isActive;
                updateActiveProductList.add(productToUpdate);
            }       
        }
        return updateActiveProductList;
    }
    
    /**

*@description : activateProductByUnit - Called by the Batch EDGE_ProductInactiveBatch 

*@return : List<Product__c>

*@param : Map<Id, Product__c>, List<Product__c>

*/
    
    public static List<Product__c> activateProductByUnit(Map<Id, Product__c> mapNewProduct, List<Product__c> updateActiveProductList){
        
        for(Id productId : mapNewProduct.keySet()){
            Product__c productRec = mapNewProduct.get(productId);
            if(((productRec.Expiry_Date__c > System.today() || productRec.Expiry_Date__c == null) 
                && productRec.Start_Date__c >= System.today()) && (productRec.Pricing_Type__c == 'By Unit'))
            {
                if(productRec.A_P_Cost__c >= 0){
                    productRec.IsActive__c = true;
                }else{
                    productRec.IsActive__c = false;
                }
                updateActiveProductList.add(productRec);
            }
        }
        return updateActiveProductList; 
    }
    
    
    /**
* @description : getFreeGoodsMail- Used from Edge_FreeGoodsOrderBatch for sending email when order is placed

* @return : String

* @param : List<Order__c>,Map<String,List<Order_Item__c>>,String,Map<String, String>
*/
    public static string getFreeGoodsMail(List<Order__c> orderList, Map<String,List<Order_Item__c>> orderListOrderItemMap,String languageName, Map<String, String> labelToTranslatedStrMap){
        String htmlBody = '';
        String todayDate = date.today().format();
        
        if(languageName != null && languageName != ''){
            htmlBody+= +labelToTranslatedStrMap.get('EDGE_EmailBody')+' ' + todayDate;
            htmlBody+= '<table style="border:1px solid balck;">';
        }
        else{
            htmlBody+= +Label.EDGE_EmailBody+' ' + todayDate;
            htmlBody+= '<table style="border:1px solid balck;">';  
        }
        if(orderList!=null && orderList.size()>0){
            for(Order__c ordObj: orderList){
                if(orderListOrderItemMap.size()>0 && orderListOrderItemMap.containsKey(ordObj.Id)){
                    List<Order_Item__c> orderItemList = orderListOrderItemMap.get(ordObj.Id);
                    Integer ordItemQuantity = orderItemList.size();
                    
                    
                    if(languageName != null && languageName != ''){
                        htmlBody += '<tr>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black ; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_AccountName')+'</td><td colspan="3" style="border:1px solid black; border-collapse: separate;"> '+ordObj.Account__r.name+'</td>';
                        htmlBody += '</tr>';
                        htmlBody += '<tr>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_AccountAdress')+'</td><td colspan="3" style="border:1px solid black; border-collapse: separate;"> '+ordObj.Account__r.BillingStreet + ',' + ordObj.Account__r.BillingCity + ',' +((ordObj.Account__r.BillingState) != null?ordObj.Account__r.BillingState:'') + ',' + ordObj.Account__r.country__r.name + '-' + ordObj.Account__r.BillingPostalCode+'</td>';
                        htmlBody += '</tr>';
                        htmlBody += '<tr>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black ; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_AccountPhone')+'</td><td colspan="3" style="border:1px solid black; border-collapse: separate;"> '+((ordObj.Account__r.PhonePrefix__c) != null ? ordObj.Account__r.PhonePrefix__c : '')+ ((ordObj.Account__r.Phone__c)!=null? ordObj.Account__r.Phone__c:'')+'</td>';
                        htmlBody += '</tr>';
                        htmlBody += '<tr>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black ; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_SalesRepresentative')+'</td><td colspan="3" style="border:1px solid black; border-collapse: separate;"> '+((ordObj.Sales_Representative__c!=null)? ordObj.Sales_Representative__r.Name: '')+'</td>'; //301950 - Changed label for representative
                        htmlBody += '</tr>';
                        htmlBody += '<tr>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_ExpectedDeliveryDate')+'</td><td colspan="3" style="border:1px solid black; border-collapse: separate;">'+((ordObj.Preferred_Delivery_Date__c)!=null ? ordObj.Preferred_Delivery_Date__c.format():'')+'</td>';
                        htmlBody += '</tr>';
                        htmlBody += '<tr>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_DeliveryInstructions')+'</td><td colspan="3" style="border:1px solid black; border-collapse: separate;">'+((ordObj.Delivery_instructions__c!=null ? ordObj.Delivery_instructions__c:''))+'</td>';
                        htmlBody += '</tr>';
                        
                        htmlBody += '<tr>';
                        htmlBody += '<td colspan="4" style="border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_OrderedProducts')+'</td>';
                        htmlBody += '</tr>';                       
                        htmlBody += '<tr>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EGDE_ProductName')+'</td>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_ProductSKUId')+'</td>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_ProductCode')+'</td>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_ProductDescription')+'</td>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_ProductQuantity')+'</td>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_Reason')+'</td>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+labelToTranslatedStrMap.get('EDGE_UOM')+'</td>';                        
                        htmlBody += '</tr>'; 
                    }
                    else{
                        htmlBody += '<tr>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black ; border-collapse: separate;">'+Label.EDGE_AccountName+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;"> '+ordObj.Account__r.name+'</td>';
                        htmlBody += '</tr>';
                        htmlBody += '<tr>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_AccountAdress+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;"> '+ordObj.Account__r.BillingStreet + ',' + ordObj.Account__r.BillingCity + ',' + ((ordObj.Account__r.BillingState) != null?ordObj.Account__r.BillingState:'') + ',' + ordObj.Account__r.country__r.name+ '-' + ordObj.Account__r.BillingPostalCode+'</td>';
                        htmlBody += '</tr>';
                        htmlBody += '<tr>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black ; border-collapse: separate;">'+Label.EDGE_AccountPhone+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;"> '+((ordObj.Account__r.PhonePrefix__c) != null ? ordObj.Account__r.PhonePrefix__c : '')+ ((ordObj.Account__r.Phone__c)!=null? ordObj.Account__r.Phone__c:'')+'</td>';
                        htmlBody += '</tr>';
                        htmlBody += '<tr>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black ; border-collapse: separate;">'+Label.EDGE_SalesRepresentative+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;"> '+((ordObj.Sales_Representative__c!=null)? ordObj.Sales_Representative__r.Name: '')+'</td>';  //301950 - Changed label for representative
                        htmlBody += '</tr>';
                        htmlBody += '<tr>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_ExpectedDeliveryDate+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;">'+((ordObj.Preferred_Delivery_Date__c)!=null ? ordObj.Preferred_Delivery_Date__c.format():'')+'</td>';
                        htmlBody += '</tr>';
                        htmlBody += '<tr>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_DeliveryInstructions+'</td><td colspan="5" style="border:1px solid black; border-collapse: separate;">'+((ordObj.Delivery_instructions__c!=null ? ordObj.Delivery_instructions__c:''))+'</td>';
                        htmlBody += '</tr>';
                        
                        htmlBody += '<tr>';
                        htmlBody += '<td colspan="6" style="border:1px solid black; border-collapse: separate;">'+Label.EDGE_OrderedProducts+'</td>';
                        htmlBody += '</tr>';                       
                        htmlBody += '<tr>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EGDE_ProductName+'</td>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_ProductSKUId+'</td>';// Added as part of ES20-12728
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_ProductCode+'</td>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_ProductDescription+'</td>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_ProductQuantity+'</td>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_Reason+'</td>';
                        htmlBody += '<td style="background: #074465; color: white; font-family: Arial; font: 14px ; font-weight: bold; border:1px solid black; border-collapse: separate;">'+Label.EDGE_UOM+'</td>';
                        htmlBody += '</tr>';
                    }
                    if(orderListOrderItemMap!=null && orderListOrderItemMap.ContainsKey(ordObj.Id) && ordItemQuantity>0){
                        /*  htmlBody += '<tr>';
htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' +orderItemList[0].Product__r.Name + '</td>';
htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' + ((orderItemList[0].Product__r.Product_Code__c)!=null ? orderItemList[0].Product__r.Product_Code__c:'') + '</td>';
htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' + ((orderItemList[0].Product__r.Description__c)!=null? orderItemList[0].Product__r.Description__c:'') + '</td>';
htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' + orderItemList[0].Quantity__c + '</td>';
htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' + ((orderItemList[0].Reason_Code__r.Name)!=null? orderItemList[0].Reason_Code__r.Name:'') + '</td>';
htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' + ((orderItemList[0].Selected_UoM__c)!=null? orderItemList[0].Selected_UoM__c:'') + '</td>';
htmlBody += '</tr>';*/
                        
                        for(integer i=0;i<ordItemQuantity;i++){
                            htmlBody += '<tr>';
                            htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' +((orderItemList[i].Market_Assortment_Product__r.D1_Product_Name__c)!=null ? orderItemList[i].Market_Assortment_Product__r.D1_Product_Name__c:orderItemList[i].Market_Assortment_Product__r.Product__r.Name) + '</td>';//Added as part of ES20-12641
                            htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' + ((orderItemList[i].Product__r.SAP_SKU_Code__c)!=null ? orderItemList[i].Product__r.SAP_SKU_Code__c:'') + '</td>';// Added as part of ES20-12728
                            htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' + ((orderItemList[i].Product__r.Product_Code__c)!=null ? orderItemList[i].Product__r.Product_Code__c:'') + '</td>';
                            htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' + ((orderItemList[i].Product__r.Description__c)!=null? orderItemList[i].Product__r.Description__c:'') + '</td>';
                            htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' + orderItemList[i].Quantity__c + '</td>';
                            htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' + ((orderItemList[i].Reason_Code__r.Name)!=null? orderItemList[i].Reason_Code__r.Name:'') + '</td>';
                            htmlBody += '<td height="70" style="border:1px solid black; border-bottom:1px solid black; border-collapse: separate;"">' + ((orderItemList[i].Selected_UoM__c)!=null? orderItemList[i].Selected_UoM__c:'') + '</td>';
                            htmlBody += '</tr>';
                        } 
                    }
                }
            }
        }
        htmlBody += '</table>';
        
        return htmlBody;
    }
    
    public static Messaging.SingleEmailMessage setEmailBody(List<Messaging.Emailfileattachment> fileAttachments,Account wholesaler,Delivery_Partner__c deliveryPartner,String body){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if(wholesaler!=null){
            mail.setTargetObjectId(wholesaler.CreatedById);
        }
        else if(deliveryPartner!=null){
            mail.setTargetObjectId(deliveryPartner.CreatedById);  
        }
        String todayDate = date.today().format();
        mail.setSubject('List Of Order Placed On_' + todayDate);
        mail.setHtmlBody(body);
        mail.saveAsActivity = false;
        if(fileAttachments!=null && fileAttachments.size()>0){
            mail.setFileAttachments(fileAttachments);
        }
        
        
        return mail;
    }
    
    /**
* @description : getMrktSttngForCountries- This methods market setting against all the country id shared

* @return :  Map<Id, Market_Setting__c>

* @param :  Set<Id>,Map<String,String>

*/
    public static Map<Id, Market_Setting__c> getMrktSttngForCountries(Set<Id> countryIds,Map<String,String> metaDataReqdMap){
        
        String queryStr = 'Select ';
        Map<Id, Market_Setting__c> countryIdToMrkStngMap = new Map<Id, Market_Setting__c>();
        String lastSeparator = ' , ';
        
        for(String mrktStngFldAPIName : metaDataReqdMap.keySet()){
            queryStr += mrktStngFldAPIName + lastSeparator;
        }
        if(queryStr != null && !queryStr.containsIgnoreCase('Geography__c')){
            queryStr += ' Geography__c' + lastSeparator; 
        }                                                                 
        
        if(queryStr != null && queryStr.lastIndexOf(lastSeparator) > 0){
            queryStr = queryStr.removeEndIgnoreCase(lastSeparator);
        }
        
        queryStr += ' from Market_Setting__c where Geography__c in :countryIds'; //Geography__c
        
        
        for(Market_Setting__c mrkStngRec : Database.query(String.escapeSingleQuotes(queryStr))){    //146443
            countryIdToMrkStngMap.put(mrkStngRec.Geography__c, mrkStngRec);
        }
        
        return countryIdToMrkStngMap;
        
    }
    
    /**
* @description : populateFieldPermissionMaps-This methods fetches Permission Set for Account, License & Supplier Outlet that is configured in the system-ES20-921

* @return : void

*  @param : String,Map<String,Field_Permission__c> ,Map<String,Field_Permission__c>,Map<String,Field_Permission__c>,Map<String,String>,Map<String,List<String>> 


*/
    public static void populateFieldPermissionMaps(String sObjectName, Map<String,Field_Permission__c> fieldPermissionOutletMap,Map<String,Field_Permission__c> fieldPermissionProspectMap,Map<String,Field_Permission__c> fieldPermissionOtherMap, Map<String,String> mapParentFieldsReturned,  Map<String,List<String>> mapDependentFieldsReturned){
        List<Business_Role__c> bRoleList = new List<Business_Role__c>();
        List<String> salesRepList = new List<String>();
        Set<Id> countryIdSet = new Set<Id>();
        Set<Id> fieldPermissionIdSet = new Set<Id>();
        Set<Id> fieldPermissionOutletIdSet = new Set<Id>();
        Set<Id> defaultfieldPermissionOutletIdSet = new Set<Id>();
        Set<Id> fieldPermissionProspectIdSet = new Set<Id>();
        Set<Id> defaultfieldPermissionProspectIdSet = new Set<Id>();
        String salesRepProfiles = label.EDGE_Rep_Profiles;
        Id userId = UserInfo.getUserId();
        Id profileId= Userinfo.getProfileId();
        String profileName=[SELECT Id,Name FROM Profile WHERE Id=:profileId].Name;
        Id managerID;
        managerID = [SELECT Id,ManagerId FROM User WHERE Id=: UserInfo.getUserId()].ManagerId;
        List<User_Business_Role__c> businessRoleId = [Select Id, Business_Role__c,User__c  from User_Business_Role__c  where User__c=:userId];
        EDGE_UtilityClass.printGovLimits(863);
        if(businessRoleId.size() >0){
            bRoleList = [Select Id, Field_Permission_Set_Outlet__c, Field_Permission_Set_Prospect__c, Country__c  from Business_Role__c where Id=:businessRoleId[0].Business_Role__c];
        } 
        EDGE_UtilityClass.printGovLimits(867);
        if(String.isNotBlank(salesRepProfiles)){
            salesRepList = salesRepProfiles.split(';');
            
        }
        
        // if(!EDGE_UtilityClass.stopTriggerToRun && profileName == 'Sales Representative' && bRoleList.size()>0){
        if(!EDGE_UtilityClass.stopTriggerToRun && salesRepList.contains(profileName) && bRoleList.size()>0){   
            mapDependentFields = new Map<String,List<String>>();
            mapParentFields = new Map<String,String>();
            
            for (Business_Role__c br:bRoleList){
                countryIdSet.add(br.Country__c);
                if(br.Field_Permission_Set_Outlet__c != null){
                    fieldPermissionOutletIdSet.add(br.Field_Permission_Set_Outlet__c);
                    fieldPermissionIdSet.add(br.Field_Permission_Set_Outlet__c);
                }
                if(br.Field_Permission_Set_Prospect__c != null){
                    fieldPermissionProspectIdSet.add(br.Field_Permission_Set_Prospect__c);
                    fieldPermissionIdSet.add(br.Field_Permission_Set_Prospect__c);    
                }
                
            }
            if(fieldPermissionOutletIdSet.size() == 0 || fieldPermissionProspectIdSet.size() == 0 ){ //|| fieldPermissionOtherIdSet.size() == 0){
                for(Field_Permission_Set__c fpsObj :[Select Id, Type__c, Market_Setting__r.Geography__c  from Field_Permission_Set__c
                                                     where  Market_Setting__r.Geography__c  IN :countryIdSet]){
                                                         if(fpsObj.Type__c == 'Default Outlet' && fieldPermissionOutletIdSet.size() == 0 ){
                                                             defaultfieldPermissionOutletIdSet.add(fpsObj.Id);
                                                             fieldPermissionIdSet.add(fpsObj.Id);
                                                         }
                                                         if(fpsObj.Type__c == 'Default Prospect' && fieldPermissionProspectIdSet.size() == 0){
                                                             defaultfieldPermissionProspectIdSet.add(fpsObj.Id);
                                                             fieldPermissionIdSet.add(fpsObj.Id);
                                                         }
                                                         
                                                     }    
            }
            for(Field_Permission__c  fieldPermission :[Select Id, Field__c,	Parent_Field_PL__c , Field_Permission_Set__c,Dependent_Fields__c, 
                                                       Permission__c, Related_Object__c, Unique_ID__c,Field_Permission_Set__r.Type__c  from 
                                                       Field_Permission__c where Field_Permission_Set__c IN :fieldPermissionIdSet
                                                       AND Related_Object__c = :sObjectName])
                
            {
                if(fieldPermission.Permission__c != null){  
                    if(fieldPermission.Related_Object__c  == 'Account' && (fieldPermissionOutletIdSet.contains(fieldPermission.Field_Permission_Set__c) || defaultfieldPermissionOutletIdSet.contains(fieldPermission.Field_Permission_Set__c))){
                        fieldPermissionOutletMap.put(fieldPermission.Field__c,fieldPermission);
                    }
                    if(fieldPermission.Related_Object__c  == 'Account' && (fieldPermissionProspectIdSet.contains(fieldPermission.Field_Permission_Set__c) || defaultfieldPermissionProspectIdSet.contains(fieldPermission.Field_Permission_Set__c))){
                        fieldPermissionProspectMap.put(fieldPermission.Field__c,fieldPermission);
                    }
                    if(fieldPermission.Related_Object__c  == 'Supplier_Outlet__c' || fieldPermission.Related_Object__c  == 'License__c' 
                       || fieldPermission.Related_Object__c  == 'Outlet_Buying_Group__c' || fieldPermission.Related_Object__c  == 'Outlet_Strategic_Fit__c'){// added Outlet_Strategic_Fit__c by 148622
                           fieldPermissionOtherMap.put(fieldPermission.Field__c,fieldPermission);
                       }
                    if(fieldPermission.Dependent_Fields__c != null){
                        List<String> tempList = new List<String>();
                        tempList = fieldPermission.Dependent_Fields__c.split(';');
                        mapDependentFields.put(fieldPermission.Field__c,tempList);
                        /*for(String dependentField :tempList){
mapParentFields.put(dependentField,fieldPermission.Field__c);
}*/
                    }
                    if(fieldPermission.Parent_Field_PL__c != null){ 
                        mapParentFields.put(fieldPermission.Field__c,fieldPermission.Parent_Field_PL__c ); 
                    }
                }
            }
        }
        if(mapParentFieldsReturned != null){
            if(mapParentFields != null){
                mapParentFieldsReturned.putAll(mapParentFields);
            }
            
        }
        if(mapDependentFieldsReturned != null){
            if(mapDependentFields != null){
                mapDependentFieldsReturned.putAll(mapDependentFields);
            }
        }
        
    } 
    
    /**
*@description : validateFieldsPerFS- This methods fetches configuration via populateFieldPermissionMaps and fires the validation through the method findErrorsByFS.-ES20-9212

*@return: void

*@param : EDGE_ValidationWrapper
*/
    public static void validateFieldsPerFS(EDGE_ValidationWrapper edgeValWrapper){
        
        Id outletRecordtypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        //List<Market_Setting__c> mrktSettingRecords = new List<Market_Setting__c>();
        //Map<String, Set<String>> validationTypeToFieldsMap = new Map<String, Set<String>>();
        Set<Id> countryIds = new Set<Id>();
        Id currProfileId = userinfo.getProfileId();
        //Map<String,String> metaDataReqdMap = new Map<String,String>();
        //Map<Id, Market_Setting__c> countryIdToMrkStngMap = new Map<Id, Market_Setting__c>();
        
        Map<Id, SObject> newItems = edgeValWrapper.newItems;
        //Map<Id, SObject> oldItems = edgeValWrapper.oldItems;
        //String relatedObject = edgeValWrapper.relatedObjectName; 
        Schema.DescribeSObjectResult sObjectDescReslt = edgeValWrapper.sObjectDescReslt; 
        Map<Id, Id> childRecIdToCountryIdMap = edgeValWrapper.childRecIdToCountryIdMap; 
        //Map<Id, Id> childRecIdToAccRecTypeIdMap = edgeValWrapper.childRecIdToAccRecTypeIdMap;
        
        //ES20-9212
        Map<String,Field_Permission__c> fieldPermissionOutletMap = new Map<String,Field_Permission__c>();
        Map<String,Field_Permission__c> fieldPermissionProspectMap = new Map<String,Field_Permission__c>();
        Map<String,Field_Permission__c> fieldPermissionOtherMap = new Map<String,Field_Permission__c>();
        Map<String,String> mapParentFieldsReturned = new Map<String,String>();
        Map<String,List<String>> mapDependentFieldsReturned = new Map<String,List<String>>();
        Map<String, String> fieldAPINameToLabelMap = new Map<String, String> ();
        Map<String, Schema.SObjectField> fieldsMap = new Map<String, Schema.SObjectField> ();
        
        if(currProfileId == getSRProfileId()){
            
            if(newItems.size() > 0){
                for(SObject sObj : newItems.values()){
                    
                    //SObject oldSObjRec;
                    Id accCountryId;
                    //Id parentAccRecId ;
                    
                    
                    if(sObjectDescReslt.getLabel() == 'Account'){
                        accCountryId = (Id)sObj.get('Country__c');
                    }else{
                        if(childRecIdToCountryIdMap != null){
                            accCountryId = childRecIdToCountryIdMap.get(sObj.Id);
                        }                        
                    }
                    countryIds.add(accCountryId);
                }
            }          
            
            edgeValWrapper.readOnlyErrorStr = readOnlyErrorStr;
            edgeValWrapper.mandatoryErrorStr = mandatoryErrorStr;
            edgeValWrapper.outletRecordtypeId = outletRecordtypeId;
            
            
            //ES20-9212
            populateFieldPermissionMaps(edgeValWrapper.relatedObjectName, fieldPermissionOutletMap, fieldPermissionProspectMap,
                                        fieldPermissionOtherMap, mapParentFieldsReturned, mapDependentFieldsReturned);
            
            
            edgeValWrapper.fieldPermissionOutletMap = fieldPermissionOutletMap;
            edgeValWrapper.fieldPermissionProspectMap = fieldPermissionProspectMap;
            edgeValWrapper.fieldPermissionOtherMap = fieldPermissionOtherMap;
            edgeValWrapper.mapParentFieldsReturned = mapParentFieldsReturned;
            edgeValWrapper.mapDependentFieldsReturned = mapDependentFieldsReturned;
            
            if(edgeValWrapper.sObjectDescReslt != null){
                fieldsMap = edgeValWrapper.sObjectDescReslt.fields.getMap();
                
                for(String key : fieldsMap.KeySet()){
                    fieldAPINameToLabelMap.put(key, fieldsMap.get(key).getDescribe().getLabel());
                }
                edgeValWrapper.fieldAPINameToLabelMap = fieldAPINameToLabelMap;
            }
            
            
            edgeValWrapper = findErrorsByFS(edgeValWrapper);
            
        }
    }
    
    /**
* @description :generateErrString- This method is used to create error string for read-only/hidden
and mandatory fields

* @return : String

* @param : String,List<String>

*/ 
    public static String generateErrString(String errorStr, List<String> errorFields){
        
        String lastSeparator = ' , ';
        errorStr += ' ';
        
        for(String fieldName : errorFields){
            errorStr +=  fieldName + lastSeparator;
        }
        if(errorStr != null && errorStr.lastIndexOf(lastSeparator) > 0){
            errorStr = errorStr.removeEndIgnoreCase(lastSeparator);
        }
        
        return errorStr;
    }
    
    /**
* @description : findErrorsByFS- This methods checks what field can be edited, which is read-only/hidden as per Field Set Configuration and throws error if any unwanted action is performed
* 
* @return : EDGE_ValidationWrapper
* 
* @param : EDGE_ValidationWrapper

*/
    public static EDGE_ValidationWrapper findErrorsByFS(EDGE_ValidationWrapper edgeValWrapper){
        
        Schema.DescribeSObjectResult sObjectDescReslt = edgeValWrapper.sObjectDescReslt;
        Map<Id, Id> childRecIdToCountryIdMap = edgeValWrapper.childRecIdToCountryIdMap; 
        Map<Id, Id> childRecIdToAccRecTypeIdMap = edgeValWrapper.childRecIdToAccRecTypeIdMap;
        
        for(SObject newSObjRec : edgeValWrapper.newItems.values()){
            SObject oldSObjRec;
            Id recordTypeId;
            Id accCountryId;
            List<String> readOnlyErrorFields = new List<String>();
            List<String> mandatoryErrorFields = new List<String>();
            //Account parentAccRec;
            
            if(edgeValWrapper.oldItems!= null && edgeValWrapper.oldItems.containsKey(newSObjRec.Id)){
                oldSObjRec = edgeValWrapper.oldItems.get(newSObjRec.Id);
            }
            
            if(sObjectDescReslt.getLabel() == 'Account'){
                accCountryId = (Id)newSObjRec.get('Country__c');
                recordTypeId = (Id)newSObjRec.get('RecordTypeId');
            }else{
                if(childRecIdToCountryIdMap != null){
                    accCountryId = childRecIdToCountryIdMap.get(newSObjRec.Id);
                    recordTypeId = childRecIdToAccRecTypeIdMap.get(newSObjRec.Id); 
                }                       
            }
            
            if(recordTypeId == edgeValWrapper.outletRecordtypeId && edgeValWrapper.fieldPermissionOutletMap != null){ //procee only for outlet record type
                
                Map<String,Field_Permission__c> fieldsToCheckMap = new Map<String,Field_Permission__c>();
                System.debug(LoggingLevel.DEBUG,'edgeValWrapper.relatedObjectName'+edgeValWrapper.relatedObjectName);       //146443 - added LoggingLevel.DEBUG
                if(edgeValWrapper.relatedObjectName == 'Account'){          //146443 - added braces
                    fieldsToCheckMap.putAll(edgeValWrapper.fieldPermissionOutletMap);
                }
                else{
                    fieldsToCheckMap.putAll(edgeValWrapper.fieldPermissionOtherMap);
                }
                
                for(String accFieldName : fieldsToCheckMap.keySet()){
                    String validationType;
                    if(fieldsToCheckMap != null){ //if(edgeValWrapper.fieldPermissionOutletMap != null){
                        Field_Permission__c fieldPermission = fieldsToCheckMap.get(accFieldName);
                        if(fieldPermission != null){
                            validationType = fieldPermission.Permission__c;
                            
                        }
                    }
                    
                    if(accFieldName != null && validationType != null){
                        String actualFldName = edgeValWrapper.fieldAPINameToLabelMap.get(accFieldName.toLowerCase()); //edgeValWrapper.metaDataToActualFieldName.get(msField);
                        //ES20-11063
                        if(validationType.equalsIgnoreCase('Read Only') || validationType.equalsIgnoreCase('Hidden/ Disabled')){
                            system.debug('@@oldSObjRec'+oldSObjRec+' '+newSObjRec.get(accFieldName)+' '+oldSObjRec.get(accFieldName));
                            system.debug('@@newSObjRec'+oldSObjRec);
                            system.debug('@@oldSObjRec'+newSObjRec);
                            system.debug('@@accFieldName'+accFieldName);
                            if(oldSObjRec != null && ((newSObjRec.get(accFieldName) != oldSObjRec.get(accFieldName))|| 
                                                      
                                                      
                                                      //ES20-12516
                                                      //((oldSObjRec.get('BillingStateCode')!=newSObjRec.get('BillingStateCode')) && accFieldName.contains('BillingState'))||//ES20-12516
                                                      //((oldSObjRec.get('ShippingStateCode')!=newSObjRec.get('ShippingStateCode')) && accFieldName.contains('ShippingState'))||////ES20-12516                          
                                                      ((newSObjRec.id.getSObjectType().getDescribe().getName() == 'Account') && (oldSObjRec.get('BillingCountryCode')!=newSObjRec.get('BillingCountryCode')) && accFieldName.contains('BillingCountry'))||////ES20-12516
                                                      ((newSObjRec.id.getSObjectType().getDescribe().getName() == 'Account') && (oldSObjRec.get('ShippingCountryCode')!=newSObjRec.get('ShippingCountryCode')) && accFieldName.contains('ShippingCountry'))))////ES20-12516 //148622 - added Account Sobject Check
                            {
                                
                                
                                
                                
                                if(actualFldName != null){
                                    readOnlyErrorFields.add(actualFldName); //accFieldName
                                    //System.debug('readOnlyErrorFields'+readOnlyErrorFields);
                                    
                                    if(edgeValWrapper.mapDependentFieldsReturned != null){ //dependentFldStr != null){
                                        
                                        List<String> dependentFlds = edgeValWrapper.mapDependentFieldsReturned.get(accFieldName); 
                                        if(dependentFlds != null && dependentFlds.size() > 0){
                                            
                                            for(String dependentFld : dependentFlds){
                                                
                                                if(newSObjRec.get(dependentFld) != oldSObjRec.get(dependentFld)){
                                                    String actualDpndtFldName = edgeValWrapper.fieldAPINameToLabelMap.get(dependentFld.toLowerCase());
                                                    readOnlyErrorFields.add(actualDpndtFldName);
                                                }
                                            }
                                        } 
                                    }
                                } 
                            }
                        }
                        if(validationType.containsIgnoreCase('Editable & Mandatory')){//equalsIgnoreCase('Editable & Mandatory')
                            if( //((newSObjRec.get('ShippingStateCode')==null) && accFieldName.equals('ShippingState'))||//ES20-12516
                                /*((newSObjRec.get('BillingStateCode')==null) && accFieldName.contains('BillingState'))||*/(newSObjRec.get(accFieldName) == null && (oldSObjRec != null && newSObjRec.get(accFieldName) != oldSObjRec.get(accFieldName)))){ //ES20-12516
                                    if(actualFldName != null){//ES20-12516
                                        mandatoryErrorFields.add(actualFldName); //ES20-12516  
                                    }/*else if(newSObjRec.get('ShippingStateCode')==null){//ES20-12516
                                    mandatoryErrorFields.add('ShippingState');//ES20-12516
                                    }else if(newSObjRec.get('BillingStateCode')==null){//ES20-12516
                                    mandatoryErrorFields.add('BillingState');//ES20-12516
                                    }*/
                                    if(edgeValWrapper.mapDependentFieldsReturned != null){ //dependentFldStr != null){
                                        List<String> dependentFlds = edgeValWrapper.mapDependentFieldsReturned.get(accFieldName); //List<String> dependentFlds = dependentFldStr.split(';');
                                        if(dependentFlds != null && dependentFlds.size() > 0){
                                            for(String dependentFld : dependentFlds){
                                                if(newSObjRec.get(dependentFld) != oldSObjRec.get(dependentFld)){
                                                    String actualDpndtFldName = edgeValWrapper.fieldAPINameToLabelMap.get(dependentFld);
                                                    mandatoryErrorFields.add(actualDpndtFldName);
                                                }
                                            }
                                        } 
                                    }
                                }
                        }
                    }
                    //}   
                }
                if(!readOnlyErrorFields.isEmpty()){
                    edgeValWrapper.readOnlyErrorStr = EDGE_UtilityClass.generateErrString(edgeValWrapper.readOnlyErrorStr, 
                                                                                          readOnlyErrorFields);
                    
                }
                if(!mandatoryErrorFields.isEmpty()){
                    edgeValWrapper.mandatoryErrorStr = EDGE_UtilityClass.generateErrString(edgeValWrapper.mandatoryErrorStr, 
                                                                                           mandatoryErrorFields);                  
                    
                }
                
                if(!Test.isRunningTest()){
                    if(!readOnlyErrorFields.isEmpty() && !mandatoryErrorFields.isEmpty()){
                        newSObjRec.addError(edgeValWrapper.readOnlyErrorStr + ' . ' + edgeValWrapper.mandatoryErrorStr);
                    }
                    if(!readOnlyErrorFields.isEmpty() && mandatoryErrorFields.isEmpty()){
                        
                        newSObjRec.addError(edgeValWrapper.readOnlyErrorStr);
                    }
                    if(readOnlyErrorFields.isEmpty() && !mandatoryErrorFields.isEmpty()){
                        newSObjRec.addError(edgeValWrapper.mandatoryErrorStr);
                    }
                }
            }
        }//end of Account iteration loop
        
        return edgeValWrapper;
    }
    
    /**
*@description : getSRProfileId- This methods returns the profile name of the user in context 

*@return :Id

*/
    private static Id getSRProfileId(){
        
        List<Profile> profileNames = new List<Profile>();
        
        if(salresRepProfId == null){
            profileNames = [Select Id,Name from Profile where Name = 'Sales Representative' LIMIT 1];
            if(!profileNames.isEmpty()){
                salresRepProfId = profileNames[0].Id;   
            }  
        }
        
        return salresRepProfId;
    }
    
    /**
*@description : getCurrentUserProfileId - This methods returns the profile name of the user in context 

*@return : Profile

*/
    public static Profile getCurrentUserProfileId(){
        
        List<Profile> profileNames = new List<Profile>();
        Profile profileRecord;
        
        Id profileId=userinfo.getProfileId();
        
        if(profileRecord == null){
            profileNames = [Select Id,Name from Profile where Id = :profileId LIMIT 1];
            if(!profileNames.isEmpty()){
                profileRecord = profileNames[0];   
            }  
        }
        
        return profileRecord;
    }
    
    public static String getMailBodyForMDM(List<Contact> contList,Map<Id,Id> contactWithActiveComm){
        String htmlBody='';//to store html body of email
        String fullRecordURL = URL.getSalesforceBaseUrl().toExternalForm()+'/';//retrieve org's base URL
        htmlBody+= '<table style="border:1px solid balck;">';
        htmlBody+='<tr>';//preparing table heading
        htmlBody+= '<td style="border:1px solid black;">Account Name</td>';
        htmlBody+= '<td style="border:1px solid black;">Contact Name</td>';
        htmlBody+= '<td style="border:1px solid black;">Contact URL</td>';
        htmlBody+= '<td style="border:1px solid black;">User Id</td>';
        htmlBody+='</tr>';
        for(Contact cont : contList){ //preparing table data
            htmlBody+= '<tr>';
            htmlBody+= '<td style="border:1px solid black;">'+cont.Account.Name+'</td>';
            htmlBody+= '<td style="border:1px solid black;">'+cont.Name+'</td>';
            htmlBody+= '<td style="border:1px solid black;">'+fullRecordURL+cont.Id+'</td>';
            htmlBody+= '<td style="border:1px solid black;">'+contactWithActiveComm.get(cont.Id)+'</td>';
            htmlBody+='</tr>';
        }
        htmlBody+= '</table>';
        return htmlBody;
    }
    
    public static void printGovLimits(Integer lineNumber){
        if(lineNumber != null){
            System.debug(LoggingLevel.DEBUG,'***getCpuTime() > Line Number '+ lineNumber  + ' : ' + System.now() + ' = ' + Limits.getCpuTime());
            System.debug(LoggingLevel.DEBUG,'***getQueryRows() > Line Number '+ lineNumber  + ' : ' + System.now() + ' = ' + Limits.getQueryRows());
            System.debug(LoggingLevel.DEBUG,'***getDMLRows()() > Line Number '+ lineNumber  + ' : ' + System.now() + ' = ' + Limits.getDMLRows());
            System.debug(LoggingLevel.DEBUG,'***getQueries()() > Line Number '+ lineNumber  + ' : ' + System.now() + ' = ' + Limits.getQueries());
            
        }else{
            System.debug(LoggingLevel.DEBUG,'***getCpuTime() > '+ System.now() + ' = ' + Limits.getCpuTime());
            System.debug(LoggingLevel.DEBUG,'***getQueryRows() > '+ System.now() + ' = ' + Limits.getQueryRows());
            System.debug(LoggingLevel.DEBUG,'***getDMLRows()() > '+ System.now() + ' = ' + Limits.getDMLRows());
            System.debug(LoggingLevel.DEBUG,'***getQueries()() > '+ System.now() + ' = ' + Limits.getQueries());
        }       
    }
    
}