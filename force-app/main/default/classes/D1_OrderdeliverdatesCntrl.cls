/**
 * @name: D1_OrderdeliverdatesCntrl
 * @description : This class is controller class to get Delivery Dates
 * @history                                                        
 * VERSION		AUTHOR				DATE			DETAIL
 * 1.0			Sai Kumar			28/01/2021		NCP-1574
 * 2.0			Manikant			09/03/2021		NCP-2360
 * 3.0			Sai Kumar			20/04/2021		NCP-2522
 * 4.0			Kapil Baliyan		18/04/2022		NCP-6437 (getTransitDuration)
 * 5.0			Kapil Baliyan		28/11/2022		NCP-7709
 * 6.0			Kapil Baliyan		20/05/2024		154003
 **/

public without sharing class D1_OrderdeliverdatesCntrl {


	/**
	* @description Method to get Order Split Details    
	* @param accountId 
	* @return `List < OrderSplitDetailsWrap >`
	*/	
	@AuraEnabled(cacheable = false) 
	public static List < OrderSplitDetailsWrap > getOrdersplits(string accountId) {
		List < OrderSplitDetailsWrap > orderSplitDetailsWrapList = new List < OrderSplitDetailsWrap > ();
		//Get Order Split Details
		if (String.isNotBlank(accountId)) {
			for (OrderSplit__c orderSplit: [SELECT Id, Name, Sales_Area__c, Market_Description__c, Description__c 
											FROM OrderSplit__c WHERE Sales_Area__c IN
											(SELECT Sales_Area__c FROM 
											PNR_Partner_Function__c WHERE PNR_Sold_To__c = : accountId 
											AND PNR_Type__c = 'Sold-To') ORDER BY Market_Description__c, Description__c]) 
			{
				OrderSplitDetailsWrap orderSplitDetails = new OrderSplitDetailsWrap();
				orderSplitDetails.orderSplitId = orderSplit.Id;
				orderSplitDetails.orderSplitName = orderSplit.Market_Description__c != null ? orderSplit.Market_Description__c : orderSplit.Description__c;
				orderSplitDetailsWrapList.add(orderSplitDetails);
			}
		}
		return orderSplitDetailsWrapList;
	}

	/**
	 * @description 
	* @param orderSplitId 
	* @param accId 
	* @param ShipToNumber 
	* @return  `date`
	*/	
	@AuraEnabled
	public static date getnextDeliveryDates(Id orderSplitId, Id accId, String shipToNumber) {
		Date nextavailableDate;
		List < DeliveryDatesWrapper > deliveryDatesWrapperList = getDeliveryDates(orderSplitId, accId, shipToNumber);
		if (deliveryDatesWrapperList != null && deliveryDatesWrapperList.size() > 0) {
			DeliveryDatesWrapper deliveryDatesWrapper = deliveryDatesWrapperList[0];
			//Get First Available Date and return it back to LWC
			if (deliveryDatesWrapper.deliveryDates != null && deliveryDatesWrapper.deliveryDates.size() > 0) {
				List < Date > availableDatesList = deliveryDatesWrapper.deliveryDates;
				nextavailableDate = availableDatesList[0];
			}
		}
		return nextavailableDate;
	}
	/**
	 * @description Method to Get Available Delivery Dates Calendar
	* @param orderSplitId 
	* @param accId 
	* @param ShipToNumber 
	* @return  `List < DeliveryDatesWrapper >`
	*/		
	@AuraEnabled 
	public static List < DeliveryDatesWrapper > getDeliveryDates(Id orderSplitId, Id accId, String shipToNumber) {
		Map < String, DeliveryDatesWrapper > availableDeliveryDatesMap = new Map < String, DeliveryDatesWrapper > ();
		//Get Order Split Data
		OrderSplit__c orderSplit = [SELECT Id,Delivery_Day_Series__c,Delivery_day_holiday_shift_ripple__c,Market_Description__c,
									Is_lead_time_in_business_days__c,Lead_Time_in_day__c,Max_future_order_days__c,Cut_Off_Time__c,
									Use_Plant_Exception_Calendar__c FROM OrderSplit__c WHERE Id = : orderSplitId LIMIT 1
									];
		Integer deliveryDaySeries = orderSplit.Delivery_Day_Series__c != NULL ? Integer.valueOf(orderSplit.Delivery_Day_Series__c) : 0;
		//KB: Fix this
		//Get Account Data
		list < Account > accRec = new list < Account > ();
		Account acc = new Account();
		/**Emergency Fix - 154003*/
		/**If Ship To Number is blank, fetch it again from BE */
		if(String.isBlank(shipToNumber)){
			B2BUtils.GenericCartWrapper gcw = B2BUtils.getCartId(UserInfo.getUserId(), accId);
			if(gcw != null){
				shipToNumber = gcw.shipToNumber;
			}
		}
		if (shipToNumber != null) {
			accRec = [SELECT Id,Delivery_Plant__c,Delivery_Pattern__c,Salesforce_Delivery_Days_Keg__c,
					Salesforce_Delivery_Days_Packaged_Good__c FROM Account WHERE KUNNR__c = : shipToNumber LIMIT 1
					];
		}
		if (accRec.size() > 0 && accRec[0] != null) {
			if (deliveryDaySeries == 1 && !String.isEmpty(accRec[0].Salesforce_Delivery_Days_Keg__c)) {
				acc = accRec[0];
			}
			if (deliveryDaySeries == 2 && !String.isEmpty(accRec[0].Salesforce_Delivery_Days_Packaged_Good__c)) {
				acc = accRec[0];
			}
		}
		if (acc.id == null) {
			acc = [SELECT Id,Delivery_Plant__c,Delivery_Pattern__c,Salesforce_Delivery_Days_Keg__c,
					Salesforce_Delivery_Days_Packaged_Good__c FROM Account WHERE Id = : accId LIMIT 1];
		}
		Set < Integer > kegDeliveryDay = createDayPatternSet(acc.Salesforce_Delivery_Days_Keg__c);
		Set < Integer > packagedGoodDeliveryDay = createDayPatternSet(acc.Salesforce_Delivery_Days_Packaged_Good__c);
		Integer deliveryPattern = String.isNotBlank(acc.Delivery_Pattern__c) ? Integer.valueOf(acc.Delivery_Pattern__c) : 0;
		Integer maxFutureDays = orderSplit.Max_future_order_days__c != NULL ? Integer.valueOf(orderSplit.Max_future_order_days__c) : 0;
		Boolean isPlantException = orderSplit.Use_Plant_Exception_Calendar__c;
		String deliveryPlant = acc.Delivery_Plant__c;
		DateTime startDate = DateTime.now();
		Date endDate = startDate.date().addDays(maxFutureDays);//NOPMD
		List<Outlet_Split_Transit_Duration__c> transitDurationList = accRec.size()>0 ? getTransitDuration(accRec.get(0).Id, orderSplitId) : null; //NCP-6437

        Integer transitDuration = (transitDurationList!=null && transitDurationList.size()>0) ? Integer.valueOf(transitDurationList.get(0).Transit_Days__c) : 0; //NCP-6437            	

		//Query String
		String queryStr = 'SELECT Id, Delivery_Date__c,Day_of_week__c, Delivery_Date_ID__c,Substitue_Delivery_Date__c,Order_Split_ID__r.Market_Description__c,Cutoff_datetime__c FROM Order_Delivery_Date__c'+
							+' WHERE Order_Split_ID__c =:orderSplitId AND Is_Delivery__c = true'+
							+' AND Cutoff_datetime__c >=:startDate AND Substitue_Delivery_Date__c <=:endDate';
		
		//Check for KEG Delivery Date
		if (deliveryDaySeries == 1) {
			if(kegDeliveryDay != null && kegDeliveryDay.size()>0){
				queryStr += ' AND Day_of_week__c IN :kegDeliveryDay';
			}
			if (deliveryPattern != 0) {
				queryStr += ' AND Delivery_Week_Pattern__c =:deliveryPattern';
			}
		}
		//Check for Non-KEG Delivery Date
		else if (deliveryDaySeries == 2) {
			if(packagedGoodDeliveryDay != null && packagedGoodDeliveryDay.size()>0){
				queryStr += ' AND Day_of_week__c IN :packagedGoodDeliveryDay';
			}
		}
		queryStr += ' ORDER BY Substitue_Delivery_Date__c ASC, Delivery_Date_ID__c';
		//Get Order Delivery dates
		for (Order_Delivery_Date__c orderDeliveryDate: Database.Query(queryStr)) {
            
			Date availableDate;
			Datetime cutOffDatetime;
			//Check Whether Plant Exception Calendar is enabled or not and based on that check Plant Calendar Dates instead of normal dates
			if (isPlantException && String.isNotBlank(deliveryPlant) && String.isNotBlank(orderDeliveryDate.Delivery_Date_ID__c)) {
				if (orderDeliveryDate.Delivery_Date_ID__c.endsWithIgnoreCase(deliveryPlant)) {
					availableDate = orderDeliveryDate.Substitue_Delivery_Date__c;
					cutOffDatetime =orderDeliveryDate.Cutoff_datetime__c;
				}
			} else {
				availableDate = orderDeliveryDate.Substitue_Delivery_Date__c;
				cutOffDatetime =orderDeliveryDate.Cutoff_datetime__c;
			}
			if (availableDate != null) {
				Integer calemdermonths = availableDate.month() - 1;
				string key = availableDate.year() + '_' + calemdermonths;
				if (availableDeliveryDatesMap.containsKey(key)) {
					DeliveryDatesWrapper deliveryDateWrapper = availableDeliveryDatesMap.get(key);
					deliveryDateWrapper.deliveryDates.add(availableDate);
					deliveryDateWrapper.dates.add(availableDate.day());
					availableDeliveryDatesMap.put(key, deliveryDateWrapper);
				} else {
					availableDeliveryDatesMap.put(key, createDateWrapper(availableDate,cutOffDatetime, orderDeliveryDate.Order_Split_ID__c));
				}
			}
		}

		//Remove Delivery Dates which falls withing Transit Duration
		if(transitDuration > 0 && availableDeliveryDatesMap.size()>0){
			Integer tDuration = 0;
			for(string key : availableDeliveryDatesMap.keySet()){
				DeliveryDatesWrapper deliveryDateWrapper = availableDeliveryDatesMap.get(key);
				while(tDuration < transitDuration && deliveryDateWrapper.dates.size()>0){
					deliveryDateWrapper.deliveryDates.remove(0);
					deliveryDateWrapper.dates.remove(0);
					tDuration++;
				}
				/**
				 * NCP-7709 : If deliveryDate is not empty for a month then add to availableDeliveryDatesMap
				 * otherwise remove the key because we dont want to return empty data to LWC
				 */
				if(deliveryDateWrapper.dates.size()>0){
					availableDeliveryDatesMap.put(key, deliveryDateWrapper);
				}else{
					availableDeliveryDatesMap.remove(key);
				}
			}
		}
		return availableDeliveryDatesMap.values();
	}
	/**
	 * @description Method to create DeliveryDatesWrapper Instance
	* @param deliveryDate 
	* @param cutOffDatetime 
	* @param splitTypeName 
	* @return  `DeliveryDatesWrapper`
	*/	
	public static DeliveryDatesWrapper createDateWrapper(date deliveryDate,Datetime cutOffDatetime ,string splitTypeName) {
		DeliveryDatesWrapper deliveryDateWrapper = new DeliveryDatesWrapper();
		deliveryDateWrapper.dates = new List < Integer > ();
		deliveryDateWrapper.deliveryDates = new List < Date > ();
		deliveryDateWrapper.year = deliveryDate.year();
		deliveryDateWrapper.month = deliveryDate.month() - 1;
		deliveryDateWrapper.dates.add(deliveryDate.day());
		deliveryDateWrapper.splitTypeId = splitTypeName;
		deliveryDateWrapper.deliveryDates.add(deliveryDate);
		return deliveryDateWrapper;
	}
	/**
	 * @description Convert String into Set<Integer>
	* @param dayPattern 
	* @return  `Set < Integer >`
	*/
	public static Set < Integer > createDayPatternSet(string dayPattern) {
		Set < Integer > dayPatternSet = new Set < Integer > ();
		if (String.isNotBlank(dayPattern)) {
			for (string day: dayPattern.split(';')) {
				try {
					dayPatternSet.add(Integer.valueOf(day));
				} catch (Exception ex) {
					System.debug(LoggingLevel.ERROR, ex);
				}
			}
		}
		return dayPatternSet;
	}

	/**
	 * @description - Method to get Transit Duration (NCP-6437)
	 * @param accId - Ship-To Account Id
	 * @param orderSplitId - Order Split Id
	 * @return  `List<Outlet_Split_Transit_Duration__c>`
	 */
	public static List<Outlet_Split_Transit_Duration__c> getTransitDuration(Id accId, Id orderSplitId){
		List<Outlet_Split_Transit_Duration__c> transitDurationList = new List<Outlet_Split_Transit_Duration__c>();
		transitDurationList = [SELECT Id, Outlet_ID__c, Order_Split_ID__c, Transit_Days__c FROM Outlet_Split_Transit_Duration__c 
								WHERE Outlet_ID__c =:accId AND Order_Split_ID__c =:orderSplitId];

		return transitDurationList;
	}

	//Order Split Wrapper Class
	public class OrderSplitDetailsWrap {
		@AuraEnabled public string orderSplitId;
		@AuraEnabled public string orderSplitName;
	}
	//Delivery Dates Wrapper Class
	public class DeliveryDatesWrapper {
		@AuraEnabled public Integer year;
		@AuraEnabled public Integer month;
		@AuraEnabled public List < Integer > dates;
		//@AuraEnabled public String splitTypeName;
		@AuraEnabled public String splitTypeId;
		@AuraEnabled public List < Date > deliveryDates;
	}
}