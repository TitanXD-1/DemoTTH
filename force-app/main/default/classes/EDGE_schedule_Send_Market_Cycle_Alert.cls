global class EDGE_schedule_Send_Market_Cycle_Alert implements Schedulable{
    global void execute(SchedulableContext sc) {
        EDGE_Send_Market_Cycle_Alert mc = new EDGE_Send_Market_Cycle_Alert();
        Database.executeBatch(mc,1);
    }
}