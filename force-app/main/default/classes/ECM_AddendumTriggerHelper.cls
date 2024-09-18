/*
* @Name: ECM_AddendumTriggerHelper
* @Purpose: This class contains all methods to be called from ECM_AddendumTriggerHandler
* @History:                                                                                                                       
* VERSION        AUTHOR            DATE              DETAIL
* 1.0        Pratap/Subhrojit   02/08/2022    Initial Development for ECM-5964
* 1.1        Pratap/Subhrojit   16/08/2022    ECM-6029 : PS generation Logic for Sales Driver-Non-Recurring PF_SFDC_EU
* 1.2		 Anshu/Tanishq		30/08/2022	  ECM-6078 : KPI Recalculation Logic_Contract_SFDC_EU
* 1.3        Ravi               12/09/2022    ECM-5960 : capture the date when Addendum was approved
* 1.4        Joshraj Sen        20/12/2023    146153 Prevent the creation of Payment Summaries for CRG Contracts
*/
public class ECM_AddendumTriggerHelper {
    /*
    * Name : ECM_createAddendumPaymentSummaries (ECM-6029)
    * @description : PS generation Logic for Sales Driver-Non-Recurring PF_SFDC_EU
    * @return : void
    * @param : Map<Id, <ECM_Addendum__c>>
    */ 
    public static void ECM_createAddendumPaymentSummaries(Map<Id,ECM_Addendum__c> newItems, Map<Id, ECM_Addendum__c> oldItems){
        /*Map of contract with approved addendum*/
        Map<Id,Id> conWithAddendum = new Map<Id,Id>();
        Map<Id,Id> conWithAddendumForVolumeBasedPS = new Map<Id,Id>();
        Map<Id,Id> conWithAddendumForPromoTypePS = new Map<Id,Id>();
        List<ECM_Sales_Driver_Item__c> salesDriverItemList = new List<ECM_Sales_Driver_Item__c>();
        Id crgRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Cold Room Grant').getRecordTypeId();//146153
        /*List of Payment Frequencies of all types*/
        List<String> atTheEndOfContractPF = Label.ECM_AtTheEndOfContractPF.replace('\r\n','').split(','); //At the End of Contract,Al finalizar el contrato 
        List<String> paymentAfterActivationPF = Label.ECM_PaymentAfterActivationPF.replace('\r\n','').split(','); //Payment after activation,Pago después de la activación
        List<String> recurringInAdvancePF = Label.ECM_RecurringInAdvancePF.replace('\r\n','').split(','); //Monthly,Quarterly,Half-yearly,Yearly
        List<String> recurringRetrsospectivePF = Label.ECM_RetrospectivePFTypes.replace('\r\n','').split(','); //Monthly Retrospective,Quarterly Retrospective,Half-yearly Retrospective,Yearly Retrospective
        List<String> partialPaymentPF = Label.ECM_PartialPaymentPF.replace('\r\n','').split(','); //Partial Prepayment,Prepago parcial
        
        /*Set of Sales Driver Item Ids for different Payment Frequencies*/
        set <Id> partialPrePymtSDISet = new set <Id>();
        set <Id> recurringInAdvancedSDISet = new set <Id>();
        set <Id> recurringRetrospectiveIdSet = new set <Id>();
        set <Id> paymentAtTheEndSDISet = new set <Id>();
        set <Id> paymentAfterActivationSDISet = new set <Id>();
        set <Id> PromoPrepaymentSDISet = new set <Id>();
        
        /*Set of Country Codes enabled with volume & Promo type PS*/
        Set<String> promoPSEnabledCountrySet = new Set<String>();
        Set<String> volumePSEnabledCountrySet = new Set<String>();
        
        //Fetch Approved Addendum and their contracts
        for(ECM_Addendum__c addndm : newItems.values()){
            if(oldItems.containsKey(addndm.Id) && oldItems.get(addndm.Id).ECM_Status__c != addndm.ECM_Status__c 
               && addndm.ECM_Status__c == 'Approved' && addndm.ECM_Contract__c != null && addndm.ECM_Addendum_Type__c != Label.ECM_AddendumTypeTC){ //type check for AU addendum : T&C
                   conWithAddendum.put(addndm.ECM_Contract__c,addndm.Id); //Considering only one Addendum gets approved at a time for a contract
               }
        }
        if(!conWithAddendum.isEmpty()){
            //Fetch payment types enabled for markets
            for(ECM_Technical_Market_Setting__mdt metaData: [SELECT ECM_Country__c,ECM_Payment_Summary_Promo__c,ECM_Payment_Summary_Volume__c
                                                             FROM ECM_Technical_Market_Setting__mdt]){
                                                                 if(metaData.ECM_Payment_Summary_Promo__c){
                                                                     promoPSEnabledCountrySet.add(metaData.ECM_Country__c);
                                                                 }
                                                                 if(metaData.ECM_Payment_Summary_Volume__c){
                                                                     volumePSEnabledCountrySet.add(metaData.ECM_Country__c);
                                                                 }
                                                             }
            
            //Filter Contracts on PS generation country check & Prepare Sales Driver Item List consisting all SDI from all contracts
            for(Contract con : [SELECT Id,Name,Account.Country_Code__c,ECM_Payment_Frequency_Type__c,ECM_Payment_Frequency_Type__r.ECM_Volume_target__c,
                                (SELECT Id,Contract__c,ECM_Payment_Frequency__c,ECM_Payment_Frequency__r.ECM_Type__c,ECM_Payment_Frequency__r.ECM_End_Date__c,
                                 ECM_Payment_Frequency__r.ECM_Prepayment__c,ECM_Payment_Frequency__r.Name,ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c,
                                 ECM_1st_Prepayment_Date__c,ECM_Payment_Date__c 
                                 FROM Sales_Driver_Masters__r
                                 WHERE ECM_Payment_Frequency__r.ECM_Other_Investment__c = true)
                                FROM Contract 
                                WHERE Id IN: conWithAddendum.keySet() 
                                AND  RecordTypeId != :crgRecordTypeId //146153
                                AND (Account.Country_Code__c IN: promoPSEnabledCountrySet OR Account.Country_Code__c IN: volumePSEnabledCountrySet)])
            {
                if(volumePSEnabledCountrySet.contains(con.Account.Country_Code__c)
                   && con.ECM_Payment_Frequency_Type__c != null
                   && con.ECM_Payment_Frequency_Type__r.ECM_Volume_target__c == true
                   && conWithAddendum.containsKey(con.Id))
                {
                    conWithAddendumForVolumeBasedPS.put(con.Id,conWithAddendum.get(con.id));
                }
                if(promoPSEnabledCountrySet.contains(con.Account.Country_Code__c) && !con.Sales_Driver_Masters__r.isEmpty() && conWithAddendum.containsKey(con.Id)){
                    salesDriverItemList.addAll(con.Sales_Driver_Masters__r);
                    conWithAddendumForPromoTypePS.put(con.Id,conWithAddendum.get(con.id));
                }
            }
            
            //Generate Volume-Based Payment Summaries
            if(!conWithAddendumForVolumeBasedPS.isEmpty()){
                ECM_CreatePaymtSummaryUtility.ECM_createVolBasedRecurringPS(null,conWithAddendumForVolumeBasedPS);
            }
            
            //Filter Sales Driver Items depending upon Payment Frequency Data set up
            for(ECM_Sales_Driver_Item__c sdiRec : salesDriverItemList){
                if(partialPaymentPF.contains(sdiRec.ECM_Payment_Frequency__r.ECM_Type__c) && sdiRec.ECM_Payment_Frequency__r.ECM_Prepayment__c){
                    partialPrePymtSDISet.add(sdiRec.Id);
                }
                if(recurringInAdvancePF.contains(sdiRec.ECM_Payment_Frequency__r.ECM_Type__c)){
                    recurringInAdvancedSDISet.add(sdiRec.Id);
                }
                if(recurringRetrsospectivePF.contains(sdiRec.ECM_Payment_Frequency__r.ECM_Type__c)){
                    recurringRetrospectiveIdSet.add(sdiRec.Id); 
                }
                if(atTheEndOfContractPF.contains(sdiRec.ECM_Payment_Frequency__r.ECM_Type__c) && sdiRec.ECM_Payment_Frequency__r.ECM_End_Date__c){
                    paymentAtTheEndSDISet.add(sdiRec.Id);
                }
                if(paymentAfterActivationPF.contains(sdiRec.ECM_Payment_Frequency__r.ECM_Type__c)){
                    paymentAfterActivationSDISet.add(sdiRec.Id);
                }
                if(!sdiRec.ECM_Payment_Frequency__r.ECM_Type__c.equals(Label.ECM_Single_Yearly_Payments) &&
                   sdiRec.ECM_Payment_Frequency__r.ECM_Prepayment__c && (sdiRec.ECM_1st_Prepayment_Date__c != null || sdiRec.ECM_Payment_Date__c != null)){
                       PromoPrepaymentSDISet.add(sdiRec.Id);
                   }
            }
            
            //Generate Promo-Standard & Promo-PrePayment Type Payment Summaries on different scenarios
            if(!partialPrePymtSDISet.isEmpty()){
                ECM_CreatePaymtSummaryUtility.ECM_createPromoStandardPrePaymentPS(partialPrePymtSDISet, conWithAddendumForPromoTypePS);
            }
            if(!recurringInAdvancedSDISet.isEmpty()){
                ECM_CreatePaymtSummaryUtility.ECM_createPromStandardRecurringPS(recurringInAdvancedSDISet, conWithAddendumForPromoTypePS); 
            }
            if(!recurringRetrospectiveIdSet.isEmpty()){
                ECM_CreatePaymtSummaryUtility.ECM_createPromStandardRecurringPS(recurringRetrospectiveIdSet, conWithAddendumForPromoTypePS);
            }
            if(!paymentAtTheEndSDISet.isEmpty()){
                ECM_CreatePaymtSummaryUtility.ECM_createPromStandardEndofContract(paymentAtTheEndSDISet, conWithAddendumForPromoTypePS); 
            }
            if(!paymentAfterActivationSDISet.isEmpty()){
                ECM_CreatePaymtSummaryUtility.ECM_createPromStandardAfteractivationPS(paymentAfterActivationSDISet, conWithAddendumForPromoTypePS); 
            }  
            if(!PromoPrepaymentSDISet.isEmpty()){
                ECM_CreatePaymtSummaryUtility.ECM_createPromoPrepaymentSummaries(PromoPrepaymentSDISet, conWithAddendumForPromoTypePS); 
            }            
        }
    }
    /*
    * Name : reCalculateKPI (ECM-5886)
    * @description : Method to calculate contract KPi recs when addendum is approved
    * @return : void
    * @param : Map<Id, <ECM_Addendum__c>>
    */ 
    public static void reCalculateKPI(Map<Id,ECM_Addendum__c> newItems, Map<Id, ECM_Addendum__c> oldItems){
        Set<Id> conSet = new Set<Id>();
        List<Contract> contractList = new List<Contract>();
        String addendumTypeExclusion = Label.ECM_AddendumTypeTC;
        List<ECM_Contract_Item__c> conItemList = new List<ECM_Contract_Item__c>();
        Decimal sdItemInv ;
        //Start of ECM-6078        
        for(ECM_Addendum__c addndm : newItems.values()){
            if(addndm.ECM_Contract__c != null  &&  addendumTypeExclusion != addndm.ECM_Addendum_Type__c
               && oldItems.containsKey(addndm.Id) && oldItems.get(addndm.Id).ECM_Status__c != addndm.ECM_Status__c 
               && addndm.ECM_Status__c == 'Approved'){ 
                   conSet.add(addndm.ECM_Contract__c); //Considering only one Addendum gets approved at a time for a contract
               }
        }
        Map<Id,Decimal> contractAandPmap = new Map<Id,Decimal>();
        Map<Id,Decimal> contractTImap = new Map<Id,Decimal>();
        List<ECM_Sales_Driver_Item_Detail__c> sdidinvestment = [SELECT Id,ECM_Budget_Type__c,ECM_Investment_Amount__c,ECM_Product__c,ECM_Sales_Driver_Item__r.Contract__c,
                                                                RecordTypeId,ECM_Addendum__r.ECM_Status__c 
                                                                FROM ECM_Sales_Driver_Item_Detail__c
                                                                WHERE ECM_Sales_Driver_Item__r.Contract__c IN: conSet AND ECM_Budget_Type__c != null AND ECM_Product__c != null
                                                                AND (ECM_Addendum__c = null OR ECM_Addendum__r.ECM_Status__c ='Approved') AND RecordType.Name = 'Sales Driver'
                                                                AND ECM_Investment_Amount__c != null];
        for(ECM_Sales_Driver_Item_Detail__c sdItemRec : sdidinvestment ){
            sdItemInv =  sdItemRec.ECM_Investment_Amount__c ;
            if(sdItemRec.ECM_Budget_Type__c.contains('A&P') ){
                if(contractAandPmap.containsKey(sdItemRec.ECM_Product__c)){                  
                    contractAandPmap.put(sdItemRec.ECM_Product__c,sdItemInv + 
                                         (contractAandPmap.get(sdItemRec.ECM_Product__c)!=Null?contractAandPmap.get(sdItemRec.ECM_Product__c):0));
                }
                else{ 
                    contractAandPmap.put(sdItemRec.ECM_Product__c,sdItemInv);       
                }
            }
            else if(sdItemRec.ECM_Budget_Type__c.contains('TI') ){ 
                if(contractTImap.containsKey(sdItemRec.ECM_Product__c)){
                    contractTImap.put(sdItemRec.ECM_Product__c,sdItemInv + 
                                      (contractTImap.get(sdItemRec.ECM_Product__c)!=Null?contractTImap.get(sdItemRec.ECM_Product__c):0));
                }
                else{ 
                    contractTImap.put(sdItemRec.ECM_Product__c,sdItemInv);  
                }
            }
        }
        
        if(!conSet.isEmpty()){
            for (ECM_Contract_Item__c conItem : [SELECT ID,ECM_EU_Volume__c,ECM_Volume__c,ECM_Price_List_ConItem__r.ECM_EU_Conversion_Factor__c,
                                                 ECM_AnP_investment__c,ECM_Trade_investments__c
                                                 FROM ECM_Contract_Item__c 
                                                 WHERE ECM_Contract__c IN:conSet 
                                                 AND (ECM_Addendum__c = null OR ECM_Addendum__r.ECM_Status__c ='Approved')])
            {
				Decimal forecastVol = conItem.ECM_Volume__c * nullCheck(conItem.ECM_Price_List_ConItem__r.ECM_EU_Conversion_Factor__c);
				conItem.ECM_EU_Volume__c = forecastVol;  
				conItem.ECM_AnP_investment__c = contractAandPmap.containsKey(conItem.ID)?contractAandPmap.get(conItem.ID).setScale(2):0;
				conItem.ECM_Trade_investments__c = contractTImap.containsKey(conItem.ID)?contractTImap.get(conItem.ID).setScale(2):0;
				conItemList.add(conItem);
			}
            if(!conItemList.isEmpty()) {
                update conItemList;
            }
            contractList = [SELECT Id,ECM_Overall_Investment_Amount__c,ECM_Total_trade_investment_Spirits__c,ECM_Total_trade_investment_Beers__c,
                            ECM_Total_A_P_Investment_Spirits__c,ECM_Total_A_P_Investment_Beers__c,ECM_EU_Total_Trade_Investment__c,ECM_Total_NSV__c,
                            ECM_Agreement_Type__r.ECM_Activation_Spend__c,ECM_Total_Indirect_Investment__c,ECM_Total_Indirect_A_P__c,ECM_CTD_Total_GP__c,
                            ECM_Generated_NSV__c,ECM_Total_TI_Investment__c,ECM_Total_A_P_Investment__c,ECM_Overall_Investment_Figure__c,ECM_Total_GP__c,
                            ECM_of_the_total_investment_vs_NSV__c,ECM_CAP_ROI__c,ECM_Fixed_share__c,ECM_Variable_share__c,ECM_of_Indirect_Invest_to_Overall_Invest__c,
                            ECM_CAAP_ROI_incl_Indirect_Invest__c,ECM_Total_Invest_vs_NSV_Indirect_Invest__c,ECM_of_A_P_vs_NSV__c,ECM_of_A_P_vs_NSV_Inc_Indirect_Inv__c,
                            ECM_GP_ROI__c,ECM_GM_innovation_share__c,ECM_GP_innovation_share__c,ECM_NSV_innovation_share__c,ECM_GM_premium_core_share__c,
                            ECM_GP_premium_core_share__c,ECM_NSV_premium_core_share__c,ECM_GM_local_priority_brand_share__c,ECM_GP_local_priority_brand_share__c,
                            ECM_NSV_local_priority_brand_share__c,ECM_GM_reserve_share__c,ECM_GP_reserve_share__c,ECM_NSV_reserve_share__c
                            FROM Contract WHERE Id IN: conSet];//update the query
            if(!contractList.isEmpty()) {
                calculateFieldValues(contractList);
            }            
        }//End of ECM-6078
        conSet.clear(); 
        conItemList.clear();
        contractAandPmap.clear();
        contractTImap.clear();
        sdidinvestment.clear();
    }
    /*
    * Name : calculateFieldValues (ECM-5907)
    * @description : Method to 
    * @return : void
    * @param : List of Contracts
    */
    public static void calculateFieldValues(List<Contract> contractList){
        List<ECM_Contract_KPI__c> conKpiList = new List<ECM_Contract_KPI__c>(); 
        Set<ID> contractIdSet = new Set<ID>();
        Map<Id,List<ECM_Contract_Item__c> > contractVsContractItem = new Map<Id,List<ECM_Contract_Item__c>>();
        Map<Id,List<Decimal> > fieldSums = new Map<Id,List<Decimal>>();
        List<ECM_Contract_Item__c> conItemUpdateList = new List<ECM_Contract_Item__c>();
        Map<Id,Map<String,List<ECM_Contract_Item__c>>> conPickUpMap = new Map<Id,Map<String,List<ECM_Contract_Item__c>>>(); 
        Map<Id,List<ECM_CreateContractController.GraphPercentValWrapper>> conGraphMap = new Map<Id,List<ECM_CreateContractController.GraphPercentValWrapper>>();
        Map<String,List<ECM_Contract_Item__c>> pickUpMap;
        //creating set of contract id to be processed
        if(contractList!=null && contractList.size()>0){
            for (Contract conRec:contractList){
                contractIdSet.add(conRec.Id);
            }        
        }
        Map<Id,Contract> contractMap=new Map<Id,Contract>(contractList);
        //creating a map of contract vs contract Item values
        if(!contractIdSet.isEmpty()){
            for (ECM_Contract_Item__c conItem : [SELECT ID,ECM_Contract__c, ECM_EU_Volume__c, ECM_NSV_After_TI__c,ECM_Retro_investment__c, 
                                                 ECM_Total_trade_investment__c, ECM_CAAP_Total__c,ECM_Total_GP__c,ECM_Gross_margin__c,
                                                 ECM_AnP_investment__c,ECM_Price_List_ConItem__r.ECM_EU_Conversion_Factor__c,ECM_Total_GP_EU__c,
                                                 ECM_Volume__c,ECM_Product__r.ECM_Pickup_Option__r.Name,ECM_NSV__c,ECM_Trade_investments__c,
                                                 ECM_GP_ROI_EU__c,ECM_CAP_ROI_EU__c,ECM_CTD_GP__c,ECM_Generated_NSV_EU__c,ECM_Gross_Profit__c
                                                 FROM ECM_Contract_Item__c 
                                                 WHERE ECM_Contract__c IN:contractIdSet
                                                 AND (ECM_Addendum__c = null OR ECM_Addendum__r.ECM_Status__c ='Approved')]) //query to fetch updated records
            {
                if(contractVsContractItem.containsKey(conItem.ECM_Contract__c)){
					contractVsContractItem.get(conItem.ECM_Contract__c).add(conItem);
				}else{
					contractVsContractItem.put(conItem.ECM_Contract__c,new List<ECM_Contract_Item__c>{conItem});
				}
                if(conPickUpMap.containsKey(conItem.ECM_Contract__c)){
					if(conPickUpMap.get(conItem.ECM_Contract__c).containsKey(conItem.ECM_Product__r.ECM_Pickup_Option__r.Name)){
						conPickUpMap.get(conItem.ECM_Contract__c).get(conItem.ECM_Product__r.ECM_Pickup_Option__r.Name).add(conItem);
					}else{
						conPickUpMap.get(conItem.ECM_Contract__c).put(conItem.ECM_Product__r.ECM_Pickup_Option__r.Name,new List<ECM_Contract_Item__c>{conItem});
					}                
				}else{
					Map <String,List<ECM_Contract_Item__c>> mapVal = new Map <String,List<ECM_Contract_Item__c>>();
					mapVal.put(conItem.ECM_Product__r.ECM_Pickup_Option__r.Name,new List<ECM_Contract_Item__c>{conItem});
					conPickUpMap.put(conItem.ECM_Contract__c,mapVal);
				}                                    
			}
        }
        if(!contractIdSet.isEmpty()){
            for(Id conRecId:contractIdSet){
                Decimal eUVolumeSum =0;
                Decimal totalNSVSum =0;
                Decimal totalTradeInvestmentSum =0;
                Decimal cAAPTotalSum =0;
                Decimal totalGnP =0;
                Decimal anPInvestment =0;
                if(contractVsContractItem.get(conRecId)!=null && contractVsContractItem.get(conRecId).size()>0){
                    for(ECM_Contract_Item__c conItem : contractVsContractItem.get(conRecId)){                        
                        eUVolumeSum += nullCheck(conItem.ECM_EU_Volume__c);
                        totalNSVSum += nullCheck(conItem.ECM_NSV_After_TI__c);
                        totalTradeInvestmentSum += nullCheck(conItem.ECM_Total_trade_investment__c);
                        cAAPTotalSum += nullCheck(conItem.ECM_CAAP_Total__c);//ECM_CAAP_Total__c
                        totalGnP += nullCheck(conItem.ECM_Total_GP_EU__c);
                        anPInvestment += nullCheck(conItem.ECM_AnP_investment__c);
                    }
                }                
                if(!fieldSums.containsKey(conRecId)){
                    fieldSums.put(conRecId,new List<Decimal>{eUVolumeSum,totalNSVSum,totalTradeInvestmentSum,cAAPTotalSum,totalGnP,anPInvestment});
                }                
            }
        }
        
        if(!conPickUpMap.isEmpty()){
            for(Id conId : conPickUpMap.keySet()){
                pickUpMap = conPickUpMap.get(conId);
                List<ECM_CreateContractController.GraphPercentValWrapper> graphVal =  new List<ECM_CreateContractController.GraphPercentValWrapper>();
                if(pickUpMap != null && !pickUpMap.isEmpty()){
                    graphVal = ECM_CreateContractController.calculateMapValues(pickUpMap);
                }
                conGraphMap.put(conId,graphVal);
            }
        }
        recalConKPI(contractMap,contractVsContractItem,conGraphMap);//ECM-6078
        List<Contract> conLst = [SELECT Id,ECM_Overall_Investment_Figure__c FROM Contract WHERE Id IN: contractIdSet];
        Map<Id,Contract> newContractMap=new Map<Id,Contract>(conLst);
        createConKpiRecs(fieldSums,'Total',newContractMap);
        conKpiList.clear();
        contractIdSet.clear();
        conItemUpdateList.clear();
        conPickUpMap.clear();
        //mapVal.clear();
        pickUpMap.clear();
    }
    /*
    * Name : createConKpiRecs (ECM-5907)
    * @description : Method to create contract KPi recs
    * @return : void
    * @param : Map<Id, List<decimal>>, String,Map<Id,Contract>
    */
    public static void createConKpiRecs(Map<Id,List<Decimal>> fieldSums,String type,Map<Id,Contract> newContractMap){
        List<ECM_Contract_KPI__c> conKpiRecToInsert = new List<ECM_Contract_KPI__c>();
        if(fieldSums!=null && fieldSums.size()>0){
            for(Id contId : fieldSums.keySet()){
                ECM_Contract_KPI__c contractKpiRec = new ECM_Contract_KPI__c();
                contractKpiRec.ECM_Contract__c = contId;
                contractKpiRec.ECM_Type__c = type;
                contractKpiRec.ECM_External_Id__c = contId+contractKpiRec.ECM_Type__c ;//ext id formula
                contractKpiRec.ECM_EU_Volume__c = fieldSums.get(contId)[0].setScale(2);
                contractKpiRec.ECM_Total_NSV__c = fieldSums.get(contId)[1].setScale(2);
                if(contractKpiRec.ECM_EU_Volume__c != null && contractKpiRec.ECM_EU_Volume__c != 0.00){
                    contractKpiRec.ECM_NSV_EU__c = (contractKpiRec.ECM_Total_NSV__c/contractKpiRec.ECM_EU_Volume__c).setScale(2);
                    contractKpiRec.ECM_Trade_Investment_EU__c = (fieldSums.get(contId)[2]/contractKpiRec.ECM_EU_Volume__c).setScale(2);
                }
                contractKpiRec.ECM_CAAP__c = fieldSums.get(contId)[3].setScale(2);
                if(contractKpiRec.ECM_Total_NSV__c != null && contractKpiRec.ECM_Total_NSV__c != 0.00){
                    contractKpiRec.ECM_CAAP_Percentage__c = (contractKpiRec.ECM_CAAP__c*100/contractKpiRec.ECM_Total_NSV__c).setScale(2);
                }
                
                if(newContractMap.containsKey(contId)){
                    Decimal overallInvstAmt =newContractMap.get(contId).ECM_Overall_Investment_Figure__c;
                    if(overallInvstAmt !=0.00 && overallInvstAmt != null){
                        contractKpiRec.ECM_CAAP_ROI_Percentage__c = (((fieldSums.get(contId)[4] - fieldSums.get(contId)[5])*100)/overallInvstAmt).setScale(2);
                    }
                }
                conKpiRecToInsert.add(contractKpiRec);                
            }
        }
        if(!conKpiRecToInsert.isEmpty()){
            //upsert conKpiList ECM_External_Id__c;
            List<Database.upsertResult> uResults = Database.upsert(conKpiRecToInsert,ECM_Contract_KPI__c.ECM_External_Id__c,false);
            for (Database.UpsertResult results : uResults){
                if (!results.isSuccess()){
                    System.debug('Failure : Result ID' + results.getId());
                    System.debug('Failure : Result' + results);
                }
            }
        }
        conKpiRecToInsert.clear();        
    }
    
    /*
	* Name : nullCheck (ECM-5907)
	* @description : Method to create contract KPi recs
	* @return : Decimal
	* @param : Decimal
	*/
    //Method to Check Null value
    public static Decimal nullCheck(Decimal val){
        return (val == null)?0:val;
        
    }
    /*
	* Name : recalConKPI (ECM-6078)
	* @description : Method to Recalculate contract fields
	* @return : void
	* @param : Map<Id,Contract>,Map<Id,List<ECM_Contract_Item__c>>,Map<Id,List<ECM_CreateContractController.GraphPercentValWrapper>>
	*/
    public static void recalConKPI(Map<Id,Contract> contractMap, Map<Id,List<ECM_Contract_Item__c>> conWithConItemMap, Map<Id,List<ECM_CreateContractController.GraphPercentValWrapper>> conGraphMap){
        List<Contract> updtconLst = new List<Contract>();
        Decimal totalGp=0;
        Decimal gpRoiInv=0;
        Decimal capRoiCalc=0;
        Decimal generatedNSV=0;
        Decimal totalInvestTrade;
        Decimal totalInvestmentAndP;
        Decimal overallInvest = 0;
        Decimal aandpPlusTrade;
        Decimal capRoirate;
        Decimal gpRoi;
        String conFieldapi;
        Map<String,Decimal> graph = new Map<String,Decimal>();
        List<ECM_CreateContractController.GraphPercentValWrapper> grphLst;
        
        for(Id conId : contractMap.keySet()){
            if(conWithConItemMap!= null && conWithConItemMap.containsKey(conId)){
                for(ECM_Contract_Item__c conItemObj : conWithConItemMap.get(conId)){
                    totalGp += conItemObj.ECM_Total_GP_EU__c;
                    gpRoiInv += conItemObj.ECM_GP_ROI_EU__c;
                    capRoiCalc += conItemObj.ECM_CAP_ROI_EU__c;
                    generatedNSV += nullCheck(conItemObj.ECM_Generated_NSV_EU__c);     
                }
            }
            Contract con = contractMap.get(conId);
            totalInvestTrade = (con.ECM_Total_trade_investment_Spirits__c + con.ECM_Total_trade_investment_Beers__c).setScale(2); 
            totalInvestmentAndP = (con.ECM_Total_A_P_Investment_Spirits__c + con.ECM_Total_A_P_Investment_Beers__c).setScale(2);           
            overallInvest = totalInvestmentAndP + con.ECM_EU_Total_Trade_Investment__c; 
            con.ECM_Overall_Investment_Figure__c = overallInvest.setScale(2); 
            con.ECM_of_the_total_investment_vs_NSV__c = con.ECM_Total_NSV__c != null && con.ECM_Total_NSV__c != 0.00 ? String.valueOf(((overallInvest/con.ECM_Total_NSV__c)*100).setScale(2)) : null; 
            aandpPlusTrade = totalInvestTrade + totalInvestmentAndP; 
            capRoirate = (totalGp - totalInvestmentAndP - capRoiCalc).setScale(2); 
            con.ECM_CAP_ROI__c = overallInvest != 0 ? String.valueOf(((capRoirate/overallInvest)*100).setScale(2)) : null; 
            
            if(contractMap.get(conId).ECM_Agreement_Type__r.ECM_Activation_Spend__c){
                //not calculating Indirect inv since not going to AP screen
                overallInvest = (overallInvest + con.ECM_Total_Indirect_Investment__c).setScale(2); 
                con.ECM_of_Indirect_Invest_to_Overall_Invest__c =  overallInvest != 0 ? ((con.ECM_Total_Indirect_Investment__c/overallInvest)*100).setScale(2) : null;
                con.ECM_CAAP_ROI_incl_Indirect_Invest__c = overallInvest != 0 ? ((capRoirate/overallInvest)*100).setScale(2) : null;
                con.ECM_Total_Invest_vs_NSV_Indirect_Invest__c = con.ECM_Total_NSV__c != null && con.ECM_Total_NSV__c != 0.00 ? ((overallInvest/con.ECM_Total_NSV__c)*100).setScale(2) : null; 
                con.ECM_of_A_P_vs_NSV_Inc_Indirect_Inv__c = con.ECM_Total_NSV__c != null && con.ECM_Total_NSV__c != 0.00 ? (((totalInvestmentAndP + con.ECM_Total_Indirect_A_P__c)/con.ECM_Total_NSV__c)*100).setScale(2) : null; 
            }
            con.ECM_Fixed_share__c =  overallInvest != 0 ? String.valueOf(((totalInvestmentAndP/overallInvest)*100).setScale(2)) : null; 
            con.ECM_Variable_share__c =  overallInvest != 0 ? String.valueOf(((totalInvestTrade/overallInvest)*100).setScale(2)) : null;
            con.ECM_of_A_P_vs_NSV__c = con.ECM_Total_NSV__c != null && con.ECM_Total_NSV__c != 0.00 ?((totalInvestmentAndP/con.ECM_Total_NSV__c)*100).setScale(2) : null; 
            
            con.ECM_Generated_NSV__c = String.valueOf((generatedNSV).setScale(2));
            con.ECM_Total_TI_Investment__c = String.valueOf(totalInvestTrade.setScale(2)); 
            con.ECM_Total_A_P_Investment__c = String.valueOf(totalInvestmentAndP.setScale(2)); 
            con.ECM_Total_GP__c = String.valueOf(totalGp.setScale(2));
            
            //not including Brand Marketing A&P,Customer Marketing A&P,Total Indirect TI,Total Indirect A&P,Total Indirect Inv.
            
            if(totalInvestTrade != 0 && totalInvestTrade != null){
                gpRoi = (gpRoiInv/totalInvestTrade)*100; 
            }            
            con.ECM_GP_ROI__c = (totalInvestTrade != 0 && totalInvestTrade != null)?String.valueOf(gpRoi.setScale(2)):'0';
            
            if(!conGraphMap.isEmpty() && conGraphMap.containsKey(conId)){
                grphLst =  conGraphMap.get(conId);
                for(Integer i=0;i<grphLst.size();i++){
                    if(grphLst[i].pkupOptnVal != null){
						conFieldapi = grphLst[i].pkupOptnVal.substringBefore('[').trim();
                    	conFieldapi = conFieldapi.replace(' ', '_').toLowerCase();
                    	graph.put('gm_'+conFieldapi,grphLst[i].gmPercentVal);
                    	graph.put('gp_'+conFieldapi,grphLst[i].gpPercentVal);
                    	graph.put('nsv_'+conFieldapi,grphLst[i].nsvPercentVal);                        
                    }                    
                }
                con.ECM_GM_innovation_share__c = graph.containsKey('gm_innovation')?String.valueOf(graph.get('gm_innovation')):null;
                con.ECM_GP_innovation_share__c = graph.containsKey('gp_innovation')?String.valueOf(graph.get('gp_innovation')):null;
                con.ECM_NSV_innovation_share__c = graph.containsKey('nsv_innovation')?String.valueOf(graph.get('nsv_innovation')):null;
                con.ECM_GM_premium_core_share__c = graph.containsKey('gm_premium_core')?String.valueOf(graph.get('gm_premium_core')):null;
                con.ECM_GP_premium_core_share__c = graph.containsKey('gp_premium_core')?String.valueOf(graph.get('gp_premium_core')):null;
                con.ECM_NSV_premium_core_share__c = graph.containsKey('nsv_premium_core')?String.valueOf(graph.get('nsv_premium_core')):null;
                con.ECM_GM_local_priority_brand_share__c = graph.containsKey('gm_local_priority_brand')?String.valueOf(graph.get('gm_local_priority_brand')):null;
                con.ECM_GP_local_priority_brand_share__c = graph.containsKey('gp_local_priority_brand')?String.valueOf(graph.get('gp_local_priority_brand')):null;
                con.ECM_NSV_local_priority_brand_share__c = graph.containsKey('nsv_local_priority_brand')?String.valueOf(graph.get('nsv_local_priority_brand')):null;
                con.ECM_GM_reserve_share__c = graph.containsKey('gm_reserve')?String.valueOf(graph.get('gm_reserve')):null;
                con.ECM_GP_reserve_share__c = graph.containsKey('gp_reserve')?String.valueOf(graph.get('gp_reserve')):null;
                con.ECM_NSV_reserve_share__c = graph.containsKey('nsv_reserve')?String.valueOf(graph.get('nsv_reserve')):null;
            }
            updtconLst.add(con);
        }
        if(!updtconLst.isEmpty()){
            update updtconLst;
        }
        updtconLst.clear();
        graph.clear();
        grphLst.clear();
    }

    /*
	* Name : updateApprovalDate (ECM-5960)
	* @description : Method to assign values to approval date
	* @return : void
	* @param : Map<Id,ECM_Addendum__c>, Map<Id, ECM_Addendum__c>
    */
    public static void updateApprovalDate ( Map<Id,ECM_Addendum__c> newItems, Map<Id, ECM_Addendum__c> oldItems ) {
        for ( ECM_Addendum__c addendum : newItems.values() ) {
            if ( addendum.ECM_Status__c == 'Approved' &&
                oldItems.get( addendum.Id ).ECM_Status__c != addendum.ECM_Status__c &&
                addendum.ECM_Addendum_Type__c != Label.ECM_AddendumTypeTC ) {
                addendum.ECM_Addendum_Approval_Date__c = Date.Today();
            }
        }
    }
    //CUS-327
    public static void updateDistributionAchievedInCI ( Map<Id,ECM_Addendum__c> newItems, Map<Id, ECM_Addendum__c> oldItems ) {
        set<id> contractIds = new set<Id>();
        for ( ECM_Addendum__c addendum : newItems.values() ) {
            if ( addendum.ECM_Status__c == 'Approved' &&
                oldItems.get( addendum.Id ).ECM_Status__c != addendum.ECM_Status__c) {
                contractIds.add(addendum.ECM_Contract__c);
            }
        }
        
        Map<Id,Contract> newContractMap = new Map<Id,Contract>();
        Map<Id,Contract> oldContractMap = new Map<Id,Contract>();
        for(Contract con: 
            [SELECT Id,Name,Status,RecordTypeId,AccountId,StartDate,Contract_End_Date__c 
             FROM Contract WHERE Id IN:contractIds]){
                 con.Status ='Approved';
                 oldContractMap.put(con.Id,con);
                 con.Status ='Active';   
                 newContractMap.put(con.Id,con);
        }
        ECM_ContractTriggerHelper.updateDistributionAchievedInCI(newContractMap, oldContractMap);
    }
}