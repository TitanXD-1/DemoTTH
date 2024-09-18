global class ECM_ContractItemAnalysis_Schedular implements Schedulable {
   global void execute(SchedulableContext sc) {
      ECM_ContractItemAnalysisInsert_Batch b = new ECM_ContractItemAnalysisInsert_Batch(); 
      database.executebatch(b);
   }
}