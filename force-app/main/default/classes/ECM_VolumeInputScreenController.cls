/*
@Name: ECM_VolumeInputScreenController
@Description: This class is used to fetch required data for "ECM_VolumeInputScreenTable" component
@History                                                            

VERSION		AUTHOR				DATE			DETAIL
1.0			Anivesh Muppa		21/04/2021      Initial Development
2.0		 	Saurav Prasad		29/04/2021		Development for ECM-4140(Save the Volume input data on the Depletion records either create/update the depletion record related to the specified month)
3.0		 	Chandrakanth		07/05/2021		Development for ECM-4136
4.0		 	Saurav Prasad		19/05/2021		Development for ECM-4442(Update the Payment summary item:Confirmed Volume,Confirmed Amount Per Payment Update the Payment summary: _VoTotal Amount Confirmed)
5.0      	Manikandan.T        24/12/2021      Bug Fix for ECM-5063
6.0			Subhrojit Majumdar	23/02/2022		Development for ECM-5194(Restrict insertion/update of Depletions with 0 Actuals)
7.0         Vinay Tummala       22/03/2022      Development for ECM-5270(Depletion Report Creation with Rate/UoM field)
8.0         Pratik Somani       07/04/2022      Development for ECM-5423(Totals Section on the Volume Input Screen)
9.0         Vinay Tummala       30/05/2022      ECM-5617 Multiple UoM actuals on Volume Input Screen_UI
10.1        Pratap Sen          22/06/2022      ECM-5677 : added ECM_Last_Volume_Information_Update__c in Contract Query of saveDepletions()
10.2        Pratap/Subhrojit    05/07/2022      ECM-5619 : added ECM_Updated_Forecasted_Volume__c in Payment Summary Item Query of saveDepletions()
10.3		Saurav Prasad		12/09/2022		ECM-6020 : Updated Forecast Volume 
10.4        Vinay Tummala       13/09/2022      ECM-6077 : Volume Input Screen for Addendum Products_SFDC_EU
10.5        SUvendu Roy         10/11/2022      ECM-6314 : In the Volume Input screen of Child contract, Period is not getting frozen for which Volume based Payment Summary is not present in child contract
10.6        Pratik Somani		15/11/2022      ECM-6360 : ECM_VolumeInputScreenController Base UOM and CM UOM issue 
11.0		Saurav Prasad		22/11/2022		ECM-6373 : Tool Translation_Volume Input Screen_SFDC
12.0		Swagata Mondal		13/07/2023		122836   : DDH External Key Set
*/
public class ECM_VolumeInputScreenController {
    @AuraEnabled
    public static List<VolumeInputWrapper> getProductValues(String ConId){
        List<VolumeInputWrapper> lstVolumeWrapper = new List<VolumeInputWrapper>();
        Id accountId ;
        Set<Id> productIds = new Set<Id>();
        Date StartDate;
        Date EndDate;
        Set<String> uniqDate = new Set<String>();
        Map<String,ECM_Contract_Item__c> prodConitem = new Map<String,ECM_Contract_Item__c>(); 
        //Map<String,ECM_Payment_Summary_Item__c> prodPaySumitem = new Map<String,ECM_Payment_Summary_Item__c>(); 
        Map<String,ChildVolumeWrapper> prodMonthwiseDepltns = new Map<String,ChildVolumeWrapper>(); 
        //ECM-6373 change
        List<Date> lstofMonths = new List<Date>();
        Map<String,Date> localeMonthNames = new Map<String,Date>();
        
        Map<Id,Map<String,Depletions__c>> depletionMap = new Map<Id,Map<String,Depletions__c>>();
        Map<String,Map<String,Integer>> paymentItemsMap = new Map<String,Map<String,Integer>>();
        Map<Id,set<String>> freezeMonths = new Map<Id,set<String>>();
        string ddhUniqstr;

        String info=[Select Name from Profile where id=:UserInfo.getProfileId()].Name;
        for(ECM_Contract_Item__c ConItem : 
            [Select Id,Name,ECM_Contracts_UoM__c,ECM_Volume__c,ECM_Contract__c,
             ECM_Contract__r.AccountId,ECM_Product_Name__c,ECM_Contract__r.Account.KUNNR__c,
             ECM_Product__r.Product__c,ECM_Contract__r.Contract_End_Date__c,ECM_Product__r.Product__r.Product_2_ID__c,
             ECM_Product__r.Base_UoM__c,ECM_Product__r.ECM_CM_UoM__c,
             ECM_Contract__r.StartDate,ECM_Contract__r.ECM_Duration__c,ECM_Lead_Brand__c
             from ECM_Contract_Item__c Where ECM_Contract__c=:ConId AND (ECM_Addendum__c=null OR (ECM_Addendum__c!=null AND ECM_Addendum__r.ECM_Status__c='Approved'))
             Order by ECM_Product_Name__c]){
                 StartDate = ConItem.ECM_Contract__r.StartDate;
                 EndDate = ConItem.ECM_Contract__r.Contract_End_Date__c;
                 accountId=ConItem.ECM_Contract__r.AccountId;
                 if(ConItem.ECM_Product__c!=Null){
                     productIds.add(ConItem.ECM_Product__r.Product__c);
                     prodConitem.put(ConItem.ECM_Product__r.Product__c,ConItem);
                 }
             }
        System.debug('paymentItemsMap->'+paymentItemsMap);
        //Added to avoid null point Exception
        Integer monthDiff = StartDate!=null?StartDate.monthsBetween(EndDate.adddays(1)):0;
        for(Integer i=0; monthDiff>i;i++){
            DateTime monthName = StartDate.addMonths(i);
            //lstofMonths.add(monthName.format('MMMMM'));
            //ECM-6373 change
            lstofMonths.add(StartDate.addMonths(i));
            if(!localeMonthNames.containsKey(monthName.format('MMMMM'))){
                localeMonthNames.put(monthName.format('MMMMM'),StartDate.addMonths(i));
        }
        }
        
        //Start ECM-6314
        Contract conRec =  [SELECT ECM_Amended__c,Id,StartDate FROM Contract WHERE Id =: ConId];
        Set<String> disableMonths = new Set<String>();
        if(conRec.ECM_Amended__c){
             ECM_Payment_Summary_Item__c payitems = [SELECT id, Start_Period__c,
             ECM_Contract_Item__r.ECM_Product__r.Product__c
             FROM ECM_Payment_Summary_Item__c WHERE
             ECM_Payment_Summary__r.ECM_Type__c = 'Volume-Based' AND
             ECM_Contract_Item__r.ECM_Contract__c=:ConId 
             ORDER BY Start_Period__c ASC NULLS LAST LIMIT 1 ];
            
            if(payitems!= null && payitems.Start_Period__c > conRec.StartDate){
                Integer length = conRec.StartDate.monthsBetween(payitems.Start_Period__c);
                
                for(Integer i = 0; i < length; i++){
                    Date tempDate = Date.valueOf(conRec.StartDate);
                    DateTime startMonth = DateTime.newInstance(tempDate.year(), tempDate.month(), 1, 11 ,59 ,59).addMonths(i);
                    disableMonths.add(startMonth.format('MMMMM')+'_'+startMonth.year());
                }
            }
        }
        //End ECM-6314
        
        //start ECM-4136
        for(ECM_Payment_Summary_Item__c payitems:
            [Select id, Start_Period__c, ECM_End_Period__c,ECM_Payment_Summary__c,
             ECM_Contract_Item__r.ECM_Product__r.Product__c
             from ECM_Payment_Summary_Item__c where 
             (ECM_Payment_Summary__r.ECM_Payment_Summary_Status__c = 'Submitted' OR 
              ECM_Payment_Summary__r.ECM_Payment_Summary_Status__c = 'Approved' OR
              ECM_Payment_Summary__r.ECM_Payment_Summary_Status__c = 'Completed' OR
              ECM_Payment_Summary__r.ECM_Payment_Summary_Status__c = 'In Approval process') AND 
             ECM_Payment_Summary__r.ECM_Type__c = 'Volume-Based' AND
             ECM_Contract_Item__r.ECM_Contract__c=:ConId 
            ]){
                
                if(!paymentItemsMap.containsKey(payitems.ECM_Contract_Item__r.ECM_Product__r.Product__c)){
                    paymentItemsMap.put(payitems.ECM_Contract_Item__r.ECM_Product__r.Product__c,new Map<String, Integer>{ String.valueOf(payitems.Start_Period__c)=> payitems.Start_Period__c.monthsBetween(payitems.ECM_End_Period__c.adddays(1))});
                }else{
                    paymentItemsMap.get(payitems.ECM_Contract_Item__r.ECM_Product__r.Product__c).put(String.valueOf(payitems.Start_Period__c), payitems.Start_Period__c.monthsBetween(payitems.ECM_End_Period__c.adddays(1)));
                }
                
            }
        
        for(string prodId : paymentItemsMap.keyset()){
            for(String payDate: paymentItemsMap.get(prodId).keySet()){
                for(Integer i=0;i<paymentItemsMap.get(prodId).get(payDate);i++){
                    
                    Date tempDate = Date.valueOf(payDate);
                    DateTime startMonth = DateTime.newInstance(tempDate.year(), tempDate.month(), 1, 11 ,59 ,59).addMonths(i);
                    
                    if(!freezeMonths.containsKey(prodId)){
                        freezeMonths.put(prodId,new Set<String>{startMonth.format('MMMMM')+'_'+startMonth.year()});
                    }
                    else{
                        freezeMonths.get(prodId).add(startMonth.format('MMMMM')+'_'+startMonth.year());
                    }
                }
            }
        }
        //End ECM-4136
        
        system.debug('freezeMonths->'+freezeMonths);
        system.debug('monthDiff'+monthDiff);
        system.debug(StartDate+'=='+EndDate);
        
        for(Depletions__c dplt : 
            [Select Id,Name,Contract__c,ECM_End_Period__c,Forecast_Volume__c,
             ECM_Outlet__c,ECM_Product__c,ECM_Start_Period__c,Unique_ID__c,ECM_Volume__c 
             FROM Depletions__c 
             Where ECM_Start_Period__c>=:StartDate AND ECM_End_Period__c<=:EndDate 
             AND ECM_Outlet__c =:accountId AND ECM_Product__c IN:prodConitem.keyset()
             AND Contract__c=:ConId Order by ECM_Product__r.Name,ECM_Start_Period__c]){
                 DateTime monthName = dplt.ECM_Start_Period__c;
                 if(!depletionMap.containsKey(dplt.ECM_Product__c)){
                     depletionMap.put(dplt.ECM_Product__c, new Map<String, Depletions__c>{monthName.format('MMMMM')+'_'+monthName.format('yyyy') => dplt});
                 }
                 else{
                     depletionMap.get(dplt.ECM_Product__c).put(monthName.format('MMMMM')+'_'+monthName.format('yyyy'), dplt);
                 }                    
                 
             }
        
        //  if(prodMonthwiseDepltns.size()>0){
        for(string prodId : prodConitem.keyset()){
            List<ChildVolumeWrapper> volumeInputValues = new List<ChildVolumeWrapper>();
            VolumeInputWrapper volmWrap = new VolumeInputWrapper();
            volmWrap.contractItem = prodConitem.get(prodId);
            set<String> monthsFromDep = depletionMap.containsKey(prodId)?depletionMap.get(prodId).keySet():new set<String>();
            //Added as part of ECM-5423->Start
            Double sumActualVal = 0;
            Double sumForecaseVal = 0;
            //Added as part of ECM-5423->End
            System.debug('monthsFromDep->'+monthsFromDep);
            for(Integer i=0; monthDiff>i;i++){
                DateTime monthName = StartDate.addMonths(i);
                String monthFormat =monthName.format('MMMMM')+'_'+monthName.format('yyyy');
                monthName.format('MMMM');
                string uniqstr = prodConitem.get(prodId).ECM_Contract__c+'_'+prodConitem.get(prodId).ECM_Contract__r.AccountId+'_'+prodId+'_'+monthFormat;
                //DDH External Key Set .US-122836
                if(prodConitem.get(prodId).ECM_Contract__r.AccountId != null && prodConitem.get(prodId).ECM_Product__r.Product__c != null){
                   ddhUniqstr = prodConitem.get(prodId).ECM_Contract__r.Account.KUNNR__c+'_'+prodConitem.get(prodId).ECM_Product__r.Product__r.Product_2_ID__c+'_'+monthFormat;
                }
                System.debug('ddhUniqstr  '+ddhUniqstr);
                system.debug('month name '+monthFormat);
                String recId = (depletionMap.containsKey(prodId) && depletionMap.get(prodId).containsKey(monthFormat))?String.valueOf(depletionMap.get(prodId).get(monthFormat).Id):'Null';
                decimal volume = (prodConitem.containskey(prodId) && prodConitem.get(prodId).ECM_Volume__c!=Null)?(prodConitem.get(prodId).ECM_Volume__c/ProdConitem.get(prodId).ECM_Contract__r.ECM_Duration__c).setscale(2):0;
                decimal actual =(depletionMap.containsKey(prodId) && depletionMap.get(prodId).containsKey(monthFormat))?(depletionMap.get(prodId).get(monthFormat).ECM_Volume__c).setScale(2):0;
                //ECM-6020 updated forecast
                decimal forecast= (depletionMap.containsKey(prodId) && depletionMap.get(prodId).containsKey(monthFormat))?(depletionMap.get(prodId).get(monthFormat).Forecast_Volume__c).setScale(2):
                (prodConitem.containskey(prodId) && prodConitem.get(prodId).ECM_Volume__c!=Null)?(prodConitem.get(prodId).ECM_Volume__c/ProdConitem.get(prodId).ECM_Contract__r.ECM_Duration__c).setScale(2):0;
                set<String> paymonths = freezeMonths.containsKey(prodId)?freezeMonths.get(prodId): new set<String>();
                if(disableMonths.size() > 0){ // ECM-6314
                    paymonths.addall(disableMonths);
                }
                //Added as part of ECM-5423->Start   
                sumActualVal += actual ;
                sumForecaseVal += forecast;
                //Added as part of ECM-5423->End
                //Added a field ECM_CM_UoM__c in logic as part of ECM-6360 
                volumeInputValues.add(new ChildVolumeWrapper(recId,actual,forecast,volume,monthFormat,prodConitem.get(prodId).ECM_Contracts_UoM__c!=null?prodConitem.get(prodId).ECM_Contracts_UoM__c:'',uniqstr, prodId, paymonths.contains(monthFormat)));
                //volumeInputValues.add(new ChildVolumeWrapper(recId,actual,forecast,volume,monthFormat,prodConitem.get(prodId).ECM_Product__r.Base_UoM__c!=null?prodConitem.get(prodId).ECM_Product__r.Base_UoM__c:'',uniqstr, prodId, paymonths.contains(monthFormat)));
            }
            volmWrap.depletionVolume = volumeInputValues;
            volmWrap.lstMonths = lstofMonths;
            //ECM-6373
            volmWrap.translatedMonths = localeMonthNames;
            volmWrap.alteredVolume = volumeInputValues;
            //Added as part of ECM-5423->Start
            volmWrap.sumActualVal = sumActualVal;
            volmWrap.sumForecaseVal = sumForecaseVal;
            volmWrap.sumVolumeVal =  volmWrap.contractItem.ECM_Volume__c;
            //Added as part of ECM-5423->End
        
            lstVolumeWrapper.add(volmWrap);
            //Security validation for specific profile ECM-4132
            volmWrap.userProfile = info;
        }
        system.debug('@'+lstVolumeWrapper);
        return lstVolumeWrapper;
    }
    /*
* Create/Updates the depletion records for the specific contract
*/
    @AuraEnabled
    public static void saveDepletions(String strWrapper, String conId){
        
        List<VolumeInputWrapper> volumeWrap =(List <VolumeInputWrapper>)JSON.deSerialize(strWrapper, List <VolumeInputWrapper>.class );
        List<ChildVolumeWrapper> depletionWrapper = new List<ChildVolumeWrapper>();
        set<String> depletionIds = new set<String>();
        set<String> productIds = new Set<String>();
        map<String, Integer> monthMap = new Map<String, Integer>();
        Map<Id,ECM_Contract_Item__c> prodIdToConItems = new Map<Id,ECM_Contract_Item__c>();
        List<Depletions__c> upsertData = new List<Depletions__c>();
        for(Integer i=0;i<12;i++){
            DateTime monthName = System.now().addMonths(i);
            monthMap.put(monthName.format('MMMMM'),monthName.month());
        }
        
        System.debug('monthMap->'+monthMap);
        Contract con = [Select Id, Accountid, Account.Country__c,Account.country__r.Code__c from Contract where Id =:conId];
        
        for(VolumeInputWrapper vol : volumeWrap){
            depletionWrapper.addAll(vol.alteredVolume);
        }
        for(ChildVolumeWrapper childVol : depletionWrapper){
            
            depletionIds.add(childVol.depId);
            //ECM-5270 for copying Rate/UoM of contract Item into Rate/UoM of depletions based on product
            productIds.add(childVol.productId);
            
            
        }
        //ECM-5270 for copying Rate/UoM of contract Item into Rate/UoM of depletions based on product
        List<ECM_Contract_Item__c> contractItems =[Select Id,ECM_UoM__c,ECM_Product__r.Product__c from ECM_Contract_Item__c where 	ECM_Contract__c = :conId and ECM_Product__r.Product__c in:productIds];
        for(ECM_Contract_Item__c conItem : contractItems){
            prodIdToConItems.put(conItem.ECM_Product__r.Product__c,conItem);
        }
        Map<Id, Depletions__c> delpetionMap = 
            new Map<Id,Depletions__c>([Select Id,ECM_Rate_UoM__c,Contract__c,ECM_End_Period__c,Forecast_Volume__c,
                                       ECM_Geography__c,ECM_Outlet__c,ECM_Product__c,ECM_Start_Period__c,
                                       Unique_ID__c,ECM_UoM__c,ECM_Volume__c
                                       from Depletions__c where id IN:depletionIds]);
        //ECM-5194
        List<Id> toDelete = new List<Id>();
        for(ChildVolumeWrapper childVolume : depletionWrapper){
            Boolean isDepletionUpdate = false;//to track Depletions for update
            if(!childVolume.isDisabled){
                Date startMonth = date.newInstance(Integer.valueOf(childVolume.mnthName.split('_')[1]),monthMap.get(childVolume.mnthName.split('_')[0]),01);
                startMonth = startMonth.toStartOfMonth();  
                Date endMonth = startMonth.addmonths(1).addDays(-1);
                Depletions__c tempUpsert;
                if(!(childVolume.depId).equalsIgnoreCase('Null') && delpetionMap.containsKey(childVolume.depId)){
                    tempUpsert = delpetionMap.get(childVolume.depId);
                    isDepletionUpdate = true;
                }else{
                    tempUpsert = new Depletions__c();
                }
                tempUpsert.Contract__c = conId;
                tempUpsert.ECM_Geography__c = con.Account.Country__c;
                tempUpsert.ECM_Outlet__c = con.Accountid;
                tempUpsert.ECM_UoM__c = childVolume.productUOM;
                if(childVolume.actualVal == 0 && isDepletionUpdate == true && childVolume.forecaseVal == 0){
                    //ECM-6020 - commenting below as part of this story
                    //toDelete.add(delpetionMap.get(childVolume.depId).Id); //delete records updated to 0 Actuals and 0 Forecasted Volume
                }
                tempUpsert.ECM_Volume__c = childVolume.actualVal;
                tempUpsert.Forecast_Volume__c =childVolume.forecaseVal;
                tempUpsert.ECM_Product__c = childVolume.productId;
                //ECM-5270 for copying Rate/UoM of contract Item into Rate/UoM of depletions based on product
                if(prodIdToConItems.containsKey(childVolume.productId) && prodIdToConItems.get(childVolume.productId).ECM_UoM__c!=null){
                  tempUpsert.ECM_Rate_UoM__c = prodIdToConItems.get(childVolume.productId).ECM_UoM__c;  
                }
                tempUpsert.Unique_ID__c = childVolume.uniqueStr;
                 // DDH External Key Set .US-122836
                /*if(System.Label.C360_DDH_Voulme_Country_Codes.contains(con.Account.country__r.Code__c)){
                    //tempUpsert.C360_DDH_External_ID__c = childVolume.ddhExternalId;
                }*/
               
                tempUpsert.ECM_Start_Period__c = startMonth;
                tempUpsert.ECM_End_Period__c = endMonth;
                System.debug('tempUpsert->'+tempUpsert);
                //Insert or Update Depletions when there is non-zero value in Actuals/Updated Forecasted Volume
                //ECM-6020 - commenting as part of the story
                // if(childVolume.actualVal != 0 || childVolume.forecaseVal != 0){
                upsertData.add(tempUpsert);
                // }
            }
        }
		Map<Id,List<ECM_Payment_Summary_Item__c>> paymentSummaryItemMap = new Map<Id,List<ECM_Payment_Summary_Item__c>>();
		set<Id> contItemIds = new set<Id>();
		Map<Id,ECM_Tiering__c> mapOfTier = new Map<Id,ECM_Tiering__c>();
		
		Contract conRec = [SELECT Id, Account.Country__c, ECM_Payment_Frequency_type__c, ECM_Payment_Frequency_type__r.ECM_Type__c, AccountId, ECM_Payment_Frequency__c, Contract_End_Date__c,
                           ECM_Last_Volume_Information_Update__c, StartDate FROM Contract where Id=:conId];
		Market_Setting__c marSet = [SELECT Id,Name,Geography__c,ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c,Depletion_market__c,ECM_Enable_Target__c FROM Market_Setting__c Where Geography__c =: conRec.Account.Country__c];
		Map<Id,ECM_Payment_Summary__c>paymentSumamryMap= new Map<Id,ECM_Payment_Summary__c>([SELECT Id, ECM_Contract__c, ECM_End_Period__c, ECM_Invoice_Receival_Date__c, ECM_Invoice_Status__c, ECM_Payment_Summary_Status__c,                                                             
										   ECM_Sales_Driver__c, ECM_Start_Period__c, ECM_Tax_Rate__c, ECM_Total_Amount_Confirmed__c,ECM_Total_Amount_Forecasted__c, ECM_Type__c, ECM_Budget_types__c,
										   ECM_Fiscal_Years__c, ECM_Total_to_be_Invoiced__c, ECM_UoS_Total__c, ECM_No_Invoice_Required__c, ECM_Approval_Date__c, ECM_Payment_Due_Date__c,ECM_Submitted_Date__c,
										   ECM_Contract__r.Account.Country__r.Name,ECM_Contract__r.Status,ECM_Contract__r.ECM_Duration__c
										   FROM ECM_Payment_Summary__c 
										   Where Ecm_Contract__c=:conId AND ECM_Type__c=:System.label.Ecm_Payment_Summary_Volume_based]);

		for(ECM_Payment_Summary_Item__c psItem: [SELECT Id,ECM_Payment_Summary__c,ECM_Payment_Summary__r.ECM_End_Period__c, ECM_Payment_Summary__r.ECM_Start_Period__c, ECM_Confirmed_Amount_Per_Payment__c, ECM_Contract_Item__c,
											ECM_Contract_Item__r.ECM_Product__r.Product__c,ECM_Contract_Item__r.ECM_Lead_Brand__c,ECM_Contract_Item__r.ECM_Volume__c,ECM_Confirmed_Volume__c, ECM_Actual_Cases__c,ECM_Contract_Item__r.ECM_UoM__c,
											ECM_Payment_Summary__r.ECM_Contract__c,ECM_Percentage_Target_Achieved__c,ECM_Contract_Item__r.ECM_Volume_Target_per_PF__c,ECM_Payment_Summary__r.ECM_Contract__r.Status,ECM_Updated_Forecasted_Volume__c
											FROM ECM_Payment_Summary_Item__c where ECM_Payment_Summary__c IN:paymentSumamryMap.keySet() ]){														
											if(paymentSummaryItemMap.get(psItem.ECM_Payment_Summary__c)!=null){
												List<ECM_Payment_Summary_Item__c> tempPSItemList= new List<ECM_Payment_Summary_Item__c>(paymentSummaryItemMap.get(psItem.ECM_Payment_Summary__c));
												tempPSItemList.add(psItem);
												paymentSummaryItemMap.put(psItem.ECM_Payment_Summary__c,tempPSItemList);
											}else{
											
												paymentSummaryItemMap.put(psItem.ECM_Payment_Summary__c,new list<ECM_Payment_Summary_Item__c>{psItem});
											}
											if(psItem.ECM_Payment_Summary__r.ECM_Contract__r.Status=='Active'){
											
												contItemIds.add(psItem.ECM_Contract_Item__c);
											}
											
		}

		for(ECM_Tiering__c tier:[SELECT Id,Name,ECM_Contract_Item__c,
												 ECM_Tier_1_volume_limit__c,ECM_Tier_1_rate_per_UoM__c,
												 ECM_Tier_2_volume_limit__c,ECM_Tier2_rate_per_UoM__c,
												 ECM_Tier_3_volume_limit__c,ECM_Tier_3_rate_per_UoM__c 
												 FROM ECM_Tiering__c Where ECM_Contract_Item__c IN:contItemIds]){
													 mapOfTier.put(tier.ECM_Contract_Item__c,tier);
												 }
												 
		Database.executeBatch(new ECM_upsertDepletionsBatchController(upsertData,toDelete,conId,conRec,marSet,paymentSumamryMap,paymentSummaryItemMap,mapOfTier));
    }
    //ECM-5617
     @AuraEnabled
    Public static List<SampleWrapper> getMap(Integer volume){ 
        List<SampleWrapper> list1 = new List<Samplewrapper>();
        Double vol = volume;
        String s ='BTL';
        Double con = 0.00;
        for(Integer i=0;i<1;i++){
            SampleWrapper sp =new SampleWrapper();
            sp.Volume = vol;
            Integer rem = math.mod(i,2);
            if(rem==1){
                sp.UOM='CAS';
                sp.Conv= sp.Volume*10;
            }
            else{
                sp.UOM=s;
                sp.Conv= sp.Volume*1;
            }
            list1.add(sp);
        }
        try{
          return list1;  
        }
        catch(Exception ex)
        {
            System.debug('Error'+ex);
        }
        return null;
 
    }
    public class SampleWrapper{
        @AuraEnabled
        public Double Volume{get;set;}
        @AuraEnabled
        Public String UOM{get;set;}
        @AuraEnabled
        Public Double Conv{get;set;}
        
    }
    public class VolumeInputWrapper{
        @AuraEnabled
        public ECM_Contract_Item__c contractItem{get;set;}
        @AuraEnabled
        public List<ChildVolumeWrapper> depletionVolume{get;set;}
        @AuraEnabled
        public List<ChildVolumeWrapper> alteredVolume{get;set;}
        //ECM-6373
        @AuraEnabled
        public Map<String,Date> translatedMonths{get;set;}
        @AuraEnabled //ECM-6373 change
        public List<Date> lstMonths{get;set;} 
        @AuraEnabled
        public String userProfile{get;set;}
        
        //Added as part of ECM-5423->Start
        @AuraEnabled
        public Decimal sumActualVal{get;set;}
        @AuraEnabled
        public Decimal sumForecaseVal{get;set;}  
        @AuraEnabled
        public Decimal sumVolumeVal{get;set;}  
        //Added as part of ECM-5423->End
    }
    Public class ChildVolumeWrapper{
        @AuraEnabled
        public String depId{get;set;}
        @AuraEnabled
        public Decimal actualVal{get;set;}
        @AuraEnabled
        public Decimal forecaseVal{get;set;}  
        @AuraEnabled
        public Decimal volumeVal{get;set;}  
        @AuraEnabled
        public String mnthName{get;set;}
        @AuraEnabled
        public String productUOM{get;set;}
        @AuraEnabled
        public String uniqueStr{get;set;}
        @AuraEnabled
        public String productId{get;set;}
        @AuraEnabled
        public Boolean isDisabled{get;set;}
       
        //public String ddhExternalId{get;set;} // DDH External Key Set .US-122836
        
        Public ChildVolumeWrapper(String recId,Decimal actual,Decimal forecast,Decimal volume,String monthName,String uom, String uniqueId, Id prodId, Boolean disabled){
            depId = recId;
            actualVal = actual;
            forecaseVal = forecast;
            volumeVal = volume;
            mnthName = monthName;
            productUOM = uom;
            uniqueStr = uniqueId;
            productId = prodId;
            isDisabled = disabled;
            //ddhExternalId = ddhUniqstr; // DDH External Key Set .US-122836
        }
    }
}