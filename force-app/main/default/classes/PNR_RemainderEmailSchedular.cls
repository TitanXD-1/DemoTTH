global class PNR_RemainderEmailSchedular implements Schedulable {
	global void execute(SchedulableContext sc){
        PNR_SendApprovalEmailReminderBatch remainderMail = new PNR_SendApprovalEmailReminderBatch();
        database.executeBatch(remainderMail,10);
    }
}