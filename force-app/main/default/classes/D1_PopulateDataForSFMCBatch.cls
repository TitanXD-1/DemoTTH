/**
 * @name D1_SFMCDataPopulationBatch
 * @purpose Batch Class for data population for SFMC
 * @history                                                                                                                       
 * VERSION      AUTHOR             DATE              DETAIL
 * 1.0          Pratap Sen        05-04-2023        NCP-8164
 * 2.0          Saikiran          17-05-2023        CUS-292
 * 3.0			Naresh			  02-06-2023		NCP-8285
**/
@SuppressWarnings('PMD.cognitivecomplexity,PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity')
public class D1_PopulateDataForSFMCBatch implements Database.Batchable<sObject>, Database.Stateful, BatchJobManagementInterfaceClass{
    /*Batch Class Variables*/
    String exceptionMsg = '';
    Boolean hasError = false ;
    Market_Batch_Setting__mdt batchSetting;
    Id marketBatchJobId;
    String recTypeToExclude = 'Distributor/Wholesaler';

    /*Batch Class Variables - updated on each Batch run*/
    static Map<Id,Account> soldToAccounts;
    static Map<Id, List<Order_Delivery_Date__c>> orderDeliveryDateMap;
    static Map<String, Integer> transitDurationMap;
    
    /**
	* @description : getBatchDetails - from BatchJobManagementInterfaceClass
	* @return : void
	* @param : Market_Batch_Setting__mdt
	*/
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    } 

    /**
	* @description : start - start method for the Batch
	* @return : List<contract> 
	* @param : Database.BatchableContext
	*/
    public Database.QueryLocator start(Database.BatchableContext bc){
        String queryString;    
        String countryCode = batchSetting.Country_Code__c;
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); 
         // CUS-292: Removed not equal to null checks for D1_Registration_Status__c, D1_Account_Last_Login_Date__c in start query.
        //Query All D1 Registered Ship-To Accounts excluding the Distributor/Wholesaler Types
        if(countryCode != ''){      
            queryString = 'SELECT Id, D1_Keg_Cut_off_time__c, D1_Non_Keg_Cut_off_time__c, D1_Keg_Next_Delivery_date__c, D1_Non_keg_Next_Delivery_Date__c, '
                                +'Delivery_Plant__c, Delivery_Pattern__c, Salesforce_Delivery_Days_Keg__c, Salesforce_Delivery_Days_Packaged_Good__c, '
                                +'D1_Registration_Status__c, D1_Account_Last_Login_Date__c'
                                +' FROM Account WHERE country__r.Code__c =: countryCode AND '
                                +'Account_Type__c INCLUDES (\'Ship-To\') AND '
                                +'RecordType.Name !=: recTypeToExclude';
        }
        return Database.getQueryLocator(queryString);                        
    }
    
    /**
	* @description : execute - execute method for the Batch
	* @return : void
	* @param : Database.BatchableContext, List<Account> 
	*/
    public void execute(Database.BatchableContext bc, list<Account> accList){
        try{
            Map<Id,Account> accMap = new Map<Id,Account>(accList);
            
            Map<Id,Id> salesAreasForAccount = new Map<Id,Id>();                     //Key : Account Id,  Value : Sales Area Id to which the Account belongs 
            Map<Id,Id> shipToSoldToMap = new Map<Id,Id>();                          //Key : Customer No Account Id of Partner Func, Value : Sold to Account Id of Partner Func
            Map<Id,OrderSplit__c> kegOrdSplits = new Map<Id,OrderSplit__c>();       //Key : SalesArea Id, Value : KEG Order Split Id of the Sales Area
            Map<Id,OrderSplit__c> nonKegOrdSplits = new Map<Id,OrderSplit__c>();    //Key : SalesArea Id, Value : NON-KEG Order Split Id of the Sales Area
              
            Set<Id> salesAreaSet = new Set<Id>();                                   //Set of Sales Area Ids
            Set<Id> oSplitIdSet = new Set<Id>();                                    //Set of Order Split Ids
            List<Account> accToUpdate = new List<Account>();                        //List of Account Records to Update 

            //Query Partner Functions to Map Sales Area against Account Ids 
            for(PNR_Partner_Function__c pF : [SELECT Sales_Area__c, PNR_Sold_To__c, PNR_Customer_No__c FROM PNR_Partner_Function__c
                                              WHERE PNR_Type__c = 'Ship-To' 
                                              AND PNR_Customer_No__c IN: accMap.keySet() 
                                              AND IsInvalid__c = false
                                              AND Sales_Area__c != NULL 
                                              AND PNR_Sold_To__c != NULL
                                              AND PNR_Customer_No__r.KUNNR__c != NULL])
            {
                salesAreasForAccount.put(pF.PNR_Customer_No__c, pF.Sales_Area__c);
                salesAreaSet.add(pF.Sales_Area__c);

                //If Sold-To Ship-To Account are not same then Map Sold To against Ship-To
                if(pF.PNR_Customer_No__c != pF.PNR_Sold_To__c){
                    shipToSoldToMap.put(pF.PNR_Customer_No__c, pF.PNR_Sold_To__c);
                }
            }
			
            //Map Keg and Non-Keg Type OrderSplits against SalesAreas separately
            for(OrderSplit__c oSplit : [SELECT Id, Sales_Area__c, Delivery_Day_Series__c, Delivery_day_holiday_shift_ripple__c, Market_Description__c,
                                        Is_lead_time_in_business_days__c, Lead_Time_in_day__c, Max_future_order_days__c, isKeg__c, Cut_Off_Time__c, Use_Plant_Exception_Calendar__c
                                        FROM OrderSplit__c
                                        WHERE Sales_Area__c IN: salesAreaSet])
            {
                oSplitIdSet.add(oSplit.Id);
                if(oSplit.isKeg__c){
                    kegOrdSplits.put(oSplit.Sales_Area__c, oSplit);
                }
                else{
                    nonKegOrdSplits.put(oSplit.Sales_Area__c, oSplit);
                }
            }
            //Query related items to calculate delivery date
            soldToAccounts = getSoldToAccounts(shipToSoldToMap.values());
            orderDeliveryDateMap = getOrdrDeliveryDateMap(oSplitIdSet);
            transitDurationMap = getTransitDurMap(oSplitIdSet, shipToSoldToMap.keySet());

            //Iterate over Accounts and add the Cut off Time & Next Delivery Dates
            Account accRec;
            Id salesAreaId;
            OrderSplit__c kegOS;
            OrderSplit__c nonKegOS;
            for(Id accId : salesAreasForAccount.keySet()){
                accRec = new Account(Id = accId);
                salesAreaId = salesAreasForAccount.get(accId);
                kegOS = kegOrdSplits.containsKey(salesAreaId) ? kegOrdSplits.get(salesAreaId) : NULL;
                nonKegOS = nonKegOrdSplits.containsKey(salesAreaId) ? nonKegOrdSplits.get(salesAreaId) : NULL;
               
                if (kegOS != null) {
                    Map<Date, DateTime> tempMap = getNextDeliveryDate(accMap.get(accId), kegOS);     //NCP-8285
                    if (!tempMap.isEmpty()) {
                        List<DateTime> valuesList = new List<DateTime>(tempMap.values());
                        List<Date> keysList = new List<Date>(tempMap.keySet());                        
                        accRec.D1_Keg_Cut_off_time__c = valuesList[0];
                        accRec.D1_Keg_Next_Delivery_date__c = keysList[0];
                    }
                }
                
                if(nonKegOS != NULL){
                    Map<Date, DateTime> tempMap1= getNextDeliveryDate(accMap.get(accId), nonKegOS);     //NCP-8285
                    if(!tempMap1.isEmpty()){
                        List<DateTime> valuesList1 = new List<DateTime>(tempMap1.values());
                        List<Date> keysList1 = new List<Date>(tempMap1.keySet()); 
                        accRec.D1_Non_Keg_Cut_off_time__c = valuesList1[0];
                        accRec.D1_Non_keg_Next_Delivery_Date__c = keysList1[0];
                    }
                }

                accToUpdate.add(accRec);
            }

            soldToAccounts.clear();
            orderDeliveryDateMap.clear();
            transitDurationMap.clear();

            if(!accToUpdate.isEmpty()){
                Database.update(accToUpdate);
            }
        }
        catch(Exception ex){
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
    }

    /**
    * @description : returns the next KEG/NonKEG Delivery Date
    * @return : Date
    * @param : Id - Account Id, OrderSplit__c - order Split Record, Account - Account Record
    */
    public static Map<Date, DateTime> getNextDeliveryDate(Account shipToAccount, OrderSplit__c oSplit){
        map<Date, DateTime> nextDeliveryDateTime = new map<Date, DateTime>();
        Date nextDeliveryDate;
        DateTime nextAvailableCutoffTime;
        //Delivery Date limitations
        Integer daySrs = oSplit.Delivery_Day_Series__c != NULL ? Integer.valueOf(oSplit.Delivery_Day_Series__c) : 0;
        Date endDate = DateTime.now().date().addDays(oSplit.Max_future_order_days__c != NULL ? Integer.valueOf(oSplit.Max_future_order_days__c) : 0);

        //Check which Account to consider for Delivery data
        Account accWithDeliveryInfo = getAccountForDeliveryData(shipToAccount, daySrs);

        //Delivery Plant Information
        Boolean isPlantException = oSplit.Use_Plant_Exception_Calendar__c;
		String deliveryPlant = accWithDeliveryInfo.Delivery_Plant__c;

        //Transit Duration if Ship To is Used for Delivery Data
        Integer transitDuration = 0;
        if(shipToAccount.Id == accWithDeliveryInfo.Id && transitDurationMap.containsKey(shipToAccount.Id + '_' + oSplit.Id)){
            transitDuration = transitDurationMap.get(shipToAccount.Id + '_' + oSplit.Id);
        }

        //Available days of week for delivery
        Set<Integer> kegDeliveryDays = D1_OrderdeliverdatesCntrl.createDayPatternSet(accWithDeliveryInfo.Salesforce_Delivery_Days_Keg__c);
        Integer deliveryPattern = String.isNotBlank(accWithDeliveryInfo.Delivery_Pattern__c) ? Integer.valueOf(accWithDeliveryInfo.Delivery_Pattern__c) : 0;
        Set<Integer> packagedGoodDeliveryDays = D1_OrderdeliverdatesCntrl.createDayPatternSet(accWithDeliveryInfo.Salesforce_Delivery_Days_Packaged_Good__c);
        
        //Get List of Delivery Date records from Order Split
        List<Order_Delivery_Date__c> allDeliveryDate = orderDeliveryDateMap.containsKey(oSplit.Id) ? orderDeliveryDateMap.get(oSplit.Id) : new List<Order_Delivery_Date__c>();
        //Get Next Delivery Date
        for(Order_Delivery_Date__c ordrDate : allDeliveryDate){
            Date nextAvailbleDate;
            if(ordrDate.Substitue_Delivery_Date__c <= endDate){
                //Check if current record meets the Delivery day of week for KEG/Non-KEG
                if(oSplit.isKeg__c){
                    nextAvailbleDate = isDayValidForKEG(ordrDate, kegDeliveryDays, deliveryPattern, daySrs) ? ordrDate.Substitue_Delivery_Date__c : NULL;
                	
                }
                else{
                    nextAvailbleDate = isDayValidForNONKEG(ordrDate, packagedGoodDeliveryDays, daySrs) ? ordrDate.Substitue_Delivery_Date__c : NULL;
                
                }
                
                //If current record passes above conditions then check if it meets plant exceptions
                if (nextAvailbleDate != NULL && isPlantException && String.isNotBlank(deliveryPlant) && String.isNotBlank(ordrDate.Delivery_Date_ID__c)) {
                    nextAvailbleDate = (ordrDate.Delivery_Date_ID__c.endsWithIgnoreCase(deliveryPlant)) ? ordrDate.Substitue_Delivery_Date__c : NULL;
                
                }

                //If current record passes above conditions then skip it for the transition period 
                if(transitDuration > 0 && nextAvailbleDate != NULL){
                    transitDuration = transitDuration - 1;
                }
            }
            //If current record passes all validations and transit count is also 0 then return it
            if(transitDuration == 0 && nextAvailbleDate != NULL){
                nextDeliveryDate = nextAvailbleDate;
                nextAvailableCutoffTime = ordrDate.Cutoff_datetime__c;     //NCP-8285
                break;
            }	
        }
        if(nextDeliveryDate!= null && nextAvailableCutoffTime!= null){
            nextDeliveryDateTime.put(nextDeliveryDate,nextAvailableCutoffTime);     //NCP-8285
            }
        return nextDeliveryDateTime;
        
    }

    /**
    * @description : Check if given Order Date is valid for KEG Delivery
    * @return : Boolean
    * @param : orderDate - Order Delivery Date record, Set<Integer> - Keg Days of Account, Integer - Delivery Pattern of Account, Integer - Day Series of Order Split
    */
    public static Boolean isDayValidForKEG(Order_Delivery_Date__c oDate, Set<Integer> kegDays, Integer dlvrPattern, Integer daySeries){
        if(daySeries != 1){
            return true;
        }

        Boolean isValid = true;
        if(kegDays.size() > 0){
            isValid = oDate.Day_of_week__c != NULL && kegDays.contains(Integer.valueOf(oDate.Day_of_week__c));
        }
        if(isValid && dlvrPattern != 0){
            isValid = oDate.Delivery_Week_Pattern__c != NULL && oDate.Delivery_Week_Pattern__c == dlvrPattern;
        }
        return isValid;
    }

    /**
    * @description : Check if given Order Date is valid for NON-KEG Delivery
    * @return : Boolean
    * @param : orderDate - Order Delivery Date record, Set<Integer> - NonKeg Days of Account, Integer - Day Series of Order Split
    */
    public static Boolean isDayValidForNONKEG(Order_Delivery_Date__c oDate, Set<Integer> nonKegDays, Integer daySeries){
        if(daySeries != 2){
            return true;
        }

        if(nonKegDays.size() > 0){
            return  (oDate.Day_of_week__c != NULL && nonKegDays.contains(Integer.valueOf(oDate.Day_of_week__c)));
        }
        return true;
    }

    /**
    * @description : To calculate Delivery date, check which Account to consider - Sold To or Ship To
    * @return : Account
    * @param : Account - Ship To Account Record, Integer - Order Split Delivery_Day_Series__c value
    */
    public static Account getAccountForDeliveryData(Account shipTo, Integer daySeries){
        if(!soldToAccounts.containsKey(shipTo.Id)
            || (daySeries == 1 && !String.isEmpty(shipTo.Salesforce_Delivery_Days_Keg__c))
            || (daySeries == 2 && !String.isEmpty(shipTo.Salesforce_Delivery_Days_Packaged_Good__c)))
        {
            return shipTo;
        }
        return soldToAccounts.get(shipTo.Id);
    }

    /**
    * @description : List 'Sold To' field accounts of Partner Functions are passed as param and returns Map of those Accounts
    * @return : Map<Id,Account>
    * @param : List<Id>
    */
    public static Map<Id,Account> getSoldToAccounts(List<Id> accId){
        List<Account> accData = new List<Account>();
        accData = [SELECT Id, Delivery_Plant__c, Delivery_Pattern__c, Salesforce_Delivery_Days_Keg__c, Salesforce_Delivery_Days_Packaged_Good__c FROM Account WHERE Id IN: accID];
        return new Map<Id,Account>(accData);
    }

    /**
    * @description : Creates a Map of Order Split Id and List of Order Delivery Date records associated with the Order Split 
    * @return : Map<Id, List<Order_Delivery_Date__c>>
    * @param : Set<Id>
    */
    public static Map<Id, List<Order_Delivery_Date__c>> getOrdrDeliveryDateMap(Set<Id> ordrSplitIdSet){
        Map<Id, List<Order_Delivery_Date__c>> deliveryMap = new Map<Id, List<Order_Delivery_Date__c>>();
        DateTime startDate = DateTime.now();
        for(Order_Delivery_Date__c ordrDlvry : [SELECT Id, Delivery_Date__c,Day_of_week__c, Delivery_Date_ID__c,Substitue_Delivery_Date__c,
                                                Order_Split_ID__c, Order_Split_ID__r.Market_Description__c, Cutoff_datetime__c, Delivery_Week_Pattern__c
                                                FROM Order_Delivery_Date__c
                                                WHERE Order_Split_ID__c IN: ordrSplitIdSet AND Is_Delivery__c = true
                                                AND Cutoff_datetime__c >=: startDate
                                                ORDER BY Substitue_Delivery_Date__c ASC, Delivery_Date_ID__c])
        {
            if(deliveryMap.containsKey(ordrDlvry.Order_Split_ID__c)){
                deliveryMap.get(ordrDlvry.Order_Split_ID__c).add(ordrDlvry);
            }
            else{
                deliveryMap.put(ordrDlvry.Order_Split_ID__c, new List<Order_Delivery_Date__c>{ordrDlvry});
            }
        }
        return deliveryMap;
    }

    /**
    * @description : Creates a Map with Order Split & account Id as key and the Transit day of associated Outlet split Transit Duration record
    * @return : Map<String, String>
    * @param : Set<Id> - Set of Order Split Ids , List<Id> - List of Account Ids
    */
    public static Map<String, Integer> getTransitDurMap(Set<Id> ordrSplitId, Set<Id> shipToAccId){
        Map<String, Integer> outletSplitTrnsit = new Map<String, Integer>();
        for(Outlet_Split_Transit_Duration__c outletTrnsit : [SELECT Outlet_ID__c,  Order_Split_ID__c, Transit_Days__c FROM Outlet_Split_Transit_Duration__c 
                                                             WHERE Outlet_ID__c IN: shipToAccId AND Order_Split_ID__c IN: ordrSplitId])
        {
            outletSplitTrnsit.put(outletTrnsit.Outlet_ID__c + '_' + outletTrnsit.Order_Split_ID__c, (outletTrnsit.Transit_Days__c != NULL) ? Integer.valueOf(outletTrnsit.Transit_Days__c) : 0);
        }
        return outletSplitTrnsit;
    }

    /**
    * @description : finish - Finish method for the Batch
    * @return : void
    * @param : Database.BatchableContext - Batchable Context
    */
    public void finish(Database.BatchableContext bc){
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId); //Get Batch Job
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){ //Check whether Batch Job has been updated by Batch Platform Event or Not
            hasError = true;
        }
        if(hasError){ //Update Batch Job Status
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'D1_PopulateDataForSFMCBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError); //Schedule Next Batch from Batch Utility Class     
        }
    }
}