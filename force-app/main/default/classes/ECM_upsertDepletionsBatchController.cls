/*
* @Name: ECM_upsertDepletionsBatchController
* @description: This Class used to create batch Jobs for the data from "ECM_VolumeInputScreenController" and update the paymentSummary Items
* @History

VERSION    AUTHOR                DATE              DETAIL
1.0      Manikandan T         24/12/2021        Initial Development
2.0      Pratap Sen           09/02/2021        ECM-5134 : Added Null Check in updatePaymentSummaryItems
3.0		 Pratap Sen			  23/02/2022		Added logic for deleting depletions updated to 0 Actuals
4.0      Pratap Sen           22/06/2022        ECM-5677 : added update contract statement in finish method if confirmed volume is changed
5.0      Pratap/Subhrojit     05/07/2022        ECM-5619 : added logic to calculate ECM_Updated_Forecasted_Volume__c of PSI in updatePaymentSummaryItems()
5.1		 Saurav Prasad		  15/11/2022		ECM-6359 : Duplicate Depletion Create issue in Prod
*/
global class ECM_upsertDepletionsBatchController implements Database.Batchable<Depletions__c>,Database.stateful{
    
    public List<Depletions__c> depletionList;
    public List<Id> depletionDelList;
    public String conId;
    public Contract conRec;
    public Market_Setting__c marSet;
    public Map<Id,ECM_Payment_Summary__c>paymentSummaryMap;
	public Map<Id,List<ECM_Payment_Summary_Item__c>> paymentSummaryItemMap;
	public Map<Id,ECM_Tiering__c> mapOfTier;
    public Map<Id, ECM_Payment_Summary_Item__c> updatePayItems;
    public Map<Id, Decimal> psMap;
    public Map<id,List<ECM_Payment_Summary_Item__c>> mapOfupdatePayItems;
    public Set<ECM_Payment_Summary_Item__c> listOfPayItems;

    global ECM_upsertDepletionsBatchController(List<Depletions__c> depletionList,List<id> depletionDelList,String conId,Contract conRec,Market_Setting__c marSet,Map<Id,ECM_Payment_Summary__c> paymentSummaryMap,Map<Id,List<ECM_Payment_Summary_Item__c>> paymentSummaryItemMap, Map<Id,ECM_Tiering__c> mapOfTier ) {
        this.depletionList = depletionList;
        this.depletionDelList = depletionDelList;
        this.conId=conId;
        this.conRec=conRec;
        this.marSet=marSet;
        this.paymentSummaryMap=paymentSummaryMap;
		this.paymentSummaryItemMap=paymentSummaryItemMap;
		this.mapOfTier=mapOfTier;
        this.updatePayItems= new Map<Id, ECM_Payment_Summary_Item__c>();
        this.psMap= new Map<Id, Decimal>();
        this.mapOfupdatePayItems = new Map<Id,List<ECM_Payment_Summary_Item__c>>();
        this.listOfPayItems = new Set<ECM_Payment_Summary_Item__c>();
    }
    
   global Iterable<Depletions__c>  start(Database.BatchableContext info){
       return new IntegerIterator(depletionList);
   }
   global void execute(Database.BatchableContext info, List<Depletions__c> scope){
	   
		List<Id>depletionsId= new List<Id>();
 		try{
            //ECM-6359 Added external Id check
        	Database.Upsert(scope,Depletions__c.Unique_ID__c);
            
            for(Depletions__c dep:scope){
                depletionsId.add(dep.Id);
            }
            updatePaymentSummaryItems(depletionsId);
		}catch(Exception ex){
            System.debug('Full Exception:'+ex);
			System.debug('Class:ECM_upsertDepletionsBatchController\nmethod:execute\nException:::' + ex.getLineNumber() +'\n'+ ex.getMessage() +'\n'+ ex.getCause());
		}
   }
   global void finish(Database.BatchableContext info){
       List<ECM_Payment_Summary__c> updatePaySum = New List<ECM_Payment_Summary__c>();
       Boolean updateConLastVolInfo = false;
       if(!updatePayItems.isEmpty()){
           //ECM-5677 starts
           if(Test.isRunningTest() || (conRec.ECM_Payment_Frequency_type__r.ECM_Type__c != Null && System.Label.ECM_PFforActualVolumeYTD.contains(conRec.ECM_Payment_Frequency_type__r.ECM_Type__c) 
              && conRec.ECM_Last_Volume_Information_Update__c != System.today())){
               for(ECM_Payment_Summary_Item__c psItemtoUpdate : listOfPayItems){
                   if(updatePayItems.containsKey(psItemtoUpdate.Id) && psItemtoUpdate.ECM_Confirmed_Volume__c != updatePayItems.get(psItemtoUpdate.Id).ECM_Confirmed_Volume__c){
                       updateConLastVolInfo = true;
                       break;
                   }
               }
           }
           //ECM-5677 ends
           update updatePayItems.values();
       }
       updatePaySum = psAchievedTableCalc(mapOfupdatePayItems.keySet(),psMap,paymentSummaryMap,paymentSummaryItemMap,updatePayItems);
       //Updating Payment summaries
       if(!updatePaySum.isEmpty()){
           update updatePaySum;
       }
       if(updateConLastVolInfo){
           Contract con = new Contract(id = conRec.Id);
           con.ECM_Last_Volume_Information_Update__c = system.today();
           update con;
       }
       //ECM-5194(Deleting depletions updated to 0 volume)
       if(!depletionDelList.isEmpty()){
           Database.deleteResult[] srList = Database.delete(depletionDelList, false);
       } 
   }
	public void updatePaymentSummaryItems(List<Id> depletionsId) {
        
        set<String> restrictedPaymentStatus = new set<String>{'Submitted','Approved','Completed','In Approval process'};
            try{

                    
				//List<ECM_Payment_Summary_Item__c> listOfPayItems = new List<ECM_Payment_Summary_Item__c>();
				Map<Id,List<ECM_Payment_Summary_Item__c>> mapOfApprovedPaymentSummary= new Map<Id,List<ECM_Payment_Summary_Item__c>>();
				List<ECM_Payment_Summary__c> psLst = new List<ECM_Payment_Summary__c>();
				List<ECM_Payment_Summary__c> updatePaySum = New List<ECM_Payment_Summary__c>();                    
													   
				for(ECM_Payment_Summary__c paysum:paymentSummaryMap.values()){

				   //filtering with specific payment summary status
				   if(!restrictedPaymentStatus.contains(paysum.ECM_Payment_Summary_Status__c) && paymentSummaryItemMap.get(paysum.Id)!=null){
					   listOfPayItems.addAll(paymentSummaryItemMap.get(paysum.Id));
					   mapOfupdatePayItems.put(paysum.Id,paymentSummaryItemMap.get(paysum.Id));
				   }
				   
				   //get Approved Payment summary items
				   else if((paysum.ECM_Payment_Summary_Status__c == 'Approved' || 
							paysum.ECM_Payment_Summary_Status__c == 'Completed') &&
						   paysum.ECM_Contract__r.Status == 'Active' && 
						   paymentSummaryItemMap.get(paysum.Id)!=null){
							   mapOfApprovedPaymentSummary.put(paysum.ECM_Contract__c,paymentSummaryItemMap.get(paysum.Id)); 
						   }
			    }
                    
                    System.debug('mapOfApprovedPaymentSummary--->'+mapOfApprovedPaymentSummary);
                    System.debug('listOfPayItems--->'+listOfPayItems.size());
                    System.debug('mapOfupdatePayItems--->'+mapOfupdatePayItems.size());
                    //map of Tiering
 
                    
                    List<Depletions__c> listOfDepletions = [Select Id,Name,Contract__c,ECM_End_Period__c,Forecast_Volume__c,
                                                            ECM_Outlet__c,ECM_Product__c,ECM_Start_Period__c,Unique_ID__c,ECM_Volume__c 
                                                            FROM Depletions__c where ECM_Start_Period__c>=:conRec.StartDate AND ECM_End_Period__c<=:conRec.Contract_End_Date__c AND ECM_Volume__c!=Null AND Id IN:depletionsId];
                    
                    If(!listOfDepletions.isEmpty()){
                        for(ECM_Payment_Summary_Item__c psItems : listOfPayItems){
                            for(Depletions__c depletn : listOfDepletions){ 
                                if((psItems.ECM_Contract_Item__r.ECM_Product__r.Product__c == depletn.ECM_Product__c) && (psItems.ECM_Payment_Summary__r.ECM_Start_Period__c <= depletn.ECM_Start_Period__c) && (psItems.ECM_Payment_Summary__r.ECM_End_Period__c >= depletn.ECM_End_Period__c)){
                                    if(updatePayItems.containskey(psItems.Id)){ 
                                        updatePayItems.get(psItems.Id).ECM_Confirmed_Volume__c += depletn.ECM_Volume__c;
                                        updatePayItems.get(psItems.Id).ECM_Updated_Forecasted_Volume__c += depletn.Forecast_Volume__c; //ECM-5619
                                        updatePayItems.get(psItems.Id).ECM_Confirmed_Amount_Per_Payment__c = (psItems.ECM_Contract_Item__r.ECM_UoM__c != NULL)? updatePayItems.get(psItems.Id).ECM_Confirmed_Volume__c * Decimal.valueOf(psItems.ECM_Contract_Item__r.ECM_UoM__c):0;
                                    }else{
                                        updatePayItems.put(psItems.Id,new ECM_Payment_Summary_Item__c(Id = psItems.Id,
                                                                                                      ECM_Confirmed_Volume__c = depletn.ECM_Volume__c,
                                                                                                      ECM_Updated_Forecasted_Volume__c = depletn.Forecast_Volume__c,
                                                                                                      ECM_Confirmed_Amount_Per_Payment__c= (psItems.ECM_Contract_Item__r.ECM_UoM__c != NULL)? depletn.ECM_Volume__c * Decimal.valueOf(psItems.ECM_Contract_Item__r.ECM_UoM__c):0,ECM_Percentage_Target_Achieved__c=null));
                                    }
                                    if(marSet.Ecm_Enable_Target__c){

                                        updatePayItems.get(psItems.Id).ECM_Percentage_Target_Achieved__c=(psItems.ECM_Contract_Item__r.ECM_Volume_Target_per_PF__c != NULL )? 
                                            (updatePayItems.get(psItems.Id).ECM_Confirmed_Volume__c/psItems.ECM_Contract_Item__r.ECM_Volume_Target_per_PF__c)*100 : 0;

                                    }
                                }                
                            }
                        }
                    }
                    
                    //Calculating Confirmed based on Tiering values
                    if(mapOfTier.size()>0){
                        for(Id paySumId : mapOfupdatePayItems.keySet()){
                            Decimal TotalConfirmedAmount = 0;
                            for(ECM_Payment_Summary_Item__c paySumItem: mapOfupdatePayItems.get(paySumId)){
                                decimal volume=0;
                                Decimal payment=0;
                                Id contractId = paySumItem.ECM_Payment_Summary__r.ECM_Contract__c;
                                Id contractItemId = paySumItem.ECM_Contract_Item__c;
                                //getting approved payment summary items
                                if(mapOfApprovedPaymentSummary.containsKey(contractId) 
                                   && 
                                   mapOfTier.containsKey(contractItemId)){
                                       for(ECM_Payment_Summary_Item__c approvedpaySumItem: mapOfApprovedPaymentSummary.get(contractId)){
                                           //Calculating Volume and Confirmed amount from approved Payment Summaries
                                           if(contractItemId == approvedpaySumItem.ECM_Contract_Item__c){
                                               volume += approvedpaySumItem.ECM_Confirmed_Volume__c;
                                               payment += approvedpaySumItem.ECM_Confirmed_Amount_Per_Payment__c;
                                           }
                                       }
                                   }
                                volume += updatePayItems.get(paySumItem.Id).ECM_Confirmed_Volume__c;
                                //Tiering Values check based on accumulated Volume
                                if( mapOfTier.containsKey(contractItemId)){
                                    System.debug('volume:'+volume);
                                    //Volume check whether it is less than or equal to Tier1 Volume
                                    if(volume <= mapOfTier.get(contractItemId).ECM_Tier_1_volume_limit__c){
                                        updatePayItems.get(paySumItem.Id).ECM_Confirmed_Amount_Per_Payment__c 
                                            = (volume * mapOfTier.get(contractItemId).ECM_Tier_1_rate_per_UoM__c).setScale(2) 
                                            - payment;
                                    }
                                    //Volume check whether it is greater than Tier1 volume and less than or equal to Tier2 Volume
                                    else if(volume > mapOfTier.get(contractItemId).ECM_Tier_1_volume_limit__c
                                            && 
                                            volume <= mapOfTier.get(contractItemId).ECM_Tier_2_volume_limit__c){
                                                updatePayItems.get(paySumItem.Id).ECM_Confirmed_Amount_Per_Payment__c 
                                                    = (volume * mapOfTier.get(contractItemId).ECM_Tier2_rate_per_UoM__c).setScale(2) 
                                                    - payment;
                                            }
                                    //Volume check whether it is greater than Tier2 volume and less than or equal to Tier3 Volume
                                    else if(volume > mapOfTier.get(contractItemId).ECM_Tier_2_volume_limit__c
                                            && 
                                            volume <= mapOfTier.get(contractItemId).ECM_Tier_3_volume_limit__c){
                                                updatePayItems.get(paySumItem.Id).ECM_Confirmed_Amount_Per_Payment__c 
                                                    = (volume * mapOfTier.get(contractItemId).ECM_Tier_3_rate_per_UoM__c).setScale(2) 
                                                    - payment;
                                            }
                                    //Volume check whether it is greater than Tier3 
                                    else if(volume > mapOfTier.get(contractItemId).ECM_Tier_3_volume_limit__c){
                                        //Market Setting Check if it is -- Pay at tier 3 rate any exceeding volume (opt.1)
                                        if(marSet.ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c 
                                           == 
                                           'Pay at tier 3 rate any exceeding volume (opt.1)'){
                                               updatePayItems.get(paySumItem.Id).ECM_Confirmed_Amount_Per_Payment__c 
                                                   = (volume * mapOfTier.get(contractItemId).ECM_Tier_3_rate_per_UoM__c).setScale(2) 
                                                   - payment;
                                           }
                                        //Market Setting Check if it is Not -- Pay at tier 3 rate any exceeding volume (opt.1)
                                        else{
                                            //Check if Tier3 colume and Tier3 Uom is greater than equal to zero
                                            if(((mapOfTier.get(contractItemId).ECM_Tier_3_volume_limit__c
                                                 * mapOfTier.get(contractItemId).ECM_Tier_3_rate_per_UoM__c)
                                                -payment) >= 0){
                                                    updatePayItems.get(paySumItem.Id).ECM_Confirmed_Amount_Per_Payment__c 
                                                        = ((mapOfTier.get(contractItemId).ECM_Tier_3_volume_limit__c
                                                            * mapOfTier.get(contractItemId).ECM_Tier_3_rate_per_UoM__c).setScale(2)
                                                           -payment);
                                                }
                                            // Check if Tier3 volume and Tier3 Uom is less than zero                     
                                            else{
                                                updatePayItems.get(paySumItem.Id).ECM_Confirmed_Amount_Per_Payment__c = 0;
                                            }
                                        }
                                    }
                                    
                                }
                                TotalConfirmedAmount += updatePayItems.get(paySumItem.Id).ECM_Confirmed_Amount_Per_Payment__c;
                            }
                            //Updating Total Amount Confirmed
                            //updatePaySum.add(new ECM_Payment_Summary__c(Id=paySumId,ECM_Total_Amount_Confirmed__c=TotalConfirmedAmount.setScale(2)));
                            psMap.put(paySumId,TotalConfirmedAmount.setScale(2));
                        }                         
                    }

                          
            }catch(exception ex){
                system.debug('Exception ='+ex.getMessage());
                System.debug('Class:ECM_upsertDepletionsBatchController\nmethod:updatePaymentSummaryItems\nException:::' + ex.getLineNumber() +'\n'+ ex.getMessage() +'\n'+ ex.getCause());
            }
    }
    
	public static List<ECM_Payment_Summary__c> psAchievedTableCalc(Set<Id> paySumId, Map<Id,Decimal> psMap,Map<Id,ECM_Payment_Summary__c>paymentSummaryMap, Map<Id,List<ECM_Payment_Summary_Item__c>> paymentSummaryItemMap, Map<Id, ECM_Payment_Summary_Item__c> updatePayItems){
			List<ECM_Payment_Summary__c> paySumList = new List<ECM_Payment_Summary__c>();
			Map<Id, ECM_PaymentSummaryController.brandCalculation> psWrapMap= new Map<Id, ECM_PaymentSummaryController.brandCalculation>();
			if(!paySumId.isEmpty()){
				for(Id psId :paySumId)
				{
					if(paymentSummaryMap.containskey(psId)){
						ECM_Payment_Summary__c psObj=paymentSummaryMap.get(psId);
					psWrapMap.put(psObj.Id, getBrandCalulation(psObj,paymentSummaryItemMap.get(psObj.Id),updatePayItems));
				}
				}
				if(!psWrapMap.isEmpty()){
					for(Id psId : psWrapMap.keySet()){   
						ECM_Payment_Summary__c paySumObj = new ECM_Payment_Summary__c(Id=psId);
						if(psMap.containsKey(psId)){
							paySumObj.ECM_Total_Amount_Confirmed__c = psMap.get(psId);
						}
						//calc for PS %Achieved Table
						Decimal totalActualVol = psWrapMap.get(psId).sumOfNonLeadActualVol + psWrapMap.get(psId).sumOfLeadActualVol;
						Decimal totalTarget = psWrapMap.get(psId).sumOfNonLeadVolTarget + psWrapMap.get(psId).sumOfLeadVolTarget;
						Decimal achievedOverallVol = totalActualVol + totalTarget;
						paySumObj.ECM_Achieved_Non_Leading_Brand__c = psWrapMap.get(psId).sumOfNonLeadVolTarget == 0 || psWrapMap.get(psId).sumOfNonLeadVolTarget ==null ? 0 :((psWrapMap.get(psId).sumOfNonLeadActualVol*100)/psWrapMap.get(psId).sumOfNonLeadVolTarget).setScale(1);
						paySumObj.ECM_Achieved_Leading_Brand__c = psWrapMap.get(psId).sumOfLeadVolTarget == 0 || psWrapMap.get(psId).sumOfLeadVolTarget == null ? 0:((psWrapMap.get(psId).sumOfLeadActualVol*100)/psWrapMap.get(psId).sumOfLeadVolTarget).setScale(1);
						paySumObj.ECM_Achieved_Overall__c = totalTarget == null || totalTarget ==0 ? 0 : ((totalActualVol*100)/totalTarget).setScale(1);
						paySumList.add(paySumObj);
                        system.debug('ECM_Achieved_Non_Leading_Brand__c--->'+paySumObj.ECM_Achieved_Non_Leading_Brand__c);
                         system.debug('ECM_Achieved_Leading_Brand__c--->'+paySumObj.ECM_Achieved_Leading_Brand__c);
                        system.debug('sumOfNonLeadVolTarget--->'+psWrapMap.get(psId).sumOfNonLeadVolTarget);
                        system.debug('sumOfLeadVolTarget--->'+psWrapMap.get(psId).sumOfLeadVolTarget);
                        system.debug('sumOfNonLeadActualVol--->'+psWrapMap.get(psId).sumOfNonLeadActualVol);
                        system.debug('sumOfLeadActualVol--->'+psWrapMap.get(psId).sumOfLeadActualVol);
					}
				}
			}
			System.debug(paySumList);
			return paySumList;
    }
	
	public static ECM_PaymentSummaryController.brandCalculation getBrandCalulation(ECM_Payment_Summary__c ps, List<ECM_Payment_Summary_Item__c>PSItemList, Map<Id, ECM_Payment_Summary_Item__c> updatePayItems){
        ECM_PaymentSummaryController.brandCalculation brandData = new ECM_PaymentSummaryController.brandCalculation();
        Integer months;
        if(ps.ECM_Start_Period__c!=Null && ps.ECM_End_Period__c!=Null){//Fix for ECM-4866
            months = ps.ECM_Start_Period__c.monthsBetween(ps.ECM_End_Period__c.addDays(1));
        }
        //Fix for ECM-4866
        if(months!=Null){
            for(ECM_Payment_Summary_Item__c psItem : PSItemList){
                if(psItem.ECM_Contract_Item__r.ECM_Lead_Brand__c){
                    brandData.sumOfLeadActualVol += (updatePayItems.get(psItem.id)!=Null && updatePayItems.get(psItem.id).ECM_Confirmed_Volume__c!=Null)?(updatePayItems.get(psItem.id).ECM_Confirmed_Volume__c).setScale(2):0;
                    brandData.sumOfLeadVolTarget += psItem.ECM_Contract_Item__r.ECM_Volume__c!=Null?psItem.ECM_Contract_Item__r.ECM_Volume__c:0;
                }else{
                    brandData.sumOfNonLeadActualVol += (updatePayItems.get(psItem.id)!=Null && updatePayItems.get(psItem.id).ECM_Confirmed_Volume__c!=Null)?(updatePayItems.get(psItem.id).ECM_Confirmed_Volume__c).setScale(2):0;
                    brandData.sumOfNonLeadVolTarget += psItem.ECM_Contract_Item__r.ECM_Volume__c!=Null?psItem.ECM_Contract_Item__r.ECM_Volume__c:0;
                }
            }            
            //Division by Duration & multiply by Payment Summary months
            brandData.sumOfLeadVolTarget = ((brandData.sumOfLeadVolTarget/ps.ECM_Contract__r.ECM_Duration__c) * months).setScale(2);
            brandData.sumOfNonLeadVolTarget = ((brandData.sumOfNonLeadVolTarget/ps.ECM_Contract__r.ECM_Duration__c) * months).setScale(2);
        }
        return brandData;
        //End of ECM-4760
    }
    
    public class IntegerIterator implements Iterable<Depletions__c>, Iterator<Depletions__c> { 
        List<Depletions__c> DepletionList; 
        Integer counter;
        public IntegerIterator(List<Depletions__c> DepletionList) {
         this.DepletionList = DepletionList; 
         this.counter=-1;
        } 
        
        public Boolean hasNext() { return counter < DepletionList.size()-1; } 
        
        public Depletions__c next() {
            
            counter++;
            return DepletionList[counter];
        } 
        
        public Iterator<Depletions__c> iterator() { return this; } 
        } 
}