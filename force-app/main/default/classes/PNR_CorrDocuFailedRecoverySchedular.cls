global class PNR_CorrDocuFailedRecoverySchedular implements Schedulable {
    global void execute(SchedulableContext sc){
        PNR_CorrDocumentFailedRecoveryBatch corrDocuFailedRecovery = new PNR_CorrDocumentFailedRecoveryBatch();
        database.executeBatch(corrDocuFailedRecovery,1);
    }
}